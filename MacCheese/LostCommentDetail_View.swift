//
//  LostCommentDetail_View.swift
//  MacCheese
//
//  유실물 댓글 화면
//

import SwiftUI

// 댓글 DTO(원댓글/대댓글 공통)
struct LostCommentDTO: Identifiable, Decodable {
    let pkey: Int
    let userPkey: Int
    let comment: String
    let parent: Int
    let createdDate: String

    var id: Int { pkey }

    enum CodingKeys: String, CodingKey {
        case pkey
        case userPkey = "user_pkey"
        case comment
        case parent
        case createdDate = "created_date"
    }
}

struct LostCommentDetail_View: View {

    let item: LostItemDTO
    let userPkey: Int

    private var itemPkey: Int { item.id }
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    @State private var comments: [LostCommentDTO] = []

    @State private var inputText: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    @State private var replyingTo: LostCommentDTO? = nil
    @State private var editingTarget: LostCommentDTO? = nil
    @State private var selectedCommentId: Int? = nil

    @State private var currentPage: Int = 0
    private let pageSize: Int = 6

    @State private var photos: [String] = []

    private var statusText: String {
        switch item.status {
        case 0: return "보관중"
        case 1: return "인계중"
        case 2: return "인계완료"
        case 3: return "경매"
        case 4: return "폐기"
        default: return "알 수 없음"
        }
    }

    // 대표사진(첫 장) 우선, 없으면 item.photoURL 사용
    private var thumbnailURL: String? {
        if let first = photos.first, !first.isEmpty {
            return first
        }
        return item.photoURL
    }

