import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import Cloudinary
import PKHUD

struct PostView: View {
    
    @State private var title: String = ""
    @State private var thumbnail: UIImage?
    @State private var canvasImages: [UIImage] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPosting = false
    
    @State private var pickerItem: PhotosPickerItem?
    
    let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dw71feikq", secure: true))
    let db = Firestore.firestore()
    
    // Grid layout
    let columns = [
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("タイトルを入力", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .cornerRadius(8)
                    }
                    
                    PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                        Text("サムネイル画像を選択")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(canvasImages.indices, id: \.self) { index in
                            Image(uiImage: canvasImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: postButtonTapped) {
                        if isPosting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                        } else {
                            Text("投稿する")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("新規投稿")
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
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
        
        let postData: [String: Any] = [
            "id": uuid,
            "title": title,
            "userId": currentUserID,
            "postImages": postImages,
            "thumbnailPost": thumbnailURL,
            "createdAt": createdAt
        ]
        
        do {
            try await db.collection("posts").document(uuid).setData(postData)
//            alertMessage = "投稿できました！"
//            showAlert = true
//            title = ""
//            thumbnail = nil
            canvasImages.removeAll()
        } catch {
//            alertMessage = "投稿に失敗しました。再試行してください。"
            showAlert = true
        }
    }
}
