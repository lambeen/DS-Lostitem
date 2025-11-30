//  APIConstants.swift
//  MacCheese
//
//  Created by 양수빈 on 11/21/25.
//

enum API {
 // static let baseURL = "http://124.56.5.77/maccheese"
  static let baseURL = "http://localhost:8000/maccheese"
 // static let baseURL = "https://maccheese-server.du.r.appspot.com"
    
    static let login       = "\(baseURL)/LoginV.php"
    static let signup      = "\(baseURL)/Signup_V.php"
    
    static let lostItemList    = "\(baseURL)/LostItemList_V.php"
    static let lostComment     = "\(baseURL)/LostComment_V.php"
    static let foundPlaceList  = "\(baseURL)/FoundPlace_List_V.php"
    static let itemCategoryList = "\(baseURL)/ItemCategory_List_V.php"
    
    static let auctionList         = "\(baseURL)/AuctionList_V.php"
    static let auctionItem         = "\(baseURL)/auction_item.php"
    static let auctionItemOverview = "\(baseURL)/auction_item_overview.php"
    static let auctionItemDetail  = "\(baseURL)/AuctionitemDetail.php"
    static let auctionEnded        = "\(baseURL)/auction_ended.php"
    static let auctionComment      = "\(baseURL)/AuctionComment_V.php"
    static let bidApply            = "\(baseURL)/BIDAPPLY.php"
    
    static let noticeList   = "\(baseURL)/notice.php"
    static let noticeDetail = "\(baseURL)/notice_detail.php"
   
    static let searchResult = "\(baseURL)/SearchResult_V.php"
    static let keyword      = "\(baseURL)/Keyword.php"
    static let myComments   = "\(baseURL)/MyComments.php"
    
  
}
