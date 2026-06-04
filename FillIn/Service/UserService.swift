//
//  UserService.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 04/06/26.
//

import Foundation
import FirebaseFirestore

class UserService {
    private let db = Firestore.firestore()

    func fetchAllUsers() async throws -> [FillInUser] {
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents.compactMap { doc -> FillInUser? in
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
    }

    func changeRole(uid: String, to role: UserRole) async throws {
        try await db.collection("users").document(uid).updateData([
            "role": role.rawValue
        ])
    }

    func deleteUser(uid: String) async throws {
        try await db.collection("users").document(uid).delete()
    }
}
