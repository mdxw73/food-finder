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
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a UIHostingController with the SwiftUI view
        let contentView = ContentView().environmentObject(PurchaseManager())
        let swiftUIHostingController = UIHostingController(rootView: contentView)
        
        // Embed the UIHostingController's view in the current view controller
        addChild(swiftUIHostingController)
        view.addSubview(swiftUIHostingController.view)
        swiftUIHostingController.view.frame = view.bounds
        swiftUIHostingController.didMove(toParent: self)
    }
}

@MainActor
class PurchaseManager: ObservableObject {

    private let productIds = ["com.zackobied.palatevision.allaccess"]

    @Published
    private(set) var products: [Product] = []
    @Published
    private(set) var purchasedProductIDs = Set<String>()

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
        self.products = try await Product.products(for: productIds)
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

    var body: some View {
        VStack(spacing: 20) {
            if purchaseManager.hasUnlockedAccess {
                Text("Thank you for subscribing!")
            } else {
                Text("Subscriptions")
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
                        Text("\(product.displayPrice) - \(product.displayName)")
                            .foregroundColor(.white)
                            .padding()
                            .background(.blue)
                            .clipShape(Capsule())
                    }
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
                    Text("Restore Purchases")
                }
            }
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
}
