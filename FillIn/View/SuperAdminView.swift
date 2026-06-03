//
//  SuperAdminView.swift
//  FillIn
//
//  Created by Dylan on 03/06/26.
//

import SwiftUI

struct SuperAdminView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var adminVM = SuperAdminViewModel()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var roleFilter: UserRole? = nil

    var filteredUsers: [FillInUser] {
        var list = adminVM.allUsers
        if let role = roleFilter { list = list.filter { $0.role == role } }
        if !searchText.isEmpty {
            list = list.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Super Admin")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("Logged in as \(authVM.currentUser?.fullName ?? "")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        Button {
                            authVM.logout()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red.opacity(0.8))
                                .padding(10)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }

                    HStack(spacing: 12) {
                        AdminStatCard(label: "Users", value: "\(adminVM.userCount)", icon: "person.fill", color: "3B82F6")
                        AdminStatCard(label: "Keepers", value: "\(adminVM.keeperCount)", icon: "building.2.fill", color: "10B981")
                        AdminStatCard(label: "Admins", value: "\(adminVM.adminCount)", icon: "shield.fill", color: "F59E0B")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.4))
                    TextField("Search by name or email...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterPill(label: "All", isSelected: roleFilter == nil) { roleFilter = nil }
                        FilterPill(label: "Users", isSelected: roleFilter == .user) { roleFilter = .user }
                        FilterPill(label: "Field Keepers", isSelected: roleFilter == .fieldKeeper) { roleFilter = .fieldKeeper }
                        FilterPill(label: "Admins", isSelected: roleFilter == .superAdmin) { roleFilter = .superAdmin }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)

                if adminVM.isLoading {
                    Spacer()
                    ProgressView().tint(Color(hex: "3B82F6"))
                    Spacer()
                } else if filteredUsers.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No users found")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredUsers, id: \.uid) { user in
                                AdminUserCard(
                                    user: user,
                                    currentAdminUid: authVM.currentUser?.uid ?? "",
                                    onChangeRole: { newRole in
                                        Task { await adminVM.changeRole(uid: user.uid, to: newRole) }
                                    },
                                    onDelete: {
                                        Task { await adminVM.deleteUser(uid: user.uid) }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .task { await adminVM.fetchAllUsers() }
        .alert("Error", isPresented: $adminVM.showError) {
            Button("OK") { adminVM.showError = false }
        } message: { Text(adminVM.errorMessage) }
        .alert("Success ✅", isPresented: $adminVM.showSuccess) {
            Button("OK") { adminVM.showSuccess = false }
        } message: { Text(adminVM.successMessage) }
    }
}

struct AdminStatCard: View {
    var label: String
    var value: String
    var icon: String
    var color: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: color).opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: color).opacity(0.2), lineWidth: 1)
        )
    }
}

struct AdminUserCard: View {
    var user: FillInUser
    var currentAdminUid: String
    var onChangeRole: (UserRole) -> Void
    var onDelete: () -> Void

    @State private var showRolePicker = false
    @State private var showDeleteConfirm = false

    var roleColor: Color {
        switch user.role {
        case .superAdmin: return Color(hex: "F59E0B")
        case .fieldKeeper: return Color(hex: "10B981")
        case .user: return Color(hex: "3B82F6")
        }
    }

    var roleIcon: String {
        switch user.role {
        case .superAdmin: return "shield.fill"
        case .fieldKeeper: return "building.2.fill"
        case .user: return "person.fill"
        }
    }

    var isSelf: Bool { user.uid == currentAdminUid }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(roleColor.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Text(user.fullName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(roleColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(user.fullName)
                            .font(.headline)
                            .foregroundColor(.white)
                        if isSelf {
                            Text("(You)")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: roleIcon)
                        .font(.caption2)
                    Text(user.role.rawValue)
                        .font(.caption.bold())
                }
                .foregroundColor(roleColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(roleColor.opacity(0.12))
                .cornerRadius(20)
            }

            if !user.sports.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(user.sports.keys), id: \.self) { sport in
                            Text("\(sport.rawValue) · \(user.sports[sport]?.rawValue ?? "")")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.07))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            if !isSelf {
                HStack(spacing: 10) {
                    Button {
                        showRolePicker = true
                    } label: {
                        Label("Change Role", systemImage: "arrow.left.arrow.right")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                    }

                    Spacer()

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(roleColor.opacity(0.15), lineWidth: 1)
        )
        .confirmationDialog("Change Role for \(user.fullName)", isPresented: $showRolePicker) {
            Button("User") { onChangeRole(.user) }
            Button("Field Keeper") { onChangeRole(.fieldKeeper) }
            Button("Super Admin") { onChangeRole(.superAdmin) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Remove \(user.fullName)?", isPresented: $showDeleteConfirm) {
            Button("Remove from Firestore", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This only removes the Firestore record, not the Firebase Auth account.")
        }
    }
}