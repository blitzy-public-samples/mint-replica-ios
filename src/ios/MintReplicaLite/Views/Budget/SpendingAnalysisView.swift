// SwiftUI v5.5+
import SwiftUI
// Combine v5.5+
import Combine

// Relative imports
import "../../ViewModels/BudgetViewModel"
import "../../Models/Budget"
import "../Components/ChartView"

// MARK: - Human Tasks
// 1. Test with different dataset sizes to validate performance
// 2. Verify accessibility labels and VoiceOver support
// 3. Test date picker interactions across different time zones
// 4. Review chart animations on different device sizes

/// A view that provides detailed spending analysis visualization and insights
/// Addresses requirements:
/// - Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
/// - Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
/// - Spending Analysis (Technical Specification/8.1.4 Budget Creation/Edit)
struct SpendingAnalysisView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: BudgetViewModel
    @State private var showingDatePicker: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var selectedChartType: ChartType = .bar
    @State private var selectedPeriod: BudgetPeriod = .monthly
    
    // MARK: - Initialization
    
    init(viewModel: BudgetViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    periodSelectorView()
                        .padding(.horizontal)
                    
                    chartTypePicker()
                        .padding(.horizontal)
                    
                    spendingChartView()
                        .frame(height: 300)
                        .padding()
                    
                    categoryBreakdownView()
                        .padding()
                }
            }
            .navigationTitle("Spending Analysis")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert(item: Binding(
                get: { viewModel.errorMessage.map { ErrorWrapper(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Supporting Views
    
    private func periodSelectorView() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(dateRangeText())
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingDatePicker.toggle() }) {
                    Image(systemName: "calendar")
                        .imageScale(.large)
                }
            }
            
            HStack(spacing: 12) {
                periodButton(.weekly, "Week")
                periodButton(.monthly, "Month")
                periodButton(.custom, "Custom")
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            .presentationDetents([.medium])
        }
    }
    
    private func periodButton(_ period: BudgetPeriod, _ title: String) -> some View {
        Button(action: { selectedPeriod = period }) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedPeriod == period ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(selectedPeriod == period ? .white : .primary)
                .cornerRadius(8)
        }
    }
    
    private func chartTypePicker() -> some View {
        Picker("Chart Type", selection: $selectedChartType) {
            Text("Bar").tag(ChartType.bar)
            Text("Line").tag(ChartType.line)
            Text("Pie").tag(ChartType.pie)
            Text("Area").tag(ChartType.area)
        }
        .pickerStyle(.segmented)
    }
    
    private func spendingChartView() -> some View {
        let chartData = processChartData()
        return ChartView(
            type: selectedChartType,
            data: chartData.values,
            labels: chartData.labels,
            showLegend: true,
            showAxes: selectedChartType != .pie,
            animate: true
        )
        .accessibilityLabel("Spending analysis chart")
    }
    
    private func categoryBreakdownView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
            
            ForEach(viewModel.budgets.sorted(by: { $0.spent > $1.spent }), id: \.id) { budget in
                VStack(spacing: 8) {
                    HStack {
                        Text(budget.category)
                            .font(.subheadline)
                        Spacer()
                        Text(budget.formattedAmount())
                            .font(.subheadline)
                            .foregroundColor(budget.isOverBudget() ? .red : .primary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(budget.isOverBudget() ? Color.red : Color.accentColor)
                                .frame(width: min(CGFloat(budget.spentPercentage()) / 100.0 * geometry.size.width, geometry.size.width), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    
                    Text(budget.formattedProgress())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func dateRangeText() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        switch selectedPeriod {
        case .weekly:
            return "Week of \(formatter.string(from: selectedDate))"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: selectedDate)
        case .custom:
            return "Custom Period"
        }
    }
    
    private func processChartData() -> (values: [Double], labels: [String]) {
        let relevantBudgets = viewModel.budgets.filter { budget in
            budget.period == selectedPeriod
        }
        
        let values = relevantBudgets.map { $0.spent }
        let labels = relevantBudgets.map { $0.category }
        
        return (values, labels)
    }
}

// MARK: - Supporting Types

private struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}