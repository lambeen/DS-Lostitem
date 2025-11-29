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

// MARK: - 경매 상세 DTO

struct AuctionItemDetailDTO: Decodable {
    let id: Int
    let itemName: String
    
    let statusCode: Int
    let statusText: String
    
    let startDate: String?
    let endDate: String?
    let minPrice: Int
    
    let timeLeftSeconds: Int
    let bids: [BidRank]
    let photos: [String]
    
    // 숫자 상태 → 공용 enum 매핑
    var statusEnum: AuctionStatus? {
        AuctionStatus(rawValue: statusCode)
    }
    
    /// 서버에서 볼 때 종료 상태인지 여부 (취소/완료 + 타이머 0 이하)
    var serverEnded: Bool {
        if let status = statusEnum {
            if status == .cancelled || status == .finished {
                return true
            }
        }
        return timeLeftSeconds <= 0
    }
    
    enum CodingKeys: String, CodingKey {
        case id, itemName
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

// MARK: - 경매 상세 화면

struct AutionItem_Detail1_View: View {
    
    let auctionId: Int           // 어떤 경매인지 (리스트에서 전달)
    let initialTitle: String     // 리스트에서 보이던 제목
    
    @State private var item: AuctionItemDetailDTO?
    @State private var isLoading: Bool = false
    
    // 타이머용 남은 시간(초) - 이 값만 줄여나감
    @State private var remainingTime: Int = 0
    
    // 입찰 순위
    @State private var bidRanks: [BidRank] = []
    
    // 이미지 인덱스 (현재 몇 번째 사진인지)
    @State private var currentPhotoIndex: Int = 0
    
    // 1초마다 타이머 감소
    private let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()
    
    // 3초마다 입찰 순위 재조회 (실시간 갱신 흉내)
    private let rankTimer = Timer.publish(
        every: 3,
        on: .main,
        in: .common
    ).autoconnect()
    
    // 더미 입찰 데이터 (서버에 아무 것도 없을 때 화면용)
    private let dummyBidRanks: [BidRank] = [
        BidRank(rank: 1, studentId: "20231234", amount: 8000),
        BidRank(rank: 2, studentId: "20234567", amount: 7500),
        BidRank(rank: 3, studentId: "20239876", amount: 7000)
    ]
    
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
                                if let end = item.endDate, !end.isEmpty {
                                    Text("종료: \(end)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // 실시간 타이머 (AuctionList 포맷 맞춰서)
                                Text(formatTimeLeft(remainingTime,
                                                    isEnded: isActuallyEnded(item)))
                                    .font(.headline)
                                    .foregroundColor(accent)
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
                                
                                // 오른쪽 > 버튼 (이미지가 2장 이상일 때만 표시, 위치는 고정)
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
                                    .opacity(photoCount > 1 ? 1 : 0)
                                }
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            
                            // ▶ 이미지 인디케이터: 이미지 하단에 깔끔하게 배치
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
                            let isEnded = isActuallyEnded(item)
                            
                            if isEnded {
                                // 입찰종료 버튼
                                NavigationLink(destination: AuctionEnded_View()) {
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
                                // 입찰신청 버튼
                                NavigationLink(destination: BidApply_View()) {
                                    Text("입찰신청")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 150)
                                        .padding()
                                        .background(Color.white)              // 흰 배경
                                        .foregroundColor(accent)             // 글자색 accent
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(accent, lineWidth: 1)
                                        )
                                }
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            // 입찰 순위
                            VStack(alignment: .leading, spacing: 12) {
                                Text("입찰 순위")
                                    .font(.headline)
                                
                                let ranksToShow = bidRanks.isEmpty
                                    ? dummyBidRanks
                                    : bidRanks
                                
                                if ranksToShow.isEmpty {
                                    Text("입찰 내역 없음")
                                        .foregroundColor(.secondary)
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(ranksToShow) { bid in
                                            HStack(spacing: 12) {
                                                Text("\(bid.rank)위")
                                                    .frame(width: 30, alignment: .leading)
                                                
                                                Text("\(bid.studentId): \(bid.amount)원")
                                                    .font(.subheadline)
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                    // 순위가 바뀔 때 위아래로 자연스럽게 움직이게
                                    .animation(.default, value: ranksToShow)
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
            title: "경매 상세",
            showSearch: false,
            hideBackButton: false
        )
        .onAppear {
            // 처음 들어올 때: 서버에서 내려준 timeLeftSeconds로 초기화
            loadAuctionItem(initial: true)
        }
        // 남은 시간 감소 (리스트처럼 매초 업데이트)
        .onReceive(timer) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            }
        }
        // 3초마다 서버에서 상세 정보 다시 가져와서 순위만 갱신 (remainingTime은 초기값 유지)
        .onReceive(rankTimer) { _ in
            loadAuctionItem(initial: false)
        }
    }
    
    // MARK: - 현재 사진 URL 계산
    
    private func currentPhotoURL(for item: AuctionItemDetailDTO) -> URL? {
        let photos = item.photos
        guard !photos.isEmpty else { return nil }
        
        let safeIndex = min(max(currentPhotoIndex, 0), photos.count - 1)
        let urlString = photos[safeIndex]
        return URL(string: urlString)
    }
    
    
    
    private func goNextPhoto(photoCount: Int) {
        guard photoCount > 1 else { return }
        let next = currentPhotoIndex + 1
        currentPhotoIndex = (next >= photoCount) ? 0 : next
    }
    

    private func loadAuctionItem(initial: Bool) {
        guard let url = URL(string: "\(API.auctionItemDetail)?auction_id=\(auctionId)") else {
            return
        }
        
        if initial && item == nil {
            isLoading = true
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil,
                  let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(AuctionItemDetailDTO.self, from: data)
                DispatchQueue.main.async {
                    self.item = decoded
                    
                    let serverTime = max(decoded.timeLeftSeconds, 0)
                    
                    if initial {
                        // 🔹 첫 진입일 때는 서버 값을 그대로 사용
                        self.remainingTime = serverTime
                    } else {
                        // 🔹 이후에는 "서버 변화가 있을 때만" 동기화
                        //    - 상태가 취소/완료로 바뀐 경우
                        //    - 타이머 차이가 너무 벌어진 경우 (3초 이상)
                        let status = decoded.statusEnum
                        let serverEnded = (status == .cancelled || status == .finished || serverTime <= 0)
                        
                        if serverEnded {
                            // 서버가 끝났다고 하면 바로 0으로 맞춰줌
                            self.remainingTime = 0
                        } else {
                            // 차이가 너무 많이 나면 서버 기준으로 재동기화
                            let diff = abs(serverTime - self.remainingTime)
                            if diff > 3 {
                                self.remainingTime = serverTime
                            }
                        }
                    }
                    
                    withAnimation {
                        self.bidRanks = decoded.bids
                    }
                    // 이미지 인덱스 초기화
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

    // MARK: - 남은 시간 포맷 (AuctionList와 동일한 스타일)

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
    
    private func formatTimeLeft(_ sec: Int, isEnded: Bool) -> String {
        // 종료/취소 상태거나 0초 이하면 고정 문구
        guard !isEnded, sec > 0 else {
            return "경매 종료까지 00:00:00:00"
        }
        
        let timePart = formatTime(sec)
        return "경매 종료까지 \(timePart)"
    }
    
    /// 버튼/타이머에서 사용할 실제 종료 여부 (상태 + 남은 시간 둘 다 반영)
    private func isActuallyEnded(_ item: AuctionItemDetailDTO) -> Bool {
        if let status = item.statusEnum,
           status == .cancelled || status == .finished {
            return true
        }
        return remainingTime <= 0
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
