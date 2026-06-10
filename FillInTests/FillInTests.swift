//
//  FillInTests.swift
//  FillInTests
//
//  Created by Clarrence Adriano Hemeldan on 28/05/26.
//

import XCTest
@testable import FillIn
internal import _LocationEssentials

extension FillInTests {
    func makeDummyField(id: String = "field-001", name: String = "GOR Ciputra", sport: SportType = .basketball, price: Int = 150000, openHour: Int = 7, closeHour: Int = 22, rating: Double = 4.5, ownerId: String = "keeper-001") -> Field {
        Field(id: id, name: name, address: "Jl. Citraland, Surabaya", sport: sport, pricePerHour: price, latitude: -7.2878, longitude: 112.6688, openHour: openHour, closeHour: closeHour, ownerId: ownerId, imageUrl: "", rating: rating, totalReviews: 20)
    }

    func makeDummyUser(uid: String = "user-001", fullName: String = "Dylan Patrick", email: String = "dylan@email.com", role: UserRole = .user, sports: [SportType: SkillLevel] = [.basketball: .pro]) -> FillInUser {
        FillInUser(uid: uid, fullName: fullName, email: email, sports: sports, createdAt: Date(), role: role)
    }

    func makeDummyBooking(id: String = "booking-001", userId: String = "user-001", userName: String = "Dylan Patrick", startHour: Int = 8, endHour: Int = 10, totalPrice: Int = 300000, status: BookingStatus = .confirmed, isMatchmaking: Bool = false, maxPlayers: Int = 2) -> Booking {
        Booking(id: id, fieldId: "field-001", fieldName: "GOR Ciputra", userId: userId, userName: userName, date: Date(), startHour: startHour, endHour: endHour, totalPrice: totalPrice, status: status, playerIds: [userId], playerNames: [userName], splitAmount: totalPrice, isMatchmaking: isMatchmaking, maxPlayers: maxPlayers, sport: .basketball)
    }
}

final class FillInTests: XCTestCase {

    func test_Field_FormattingAndDictionary() {
        let field = makeDummyField(price: 150000)
        XCTAssertEqual(field.priceFormatted, "Rp 150.000/jam")
        XCTAssertEqual(makeDummyField(price: 1000000).priceFormatted, "Rp 1.000.000/jam")
        XCTAssertEqual(field.coordinate.latitude, -7.2878, accuracy: 0.0001)
        
        let dict = field.toDictionary()
        XCTAssertEqual(dict["sport"] as? String, "Basketball")
        
        let restored = Field.fromDictionary(dict, id: field.id)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.name, field.name)
        
        var invalidDict = dict
        invalidDict.removeValue(forKey: "name")
        XCTAssertNil(Field.fromDictionary(invalidDict, id: "test"))
    }

    func test_Booking_LogicAndDictionary() {
        let booking = makeDummyBooking(startHour: 8, endHour: 11)
        XCTAssertEqual(booking.durationHours, 3)
        XCTAssertEqual(booking.timeFormatted, "8:00 – 11:00")
        XCTAssertFalse(booking.dateFormatted.isEmpty)
        
        let dict = booking.toDictionary()
        XCTAssertEqual(dict["status"] as? String, "Confirmed")
        XCTAssertNotNil(Booking.fromDictionary(dict, id: booking.id))
        
        var invalidDict = dict
        invalidDict.removeValue(forKey: "fieldId")
        XCTAssertNil(Booking.fromDictionary(invalidDict, id: "test"))
    }

    func test_Chat_Models() {
        let msg = ChatMessage(id: "1", senderId: "u1", senderName: "A", senderRole: .user, text: "Hi", timestamp: Date())
        XCTAssertNotNil(msg.toDictionary()["senderRole"])
        XCTAssertEqual(MessageSender.fieldKeeper.rawValue, "fieldKeeper")
        
        let room = ChatRoom(id: "r1", fieldId: "f1", fieldName: "G", userId: "u1", userName: "D", keeperId: "k1", lastMessage: "H", lastUpdated: Date(), unreadCount: 2)
        XCTAssertNotNil(ChatRoom.fromDictionary(room.toDictionary(), id: room.id))
    }

    func test_UserAndEnums() {
        let user = makeDummyUser(role: .fieldKeeper, sports: [.basketball: .pro, .football: .intermediate])
        let dict = user.toDictionary()
        XCTAssertEqual(dict["role"] as? String, "fieldKeeper")
        XCTAssertEqual((dict["sports"] as? [String: String])?["Basketball"], "Pro")
        XCTAssertEqual(UserRole.superAdmin.rawValue, "superAdmin")
        XCTAssertEqual(UserRole(rawValue: "user"), .user)
        XCTAssertEqual(SportType.basketball.rawValue, "Basketball")
        XCTAssertEqual(SkillLevel.beginner.rawValue, "Pemula")
    }

    func test_BusinessLogic_CalculationsAndFilters() {
        XCTAssertEqual(300000 / 3, 100000)
        XCTAssertEqual(makeDummyField(price: 150000).pricePerHour * 2, 300000)
        
        let available = Array(7..<12).filter { ![8, 9, 10].contains($0) }
        XCTAssertEqual(available, [7, 11])
    
        let fields = [makeDummyField(id: "1", name: "GOR Ciputra", sport: .basketball), makeDummyField(id: "2", name: "Futsal Galaxy", sport: .football)]
        XCTAssertEqual(fields.filter { $0.sport == .basketball }.count, 1)
        XCTAssertEqual(fields.filter { $0.name.localizedCaseInsensitiveContains("galaxy") }.first?.id, "2")
    }

    func test_MatchmakingAndStats() {
        let booking = makeDummyBooking(isMatchmaking: true, maxPlayers: 4)
        XCTAssertEqual(booking.maxPlayers - booking.playerIds.count, 3)
        
        let users = [makeDummyUser(role: .user), makeDummyUser(role: .fieldKeeper)]
        XCTAssertEqual(users.filter { $0.role == .user }.count, 1)
        
        let bookings = [makeDummyBooking(totalPrice: 200000, status: .confirmed), makeDummyBooking(totalPrice: 150000, status: .cancelled)]
        let revenue = bookings.filter { $0.status == .confirmed }.reduce(0) { $0 + $1.totalPrice }
        XCTAssertEqual(revenue, 200000)
    }

    func test_Performances() {
        let fields = (0..<500).map { makeDummyField(id: "\($0)", sport: $0 % 2 == 0 ? .basketball : .football) }
        measure {
            _ = fields.filter { $0.sport == .basketball }
        }
    }
}
