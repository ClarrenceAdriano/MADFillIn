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
    @Published var bookedHours: [Int] = []
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
            let slots = try await service.fetchAvailableSlots(
                fieldId: fieldId,
                date: date,
                openHour: openHour,
                closeHour: closeHour
            )
            let booked = try await service.fetchBookedHours(fieldId: fieldId, date: date)
            availableSlots = slots
            bookedHours = booked
        } catch {
            // On error, show all slots as available (fallback) but log the error
            print("[BookingVM] fetchAvailableSlots error: \(error)")
            availableSlots = Array(openHour..<closeHour)
            bookedHours = []
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

        // Server-side conflict check — prevent double-booking
        do {
            let currentlyBooked = try await service.fetchBookedHours(fieldId: field.id, date: date)
            let selectedHours = Array(startHour..<endHour)
            if selectedHours.contains(where: { currentlyBooked.contains($0) }) {
                errorMessage = "Jam yang kamu pilih sudah dibooking. Silakan pilih jam lain."
                showError = true
                await fetchAvailableSlots(
                    fieldId: field.id,
                    date: date,
                    openHour: field.openHour,
                    closeHour: field.closeHour
                )
                isLoading = false
                return
            }
        } catch {
            // If the conflict check itself fails, block the booking to be safe
            errorMessage = "Tidak dapat memverifikasi ketersediaan jam. Coba lagi."
            showError = true
            isLoading = false
            return
        }

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
