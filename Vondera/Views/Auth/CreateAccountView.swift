//
//  CreateAccountView.swift
//  Vondera
//
//  Created by Shreif El Sayed on 01/06/2023.
//

import SwiftUI
import AlertToast

struct CreateAccountView: View {
    
    
    @State var openCategory = false
    @State var openMarkets = false

    @StateObject var viewModel = CreateAccountViewModel()
    @Environment(\.presentationMode) private var presentationMode

    func nextScreen() {
        Task {
            await viewModel.showNextPage()
        }
    }
    
    var body: some View {
        ZStack(alignment: viewModel.isCreated ? .center : .bottomTrailing) {
            if viewModel.isCreated {
                LottieView(name: "cart_loading", loopMode: .autoReverse)
            } else {
                currentPage
                FloatingActionButton(symbolName: "arrow.forward", action: nextScreen)
                    .padding()
            }
        }
        .toast(isPresenting: Binding(value: $viewModel.errorMsg)){
            AlertToast(displayMode: .alert,
                type: .error(.red),
                title: viewModel.errorMsg)
        }
        .onReceive(viewModel.viewDismissalModePublisher) { shouldDismiss in
            if shouldDismiss {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .willProgress(saving: viewModel.isSaving)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if !viewModel.isSaving && !viewModel.isCreated {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showPrevPage()
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                }
            }
            
        }
        .sheet(isPresented: $openCategory) {
            PickCategory(sheetVisible: $openCategory, selected: $viewModel.selectedCateogry)
        }
        .sheet(isPresented: $openMarkets) {
            StoreMarketPlaces(selectedItems: $viewModel.selectedMarkets)
        }
        .navigationTitle("Create New Store")
    }
    
    //MARK : This decide which page to return
    var currentPage: some View {
        if viewModel.currentPage == 1 {
            return AnyView(page1)
        } else if viewModel.currentPage == 2 {
            return AnyView(page2)
        }
        // Add a default return value here
        return AnyView(EmptyView())
    }
    
    var page2: some View {
        Form {
            
            Section("Name & Slogan") {
                FloatingTextField(title: "Store Name", text: $viewModel.storeName, caption: "This is your store name, it will be printed on the receipts and in your website, it can be changed later", required: true, autoCapitalize: .words)
                
                FloatingTextField(title: "Slogan", text: $viewModel.slogan, caption: "Your store slogan, it will be shown on your receipts and in your website", required: false, autoCapitalize: .words)
                
                HStack {
                    Text("Category")
                    
                    Spacer()
                    
                    Text(CategoryManager().getCategoryById(id: viewModel.selectedCateogry ?? 0).nameEn)
                        .foregroundStyle(Color.accentColor)
                        .bold()
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }.onTapGesture {
                    openCategory.toggle()
                }
                
                VStack{
                    HStack {
                        Text("MarketPlaces")
                        
                        Spacer()
                        
                        Text("\($viewModel.selectedMarkets.count) Markets")
                            .foregroundStyle(Color.accentColor)
                            .bold()
                        
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }.onTapGesture {
                        openMarkets.toggle()
                    }
                    
                    Text("Those are the market places (Sales Channels) you sell on, select only where your brand sell")
                        .font(.caption)
                }
                
            }
            
            Section("Communication") {
                FloatingTextField(title: "Business phone number", text: $viewModel.bPhone, caption: "We will use this number to contact you for any inquaries", required: true, keyboard: .phonePad)
                
                Picker("Government", selection: $viewModel.gov) {
                    ForEach(GovsUtil().govs, id: \.self) { option in
                        Text(option)
                    }
                }
                
                FloatingTextField(title: "Address", text: $viewModel.address, caption: "We won't share your address, we collect it for analyze perpose", required: true, multiLine: true, autoCapitalize: .sentences)
                    

            }
           
            FloatingTextField(title: "Refer Code", text: $viewModel.refferCode, caption: "If one of Vondera team invited you, enter his refer code", required: false)

        }
        .lineLimit(1, reservesSpace: true)
    }
    
    var page1: some View {
        Form {
            Section("Personal Info") {
                FloatingTextField(title: "Name", text: $viewModel.name, caption: "Your personal legal name", required: true, autoCapitalize: .words)
                    

                FloatingTextField(title: "Phone Number", text: $viewModel.phone, caption: "This will not be visible anywere", required: true, autoCapitalize: .words)
            }
            
            Section("Login Credintals") {
                FloatingTextField(title: "Email Address", text: $viewModel.email, caption: "This is your main email address, note you can't change it later, you will use it to login to your store", required: true, keyboard: .emailAddress)
            
                
                FloatingTextField(title: "Password", text: $viewModel.password, caption: "Choose a strong password, it must be 6 chars at least", required: nil, secure: true)
            }
           
        }
        .lineLimit(1, reservesSpace: true)
        //.textFieldStyle(.roundedBorder)
    }
}

struct PickCategory: View {
    @Binding var sheetVisible:Bool
    @Binding var selected:Int?
    var body: some View {
        VStack {
            List(CategoryManager().getAll(), id: \.self) { category in
                StoreCategoryLinearCard(storeCategory: category, selected: $selected, onClicked: {
                    sheetVisible.toggle()
                })
            }
            .listStyle(.plain)
        }
        .navigationTitle("Choose your category")
    }
}
struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            CreateAccountView()
        }
    }
}
