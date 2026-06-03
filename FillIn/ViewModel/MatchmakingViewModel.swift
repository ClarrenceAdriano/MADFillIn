//
//  MatchmakingViewModel.swift
//  FillIn
//
//  Created by Shatrya Christiano on 03/06/26.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class MatchmakingViewModel: ObservableObject {
    @Published var openSessions: [Booking] = []
    @Published var isLoading = false
    @Published var joinSuccess = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let db = Firestore.firestore()

    func fetchOpenSessions(sport: SportType? = nil) async {
        isLoading = true
        do {
            var query: Query = db.collection("bookings")
                .whereField("isMatchmaking", isEqualTo: true)
                .whereField("status", isEqualTo: BookingStatus.confirmed.rawValue)

            if let sport = sport {
                query = query.whereField("sport", isEqualTo: sport.rawValue)
            }

            let snapshot = try await query.getDocuments()
            let uid = Auth.auth().currentUser?.uid ?? ""

            openSessions = snapshot.documents
                .compactMap { Booking.fromDictionary($0.data(), id: $0.documentID) }
                .filter { booking in
                    booking.playerIds.count < booking.maxPlayers &&
                    !booking.playerIds.contains(uid) &&
                    booking.date >= Date()
                }
                .sorted { $0.date < $1.date }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func joinSession(_ booking: Booking, user: FillInUser) async {
        isLoading = true
        let newPlayerIds = booking.playerIds + [user.uid]
        let newPlayerNames = booking.playerNames + [user.fullName]
        let newSplitAmount = booking.totalPrice / newPlayerIds.count

        do {
            try await db.collection("bookings").document(booking.id).updateData([
                "playerIds": newPlayerIds,
                "playerNames": newPlayerNames,
                "splitAmount": newSplitAmount
            ])
            joinSuccess = true
            await fetchOpenSessions()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}
