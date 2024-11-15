// Foundation v5.5+
import Foundation
// Combine v5.5+
import Combine

// Relative imports
import Models.Investment
import Mocks.MockInvestmentService
import Core.Protocols.ViewModelProtocol

// MARK: - Human Tasks
// 1. Review asset allocation calculation logic with product team
// 2. Add unit tests for error handling scenarios
// 3. Consider adding portfolio performance analytics
// 4. Review data refresh intervals with stakeholders

/// ViewModel responsible for managing investment portfolio data and business logic
/// Addresses requirements:
/// - Investment Portfolio Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Investment Dashboard (Technical Specification/8.1.5 Investment Dashboard)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
@MainActor
final class InvestmentViewModel: ViewModelProtocol {
    
    // MARK: - Published Properties
    
    @Published private(set) var investments: [Investment] = []
    @Published private(set) var totalPortfolioValue: Double = 0.0
    @Published private(set) var totalReturn: Double = 0.0
    @Published private(set) var returnPercentage: Double = 0.0
    @Published private(set) var assetAllocation: [String: Double] = [:]
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - ViewModelProtocol Conformance
    
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private Properties
    
    private let investmentService: MockInvestmentService
    
    // MARK: - Publisher Accessors for Protocol Conformance
    
    var isLoading_: Published<Bool>.Publisher { $isLoading }
    var errorMessage_: Published<String?>.Publisher { $errorMessage }
    
    // MARK: - Initialization
    
    init() {
        self.investmentService = MockInvestmentService.shared
        initialize()
    }
    
    // MARK: - Public Methods
    
    func initialize() {
        setupSubscriptions()
        Task {
            try? await refreshData()
        }
    }
    
    /// Refreshes investment portfolio data
    func refreshData() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await investmentService.refreshInvestments()
            assetAllocation = calculateAssetAllocation()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to refresh investment data: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to investments updates
        investmentService.getInvestments()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] investments in
                self?.investments = investments
            }
            .store(in: &cancellables)
        
        // Subscribe to portfolio value updates
        investmentService.getTotalPortfolioValue()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] value in
                self?.totalPortfolioValue = value
            }
            .store(in: &cancellables)
        
        // Subscribe to total return updates
        investmentService.getTotalReturn()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] returnValue in
                self?.totalReturn = returnValue
                if let totalValue = self?.totalPortfolioValue, totalValue > 0 {
                    self?.returnPercentage = returnValue / totalValue
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateAssetAllocation() -> [String: Double] {
        var allocation: [String: Double] = [:]
        let totalValue = investments.reduce(0.0) { $0 + $1.getCurrentValue() }
        
        guard totalValue > 0 else { return [:] }
        
        // Group investments by asset class and calculate percentages
        let groupedInvestments = Dictionary(grouping: investments) { $0.assetClass }
        for (assetClass, investments) in groupedInvestments {
            let classValue = investments.reduce(0.0) { $0 + $1.getCurrentValue() }
            let percentage = (classValue / totalValue) * 100
            allocation[assetClass] = percentage
        }
        
        return allocation
    }
    
    func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}