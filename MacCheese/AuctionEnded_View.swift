import SwiftUI

struct AuctionEndedDTO: Decodable {
    let itemName: String
    let description: String?
    let photos: [String]
    let endDate: String?
    let winnerStudentId: String?
    let finalPrice: Int?
}

struct AuctionEnded_View: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalTimer: GlobalTimer
    
    let auctionId: Int
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    @State private var endedData: AuctionEndedDTO?
    @State private var isLoading = false
    @State private var currentPhotoIndex = 0
    @State private var autoSlideTimer: Timer?
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if isLoading && endedData == nil {
                Spacer()
                ProgressView("불러오는 중...")
                Spacer()
            } else if let data = endedData {
                ScrollView {
                    VStack(spacing: 24) {
                        productImageView(photos: data.photos)
                        auctionResultCard(data: data)
                        descriptionCard(data: data)
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            } else {
                Spacer()
                Text("해당 물품 정보를 불러오지 못했습니다.")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .task {
            loadAllData()
        }
        .onDisappear {
            stopAutoSlide()
        }
    }
    
    private var headerView: some View {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
            Text(headerTimerText)
                    .font(.headline)
                    .foregroundColor(.white)
                .id(globalTimer.currentTime)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(accent)
    }
    
    private var headerTimerText: String {
        guard let data = endedData,
              let endDateString = data.endDate,
              !endDateString.isEmpty,
              let endDate = AuctionEnded_View.dateFormatter.date(from: endDateString) else {
            return "경매 종료까지 00:00:00:00"
        }
        
        let diff = Int(endDate.timeIntervalSince(globalTimer.currentTime))
        let remaining = max(0, diff)
        
        if remaining <= 0 {
            return "경매 종료까지 00:00:00:00"
        }
        
        let days = remaining / 86400
        let hours = (remaining % 86400) / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        
        if days > 0 {
            return String(format: "경매 종료까지 D-%d %02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            return String(format: "경매 종료까지 %02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    private func productImageView(photos: [String]) -> some View {
        VStack(spacing: 12) {
            if photos.isEmpty {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                    .frame(height: 300)
                    .cornerRadius(16)
            } else {
                TabView(selection: $currentPhotoIndex) {
                    ForEach(0..<photos.count, id: \.self) { index in
                        if let url = imageURL(from: photos[safe: index]) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .overlay(ProgressView())
                                case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                case .failure:
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(height: 300)
                            .clipped()
                            .tag(index)
                        } else {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                                .frame(height: 300)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 300)
                .cornerRadius(16)
                .onAppear {
                    startAutoSlide(total: photos.count)
                }
                .onChange(of: currentPhotoIndex) { _ in
                    stopAutoSlide()
                    startAutoSlide(total: photos.count)
                }
                
                HStack(spacing: 6) {
                    ForEach(0..<photos.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPhotoIndex ? accent : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
    
    private func auctionResultCard(data: AuctionEndedDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(data.itemName)
                .font(.system(size: 22, weight: .bold))
            
            if let desc = data.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .padding(.top, 4)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            if let winnerId = data.winnerStudentId {
                HStack {
                    Text("낙찰자")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(": \(winnerId)")
                        .font(.system(size: 15, weight: .medium))
                }
                        } else {
                HStack {
                    Text("낙찰자")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(": 없음")
                        .font(.system(size: 15, weight: .medium))
                }
            }
            
            if let price = data.finalPrice {
                HStack {
                    Text("낙찰가")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(": \(formatPrice(price))원")
                        .font(.system(size: 15, weight: .medium))
                }
            } else {
                HStack {
                    Text("낙찰가")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(": - 원")
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func descriptionCard(data: AuctionEndedDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let price = data.finalPrice {
                Text("\(formatPrice(price))원에 낙찰되었습니다.")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.bottom, 4)
            }
            
            Text("낙찰된 물품은 1주일 내 센터로 방문하여 수령하시면 됩니다. 현금/계좌이체 등 오프라인 결제 확인 후 물품 인계 가능합니다. 미방문 시 다음 낙찰자로 넘어갑니다.")
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func startAutoSlide(total: Int) {
        guard total > 1 else { return }
        stopAutoSlide()
        
        autoSlideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPhotoIndex = (currentPhotoIndex + 1) % total
            }
        }
    }
    
    private func stopAutoSlide() {
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
    }
    
    private func imageURL(from urlString: String?) -> URL? {
        guard let urlString = urlString, !urlString.isEmpty else {
            return nil
        }
        
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return URL(string: urlString)
        } else {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let fullURL = "\(API.baseURL)/\(cleanPath)"
            return URL(string: fullURL)
        }
    }
    
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
    
    private func loadAllData() {
        isLoading = true
        
        let group = DispatchGroup()
        var listData: AuctionItemDTO?
        var detailData: AuctionItemDetailDTO?
        var bidsData: [BidRank] = []
        
        group.enter()
        loadAuctionList { item in
            listData = item
            group.leave()
        }
        
        group.enter()
        loadAuctionDetail { item in
            detailData = item
            group.leave()
        }
        
        group.enter()
        loadBids { bids in
            bidsData = bids
            group.leave()
        }
        
        group.notify(queue: .main) {
            let topBid = bidsData.sorted { $0.rank < $1.rank }.first
            
            if let list = listData, let detail = detailData {
                self.endedData = AuctionEndedDTO(
                    itemName: list.title,
                    description: detail.description,
                    photos: detail.photos,
                    endDate: detail.endDate,
                    winnerStudentId: topBid?.studentId,
                    finalPrice: topBid?.amount
                )
            } else if let detail = detailData {
                self.endedData = AuctionEndedDTO(
                    itemName: detail.itemName,
                    description: detail.description,
                    photos: detail.photos,
                    endDate: detail.endDate,
                    winnerStudentId: topBid?.studentId,
                    finalPrice: topBid?.amount
                )
            } else {
                self.endedData = AuctionEndedDTO(
                    itemName: "상품명 없음",
                    description: nil,
                    photos: [],
                    endDate: nil,
                    winnerStudentId: topBid?.studentId,
                    finalPrice: topBid?.amount
                )
            }
            
            self.isLoading = false
        }
    }
    
    private func loadAuctionList(completion: @escaping (AuctionItemDTO?) -> Void) {
        guard let url = URL(string: API.auctionList) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("auction_list 오류: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("auction_list 데이터 없음")
                completion(nil)
                return
            }
            
            if let decoded = try? JSONDecoder().decode(AuctionListResponseDTO.self, from: data) {
                let found = decoded.auctions.first { $0.id == self.auctionId }
                print("auction_list 성공: \(found != nil ? "찾음" : "없음")")
                completion(found)
            } else {
                print("auction_list 디코딩 실패")
                completion(nil)
            }
        }.resume()
    }
    
    private func loadAuctionDetail(completion: @escaping (AuctionItemDetailDTO?) -> Void) {
        guard let url = URL(string: "\(API.auctionItemDetail)?auction_id=\(auctionId)") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("auction_detail 오류: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("auction_detail 데이터 없음")
                completion(nil)
                return
            }
            
            if let decoded = try? JSONDecoder().decode(AuctionItemDetailDTO.self, from: data) {
                print("auction_detail 성공: itemName=\(decoded.itemName), endDate=\(decoded.endDate ?? "nil")")
                completion(decoded)
            } else {
                print("auction_detail 디코딩 실패")
                if let rawString = String(data: data, encoding: .utf8) {
                    print("원본 응답: \(rawString)")
                }
                completion(nil)
            }
        }.resume()
    }
    
    private func loadBids(completion: @escaping ([BidRank]) -> Void) {
        guard let url = URL(string: "\(API.auctionBids)?auction_id=\(auctionId)") else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("auction_bids 오류: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data else {
                print("auction_bids 데이터 없음")
                completion([])
                return
            }
            
            if let decoded = try? JSONDecoder().decode(AuctionBidsResponseDTO.self, from: data) {
                print("auction_bids 성공: 입찰 개수=\(decoded.bids.count)")
                if let topBid = decoded.bids.sorted(by: { $0.rank < $1.rank }).first {
                    print("  낙찰자: \(topBid.studentId), 낙찰가: \(topBid.amount)")
                }
                completion(decoded.bids)
            } else {
                print("auction_bids 디코딩 실패")
                completion([])
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        AuctionEnded_View(auctionId: 1)
            .environmentObject(GlobalTimer.shared)
    }
}
