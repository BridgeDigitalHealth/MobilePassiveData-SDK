@file:UseSerializers(InstantSerializer::class, LongNanosAsSecondsSerializer::class)

package org.sagebionetworks.assessmentmodel.passivedata.recorder.sensor

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorManager
import android.os.Build
import kotlinx.datetime.Instant
import kotlinx.serialization.*
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclass
import org.sagebionetworks.assessmentmodel.passivedata.recorder.SampleRecord
import org.sagebionetworks.assessmentmodel.passivedata.recorder.motion.DeviceMotionUtil
import org.sagebionetworks.assessmentmodel.passivedata.recorder.motion.DeviceMotionUtil.Companion.SENSOR_TYPE_TO_DATA_TYPE
import org.sagebionetworks.assessmentmodel.serialization.InstantSerializer

interface SensorRecord
    : SampleRecord {

    val sensorType: String?

    // system uptime in nanos, serialized in seconds
    val uptime: Long?
    val eventAccuracy: Int?

    // first sensor record will have a timestampDate. this is the zero reference for subsequent
    // records' relative timestamp
    override val timestampDate: Instant?

    // relative timestamp in nano seconds. serialized as seconds elapsed since first recorded event
    override val timestamp: Long?

    companion object {
        const val SECONDS_TO_NANOS = 1_000_000_000
    }
}

object LongNanosAsSecondsSerializer : KSerializer<Long> {
    const val secondsToNanos = 1_000_000_000
    override val descriptor: SerialDescriptor
        get() = PrimitiveSerialDescriptor("DateTimePeriod", PrimitiveKind.DOUBLE)

    override fun serialize(encoder: Encoder, value: Long) {

        encoder.encodeDouble(value.toDouble() / secondsToNanos)
    }

    override fun deserialize(decoder: Decoder): Long {
        return (decoder.decodeDouble() * secondsToNanos).toLong()
    }
}

@ExperimentalSerializationApi
val sensorRecordModule = SerializersModule {
    polymorphic(SensorRecord::class) {
        subclass(FirstRecord::class)
        subclass(AccelerationRecord::class)
        subclass(GyroscopeRecord::class)
        subclass(MagneticRecord::class)
        subclass(RotationRecord::class)
        subclass(UncalibratedRecord::class)
    }
}

@Serializable
data class FirstRecord(
    override val timestampDate: Instant? = null,
    override val timestamp: Long?,
    override val sensorType: String?,
    override val uptime: Long?,
    override val eventAccuracy: Int?,
    @Transient val sensor: Sensor? = null
) : SensorRecord

fun SensorEvent.createFirstRecord(): FirstRecord {
    return FirstRecord(
        timestampDate = DeviceMotionUtil.SensorEventPOJO.instantOf(timestamp),
        timestamp = 0,
        sensorType = SENSOR_TYPE_TO_DATA_TYPE[sensor.type],
        uptime = timestamp,
        eventAccuracy = null,
        sensor = sensor
    )
}

@ExperimentalSerializationApi
@Serializable
data class AccelerationRecord(
    override val timestamp: Long?,
    override val sensorType: String?,
    override val uptime: Long?,
    val x: Double,
    val y: Double,
    val z: Double
) : SensorRecord {
    @Transient
    @EncodeDefault(EncodeDefault.Mode.ALWAYS)
    val unit = "g"

    override val timestampDate: Instant? = null
    override val eventAccuracy: Int? = null
}

@ExperimentalSerializationApi
fun SensorEvent.createAccelerationRecord(referenceTimestamp: Long): AccelerationRecord {
    return AccelerationRecord(
        timestamp = timestamp - referenceTimestamp,
        sensorType = SENSOR_TYPE_TO_DATA_TYPE[sensor.type],
        uptime = timestamp,
        x = (values[0] / SensorManager.GRAVITY_EARTH).toDouble(),
        y = (values[1] / SensorManager.GRAVITY_EARTH).toDouble(),
        z = (values[2] / SensorManager.GRAVITY_EARTH).toDouble()
    )
}

@ExperimentalSerializationApi
@Serializable
data class GyroscopeRecord(
    override val timestamp: Long?,
    override val sensorType: String?,
    override val uptime: Long?,
    val x: Double,
    val y: Double,
    val z: Double
) : SensorRecord {
    @EncodeDefault(EncodeDefault.Mode.ALWAYS)
    val unit = "rad/s"

    override val timestampDate: Instant? = null
    override val eventAccuracy: Int? = null
}

