//
//  Terms_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct Terms_View: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            // 상단 타이틀 바 (핑크)
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text("개인정보 처리방침/ 이용약관")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.78, green: 0.10, blue: 0.36))

            // 본문
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("“분실물은 덕새를 타고”는 학번, 이름 등 최소한의 개인정보만 수집하며, 로그인 인증과 유실물 수령 확인을 위해서만 사용합니다. 모든 개인정보는 보관 기간 후 안전하게 파기되며, 법령에 의한 요청 외에는 제3자에게 제공되지 않습니다.")
                        .font(.body)
                        .lineSpacing(6)

                    Text("또한 내 분실물 등록·조회·알림 및 경매 기능을 제공합니다. 사용자는 허위 정보 등록이나 악용을 해서는 안 되며, 분실물의 실제 인계·결제는 센터에서 오프라인으로 처리됩니다. 서비스 변경 시 앱 내 공지를 통해 안내합니다.")
                        .font(.body)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    Terms_View()
}

