//
//  AuctionItem_Overview_View.swift
//  MacCheese
//

import SwiftUI

struct AuctionItemOverviewDTO: Decodable {
    let auctionId: Int
    let itemName: String
    let statusText: String
    let endDate: String?
    let minPrice: Int
    let description: String?
    let photos: [String]
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

struct AuctionItem_Overview_View: View {
    @Environment(\.dismiss) private var dismiss
    
    let auctionId: Int
    let initialTitle: String
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    @State private var overview: AuctionItemOverviewDTO?
    @State private var isLoading = false
    @State private var currentPhotoIndex = 0
    @State private var autoSlideTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if isLoading && overview == nil {
                Spacer()
                ProgressView("불러오는 중...")
                Spacer()
            } else if let o = overview {
                ScrollView {
                    VStack(spacing: 0) {
                        imageSliderView(photos: o.photos)
                        productInfoView(overview: o)
                        actionButtonsView()
                    }
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
            loadOverview()
        }
        .onDisappear {
            stopAutoSlide()
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text("물품 세부사항")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(accent)
    }
    
    private func imageSliderView(photos: [String]) -> some View {
        VStack(spacing: 0) {
            if photos.isEmpty {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 400)
                    .overlay(
                        Text("이미지 없음")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    )
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
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                                Text("이미지 로드 실패")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(height: 400)
                            .clipped()
                            .tag(index)
                        } else {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    Text("이미지 URL 오류")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                )
                                .frame(height: 400)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 400)
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
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func imageURL(from urlString: String?) -> URL? {
        guard let urlString = urlString, !urlString.isEmpty else {
            return nil
        }
        
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return URL(string: urlString)
        } else {
            let fullURL = "\(API.baseURL)/\(urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString)"
            return URL(string: fullURL)
        }
    }
    
    private func productInfoView(overview: AuctionItemOverviewDTO) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Text(initialTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Text("상태: \(overview.statusText)")
                    .font(.subheadline)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            if let desc = overview.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                if let end = overview.endDate {
                    Text("종료일: \(String(end.prefix(10)))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Text("최소 금액: \(formatPrice(overview.minPrice))원")
                    .font(.system(size: 15, weight: .medium))
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 24)
        }
    }
    
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
    
    private func actionButtonsView() -> some View {
        VStack(spacing: 16) {
            Button {
                print("소유자 확인 요청")
            } label: {
                Text("소유자 확인 요청")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            Rectangle()
                .fill(accent)
                .frame(height: 2)
                .padding(.horizontal, 20)
            
            NavigationLink {
                Text("댓글 화면 (임시)")
            } label: {
                Text("댓글 확인하기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .padding(.top, 8)
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
    
    private func loadOverview() {
        guard let url = URL(string: "\(API.auctionItemDetail)?auction_id=\(auctionId)") else {
            return
        }
        
        if overview == nil {
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
                    let overviewData = AuctionItemOverviewDTO(
                        auctionId: decoded.id,
                        itemName: decoded.itemName,
                        statusText: decoded.statusText,
                        endDate: decoded.endDate,
                        minPrice: decoded.minPrice,
                        description: nil,
                        photos: decoded.photos
                    )
                    self.overview = overviewData
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        AuctionItem_Overview_View(auctionId: 1, initialTitle: "예시 물품명")
    }
}
