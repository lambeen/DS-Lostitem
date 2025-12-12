//
//  AuctionCommentDetail_View.swift
//  MacCheese
//
//  경매 물품 댓글 화면
//

import SwiftUI

// 서버에서 받아오는 댓글 데이터
struct AuctionCommentDTO: Identifiable, Decodable {
    let pkey: Int           // 댓글 번호
    let userPkey: Int       // 작성자 사용자 키
    let comment: String     // 내용
    let parent: Int         // 부모 댓글 번호(0이면 원댓글)
    let createdDate: String // 작성 시간
    
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
    // 경매 물품 정보
    let itemName: String
    let statusText: String
    let endDate: String
    
    // 물품 키 / 로그인 사용자 키
    let itemPkey: Int
    let loginUserPkey: Int
    
    @Environment(\.dismiss) private var dismiss
    
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    // 댓글 목록
    @State private var comments: [AuctionCommentDTO] = []
    
    // 입력/표시 상태
    @State private var inputText: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    
    // 대댓글/수정 상태
    @State private var replyingTo: AuctionCommentDTO? = nil
    @State private var editingTarget: AuctionCommentDTO? = nil
    
    // 선택된 댓글
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
                        ForEach(pagedComments, id: \.comment.pkey) { item in
                            commentBlock(item.comment, isReply: item.isReply)
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
        .navigationBarHidden(true)
        .onAppear {
            loadComments()
        }
    }
    
    private var headerBar: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
            }
            
            Text("경매 댓글")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(accent)
    }
    
    private var itemSummarySection: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(itemName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text("상태: \(statusText)")
                    .font(.caption)
                
                Text("종료일: \(endDate)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }
    
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
                    Button {
                        replyingTo = c
                        editingTarget = nil
                        inputText = ""
                    } label: {
                        Text("답글")
                            .font(.caption)
                            .foregroundColor(accent)
                    }
                    
                    if c.userPkey == loginUserPkey {
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
    
    private var rootComments: [AuctionCommentDTO] {
        comments.filter { $0.parent == 0 }
    }
    
    private func children(of comment: AuctionCommentDTO) -> [AuctionCommentDTO] {
        comments.filter { $0.parent == comment.pkey }
    }
    
    private var flattenedComments: [(comment: AuctionCommentDTO, isReply: Bool)] {
        var result: [(AuctionCommentDTO, Bool)] = []
        for root in rootComments {
            result.append((root, false))
            for child in children(of: root) {
                result.append((child, true))
            }
        }
        return result
    }
    
    private var totalPages: Int {
        let total = flattenedComments.count
        if total <= 0 { return 1 }
        return Int(ceil(Double(total) / Double(pageSize)))
    }
    
    private var pagedComments: [(comment: AuctionCommentDTO, isReply: Bool)] {
        let all = flattenedComments
        if all.isEmpty { return [] }
        
        let start = currentPage * pageSize
        let end = min(start + pageSize, all.count)
        if start >= end { return [] }
        return Array(all[start..<end])
    }
    
    private func authorLabel(for c: AuctionCommentDTO, isReply: Bool) -> String {
        let base = (c.userPkey == loginUserPkey) ? "익명(나)" : "익명"
        return isReply ? "\(base) · 대댓글" : base
    }
    
    private func loadComments() {
        guard let url = URL(string: "\(API.auctionComment)?item_pkey=\(itemPkey)") else {
            self.errorMessage = "서버 주소 오류"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { data, response, error in
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
                }
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("경매 댓글 목록 응답:", raw)
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("insertComment error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "댓글 등록 중 오류가 발생했습니다."
                }
                return
            }
            
            if let data = data, let raw = String(data: data, encoding: .utf8) {
                print("auction insert 응답:", raw)
            }
            
            DispatchQueue.main.async {
                self.inputText = ""
                self.replyingTo = nil
                self.editingTarget = nil
            }
            self.loadComments()
        }.resume()
    }
    
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("updateComment error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "댓글 수정 중 오류가 발생했습니다."
                }
                return
            }
            
            if let data = data, let raw = String(data: data, encoding: .utf8) {
                print("auction update 응답:", raw)
            }
            
            DispatchQueue.main.async {
                self.inputText = ""
                self.editingTarget = nil
            }
            self.loadComments()
        }.resume()
    }
    
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("deleteComment error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "댓글 삭제 중 오류가 발생했습니다."
                }
                return
            }
            
            if let data = data, let raw = String(data: data, encoding: .utf8) {
                print("auction delete 응답:", raw)
            }
            
            self.loadComments()
        }.resume()
    }
}

#Preview {
    NavigationStack {
        AuctionCommentDetail_View(
            itemName: "라네즈 크림",
            statusText: "경매중",
            endDate: "2025-11-02",
            itemPkey: 1,
            loginUserPkey: 1
        )
    }
}
