package com.local.photopractice;

import android.content.Context;
import android.graphics.Matrix;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.widget.ImageView;

class ZoomImageView extends ImageView {
    private final Matrix matrix = new Matrix();
    private final ScaleGestureDetector detector;
    private float scale = 1f;
    private float lastX;
    private float lastY;
    private boolean dragging;

    ZoomImageView(Context context) {
        super(context);
        setScaleType(ScaleType.MATRIX);
        detector = new ScaleGestureDetector(context, new ScaleGestureDetector.SimpleOnScaleGestureListener() {
            @Override public boolean onScale(ScaleGestureDetector d) {
                float factor = d.getScaleFactor();
                float next = Math.max(1f, Math.min(scale * factor, 6f));
                factor = next / scale;
                scale = next;
                matrix.postScale(factor, factor, d.getFocusX(), d.getFocusY());
                setImageMatrix(matrix);
                return true;
            }
        });
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
                    if (dragging && scale > 1f) {
                        matrix.postTranslate(event.getX() - lastX, event.getY() - lastY);
                        setImageMatrix(matrix);
                        lastX = event.getX();
                        lastY = event.getY();
                    }
                    return true;
                case MotionEvent.ACTION_UP:
                    if (event.getEventTime() - event.getDownTime() < 220) toggleZoom(event.getX(), event.getY());
                    dragging = false;
                    return true;
                default:
                    return true;
            }
        }
        return true;
    }

    private void toggleZoom(float x, float y) {
        if (scale > 1f) {
            scale = 1f;
            matrix.reset();
        } else {
            scale = 3f;
            matrix.postScale(3f, 3f, x, y);
        }
        setImageMatrix(matrix);
    }
}
