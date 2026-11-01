package com.orko_hubco.integrity

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityException
import com.google.android.play.core.integrity.StandardIntegrityManager
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode

/** Error reported back over the channel. [code] is the Play error code number when known. */
internal data class IntegrityError(val code: String, val message: String?)

/**
 * Process-wide Play Integrity standard-request token source.
 *
 * - The provider is prepared once and shared by every engine; concurrent
 *   callers wait on a single in-flight preparation.
 * - A token is requested per call, never cached (the backend rejects tokens
 *   older than 5 minutes).
 * - `INTEGRITY_TOKEN_PROVIDER_INVALID` re-prepares and retries once.
 * - A failed preparation (no Play Store / Play services, API unavailable,
 *   network) is not retried for [PREPARE_COOLDOWN_MS], so a device that can
 *   never produce a token doesn't pay a slow preparation on every request.
 *
 * All state is touched only on the main thread: channel calls arrive there and
 * Play's Task listeners fire there by default.
 */
internal class PlayIntegrityTokenSource private constructor(context: Context) {
    private val manager: StandardIntegrityManager = IntegrityManagerFactory.createStandard(context)
    private val main = Handler(Looper.getMainLooper())

    private var provider: StandardIntegrityTokenProvider? = null
    private var preparedFor: Long? = null
    private var waiters: MutableList<(IntegrityError?) -> Unit>? = null
    private var lastPrepareFailure: IntegrityError? = null
    private var lastPrepareFailureAt = 0L

    fun prepare(projectNumber: Long, done: (IntegrityError?) -> Unit): Unit = onMain {
        if (provider != null && preparedFor == projectNumber) return@onMain done(null)

        waiters?.let { it += done; return@onMain }

        val failure = lastPrepareFailure
        if (failure != null && SystemClock.elapsedRealtime() - lastPrepareFailureAt < PREPARE_COOLDOWN_MS) {
            return@onMain done(failure)
        }

        val pending = mutableListOf(done)
        waiters = pending
        manager.prepareIntegrityToken(
            PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(projectNumber).build(),
        ).addOnSuccessListener {
            provider = it
            preparedFor = projectNumber
            lastPrepareFailure = null
            finishPrepare(pending, null)
        }.addOnFailureListener { e ->
            provider = null
            lastPrepareFailure = e.toIntegrityError()
            lastPrepareFailureAt = SystemClock.elapsedRealtime()
            finishPrepare(pending, lastPrepareFailure)
        }
    }

    fun requestToken(projectNumber: Long, done: (String?, IntegrityError?) -> Unit) {
        request(projectNumber, retryOnInvalidProvider = true, done)
    }

    private fun request(
        projectNumber: Long,
        retryOnInvalidProvider: Boolean,
        done: (String?, IntegrityError?) -> Unit,
    ): Unit = prepare(projectNumber) { prepareError ->
        val current = provider
        if (prepareError != null || current == null) {
            return@prepare done(null, prepareError ?: IntegrityError("unknown", "No provider"))
        }
        current.request(StandardIntegrityTokenRequest.builder().build())
            .addOnSuccessListener { done(it.token(), null) }
            .addOnFailureListener { e ->
                val invalid = e is StandardIntegrityException &&
                    e.errorCode == StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID
                if (invalid && retryOnInvalidProvider) {
                    // Drop only the provider that failed; another caller may have replaced it already.
                    if (provider === current) provider = null
                    request(projectNumber, retryOnInvalidProvider = false, done)
                } else {
                    done(null, e.toIntegrityError())
                }
            }
    }

    private fun finishPrepare(pending: List<(IntegrityError?) -> Unit>, error: IntegrityError?) {
        waiters = null
        pending.forEach { it(error) }
    }

    private fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else main.post(block)
    }

    private fun Exception.toIntegrityError(): IntegrityError =
        if (this is StandardIntegrityException) IntegrityError(errorCode.toString(), message)
        else IntegrityError("unknown", message)

    companion object {
        private const val PREPARE_COOLDOWN_MS = 30_000L

        @Volatile private var instance: PlayIntegrityTokenSource? = null

        fun get(context: Context): PlayIntegrityTokenSource =
            instance ?: synchronized(this) {
                instance ?: PlayIntegrityTokenSource(context.applicationContext).also { instance = it }
            }
    }
}
