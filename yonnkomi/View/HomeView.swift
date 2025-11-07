import SwiftUI
import Firebase
import FirebaseAuth
//ホーム画面、漫画のサムネが並んでいる画面
struct HomeView: View {
    @State private var posts: [Post] = []
    @State private var isLoading: Bool = false
    @State private var selectedPost: Post?
    @State private var likedPostIds: Set<String> = []
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
                                toggleLike(for: post)
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
                fetchLikedPosts()
            }
            .refreshable {
                fetchPosts()
                fetchLikedPosts()
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
                let userProfileImageUrl = data["userProfileImageUrl"] as? String
                let postImages = data["postImages"] as? [String] ?? []
                let thumbnailPost = data["thumbnailPost"] as? String ?? "No Thumbnail"
                let createdAt = data["createdAt"] as? String ?? "No Date"

                // いいね状態を反映
                let isLiked = likedPostIds.contains(id)
                return Post(id: id, title: title, userId: userId, userProfileImageUrl: userProfileImageUrl, postImages: postImages, thumbnailPost: thumbnailPost, createdAt: createdAt, isLiked: isLiked)
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

    private func fetchLikedPosts() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).collection("likes").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("❌ Error fetching likes: \(error.localizedDescription)")
                return
            }

            likedPostIds = Set(querySnapshot?.documents.compactMap { $0.documentID } ?? [])
            print("✅ Loaded \(likedPostIds.count) liked posts")

            // いいね状態を更新
            for index in posts.indices {
                posts[index].isLiked = likedPostIds.contains(posts[index].id)
            }
        }
    }

    private func toggleLike(for post: Post) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ User not logged in")
            return
        }

        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            withAnimation(.spring()) {
                posts[index].isLiked.toggle()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            let likeRef = db.collection("users").document(userId).collection("likes").document(post.id)

            if posts[index].isLiked {
                // いいねを追加
                likedPostIds.insert(post.id)
                var likeData: [String: Any] = [
                    "postId": post.id,
                    "title": post.title,
                    "thumbnailPost": post.thumbnailPost,
                    "userId": post.userId,
                    "postImages": post.postImages,
                    "createdAt": post.createdAt,
                    "likedAt": Timestamp(date: Date())
                ]

                // 投稿者のプロフィール画像URLがあれば追加
                if let profileUrl = post.userProfileImageUrl {
                    likeData["userProfileImageUrl"] = profileUrl
                }

                likeRef.setData(likeData) { error in
                    if let error = error {
                        print("❌ Error saving like: \(error.localizedDescription)")
                    } else {
                        print("✅ Like saved for post: \(post.title)")
                    }
                }
            } else {
                // いいねを削除
                likedPostIds.remove(post.id)
                likeRef.delete { error in
                    if let error = error {
                        print("❌ Error removing like: \(error.localizedDescription)")
                    } else {
                        print("✅ Like removed for post: \(post.title)")
                    }
                }
            }
        }
    }
}
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(isLoggedIn: .constant(true))
    }
}