    var body: some View {
        VStack(spacing: 0) {
            itemSummarySection
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("댓글 불러오는 중...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if comments.isEmpty {
                        Text(isLoading ? "" : "아직 등록된 댓글이 없습니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(pagedComments, id: \.0.pkey) { row in
                            commentBlock(row.0, isReply: row.1)
                        }

                        if totalPages > 1 {
                            HStack {
                                Button {
                                    if currentPage > 0 {
                                        currentPage -= 1
                                        selectedCommentId = nil
                                    }
                                } label: {
                                    Text("이전")
                                }
                                .disabled(currentPage == 0)

                                Spacer()

                                Text("\(currentPage + 1) / \(totalPages)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button {
                                    if currentPage < totalPages - 1 {
                                        currentPage += 1
                                        selectedCommentId = nil
                                    }
                                } label: {
                                    Text("다음")
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
        .onAppear {
            loadItemPhotos()
            loadComments()
        }
        .duksungHeaderNav(
            title: "유실물 상세",
            showSearch: false,
            hideBackButton: false
        )
    }

    // 게시글 요약(제목/상태/날짜/대표사진)
    private var itemSummarySection: some View {
        HStack(spacing: 10) {

            if let urlStr = thumbnailURL,
               let url = URL(string: urlStr) {

                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 48, height: 48)
                .clipped()
                .cornerRadius(8)

            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 48, height: 48)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Text("상태: \(statusText)")
                    .font(.caption)

                Text(String(item.createdDate.prefix(10)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }

    // 댓글 1개 표시
    @ViewBuilder
    private func commentBlock(_ c: LostCommentDTO, isReply: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(authorLabel(for: c, isReply: isReply))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(c.createdDate.prefix(10)))
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
                    Button {
                        replyingTo = c
                        editingTarget = nil
                        inputText = ""
                    } label: {
                        Text("답글")
                            .font(.caption)
                            .foregroundColor(accent)
                    }

                    if c.userPkey == userPkey {
                        Button {
                            editingTarget = c
                            replyingTo = nil
                            inputText = c.comment
                        } label: {
                            Text("수정")
                                .font(.caption)
                                .foregroundColor(accent)
                        }

                        Button {
                            deleteComment(c)
                        } label: {
                            Text("삭제")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCommentId = (selectedCommentId == c.pkey) ? nil : c.pkey
        }
        .padding(.leading, isReply ? 24 : 0)
    }

    // 입력 영역
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
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            HStack {
                Spacer()
                Button {
                    submit()
                } label: {
                    Text(
                        editingTarget != nil
                        ? "수정 완료"
                        : (replyingTo != nil ? "답글 등록" : "등록")
                    )
                    .font(.subheadline)
                    .frame(width: 90, height: 34)
                    .background(canSubmit ? accent : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!canSubmit)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 원댓글(parent=0)
    private var rootComments: [LostCommentDTO] {
        comments.filter { $0.parent == 0 }
    }

    // 대댓글 목록
    private func children(of comment: LostCommentDTO) -> [LostCommentDTO] {
        comments.filter { $0.parent == comment.pkey }
    }

    // 표시 순서(원댓글 → 대댓글)
    private var flattenedComments: [(LostCommentDTO, Bool)] {
        var result: [(LostCommentDTO, Bool)] = []
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
        let total = flattenedComments.count
        if total <= 0 { return 1 }
        return Int(ceil(Double(total) / Double(pageSize)))
    }

    // 현재 페이지 댓글
    private var pagedComments: [(LostCommentDTO, Bool)] {
        let all = flattenedComments
        if all.isEmpty { return [] }

        let start = currentPage * pageSize
        let end = min(start + pageSize, all.count)
        if start >= end { return [] }
        return Array(all[start..<end])
    }

    private func authorLabel(for c: LostCommentDTO, isReply: Bool) -> String {
        let base = (c.userPkey == userPkey) ? "익명(나)" : "익명"
        return isReply ? "\(base) · 대댓글" : base
    }

    // 게시글 사진 목록
    private func loadItemPhotos() {
        guard var components = URLComponents(string: API.lostPhotos) else { return }
        components.queryItems = [
            URLQueryItem(name: "item_pkey", value: String(itemPkey))
        ]
        guard let url = components.url else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else { return }

            DispatchQueue.main.async {
                self.photos = decoded
            }
        }.resume()
    }

    // 댓글 목록
    private func loadComments() {
        guard let url = URL(string: "\(API.lostComment)?item_pkey=\(itemPkey)") else {
            self.errorMessage = "서버 주소 오류"
            return
        }

        isLoading = true
        errorMessage = nil

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let _ = error {
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
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode([LostCommentDTO].self, from: data)
                DispatchQueue.main.async {
                    self.comments = decoded
                    self.isLoading = false
                    self.currentPage = 0
                    self.selectedCommentId = nil
                }
            } catch {
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
        guard let url = URL(string: API.lostComment) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        request.httpBody = makeFormBody([
            URLQueryItem(name: "action", value: "insert"),
            URLQueryItem(name: "user_pkey", value: "\(userPkey)"),
            URLQueryItem(name: "item_pkey", value: "\(itemPkey)"),
            URLQueryItem(name: "comment", value: text),
            URLQueryItem(name: "parent", value: "\(parent)")
        ])

        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                self.inputText = ""
                self.replyingTo = nil
                self.editingTarget = nil
            }
            self.loadComments()
        }.resume()
    }

    // 댓글 수정
    private func updateComment(_ comment: LostCommentDTO, newText: String) {
        guard let url = URL(string: API.lostComment) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        request.httpBody = makeFormBody([
            URLQueryItem(name: "action", value: "update"),
            URLQueryItem(name: "pkey", value: "\(comment.pkey)"),
            URLQueryItem(name: "user_pkey", value: "\(userPkey)"),
            URLQueryItem(name: "comment", value: newText)
        ])

        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                self.inputText = ""
                self.editingTarget = nil
            }
            self.loadComments()
        }.resume()
    }

    // 댓글 삭제
    private func deleteComment(_ comment: LostCommentDTO) {
        guard let url = URL(string: API.lostComment) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        request.httpBody = makeFormBody([
            URLQueryItem(name: "action", value: "delete"),
            URLQueryItem(name: "pkey", value: "\(comment.pkey)"),
            URLQueryItem(name: "user_pkey", value: "\(userPkey)")
        ])

        URLSession.shared.dataTask(with: request) { _, _, _ in
            self.loadComments()
        }.resume()
    }
}

#Preview {
    NavigationStack {
        LostCommentDetail_View(
            item: LostItemDTO(
                id: 1,
                title: "금목걸이",
                categoryName: "귀중물",
                placeName: "중앙도서관 3층",
                status: 0,
                createdDate: "2025-01-05 10:00:00",
                photoURL: nil,
                description: "작은 펜던트가 달린 금목걸이로 가족에게 선물 받은 귀중품입니다."
            ),
            userPkey: 1
        )
    }
}
