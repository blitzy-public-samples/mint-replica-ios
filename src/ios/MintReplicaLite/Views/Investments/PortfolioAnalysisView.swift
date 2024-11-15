// SwiftUI v5.5+
import SwiftUI

// MARK: - Human Tasks
// 1. Review color contrast ratios for accessibility compliance
// 2. Validate VoiceOver labels with accessibility team
// 3. Test dynamic type scaling across all device sizes
// 4. Consider adding haptic feedback for interactive elements

// Relative imports
import "../../ViewModels/InvestmentViewModel"
import "../Components/ChartView"

// MARK: - TimeRange
enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    case all = "All Time"
}

// MARK: - PortfolioAnalysisView
struct PortfolioAnalysisView: View {
    // MARK: - Properties
    @StateObject private var viewModel: InvestmentViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingAllHoldings: Bool = false
    
    // MARK: - Constants
    private let maxVisibleHoldings = 5
    private let chartHeight: CGFloat = 250
    private let spacing: CGFloat = 16
    
    // MARK: - Initialization
    init() {
        _viewModel = StateObject(wrappedValue: InvestmentViewModel())
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: spacing) {
                // Portfolio Value Section
                // Addresses requirement: Investment Dashboard (Technical Specification/8.1.5)
                portfolioValueSection()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Portfolio Value")
                
                Divider()
                
                // Asset Allocation Section
                // Addresses requirement: Investment Portfolio Tracking (Technical Specification/1.2 Scope/Core Features)
                assetAllocationSection()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Asset Allocation")
                
                Divider()
                
                // Holdings Section
                holdingsSection()
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Investment Holdings")
            }
            .padding()
        }
        .refreshable {
            try? await viewModel.refreshData()
        }
        .navigationTitle("Portfolio Analysis")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Portfolio Value Section
    private func portfolioValueSection() -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text("Total Portfolio Value")
                .font(.headline)
            
            Text(String(format: "$%.2f", viewModel.totalPortfolioValue))
                .font(.system(size: 34, weight: .bold))
                .accessibilityLabel("Total value \(String(format: "%.2f dollars", viewModel.totalPortfolioValue))")
            
            HStack {
                Text(String(format: "%.1f%%", viewModel.returnPercentage * 100))
                    .foregroundColor(viewModel.returnPercentage >= 0 ? .green : .red)
                    .font(.headline)
                
                Text(String(format: "($%.2f)", viewModel.totalReturn))
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Return \(String(format: "%.1f percent", viewModel.returnPercentage * 100))")
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, spacing)
        }
    }
    
    // MARK: - Asset Allocation Section
    private func assetAllocationSection() -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text("Asset Allocation")
                .font(.headline)
            
            ChartView(
                type: .pie,
                data: Array(viewModel.assetAllocation.values),
                labels: Array(viewModel.assetAllocation.keys),
                showLegend: true,
                animate: true
            )
            .frame(height: chartHeight)
            
            // Asset allocation legend
            ForEach(Array(viewModel.assetAllocation.keys.enumerated()), id: \.element) { index, assetClass in
                HStack {
                    Circle()
                        .fill(Color.primary.opacity(Double(index + 1) / Double(viewModel.assetAllocation.count)))
                        .frame(width: 12, height: 12)
                    
                    Text(assetClass)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", viewModel.assetAllocation[assetClass] ?? 0))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("\(assetClass) \(String(format: "%.1f percent", viewModel.assetAllocation[assetClass] ?? 0))")
            }
        }
    }
    
    // MARK: - Holdings Section
    private func holdingsSection() -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack {
                Text("Holdings")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showingAllHoldings.toggle()
                    }
                }) {
                    Text(showingAllHoldings ? "Show Less" : "Show All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            let displayedInvestments = showingAllHoldings ? 
                viewModel.investments : 
                Array(viewModel.investments.prefix(maxVisibleHoldings))
            
            ForEach(displayedInvestments, id: \.id) { investment in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(investment.symbol)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", investment.getCurrentValue()))
                            .font(.headline)
                    }
                    
                    HStack {
                        Text(investment.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let returnPercentage = investment.getReturnPercentage()
                        Text(String(format: "%.1f%%", returnPercentage))
                            .font(.subheadline)
                            .foregroundColor(returnPercentage >= 0 ? .green : .red)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(investment.symbol) \(investment.name) Value \(String(format: "%.2f dollars", investment.getCurrentValue())) Return \(String(format: "%.1f percent", investment.getReturnPercentage()))")
            }
        }
    }
}