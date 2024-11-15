// External dependencies versions:
// SwiftUI: 5.5+
// Combine: 5.5+

import SwiftUI
import Combine

// Relative imports
import "../../ViewModels/GoalViewModel"
import "../../Models/Goal"
import "../Components/LoadingView"

// MARK: - Human Tasks
/*
1. Review accessibility labels and traits with UX team
2. Add analytics tracking for goal creation events
3. Consider adding haptic feedback for form submission
4. Test form validation with VoiceOver enabled
*/

/// A view that provides the interface for creating new financial goals
/// Requirements addressed:
/// - Financial Goal Setting (Technical Specification/1.1 System Overview/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
struct GoalCreationView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = GoalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var goalName = ""
    @State private var goalDescription = ""
    @State private var targetAmount = ""
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedCategory = GoalCategory.savings
    @State private var showingError = false
    
    // MARK: - Private Properties
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // MARK: - Validation
    
    private func validateInputs() -> Bool {
        guard !goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewModel.errorMessage = "Please enter a goal name"
            return false
        }
        
        guard let amount = numberFormatter.number(from: targetAmount)?.doubleValue,
              amount > 0 else {
            viewModel.errorMessage = "Please enter a valid target amount"
            return false
        }
        
        guard targetDate > Date() else {
            viewModel.errorMessage = "Target date must be in the future"
            return false
        }
        
        return true
    }
    
    // MARK: - Actions
    
    private func createGoal() {
        guard validateInputs(),
              let amount = numberFormatter.number(from: targetAmount)?.doubleValue else {
            showingError = true
            return
        }
        
        viewModel.createGoal(
            name: goalName,
            description: goalDescription,
            targetAmount: amount,
            targetDate: targetDate,
            category: selectedCategory
        )
        .receive(on: RunLoop.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure = completion {
                    showingError = true
                }
            },
            receiveValue: { _ in
                dismiss()
            }
        )
        .store(in: &viewModel.cancellables)
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Goal Details")) {
                        TextField("Goal Name", text: $goalName)
                            .textContentType(.name)
                            .accessibilityLabel("Goal name")
                        
                        TextField("Description (Optional)", text: $goalDescription)
                            .accessibilityLabel("Goal description")
                    }
                    
                    Section(header: Text("Financial Details")) {
                        TextField("Target Amount", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Target amount")
                        
                        DatePicker(
                            "Target Date",
                            selection: $targetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .accessibilityLabel("Target date")
                    }
                    
                    Section(header: Text("Category")) {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Savings").tag(GoalCategory.savings)
                            Text("Debt").tag(GoalCategory.debt)
                            Text("Investment").tag(GoalCategory.investment)
                            Text("Emergency").tag(GoalCategory.emergency)
                            Text("Retirement").tag(GoalCategory.retirement)
                            Text("Education").tag(GoalCategory.education)
                            Text("Home").tag(GoalCategory.home)
                            Text("Travel").tag(GoalCategory.travel)
                            Text("Other").tag(GoalCategory.other)
                        }
                        .accessibilityLabel("Goal category")
                    }
                    
                    Section {
                        Button(action: createGoal) {
                            Text("Create Goal")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.blue)
                        .disabled(goalName.isEmpty || targetAmount.isEmpty)
                    }
                }
                .navigationTitle("New Goal")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK") {
                        showingError = false
                    }
                } message: {
                    Text(viewModel.errorMessage ?? "An error occurred")
                }
                
                if viewModel.isLoading {
                    LoadingView(
                        message: "Creating your goal...",
                        backgroundColor: .white,
                        spinnerColor: .blue
                    )
                }
            }
        }
    }
}

#if DEBUG
struct GoalCreationView_Previews: PreviewProvider {
    static var previews: some View {
        GoalCreationView()
    }
}
#endif