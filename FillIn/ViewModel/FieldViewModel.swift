//
//  FieldViewModel.swift
//  FillIn
//
//  Created by Shatrya Christiano on 29/05/26.
//

import Foundation
import CoreLocation
import FirebaseFirestore
import Combine

@MainActor
class FieldViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var fields: [Field] = []
    @Published var filteredFields: [Field] = []
    @Published var selectedSport: SportType? = nil
    @Published var searchText: String = ""
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var isLoading = false
    @Published var selectedField: Field? = nil

    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        Task { await fetchFields() }
    }

    func fetchFields() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("fields").getDocuments()
            let fetched = snapshot.documents.compactMap {
                Field.fromDictionary($0.data(), id: $0.documentID)
            }
            self.fields = fetched
            applyFilters()
        } catch {
            print("Error fetching fields: \(error)")
        }
        isLoading = false
    }

    func applyFilters() {
        var result = fields

        if let sport = selectedSport {
            result = result.filter { $0.sport == sport }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredFields = result
    }

    func selectSport(_ sport: SportType?) {
        selectedSport = sport
        applyFilters()
    }

    func seedDummyFields() async {
        let dummies: [Field] = [
            Field(id: UUID().uuidString, name: "GOR Bola Basket Ciputra", address: "Jl. Citraland, Surabaya", sport: .basketball, pricePerHour: 150000, latitude: -7.2878, longitude: 112.6688, openHour: 7, closeHour: 22, ownerId: "admin", imageUrl: "", rating: 4.7, totalReviews: 34),
            Field(id: UUID().uuidString, name: "Lapangan Futsal Galaxy", address: "Jl. Galaxy Bumi Permai, Surabaya", sport: .football, pricePerHour: 120000, latitude: -7.2785, longitude: 112.7540, openHour: 8, closeHour: 23, ownerId: "admin", imageUrl: "", rating: 4.5, totalReviews: 21),
            Field(id: UUID().uuidString, name: "Badminton Hall Manyar", address: "Jl. Manyar Kertoarjo, Surabaya", sport: .badminton, pricePerHour: 80000, latitude: -7.2701, longitude: 112.7531, openHour: 6, closeHour: 22, ownerId: "admin", imageUrl: "", rating: 4.3, totalReviews: 15),
            Field(id: UUID().uuidString, name: "Tennis Club Pakuwon", address: "Pakuwon City, Surabaya", sport: .tennis, pricePerHour: 200000, latitude: -7.2607, longitude: 112.7244, openHour: 7, closeHour: 20, ownerId: "admin", imageUrl: "", rating: 4.8, totalReviews: 44),
            Field(id: UUID().uuidString, name: "Voli Indoor Kenjeran", address: "Jl. Kenjeran, Surabaya", sport: .volleyball, pricePerHour: 90000, latitude: -7.2319, longitude: 112.7730, openHour: 8, closeHour: 21, ownerId: "admin", imageUrl: "", rating: 4.1, totalReviews: 9),
        ]

        for field in dummies {
            try? await db.collection("fields").document(field.id).setData(field.toDictionary())
        }

        await fetchFields()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.userLocation = loc.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
