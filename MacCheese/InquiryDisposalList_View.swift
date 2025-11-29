//
//  InquiryDisposalList_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct InquiryDisposalList_View: View {
    var body: some View {
        VStack {
            NavigationLink(destination: InquiryDisposalContent_View()) {
                Text("폐기 소유자 문의 내용")
            }
            NavigationLink(destination: NewInquiry_View()) {
                Text("문의하기")
            }
        }
    }
}

#Preview {
    InquiryDisposalList_View()
}
