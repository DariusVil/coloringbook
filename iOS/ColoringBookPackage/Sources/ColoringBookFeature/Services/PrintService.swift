import SwiftUI

#if canImport(UIKit)
import UIKit

/// Service for printing coloring images via AirPrint
@MainActor
final class PrintService {

    /// Presents the print dialog for a given image
    /// - Parameters:
    ///   - image: The UIImage to print
    ///   - title: Job name for the print queue
    /// - Returns: True if printing was initiated successfully
    @discardableResult
    func printImage(_ image: UIImage, title: String) -> Bool {
        guard UIPrintInteractionController.isPrintingAvailable else {
            return false
        }

        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = title
        printInfo.outputType = .photo
        printInfo.orientation = image.size.width > image.size.height ? .landscape : .portrait

        printController.printInfo = printInfo
        printController.printingItem = image

        printController.present(animated: true) { _, completed, error in
            if let error = error {
                print("Print error: \(error.localizedDescription)")
            }
        }

        return true
    }

    /// Checks if printing is available on this device
    var isPrintingAvailable: Bool {
        UIPrintInteractionController.isPrintingAvailable
    }
}

#else

/// Stub for non-UIKit platforms
@MainActor
final class PrintService {
    @discardableResult
    func printImage(_ image: Any, title: String) -> Bool { false }
    var isPrintingAvailable: Bool { false }
}

#endif
