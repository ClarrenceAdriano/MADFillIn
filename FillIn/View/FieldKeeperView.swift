//
//  FieldKeeperView.swift
//  FillIn
//
//  Created by Shatrya Christiano on 03/06/26.
//

import SwiftUI

struct FieldKeeperView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var keeperVM = FieldKeeperViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                KeeperDashboardTab(keeperVM: keeperVM)
                    .environmentObject(authVM)
                    .tag(0)

                KeeperFieldsTab(keeperVM: keeperVM)
                    .environmentObject(authVM)
                    .tag(1)

                KeeperBookingsTab(keeperVM: keeperVM)
                    .environmentObject(authVM)
                    .tag(2)

                KeeperProfileTab()
                    .environmentObject(authVM)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            KeeperTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            guard let uid = authVM.currentUser?.uid else { return }
            await keeperVM.fetchMyFields(keeperId: uid)
            await keeperVM.fetchBookings(keeperId: uid)
        }
        .alert("Error", isPresented: $keeperVM.showError) {
            Button("OK") { keeperVM.showError = false }
        } message: { Text(keeperVM.errorMessage) }
        .alert("Success ", isPresented: $keeperVM.showSuccess) {
            Button("OK") { keeperVM.showSuccess = false }
        } message: { Text(keeperVM.successMessage) }
    }
}

struct KeeperTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, label: String)] = [
        ("chart.bar.fill", "Dashboard"),
        ("sportscourt.fill", "My Fields"),
        ("calendar.badge.clock", "Bookings"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 22, weight: selectedTab == i ? .bold : .regular))
                            .foregroundColor(selectedTab == i ? Color(hex: "10B981") : .white.opacity(0.4))
                            .scaleEffect(selectedTab == i ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3), value: selectedTab)
                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == i ? Color(hex: "10B981") : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 24)
        .background(
            Color(hex: "0F172A")
                .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1), alignment: .top)
        )
    }
}

struct KeeperDashboardTab: View {
    @ObservedObject var keeperVM: FieldKeeperViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dashboard")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("Welcome, \(authVM.currentUser?.fullName ?? "Keeper") 👋")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Image(systemName: "building.2.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    .padding(.top, 60)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        KeeperStatCard(
                            icon: "sportscourt.fill",
                            label: "My Fields",
                            value: "\(keeperVM.myFields.count)",
                            color: "10B981"
                        )
                        KeeperStatCard(
                            icon: "calendar.badge.checkmark",
                            label: "Total Bookings",
                            value: "\(keeperVM.myBookings.count)",
                            color: "3B82F6"
                        )
                        KeeperStatCard(
                            icon: "sun.max.fill",
                            label: "Today's Bookings",
                            value: "\(keeperVM.todayBookings.count)",
                            color: "F59E0B"
                        )
                        KeeperStatCard(
                            icon: "banknote.fill",
                            label: "Total Revenue",
                            value: formatRupiah(keeperVM.totalRevenue),
                            color: "EC4899"
                        )
                    }

                    if !keeperVM.todayBookings.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Schedule")
                                .font(.headline)
                                .foregroundColor(.white)

                            ForEach(keeperVM.todayBookings) { booking in
                                TodayBookingRow(booking: booking)
                            }
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No bookings today")
                                .foregroundColor(.white.opacity(0.3))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(30)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
    }

    func formatRupiah(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            return "Rp \(amount / 1_000_000)jt"
        } else if amount >= 1_000 {
            return "Rp \(amount / 1_000)rb"
        }
        return "Rp \(amount)"
    }
}

struct KeeperStatCard: View {
    var icon: String
    var label: String
    var value: String
    var color: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: color).opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: color).opacity(0.2), lineWidth: 1)
        )
    }
}

struct TodayBookingRow: View {
    var booking: Booking

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("\(booking.startHour):00")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "10B981"))
                Rectangle()
                    .fill(Color(hex: "10B981").opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                Text("\(booking.endHour):00")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.userName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text("\(booking.playerIds.count) player(s) · \(booking.sport.rawValue)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Text(formatRupiah(booking.totalPrice))
                .font(.caption.bold())
                .foregroundColor(Color(hex: "10B981"))
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    func formatRupiah(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return "Rp \(f.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }
}

struct KeeperFieldsTab: View {
    @ObservedObject var keeperVM: FieldKeeperViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAddField = false
    @State private var editingField: Field? = nil

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("My Fields")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        showAddField = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color(hex: "10B981"))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                if keeperVM.myFields.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No fields yet")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.4))
                        Text("Tap + to add your first field")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.25))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(keeperVM.myFields) { field in
                                KeeperFieldCard(field: field) {
                                    editingField = field
                                } onDelete: {
                                    guard let uid = authVM.currentUser?.uid else { return }
                                    Task { await keeperVM.deleteField(field, keeperId: uid) }
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
        .sheet(isPresented: $showAddField) {
            AddFieldView(keeperVM: keeperVM)
                .environmentObject(authVM)
        }
        .sheet(item: $editingField) { field in
            EditFieldView(field: field, keeperVM: keeperVM)
                .environmentObject(authVM)
        }
    }
}

