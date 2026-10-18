package com.drilemoz.uainaoparecereal

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Importação e exportação explícitas de token pelo Storage Access Framework. */
class MainActivity : FlutterActivity() {
    private val channelName = "com.drilemoz.uainaoparecereal/token_transfer"
    private val importRequest = 19101
    private val exportRequest = 19102
    private var pending: MethodChannel.Result? = null
    private var exportContent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (pending != null) {
                result.error("BUSY", "Seletor já aberto.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "importToken" -> {
                    pending = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("text/plain", "application/json", "application/octet-stream"))
                        }
                        startActivityForResult(intent, importRequest)
                    } catch (_: Exception) { fail() }
                }
                "exportToken" -> {
                    val content = call.argument<String>("content")
                    if (content.isNullOrBlank() || content.length > 8192) {
                        result.error("INVALID", "Conteúdo inválido.", null)
                        return@setMethodCallHandler
                    }
                    pending = result
                    exportContent = content
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TITLE, "Uai-Nao-Parece-Real-TOKEN-PRIVADO.txt")
                        }
                        startActivityForResult(intent, exportRequest)
                    } catch (_: Exception) { fail() }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun fail() {
        pending?.error("DOCUMENT", "Não foi possível acessar o documento.", null)
        pending = null
        exportContent = null
    }

    @Deprecated("API nativa do SAF em FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != importRequest && requestCode != exportRequest) return
        val callback = pending ?: return
        try {
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                callback.success(null)
            } else if (requestCode == importRequest) {
                val uri = data.data!!
                val input = contentResolver.openInputStream(uri)
                    ?: throw IllegalStateException("Documento inválido")
                val bytes = input.use { stream ->
                    val output = java.io.ByteArrayOutputStream()
                    val buffer = ByteArray(1024)
                    while (true) {
                        val count = stream.read(buffer)
                        if (count < 0) break
                        if (output.size() + count > 8192) throw IllegalArgumentException("Arquivo grande")
                        output.write(buffer, 0, count)
                    }
                    output.toByteArray()
                }
                callback.success(String(bytes, Charsets.UTF_8))
            } else {
                val output = contentResolver.openOutputStream(data.data!!, "w")
                    ?: throw IllegalStateException("Destino inválido")
                output.use { it.write((exportContent ?: "").toByteArray(Charsets.UTF_8)) }
                callback.success(true)
            }
        } catch (_: Exception) {
            callback.error("DOCUMENT", "Falha ao processar o documento.", null)
        } finally {
            pending = null
            exportContent = null
        }
    }
}
