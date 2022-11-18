package org.sagebionetworks.assessmentmodel.passivedata.recorder.motion

import io.github.aakira.napier.Napier
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.produce
import kotlinx.coroutines.flow.*
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import org.sagebionetworks.assessmentmodel.Result
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionConfiguration
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionStatus
import org.sagebionetworks.assessmentmodel.passivedata.recorder.Recorder

abstract class FlowRecorder<in E, out R : Result>(
    open val identifier: String,
    override val configuration: AsyncActionConfiguration,
    open val scope: CoroutineScope,
    private val flow: Flow<E>
) :
    Recorder<R> {
    internal var _asyncStatus = AsyncActionStatus.IDLE
    override val status: AsyncActionStatus
        get() = _asyncStatus

    private var job: Job? = null
    protected var startTime: Instant? = null
    protected var endTime: Instant? = null

    override fun start() {
        if (_asyncStatus >= AsyncActionStatus.STARTING) {
            Napier.e("Recorder $identifier has already been started")
            return
        }
        startTime = Clock.System.now()
        _asyncStatus = AsyncActionStatus.RUNNING
        job = scope.launch {
            flow
                .onCompletion {
                    Napier.i("Flow collection completed")
                    _asyncStatus = AsyncActionStatus.WAITING_TO_STOP
                    completedHandlingFlow(it)
                }
                .onEach {
                    coroutineContext.ensureActive()
                    handleElement(it)
                }.catch { t ->
                    if (t is CancellationException) {
                        Napier.d("Flow cancelled")
                    } else {
                        Napier.w("Flow cancelled")
                        throw t
                    }
                }.collect()
        }
    }

    abstract suspend fun handleElement(e: E)

    abstract fun completedHandlingFlow(e: Throwable?)

    override fun stop() {
        Napier.i("Stop called")
        endTime = Clock.System.now()
        job?.cancel()
        job = null
    }

    override fun cancel() {
        Napier.i("Cancel called")
        job?.cancel()
        job = null
        _asyncStatus = AsyncActionStatus.CANCELLED
    }
}