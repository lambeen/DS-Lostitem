//
//  AuctionCommentDetail_View.swift
//  MacCheese
//
//  경매 댓글 화면
//

import SwiftUI

// 댓글 DTO(원댓글/대댓글 공통)
struct AuctionCommentDTO: Identifiable, Decodable {
    let pkey: Int
    let userPkey: Int
    let comment: String
    let parent: Int
    let createdDate: String

    var id: Int { pkey }

    enum CodingKeys: String, CodingKey {
        case pkey
        case userPkey    = "user_pkey"
        case comment
        case parent
        case createdDate = "created_date"
    }
}

struct AuctionCommentDetail_View: View {

    // 화면 상단 요약에 보여줄 값(제목/상태/종료일)
    let itemName: String
    let statusText: String
    let endDate: String

    // API 요청에 필요한 키
    let itemPkey: Int
    let loginUserPkey: Int

    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    @State private var comments: [AuctionCommentDTO] = []

    @State private var inputText: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    @State private var replyingTo: AuctionCommentDTO? = nil
    @State private var editingTarget: AuctionCommentDTO? = nil
    @State private var selectedCommentId: Int? = nil

    // 페이지
    @State private var currentPage: Int = 0
    private let pageSize: Int = 6

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            itemSummarySection

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if comments.isEmpty {
                        Text(isLoading ? "로딩 중..." : "아직 등록된 댓글이 없습니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(pagedComments, id: \.0.pkey) { row in
                            commentBlock(row.0, isReply: row.1)
                        }

                        if totalPages > 1 {
                            HStack {
                                Button("이전") {
                                    if currentPage > 0 {
                                        currentPage -= 1
                                        selectedCommentId = nil
                                    }
                                }
                                .disabled(currentPage == 0)

                                Spacer()

                                Text("\(currentPage + 1) / \(totalPages)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button("다음") {
                                    if currentPage < totalPages - 1 {
                                        currentPage += 1
                                        selectedCommentId = nil
                                    }
                                }
                                .disabled(currentPage >= totalPages - 1)
                            }
                            .font(.caption)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            Divider()
            inputArea
        }
        .navigationBarHidden(true)
        .onAppear {
            loadComments()
        }
    }

