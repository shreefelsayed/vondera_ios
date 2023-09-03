//
//  ReceiptPDF.swift
//  Vondera
//
//  Created by Shreif El Sayed on 02/08/2023.
//

import Foundation
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import PDFKit
import NetworkImage

@MainActor
class ReciptPDF {
    var orderList:[Order]
    var myUser:UserData?
    let a5PageSize = CGSize(width: 420.9, height: 595.2)

    init(orderList: [Order]) async {
        self.orderList = orderList
        let local = LocalInfo()
        self.myUser = await local.getLocalUser()
    }
    
    
    func generateAndOpenPDF() {
        let url = render()
        
        FileUtils().shareFile(url: url)
    }
    
    func render() -> URL {
        // 2: Save it to our documents directory
        let url = URL.documentsDirectory.appending(path: "receipt.pdf")
        let renderer = ImageRenderer(content: EmptyView())
        var box = CGRect(origin: .zero, size: a5PageSize)
        
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return url
            }
        
        for order in orderList {
            // 5: Update the content with the current order
            let updatedRenderer = ImageRenderer(content: PDFReceipt(order: order, myUser: myUser))
                
            // 6: Render the SwiftUI view data onto the page
            updatedRenderer.render { size, context in
                // 6: Start a new PDF page
                pdf.beginPDFPage(nil)
                
                // 7: Render the SwiftUI view data onto the page
                context(pdf)
                
                // 8: End the page and close the file
                pdf.endPDFPage()
            }
        }
        
        // 7: Close the PDF file
        pdf.closePDF()
        print("Pdf Created")
        
        print("Location \(url.absoluteString)")
        return url
    }
}

struct PDFViewerUsingUrl: UIViewRepresentable {
    let pdfURL: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let pdfDocument = PDFDocument(url: pdfURL) {
            pdfView.document = pdfDocument
        } else {
            print("Error: Unable to open PDF.")
        }
    }
}

struct Rceipts:View {
    var orders:[Order]
    var myUser: UserData?
    
    var body: some View {
        VStack(alignment: .center) {
            ForEach(orders) { order in
                PDFReceipt(order: order, myUser: myUser)
            }
        }
        .frame(maxWidth: .infinity) // Set the VStack width to the maximum available width
    }
}

struct PDFReceipt: View {
    var order:Order
    var myUser:UserData?
    let a5PageSize = CGSize(width: 595.2, height: 420.9)

    
    var body: some View {
        VStack(alignment: .center) {
            // HEADER
            HStack (alignment: .center){
                // ORDER ID
                Text("#\(order.id)")
                    .font(.body)
                    .bold()
                
                Spacer()
                
                HStack(alignment: .center) {
                    // MARK : Store Logo
                    NetworkImage(url: URL(string: myUser?.store!.logo ?? "" )) { image in
                        image.centerCropped()
                    } placeholder: {
                        ProgressView()
                    } fallback: {
                        Image("defaultPhoto")
                            .resizable()
                            .centerCropped()
                    }
                    .background(Color.white)
                    .frame(width: 40, height: 40, alignment: .bottomTrailing)
                    .clipShape(Circle())
                    
                    VStack(alignment: .center) {
                        Text(myUser?.store?.name ?? "")
                            .font(.title3)
                            .bold()
                        
                        Text(myUser?.store?.slogan ?? "")
                            .font(.caption)
                    }
                    .padding(.horizontal, 20)
                }
                
                
                
                Spacer()
                
                // QR CODE
                Image(uiImage: UIImage(data: generateQR(text: order.id)!))
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            
            // Client INFO
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name : \(order.name) - Phone Number : \(order.phone)")
                    
                    Text("Address : \(order.gov) - \(order.address)")
                        
                }
                
                Spacer()
            }
            .font(.caption)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            
            
            // ITEMS
            TableView(order: order)
                .padding(.vertical, 6)
            
            // Message
            VStack(alignment: .center) {
                Text(myUser?.store?.customMessage)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            
            Spacer()
        }
        .frame(width: 400, height: 560)
        .padding()
        
    }
    
    struct TableView: View {
        let order: Order

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Table header
                HStack(alignment: .center) {
                    Text("Product")
                    Spacer()
                    Text("Varient")
                    Spacer()
                    Text("Quantity")
                    Spacer()
                    Text("Total")
                }
                .padding(.horizontal)
                .background(Color.gray.opacity(0.3))
                
                // Table rows
                ForEach(order.listProducts!, id: \.self) { product in
                    HStack(alignment: .center) {
                        Text(product.name)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                        
                        Text(product.getVarientsString())
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                        
                        
                        Text("\(product.quantity) x \(Int(product.price))")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                        
                        Text("\(Int(Double(product.quantity) * product.price)) EGP")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 2)

                    Divider()
                }
                
                VStack (alignment: .leading, spacing: 0) {
                    // Shipping Fees
                    HStack(alignment: .center) {
                        Text("Shipping Fees")
                            .font(.caption)
                            .bold()
                            .frame(maxWidth: .infinity)
                        
                        Text("-")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                        
                        
                        Text("-")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                        
                        Text("+ \(order.clientShippingFees) EGP")
                            .font(.caption)
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 2)
                    Divider()
                    
                    // DISCOUNT
                    if(order.discount ?? 0 > 0) {
                        HStack(alignment: .center) {
                            Text("Discount")
                                .font(.caption)
                                .bold()
                                .frame(maxWidth: .infinity)
                            
                            Text("-")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                            
                            
                            Text("-")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                            
                            Text("- \(order.discount ?? 0) EGP")
                                .font(.caption)
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 2)
                        Divider()
                    }
                    
                    // DEPOSIT
                    if(order.deposit != nil && order.deposit! > 0) {
                        HStack(alignment: .center) {
                            Text("Deposit")
                                .font(.caption)
                                .bold()
                                .frame(maxWidth: .infinity)
                            
                            Text("-")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                            
                            
                            Text("-")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                            
                            Text("- \(Int(order.deposit!)) EGP")
                                .font(.caption)
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 2)
                        Divider()
                    }
                    
                    // COD
                    HStack(alignment: .center) {
                        Text("COD")
                            .font(.caption)
                            .bold()
                            .frame(maxWidth: .infinity)
                        
                        Text("-")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                        
                        
                        Text("-")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                        
                        Text("\(order.amountToGet) EGP")
                            .font(.caption)
                            .underline(true, color: .blue)
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 2)
                }
                
            }
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
        }
        
    }
    
    
    
    func generateQR(text: String) -> Data? {
        let filter = CIFilter.qrCodeGenerator()
        guard let data = text.data(using: .ascii, allowLossyConversion: false) else { return nil }
        filter.message = data
        guard let ciimage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciimage.transformed(by: transform)
        let uiimage = UIImage(ciImage: scaledCIImage)
        return uiimage.pngData()!
    }
}