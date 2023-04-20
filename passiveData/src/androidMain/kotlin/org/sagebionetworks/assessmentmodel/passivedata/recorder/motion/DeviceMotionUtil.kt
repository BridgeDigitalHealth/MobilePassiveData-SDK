package org.sagebionetworks.assessmentmodel.passivedata.recorder.motion

import android.hardware.Sensor
import android.hardware.SensorManager
import android.hardware.SensorEvent
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.os.SystemClock
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.minus
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.JsonObject
import org.sagebionetworks.assessmentmodel.passivedata.recorder.sensor.*
import kotlin.time.Duration
import kotlin.time.ExperimentalTime


/**
 * Created by TheMDP on 2/5/17.
 *
 *
 * The DeviceMotionUtil incorporates a bunch of sensor fusion sensor readings together to paint a broad picture of the
 * device's orientation and movement over time.
 *
 *
 * This class is an attempt at recording data in a similar way as iOS' device motion recorder.
 *
 * @see [
 * Sensor values](https://developer.android.com/reference/android/hardware/SensorEvent.html.values)
 *
 * @see [Sensor Types](https://source.android.com/devices/sensors/sensor-type)
 *
 * @see [
 * Position Sensors](https://developer.android.com/guide/topics/sensors/sensors_position.html)
 *
 * @see [
 * Motion Sensors](https://developer.android.com/guide/topics/sensors/sensors_motion.html)
 */
class DeviceMotionUtil {

