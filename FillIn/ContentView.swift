//
//  ContentView.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 28/05/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    
    var body: some View {
        Group {
            if authVM.isLoggedIn {
                HomeView()
                    .environmentObject(authVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
        .animation(.easeInOut, value: authVM.isLoggedIn)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
