import SwiftUI

// 공통 색상
let accent = Color(red: 0.78, green: 0.10, blue: 0.36)



// 공통 상단 헤더 + 네비게이션바
struct DuksungHeaderNavModifier: ViewModifier {
    var titleText: String
    var showSearch: Bool
    var hideBackButton: Bool
    
    @Environment(\.dismiss) private var dismiss // 뒤로가기용
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // 상단 붉은 타이틀 바
            Text(titleText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(accent)
            
            // 아래에 원래 각 화면의 컨텐츠가 붙음
            content
        }
        // 네비게이션바 공통 설정
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(accent)
        .toolbar {
            
            // 뒤로가기 버튼 (필요할 때만)
            if !hideBackButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(accent)
                    }
                }
            }
            
            // 로고
            ToolbarItem(placement: .principal) {
                Image("ds_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            
            // 검색 아이콘
            if showSearch {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        Search_View()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .foregroundColor(accent)
                    }
                }
            }
        }
    }
}


extension View {
    // 로고 + 타이틀바 공통적용하기
    func duksungHeaderNav(
        title: String = "덕성여대 유실물 통합포털",
        showSearch: Bool = true,
        hideBackButton: Bool = true
    ) -> some View {
        self.modifier(
            DuksungHeaderNavModifier(
                titleText: title,
                showSearch: showSearch,
                hideBackButton: hideBackButton
            )
        )
    }
}


// 서버에서 내려오는 유실물 DTO
struct LostItemDTO: Identifiable, Codable {
    let id: Int
    let title: String
    let categoryName: String
    let placeName: String
    let status: Int
    let createdDate: String
    let photoURL: String?
    let description : String?
    
    enum CodingKeys: String, CodingKey {
        case id           = "item_pkey"
        case title        = "lost_title"
        case categoryName = "category_name"
        case placeName    = "place_name"
        case status       = "status"
        case createdDate  = "created_date"
        case photoURL     = "photo_url"
        case description = "description"
    }
}


// 상단 카테고리 필터 (UI용)
enum LostItemFilter: String, CaseIterable {
    case all         = "전체"
    case valuables   = "귀중물"   // type = 0
    case electronics = "전자기기" // type = 1
    case clothing    = "의류"     // type = 2
    case etcGoods    = "잡화"     // type = 3
    case others      = "기타"     // type = 4
}


struct LostItemList_View: View {
    let userPkey: Int
    
    //서버에서 가져올 유실물목록데이터
    @State private var items: [LostItemDTO] = []
    @State private var selectedFilter: LostItemFilter = .all
    
    //페이지네이션 상태
    @State private var currentPage: Int = 1
    private let pageSize: Int = 4
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 카테고리 필터 탭
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LostItemFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                            currentPage = 1
                        } label: {
                            Text(filter.rawValue)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedFilter == filter
                                    ? accent.opacity(0.9)
                                    : Color(.systemGray6)
                                )
                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // 현재 데이터 개수
            VStack(spacing: 0) {
                Text("현재 유실물 개수: \(filteredItems.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                Divider()
            }
            
            
            // 리스트 (현재 페이지의 아이템만)
            List(pagedItems) { item in
                NavigationLink {
                    LostDetail_View(item: item,   userPkey: userPkey)
                } label: {
                    LostItemRowView(item: item)
                }
                .listRowSeparator(.visible)
            }
            .listStyle(.plain)
            .id(currentPage)
            
            
            // 페이지 표시 (1 / N 형식)
            HStack(spacing: 16) {
                Button {
                    if currentPage > 1 {
                        currentPage -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(currentPage <= 1)
                
                Text("\(currentPage) / \(totalPages)")
                    .font(.subheadline)
                
                Button {
                    if currentPage < totalPages {
                        currentPage += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(currentPage >= totalPages)
            }
            .padding(.vertical, 8)
            
            Spacer().frame(height: 32)
        }
        .duksungHeaderNav(
            title: "덕성여대 유실물 통합포털", // 붉은 타이틀 바 텍스트
            showSearch: true,                 // 오른쪽 검색 버튼 표시
            hideBackButton: true              // 루트 화면이니까 뒤로가기 숨김
        )
        .onAppear {
            // 서버에서 실제 데이터 가져오기
            loadItems()
        }
    }
    
    // 필터링
    private var filteredItems: [LostItemDTO] {
        switch selectedFilter {
        case .all:
            return items
        case .valuables:
            return items.filter { $0.categoryName == "귀중물" }
        case .electronics:
            return items.filter { $0.categoryName == "전자기기" }
        case .clothing:
            return items.filter { $0.categoryName == "의류" }
        case .etcGoods:
            return items.filter { $0.categoryName == "잡화" }
        case .others:
            return items.filter { $0.categoryName == "기타" }
        }
    }


    
    //현재 페이지에 해당하는 아이템만 잘라내기
    private var pagedItems: [LostItemDTO] {
        let total = filteredItems.count
        guard total > 0 else { return [] }
        
        let startIndex = (currentPage - 1) * pageSize
        if startIndex >= total { return [] }
        
        let endIndex = min(startIndex + pageSize, total)
        return Array(filteredItems[startIndex..<endIndex])
    }
    
    //전체 페이지 수
    private var totalPages: Int {
        let count = filteredItems.count
        if count == 0 { return 1 }
        return Int(ceil(Double(count) / Double(pageSize)))
    }
    
    //서버 통신
    private func loadItems() {
        guard let url = URL(string:API.lostItemList) else {
            print("❌ 서버 주소가 잘못되었습니다.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("❌ 네트워크 오류: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ 서버 응답이 없습니다!")
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("LostItemList_V.php 응답:", raw)
            }
            
            do {
                let decoded = try JSONDecoder().decode([LostItemDTO].self, from: data)
                DispatchQueue.main.async {
                    self.items = decoded
                    self.currentPage = 1
                    
                    print("=== 서버에서 받은 카테고리 목록 ===")
                            for item in decoded {
                                print("[\(item.id)] \(item.title) / categoryName = '\(item.categoryName)'")
                            }
                }
            } catch {
                print("❌ JSON 디코딩 오류:", error)
            }
        }.resume()
    }
}


// - 한 줄 셀 UI
struct LostItemRowView: View {
    let item: LostItemDTO
    
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
    
    private var displayCategory: String {
        item.categoryName.isEmpty ? "카테고리 없음" : item.categoryName
    }
    
    private var displayPlace: String {
        item.placeName.isEmpty ? "위치 정보 없음" : item.placeName
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // 썸네일
            if let urlStr = item.photoURL,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // 텍스트 영역
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(displayCategory)
                        .font(.subheadline)
                    
                    Text(displayPlace)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("상태: \(statusText)")
                        .font(.subheadline)
                    
                    Text(item.createdDate)
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 6)
    }
}


struct LostItemList_View_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LostItemList_View(userPkey: 1)
        }
    }
}
