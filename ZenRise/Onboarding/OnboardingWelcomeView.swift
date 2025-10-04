//
//  OnboardingWelcomeView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @Binding var currentStep: OnboardingStep
    @EnvironmentObject var settingsManager: UserSettingsManager
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 24) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.8),
                                    Color.mint.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    Text("Welcome to ZenRise")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Transform your mornings with science-backed gradual wake-up routines")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            // Benefits Preview
            VStack(spacing: 16) {
                BenefitRow(icon: "clock.badge.checkmark", text: "Gradual 15-minute shifts")
                BenefitRow(icon: "brain.head.profile", text: "Sleep cycle optimization")
                BenefitRow(icon: "moon.zzz.fill", text: "Melatonin-friendly routines")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            
            // Continue Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .science
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.semibold)
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
}

struct BenefitRow: View {
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
    OnboardingWelcomeView(currentStep: .constant(.welcome))
        .environmentObject(UserSettingsManager())
}
