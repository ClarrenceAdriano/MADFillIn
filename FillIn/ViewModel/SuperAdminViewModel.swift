//
//  SuperAdminViewModel.swift
//  FillIn
//
//  Created by Dylan on 03/06/26.
//

import Foundation
import Combine

@MainActor
class SuperAdminViewModel: ObservableObject {
    @Published var allUsers: [FillInUser] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var successMessage = ""
    @Published var showSuccess = false

    private let service = UserService()

    func fetchAllUsers() async {
        isLoading = true
        do {
            allUsers = try await service.fetchAllUsers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func changeRole(uid: String, to role: UserRole) async {
        do {
            try await service.changeRole(uid: uid, to: role)
            successMessage = "Role updated to \(role.rawValue) successfully!"
            showSuccess = true
            await fetchAllUsers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func deleteUser(uid: String) async {
        do {
            try await service.deleteUser(uid: uid)
            successMessage = "User removed successfully."
            showSuccess = true
            await fetchAllUsers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    var userCount: Int { allUsers.filter { $0.role == .user }.count }
    var keeperCount: Int { allUsers.filter { $0.role == .fieldKeeper }.count }
    var adminCount: Int { allUsers.filter { $0.role == .superAdmin }.count }
}
