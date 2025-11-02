import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    
    @State var inputEmail: String = ""
    @State var inputPassword: String = ""
    @State private var isPresented: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // 生体認証ON/OFFと最後にログインしたメールを保存
    @AppStorage("biometricEnabled") private var biometricEnabled: Bool = false
    @AppStorage("lastEmail") private var lastEmail: String = ""
    
    var body: some View {
        
        VStack(alignment: .center) {
            Text("SwiftUI App")
                .font(.system(size: 48, weight: .heavy))
            
            VStack(spacing: 24) {
                TextField("Mail address", text: $inputEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 280)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $inputPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 280)
            }
            .frame(height: 200)
            
            Button(action: {
                loginWithEmail()
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
            
            if biometricEnabled {
                Button(action: {
                    authenticateWithBiometrics()
                }) {
                    Label("生体認証でログイン", systemImage: "faceid")
                        .fontWeight(.medium)
                        .frame(minWidth: 160)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
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
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            // 画面起動時に生体認証
            if biometricEnabled && !lastEmail.isEmpty {
                authenticateWithBiometrics()
            }
        }
        .contentShape(Rectangle()) // タップ可能な領域を拡張
        .onTapGesture {
            // キーボードを閉じる
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    
    // MARK: - メールログイン
    private func loginWithEmail() {
        if !isValidEmail(inputEmail) {
            alertMessage = "メールアドレスの形式が正しくありません"
            showAlert = true
            return
        }
        Auth.auth().signIn(withEmail: inputEmail, password: inputPassword) { authResult, error in
            if let _ = authResult?.user {
                isLoggedIn = true
                biometricEnabled = true
                lastEmail = inputEmail // 保存
            } else {
                alertMessage = error?.localizedDescription ?? "ログインに失敗しました"
                showAlert = true
            }
        }
    }
    
    // MARK: - 生体認証
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "アプリにログインするために認証してください"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // 生体認証成功 → Firebaseで最後にログインしたメールアドレスを再ログイン
                        if !lastEmail.isEmpty {
                            Auth.auth().fetchSignInMethods(forEmail: lastEmail) { methods, error in
                                if let _ = methods, error == nil {
                                    isLoggedIn = true
                                } else {
                                    alertMessage = "Firebase認証情報が見つかりません"
                                    showAlert = true
                                }
                            }
                        } else {
                            alertMessage = "メール情報が保存されていません"
                            showAlert = true
                        }
                    } else {
                        alertMessage = authenticationError?.localizedDescription ?? "生体認証に失敗しました"
                        showAlert = true
                    }
                }
            }
        } else {
            alertMessage = error?.localizedDescription ?? "このデバイスでは生体認証が使えません"
            showAlert = true
        }
    }
    
    // MARK: - メールバリデーション
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}
