//
//  ChatView.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 03/06/26.
//

import SwiftUI

struct ChatView: View {
    var field: Field
    var currentUser: FillInUser

    @StateObject private var chatVM = ChatViewModel()
    @State private var chatRoomId: String = ""
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }

                    ZStack {
                        Circle()
                            .fill(Color(hex: "3B82F6").opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "building.2")
                            .foregroundColor(Color(hex: "3B82F6"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(field.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Field Keeper")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: "0F172A"))
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1),
                    alignment: .bottom
                )

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if chatVM.isLoading && chatVM.messages.isEmpty {
                                ProgressView().tint(Color(hex: "3B82F6"))
                                    .padding(.top, 40)
                            } else if chatVM.messages.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.2))
                                    Text("Start the conversation!")
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("Ask about facilities, availability, or anything else.")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.25))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 60)
                            } else {
                                ForEach(chatVM.messages) { msg in
                                    MessageBubble(
                                        message: msg,
                                        isMe: msg.senderId == currentUser.uid
                                    )
                                    .id(msg.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.bottom, 8)
                    }
                    .onChange(of: chatVM.messages.count) { _ in
                        if let last = chatVM.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                if chatVM.messages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickReplies, id: \.self) { reply in
                                Button {
                                    messageText = reply
                                } label: {
                                    Text(reply)
                                        .font(.caption.bold())
                                        .foregroundColor(Color(hex: "3B82F6"))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(hex: "3B82F6").opacity(0.1))
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color(hex: "3B82F6").opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }

                HStack(spacing: 10) {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .lineLimit(1...4)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(20)
                        .focused($isFocused)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color.white.opacity(0.1)
                                        : Color(hex: "3B82F6"))
                            .clipShape(Circle())
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "0F172A"))
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .navigationBarHidden(true)
        .task {
            chatRoomId = await chatVM.openChatRoom(field: field, user: currentUser)
            chatVM.listenToMessages(chatRoomId: chatRoomId)
        }
        .onDisappear {
            chatVM.stopListening()
        }
    }

    var quickReplies: [String] {
        [
            "Is the field available?",
            "What facilities are included?",
            "Do you have parking?",
            "Can I bring my own equipment?"
        ]
    }

    func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !chatRoomId.isEmpty else { return }
        messageText = ""
        Task {
            await chatVM.sendMessage(
                chatRoomId: chatRoomId,
                text: trimmed,
                sender: currentUser,
                role: .user
            )
        }
    }
}

struct MessageBubble: View {
    var message: ChatMessage
    var isMe: Bool

    var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: message.timestamp)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 60) }

            if !isMe {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "building.2")
                        .font(.caption)
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(message.senderName)
                        .font(.caption2.bold())
                        .foregroundColor(.white.opacity(0.4))
                }

                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMe ? Color(hex: "3B82F6") : Color.white.opacity(0.1))
                    .cornerRadius(isMe ? 20 : 20,
                                  corners: isMe
                                  ? [.topLeft, .topRight, .bottomLeft]
                                  : [.topLeft, .topRight, .bottomRight])

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    let dummyField = Field(
        id: "preview-field-1",
        name: "GOR Bola Basket Ciputra",
        address: "Jl. Citraland, Surabaya",
        sport: .basketball,
        pricePerHour: 150000,
        latitude: -7.2878,
        longitude: 112.6688,
        openHour: 7,
        closeHour: 22,
        ownerId: "keeper-123",
        imageUrl: "",
        rating: 4.7,
        totalReviews: 34
    )

    let dummyUser = FillInUser(
        uid: "user-preview-1",
        fullName: "Dylan Patrick",
        email: "dylan@email.com",
        sports: [.basketball: .pro],
        createdAt: Date()
    )

    ChatView(field: dummyField, currentUser: dummyUser)
}
