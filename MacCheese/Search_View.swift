//
//  Search_View.swift
//  MacCheese
//
//  Created by mac10 on 11/03/25.
//


import SwiftUI

// 카테고리 구조체
struct ItemCategoryDTO: Identifiable, Decodable {
    let pkey: Int
    let name: String
    let type: Int
    var id: Int { pkey }
}

// 장소 구조체
struct FoundPlaceDTO: Identifiable, Decodable {
    let pkey: Int
    let placename: String
    let floor: String?
    var id: Int { pkey }
}

struct Search_View: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var categories: [ItemCategoryDTO] = []
    @State private var places: [FoundPlaceDTO] = []
    
    @State private var category: String = ""
    @State private var place: String = ""
    @State private var keyword: String = ""
    
    @State private var goResult: Bool = false
    
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    var body: some View {
        VStack(spacing: 30) {
            
            
            // 입력 영역
            ScrollView {
                VStack(alignment: .leading, spacing: 48) {
                    
                    RowLabelPicker(
                        title: "카테고리",
                        placeholder: "선택",
                        selection: $category,
                        options: categories.map { $0.name },
                        accent: accent
                    )
                    
                    RowLabelPicker(
                        title: "습득장소",
                        placeholder: "선택",
                        selection: $place,
                        options: places.map { $0.placename },
                        accent: accent
                    )
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("습득물명")
                        TextField("검색어를 입력하세요", text: $keyword)
                            .textInputAutocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        Divider()
                            .frame(height: 1)
                            .background(accent)
                    }
                    .font(.body)
                    
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            
            // 하단 버튼
            HStack(spacing: 12) {
                Button(action: { goResult = true }) {
                    Text("확인")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accent)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                Button(action: { dismiss() }) {
                    Text("취소")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray4))
                        .foregroundColor(.black)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .duksungHeaderNav(
            title: "유실물 검색하기",
            showSearch: false,
            hideBackButton: false
        )
        .onAppear {
            loadCategories()
            loadPlaces()
        }
        .background(
            
            NavigationLink(
                destination: SearchResult_View(
                    selectedCategoryPkey: categories.first(where: { $0.name == category })?.pkey,
                    selectedPlacePkey: places.first(where: { $0.placename == place })?.pkey,
                    selectedDate: nil,
                    keyword: keyword.isEmpty ? nil : keyword,
                    userPkey: 1
                )
                .duksungHeaderNav(
                    title: "검색 결과",
                    showSearch: true,
                    hideBackButton: false
                ),
                isActive: $goResult
                
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    // 카테고리 불러오기
    private func loadCategories() {
        guard let url = URL(string: API.itemCategoryList) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            
            if let decoded = try? JSONDecoder().decode([ItemCategoryDTO].self, from: data) {
                DispatchQueue.main.async {
                    categories = decoded
                }
            }
        }.resume()
    }
    
    // 장소 불러오기
    private func loadPlaces() {
        guard let url = URL(string:API.foundPlaceList) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            
            if let decoded = try? JSONDecoder().decode([FoundPlaceDTO].self, from: data) {
                DispatchQueue.main.async {
                    places = decoded
                }
            }
        }.resume()
    }
}

// 라벨 있는 메뉴 선택
private struct RowLabelPicker: View {
    let title: String
    let placeholder: String
    @Binding var selection: String
    let options: [String]
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                
                Menu {
                    ForEach(options, id: \.self) { opt in
                        Button(opt) {
                            selection = opt
                        }
                    }
                    Button("지우기", role: .destructive) {
                        selection = ""
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selection.isEmpty ? placeholder : selection)
                            .foregroundColor(selection.isEmpty ? .secondary : .primary)
                        Image(systemName: "chevron.down")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
                .frame(height: 1)
                .background(accent)
        }
        .font(.body)
    }
}

#Preview {
    NavigationStack {
        Search_View()
    }
}
