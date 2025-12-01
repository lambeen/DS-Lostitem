//
//  InquiryGeneralList_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct InquiryGeneralList_View: View {
    var body: some View {
        VStack {
            NavigationLink(destination: InquiryGeneralContent_View()) {
                Text("일반 문의 내용")
            }
            .duksungHeaderNav(
                title: "덕성여대 문의 통합포털", // 붉은 타이틀 바 텍스트
                showSearch: false,                 // 오른쪽 검색 버튼 표시
                hideBackButton: false  )          // 루트 화면이니까 뒤로가기 숨김
            NavigationLink(destination: NewInquiry_View()) {
                Text("문의하기")
            }
        }
    }
}

#Preview {
    InquiryGeneralList_View()
}
