//
//  Notification_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//
// ****순위에 밀린 항목이므로 기능만 확인할 수 있도록 제작함******
//

import SwiftUI

struct Notification_View: View {
    @State private var notifications: [NotificationItem] = [
        .init(type: "분실물 알림", message: "키워드 '인형' 관련 분실물이 나타났습니다!", date: "09/23 18:25"),
        .init(type: "분실물 알림", message: "키워드 '카드' 관련 분실물이 나타났습니다!", date: "07/19 05:16"),
        .init(type: "경매 알림", message: "즐겨찾기 설정한 ‘발끝 니트’의 경매가 시작되었습니다!", date: "09/23 18:25"),
        .init(type: "경매 알림", message: "핑크 체크 도자컵 낙찰 성공하였습니다!", date: "07/19 05:16"),
        .init(type: "경매 알림", message: "‘더 높은 금액’의 입찰자가 나타났습니다!", date: "07/19 05:16")
    ]

    @State private var showDeleteButtons: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var selectedNotification: NotificationItem? = nil

    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    var body: some View {
        VStack(spacing: 0) {

            topRightTrashButton

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(notifications) { noti in
                        notificationRow(noti)
                        Divider()
                    }
                }
            }

            bottomButtons
        }
        .duksungHeaderNav(
            title: "알림",
            showSearch: false,
            hideBackButton: true
        )
        .alert("삭제하시겠습니까?", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                if let selected = selectedNotification {
                    withAnimation {
                        notifications.removeAll { $0.id == selected.id }
                    }
                }
            }
        } message: {
            Text("선택한 알림이 목록에서 제거됩니다.")
        }
    }

    private var topRightTrashButton: some View {
        HStack {
            Spacer()

            Button {
                withAnimation {
                    showDeleteButtons.toggle()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.headline)
                    .foregroundColor(accent)
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
    }

    private func notificationRow(_ noti: NotificationItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(accent)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("[\(noti.type)] \(noti.message)")
                    .font(.body)
                    .foregroundColor(.primary)

                Text(noti.date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if showDeleteButtons {
                Button {
                    selectedNotification = noti
                    showDeleteAlert = true
                } label: {
                    Text("삭제")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(Color.red)
                        .cornerRadius(6)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: AuctionNotification_View()) {
                Text("경매 알림")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            NavigationLink(destination: KeywordRegister_View()) {
                Text("키워드 등록")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

struct NotificationItem: Identifiable, Equatable {
    let id = UUID()
    let type: String
    let message: String
    let date: String
}

#Preview {
    NavigationStack {
        Notification_View()
    }
}
