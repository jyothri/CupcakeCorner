//
//  ContentView.swift
//  CupcakeCorner
//
//  Created by Jyothrilinga Kurapati on 4/18/20.
//  Copyright © 2020 Jyothrilinga Kurapati. All rights reserved.
//

import SwiftUI

class Order: ObservableObject, Codable, CustomStringConvertible {
    enum CodingKeys: CodingKey {
        case type, quantity, extraFrosting, addSprinkles
        case name, streetAddress, city, zipcode
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(Int.self, forKey: .type)
        quantity = try container.decode(Int.self, forKey: .quantity)
        addSprinkles = try container.decode(Bool.self, forKey: .addSprinkles)
        extraFrosting = try container.decode(Bool.self, forKey: .extraFrosting)

        name = try container.decode(String.self, forKey: .name)
        streetAddress = try container.decode(String.self, forKey: .streetAddress)
        city = try container.decode(String.self, forKey: .city)
        zipcode = try container.decode(String.self, forKey: .zipcode)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(extraFrosting, forKey: .extraFrosting)
        try container.encode(addSprinkles, forKey: .addSprinkles)
        
        try container.encode(name, forKey: .name)
        try container.encode(streetAddress, forKey: .streetAddress)
        try container.encode(city, forKey: .city)
        try container.encode(zipcode, forKey: .zipcode)
    }

    init() {
    }
    
    static let types = ["Vanilla", "Strawberry", "Chocolate", "Rainbow"]
    
    @Published var type = 0
    @Published var quantity = 3
    @Published var extraFrosting = false
    @Published var addSprinkles = false
    @Published var specialRequests = false
    
    @Published var name = ""
    @Published var streetAddress = ""
    @Published var city = ""
    @Published var zipcode = ""
    
    var isValid: Bool {
        if name.isEmpty || streetAddress.isEmpty || city.isEmpty || zipcode.isEmpty {
            return false
        }
        return true
    }
    
    public var description: String { return "Order: Type:\(type), Qty: \(quantity), frosting? \(extraFrosting), sprinkles? \(addSprinkles), name: \(name), streetAddress: \(streetAddress), city: \(city), zip: \(zipcode)" }
}

struct ContentView: View {
    
    @ObservedObject var order = Order()
    @State var confirmationMessage = ""
    @State var showConfirmtion = false
    
    var body: some View {
        NavigationView {
            Form {
                
                Section {
                    Picker(selection: $order.type, label: Text("Select cupcake type")) {
                        ForEach(0 ..< Order.types.count) {
                            Text(Order.types[$0]).tag(($0))
                        }
                    }
                    
                    Stepper(value: $order.quantity, in: 3...20)
                    {   Text("Number of cupcakes \(order.quantity)")   }
                }
                
                Section {
                    Toggle(isOn: $order.specialRequests) {
                        Text("Any special requests?")
                    }
                    
                    if order.specialRequests {
                        Toggle(isOn: $order.extraFrosting) {
                            Text("Add extra frosting")
                        }
                        
                        Toggle(isOn: $order.addSprinkles) {
                            Text("Add Sprinkles")
                        }
                    }
                    
                }
                
                Section {
                    TextField("Name", text: $order.name)
                    TextField("Street Address", text: $order.streetAddress)
                    TextField("City", text: $order.city)
                    TextField("Zip code", text: $order.zipcode)
                }
                
                Section {
                    Button(action: {
                        self.placeOrder()
                    }) {
                        Text("Place order")
                    }
                }.disabled(!order.isValid)

            }.navigationBarTitle(Text("Cupcake Corner"))
                .alert(isPresented: $showConfirmtion) {
                        Alert(title: Text("Order placed"), message: Text(confirmationMessage), dismissButton: .default(Text("OK")))
            }
//            .actionSheet(isPresented: $showConfirmtion) {
//                ActionSheet(title: Text(confirmationMessage), buttons: [.default(Text("OK"))])
//            }
        }
    }
    
    func placeOrder() ->  Void {
        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted
        
        guard let encodedOrder = try? encoder.encode(order) else {
            print("Failed to encode order.")
            return
        }
        printJsonDebugMessage(for: encodedOrder, jsonField: "Encoded Message")
        let url = URL(string: "https://reqres.in/api/cupcakes")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedOrder
        
        URLSession.shared.dataTask(with: request) {
            guard let data = $0 else {
                print("No data in response: \($2?.localizedDescription ?? "Unknown error").")
                return
            }
            self.printJsonDebugMessage(for: data, jsonField: "Decoded Message")
            if let decodedOrder = try? JSONDecoder().decode(Order.self, from: data) {
                print(decodedOrder)
                self.confirmationMessage = "Your order for \(decodedOrder.quantity) cupcakes is own its way."
                self.showConfirmtion = true
            } else {
                let dataString = String(decoding: data, as: UTF8.self)
                self.confirmationMessage = "Invalid response \(dataString)"
                self.showConfirmtion = true
            }
        }.resume()
        
    }
    
    func printJsonDebugMessage(for jsonMessage: Data, jsonField: String) -> Void {
        let jsonString = String(data: jsonMessage, encoding: .utf8)
        print("\(jsonField): \(String(describing: jsonString))  DONE.")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
