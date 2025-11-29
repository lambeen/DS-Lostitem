//
//  BidApply_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct BidApply_View: View {

    @Environment(\.dismiss) private var dismiss

    // 포인트 컬러 (공통)
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    @State private var bidAmount: String = ""

    var body: some View {
        VStack(spacing: 0) {

            // 상단 헤더
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text("경매 종료까지 01:01:53:20")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(accent)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // 상품명 + 상태
                    HStack(alignment: .top) {
                        Text("라네즈 크림")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("상태: 경매중")
                                .font(.caption)
                            Text("-2025-11-02")
                                .font(.caption2)
                        }
                        .foregroundColor(.primary)
                    }

                    // 상품 이미지 (플레이스홀더)
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

                        Text("1/5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    // 새로고침 버튼
                    Button {
                        // TODO: 새로고침 로직
                    } label: {
                        HStack(spacing: 6) {
                            Text("새로고침")
                            Image(systemName: "arrow.clockwise")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(accent)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 안내 + 입찰 금액 입력 박스
                    VStack(alignment: .leading, spacing: 8) {

                        Text("현재 최고 입찰가 8,000원입니다.")
                            .bold()

                        Text("""
                        * 현재 최고 입찰가 보다
                        높은 금액만 가능합니다.
                        입찰 취소는 불가능합니다.
                        최소 금액: 3000
                        """)

                        TextField("입찰 금액을 입력하세요", text: $bidAmount)
                            .keyboardType(.numberPad)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
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

            // 하단 버튼 영역
            HStack(spacing: 16) {
                Button {
                    // TODO: 입찰 확정 로직
                } label: {
                    Text("입찰확정")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accent)
                        .cornerRadius(6)
                }

                Button {
                    // TODO: 입찰 취소 로직 (또는 dismiss())
                    dismiss()
                } label: {
                    Text("입찰취소")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accent)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        BidApply_View()
    }
}
