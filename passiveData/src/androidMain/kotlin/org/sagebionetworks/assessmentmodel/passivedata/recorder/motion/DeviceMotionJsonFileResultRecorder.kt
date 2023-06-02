package org.sagebionetworks.assessmentmodel.passivedata.recorder.motion

import android.content.Context
import android.hardware.SensorEvent
import io.github.aakira.napier.Napier
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.encodeToStream
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionConfiguration
import org.sagebionetworks.assessmentmodel.passivedata.recorder.FlowJsonFileResultRecorder
import org.sagebionetworks.assessmentmodel.passivedata.recorder.motion.DeviceMotionUtil.Companion.SENSOR_TYPE_TO_RECORD_FACTORY
import org.sagebionetworks.assessmentmodel.passivedata.recorder.sensor.SensorRecord
import org.sagebionetworks.assessmentmodel.passivedata.recorder.sensor.createFirstRecord
import java.lang.Exception
import java.util.concurrent.atomic.AtomicReference
import kotlin.time.ExperimentalTime

/**
 * Writes a SensorEvent Flow as a Json formatted FileResult.
 *
 * The SensorEvents are written in the way defined by SensorRecord.
 * @see SensorRecord
 */
class DeviceMotionJsonFileResultRecorder(
    override val identifier: String,
    override val configuration: AsyncActionConfiguration,
    override val scope: CoroutineScope,
    flow: Flow<SensorEvent>,
    context: Context,
    val jsonCoder: Json
) :
    FlowJsonFileResultRecorder<SensorEvent>(
        identifier, configuration, scope, flow, context
    ) {
    var firstEventUptimeReference = AtomicReference<Long>()

    override val jsonSchemaUrl: String
        get() = "https://sage-bionetworks.github.io/mobile-client-json/schemas/v2/MotionRecord.json"

    @ExperimentalSerializationApi
    @ExperimentalTime
    @ExperimentalStdlibApi
    override fun serializeElement(e: SensorEvent) {
        val record: SensorRecord? = if (firstEventUptimeReference.get() == null) {
            // determine uptime reference and log full info about sensor
            val first = e.createFirstRecord()
            firstEventUptimeReference.set(e.timestamp)
            first
        } else {
            // normal log of event based on uptime reference
            SENSOR_TYPE_TO_RECORD_FACTORY[e.sensor.type]
                ?.invoke(e, firstEventUptimeReference.get())
        }

        if (record == null) {
            Napier.w("Failed to serialize SensorEvent for recorder $identifier and sensor ${e.sensor}")
        } else {
            try {
                jsonCoder.encodeToStream(record, filePrintStream)
            } catch (e: Exception) {
                Napier.w("Error encoding sensor record $record", e)
            }
        }
    }

    override fun pause() {
        // TODO: implement pausing - liujoshua 2021-09-12
    }

    override fun resume() {
        // TODO: implement resume - liujoshua 2021-09-12
    }

    override fun isPaused(): Boolean {
        // TODO: implement pausing - liujoshua 2021-09-12
        return false
    }
}