//
//  ProfileView.swift
//  FillIn
//
//  Created by Dylan on 03/06/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.2))
                        .frame(width: 100, height: 100)
                    Text(authVM.currentUser?.fullName.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(Color(hex: "3B82F6"))
                }

                VStack(spacing: 6) {
                    Text(authVM.currentUser?.fullName ?? "")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text(authVM.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }

                if let sports = authVM.currentUser?.sports, !sports.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("My Sports")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 24)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(sports.keys), id: \.self) { sport in
                                    VStack(spacing: 4) {
                                        Text(sport.rawValue)
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                        Text(sports[sport]?.rawValue ?? "")
                                            .font(.caption2)
                                            .foregroundColor(Color(hex: "3B82F6"))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                Spacer()

                Button {
                    authVM.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 100)
            }
        }
    }
}

