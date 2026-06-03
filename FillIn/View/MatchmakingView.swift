//
//  MatchmakingView.swift
//  FillIn
//
//  Created by Shatrya Christiano on 03/06/26.
//


import SwiftUI
import Combine

struct MatchmakingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var matchVM = MatchmakingViewModel()
    @State private var selectedSport: SportType? = nil

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Matchmaking")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("Find players to join your game")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        Button {
                            Task { await matchVM.fetchOpenSessions(sport: selectedSport) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                        }
                    }

                    // Sport filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterPill(label: "All Sports", isSelected: selectedSport == nil) {
                                selectedSport = nil
                                Task { await matchVM.fetchOpenSessions() }
                            }
                            ForEach(SportType.allCases, id: \.self) { sport in
                                FilterPill(label: sport.rawValue, isSelected: selectedSport == sport) {
                                    selectedSport = sport
                                    Task { await matchVM.fetchOpenSessions(sport: sport) }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                if matchVM.isLoading {
                    Spacer()
                    ProgressView().tint(Color(hex: "3B82F6"))
                    Spacer()
                } else if matchVM.openSessions.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No open sessions")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.4))
                        Text("Book a field and enable matchmaking\nto invite other players!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.25))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(matchVM.openSessions) { session in
                                MatchSessionCard(session: session) {
                                    guard let user = authVM.currentUser else { return }
                                    Task { await matchVM.joinSession(session, user: user) }
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
        .task { await matchVM.fetchOpenSessions() }
        .alert("Joined! 🎉", isPresented: $matchVM.joinSuccess) {
            Button("OK") { matchVM.joinSuccess = false }
        } message: {
            Text("You've successfully joined the session. Check My Bookings for details.")
        }
        .alert("Error", isPresented: $matchVM.showError) {
            Button("OK") { matchVM.showError = false }
        } message: {
            Text(matchVM.errorMessage)
        }
    }
}

// MARK: - Match Session Card
struct MatchSessionCard: View {
    var session: Booking
    var onJoin: () -> Void

    var spotsLeft: Int { session.maxPlayers - session.playerIds.count }
    var splitPrice: Int {
        session.maxPlayers > 0 ? session.totalPrice / session.maxPlayers : session.totalPrice
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top: field name + sport badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.fieldName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(session.dateFormatted + " · " + session.timeFormatted)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Text(session.sport.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "3B82F6"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "3B82F6").opacity(0.15))
                    .cornerRadius(20)
            }

            // Player slots visual
            HStack(spacing: 8) {
                ForEach(0..<session.maxPlayers, id: \.self) { i in
                    ZStack {
                        Circle()
                            .fill(i < session.playerIds.count
                                  ? Color(hex: "3B82F6")
                                  : Color.white.opacity(0.1))
                            .frame(width: 32, height: 32)
                        if i < session.playerIds.count {
                            Text(session.playerNames[i].prefix(1).uppercased())
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "plus")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                Spacer()
                Text("\(spotsLeft) spot\(spotsLeft == 1 ? "" : "s") left")
                    .font(.caption.bold())
                    .foregroundColor(spotsLeft <= 1 ? .orange : .green)
            }

            Divider().background(Color.white.opacity(0.08))

            // Host + price + join button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Host: \(session.userName)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Text("Your share: \(formatRupiah(splitPrice))")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "3B82F6"))
                }
                Spacer()
                Button(action: onJoin) {
                    Text("Join")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "3B82F6"))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "3B82F6").opacity(0.2), lineWidth: 1)
        )
    }

    func formatRupiah(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return "Rp \(f.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }
}
