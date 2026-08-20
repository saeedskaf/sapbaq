package com.albairakgroup.sapbaq

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth so the
// biometric prompt can attach to a FragmentActivity.
class MainActivity : FlutterFragmentActivity() {

    // Lets Dart raise FLAG_SECURE for the duration of a payment. Flutter has no
    // built-in for this, and every package that wraps it is a whole native
    // dependency for four lines of Kotlin — so it lives here.
    //
    // FLAG_SECURE keeps the window out of screenshots, screen recordings and the
    // task-switcher thumbnail: the places a card number would otherwise be
    // captured by screen-recording malware or simply read over a shoulder. It is
    // raised only while a payment surface is up, because applying it app-wide
    // would stop customers screenshotting their own orders — which they do.
    private val secureChannel = "sapbaq/secure_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, secureChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val on = call.argument<Boolean>("enabled") ?: false
                        // Window flags must be touched on the UI thread.
                        runOnUiThread {
                            if (on) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
