//
//  FieldKeeperViewModel.swift
//  FillIn
//
//  Created by Shatrya Christiano on 03/06/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class FieldKeeperViewModel: ObservableObject {
    @Published var myFields: [Field] = []
    @Published var myBookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var successMessage = ""
    @Published var showSuccess = false
    
    private let db = Firestore.firestore()
    
    func fetchMyFields(keeperId: String) async {
        isLoading = true
        do {
            let snapshot = try await db.collection("fields")
                .whereField("ownerId", isEqualTo: keeperId)
                .getDocuments()
            myFields = snapshot.documents.compactMap {
                Field.fromDictionary($0.data(), id: $0.documentID)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    func fetchBookings(keeperId: String) async {
        do {
            let fieldIds = myFields.map { $0.id }
            guard !fieldIds.isEmpty else {
                myBookings = []
                return
            }
            
            let snapshot = try await db.collection("bookings")
                .whereField("fieldId", in: Array(fieldIds.prefix(10)))
                .getDocuments()
            
            myBookings = snapshot.documents
                .compactMap { Booking.fromDictionary($0.data(), id: $0.documentID) }
                .sorted { $0.date > $1.date }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func addField(
        name: String,
        address: String,
        sport: SportType,
        pricePerHour: Int,
        latitude: Double,
        longitude: Double,
        openHour: Int,
        closeHour: Int,
        keeperId: String
    ) async {
        isLoading = true
        let fieldId = UUID().uuidString
        let field = Field(
            id: fieldId,
            name: name,
            address: address,
            sport: sport,
            pricePerHour: pricePerHour,
            latitude: latitude,
            longitude: longitude,
            openHour: openHour,
            closeHour: closeHour,
            ownerId: keeperId,
            imageUrl: "",
            rating: 0.0,
            totalReviews: 0
        )
        do {
            try await db.collection("fields").document(fieldId).setData(field.toDictionary())
            successMessage = "Field \"\(name)\" added successfully!"
            showSuccess = true
            await fetchMyFields(keeperId: keeperId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    func updateField(_ field: Field, pricePerHour: Int, openHour: Int, closeHour: Int) async {
        do {
            try await db.collection("fields").document(field.id).updateData([
                "pricePerHour": pricePerHour,
                "openHour": openHour,
                "closeHour": closeHour
            ])
            successMessage = "Field updated!"
            showSuccess = true
            if let uid = Auth.auth().currentUser?.uid {
                await fetchMyFields(keeperId: uid)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func updateFieldFull(
        _ field: Field,
        name: String,
        address: String,
        sport: SportType,
        pricePerHour: Int,
        latitude: Double,
        longitude: Double,
        openHour: Int,
        closeHour: Int,
        imageUrl: String
    ) async {
        isLoading = true
        do {
            try await db.collection("fields").document(field.id).updateData([
                "name": name,
                "address": address,
                "sport": sport.rawValue,
                "pricePerHour": pricePerHour,
                "latitude": latitude,
                "longitude": longitude,
                "openHour": openHour,
                "closeHour": closeHour,
                "imageUrl": imageUrl
            ])
            successMessage = "Field \"\(name)\" updated!"
            showSuccess = true
            if let uid = Auth.auth().currentUser?.uid {
                await fetchMyFields(keeperId: uid)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func deleteField(_ field: Field, keeperId: String) async {
        do {
            try await db.collection("fields").document(field.id).delete()
            successMessage = "Field deleted."
            showSuccess = true
            await fetchMyFields(keeperId: keeperId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func updateBookingStatus(_ booking: Booking, status: BookingStatus) async {
        do {
            try await db.collection("bookings").document(booking.id).updateData([
                "status": status.rawValue
            ])
            successMessage = "Booking \(status.rawValue)."
            showSuccess = true
            if let uid = Auth.auth().currentUser?.uid {
                await fetchBookings(keeperId: uid)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func addManualBooking(
        field: Field,
        guestName: String,
        date: Date,
        startHour: Int,
        endHour: Int
    ) async {
        let bookingId = UUID().uuidString
        let duration = endHour - startHour
        let totalPrice = field.pricePerHour * duration

        let booking = Booking(
            id: bookingId,
            fieldId: field.id,
            fieldName: field.name,
            userId: "offline",
            userName: guestName,
            date: date,
            startHour: startHour,
            endHour: endHour,
            totalPrice: totalPrice,
            status: .confirmed,
            playerIds: ["offline"],
            playerNames: [guestName],
            splitAmount: totalPrice,
            isMatchmaking: false,
            maxPlayers: 1,
            sport: field.sport
        )

        do {
            try await db.collection("bookings").document(bookingId).setData(booking.toDictionary())
            successMessage = "Manual booking for \(guestName) added!"
            showSuccess = true
            if let uid = Auth.auth().currentUser?.uid {
                await fetchBookings(keeperId: uid)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    var totalRevenue: Int {
        myBookings.filter { $0.status == .confirmed }.reduce(0) { $0 + $1.totalPrice }
    }

    var todayBookings: [Booking] {
        let today = Calendar.current.startOfDay(for: Date())
        return myBookings.filter {
            Calendar.current.startOfDay(for: $0.date) == today
        }
    }
}
