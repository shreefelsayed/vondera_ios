//
//  Expanses.swift
//  Vondera
//
//  Created by Shreif El Sayed on 22/06/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Expense: Codable, Identifiable, Equatable {
    var id: String = ""
    @ServerTimestamp var date:Timestamp? = Timestamp(date: Date())
    var amount: Int = 0
    var description: String = ""
    var madeBy: String = ""
    var name: String = ""

    init(amount: Int, description: String, madeBy: String) {
        self.amount = amount
        self.description = description
        self.madeBy = madeBy
    }
    
    static func ==(lhs: Expense, rhs: Expense) -> Bool {
            return lhs.id == rhs.id
        }
}

extension Expense {
    static func example() -> Expense {
        return Expense(amount: 400, description: "Expanse Description", madeBy: "")
    }
}