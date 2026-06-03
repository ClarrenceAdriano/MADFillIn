//
//  BookingViewModel.swift
//  FillIn
//
//  Created by Dylan on 02/06/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class BookingViewModel: ObservableObject {
    @Published var myBookings: [Booking] = []
    @Published var availableSlots: [Int] = []
    @Published var isLoading = false
    @Published var bookingSuccess = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let db = Firestore.firestore()

    func fetchMyBookings() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        do {
            let snapshot = try await db.collection("bookings")
                .whereField("playerIds", arrayContains: uid)
                .getDocuments()
            myBookings = snapshot.documents.compactMap {
                Booking.fromDictionary($0.data(), id: $0.documentID)
            }.sorted { $0.date > $1.date }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func fetchAvailableSlots(fieldId: String, date: Date, openHour: Int, closeHour: Int) async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            let snapshot = try await db.collection("bookings")
                .whereField("fieldId", isEqualTo: fieldId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()

            let bookedHours = snapshot.documents.compactMap {
                Booking.fromDictionary($0.data(), id: $0.documentID)
            }.flatMap { booking in
                (booking.startHour..<booking.endHour).map { $0 }
            }

            availableSlots = (openHour..<closeHour).filter { !bookedHours.contains($0) }
        } catch {
            availableSlots = Array(openHour..<closeHour)
        }
    }

    func createBooking(
        field: Field,
        date: Date,
        startHour: Int,
        endHour: Int,
        isMatchmaking: Bool,
        maxPlayers: Int,
        currentUser: FillInUser
    ) async {
        isLoading = true
        let duration = endHour - startHour
        let totalPrice = field.pricePerHour * duration
        let bookingId = UUID().uuidString

        let booking = Booking(
            id: bookingId,
            fieldId: field.id,
            fieldName: field.name,
            userId: currentUser.uid,
            userName: currentUser.fullName,
            date: date,
            startHour: startHour,
            endHour: endHour,
            totalPrice: totalPrice,
            status: .confirmed,
            playerIds: [currentUser.uid],
            playerNames: [currentUser.fullName],
            splitAmount: totalPrice,
            isMatchmaking: isMatchmaking,
            maxPlayers: maxPlayers,
            sport: field.sport
        )

        do {
            try await db.collection("bookings").document(bookingId).setData(booking.toDictionary())
            bookingSuccess = true
            await fetchMyBookings()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func cancelBooking(_ booking: Booking) async {
        do {
            try await db.collection("bookings").document(booking.id).updateData([
                "status": BookingStatus.cancelled.rawValue
            ])
            await fetchMyBookings()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
