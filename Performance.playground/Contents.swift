import Foundation
import PlaygroundSupport
import UIKit

// MARK: - Chart

class Chart: UIView {

    // MARK: - Properties

    var isXAxisLogarithmic = false
    var isYAxisLogarithmic = false

    var canvasColor = UIColor.black
    var axisColor = UIColor.red
    var pointColors = [UIColor.green, .blue, .magenta]

    var pointSize = 3

    private let bodyPadding: CGFloat = 40
    private let labelPadding: CGFloat = 4
    private var labelWidth: CGFloat { bodyPadding - labelPadding }
    private let labelFontSize: CGFloat = 12

    private var points = [Point]()

    // MARK: - Updating

    func reset() {
        points = []
        setNeedsDisplay()
    }

    func addPoint(x: Double, y: Double, series: Int = 0) {
        points.append(Point(x: x, y: y, series: series))
        setNeedsDisplay()
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        clear(rect, context: context)

        guard !points.isEmpty else {
            return
        }

        let plotRect = rect.inset(by: .init(
            top: bodyPadding,
            left: bodyPadding,
            bottom: bodyPadding,
            right: bodyPadding))

        let points = self.points.map {
            $0.transform(
                isXAxisLogarithmic: isXAxisLogarithmic,
                isYAxisLogarithmic: isYAxisLogarithmic)
        }

        let xMin = points.min{ $0.x < $1.x }!.x
        let xMax = points.max{ $0.x < $1.x }!.x
        let yMin = points.min{ $0.y < $1.y }!.y
        let yMax = points.max{ $0.y < $1.y }!.y

        drawAxis(
            plotRect,
            context: context,
            points: points,
            xMin: xMin,
            xMax: xMax,
            yMin: yMin,
            yMax: yMax)

        drawPoints(
            plotRect,
            context: context,
            points: points,
            xMin: xMin,
            xMax: xMax,
            yMin: yMin,
            yMax: yMax)
    }

    private func clear(_ rect: CGRect, context: CGContext) {
        context.setFillColor(canvasColor.cgColor)
        context.fill(rect)
    }

    private func drawAxis(
        _ rect: CGRect,
        context: CGContext,
        points: [Point],
        xMin: Double,
        xMax: Double,
        yMin: Double,
        yMax: Double)
    {
        context.setStrokeColor(axisColor.cgColor)
        context.stroke(rect)

        if isXAxisLogarithmic && ceil(xMin) < floor(xMax) {
            context.saveGState()
            context.setLineDash(phase: 5, lengths: [5])

            for x in Int(ceil(xMin))...Int(floor(xMax)) {
                guard Double(x) > xMin && Double(x) < xMax else {
                    continue
                }

                let p1 = cgPoint(
                    for: Point(x: Double(x), y: yMin, series: 0),
                    in: rect,
                    xMin: xMin,
                    xMax: xMax,
                    yMin: yMin,
                    yMax: yMax)
                let p2 = cgPoint(
                    for: Point(x: Double(x), y: yMax, series: 0),
                    in: rect,
                    xMin: xMin,
                    xMax: xMax,
                    yMin: yMin,
                    yMax: yMax)
                context.strokeLineSegments(between: [p1, p2])

                let origin = p1.applying(.init(
                    translationX: -labelWidth / 2,
                    y: labelPadding))
                let box = CGRect(
                    origin: origin,
                    size: CGSize(width: labelWidth, height: labelWidth))
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                NSString(format: "1e%i", x).draw(in: box, withAttributes: [
                    .font: UIFont.systemFont(ofSize: labelFontSize),
                    .foregroundColor: axisColor,
                    .paragraphStyle: paragraph])
            }

            context.restoreGState()
        }

        if isYAxisLogarithmic && ceil(yMin) < floor(yMax) {
            context.saveGState()
            context.setLineDash(phase: 5, lengths: [5])

            for y in Int(ceil(yMin))...Int(floor(yMax)) {
                guard Double(y) > yMin && Double(y) < yMax else {
                    continue
                }

                let p1 = cgPoint(
                    for: Point(x: xMin, y: Double(y), series: 0),
                    in: rect,
                    xMin: xMin,
                    xMax: xMax,
                    yMin: yMin,
                    yMax: yMax)
                let p2 = cgPoint(
                    for: Point(x: xMax, y: Double(y), series: 0),
                    in: rect,
                    xMin: xMin,
                    xMax: xMax,
                    yMin: yMin,
                    yMax: yMax)
                context.strokeLineSegments(between: [p1, p2])

                let origin = p1.applying(.init(
                    translationX: -bodyPadding,
                    y: -labelFontSize / 2))
                let box = CGRect(
                    origin: origin,
                    size: CGSize(width: labelWidth, height: labelWidth))
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .right
                NSString(format: "1e%i", y).draw(in: box, withAttributes: [
                    .font: UIFont.systemFont(ofSize: labelFontSize),
                    .foregroundColor: axisColor,
                    .paragraphStyle: paragraph])
            }

            context.restoreGState()
        }
    }

