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
            NavigationLink(destination: NewInquiry_View()) {
                Text("문의하기")
            }
        }
    }
}

#Preview {
    InquiryGeneralList_View()
}
