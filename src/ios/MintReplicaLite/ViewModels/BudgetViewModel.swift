// External dependencies versions:
// Foundation: iOS 14.0+
// Combine: iOS 14.0+
// SwiftUI: iOS 14.0+

import Foundation
import Combine
import SwiftUI

// Relative imports
import "../Core/Protocols/ViewModelProtocol"
import "../Models/Budget"
import "../Mocks/MockBudgetService"

// MARK: - Human Tasks
// 1. Verify error handling and user feedback mechanisms
// 2. Test memory management with long-running subscriptions
// 3. Validate budget update performance with large datasets
// 4. Review budget period calculations across time zones

/// ViewModel responsible for managing budget-related business logic and state
/// Addresses requirements:
/// - Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
/// - Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
@MainActor
final class BudgetViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var budgets: [Budget] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Internal Properties
    
    var cancellables = Set<AnyCancellable>()
    private let budgetService: MockBudgetService
    
    // MARK: - Computed Properties
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorMessagePublisher: Published<String?>.Publisher { $errorMessage }
    
    // MARK: - Initialization
    
    init(budgetService: MockBudgetService) {
        self.budgetService = budgetService
        initialize()
    }
    
    // MARK: - ViewModelProtocol Implementation
    
    func initialize() {
        setupBudgetUpdatesSubscription()
        fetchBudgets()
    }
    
    func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        budgets.removeAll()
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func setupBudgetUpdatesSubscription() {
        budgetService.getBudgetUpdates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedBudget in
                guard let self = self else { return }
                if let index = self.budgets.firstIndex(where: { $0.id == updatedBudget.id }) {
                    self.budgets[index] = updatedBudget
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Fetches all budgets from the service
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
    func fetchBudgets() {
        isLoading = true
        errorMessage = nil
        
        budgetService.fetchBudgets()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] fetchedBudgets in
                guard let self = self else { return }
                self.budgets = fetchedBudgets
            }
            .store(in: &cancellables)
    }
    
    /// Creates a new budget with the specified parameters
    /// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
    func createBudget(name: String, amount: Double, category: String, period: BudgetPeriod) -> AnyPublisher<Budget, Error> {
        isLoading = true
        errorMessage = nil
        
        return budgetService.createBudget(name: name, amount: amount, category: category, period: period)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// Updates an existing budget
    /// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
    func updateBudget(_ budget: Budget) -> AnyPublisher<Budget, Error> {
        isLoading = true
        errorMessage = nil
        
        return budgetService.updateBudget(budget: budget)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// Deletes a budget by ID
    /// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
    func deleteBudget(budgetId: String) -> AnyPublisher<Void, Error> {
        isLoading = true
        errorMessage = nil
        
        return budgetService.deleteBudget(budgetId: budgetId)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    } else {
                        self.budgets.removeAll { $0.id == budgetId }
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}