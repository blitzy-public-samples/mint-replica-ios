// SwiftUI v5.5+
import SwiftUI
// Combine v5.5+
import Combine

// MARK: - Human Tasks
/*
 * 1. Ensure VoiceOver descriptions are properly localized for accessibility
 * 2. Verify color contrast ratios meet WCAG 2.1 AA standards
 * 3. Test with different data set sizes to ensure performance
 * 4. Validate chart rendering on different device sizes
 */

// Relative imports from project
import "../../Core/Extensions/Color+Extensions"
import "../../Core/Extensions/View+Extensions"

// MARK: - ChartType
/// Supported chart visualization types
/// Addresses requirement: Investment Portfolio Tracking - Technical Specification/1.2 Scope/Core Features
enum ChartType {
    case line
    case bar
    case pie
    case area
}

// MARK: - ChartView
/// SwiftUI View that renders financial data visualizations
/// Addresses requirements:
/// - Investment Portfolio Tracking - Technical Specification/1.2 Scope/Core Features
/// - Budget Monitoring - Technical Specification/1.2 Scope/Core Features
/// - Accessibility Features - Technical Specification/8.1.8 Accessibility Features
struct ChartView: View {
    // MARK: - Properties
    let type: ChartType
    let data: [Double]
    let labels: [String]
    let showLegend: Bool
    let showAxes: Bool
    let animate: Bool
    var isLoading: Bool = false
    
    // MARK: - Private Properties
    @State private var animationProgress: CGFloat = 0
    private let chartPadding: CGFloat = 20
    private let axisLineWidth: CGFloat = 1
    private let dataPointRadius: CGFloat = 4
    
