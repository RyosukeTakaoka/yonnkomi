import SwiftUI
import FirebaseAuth
//ユーザー画面
struct SavedItem {
    let id = UUID()
    let title: String
    let episode: String
    let savedDate: Date
    let thumbnailName: String
    let isRead: Bool
    let progress: Double // 0.0 to 1.0
}

struct UserView: View {
    @Binding var isLoggedIn: Bool

    @State private var savedItems: [SavedItem] = [
        SavedItem(title: "地縛少年花子くん", episode: "第1話", savedDate: Date().addingTimeInterval(-86400), thumbnailName: "hanako1", isRead: false, progress: 0.3),
        SavedItem(title: "地縛少年花子くん", episode: "第2話", savedDate: Date().addingTimeInterval(-172800), thumbnailName: "hanako2", isRead: true, progress: 1.0),
        SavedItem(title: "地縛少年花子くん", episode: "第3話", savedDate: Date().addingTimeInterval(-259200), thumbnailName: "hanako3", isRead: false, progress: 0.0),
        SavedItem(title: "地縛少年花子くん", episode: "第4話", savedDate: Date().addingTimeInterval(-345600), thumbnailName: "hanako4", isRead: false, progress: 0.7),
        SavedItem(title: "地縛少年花子くん", episode: "第5話", savedDate: Date().addingTimeInterval(-432000), thumbnailName: "hanako5", isRead: true, progress: 1.0)
    ]

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
        NavigationView {
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
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                // Profile icon
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("たかおか")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("231321@gagdafdfa")
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
                title: item.title,
                episode: item.episode,
                savedDate: item.savedDate,
                thumbnailName: item.thumbnailName,
                isRead: !item.isRead,
                progress: item.progress
            )
        }
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
            AsyncImage(url: URL(string: "https://via.placeholder.com/60x80")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray4))
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(.secondary)
                    )
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
