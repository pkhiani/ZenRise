//
//  SleepReadinessQuiz.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import Foundation

// MARK: - Quiz Question Types
enum QuizQuestionType: String, CaseIterable, Codable {
    case mood = "mood"
    case deviceUse = "device_use"
    case workCutoff = "work_cutoff"
    case mealTiming = "meal_timing"
    case caffeine = "caffeine"
    case exercise = "exercise"
    case stress = "stress"
    case environment = "environment"
    
    var title: String {
        switch self {
        case .mood: return "How are you feeling?"
        case .deviceUse: return "Device usage before bed"
        case .workCutoff: return "Work stress management"
        case .mealTiming: return "Last meal timing"
        case .caffeine: return "Caffeine intake"
        case .exercise: return "Physical activity"
        case .stress: return "Stress levels"
        case .environment: return "Sleep environment"
        }
    }
    
    var icon: String {
        switch self {
        case .mood: return "heart.fill"
        case .deviceUse: return "iphone"
        case .workCutoff: return "briefcase.fill"
        case .mealTiming: return "fork.knife"
        case .caffeine: return "cup.and.saucer.fill"
        case .exercise: return "figure.walk"
        case .stress: return "brain.head.profile"
        case .environment: return "bed.double.fill"
        }
    }
}

// MARK: - Quiz Answer Options
struct QuizAnswer: Codable, Identifiable, Equatable {
    let id = UUID()
    let text: String
    let value: Int // 1-5 scale for scoring
    let color: String // Color name for UI
    
    static func == (lhs: QuizAnswer, rhs: QuizAnswer) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Quiz Question
struct QuizQuestion: Codable, Identifiable {
    let id = UUID()
    let type: QuizQuestionType
    let question: String
    let answers: [QuizAnswer]
    let isAdaptive: Bool // Whether this question adapts based on user history
    
    static func createDefaultQuestions() -> [QuizQuestion] {
        return [
            QuizQuestion(
                type: .mood,
                question: "How are you feeling right now?",
                answers: [
                    QuizAnswer(text: "😊 Great", value: 5, color: "green"),
                    QuizAnswer(text: "😌 Good", value: 4, color: "mint"),
                    QuizAnswer(text: "😐 Okay", value: 3, color: "yellow"),
                    QuizAnswer(text: "😔 Tired", value: 2, color: "orange"),
                    QuizAnswer(text: "😰 Stressed", value: 1, color: "red")
                ],
                isAdaptive: false
            ),
            QuizQuestion(
                type: .deviceUse,
                question: "How much time did you spend on devices in the last hour?",
                answers: [
                    QuizAnswer(text: "None", value: 5, color: "green"),
                    QuizAnswer(text: "Under 10 min", value: 4, color: "mint"),
                    QuizAnswer(text: "10-30 min", value: 3, color: "yellow"),
                    QuizAnswer(text: "30-45 min", value: 2, color: "orange"),
                    QuizAnswer(text: "Over 45 min", value: 1, color: "red")
                ],
                isAdaptive: false
            ),
            QuizQuestion(
                type: .workCutoff,
                question: "When did you stop working today?",
                answers: [
                    QuizAnswer(text: "Before 6 PM", value: 5, color: "green"),
                    QuizAnswer(text: "6-7 PM", value: 4, color: "mint"),
                    QuizAnswer(text: "7-8 PM", value: 3, color: "yellow"),
                    QuizAnswer(text: "8-9 PM", value: 2, color: "orange"),
                    QuizAnswer(text: "After 9 PM", value: 1, color: "red")
                ],
                isAdaptive: true
            ),
            QuizQuestion(
                type: .mealTiming,
                question: "When was your last meal?",
                answers: [
                    QuizAnswer(text: "3+ hours ago", value: 5, color: "green"),
                    QuizAnswer(text: "2-3 hours ago", value: 4, color: "mint"),
                    QuizAnswer(text: "1-2 hours ago", value: 3, color: "yellow"),
                    QuizAnswer(text: "30-60 min ago", value: 2, color: "orange"),
                    QuizAnswer(text: "Within 30 min", value: 1, color: "red")
                ],
                isAdaptive: false
            ),
            QuizQuestion(
                type: .caffeine,
                question: "Caffeine intake in the last 6 hours?",
                answers: [
                    QuizAnswer(text: "None", value: 5, color: "green"),
                    QuizAnswer(text: "1 cup", value: 4, color: "mint"),
                    QuizAnswer(text: "2 cups", value: 3, color: "yellow"),
                    QuizAnswer(text: "3 cups", value: 2, color: "orange"),
                    QuizAnswer(text: "4+ cups", value: 1, color: "red")
                ],
                isAdaptive: true
            ),
            QuizQuestion(
                type: .exercise,
                question: "Physical activity today?",
                answers: [
                    QuizAnswer(text: "Intense workout", value: 4, color: "green"),
                    QuizAnswer(text: "Moderate exercise", value: 5, color: "mint"),
                    QuizAnswer(text: "Light activity", value: 4, color: "yellow"),
                    QuizAnswer(text: "Minimal movement", value: 2, color: "orange"),
                    QuizAnswer(text: "No activity", value: 1, color: "red")
                ],
                isAdaptive: false
            ),
            QuizQuestion(
                type: .stress,
                question: "How stressed do you feel?",
                answers: [
                    QuizAnswer(text: "Very relaxed", value: 5, color: "green"),
                    QuizAnswer(text: "Mostly calm", value: 4, color: "mint"),
                    QuizAnswer(text: "Somewhat tense", value: 3, color: "yellow"),
                    QuizAnswer(text: "Quite stressed", value: 2, color: "orange"),
                    QuizAnswer(text: "Very stressed", value: 1, color: "red")
                ],
                isAdaptive: true
            ),
            QuizQuestion(
                type: .environment,
                question: "How is your sleep environment?",
                answers: [
                    QuizAnswer(text: "Perfect", value: 5, color: "green"),
                    QuizAnswer(text: "Good", value: 4, color: "mint"),
                    QuizAnswer(text: "Okay", value: 3, color: "yellow"),
                    QuizAnswer(text: "Not ideal", value: 2, color: "orange"),
                    QuizAnswer(text: "Poor", value: 1, color: "red")
                ],
                isAdaptive: false
            )
        ]
    }
}

// MARK: - Quiz Response
struct QuizResponse: Codable, Identifiable {
    let id = UUID()
    let questionId: UUID
    let questionType: QuizQuestionType
    let answerValue: Int
    let timestamp: Date
    
