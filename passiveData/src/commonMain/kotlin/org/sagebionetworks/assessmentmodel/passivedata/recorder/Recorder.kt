package org.sagebionetworks.assessmentmodel.passivedata.recorder

import org.sagebionetworks.assessmentmodel.Result
import org.sagebionetworks.assessmentmodel.passivedata.asyncaction.AsyncActionController

interface Recorder<out R : Result> : AsyncActionController<R> {
}