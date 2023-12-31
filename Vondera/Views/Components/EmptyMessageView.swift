//
//  EmptyMessageView.swift
//  Vondera
//
//  Created by Shreif El Sayed on 22/06/2023.
//

import SwiftUI

struct SearchEmptyView : View {
    var searchText:String
    
    var body: some View {
        EmptyMessageView(systemName: "magnifyingglass", msg: searchText.isBlank ? "Start typing to search" : "No result for your search \(searchText)")
    }
}

struct EmptyMessageView: View {
    var systemName:String = "bag.badge.minus"
    var msg:LocalizedStringKey = "No Orders are added by you"
    var onClick :(() -> ())?
    
    var body: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView(msg, systemImage: systemName)
                .onTapGesture {
                    if onClick != nil {
                        onClick!()
                    }
                }
        } else {
            VStack(alignment: .center) {
                Spacer()
                VStack(alignment: .center) {
                    Image(systemName: systemName)
                        .resizable()
                        .frame(width: 100, height: 100)
                    
                    Spacer().frame(height: 40)
                    
                    HStack {
                        Text(msg)
                            .lineLimit(4)
                            .multilineTextAlignment(.center)
                            .bold()
                    }
                    
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .opacity(0.3)
            .onTapGesture {
                if onClick != nil {
                    onClick!()
                }
            }
        }
        
        
    }
}

struct EmptyMessageView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyMessageView()
    }
}
