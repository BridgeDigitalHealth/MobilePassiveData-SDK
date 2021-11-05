package org.sagebionetworks.assessmentmodel.passivedata.recorder.audio

import android.content.Context
import io.github.aakira.napier.Napier
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.encodeToStream
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionConfiguration
import org.sagebionetworks.assessmentmodel.passivedata.recorder.FlowJsonFileResultRecorder
import java.lang.Exception
import java.util.concurrent.atomic.AtomicReference

public class AudioRecorder(
    identifier: String,
    configuration: AsyncActionConfiguration,
    scope: CoroutineScope,
    flow: Flow<Int>,
    context: Context

) : FlowJsonFileResultRecorder<Int>(identifier, configuration, scope, flow, context) {

    var firstEventUptimeReference = AtomicReference<Long>()

    override fun serializeElement(e: Int) {
        var timestampDate : Instant? = null
        val now = Clock.System.now()
        val referenceTimeStamp = if (firstEventUptimeReference.get() == null) {
            timestampDate = now
            firstEventUptimeReference.set(now.toEpochMilliseconds())
            now.toEpochMilliseconds()
        } else {
            firstEventUptimeReference.get()
        }

        val record = AudioLevelRecord(
            timestampDate = timestampDate,
            timestamp = (now.toEpochMilliseconds() - referenceTimeStamp) / 1000.0,
            uptime = now.toEpochMilliseconds() / 1000.0,
            timeInterval = AudioRecorderConfiguration.SAMPLE_INTERVAL_MILLISECONDS / 1000.0,
            peak = e,
        )
        Napier.d("AudioRecord: $record")

        try {
            Json.encodeToStream(record, filePrintStream)
        } catch (e: Exception) {
            Napier.w("Error encoding audio record $record", e)
        }

    }

    override fun pause() {
        TODO("Not yet implemented")
    }

    override fun resume() {
        TODO("Not yet implemented")
    }

    override fun isPaused(): Boolean {
        TODO("Not yet implemented")
    }

}