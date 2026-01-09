import AppKit
import CoreGraphics
import Foundation
import UniformTypeIdentifiers

/// Generates DMG background image for Canopy installer
/// Shows drag-to-Applications visual with consistent tree theme

let width: CGFloat = 660
let height: CGFloat = 400
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "dmg-background.png"

// Create bitmap context
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: Int(width),
    height: Int(height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create graphics context")
    exit(1)
}

// Flip coordinate system
context.translateBy(x: 0, y: height)
context.scaleBy(x: 1, y: -1)

// Background gradient - subtle forest theme matching app icon
let gradientColors = [
    CGColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0),  // Dark slate
    CGColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 1.0)   // Darker
] as CFArray
let gradientLocations: [CGFloat] = [0.0, 1.0]
guard let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: gradientLocations) else {
    print("Failed to create gradient")
    exit(1)
}

context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: 0, y: height),
    options: []
)

// Draw subtle decorative branches in background
func drawDecorativeBranch(from start: CGPoint, to end: CGPoint, width: CGFloat, alpha: CGFloat) {
    context.saveGState()
    let branchColor = CGColor(red: 0.3, green: 0.5, blue: 0.45, alpha: alpha)
    context.setStrokeColor(branchColor)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.beginPath()
    context.move(to: start)
    context.addLine(to: end)
    context.strokePath()
    context.restoreGState()
}

// Subtle background branches
drawDecorativeBranch(from: CGPoint(x: 0, y: 380), to: CGPoint(x: 120, y: 320), width: 3, alpha: 0.08)
drawDecorativeBranch(from: CGPoint(x: 120, y: 320), to: CGPoint(x: 80, y: 260), width: 2, alpha: 0.06)
drawDecorativeBranch(from: CGPoint(x: 120, y: 320), to: CGPoint(x: 180, y: 280), width: 2, alpha: 0.06)

drawDecorativeBranch(from: CGPoint(x: 660, y: 350), to: CGPoint(x: 540, y: 290), width: 3, alpha: 0.08)
drawDecorativeBranch(from: CGPoint(x: 540, y: 290), to: CGPoint(x: 580, y: 230), width: 2, alpha: 0.06)
drawDecorativeBranch(from: CGPoint(x: 540, y: 290), to: CGPoint(x: 480, y: 250), width: 2, alpha: 0.06)

// Draw arrow from app position to Applications position
// App at x=180, Applications at x=480, both at y=170 (in DMG coords, which is y=230 in our flipped system)
let arrowY: CGFloat = 230
let arrowStartX: CGFloat = 240  // After app icon
let arrowEndX: CGFloat = 420    // Before Applications folder

let arrowColor = CGColor(red: 0.6, green: 0.75, blue: 0.7, alpha: 0.6)
context.setStrokeColor(arrowColor)
context.setLineWidth(3)
context.setLineCap(.round)

// Arrow shaft (curved)
context.beginPath()
context.move(to: CGPoint(x: arrowStartX, y: arrowY))

// Gentle curve
let controlY = arrowY - 20
context.addQuadCurve(
    to: CGPoint(x: arrowEndX, y: arrowY),
    control: CGPoint(x: (arrowStartX + arrowEndX) / 2, y: controlY)
)
context.strokePath()

// Arrow head
context.beginPath()
context.move(to: CGPoint(x: arrowEndX - 15, y: arrowY - 10))
context.addLine(to: CGPoint(x: arrowEndX, y: arrowY))
context.addLine(to: CGPoint(x: arrowEndX - 15, y: arrowY + 10))
context.strokePath()

// Add text labels
func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, color: CGColor, centered: Bool = true) {
    let font = CTFontCreateWithName("SF Pro Display" as CFString, fontSize, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: color)!
    ]
    let attributedString = NSAttributedString(string: text, attributes: attributes)
    let line = CTLineCreateWithAttributedString(attributedString)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

    context.saveGState()
    context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)

    var x = point.x
    if centered {
        x -= bounds.width / 2
    }

    context.textPosition = CGPoint(x: x, y: point.y)
    CTLineDraw(line, context)
    context.restoreGState()
}

// Instructional text at bottom
let textColor = CGColor(red: 0.7, green: 0.75, blue: 0.73, alpha: 0.9)
drawText("Drag Canopy to Applications to install", at: CGPoint(x: width / 2, y: 340), fontSize: 14, color: textColor)

// Subtitle
let subtitleColor = CGColor(red: 0.5, green: 0.55, blue: 0.53, alpha: 0.7)
drawText("Git worktree manager for macOS", at: CGPoint(x: width / 2, y: 365), fontSize: 11, color: subtitleColor)

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
    print("DMG background saved to: \(outputPath)")
} else {
    print("Failed to save image")
    exit(1)
}
