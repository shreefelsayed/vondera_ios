//
//  StringExtenstions.swift
//  Vondera
//
//  Created by Shreif El Sayed on 01/06/2023.
//

import Foundation
import FirebaseFirestore
import SwiftUI
import PhotosUI

extension Timestamp {
    func toString(format: String = "yyyy MMM, dd") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: dateValue())
    }
}

extension LocalizedStringKey {
    public func toString() -> String {
        //use reflection
        let mirror = Mirror(reflecting: self)
        
        //try to find 'key' attribute value
        let attributeLabelAndValue = mirror.children.first { (arg0) -> Bool in
            let (label, _) = arg0
            if(label == "key"){
                return true;
            }
            return false;
        }
        
        if(attributeLabelAndValue != nil) {
            //ask for localization of found key via NSLocalizedString
            return String.localizedStringWithFormat(NSLocalizedString(attributeLabelAndValue!.value as! String, comment: ""));
        }
        else {
            return "Swift LocalizedStringKey signature must have changed. @see Apple documentation."
        }
    }
}

extension Double {
    func toString(withDecimalPlaces places: Int) -> String {
            return String(format: "%.\(places)f", self)
        }
    
    func toString() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0
        
        guard let formattedString = numberFormatter.string(from: NSNumber(value: self)) else {
            return ""
        }
        
        return formattedString
    }
}

extension Int {
    func double() -> Double {
        return Double(self)
    }
}

extension String {
    func localize() -> LocalizedStringKey {
        return LocalizedStringKey(self)
    }
    
    
    func toIntOrZero() -> Int {
        return Int(self) ?? 0
    }
    
    // Converts a String to Double and returns 0.0 if conversion fails
    func toDoubleOrZero() -> Double {
        return Double(self) ?? 0.0
    }
    
    var firstName: String {
        let components = self.components(separatedBy: " ")
        if let firstName = components.first {
            return firstName
        } else {
            return self
        }
    }
    
    var isValidEmail: Bool {
        // Regular expression pattern to match the email format
        let emailRegex = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        // Create a predicate with the email regex pattern
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        // Evaluate the predicate for the current string
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidName : Bool {
        
        return self.count >= 3
    }
    
    var isValidPassword:Bool {
        return self.count >= 6
    }
    
    var isNumeric: Bool {
        let numericSet = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: self)
        return numericSet.isSuperset(of: characterSet)
    }
    
    var isPhoneNumber: Bool {
        let requiredLength = 11
        let prefix = "01"
        
        guard count == requiredLength else {
            return false
        }
        
        guard self.isNumeric else {
            return false
        }
        
        return hasPrefix(prefix)
    }
    
    func containsOnlyEnglishLetters() -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[a-zA-Z]*$", options: .caseInsensitive)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
    