    private func drawPoints(
        _ rect: CGRect,
        context: CGContext,
        points: [Point],
        xMin: Double,
        xMax: Double,
        yMin: Double,
        yMax: Double)
    {
        let offset = CGFloat(pointSize - 1) / CGFloat(2)
        let size = CGSize(width: pointSize, height: pointSize)

        for point in points {
            context.setFillColor(pointColor(forSeries: point.series))

            let origin = cgPoint(
                for: point,
                in: rect,
                xMin: xMin,
                xMax: xMax,
                yMin: yMin,
                yMax: yMax).applying(.init(translationX: -offset, y: -offset))
            context.fillEllipse(in: CGRect(origin: origin, size: size))
        }
    }

    private func cgPoint(
        for point: Point,
        in rect: CGRect,
        xMin: Double,
        xMax: Double,
        yMin: Double,
        yMax: Double) -> CGPoint
    {
        let xScale = (rect.width - CGFloat(1)) / CGFloat(xMax - xMin)
        let yScale = (rect.height - CGFloat(1)) / CGFloat(yMax - yMin)
        return CGPoint(
            x: rect.origin.x + CGFloat(point.x - xMin) * xScale,
            y: rect.origin.y + rect.size.width - CGFloat(1)
                - CGFloat(point.y - yMin) * yScale)
    }

    private func pointColor(forSeries series: Int) -> CGColor {
        return pointColors[series % pointColors.count].cgColor
    }

    // MARK: - Point

    private struct Point {
        let x: Double
        let y: Double
        let series: Int

        func transform(
            isXAxisLogarithmic: Bool,
            isYAxisLogarithmic: Bool) -> Point
        {
            return Point(
                x: isXAxisLogarithmic ? log10(x) : x,
                y: isYAxisLogarithmic ? log10(y) : y,
                series: series)
        }
    }

}

// MARK: - Timekeeper

class Timekeeper {

    // MARK: - Properties

    let chart: Chart

    // MARK: - Object Lifecycle

    init(chart: Chart) {
        self.chart = chart
    }

    // MARK: - Measurement

    func measure<T>(input: InputSpec<T>, block: @escaping (T) -> Void) {
        measure(input: input, blocks: [block])
    }

    func measure<T>(input: InputSpec<T>, blocks: [(T) -> Void]) {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            self.resetDisplay()
            var inputSize = input.minSize
            while inputSize <= input.maxSize {
                let data = input.make(inputSize)
                for (index, block) in blocks.enumerated() {
                    let t1 = Date()
                    block(data)
                    let t2 = Date()
                    self.display(
                        inputSize: inputSize,
                        timeInterval: t2.timeIntervalSince(t1),
                        series: index)
                }
                inputSize = input.step(inputSize)
            }
        }
    }

    // MARK: - Result Display

    private func resetDisplay() {
        DispatchQueue.main.sync {
            chart.reset()
        }
    }

    private func display(
        inputSize: Int,
        timeInterval: TimeInterval,
        series: Int)
    {
        DispatchQueue.main.sync {
            chart.addPoint(
                x: Double(inputSize),
                y: timeInterval,
                series: series)
        }
    }

    // MARK: - InputSpec

    struct InputSpec<T> {
        let minSize: Int
        let maxSize: Int
        let step: (Int) -> Int
        let make: (Int) -> T
    }

}

// MARK: - Chart Display

let chart = Chart(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
chart.isXAxisLogarithmic = true
chart.isYAxisLogarithmic = true
PlaygroundPage.current.liveView = chart

// MARK: - Measurements

let timekeeper = Timekeeper(chart: chart)

let input = Timekeeper.InputSpec(
    minSize: 1,
    maxSize: 1000000,
    step: { $0 * 4 }) { inputSize in
        (0..<inputSize).shuffled()
    }

timekeeper.measure(input: input, blocks: [
    { data in
        for i in 0..<data.count {
            _ = data[i] * data[i]
        }
    },
    { data in
        _ = data.sorted()
    }
])
