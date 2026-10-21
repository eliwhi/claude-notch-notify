// Turns a screen recording into a looping GIF using macOS's built-in AVFoundation and ImageIO.
//
// Run: swift scripts/make-gif.swift <input.mov> <output.gif> [fps=15] [width=original] [start=0] [end=duration]

import AVFoundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage: swift scripts/make-gif.swift <input.mov> <output.gif> [fps=15] [width] [start] [end]")
    exit(1)
}
let input = URL(fileURLWithPath: args[1])
let output = URL(fileURLWithPath: args[2])
let fps = args.count > 3 ? (Double(args[3]) ?? 15) : 15
let width = args.count > 4 ? Double(args[4]).flatMap { $0 > 0 ? $0 : nil } : nil // 0 keeps the original width

let asset = AVURLAsset(url: input)
let length = CMTimeGetSeconds(asset.duration)
let start = args.count > 5 ? (Double(args[5]) ?? 0) : 0
let end = args.count > 6 ? min(Double(args[6]) ?? length, length) : length
let duration = end - start
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
if let width {
    generator.maximumSize = CGSize(width: width, height: 10_000)
}

let frameCount = Int(duration * fps)
guard let dest = CGImageDestinationCreateWithURL(output as CFURL, UTType.gif.identifier as CFString, frameCount, nil) else {
    print("Couldn't create \(output.path)")
    exit(1)
}
CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
let frameProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps]] as CFDictionary

for i in 0..<frameCount {
    let time = CMTime(seconds: start + Double(i) / fps, preferredTimescale: 600)
    guard let image = try? generator.copyCGImage(at: time, actualTime: nil) else { continue }
    CGImageDestinationAddImage(dest, image, frameProps)
}
guard CGImageDestinationFinalize(dest) else {
    print("Couldn't write the GIF")
    exit(1)
}
print("wrote \(output.path): \(frameCount) frames at \(Int(fps)) fps")
