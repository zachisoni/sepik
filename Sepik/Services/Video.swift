//
//  Video.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import UniformTypeIdentifiers
import SwiftUI

struct Video: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            // Check if source file exists and is readable
            guard FileManager.default.fileExists(atPath: received.file.path) else {
                throw NSError(domain: "VideoTransfer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Source video file not found"])
            }
            
            // Check file size to ensure it's reasonable
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: received.file.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            let fileSizeGB = Double(fileSize) / (1024 * 1024 * 1024)
            
            guard fileSizeGB <= 5.0 else {
                throw NSError(domain: "VideoTransfer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Video file is too large (max 5GB)"])
            }
            
            // Remove existing temp file if it exists
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            
            // Use a more efficient copy method for large files
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            
            // Verify the copied file
            guard FileManager.default.fileExists(atPath: tempURL.path) else {
                throw NSError(domain: "VideoTransfer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to copy video file"])
            }
            return Self(url: tempURL)
        }
    }
} 