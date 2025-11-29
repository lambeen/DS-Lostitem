//
//  AuctionList_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

enum AuctionStatus: Int {
    case scheduled = 0
    case cancelled = 1
    case ongoing   = 2
    case finished  = 3
}

// 상태 목록
struct AuctionStatusDTO: Identifiable, Decodable {
    let code: Int
    let label: String
    
    var id: Int { code }
    
    enum CodingKeys: String, CodingKey {
        case code, label
    }
}

// 경매 항목
struct AuctionItemDTO: Identifiable, Decodable {
    let id: Int
    let itemPkey: Int
    let title: String
    let category: String?
    let minPrice: Int
    
    let statusCode: Int
    let statusText: String
    
    let startDate: String?
    let endDate: String?
    let remainingSeconds: Int?
    let photoURL: String?
    
    var statusEnum: AuctionStatus? {
        AuctionStatus(rawValue: statusCode)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "auction_pkey"
        case itemPkey = "item_pkey"
        case title, category
        case minPrice = "min_price"
        
        case statusCode = "status_code"
        case statusText = "status_text"
        
        case startDate = "start_date"
        case endDate = "end_date"
        case remainingSeconds = "remaining_seconds"
        case photoURL = "photo_url"
    }
}

// 전체 응답
struct AuctionListResponseDTO: Decodable {
    let statusList: [AuctionStatusDTO]
    let auctions: [AuctionItemDTO]
    
    enum CodingKeys: String, CodingKey {
        case statusList = "status_list"
        case auctions
    }
}

struct AuctionList_View: View {
    @State private var statusList: [AuctionStatusDTO] = []
    @State private var selectedStatusCode: Int = -1
    
    @State private var auctions: [AuctionItemDTO] = []
    @State private var now = Date()
    
    @State private var currentPage = 1
    private let pageSize = 4
    
    private let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 상태 필터 탭
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(statusList) { s in
                        Button {
                            selectedStatusCode = s.code
                            currentPage = 1
                        } label: {
                            Text(s.label)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedStatusCode == s.code
                                    ? accent.opacity(0.9)
                                    : Color(.systemGray6)
                                )
                                .foregroundColor(selectedStatusCode == s.code ? .white : .primary)
                                .cornerRadius(16)
                        }
                    }

                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // 현재 데이터 개수
            VStack(spacing: 0) {
                Text("현재 경매 개수: \(filteredAuctions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                Divider()
            }
            
            // 리스트 (현재 페이지의 경매만)
            List(pagedAuctions) { auction in
                NavigationLink {
                    AutionItem_Detail1_View(
                        auctionId: auction.id,
                        initialTitle: auction.title   // 리스트에서 쓰던 제목
                    )
                } label: {
                    AuctionRowView(auction: auction, now: now)
                }
                .listRowSeparator(.visible)
            }
            .listStyle(.plain)
            .id(currentPage)
            
            // 페이지 표시 (1 / N 형식)
            HStack(spacing: 16) {
                Button {
                    if currentPage > 1 {
                        currentPage -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(currentPage <= 1)
                
                Text("\(currentPage) / \(totalPages)")
                    .font(.subheadline)
                
                Button {
                    if currentPage < totalPages {
                        currentPage += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(currentPage >= totalPages)
            }
            .padding(.vertical, 8)
            
            Spacer().frame(height: 32)
        }
        .duksungHeaderNav(
            title: "덕성여대 경매포털",
            showSearch: true,
            hideBackButton: true
        )
        .onAppear(perform: loadAuctions)
        .onReceive(timer) { now = $0 }
    }
    
    //그냥 전체목록 보여주기(정렬 조건 없이
    private var filteredAuctions: [AuctionItemDTO] {
        if selectedStatusCode == -1 {
            return auctions
        } else {
            return auctions.filter { $0.statusCode == selectedStatusCode }
        }
    }

    // 정렬순서 경매중 -> 예정 -> 완료 -> 취소 순으로 정렬하기
    private var sortedFilteredAuctions: [AuctionItemDTO] {
        let list = filteredAuctions
        
        // 전체일 때만 정렬, 나머지 카테고리는 DB 순서대로 두기
        if selectedStatusCode == -1 {
            let order: [Int: Int] = [
                2: 0, // 경매중
                0: 1, // 경매예정
                3: 2, // 경매완료
                1: 3  // 경매취소
            ]
            
            return list.sorted { lhs, rhs in
                let lw = order[lhs.statusCode] ?? 99
                let rw = order[rhs.statusCode] ?? 99
                if lw != rw { return lw < rw } // 같은 상태면 최근 경매 먼저
                
                return lhs.id > rhs.id
            }
        } else {
            return list
        }
    }
    
    // 현재 페이지 목록
    private var pagedAuctions: [AuctionItemDTO] {
        let totalList = sortedFilteredAuctions
        let total = totalList.count
        guard total > 0 else { return [] }
        
        let start = (currentPage - 1) * pageSize
        let end = min(start + pageSize, total)
        guard start < end else { return [] }
        
        return Array(totalList[start..<end])
    }

    // 전체 페이지 수
    private var totalPages: Int {
        let count = filteredAuctions.count
        if count == 0 { return 1 }
        return Int(ceil(Double(count) / Double(pageSize)))
    }
    
    // 서버 호출
    private func loadAuctions() {
        guard let url = URL(string: API.auctionList) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil,
                  let data = data
            else { return }
            
            if let decoded = try? JSONDecoder().decode(AuctionListResponseDTO.self, from: data) {
                DispatchQueue.main.async {
                    self.statusList = decoded.statusList
                    self.auctions = decoded.auctions
                    self.currentPage = 1
                    self.selectedStatusCode = -1
                }
            }
        }.resume()
    }
}

// - 한 줄 셀 UI
struct AuctionRowView: View {
    let auction: AuctionItemDTO
    let now: Date
    
    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()
    
    // 경매 상태 Or 타이머 표시 부분
    private var remainingText: String {
        // 경매중일 때만 타이머
        guard auction.statusEnum == .ongoing else { return "" }

        guard let text = auction.endDate,
              let end = AuctionRowView.df.date(from: text) else {
            return "진행중"
        }
        let diff = Int(end.timeIntervalSince(now))
        guard diff > 0 else { return "00:00:00" }
        return formatTime(diff)
    }

    private var statusDisplayText: String {
        switch auction.statusEnum {
        case .ongoing:
            return remainingText.isEmpty ? "진행중" : remainingText
        case .scheduled:
            return "예정"
        case .finished:
            return "종료"
        case .cancelled:
            return "취소"
        case .none:
            return "알수없음"
        }
    }

    private func formatTime(_ s: Int) -> String {
        let days = s / 86400
        let hours = (s % 86400) / 3600
        let minutes = (s % 3600) / 60
        let secs = s % 60
        
        if days > 0 {
            return String(format: "D-%d %02d:%02d:%02d", days, hours, minutes, secs)
        }
        
        return String(format: "%02d:%02d:%02d", hours + days * 24, minutes, secs)
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f.string(from: date)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            
            // 썸네일
            if let urlStr = auction.photoURL,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // 텍스트 영역
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    // 타이틀
                    Text(auction.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // 종료 날짜
                    if let endText = auction.endDate,
                       let end = AuctionRowView.df.date(from: endText) {
                        Text("종료: \(formatShortDate(end))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // 시작가
                    Text("시작가: \(auction.minPrice)원")
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(statusDisplayText)
                        .font(.headline)
                        .multilineTextAlignment(.trailing)
                }
                .frame(minWidth: 60) // 살짝 폭 확보 (옵션)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        AuctionList_View()
    }
}
