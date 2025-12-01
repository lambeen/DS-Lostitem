//
//  NoticeDetail_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct NoticeDetail: Codable {
    let title: String?
    let intro: String?
    let operationTitle: String?
    let operationContent: String?
    let requiredTitle: String?
    let requiredContent: String?
    let warningTitle: String?
    let warningContent: String?
}

struct NoticeDetail_View: View {

    @Environment(\.dismiss) private var dismiss

    let noticeId: Int

    // 공통 포인트 컬러
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    // 백엔드에서 가져온 공지 데이터
    @State private var notice: NoticeDetail?
    @State private var isLoading: Bool = false
    @State private var alertMessage: String?
    @State private var showAlert: Bool = false

    var body: some View {
        VStack(spacing: 0) {

            // 상단 헤더 (뒤로가기)
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

            // 본문
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    if let intro = notice?.intro {
                        Text(intro)
                    }

                    if let t = notice?.operationTitle {
                        Text(t)
                            .font(.headline)
                            .padding(.top, 4)
                    }
                    if let c = notice?.operationContent {
                        Text(c)
                    }

                    if let t = notice?.requiredTitle {
                        Text(t)
                            .font(.headline)
                            .padding(.top, 4)
                    }
                    if let c = notice?.requiredContent {
                        Text(c)
                    }

                    if let t = notice?.warningTitle {
                        Text(t)
                            .font(.headline)
                            .padding(.top, 4)
                    }
                    if let c = notice?.warningContent {
                        Text(c)
                    }

                }
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .padding(16)
                .background(Color.white)
            }
            .background(Color(.systemGray6))
        }
        .duksungHeaderNav(
            
            title: "덕성여대 공지사항 통합포털", // 붉은 타이틀 바 텍스트

            showSearch: false,                 // 오른쪽 검색 버튼 표시

            hideBackButton: false            // 루트 화면이니까 뒤로가기 숨김

        )
        
        .navigationBarHidden(true)
        .task {
            await fetchNotice()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("알림"),
                message: Text(alertMessage ?? "오류가 발생했습니다."),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    // 🔹 서버에서 공지 가져오는 함수
    private func fetchNotice() async {

        guard let url = URL(string: "http://124.56.5.77/maccheese/notice_detail.php?notice_id=\(noticeId)") else {
            return
        }

        isLoading = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(NoticeDetail.self, from: data)

            await MainActor.run {
                self.notice = decoded
                self.isLoading = false
            }
        } catch {
            print("fetchNotice error:", error)
            await MainActor.run {
                self.isLoading = false
                self.alertMessage = "서버에서 공지 내용을 가져오지 못했어요."
                self.showAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        NoticeDetail_View(noticeId: 1)
    }
}
