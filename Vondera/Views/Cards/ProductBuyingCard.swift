//
//  ProductCard.swift
//  Vondera
//
//  Created by Shreif El Sayed on 22/06/2023.
//

import SwiftUI
import NetworkImage

struct ProductBuyingCard: View {
    var product:Product
    var action:(() -> ())
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            NetworkImage(url: URL(string: product.defualtPhoto() )) { image in
                image.centerCropped()
            } placeholder: {
                ZStack(alignment: .center) {
                    Color.gray
                    
                    ProgressView()
                }
                
            } fallback: {
                Color.gray
            }
            .background(Color.white)
            .shadow(radius: 15)
            .cornerRadius(15)
            .frame(height: 240)
            
            Spacer().frame(height: 16)
            
            Text(product.name.uppercased())
                .font(.title3)
                .lineLimit(1)
                .bold()
            
            Text(product.categoryName)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(.secondary)
            
            Text("\(Int(product.price)) LE")
                .font(.title2)
                .multilineTextAlignment(.center)
                .bold()
           
            ButtonLarge(label: "Add to Cart") {
                action()
            }
            
        }
        .padding()
        .background(colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.03))
        .cornerRadius(15)
        
    }
}

struct ProductBuyingCard_Previews: PreviewProvider {
    static var previews: some View {
        ProductBuyingCard(product: Product.example()) {
            
        }
    }
}
