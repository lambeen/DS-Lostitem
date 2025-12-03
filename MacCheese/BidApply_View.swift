//
//  BidApply_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct BidApply_View: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalTimer: GlobalTimer
    @AppStorage("studentId") private var storedStudentId: String = ""
    
    let auctionId: Int
    let initialTitle: String
    
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    @State private var bidAmount: String = ""
    @State private var item: AuctionItemDetailDTO?
    @State private var isLoading = false
    @State private var currentPhotoIndex = 0
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var autoSlideTimer: Timer?
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()
    
    private var topBidAmount: Int {
        guard let item = item else { return 0 }
        if item.bids.isEmpty {
            return item.minPrice
        }
        return item.bids.map { $0.amount }.max() ?? item.minPrice
    }
    
    private var remainingTimeText: String {
        guard let item = item,
              let endStr = item.endDate,
              !endStr.isEmpty,
              let end = BidApply_View.dateFormatter.date(from: endStr) else {
            return "00:00:00"
        }
        
        let diff = Int(end.timeIntervalSince(globalTimer.currentTime))
        if diff <= 0 { return "00:00:00" }
        
        let days = diff / 86400
        let hours = (diff % 86400) / 3600
        let mins = (diff % 3600) / 60
        let secs = diff % 60
        
        if days > 0 {
            return String(format: "D-%d %02d:%02d:%02d", days, hours, mins, secs)
        }
        return String(format: "%02d:%02d:%02d", hours, mins, secs)
    }
    
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                
                    
                    if let item = item, !item.photos.isEmpty {
                        TabView(selection: $currentPhotoIndex) {
                            ForEach(0..<item.photos.count, id: \.self) { idx in
                                if let url = imageURL(from: item.photos[safe: idx]) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            Rectangle().fill(Color(.systemGray5)).overlay(ProgressView())
                                        case .success(let img):
                                            img.resizable().scaledToFill()
                                        case .failure:
                                            Rectangle().fill(Color(.systemGray5))
                                                .overlay(Image(systemName: "photo").foregroundColor(.gray))
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(height: 300)
                                    .clipped()
                                    .tag(idx)
                                } else {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                                        .frame(height: 300)
                                        .tag(idx)
                                }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 300)
                        .cornerRadius(16)
                        .onAppear {
                            startAutoSlide(total: item.photos.count)
                        }
                        .onChange(of: currentPhotoIndex) { _ in
                            stopAutoSlide()
                            startAutoSlide(total: item.photos.count)
                        }
                        
                        HStack(spacing: 6) {
                            ForEach(0..<item.photos.count, id: \.self) { idx in
                                Circle()
                                    .fill(idx == currentPhotoIndex ? accent : Color(.systemGray4))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(Text("이미지 없음").foregroundColor(.secondary).font(.caption))
                            .frame(height: 300)
                            .cornerRadius(16)
                    }
                    
                    HStack {
                        if item != nil {
                            Text(remainingTimeText)
                                .font(.headline)
                                .foregroundColor(accent)
                                .id(globalTimer.currentTime)
                        }
                        Spacer()
                        if let item = item {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("상태: \(item.statusText)").font(.caption)
                                if let end = item.endDate, !end.isEmpty {
                                    Text(end).font(.caption2)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let item = item {
                            Text("현재 최고 입찰가 \(formatPrice(topBidAmount))원입니다.").bold()
                            Text("""
                            
                            * 현재 최고 입찰가 보다 높은 금액만 가능합니다.
                            최소 금액: \(formatPrice(item.minPrice))
                            
                            """)
                        } else {
                            Text("현재 최고 입찰가를 불러오는 중...").bold()
                        }
                        TextField("입찰 금액을 입력하세요", text: $bidAmount)
                            .keyboardType(.numberPad)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(accent)
                    .cornerRadius(6)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            HStack(spacing: 16) {
                Button {
                    submitBid()
                } label: {
                    if isSubmitting {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("입찰확정")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accent)
                .cornerRadius(10)
                .disabled(isSubmitting || bidAmount.isEmpty)

                Button {
                    dismiss()
                } label: {
                    Text("입찰취소")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accent)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .duksungHeaderNav(
            title: initialTitle,
            showSearch: false,
            hideBackButton: false
        )
        .task {
            loadAuctionItem()
        }
        .onDisappear {
            stopAutoSlide()
        }
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) {
                if alertMessage.contains("성공") || alertMessage.contains("완료") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func submitBid() {
        guard let price = Int(bidAmount), let item = item else {
            alertMessage = "입찰 금액을 입력해주세요."
            showAlert = true
            return
        }
        
        if price <= topBidAmount {
            alertMessage = "현재 최고 입찰가(\(formatPrice(topBidAmount))원)보다 높은 금액을 입력해주세요."
            showAlert = true
            return
        }
        
        if price < item.minPrice {
            alertMessage = "최소 입찰가(\(formatPrice(item.minPrice))원) 이상 입력해주세요."
            showAlert = true
            return
        }
        
        if storedStudentId.isEmpty {
            alertMessage = "로그인이 필요합니다."
            showAlert = true
            return
        }
        
        isSubmitting = true
        
        guard let url = URL(string: API.bidApply) else {
            isSubmitting = false
            alertMessage = "서버 연결에 실패했습니다."
            showAlert = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "auction_id=\(auctionId)&student_id=\(storedStudentId)&bid_price=\(price)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isSubmitting = false
                
                if let err = error {
                    self.alertMessage = "네트워크 오류: \(err.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let data = data, let str = String(data: data, encoding: .utf8) else {
                    self.alertMessage = "서버 응답을 처리할 수 없습니다."
                    self.showAlert = true
                    return
                }
                
                let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.lowercased().contains("success") || trimmed.lowercased().contains("성공") || trimmed == "1" {
                    self.alertMessage = "입찰 신청이 완료되었습니다."
                } else {
                    self.alertMessage = trimmed.isEmpty ? "입찰 신청에 실패했습니다." : trimmed
                }
                self.showAlert = true
            }
        }.resume()
    }
    
    private func loadAuctionItem() {
        guard let url = URL(string: "\(API.auctionItemDetail)?auction_id=\(auctionId)") else { return }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                guard error == nil, let data = data else { return }
                
                if let decoded = try? JSONDecoder().decode(AuctionItemDetailDTO.self, from: data) {
                    self.item = decoded
                }
            }
        }.resume()
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
}

#Preview {
    NavigationStack {
        BidApply_View(auctionId: 1, initialTitle: "예시 상품명")
            .environmentObject(GlobalTimer.shared)
    }
}
