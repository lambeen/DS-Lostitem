//
//  InquiryDisposalContent_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct InquiryDisposalContent_View: View {
    var body: some View {
        VStack {
            NavigationLink(destination: InquiryUserReply_VIew()) {
                Text("문의 답변하기")
            }
        }
    }
}

#Preview {
    InquiryDisposalContent_View()
}
