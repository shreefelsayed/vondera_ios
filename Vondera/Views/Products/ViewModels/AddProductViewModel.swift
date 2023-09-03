//
//  AddProductViewMode.swift
//  Vondera
//
//  Created by Shreif El Sayed on 22/06/2023.
//

import Foundation
import Firebase
import FirebaseStorage
import PhotosUI
import Combine

class AddProductViewModel : NSObject, ObservableObject, PHPickerViewControllerDelegate {
    var storeId:String = ""
    var categorysDao:CategoryDao
    var productsDao:ProductsDao
    
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    init(storeId: String) {
        self.storeId = storeId
        self.categorysDao = CategoryDao(storeId: storeId)
        self.productsDao = ProductsDao(storeId: storeId)
        
        super.init()
        
        Task {
            await createProductId()
            await getStoreCategories()
        }
    }
    
    var productId = ""
    @Published var page = 1
    @Published var categories = [Category]()
    @Published var category:Category?
    @Published var isSheetPresented = false

    @Published var selectedPhotos: [UIImage] = []
    
    @Published var name = ""
    @Published var alwaysStocked = false
    @Published var sellingPrice = "0"
    @Published var cost = "0"
    @Published var quantity = "0"
    @Published var isSaving = false
    
    @Published var listVarients = [[String:[String]]]()
    @Published var listTitles = [String]()
    @Published var listOptions = [[String]]()
    
    @Published var showToast = false
    @Published var msg = ""
    
    func deleteVarient(i:Int) {
        listTitles.remove(at: i)
        listOptions.remove(at: i)
        listVarients.remove(at: i)
    }

    func canAddVarient() -> Bool {
        if listVarients.isEmpty { return true }
        if listTitles.last!.isEmpty || listOptions.last!.isEmpty {
            return false
        }
        
        return true
    }
    
    func addVarient() {
        guard canAddVarient() else {
            showMessage("Fill the current varient first")
            return
        }
        
        listVarients.append(["":[]])
        listTitles.append("")
        listOptions.append([String]())
    }
    
    func showMessage(_ msg:String) {
        self.msg = msg
        showToast.toggle()
    }
    
    func nextPage() async {
        if page == 1 {
            if (check1()) {page = 2}
        } else if page == 2 {
            if (check2()) {
                if alwaysStocked {
                    uploadPhotos()
                } else {
                    page = 3
                }
            }
        } else if page == 3 {
            if(check3()) {uploadPhotos()}
        }
    }
    
    func check1() -> Bool {
        guard !name.isBlank else {
            showMessage("Enter product name")
            return false
        }
        
        guard selectedPhotos.count > 0 else {
            showMessage("Select one photo at least")
            return false
        }
        
        guard category != nil else {
            showMessage("Select the product category")
            return false
        }
        
        guard sellingPrice.isNumeric else {
            showMessage("Enter a valid price amount")
            return false
        }
        
        guard cost.isNumeric else {
            showMessage("Enter a valid cost amount")
            return false
        }
        
        return true
    }
    
    func check2() -> Bool {
        var titleFilled = true
        var optionsProvided = true
        
        for str in listTitles {
            if str.isBlank {titleFilled = false}
        }
        
        for list in listOptions {
            if list.count < 2 {optionsProvided = false}
        }
        
        guard titleFilled else {
            showMessage("Fill all varients titles")
            return false
        }
        
        guard optionsProvided else {
            showMessage("Add at least 2 options to each varient")
            return false
        }
        
        return true
    }
    
    func check3() -> Bool {
        guard quantity.isNumeric else {
            showMessage("Enter a valid quantity amount")
            return false
        }
        
        return true
    }
    
    func listVarient() -> [[String: [String]]] {
        var listVars = [[String: [String]]]()
        for (index, title) in listTitles.enumerated() {
            listVars.append([title:listOptions[index]])
        }
        
        return listVars
    }
    
    func uploadPhotos() {
        DispatchQueue.main.async {
            self.isSaving = true
        }
        
        let storageRef = Storage.storage().reference().child("products").child(productId)
        FirebaseStorageUploader().uploadImagesToFirebaseStorage(images: selectedPhotos, storageRef: storageRef) { imageURLs, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.showMessage(error.localizedDescription)
                }
            } else if let imageURLs = imageURLs {
                self.saveProduct(uris: imageURLs)
            }
        }
    }
    
    func saveProduct(uris: [URL]) {
        Task {
            // MARK : Create a product Object
            var product = Product(name: name.lowercased(), id: productId, quantity: Int(quantity) ?? 0, addedBy: "", price: Double(sellingPrice) ?? 0, buyingPrice: Double(cost) ?? 0)
            
            product.storeId = storeId
            product.listPhotos = uris.map { $0.absoluteString }
            product.hashVarients = listVarient()
            product.alwaysStocked = alwaysStocked
            product.categoryId = category?.id ?? ""
            product.categoryName = category?.name ?? ""
            
            // MARK : Save the product to database
            do {
                try await productsDao.create(product)
                showMessage("Product has been added")
                
                // --> Saving Local
                var myUser = await LocalInfo().getLocalUser()
                if myUser?.storeId == storeId {
                    if var productsCount = myUser?.store?.productsCount {
                        productsCount = productsCount + 1
                        myUser?.store?.productsCount = productsCount
                        _ = await LocalInfo().saveUser(user: myUser!)
                    }
                }
                
                DispatchQueue.main.async {
                    self.shouldDismissView = true
                }
            } catch {
                showMessage(error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self.isSaving = false
            }
        }
    }
    
    func getStoreCategories() async {
        do {
            categories = try await categorysDao.getAll()
            category = categories.first
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func pickPhotos() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 6 - selectedPhotos.count
        configuration.filter = .images
        configuration.selection = .ordered
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        // Present the photo picker
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }
    
    func removePhoto(image: UIImage) {
        if let index = selectedPhotos.firstIndex(of: image) {
            selectedPhotos.remove(at: index)
        }
    }
    
    // Add a function to clear the selected photos
    func clearSelectedPhotos() {
        selectedPhotos.removeAll()
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self?.selectedPhotos.append(image)
                        }
                    }
                }
            }
        }
    }
        
    func createProductId() async {
        let id:String = "\(generateRandomNumber())"
        let isExist = await productsDao.productExist(id: id)
        if isExist {
            await createProductId()
            return
        }
        
        self.productId = id
    }
    
    func generateRandomNumber() -> Int {
        let randomNumber = arc4random_uniform(9000) + 1000
        return Int(randomNumber)
    }
}