import SwiftUI
import FirebaseAuth
import FirebaseFirestore
//ユーザー画面
struct SavedItem {
    let id = UUID()
    let postId: String // FirestoreのpostId
    let title: String
    let episode: String
    let savedDate: Date
    let thumbnailName: String
    let isRead: Bool
    let progress: Double // 0.0 to 1.0
    let userId: String // 投稿者ID
    let postImages: [String] // 4コマ漫画の画像URL配列
    let createdAt: String // 投稿日時
}

struct UserView: View {
    @Binding var isLoggedIn: Bool

    @State private var userName: String = "読み込み中..."
    @State private var userEmail: String = ""
    @State private var profileImageUrl: String? = nil

    @State private var savedItems: [SavedItem] = []
    @State private var selectedPost: Post? = nil

    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateDescending
    @State private var showingFilterSheet = false
    @State private var showLogoutAlert = false
    @State private var logoutErrorMessage = ""
    
    enum SortOption: String, CaseIterable {
        case dateDescending = "保存日時（新しい順）"
        case dateAscending = "保存日時（古い順）"
        case titleAscending = "作品名（あいうえお順）"
        case unreadFirst = "未読優先"
    }
    
    var filteredAndSortedItems: [SavedItem] {
        let filtered = savedItems.filter { item in
            searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText) || item.episode.localizedCaseInsensitiveContains(searchText)
        }
        
