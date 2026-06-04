//
//  MatchmakingService.swift
//  FillIn
//
//  Created by Shatrya Christiano on 04/06/26.
//

import Foundation
import FirebaseFirestore

class MatchmakingService {
    private let db = Firestore.firestore()

    func fetchOpenSessions(sport: SportType? = nil, excludingUid uid: String) async throws -> [Booking] {
        var query: Query = db.collection("bookings")
            .whereField("isMatchmaking", isEqualTo: true)
            .whereField("status", isEqualTo: BookingStatus.confirmed.rawValue)

        if let sport = sport {
            query = query.whereField("sport", isEqualTo: sport.rawValue)
        }

        let snapshot = try await query.getDocuments()

        return snapshot.documents
            .compactMap { Booking.fromDictionary($0.data(), id: $0.documentID) }
            .filter { booking in
                booking.playerIds.count < booking.maxPlayers &&
                !booking.playerIds.contains(uid) &&
                booking.date >= Date()
            }
            .sorted { $0.date < $1.date }
    }

    func joinSession(_ booking: Booking, user: FillInUser) async throws {
        let newPlayerIds = booking.playerIds + [user.uid]
        let newPlayerNames = booking.playerNames + [user.fullName]
        let newSplitAmount = booking.totalPrice / newPlayerIds.count

        try await db.collection("bookings").document(booking.id).updateData([
            "playerIds": newPlayerIds,
            "playerNames": newPlayerNames,
            "splitAmount": newSplitAmount
        ])
    }
}
