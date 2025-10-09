//
//  OnboardingFeaturesView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct OnboardingFeaturesView: View {
    @Binding var currentStep: OnboardingStep
    @State private var currentFeatureIndex = 0
    
    private let features = [
        Feature(
            icon: "speaker.wave.2.fill",
            title: "Gentle Wake-Up Sounds",
            description: "Start your day with soothing, scientifically-selected alarm tones designed to wake you naturally.",
            details: ["Nature sounds", "Gentle wake-up tones", "Built-in alarm tones"]
        ),
        Feature(
            icon: "chart.line.uptrend.xyaxis",
            title: "Snooze Habit Tracking",
            description: "Monitor your snooze patterns and get insights to help break the habit while building healthier wake-up routines.",
            details: ["Pattern recognition", "Progress insights", "Habit coaching"]
        ),
        Feature(
            icon: "chart.bar.fill",
            title: "Progress Visualization",
            description: "Watch your transformation unfold with beautiful charts showing your journey from current to target wake time.",
            details: ["Visual progress", "Achievement milestones", "Success analytics"]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("Core Features")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Everything you need for better mornings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Feature Cards
            TabView(selection: $currentFeatureIndex) {
                ForEach(0..<features.count, id: \.self) { index in
                    FeatureCardView(feature: features[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 450)
            
            // Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(currentFeatureIndex == index ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentFeatureIndex == index ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentFeatureIndex)
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .science
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
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .subscription
                    }
                }) {
                    Text("Continue")
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

struct Feature {
    let icon: String
    let title: String
    let description: String
    let details: [String]
}

struct FeatureCardView: View {
    let feature: Feature
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.2),
                                Color.mint.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                // Feature Details
                VStack(spacing: 8) {
                    ForEach(feature.details, id: \.self) { detail in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text(detail)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingFeaturesView(currentStep: .constant(.features))
}
