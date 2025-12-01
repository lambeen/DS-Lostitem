//
//  InquiryUserReply_VIew.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct InquiryUserReply_VIew: View {

    @Environment(\.dismiss) private var dismiss

    // 포인트 컬러 (다른 화면과 동일)
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    // 센터 답변은 고정 텍스트
    private let centerReply: String = "센터로 10월 7일까지 찾으러 오세요"

    // 사용자가 직접 입력하는 답변
    @State private var userReply: String = ""

    var body: some View {
        VStack(spacing: 0) {
            
            

            // 상단 헤더
            HStack(spacing: 12) {
                Button {
                    // 뒤로가기
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text("")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(accent)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // 센터 답변
                    Text("센터 답변")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text(centerReply)
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        .padding(8)
                        .background(accent)
                        .cornerRadius(4)

                    // 사용자 답변
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer(minLength: 40)

                // 하단 구분선
                Rectangle()
                    .fill(accent)
                    .frame(height: 2)
                    .padding(.horizontal, 0)

                // 답변완료 버튼
                Button {
                    // 여기서 서버 통신이 필요하면 추가하고
                    // 지금은 단순히 유실물 목록으로 되돌아가기만
                    dismiss()
                    
                } label: {
                    Text("문의확인")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accent)
                        .cornerRadius(6)
                }
                .padding(.horizontal, 60)
                .padding(.top, 16)
                
                
                

                // 이메일 (고정 텍스트 - 필요 없으면 지워도 됨)
                Text("befanyelse@gmail.com")
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        InquiryUserReply_VIew()
    }
}
