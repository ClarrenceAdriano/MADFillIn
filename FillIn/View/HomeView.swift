//
//  HomeView.swift
//  FillIn
//
//  Created by Dylan on 03/06/2026.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var fieldVM = FieldViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {

                ExploreView(fieldVM: fieldVM)
                    .tag(0)

                MatchmakingView()
                    .environmentObject(authVM)
                    .tag(1)

                MyBookingsView()
                    .environmentObject(authVM)
                    .tag(2)

                ProfileView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .environmentObject(fieldVM)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("map.fill",       "Explore"),
        ("person.2.fill",  "Match"),
        ("calendar",       "Bookings"),
        ("person.fill",    "Profile")
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
                            .foregroundColor(selectedTab == i ? Color(hex: "3B82F6") : .white.opacity(0.4))
                            .scaleEffect(selectedTab == i ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3), value: selectedTab)
                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == i ? Color(hex: "3B82F6") : .white.opacity(0.4))
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
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}
