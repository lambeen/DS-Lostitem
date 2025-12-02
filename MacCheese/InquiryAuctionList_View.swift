//
//  InquiryAuctionList_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct InquiryAuctionList_View: View {
    var body: some View {
        VStack {
            NavigationLink(destination: InquiryAuctionContent_View()) {
                Text("경매 소유자 문의 내용")
            }
            
        }
    }
}

#Preview {
    InquiryAuctionList_View()
}
