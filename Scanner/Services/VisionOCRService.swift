//
//  VisionOCRService.swift
//  Scanner
//
//  Created on 12/2/25.
//

import Foundation
import Vision
import UIKit

actor VisionOCRService {

    /// Recognize text from an image using Apple Vision framework
    /// - Parameter image: The UIImage to process
    /// - Returns: Recognized text as a string
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                // Extract text from observations, preserving line breaks
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                if recognizedText.isEmpty {
                    continuation.resume(throwing: ScannerError.ocrFailed)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }

            // Configure request for optimal receipt scanning
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            // iOS 16+ feature: automatic language detection
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            // Perform OCR on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Recognize text with detailed information including confidence and bounding boxes
    /// - Parameter image: The UIImage to process
    /// - Returns: Array of RecognizedTextBlock with detailed information
    func recognizeTextDetailed(from image: UIImage) async throws -> [RecognizedTextBlock] {
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }

        let imageSize = image.size

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                var results: [RecognizedTextBlock] = []

                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }

                    // Convert Vision coordinates to UIKit coordinates
                    let boundingBox = VNImageRectForNormalizedRect(
                        observation.boundingBox,
                        Int(imageSize.width),
                        Int(imageSize.height)
                    )

                    let block = RecognizedTextBlock(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: boundingBox
                    )

                    results.append(block)
                }

                continuation.resume(returning: results)
            }

            // Configure request
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Preprocess image for better OCR results
    /// - Parameter image: Original UIImage
    /// - Returns: Preprocessed UIImage
    func preprocessImage(_ image: UIImage) -> UIImage {
        // For now, return the original image
        // In production, you could add contrast enhancement, denoising, etc.
        return image
    }
}
