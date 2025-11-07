import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import Cloudinary
import PKHUD

struct PostView: View {

    @State private var title: String = ""
    @State private var thumbnail: UIImage?
    @State private var canvasImages: [UIImage]
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPosting = false

    @State private var pickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    @Binding var shouldResetCanvas: Bool

    let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dw71feikq", secure: true))
    let db = Firestore.firestore()

    // Grid layout
    let columns = [
        GridItem(.flexible())
    ]

    init(canvasImages: [UIImage] = [], shouldResetCanvas: Binding<Bool>) {
        self._canvasImages = State(initialValue: canvasImages)
        self._shouldResetCanvas = shouldResetCanvas
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    // タイトル入力セクション
                    VStack(alignment: .leading, spacing: 12) {
                        Label("タイトル", systemImage: "text.alignleft")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("作品のタイトルを入力", text: $title)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // サムネイル選択セクション
                    VStack(alignment: .leading, spacing: 12) {
                        Label("サムネイル", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ZStack {
                            if let thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(16)
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 220)
                                    .overlay {
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 48))
                                                .foregroundColor(.secondary)
                                            Text("サムネイル画像を選択")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                                Label("選択", systemImage: "photo")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .padding(12)
                        }
                    }
                    .padding(.horizontal)

                    // キャンバス画像プレビューセクション
                    if !canvasImages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("4コマ漫画 (\(canvasImages.count)ページ)", systemImage: "rectangle.stack")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(canvasImages.indices, id: \.self) { index in
                                        VStack(spacing: 8) {
                                            Image(uiImage: canvasImages[index])
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 280, height: 280)
                                                .background(Color.white)
                                                .cornerRadius(12)
                                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                            Text("\(index + 1) / \(canvasImages.count)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // 投稿ボタン用のスペース
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.top)
            }

            // 固定された投稿ボタン
            VStack(spacing: 0) {
                Divider()

                Button(action: postButtonTapped) {
                    HStack(spacing: 12) {
                        if isPosting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("投稿中...")
                                .fontWeight(.semibold)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                            Text("投稿する")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isPosting)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.95))
            }
        }
        .navigationTitle("新規投稿")
        .navigationBarTitleDisplayMode(.large)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: pickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    thumbnail = uiImage
                }
            }
        }
    }
    
    func postButtonTapped() {
        guard !title.isEmpty else {
            alertMessage = "タイトルを入力してください。"
            showAlert = true
            return
        }
        
        guard let thumbnail else {
            alertMessage = "サムネイル画像を選択してください。"
            showAlert = true
            return
        }
        
        Task {
            isPosting = true
            
            let thumbnailURL = await uploadThumbnailImage(image: thumbnail)
            
            var canvasImageURLs: [String] = []
            for image in canvasImages {
                let url = await uploadThumbnailImage(image: image)
                if !url.isEmpty { canvasImageURLs.append(url) }
            }
            
            await savePostToFirestore(title: title, thumbnailURL: thumbnailURL, postImages: canvasImageURLs)
            
            isPosting = false
        }
    }
    
    func uploadThumbnailImage(image: UIImage) async -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return "" }
        
        let uploader = cloudinary.createUploader()
        
        return await withCheckedContinuation { continuation in
            let uniqueId = "thumbnail_\(UUID().uuidString)"
            let params = CLDUploadRequestParams().setPublicId(uniqueId)
            
            uploader.upload(data: imageData, uploadPreset: "manga_thumbnail", params: params, progress: nil) { result, error in
                if let secureUrl = result?.secureUrl {
                    continuation.resume(returning: secureUrl)
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    func savePostToFirestore(title: String, thumbnailURL: String, postImages: [String]) async {
        let uuid = UUID().uuidString
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let createdAt = formatter.string(from: Date())
        let currentUserID = Auth.auth().currentUser?.uid ?? ""

        // 投稿者のプロフィール画像URLを取得
        var userProfileImageUrl: String? = nil
        do {
            let userDoc = try await db.collection("users").document(currentUserID).getDocument()
            if let userData = userDoc.data() {
                userProfileImageUrl = userData["profileImageUrl"] as? String
                print("✅ User profile image URL retrieved: \(userProfileImageUrl ?? "nil")")
            }
        } catch {
            print("⚠️ Failed to fetch user profile image: \(error.localizedDescription)")
        }

        var postData: [String: Any] = [
            "id": uuid,
            "title": title,
            "userId": currentUserID,
            "postImages": postImages,
            "thumbnailPost": thumbnailURL,
            "createdAt": createdAt
        ]

        // プロフィール画像URLがあれば追加
        if let profileUrl = userProfileImageUrl {
            postData["userProfileImageUrl"] = profileUrl
        }

        do {
            try await db.collection("posts").document(uuid).setData(postData)
            alertMessage = "投稿できました！"
            showAlert = true

            // 投稿成功フラグを設定
            shouldResetCanvas = true

            // 画面を閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            alertMessage = "投稿に失敗しました。再試行してください。"
            showAlert = true
        }
    }
}
