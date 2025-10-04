//
//  OnboardingFlowView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case science = 1
    case features = 2
    case subscription = 3
    case setup = 4
}

struct OnboardingFlowView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep: OnboardingStep = .welcome
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGroupedBackground).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Onboarding Steps
            Group {
                switch currentStep {
                case .welcome:
                    OnboardingWelcomeView(currentStep: $currentStep)
                case .science:
                    OnboardingScienceView(currentStep: $currentStep)
                case .features:
                    OnboardingFeaturesView(currentStep: $currentStep)
                case .subscription:
                    OnboardingSubscriptionView(currentStep: $currentStep)
                case .setup:
                    OnboardingSetupView(
                        currentStep: $currentStep,
                        hasCompletedOnboarding: $hasCompletedOnboarding
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

#Preview {
    OnboardingFlowView(hasCompletedOnboarding: .constant(false))
        .environmentObject(UserSettingsManager())
        .environmentObject(NotificationManager())
}
