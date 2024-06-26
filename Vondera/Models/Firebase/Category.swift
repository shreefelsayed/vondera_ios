//
//  Category.swift
//  Vondera
//
//  Created by Shreif El Sayed on 22/06/2023.
//

import Foundation
import FirebaseFirestoreSwift

struct Category: Codable, Identifiable, Equatable, Hashable {
    var id: String = ""
    var name: String = ""
    var url: String = ""
    var desc:String? = ""
    var hidden:Bool? = false
    var sortValue: Int? = 0
    var productsCount: Int? = 0
    
    init(id: String, name: String, url: String, sortValue: Int? = 0, productsCount: Int = 0) {
        self.id = id
        self.name = name
        self.url = url
        self.sortValue = sortValue
        self.productsCount = productsCount
    }
    
    static func ==(lhs: Category, rhs: Category) -> Bool {
            return lhs.id == rhs.id
        }
    
    func filter(searchText:String) -> Bool {
        if searchText.isBlank {
            return true
        }
        
        return self.id.localizedCaseInsensitiveContains(searchText)
        || self.name.localizedCaseInsensitiveContains(searchText)
        || ((self.desc?.localizedCaseInsensitiveContains(searchText)) != nil)
    }
    
}

extension Category {
    
    
    static func example() -> Category {
        return Category(id: "", name: "T-shirts", url: "https://eg.jumia.is/unsafe/fit-in/500x500/filters:fill(white)/product/61/805162/1.jpg?1359")
    }
}
