//
//  ChatModel.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 03/06/26.
//
import Foundation
import FirebaseFirestore

enum MessageSender: String, Codable {
    case user = "user"
    case fieldKeeper = "fieldKeeper"
}

struct ChatMessage: Identifiable, Codable {
    var id: String
    var senderId: String
    var senderName: String
    var senderRole: MessageSender
    var text: String
    var timestamp: Date

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "senderId": senderId,
            "senderName": senderName,
            "senderRole": senderRole.rawValue,
            "text": text,
            "timestamp": Timestamp(date: timestamp)
        ]
    }

    static func fromDictionary(_ data: [String: Any], id: String) -> ChatMessage? {
        guard
            let senderId = data["senderId"] as? String,
            let senderName = data["senderName"] as? String,
            let roleRaw = data["senderRole"] as? String,
            let role = MessageSender(rawValue: roleRaw),
            let text = data["text"] as? String,
            let timestamp = data["timestamp"] as? Timestamp
        else { return nil }

        return ChatMessage(
            id: id,
            senderId: senderId,
            senderName: senderName,
            senderRole: role,
            text: text,
            timestamp: timestamp.dateValue()
        )
    }
}

struct ChatRoom: Identifiable, Codable {
    var id: String
    var fieldId: String
    var fieldName: String
    var userId: String
    var userName: String
    var keeperId: String
    var lastMessage: String
    var lastUpdated: Date
    var unreadCount: Int

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "fieldId": fieldId,
            "fieldName": fieldName,
            "userId": userId,
            "userName": userName,
            "keeperId": keeperId,
            "lastMessage": lastMessage,
            "lastUpdated": Timestamp(date: lastUpdated),
            "unreadCount": unreadCount
        ]
    }

    static func fromDictionary(_ data: [String: Any], id: String) -> ChatRoom? {
        guard
            let fieldId = data["fieldId"] as? String,
            let fieldName = data["fieldName"] as? String,
            let userId = data["userId"] as? String,
            let userName = data["userName"] as? String,
            let keeperId = data["keeperId"] as? String,
            let lastMessage = data["lastMessage"] as? String,
            let timestamp = data["lastUpdated"] as? Timestamp
        else { return nil }

        return ChatRoom(
            id: id,
            fieldId: fieldId,
            fieldName: fieldName,
            userId: userId,
            userName: userName,
            keeperId: keeperId,
            lastMessage: lastMessage,
            lastUpdated: timestamp.dateValue(),
            unreadCount: data["unreadCount"] as? Int ?? 0
        )
    }
}
