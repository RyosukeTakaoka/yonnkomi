import SwiftUI

struct RootView: View {
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationStack {
            if isLoggedIn {
                CustomTabView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}

