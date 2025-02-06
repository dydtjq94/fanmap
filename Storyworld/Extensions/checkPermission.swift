//
//  checkPermission.swift
//  Storyworld
//
//  Created by peter on 2/6/25.
//


import AVFoundation
import Photos

enum PermissionType {
    case camera
    case photoLibrary
}

func checkPermission(for type: PermissionType, completion: @escaping (Bool) -> Void) {
    switch type {
    case .camera:
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }

    case .photoLibrary:
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        switch photoStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}
