//
//  Inquiry_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct Inquiry_View: View {
    @Environment(\.dismiss) private var dismiss

    // 캡처와 비슷한 포인트 컬러
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("문의하기")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
            }.duksungHeaderNav(
                
                title: "덕성여대 문의 통합포털", // 붉은 타이틀 바 텍스트

                showSearch: false,                 // 오른쪽 검색 버튼 표시

                hideBackButton: false  )          // 루트 화면이니까 뒤로가기 숨김
            
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(accent)

            // 본문 리스트
            VStack(spacing: 0) {
                // 1) 일반 문의
                NavigationLink {
                    InquiryGeneralList_View()
                } label: {
                    RowChevronLabel("일반 문의")
                }
                Divider()

                // 2) 경매 물품 소유자 확인 요청
                NavigationLink {
                    InquiryAuctionList_View()
                } label: {
                    RowChevronLabel("경매 물품 소유자 확인 문의")
                }
                Divider()

                // 3) 폐기 물품 소유자 확인 문의
                NavigationLink {
                    InquiryDisposalList_View()
                } label: {
                    RowChevronLabel("폐기 물품 소유자 확인 문의")
                }
                Divider()
            }
            .background(Color(.systemBackground))

            Spacer()
        }

    }
}

private struct RowChevronLabel: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle()) // 터치 여백 넓게
    }
}

#Preview {
    NavigationStack { Inquiry_View() }
}
