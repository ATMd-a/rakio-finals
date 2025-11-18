import SwiftUI

struct ChapterDetailView: View {
    @ObservedObject var viewModel: NovelDetailViewModel
    let chapters: [Chapter]
    let currentIndex: Int

    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 1
    @State private var showControls: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // MARK: - Background
                Color.rakioBackground.ignoresSafeArea()

                // MARK: - Scrollable Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text(currentChapter.title)
                            .font(.custom("Poppins", size: 26))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)

                        // Chapter text
                        Text(currentChapter.content)
                            .font(.custom("Poppins", size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 100)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: ContentHeightKey.self,
                                                    value: geo.size.height)
                                }
                            )
                    }
                    .padding(.horizontal)
                    .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
                    .background(
                        GeometryReader { geoScroll in
                            Color.clear
                                .onChange(of: geoScroll.frame(in: .global).minY) { oldY, newY in
                                    scrollOffset = -newY
                                    checkIfReachedBottom(
                                        scrollHeight: contentHeight,
                                        viewHeight: geometry.size.height
                                    )
                                }
                        }
                    )
                }
                .gesture(
                    TapGesture().onEnded {
                        withAnimation(.easeInOut) { showControls.toggle() }
                    }
                )

                // MARK: - Bottom Progress Bar
                if showControls {
                    VStack(spacing: 0) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "1C1917"))
                                .frame(height: 4)
                                .cornerRadius(2)

                            Rectangle()
                                .fill(Color.rakioPrimary)
                                .frame(width: geometry.size.width * progress, height: 4)
                                .cornerRadius(2)
                                .animation(.easeInOut(duration: 0.25), value: progress)
                        }
                        .padding(.horizontal, geometry.size.width * 0.05)
                        .padding(.top, 8)
                    }
                    .background(
                        Rectangle()
                            .fill(Color.rakioBackground)
                            .shadow(color: .black.opacity(0.4), radius: 8, y: -4)
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(currentChapter.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { EmptyView() }
            }
            .id(currentIndex)
        }
    }

    // MARK: - Helpers
    private var currentChapter: Chapter {
        chapters[currentIndex]
    }

    private var progress: CGFloat {
        let scrollableHeight = max(contentHeight - UIScreen.main.bounds.height, 1)
        return min(max(scrollOffset / scrollableHeight, 0), 1)
    }

    private func checkIfReachedBottom(scrollHeight: CGFloat, viewHeight: CGFloat) {
        // When within 50 pts of bottom, go to next chapter
        if scrollOffset + viewHeight >= scrollHeight - 50 {
            if viewModel.canGoNext {
                viewModel.navigateChapter(direction: .next)
            }
        }
    }
}

// MARK: - ContentHeightKey
struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