    // 상단 바(뒤로가기/제목)
    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
            }

            Text("경매 댓글")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(accent)
    }

    // 게시글 요약(제목/상태/종료일)
    private var itemSummarySection: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(itemName)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("상태: \(statusText)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                Text("종료일:")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text(endDate)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
    }

    // 댓글 1개 표시(원댓글/대댓글 공통)
    @ViewBuilder
    private func commentBlock(_ c: AuctionCommentDTO, isReply: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(authorLabel(for: c, isReply: isReply))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(c.createdDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(c.comment)
                .font(.system(size: 14))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            accent.opacity(selectedCommentId == c.pkey ? 0.8 : 0.3),
                            lineWidth: selectedCommentId == c.pkey ? 1.5 : 1
                        )
                )

            if selectedCommentId == c.pkey {
                HStack(spacing: 12) {
                    Button("답글") {
                        replyingTo = c
                        editingTarget = nil
                        inputText = ""
                    }
                    .font(.caption)
                    .foregroundColor(accent)

                    if c.userPkey == loginUserPkey {
                        Button("수정") {
                            editingTarget = c
                            replyingTo = nil
                            inputText = c.comment
                        }
                        .font(.caption)
                        .foregroundColor(accent)

                        Button("삭제") {
                            deleteComment(c)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }

                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .padding(.leading, isReply ? 24 : 0)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCommentId = selectedCommentId == c.pkey ? nil : c.pkey
        }
    }

    // 입력 영역(등록/답글/수정)
    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack {
                if editingTarget != nil {
                    Text("내 댓글 수정 중")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("취소") {
                        editingTarget = nil
                        inputText = ""
                    }
                    .font(.footnote)

                } else if replyingTo != nil {
                    Text("대댓글 작성 중")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("취소") {
                        replyingTo = nil
                        inputText = ""
                    }
                    .font(.footnote)

                } else {
                    Text("댓글 추가")
                        .font(.subheadline)
                        .bold()
                }
            }

            TextEditor(text: $inputText)
                .frame(minHeight: 44, maxHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3))
                )

            HStack {
                Spacer()
                Button(editingTarget != nil ? "수정 완료" : (replyingTo != nil ? "답글 등록" : "등록")) {
                    submit()
                }
                .font(.subheadline)
                .frame(width: 90, height: 34)
                .background(canSubmit ? accent : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(!canSubmit)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 원댓글(parent=0)
    private var rootComments: [AuctionCommentDTO] {
        comments.filter { $0.parent == 0 }
    }

    // 대댓글 목록
    private func children(of c: AuctionCommentDTO) -> [AuctionCommentDTO] {
        comments.filter { $0.parent == c.pkey }
    }

    // 표시 순서(원댓글 → 대댓글)
    private var flattenedComments: [(AuctionCommentDTO, Bool)] {
        var result: [(AuctionCommentDTO, Bool)] = []
        for root in rootComments {
            result.append((root, false))
            for child in children(of: root) {
                result.append((child, true))
            }
        }
        return result
    }

    // 페이지 수
    private var totalPages: Int {
        max(1, Int(ceil(Double(flattenedComments.count) / Double(pageSize))))
    }

    // 현재 페이지 댓글
    private var pagedComments: [(AuctionCommentDTO, Bool)] {
        let start = currentPage * pageSize
        let end = min(start + pageSize, flattenedComments.count)
        return start < end ? Array(flattenedComments[start..<end]) : []
    }

    private func authorLabel(for c: AuctionCommentDTO, isReply: Bool) -> String {
        let base = (c.userPkey == loginUserPkey) ? "익명(나)" : "익명"
        return isReply ? "\(base) · 대댓글" : base
    }

    // 댓글 목록
    private func loadComments() {
        guard let url = URL(string: "\(API.auctionComment)?item_pkey=\(itemPkey)") else {
            self.errorMessage = "서버 주소 오류"
            return
        }

        isLoading = true
        errorMessage = nil

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("loadComments error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "댓글 로드 중 오류가 발생했습니다."
                    self.comments = []
                    self.isLoading = false
                    self.currentPage = 0
                    self.selectedCommentId = nil
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "서버 응답이 비어있습니다."
                    self.comments = []
                    self.isLoading = false
                    self.currentPage = 0
                    self.selectedCommentId = nil
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode([AuctionCommentDTO].self, from: data)
                DispatchQueue.main.async {
                    self.comments = decoded
                    self.isLoading = false
                    self.currentPage = 0
                    self.selectedCommentId = nil
                }
            } catch {
                print("decode error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "댓글 로드 중 오류가 발생했습니다."
                    self.comments = []
                    self.isLoading = false
                    self.currentPage = 0
                    self.selectedCommentId = nil
                }
            }
        }.resume()
    }

    // 등록/수정 분기
    private func submit() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return }

        if let editing = editingTarget {
            updateComment(editing, newText: text)
        } else {
            let parentId = replyingTo?.pkey ?? 0
            insertComment(text: text, parent: parentId)
        }
    }

    private func makeFormBody(_ items: [URLQueryItem]) -> Data? {
        var comps = URLComponents()
        comps.queryItems = items
        return comps.percentEncodedQuery?.data(using: .utf8)
    }

    // 댓글 등록
    private func insertComment(text: String, parent: Int) {
        guard let url = URL(string: API.auctionComment) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        request.httpBody = makeFormBody([
            URLQueryItem(name: "action", value: "insert"),
            URLQueryItem(name: "user_pkey", value: "\(loginUserPkey)"),
            URLQueryItem(name: "item_pkey", value: "\(itemPkey)"),
            URLQueryItem(name: "comment", value: text),
            URLQueryItem(name: "parent", value: "\(parent)")
        ])

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("insertComment error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "댓글 등록 중 오류가 발생했습니다."
                }
                return
            }

            DispatchQueue.main.async {
                self.inputText = ""
                self.replyingTo = nil
                self.editingTarget = nil
            }
            self.loadComments()
        }.resume()
    }

    // 댓글 수정
    private func updateComment(_ comment: AuctionCommentDTO, newText: String) {
        guard let url = URL(string: API.auctionComment) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        request.httpBody = makeFormBody([
            URLQueryItem(name: "action", value: "update"),
            URLQueryItem(name: "pkey", value: "\(comment.pkey)"),
            URLQueryItem(name: "user_pkey", value: "\(loginUserPkey)"),
            URLQueryItem(name: "comment", value: newText)
        ])

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("updateComment error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "댓글 수정 중 오류가 발생했습니다."
                }
                return
            }

            DispatchQueue.main.async {
                self.inputText = ""
                self.editingTarget = nil
            }
            self.loadComments()
        }.resume()
    }

    // 댓글 삭제
    private func deleteComment(_ comment: AuctionCommentDTO) {
        guard let url = URL(string: API.auctionComment) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        request.httpBody = makeFormBody([
            URLQueryItem(name: "action", value: "delete"),
            URLQueryItem(name: "pkey", value: "\(comment.pkey)"),
            URLQueryItem(name: "user_pkey", value: "\(loginUserPkey)")
        ])

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("deleteComment error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "댓글 삭제 중 오류가 발생했습니다."
                }
                return
            }

            self.loadComments()
        }.resume()
    }
}

#Preview {
    NavigationStack {
        AuctionCommentDetail_View(
            itemName: "은색 팔찌",
            statusText: "경매중",
            endDate: "2025-12-30 09:17:28",
            itemPkey: 1,
            loginUserPkey: 1
        )
    }
}
