//
//  OnboardingSubscriptionView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct OnboardingSubscriptionView: View {
    @Binding var currentStep: OnboardingStep
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isLoading = false
    
    private let plans = [
        SubscriptionPlan.monthly
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("Start Your Journey")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Try ZenRise free for 2 days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Benefits List
            VStack(spacing: 16) {
                SubscriptionBenefit(icon: "infinity", text: "Unlimited alarm adjustments")
                SubscriptionBenefit(icon: "waveform", text: "Full access to premium sounds")
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
                Text("2-day free trial, then \(selectedPlan.price)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Cancel anytime. No commitment required.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            
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
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
    }
    
    private func handleSubscription() async {
        isLoading = true
        
        // Simulate subscription process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            isLoading = false
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .setup
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
    
    static let monthly = SubscriptionPlan(
        id: "monthly",
        title: "Monthly",
        price: "$4.99/month",
        period: "Billed monthly",
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
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
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
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    OnboardingSubscriptionView(currentStep: .constant(.subscription))
}
