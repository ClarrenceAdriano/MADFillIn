//
//  AddFieldView.swift
//  FillIn
//
//  Created by Shatrya Christiano on 04/06/26.
//

import SwiftUI
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocating = false
    @Published var locationError: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        isLocating = true
        locationError = nil
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.first {
            latitude = loc.coordinate.latitude
            longitude = loc.coordinate.longitude
        }
        isLocating = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
        isLocating = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

struct AddFieldView: View {
    @ObservedObject var keeperVM: FieldKeeperViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    
    @State private var fieldName = ""
    @State private var address = ""
    @State private var selectedSport: SportType = .football
    @State private var pricePerHour = ""
    @State private var openHour = 8
    @State private var closeHour = 22
    @State private var useMyLocation = true
    @State private var manualLatitude = ""
    @State private var manualLongitude = ""
    
    private let accent = Color(hex: "10B981")
    private let bgColor = Color(hex: "0F172A")
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    fieldInfoSection
                    sportSection
                    pricingSection
                    operatingHoursSection
                    locationSection
                    addButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: keeperVM.showSuccess) { _, success in
            if success { dismiss() }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add New Field")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Set up your sports venue details")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }
    
    private var fieldInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            KeeperSectionLabel(text: "Field Information", icon: "sportscourt.fill")
            
            VStack(spacing: 12) {
                KeeperTextField(placeholder: "Field Name", text: $fieldName, icon: "textformat")
                KeeperTextField(placeholder: "Address", text: $address, icon: "mappin.and.ellipse")
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    private var sportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            KeeperSectionLabel(text: "Sport Type", icon: "figure.run")
            
            VStack(spacing: 0) {
                ForEach(SportType.allCases, id: \.self) { sport in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedSport = sport }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: iconFor(sport))
                                .font(.title3)
                                .foregroundColor(selectedSport == sport ? accent : .white.opacity(0.4))
                                .frame(width: 28)
                            
                            Text(sport.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(selectedSport == sport ? .white : .white.opacity(0.5))
                            
                            Spacer()
                            
                            if selectedSport == sport {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(accent)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            selectedSport == sport
                            ? accent.opacity(0.1)
                            : Color.clear
                        )
                    }
                    
                    if sport != SportType.allCases.last {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            KeeperSectionLabel(text: "Pricing", icon: "banknote.fill")
            
            HStack(spacing: 10) {
                Text("Rp")
                    .font(.headline.bold())
                    .foregroundColor(accent)
                
                TextField("150000", text: $pricePerHour)
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("/ hour")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
    
    private var operatingHoursSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            KeeperSectionLabel(text: "Operating Hours", icon: "clock.fill")
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Open")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.5))
                    Picker("Open", selection: $openHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d:00", h))
                                .tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Close")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.5))
                    Picker("Close", selection: $closeHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d:00", h))
                                .tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            KeeperSectionLabel(text: "Location", icon: "location.fill")
            
            VStack(spacing: 16) {
                Picker("Location Mode", selection: $useMyLocation) {
                    Text("Use My Location").tag(true)
                    Text("Enter Manually").tag(false)
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)
                
                if useMyLocation {
                    VStack(spacing: 12) {
                        if locationManager.isLocating {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(accent)
                                Text("Getting your location...")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else if let lat = locationManager.latitude,
                                  let lng = locationManager.longitude {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Latitude")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.4))
                                    Text(String(format: "%.6f", lat))
                                        .font(.system(.subheadline, design: .monospaced).bold())
                                        .foregroundColor(accent)
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Longitude")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.4))
                                    Text(String(format: "%.6f", lng))
                                        .font(.system(.subheadline, design: .monospaced).bold())
                                        .foregroundColor(accent)
                                }
                                Spacer()
                            }
                            
                            Map(coordinateRegion: .constant(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                            )), annotationItems: [LocationPin(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))]) { pin in
                                MapMarker(coordinate: pin.coordinate, tint: Color(hex: "10B981"))
                            }
                            .frame(height: 120)
                            .cornerRadius(12)
                            .allowsHitTesting(false)
                            
                            Button {
                                locationManager.requestLocation()
                            } label: {
                                Label("Refresh Location", systemImage: "arrow.clockwise")
                                    .font(.caption.bold())
                                    .foregroundColor(accent)
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "location.circle")
                                    .font(.system(size: 36))
                                    .foregroundColor(accent.opacity(0.5))
                                
                                if let error = locationManager.locationError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                }
                                
                                Button {
                                    locationManager.requestLocation()
                                } label: {
                                    Label("Get Current Location", systemImage: "location.fill")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(accent.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Latitude")
                                    .font(.caption.bold())
                                    .foregroundColor(.white.opacity(0.5))
                                TextField("-6.2088", text: $manualLatitude)
                                    .keyboardType(.decimalPad)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(14)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Longitude")
                                    .font(.caption.bold())
                                    .foregroundColor(.white.opacity(0.5))
                                TextField("106.8456", text: $manualLongitude)
                                    .keyboardType(.decimalPad)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(14)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    private var addButton: some View {
        Button {
            Task { await submitField() }
        } label: {
            HStack(spacing: 10) {
                if keeperVM.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                Text("Add Field")
                    .font(.headline.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: isFormValid
                    ? [Color(hex: "10B981"), Color(hex: "059669")]
                    : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: isFormValid ? accent.opacity(0.3) : .clear, radius: 12, y: 6)
        }
        .disabled(!isFormValid || keeperVM.isLoading)
        .padding(.top, 8)
    }
    
    private var isFormValid: Bool {
        !fieldName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(pricePerHour) ?? 0) > 0 &&
        openHour < closeHour &&
        hasValidLocation
    }
    
    private var hasValidLocation: Bool {
        if useMyLocation {
            return locationManager.latitude != nil && locationManager.longitude != nil
        } else {
            return Double(manualLatitude) != nil && Double(manualLongitude) != nil
        }
    }
    
    private func submitField() async {
        guard let keeperId = authVM.currentUser?.uid else { return }
        
        let lat: Double
        let lng: Double
        
        if useMyLocation {
            guard let gpsLat = locationManager.latitude,
                  let gpsLng = locationManager.longitude else { return }
            lat = gpsLat
            lng = gpsLng
        } else {
            guard let manLat = Double(manualLatitude),
                  let manLng = Double(manualLongitude) else { return }
            lat = manLat
            lng = manLng
        }
        
        guard let price = Int(pricePerHour) else { return }
        
        await keeperVM.addField(
            name: fieldName.trimmingCharacters(in: .whitespaces),
            address: address.trimmingCharacters(in: .whitespaces),
            sport: selectedSport,
            pricePerHour: price,
            latitude: lat,
            longitude: lng,
            openHour: openHour,
            closeHour: closeHour,
            keeperId: keeperId
        )
    }
    
    private func iconFor(_ sport: SportType) -> String {
        switch sport {
        case .basketball: return "basketball"
        case .football: return "soccerball"
        case .badminton: return "figure.badminton"
        case .tennis: return "tennis.racket"
        case .volleyball: return "volleyball"
        }
    }
}

struct LocationPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct KeeperSectionLabel: View {
    var text: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "10B981"))
            Text(text)
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct KeeperTextField: View {
    var placeholder: String
    @Binding var text: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color(hex: "10B981").opacity(0.7))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    AddFieldView(keeperVM: FieldKeeperViewModel())
        .environmentObject(AuthViewModel())
}
