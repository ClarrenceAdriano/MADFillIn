//
//  HomeView.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 28/05/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("Welcome, \(authVM.currentUser?.fullName ?? "Player")! 👋")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Button("Log Out") {
                    authVM.logout()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.top, 20)
            }
        }
    }
}

#Preview{
    HomeView()
        .environmentObject(AuthViewModel())
}
