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

    private let service = FieldService()
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
            fields = try await service.fetchFields()
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
