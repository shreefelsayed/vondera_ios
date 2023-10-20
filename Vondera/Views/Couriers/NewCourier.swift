//
//  NewCourier.swift
//  Vondera
//
//  Created by Shreif El Sayed on 27/06/2023.
//

import SwiftUI
import AlertToast

struct NewCourier: View {
    var storeId:String
    @ObservedObject var viewModel:NewCourierViewModel
    @Binding var currentList:[Courier]
    @Environment(\.presentationMode) private var presentationMode
    
    init(storeId: String, currentList: Binding<[Courier]>) {
        self.storeId = storeId
        self._currentList = currentList
        self.viewModel = NewCourierViewModel(storeId: storeId)
    }
    
    var body: some View {
        List {
            Section("Courier Info") {
                
                FloatingTextField(title: "Courier Name", text: $viewModel.name, caption: "This is the courier company name", required: true, autoCapitalize: .words)
                
                FloatingTextField(title: "Courier Contact Phone", text: $viewModel.phone, caption: "This will help you contact the courier company easily", required: true, keyboard: .phonePad)
            }
            
            Section("Shipping Fees") {
                Text("Note that the courier shipping fees will be detected from your net proft, this is the price that the couriers get for his service for you")
                    .font(.body)
                
                
                ForEach($viewModel.items.indices, id: \.self) { index in
                    VStack {
                        HStack {
                            Text(viewModel.items[index].govName)
                            
                            Spacer()
                            
                            FloatingTextField(title: "Price", text: .constant(""), required: nil, isNumric: true, number: $viewModel.items[index].price)
                                .frame(width: 80)
                        }
                    }
                }
            }
        }
        .navigationTitle("New Courier")
        .onReceive(viewModel.viewDismissalModePublisher) { shouldDismiss in
            if shouldDismiss {
                if viewModel.newItem != nil {
                    currentList.append(viewModel.newItem!)
                }
                
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .toast(isPresenting: $viewModel.showToast){
            AlertToast(displayMode: .banner(.slide),
                       type: .regular,
                       title: viewModel.msg)
        }
        .willProgress(saving: viewModel.isSaving)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Create") {
                    Task {
                        await viewModel.save()
                    }
                }
            }
        }
    }
}
