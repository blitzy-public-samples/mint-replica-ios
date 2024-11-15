// Foundation v5.5+
import Foundation
// Combine v2.0+
import Combine

// Relative imports
import "../Models/Budget"
import "../Core/Utilities/MockDataGenerator"

// MARK: - Human Tasks
// 1. Verify artificial delay timings with UI/UX team for realistic simulation
// 2. Add more edge cases in mock data generation
// 3. Test concurrent budget operations for race conditions
// 4. Validate memory management with long-running Combine subscriptions

/// Mock implementation of budget service for development and preview purposes
/// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
@MainActor
public class MockBudgetService {
    // MARK: - Properties
    
    private var mockBudgets: [Budget]
    private let budgetUpdateSubject: PassthroughSubject<Budget, Never>
    
    // MARK: - Initialization
    
    public init() {
        self.mockBudgets = []
        self.budgetUpdateSubject = PassthroughSubject<Budget, Never>()
        
        // Generate initial mock budget
        if let initialBudget = MockDataGenerator.generateMockBudget() {
            self.mockBudgets.append(initialBudget)
        }
    }
    
    // MARK: - Public Methods
    
    /// Simulates fetching all budgets for the current user
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
    public func fetchBudgets() -> AnyPublisher<[Budget], Error> {
        Just(mockBudgets)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Simulates creating a new budget with provided parameters
    /// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
    public func createBudget(name: String, amount: Double, category: String, period: BudgetPeriod) -> AnyPublisher<Budget, Error> {
        Future<Budget, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MockBudgetService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Service instance deallocated"])))
                return
            }
            
            do {
                let startDate = Date()
                let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate
                
                let newBudget = try Budget(
                    id: UUID().uuidString,
                    name: name,
                    amount: amount,
                    category: category,
                    period: period,
                    startDate: startDate,
                    endDate: endDate,
                    spent: 0.0,
                    isActive: true
                )
                
                self.mockBudgets.append(newBudget)
                self.budgetUpdateSubject.send(newBudget)
                promise(.success(newBudget))
                
            } catch {
                promise(.failure(error))
            }
        }
        .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Simulates updating an existing budget
    /// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
    public func updateBudget(budget: Budget) -> AnyPublisher<Budget, Error> {
        Future<Budget, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MockBudgetService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Service instance deallocated"])))
                return
            }
            
            if let index = self.mockBudgets.firstIndex(where: { $0.id == budget.id }) {
                self.mockBudgets[index] = budget
                self.budgetUpdateSubject.send(budget)
                promise(.success(budget))
            } else {
                promise(.failure(NSError(domain: "MockBudgetService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Budget not found"])))
            }
        }
        .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Simulates deleting a budget by ID
    /// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
    public func deleteBudget(budgetId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MockBudgetService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Service instance deallocated"])))
                return
            }
            
            if let index = self.mockBudgets.firstIndex(where: { $0.id == budgetId }) {
                self.mockBudgets.remove(at: index)
                promise(.success(()))
            } else {
                promise(.failure(NSError(domain: "MockBudgetService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Budget not found"])))
            }
        }
        .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Provides a stream of budget updates for real-time monitoring
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
    public func getBudgetUpdates() -> AnyPublisher<Budget, Never> {
        budgetUpdateSubject.eraseToAnyPublisher()
    }
}