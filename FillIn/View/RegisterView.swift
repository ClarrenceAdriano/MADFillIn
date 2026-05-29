//
//  RegisterView.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 28/05/26.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedSports: [SportType: SkillLevel] = [:]
    @State private var currentStep = 1
    @State private var passwordMismatch = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1E3A5F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Step \(currentStep) of 2")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.subheadline)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "3B82F6"))
                            .frame(
                                width: geo.size.width
                                    * (currentStep == 1 ? 0.5 : 1.0),
                                height: 4
                            )
                            .animation(.spring(), value: currentStep)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                currentStep == 1
                                    ? "Create Account" : "Your Sports"
                            )
                            .font(
                                .system(
                                    size: 28,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .foregroundColor(.white)
                            Text(
                                currentStep == 1
                                    ? "Fill in your details to get started"
                                    : "Select your sports and skill level"
                            )
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        if currentStep == 1 {
                            stepOneFields
                        } else {
                            stepTwoSports
                        }

                        Button {
                            if currentStep == 1 {
                                advanceToStep2()
                            } else {
                                Task { await submitRegistration() }
                            }
                        } label: {
                            ZStack {
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(
                                        currentStep == 1
                                            ? "Continue" : "Create Account"
                                    )
                                    .font(.headline)
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                step1Valid || currentStep == 2
                                    ? Color(hex: "3B82F6")
                                    : Color.white.opacity(0.2)
                            )
                            .cornerRadius(16)
                        }
                        .disabled(currentStep == 1 && !step1Valid)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Password Mismatch", isPresented: $passwordMismatch) {
            Button("OK") {}
        } message: {
            Text("Passwords do not match. Please try again.")
        }
        .alert("Registration Failed", isPresented: $authVM.showError) {
            Button("OK") { authVM.showError = false }
        } message: {
            Text(authVM.errorMessage)
        }
    }

    var stepOneFields: some View {
        VStack(spacing: 16) {
            FillInTextField(
                icon: "person",
                placeholder: "Full Name",
                text: $fullName,
                isSecure: false
            )
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
            FillInTextField(
                icon: "lock.fill",
                placeholder: "Confirm Password",
                text: $confirmPassword,
                isSecure: true
            )
        }
        .padding(.horizontal, 24)
    }

    var stepTwoSports: some View {
        VStack(spacing: 12) {
            ForEach(SportType.allCases, id: \.self) { sport in
                SportSelectionRow(
                    sport: sport,
                    selectedLevel: selectedSports[sport],
                    onSelect: { level in
                        if selectedSports[sport] == level {
                            selectedSports.removeValue(forKey: sport)
                        } else {
                            selectedSports[sport] = level
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 24)
    }

    var step1Valid: Bool {
        !fullName.isEmpty && !email.isEmpty && password.count >= 6
            && !confirmPassword.isEmpty
    }

    func advanceToStep2() {
        guard password == confirmPassword else {
            passwordMismatch = true
            return
        }
        withAnimation { currentStep = 2 }
    }

    func submitRegistration() async {
        await authVM.register(
            fullName: fullName,
            email: email,
            password: password,
            sports: selectedSports
        )
    }
}

struct SportSelectionRow: View {
    var sport: SportType
    var selectedLevel: SkillLevel?
    var onSelect: (SkillLevel) -> Void

    var sportIcon: String {
        switch sport {
        case .basketball: return "basketball"
        case .football: return "soccerball"
        case .badminton: return "figure.badminton"
        case .tennis: return "tennis.racket"
        case .volleyball: return "volleyball"
        }
    }

    var isSelected: Bool { selectedLevel != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: sportIcon)
                    .font(.title3)
                    .foregroundColor(
                        isSelected ? Color(hex: "3B82F6") : .white.opacity(0.5)
                    )
                    .frame(width: 28)

                Text(sport.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            }

            HStack(spacing: 8) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Button {
                        onSelect(level)
                    } label: {
                        Text(level.rawValue)
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedLevel == level
                                    ? Color(hex: "3B82F6")
                                    : Color.white.opacity(0.1)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isSelected
                        ? Color(hex: "3B82F6").opacity(0.1)
                        : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected
                                ? Color(hex: "3B82F6").opacity(0.5)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview{
    RegisterView()
        .environmentObject(AuthViewModel())
}
