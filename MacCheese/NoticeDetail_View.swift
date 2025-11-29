//
//  NoticeDetail_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

// 🔹 서버에서 오는 공지 JSON 구조
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
                VStack(spacing: 16) {

                    // 상단 제목 바
                    VStack(spacing: 0) {
                        Text(notice?.title ?? "유실물 센터 안내 (필수 확인)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(accent)

                        Rectangle()
                            .fill(accent)
                            .frame(height: 4)
                    }

                    // 내용
                    VStack(alignment: .leading, spacing: 12) {

                        Group {
                            Text(notice?.intro ?? "안녕하세요.\n덕성여자대학교 유실물 센터입니다.\n아래 내용을 반드시 확인해 주시기 바랍니다.")
                        }

                        Group {
                            Text(notice?.operationTitle ?? "운영 시간")
                                .font(.headline)
                                .padding(.top, 4)

                            Text(notice?.operationContent ?? "매일 오전 9시부터 오후 6시까지 운영합니다.\n운영 시간 외에는 유실물 수령이 불가합니다.\n센터위치: 캡스 사무실 101호")
                        }

                        Group {
                            Text(notice?.requiredTitle ?? "수령 시 필수 지참물")
                                .font(.headline)
                                .padding(.top, 4)

                            Text(notice?.requiredContent ?? "학생증 필히 지참 (반드시 실물 확인)\n학생증이 없을 경우 아래 신분증으로 대체 가능합니다.\n1. 주민등록증   2. 운전면허증   3. 여권\n단, 사진 캡처본·사본은 인정되지 않습니다.")
                        }

                        Group {
                            Text(notice?.warningTitle ?? "주의사항")
                                .font(.headline)
                                .padding(.top, 4)

                            Text(notice?.warningContent ?? "학생증 또는 인정되는 신분증이 없을 경우 유실물을 인계받지 않습니다. 모든 유실물은 센터를 통해서만 수령 가능하며, 보관 365일 이후에는 경매로 넘어갑니다.\n\n.\n.\n.")
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(Color.white)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(.systemGray6))
        }
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

  
    private func fetchNotice() async {
        
        guard let url = URL(string: "http://localhost/ip3/notice_detail.php") else {
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
