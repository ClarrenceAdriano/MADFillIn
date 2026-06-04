//
//  BookingView.swift
//  FillIn
//
//  Created by Dylan on 02/06/26.
//

import SwiftUI

struct BookingView: View {
    var field: Field
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var bookingVM = BookingViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var selectedDate = Date()
    @State private var startHour: Int? = nil
    @State private var endHour: Int? = nil
    @State private var isMatchmaking = false
    @State private var maxPlayers = 4
    @State private var step = 1  // 1=date, 2=time, 3=confirm

    var duration: Int { (endHour ?? 0) - (startHour ?? 0) }
    var totalPrice: Int { field.pricePerHour * max(duration, 0) }
    var splitPrice: Int { isMatchmaking && maxPlayers > 0 ? totalPrice / maxPlayers : totalPrice }

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Book Field")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(step)/3")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { s in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(s <= step ? Color(hex: "3B82F6") : Color.white.opacity(0.1))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "3B82F6").opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: iconFor(field.sport))
                                    .foregroundColor(Color(hex: "3B82F6"))
                                    .font(.title3)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(field.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(field.priceFormatted)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "3B82F6"))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)

                        if step == 1 { stepDateView }
                        if step == 2 { stepTimeView }
                        if step == 3 { stepConfirmView }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                VStack(spacing: 0) {
                    Divider().background(Color.white.opacity(0.08))
                    Button {
                        withAnimation(.spring()) {
                            if step < 3 { step += 1 }
                            else {
                                Task { await submitBooking() }
                            }
                        }
                        if step == 2 {
                            Task {
                                await bookingVM.fetchAvailableSlots(
                                    fieldId: field.id,
                                    date: selectedDate,
                                    openHour: field.openHour,
                                    closeHour: field.closeHour
                                )
                            }
                        }
                    } label: {
                        ZStack {
                            if bookingVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(step == 3 ? "Confirm Booking" : "Continue")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(canContinue ? Color(hex: "3B82F6") : Color.white.opacity(0.15))
                        .cornerRadius(16)
                    }
                    .disabled(!canContinue || bookingVM.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "0F172A"))
            }
        }
        .alert("Booking Confirmed! 🎉", isPresented: $bookingVM.bookingSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your booking for \(field.name) has been confirmed.")
        }
        .alert("Error", isPresented: $bookingVM.showError) {
            Button("OK") { bookingVM.showError = false }
        } message: {
            Text(bookingVM.errorMessage)
        }
    }

    var stepDateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Select Date", icon: "calendar")

            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .accentColor(Color(hex: "3B82F6"))
                .background(Color.white.opacity(0.04))
                .cornerRadius(14)
        }
    }

    var stepTimeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Select Time Slot", icon: "clock")

            if bookingVM.availableSlots.isEmpty {
                Text("Loading slots...")
                    .foregroundColor(.white.opacity(0.4))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Start Time")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.5))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(bookingVM.availableSlots.dropLast(), id: \.self) { hour in
                            TimeSlotButton(
                                hour: hour,
                                isSelected: startHour == hour,
                                isDisabled: endHour != nil && hour >= (endHour ?? 0)
                            ) {
                                startHour = hour
                                if let end = endHour, end <= hour { endHour = nil }
                            }
                        }
                    }
                }

                if startHour != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("End Time")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.5))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(bookingVM.availableSlots.filter { $0 > (startHour ?? 0) }, id: \.self) { hour in
                                TimeSlotButton(
                                    hour: hour,
                                    isSelected: endHour == hour,
                                    isDisabled: false
                                ) {
                                    endHour = hour
                                }
                            }
                        }
                    }
                }

                if let start = startHour, let end = endHour {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(start):00 – \(end):00 · \(end - start) hour(s)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }

    var stepConfirmView: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionTitle(title: "Confirm Booking", icon: "checkmark.seal")

            VStack(spacing: 12) {
                BookingRow(label: "Date", value: selectedDate.formatted(date: .long, time: .omitted))
                BookingRow(label: "Time", value: "\(startHour ?? 0):00 – \(endHour ?? 0):00")
                BookingRow(label: "Duration", value: "\(duration) hour(s)")
                BookingRow(label: "Total Price", value: formatRupiah(totalPrice))
                Divider().background(Color.white.opacity(0.1))
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)

            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "Matchmaking", icon: "person.2")

                Toggle(isOn: $isMatchmaking) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open for other players")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("Others can join and split the cost")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .tint(Color(hex: "3B82F6"))

                if isMatchmaking {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max Players: \(maxPlayers)")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.6))
                        Slider(value: Binding(
                            get: { Double(maxPlayers) },
                            set: { maxPlayers = Int($0) }
                        ), in: 2...12, step: 1)
                        .tint(Color(hex: "3B82F6"))
                    }

                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color(hex: "3B82F6"))
                        Text("Your share: \(formatRupiah(splitPrice))")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Text("÷ \(maxPlayers) players")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color(hex: "3B82F6").opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)
        }
    }

    var canContinue: Bool {
        switch step {
        case 1: return true
        case 2: return startHour != nil && endHour != nil && duration > 0
        case 3: return true
        default: return false
        }
    }

    func submitBooking() async {
        guard let user = authVM.currentUser,
              let start = startHour, let end = endHour else { return }
        await bookingVM.createBooking(
            field: field,
            date: selectedDate,
            startHour: start,
            endHour: end,
            isMatchmaking: isMatchmaking,
            maxPlayers: isMatchmaking ? maxPlayers : 1,
            currentUser: user
        )
    }

    func formatRupiah(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return "Rp \(f.string(from: NSNumber(value: amount)) ?? "\(amount)")"
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
}

struct TimeSlotButton: View {
    var hour: Int
    var isSelected: Bool
    var isDisabled: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(String(format: "%02d:00", hour))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : isDisabled ? .white.opacity(0.2) : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "3B82F6") : Color.white.opacity(0.08))
                .cornerRadius(10)
        }
        .disabled(isDisabled)
    }
}

struct BookingRow: View {
    var label: String
    var value: String

    var body: some View {
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
}

struct SectionTitle: View {
    var title: String
    var icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "3B82F6"))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
