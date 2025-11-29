//
//  AuctionEnded_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI


struct AuctionEndedDetail: Codable {
    let name: String?
    let imageCount: Int?
    let winnerId: String?
    let finalPrice: Int?
    let notice: String?
}

struct AuctionEnded_View: View {

    @Environment(\.dismiss) private var dismiss

    
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    
    @State private var ended: AuctionEndedDetail?
    @State private var isLoading: Bool = false
    @State private var alertMessage: String?
    @State private var showAlert: Bool = false

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - 상단 헤더
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                // 종료된 화면이라 타이머 대신 고정 문구로
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
                    Text(ended?.name ?? "라네즈 크림")
                        .font(.headline)
                        .padding(.top, 16)

                    // 상품 이미지 + 페이지 인디케이터
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Text("IMAGE")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            )
                            .frame(height: 180)
                            .cornerRadius(4)

                        Text("1/\(ended?.imageCount ?? 5)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 낙찰 정보 + 안내문 (핑크 박스)
                    VStack(spacing: 12) {
                        Text("낙찰자 : \(ended?.winnerId ?? "2023XXXX")")
                            .font(.headline)

                        if let final = ended?.finalPrice {
                            Text("낙찰가 : \(final)")
                                .font(.headline)
                        } else {
                            Text("낙찰가 : 12,000")
                                .font(.headline)
                        }

                        Text(ended?.notice ?? """
                        12,000원에 낙찰되었습니다.
                        낙찰된 물품은 1주일 내 센터로 방문하여 수령하셔야 합니다.
                        경매시작시에 오프라인 관제 확인 후 재입고 가능합니다.
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

            // MARK: - 하단 탭바
            HStack(spacing: 0) {
                tabItem(title: "분실물", isSelected: false)
                tabItem(title: "경매", isSelected: true)   // 현재 화면
                tabItem(title: "설정", isSelected: false)
                tabItem(title: "알림", isSelected: false)
            }
            .frame(height: 48)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .task {
            await fetchAuctionEnded()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("알림"),
                message: Text(alertMessage ?? "오류가 발생했습니다."),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    // 탭바 아이템
    private func tabItem(title: String, isSelected: Bool) -> some View {
        VStack {
            Spacer()
            Text(title)
                .font(.footnote)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(accent)
    }

    // MARK: - 네트워크: PHP에서 종료 정보 가져오기
    private func fetchAuctionEnded() async {
        guard let url = URL(string: API.auctionEnded) else {
            return
        }

        isLoading = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(AuctionEndedDetail.self, from: data)

            await MainActor.run {
                self.ended = decoded
                self.isLoading = false
            }
        } catch {
            print("fetchAuctionEnded error:", error)
            await MainActor.run {
                self.isLoading = false
                self.alertMessage = "서버에서 경매 종료 정보를 가져오지 못했어요."
                self.showAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuctionEnded_View()
    }
}

