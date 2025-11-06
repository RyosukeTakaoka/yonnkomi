import SwiftUI
import Firebase
//ホーム画面、漫画のサムネが並んでいる画面
struct HomeView: View {
    @State private var posts: [Post] = []
    @State private var isLoading: Bool = false
    @State private var selectedPost: Post?
    let db = Firestore.firestore()
    let spacer: CGFloat = 8

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: spacer) {
                    ForEach(posts) { post in
                        PostItemView(
                            post: post,
                            spacer: spacer,
                            onLikeTapped: {
                                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                                    withAnimation(.spring()) {
                                        posts[index].isLiked.toggle()
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            },
                            onTap: {
                                selectedPost = post
                            }
                        )
                    }
                }
                .padding(.horizontal, spacer * 2)
            }
            .onAppear {
                fetchPosts()
            }
            .refreshable {
                fetchPosts()
            }
            .navigationDestination(item: $selectedPost) { post in
                MangaDetailView(post: post)
            }
        }
    }

    private func fetchPosts() {
        isLoading = true
        db.collection("posts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                isLoading = false
                return
            }

            posts = querySnapshot?.documents.compactMap { document -> Post? in
                let data = document.data()
                let id = data["id"] as? String ?? "defaultId"
                let title = data["title"] as? String ?? "No Title"
                let userId = data["userId"] as? String ?? "defaultUserId"
                let postImages = data["postImages"] as? [String] ?? []
                let thumbnailPost = data["thumbnailPost"] as? String ?? "No Thumbnail"
                let createdAt = data["createdAt"] as? String ?? "No Date"

                return Post(id: id, title: title, userId: userId, postImages: postImages, thumbnailPost: thumbnailPost, createdAt: createdAt, isLiked: false)
            } ?? []

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            posts.sort {
                guard let date1 = dateFormatter.date(from: $0.createdAt),
                      let date2 = dateFormatter.date(from: $1.createdAt) else { return false }
                return date1 > date2
            }
            isLoading = false
        }
    }
}
