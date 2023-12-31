//
//  CustomButton.swift
//  Vondera
//
//  Created by Shreif El Sayed on 18/06/2023.
//

import SwiftUI

struct ButtonLarge: View {
    
    var label: LocalizedStringKey
    var background: Color = .accentColor
    var textColor: Color = .white
    var action: (() -> ())
    
    let cornorRadius: CGFloat = 24
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(label)
                    .foregroundColor(textColor)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: cornorRadius)
                    .stroke(.gray.opacity(0.5), lineWidth: 1)
            )
        }
        .background(background)
        .cornerRadius(cornorRadius)
        .frame(height: 46)
    }
}

struct CustomButton: View {
    let label: LocalizedStringKey
    let action: () -> Void
    let foregroundColor: Color?

    init(label: LocalizedStringKey, action: @escaping () -> Void, foregroundColor: Color? = nil) {
        self.label = label
        self.action = action
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .padding()
                .foregroundColor(foregroundColor ?? Color.accentColor)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(8)
        }.frame(width: .infinity, height: 45)
    }
}