    companion object {

        const val GRAVITY_SI_CONVERSION = SensorManager.GRAVITY_EARTH
        const val SENSOR_DATA_TYPE_KEY = "sensorType"
        const val SENSOR_DATA_SUBTYPE_KEY = "sensorAndroidType"
        const val SENSOR_EVENT_ACCURACY_KEY = "eventAccuracy"
        val SENSOR_TYPE_TO_DATA_TYPE: Map<Int, String>
        val ROTATION_VECTOR_TYPES: Set<Int>
        const val ROTATION_REFERENCE_COORDINATE_KEY = "referenceCoordinate"
        const val X_KEY = "x"
        const val Y_KEY = "y"
        const val Z_KEY = "z"
        const val W_KEY = "w"
        const val ACCURACY_KEY = "estimatedAccuracy"
        const val X_UNCALIBRATED_KEY = "xUncalibrated"
        const val Y_UNCALIBRATED_KEY = "yUncalibrated"
        const val Z_UNCALIBRATED_KEY = "zUncalibrated"
        const val X_BIAS_KEY = "xBias"
        const val Y_BIAS_KEY = "yBias"
        const val Z_BIAS_KEY = "zBias"
        val SENSOR_TYPE_TO_EVENT_POJO: Map<Int, Class<out SensorEventPOJO>> =
            mapOf(
                Sensor.TYPE_ACCELEROMETER to AccelerationEventPojo::class.java,
                Sensor.TYPE_GRAVITY to AccelerationEventPojo::class.java,
                Sensor.TYPE_LINEAR_ACCELERATION to AccelerationEventPojo::class.java,
                Sensor.TYPE_GYROSCOPE to GyroscopeEventPOJO::class.java,
                Sensor.TYPE_MAGNETIC_FIELD to MagneticEventPojo::class.java,
                Sensor.TYPE_GYROSCOPE_UNCALIBRATED to UncalibratedEventPOJO::class.java,
                Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED to UncalibratedEventPOJO::class.java,
                Sensor.TYPE_ACCELEROMETER_UNCALIBRATED to UncalibratedEventPOJO::class.java,
                Sensor.TYPE_GAME_ROTATION_VECTOR to RotationEventPojo::class.java,
                Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR to RotationEventPojo::class.java,
                Sensor.TYPE_ROTATION_VECTOR to RotationEventPojo::class.java,
            )

        @ExperimentalStdlibApi
        val SENSOR_TYPE_TO_FACTORY: Map<Int, (event: SensorEvent, referenceTimestampNanos: Double)
        -> SensorEventPOJO> =
            buildMap {
                put(Sensor.TYPE_ACCELEROMETER)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    AccelerationEventPojo.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_GRAVITY)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    AccelerationEventPojo.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_LINEAR_ACCELERATION)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    AccelerationEventPojo.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_GYROSCOPE)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    GyroscopeEventPOJO.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_MAGNETIC_FIELD)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    MagneticEventPojo.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_GYROSCOPE_UNCALIBRATED)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    UncalibratedEventPOJO.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    UncalibratedEventPOJO.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_ACCELEROMETER_UNCALIBRATED)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    UncalibratedEventPOJO.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_GAME_ROTATION_VECTOR)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    RotationEventPojo.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    RotationEventPojo.create(event, referenceTimestampNanos)
                }
                put(Sensor.TYPE_ROTATION_VECTOR)
                { event: SensorEvent, referenceTimestampNanos: Double ->
                    RotationEventPojo.create(event, referenceTimestampNanos)
                }
            }

        @ExperimentalSerializationApi
        @ExperimentalStdlibApi
        val SENSOR_TYPE_TO_RECORD_FACTORY: Map<Int, (event: SensorEvent, referenceTimestampNanos: Long)
        -> SensorRecord> =
            buildMap {
                put(Sensor.TYPE_ACCELEROMETER) { event, referenceTimestampNanos ->
                    event.createAccelerationRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_GRAVITY) { event, referenceTimestampNanos ->
                    event.createAccelerationRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_LINEAR_ACCELERATION) { event, referenceTimestampNanos ->
                    event.createAccelerationRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_GYROSCOPE) { event, referenceTimestampNanos ->
                    event.createGyroscopeRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_MAGNETIC_FIELD) { event, referenceTimestampNanos ->
                    event.createMagneticRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_GYROSCOPE_UNCALIBRATED) { event, referenceTimestampNanos ->
                    event.createUncalibratedRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED) { event, referenceTimestampNanos ->
                    event.createUncalibratedRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_ACCELEROMETER_UNCALIBRATED) { event, referenceTimestampNanos ->
                    event.createUncalibratedRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_GAME_ROTATION_VECTOR) { event, referenceTimestampNanos ->
                    event.createRotationRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR) { event, referenceTimestampNanos ->
                    event.createRotationRecord(referenceTimestampNanos)
                }
                put(Sensor.TYPE_ROTATION_VECTOR) { event, referenceTimestampNanos ->
                    event.createRotationRecord(referenceTimestampNanos)
                }
            }

        /**
         * @param availableSensorList
         * the list of available sensors
         * @param sensorType
         * the sensor type to check if it is contained in the list
         * @return true if that sensor type is available, false if it is not
         */
        fun hasAvailableType(availableSensorList: List<Sensor>, sensorType: Int): Boolean {
            for (sensor in availableSensorList) {
                if (sensor.type == sensorType) {
                    return true
                }
            }
            return false
        }

        fun getSensorTypeList(availableSensorList: List<Sensor>): List<Int> {
            val sensorTypeList: MutableList<Int> = ArrayList()

            // Only add these sensors if the device has them
            if (hasAvailableType(availableSensorList, Sensor.TYPE_ACCELEROMETER)) {
                sensorTypeList.add(Sensor.TYPE_ACCELEROMETER)
            }
            if (VERSION.SDK_INT >= VERSION_CODES.O
                && hasAvailableType(availableSensorList, Sensor.TYPE_ACCELEROMETER_UNCALIBRATED)
            ) {
                sensorTypeList.add(Sensor.TYPE_ACCELEROMETER_UNCALIBRATED)
            }
            if (hasAvailableType(availableSensorList, Sensor.TYPE_GRAVITY)) {
                sensorTypeList.add(Sensor.TYPE_GRAVITY)
            }
            if (hasAvailableType(availableSensorList, Sensor.TYPE_LINEAR_ACCELERATION)) {
                sensorTypeList.add(Sensor.TYPE_LINEAR_ACCELERATION)
            }
            if (hasAvailableType(availableSensorList, Sensor.TYPE_GYROSCOPE)) {
                sensorTypeList.add(Sensor.TYPE_GYROSCOPE)
            }
            if (VERSION.SDK_INT >= VERSION_CODES.JELLY_BEAN_MR2
                && hasAvailableType(availableSensorList, Sensor.TYPE_GYROSCOPE_UNCALIBRATED)
            ) {
                sensorTypeList.add(Sensor.TYPE_GYROSCOPE_UNCALIBRATED)
            }
            if (hasAvailableType(availableSensorList, Sensor.TYPE_MAGNETIC_FIELD)) {
                sensorTypeList.add(Sensor.TYPE_MAGNETIC_FIELD)
            }
            if (VERSION.SDK_INT >= VERSION_CODES.JELLY_BEAN_MR2
                && hasAvailableType(availableSensorList, Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED)
            ) {
                sensorTypeList.add(Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED)
            }
            if (hasAvailableType(availableSensorList, Sensor.TYPE_ROTATION_VECTOR)) {
                sensorTypeList.add(Sensor.TYPE_ROTATION_VECTOR)
            }
            if (VERSION.SDK_INT >= VERSION_CODES.JELLY_BEAN_MR2) {
                if (hasAvailableType(availableSensorList, Sensor.TYPE_GAME_ROTATION_VECTOR)) {
                    sensorTypeList.add(Sensor.TYPE_GAME_ROTATION_VECTOR)
                }
            }
            if (VERSION.SDK_INT >= VERSION_CODES.KITKAT) {
                if (hasAvailableType(
                        availableSensorList,
                        Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR
                    )
                ) {
                    sensorTypeList.add(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)
                }
            }
            return sensorTypeList
        }

        init {
            // build mapping for sensor type and its data type value
            val sensorMapType = mutableMapOf<Int, String>()
            // rotation/gyroscope
            sensorMapType.put(
                Sensor.TYPE_GYROSCOPE,
                "rotationRate"
            )
            sensorMapType.put(
                Sensor.TYPE_GYROSCOPE_UNCALIBRATED, "rotationRateUncalibrated"
            )

            // accelerometer
            sensorMapType.put(
                Sensor.TYPE_ACCELEROMETER, "accelerometer"
            )
            if (VERSION.SDK_INT >= VERSION_CODES.O) {
                sensorMapType.put(
                    Sensor.TYPE_ACCELEROMETER_UNCALIBRATED, "accelerationUncalibrated"
                )
            }

            // gravity
            sensorMapType.put(
                Sensor.TYPE_GRAVITY,
                "gravity"
            )

            // acceleration without gravity
            sensorMapType.put(
                Sensor.TYPE_LINEAR_ACCELERATION, "userAcceleration"
            )

            // magnetic field
            sensorMapType.put(
                Sensor.TYPE_MAGNETIC_FIELD, "magneticField"
            )
            sensorMapType.put(
                Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED, "magneticFieldUncalibrated"
            )

            // attitude
            sensorMapType.put(
                Sensor.TYPE_ROTATION_VECTOR, "attitude"
            )
            if (VERSION.SDK_INT >= VERSION_CODES.KITKAT) {
                sensorMapType.put(
                    Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR, "attitude"
                )
            }
            SENSOR_TYPE_TO_DATA_TYPE = sensorMapType


            // build mapping for rotation type
            val rotationTypeBuilder = mutableSetOf<Int>()
            rotationTypeBuilder.add(
                Sensor.TYPE_ROTATION_VECTOR
            )
            rotationTypeBuilder.add(
                Sensor.TYPE_GAME_ROTATION_VECTOR
            )
            if (VERSION.SDK_INT >= VERSION_CODES.KITKAT) {
                rotationTypeBuilder.add(
                    Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR
                )
            }

            ROTATION_VECTOR_TYPES = rotationTypeBuilder
        }
    }

    open class SensorEventPOJO {

        val sensor: Sensor?

        // ISO-8601 for the first sensorEvent's timestamp, which is then used as the zero for the relative timestamp
        // of subsequent SensorEventPojo
        val timestampDate: Instant?
        val sensorType: String?

        // relative timestamp in seconds. seconds elapsed since first recorded event
        val timestamp: Double

        // system uptime in seconds
        val uptime: Double
        var eventAccuracy = 0

        /**
         * @param event
         * sensor event
         * @param referenceUptimeSeconds
         * uptime zero in nanos from epoch
         */
        constructor(event: SensorEvent, referenceUptimeSeconds: Double) {
            uptime = event.timestamp.toDouble() / SECONDS_TO_NANOS
            timestamp = uptime - referenceUptimeSeconds
            sensorType = SENSOR_TYPE_TO_DATA_TYPE!![event.sensor.type]
            timestampDate = null
            sensor = null
        }

        // used to log initial event, contains more data about sensor and reference for subsequent events
        @OptIn(ExperimentalTime::class)
        constructor(event: SensorEvent) {
            uptime = event.timestamp.toDouble() / SECONDS_TO_NANOS
            timestampDate = instantOf(event.timestamp)
            timestamp = 0.0
            sensorType = SENSOR_TYPE_TO_DATA_TYPE!![event.sensor.type]
            sensor = event.sensor
        }

        companion object {

            private const val SECONDS_TO_NANOS = 1000000000
            fun toNanos(timestamp: Instant): Long {
                return timestamp.epochSeconds * SECONDS_TO_NANOS + timestamp.nanosecondsOfSecond
            }

            /**
             * @param sensorTimestamp
             * sensor timestamp
             * @return instant corresponding to sensor timestamp
             * Used to set the timestampDate on the first sensor event
             */
            fun instantOf(sensorTimestamp: Long): Instant {
                if (sensorTimestamp > SystemClock.elapsedRealtimeNanos()) {
                    // Adding this special case to prevent crash when running tests on an Android emulator -nbrown 03/31/2023
                    // Shouldn't ever get here as that would imply sensor event occurred in the future.
                    // However, running tests with Github actions on an emulator gets into this state.
                    return Clock.System.now()
                }
                return Clock.System.now()
                    .minus(DateTimeUnit.TimeBased(SystemClock.elapsedRealtimeNanos() - sensorTimestamp))
            }
        }
    }

    class AccelerationEventPojo(sensorEvent: SensorEvent, referenceTimestampNanos: Double) :
        SensorEventPOJO(sensorEvent, referenceTimestampNanos) {

        val x: Double
        val y: Double
        val z: Double
        val unit = "g"

        companion object {

            fun create(event: SensorEvent, referenceTimestampNanos: Double): AccelerationEventPojo {
                return AccelerationEventPojo(event, referenceTimestampNanos)
            }
        }

        init {
            x = (sensorEvent.values[0] / SensorManager.GRAVITY_EARTH).toDouble()
            y = (sensorEvent.values[1] / SensorManager.GRAVITY_EARTH).toDouble()
            z = (sensorEvent.values[2] / SensorManager.GRAVITY_EARTH).toDouble()
        }
    }

    class GyroscopeEventPOJO(sensorEvent: SensorEvent, referenceTimestampNanos: Double) :
        SensorEventPOJO(sensorEvent, referenceTimestampNanos) {

        val x: Double
        val y: Double
        val z: Double
        val unit = "rad/s"

        companion object {

            fun create(event: SensorEvent, referenceTimestampNanos: Double): GyroscopeEventPOJO {
                return GyroscopeEventPOJO(event, referenceTimestampNanos)
            }
        }

        init {
            x = sensorEvent.values[0].toDouble()
            y = sensorEvent.values[1].toDouble()
            z = sensorEvent.values[2].toDouble()
        }
    }

    class MagneticEventPojo(sensorEvent: SensorEvent, referenceTimestampNanos: Double) :
        SensorEventPOJO(sensorEvent, referenceTimestampNanos) {

        val x: Double
        val y: Double
        val z: Double
        val unit = "uT"

        companion object {

            fun create(event: SensorEvent, referenceTimestampNanos: Double): MagneticEventPojo {
                return MagneticEventPojo(event, referenceTimestampNanos)
            }
        }

        init {
            x = sensorEvent.values[0].toDouble()
            y = sensorEvent.values[1].toDouble()
            z = sensorEvent.values[2].toDouble()
        }
    }

    class RotationEventPojo(event: SensorEvent, referenceTimestampNanos: Double) :
        SensorEventPOJO(event, referenceTimestampNanos) {

        var referenceCoordinate: String? = null
        var sensorAndroidType: String? = null
        val x: Double
        val y: Double
        val z: Double
        val w: Double
        var estimatedAccuracy: Double

        companion object {

            fun create(event: SensorEvent, referenceTimestampNanos: Double): RotationEventPojo {
                return RotationEventPojo(event, referenceTimestampNanos)
            }
        }

        init {
            // rot_axis.x * sin(theta/2)
            x = event.values[0].toDouble()
            // rot_axis.y * sin(theta/2)
            y = event.values[1].toDouble()
            // rot_axis.z * sin(theta/2)
            z = event.values[2].toDouble()
            // cos(theta/2)
            w = event.values[3].toDouble()
            estimatedAccuracy = event.values[4].toDouble()
            val sensorType = event.sensor.type
            if (Sensor.TYPE_ROTATION_VECTOR == sensorType) {
                sensorAndroidType = "rotationVector"
                referenceCoordinate = "East-Up-North"
            } else if (VERSION.SDK_INT >= VERSION_CODES.JELLY_BEAN_MR2
                && Sensor.TYPE_GAME_ROTATION_VECTOR == sensorType
            ) {
                sensorAndroidType = "gameRotationVector"
                referenceCoordinate = "zUp"
            } else if (VERSION.SDK_INT >= VERSION_CODES.KITKAT
                && Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR == sensorType
            ) {
                sensorAndroidType = "geomagneticRotationVector"
                referenceCoordinate = "East-Up-North"
            } else {
                sensorAndroidType = null
                referenceCoordinate = null
            }
        }
    }

    class UncalibratedEventPOJO(event: SensorEvent, referenceTimestampNanos: Double) :
        SensorEventPOJO(event, referenceTimestampNanos) {

        val xUncalibrated: Double
        val xBias: Double
        val yUncalibrated: Double
        val yBias: Double
        val zUncalibrated: Double
        val zBias: Double

        companion object {

            fun create(event: SensorEvent, referenceTimestampNanos: Double): UncalibratedEventPOJO {
                return UncalibratedEventPOJO(event, referenceTimestampNanos)
            }
        }

        init {
            xUncalibrated = event.values[0].toDouble()
            yUncalibrated = event.values[1].toDouble()
            zUncalibrated = event.values[2].toDouble()
            xBias = event.values[3].toDouble()
            yBias = event.values[4].toDouble()
            zBias = event.values[5].toDouble()
        }
    }
}