//
//  OrderDetails.swift
//  Vondera
//
//  Created by Shreif El Sayed on 20/06/2023.
//

import SwiftUI
import MapKit
import AlertToast
import StepProgressView

struct OrderDetails: View {
    @Binding var order:Order
    
    @State var isLoading = false
    @State var comment = ""
    
    @State var myUser = UserInformation.shared.user
    
    @State private var snapshotImage: UIImage?
    @State private var delete = false
    
    // COURIER SHEET
    @State var courier:Courier?
    @State var assignDialog = false

    // CONTACT CLIENT
    @State var contactSheet = false
    
    // CONTACT INFO
    @State var contactUser:UserData?
    @State private var sheetHeight: CGFloat = .zero
    @State var msg:String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK : ORDER HEADER
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            if order.marketPlaceId != nil && !order.marketPlaceId!.isBlank {
                                MarketHeaderCard(marketId: order.marketPlaceId!, withText: false)
                            }
                            
                            Text("Order Details")
                                .font(.title3)
                                .bold()
                            
                            Spacer()
                            
                            Text("#\(order.id)")
                                .bold()
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        Divider()
                        
                        HStack(alignment: .center) {
                            Text("Order Statue")
                                .font(.title3)
                                .bold()
                            
                            Spacer()
                            
                            Text("\(order.statue)")
                                .bold()
                        }
                    }
                    
                    
                    StepsView(currentStep: .constant(order.getCurrentStep()), steps:  ["Added", "Confirmed", "Ready", "Shipped", "Finished"])
                        .stepShape(.circle)
                        .lastStepShape(.downTriangle)
                        .futureStepFillColor(.yellow)
                        .currentStepFillColor(UIColor(Color.accentColor))
                        .pastStepFillColor(UIColor(Color.accentColor))
                        
                    // MARK : SHIPPING OPTIONS
                    if (order.requireDelivery ?? true) {
                        VStack(alignment: .leading) {
                            Text("Shipping Info")
                                .font(.title2)
                                .bold()
                            
                            Spacer().frame(height: 8)
                            
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(order.name)
                                    Text("\(order.gov), \(order.address)")
                                    Text(order.gov)
                                    Text(order.phone)
                                }
                                
                                Spacer()
                                
                                if let image = snapshotImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .cornerRadius(12)
                                        .frame(width: 140, height: 100)
                                        .onTapGesture {
                                            openLocation()
                                        }
                                }
                                
                            }
                            .font(.body)
                            .foregroundColor(.secondary)
                            
                            Spacer().frame(height: 4)
                            
                            if !(order.notes?.isBlank ?? true) {
                                Text(order.notes ?? "")
                                    .foregroundStyle(.red)
                                    .bold()
                            }
                        }
                    }
                    
                    
                    // MARK : CONTACT BUTTON
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.accentColor)
                        
                        Text("Contact Customer")
                    }
                    .onTapGesture {
                        contactSheet.toggle()
                    }
                    
                    
                    // MARK : ORDER SUMMERY
                    VStack(alignment: .leading) {
                        Text("Order Summery")
                            .font(.title2)
                            .bold()
                        
                        Spacer().frame(height: 8)
                        
                        HStack {
                            Text("Products Price")
                            Spacer()
                            Text("+\(order.totalPrice) LE")
                        }
                        
                        if (order.requireDelivery ?? true) {
                            
                            HStack {
                                Text("Shipping Fees")
                                Spacer()
                                Text("+\(order.clientShippingFees) LE")
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        if order.discount ?? 0 > 0 {
                            HStack {
                                Text("Discount")
                                Spacer()
                                Text("-\(order.discount ?? 0) LE")
                                    .foregroundColor(.red)
                            }
                            
                            
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("COD")
                            Spacer()
                            Text("\(order.COD) LE")
                                .foregroundColor(.green)
                        }
                        
                    }
                    .bold()
                    
                    
                    //MARK : ORDER PRODUCTS
                    VStack (alignment: .leading){
                        Text("Products Details")
                            .font(.title2)
                            .bold()
                        
                        Spacer().frame(height: 8)
                        
                        ForEach(order.listProducts!, id: \.productId) { product in
                            ProductOrderCard(orderProduct: product)
                        }
                    }
                    
                    // MARK : Updates View
                    if order.listUpdates != nil {
                        VStack (alignment: .leading){
                            Text("Updates")
                                .font(.title2)
                                .bold()
                            
                            Spacer().frame(height: 8)
                            
                            ForEach(order.listUpdates!.reversed(), id: \.self) { update in
                                UpdateCard(update: update)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(allowsFullSwipe: false){
                                        Button {
                                            Task {
                                                let result = try await UsersDao().getUser(uId: update.uId)
                                                if result.exists {
                                                    contactUser = result.item
                                                }
                                            }
                                            
                                        } label: {
                                            Image(systemName: "message.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                    .buttonStyle(.plain)
                            }
                            
                            
                            // MARK : Add New Comment
                            HStack {
                                FloatingTextField(title: "Add Comment", text: $comment, required: nil)
                                    .padding(4)
                                
                                Button {
                                    withAnimation {
                                        addComment()
                                    }
                                } label: {
                                    Image(systemName: "paperplane")
                                        .font(.title3)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .cornerRadius(10)
                            
                            
                            
                        }
                        
                        
                        Spacer().frame(height: 20)
                    }
                }
            }
            
            // MARK : BUTTONS
            if let myUser = myUser {
                buttons.background(Color.background)
            }
        }
        .padding()
        .refreshable {
            await getOrderData()
        }
        .onAppear {
            generateMapSnapshot(latLang: order.latLang)
        }
        .overlay(alignment: .center) {
            if isLoading {
                ProgressView()
            }
        }
        .confirmationDialog("Are you sure you want to delete the order ?", isPresented: $delete, titleVisibility: .visible, actions: {
            Button("Delete", role: .destructive) {
                deleteOrder()
            }
            
            Button("Later", role: .cancel) {
            }
        })
        .sheet(isPresented: $contactSheet, content: {
            ContactDialog(phone: order.phone , toggle: $contactSheet)
                .fixedInnerHeight($sheetHeight)
        })
        .sheet(isPresented: $assignDialog) {
            CourierPicker(storeId: order.storeId ?? "", selectedOption: $courier)
        }
        .sheet(item: $contactUser, content: { user in
            ContactDialog(phone: user.phone, toggle: Binding(value: $contactUser))
                .fixedInnerHeight($sheetHeight)
        })
        .toast(isPresenting: Binding(value: $msg)){
            AlertToast(displayMode: .banner(.slide),
                       type: .regular,
                       title: msg)
        }
        .onChange(of: courier) { newValue in
            if let option = newValue {
                assign(option)
            }
        }
        .navigationTitle("#\(order.id)")
    }
    
    func getOrderData() async {
        do {
            let orderData = try await OrdersDao(storeId: order.storeId ?? "").getOrder(id: order.id)
            DispatchQueue.main.async {
                if !orderData.exists {
                    self.showTosat("Order doesn't exist")
                    return
                }
                self.order = orderData.item
            }
        } catch {
            showTosat(error.localizedDescription)
        }
    }
    
    func confirm() {
        Task {
            let order = await OrderManager().confirmOrder(order:&order)
            DispatchQueue.main.async { [order] in
                self.order = order
                self.showTosat("Order Confirmed")
            }
        }
    }
    
    func assign(_ courier:Courier) {
        Task {
            let order = await OrderManager().outForDelivery(order: &order, courier: courier)
            DispatchQueue.main.async { [order] in
                self.order = order
                self.showTosat("Order Is with courier")
            }
        }
    }
    
    func ready() {
        Task {
            let order = await OrderManager().assambleOrder(order:&order)
            DispatchQueue.main.async { [order] in
                self.order = order
                self.showTosat("Order Is ready for Shipping")
            }
        }
    }
    
    func deliver() {
        Task {
            let order  = await OrderManager().orderDelivered(order:&order)
            DispatchQueue.main.async { [order] in
                self.order = order
                self.showTosat("Order is Delivered")
            }
        }
    }
    
    func reset() {
        Task {
            self.order = await OrderManager().resetOrder(order:&order)
            self.showTosat("Order has been reset")
        }
    }
    
    func deleteOrder() {
        Task {
            let order = await OrderManager().orderDelete(order:&order).result
            DispatchQueue.main.async { [order] in
                self.order = order
                self.showTosat("Order deleted")
            }
        }
    }
    
    func failed() {
        Task {
            
            let order = await OrderManager().orderFailed(order:&order)
            DispatchQueue.main.async { [order] in
                self.order = order
                self.showTosat("Order Failed")
            }
        }
    }
    
    func addComment() {
        Task {
            
            let order = await OrderManager().addComment(order: &order, msg: comment, code: 0)
            DispatchQueue.main.async { [order] in
                self.order = order
                self.comment = ""
                showTosat("Comment added")
            }
        }
    }
        
    func showTosat(_ msg: String) {
        DispatchQueue.main.async {
            self.msg = msg
        }
    }
    
    var buttons: some View {
        VStack (alignment: .leading, spacing: 6){
            HStack(spacing: 6) {
                if showConfirm {
                    ButtonLarge(label: "Confirm") {
                        confirm()
                    }
                }
                
                if showAssembleButton {
                    ButtonLarge(label: "Ready to ship") {
                        ready()
                    }
                }
                
                if showAssign {
                    ButtonLarge(label: "Assign to Courier") {
                        assignDialog.toggle()
                    }
                }
            }
            
            HStack(spacing: 6) {
                if showDeliverButton {
                    ButtonLarge(label: "Delivered", background: .green) {
                        deliver()
                    }
                }
                
                #warning("Active this")
                /*if showFailed {
                    ButtonLarge(label: "Return Order", background: .gray) {
                        failed()
                    }
                }*/
                
            }
            
            HStack(spacing: 6) {
                if showResetButton {
                    ButtonLarge(label: "Reset Order", background: .red) {
                        reset()
                    }
                }
                
                if showDelete {
                    ButtonLarge(label: "Delete Order", background: .red) {
                        self.delete.toggle()
                    }
                }
                
            }
        }
    }
    
    var showAssign:Bool {myUser!.accountType == "Marketing" ? false : order.statue == "Assembled"}
    
    var showConfirm:Bool { order.statue == "Pending" }
    
    var showAssembleButton: Bool { myUser!.accountType == "Marketing" ? false : order.statue == "Confirmed" }
    
    var showDeliverButton: Bool { myUser!.accountType == "Marketing" ? false : order.statue == "Assembled" || order.statue == "Out For Delivery" }
    
    var showFailed: Bool { myUser!.accountType == "Marketing" ? false : (order.requireDelivery ?? true) && order.statue == "Out For Delivery" }
    
    var showResetButton:Bool {
        if order.statue == "Pending" { return false }
        
        if myUser!.accountType == "Owner" || myUser!.accountType == "Store Admin" {
            return true
        }
        
        if (myUser?.store?.canWorkersReset ?? false) && myUser!.accountType == "Worker" {
            return true
        }
        
        return false
    }
    
    var showDelete:Bool {
        return order.canDeleteOrder(accountType: myUser!.accountType)
    }
    
    func openLocation() {
        if let location = order.latLang  {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location, addressDictionary:nil))
            mapItem.name = "\(order.name) - #\(order.id)"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    func generateMapSnapshot(latLang: CLLocationCoordinate2D?) {
        if latLang == nil { return }
        
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: latLang!, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        options.size = CGSize(width: 140, height: 100) // Adjust the size as needed
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            if let snapshotImage = snapshot?.image {
                self.snapshotImage = snapshotImage
            }
        }
    }
}