    func containsOnlyEnglishLettersOrNumbers() -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[a-zA-Z0-9]*$", options: .caseInsensitive)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
    
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func toHtml() -> NSAttributedString {
        let encodedData = self.data(using: String.Encoding.utf8)!
        var attributedString: NSAttributedString
        
        do {
            attributedString = try NSAttributedString(data: encodedData, options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html,NSAttributedString.DocumentReadingOptionKey.characterEncoding:NSNumber(value: String.Encoding.utf8.rawValue)], documentAttributes: nil)
            
            return attributedString
        } catch let error as NSError {
            print(error.localizedDescription)
            return NSAttributedString.empty
        } catch {
            print("error")
            return NSAttributedString.empty
        }
    }
    
    func capitalizeFirstLetter() -> String {
        guard let firstLetter = self.first else {
            return self
        }
        
        let restOfString = String(self.dropFirst())
        return String(firstLetter).uppercased() + restOfString.lowercased()
    }
    
    func containsNoNumbers() -> Bool {
        let numberCharacterSet = CharacterSet.decimalDigits
        return self.rangeOfCharacter(from: numberCharacterSet) == nil
    }
    
    var qrCodeData: Data? {
        let filter = CIFilter.qrCodeGenerator()
        guard let data = self.data(using: .ascii, allowLossyConversion: false) else { return nil }
        filter.message = data
        guard let ciimage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciimage.transformed(by: transform)
        let uiimage = UIImage(ciImage: scaledCIImage)
        return uiimage.pngData()!
    }
    
    var barcodeData: Data? {
        let filter = CIFilter(name: "CICode128BarcodeGenerator")!
        
        // Convert the string to data
        guard let data = self.data(using: .ascii, allowLossyConversion: false) else { return nil }
        
        // Set the input message
        filter.setValue(data, forKey: "inputMessage")
        
        // Set the output image size
        let outputImage = filter.outputImage!
        let transform = CGAffineTransform(scaleX: 3.0, y: 3.0) // Adjust scale as needed
        let scaledImage = outputImage.transformed(by: transform)
        
        // Convert to UIImage and then to PNG data
        let uiImage = UIImage(ciImage: scaledImage)
        return uiImage.pngData()
    }
    
    func qrCodeDataWithLogo(assetName:String = "app_icon") -> Data? {
        guard let logoImage = UIImage(named: assetName) else {
            return nil
        }
        
        // Generate the QR code
        let filter = CIFilter.qrCodeGenerator()
        guard let data = self.data(using: .ascii, allowLossyConversion: false) else {
            return nil
        }
        filter.message = data
        guard let qrCIImage = filter.outputImage else {
            return nil
        }
        
        let scaleFactor: CGFloat = 20 // Adjust this value as needed
        let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        qrCIImage.transformed(by: transform)
        let qrCodeSize = qrCIImage.extent.size
        let logoSize = CGSize(width: qrCodeSize.width / 3, height: qrCodeSize.height / 3) // Adjust the size as needed
        
        // Scale the logo image to the desired size
        let scaledLogoImage = logoImage.resize(targetSize: logoSize)
        
        // Create a CGContext to composite the QR code and logo
        let context = CIContext()
        guard let qrCGImage = context.createCGImage(qrCIImage, from: qrCIImage.extent) else {
            return nil
        }
        
        UIGraphicsBeginImageContext(qrCodeSize)
        
        // Draw the QR code
        UIImage(cgImage: qrCGImage).draw(in: CGRect(origin: .zero, size: qrCodeSize))
        
        // Draw the logo in the center
        let originX = (qrCodeSize.width - logoSize.width) / 2
        let originY = (qrCodeSize.height - logoSize.height) / 2
        scaledLogoImage.draw(in: CGRect(origin: CGPoint(x: originX, y: originY), size: logoSize))
        
        let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return compositeImage?.pngData()
    }
    
    var qrCodeUIImage : UIImage? {
        if let data = qrCodeData {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    var barCodeUIImage : UIImage? {
        if let data = barcodeData {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    var toDouble: Double {
        return Double(self) ?? 0.0
    }
    
    var toInt: Int {
        return Int(self) ?? 0
    }
    
    
}

extension Binding where Value == String {
    init(fromOptional: Binding<String?>) {
        self.init {
            fromOptional.wrappedValue ?? ""
        } set : { newValue in
            fromOptional.wrappedValue = newValue
        }
    }
}

extension Binding where Value == Int {
    init(fromOptional: Binding<Int?>) {
        self.init {
            fromOptional.wrappedValue ?? 0
        } set : { newValue in
            fromOptional.wrappedValue = newValue
        }
    }
}



extension Binding where Value == Bool {
    init<T>(value: Binding<T?>) {
        self.init {
            value.wrappedValue != nil
        } set : { newValue in
            if !newValue {
                value.wrappedValue = nil
            }
        }
    }
    
    init(fromOptional: Binding<Bool?>, defaultValue:Bool) {
        self.init {
            fromOptional.wrappedValue ?? defaultValue
        } set : { newValue in
            fromOptional.wrappedValue = newValue
        }
    }
    
    
    init<T>(items: Binding<[T]>, currentItem: T) where T: Equatable {
        self.init(
            get: { items.wrappedValue.contains(currentItem) },
            set: { newValue in
                if newValue {
                    if !items.wrappedValue.contains(currentItem) {
                        items.wrappedValue.append(currentItem)
                    }
                } else {
                    items.wrappedValue.removeAll { $0 == currentItem }
                }
            }
        )
    }
}

extension Array where Element: Equatable {
    func uniqueElements() -> [Element] {
        var uniqueElements = [Element]()
        
        for element in self {
            if !uniqueElements.contains(element) {
                uniqueElements.append(element)
            }
        }
        
        return uniqueElements
    }
}


// Function to resize a UIImage
extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
}

extension NSAttributedString {
    var attributedString2Html: String? {
        do {
            let htmlData = try self.data(from: NSRange(location: 0, length: self.length), documentAttributes:[.documentType: NSAttributedString.DocumentType.html]);
            return String.init(data: htmlData, encoding: String.Encoding.utf8)
        } catch {
            print("error:", error)
            return nil
        }
    }
}

extension Dictionary where Value: Equatable {
    func areEqual(to otherDictionary: [Key: Value]) -> Bool {
        // Check if both dictionaries have the same keys
        guard Set(self.keys) == Set(otherDictionary.keys) else {
            return false
        }
        
        // Check if the values for each corresponding key are equal
        for key in self.keys {
            guard let selfValue = self[key] , let otherValue = otherDictionary[key] else {
                return false
            }
            
            // Check if the arrays have the same elements
            if selfValue != otherValue {
                return false
            }
        }
        
        // If all keys and values are equal, return true
        return true
    }
}


extension Array where Element == VariantsDetails {
    func getVarientFromOption(_ option:[String:String]) -> VariantsDetails? {
        for item in self {
            if item.options.areEqual(to: option) {
                return item
            }
        }
        
        return nil
    }
    
    func totalQuantity() -> Int {
        var total = 0
        for item in self {
            total += item.quantity
        }
        
        return total
    }
    
    func getCost() -> Double {
        var total = 0.0
        for item in self {
            total += item.quantity.double() * item.cost
        }
        
        return total
    }
    
    func totalSold() -> Int {
        var total = 0
        for item in self {
            total += item.sold ?? 0
        }
        
        return total
    }
}

extension Array where Element == [String: [String]] {
    func mapVariantDetails(q:Int, cost:Double, price:Double) -> [VariantsDetails] {
        if self.isEmpty {
            return []
        }
        
        var details = [VariantsDetails]()
        let variants = self
        // Generate all possible combinations of options
        func generateCombinations(variantOptions: [[String: [String]]], currentOptionIndex: Int, currentOptions: [String: String]) {
            if currentOptionIndex == variantOptions.count {
                details.append(VariantsDetails(options: currentOptions, quantity: q, sold: 0, image: "", cost: cost, price: price))
                return
            }
            
            let currentOption = variantOptions[currentOptionIndex]
            for (optionKey, optionValues) in currentOption {
                for value in optionValues {
                    var updatedOptions = currentOptions
                    updatedOptions[optionKey] = value
                    generateCombinations(variantOptions: variantOptions, currentOptionIndex: currentOptionIndex + 1, currentOptions: updatedOptions)
                }
            }
        }
        
        generateCombinations(variantOptions: variants, currentOptionIndex: 0, currentOptions: [:])
        
        return details
    }
}
extension Array where Element == PhotosPickerItem {
    func getUIImages() async throws -> [UIImage] {
        var items: [UIImage] = []
        
        for image in self {
            if let uiImage = try? await image.getImage() {
                items.append(uiImage)
            }
        }
        
        return items
    }
    
    func addToListPhotos(list: [ImagePickerWithUrL]) async throws -> [ImagePickerWithUrL] {
        var listPhotos = list
        let uiImages = try await self.getUIImages()
        
        // Create a set for image comparison
        var existingImagesSet = Set<UIImage>(listPhotos.compactMap { $0.image })
        
        // Add new images and remove changed images
        for image in uiImages {
            if !existingImagesSet.contains(image) {
                listPhotos.append(ImagePickerWithUrL(image: image, link: nil, index: listPhotos.count))
                existingImagesSet.insert(image) // Update the set
            }
        }
        
        // Remove images that are no longer present
        listPhotos.removeAll { item in
            guard let itemImage = item.image else { return false }
            return !uiImages.contains(itemImage)
        }
        
        return listPhotos
    }
}

extension PhotosPickerItem {
    func getImage() async throws -> UIImage?{
        let data = try await self.loadTransferable(type: Data.self)
        guard let data = data, let image = UIImage(data: data) else{
            return nil
        }
        return image
    }
    
    func getPath() async  -> String {
        if let id = try? await self.getURL(item: self) {
            print("Path \(id)")
            return id.path()
        }
        
        print("Couldn't get id")
        return ""
    }
    
    func getURL(item: PhotosPickerItem) async throws -> URL? {
        // Step 1: Load as Data object.
        let data = try await item.loadTransferable(type: Data.self)
        
        if let contentType = item.supportedContentTypes.first {
            // Step 2: make the URL file name and get a file extension.
            let url = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")")
            
            if let data = data {
                do {
                    try data.write(to: url)
                    return url
                } catch {
                    throw error
                }
            }
            
        }
        
        return nil
    }
    
    /// from: https://www.hackingwithswift.com/books/ios-swiftui/writing-data-to-the-documents-directory
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
}

extension Array where Element == String {
    func convertImageUrlsToItems() -> [ImagePickerWithUrL] {
        let items = self.filter { !$0.isBlank }
        return items.map { link in
            ImagePickerWithUrL(image: nil, link: link, index: 0)
        }
    }
}



extension Array where Element == ImagePickerWithUrL {
    func getItemsToUpload() -> [ImagePickerWithUrL] {
        var images = [ImagePickerWithUrL]()
        for items in self {
            if items.image != nil {
                images.append(items)
            }
        }
        return images
    }
    
    func mapUrlsToLinks(urls : [String]) -> [ImagePickerWithUrL] {
        var listPhotos = self
        let uploadedItems = listPhotos.getItemsToUpload()
        for photoIndex in listPhotos.indices {
            let photo = listPhotos[photoIndex]
            
            for uiImageIndex in uploadedItems.indices {
                let uiImage = uploadedItems[uiImageIndex]
                if photo.id == uiImage.id {
                    listPhotos[photoIndex].image = nil
                    listPhotos[photoIndex].link = urls[uiImageIndex]
                }
            }
        }
        
        return listPhotos
    }
    
    func getLinks() -> [String] {
        var allLinks = [String]()
        
        for item in self {
            if let link = item.link, !link.isBlank, item.image == nil {
                allLinks.append(link)
            }
        }
        
        return allLinks
    }
}


extension String {
    enum TrimmingOptions {
           case all
           case leading
           case trailing
           case leadingAndTrailing
       }
       
       func trimming(spaces: TrimmingOptions, using characterSet: CharacterSet = .whitespacesAndNewlines) ->  String {
           switch spaces {
           case .all: return trimmingAllSpaces(using: characterSet)
           case .leading: return trimingLeadingSpaces(using: characterSet)
           case .trailing: return trimingTrailingSpaces(using: characterSet)
           case .leadingAndTrailing:  return trimmingLeadingAndTrailingSpaces(using: characterSet)
           }
       }
       
       private func trimingLeadingSpaces(using characterSet: CharacterSet) -> String {
           guard let index = firstIndex(where: { !CharacterSet(charactersIn: String($0)).isSubset(of: characterSet) }) else {
               return self
           }

           return String(self[index...])
       }
       
       private func trimingTrailingSpaces(using characterSet: CharacterSet) -> String {
           guard let index = lastIndex(where: { !CharacterSet(charactersIn: String($0)).isSubset(of: characterSet) }) else {
               return self
           }

           return String(self[...index])
       }
       
       private func trimmingLeadingAndTrailingSpaces(using characterSet: CharacterSet) -> String {
           return trimmingCharacters(in: characterSet)
       }
       
       private func trimmingAllSpaces(using characterSet: CharacterSet) -> String {
           return components(separatedBy: characterSet).joined()
       }
}
