//
//  FieldModel.swift
//  FillIn
//
//  Created by Shatrya Christiano on 29/05/26.
//

import Foundation
import CoreLocation
import FirebaseFirestore

struct Field: Identifiable, Codable {
    var id: String
    var name: String
    var address: String
    var sport: SportType
    var pricePerHour: Int
    var latitude: Double
    var longitude: Double
    var openHour: Int
    var closeHour: Int
    var ownerId: String
    var imageUrl: String
    var rating: Double
    var totalReviews: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var priceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formatted = formatter.string(from: NSNumber(value: pricePerHour)) ?? "\(pricePerHour)"
        return "Rp \(formatted)/jam"
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "address": address,
            "sport": sport.rawValue,
            "pricePerHour": pricePerHour,
            "latitude": latitude,
            "longitude": longitude,
            "openHour": openHour,
            "closeHour": closeHour,
            "ownerId": ownerId,
            "imageUrl": imageUrl,
            "rating": rating,
            "totalReviews": totalReviews
        ]
    }

    static func fromDictionary(_ data: [String: Any], id: String) -> Field? {
        guard
            let name = data["name"] as? String,
            let address = data["address"] as? String,
            let sportRaw = data["sport"] as? String,
            let sport = SportType(rawValue: sportRaw),
            let price = data["pricePerHour"] as? Int,
            let lat = data["latitude"] as? Double,
            let lng = data["longitude"] as? Double,
            let openHour = data["openHour"] as? Int,
            let closeHour = data["closeHour"] as? Int,
            let ownerId = data["ownerId"] as? String
        else { return nil }

        return Field(
            id: id,
            name: name,
            address: address,
            sport: sport,
            pricePerHour: price,
            latitude: lat,
            longitude: lng,
            openHour: openHour,
            closeHour: closeHour,
            ownerId: ownerId,
            imageUrl: data["imageUrl"] as? String ?? "",
            rating: data["rating"] as? Double ?? 0.0,
            totalReviews: data["totalReviews"] as? Int ?? 0
        )
    }
}
