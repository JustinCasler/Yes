//
//  BackgroundTaskManager.swift
//  Yes
//
//  Created by justin casler on 2/27/25.
//

import BackgroundTasks 
import WidgetKit

class BackgroundTaskManager { 
    static let shared = BackgroundTaskManager()
    
func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourApp.dailyRefresh", using: nil) { task in
        self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }
}

func scheduleDailyRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.yourApp.dailyRefresh")
    let now = Date()
    let calendar = Calendar.current
    if let nextMidnight = calendar.nextDate(after: now,
                                             matching: DateComponents(hour: 0, minute: 0, second: 0),
                                             matchingPolicy: .nextTime) {
        request.earliestBeginDate = nextMidnight
    }
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("Could not schedule daily refresh: \(error)")
    }
}

func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleDailyRefresh()
    updateDailyData {
        task.setTaskCompleted(success: true)
    }
}

func updateDailyData(completion: @escaping () -> Void) {
    // Instead of calling updatePhraseOnNewDay() on HomeViewModel,
    // we call the shared PhraseManager to update the data.
    PhraseManager.shared.updateDailyPhrase {
        completion()
    }
}
}
