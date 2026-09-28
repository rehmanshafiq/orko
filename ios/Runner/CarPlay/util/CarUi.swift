import CarPlay
import UIKit

/// Stand-in for androidx CarToast, which CarPlay has no equivalent of: a
/// one-line alert that dismisses itself after a short delay.
@MainActor
enum CarToast {
    private static let duration: TimeInterval = 2

    static func show(_ text: String, on screenManager: CarScreenManager) {
        let ic = screenManager.interfaceController
        guard ic.presentedTemplate == nil else { return }
        let alert = CPAlertTemplate(
            titleVariants: [text],
            actions: [CPAlertAction(title: "OK", style: .cancel) { _ in
                ic.dismissTemplate(animated: true, completion: nil)
            }]
        )
        ic.presentTemplate(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if ic.presentedTemplate === alert {
                ic.dismissTemplate(animated: true, completion: nil)
            }
        }
    }
}

/// Number / distance formatting shared by the car screens.
enum CarFormat {
    /// "12" for whole numbers, otherwise one decimal ("12.5"), US locale.
    static func trimNum(_ d: Double) -> String {
        d == d.rounded() && abs(d) < 1e15
            ? String(Int64(d))
            : String(format: "%.1f", locale: Locale(identifier: "en_US"), d)
    }

    /// Android renders distance through a DistanceSpan so the host localises
    /// the unit; MeasurementFormatter does the same here (km or mi per locale).
    static func distance(km: Double) -> String {
        let f = MeasurementFormatter()
        f.unitOptions = .naturalScale
        f.unitStyle = .medium
        f.numberFormatter.maximumFractionDigits = 1
        return f.string(from: Measurement(value: km, unit: UnitLength.kilometers))
    }
}

/// Map pins for the nearby-stations template: a coloured disc carrying the
/// station's rank, so pin "2" matches list row 2 (as on Android).
enum StationPin {
    private static let size = CGSize(width: 30, height: 30)

    static func image(label: String, color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            let circle = UIBezierPath(ovalIn: rect)
            color.setFill()
            circle.fill()
            UIColor.white.setStroke()
            circle.lineWidth = 2
            circle.stroke()

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.white,
            ]
            let text = NSAttributedString(string: label, attributes: attrs)
            let t = text.size()
            text.draw(at: CGPoint(x: (size.width - t.width) / 2, y: (size.height - t.height) / 2))
        }
    }
}
