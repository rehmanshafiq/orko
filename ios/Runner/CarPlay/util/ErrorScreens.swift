import CarPlay

/// Central builder for driver-safe error / empty / sign-in message content —
/// the CarPlay counterpart of ErrorScreens.kt. Android's MessageTemplate maps
/// to a CPInformationTemplate (title, one message line, optional single
/// action).
///
/// Only short, human copy is shown — never raw error strings, URLs, stack
/// traces, tokens, or PII. The "auth" code is NOT rendered here: callers route
/// it to SignInRequiredScreen instead.
@MainActor
enum ErrorScreens {

    /// Short, safe copy for a typed error code (excluding "auth").
    static func copyForCode(_ code: String) -> String {
        switch code {
        case "network": return "No internet connection"
        case "location": return "Location unavailable"
        default: return "Something went wrong"
        }
    }

    /// A new message template (for screens that swap to it, like the root).
    static func message(
        title: String,
        message: String,
        actionTitle: String = "Retry",
        onAction: (() -> Void)?
    ) -> CPInformationTemplate {
        let t = CPInformationTemplate(title: title, layout: .leading, items: [], actions: [])
        apply(to: t, title: title, message: message, actionTitle: actionTitle, onAction: onAction)
        return t
    }

    /// Renders a message into an existing template in place. Pass
    /// [onAction] = nil for a message with no action.
    static func apply(
        to template: CPInformationTemplate,
        title: String,
        message: String,
        actionTitle: String = "Retry",
        onAction: (() -> Void)?
    ) {
        template.title = title
        template.items = [CPInformationItem(title: message, detail: nil)]
        template.actions = onAction.map { action in
            [CPTextButton(title: actionTitle, textStyle: .confirm) { _ in action() }]
        } ?? []
    }

    /// Convenience for a typed error code with a Retry action. Callers must
    /// handle "auth" separately (route to sign-in) before calling this.
    static func apply(
        to template: CPInformationTemplate,
        code: String,
        title: String,
        onRetry: @escaping () -> Void
    ) {
        apply(to: template, title: title, message: copyForCode(code), onAction: onRetry)
    }

    /// The loading state of an information template (Android: `setLoading(true)`,
    /// which CarPlay has no equivalent for).
    static func applyLoading(to template: CPInformationTemplate, title: String, actions: [CPTextButton] = []) {
        template.title = title
        template.items = [CPInformationItem(title: "Loading…", detail: nil)]
        template.actions = actions
    }
}
