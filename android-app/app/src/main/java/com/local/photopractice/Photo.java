package com.local.photopractice;

import org.json.JSONObject;

class Photo {
    String filename;
    String path;
    String title;
    String photographer;
    String category;
    String award;
    String camera;
    int year;

    static Photo fromJson(JSONObject json) {
        Photo p = new Photo();
        p.filename = json.optString("filename", "");
        p.path = json.optString("path", p.filename);
        p.title = emptyToNull(json.optString("title", null));
        p.photographer = emptyToNull(json.optString("photographer", null));
        p.category = emptyToNull(json.optString("category", null));
        p.award = emptyToNull(json.optString("award", null));
        p.camera = emptyToNull(json.optString("camera_info", null));
        p.year = json.optInt("year", 0);
        return p;
    }

    static Photo fallback(String path, String filename) {
        Photo p = new Photo();
        p.path = path;
        p.filename = filename;
        p.title = filename.replace('_', ' ').replaceAll("\\.[^.]+$", "");
        p.photographer = "未知";
        p.category = "未分类";
        p.award = "无";
        return p;
    }

    Photo withLocalPath(String localPath, String localFilename) {
        Photo p = new Photo();
        p.path = localPath;
        p.filename = localFilename;
        p.title = title;
        p.photographer = photographer;
        p.category = category;
        p.award = award;
        p.camera = camera;
        p.year = year;
        return p;
    }

    JSONObject toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("filename", filename);
            json.put("path", path);
            json.put("title", title);
            json.put("photographer", photographer);
            json.put("category", category);
            json.put("award", award);
            json.put("camera_info", camera);
            json.put("year", year);
        } catch (Exception ignored) { }
        return json;
    }

    private static String emptyToNull(String value) {
        return value == null || value.length() == 0 || "null".equals(value) ? null : value;
    }
}
