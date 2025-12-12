//
//  SearchResult_View.swift
//  MacCheese
//

import SwiftUI

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

    var body: some View {
        VStack(spacing: 0) {

            Button {
                dismiss()
            } label: {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .overlay(
                        HStack {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(Color(red: 0.78, green: 0.10, blue: 0.36))
                                .padding(.trailing, 24)
                        }
                    )
            }
            .frame(height: 40)
            .padding(.horizontal, 40)
            .padding(.top, 8)
            .buttonStyle(.plain)

            List(items) { result in
                NavigationLink {
                    LostDetail_View(
                        item: LostItemDTO(
                            id: result.itemPkey,
                            title: result.title,
                            categoryName: result.category ?? "카테고리 없음",
                            placeName: result.place,
                            status: result.status,
                            createdDate: result.foundDateShort,
                            photoURL: result.photoURL,     // 여기만 정상 전달
                            description: nil
                        ),
                        userPkey: userPkey
                    )
                } label: {
                    SearchResultRowView(item: result)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            loadSearchResults()
        }
    }

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
            f.timeZone = TimeZone(identifier: "Asia/Seoul")
            params.append("date=\(f.string(from: date))")
        }
        if let keyword, !keyword.isEmpty {
            let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
            params.append("keyword=\(encoded)")
        }

        if !params.isEmpty {
            urlString += "?" + params.joined(separator: "&")
        }

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let decoded = try? JSONDecoder().decode([SearchItemDTO].self, from: data)
            else { return }

            DispatchQueue.main.async {
                items = decoded
            }
        }.resume()
    }
}

struct SearchResultRowView: View {

    let item: SearchItemDTO
    @State private var photos: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {

                if let first = photos.first,
                   !first.isEmpty,
                   let url = URL(string: first) {

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
                    Text(item.title).font(.headline)
                    Text(item.category ?? "").font(.subheadline)
                    Text(item.place).font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("상태: \(item.statusLabel)").font(.subheadline)
                    Text(item.foundDateShort).font(.subheadline)
                }
            }
            .padding(.vertical, 8)

            Divider()
        }
        .onAppear {
            if photos.isEmpty {
                loadPhotos()
            }
        }
    }

    private func loadPhotos() {

        guard var comp = URLComponents(string: API.lostPhotos) else { return }
        comp.queryItems = [
            URLQueryItem(name: "item_pkey", value: String(item.itemPkey))
        ]

        guard let url = comp.url else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else { return }

            DispatchQueue.main.async {
                photos = decoded
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        SearchResult_View(
            selectedCategoryPkey: nil,
            selectedPlacePkey: nil,
            selectedDate: nil,
            keyword: nil,
            userPkey: 1
        )
    }
}

