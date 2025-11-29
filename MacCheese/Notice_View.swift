//
//  Notice_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct NoticeSummary: Identifiable, Codable {
    let id: Int
    let title: String
    let date: String
}

struct Notice_View: View {

    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    @State private var notices: [NoticeSummary] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false

    var body: some View {
        VStack(spacing: 0) {

            // 상단 헤더
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text("공지사항")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(accent)

            // 리스트 본문
            List {
                ForEach(notices) { notice in
                    NavigationLink {
                        NoticeDetail_View(noticeId: notice.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notice.title)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text(notice.date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationBarHidden(true)
        .task {
            await fetchNoticeList()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("알림"),
                message: Text(errorMessage ?? "오류가 발생했습니다."),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    // MARK: - 공지 리스트 불러오기
    private func fetchNoticeList() async {
        // 🔹 너 PHP 위치에 맞게 주소만 수정해서 사용
        guard let url = URL(string: "http://localhost/ip3/notice.php") else {
            return
        }

        isLoading = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([NoticeSummary].self, from: data)

            await MainActor.run {
                self.notices = decoded
                self.isLoading = false
            }
        } catch {
            print("fetchNoticeList error:", error)
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "공지 목록을 불러오지 못했습니다."
                self.showAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack { Notice_View() }
}
