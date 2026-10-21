package com.jonay.guachinches

import android.annotation.SuppressLint
import android.content.Context
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Identidad del móvil para la encuesta (ENCUESTA-SEGURIDAD.md, plan App Check).
 *
 * `localIdHash` = SHA256("gm-survey-id:" + SSAID). El SSAID no sale de aquí ni
 * se registra. Es estable entre reinstalaciones y al borrar datos (misma clave
 * de firma); cambia al restablecer de fábrica y en otro usuario o perfil.
 */
class SurveyDevicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    @SuppressLint("HardwareIds") // Uso antiabuso; solo sale el hash.
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "localIdHash") return result.notImplemented()
        val ssaid = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
        if (ssaid.isNullOrEmpty()) return result.error("unsupported", null, null)
        val digest = MessageDigest.getInstance("SHA-256")
            .digest("gm-survey-id:$ssaid".toByteArray(Charsets.UTF_8))
        result.success(mapOf("localIdHash" to digest.joinToString("") { "%02x".format(it) }, "created" to false))
    }

    companion object {
        const val CHANNEL = "com.jonay.guachinches/survey_device"
    }
}
