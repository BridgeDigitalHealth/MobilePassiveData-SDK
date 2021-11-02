package org.sagebionetworks.assessmentmodel.passivedata.recorder.audio

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import io.github.aakira.napier.Napier
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import java.io.File
import java.lang.IllegalStateException


// see for more info: https://web.archive.org/web/20121225215502/http://code.google.com/p/android-labs/source/browse/trunk/NoiseAlert/src/com/google/android/noisealert/SoundMeter.java
fun AudioRecorderConfiguration.createAudioLevelFlow(context: Context): Flow<Int> {
    val flow: Flow<Int> = channelFlow {

        var tempFile: File? = null
        var mr = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
            setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            setOutputFile("/dev/null");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tempFile = File.createTempFile("tmp_media", null, context.cacheDir)
                setOutputFile(tempFile)
            } else {
                setOutputFile("/dev/null")
            }
        }

        try {
            mr.apply {
                Napier.i("Preparing MediaRecorder")
                kotlin.runCatching {
                    prepare()
                }
                Napier.i("Starting MediaRecorder")
                start()
                maxAmplitude // first call is always zero and sets up for subsequent call
            }

            while (!isClosedForSend) {
                Napier.d("Delaying")
                delay(AudioRecorderConfiguration.SAMPLE_INTERVAL_MILLISECONDS)
                Napier.d("Done delaying")
                val maxAmplitude = mr.maxAmplitude
                Napier.d("Collected maxAmplitude: $maxAmplitude")
                send(maxAmplitude)
                //send(20 * ln(maxAmplitude / 2700.0)) // sampled from previous call
            }
            Napier.d("Leaving Audio SamplingLoop")
        } finally {
            awaitClose {
                try {
                    Napier.i("Closing MediaRecorder")
                    mr.stop()
                    mr.release()
                    tempFile?.delete()
                } catch (e: IllegalStateException) {
                    // no-op, we are not actually recording so this is always thrown
                }
            }
        }

    }
    return flow.shareIn(
        CoroutineScope(Dispatchers.IO),
        SharingStarted.WhileSubscribed(stopTimeoutMillis = 0, replayExpirationMillis = 0)
    )


}