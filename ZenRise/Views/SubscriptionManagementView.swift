//
//  SubscriptionManagementView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI
import RevenueCat

struct SubscriptionManagementView: View {
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var showingRestoreAlert = false
    @State private var showingCancelAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Subscription")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Manage your ZenRise subscription")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Subscription Status
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: revenueCatManager.isSubscribed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(revenueCatManager.isSubscribed ? .green : .red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(revenueCatManager.isSubscribed ? "Active Subscription" : "No Active Subscription")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if revenueCatManager.isSubscribed {
                            Text("Weekly Plan - $1.99/week")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Subscribe to unlock premium features")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(revenueCatManager.isSubscribed ? Color.green : Color.red, lineWidth: 1)
                        )
                )
            }
            
            // Action Buttons
            VStack(spacing: 16) {
                if !revenueCatManager.isSubscribed {
                    Button(action: {
                        Task {
                            await handleSubscribe()
                        }
                    }) {
                        HStack {
                            if revenueCatManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Subscribe Now")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(revenueCatManager.isLoading)
                }
                
                Button(action: {
                    Task {
                        await handleRestore()
                    }
                }) {
                    Text("Restore Purchases")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .disabled(revenueCatManager.isLoading)
                
                if revenueCatManager.isSubscribed {
                    Button(action: {
                        showingCancelAlert = true
                    }) {
                        Text("Manage Subscription")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                }
            }
            
            // Error Message
            if let errorMessage = revenueCatManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGroupedBackground).opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .task {
            await revenueCatManager.fetchOfferings()
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore") {
                Task {
                    await handleRestore()
                }
            }
        } message: {
            Text("This will restore any previous purchases associated with your Apple ID.")
        }
        .alert("Manage Subscription", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings", role: .destructive) {
                openSubscriptionSettings()
            }
        } message: {
            Text("To cancel your subscription, you'll need to go to your Apple ID settings in the Settings app.")
        }
    }
    
    private func handleSubscribe() async {
        let success = await revenueCatManager.purchaseWeeklySubscription()
        if success {
            print("✅ Subscription successful")
        } else {
            print("❌ Subscription failed")
        }
    }
    
    private func handleRestore() async {
        let success = await revenueCatManager.restorePurchases()
        if success {
            print("✅ Purchases restored")
        } else {
            print("❌ Restore failed")
        }
    }
    
    private func openSubscriptionSettings() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SubscriptionManagementView()
}
