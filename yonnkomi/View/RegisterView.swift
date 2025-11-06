import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore
import Cloudinary
//新規登録
struct RegisterView: View {
    @Binding var isLoggedIn: Bool

    @State var imputName: String = ""
    @State var inputEmail: String = ""
    @State var inputPassword: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var isPresented: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false

    // 画面遷移用のEnvironment変数
    @Environment(\.presentationMode) var presentationMode

    // Cloudinary設定
    // 1. https://cloudinary.com/ でアカウントを作成
    // 2. Dashboard > Account Details から "Cloud Name" を取得
    // 3. Settings > Upload > Upload presets で "unsigned" プリセットを作成
    // 4. 作成したプリセット名を下記に設定
    private let cloudinaryCloudName = "YOUR_CLOUD_NAME" // ← CloudinaryのCloud Nameを設定
    private let cloudinaryUploadPreset = "YOUR_UPLOAD_PRESET" // ← Upload Preset名を設定（unsigned推奨）
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 20)
                    
                    // タイトル
                    Text("SwiftUI App")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)
                    
                    // プロフィール画像選択部分
                    VStack(spacing: 12) {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            ZStack {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "person.fill.badge.plus")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.gray)
                                                Text("画像を選択")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        )
                                }
                            }
                        }
                        
                        Text("プロフィール画像")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // 入力フィールド
                    VStack(spacing: 16) {
                        CustomTextField(placeholder: "名前", text: $imputName)
                        CustomTextField(placeholder: "メールアドレス", text: $inputEmail)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("パスワード", text: $inputPassword)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .frame(maxWidth: 320)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // ボタン
                    VStack(spacing: 16) {
                        // 新規登録ボタン
                        Button(action: {
                            registerUser()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("登録中...")
                                } else {
                                    Text("新規登録")
                                }
                            }
                            .fontWeight(.medium)
                            .frame(maxWidth: 320)
                            .foregroundColor(.white)
                            .padding(16)
                            .background(isLoading ? Color.gray : Color.blue)
                            .cornerRadius(8)
                        }
                        .disabled(isLoading)
                        
                        // 戻るボタン
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("戻る")
                                .fontWeight(.medium)
                                .frame(maxWidth: 320)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.gray)
                                .cornerRadius(8)
                        }
                        .disabled(isLoading)
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 40)
            }
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    // 登録処理
    private func registerUser() {
        // バリデーション
        if imputName.isEmpty || inputEmail.isEmpty || inputPassword.isEmpty {
            alertTitle = "エラー"
            alertMessage = "すべての項目を入力してください。"
            showAlert = true
            return
        }

        if !isValidEmail(inputEmail) {
            alertTitle = "エラー"
            alertMessage = "メールアドレスの形式が正しくありません"
            showAlert = true
            return
        }

        if inputPassword.count < 6 {
            alertTitle = "エラー"
            alertMessage = "パスワードは6文字以上で入力してください"
            showAlert = true
            return
        }

        isLoading = true

        // FirebaseAuthでユーザー登録
        Auth.auth().createUser(withEmail: inputEmail, password: inputPassword) { authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertTitle = "エラー"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
                return
            }

            guard let user = authResult?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertTitle = "エラー"
                    self.alertMessage = "ユーザー登録に失敗しました"
                    self.showAlert = true
                }
                return
            }

            // プロフィール更新（表示名の設定）
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = self.imputName
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Display name update error: \(error.localizedDescription)")
                }
            }

            // 画像がある場合はアップロード
            if let image = self.selectedImage {
                self.uploadProfileImage(image: image, userId: user.uid) { imageUrl in
                    self.saveUserProfile(userId: user.uid, name: self.imputName, email: self.inputEmail, profileImageUrl: imageUrl)
                }
            } else {
                // 画像がない場合はそのまま保存
                self.saveUserProfile(userId: user.uid, name: self.imputName, email: self.inputEmail, profileImageUrl: nil)
            }
        }
    }

    // 画像をCloudinaryにアップロード
    private func uploadProfileImage(image: UIImage, userId: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to convert image to JPEG data")
            completion(nil)
            return
        }

        print("📤 Starting Cloudinary image upload for user: \(userId)")
        print("📦 Image data size: \(imageData.count) bytes")

        // Cloudinary設定
        let config = CLDConfiguration(cloudName: cloudinaryCloudName, secure: true)
        let cloudinary = CLDCloudinary(configuration: config)

        // アップロードパラメータ
        let params = CLDUploadRequestParams()
        params.setPublicId("profile_images/\(userId)") // ユーザーIDをファイル名として使用
        params.setFolder("profile_images") // フォルダを指定

        print("☁️ Uploading to Cloudinary...")

        // Cloudinaryにアップロード
        cloudinary.createUploader().upload(
            data: imageData,
            uploadPreset: cloudinaryUploadPreset,
            params: params,
            progress: { progress in
                print("📊 Upload progress: \(progress.fractionCompleted * 100)%")
            },
            completionHandler: { result, error in
                if let error = error {
                    print("❌ Cloudinary upload error: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                    completion(nil)
                    return
                }

                if let result = result, let secureUrl = result.secureUrl {
                    print("✅ Image uploaded successfully to Cloudinary")
                    print("✅ Image URL: \(secureUrl)")
                    completion(secureUrl)
                } else {
                    print("❌ Failed to get secure URL from Cloudinary result")
                    completion(nil)
                }
            }
        )
    }

    // ユーザー情報をFirestoreに保存
    private func saveUserProfile(userId: String, name: String, email: String, profileImageUrl: String?) {
        let db = Firestore.firestore()
        var userData: [String: Any] = [
            "name": name,
            "email": email,
            "createdAt": Timestamp(date: Date())
        ]

        if let imageUrl = profileImageUrl {
            print("💾 Saving profile with image URL: \(imageUrl)")
            userData["profileImageUrl"] = imageUrl
        } else {
            print("⚠️ No profile image URL to save")
        }

        print("💾 Saving user profile to Firestore for user: \(userId)")
        print("💾 User data: \(userData)")

        db.collection("users").document(userId).setData(userData) { error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    print("❌ Firestore save error: \(error.localizedDescription)")
                    self.alertTitle = "エラー"
                    self.alertMessage = "ユーザー情報の保存に失敗しました: \(error.localizedDescription)"
                    self.showAlert = true
                } else {
                    print("✅ User profile saved successfully to Firestore")
                    // 成功時
                    self.alertTitle = "成功"
                    self.alertMessage = "アカウントの登録が完了しました。"
                    self.showAlert = true
                    self.isLoggedIn = true

                    // アラート表示後に閉じる
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    
    // メールアドレスバリデーション関数
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}

// カスタムテキストフィールド
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .frame(maxWidth: 320)
            .disableAutocorrection(true)
    }
}

// 画像ピッカー
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

