// SwiftUI v5.5+
import SwiftUI
// Combine v5.5+
import Combine

// MARK: - Human Tasks
// 1. Review color contrast ratios for accessibility compliance
// 2. Verify VoiceOver descriptions with accessibility team
// 3. Test chart interactions with different data set sizes
// 4. Validate layout on all iOS device sizes

// Relative imports
import "../../ViewModels/InvestmentViewModel"
import "../../Models/Investment"
import "../../Views/Components/ChartView"

/// A detailed view of an investment holding showing performance metrics and charts
/// Addresses requirements:
/// - Investment Portfolio Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Investment Dashboard (Technical Specification/8.1.5 Investment Dashboard)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct InvestmentDetailView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = InvestmentViewModel()
    @State private var showingTransactionHistory = false
    @State private var showingPerformanceChart = true
    let investment: Investment
    
    // MARK: - Private Properties
    
    private let chartHeight: CGFloat = 200
    private let spacing: CGFloat = 16
    
    // MARK: - Initialization
    
    init(investment: Investment) {
        self.investment = investment
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: spacing) {
                headerView()
                
                if showingPerformanceChart {
                    performanceChartView()
                }
                
                detailsView()
            }
            .padding()
        }
        .navigationTitle(investment.symbol)
        .refreshable {
            try? await viewModel.refreshData()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .background(Color.secondary.opacity(0.1))
            }
        }
    }
    
    // MARK: - View Components
    
    private func headerView() -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(investment.name)
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Value")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(investment.getFormattedCurrentValue())
                        .font(.title)
                        .bold()
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Return")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(investment.getFormattedReturn())
                        .font(.title3)
                        .bold()
                        .foregroundColor(investment.getReturnAmount() >= 0 ? .green : .red)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func performanceChartView() -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack {
                Text("Performance")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingPerformanceChart.toggle()
                } label: {
                    Image(systemName: showingPerformanceChart ? "chevron.up" : "chevron.down")
                }
                .accessibilityLabel(showingPerformanceChart ? "Hide performance chart" : "Show performance chart")
            }
            
            ChartView(
                type: .line,
                data: [investment.getCurrentValue()],
                labels: [investment.symbol],
                showLegend: false,
                animate: true
            )
            .frame(height: chartHeight)
            .accessibilityLabel("Performance chart showing investment value over time")
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func detailsView() -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text("Details")
                .font(.headline)
            
            Group {
                detailRow(title: "Cost Basis", value: String(format: "%.2f", investment.costBasis))
                detailRow(title: "Quantity", value: String(format: "%.4f", investment.quantity))
                detailRow(title: "Current Price", value: String(format: "%.2f", investment.currentPrice))
                detailRow(title: "Asset Class", value: investment.assetClass.capitalized)
                detailRow(title: "Last Updated", value: formatDate(investment.lastUpdated))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}