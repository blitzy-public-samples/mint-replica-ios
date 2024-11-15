// External dependencies versions:
// Foundation: 5.5+
// Combine: 5.5+
// SwiftUI: 5.5+

import Foundation
import Combine
import SwiftUI

// Relative imports
import "../Core/Protocols/ViewModelProtocol"
import "../Models/Goal"
import "../Mocks/MockGoalService"

// MARK: - Human Tasks
/*
1. Review error handling strategy with team
2. Add analytics tracking for goal-related events
3. Implement unit tests for goal operations
4. Consider adding goal reminder notifications
*/

/// ViewModel that manages the presentation logic and state for financial goals
/// Requirements addressed:
/// - Financial Goal Setting (Technical Specification/1.1 System Overview/Core Features)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
/// - SwiftUI + Combine (Technical Specification/Constraints for the AI to Generate a New iOS App/1)
@MainActor
final class GoalViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var goals: [Goal] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - ViewModelProtocol Properties
    
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private Properties
    
    private let goalService: MockGoalService
    
    // MARK: - Initialization
    
    init(goalService: MockGoalService = MockGoalService()) {
        self.goalService = goalService
        setupSubscriptions()
        initialize()
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to goal updates from the service
        goalService.goalUpdates
            .receive(on: RunLoop.main)
            .sink { [weak self] updatedGoal in
                guard let self = self else { return }
                if let index = self.goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                    self.goals[index] = updatedGoal
                } else {
                    self.goals.append(updatedGoal)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - ViewModelProtocol Methods
    
    func initialize() {
        isLoading = true
        errorMessage = nil
        
        goalService.fetchGoals()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] fetchedGoals in
                    self?.goals = fetchedGoals
                }
            )
            .store(in: &cancellables)
    }
    
    func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        goals.removeAll()
        errorMessage = nil
        isLoading = false
    }
    
    // MARK: - Public Methods
    
    /// Creates a new financial goal
    /// - Parameters:
    ///   - name: Name of the goal
    ///   - description: Detailed description
    ///   - targetAmount: Target amount to achieve
    ///   - targetDate: Target date for completion
    ///   - category: Goal category
    /// - Returns: Publisher that emits the created goal or error
    func createGoal(
        name: String,
        description: String,
        targetAmount: Double,
        targetDate: Date,
        category: GoalCategory
    ) -> AnyPublisher<Goal, Error> {
        isLoading = true
        errorMessage = nil
        
        return goalService.createGoal(
            name: name,
            description: description,
            targetAmount: targetAmount,
            targetDate: targetDate,
            category: category
        )
        .receive(on: RunLoop.main)
        .handleEvents(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    /// Updates the progress of a specific goal
    /// - Parameters:
    ///   - goalId: Unique identifier of the goal
    ///   - newAmount: New progress amount
    /// - Returns: Publisher that emits the updated goal or error
    func updateGoalProgress(
        goalId: String,
        newAmount: Double
    ) -> AnyPublisher<Goal, Error> {
        isLoading = true
        errorMessage = nil
        
        return goalService.updateGoalProgress(
            goalId: goalId,
            newAmount: newAmount
        )
        .receive(on: RunLoop.main)
        .handleEvents(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    /// Deletes a specific goal
    /// - Parameter goalId: Unique identifier of the goal to delete
    /// - Returns: Publisher that emits completion or error
    func deleteGoal(goalId: String) -> AnyPublisher<Void, Error> {
        isLoading = true
        errorMessage = nil
        
        return goalService.deleteGoal(goalId: goalId)
            .receive(on: RunLoop.main)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}