//
//  ChatViewModel.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 03/06/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var chatRooms: [ChatRoom] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    func listenToMessages(chatRoomId: String) {
        listener?.remove()
        isLoading = true

        listener = db.collection("chats")
            .document(chatRoomId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }

                self.messages = snapshot?.documents.compactMap {
                    ChatMessage.fromDictionary($0.data(), id: $0.documentID)
                } ?? []
            }
    }

    func sendMessage(chatRoomId: String, text: String, sender: FillInUser, role: MessageSender) async {
        let msgId = UUID().uuidString
        let msg = ChatMessage(
            id: msgId,
            senderId: sender.uid,
            senderName: sender.fullName,
            senderRole: role,
            text: text,
            timestamp: Date()
        )

        do {
            try await db.collection("chats")
                .document(chatRoomId)
                .collection("messages")
                .document(msgId)
                .setData(msg.toDictionary())

            try await db.collection("chatRooms").document(chatRoomId).setData([
                "lastMessage": text,
                "lastUpdated": Timestamp(date: Date())
            ], merge: true)

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func openChatRoom(field: Field, user: FillInUser) async -> String {
        let roomId = "\(field.id)_\(user.uid)"

        let room = ChatRoom(
            id: roomId,
            fieldId: field.id,
            fieldName: field.name,
            userId: user.uid,
            userName: user.fullName,
            keeperId: field.ownerId,
            lastMessage: "",
            lastUpdated: Date(),
            unreadCount: 0
        )

        try? await db.collection("chatRooms")
            .document(roomId)
            .setData(room.toDictionary(), merge: true)

        return roomId
    }

    func openChatRoomForBooking(booking: Booking, currentUser: FillInUser) async -> String {
        let roomId = "\(booking.fieldId)_\(booking.userId)"

        let room = ChatRoom(
            id: roomId,
            fieldId: booking.fieldId,
            fieldName: booking.fieldName,
            userId: booking.userId,
            userName: booking.userName,
            keeperId: currentUser.role == .fieldKeeper ? currentUser.uid : "",
            lastMessage: "",
            lastUpdated: Date(),
            unreadCount: 0
        )

        try? await db.collection("chatRooms")
            .document(roomId)
            .setData(room.toDictionary(), merge: true)

        return roomId
    }

    func fetchMyChatRooms(userId: String) async {
        isLoading = true
        do {
            let snapshot = try await db.collection("chatRooms")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            chatRooms = snapshot.documents
                .compactMap { ChatRoom.fromDictionary($0.data(), id: $0.documentID) }
                .sorted { $0.lastUpdated > $1.lastUpdated }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        messages = []
    }
}
