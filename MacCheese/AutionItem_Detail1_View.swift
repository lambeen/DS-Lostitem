//
//  AutionItem_Detail1_View.swift
//  MacCheese
//

import SwiftUI

// MARK: - 입찰 순위 DTO

struct BidRank: Identifiable, Decodable, Equatable {
    let rank: Int
    let studentId: String
    let amount: Int
    
    // 순위 애니메이션용 고유 id
    var id: String { studentId }
    
    enum CodingKeys: String, CodingKey {
        case rank
        case studentId
        case amount
    }
}


struct AuctionBidsResponseDTO: Decodable {
    let bids: [BidRank]
}



struct AuctionItemDetailDTO: Decodable {
    let id: Int
    let itemName: String
    let description: String?
    
    let statusCode: Int
    let statusText: String
    
    let startDate: String?
    let endDate: String?
    let minPrice: Int
    
    let timeLeftSeconds: Int
    let bids: [BidRank]
    let photos: [String]
    
    
    var statusEnum: AuctionStatus? {
        AuctionStatus(rawValue: statusCode)
    }
    
    /// 서버에서 볼 때 종료 상태인지 여부 (취소/완료 + 타이머 0 이하)
    var serverEnded: Bool {
        if let status = statusEnum {
            if status == .cancelled {
                return true
            }
            if status == .finished {
                return true
            }
        }
        if timeLeftSeconds <= 0 {
            return true
        }
        return false
    }
    
    enum CodingKeys: String, CodingKey {
        case id, itemName, description
        case statusCode     = "status_code"
        case statusText     = "status_text"
        case startDate
        case endDate
        case minPrice
        case timeLeftSeconds
        case bids
        case photos
    }
}


struct AutionItem_Detail1_View: View {
    @EnvironmentObject var globalTimer: GlobalTimer
    
    let auctionId: Int           // 어떤 경매인지 (리스트에서 전달)
    let initialTitle: String     // 리스트에서 보이던 제목
    
    @State private var item: AuctionItemDetailDTO?
    @State private var isLoading: Bool = false
    
    // 입찰 순위
    @State private var bidRanks: [BidRank] = []
    
    // 이미지 인덱스 (현재 몇 번째 사진인지)
    @State private var currentPhotoIndex: Int = 0
    
    // 입찰 순위 재조회용 타이머
    private let rankTimer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()
    
    private func calculateRemainingTime(for item: AuctionItemDetailDTO) -> Int {
        guard let endDateString = item.endDate,
              !endDateString.isEmpty,
              let endDate = AutionItem_Detail1_View.dateFormatter.date(from: endDateString) else {
            return 0
        }
        
        let diff = Int(endDate.timeIntervalSince(globalTimer.currentTime))
        return max(0, diff)
    }
    
