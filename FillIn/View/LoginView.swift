//
//  LoginView.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 28/05/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "0F172A"), Color(hex: "1E3A5F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "3B82F6").opacity(0.2))
                                .frame(width: 90, height: 90)
                            Image(systemName: "figure.run")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color(hex: "3B82F6"))
                        }
                        
                        Text("Fill In")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Find your game. Book your court.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        FillInTextField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            isSecure: false
                        )
                        
                        FillInTextField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        Task { await authVM.login(email: email, password: password) }
                    } label: {
                        ZStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Log In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "3B82F6"))
                        .cornerRadius(16)
                    }
                    .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 24)
                    
                    Button {
                        showRegister = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.white.opacity(0.6))
                            Text("Register")
                                .foregroundColor(Color(hex: "3B82F6"))
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                    }
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(authVM)
            }
            .alert("Login Failed", isPresented: $authVM.showError) {
                Button("OK") { authVM.showError = false }
            } message: {
                Text(authVM.errorMessage)
            }
        }
    }
}

struct FillInTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "3B82F6"))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview{
    LoginView()
        .environmentObject(AuthViewModel())
}
