import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isLoggedIn: Bool
   
    @State var inputEmail: String = ""
    @State var inputPassword: String = ""
    @State private var isPresented: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        VStack(alignment: .center) {
            Text("SwiftUI App")
                .font(.system(size: 48, weight: .heavy))

            VStack(spacing: 24) {
                // ここにcontentTypeを追加
                TextField("Mail address", text: $inputEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 280)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)  // ★ここを追加
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $inputPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 280)
            }
            .frame(height: 200)

            Button(action: {
                if !isValidEmail(inputEmail) {
                    alertMessage = "メールアドレスの形式が正しくありません"
                    showAlert = true
                    return
                }
                Login(email: inputEmail, password: inputPassword) { success in
                    if success {
                        print("ログイン成功")
                        isLoggedIn = true
                    } else {
                        print("ログイン失敗")
                        alertMessage = "ログインに失敗しました"
                        showAlert = true
                    }
                }
            }) {
                Text("Login")
                    .fontWeight(.medium)
                    .frame(minWidth: 160)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }

            Button(action: {
                isPresented = true
            }) {
                Text("新規登録")
                    .fontWeight(.medium)
                    .frame(minWidth: 160)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .fullScreenCover(isPresented: $isPresented) {
                RegisterView(isLoggedIn: $isLoggedIn)
            }
        }
        .contentShape(Rectangle()) // タップ可能な領域を拡張
        .onTapGesture {
            // キーボードを閉じる
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    // メールアドレスバリデーション関数
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    func Login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let _ = authResult?.user {
                completion(true)  // 成功時
            } else {
                completion(false) // 失敗時
            }
        }
    }
}
