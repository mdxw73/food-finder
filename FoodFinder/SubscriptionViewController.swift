//
//  SubscriptionViewController.swift
//  FoodFinder
//
//  Created by Zack Obied on 28/08/2023.
//

import UIKit
import SwiftUI
import StoreKit

class SubscriptionViewController: UIViewController {
    var swiftUIHostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a UIHostingController with the SwiftUI view
        let purchaseManager = PurchaseManager()
        purchaseManager.tabBarController = self.tabBarController!
        let contentView = ContentView().environmentObject(purchaseManager)
        swiftUIHostingController = UIHostingController(rootView: AnyView(contentView))

        if let hostingController = swiftUIHostingController {
            // Embed the UIHostingController's view in the current view controller
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.frame = view.bounds
            hostingController.didMove(toParent: self)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            // Update the frame of the embedded UIHostingController's view
            self?.swiftUIHostingController?.view.frame = CGRect(origin: CGPoint.zero, size: size)
        }, completion: nil)
    }
}

extension UIViewController {
    func checkSubscription() {
        Task.init {
            let purchaseManager = PurchaseManager()
            await purchaseManager.updatePurchasedProducts()
            do {
                try await purchaseManager.loadProducts()
            } catch {
                print(error)
            }
            if !purchaseManager.hasUnlockedAccess {
                tabBarController?.selectedIndex = 3
            }
        }
    }
}

// tutorial: www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift
@MainActor
class PurchaseManager: ObservableObject {

    private let productIDs = ["com.zackobied.PantryView.AllAccess"]
    weak var tabBarController: UITabBarController?

    @Published
    private(set) var products: [Product] = []
    @Published
    private(set) var purchasedProductIDs = Set<String>() {
        didSet {
            if hasUnlockedAccess {
                if let tabBarController = tabBarController {
                    for item in tabBarController.tabBar.items! {
                        item.isEnabled = true
                    }
                }
            }
        }
    }

    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil

    init() {
        self.updates = observeTransactionUpdates()
    }

    deinit {
        self.updates?.cancel()
    }

    var hasUnlockedAccess: Bool {
       return !self.purchasedProductIDs.isEmpty
    }

    func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        self.products = try await Product.products(for: productIDs)
        self.productsLoaded = true
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            // Successful purchase
            await transaction.finish()
            await self.updatePurchasedProducts()
        case let .success(.unverified(_, error)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            print("Error: \(error)")
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            break
        case .userCancelled:
            // ^^^
            break
        @unknown default:
            break
        }
    }

    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                // Using verificationResult directly would be better
                // but this way works for now
                await self.updatePurchasedProducts()
                
                switch verificationResult {
                case .verified(let transaction):
                    print("Transaction verified:")
                    print("Product ID: \(transaction.productID)")
                    if let revocationDate = transaction.revocationDate {
                        print("Revocation Date: \(revocationDate)")
                    }
                    if let expirationDate = transaction.expirationDate {
                        print("Expiration Date: \(expirationDate)")
                    }
                    print("Is Upgraded: \(transaction.isUpgraded)")
                case .unverified(_, let error):
                    print("Transaction unverified:")
                    print("Error: \(error)")
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject
    private var purchaseManager: PurchaseManager
    
    private func getCardWidth() -> CGFloat {
        var cardWidth = UIScreen.main.bounds.width * 0.9
        if UIScreen.main.bounds.width > 500 {
            cardWidth = CGFloat(500)
        }
        return cardWidth
    }

    var body: some View {
        let lineWidth: CGFloat = 2
        let gapWidth: CGFloat = 5
        let cardWidth = getCardWidth()
        VStack(spacing: 20) {
            if purchaseManager.hasUnlockedAccess {
                Text("Subscriptions")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.top, 20)
                ForEach(purchaseManager.products) { product in
                    VStack {
                        HStack {
                            Image("LaunchScreen")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .cornerRadius(10)
                                .padding(.top, 20)
                                .padding(.leading, 20)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .cornerRadius(10)
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                                .foregroundColor(Color(red: 0.0, green: 0.6, blue: 0.0))
                                .shadow(color: .gray, radius: 10, x: 0, y: 2)
                        }
                        Text("\(product.displayPrice) / Month - \(product.displayName)")
                            .frame(width: cardWidth * 0.8, alignment: .leading)
                            .foregroundColor(.black)
                            .padding(20)
                            .font(.headline)
                            
                        Divider().background(Color.black.opacity(0.2))
                        
                        Text("\(product.description)")
                            .frame(width: cardWidth * 0.8, alignment: .leading)
                            .foregroundColor(.black)
                            .padding(20)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(width: cardWidth * 0.9, alignment: .center)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.green, lineWidth: lineWidth)
                            .padding(lineWidth / 2)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.green, lineWidth: lineWidth)
                                    .padding(lineWidth / 2 + gapWidth)
                            )
                    )
                }
            } else {
                Text("Subscriptions")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.top, 20)
                ForEach(purchaseManager.products) { product in
                    Button {
                        _ = Task<Void, Never> {
                            do {
                                try await purchaseManager.purchase(product)
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        VStack {
                            HStack {
                                Image("LaunchScreen")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(10)
                                    .padding(.top, 20)
                                    .padding(.leading, 20)
                                
                                Spacer()
                            }
                            Text("\(product.displayPrice) / Month - \(product.displayName)")
                                .frame(width: cardWidth * 0.8, alignment: .leading)
                                .foregroundColor(.black)
                                .padding(20)
                                .font(.headline)
                            
                            Divider().background(Color.black.opacity(0.2))
                            
                            Text("\(product.description)")
                                .frame(width: cardWidth * 0.8, alignment: .leading)
                                .foregroundColor(.black)
                                .padding(20)
                                .font(.system(size: 14))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(width: cardWidth * 0.9, alignment: .center)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }

                Button {
                    _ = Task<Void, Never> {
                        do {
                            try await AppStore.sync()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Already subscribed? Sign in.")
                }
            }
            Spacer()
            
            VStack {
                Button {
                    openURL(URL(string: "https://pantryview.co.uk/#privacy")!)
                } label: {
                    Text("Privacy Policy")
                }
                .font(.system(size: 14))
                .padding(.bottom, 10)

                Button {
                    openURL(URL(string: "https://pantryview.co.uk/#terms")!)
                } label: {
                    Text("Terms of Use")
                }
                .font(.system(size: 14))
            }
            .padding(.bottom, 20)
        }.task {
            await purchaseManager.updatePurchasedProducts()
        }.task {
            _ = Task<Void, Never> {
                do {
                    try await purchaseManager.loadProducts()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func openURL(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Handle the case when the URL can't be opened
            print("Cannot open the URL: \(url)")
        }
    }
}
