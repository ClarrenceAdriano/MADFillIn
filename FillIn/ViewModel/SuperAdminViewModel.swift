//
//  SuperAdminViewModel.swift
//  FillIn
//
//  Created by Dylan on 03/06/26.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class SuperAdminViewModel: ObservableObject {
    @Published var allUsers: [FillInUser] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var successMessage = ""
    @Published var showSuccess = false

    private let db = Firestore.firestore()

    func fetchAllUsers() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("users").getDocuments()
            allUsers = snapshot.documents.compactMap { doc -> FillInUser? in
                let data = doc.data()
                let roleRaw = data["role"] as? String ?? "user"
                let role = UserRole(rawValue: roleRaw) ?? .user
                let sportsRaw = data["sports"] as? [String: String] ?? [:]
                let timestamp = data["createdAt"] as? Timestamp

                var sports: [SportType: SkillLevel] = [:]
                for (k, v) in sportsRaw {
                    if let sport = SportType(rawValue: k), let level = SkillLevel(rawValue: v) {
                        sports[sport] = level
                    }
                }

                return FillInUser(
                    uid: data["uid"] as? String ?? doc.documentID,
                    fullName: data["fullName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    sports: sports,
                    createdAt: timestamp?.dateValue() ?? Date(),
                    role: role
                )
            }
            .sorted { $0.fullName < $1.fullName }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func changeRole(uid: String, to role: UserRole) async {
        do {
            try await db.collection("users").document(uid).updateData([
                "role": role.rawValue
            ])
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
            try await db.collection("users").document(uid).delete()
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
