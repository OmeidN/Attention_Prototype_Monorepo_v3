package com.attention.androidapitest

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.time.Instant

class MainActivity : ComponentActivity() {

    private val lastResumeAt = mutableStateOf("")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        logEvent("onCreate")
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("AttentionAndroidAPITest")
                        Text("Milestone 00 — Environment Setup")
                        Text("Last onResume: ${lastResumeAt.value}")
                    }
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        lastResumeAt.value = Instant.now().toString()
        logEvent("onResume")
    }

    private fun logEvent(event: String) {
        Log.i(TAG, "$event at ${Instant.now()}")
    }

    companion object {
        private const val TAG = "ATTN-M00"
    }
}
