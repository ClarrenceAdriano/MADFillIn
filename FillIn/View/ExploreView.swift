//
//  ExploreView.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 01/06/26.
//

import Foundation
import SwiftUI
import MapKit

struct ExploreView: View {
    @ObservedObject var fieldVM: FieldViewModel
    @State private var showList = true
    @State private var selectedField: Field? = nil
    @State private var showDetail = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -7.2575, longitude: 112.7521),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Explore Fields")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("Surabaya, Indonesia")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()

                        Button {
                            withAnimation(.spring()) { showList.toggle() }
                        } label: {
                            Image(systemName: showList ? "map.fill" : "list.bullet")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("Search fields...", text: $fieldVM.searchText)
                            .foregroundColor(.white)
                            .onChange(of: fieldVM.searchText) { _ in fieldVM.applyFilters() }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        SportChip(label: "All", icon: "square.grid.2x2", isSelected: fieldVM.selectedSport == nil) {
                            fieldVM.selectSport(nil)
                        }
                        ForEach(SportType.allCases, id: \.self) { sport in
                            SportChip(
                                label: sport.rawValue,
                                icon: iconFor(sport),
                                isSelected: fieldVM.selectedSport == sport
                            ) {
                                fieldVM.selectSport(fieldVM.selectedSport == sport ? nil : sport)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }

                if showList {
                    fieldListView
                } else {
                    mapView
                }
            }
        }
        .sheet(item: $selectedField) { field in
            FieldDetailView(field: field)
        }
        .onAppear {
            if fieldVM.fields.isEmpty {
                Task { await fieldVM.fetchFields() }
            }
        }
    }

    var fieldListView: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if fieldVM.isLoading {
                    ProgressView()
                        .tint(Color(hex: "3B82F6"))
                        .padding(.top, 40)
                } else if fieldVM.filteredFields.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No fields found")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(fieldVM.filteredFields) { field in
                        FieldCard(field: field)
                            .onTapGesture { selectedField = field }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
    }

    var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: fieldVM.filteredFields) { field in
            MapAnnotation(coordinate: field.coordinate) {
                Button {
                    selectedField = field
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "3B82F6"))
                                .frame(width: 40, height: 40)
                            Image(systemName: iconFor(field.sport))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text(field.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "0F172A").opacity(0.85))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct SportChip: View {
    var label: String
    var icon: String
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? Color(hex: "3B82F6")
                : Color.white.opacity(0.08)
            )
            .cornerRadius(20)
        }
    }
}

struct FieldCard: View {
    var field: Field

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "3B82F6").opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: iconFor(field.sport))
                    .font(.system(size: 26))
                    .foregroundColor(Color(hex: "3B82F6"))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(field.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(field.address)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label("\(String(format: "%.1f", field.rating))", systemImage: "star.fill")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)

                    Text(field.priceFormatted)
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.3))
                .font(.caption)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
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

#Preview{
    ExploreView(fieldVM: FieldViewModel())
}
