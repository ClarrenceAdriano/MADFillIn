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

    private let service = BookingService()

    func fetchMyBookings() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        do {
            myBookings = try await service.fetchMyBookings(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func fetchAvailableSlots(fieldId: String, date: Date, openHour: Int, closeHour: Int) async {
        do {
            availableSlots = try await service.fetchAvailableSlots(
                fieldId: fieldId,
                date: date,
                openHour: openHour,
                closeHour: closeHour
            )
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
            try await service.createBooking(booking)
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
            try await service.cancelBooking(id: booking.id)
            await fetchMyBookings()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
