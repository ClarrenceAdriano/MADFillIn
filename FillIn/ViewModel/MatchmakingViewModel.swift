//
//  MatchmakingViewModel.swift
//  FillIn
//
//  Created by Shatrya Christiano on 03/06/26.
//


import Foundation
import FirebaseAuth
import Combine

@MainActor
class MatchmakingViewModel: ObservableObject {
    @Published var openSessions: [Booking] = []
    @Published var isLoading = false
    @Published var joinSuccess = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let service = MatchmakingService()

    func fetchOpenSessions(sport: SportType? = nil) async {
        isLoading = true
        let uid = Auth.auth().currentUser?.uid ?? ""
        do {
            openSessions = try await service.fetchOpenSessions(sport: sport, excludingUid: uid)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func joinSession(_ booking: Booking, user: FillInUser) async {
        isLoading = true
        do {
            try await service.joinSession(booking, user: user)
            joinSuccess = true
            await fetchOpenSessions()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}
