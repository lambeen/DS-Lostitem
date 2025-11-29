//
//  AuctionCommentDetail_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

// MARK: - 서버 댓글 DTO (경매용)
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

// MARK: - View
struct AuctionCommentDetail_View: View {
    // 상단 요약용 정보 (경매 물품 정보)
    let itemName: String
    let statusText: String     // "경매중", "경매예정" 등
    let endDate: String        // "2025-11-02" 같은 문자열
    
    let itemPkey: Int          // Items.pkey (Auctions.item_pkey와 동일)
    let loginUserPkey: Int     // 로그인 사용자 pkey
    
    @Environment(\.dismiss) private var dismiss
    
    // 공통 포인트 컬러
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    // 서버에서 받아온 전체 댓글(루트 + 대댓글)
    @State private var comments: [AuctionCommentDTO] = []
    
    // 입력/상태
    @State private var inputText: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    
    // 대댓글/수정 상태
    @State private var replyingTo: AuctionCommentDTO? = nil
    @State private var editingTarget: AuctionCommentDTO? = nil
    
    // UI 상태: 어떤 댓글이 선택되었는지 (버튼 노출용)
    @State private var selectedCommentId: Int? = nil
    
    // 페이지네이션 상태
    @State private var currentPage: Int = 0
    private let pageSize: Int = 6
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 뒤로가기 + 제목
            headerBar
            
            // 상단 경매 요약 (썸네일 + 타이틀 + 상태/종료일)
            itemSummarySection
            
            Divider()
            
            // 댓글 리스트
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if comments.isEmpty {
                        Text("아직 등록된 댓글이 없습니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(pagedComments, id: \.comment.pkey) { item in
                            commentBlock(item.comment,
                                         isReply: item.isReply)
                        }
                        
                        // 페이지 이동 컨트롤
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
            
            // 입력 영역
            inputArea
        }
        .navigationBarHidden(true)
        .task {
            await loadComments()
        }
    }
    
    // MARK: - 상단 바
    private var headerBar: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
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
    
    // MARK: - 상단 경매 요약 섹션
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
    
    // MARK: - 댓글 하나 블럭
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
                            accent.opacity(
                                selectedCommentId == c.pkey ? 0.8 : 0.3
                            ),
                            lineWidth: selectedCommentId == c.pkey ? 1.5 : 1
                        )
                )
            
            if selectedCommentId == c.pkey {
                HStack(spacing: 12) {
                    // 답글 달기
                    Button {
                        replyingTo = c
                        editingTarget = nil
                        inputText = ""
                    } label: {
                        Text("답글")
                            .font(.caption)
                            .foregroundColor(accent)
                    }
                    
                    // 내 댓글일 때만 수정/삭제
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
                            Task {
                                await deleteComment(c)
                            }
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
            if selectedCommentId == c.pkey {
                selectedCommentId = nil
            } else {
                selectedCommentId = c.pkey
            }
        }
        .padding(.leading, isReply ? 24 : 0) // 대댓글 들여쓰기
    }
    
    // MARK: - 입력 영역
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
                } else if let _ = replyingTo {
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
                    Task {
                        await submit()
                    }
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
    
    // MARK: - 플랫 리스트 + 페이지 계산
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
        guard total > 0 else { return 1 }
        return Int(ceil(Double(total) / Double(pageSize)))
    }
    
    private var pagedComments: [(comment: AuctionCommentDTO, isReply: Bool)] {
        let all = flattenedComments
        guard !all.isEmpty else { return [] }
        
        let start = currentPage * pageSize
        let end = min(start + pageSize, all.count)
        if start >= end { return [] }
        return Array(all[start..<end])
    }
    
    // MARK: - 작성자 라벨
    private func authorLabel(for c: AuctionCommentDTO, isReply: Bool) -> String {
        let base: String = (c.userPkey == loginUserPkey) ? "익명(나)" : "익명"
        return isReply ? "\(base) · 대댓글" : base
    }
    
    // MARK: - 네트워크: 목록 조회 (경매용)
    private func loadComments() async {
        guard let url = URL(string: "\(API.auctionComment)?item_pkey=\(itemPkey)") else {
            await MainActor.run {
                self.errorMessage = "서버 주소 오류"
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let raw = String(data: data, encoding: .utf8) {
                print("경매 댓글 목록 응답:", raw)
            }
            
            let decoded = try JSONDecoder().decode([AuctionCommentDTO].self, from: data)
            
            await MainActor.run {
                self.comments = decoded
                self.isLoading = false
                self.currentPage = 0
                self.selectedCommentId = nil
            }
        } catch {
            print("loadComments error:", error)
            await MainActor.run {
                self.errorMessage = "댓글 로드 중 오류가 발생했습니다."
                self.comments = []
                self.isLoading = false
                self.currentPage = 0
                self.selectedCommentId = nil
            }
        }
    }
    
    // MARK: - 네트워크: 등록/수정 공통
    private func submit() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        if let editing = editingTarget {
            await updateComment(editing, newText: text)
        } else {
            let parentId = replyingTo?.pkey ?? 0
            await insertComment(text: text, parent: parentId)
        }
    }
    
    // 댓글/대댓글 등록 (경매용)
    private func insertComment(text: String, parent: Int) async {
        guard let url = URL(string: API.auctionComment) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "action", value: "insert"),
            URLQueryItem(name: "user_pkey", value: "\(loginUserPkey)"),
            URLQueryItem(name: "item_pkey", value: "\(itemPkey)"),
            URLQueryItem(name: "comment", value: text),
            URLQueryItem(name: "parent", value: "\(parent)")
        ]
        request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let raw = String(data: data, encoding: .utf8) {
                print("auction insert 응답:", raw)
            }
            
            await MainActor.run {
                self.inputText = ""
                self.replyingTo = nil
                self.editingTarget = nil
            }
            await loadComments()
        } catch {
            print("insertComment error:", error)
            await MainActor.run {
                self.errorMessage = "댓글 등록 중 오류가 발생했습니다."
            }
        }
    }
    
    // 댓글 수정 (경매용)
    private func updateComment(_ comment: AuctionCommentDTO, newText: String) async {
        guard let url = URL(string: API.auctionComment) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "action", value: "update"),
            URLQueryItem(name: "pkey", value: "\(comment.pkey)"),
            URLQueryItem(name: "user_pkey", value: "\(loginUserPkey)"),
            URLQueryItem(name: "comment", value: newText)
        ]
        request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let raw = String(data: data, encoding: .utf8) {
                print("auction update 응답:", raw)
            }
            
            await MainActor.run {
                self.inputText = ""
                self.editingTarget = nil
            }
            await loadComments()
        } catch {
            print("updateComment error:", error)
            await MainActor.run {
                self.errorMessage = "댓글 수정 중 오류가 발생했습니다."
            }
        }
    }
    
    // 댓글 삭제 (경매용)
    private func deleteComment(_ comment: AuctionCommentDTO) async {
        guard let url = URL(string: API.auctionComment) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "action", value: "delete"),
            URLQueryItem(name: "pkey", value: "\(comment.pkey)"),
            URLQueryItem(name: "user_pkey", value: "\(loginUserPkey)")
        ]
        request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let raw = String(data: data, encoding: .utf8) {
                print("auction delete 응답:", raw)
            }
            await loadComments()
        } catch {
            print("deleteComment error:", error)
            await MainActor.run {
                self.errorMessage = "댓글 삭제 중 오류가 발생했습니다."
            }
        }
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
