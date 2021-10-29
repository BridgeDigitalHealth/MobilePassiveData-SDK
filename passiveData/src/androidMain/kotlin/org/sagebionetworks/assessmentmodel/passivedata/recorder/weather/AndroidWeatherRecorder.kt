package org.sagebionetworks.assessmentmodel.passivedata.recorder.weather

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.annotation.RequiresPermission
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY
import com.google.android.gms.location.LocationServices
import com.google.android.gms.tasks.CancellationTokenSource
import io.github.aakira.napier.Napier
import io.ktor.client.*
import kotlinx.coroutines.*
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionStatus
import org.sagebionetworks.assessmentmodel.passivedata.recorder.coroutineExceptionLogger
import kotlin.coroutines.coroutineContext


class AndroidWeatherRecorder(
    override val configuration: WeatherConfiguration,
    httpClient: HttpClient,
    val context: Context
) :
    WeatherRecorder(configuration, httpClient) {
    private val tag = "AndroidWeatherRecorder"
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private val cancellationTokenSource = CancellationTokenSource()
    private var _asyncStatus = AsyncActionStatus.IDLE

    override val status: AsyncActionStatus
        get() = _asyncStatus

    @RequiresPermission(
        anyOf =
        ["android.permission.ACCESS_COARSE_LOCATION", "android.permission.ACCESS_FINE_LOCATION"]
    )
    override fun start() {
        Napier.d("Starting AndroidWeatherRecorder)")

        if (_asyncStatus >= AsyncActionStatus.STARTING) {
            Napier.e("Recorder was previously started")
            return
        }

        //TODO: Add way to request permissions at runtime - liujoshua 2021-09-21
        requestLocation()
    }

    internal fun requestLocation() {
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Napier.i("No location permission")
            _asyncStatus = AsyncActionStatus.FAILED
            result.cancel(CancellationException("No location permission"))
            return
        }

        _asyncStatus = AsyncActionStatus.RUNNING
        CoroutineScope(Job()).launch(coroutineExceptionLogger) {
            Napier.i("Launching weather services")
            launchWeatherServices(
                getLocation()
            )
        }
    }

    override fun stop() {
        cancellationTokenSource.cancel()
        _asyncStatus = AsyncActionStatus.FINISHED
    }

    override fun cancel() {
        cancellationTokenSource.cancel()
        _asyncStatus = AsyncActionStatus.CANCELLED
    }

    @RequiresPermission(
        anyOf =
        ["android.permission.ACCESS_COARSE_LOCATION", "android.permission.ACCESS_FINE_LOCATION"]
    )
    override suspend fun getLocation(): Location? {
        val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

        val cancellationToken = cancellationTokenSource.token
        cancellationToken.onCanceledRequested {
            cancel()
        }
        val currentLocation =
            fusedLocationClient.getCurrentLocation(
                PRIORITY_BALANCED_POWER_ACCURACY,
                cancellationToken
            )

        val result = CompletableDeferred<Location?>(coroutineContext.job)
        currentLocation.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Napier.i("Successfully retrieved location")
                if (currentLocation.result == null) {
                    Napier.w("Retrieved null location")
                    result.complete(null)
                }
                result.complete(with(currentLocation.result) {
                    Location(longitude = longitude, latitude = latitude)
                })
            } else if (task.exception != null) {
                Napier.e("Encountered exception while retrieving location", task.exception)
                result.completeExceptionally(task.exception!!)
            } else {
                Napier.w("Location retrieval completed unsuccessfully")
                result.complete(null)
            }
        }

        result.invokeOnCompletion {
            Napier.d("getLocation completed", it)
        }

        return result.await()
    }
}