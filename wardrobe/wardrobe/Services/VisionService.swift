//
//  VisionService.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
import UIKit
import Vision
import CoreImage

class VisionService {
    
    // MARK: - Background Removal
    
    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = request.results?.first as? VNPixelBufferObservation else {
                    continuation.resume(throwing: VisionError.segmentationFailed)
                    return
                }
                
                do {
                    let maskedImage = try self.applyMask(to: cgImage, mask: result.pixelBuffer)
                    continuation.resume(returning: maskedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            request.qualityLevel = .balanced
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func applyMask(to image: CGImage, mask: CVPixelBuffer) throws -> UIImage {
        let ciImage = CIImage(cgImage: image)
        let maskImage = CIImage(cvPixelBuffer: mask)
        
        // Scale mask to match image size
        let scaleX = ciImage.extent.width / maskImage.extent.width
        let scaleY = ciImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Apply mask
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            throw VisionError.filterFailed
        }
        
        blendFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        
        guard let output = blendFilter.outputImage else {
            throw VisionError.filterFailed
        }
        
        let context = CIContext()
        guard let cgOutput = context.createCGImage(output, from: output.extent) else {
            throw VisionError.renderFailed
        }
        
        return UIImage(cgImage: cgOutput)
    }
    
    // MARK: - Color Detection
    
    func detectColors(in image: UIImage, maxColors: Int = 3) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }
        
        // Extract dominant colors from the original CGImage
        let colors = extractDominantColors(from: cgImage, count: maxColors)
        
        // Convert to hex strings
        return colors.map { $0.toHex() }
    }

    private func extractDominantColors(from cgImage: CGImage, count: Int) -> [UIColor] {
        // Create a bitmap context to properly handle alpha channel
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        guard let context = context else {
            return []
        }
        
        // Draw the image into our context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var colorCount: [UIColor: Int] = [:]
        
        // Sample every 5th pixel for better accuracy while maintaining performance
        for y in stride(from: 0, to: height, by: 5) {
            for x in stride(from: 0, to: width, by: 5) {
                let offset = (y * width + x) * bytesPerPixel
                
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                let a = CGFloat(pixelData[offset + 3]) / 255.0
                
                // CRITICAL: Only sample opaque pixels (from the clothing item)
                // Skip transparent pixels (background removed areas)
                if a < 0.8 {
                    continue
                }
                
                // Skip very light pixels (whites, very light grays)
                if r > 0.92 && g > 0.92 && b > 0.92 {
                    continue
                }
                
                // Skip very dark pixels (pure black, shadows)
                if r < 0.08 && g < 0.08 && b < 0.08 {
                    continue
                }
                
                let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                let quantized = quantizeColor(color)
                
                colorCount[quantized, default: 0] += 1
            }
        }
        
        // Filter out colors with very few occurrences (noise)
        let totalPixels = colorCount.values.reduce(0, +)
        let threshold = max(5, totalPixels / 100) // At least 1% of pixels
        
        let significantColors = colorCount.filter { $0.value > threshold }
        
        // Return top N colors
        return significantColors
            .sorted { $0.value > $1.value }
            .prefix(count)
            .map { $0.key }
    }

    private func quantizeColor(_ color: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Use HSB (Hue, Saturation, Brightness) for better color clustering
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &br, alpha: &a)
        
        // Quantize hue to 24 buckets (every 15 degrees)
        h = round(h * 24) / 24
        
        // Quantize saturation to 5 levels
        s = round(s * 5) / 5
        
        // Quantize brightness to 5 levels
        br = round(br * 5) / 5
        
        return UIColor(hue: h, saturation: s, brightness: br, alpha: 1.0)
    }
    
    // MARK: - Clothing Classification
    
    func classifyClothing(_ image: UIImage) async throws -> ClothingCategory {
        // For MVP, use simple heuristics based on aspect ratio
        // Later you can train a CoreML model
        
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let aspectRatio = width / height
        
        // Simple classification based on shape
        if aspectRatio > 1.5 {
            return .shoes // Wide items are likely shoes
        } else if aspectRatio < 0.7 {
            return .bottom // Tall items are likely pants
        } else if height > width * 1.2 {
            return .dress // Slightly tall could be dress
        } else {
            return .top // Default to top
        }
    }
}

// MARK: - Errors

enum VisionError: Error, LocalizedError {
    case invalidImage
    case segmentationFailed
    case filterFailed
    case renderFailed
    case classificationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .segmentationFailed:
            return "Failed to remove background"
        case .filterFailed:
            return "Failed to apply image filter"
        case .renderFailed:
            return "Failed to render image"
        case .classificationFailed:
            return "Failed to classify clothing"
        }
    }
}

// MARK: - Helper Extensions

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIColor {
    func toHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255)
        return String(format: "#%06X", rgb)
    }
}
