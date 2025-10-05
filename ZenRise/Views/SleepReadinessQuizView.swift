//
//  SleepReadinessQuizView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct SleepReadinessQuizView: View {
    @ObservedObject var quizManager: SleepReadinessQuizManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResults = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGroupedBackground).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if quizManager.isQuizActive {
                    QuizContentView(quizManager: quizManager)
                } else if showResults, let score = quizManager.lastScore {
                    QuizResultsView(score: score, quizManager: quizManager) {
                        dismiss()
                    }
                } else {
                    QuizWelcomeView(quizManager: quizManager)
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: quizManager.isQuizActive) { isActive in
            if !isActive && quizManager.lastScore != nil {
                showResults = true
            }
        }
    }
}

struct QuizWelcomeView: View {
    @ObservedObject var quizManager: SleepReadinessQuizManager
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon and title
            VStack(spacing: 20) {
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
                    
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    Text("Sleep Readiness Check")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("A quick 30-second assessment to optimize your sleep preparation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Features
            VStack(spacing: 16) {
                FeatureRow(icon: "heart.fill", text: "Mood & stress check", color: Color.green.opacity(0.1))
                FeatureRow(icon: "iphone", text: "Device usage tracking", color: Color.mint.opacity(0.1))
                FeatureRow(icon: "briefcase.fill", text: "Work-life balance", color: Color.green.opacity(0.1))
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Personalized insights", color: Color.mint.opacity(0.1))
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Start button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quizManager.startQuiz()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Start Assessment")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.2), value: quizManager.isQuizActive)
            
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.green)
            }
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct QuizContentView: View {
    @ObservedObject var quizManager: SleepReadinessQuizManager
    @State private var selectedAnswer: QuizAnswer?
    @State private var showNextButton = false
    
    private var currentQuestion: QuizQuestion? {
        guard quizManager.currentQuestionIndex < quizManager.currentQuiz.count else { return nil }
        return quizManager.currentQuiz[quizManager.currentQuestionIndex]
    }
    
    private var progress: Double {
        guard !quizManager.currentQuiz.isEmpty else { return 0 }
        return Double(quizManager.currentQuestionIndex + 1) / Double(quizManager.currentQuiz.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            quizManager.skipQuiz()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(quizManager.currentQuestionIndex + 1) of \(quizManager.currentQuiz.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Question content
            if let question = currentQuestion {
                VStack(spacing: 32) {
                    // Question icon and title
                    VStack(spacing: 20) {
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
                                .shadow(color: .green.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: question.type.icon)
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.green)
                        }
                        
                        Text(question.question)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Answer options
                    VStack(spacing: 12) {
                        ForEach(question.answers, id: \.id) { answer in
                            AnswerButton(
                                answer: answer,
                                isSelected: selectedAnswer?.id == answer.id
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedAnswer = answer
                                    showNextButton = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
            
            // Next button
            if showNextButton, let question = currentQuestion, let answer = selectedAnswer {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        quizManager.answerQuestion(answer, for: question)
                        selectedAnswer = nil
                        showNextButton = false
                    }
                }) {
                    HStack(spacing: 12) {
                        if quizManager.currentQuestionIndex == quizManager.currentQuiz.count - 1 {
                            Text("Complete")
                                .font(.headline)
                                .fontWeight(.semibold)
                        } else {
                            Text("Next")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

struct AnswerButton: View {
    let answer: QuizAnswer
    let isSelected: Bool
    let action: () -> Void
    
    private var answerColor: Color {
        switch answer.color {
        case "green": return .green
        case "mint": return .mint
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .green
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(answer.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [answerColor, answerColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.white, Color(.systemGroupedBackground)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.clear : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? answerColor.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct QuizResultsView: View {
    let score: SleepReadinessScore
    @ObservedObject var quizManager: SleepReadinessQuizManager
    let onDismiss: () -> Void
    
    private var scoreColor: Color {
        switch score.scoreCategory.color {
        case "green": return .green
        case "mint": return .mint
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .green
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Score header
                VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [scoreColor.opacity(0.2), scoreColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: scoreColor.opacity(0.2), radius: 20, x: 0, y: 10)
                            
                            VStack(spacing: 4) {
                                Text("\(Int(score.percentage * 100))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(scoreColor)
                                
                                Text("Score")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    
                    VStack(spacing: 12) {
                        Text(score.scoreCategory.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(score.scoreCategory.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Recommendations
                if !score.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personalized Recommendations")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ForEach(Array(score.recommendations.enumerated()), id: \.offset) { index, recommendation in
                                RecommendationRow(
                                    number: index + 1,
                                    text: recommendation,
                                    color: .green
                                )
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: onDismiss) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Continue")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            quizManager.startQuiz()
                        }
                    }) {
                        Text("Retake Assessment")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}

struct RecommendationRow: View {
    let number: Int
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}


#Preview {
    SleepReadinessQuizView(quizManager: SleepReadinessQuizManager())
}
