//
//  TabView.swift
//  yonnkomi
//
//  Created by Ryosuke Takaoka on 2025/07/20.
//

import SwiftUI

struct CustomTabView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView()
                .tabItem { Label("Home", systemImage: "house.circle") }
                .tag(1)

            NavigationStack { // CreateViewだけナビバー表示
                CreateView()
            }
            .tabItem { Label("Create", systemImage: "pencil.circle") }
            .tag(2)

            UserView(isLoggedIn: $isLoggedIn)
                .tabItem { Label("User", systemImage: "person.circle") }
                .tag(3)
        }
    }
}

#Preview {
    CustomTabView(isLoggedIn: .constant(true))
}
