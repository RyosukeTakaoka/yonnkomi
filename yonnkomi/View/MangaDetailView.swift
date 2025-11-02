import SwiftUI

struct MangaDetailView: View {
    let post: Post
    @State private var currentPage: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            // メインコンテンツ - Y軸方向の連続スクロール
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // 1-4画面目: 4コマ漫画の各コマ
                        ForEach(0..<post.postImages.count, id: \.self) { index in
                            MangaPageView(
                                imageUrl: post.postImages[index],
                                pageTitle: "\(index + 1)コマ目"
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .background(
                                GeometryReader { pageGeometry in
                                    Color.clear
                                        .preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: pageGeometry.frame(in: .named("scroll")).minY
                                        )
                                }
                            )
                            .onAppear {
                                updateCurrentPage(index: index, geometry: geometry)
                            }
                        }

                        // 5画面目: サムネイル
                        MangaPageView(
                            imageUrl: post.thumbnailPost,
                            pageTitle: "サムネイル"
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background(
                            GeometryReader { pageGeometry in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: pageGeometry.frame(in: .named("scroll")).minY
                                    )
                            }
                        )
                        .onAppear {
                            updateCurrentPage(index: post.postImages.count, geometry: geometry)
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    updateCurrentPageFromScroll(offset: value, height: geometry.size.height)
                }
            }
            .ignoresSafeArea()

            // 上部のヘッダー
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text(post.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(pageIndicator)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)

                    Spacer()

                    // 右側のスペーサー（左右対称にするため）
                    Color.clear
                        .frame(width: 48, height: 48)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private var pageIndicator: String {
        if currentPage < post.postImages.count {
            return "\(currentPage + 1)/\(post.postImages.count)"
        } else {
            return "サムネイル"
        }
    }

    private func updateCurrentPage(index: Int, geometry: GeometryProxy) {
        currentPage = index
    }

    private func updateCurrentPageFromScroll(offset: CGFloat, height: CGFloat) {
        let page = Int(round(-offset / height))
        if page >= 0 && page <= post.postImages.count {
            currentPage = page
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MangaPageView: View {
    let imageUrl: String
    let pageTitle: String

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure:
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        Text("画像を読み込めませんでした")
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}
