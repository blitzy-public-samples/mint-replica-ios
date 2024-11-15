// Foundation v5.5+
import Foundation
// Combine v5.5+
import Combine

// Relative import for Investment model
import Models.Investment

// MARK: - Human Tasks
// 1. Review mock data values with product team for realistic test scenarios
// 2. Add unit tests for publisher behavior and async operations
// 3. Consider adding configurable network delay simulation
// 4. Add error simulation scenarios for testing error handling

/// Error types that can occur in the investment service
enum InvestmentServiceError: Error {
    case networkError
    case dataUpdateError
    case invalidData
}

/// A mock service class that simulates investment-related functionality
/// Addresses requirement: Investment Portfolio Tracking - Technical Specification/1.2 Scope/Core Features
/// Addresses requirement: Mock Service Implementation - Technical Specification/Constraints for the AI to Generate a New iOS App/3
@MainActor
final class MockInvestmentService {
    
    // MARK: - Singleton
    
    static let shared = MockInvestmentService()
    
    // MARK: - Properties
    
    private var investments: [Investment]
    private let investmentsSubject = PassthroughSubject<[Investment], Error>()
    private let portfolioValueSubject = PassthroughSubject<Double, Error>()
    private let totalReturnSubject = PassthroughSubject<Double, Error>()
    
    // MARK: - Initialization
    
    private init() {
        self.investments = []
        self.investments = generateMockData()
        
        // Send initial values
        investmentsSubject.send(investments)
        
        let initialPortfolioValue = investments.reduce(0.0) { $0 + $1.getCurrentValue() }
        portfolioValueSubject.send(initialPortfolioValue)
        
        let initialTotalReturn = investments.reduce(0.0) { $0 + $1.getReturnAmount() }
        totalReturnSubject.send(initialTotalReturn)
    }
    
    // MARK: - Public Methods
    
    /// Get a publisher that emits investment updates
    func getInvestments() -> AnyPublisher<[Investment], Error> {
        return investmentsSubject.eraseToAnyPublisher()
    }
    
    /// Get a publisher that emits portfolio value updates
    func getTotalPortfolioValue() -> AnyPublisher<Double, Error> {
        return portfolioValueSubject.eraseToAnyPublisher()
    }
    
    /// Get a publisher that emits total return updates
    func getTotalReturn() -> AnyPublisher<Double, Error> {
        return totalReturnSubject.eraseToAnyPublisher()
    }
    
    /// Simulate refreshing investment data with network delay
    func refreshInvestments() async throws {
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Generate new mock data
            investments = generateMockData()
            
            // Calculate updated values
            let totalValue = investments.reduce(0.0) { $0 + $1.getCurrentValue() }
            let totalReturn = investments.reduce(0.0) { $0 + $1.getReturnAmount() }
            
            // Send updates through publishers
            investmentsSubject.send(investments)
            portfolioValueSubject.send(totalValue)
            totalReturnSubject.send(totalReturn)
            
        } catch {
            investmentsSubject.send(completion: .failure(InvestmentServiceError.networkError))
            portfolioValueSubject.send(completion: .failure(InvestmentServiceError.networkError))
            totalReturnSubject.send(completion: .failure(InvestmentServiceError.networkError))
            throw InvestmentServiceError.networkError
        }
    }
    
    // MARK: - Private Methods
    
    /// Generate realistic mock investment data
    private func generateMockData() -> [Investment] {
        var mockInvestments: [Investment] = []
        
        do {
            // Mock Stocks
            let appleStock = try Investment(
                id: "AAPL_001",
                accountId: "ACCT001",
                symbol: "AAPL",
                name: "Apple Inc.",
                quantity: 10.0,
                costBasis: 150.0,
                currentPrice: 175.0,
                lastUpdated: Date(),
                assetClass: "stocks"
            )
            
            let googleStock = try Investment(
                id: "GOOGL_001",
                accountId: "ACCT001",
                symbol: "GOOGL",
                name: "Alphabet Inc.",
                quantity: 5.0,
                costBasis: 2800.0,
                currentPrice: 2950.0,
                lastUpdated: Date(),
                assetClass: "stocks"
            )
            
            let microsoftStock = try Investment(
                id: "MSFT_001",
                accountId: "ACCT001",
                symbol: "MSFT",
                name: "Microsoft Corporation",
                quantity: 15.0,
                costBasis: 285.0,
                currentPrice: 310.0,
                lastUpdated: Date(),
                assetClass: "stocks"
            )
            
            // Mock ETFs
            let vanguardSP500 = try Investment(
                id: "VOO_001",
                accountId: "ACCT001",
                symbol: "VOO",
                name: "Vanguard S&P 500 ETF",
                quantity: 20.0,
                costBasis: 350.0,
                currentPrice: 380.0,
                lastUpdated: Date(),
                assetClass: "etfs"
            )
            
            let vanguardTotal = try Investment(
                id: "VTI_001",
                accountId: "ACCT001",
                symbol: "VTI",
                name: "Vanguard Total Stock Market ETF",
                quantity: 25.0,
                costBasis: 200.0,
                currentPrice: 220.0,
                lastUpdated: Date(),
                assetClass: "etfs"
            )
            
            // Mock Mutual Fund
            let vanguardIndex = try Investment(
                id: "VFIAX_001",
                accountId: "ACCT001",
                symbol: "VFIAX",
                name: "Vanguard 500 Index Fund",
                quantity: 50.0,
                costBasis: 375.0,
                currentPrice: 395.0,
                lastUpdated: Date(),
                assetClass: "mutual_funds"
            )
            
            mockInvestments = [
                appleStock,
                googleStock,
                microsoftStock,
                vanguardSP500,
                vanguardTotal,
                vanguardIndex
            ]
            
        } catch {
            // In production environment, we would log this error
            print("Error generating mock data: \(error)")
        }
        
        return mockInvestments
    }
}