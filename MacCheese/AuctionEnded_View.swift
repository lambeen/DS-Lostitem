import SwiftUI

struct AuctionEnded_View: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // 디테일 화면에서 넘겨받을 값들
    let itemName: String
    let thumbURL: String?
    let winnerStudentId: String?
    let finalPrice: Int?
    
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 상단 헤더
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text("경매 종료")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(accent)
            
            // MARK: - 본문
            ScrollView {
                VStack(spacing: 16) {
                    
                    // 상품명
                    Text(itemName)
                        .font(.headline)
                        .padding(.top, 16)
                    
                    // 상품 이미지 + 간단 인디케이터
                    VStack(spacing: 4) {
                        if let urlString = thumbURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                            }
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(4)
                        } else {
                            // 썸네일이 없을 때
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                )
                                .frame(height: 180)
                                .cornerRadius(4)
                        }
                        
                        Text("1 / 1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    
                    // 낙찰 정보 + 안내문 (핑크 박스)
                    VStack(spacing: 12) {
                        // 낙찰자
                        if let id = winnerStudentId {
                            Text("낙찰자 : \(id)")
                                .font(.headline)
                        } else {
                            Text("낙찰자 : 없음")
                                .font(.headline)
                        }
                        
                        // 낙찰가
                        if let price = finalPrice {
                            Text("낙찰가 : \(price)원")
                                .font(.headline)
                        } else {
                            Text("낙찰가 : - 원")
                                .font(.headline)
                        }
                        
                        Text("""
                        낙찰된 물품은 1주일 내 센터로 방문하여 수령하셔야 합니다.
                        미방문 시 다음 낙찰자로 넘어갑니다.
                        """)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(accent)
                    .cornerRadius(6)
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuctionEnded_View(
            itemName: "라네즈 크림",
            thumbURL: nil,
            winnerStudentId: "2023XXXX",
            finalPrice: 12000
        )
    }
}
