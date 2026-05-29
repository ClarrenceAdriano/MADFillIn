//
//  FillInApp.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 28/05/26.
//

import SwiftUI
import Firebase

@main
struct FillInApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
