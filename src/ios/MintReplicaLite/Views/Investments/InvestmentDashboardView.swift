// SwiftUI v5.5+
import SwiftUI
// Combine v5.5+
import Combine

// Relative imports
import "../../ViewModels/InvestmentViewModel"
import "../../Views/Components/ChartView"
import "../../Views/Components/LoadingView"

// MARK: - Human Tasks
// 1. Review color contrast ratios for accessibility compliance
// 2. Verify VoiceOver labels and hints
// 3. Test with dynamic type sizes
// 4. Validate chart interactions with assistive technologies

/// Time range options for investment performance
enum TimeRange: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case quarter = "3M"
    case YTD = "YTD"
    case year = "1Y"
    case all = "ALL"
}

/// Main investment dashboard view showing portfolio overview and holdings
/// Addresses requirements:
/// - Investment Portfolio Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Investment Dashboard (Technical Specification/8.1.5 Investment Dashboard)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct InvestmentDashboardView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = InvestmentViewModel()
    @State private var selectedTimeRange: TimeRange = .YTD
    @State private var showingHoldingDetails: Bool = false
    @State private var selectedHolding: Investment? = nil
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        portfolioValueSection
                        
                        timeRangeSelector
                        
                        returnsSection
                        
                        assetAllocationSection
                        
                        holdingsListSection
                    }
                    .padding()
                }
                .refreshable {
                    Task {
                        try? await viewModel.refreshData()
                    }
                }
                
                if viewModel.isLoading {
                    LoadingView(message: "Updating portfolio...")
                }
            }
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            try? await viewModel.refreshData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .accessibilityLabel("Refresh portfolio data")
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Portfolio Value Section
    
    private var portfolioValueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Portfolio Value")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(String(format: "$%.2f", viewModel.totalPortfolioValue))
                .font(.title.bold())
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: viewModel.returnPercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text(String(format: "%.1f%%", abs(viewModel.returnPercentage * 100)))
                Text(viewModel.returnPercentage >= 0 ? "Gain" : "Loss")
            }
            .font(.subheadline)
            .foregroundColor(viewModel.returnPercentage >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Portfolio value")
        .accessibilityValue(String(format: "$%.2f, %.1f%% %@",
                                 viewModel.totalPortfolioValue,
                                 abs(viewModel.returnPercentage * 100),
                                 viewModel.returnPercentage >= 0 ? "gain" : "loss"))
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button {
                        selectedTimeRange = range
                    } label: {
                        Text(range.rawValue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeRange == range ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedTimeRange == range ? .white : .primary)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("\(range.rawValue) time range")
                    .accessibilityAddTraits(selectedTimeRange == range ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Returns Section
    
    private var returnsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
            
            ChartView(
                type: .area,
                data: [viewModel.totalPortfolioValue - viewModel.totalReturn] + [viewModel.totalPortfolioValue],
                labels: ["Start", "Current"],
                showAxes: true
            )
            .frame(height: 200)
            .accessibilityLabel("Portfolio performance chart")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Asset Allocation Section
    
    private var assetAllocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asset Allocation")
                .font(.headline)
            
            ChartView(
                type: .pie,
                data: viewModel.assetAllocation.map { $0.value },
                labels: viewModel.assetAllocation.map { $0.key },
                showLegend: true
            )
            .frame(height: 200)
            .accessibilityLabel("Asset allocation pie chart")
            
            ForEach(Array(viewModel.assetAllocation.keys.sorted()), id: \.self) { asset in
                if let value = viewModel.assetAllocation[asset] {
                    HStack {
                        Text(asset)
                        Spacer()
                        Text(String(format: "%.1f%%", value))
                    }
                    .font(.subheadline)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(asset): \(String(format: "%.1f percent", value))")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Holdings List Section
    
    private var holdingsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Holdings")
                .font(.headline)
            
            ForEach(viewModel.investments) { investment in
                Button {
                    selectedHolding = investment
                    showingHoldingDetails = true
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(investment.symbol)
                                .font(.headline)
                            Text(investment.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(String(format: "$%.2f", investment.getCurrentValue()))
                                .font(.headline)
                            Text(String(format: "%.2f shares", investment.shares))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(investment.name)")
                .accessibilityValue("Current value: $\(String(format: "%.2f", investment.getCurrentValue())), \(String(format: "%.2f shares", investment.shares))")
                .accessibilityHint("Double tap to view details")
            }
        }
        .sheet(isPresented: $showingHoldingDetails) {
            if let holding = selectedHolding {
                NavigationView {
                    // Note: Holding details view to be implemented separately
                    Text("Details for \(holding.symbol)")
                        .navigationTitle(holding.name)
                        .navigationBarItems(trailing: Button("Done") {
                            showingHoldingDetails = false
                        })
                }
            }
        }
    }
}

#if DEBUG
struct InvestmentDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        InvestmentDashboardView()
    }
}
#endif