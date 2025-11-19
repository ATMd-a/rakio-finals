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
