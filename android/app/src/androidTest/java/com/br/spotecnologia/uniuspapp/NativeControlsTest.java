package com.br.spotecnologia.uniuspapp;

import android.os.SystemClock;
import android.util.Log;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.rule.ActivityTestRule;
import androidx.test.uiautomator.UiDevice;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import java.io.File;
import java.nio.file.Files;
import java.net.HttpURLConnection;
import java.net.URL;
import org.junit.Rule;
import org.junit.runner.RunWith;

/** Exercises the actual Android Back action, including the native IME. */
@RunWith(FlutterTestRunner.class)
public class NativeControlsTest {
  @Rule
  public ActivityTestRule<MainActivity> rule = new ActivityTestRule<MainActivity>(MainActivity.class,true,false) {
    @Override protected void beforeActivityLaunched() {
      UiDevice.getInstance(InstrumentationRegistry.getInstrumentation()).getCurrentPackageName();
    }
    @Override protected void afterActivityLaunched() {
      Thread driver = new Thread(() -> pressBackAtStages(), "usp-system-back-test");
      driver.setDaemon(true);
      driver.start();
    }
  };

  private static void pressBackAtStages() {
    UiDevice device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation());
    File cache = InstrumentationRegistry.getInstrumentation().getTargetContext().getCacheDir();
    try {
      for (int stage=1;stage<=2;stage++) {
        File ready = new File(cache,"usp-native-back-"+stage);
        long deadline = SystemClock.uptimeMillis()+90000;
        while (!ready.exists() && SystemClock.uptimeMillis()<deadline) SystemClock.sleep(100);
        if (!ready.exists()) throw new AssertionError("Back stage not requested: "+stage);
        File screenshot = new File(cache,"native-back.png");
        if (!device.takeScreenshot(screenshot)) throw new AssertionError("Native screenshot failed");
        HttpURLConnection connection = (HttpURLConnection)new URL("http://127.0.0.1:8774/android/native-back-stage-"+stage+".png").openConnection();
        connection.setRequestMethod("POST");connection.setDoOutput(true);connection.setConnectTimeout(5000);connection.setReadTimeout(5000);
        byte[] bytes = Files.readAllBytes(screenshot.toPath());connection.setFixedLengthStreamingMode(bytes.length);
        try (java.io.OutputStream output=connection.getOutputStream()) { output.write(bytes); }
        if (connection.getResponseCode()!=201) throw new AssertionError("Native evidence not saved");
        connection.disconnect();screenshot.delete();
        if (!device.pressBack()) throw new AssertionError("System Back was not delivered");
        SystemClock.sleep(300);
        Files.write(new File(cache,"usp-native-back-"+stage+"-ack").toPath(),new byte[]{1});
      }
    } catch (Throwable error) { Log.e("USP_NATIVE_CONTROLS","Native Back test failed",error); }
  }
}