        switch sortOption {
        case .dateDescending:
            return filtered.sorted { $0.savedDate > $1.savedDate }
        case .dateAscending:
            return filtered.sorted { $0.savedDate < $1.savedDate }
        case .titleAscending:
            return filtered.sorted { $0.title < $1.title }
        case .unreadFirst:
            return filtered.sorted { !$0.isRead && $1.isRead }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with profile info
                headerSection
                
                // Search and filter section
                searchAndFilterSection
                
                // Content
                if filteredAndSortedItems.isEmpty {
                    emptyStateView
                } else {
                    savedItemsList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("ログアウトエラー", isPresented: $showLogoutAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(logoutErrorMessage)
            }
            .navigationDestination(item: $selectedPost) { post in
                MangaDetailView(post: post)
            }
        }
        .onAppear {
            fetchUserProfile()
            fetchLikedPosts()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                // Profile icon
                if let imageUrl = profileImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 50, height: 50)
                                .onAppear {
                                    print("🔄 Loading image from: \(url)")
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .onAppear {
                                    print("✅ Image loaded successfully")
                                }
                        case .failure(let error):
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                                .onAppear {
                                    print("❌ Image load failed: \(error)")
                                }
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .onAppear {
                            print("ℹ️ No profile image URL available, showing default icon")
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(userEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Logout button
                Button(action: {
                    handleLogout()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            // Stats
            HStack(spacing: 30) {
                StatView(title: "保存済み", value: "\(savedItems.count)")
                StatView(title: "読了", value: "\(savedItems.filter { $0.isRead }.count)")
                StatView(title: "未読", value: "\(savedItems.filter { !$0.isRead }.count)")
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 8) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("作品名やエピソードを検索", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(action: { showingFilterSheet = true }) {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // Sort indicator
            if sortOption != .dateDescending {
                HStack {
                    Text("並び順: \(sortOption.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var savedItemsList: some View {
        List {
            ForEach(filteredAndSortedItems, id: \.id) { item in
                SavedItemRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPost = convertToPost(from: item)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("削除", role: .destructive) {
                            deleteItem(item)
                        }
                        .tint(.red)

                        Button(item.isRead ? "未読にする" : "既読にする") {
                            toggleReadStatus(item)
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("保存した作品がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("気になる作品を保存すると\nここに表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var filterSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("並び替え")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        sortOption = option
                        showingFilterSheet = false
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完了") {
                showingFilterSheet = false
            })
        }
    }
    
    private func deleteItem(_ item: SavedItem) {
        savedItems.removeAll { $0.id == item.id }
    }
    
    private func toggleReadStatus(_ item: SavedItem) {
        if let index = savedItems.firstIndex(where: { $0.id == item.id }) {
            savedItems[index] = SavedItem(
                postId: item.postId,
                title: item.title,
                episode: item.episode,
                savedDate: item.savedDate,
                thumbnailName: item.thumbnailName,
                isRead: !item.isRead,
                progress: item.progress,
                userId: item.userId,
                postImages: item.postImages,
                createdAt: item.createdAt
            )
        }
    }

    private func fetchUserProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            print("⚠️ No current user")
            return
        }

        print("📥 Fetching user profile for: \(currentUser.uid)")

        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).getDocument { document, error in
            if let error = error {
                print("❌ Error fetching user profile: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                print("✅ User document found")
                print("📄 Document data: \(String(describing: data))")

                DispatchQueue.main.async {
                    self.userName = data?["name"] as? String ?? "ユーザー"
                    self.userEmail = data?["email"] as? String ?? currentUser.email ?? ""

                    if let imageUrl = data?["profileImageUrl"] as? String {
                        print("🖼️ Profile image URL found: \(imageUrl)")
                        self.profileImageUrl = imageUrl
                    } else {
                        print("⚠️ No profile image URL in document")
                        self.profileImageUrl = nil
                    }
                }
            } else {
                print("⚠️ User document does not exist")
                // Firestoreにデータがない場合はAuthから取得
                DispatchQueue.main.async {
                    self.userName = currentUser.displayName ?? "ユーザー"
                    self.userEmail = currentUser.email ?? ""
                }
            }
        }
    }

    private func fetchLikedPosts() {
        guard let currentUser = Auth.auth().currentUser else {
            print("⚠️ No current user")
            return
        }

        print("📥 Fetching liked posts for user: \(currentUser.uid)")

        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).collection("likes")
            .order(by: "likedAt", descending: true)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("❌ Error fetching liked posts: \(error.localizedDescription)")
                    return
                }

                let items = querySnapshot?.documents.compactMap { document -> SavedItem? in
                    let data = document.data()
                    let postId = data["postId"] as? String ?? document.documentID
                    let title = data["title"] as? String ?? "タイトルなし"
                    let thumbnailPost = data["thumbnailPost"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let postImages = data["postImages"] as? [String] ?? []
                    let createdAt = data["createdAt"] as? String ?? ""
                    let likedAt = (data["likedAt"] as? Timestamp)?.dateValue() ?? Date()

                    print("📚 Liked post: \(title), postImages count: \(postImages.count)")

                    return SavedItem(
                        postId: postId,
                        title: title,
                        episode: "投稿",
                        savedDate: likedAt,
                        thumbnailName: thumbnailPost,
                        isRead: false,
                        progress: 0.0,
                        userId: userId,
                        postImages: postImages,
                        createdAt: createdAt
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.savedItems = items
                    print("✅ Loaded \(items.count) liked posts")
                }
            }
    }

    private func convertToPost(from item: SavedItem) -> Post {
        return Post(
            id: item.postId,
            title: item.title,
            userId: item.userId,
            postImages: item.postImages,
            thumbnailPost: item.thumbnailName,
            createdAt: item.createdAt,
            isLiked: true // いいねした作品なので常にtrue
        )
    }

    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            // 生体認証の設定をクリア
            UserDefaults.standard.set(false, forKey: "biometricEnabled")
            UserDefaults.standard.set("", forKey: "lastEmail")
            // ログイン画面に戻る
            isLoggedIn = false
        } catch let error {
            logoutErrorMessage = error.localizedDescription
            showLogoutAlert = true
        }
    }
}

struct SavedItemRow: View {
    let item: SavedItem

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: URL(string: item.thumbnailName)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray4))
                        .overlay(
                            ProgressView()
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray4))
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray4))
                }
            }
            .frame(width: 60, height: 80)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title and episode
                Text(item.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(item.episode)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Progress bar
                if item.progress > 0 {
                    ProgressView(value: item.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .frame(height: 4)
                }
                
                // Saved date and status
                HStack {
                    Text(item.savedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if item.isRead {
                        Label("読了", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("未読", systemImage: "circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(isLoggedIn: .constant(true))
    }
}
