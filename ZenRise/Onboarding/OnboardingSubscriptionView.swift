//
//  OnboardingSubscriptionView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct OnboardingSubscriptionView: View {
    @Binding var currentStep: OnboardingStep
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @State private var selectedPlan: SubscriptionPlan = .weekly
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let plans = [
        SubscriptionPlan.weekly
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("Start Your Journey")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Try ZenRise free for \(AppConfig.RevenueCat.freeTrialDays) days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Benefits List
            VStack(spacing: 20) {
                SubscriptionBenefit(icon: "infinity", text: "Unlimited alarm adjustments")
                SubscriptionBenefit(icon: "chart.bar.fill", text: "Advanced progress tracking")
                SubscriptionBenefit(icon: "bell.badge", text: "Smart snooze insights")
                SubscriptionBenefit(icon: "moon.zzz.fill", text: "Sleep cycle optimization")
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Subscription Plans
            VStack(spacing: 16) {
                ForEach(plans, id: \.id) { plan in
                    SubscriptionPlanCard(
                        plan: plan,
                        isSelected: selectedPlan.id == plan.id
                    ) {
                        selectedPlan = plan
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Free Trial Notice
            VStack(spacing: 8) {
                Text("\(AppConfig.RevenueCat.freeTrialDays)-day free trial, then \(revenueCatManager.getWeeklyPrice() ?? selectedPlan.price)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Cancel anytime. No commitment required.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
            
            // Navigation Buttons
            VStack(spacing: 16) {
                Button(action: {
                    Task {
                        await handleSubscription()
                    }
                }) {
                    HStack {
                        if isLoading {
                            SwiftUI.ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Start Free Trial")
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
                .disabled(isLoading)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .features
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
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
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSubscription() async {
        print("🚀 Starting subscription process...")
        isLoading = true
        
        // Purchase weekly subscription through RevenueCat
        let success = await revenueCatManager.purchaseWeeklySubscription()
        print("📊 Purchase result: \(success)")
        
        // Wait a moment for subscription status to update
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        
        await MainActor.run {
            isLoading = false
            
            if success {
                // Force subscription status to true since purchase was successful
                revenueCatManager.isSubscribed = true
                print("🔧 Forcing subscription status to true after successful purchase")

                        // Check subscription status again
                revenueCatManager.checkSubscriptionStatus()
                print("📊 Final subscription status: \(revenueCatManager.isSubscribed)")
                
                // Only proceed if purchase was actually successful
                print("✅ Purchase successful, proceeding to next screen...")
                print("🔍 Current step before change: \(currentStep)")
                print("🔍 Setting step to: .setup")
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .setup
                }
                
                print("🔍 Current step after change: \(currentStep)")
            } else {
                // Purchase failed - show error or allow retry
                print("❌ Purchase failed - staying on subscription screen")
                print("💡 User needs to fix sandbox account authentication")
                
                showError = true
                errorMessage = "Purchase failed. Please check your sandbox account settings and try again."
            }
        }
    }
}

struct SubscriptionPlan {
    let id: String
    let title: String
    let price: String
    let period: String
    let savings: String?
    
    static let weekly = SubscriptionPlan(
        id: "weekly",
        title: "Weekly",
        price: "$1.99/week",
        period: "Billed weekly",
        savings: nil
    )
}

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green)
                                )
                        }
                    }
                    
                    Text(plan.price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(plan.period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSelected ? Color.green : Color(.systemGray4), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionBenefit: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    OnboardingSubscriptionView(currentStep: .constant(.subscription))
}
