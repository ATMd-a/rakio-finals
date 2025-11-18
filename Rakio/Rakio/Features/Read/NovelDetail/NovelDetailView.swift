import SwiftUI
import FirebaseFirestore


struct NovelDetailView: View {
    // Requires a novel ID to fetch the details
    let novelId: String
    
    // The source of truth for the novel data
    @StateObject private var viewModel = NovelDetailViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.rakioBackground.ignoresSafeArea()

            // 1. Handle Loading State
            if viewModel.isLoading {
                ProgressView("Loading novel details...")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 2. Handle Success State (Extracted to new view)
            } else if let novel = viewModel.novel {
                NovelContentView(novel: novel, viewModel: viewModel)
            // 3. Handle Error State
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Upload Error Sheet
        .sheet(isPresented: $viewModel.showUploadError) {
            VStack(spacing: 20) {
                Text("Upload Error")
                    .font(.headline)
                Text(viewModel.uploadErrorMessage ?? "Unknown error")
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Dismiss") {
                    viewModel.showUploadError = false
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Triggers the data fetch on view appearance
            await viewModel.fetchNovel(by: novelId)
        }
    }
}

struct NovelContentView: View {
    let novel: NovelDetail // ✨ FIX 1: Change to the actual type
    @ObservedObject var viewModel: NovelDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                Spacer().frame(height: 41)
                
                NovelImageView(imageName: novel.imageName)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(novel.title)
                        .font(.custom("Poppins", size: 30))
                        .foregroundColor(.white)
                    
                    Text("Author: \(novel.author)")
                        .font(.custom("Poppins", size: 14))
                        .foregroundColor(.gray)
                    
                    Text(novel.description)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(nil)
                    
                    ChapterListView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                    
                    if let series = viewModel.series {
                        RelatedSeriesView(series: series)
                    }
                    
                    CommentsView()
                        .padding(.top, 40)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 50)
            .background(Color.rakioBackground.ignoresSafeArea()
            ) // Make scroll background dark
        }
        
    }
    
    struct NovelImageView: View {
        let imageName: String?
        
        var body: some View {
            if let imageName = imageName {
                // Assumes Image(uiImage: UIImage(named: ...)) works for assets
                Image(uiImage: UIImage(named: imageName) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 250)
                    .cornerRadius(10)
                    .padding(.bottom, 10)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 148, height: 209)
                    .cornerRadius(8)
            }
        }
    }
    
    struct ChapterListView: View {
        let viewModel: NovelDetailViewModel
        
        var body: some View {
            VStack(spacing: 16) {
                Text("Chapters")
                    .font(.custom("Poppins", size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.rakioSecondary, lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.rakioBackground
                                                                          ))
                    
                    if let errorMessage = viewModel.chapterErrorMessage {
                        Text(errorMessage).foregroundColor(.red).padding()
                    } else if viewModel.chapters.isEmpty {
                        Text("No chapters available.").foregroundColor(.gray).padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.chapters.indices, id: \.self) { index in
                                    ChapterRow(
                                        chapters: viewModel.chapters,
                                        currentIndex: index,
                                        viewModel: viewModel      // ✅ pass it explicitly
                                    )
                                }

                            }
                            .padding(.vertical, 10)
                        }
                        .frame(maxHeight: 300)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    
    struct ChapterRow: View {
        let chapters: [Chapter]
        let currentIndex: Int
        @ObservedObject var viewModel: NovelDetailViewModel
      // Index of this chapter in the list
        
        var body: some View {
            let chapter = chapters[currentIndex]
            let isLast = currentIndex == chapters.count - 1
            
            NavigationLink(
                destination: ChapterDetailView(
                    viewModel: viewModel,          // pass the ViewModel
                    chapters: chapters,
                    currentIndex: currentIndex
                )
            ) {
                VStack(spacing: 0) {
                    HStack {
                        Text(chapters[currentIndex].title)
                            .font(.custom("Poppins", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 5) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                            Text("\(chapters[currentIndex].heartCount)")
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 70)
                    
                    if currentIndex < chapters.count - 1 {
                        Divider()
                            .background(Color.gray)
                            .padding(.horizontal, 8)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

        }
    }
    
    
    struct RelatedSeriesView: View {
        let series: Series // Assuming 'Series' is a defined model type
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("Watch the Adaptation")
                    .font(.custom("Poppins", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Assumes SeriesDetailView exists
                NavigationLink(destination: SeriesDetailView(show: series)) {
                    HStack(spacing: 15) {
                        Image(uiImage: UIImage(named: series.imageName) ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 58)
                            .cornerRadius(6)
                            .clipped()
                        
                        VStack(alignment: .leading) {
                            Text(series.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("View Series Episodes ➔")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
}
