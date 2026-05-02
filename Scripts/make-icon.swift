#!/usr/bin/env swift

import AppKit
import Foundation

// Usage:
//   swift Scripts/make-icon.swift preview
//      → écrit /tmp/mdv-icon-preview.png en 1024x1024 puis ouvre Preview.app
//   swift Scripts/make-icon.swift all <output-dir>
//      → écrit les 10 tailles requises par macOS dans <output-dir>

struct IconStyle {
    let topColor: NSColor
    let bottomColor: NSColor
    let textColor: NSColor
    let fontWeight: NSFont.Weight
    let cornerRadiusFactor: CGFloat
    let fontSizeFactor: CGFloat
    let kerningFactor: CGFloat
    let shadowOpacity: CGFloat

    static let indigo = IconStyle(
        topColor: NSColor(red: 0.42, green: 0.36, blue: 0.97, alpha: 1.0),
        bottomColor: NSColor(red: 0.18, green: 0.13, blue: 0.55, alpha: 1.0),
        textColor: NSColor.white,
        fontWeight: .heavy,
        cornerRadiusFactor: 0.225,
        fontSizeFactor: 0.42,
        kerningFactor: -0.012,
        shadowOpacity: 0.18
    )
}

func renderIcon(size: Int, style: IconStyle) -> Data? {
    let s = CGFloat(size)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ),
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    else { return nil }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = context

    let ctx = context.cgContext
    ctx.setShouldAntialias(true)
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    // 1. Squircle (rounded rect façon macOS, pas le superellipse exact mais visuellement très proche)
    let radius = s * style.cornerRadiusFactor
    let bgPath = NSBezierPath(
        roundedRect: NSRect(x: 0, y: 0, width: s, height: s),
        xRadius: radius,
        yRadius: radius
    )

    // 2. Gradient vertical
    if let gradient = NSGradient(colors: [style.topColor, style.bottomColor]) {
        gradient.draw(in: bgPath, angle: -90)
    } else {
        style.bottomColor.setFill()
        bgPath.fill()
    }

    // 3. Subtil highlight en haut (effet glossy léger)
    let highlightPath = NSBezierPath(
        roundedRect: NSRect(x: s * 0.04, y: s * 0.55, width: s * 0.92, height: s * 0.4),
        xRadius: radius * 0.7,
        yRadius: radius * 0.7
    )
    if let highlight = NSGradient(colors: [
        NSColor(white: 1.0, alpha: 0.10),
        NSColor(white: 1.0, alpha: 0.0)
    ]) {
        highlight.draw(in: highlightPath, angle: -90)
    }

    // 4. Texte "M↓" — caractère Unicode rendu en SF Heavy
    let fontSize = s * style.fontSizeFactor
    let font = NSFont.systemFont(ofSize: fontSize, weight: style.fontWeight)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: style.shadowOpacity)
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.005)
    shadow.shadowBlurRadius = s * 0.015

    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: style.textColor,
        .kern: s * style.kerningFactor,
        .shadow: shadow
    ]
    let text = NSAttributedString(string: "M↓", attributes: attrs)
    let textSize = text.size()
    let textRect = NSRect(
        x: (s - textSize.width) / 2,
        y: (s - textSize.height) / 2 - s * 0.025,
        width: textSize.width,
        height: textSize.height
    )
    text.draw(in: textRect)

    return bitmap.representation(using: .png, properties: [:])
}

func write(data: Data, to path: String) {
    try? data.write(to: URL(fileURLWithPath: path))
}

// Tailles requises par macOS AppIcon (idiom mac)
let macIcons: [(size: Int, scale: Int, render: Int)] = [
    (16, 1, 16), (16, 2, 32),
    (32, 1, 32), (32, 2, 64),
    (128, 1, 128), (128, 2, 256),
    (256, 1, 256), (256, 2, 512),
    (512, 1, 512), (512, 2, 1024)
]

// Tailles requises par iOS / iPadOS AppIcon (idiom universal)
// Format moderne (Xcode 14+) : un seul "iOS Marketing" 1024 1x universal
// + le runtime synthétise les tailles en interne. On garde aussi les classiques
// pour compatibilité avec les anciennes versions d'iOS et la fiabilité.
let iosIcons: [(size: String, scale: Int, render: Int, idiom: String)] = [
    ("1024x1024", 1, 1024, "universal")
]

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("Usage: swift Scripts/make-icon.swift {preview | all <output-dir>}")
    exit(1)
}

switch args[1] {
case "preview":
    let path = "/tmp/mdv-icon-preview.png"
    guard let data = renderIcon(size: 1024, style: .indigo) else {
        print("✗ render failed"); exit(1)
    }
    write(data: data, to: path)
    print("✓ \(path)")
    NSWorkspace.shared.open(URL(fileURLWithPath: path))

case "all":
    guard args.count >= 3 else {
        print("Usage: swift Scripts/make-icon.swift all <output-dir>"); exit(1)
    }
    let outDir = args[2]
    try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

    var images: [[String: String]] = []

    for (idiomSize, scale, renderSize) in macIcons {
        let suffix = scale == 1 ? "" : "@\(scale)x"
        let name = "icon_\(idiomSize)x\(idiomSize)\(suffix).png"
        guard let data = renderIcon(size: renderSize, style: .indigo) else { continue }
        write(data: data, to: "\(outDir)/\(name)")
        images.append([
            "filename": name,
            "idiom": "mac",
            "scale": "\(scale)x",
            "size": "\(idiomSize)x\(idiomSize)"
        ])
        print("✓ \(name)  (\(renderSize)x\(renderSize))")
    }

    for (size, scale, renderSize, idiom) in iosIcons {
        let suffix = scale == 1 ? "" : "@\(scale)x"
        let cleanSize = size.replacingOccurrences(of: "x", with: "_")
        let name = "icon_ios_\(cleanSize)\(suffix).png"
        guard let data = renderIcon(size: renderSize, style: .indigo) else { continue }
        write(data: data, to: "\(outDir)/\(name)")
        images.append([
            "filename": name,
            "idiom": idiom,
            "platform": "ios",
            "scale": "\(scale)x",
            "size": size
        ])
        print("✓ \(name)  (\(renderSize)x\(renderSize), iOS)")
    }

    // Génère un Contents.json compatible Asset Catalog
    let json: [String: Any] = [
        "images": images,
        "info": ["author": "xcode", "version": 1]
    ]
    if let data = try? JSONSerialization.data(
        withJSONObject: json, options: [.prettyPrinted, .sortedKeys]
    ) {
        write(data: data, to: "\(outDir)/Contents.json")
        print("✓ Contents.json (\(images.count) images)")
    }

default:
    print("Unknown mode \(args[1])"); exit(1)
}
