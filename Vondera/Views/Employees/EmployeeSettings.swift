//
//  EmployeeSettings.swift
//  Vondera
//
//  Created by Shreif El Sayed on 03/07/2023.
//

import SwiftUI
import AlertToast

struct EmployeeSettings: View {
    var id:String
    @ObservedObject var viewModel:EmployeeSettingsViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(id: String) {
        self.id = id
        self.viewModel = EmployeeSettingsViewModel(id: id)
    }
    
    var body: some View {
        List {
            Section("User Info") {
                FloatingTextField(title: "Name", text: $viewModel.name, caption: "The name of the emloyee you want to add", required: true, autoCapitalize: .words)
                
                
                FloatingTextField(title: "Phone Number", text: $viewModel.phone, caption: "Use the whatsapp number of the employee", required: true, keyboard: .phonePad)
            }
            
            Section("Access") {
                
                Picker("Account Type", selection: $viewModel.selectedAccountType) {
                    Text("Admin").tag(UserRoles.admin)
                    Text("Employee").tag(UserRoles.employee)
                    Text("Sales Account").tag(UserRoles.modrator)
                }
                .pickerStyle(.menu)
                
                Text(viewModel.selectedAccountType.getRoleDesc())
                    .font(.caption)
                
                if viewModel.selectedAccountType == .modrator {
                    HStack {
                        FloatingTextField(title: "Commission", text: .constant(""), caption: "This commission will be calculate from the order's netprofit From 1% to 99%", required: false, isNumric: true, number: $viewModel.perc)
                        
                        Text("%")
                    }
                }
            }
            
            Section("App Access") {
                Toggle("Account Active", isOn: $viewModel.active)
                    .isHidden(viewModel.myUser!.accountType != "Owner" && viewModel.myUser!.accountType != "Store Admin")
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Email address : \(viewModel.email)")
                            .bold()
                        
                        Text("Password : \(viewModel.pass)")
                            .bold()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "doc.on.clipboard")
                        .font(.callout)
                        .bold()
                        .onTapGesture {
                            CopyingData().copyToClipboard("Email : \(viewModel.email)\n Password: \(viewModel.pass)")
                        }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Member settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Update") {
                    update()
                }
                .disabled(viewModel.isLoading || viewModel.isSaving)
            }
        }
        .isHidden(viewModel.isLoading)
        .willProgress(saving: viewModel.isSaving)
        .willLoad(loading: viewModel.isLoading)
        .onReceive(viewModel.viewDismissalModePublisher) { shouldDismiss in
            if shouldDismiss {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .toast(isPresenting: Binding(value: $viewModel.msg)){
            AlertToast(displayMode: .banner(.slide),
                       type: .regular,
                       title: viewModel.msg?.toString())
        }
        .withAccessLevel(accessKey: .teamMembersUpdate, presentation: presentationMode)
    }
    
    func update() {
        Task {
            await viewModel.update()
        }
    }

}

struct EmployeeSettings_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeSettings(id: "")
    }
}
