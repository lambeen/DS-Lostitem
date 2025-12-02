import SwiftUI

struct  LostDetail_View: View {
    @State private var isBelled = false
    let item: LostItemDTO
    let userPkey: Int
    
    @State private var photos: [String] = []
    @State private var currentPhotoIndex: Int = 0
    
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
            
            ZStack {
                HStack {
                    Spacer()

                    if let urlStr = currentPhotoURL,
                       let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(ProgressView())
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure(_):
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color(.systemGray5))
                            }
                        }
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(8)
                        .overlay(alignment: .topLeading) {
                            Button {
                                toggleBell()
                            } label: {
                                Image(systemName: isBelled ? "bell.fill" : "bell")
                                    .font(.system(size: 20))
                                    .foregroundColor(.yellow)
                                    .padding(8)
                            }
                        }
                    } else {
                        // URL 없을 때
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
                                    Button {
                                        toggleBell()
                                    } label: {
                                        Image(systemName: isBelled ? "bell.fill" : "bell")
                                            .font(.system(size: 20))
                                            .foregroundColor(.yellow)
                                            .padding(8)
                                    }
                                }
                            )
                    }

                    Spacer()
                }

                //2장 이상일 때만 보이기
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20))
                        .foregroundColor(accent)
                        .padding(.trailing, 16)
                        .opacity(photos.count > 1 ? 1 : 0)
                        .onTapGesture {
                            guard photos.count > 1 else { return }
                            currentPhotoIndex = (currentPhotoIndex + 1) % photos.count
                        }
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
        .onAppear {
            loadPhotos()
        }
    }
    
    private var currentPhotoURL: String? {
           if !photos.isEmpty {
               if photos.indices.contains(currentPhotoIndex) {
                   return photos[currentPhotoIndex]
               } else {
                   return photos.first
               }
           }
           // 아직 상세 사진을 못 받아왔으면, 리스트에서 넘어온 대표사진이라도 사용
           return item.photoURL
       }
    
    private func loadPhotos() {
        guard var components = URLComponents(string: API.lostPhotos) else { return }
        components.queryItems = [
            URLQueryItem(name: "item_pkey", value: String(item.id))
        ]
        guard let url = components.url else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ 사진 API 네트워크 오류:", error.localizedDescription)
                return
            }
            guard let data = data else {
                print("사진 API 응답 없음")
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("LostPhotos.php 응답:", raw)
            }

            do {
                let decoded = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async {
                    self.photos = decoded
                    self.currentPhotoIndex = 0
                }
            } catch {
                print("사진 배열 JSON 디코딩 오류:", error)
            }
        }.resume()
    }

    
    private func toggleBell() {
        isBelled.toggle()
        if isBelled {
            // 벨을 켰을 때만 키워드 등록
            addKeyword(word: item.title, userId: userPkey)
        } else {
            // 해제 로직(시간남으면
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
