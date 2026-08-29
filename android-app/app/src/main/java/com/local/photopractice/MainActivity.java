package com.local.photopractice;

import android.app.Activity;
import android.app.Dialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.text.format.DateFormat;
import android.view.Gravity;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class MainActivity extends Activity {
    private static final int REQ_IMPORT_ZIP = 4012;
    private static final String IMPORTED_ROOT = "ImportedPhotoLibrary";
    private static final String LIBRARY_JSON = "photo-library.json";
    private static final String PREFS = "photo-practice-progress";

    private static final int INK = Color.rgb(23, 33, 36);
    private static final int MUTED = Color.rgb(98, 121, 124);
    private static final int PAPER = Color.rgb(252, 250, 240);
    private static final int FOREST = Color.rgb(23, 74, 64);
    private static final int AQUA = Color.rgb(82, 173, 179);
    private static final int MINT = Color.rgb(188, 232, 217);
    private static final int PEACH = Color.rgb(250, 161, 133);
    private static final int WHITE_GLASS = Color.argb(218, 255, 255, 255);

    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final ArrayList<Photo> photos = new ArrayList<>();
    private final Map<String, Photo> metadata = new HashMap<>();
    private final Set<String> viewed = new HashSet<>();
    private final Set<String> favorites = new HashSet<>();
    private final ArrayList<Record> records = new ArrayList<>();

    private FrameLayout content;
    private LinearLayout bottomNav;
    private SharedPreferences prefs;
    private int selectedTab = 0;
    private int currentIndex = 0;
    private String loadingMessage = "请先在设置中导入图片 ZIP。";

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        loadProgress();
        loadBundledMetadata();
        loadImportedLibrary();
        buildShell();
        showToday();
    }

    @Override protected void onDestroy() {
        executor.shutdownNow();
        super.onDestroy();
    }

    private void buildShell() {
        LinearLayout root = column();
        root.setBackgroundColor(PAPER);
        content = new FrameLayout(this);
        root.addView(content, new LinearLayout.LayoutParams(-1, 0, 1));
        bottomNav = row();
        bottomNav.setGravity(Gravity.CENTER);
        bottomNav.setPadding(dp(10), dp(8), dp(10), dp(10));
        bottomNav.setBackground(round(Color.argb(235, 58, 58, 54), dp(30)));
        LinearLayout.LayoutParams navParams = new LinearLayout.LayoutParams(-1, dp(78));
        navParams.setMargins(dp(16), dp(4), dp(16), dp(12));
        root.addView(bottomNav, navParams);
        setContentView(root);
        rebuildNav();
    }

    private void rebuildNav() {
        bottomNav.removeAllViews();
        addNavButton("今日", 0);
        addNavButton("看图", 1);
        addNavButton("图库", 2);
        addNavButton("回顾", 3);
        addNavButton("设置", 4);
    }

    private void addNavButton(String title, final int tab) {
        Button button = new Button(this);
        button.setText(title);
        button.setTextSize(13);
        button.setTypeface(Typeface.DEFAULT_BOLD);
        button.setAllCaps(false);
        button.setTextColor(tab == selectedTab ? FOREST : Color.WHITE);
        button.setBackground(round(tab == selectedTab ? Color.argb(210, 255, 255, 255) : Color.TRANSPARENT, dp(28)));
        button.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { selectTab(tab); } });
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, -1, 1);
        params.setMargins(dp(3), 0, dp(3), 0);
        bottomNav.addView(button, params);
    }

    private void selectTab(int tab) {
        selectedTab = tab;
        rebuildNav();
        if (tab == 0) showToday();
        if (tab == 1) showViewer();
        if (tab == 2) showLibrary();
        if (tab == 3) showReview();
        if (tab == 4) showSettings();
    }

    private void showToday() {
        selectedTab = 0;
        rebuildNav();
        ScrollView scroll = pageScroll();
        LinearLayout body = pageBody();
        scroll.addView(body);
        body.addView(title("看图计划", 34));
        body.addView(hero());
        LinearLayout actions = row();
        Button unseen = primaryButton("看未看照片");
        unseen.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { startSession(false); } });
        Button random = secondaryButton("随机一张");
        random.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { startSession(true); } });
        actions.addView(unseen, weightButton());
        actions.addView(random, weightButton());
        body.addView(actions, margins(0, dp(12), 0, 0));
        LinearLayout stats = row();
        stats.addView(stat("未看", String.valueOf(Math.max(photos.size() - viewed.size(), 0))), weightBox());
        stats.addView(stat("已看", String.valueOf(viewed.size())), weightBox());
        stats.addView(stat("收藏", String.valueOf(favorites.size())), weightBox());
        body.addView(stats, margins(0, dp(12), 0, dp(12)));
        body.addView(sectionTitle("今日看过"));
        int added = 0;
        for (int i = records.size() - 1; i >= 0 && added < 20; i--) {
            if (isToday(records.get(i).time)) { body.addView(recordRow(records.get(i)), margins(0, dp(8), 0, 0)); added++; }
        }
        if (added == 0) body.addView(emptyPanel(photos.isEmpty() ? loadingMessage : "今天还没有记录，先看一张好照片。"));
        setContent(scroll);
    }

    private View hero() {
        LinearLayout hero = row();
        hero.setGravity(Gravity.CENTER_VERTICAL);
        hero.setPadding(dp(16), dp(16), dp(16), dp(16));
        hero.setBackground(round(MINT, dp(8)));
        TextView progress = text(viewedTodayCount() + "\n/ 100", 24, INK, true);
        progress.setGravity(Gravity.CENTER);
        progress.setBackground(ringBg());
        hero.addView(progress, new LinearLayout.LayoutParams(dp(98), dp(98)));
        LinearLayout copy = column();
        copy.setPadding(dp(14), 0, 0, 0);
        copy.addView(text("今天", 14, MUTED, true));
        copy.addView(text(todayMessage(), 21, INK, true));
        copy.addView(text("离线图库 " + photos.size() + " 张", 14, MUTED, false));
        hero.addView(copy, new LinearLayout.LayoutParams(0, -2, 1));
        return hero;
    }

    private void showViewer() {
        selectedTab = 1;
        rebuildNav();
        if (photos.isEmpty()) { showImportPrompt(); return; }
        if (currentIndex >= photos.size()) currentIndex = 0;
        final Photo photo = photos.get(currentIndex);
        LinearLayout root = column();
        root.setBackgroundColor(PAPER);
        ImageView stage = new ImageView(this);
        stage.setScaleType(ImageView.ScaleType.FIT_CENTER);
        stage.setBackgroundColor(Color.rgb(16, 23, 31));
        loadImageInto(stage, photo, 1200);
        stage.setOnLongClickListener(new View.OnLongClickListener() { @Override public boolean onLongClick(View v) { showFullscreen(photo); return true; } });
        root.addView(stage, heightMargins(dp(340), dp(16), dp(8), dp(16), dp(10)));
        ScrollView scroll = pageScroll();
        LinearLayout body = pageBody();
        scroll.addView(body);
        body.addView(metadataPanel(photo));
        body.addView(observationPanel());
        root.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
        setContent(root);
    }

    private void showImportPrompt() {
        ScrollView scroll = pageScroll();
        LinearLayout body = pageBody();
        scroll.addView(body);
        body.addView(emptyPanel(loadingMessage));
        Button b = primaryButton("导入图片 ZIP");
        b.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { pickZip(); } });
        body.addView(b, margins(0, dp(14), 0, 0));
        setContent(scroll);
    }

    private View metadataPanel(Photo p) {
        LinearLayout panel = panel();
        panel.addView(badge((currentIndex + 1) + " / " + photos.size()));
        panel.addView(text(nullTo(p.title, p.filename), 24, INK, true), margins(0, dp(10), 0, dp(8)));
        LinearLayout row1 = row();
        row1.addView(infoTile("摄影人", nullTo(p.photographer, "未知")), weightBox());
        row1.addView(infoTile("年份", p.year > 0 ? String.valueOf(p.year) : "未知"), weightBox());
        panel.addView(row1);
        LinearLayout row2 = row();
        row2.addView(infoTile("分类", nullTo(p.category, "未分类")), weightBox());
        row2.addView(infoTile("奖项", nullTo(p.award, "无")), weightBox());
        panel.addView(row2);
        if (p.camera != null && p.camera.length() > 0) panel.addView(text(p.camera, 13, MUTED, false));
        return panel;
    }

    private View observationPanel() {
        LinearLayout panel = panel();
        panel.addView(sectionTitle("一句观察"));
        final EditText edit = new EditText(this);
        edit.setHint("写下这一张照片最打动你的地方");
        edit.setTextSize(15);
        edit.setTextColor(INK);
        edit.setHintTextColor(Color.argb(150, 98, 121, 124));
        edit.setMinLines(3);
        edit.setGravity(Gravity.TOP | Gravity.START);
        edit.setSingleLine(false);
        edit.setImeOptions(EditorInfo.IME_ACTION_DONE);
        edit.setBackground(round(Color.argb(188, 255, 255, 255), dp(8), Color.argb(90, 82, 173, 179), 1));
        panel.addView(edit, heightMargins(dp(96), 0, dp(8), 0, dp(12)));
        String[] tags = {"构图", "光线", "色彩", "主体", "瞬间", "层次"};
        for (int i = 0; i < tags.length; i += 3) {
            LinearLayout tagRow = row();
            for (int j = i; j < i + 3 && j < tags.length; j++) tagRow.addView(secondaryButton(tags[j]), weightButton());
            panel.addView(tagRow, margins(0, dp(6), 0, 0));
        }
        LinearLayout nav = row();
        Button prev = secondaryButton("上一张");
        prev.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { hideKeyboard(edit); previousPhoto(); } });
        Button later = secondaryButton("稍后");
        later.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { hideKeyboard(edit); nextPhoto(); } });
        nav.addView(prev, weightButton());
        nav.addView(later, weightButton());
        panel.addView(nav, margins(0, dp(12), 0, 0));
        LinearLayout marks = row();
        Button seen = primaryButton("已看");
        seen.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { hideKeyboard(edit); markCurrent(false); } });
        Button fav = secondaryButton("收藏");
        fav.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { hideKeyboard(edit); markCurrent(true); } });
        marks.addView(seen, weightButton());
        marks.addView(fav, weightButton());
        panel.addView(marks, margins(0, dp(10), 0, 0));
        return panel;
    }

    private void showLibrary() {
        selectedTab = 2;
        rebuildNav();
        ScrollView scroll = pageScroll();
        LinearLayout body = pageBody();
        scroll.addView(body);
        body.addView(title("图库", 32));
        body.addView(text("已导入 " + photos.size() + " 张 · 已看 " + viewed.size() + " · 收藏 " + favorites.size(), 15, MUTED, false));
        for (int i = 0; i < Math.min(photos.size(), 80); i++) {
            final int idx = i;
            Photo p = photos.get(i);
            Button row = secondaryButton((i + 1) + ". " + nullTo(p.title, p.filename));
            row.setGravity(Gravity.START | Gravity.CENTER_VERTICAL);
            row.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { currentIndex = idx; showViewer(); } });
            body.addView(row, margins(0, dp(8), 0, 0));
        }
        if (photos.isEmpty()) body.addView(emptyPanel("还没有导入图片 ZIP。"));
        setContent(scroll);
    }

    private void showReview() {
        selectedTab = 3;
        rebuildNav();
        ScrollView scroll = pageScroll();
        LinearLayout body = pageBody();
        scroll.addView(body);
        body.addView(title("回顾", 32));
        if (records.isEmpty()) body.addView(emptyPanel("还没有看图记录。"));
        for (int i = records.size() - 1; i >= 0; i--) body.addView(recordRow(records.get(i)), margins(0, dp(8), 0, 0));
        setContent(scroll);
    }

    private void showSettings() {
        selectedTab = 4;
        rebuildNav();
        ScrollView scroll = pageScroll();
        LinearLayout body = pageBody();
        scroll.addView(body);
        body.addView(title("设置", 32));
        body.addView(text("安卓版本可以直接安装 APK 测试，不需要 Apple 签名，也不用开发者模式。", 15, MUTED, false));
        Button importButton = primaryButton("导入图片 ZIP");
        importButton.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { pickZip(); } });
        body.addView(importButton, margins(0, dp(16), 0, 0));
        Button appSettings = secondaryButton("打开系统应用设置");
        appSettings.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { openSystemSettings(); } });
        body.addView(appSettings, margins(0, dp(10), 0, 0));
        body.addView(emptyPanel("导入格式：把 PhotoLibrary.zip 放到手机文件里，在这里选择 ZIP。App 会复制到本机私有目录并离线使用。"), margins(0, dp(14), 0, 0));
        setContent(scroll);
    }

    private void pickZip() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("application/zip");
        startActivityForResult(intent, REQ_IMPORT_ZIP);
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQ_IMPORT_ZIP && resultCode == RESULT_OK && data != null && data.getData() != null) importZip(data.getData());
    }

    private void importZip(final Uri uri) {
        loadingMessage = "正在导入图片包，请保持 App 打开...";
        showSettings();
        executor.execute(new Runnable() {
            @Override public void run() {
                try {
                    final int count = extractAndScan(uri);
                    runOnUiThread(new Runnable() { @Override public void run() {
                        Toast.makeText(MainActivity.this, "导入完成：" + count + " 张", Toast.LENGTH_LONG).show();
                        loadingMessage = "";
                        showToday();
                    }});
                } catch (final Exception e) {
                    runOnUiThread(new Runnable() { @Override public void run() {
                        loadingMessage = "导入失败：" + e.getMessage();
                        Toast.makeText(MainActivity.this, loadingMessage, Toast.LENGTH_LONG).show();
                        showSettings();
                    }});
                }
            }
        });
    }

    private int extractAndScan(Uri uri) throws Exception {
        File root = new File(getFilesDir(), IMPORTED_ROOT);
        File staging = new File(getFilesDir(), IMPORTED_ROOT + "-staging");
        deleteRecursively(staging);
        staging.mkdirs();
        InputStream input = getContentResolver().openInputStream(uri);
        if (input == null) throw new IllegalStateException("无法打开 ZIP 文件");
        ZipInputStream zip = new ZipInputStream(new BufferedInputStream(input));
        ZipEntry entry;
        byte[] buffer = new byte[1024 * 64];
        while ((entry = zip.getNextEntry()) != null) {
            String name = normalizePath(entry.getName());
            if (name.length() == 0 || name.contains("../")) continue;
            File out = new File(staging, name);
            if (entry.isDirectory()) {
                out.mkdirs();
            } else if (isImage(name) || name.endsWith("manifest.json") || name.endsWith("photo-manifest.json")) {
                File parent = out.getParentFile();
                if (parent != null) parent.mkdirs();
                BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(out));
                int read;
                while ((read = zip.read(buffer)) != -1) bos.write(buffer, 0, read);
                bos.close();
            }
            zip.closeEntry();
        }
        zip.close();
        ArrayList<Photo> scanned = scanPhotos(staging);
        if (scanned.isEmpty()) throw new IllegalStateException("压缩包里没有找到图片");
        saveLibraryJson(scanned, staging);
        deleteRecursively(root);
        if (!staging.renameTo(root)) throw new IllegalStateException("保存图库失败");
        photos.clear();
        photos.addAll(scanned);
        currentIndex = 0;
        saveProgress();
        return photos.size();
    }

    private ArrayList<Photo> scanPhotos(File root) {
        ArrayList<File> files = new ArrayList<>();
        collectImages(root, files);
        Collections.sort(files, new Comparator<File>() { @Override public int compare(File a, File b) { return a.getPath().compareToIgnoreCase(b.getPath()); } });
        ArrayList<Photo> result = new ArrayList<>();
        for (File file : files) {
            String rel = normalizePath(root.toURI().relativize(file.toURI()).getPath());
            Photo meta = matchMetadata(rel, file.getName());
            result.add(meta != null ? meta.withLocalPath(rel, file.getName()) : Photo.fallback(rel, file.getName()));
        }
        return result;
    }

    private void collectImages(File dir, ArrayList<File> files) {
        File[] children = dir.listFiles();
        if (children == null) return;
        for (File child : children) {
            if (child.isDirectory()) collectImages(child, files);
            else if (isImage(child.getName())) files.add(child);
        }
    }

    private void loadBundledMetadata() {
        try {
            JSONArray arr = new JSONObject(readAll(getAssets().open("PhotoMetadata/ippawards-metadata.json"))).getJSONArray("photos");
            for (int i = 0; i < arr.length(); i++) {
                Photo p = Photo.fromJson(arr.getJSONObject(i));
                indexMetadata(p.path, p);
                indexMetadata(lookupPath(p.path), p);
                indexMetadata(p.filename, p);
            }
        } catch (Exception e) {
            loadingMessage = "元数据读取失败：" + e.getMessage();
        }
    }

    private void loadImportedLibrary() {
        try {
            File file = new File(new File(getFilesDir(), IMPORTED_ROOT), LIBRARY_JSON);
            if (!file.exists()) return;
            JSONArray arr = new JSONObject(readAll(new FileInputStream(file))).getJSONArray("photos");
            photos.clear();
            for (int i = 0; i < arr.length(); i++) {
                Photo local = Photo.fromJson(arr.getJSONObject(i));
                Photo meta = matchMetadata(local.path, local.filename);
                photos.add(meta != null ? meta.withLocalPath(local.path, local.filename) : local);
            }
            loadingMessage = photos.isEmpty() ? "图库为空。" : "";
        } catch (Exception e) {
            loadingMessage = "图库读取失败：" + e.getMessage();
        }
    }

    private void saveLibraryJson(ArrayList<Photo> list, File root) throws Exception {
        JSONArray arr = new JSONArray();
        for (Photo p : list) arr.put(p.toJson());
        JSONObject json = new JSONObject();
        json.put("photos", arr);
        FileOutputStream out = new FileOutputStream(new File(root, LIBRARY_JSON));
        out.write(json.toString().getBytes(StandardCharsets.UTF_8));
        out.close();
    }

    private Photo matchMetadata(String path, String filename) {
        Photo p = metadata.get(normalizePath(path).toLowerCase(Locale.ROOT));
        if (p == null) p = metadata.get(lookupPath(path).toLowerCase(Locale.ROOT));
        if (p == null) p = metadata.get(filename.toLowerCase(Locale.ROOT));
        return p;
    }

    private void indexMetadata(String key, Photo photo) {
        if (key != null && key.length() > 0) metadata.put(normalizePath(key).toLowerCase(Locale.ROOT), photo);
    }

    private void startSession(boolean random) {
        if (photos.isEmpty()) { showViewer(); return; }
        if (random) currentIndex = (int) (Math.random() * photos.size());
        else for (int i = 0; i < photos.size(); i++) if (!viewed.contains(photos.get(i).path)) { currentIndex = i; break; }
        showViewer();
    }

    private void previousPhoto() {
        if (photos.isEmpty()) return;
        currentIndex = (currentIndex - 1 + photos.size()) % photos.size();
        saveProgress();
        showViewer();
    }

    private void nextPhoto() {
        if (photos.isEmpty()) return;
        currentIndex = (currentIndex + 1) % photos.size();
        saveProgress();
        showViewer();
    }

    private void markCurrent(boolean favorite) {
        if (photos.isEmpty()) return;
        Photo p = photos.get(currentIndex);
        viewed.add(p.path);
        if (favorite) favorites.add(p.path);
        records.add(new Record(p.path, nullTo(p.title, p.filename), nullTo(p.photographer, "未知摄影人"), favorite, System.currentTimeMillis()));
        saveProgress();
        nextPhoto();
    }

    private void loadProgress() {
        viewed.clear();
        favorites.clear();
        viewed.addAll(prefs.getStringSet("viewed", new HashSet<String>()));
        favorites.addAll(prefs.getStringSet("favorites", new HashSet<String>()));
        currentIndex = prefs.getInt("currentIndex", 0);
        try {
            JSONArray arr = new JSONArray(prefs.getString("records", "[]"));
            records.clear();
            for (int i = 0; i < arr.length(); i++) records.add(Record.fromJson(arr.getJSONObject(i)));
        } catch (Exception ignored) { }
    }

    private void saveProgress() {
        JSONArray arr = new JSONArray();
        for (Record r : records) arr.put(r.toJson());
        prefs.edit()
            .putStringSet("viewed", new HashSet<>(viewed))
            .putStringSet("favorites", new HashSet<>(favorites))
            .putInt("currentIndex", currentIndex)
            .putString("records", arr.toString())
            .apply();
    }

    private void loadImageInto(ImageView view, Photo photo, int maxSize) {
        File file = imageFile(photo);
        if (file == null || !file.exists()) return;
        BitmapFactory.Options bounds = new BitmapFactory.Options();
        bounds.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(file.getPath(), bounds);
        int sample = 1;
        while ((bounds.outWidth / sample) > maxSize || (bounds.outHeight / sample) > maxSize) sample *= 2;
        BitmapFactory.Options opts = new BitmapFactory.Options();
        opts.inSampleSize = sample;
        view.setImageBitmap(BitmapFactory.decodeFile(file.getPath(), opts));
    }

    private File imageFile(Photo photo) {
        File file = new File(new File(getFilesDir(), IMPORTED_ROOT), photo.path);
        if (file.exists()) return file;
        return findByFilename(photo.filename);
    }

    private File findByFilename(String filename) {
        File root = new File(getFilesDir(), IMPORTED_ROOT);
        ArrayList<File> files = new ArrayList<>();
        collectImages(root, files);
        for (File f : files) if (f.getName().equalsIgnoreCase(filename)) return f;
        return null;
    }

    private void showFullscreen(Photo photo) {
        File file = imageFile(photo);
        if (file == null || !file.exists()) return;
        Bitmap bitmap = BitmapFactory.decodeFile(file.getPath());
        if (bitmap == null) return;
        final Dialog dialog = new Dialog(this, android.R.style.Theme_Black_NoTitleBar_Fullscreen);
        FrameLayout frame = new FrameLayout(this);
        frame.setBackgroundColor(Color.BLACK);
        ZoomImageView zoom = new ZoomImageView(this);
        zoom.setImageBitmap(bitmap);
        frame.addView(zoom, new FrameLayout.LayoutParams(-1, -1));
        ImageButton close = new ImageButton(this);
        close.setImageResource(android.R.drawable.ic_menu_close_clear_cancel);
        close.setColorFilter(Color.WHITE);
        close.setBackground(round(Color.argb(120, 0, 0, 0), dp(24)));
        close.setOnClickListener(new View.OnClickListener() { @Override public void onClick(View v) { dialog.dismiss(); } });
        FrameLayout.LayoutParams closeParams = new FrameLayout.LayoutParams(dp(48), dp(48), Gravity.TOP | Gravity.END);
        closeParams.setMargins(0, dp(22), dp(16), 0);
        frame.addView(close, closeParams);
        dialog.setContentView(frame);
        dialog.show();
    }

    private View stat(String label, String value) {
        LinearLayout tile = column();
        tile.setPadding(dp(10), dp(9), dp(10), dp(8));
        tile.setBackground(round(WHITE_GLASS, dp(8)));
        tile.addView(text(label, 13, MUTED, false));
        tile.addView(text(value, 22, INK, true));
        return tile;
    }

    private View infoTile(String label, String value) {
        LinearLayout tile = column();
        tile.setPadding(dp(10), dp(8), dp(10), dp(8));
        tile.setBackground(round(Color.argb(184, 255, 255, 255), dp(8)));
        tile.addView(text(label, 13, MUTED, false));
        tile.addView(text(value, 17, INK, true));
        return tile;
    }

    private TextView recordRow(Record r) {
        TextView row = text(r.title + "\n" + r.photographer + " · " + DateFormat.format("HH:mm", r.time), 15, INK, true);
        row.setPadding(dp(14), dp(10), dp(14), dp(10));
        row.setBackground(round(Color.argb(150, 255, 255, 255), dp(8)));
        return row;
    }

    private TextView emptyPanel(String message) {
        TextView view = text(message, 15, MUTED, false);
        view.setGravity(Gravity.CENTER);
        view.setPadding(dp(20), dp(24), dp(20), dp(24));
        view.setBackground(round(WHITE_GLASS, dp(8)));
        return view;
    }

    private LinearLayout panel() {
        LinearLayout panel = column();
        panel.setPadding(dp(16), dp(16), dp(16), dp(16));
        panel.setBackground(round(WHITE_GLASS, dp(8)));
        panel.setLayoutParams(margins(0, 0, 0, dp(14)));
        return panel;
    }

    private TextView badge(String value) {
        TextView badge = text(value, 14, Color.WHITE, true);
        badge.setPadding(dp(10), dp(6), dp(10), dp(6));
        badge.setBackground(round(PEACH, dp(8)));
        return badge;
    }

    private TextView title(String value, int sp) { return text(value, sp, INK, true); }
    private TextView sectionTitle(String value) { return text(value, 20, INK, true); }

    private TextView text(String value, int sp, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(sp);
        t.setTextColor(color);
        if (bold) t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setIncludeFontPadding(true);
        return t;
    }

    private Button primaryButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextColor(Color.WHITE);
        b.setTextSize(15);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setBackground(round(AQUA, dp(8)));
        return b;
    }

    private Button secondaryButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextColor(FOREST);
        b.setTextSize(15);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setBackground(round(Color.argb(220, 255, 255, 255), dp(8), Color.argb(70, 82, 173, 179), 1));
        return b;
    }

    private ScrollView pageScroll() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(false);
        scroll.setBackgroundColor(PAPER);
        return scroll;
    }

    private LinearLayout pageBody() {
        LinearLayout body = column();
        body.setPadding(dp(16), dp(18), dp(16), dp(104));
        return body;
    }

    private LinearLayout row() {
        LinearLayout l = new LinearLayout(this);
        l.setOrientation(LinearLayout.HORIZONTAL);
        return l;
    }

    private LinearLayout column() {
        LinearLayout l = new LinearLayout(this);
        l.setOrientation(LinearLayout.VERTICAL);
        return l;
    }

    private void setContent(View view) {
        content.removeAllViews();
        content.addView(view, new FrameLayout.LayoutParams(-1, -1));
    }

    private LinearLayout.LayoutParams margins(int l, int t, int r, int b) {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
        p.setMargins(l, t, r, b);
        return p;
    }

    private LinearLayout.LayoutParams heightMargins(int h, int l, int t, int r, int b) {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, h);
        p.setMargins(l, t, r, b);
        return p;
    }

    private LinearLayout.LayoutParams weightButton() {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, dp(50), 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        return p;
    }

    private LinearLayout.LayoutParams weightBox() {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, dp(82), 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        return p;
    }

    private GradientDrawable round(int color, int radius) { return round(color, radius, Color.TRANSPARENT, 0); }

    private GradientDrawable round(int color, int radius, int strokeColor, int strokeWidth) {
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(color);
        gd.setCornerRadius(radius);
        if (strokeWidth > 0) gd.setStroke(strokeWidth, strokeColor);
        return gd;
    }

    private GradientDrawable ringBg() {
        GradientDrawable gd = new GradientDrawable();
        gd.setShape(GradientDrawable.OVAL);
        gd.setColor(Color.argb(80, 255, 255, 255));
        gd.setStroke(dp(10), PEACH);
        return gd;
    }

    private int dp(int value) { return (int) (value * getResources().getDisplayMetrics().density + 0.5f); }
    private String nullTo(String value, String fallback) { return value == null || value.length() == 0 ? fallback : value; }
    private String normalizePath(String s) { return s == null ? "" : s.replace('\\', '/').replace("//", "/"); }
    private boolean isImage(String name) {
        String n = name.toLowerCase(Locale.ROOT);
        return n.endsWith(".jpg") || n.endsWith(".jpeg") || n.endsWith(".png") || n.endsWith(".webp") || n.endsWith(".heic");
    }

    private String lookupPath(String path) {
        String p = normalizePath(path);
        int idx = p.indexOf("/photos/");
        if (idx >= 0) return p.substring(idx + 8);
        int slash = p.lastIndexOf('/');
        return slash >= 0 ? p.substring(slash + 1) : p;
    }

    private String todayMessage() {
        if (photos.isEmpty()) return "先准备离线图库。";
        int count = viewedTodayCount();
        if (count >= 100) return "今天的训练完成了。";
        if (count > 0) return "接着看，别让进度丢了。";
        return "先看一张好照片。";
    }

    private int viewedTodayCount() {
        int count = 0;
        for (Record r : records) if (isToday(r.time)) count++;
        return count;
    }

    private boolean isToday(long millis) {
        Calendar a = Calendar.getInstance();
        Calendar b = Calendar.getInstance();
        b.setTimeInMillis(millis);
        return a.get(Calendar.YEAR) == b.get(Calendar.YEAR) && a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR);
    }

    private void hideKeyboard(View view) {
        InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        if (imm != null) imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
        view.clearFocus();
    }

    private void openSystemSettings() {
        startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + getPackageName())));
    }

    private String readAll(InputStream input) throws Exception {
        byte[] buffer = new byte[1024 * 64];
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        int read;
        while ((read = input.read(buffer)) != -1) out.write(buffer, 0, read);
        input.close();
        return new String(out.toByteArray(), StandardCharsets.UTF_8);
    }

    private void deleteRecursively(File file) {
        if (file == null || !file.exists()) return;
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) for (File child : children) deleteRecursively(child);
        }
        file.delete();
    }
}
