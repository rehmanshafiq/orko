package com.orko_hubco.integrity

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `orko/app_integrity` channel (Android side). Registered by
 * GeneratedPluginRegistrant in every engine; all engines share the
 * process-wide [PlayIntegrityTokenSource].
 */
class AppIntegrityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var tokenSource: PlayIntegrityTokenSource? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        tokenSource = PlayIntegrityTokenSource.get(binding.applicationContext)
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        tokenSource = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val source = tokenSource ?: return result.error("unknown", "Detached", null)
        val projectNumber = (call.argument<Any>("cloudProjectNumber") as? Number)?.toLong()

        when (call.method) {
            "prepare" -> {
                if (projectNumber == null) return result.error("invalid_input", "cloudProjectNumber", null)
                source.prepare(projectNumber) { error ->
                    if (error == null) result.success(null) else result.error(error.code, error.message, null)
                }
            }
            "requestToken" -> {
                if (projectNumber == null) return result.error("invalid_input", "cloudProjectNumber", null)
                source.requestToken(projectNumber) { token, error ->
                    if (token != null) result.success(token) else result.error(
                        error?.code ?: "unknown", error?.message, null,
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    private companion object {
        const val CHANNEL = "orko/app_integrity"
    }
}
