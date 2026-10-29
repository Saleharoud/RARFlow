import AppKit

func createIcon() -> NSImage {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // 1. Draw rounded squircle background
    let rect = CGRect(x: 80, y: 80, width: 864, height: 864)
    let path = CGPath(roundedRect: rect, cornerWidth: 190, cornerHeight: 190, transform: nil)

    // Gradient background: Deep Purple / Royal Blue to Indigo
    let colors = [
        NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.85, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.38, green: 0.15, blue: 0.78, alpha: 1.0).cgColor
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 944), end: CGPoint(x: 512, y: 80), options: [])
        ctx.restoreGState()
    }

    // Inner subtle border highlight
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setLineWidth(8)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    // 2. Draw Archive / Books / Zipper graphic using SF Symbols
    if let symbol = NSImage(systemSymbolName: "archivebox.fill", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: 420, weight: .semibold)
        if let configured = symbol.withSymbolConfiguration(config) {
            let symbolRect = NSRect(x: 232, y: 260, width: 560, height: 500)
            configured.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }

    // 3. Draw "RARFlow" text banner badge at bottom
    let text = "RARFlow" as NSString
    let font = NSFont.systemFont(ofSize: 76, weight: .black)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .shadow: {
            let s = NSShadow()
            s.shadowBlurRadius = 12
            s.shadowOffset = NSSize(width: 0, height: -4)
            s.shadowColor = NSColor.black.withAlphaComponent(0.4)
            return s
        }()
    ]
    let textSize = text.size(withAttributes: attrs)
    let textRect = CGRect(x: (1024 - textSize.width) / 2, y: 150, width: textSize.width, height: textSize.height)
    text.draw(in: textRect, withAttributes: attrs)

    image.unlockFocus()
    return image
}

let image = createIcon()
let fm = FileManager.default
let iconsetDir = URL(fileURLWithPath: "build/AppIcon.iconset")
try? fm.removeItem(at: iconsetDir)
try! fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, Int, String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png")
]

for (pt, scale, filename) in sizes {
    let px = pt * scale
    let resized = NSImage(size: NSSize(width: px, height: px))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: px, height: px), from: .zero, operation: .sourceOver, fraction: 1.0)
    resized.unlockFocus()

    if let tiff = resized.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let dest = iconsetDir.appendingPathComponent(filename)
        try! png.write(to: dest)
    }
}

print("Iconset created successfully.")
