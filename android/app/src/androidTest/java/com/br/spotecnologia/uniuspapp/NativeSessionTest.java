package com.br.spotecnologia.uniuspapp;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;

/** Separate instrumentation invocations retain app data across real processes. */
@RunWith(FlutterTestRunner.class)
public class NativeSessionTest {
  @Rule
  public ActivityTestRule<MainActivity> rule =
      new ActivityTestRule<>(MainActivity.class, true, false);
}
