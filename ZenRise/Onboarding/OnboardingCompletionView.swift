//
//  OnboardingCompletionView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct OnboardingCompletionView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var showCelebration = false
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Celebration Animation
            VStack(spacing: 32) {
                ZStack {
                    // Background circles for animation
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.3),
                                        Color.mint.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 120 + CGFloat(index * 20), height: 120 + CGFloat(index * 20))
                            .scaleEffect(showCelebration ? 1.2 : 0.8)
                            .opacity(showCelebration ? 0.0 : 0.6)
                            .animation(
                                .easeOut(duration: 1.5)
                                .delay(Double(index) * 0.2)
                                .repeatCount(2, autoreverses: false),
                                value: showCelebration
                            )
                    }
                    
                    // Main icon
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
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showCelebration ? 1.1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCelebration)
                }
                
                // Content
                VStack(spacing: 16) {
                    Text("Welcome to ZenRise!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: showContent)
                    
                    Text("Your personalized wake-up journey begins now")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.8).delay(0.5), value: showContent)
                }
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasCompletedOnboarding = true
                }
            }) {
                Text("Enter App")
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
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.8).delay(0.7), value: showContent)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCelebration = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showContent = true
            }
        }
    }
}

#Preview {
    OnboardingCompletionView(hasCompletedOnboarding: .constant(false))
}
