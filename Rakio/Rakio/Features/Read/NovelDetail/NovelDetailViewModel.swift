import Foundation
import FirebaseFirestore
import SwiftUI // Required for @MainActor

// MARK: - Supporting Data Structures

enum NavigationDirection {
    case previous, next
}
// MARK: - NovelDetailViewModel

@MainActor
class NovelDetailViewModel: ObservableObject {
    @Published var novel: NovelDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var series: Series?

    // Chapters specific
    @Published var chapters: [Chapter] = []
    @Published var chapterErrorMessage: String?
    @Published var showAllChapters = false
    @Published var showUploadError = false
    @Published var uploadErrorMessage: String?

    // MARK: - Chapter Reading State & Navigation (NEW/MODIFIED)
    @Published var currentChapterIndex: Int? = nil // Index of chapter currently being read
    @Published var shouldNavigateToChapter: Bool = false // Programmatic navigation flag

    var currentChapter: Chapter? {
        guard let index = currentChapterIndex, index >= 0, index < chapters.count else {
            return nil
        }
        return chapters[index]
    }
    
    var canGoPrevious: Bool {
        guard let index = currentChapterIndex else { return false }
        return index > 0
    }
    
    var canGoNext: Bool {
        guard let index = currentChapterIndex else { return false }
        return index < chapters.count - 1
    }

    // MARK: - Navigation Logic (Implements the ChapterDetailView's navigateAction)
    func navigateChapter(direction: NavigationDirection) {
        guard let current = currentChapterIndex else { return }

        switch direction {
        case .previous:
            if canGoPrevious {
                currentChapterIndex = current - 1
            }
        case .next:
            if canGoNext {
                currentChapterIndex = current + 1
            }
        }
        // NOTE: No need to call self.shouldNavigateToChapter = true/false,
        // the existing NavigationLink binding in NovelContentView maintains the active state.
    }
    // END NEW/MODIFIED

    private let novelService = NovelService()
    
    init() { }

    // MARK: - Fetch Novel Details
    func fetchNovel(by id: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            self.novel = try await novelService.fetchNovelDetail(by: id)
            
            if let relatedSeriesRef = novel?.relatedSeriesId {
                await fetchSeries(by: relatedSeriesRef)
            }
            
            await fetchChaptersFromFirestore()

            
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Error fetching novel details: \(error.localizedDescription)")
        }
        
