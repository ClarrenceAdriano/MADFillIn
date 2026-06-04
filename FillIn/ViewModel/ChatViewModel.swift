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
    private let service = ChatService()
    private var listener: ListenerRegistration?
    deinit {
        listener?.remove()
    }
    func listenToMessages(chatRoomId: String) {
        listener?.remove()
        isLoading = true
        listener = service.listenToMessages(
            chatRoomId: chatRoomId,
            onUpdate: { [weak self] messages in
                guard let self = self else { return }
                self.isLoading = false
                self.messages = messages
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        )
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
            try await service.sendMessage(chatRoomId: chatRoomId, message: msg, text: text)
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
        try? await service.openChatRoom(room)
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
        try? await service.openChatRoom(room)
        return roomId
    }
    func fetchMyChatRooms(userId: String) async {
        isLoading = true
        do {
            chatRooms = try await service.fetchMyChatRooms(userId: userId)
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
