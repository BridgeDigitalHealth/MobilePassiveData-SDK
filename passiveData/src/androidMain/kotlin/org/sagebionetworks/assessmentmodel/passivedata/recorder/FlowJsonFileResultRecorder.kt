package org.sagebionetworks.assessmentmodel.passivedata.recorder

import android.content.Context
import io.github.aakira.napier.Napier
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.Clock
import org.sagebionetworks.assessmentmodel.FileResult
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionConfiguration
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionStatus
import org.sagebionetworks.assessmentmodel.passivedata.recorder.motion.FlowRecorder
import org.sagebionetworks.assessmentmodel.serialization.FileResultObject
import java.io.File
import java.io.IOException
import java.io.PrintStream
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Base class for a Recorder that reads from a Flow and produces a FileResult in Json format.
 */
abstract class FlowJsonFileResultRecorder<in E>(
    override val identifier: String,
    override val configuration: AsyncActionConfiguration,
    override val scope: CoroutineScope,
    flow: Flow<E>,
    private val context: Context
) : FlowRecorder<E, FileResult>(
    identifier, configuration, scope, flow
) {
    override val result = CompletableDeferred<FileResult>()

    private val JSON_MIME_CONTENT_TYPE = "application/json"
    private val JSON_FILE_START = "["
    private val JSON_FILE_END = "]"
    private val JSON_OBJECT_DELIMINATOR = ","

    private lateinit var file: File
    protected lateinit var filePrintStream: PrintStream

    private val isFirstJsonObject = AtomicBoolean(true)

    internal abstract val jsonSchemaUrl: String

    override fun start() {
        file = getTaskOutputFile("${defaultLoggerIdentifier()}.json")
        filePrintStream = PrintStream(file)
        filePrintStream.print(JSON_FILE_START)
        super.start()
    }

    @Throws(IOException::class)
    open fun getTaskOutputFile(
        filename: String
    ): File {
        val path = context.filesDir
        val outputFilename = "${UUID.randomUUID()}/$filename"
        val outputFile = File(path, outputFilename)
        if (!outputFile.isFile && !outputFile.exists()) {
            outputFile.parentFile!!.mkdirs()
            outputFile.createNewFile()
        }
        return outputFile
    }

    override suspend fun handleElement(e: E) {
        if (!isFirstJsonObject.compareAndSet(true, false)) {
            filePrintStream.print(JSON_OBJECT_DELIMINATOR)
        }
        serializeElement(e)
    }

    abstract fun serializeElement(e: E)

    /**
     * The default logger is a file with markers for each step transition.
     *
     * Recorders can have multiple files associated with them. For example, an
     * audio recorder ("microphone") can record audio to an mp4 and microphone
     * levels to a log file. In that case, by convention, the primary file is
     * has the filename "microphone.mp4" and the secondary logging file that
     * logs the microphone levels is named "microphone_levels.json".
     *
     * - Note: This library does not currently support non-JSON recordings, but
     * is structured this way to keep it consistent with iOS where mp4, jpeg, etc.
     * have been supported for previously implemented assessments. syoung 04/27/2023
     */
    open fun defaultLoggerIdentifier(): String = identifier

    override fun completedHandlingFlow(e: Throwable?) {
        Napier.i("Completed handling flow")
        if (e == null || e is CancellationException) {
            filePrintStream.print(JSON_FILE_END)
            result.complete(
                FileResultObject(
                    identifier = identifier,
                    startDateTime = startTime ?: Clock.System.now(),
                    endDateTime = endTime ?: Clock.System.now(),
                    filename = file.name,
                    contentType = JSON_MIME_CONTENT_TYPE,
                    path = file.path,
                    jsonSchema = jsonSchemaUrl
                )
            )
            _asyncStatus = AsyncActionStatus.FINISHED
            filePrintStream.close()
        } else {
            result.completeExceptionally(e)
            filePrintStream.close()
            file.delete()
        }
    }

}