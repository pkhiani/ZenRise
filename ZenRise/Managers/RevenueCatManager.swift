//
//  RevenueCatManager.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import Foundation
import SwiftUI
import RevenueCat

class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var isSubscribed = false
    @Published var currentOffering: Offering?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = AppConfig.RevenueCat.apiKey
    
    override init() {
        super.init()
        setupRevenueCat()
    }
    
    private func setupRevenueCat() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        
        // Set up delegate to handle subscription updates
        Purchases.shared.delegate = self
        
        // Check current subscription status
        checkSubscriptionStatus()
    }
    
    func checkSubscriptionStatus() {
        isLoading = true
        
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to check subscription: \(error.localizedDescription)"
                    print("❌ RevenueCat error: \(error)")
                    return
                }
                
                // Check if user has active subscription
                self?.isSubscribed = customerInfo?.entitlements[AppConfig.RevenueCat.premiumEntitlement]?.isActive == true
                print("✅ Subscription status: \(self?.isSubscribed ?? false)")
            }
        }
    }
    
    func checkSubscriptionStatus() async {
        isLoading = true
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.isLoading = false
                self.isSubscribed = customerInfo.entitlements[AppConfig.RevenueCat.premiumEntitlement]?.isActive == true
                print("✅ Async subscription status: \(self.isSubscribed)")
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to check subscription: \(error.localizedDescription)"
                print("❌ Async RevenueCat error: \(error)")
            }
        }
    }
    
    func fetchOfferings() async {
        isLoading = true
        
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.currentOffering = offerings.current
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch offerings: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Failed to fetch offerings: \(error)")
            }
        }
    }
    
    func purchaseWeeklySubscription() async -> Bool {
        guard let weeklyPackage = getWeeklyPackageFromOfferings() else {
            await MainActor.run {
                self.errorMessage = "Weekly subscription not available"
            }
            return false
        }
        
        print("🛒 Starting purchase for package: \(weeklyPackage.storeProduct.productIdentifier)")
        isLoading = true
        
        do {
            let result = try await Purchases.shared.purchase(package: weeklyPackage)
            
            print("✅ Purchase completed successfully")
            print("📊 Customer info entitlements: \(result.customerInfo.entitlements)")
            
            let isActive = result.customerInfo.entitlements[AppConfig.RevenueCat.premiumEntitlement]?.isActive == true
            print("🎯 Premium entitlement active: \(isActive)")
            
            await MainActor.run {
                self.isLoading = false
                self.isSubscribed = isActive
            }
            
            return isActive
        } catch {
            print("❌ Purchase failed: \(error)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            
            await MainActor.run {
                self.isLoading = false
                self.isSubscribed = customerInfo.entitlements[AppConfig.RevenueCat.premiumEntitlement]?.isActive == true
            }
            
            return customerInfo.entitlements[AppConfig.RevenueCat.premiumEntitlement]?.isActive == true
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func getWeeklyPackage() -> Package? {
        return currentOffering?.weekly
    }
    
    func getWeeklyPackageFromOfferings() -> Package? {
        guard let offering = currentOffering else { return nil }
        
        // Try to find weekly package by duration
        for package in offering.availablePackages {
            if package.packageType == .weekly {
                return package
            }
        }
        
        // Fallback: look for package with "weekly" in the identifier
        for package in offering.availablePackages {
            if package.storeProduct.productIdentifier.lowercased().contains("weekly") {
                return package
            }
        }
        
        return nil
    }
    
    func getWeeklyPrice() -> String? {
        guard let weeklyPackage = getWeeklyPackageFromOfferings() else { return nil }
        return weeklyPackage.storeProduct.localizedPriceString
    }
}

// MARK: - PurchasesDelegate
extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            self.isSubscribed = customerInfo.entitlements[AppConfig.RevenueCat.premiumEntitlement]?.isActive == true
        }
    }
}
