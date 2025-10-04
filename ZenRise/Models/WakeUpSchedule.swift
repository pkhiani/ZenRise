import Foundation

struct WakeUpSchedule {
    let currentWakeUpTime: Date
    let targetWakeUpTime: Date
    let adjustmentMinutesPerDay: Int = 15
    
    var timeUntilTarget: (days: Int, nextWakeUp: Date) {
        let calendar = Calendar.current
        
        // Extract hours and minutes from both times
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentWakeUpTime)
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetWakeUpTime)
        
        // Convert both times to minutes since midnight
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        let targetMinutes = targetComponents.hour! * 60 + targetComponents.minute!
        
        // Calculate total minutes difference
        var minutesDifference = targetMinutes - currentMinutes
        if minutesDifference > 0 {
            minutesDifference = 24 * 60 - minutesDifference // Reverse the difference since we're waking earlier
        } else {
            minutesDifference = abs(minutesDifference)
        }
        
        // Calculate days needed
        let daysNeeded = Int(ceil(Double(minutesDifference) / Double(adjustmentMinutesPerDay)))
        
        // Calculate next wake up time
        let nextWakeUp = calculateNextWakeUpTime(currentMinutes: currentMinutes, daysNeeded: daysNeeded)
        
        return (daysNeeded, nextWakeUp)
    }
    
    private func calculateNextWakeUpTime(currentMinutes: Int, daysNeeded: Int) -> Date {
        let calendar = Calendar.current
        let minutesAdjustment = min(adjustmentMinutesPerDay, daysNeeded > 0 ? adjustmentMinutesPerDay : 0)
        let adjustedMinutes = (currentMinutes - minutesAdjustment + 24 * 60) % (24 * 60)
        
        let hour = adjustedMinutes / 60
        let minute = adjustedMinutes % 60
        
        // Create a proper date for tomorrow with the calculated time
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        
        var nextWakeUpComponents = DateComponents()
        nextWakeUpComponents.year = tomorrowComponents.year
        nextWakeUpComponents.month = tomorrowComponents.month
        nextWakeUpComponents.day = tomorrowComponents.day
        nextWakeUpComponents.hour = hour
        nextWakeUpComponents.minute = minute
        
        return calendar.date(from: nextWakeUpComponents) ?? currentWakeUpTime
    }
    
    func wakeUpTimeForDay(_ day: Int) -> Date {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentWakeUpTime)
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        
        let totalAdjustment = day * adjustmentMinutesPerDay
        let adjustedMinutes = (currentMinutes - totalAdjustment + 24 * 60) % (24 * 60)
        
        var components = DateComponents()
        components.hour = adjustedMinutes / 60
        components.minute = adjustedMinutes % 60
        
        return calendar.date(from: components) ?? currentWakeUpTime
    }
    
    var isTargetReached: Bool {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentWakeUpTime)
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetWakeUpTime)
        
        return currentComponents.hour == targetComponents.hour && 
               currentComponents.minute == targetComponents.minute
    }
}
