package org.sagebionetworks.assessmentmodel.passivedata.android

import android.app.Activity
import android.os.Bundle
import org.sagebionetworks.assessmentmodel.passivedata.Greeting
import android.widget.TextView

fun greet(): String {
    return Greeting().greeting()
}

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val tv: TextView = findViewById(R.id.text_view)
        tv.text = greet()
    }
}
