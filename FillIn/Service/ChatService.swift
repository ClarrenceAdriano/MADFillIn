//
//  ChatService.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 04/06/26.
//

import Foundation
import FirebaseFirestore
class ChatService {
    private let db = Firestore.firestore()
    func listenToMessages(
        chatRoomId: String,
        onUpdate: @escaping ([ChatMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        return db.collection("chats")
            .document(chatRoomId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onError(error)
                    return
                }
                let messages = snapshot?.documents.compactMap {
                    ChatMessage.fromDictionary($0.data(), id: $0.documentID)
                } ?? []
                onUpdate(messages)
            }
    }
    
    func sendMessage(chatRoomId: String, message: ChatMessage, text: String) async throws {
        try await db.collection("chats")
            .document(chatRoomId)
            .collection("messages")
            .document(message.id)
            .setData(message.toDictionary())
        try await db.collection("chatRooms").document(chatRoomId).setData([
            "lastMessage": text,
            "lastUpdated": Timestamp(date: Date())
        ], merge: true)
    }

    func openChatRoom(_ room: ChatRoom) async throws {
        try await db.collection("chatRooms")
            .document(room.id)
            .setData(room.toDictionary(), merge: true)
    }

    func fetchMyChatRooms(userId: String) async throws -> [ChatRoom] {
        let snapshot = try await db.collection("chatRooms")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents
            .compactMap { ChatRoom.fromDictionary($0.data(), id: $0.documentID) }
            .sorted { $0.lastUpdated > $1.lastUpdated }
    }
}
