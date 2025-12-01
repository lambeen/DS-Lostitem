//
//  AuctionItem_Overview_View.swift
//  MacCheese
//

import SwiftUI

// MARK: - 서버 JSON 모델 (DTO)
// PHP에서 내려주는 키랑 이름 똑같이 맞춤
struct AuctionItemOverviewDTO: Decodable {
    let auctionId: Int
    let itemName: String
    let statusText: String
    let endDate: String?        // null 가능
    let minPrice: Int
    let description: String?    // ✅ null 대비해서 옵셔널로 변경
    let photos: [String]
}

// 배열 안전 인덱싱 (사진 인덱스 오류 방지용)
extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

struct AuctionItem_Overview_View: View {

    @Environment(\.dismiss) private var dismiss

    // 어떤 경매인지 외부에서 받는 값
    let auctionId: Int

    // 포인트 색
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    @State private var overview: AuctionItemOverviewDTO?
    @State private var isLoading = false
    @State private var currentPhotoIndex = 0

    var body: some View {
        VStack(spacing: 0) {

            // 상단 헤더
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

            // 본문
            if isLoading && overview == nil {
                Spacer()
                ProgressView("불러오는 중...")
                Spacer()
            } else if let o = overview {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // 물품명 + 상태 / 날짜
                        HStack(alignment: .top) {
                            Text(o.itemName)
                                .font(.headline)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("상태: \(o.statusText)")
                                if let end = o.endDate {
                                    Text(String(end.prefix(10)) + " 까지")   // yyyy-MM-dd
                                }
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // 이미지 + > 버튼 + 인덱스
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color(.systemGray5))

                                    if !o.photos.isEmpty,
                                       let urlStr = o.photos[safe: currentPhotoIndex],
                                       let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    } else {
                                        Text("이미지 없음")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .frame(height: 220)
                                .cornerRadius(8)

                                Button {
                                    showNextPhoto(total: o.photos.count)
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)

                            Text("\(min(currentPhotoIndex + 1, max(o.photos.count, 1)))/\(max(o.photos.count, 1))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // 최소 금액
                        Text("최소 금액: \(o.minPrice)원")
                            .font(.subheadline)
                            .padding(.horizontal, 16)

                        // 소개글
                        Text(o.description ?? "이 물품에 대한 상세 설명이 없습니다.")   // ✅ 옵셔널 처리
                            .font(.footnote)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)

                        // 소유자 확인 요청 버튼
                        Button {
                            // TODO: 서버 연동 필요하면 추가
                            print("소유자 확인 요청")
                        } label: {
                            Text("소유자 확인 요청")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(accent)
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 16)

                        // 구분선
                        Rectangle()
                            .fill(accent)
                            .frame(height: 2)
                            .padding(.top, 24)

                        // 댓글 확인하기 버튼 (나중에 진짜 뷰로 교체 가능)
                        NavigationLink {
                            Text("댓글 화면 (임시)")
                        } label: {
                            Text("댓글 확인하기")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(accent)
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)

                        Spacer(minLength: 32)
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
            
        }
    }

    // MARK: - 다음 사진
    private func showNextPhoto(total: Int) {
        guard total > 0 else { return }
        currentPhotoIndex = (currentPhotoIndex + 1) % total
    }

   
    
    
    
    
}

#Preview {
    NavigationStack {
        AuctionItem_Overview_View(auctionId: 1)
    }
}
