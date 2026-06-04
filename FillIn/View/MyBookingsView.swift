//
//  MyBookingsView.swift
//  FillIn
//
//  Created by Dylan on 03/06/26.
//

import SwiftUI

struct MyBookingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var bookingVM = BookingViewModel()
    @State private var selectedFilter: BookingStatus? = nil
    @State private var chatBooking: Booking? = nil

    var filtered: [Booking] {
        guard let f = selectedFilter else { return bookingVM.myBookings }
        return bookingVM.myBookings.filter { $0.status == f }
    }

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("My Bookings")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Button {
                            Task { await bookingVM.fetchMyBookings() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    HStack(spacing: 10) {
                        FilterPill(label: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        FilterPill(label: "Confirmed", isSelected: selectedFilter == .confirmed) {
                            selectedFilter = .confirmed
                        }
                        FilterPill(label: "Pending", isSelected: selectedFilter == .pending) {
                            selectedFilter = .pending
                        }
                        FilterPill(label: "Cancelled", isSelected: selectedFilter == .cancelled) {
                            selectedFilter = .cancelled
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                if bookingVM.isLoading {
                    Spacer()
                    ProgressView().tint(Color(hex: "3B82F6"))
                    Spacer()
                } else if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No bookings yet")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.4))
                        Text("Book a field from the Explore tab")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.25))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(filtered) { booking in
                                BookingCard(booking: booking, onChat: {
                                    chatBooking = booking
                                }) {
                                    Task { await bookingVM.cancelBooking(booking) }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .task { await bookingVM.fetchMyBookings() }
        .sheet(item: $chatBooking) { booking in
            if let user = authVM.currentUser {
                NavigationStack {
                    ChatView(field: nil, booking: booking, currentUser: user)
                }
            }
        }
    }
}

struct BookingCard: View {
    var booking: Booking
    var onChat: () -> Void
    var onCancel: () -> Void
    @State private var showCancel = false

    var statusColor: Color {
        switch booking.status {
        case .confirmed: return .green
        case .pending: return .orange
        case .cancelled: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.fieldName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(booking.sport.rawValue)
                        .font(.caption)
                        .foregroundColor(Color(hex: "3B82F6"))
                }
                Spacer()
                Text(booking.status.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(20)
            }

            Divider().background(Color.white.opacity(0.08))

            HStack(spacing: 20) {
                BookingInfoItem(icon: "calendar", text: booking.dateFormatted)
                BookingInfoItem(icon: "clock", text: booking.timeFormatted)
                BookingInfoItem(icon: "person.2", text: "\(booking.playerIds.count)/\(booking.maxPlayers)")
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                    Text(formatRupiah(booking.totalPrice))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                if booking.isMatchmaking && booking.playerIds.count > 1 {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Your share")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                        Text(formatRupiah(booking.splitAmount))
                            .font(.subheadline.bold())
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                }
                Spacer()
                if booking.status == .confirmed {
                    Button(action: onChat) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.fill")
                                .font(.caption)
                            Text("Chat")
                                .font(.caption.bold())
                        }
                        .foregroundColor(Color(hex: "3B82F6"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "3B82F6").opacity(0.1))
                        .cornerRadius(8)
                    }

                    Button {
                        showCancel = true
                    } label: {
                        Text("Cancel")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
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
        .confirmationDialog("Cancel Booking?", isPresented: $showCancel) {
            Button("Cancel Booking", role: .destructive) { onCancel() }
            Button("Keep It", role: .cancel) {}
        }
    }

    func formatRupiah(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return "Rp \(f.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }
}

struct BookingInfoItem: View {
    var icon: String
    var text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color(hex: "3B82F6"))
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct FilterPill: View {
    var label: String
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color(hex: "3B82F6") : Color.white.opacity(0.08))
                .cornerRadius(20)
        }
    }
}
