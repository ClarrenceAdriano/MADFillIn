//
//  Booking.swift
//  FillIn
//
//  Created by Dylan on 02/06/26.
//

import Foundation
import FirebaseFirestore

enum BookingStatus: String, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case cancelled = "Cancelled"
}

struct Booking: Identifiable, Codable {
    var id: String
    var fieldId: String
    var fieldName: String
    var userId: String
    var userName: String
    var date: Date
    var startHour: Int
    var endHour: Int
    var totalPrice: Int
    var status: BookingStatus
    var playerIds: [String]
    var playerNames: [String]
    var splitAmount: Int
    var isMatchmaking: Bool
    var maxPlayers: Int
    var sport: SportType

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    var timeFormatted: String {
        return "\(startHour):00 – \(endHour):00"
    }

    var durationHours: Int {
        return endHour - startHour
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "fieldId": fieldId,
            "fieldName": fieldName,
            "userId": userId,
            "userName": userName,
            "date": Timestamp(date: date),
            "startHour": startHour,
            "endHour": endHour,
            "totalPrice": totalPrice,
            "status": status.rawValue,
            "playerIds": playerIds,
            "playerNames": playerNames,
            "splitAmount": splitAmount,
            "isMatchmaking": isMatchmaking,
            "maxPlayers": maxPlayers,
            "sport": sport.rawValue
        ]
    }

    static func fromDictionary(_ data: [String: Any], id: String) -> Booking? {
        guard
            let fieldId = data["fieldId"] as? String,
            let fieldName = data["fieldName"] as? String,
            let userId = data["userId"] as? String,
            let userName = data["userName"] as? String,
            let timestamp = data["date"] as? Timestamp,
            let startHour = data["startHour"] as? Int,
            let endHour = data["endHour"] as? Int,
            let totalPrice = data["totalPrice"] as? Int,
            let statusRaw = data["status"] as? String,
            let status = BookingStatus(rawValue: statusRaw),
            let sportRaw = data["sport"] as? String,
            let sport = SportType(rawValue: sportRaw)
        else { return nil }

        return Booking(
            id: id,
            fieldId: fieldId,
            fieldName: fieldName,
            userId: userId,
            userName: userName,
            date: timestamp.dateValue(),
            startHour: startHour,
            endHour: endHour,
            totalPrice: totalPrice,
            status: status,
            playerIds: data["playerIds"] as? [String] ?? [],
            playerNames: data["playerNames"] as? [String] ?? [],
            splitAmount: data["splitAmount"] as? Int ?? totalPrice,
            isMatchmaking: data["isMatchmaking"] as? Bool ?? false,
            maxPlayers: data["maxPlayers"] as? Int ?? 2,
            sport: sport
        )
    }
}