    init(questionId: UUID, questionType: QuizQuestionType, answerValue: Int) {
        self.questionId = questionId
        self.questionType = questionType
        self.answerValue = answerValue
        self.timestamp = Date()
    }
}

// MARK: - Sleep Readiness Score
struct SleepReadinessScore: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let totalScore: Int
    let maxScore: Int
    let responses: [QuizResponse]
    let recommendations: [String]
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(totalScore) / Double(maxScore)
    }
    
    var scoreCategory: ScoreCategory {
        switch percentage {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        case 0.2..<0.4: return .poor
        default: return .veryPoor
        }
    }
    
    enum ScoreCategory: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case veryPoor = "Very Poor"
        
        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "mint"
            case .fair: return "yellow"
            case .poor: return "orange"
            case .veryPoor: return "red"
            }
        }
        
        var description: String {
            switch self {
            case .excellent: return "Perfect sleep readiness! You're well-prepared for restful sleep."
            case .good: return "Good sleep readiness. A few small adjustments could help."
            case .fair: return "Fair sleep readiness. Consider some pre-sleep improvements."
            case .poor: return "Poor sleep readiness. Focus on better sleep habits."
            case .veryPoor: return "Very poor sleep readiness. Significant changes needed."
            }
        }
    }
}

// MARK: - Quiz Manager
class SleepReadinessQuizManager: ObservableObject {
    @Published var currentQuiz: [QuizQuestion] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var responses: [QuizResponse] = []
    @Published var isQuizActive: Bool = false
    @Published var lastScore: SleepReadinessScore?
    @Published var historicalScores: [SleepReadinessScore] = []
    
    private let userDefaults = UserDefaults.standard
    private let scoresKey = "SleepReadinessScores"
    private let responsesKey = "QuizResponses"
    
    init() {
        loadHistoricalData()
        generateAdaptiveQuiz()
    }
    
    // MARK: - Quiz Management
    
    func startQuiz() {
        generateAdaptiveQuiz()
        currentQuestionIndex = 0
        responses = []
        isQuizActive = true
    }
    
    func answerQuestion(_ answer: QuizAnswer, for question: QuizQuestion) {
        let response = QuizResponse(
            questionId: question.id,
            questionType: question.type,
            answerValue: answer.value
        )
        responses.append(response)
        
        if currentQuestionIndex < currentQuiz.count - 1 {
            currentQuestionIndex += 1
        } else {
            completeQuiz()
        }
    }
    
    func completeQuiz() {
        let score = calculateScore()
        lastScore = score
        historicalScores.append(score)
        isQuizActive = false
        
        saveHistoricalData()
    }
    
    func skipQuiz() {
        isQuizActive = false
    }
    