struct KeeperFieldCard: View {
    var field: Field
    var onEdit: () -> Void
    var onDelete: () -> Void
    @State private var showDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "10B981").opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: iconFor(field.sport))
                        .foregroundColor(Color(hex: "10B981"))
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(field.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(field.sport.rawValue)
                        .font(.caption)
                        .foregroundColor(Color(hex: "10B981"))
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.caption2).foregroundColor(.yellow)
                    Text(String(format: "%.1f", field.rating))
                        .font(.caption.bold()).foregroundColor(.white)
                }
            }

            HStack(spacing: 16) {
                Label(field.priceFormatted, systemImage: "tag")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Label("\(field.openHour):00–\(field.closeHour):00", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            HStack(spacing: 10) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                }
                Spacer()
                Button { showDelete = true } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .confirmationDialog("Delete \(field.name)?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
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
}

struct KeeperBookingsTab: View {
    @ObservedObject var keeperVM: FieldKeeperViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showManualBooking = false
    @State private var statusFilter: BookingStatus? = nil
    @State private var chatBooking: Booking? = nil

    var filtered: [Booking] {
        guard let f = statusFilter else { return keeperVM.myBookings }
        return keeperVM.myBookings.filter { $0.status == f }
    }

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Bookings")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        showManualBooking = true
                    } label: {
                        Label("Manual", systemImage: "plus.circle")
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: "10B981"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "10B981").opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterPill(label: "All", isSelected: statusFilter == nil) { statusFilter = nil }
                        FilterPill(label: "Confirmed", isSelected: statusFilter == .confirmed) { statusFilter = .confirmed }
                        FilterPill(label: "Pending", isSelected: statusFilter == .pending) { statusFilter = .pending }
                        FilterPill(label: "Cancelled", isSelected: statusFilter == .cancelled) { statusFilter = .cancelled }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)

                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No bookings")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { booking in
                                KeeperBookingCard(booking: booking, onChat: {
                                    chatBooking = booking
                                }) { status in
                                    Task { await keeperVM.updateBookingStatus(booking, status: status) }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .sheet(isPresented: $showManualBooking) {
            ManualBookingView(keeperVM: keeperVM)
                .environmentObject(authVM)
        }
        .sheet(item: $chatBooking) { booking in
            if let user = authVM.currentUser {
                NavigationStack {
                    ChatView(field: nil, booking: booking, currentUser: user)
                }
            }
        }
    }
}

struct KeeperBookingCard: View {
    var booking: Booking
    var onChat: () -> Void
    var onUpdateStatus: (BookingStatus) -> Void

    var statusColor: Color {
        switch booking.status {
        case .confirmed: return .green
        case .pending: return .orange
        case .cancelled: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(booking.userName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(booking.fieldName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
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

            HStack(spacing: 16) {
                Label(booking.dateFormatted, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Label(booking.timeFormatted, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Label("\(booking.playerIds.count) player(s)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            // Chat button
            Button(action: onChat) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption)
                    Text("Chat")
                        .font(.caption.bold())
                }
                .foregroundColor(Color(hex: "3B82F6"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(hex: "3B82F6").opacity(0.1))
                .cornerRadius(8)
            }

            HStack {
                Text(formatRupiah(booking.totalPrice))
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "10B981"))
                Spacer()

                if booking.status == .pending {
                    HStack(spacing: 8) {
                        Button { onUpdateStatus(.cancelled) } label: {
                            Text("Reject")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        Button { onUpdateStatus(.confirmed) } label: {
                            Text("Confirm")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color(hex: "10B981"))
                                .cornerRadius(8)
                        }
                    }
                } else if booking.status == .confirmed {
                    Button { onUpdateStatus(.cancelled) } label: {
                        Text("Cancel")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    func formatRupiah(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return "Rp \(f.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }
}

struct KeeperProfileTab: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color(hex: "10B981").opacity(0.2))
                        .frame(width: 100, height: 100)
                    Text(authVM.currentUser?.fullName.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(Color(hex: "10B981"))
                }
                VStack(spacing: 6) {
                    Text(authVM.currentUser?.fullName ?? "")
                        .font(.title2.bold()).foregroundColor(.white)
                    Text(authVM.currentUser?.email ?? "")
                        .font(.subheadline).foregroundColor(.white.opacity(0.5))
                    Text("Field Keeper")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "10B981"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color(hex: "10B981").opacity(0.1))
                        .cornerRadius(20)
                }
                Spacer()
                Button { authVM.logout() } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 100)
            }
        }
    }
}
