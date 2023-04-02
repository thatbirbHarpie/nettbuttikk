import SwiftUI

struct Product: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let price: Double
}

struct User {
    let username: String
    let password: String
}

class UserStore: ObservableObject {
    @Published var currentUser: User?
    
    func login(username: String, password: String) {
        // Here you would write code to authenticate the user
        // For the purposes of this example, we'll just create a dummy user
        currentUser = User(username: username, password: password)
    }
    
    func logout() {
        currentUser = nil
    }
}

class CartStore: ObservableObject {
    @Published var cartItems = [Product]()
    
    func addToCart(_ product: Product) {
        cartItems.append(product)
    }
    
    func removeFromCart(_ product: Product) {
        if let index = cartItems.firstIndex(where: { $0.id == product.id }) {
            cartItems.remove(at: index)
        }
    }
}

struct ContentView: View {
    @State private var products = [Product]()
    @State private var selectedProduct: Product?
    
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var cartStore: CartStore
    
    var body: some View {
        NavigationView {
            List(products) { product in
                Button(action: {
                    selectedProduct = product
                }) {
                    VStack(alignment: .leading) {
                        Text(product.title)
                            .font(.headline)
                        Text(String(format: "$%.2f", product.price))
                            .font(.subheadline)
                    }
                }
            }
            .navigationBarTitle("")
            .navigationBarItems(trailing:
                HStack {
                    NavigationLink(destination: CartView()) {
                        Image(systemName: "cart")
                            .foregroundColor(.blue)
                    }
                    if userStore.currentUser != nil {
                        Button("Log out") {
                            userStore.logout()
                            cartStore.cartItems.removeAll()
                        }
                        .padding()
                    } else {
                        NavigationLink(destination: LoginView()) {
                            Text("Log in")
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                }
            )
        }
        .onAppear {
            fetchData()
        }
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(product: product)
        }
    }
    
    func fetchData() {
        guard let url = URL(string: "https://fakestoreapi.com/products") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let products = try JSONDecoder().decode([Product].self, from: data)
                    DispatchQueue.main.async {
                        self.products = products
                    }
                } catch {
                    print("Error decoding JSON: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

struct ProductDetailView: View {
    let product: Product
    
    @EnvironmentObject var cartStore: CartStore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(product.title)
                .font(.title)
            Text(String(format: "$%.2f", product.price))
                .font(.headline)
                .padding(.bottom)
            Text(product.description)
                .font(.body)
            Button(action: {
                cartStore.addToCart(product)
            }) {
                Text("Add to Cart")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}
struct CartView: View {
    @EnvironmentObject var cartStore: CartStore
    
    var body: some View {
        NavigationView {
            if cartStore.cartItems.count > 0 {
                List {
                    ForEach(cartStore.cartItems) { item in
                        HStack {
                            Text(item.title)
                            Spacer()
                            Text(String(format: "$%.2f", item.price))
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let item = cartStore.cartItems[index]
                            cartStore.removeFromCart(item)
                        }
                    }
                }
                .navigationBarTitle("Cart")
                .navigationBarItems(trailing: EditButton())
            } else {
                Text("Your cart is empty!")
                    .font(.title)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    
    @EnvironmentObject var userStore: UserStore
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Log in to your account")
                .font(.title)
                .bold()
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Log in") {
                userStore.login(username: username, password: password)
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
    }
}

@main
struct MyApp: App {
    @StateObject var userStore = UserStore()
    @StateObject var cartStore = CartStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userStore)
                .environmentObject(cartStore)
        }
    }
}
