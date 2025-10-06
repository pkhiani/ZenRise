//
//  SleepReadinessTrackerView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct SleepReadinessTrackerView: View {
    @ObservedObject var quizManager: SleepReadinessQuizManager
    @Binding var showQuiz: Bool
    
    private var averageScore: Double {
        quizManager.getAverageScore()
    }
    
    
    private var mostCommonIssues: [QuizQuestionType] {
        quizManager.getMostCommonIssues()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with quick assessment button
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Readiness")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Track your pre-sleep preparation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showQuiz = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Quick Check")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            }
            
            // Current score card
            if let lastScore = quizManager.lastScore {
                CurrentScoreCard(score: lastScore)
            } else {
                EmptyStateCard {
                    showQuiz = true
                }
            }
            
            // Historical data
            if !quizManager.historicalScores.isEmpty {
                VStack(spacing: 20) {
                    // Average score
                    AverageScoreCard(averageScore: averageScore)
                    
                    // Common issues
                    if !mostCommonIssues.isEmpty {
                        CommonIssuesCard(issues: mostCommonIssues)
                    }
                    
                    // Recent scores list
                    RecentScoresCard(scores: Array(quizManager.historicalScores.suffix(5)))
                }
            }
        }
    }
}

struct CurrentScoreCard: View {
    let score: SleepReadinessScore
    
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
        VStack(spacing: 16) {
            HStack {
                Text("Latest Assessment")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(score.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: score.percentage)
                        .stroke(
                            LinearGradient(
                                colors: [scoreColor, scoreColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: score.percentage)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(score.percentage * 100))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                        
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(score.scoreCategory.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(score.scoreCategory.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    if !score.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Top Recommendations:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(score.recommendations.prefix(2).enumerated()), id: \.offset) { index, recommendation in
                                HStack(alignment: .top, spacing: 6) {
                                    Circle()
                                        .fill(scoreColor)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 2)
                                    
                                    Text(recommendation)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct EmptyStateCard: View {
    let onStartQuiz: () -> Void
    
    var body: some View {
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
                    
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.green)
                }
            
            VStack(spacing: 8) {
                Text("Start Your Sleep Journey")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Take a quick assessment to track your sleep readiness and get personalized recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onStartQuiz) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Start Assessment")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                .clipShape(Capsule())
                .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct AverageScoreCard: View {
    let averageScore: Double
    
    private var scoreCategory: SleepReadinessScore.ScoreCategory {
        switch averageScore {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        case 0.2..<0.4: return .poor
        default: return .veryPoor
        }
    }
    
    private var scoreColor: Color {
        switch scoreCategory.color {
        case "green": return .green
        case "mint": return .mint
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Average Score")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(scoreCategory.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(scoreColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scoreColor.opacity(0.1))
                    )
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(averageScore * 100))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                    
                    Text("out of 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Based on \(Int(averageScore * 100))% of assessments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}


struct CommonIssuesCard: View {
    let issues: [QuizQuestionType]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas for Improvement")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(Array(issues.prefix(3).enumerated()), id: \.offset) { index, issue in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: issue.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Focus on improving this area")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct RecentScoresCard: View {
    let scores: [SleepReadinessScore]
    
    private func scoreColor(for score: SleepReadinessScore) -> Color {
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Assessments")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(scores, id: \.id) { score in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(score.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(score.scoreCategory.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text("\(Int(score.percentage * 100))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(scoreColor(for: score))
                            
                            Circle()
                                .fill(scoreColor(for: score))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGroupedBackground))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    SleepReadinessTrackerView(
        quizManager: SleepReadinessQuizManager(),
        showQuiz: .constant(false)
    )
}
