//
//  EditFieldView.swift
//  FillIn
//
//  Created by Dylan on 04/06/26.
//

import SwiftUI

struct EditFieldView: View {
    var field: Field
    @ObservedObject var keeperVM: FieldKeeperViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var address: String
    @State private var sport: SportType
    @State private var pricePerHour: String
    @State private var openHour: Int
    @State private var closeHour: Int
    @State private var latitude: String
    @State private var longitude: String
    @State private var imageUrl: String
    @State private var isSaving = false

    init(field: Field, keeperVM: FieldKeeperViewModel) {
        self.field = field
        self.keeperVM = keeperVM
        _name = State(initialValue: field.name)
        _address = State(initialValue: field.address)
        _sport = State(initialValue: field.sport)
        _pricePerHour = State(initialValue: "\(field.pricePerHour)")
        _openHour = State(initialValue: field.openHour)
        _closeHour = State(initialValue: field.closeHour)
        _latitude = State(initialValue: "\(field.latitude)")
        _longitude = State(initialValue: "\(field.longitude)")
        _imageUrl = State(initialValue: field.imageUrl)
    }

    private let accentGreen = Color(hex: "10B981")
    private let bgColor = Color(hex: "0F172A")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    basicInfoSection
                    locationSection
                    schedulePricingSection
                    mediaSection
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .onChange(of: keeperVM.showSuccess) { _, success in
            if success { dismiss() }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.line")
                        .font(.title2)
                        .foregroundColor(accentGreen)
                    Text("Edit Field")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                Text(field.name)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body.bold())
                    .foregroundColor(.white.opacity(0.7))
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
            }
        }
        .padding(.top, 8)
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Basic Information", icon: "info.circle.fill")

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Field Name")
                TextField("", text: $name)
                    .placeholder(when: name.isEmpty) { Text("Enter field name").foregroundColor(.white.opacity(0.25)) }
                    .fieldInputStyle()
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Address")
                TextField("", text: $address)
                    .placeholder(when: address.isEmpty) { Text("Enter address").foregroundColor(.white.opacity(0.25)) }
                    .fieldInputStyle()
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Sport Type")
                HStack(spacing: 8) {
                    ForEach(SportType.allCases, id: \.self) { sportType in
                        EditSportChip(
                            sport: sportType,
                            isSelected: sport == sportType,
                            accent: accentGreen
                        ) {
                            sport = sportType
                        }
                    }
                }
            }
        }
        .sectionCardStyle()
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Location", icon: "mappin.circle.fill")

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    fieldLabel("Latitude")
                    TextField("", text: $latitude)
                        .placeholder(when: latitude.isEmpty) { Text("-7.25").foregroundColor(.white.opacity(0.25)) }
                        .keyboardType(.decimalPad)
                        .fieldInputStyle()
                }
                VStack(alignment: .leading, spacing: 6) {
                    fieldLabel("Longitude")
                    TextField("", text: $longitude)
                        .placeholder(when: longitude.isEmpty) { Text("112.75").foregroundColor(.white.opacity(0.25)) }
                        .keyboardType(.decimalPad)
                        .fieldInputStyle()
                }
            }
        }
        .sectionCardStyle()
    }

    private var schedulePricingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Schedule & Pricing", icon: "clock.fill")

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    fieldLabel("Open Hour")
                    Picker("", selection: $openHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d:00", h)).tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(accentGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fieldInputStyle()
                }

                VStack(alignment: .leading, spacing: 6) {
                    fieldLabel("Close Hour")
                    Picker("", selection: $closeHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d:00", h)).tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(accentGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fieldInputStyle()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Price Per Hour (Rp)")
                TextField("", text: $pricePerHour)
                    .placeholder(when: pricePerHour.isEmpty) { Text("150000").foregroundColor(.white.opacity(0.25)) }
                    .keyboardType(.numberPad)
                    .fieldInputStyle()
            }
        }
        .sectionCardStyle()
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Media", icon: "photo.fill")

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Image URL")
                TextField("", text: $imageUrl)
                    .placeholder(when: imageUrl.isEmpty) { Text("https://example.com/image.jpg").foregroundColor(.white.opacity(0.25)) }
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .fieldInputStyle()
            }

            if !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .cornerRadius(12)
                            .clipped()
                    case .failure:
                        imagePreviewPlaceholder(icon: "exclamationmark.triangle", text: "Failed to load image")
                    case .empty:
                        ProgressView()
                            .tint(accentGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .sectionCardStyle()
    }

    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body.bold())
                    Text("Save Changes")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color(hex: "10B981"), Color(hex: "059669")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 12, y: 6)
        }
        .disabled(isSaving || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.5)
        .padding(.top, 8)
    }


    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(pricePerHour) != nil &&
        Double(latitude) != nil &&
        Double(longitude) != nil
    }

    private func saveChanges() {
        guard let price = Int(pricePerHour),
              let lat = Double(latitude),
              let lng = Double(longitude) else { return }

        isSaving = true
        Task {
            await keeperVM.updateFieldFull(
                field,
                name: name.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces),
                sport: sport,
                pricePerHour: price,
                latitude: lat,
                longitude: lng,
                openHour: openHour,
                closeHour: closeHour,
                imageUrl: imageUrl.trimmingCharacters(in: .whitespaces)
            )
            isSaving = false
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(accentGreen)
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white.opacity(0.5))
    }

    private func imagePreviewPlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.3))
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

struct EditSportChip: View {
    let sport: SportType
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(sport.rawValue)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(isSelected ? accent.opacity(0.25) : Color.white.opacity(0.06))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? accent.opacity(0.6) : Color.clear, lineWidth: 1)
                )
        }
    }
}

private extension View {
    func fieldInputStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }

    func sectionCardStyle() -> some View {
        self
            .padding(18)
            .background(Color.white.opacity(0.04))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    @ViewBuilder
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    EditFieldView(
        field: Field(
            id: "preview",
            name: "Lapangan Futsal A",
            address: "Jl. Raya Darmo 45",
            sport: .football,
            pricePerHour: 150000,
            latitude: -7.2575,
            longitude: 112.7521,
            openHour: 8,
            closeHour: 22,
            ownerId: "preview",
            imageUrl: "",
            rating: 4.5,
            totalReviews: 12
        ),
        keeperVM: FieldKeeperViewModel()
    )
    .environmentObject(AuthViewModel())
}