@ExperimentalSerializationApi
fun SensorEvent.createGyroscopeRecord(referenceTimestamp: Long): GyroscopeRecord {
    return GyroscopeRecord(
        timestamp = timestamp - referenceTimestamp,
        sensorType = SENSOR_TYPE_TO_DATA_TYPE[sensor.type],
        uptime = timestamp,
        x = values[0].toDouble(),
        y = values[1].toDouble(),
        z = values[2].toDouble()
    )
}

@ExperimentalSerializationApi
@Serializable
data class MagneticRecord(
    override val timestamp: Long?,
    override val sensorType: String?,
    override val uptime: Long?,
    val x: Double,
    val y: Double,
    val z: Double
) : SensorRecord {
    @EncodeDefault(EncodeDefault.Mode.ALWAYS)
    val unit = "uT"

    override val timestampDate: Instant? = null
    override val eventAccuracy: Int? = null
}

@ExperimentalSerializationApi
fun SensorEvent.createMagneticRecord(referenceTimestamp: Long): MagneticRecord {
    return MagneticRecord(
        timestamp = timestamp - referenceTimestamp,
        sensorType = SENSOR_TYPE_TO_DATA_TYPE[sensor.type],
        uptime = timestamp,
        x = values[0].toDouble(),
        y = values[1].toDouble(),
        z = values[2].toDouble()
    )
}

/**
 * @param x rot_axis.x * sin(theta/2)
 * @param y rot_axis.y * sin(theta/2)
 * @param z rot_axis.z * sin(theta/2)
 * @param w cos(theta/2)
 */
@Serializable
data class RotationRecord(
    override val timestamp: Long?,
    override val sensorType: String?,
    override val uptime: Long?,
    val x: Double,
    val y: Double,
    val z: Double,
    val w: Double,
    val referenceCoordinate: String?,
    val sensorAndroidType: String?,
    val estimatedAccuracy: Double
) : SensorRecord {
    override val timestampDate: Instant? = null
    override val eventAccuracy: Int? = null
}


@ExperimentalSerializationApi
fun SensorEvent.createRotationRecord(referenceTimestamp: Long): RotationRecord {
    val sensorType = sensor.type
    val sensorAndroidType: String?
    val referenceCoordinate: String?

    if (Sensor.TYPE_ROTATION_VECTOR == sensorType) {
        sensorAndroidType = "rotationVector"
        referenceCoordinate = "East-Up-North"
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2
        && Sensor.TYPE_GAME_ROTATION_VECTOR == sensorType
    ) {
        sensorAndroidType = "gameRotationVector"
        referenceCoordinate = "zUp"
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT
        && Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR == sensorType
    ) {
        sensorAndroidType = "geomagneticRotationVector"
        referenceCoordinate = "East-Up-North"
    } else {
        sensorAndroidType = null
        referenceCoordinate = null
    }

    return RotationRecord(
        timestamp = timestamp - referenceTimestamp,
        sensorType = SENSOR_TYPE_TO_DATA_TYPE[sensor.type],
        uptime = timestamp,
        x = values[0].toDouble(),
        y = values[1].toDouble(),
        z = values[2].toDouble(),
        w = values[3].toDouble(),
        estimatedAccuracy = values[0].toDouble(),
        sensorAndroidType = sensorAndroidType,
        referenceCoordinate = referenceCoordinate
    )
}

@Serializable
data class UncalibratedRecord(
    override val timestamp: Long?,
    override val sensorType: String?,
    override val uptime: Long?,
    val xUncalibrated: Double,
    val yUncalibrated: Double,
    val zUncalibrated: Double,
    val xBias: Double,
    val yBias: Double,
    val zBias: Double
) : SensorRecord {
    override val timestampDate: Instant? = null
    override val eventAccuracy: Int? = null
}

@ExperimentalSerializationApi
fun SensorEvent.createUncalibratedRecord(referenceTimestamp: Long): UncalibratedRecord {
    return UncalibratedRecord(
        timestamp = timestamp - referenceTimestamp,
        sensorType = SENSOR_TYPE_TO_DATA_TYPE[sensor.type],
        uptime = timestamp,
        xUncalibrated = values[0].toDouble(),
        yUncalibrated = values[1].toDouble(),
        zUncalibrated = values[2].toDouble(),
        xBias = values[3].toDouble(),
        yBias = values[4].toDouble(),
        zBias = values[5].toDouble()
    )
}