    // MARK: - Adaptive Quiz Generation
    
    private func generateAdaptiveQuiz() {
        var questions = QuizQuestion.createDefaultQuestions()
        
        // Adapt questions based on user history
        if let lastScore = historicalScores.last {
            questions = adaptQuestions(questions, basedOn: lastScore)
        }
        
        // Select 4-6 most relevant questions for quick completion
        let selectedQuestions = selectMostRelevantQuestions(questions)
        currentQuiz = selectedQuestions
    }
    
    private func adaptQuestions(_ questions: [QuizQuestion], basedOn lastScore: SleepReadinessScore) -> [QuizQuestion] {
        // Focus on areas where user scored poorly
        let poorAreas = lastScore.responses.filter { $0.answerValue <= 2 }.map { $0.questionType }
        
        return questions.map { question in
            if poorAreas.contains(question.type) {
                // Prioritize questions in areas where user needs improvement
                return question
            }
            return question
        }
    }
    
    private func selectMostRelevantQuestions(_ questions: [QuizQuestion]) -> [QuizQuestion] {
        // Always include core questions
        let coreTypes: [QuizQuestionType] = [.mood, .deviceUse, .mealTiming, .stress]
        let coreQuestions = questions.filter { coreTypes.contains($0.type) }
        
        // Add 1-2 additional questions based on user patterns
        let additionalQuestions = questions.filter { !coreTypes.contains($0.type) }
        let selectedAdditional = Array(additionalQuestions.prefix(2))
        
        return coreQuestions + selectedAdditional
    }
    
    // MARK: - Score Calculation
    
    private func calculateScore() -> SleepReadinessScore {
        let totalScore = responses.reduce(0) { $0 + $1.answerValue }
        let maxScore = responses.count * 5 // Assuming 5-point scale
        
        let recommendations = generateRecommendations()
        
        return SleepReadinessScore(
            date: Date(),
            totalScore: totalScore,
            maxScore: maxScore,
            responses: responses,
            recommendations: recommendations
        )
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        for response in responses {
            if response.answerValue <= 2 {
                switch response.questionType {
                case .mood:
                    recommendations.append("Try a 5-minute meditation or deep breathing exercise")
                case .deviceUse:
                    recommendations.append("Put devices away 1 hour before bed for better sleep")
                case .workCutoff:
                    recommendations.append("Set a firm work cutoff time to reduce stress")
                case .mealTiming:
                    recommendations.append("Avoid eating 2-3 hours before bedtime")
                case .caffeine:
                    recommendations.append("Limit caffeine intake after 2 PM")
                case .exercise:
                    recommendations.append("Light stretching or yoga can help prepare for sleep")
                case .stress:
                    recommendations.append("Try journaling or relaxation techniques")
                case .environment:
                    recommendations.append("Ensure your room is cool, dark, and quiet")
                }
            }
        }
        
        if recommendations.isEmpty {
            recommendations.append("Great job! Keep up these healthy sleep habits.")
        }
        
        return recommendations
    }
    
    // MARK: - Data Persistence
    
    private func saveHistoricalData() {
        if let encoded = try? JSONEncoder().encode(historicalScores) {
            userDefaults.set(encoded, forKey: scoresKey)
        }
    }
    
    private func loadHistoricalData() {
        if let data = userDefaults.data(forKey: scoresKey),
           let decoded = try? JSONDecoder().decode([SleepReadinessScore].self, from: data) {
            historicalScores = decoded
        }
    }
    
    // MARK: - Analytics
    
    func getAverageScore() -> Double {
        guard !historicalScores.isEmpty else { return 0 }
        let totalPercentage = historicalScores.reduce(0) { $0 + $1.percentage }
        return totalPercentage / Double(historicalScores.count)
    }
    
    func getScoreTrend() -> [Double] {
        let recentScores = Array(historicalScores.suffix(7))
        return recentScores.map { $0.percentage }
    }
    
    func getMostCommonIssues() -> [QuizQuestionType] {
        let recentResponses = historicalScores.flatMap { $0.responses }
        let issueCounts = Dictionary(grouping: recentResponses.filter { $0.answerValue <= 2 }) { $0.questionType }
            .mapValues { $0.count }
        
        return issueCounts.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        historicalScores.removeAll()
        lastScore = nil
        responses.removeAll()
        currentQuiz = []
        currentQuestionIndex = 0
        isQuizActive = false
        
        // Clear from UserDefaults
        userDefaults.removeObject(forKey: scoresKey)
        userDefaults.removeObject(forKey: responsesKey)
        
        // Regenerate default quiz
        generateAdaptiveQuiz()
    }
}
