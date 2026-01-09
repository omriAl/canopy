import AppKit
import CoreGraphics
import Foundation
import UniformTypeIdentifiers

/// Generates a layered canopy icon for Canopy
/// The design represents multiple tree crowns seen from above - a bird's eye view of a forest canopy
/// Each crown represents a worktree in the git worktree metaphor

let size: CGFloat = 1024
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon_1024x1024.png"

// Create bitmap context
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create graphics context")
    exit(1)
}

// Flip coordinate system for easier drawing (origin at top-left)
context.translateBy(x: 0, y: size)
context.scaleBy(x: 1, y: -1)

// Background - rounded rectangle with gradient
let cornerRadius: CGFloat = size * 0.22
let backgroundRect = CGRect(x: 0, y: 0, width: size, height: size)
let roundedPath = CGPath(roundedRect: backgroundRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Gradient background - deep forest tones
let gradientColors = [
    CGColor(red: 0.078, green: 0.196, blue: 0.176, alpha: 1.0),  // Dark forest
    CGColor(red: 0.098, green: 0.255, blue: 0.220, alpha: 1.0)   // Slightly lighter forest
] as CFArray
let gradientLocations: [CGFloat] = [0.0, 1.0]
guard let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: gradientLocations) else {
    print("Failed to create gradient")
    exit(1)
}

context.saveGState()
context.addPath(roundedPath)
context.clip()
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: size, y: size),
    options: []
)
context.restoreGState()

// Helper function to draw an organic blob shape (tree crown from above)
// Uses bezier curves to create a natural, slightly irregular circular shape
func drawOrganicBlob(
    center: CGPoint,
    radiusX: CGFloat,
    radiusY: CGFloat,
    irregularity: CGFloat,
    fillColor: CGColor,
    highlightColor: CGColor? = nil
) {
    context.saveGState()

    // Create organic blob path using bezier curves with slight variations
    let path = CGMutablePath()
    let points = 8  // Number of control points around the shape
    var controlPoints: [(point: CGPoint, controlIn: CGPoint, controlOut: CGPoint)] = []

    // Generate points around the shape with slight irregularity
    for i in 0..<points {
        let angle = (CGFloat(i) / CGFloat(points)) * 2 * .pi

        // Add slight random-ish variation based on index for reproducibility
        let variation = 1.0 + irregularity * sin(CGFloat(i * 3 + 1) * 1.7)
        let rx = radiusX * variation
        let ry = radiusY * variation

        let x = center.x + cos(angle) * rx
        let y = center.y + sin(angle) * ry

        // Control points for smooth bezier curves
        let controlRadius: CGFloat = 0.55  // Approximates a circle with bezier
        let controlInAngle = angle - .pi / CGFloat(points)
        let controlOutAngle = angle + .pi / CGFloat(points)

        let controlIn = CGPoint(
            x: x - cos(controlInAngle) * rx * controlRadius / CGFloat(points) * .pi,
            y: y - sin(controlInAngle) * ry * controlRadius / CGFloat(points) * .pi
        )
        let controlOut = CGPoint(
            x: x + cos(controlOutAngle) * rx * controlRadius / CGFloat(points) * .pi,
            y: y + sin(controlOutAngle) * ry * controlRadius / CGFloat(points) * .pi
        )

        controlPoints.append((CGPoint(x: x, y: y), controlIn, controlOut))
    }

    // Build the path
    path.move(to: controlPoints[0].point)
    for i in 0..<points {
        let current = controlPoints[i]
        let next = controlPoints[(i + 1) % points]
        path.addCurve(
            to: next.point,
            control1: current.controlOut,
            control2: next.controlIn
        )
    }
    path.closeSubpath()

    // Fill with base color
    context.addPath(path)
    context.setFillColor(fillColor)
    context.fillPath()

    // Add radial gradient highlight for depth
    if let highlight = highlightColor {
        context.saveGState()
        context.addPath(path)
        context.clip()

        let highlightColors = [
            highlight,
            highlight.copy(alpha: 0.0)!
        ] as CFArray
        let highlightLocations: [CGFloat] = [0.0, 1.0]

        if let highlightGradient = CGGradient(colorsSpace: colorSpace, colors: highlightColors, locations: highlightLocations) {
            // Offset highlight toward upper-left for natural lighting
            let highlightCenter = CGPoint(x: center.x - radiusX * 0.2, y: center.y - radiusY * 0.2)
            context.drawRadialGradient(
                highlightGradient,
                startCenter: highlightCenter,
                startRadius: 0,
                endCenter: center,
                endRadius: max(radiusX, radiusY),
                options: []
            )
        }
        context.restoreGState()
    }

    context.restoreGState()
}

