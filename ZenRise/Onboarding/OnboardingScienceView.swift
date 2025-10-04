//
//  OnboardingScienceView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct OnboardingScienceView: View {
    @Binding var currentStep: OnboardingStep
    @State private var currentCardIndex = 0
    
    private let scienceCards = [
        ScienceCard(
            icon: "clock.arrow.circlepath",
            title: "Gradual 15-Minute Shifts",
            description: "Research shows that gradual wake time adjustments of 15 minutes per day help your circadian rhythm adapt naturally without causing sleep disruption or morning fatigue.",
            detail: "Based on chronobiology studies from Stanford University"
        ),
        ScienceCard(
            icon: "brain.head.profile",
            title: "Sleep Cycle Alignment",
            description: "Our algorithm calculates optimal wake times based on your natural sleep cycles, helping you wake up during light sleep phases for a more refreshing morning.",
            detail: "Utilizes 90-minute sleep cycle science"
        ),
        ScienceCard(
            icon: "moon.zzz.fill",
            title: "Melatonin-Friendly Routines",
            description: "Gradual adjustments preserve your natural melatonin production, ensuring better sleep quality and easier morning transitions.",
            detail: "Supports healthy circadian rhythm maintenance"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("The Science Behind ZenRise")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Evidence-based approach to better mornings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Science Cards
            TabView(selection: $currentCardIndex) {
                ForEach(0..<scienceCards.count, id: \.self) { index in
                    ScienceCardView(card: scienceCards[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 400)
            
            // Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<scienceCards.count, id: \.self) { index in
                    Circle()
                        .fill(currentCardIndex == index ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentCardIndex == index ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentCardIndex)
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .welcome
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
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .features
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

struct ScienceCard {
    let icon: String
    let title: String
    let description: String
    let detail: String
}

struct ScienceCardView: View {
    let card: ScienceCard
    
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
                
                Image(systemName: card.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                Text(card.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(card.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                
                Text(card.detail)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingScienceView(currentStep: .constant(.science))
}
