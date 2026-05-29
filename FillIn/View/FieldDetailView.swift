//
//  FieldDetailView.swift
//  FillIn
//
//  Created by Shatrya Christiano on 29/05/26.
//

import SwiftUI
import MapKit

struct FieldDetailView: View {
    var field: Field
    @Environment(\.dismiss) var dismiss
    @State private var region: MKCoordinateRegion

    init(field: Field) {
        self.field = field
        _region = State(initialValue: MKCoordinateRegion(
            center: field.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "0F172A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    ZStack(alignment: .topLeading) {
                        Map(coordinateRegion: $region, annotationItems: [field]) { f in
                            MapAnnotation(coordinate: f.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "3B82F6"))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: iconFor(f.sport))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(height: 220)
                        .cornerRadius(0)

                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(16)
                        .padding(.top, 8)
                    }

                    VStack(alignment: .leading, spacing: 20) {

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(field.name)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text(field.address)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    Text(String(format: "%.1f", field.rating))
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                }
                                Text("\(field.totalReviews) reviews")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }

                        HStack(spacing: 12) {
                            StatBadge(icon: "clock", label: "Hours", value: "\(field.openHour):00–\(field.closeHour):00")
                            StatBadge(icon: "tag", label: "Per Hour", value: field.priceFormatted)
                            StatBadge(icon: "sportscourt", label: "Sport", value: field.sport.rawValue)
                        }

                        Divider().background(Color.white.opacity(0.1))

                    }
                    .padding(20)
                }
            }

            VStack {
                Spacer()
                Button {
                } label: {
                    Text("Book This Field")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "3B82F6"))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
                .background(
                    Color(hex: "0F172A")
                        .ignoresSafeArea()
                        .frame(height: 100)
                    , alignment: .bottom
                )
            }
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

struct StatBadge: View {
    var icon: String
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "3B82F6"))
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}

#Preview {
    FieldDetailView(field: Field(
        id: "preview-1",
        name: "KYZN at Citraland Arena",
        address: "Northwest Boulevard 1 Jalan CitraLand Utara, Pakal, Surabaya, East Java 60196",
        sport: .badminton,
        pricePerHour: 150000,
        latitude: -7.251968,
        longitude: 112.615918,
        openHour: 7,
        closeHour: 22,
        ownerId: "admin",
        imageUrl: "",
        rating: 4.7,
        totalReviews: 34
    ))
}