// Draw subtle shadow/glow beneath the whole canopy cluster
func drawShadow(at center: CGPoint, radius: CGFloat) {
    context.saveGState()

    let shadowColors = [
        CGColor(red: 0.0, green: 0.1, blue: 0.08, alpha: 0.3),
        CGColor(red: 0.0, green: 0.1, blue: 0.08, alpha: 0.0)
    ] as CFArray
    let shadowLocations: [CGFloat] = [0.0, 1.0]

    if let shadowGradient = CGGradient(colorsSpace: colorSpace, colors: shadowColors, locations: shadowLocations) {
        context.drawRadialGradient(
            shadowGradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: []
        )
    }

    context.restoreGState()
}

// Add ambient glow behind the canopy for depth
let canopyCenter = CGPoint(x: size * 0.5, y: size * 0.52)
drawShadow(at: CGPoint(x: canopyCenter.x + size * 0.02, y: canopyCenter.y + size * 0.03), radius: size * 0.45)

// Crown colors - from back (darkest) to front (brightest)
let crown1Color = CGColor(red: 0.137, green: 0.333, blue: 0.275, alpha: 1.0)  // Deep forest
let crown2Color = CGColor(red: 0.216, green: 0.490, blue: 0.392, alpha: 1.0)  // Forest green
let crown3Color = CGColor(red: 0.353, green: 0.647, blue: 0.510, alpha: 1.0)  // Bright sage
let crown4Color = CGColor(red: 0.549, green: 0.784, blue: 0.667, alpha: 1.0)  // Light mint

// Highlight colors for inner glow
let highlight1 = CGColor(red: 0.2, green: 0.4, blue: 0.35, alpha: 0.3)
let highlight2 = CGColor(red: 0.3, green: 0.55, blue: 0.45, alpha: 0.35)
let highlight3 = CGColor(red: 0.45, green: 0.7, blue: 0.58, alpha: 0.4)
let highlight4 = CGColor(red: 0.65, green: 0.85, blue: 0.75, alpha: 0.45)

// Draw crowns from back to front (painter's algorithm)

// Crown 1: Back layer - largest, center-bottom
drawOrganicBlob(
    center: CGPoint(x: size * 0.48, y: size * 0.58),
    radiusX: size * 0.28,
    radiusY: size * 0.26,
    irregularity: 0.08,
    fillColor: crown1Color,
    highlightColor: highlight1
)

// Crown 2: Middle-left layer
drawOrganicBlob(
    center: CGPoint(x: size * 0.35, y: size * 0.42),
    radiusX: size * 0.22,
    radiusY: size * 0.20,
    irregularity: 0.07,
    fillColor: crown2Color,
    highlightColor: highlight2
)

// Crown 3: Middle-right layer
drawOrganicBlob(
    center: CGPoint(x: size * 0.62, y: size * 0.40),
    radiusX: size * 0.21,
    radiusY: size * 0.19,
    irregularity: 0.09,
    fillColor: crown3Color,
    highlightColor: highlight3
)

// Crown 4: Front accent - small, bright, top-center
drawOrganicBlob(
    center: CGPoint(x: size * 0.50, y: size * 0.32),
    radiusX: size * 0.13,
    radiusY: size * 0.12,
    irregularity: 0.06,
    fillColor: crown4Color,
    highlightColor: highlight4
)

// Add a subtle outer glow around the whole canopy cluster for polish
func drawOuterGlow() {
    context.saveGState()

    let glowColors = [
        CGColor(red: 0.4, green: 0.65, blue: 0.55, alpha: 0.0),
        CGColor(red: 0.3, green: 0.5, blue: 0.4, alpha: 0.08),
        CGColor(red: 0.2, green: 0.35, blue: 0.28, alpha: 0.0)
    ] as CFArray
    let glowLocations: [CGFloat] = [0.0, 0.5, 1.0]

    if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: glowLocations) {
        context.drawRadialGradient(
            glowGradient,
            startCenter: canopyCenter,
            startRadius: size * 0.25,
            endCenter: canopyCenter,
            endRadius: size * 0.5,
            options: []
        )
    }

    context.restoreGState()
}

drawOuterGlow()

// Create image from context
guard let image = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

// Save as PNG
let url = URL(fileURLWithPath: outputPath)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    print("Failed to create image destination")
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)

if CGImageDestinationFinalize(destination) {
    print("Icon saved to: \(outputPath)")
} else {
    print("Failed to save image")
    exit(1)
}
