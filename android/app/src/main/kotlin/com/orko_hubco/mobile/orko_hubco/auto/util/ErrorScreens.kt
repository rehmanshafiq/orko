package com.orko_hubco.mobile.orko_hubco.auto.util

import androidx.car.app.CarContext
import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.MessageTemplate

/**
 * Central builder for driver-safe error / empty / sign-in message templates.
 *
 * Every screen routes its failure and empty states through here so copy and
 * behavior stay consistent. Only short, human copy is shown — never raw error
 * strings, URLs, stack traces, tokens, or PII. The "auth" code is NOT rendered
 * here: callers route it to SignInRequiredScreen instead (auth = signed out).
 */
object ErrorScreens {

    /** Short, safe copy for a typed error code (excluding "auth"). */
    fun copyForCode(code: String): String = when (code) {
        "network" -> "No internet connection"
        "location" -> "Location unavailable"
        else -> "Something went wrong"
    }

    /**
     * Builds a [MessageTemplate] with a title, short message and an optional
     * single action (defaults to "Retry"). Pass [onAction] = null for a
     * message with no action.
     */
    fun message(
        carContext: CarContext,
        title: String,
        message: String,
        headerAction: Action = Action.BACK,
        actionTitle: String = "Retry",
        onAction: (() -> Unit)? = null,
    ): MessageTemplate {
        val builder = MessageTemplate.Builder(message)
            .setTitle(title)
            .setHeaderAction(headerAction)
        if (onAction != null) {
            builder.addAction(
                Action.Builder()
                    .setTitle(actionTitle)
                    .setBackgroundColor(CarColor.PRIMARY)
                    .setOnClickListener { onAction() }
                    .build()
            )
        }
        return builder.build()
    }

    /**
     * Convenience for a typed error code with a Retry action. Callers must
     * handle "auth" separately (route to sign-in) before calling this.
     */
    fun forCode(
        carContext: CarContext,
        code: String,
        title: String,
        headerAction: Action = Action.BACK,
        onRetry: () -> Unit,
    ): MessageTemplate = message(
        carContext = carContext,
        title = title,
        message = copyForCode(code),
        headerAction = headerAction,
        actionTitle = "Retry",
        onAction = onRetry,
    )
}
