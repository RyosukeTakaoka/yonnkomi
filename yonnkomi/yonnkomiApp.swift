//
//  yonnkomiApp.swift
//  yonnkomi
//
//  Created by Ryosuke Takaoka on 2025/07/20.
//

import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseCore
import Firebase

@main
struct yonnkomiApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    class AppDelegate:NSObject,UIApplicationDelegate{
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            FirebaseApp.configure()
            return true
        }
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
