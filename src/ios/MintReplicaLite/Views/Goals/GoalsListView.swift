// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "../../Core/Extensions/View+Extensions"
import "../../Models/Goal"
import "../../ViewModels/GoalViewModel"
import "../../Views/Components/LoadingView"
import "../../Views/Components/ErrorView"

// MARK: - Human Tasks
/*
 1. Verify accessibility labels and traits with VoiceOver
 2. Test swipe-to-delete gesture with VoiceOver enabled
 3. Add unit tests for view state transitions
 4. Review goal creation sheet implementation with design team
*/

/// Main view for displaying and managing financial goals
/// Requirements addressed:
/// - Financial Goal Setting (Technical Specification/1.1 System Overview/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
struct GoalsListView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = GoalViewModel()
    @State private var showingCreateGoal = false
    @State private var selectedGoal: Goal?
    @State private var showingDeleteConfirmation = false
    @State private var goalToDelete: Goal?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.goals.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    goalsList
                }
                
                if let errorMessage = viewModel.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        title: "Error",
                        retryAction: { viewModel.initialize() },
                        retryButtonText: "Try Again"
                    )
                }
            }
            .navigationTitle("Financial Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGoal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .accessibilityLabel("Create New Goal")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGoal) {
                // CreateGoalView will be implemented separately
                Text("Create Goal View")
            }
            .loadingOverlay(viewModel.isLoading)
        }
    }
    
    // MARK: - Subviews
    
    private var goalsList: some View {
        List {
            ForEach(viewModel.goals, id: \.id) { goal in
                goalRow(goal)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            goalToDelete = goal
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.initialize()
        }
        .confirmationDialog(
            "Delete Goal",
            isPresented: $showingDeleteConfirmation,
            presenting: goalToDelete
        ) { goal in
            Button("Delete", role: .destructive) {
                deleteGoal(goal)
            }
        } message: { goal in
            Text("Are you sure you want to delete '\(goal.name)'?")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Goals Yet")
                .font(.headline)
            
            Text("Tap the + button to create your first financial goal")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    private func goalRow(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.headline)
                
                Spacer()
                
                Text(goal.formattedTargetAmount())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: goal.calculateProgress(), total: 100)
                .tint(.blue)
            
            HStack {
                Text(goal.formattedCurrentAmount())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(goal.calculateProgress()))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture {
            selectedGoal = goal
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.name), Progress: \(Int(goal.calculateProgress()))%, Current: \(goal.formattedCurrentAmount()), Target: \(goal.formattedTargetAmount())")
    }
    
    private func deleteGoal(_ goal: Goal) {
        Task {
            do {
                _ = try await viewModel.deleteGoal(goalId: goal.id).async()
            } catch {
                // Error handling is managed by the ViewModel
                print("Error deleting goal: \(error)")
            }
        }
    }
}

#if DEBUG
struct GoalsListView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsListView()
    }
}
#endif