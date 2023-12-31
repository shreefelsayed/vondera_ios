//
//  CourierFeesViewModel.swift
//  Vondera
//
//  Created by Shreif El Sayed on 03/07/2023.
//

import Foundation
import Combine
import FirebaseFirestore
import SwiftUI

class CourierFeesViewModel : ObservableObject {
    var id:String
    var storeId:String
    
    var couriersDao:CouriersDao
    
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    @Published var items = [CourierPrice]()
    
    @Published var isSaving = false
    @Published var isLoading = false
    @Published var msg:LocalizedStringKey?
    
    init(id:String, storeId:String) {
        self.id = id
        self.storeId = storeId
        
        couriersDao = CouriersDao(storeId: storeId)
        
        // --> Set the published values
        Task {
            await getData()
        }
    }
    
    func getData() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        do {
            let courier = try await couriersDao.getCourier(id: id)
            items = courier.listPrices.uniqueElements()
        } catch {
            print(error.localizedDescription)
        }
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func update() async {
        DispatchQueue.main.async {
            self.isSaving = true
        }
        
        do {
            // --> Update the database
            let map:[String:[CourierPrice]] = ["listPrices": items.uniqueElements()]
            let encoded: [String: Any]
            encoded = try! Firestore.Encoder().encode(map)
            
            try await couriersDao.update(id: id, hashMap: encoded)
            
            showToast("Courier info changed")
            DispatchQueue.main.async {
                self.shouldDismissView = true
            }
        } catch {
            showToast(error.localizedDescription.localize())
        }
        
        
        DispatchQueue.main.async {
            self.isSaving = false
        }
        
    }
    
    func showToast(_ msg: LocalizedStringKey) {
        self.msg = msg
    }
}

