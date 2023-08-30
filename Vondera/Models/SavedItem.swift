//
//  SavedItem.swift
//  Vondera
//
//  Created by Shreif El Sayed on 29/06/2023.
//

import Foundation

struct SavedItems: Codable, Equatable, Hashable {
    let randomId: String
    let productId: String
    let hashMap: [String: String]
    var quantity: Int

    init(randomId: String, productId: String, hashMap: [String: String], quantity: Int = 1) {
        self.randomId = randomId
        self.productId = productId
        self.hashMap = hashMap
        self.quantity = quantity
    }
    
    // Custom CodingKeys in case you want to change the property names in the JSON representation
    private enum CodingKeys: String, CodingKey {
        case randomId, productId, hashMap, quantity
    }
}
