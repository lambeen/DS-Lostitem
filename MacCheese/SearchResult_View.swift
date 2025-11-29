//
//  SearchResult_View.swift
//  MacCheese
//

import SwiftUI

// 검색 결과 구조체
struct SearchItemDTO: Identifiable, Decodable {
    let itemPkey: Int
    let category: String?
    let title: String
    let place: String
    let status: Int
    let statusLabel: String
    let foundDate: String
    let photoURL: String?
    
    var id: Int { itemPkey }
    
    enum CodingKeys: String, CodingKey {
        case itemPkey    = "item_pkey"
        case category
        case title       = "lost_title"
        case place       = "place_name"
        case status
        case statusLabel = "status_label"
        case foundDate   = "found_date"
        case photoURL    = "photo_url"
    }
    
    var foundDateShort: String {
        String(foundDate.prefix(10))
    }
}

struct SearchResult_View: View {
    let selectedCategoryPkey: Int?
    let selectedPlacePkey: Int?
    let selectedDate: Date?
    let keyword: String?
    let userPkey: Int
    
    @State private var items: [SearchItemDTO] = []
    
    @Environment(\.dismiss) private var dismiss
    
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 상단
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15),
                                radius: 4, x: 0, y: 2)
                    
                    HStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(accent)
                            .padding(.trailing, 24)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(height: 40)
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
        
            
            List(items) { result in
                NavigationLink(
                    destination: LostDetail_View(
                        item: LostItemDTO(
                            id: result.itemPkey,
                            title: result.title,
                            categoryName: result.category ?? "카테고리 없음",
                            placeName: result.place,
                            status: result.status,
                            createdDate: result.foundDateShort, // yyyy-MM-dd 잘라쓴 날짜
                            photoURL: result.photoURL,
                            description: nil                    // 검색 결과 JSON에 없으니까 일단 nil
                        ),
                        userPkey: userPkey
                    )
                ) {
                    SearchResultRowView(item: result)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            
            Spacer()
        }
        
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            loadSearchResults()
        }
    }
    
    // 검색 결과 불러오기
    private func loadSearchResults() {
        var urlString = API.searchResult
        var params: [String] = []
        
        if let cat = selectedCategoryPkey {
            params.append("category_pkey=\(cat)")
        }
        if let place = selectedPlacePkey {
            params.append("found_place_pkey=\(place)")
        }
        
        if let date = selectedDate {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "ko_KR")
            f.timeZone = TimeZone(identifier: "Asia/Seoul")
            let d = f.string(from: date)
            params.append("date=\(d)")
        }
        
        if let keyword = keyword, !keyword.isEmpty {
            params.append("keyword=\(keyword)")
        }
        
        if !params.isEmpty {
            urlString += "?" + params.joined(separator: "&")
        }
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let _ = error {
                return
            }
            
            guard let data = data else { return }
            
            if let decoded = try? JSONDecoder().decode([SearchItemDTO].self, from: data) {
                DispatchQueue.main.async {
                    items = decoded
                }
            }
        }.resume()
    }
}

// 결과 셀
struct SearchResultRowView: View {
    let item: SearchItemDTO
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                
                if let urlStr = item.photoURL,
                   let url = URL(string: urlStr) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(.systemGray5)
                    }
                    .frame(width: 80, height: 80)
                    .clipped()
                } else {
                    Color(.systemGray5)
                        .frame(width: 80, height: 80)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.category ?? "")
                        .font(.subheadline)
                    Text(item.place)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("상태: \(item.statusLabel)")
                        .font(.subheadline)
                    Text(item.foundDateShort)
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 8)
            
            Divider()
        }
    }
}

#Preview {
    SearchResult_View(
        selectedCategoryPkey: nil,
        selectedPlacePkey: nil,
        selectedDate: nil,
        keyword: nil,
        userPkey: 1
    )
}
