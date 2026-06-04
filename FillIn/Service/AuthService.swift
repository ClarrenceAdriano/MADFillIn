//
//  AuthService.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 04/06/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    var firebaseAuth: Auth { auth }
    
    func register(
        fullName: String,
        email: String,
        password: String,
        sports: [SportType: SkillLevel]
    ) async throws -> FillInUser {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid
        let newUser = FillInUser(
            uid: uid,
            fullName: fullName,
            email: email,
            sports: sports,
            createdAt: Date(),
            role: .user
        )
        try await db.collection("users").document(uid).setData(newUser.toDictionary())
        return newUser
    }

    func login(email: String, password: String) async throws -> String {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func logout() throws {
        try auth.signOut()
    }

    func fetchUser(uid: String) async throws -> FillInUser? {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let data = doc.data() else { return nil }

        let fullName = data["fullName"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        let sportsRaw = data["sports"] as? [String: String] ?? [:]
        let timestamp = data["createdAt"] as? Timestamp
        let roleRaw = data["role"] as? String ?? "user"
        let role = UserRole(rawValue: roleRaw) ?? .user

        var sports: [SportType: SkillLevel] = [:]
        for (sportKey, levelValue) in sportsRaw {
            if let sport = SportType(rawValue: sportKey),
               let level = SkillLevel(rawValue: levelValue) {
                sports[sport] = level
            }
        }

        return FillInUser(
            uid: uid,
            fullName: fullName,
            email: email,
            sports: sports,
            createdAt: timestamp?.dateValue() ?? Date(),
            role: role
        )
    }
}
