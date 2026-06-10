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

        // Query only by fieldId to avoid requiring a Firestore composite index.
        // Date filtering is done in-memory.
        let snapshot = try await db.collection("bookings")
            .whereField("fieldId", isEqualTo: fieldId)
            .getDocuments()

        let bookedHours = snapshot.documents
            .compactMap { Booking.fromDictionary($0.data(), id: $0.documentID) }
            .filter { booking in
                booking.status != .cancelled &&
                booking.date >= startOfDay &&
                booking.date < endOfDay
            }
            .flatMap { booking in (booking.startHour..<booking.endHour).map { $0 } }

        return (openHour..<closeHour).filter { !bookedHours.contains($0) }
    }

    func fetchBookedHours(
        fieldId: String,
        date: Date
    ) async throws -> [Int] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Query only by fieldId to avoid requiring a Firestore composite index.
        // Date filtering is done in-memory.
        let snapshot = try await db.collection("bookings")
            .whereField("fieldId", isEqualTo: fieldId)
            .getDocuments()

        return snapshot.documents
            .compactMap { Booking.fromDictionary($0.data(), id: $0.documentID) }
            .filter { booking in
                booking.status != .cancelled &&
                booking.date >= startOfDay &&
                booking.date < endOfDay
            }
            .flatMap { booking in (booking.startHour..<booking.endHour).map { $0 } }
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
