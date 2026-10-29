import AppKit

let inputPath = "/Users/salehorod/.gemini/antigravity/brain/ba6826d2-1242-4f20-bf27-bd7e8fc68c0d/rarflow_app_icon_1793304915881.jpg"
guard let sourceImage = NSImage(contentsOfFile: inputPath) else {
    print("Failed to load source image")
    exit(1)
}

let fm = FileManager.default
let assetsDir = URL(fileURLWithPath: "docs/assets")
let buildDir = URL(fileURLWithPath: "build")
let iconsetDir = buildDir.appendingPathComponent("AppIcon.iconset")

try? fm.createDirectory(at: assetsDir, withIntermediateDirectories: true)
try? fm.removeItem(at: iconsetDir)
try? fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

// 1. Create a 1024x1024 transparent canvas with rounded squircle mask and subtle rim
let canvasSize = NSSize(width: 1024, height: 1024)
let maskedImage = NSImage(size: canvasSize)
maskedImage.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    print("Failed to get graphics context")
    exit(1)
}

// Apple macOS squircle dimensions: 824x824 placed at (100, 100)
let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Draw subtle drop shadow behind the squircle
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 36, color: NSColor.black.withAlphaComponent(0.45).cgColor)
ctx.addPath(squirclePath)
ctx.setFillColor(NSColor.black.cgColor)
ctx.fillPath()
ctx.restoreGState()

// Clip to squircle and draw the high-res 3D icon
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.clip()
sourceImage.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
ctx.restoreGState()

// Draw subtle glassy border highlight around the rim
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.setLineWidth(4)
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.3).cgColor)
ctx.strokePath()
ctx.restoreGState()

maskedImage.unlockFocus()

// Save high-res PNG to docs/assets/icon.png
if let tiff = maskedImage.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    let iconPNGPath = assetsDir.appendingPathComponent("icon.png")
    try! png.write(to: iconPNGPath)
    print("Saved docs/assets/icon.png")
}

// Generate iconset
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
    maskedImage.draw(in: NSRect(x: 0, y: 0, width: px, height: px), from: .zero, operation: .sourceOver, fraction: 1.0)
    resized.unlockFocus()

    if let tiff = resized.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let dest = iconsetDir.appendingPathComponent(filename)
        try! png.write(to: dest)
    }
}

print("Iconset created successfully.")
