//  MyComments_View.swift
//  MacCheese
//

import SwiftUI

// MARK: - 모델

struct MyCommentSummary: Identifiable, Codable {
    let id: Int          // 댓글 pkey
    let content: String  // 댓글 내용
    let date: String     // 댓글 작성일
    let item: LostItemDTO
}

// MARK: - View

struct MyComments_View: View {

    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    @State private var myComments: [MyCommentSummary] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false

    let userPkey: Int

    var body: some View {
        VStack(spacing: 0) {

            // 본문
            Group {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("불러오는 중...")
                        Spacer()
                    }
                } else if let errorMessage {
                    VStack(spacing: 8) {
                        Spacer()
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("다시 시도") {
                            Task { await fetchMyComments() }
                        }
                        .foregroundColor(accent)
                        Spacer()
                    }
                } else if myComments.isEmpty {
                    VStack {
                        Spacer()
                        Text("작성한 댓글이 없습니다.")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(myComments) { comment in
                            NavigationLink {
                                LostDetail_View(
                                    item: comment.item,
                                    userPkey: userPkey
                                )
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(comment.content)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)

                                        Text(comment.date)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .duksungHeaderNav(
            title: "내 댓글",
            showSearch: false,
            hideBackButton: false)
        
        .task {
            await fetchMyComments()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("알림"),
                message: Text(errorMessage ?? "오류가 발생했습니다."),
                dismissButton: .default(Text("확인"))
            )
        }
    }

   

    private func fetchMyComments() async {
      
        guard let baseURL = URL(string: API.myComments),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return
        }

        components.queryItems = [
            URLQueryItem(name: "user_pkey", value: String(userPkey))
        ]

        guard let url = components.url else { return }

        isLoading = true
        errorMessage = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // 디버그용
            if let raw = String(data: data, encoding: .utf8) {
                print("fetchMyComments raw json:", raw)
            }

            let decoded = try JSONDecoder().decode([MyCommentSummary].self, from: data)

            await MainActor.run {
                self.myComments = decoded
                self.isLoading = false
            }
        } catch {
            print("fetchMyComments error:", error)
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "내 댓글 목록을 불러오지 못했습니다."
                self.showAlert = true
            }
        }
    }
}

// MARK: - Preview

struct MyComments_View_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MyComments_View(userPkey: 1)
        }
    }
}
