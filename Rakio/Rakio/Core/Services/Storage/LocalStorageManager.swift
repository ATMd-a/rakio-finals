//
//  LocalStorageManager.swift
//  Rakio
//
//  Created by STUDENT on 11/18/25.
//


import UIKit

/// Centralized manager for local file storage operations
final class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let fileManager = FileManager.default
    private let resourcesDirectoryName = "Resources"
    
    private init() {
        createResourcesDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func getDocumentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getResourcesDirectory() -> URL {
        getDocumentsDirectory().appendingPathComponent(resourcesDirectoryName)
    }
    
    private func createResourcesDirectoryIfNeeded() {
        let resourcesDir = getResourcesDirectory()
        
        if !fileManager.fileExists(atPath: resourcesDir.path) {
            try? fileManager.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Profile Image Operations
    @discardableResult
    func saveProfileImage(_ image: UIImage, for userId: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            return false
        }
        
        let fileURL = getResourcesDirectory().appendingPathComponent("\(userId)_profile.jpg")
        
        do {
            try data.write(to: fileURL)
            print("✅ Profile image saved successfully for user: \(userId)")
            return true
        } catch {
            print("❌ Failed to save profile image: \(error.localizedDescription)")
            return false
        }
    }

    func loadProfileImage(for userId: String) -> UIImage? {
        let fileURL = getResourcesDirectory().appendingPathComponent("\(userId)_profile.jpg")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ Profile image not found for user: \(userId)")
            return nil
        }
        
        guard let image = UIImage(contentsOfFile: fileURL.path) else {
            print("❌ Failed to load image from file for user: \(userId)")
            return nil
        }
        
        print("✅ Profile image loaded successfully for user: \(userId)")
        return image
    }

    @discardableResult
    func deleteProfileImage(for userId: String) -> Bool {
        let fileURL = getResourcesDirectory().appendingPathComponent("\(userId)_profile.jpg")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ No profile image to delete for user: \(userId)")
            return true
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("✅ Profile image deleted for user: \(userId)")
            return true
        } catch {
            print("❌ Failed to delete profile image: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Generic File Operations

    @discardableResult
    func saveData(_ data: Data, filename: String) -> Bool {
        let fileURL = getResourcesDirectory().appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Data saved successfully: \(filename)")
            return true
        } catch {
            print("❌ Failed to save data: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Loads data from a file in the resources directory
    func loadData(filename: String) -> Data? {
        let fileURL = getResourcesDirectory().appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ File not found: \(filename)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            print("✅ Data loaded successfully: \(filename)")
            return data
        } catch {
            print("❌ Failed to load data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Deletes a file from the resources directory
    @discardableResult
    func deleteFile(filename: String) -> Bool {
        let fileURL = getResourcesDirectory().appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ No file to delete: \(filename)")
            return true
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("✅ File deleted: \(filename)")
            return true
        } catch {
            print("❌ Failed to delete file: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Checks if a file exists in the resources directory
    func fileExists(filename: String) -> Bool {
        let fileURL = getResourcesDirectory().appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Gets the URL for a file in the resources directory
    func fileURL(for filename: String) -> URL {
        getResourcesDirectory().appendingPathComponent(filename)
    }
}
