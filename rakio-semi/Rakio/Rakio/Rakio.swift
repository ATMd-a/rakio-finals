//
//  Test3App.swift
//  Test3
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI
import Firebase

@main
struct Rakio: App {
    
    
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//class AppDelegate: NSObject, UIApplicationDelegate {
//  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//
//    return true
//  }
//}


//notes: create a PDF to text file

