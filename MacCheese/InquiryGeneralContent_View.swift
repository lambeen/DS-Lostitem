//
//  InquiryGeneralContent_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct InquiryGeneralContent_View: View {
    var body: some View {
        VStack {
            NavigationLink(destination: InquiryUserReply_VIew()) {
                Text("문의 답변하기")
            }
        }
        .duksungHeaderNav(

                    title: "덕성여대 문의 통합포털", // 붉은 타이틀 바 텍스트

                    showSearch: false,                 // 오른쪽 검색 버튼 표시

                    hideBackButton: false  )          // 루트 화면이니까 뒤로가기 숨김
    }
}

#Preview {
    InquiryGeneralContent_View()
}
