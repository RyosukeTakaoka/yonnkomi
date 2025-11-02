import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var isLoggedIn = false
    @State private var isCheckingAuth = true
    @State private var authStateHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if isCheckingAuth {
                // 認証状態をチェック中
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if isLoggedIn {
                CustomTabView(isLoggedIn: $isLoggedIn)
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            setupAuthStateListener()
        }
        .onDisappear {
            removeAuthStateListener()
        }
    }

    private func setupAuthStateListener() {
        // 既にリスナーが設定されている場合はスキップ
        guard authStateHandle == nil else { return }

        // Firebase Auth の状態を監視
        authStateHandle = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isLoggedIn = user != nil
                self.isCheckingAuth = false
            }
        }
    }

    private func removeAuthStateListener() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

