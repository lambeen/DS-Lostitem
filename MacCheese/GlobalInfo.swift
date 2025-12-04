//
//  GlobalInfo.swift
//  MacCheese
//
//  Created by 양수빈 on 12/4/25.
//

import Foundation
import Combine

final class GlobalSession: ObservableObject {
    static let shared = GlobalSession()

    @Published var userPkey: Int?
    @Published var studentId: String?

    private init() {}   // 밖에서 init 못하게 막기 (싱글톤)
}