    // 더미 입찰 데이터
    private let dummyBidRanks: [BidRank] = [
        BidRank(rank: 1, studentId: "20231234", amount: 8000),
        BidRank(rank: 2, studentId: "20234567", amount: 7500),
        BidRank(rank: 3, studentId: "20239876", amount: 7000)
    ]
    
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
   
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading && item == nil {
                Spacer()
                ProgressView("불러오는 중...")
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        if let item = item {
                            // 상단: 제목 / 상태 / 종료날짜 / 타이머
                            VStack(alignment: .leading, spacing: 8) {
                                
                                HStack(alignment: .top) {
                                    // 왼쪽: 리스트에서 쓰던 제목
                                    Text(initialTitle)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    
                                    // 오른쪽: 상태 텍스트
                                    Text("상태: \(item.statusText)")
                                        .font(.subheadline)
                                }
                                
                                // 종료 날짜
                                if let end = item.endDate {
                                    if !end.isEmpty {
                                        Text("종료: \(end)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text(
                                    formatTimeLeft(
                                        seconds: calculateRemainingTime(for: item),
                                        isEnded: isActuallyEnded(item: item)
                                    )
                                )
                                .font(.headline)
                                .foregroundColor(accent)
                                .id(globalTimer.currentTime)
                            }
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                            
                            let photoCount = item.photos.count
                            
                            // 이미지 영역
                            ZStack {
                                HStack {
                                    Spacer()
                                    
                                    if let url = currentPhotoURL(for: item) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color(.systemGray5))
                                        }
                                        .frame(width: 200, height: 200)
                                        .clipped()
                                        .cornerRadius(8)
                                    } else {
                                        // 사진이 없을 때 기본 회색 박스
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: 200, height: 200)
                                            .cornerRadius(8)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    
                                    Spacer()
                                }
                                
                                // 오른쪽 > 버튼 (이미지가 2장 이상일 때만 표시)
                                HStack {
                                    Spacer()
                                    Button {
                                        goNextPhoto(photoCount: photoCount)
                                    } label: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 20))
                                            .foregroundColor(accent)
                                            .padding(.trailing, 16)
                                    }
                                    .opacity(photoCount > 1 ? 1.0 : 0.0)
                                }
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            
                            // ▶ 이미지 인디케이터
                            if photoCount > 0 {
                                Text("\(currentPhotoIndex + 1) / \(photoCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .top)
                            } else {
                                Text("0 / 0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .top)
                            }
                            
                            // 버튼: 진행 중이면 "입찰신청", 종료/취소이면 "입찰종료"
                            if isActuallyEnded(item: item) {
                                NavigationLink(
                                    destination: AuctionEnded_View(auctionId: auctionId)
                                        .environmentObject(globalTimer)
                                ) {
                                    Text("입찰종료")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 150)
                                        .padding()
                                        .background(accent)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                HStack(spacing: 12) {
                                    NavigationLink(destination: BidApply_View()) {
                                        Text("입찰신청")
                                            .font(.system(size: 16, weight: .semibold))
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.white)
                                            .foregroundColor(accent)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(accent, lineWidth: 1)
                                            )
                                    }
                                    
                                    NavigationLink(
                                        destination: AuctionItem_Overview_View(
                                            auctionId: auctionId,
                                            initialTitle: initialTitle
                                        )
                                        .environmentObject(globalTimer)
                                    ) {
                                        Text("상세보기")
                                            .font(.system(size: 16, weight: .semibold))
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(accent)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                            
                            // 입찰 순위
                            VStack(alignment: .leading, spacing: 12) {
                                Text("입찰 순위")
                                    .font(.headline)
                                
                                if sortedRanksToShow.isEmpty {
                                    Text("입찰 내역 없음")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(sortedRanksToShow) { bid in
                                            HStack(spacing: 12) {
                                                // 랭크
                                                Text("\(bid.rank)위")
                                                    .font(.subheadline.weight(.semibold))
                                                    .frame(width: 40, alignment: .leading)
                                                
                                                // 학번
                                                Text(bid.studentId)
                                                    .font(.subheadline)
                                                
                                                Spacer()
                                                
                                                // 입찰가
                                                Text("\(bid.amount)원")
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(accent)
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(.white, lineWidth: 0.1)
                                            )
                                            
                                        }
                                    }
                                    .animation(.easeInOut, value: sortedRanksToShow)
                                    .shadow(radius: 1, y: 1)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            Spacer(minLength: 24)
                            
                        } else {
                            Text("표시할 경매가 없습니다.")
                                .padding(.top, 40)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .duksungHeaderNav(
            title: initialTitle,
            showSearch: false,
            hideBackButton: false
        )
        .onAppear {
            loadAuctionItem()
        }
        .onReceive(rankTimer) { _ in
            loadBids()
        }
    }
    
    // MARK: - 현재 사진 URL 계산
    
    private func currentPhotoURL(for item: AuctionItemDetailDTO) -> URL? {
        let photos = item.photos
        if photos.isEmpty {
            return nil
        }
        
        var safeIndex = currentPhotoIndex
        if safeIndex < 0 {
            safeIndex = 0
        }
        if safeIndex >= photos.count {
            safeIndex = photos.count - 1
        }
        
        let urlString = photos[safeIndex]
        return URL(string: urlString)
    }
    
    private func goNextPhoto(photoCount: Int) {
        if photoCount <= 1 {
            return
        }
        
        let nextIndex = currentPhotoIndex + 1
        
        if nextIndex >= photoCount {
            currentPhotoIndex = 0
        } else {
            currentPhotoIndex = nextIndex
        }
    }
    
    // MARK: - Helper: 종료 화면용 데이터
    
    private func endedItemName(for item: AuctionItemDetailDTO) -> String {
        if item.itemName.isEmpty {
            return initialTitle
        }
        return item.itemName
    }
    
    private func endedThumbURL(for item: AuctionItemDetailDTO) -> String? {
        if item.photos.isEmpty {
            return nil
        }
        return item.photos[0]
    }
    
    private func topBidRank() -> BidRank? {
        if bidRanks.isEmpty {
            return nil
        }
        
        let sorted = bidRanks.sorted { lhs, rhs in
            lhs.rank < rhs.rank
        }
        
        if sorted.isEmpty {
            return nil
        }
        return sorted[0]
    }
    
    // 입찰 순위에 보여줄 배열 (더미 포함)
    private var ranksToShow: [BidRank] {
        if bidRanks.isEmpty {
            return dummyBidRanks
        }
        return bidRanks
    }
    
    // 금액 내림차순 정렬 (낙찰 금액 높은 순)
    private var sortedRanksToShow: [BidRank] {
        ranksToShow.sorted { $0.amount > $1.amount }
    }
    
    // MARK: - 서버 호출
    
    /// 처음 진입 시: 상세 전체 1번 호출
    private func loadAuctionItem() {
        guard let url = URL(string: "\(API.auctionItemDetail)?auction_id=\(auctionId)") else {
            return
        }
        
        if item == nil {
            isLoading = true
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(AuctionItemDetailDTO.self, from: data)
                DispatchQueue.main.async {
                    self.item = decoded
                    
                    withAnimation {
                        self.bidRanks = decoded.bids
                    }
                    
                    self.currentPhotoIndex = 0
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    /// 입찰 순위만 별도 API로 1초마다 재조회
    private func loadBids() {
        guard let url = URL(string: "\(API.auctionBids)?auction_id=\(auctionId)") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {
                return
            }
            
            guard let data = data else {
                return
            }
            
            if let decoded = try? JSONDecoder().decode(AuctionBidsResponseDTO.self, from: data) {
                DispatchQueue.main.async {
                    withAnimation {
                        self.bidRanks = decoded.bids
                    }
                }
            }
        }.resume()
    }

    // MARK: - 남은 시간 포맷 (AuctionList와 동일한 스타일)

    private func formatTime(seconds: Int) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if days > 0 {
            return String(format: "D-%d %02d:%02d:%02d", days, hours, minutes, secs)
        } else {
            let totalHours = hours + days * 24
            return String(format: "%02d:%02d:%02d", totalHours, minutes, secs)
        }
    }
    
    private func formatTimeLeft(seconds: Int, isEnded: Bool) -> String {
        if isEnded {
            return "경매 종료까지 00:00:00:00"
        }
        if seconds <= 0 {
            return "경매 종료까지 00:00:00:00"
        }
        
        let timePart = formatTime(seconds: seconds)
        return "경매 종료까지 \(timePart)"
    }
    
    /// 버튼/타이머에서 사용할 실제 종료 여부 (상태 + 남은 시간 둘 다 반영)
    private func isActuallyEnded(item: AuctionItemDetailDTO) -> Bool {
        if let status = item.statusEnum {
            if status == .cancelled {
                return true
            }
            if status == .finished {
                return true
            }
        }
        if calculateRemainingTime(for: item) <= 0 {
            return true
        }
        return false
    }
}

#Preview {
    NavigationStack {
        AutionItem_Detail1_View(
            auctionId: 1,
            initialTitle: "예시 경매 물품 제목"
        )
        
    }
}