        isLoading = false
    }

    // MARK: - Fetch Series (Assumes Series struct exists)
    func fetchSeries(by documentReference: DocumentReference) async {
        await MainActor.run { self.series = nil }
        
        do {
            let documentSnapshot = try await documentReference.getDocument()
            var decodedSeries = try documentSnapshot.data(as: Series.self)
            decodedSeries.id = documentSnapshot.documentID
            await MainActor.run { self.series = decodedSeries }
            print("✅ Successfully decoded series with ID: \(self.series?.id ?? "nil")")
        } catch {
            await MainActor.run {
                self.errorMessage = "Error fetching series: \(error.localizedDescription)"
                print("❌ Error fetching series: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch Chapters from Firestore (UPDATED to include sorting)
    @MainActor
    func fetchChaptersFromFirestore() async {
        guard let novelId = novel?.id else {
            chapterErrorMessage = "Novel ID not available."
            return
        }

        let db = Firestore.firestore()
        let chaptersRef = db.collection("novels").document(novelId).collection("chapters")
        
        do {
            let snapshot = try await chaptersRef.order(by: "sortOrder").getDocuments()
            let decodedChapters = snapshot.documents.compactMap { doc -> Chapter? in
                try? doc.data(as: Chapter.self)
            }

            if decodedChapters.isEmpty {
                chapterErrorMessage = "No chapters found in Firestore, falling back to TXT."
                loadChaptersFromTxt()

                if !chapters.isEmpty {
                    Task { await uploadChaptersToFirestore() }
                }
            } else {
                chapters = decodedChapters
                chapterErrorMessage = nil
            }

            print("✅ Successfully updated chapters count: \(chapters.count)")

        } catch {
            chapterErrorMessage = "Error fetching chapters: \(error.localizedDescription)"
            print("❌ \(chapterErrorMessage!)")
            loadChaptersFromTxt()
        }
    }


    // MARK: - Load Chapters from TXT (Local Fallback)
    func loadChaptersFromTxt() {
        // ... (Function body remains the same, just calls parseChapters) ...
        guard let novel = novel, let fileName = novel.txtFileName else {
            chapterErrorMessage = "No text file available for this novel."
            return
        }
        
        chapters.removeAll()
        chapterErrorMessage = nil
        
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "txt") else {
            chapterErrorMessage = "Text file not found in bundle."
            print("❌ TXT file \(fileName).txt not found")
            return
        }
        
        do {
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            self.chapters = parseChapters(from: text)
            
            if self.chapters.isEmpty {
                chapterErrorMessage = "No chapters found in text file."
            } else {
                print("✅ Loaded \(chapters.count) chapters from TXT")
            }
            
        } catch {
            chapterErrorMessage = "Error reading text file: \(error.localizedDescription)"
            print("❌ Error reading TXT file: \(error.localizedDescription)")
        }
    }

    // MARK: - Parse Chapters from TXT (CRITICAL LOGIC CHANGE FOR SEQUENCING)
    private func parseChapters(from text: String) -> [Chapter] {
        var result: [Chapter] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentType: String = ""
        var currentTitle: String = ""
        var currentContent: String = ""
        var sortCounter = 0 // Tracks the chronological position in the file
        var chapterNumberCounter = 0 // Tracks the number for "Chapter" type
        
        func saveCurrentChapter() {
            if !currentType.isEmpty || !currentContent.isEmpty {
                
                let lowerType = currentType.lowercased()
                let isChapter = lowerType.contains("chapter")
                
                // If the type is chapter/special chapter, use the number. Otherwise, it's nil.
                let numberToUse = isChapter ? chapterNumberCounter : nil
                
                let chapter = Chapter(
                    id: nil,
                    title: currentTitle.isEmpty ? currentType : currentTitle,
                    heartCount: 0,
                    content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines),
                    type: currentType.lowercased(),
                    number: numberToUse,
                    sortOrder: sortCounter
                )
                result.append(chapter)
            }
            currentTitle = ""
            currentContent = ""
        }
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.starts(with: "---") {
                saveCurrentChapter() // Save the previous chapter
                sortCounter += 1 // Increment the overall order for the NEW chapter/section

                if trimmedLine.starts(with: "---Author note") {
                    currentType = "Author Note"
                    currentTitle = trimmedLine.replacingOccurrences(of: "---", with: "")
                } else if trimmedLine.starts(with: "---Synopsis") {
                    currentType = "Synopsis"
                    currentTitle = trimmedLine.replacingOccurrences(of: "---", with: "")
                } else if trimmedLine.starts(with: "---Introduction") {
                    currentType = "Introduction"
                    currentTitle = trimmedLine.replacingOccurrences(of: "---", with: "")
                } else if trimmedLine.starts(with: "---Chapter") {
                    currentType = "Chapter"
                    // Extract number: ---Chapter : 1, ---Chapter: 2 etc.
                    let numberString = trimmedLine.components(separatedBy: CharacterSet.decimalDigits.inverted)
                        .filter { !$0.isEmpty }
                        .joined()
                    chapterNumberCounter = Int(numberString) ?? (chapterNumberCounter + 1)
                    // Title will be captured in the next block
                } else if trimmedLine.starts(with: "---Special Chapter") {
                    currentType = "Special Chapter"
                    // Title will be captured in the next block
                }
            }
            // If the current section needs a separate title (like Chapter or Special Chapter)
            else if (currentType.lowercased().contains("chapter")) && currentTitle.isEmpty && !trimmedLine.isEmpty {
                currentTitle = trimmedLine // Capture the line immediately following the tag as the title
            } else if !currentType.isEmpty {
                // Otherwise, append the line to the content of the current chapter
                currentContent += line + "\n"
            }
        }
        
        saveCurrentChapter() // Save last chapter
        return result
    }

    // MARK: - Optional: Upload chapters to Firestore (The function that CREATES the subcollection)
    func uploadChaptersToFirestore() async {
        guard let novelId = novel?.id else { return }
        let db = Firestore.firestore()
        let chaptersRef = db.collection("novels").document(novelId).collection("chapters")
        
        // This loop
        for chapter in self.chapters {
            do {
                // The 'chapter' object now includes the 'sortOrder' field, which ensures the correct retrieval order.
                _ = try chaptersRef.addDocument(from: chapter)
                print("✅ Uploaded chapter: \(chapter.title) (Sort Order: \(chapter.sortOrder))")
            } catch {
                let msg = "Failed to upload chapter: \(chapter.title) - \(error.localizedDescription)"
                print("❌ \(msg)")
                await MainActor.run {
                    self.uploadErrorMessage = msg
                    self.showUploadError = true
                }
            }
        }
    }
}
