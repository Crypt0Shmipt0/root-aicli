package dev.rootaicli;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.Button;
import android.widget.ScrollView;
import android.widget.TextView;
import java.io.BufferedReader;
import java.io.InputStreamReader;

/**
 * Root.AICLI - thin Android shell around bash modules that install AI CLIs
 * inside Termux. The actual install logic lives in modules/*.sh on disk; this
 * Activity is just the button surface + log streaming.
 *
 * Key implementation notes:
 *
 *  - Every action uses {@code su -mm} (mount-master) so the resulting root
 *    process can see /data/data/com.termux/files. Without -mm, Magisk gives
 *    apps an isolated mount namespace where other apps' private storage is
 *    invisible.
 *
 *  - We invoke Termux's bash with the absolute path and set
 *    LD_LIBRARY_PATH=$PREFIX/lib so it loads its own libc. The shebang chain
 *    /usr/bin/env bash fails outside Termux because /system/bin/sh's PATH
 *    doesn't include $PREFIX/bin.
 *
 *  - Process stdout streams back to the TextView via Handler.post on the main
 *    thread. errStream is merged into stdout with redirectErrorStream(true).
 */
public class MainActivity extends Activity {

    private static final String TWEAKS_DIR = "/data/data/com.termux/files/home/root-aicli";

    private TextView output;
    private final Handler ui = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        output = findViewById(R.id.output);

        bind(R.id.btn_status,    "status");
        bind(R.id.btn_claude,    "claude");
        bind(R.id.btn_agy,       "agy");
        bind(R.id.btn_codex,     "codex");
        bind(R.id.btn_grok,      "grok");
        bind(R.id.btn_all,       "all");
        bind(R.id.btn_permanent, "permanent");

        findViewById(R.id.btn_clear).setOnClickListener(v -> output.setText(""));
    }

    private void bind(int id, String action) {
        Button b = findViewById(id);
        b.setOnClickListener(v -> {
            disableAll(true);
            output.setText("");
            append("$ root-aicli " + action + "\n\n");

            String cmd = "export HOME=/data/data/com.termux/files/home; "
                + "export PREFIX=/data/data/com.termux/files/usr; "
                + "export TMPDIR=$PREFIX/tmp; "
                + "export PATH=$PREFIX/bin:$PATH; "
                + "export LD_LIBRARY_PATH=$PREFIX/lib; "
                + "export ROOT_AICLI_YES=1; "
                + "export NO_COLOR=1; "
                + "cd $HOME 2>/dev/null || cd /; "
                + "$PREFIX/bin/bash " + TWEAKS_DIR + "/root-aicli " + action;

            new Thread(() -> {
                int code = runProcess(cmd);
                ui.post(() -> {
                    append("\n[exit " + code + "]\n");
                    disableAll(false);
                });
            }).start();
        });
    }

    private int runProcess(String cmd) {
        try {
            ProcessBuilder pb = new ProcessBuilder("su", "-mm", "-c", cmd);
            pb.redirectErrorStream(true);
            Process p = pb.start();
            BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream()));
            String line;
            while ((line = r.readLine()) != null) {
                final String l = line;
                ui.post(() -> append(l + "\n"));
            }
            return p.waitFor();
        } catch (Exception e) {
            ui.post(() -> append("ERROR: " + e.getMessage() + "\n"));
            return -1;
        }
    }

    private void append(String s) {
        output.append(s);
        ScrollView sv = (ScrollView) output.getParent();
        sv.post(() -> sv.fullScroll(View.FOCUS_DOWN));
    }

    private void disableAll(boolean disabled) {
        int[] ids = { R.id.btn_status, R.id.btn_claude, R.id.btn_agy,
                      R.id.btn_codex, R.id.btn_grok, R.id.btn_all,
                      R.id.btn_permanent };
        for (int id : ids) findViewById(id).setEnabled(!disabled);
    }
}
