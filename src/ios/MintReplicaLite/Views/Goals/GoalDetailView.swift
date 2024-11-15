// SwiftUI v5.5+
import SwiftUI
import Combine

// Relative imports
import "../../Core/Extensions/View+Extensions"
import "../../Models/Goal"
import "../../ViewModels/GoalViewModel"
import "../Components/ProgressView"

// MARK: - Human Tasks
/*
 1. Review accessibility labels with UX team
 2. Consider adding haptic feedback for progress updates
 3. Add unit tests for view state management
 4. Consider adding goal sharing functionality
*/

/// A view that displays detailed information about a financial goal
/// Addresses requirements:
/// - Financial Goal Setting (Technical Specification/1.1 System Overview/Core Features)
/// - Goal Progress Tracking (Technical Specification/8.1.2 Main Dashboard)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
struct GoalDetailView: View {
    // MARK: - Properties
    
    let goal: Goal
    @ObservedObject var viewModel: GoalViewModel
    @Binding var isPresented: Bool
    
    @State private var showingDeleteAlert = false
    @State private var showingProgressSheet = false
    @State private var newProgress: Double
    
    // MARK: - Initialization
    
    init(goal: Goal, viewModel: GoalViewModel, isPresented: Binding<Bool>) {
        self.goal = goal
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._newProgress = State(initialValue: goal.currentAmount)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Goal Title
                Text(goal.name)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Goal Description
                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Progress Section
                VStack(alignment: .leading, spacing: 8) {
                    CustomProgressView(
                        progress: goal.calculateProgress() / 100,
                        label: "Progress towards \(goal.name)",
                        showPercentage: true,
                        progressColor: .accentColor
                    )
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(goal.formattedCurrentAmount())
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Target")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(goal.formattedTargetAmount())
                                .font(.headline)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Target Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(goal.formattedTargetDate())
                        .font(.headline)
                }
                
                Spacer(minLength: 24)
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: { showingProgressSheet = true }) {
                        HStack {
                            Image(systemName: "arrow.up.right.circle.fill")
                            Text("Update Progress")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .accessibleTapTarget()
                    
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Goal")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                    .accessibleTapTarget()
                }
            }
            .standardPadding()
            .cardStyle()
        }
        .loadingOverlay(viewModel.isLoading)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Goal"),
                message: Text("Are you sure you want to delete this goal? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteGoal()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingProgressSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Update Progress")
                        .font(.headline)
                        .padding(.top)
                    
                    TextField("Current Amount", value: $newProgress, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button("Save") {
                        updateProgress()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationBarItems(
                    trailing: Button("Cancel") {
                        showingProgressSheet = false
                    }
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func updateProgress() {
        viewModel.updateGoalProgress(goalId: goal.id, newAmount: newProgress)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        showingProgressSheet = false
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &viewModel.cancellables)
    }
    
    private func deleteGoal() {
        viewModel.deleteGoal(goalId: goal.id)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        isPresented = false
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &viewModel.cancellables)
    }
}