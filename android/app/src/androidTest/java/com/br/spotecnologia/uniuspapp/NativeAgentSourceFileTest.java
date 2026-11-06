package com.br.spotecnologia.uniuspapp;

import android.os.SystemClock;
import android.util.Log;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.rule.ActivityTestRule;
import androidx.test.uiautomator.UiDevice;
import androidx.test.uiautomator.UiObject;
import androidx.test.uiautomator.UiSelector;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import java.io.File;
import java.nio.file.Files;
import java.net.HttpURLConnection;
import java.net.URL;
import org.junit.Rule;
import org.junit.runner.RunWith;

/** Test-only driver for the actual Android DocumentsUI, limited to our fixture folder. */
@RunWith(FlutterTestRunner.class)
public class NativeAgentSourceFileTest {
  @Rule
  public ActivityTestRule<MainActivity> rule = new ActivityTestRule<MainActivity>(MainActivity.class, true, false) {
    @Override protected void beforeActivityLaunched() {
      // Attach accessibility before Flutter records its test baseline.
      UiDevice.getInstance(InstrumentationRegistry.getInstrumentation()).getCurrentPackageName();
    }
    @Override protected void afterActivityLaunched() {
      new Thread(() -> selectFixtures(), "usp-document-picker-test").start();
    }
  };

  private static boolean picker(String name) {
    return "com.google.android.documentsui".equals(name) || "com.android.documentsui".equals(name);
  }
  private static void selectFixtures() {
    UiDevice device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation());
    String[] names = {"usp-plan-note.txt"};
    try {
      for (int step = 0; step < names.length; step++) {
        long deadline = SystemClock.uptimeMillis() + 90000;
        while (!picker(device.getCurrentPackageName()) && SystemClock.uptimeMillis() < deadline) SystemClock.sleep(200);
        if (!picker(device.getCurrentPackageName())) throw new AssertionError("DocumentsUI did not open for fixture " + (step + 1));
        UiObject file = device.findObject(new UiSelector().text(names[step]));
        // Always use a dedicated synthetic folder, never choose unrelated recent files.
        UiObject roots = device.findObject(new UiSelector().descriptionMatches("Show roots|Mostrar raízes|Open navigation drawer|Abrir menu de navegação"));
        if (roots.waitForExists(3000)) roots.click();
        UiObject downloads = device.findObject(new UiSelector().textMatches("Downloads|Download|Transferências"));
        if (downloads.waitForExists(3000)) downloads.click();
        UiObject folder = device.findObject(new UiSelector().text("USP_Validation"));
        if (folder.waitForExists(5000)) folder.click();
        UiObject listView = device.findObject(new UiSelector().descriptionMatches("List view|Visualização em lista|Vista de lista"));
        if (listView.waitForExists(2000)) listView.click();
        boolean visible = file.waitForExists(5000);
        if (!visible) {
          file = device.findObject(new UiSelector().descriptionContains(names[step]));
          visible = file.waitForExists(5000);
        }
        File image = new File(InstrumentationRegistry.getInstrumentation().getTargetContext().getCacheDir(), "native-picker.png");
        if (!device.takeScreenshot(image)) throw new AssertionError("Native picker screenshot failed");
        HttpURLConnection connection = (HttpURLConnection)new URL("http://127.0.0.1:8774/android/agent-source-picker-" + (step + 1) + ".png").openConnection();
        connection.setRequestMethod("POST"); connection.setDoOutput(true); connection.setConnectTimeout(5000); connection.setReadTimeout(5000);
        byte[] bytes = Files.readAllBytes(image.toPath());
        connection.setFixedLengthStreamingMode(bytes.length);
        try (java.io.OutputStream output = connection.getOutputStream()) { output.write(bytes); }
        if (connection.getResponseCode() != 201) throw new AssertionError("Native picker evidence was not saved");
        connection.disconnect(); image.delete();
        if (!visible) throw new AssertionError("Synthetic document not visible: " + names[step]);
        file.click();
        deadline = SystemClock.uptimeMillis() + 10000;
        while (picker(device.getCurrentPackageName()) && SystemClock.uptimeMillis() < deadline) SystemClock.sleep(100);
      }
    } catch (Throwable error) {
      // The Dart test also times out if no real document result arrives.
      Log.e("USP_NATIVE_PICKER", "Synthetic file selection failed", error);
      if (picker(device.getCurrentPackageName())) device.pressBack();
    }
  }
}
