//
//  AuthViewModel.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 28/05/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

enum SkillLevel: String, CaseIterable, Codable {
    case beginner = "Pemula"
    case intermediate = "Menengah"
    case pro = "Pro"
}

enum SportType: String, CaseIterable, Codable {
    case basketball = "Basketball"
    case football = "Football"
    case badminton = "Badminton"
    case tennis = "Tennis"
    case volleyball = "Volleyball"
}

struct FillInUser: Codable {
    var uid: String
    var fullName: String
    var email: String
    var sports: [SportType: SkillLevel]
    var createdAt: Date
    var role: UserRole

    func toDictionary() -> [String: Any] {
        var sportsDict: [String: String] = [:]
        for (sport, level) in sports {
            sportsDict[sport.rawValue] = level.rawValue
        }
        return [
            "uid": uid,
            "fullName": fullName,
            "email": email,
            "sports": sportsDict,
            "createdAt": Timestamp(date: createdAt),
            "role": role.rawValue
        ]
    }
}

@MainActor
class AuthViewModel: ObservableObject {

    @Published var currentUser: FillInUser? = nil
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false

    private let service = AuthService()

    init() {
        service.firebaseAuth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                Task { await self?.fetchUser(uid: user.uid) }
            } else {
                self?.currentUser = nil
                self?.isLoggedIn = false
            }
        }
    }

    func register(fullName: String, email: String, password: String, sports: [SportType: SkillLevel]) async {
        isLoading = true
        errorMessage = ""
        do {
            let newUser = try await service.register(
                fullName: fullName,
                email: email,
                password: password,
                sports: sports
            )
            self.currentUser = newUser
            self.isLoggedIn = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let uid = try await service.login(email: email, password: password)
            await fetchUser(uid: uid)
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
        isLoading = false
    }

    func logout() {
        try? service.logout()
        currentUser = nil
        isLoggedIn = false
    }

    func fetchUser(uid: String) async {
        do {
            self.currentUser = try await service.fetchUser(uid: uid)
            self.isLoggedIn = true
        } catch {
            print("Error fetching user: \(error)")
        }
    }
}
