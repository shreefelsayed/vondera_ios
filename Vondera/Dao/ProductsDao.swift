//
//  ProductsDao.swift
//  Vondera
//
//  Created by Shreif El Sayed on 01/06/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class ProductsDao {
    var collection:CollectionReference
    let pageSize = 10
    
    init(storeId:String) {
        self.collection = Firestore.firestore().collection("stores").document(storeId).collection("products")
    }
    
    func delete(id:String) async throws {
        return try await collection.document(id).delete()
    }
    
    func create(_ product:StoreProduct) async throws {
        try collection.document(product.id).setData(from: product)
    }
    
    func productExist(id:String) async throws -> Bool {
        let doc = try await  collection.document(id).getDocument()
        return doc.exists
    }
    
    func getInStock() async throws -> [StoreProduct] {
        return try await collection
            .whereField("quantity", isGreaterThan: 0)
            .order(by: "quantity", descending: true)
            .getDocuments(as: StoreProduct.self)
    }
    
    func getInStock(lastSnapShot:DocumentSnapshot?) async throws -> ([StoreProduct], QueryDocumentSnapshot?) {
        var query:Query = collection
            .order(by: "quantity", descending: true)
            .whereField("quantity", isGreaterThan: 0)
            .limit(to: pageSize)
        
        if lastSnapShot != nil {
            query = query.start(afterDocument: lastSnapShot!)
        }
                
        let docs = try await query.getDocuments()
        return (convertToList(snapShot: docs), docs.documents.last)
    }
    
    func getOutOfStock() async throws -> [StoreProduct] {
        try await collection
            .order(by: "quantity", descending: false)
            .whereField("quantity", isLessThanOrEqualTo: 0)
            .getDocuments(as: StoreProduct.self)
    }
    
    func getOutOfStock(lastSnapShot:DocumentSnapshot?) async throws -> ([StoreProduct], QueryDocumentSnapshot?) {
        var query:Query = collection
            .order(by: "quantity", descending: false)
            .whereField("quantity", isLessThanOrEqualTo: 0)
           
        
        if lastSnapShot != nil {
            query = query.start(afterDocument: lastSnapShot!)
        }
        
        query.limit(to: pageSize)
        
        let docs = try await query.getDocuments()
        return (convertToList(snapShot: docs), docs.documents.last)
    }
    
    func getStockLessThen(almostOut:Int) async throws -> [StoreProduct] {
        return try await collection
            .whereField("quantity", isLessThanOrEqualTo: almostOut)
            .whereField("quantity", isGreaterThan: 0)
            .order(by: "quantity", descending: true)
            .getDocuments(as: StoreProduct.self)
    }
    
    func getStockLessThen(almostOut:Int, lastSnapShot:DocumentSnapshot?) async throws -> ([StoreProduct], QueryDocumentSnapshot?) {
        var query:Query = collection
            .whereField("quantity", isLessThanOrEqualTo: almostOut)
            .whereField("quantity", isGreaterThan: 0)
            .order(by: "quantity", descending: true)
           
        
        if lastSnapShot != nil {
            query = query.start(afterDocument: lastSnapShot!)
        }
        
        query.limit(to: pageSize)
        
        let docs = try await query.getDocuments()
        return (convertToList(snapShot: docs), docs.documents.last)
    }
    
    func getByCategory(id:String) async throws -> [StoreProduct] {
        return try await collection
            .whereField("categoryId", isEqualTo: id)
            .getDocuments(as: StoreProduct.self)
        
    }
    
    func getAll(sort:String = "name") async throws -> [StoreProduct] {
        return try await collection
            .order(by: sort, descending: true)
            .getDocuments(as: StoreProduct.self)
    }
    
    func addToStock(id:String, q:Double) async throws {
        return try await collection.document(id).updateData(["quantity":  FieldValue.increment(q)])
    }
    
    func detectFromStock(id:String, productInfo:ProductOrderObject) async throws {
        return try await collection.document(id).updateData(["quantity":  FieldValue.increment(Double(productInfo.quantity * -1)),
                                                             "listOrders":FieldValue.arrayUnion([productInfo])])
    }
    
    func update(id:String, hashMap:[String:Any]) async throws {
        return try await collection.document(id).updateData(hashMap)
    }
    
    func getTopSelling(limit:Int = 10) async throws -> [StoreProduct] {
        return  try await collection
            .order(by: "sold", descending: true)
            .whereField("sold", isGreaterThan: 0)
            .limit(to: limit)
            .getDocuments(as: StoreProduct.self)
    }
    
    func getMostVieweed(limit:Int = 10) async throws -> [StoreProduct] {
        return  try await collection
            .order(by: "views", descending: true)
            .whereField("views", isGreaterThan: 0)
            .limit(to: limit)
            .getDocuments(as: StoreProduct.self)
    }
    
    func getProduct(id:String) async throws -> StoreProduct? {
        let doc = try await collection.document(id).getDocument()
        if !doc.exists { return nil }
        return try doc.data(as: StoreProduct.self)
    }
    
    func removeOrderItem(orderId:String, productId:String, q:Int) async throws -> Bool {
        let prod = try await getProduct(id: productId)
        if var prod = prod {
            var found = false
            for (index, orderObj) in prod.listOrder!.enumerated() {
                if orderObj.orderId == orderId {
                    prod.listOrder!.remove(at: index)
                    found.toggle()
                    break
                }
            }
            
            if found {
                let hash:[String:Any] = ["listOrder": prod.listOrder!, "quantity": FieldValue.increment(Double(q))]
                try await update(id: productId, hashMap: hash)
                return true
            }
            
            return false
        }
        
        return false
    }
    
    func convertToList(snapShot:QuerySnapshot) -> [StoreProduct] {
        let arr = snapShot.documents.compactMap{doc -> StoreProduct? in
            return try! doc.data(as: StoreProduct.self)
        }
        
        return arr
    }
}
