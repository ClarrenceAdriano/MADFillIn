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
            "createdAt": Timestamp(date: createdAt)
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
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                Task {
                    await self?.fetchUser(uid: user.uid)
                }
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
            let result = try await auth.createUser(withEmail: email, password: password)
            let uid = result.user.uid
            
            let newUser = FillInUser(
                uid: uid,
                fullName: fullName,
                email: email,
                sports: sports,
                createdAt: Date()
            )
            
            try await db.collection("users").document(uid).setData(newUser.toDictionary())
            
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
            let result = try await auth.signIn(withEmail: email, password: password)
            await fetchUser(uid: result.user.uid)
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
        
        isLoading = false
    }
    
    func logout() {
        try? auth.signOut()
        currentUser = nil
        isLoggedIn = false
    }
    
    func fetchUser(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            guard let data = doc.data() else { return }
            
            let fullName = data["fullName"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let sportsRaw = data["sports"] as? [String: String] ?? [:]
            let timestamp = data["createdAt"] as? Timestamp
            
            var sports: [SportType: SkillLevel] = [:]
            for (sportKey, levelValue) in sportsRaw {
                if let sport = SportType(rawValue: sportKey),
                   let level = SkillLevel(rawValue: levelValue) {
                    sports[sport] = level
                }
            }
            
            self.currentUser = FillInUser(
                uid: uid,
                fullName: fullName,
                email: email,
                sports: sports,
                createdAt: timestamp?.dateValue() ?? Date()
            )
            self.isLoggedIn = true
            
        } catch {
            print("Error fetching user: \(error)")
        }
    }
}

