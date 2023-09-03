//
//  StoreOptions.swift
//  Vondera
//
//  Created by Shreif El Sayed on 25/06/2023.
//

import SwiftUI
import AlertToast
import LoadingButton



struct StoreOptions: View {
    var store:Store
    @ObservedObject var viewModel:StoreOptionsViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(store: Store) {
        self.store = store
        self.viewModel = StoreOptionsViewModel(store: store)
    }
    
    var body: some View {
        Form {
            Section("Orders") {
                VStack(alignment: .leading) {
                    Toggle("Enable Ordering", isOn: $viewModel.ordering)
                    
                    Text("This is enabled by default, if you turn this off no one will be able to submit new orders")
                        .font(.caption)
                    
                }
                
                VStack(alignment: .leading) {
                    Toggle("Offline Orders", isOn: $viewModel.offline)
                    
                    Text("Enable this to optionlly not require address when sumbiting an order")
                        .font(.caption)
                    
                }
                
                VStack(alignment: .leading) {
                    Toggle("Employees can reset orders", isOn: $viewModel.reset)
                    
                    Text("Can your employees accounts reset orders to the intial state ?")
                        .font(.caption)
                    
                }
                
                Toggle("Accept Prepaid Orders", isOn: $viewModel.prepaid)

                Toggle("Enable Attachments", isOn: $viewModel.attachments)
                
            }
            
            Section("Receipts") {
                VStack (alignment: .leading) {
                    Toggle("Can't open package label", isOn: $viewModel.label)
                    
                    Text("Display a can't open this package label on the orders receipt")
                        .font(.caption)
                }
            }
            
            Section("Products") {
                VStack(alignment: .leading) {
                    Text("Low Stocks Indecator")
                    
                    HStack {
                        Text("Min Quantity")
                        
                        Spacer()
                        
                        TextField("Quantity", text: $viewModel.indec)
                            .roundedTextFieldStyle()
                            .frame(width: 60, height: 50)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Set up an indecator to track your low stocks")
                        .font(.caption)
                }
                
                VStack (alignment: .leading) {
                    Toggle("Product Editable Prices", isOn: $viewModel.editPrice)
                    
                    Text("Your employees can edit the product prices on the checkout proccess")
                        .font(.caption)
                }
                
                
            }
            
            Section("Others") {
                VStack (alignment: .leading) {
                    Toggle("Local Whatsapp", isOn: $viewModel.whatsapp)
                    
                    Text("Enable sending a WhatsApp message to your client from your phone, once the order is submitted")
                        .font(.caption)
                }
                
                VStack(alignment: .leading) {
                    Toggle("Live E-commerce website", isOn: $viewModel.website)
                        .disabled(!(viewModel.store.subscribedPlan?.website ?? false))

                    Text("If this feature is supported in your package, you can enable your website or disable it from here")
                        .font(.caption)
                }
                
                VStack (alignment: .leading) {
                    Toggle("Store Chatting", isOn: $viewModel.chat)
                    
                    Text("Enable a store chat, so you can chat with all the employees")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Store Options")
        .willProgress(saving: viewModel.isSaving)
        .onReceive(viewModel.viewDismissalModePublisher) { shouldDismiss in
            if shouldDismiss {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("Save")
                    .foregroundStyle(Color.accentColor)
                    .bold()
                    .onTapGesture {
                        save()
                    }
            }
        }
        .toast(isPresenting: $viewModel.showToast){
            AlertToast(displayMode: .banner(.slide),
                       type: .regular,
                       title: viewModel.msg)
        }
    }
    
    func save() {
        Task {
            await viewModel.save()
        }
    }
}

struct StoreOptions_Previews: PreviewProvider {
    static var previews: some View {
        StoreOptions(store: Store.example())
    }
}
