//
//  StoreOptionsViewModel.swift
//  Vondera
//
//  Created by Shreif El Sayed on 26/06/2023.
//

import Foundation
import Combine
import SwiftUI

class StoreOptionsViewModel: ObservableObject {
    var store:Store
    var storesDao = StoresDao()
    
    @Published var ordering:Bool = false
    @Published var offline:Bool = false
    @Published var prepaid:Bool = false
    @Published var attachments:Bool = false
    @Published var label:Bool = false
    @Published var whatsapp:Bool = false
    @Published var chat:Bool = false
    @Published var sellerName = false
    
    @Published var editPrice:Bool = false
    @Published var indec:Int = 20
    @Published var reset = false
    
    @Published var isSaving:Bool = false
    @Published var msg:LocalizedStringKey?
    
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    init(store:Store) {
        self.store = store
        ordering = store.canOrder ?? true
        offline = !(store.onlyOnline ?? true)
        prepaid = store.canPrePaid ?? true
        attachments = store.orderAttachments ?? true
        label = store.cantOpenPackage ?? false
        whatsapp = store.localWhatsapp ?? true
        chat = store.chatEnabled ?? true
        reset = store.canWorkersReset ?? false
        editPrice = store.canEditPrice ?? false
        sellerName = store.sellerName ?? false
        indec = store.almostOut ?? 20
    }
    
    func save() async {
        DispatchQueue.main.async {
            self.isSaving = true
        }
        
        do {
            // --> Update the database
            let map:[String:Any] = ["canOrder": ordering,
                                    "onlyOnline":!offline,
                                    "canPrePaid":prepaid,
                                    "orderAttachments":attachments,
                                    "cantOpenPackage":label,
                                    "sellerName":sellerName,
                                    "localWhatsapp":whatsapp,
                                    "chatEnabled":chat,
                                    "canWorkersReset":reset,
                                    "canEditPrice":editPrice,
                                    "almostOut":indec]
            
            try await storesDao.update(id: store.ownerId, hashMap: map)
            store.canOrder = map["canOrder"] as? Bool ?? false
            store.onlyOnline = !(map["onlyOnline"] as? Bool ?? true)
            store.canPrePaid = map["canPrePaid"] as? Bool ?? false
            store.orderAttachments = map["orderAttachments"] as? Bool ?? true
            store.cantOpenPackage = map["cantOpenPackage"] as? Bool ?? false
            store.sellerName = map["sellerName"] as? Bool ?? false
            store.localWhatsapp = map["localWhatsapp"] as? Bool ?? true
            store.chatEnabled = map["chatEnabled"] as? Bool ?? false
            store.canWorkersReset = map["canWorkersReset"] as? Bool ?? false
            store.canEditPrice = map["canEditPrice"] as? Bool ?? false
            store.almostOut = map["almostOut"] as? Int ?? 0
            
            // Saving local
            if var myUser = UserInformation.shared.getUser() {
                myUser.store = store
                UserInformation.shared.updateUser(myUser)
            }
            
            showTosat(msg: "Updated".localize())
            DispatchQueue.main.async {
                self.shouldDismissView = true
            }
        } catch {
            showTosat(msg: error.localizedDescription.localize())
        }
        
        
        DispatchQueue.main.async {
            self.isSaving = false
        }
        
    }
    
    func showTosat(msg: LocalizedStringKey) {
        self.msg = msg
    }
}
