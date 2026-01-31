import UIKit

/// Service for printing coloring images via AirPrint
@MainActor
enum PrintService {

    /// Presents the print dialog for a given image
    @discardableResult
    static func printImage(_ image: UIImage, title: String) -> Bool {
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

        printController.present(animated: true) { _, _, error in
            if let error = error {
                print("Print error: \(error.localizedDescription)")
            }
        }

        return true
    }

    /// Checks if printing is available on this device
    static var isPrintingAvailable: Bool {
        UIPrintInteractionController.isPrintingAvailable
    }
}
