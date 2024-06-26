//
//  SalesReport.swift
//  Vondera
//
//  Created by Shreif El Sayed on 30/08/2023.
//

import Foundation
import SwiftXLSX

class ProductSalesExcel {
    var name = "Product Sales"
    var listOrders:[Order]
    let book = XWorkBook()
    var sheet:XSheet
    
    init(name: String = "Product Sales", listOrders: [Order]) {
        self.name = name
        self.listOrders = listOrders.filter({$0.isHidden == false && $0.statue != "Deleted"})
        sheet = book.NewSheet(name)
    }
    
    func generateReport() -> URL? {
        // MARK : Create the header
        createHeader(["Product ID",
                      "Product Name",
                      "Product Variants",
                      "Sold Count",
                      "Total Sales (EGP)",
                      "Total Cost (EGP)"])
        
        let totalItems = listOrders.getFinalProductList()
        //MARK : Add Items
        for (index, productObject) in totalItems.enumerated() {
            let data:[String] = ["#\(productObject.productId)",
                                 productObject.name,
                                 productObject.getVarientsString(),
                                 "\(productObject.quantity) Pieces",
                                 "\((productObject.price * productObject.quantity.double()).toString()) LE",
                                 "\((productObject.buyingPrice * productObject.quantity.double()).toString()) LE"]
            
            addRow(rowNumber: (index + 2), items: data)
        }
        
        addFinalRow()
              
        // MARK : Create file and save
        let fileid = book.save("\(name).xlsx")
        let url = URL(fileURLWithPath: fileid)
        return url
    }
    
    func addFinalRow() {
        let totalItems = listOrders.getFinalProductList()
        
        var count = 0
        var sales = 0.0
        var cost = 0.0

        totalItems.forEach { item in
            count += item.quantity
            sales += Double(item.price * Double(item.quantity))
            cost += Double(item.buyingPrice * Double(item.quantity))

        }
        
        let data:[String] = [
            "\(totalItems.count) Products",
            "",
            "\(count) Pieces",
            "\(sales.toString()) EGP",
            "\(cost.toString()) EGP"]
        
        addRow(rowNumber: listOrders.count + 2, items: data)
    }
    
    func createHeader(_ items:[String]) {
        for (index, title) in items.enumerated() {
            let cell = sheet.AddCell(XCoords(row: 1, col: (index + 1)))
            cell.Cols(txt: .white, bg: .darkGray)
            cell.value = .text(title.uppercased(with: .autoupdatingCurrent))
            cell.width = 100
            cell.Font = XFont(.TrebuchetMS, 8, true)
            cell.alignmentHorizontal = .center
        }
    }
    
    
    
    func addRow(rowNumber:Int, items:[String]) {
        for (index, title) in items.enumerated() {
            let cell = sheet.AddCell(XCoords(row: rowNumber, col: (index + 1)))
            cell.Cols(txt: .black, bg: .white)
            cell.width = 100
            cell.value = .text(title.uppercased(with: .autoupdatingCurrent))
            cell.Font = XFont(.TrebuchetMS, 5, true)
            cell.alignmentHorizontal = .left
        }
    }
}
