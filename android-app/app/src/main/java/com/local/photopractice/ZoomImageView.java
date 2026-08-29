package com.local.photopractice;

import android.content.Context;
import android.graphics.Matrix;
import android.graphics.RectF;
import android.graphics.drawable.Drawable;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.widget.ImageView;

class ZoomImageView extends ImageView {
    private final Matrix matrix = new Matrix();
    private final ScaleGestureDetector detector;
    private float baseScale = 1f;
    private float userScale = 1f;
    private float lastX;
    private float lastY;
    private long lastTapTime;
    private boolean dragging;

    ZoomImageView(Context context) {
        super(context);
        setScaleType(ScaleType.MATRIX);
        detector = new ScaleGestureDetector(context, new ScaleGestureDetector.SimpleOnScaleGestureListener() {
            @Override public boolean onScale(ScaleGestureDetector d) {
                zoomBy(d.getScaleFactor(), d.getFocusX(), d.getFocusY());
                return true;
            }
        });
    }

    @Override public void setImageDrawable(Drawable drawable) {
        super.setImageDrawable(drawable);
        post(new Runnable() { @Override public void run() { resetToFitCenter(); } });
    }

    @Override protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        resetToFitCenter();
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        detector.onTouchEvent(event);
        if (event.getPointerCount() == 1) {
            switch (event.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    lastX = event.getX();
                    lastY = event.getY();
                    dragging = true;
                    return true;
                case MotionEvent.ACTION_MOVE:
                    if (dragging && userScale > 1f && !detector.isInProgress()) {
                        matrix.postTranslate(event.getX() - lastX, event.getY() - lastY);
                        keepImageInView();
                        setImageMatrix(matrix);
                        lastX = event.getX();
                        lastY = event.getY();
                    }
                    return true;
                case MotionEvent.ACTION_UP:
                    if (event.getEventTime() - event.getDownTime() < 220) {
                        long now = event.getEventTime();
                        if (now - lastTapTime < 320) {
                            toggleZoom(event.getX(), event.getY());
                            lastTapTime = 0L;
                        } else {
                            lastTapTime = now;
                        }
                    }
                    dragging = false;
                    return true;
                default:
                    return true;
            }
        }
        return true;
    }

    private void resetToFitCenter() {
        Drawable drawable = getDrawable();
        int viewWidth = getWidth();
        int viewHeight = getHeight();
        if (drawable == null || viewWidth <= 0 || viewHeight <= 0) return;
        int imageWidth = drawable.getIntrinsicWidth();
        int imageHeight = drawable.getIntrinsicHeight();
        if (imageWidth <= 0 || imageHeight <= 0) return;

        baseScale = Math.min((float) viewWidth / imageWidth, (float) viewHeight / imageHeight);
        float dx = (viewWidth - imageWidth * baseScale) / 2f;
        float dy = (viewHeight - imageHeight * baseScale) / 2f;
        userScale = 1f;
        matrix.reset();
        matrix.postScale(baseScale, baseScale);
        matrix.postTranslate(dx, dy);
        setImageMatrix(matrix);
    }

    private void toggleZoom(float x, float y) {
        if (userScale > 1f) {
            resetToFitCenter();
        } else {
            zoomBy(3f, x, y);
        }
    }

    private void zoomBy(float factor, float focusX, float focusY) {
        float next = Math.max(1f, Math.min(userScale * factor, 6f));
        float applied = next / userScale;
        userScale = next;
        if (userScale <= 1.01f) {
            resetToFitCenter();
            return;
        }
        matrix.postScale(applied, applied, focusX, focusY);
        keepImageInView();
        setImageMatrix(matrix);
    }

    private void keepImageInView() {
        Drawable drawable = getDrawable();
        if (drawable == null) return;
        RectF rect = new RectF(0, 0, drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight());
        matrix.mapRect(rect);
        float dx = 0f;
        float dy = 0f;
        if (rect.width() <= getWidth()) dx = (getWidth() - rect.width()) / 2f - rect.left;
        else if (rect.left > 0) dx = -rect.left;
        else if (rect.right < getWidth()) dx = getWidth() - rect.right;
        if (rect.height() <= getHeight()) dy = (getHeight() - rect.height()) / 2f - rect.top;
        else if (rect.top > 0) dy = -rect.top;
        else if (rect.bottom < getHeight()) dy = getHeight() - rect.bottom;
        matrix.postTranslate(dx, dy);
    }
}
