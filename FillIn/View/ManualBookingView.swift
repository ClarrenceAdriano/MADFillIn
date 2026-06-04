//
//  ManualBookingView.swift
//  FillIn
//
//  Created by Dylan on 04/06/26.
//

import SwiftUI

struct ManualBookingView: View {
    @ObservedObject var keeperVM: FieldKeeperViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedField: Field? = nil
    @State private var guestName = ""
    @State private var bookingDate = Date()
    @State private var startHour = 8
    @State private var endHour = 9

    private var duration: Int {
        max(endHour - startHour, 0)
    }

    private var totalPrice: Int {
        guard let field = selectedField else { return 0 }
        return field.pricePerHour * duration
    }

    private var availableHours: [Int] {
        guard let field = selectedField else { return Array(6...23) }
        return Array(field.openHour...field.closeHour)
    }

    private var startHours: [Int] {
        let hours = availableHours
        guard hours.count > 1 else { return hours }
        return Array(hours.dropLast())
    }

    private var endHours: [Int] {
        let hours = availableHours
        return hours.filter { $0 > startHour }
    }

    private var canSubmit: Bool {
        selectedField != nil &&
        !guestName.trimmingCharacters(in: .whitespaces).isEmpty &&
        duration > 0
    }

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                if keeperVM.myFields.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            fieldSelectionSection
                            guestNameSection
                            dateSection
                            hourSection
                            priceSummaryCard
                            createButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }

            if keeperVM.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            if selectedField == nil, let first = keeperVM.myFields.first {
                selectedField = first
                startHour = first.openHour
                endHour = min(first.openHour + 1, first.closeHour)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "10B981").opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "10B981"))
                }
                Text("Manual Booking")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(hex: "10B981").opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "sportscourt")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.2))
            }
            Text("No Fields Available")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
            Text("Add a field first before creating\na manual booking.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var fieldSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Select Field", icon: "sportscourt.fill")

            Menu {
                ForEach(keeperVM.myFields) { field in
                    Button {
                        selectedField = field
                        // Reset hours to fit new field
                        startHour = field.openHour
                        endHour = min(field.openHour + 1, field.closeHour)
                    } label: {
                        Label {
                            Text("\(field.name) — \(field.sport.rawValue)")
                        } icon: {
                            Image(systemName: iconFor(field.sport))
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    if let field = selectedField {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "10B981").opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: iconFor(field.sport))
                                .foregroundColor(Color(hex: "10B981"))
                                .font(.system(size: 16))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(field.name)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Text(field.sport.rawValue)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else {
                        Image(systemName: "sportscourt")
                            .foregroundColor(.white.opacity(0.4))
                        Text("Choose a field")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.subheadline)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
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
    }

    private var guestNameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Guest Name", icon: "person.fill")

            TextField("", text: $guestName, prompt: Text("Walk-in guest name").foregroundColor(.white.opacity(0.3)))
                .foregroundColor(.white)
                .font(.subheadline)
                .padding(14)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Date", icon: "calendar")

            DatePicker("", selection: $bookingDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(Color(hex: "10B981"))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private var hourSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Time Slot", icon: "clock.fill")

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))

                    Menu {
                        ForEach(startHours, id: \.self) { hour in
                            Button {
                                startHour = hour
                                if endHour <= hour {
                                    endHour = min(hour + 1, selectedField?.closeHour ?? 23)
                                }
                            } label: {
                                Text(String(format: "%02d:00", hour))
                            }
                        }
                    } label: {
                        HStack {
                            Text(String(format: "%02d:00", startHour))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.3))
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

                Image(systemName: "arrow.right")
                    .foregroundColor(Color(hex: "10B981"))
                    .padding(.top, 22)

                VStack(alignment: .leading, spacing: 6) {
                    Text("End")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))

                    Menu {
                        ForEach(endHours, id: \.self) { hour in
                            Button {
                                endHour = hour
                            } label: {
                                Text(String(format: "%02d:00", hour))
                            }
                        }
                    } label: {
                        HStack {
                            Text(String(format: "%02d:00", endHour))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.3))
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
            }
        }
    }

    private var priceSummaryCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "receipt.fill")
                    .foregroundColor(Color(hex: "10B981"))
                Text("Price Summary")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.bottom, 14)

            VStack(spacing: 10) {
                summaryRow(label: "Duration", value: "\(duration) hour\(duration == 1 ? "" : "s")")
                summaryRow(label: "Price / hour", value: formatRupiah(selectedField?.pricePerHour ?? 0))

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                HStack {
                    Text("Total")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatRupiah(totalPrice))
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color(hex: "10B981"))
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "10B981").opacity(0.2), lineWidth: 1)
        )
    }

    private var createButton: some View {
        Button {
            guard let field = selectedField else { return }
            Task {
                await keeperVM.addManualBooking(
                    field: field,
                    guestName: guestName.trimmingCharacters(in: .whitespaces),
                    date: bookingDate,
                    startHour: startHour,
                    endHour: endHour
                )
                if !keeperVM.showError {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                Text("Create Booking")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: canSubmit
                        ? [Color(hex: "10B981"), Color(hex: "059669")]
                        : [Color.white.opacity(0.1), Color.white.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: canSubmit ? Color(hex: "10B981").opacity(0.3) : .clear, radius: 12, y: 4)
        }
        .disabled(!canSubmit)
        .padding(.top, 6)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .tint(Color(hex: "10B981"))
                    .scaleEffect(1.3)
                Text("Creating booking...")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(hex: "1E293B"))
            .cornerRadius(16)
        }
    }

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "10B981"))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }

    func iconFor(_ sport: SportType) -> String {
        switch sport {
        case .basketball: return "basketball"
        case .football: return "soccerball"
        case .badminton: return "figure.badminton"
        case .tennis: return "tennis.racket"
        case .volleyball: return "volleyball"
        }
    }

    func formatRupiah(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return "Rp \(f.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }
}

#Preview {
    ManualBookingView(keeperVM: FieldKeeperViewModel())
}
