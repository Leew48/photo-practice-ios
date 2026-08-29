package com.local.photopractice;

import org.json.JSONObject;

class Record {
    String path;
    String title;
    String photographer;
    boolean favorite;
    long time;

    Record(String path, String title, String photographer, boolean favorite, long time) {
        this.path = path;
        this.title = title;
        this.photographer = photographer;
        this.favorite = favorite;
        this.time = time;
    }

    static Record fromJson(JSONObject json) {
        return new Record(
            json.optString("path"),
            json.optString("title"),
            json.optString("photographer"),
            json.optBoolean("favorite"),
            json.optLong("time")
        );
    }

    JSONObject toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("path", path);
            json.put("title", title);
            json.put("photographer", photographer);
            json.put("favorite", favorite);
            json.put("time", time);
        } catch (Exception ignored) { }
        return json;
    }
}
