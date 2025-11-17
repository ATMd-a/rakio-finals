//
//  OrientationManager.swift
//  Rakio
//
//  Created by STUDENT on 11/17/25.
//
//
//
//import SwiftUI
//
//class OrientationManager: ObservableObject {
//    @Published var isLandscape: Bool = false
//
//    init() {
//        updateOrientation()
//        NotificationCenter.default.addObserver(
//            forName: UIDevice.orientationDidChangeNotification,
//            object: nil,
//            queue: .main
//        ) { _ in
//            self.updateOrientation()
//        }
//    }
//
//    private func updateOrientation() {
//        let orientation = UIDevice.current.orientation
//        if orientation.isValidInterfaceOrientation {
//            isLandscape = orientation.isLandscape
//        }
//    }
//}
//
//extension UIDeviceOrientation {
//    var isValidInterfaceOrientation: Bool {
//        self == .portrait ||
//        self == .landscapeRight ||
//        self == .portraitUpsideDown||
//        self == .landscapeLeft
//  
//    }
//}
