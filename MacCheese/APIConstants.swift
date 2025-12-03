//  APIConstants.swift
//  MacCheese
//
//  Created by 양수빈 on 11/21/25.
//

enum API {
 // static let baseURL = "http://124.56.5.77/maccheese"
//  static let baseURL = "http://localhost:8000/maccheese"
    static let baseURL = "https://lambeen.du.r.appspot.com/"
 
    
    static let login       = "\(baseURL)/LoginV.php"
    static let signup      = "\(baseURL)/Signup_V.php"
    
    static let lostItemList    = "\(baseURL)/LostItemList_V.php"
    static let lostPhotos = "\(baseURL)/LostPhotos.php"
    static let lostComment     = "\(baseURL)/LostComment_V.php"
    static let foundPlaceList  = "\(baseURL)/FoundPlace_List_V.php"
    static let itemCategoryList = "\(baseURL)/ItemCategory_List_V.php"
    
    static let auctionList         = "\(baseURL)/auction_list.php"
    static let auctionItemDetail  = "\(baseURL)/auction_detail.php"
    
    static let auctionBids         = "\(baseURL)/auction_bids.php"
    static let auctionComment      = "\(baseURL)/AuctionComment_V.php"
    static let bidApply            = "\(baseURL)/bid_apply.php"
    
    static let noticeList   = "\(baseURL)/notice.php"
    static let noticeDetail = "\(baseURL)/notice_detail.php"
   
    static let searchResult = "\(baseURL)/SearchResult_V.php"
    static let keyword      = "\(baseURL)/keyword.php"
    static let myComments   = "\(baseURL)/myComments.php"
    
  
}
