import SwiftUI

struct  LostDetail_View: View {
    @State private var isBelled = false
    let photos: [String] = []
    let item: LostItemDTO
    let userPkey: Int
    
    private var statusText: String {
        switch item.status {
        case 0: return "보관중"
        case 1: return "인계중"
        case 2: return "인계완료"
        case 3: return "경매"
        case 4: return "폐기"
        default: return "알 수 없음"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            
            HStack {
                VStack{
                    Text(item.title)
                        .font(.subheadline)
                }
                Spacer()
                VStack{
                    Text("상태: \(statusText)")
                        .font(.subheadline)
                    Text(item.createdDate)
                        .font(.subheadline)
                }
            }
            
            ZStack{
                HStack{
                    Spacer()
                    HStack{
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 200, height: 200)
                            .cornerRadius(8)
                          
                            .overlay(
                                ZStack(alignment: .topLeading) {
                                  
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity,
                                               maxHeight: .infinity)
                                        .contentShape(Rectangle())
                                    
                                    
                                    Button {
                                        toggleBell()
                                    } label: {
                                        Image(systemName: isBelled ? "bell.fill" : "bell")
                                            .font(.system(size: 20))
                                            .foregroundColor(.yellow)
                                            .padding(8)
                                            .offset(x: -35, y: -4)
                                    }
                                }
                            )
                    }
                    Spacer()
                }
                
                HStack{
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20))
                        .foregroundColor(accent)
                        .padding(.trailing, 16)
                        .opacity(photos.count > 1 ? 1 : 0)
                        //이미지 2장 이상일 때만 보이는데 자리는 고정
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        
            Divider()
            
            VStack(alignment: .leading, spacing: 15){
                Text("• 접수일: \(item.createdDate)")
                Text("• 발견 장소: \(item.placeName)")
                Text("• 카테고리: \(item.categoryName)")
                Text("• 특징: \(item.description ?? "특이사항 없음")")
            }
         
            Divider()
            
            Spacer()
            
            NavigationLink {
                LostCommentDetail_View(item: item, userPkey: userPkey)
            } label: {
                Text("댓글 보기")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 150)
                    .padding()
                    .background(accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .duksungHeaderNav(
            title: "유실물 상세",
            showSearch: false,
            hideBackButton: false
        )
    }
    
    private func toggleBell() {
        isBelled.toggle()
        if isBelled {
            // 벨을 켰을 때만 키워드 등록
            addKeyword(word: item.title, userId: userPkey)
        } else {
            // 해제 로직도 나중에 추가
        }
    }
    
    private func addKeyword(word: String, userId: Int) {
        guard let url = URL(string:API.keyword) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let params: [String: String] = [
            "word": word,
            "user_pkey": String(userId)
        ]

        let bodyString = params
            .map { key, value in
                let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(key)=\(encoded)"
            }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("키워드 등록 네트워크 오류:", error.localizedDescription)
                return
            }
           
            if let http = response as? HTTPURLResponse {
                print("Keyword_V 응답 코드:", http.statusCode)
            }
           
            if let data = data,
               let text = String(data: data, encoding: .utf8) {
                print("서버 응답:", text)
            }
        }.resume()
    }
}

struct LostDetail_View_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LostDetail_View(
                item: LostItemDTO(
                    id: 1,
                    title: "검은 우산",
                    categoryName: "기타",
                    placeName: "도서관 3층",
                    status: 0,
                    createdDate: "2025-10-07",
                    photoURL: nil,
                    description: "description 부분"
                ),
                userPkey: 1
            )
        }
    }
}