    // MARK: - Initializer
    init(type: ChartType,
         data: [Double],
         labels: [String],
         showLegend: Bool = true,
         showAxes: Bool = true,
         animate: Bool = true) {
        self.type = type
        self.data = data
        self.labels = labels
        self.showLegend = showLegend
        self.showAxes = showAxes
        self.animate = animate
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch type {
                case .line:
                    lineChart(size: geometry.size)
                case .bar:
                    barChart(size: geometry.size)
                case .pie:
                    pieChart(size: geometry.size)
                case .area:
                    areaChart(size: geometry.size)
                }
            }
            .accessibleTapTarget()
            .loadingOverlay(isLoading)
            .onAppear {
                if animate {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        animationProgress = 1.0
                    }
                } else {
                    animationProgress = 1.0
                }
            }
        }
    }
    
    // MARK: - Private Chart Rendering Methods
    
    private func lineChart(size: CGSize) -> some View {
        let points = calculateDataPoints(values: data, size: size)
        return ZStack {
            if showAxes {
                axesView(size: size)
            }
            
            Path { path in
                guard let firstPoint = points.first else { return }
                path.move(to: firstPoint)
                points.dropFirst().forEach { point in
                    path.addLine(to: point)
                }
            }
            .trim(from: 0, to: animationProgress)
            .stroke(Color.primary, lineWidth: 2)
            
            ForEach(points.indices, id: \.self) { index in
                Circle()
                    .fill(Color.primary)
                    .frame(width: dataPointRadius * 2, height: dataPointRadius * 2)
                    .position(points[index])
                    .opacity(animationProgress)
            }
        }
        .accessibilityLabel("Line chart showing financial data")
        .accessibilityValue(accessibilityDescription())
    }
    
    private func barChart(size: CGSize) -> some View {
        let barWidth = (size.width - chartPadding * 2) / CGFloat(data.count)
        let maxValue = data.max() ?? 1
        
        return ZStack {
            if showAxes {
                axesView(size: size)
            }
            
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(data.indices, id: \.self) { index in
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: barWidth * 0.8,
                               height: (data[index] / maxValue) * (size.height - chartPadding * 2) * animationProgress)
                        .accessibilityLabel("\(labels[index])")
                        .accessibilityValue("\(data[index])")
                }
            }
            .padding(.horizontal, chartPadding)
        }
        .accessibilityLabel("Bar chart showing financial data")
        .accessibilityValue(accessibilityDescription())
    }
    
    private func pieChart(size: CGSize) -> some View {
        let total = data.reduce(0, +)
        let angles = data.map { $0 / total * 360 }
        let radius = min(size.width, size.height) / 2 - chartPadding
        
        return ZStack {
            ForEach(angles.indices, id: \.self) { index in
                let startAngle = index == 0 ? 0 : angles[..<index].reduce(0, +)
                PieSlice(startAngle: Angle(degrees: startAngle),
                        endAngle: Angle(degrees: startAngle + angles[index] * animationProgress))
                    .fill(Color.primary.opacity(Double(index + 1) / Double(data.count)))
                    .frame(width: radius * 2, height: radius * 2)
                    .accessibilityLabel("\(labels[index])")
                    .accessibilityValue("\(data[index])")
            }
        }
        .accessibilityLabel("Pie chart showing financial data")
        .accessibilityValue(accessibilityDescription())
    }
    
    private func areaChart(size: CGSize) -> some View {
        let points = calculateDataPoints(values: data, size: size)
        return ZStack {
            if showAxes {
                axesView(size: size)
            }
            
            Path { path in
                guard let firstPoint = points.first else { return }
                path.move(to: CGPoint(x: firstPoint.x, y: size.height - chartPadding))
                path.addLine(to: firstPoint)
                points.dropFirst().forEach { point in
                    path.addLine(to: point)
                }
                path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: size.height - chartPadding))
                path.closeSubpath()
            }
            .fill(Color.primary.opacity(0.2))
            .opacity(animationProgress)
            
            Path { path in
                guard let firstPoint = points.first else { return }
                path.move(to: firstPoint)
                points.dropFirst().forEach { point in
                    path.addLine(to: point)
                }
            }
            .trim(from: 0, to: animationProgress)
            .stroke(Color.primary, lineWidth: 2)
        }
        .accessibilityLabel("Area chart showing financial data")
        .accessibilityValue(accessibilityDescription())
    }
    
    // MARK: - Helper Methods
    
    private func calculateDataPoints(values: [Double], size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let maxValue = values.max() ?? 1
        let minValue = values.min() ?? 0
        let range = maxValue - minValue
        
        let xStep = (size.width - chartPadding * 2) / CGFloat(values.count - 1)
        
        return values.enumerated().map { index, value in
            let x = chartPadding + CGFloat(index) * xStep
            let normalizedValue = (value - minValue) / range
            let y = size.height - chartPadding - (normalizedValue * (size.height - chartPadding * 2))
            return CGPoint(x: x, y: y)
        }
    }
    
    private func calculateYAxisLabels(values: [Double]) -> [String] {
        guard !values.isEmpty else { return [] }
        let maxValue = values.max() ?? 1
        let minValue = values.min() ?? 0
        let range = maxValue - minValue
        let step = range / 4
        
        return (0...4).map { index in
            let value = minValue + (step * Double(index))
            return String(format: "%.1f", value)
        }
    }
    
    private func axesView(size: CGSize) -> some View {
        let yLabels = calculateYAxisLabels(values: data)
        return ZStack {
            // Y-axis
            Path { path in
                path.move(to: CGPoint(x: chartPadding, y: chartPadding))
                path.addLine(to: CGPoint(x: chartPadding, y: size.height - chartPadding))
            }
            .stroke(Color.secondary, lineWidth: axisLineWidth)
            
            // X-axis
            Path { path in
                path.move(to: CGPoint(x: chartPadding, y: size.height - chartPadding))
                path.addLine(to: CGPoint(x: size.width - chartPadding, y: size.height - chartPadding))
            }
            .stroke(Color.secondary, lineWidth: axisLineWidth)
            
            // Y-axis labels
            ForEach(yLabels.indices, id: \.self) { index in
                Text(yLabels[index])
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .position(x: chartPadding - 20,
                            y: size.height - chartPadding - (CGFloat(index) / CGFloat(yLabels.count - 1)) * (size.height - chartPadding * 2))
            }
        }
    }
    
    private func accessibilityDescription() -> String {
        let values = data.enumerated().map { index, value in
            "\(labels[index]): \(value)"
        }
        return values.joined(separator: ", ")
    }
}

// MARK: - PieSlice Shape
private struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center,
                   radius: radius,
                   startAngle: startAngle - .degrees(90),
                   endAngle: endAngle - .degrees(90),
                   clockwise: false)
        path.closeSubpath()
        return path
    }
}