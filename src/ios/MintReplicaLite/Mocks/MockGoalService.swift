// Foundation v5.5+
import Foundation
// Combine v2.0+
import Combine

// Relative imports
import "../Models/Goal"
import "../Core/Utilities/MockDataGenerator"

// MARK: - Human Tasks
/*
 1. Verify mock delay times with UX team for realistic simulation
 2. Add error simulation scenarios for testing error handling
 3. Consider adding network condition simulation (poor connectivity, etc.)
 4. Add persistence for mock data between app launches if needed
*/

/// Mock service class that provides simulated goal-related operations
/// Addresses requirements:
/// - Financial Goal Setting (Technical Specification/1.1 System Overview/Core Features)
/// - Preview Content (Technical Specification/Constraints/3. Generate Only UI and ViewModel)
@MainActor
final class MockGoalService {
    // MARK: - Properties
    
    /// Collection of mock goals
    private var goals: [Goal]
    
    /// Publisher for broadcasting goal updates
    let goalUpdates: PassthroughSubject<Goal, Never>
    
    // MARK: - Initialization
    
    init() {
        self.goals = []
        self.goalUpdates = PassthroughSubject<Goal, Never>()
        
        // Generate initial set of mock goals
        do {
            let mockGoals = try MockDataGenerator.generateMockGoals(count: 5)
            self.goals = mockGoals
        } catch {
            print("Failed to generate initial mock goals: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetches all goals with simulated network delay
    /// - Returns: Publisher that emits the list of goals
    func fetchGoals() -> AnyPublisher<[Goal], Error> {
        Just(goals)
            .delay(for: .seconds(Double.random(in: 0.5...1.5)), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    /// Creates a new goal with the specified parameters
    /// - Parameters:
    ///   - name: Name of the goal
    ///   - description: Detailed description
    ///   - targetAmount: Target amount to achieve
    ///   - targetDate: Target date for completion
    ///   - category: Goal category
    /// - Returns: Publisher that emits the created goal
    func createGoal(
        name: String,
        description: String,
        targetAmount: Double,
        targetDate: Date,
        category: GoalCategory
    ) -> AnyPublisher<Goal, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockServiceError.serviceNotAvailable))
                return
            }
            
            do {
                let newGoal = try Goal(
                    id: UUID().uuidString,
                    name: name,
                    description: description,
                    targetAmount: targetAmount,
                    currentAmount: 0,
                    targetDate: targetDate,
                    category: category
                )
                
                self.goals.append(newGoal)
                self.goalUpdates.send(newGoal)
                promise(.success(newGoal))
            } catch {
                promise(.failure(error))
            }
        }
        .delay(for: .seconds(Double.random(in: 0.5...1.0)), scheduler: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    /// Updates the progress of a specific goal
    /// - Parameters:
    ///   - goalId: Unique identifier of the goal
    ///   - newAmount: New progress amount
    /// - Returns: Publisher that emits the updated goal
    func updateGoalProgress(goalId: String, newAmount: Double) -> AnyPublisher<Goal, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockServiceError.serviceNotAvailable))
                return
            }
            
            guard let goalIndex = self.goals.firstIndex(where: { $0.id == goalId }) else {
                promise(.failure(MockServiceError.goalNotFound))
                return
            }
            
            do {
                try self.goals[goalIndex].updateProgress(newAmount)
                let updatedGoal = self.goals[goalIndex]
                self.goalUpdates.send(updatedGoal)
                promise(.success(updatedGoal))
            } catch {
                promise(.failure(error))
            }
        }
        .delay(for: .seconds(Double.random(in: 0.3...0.8)), scheduler: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    /// Deletes a goal with the specified ID
    /// - Parameter goalId: Unique identifier of the goal to delete
    /// - Returns: Publisher that emits when deletion is complete
    func deleteGoal(goalId: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockServiceError.serviceNotAvailable))
                return
            }
            
            guard let goalIndex = self.goals.firstIndex(where: { $0.id == goalId }) else {
                promise(.failure(MockServiceError.goalNotFound))
                return
            }
            
            let deletedGoal = self.goals.remove(at: goalIndex)
            self.goalUpdates.send(deletedGoal)
            promise(.success(()))
        }
        .delay(for: .seconds(Double.random(in: 0.3...0.8)), scheduler: RunLoop.main)
        .eraseToAnyPublisher()
    }
}

// MARK: - Error Handling

/// Errors specific to the mock service
private enum MockServiceError: LocalizedError {
    case serviceNotAvailable
    case goalNotFound
    
    var errorDescription: String? {
        switch self {
        case .serviceNotAvailable:
            return "Mock service is not available"
        case .goalNotFound:
            return "Goal not found"
        }
    }
}