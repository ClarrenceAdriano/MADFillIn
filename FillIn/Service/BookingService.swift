//
//  BookingService.swift
//  FillIn
//
//  Created by Dylan on 04/06/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class BookingService {
    private let db = Firestore.firestore()

    func fetchMyBookings(uid: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("playerIds", arrayContains: uid)
            .getDocuments()

        return snapshot.documents
            .compactMap { Booking.fromDictionary($0.data(), id: $0.documentID) }
            .sorted { $0.date > $1.date }
    }

    func fetchAvailableSlots(
        fieldId: String,
        date: Date,
        openHour: Int,
        closeHour: Int
    ) async throws -> [Int] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let snapshot = try await db.collection("bookings")
            .whereField("fieldId", isEqualTo: fieldId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments()

        let bookedHours = snapshot.documents
            .compactMap { Booking.fromDictionary($0.data(), id: $0.documentID) }
            .flatMap { booking in (booking.startHour..<booking.endHour).map { $0 } }

        return (openHour..<closeHour).filter { !bookedHours.contains($0) }
    }

    func createBooking(_ booking: Booking) async throws {
        try await db.collection("bookings")
            .document(booking.id)
            .setData(booking.toDictionary())
    }

    func cancelBooking(id: String) async throws {
        try await db.collection("bookings").document(id).updateData([
            "status": BookingStatus.cancelled.rawValue
        ])
    }
}
