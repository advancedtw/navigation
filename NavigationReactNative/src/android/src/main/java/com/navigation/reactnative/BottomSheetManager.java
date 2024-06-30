package com.navigation.reactnative;

import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.PixelUtil;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.google.android.material.bottomsheet.BottomSheetBehavior;

import java.util.Map;

public class BottomSheetManager extends ViewGroupManager<BottomSheetView> {
    @NonNull
    @Override
    public String getName() {
        return "NVBottomSheet";
    }

    @NonNull
    @Override
    protected BottomSheetView createViewInstance(@NonNull ThemedReactContext reactContext) {
        return new BottomSheetView(reactContext);
    }

    @ReactProp(name = "detent")
    public void setDetent(BottomSheetView view, String detent) {
        view.pendingDetent = Integer.parseInt(detent);
    }

    @ReactProp(name = "mostRecentEventCount")
    public void setMostRecentEventCount(BottomSheetView view, int mostRecentEventCount) {
        view.mostRecentEventCount = mostRecentEventCount;
    }

    @ReactProp(name = "fragmentTag")
    public void setFragmentTag(BottomSheetView view, String fragmentTag) {
        view.fragmentTag = fragmentTag;
    }

    @ReactProp(name = "ancestorFragmentTags")
    public void setAncestorFragmentTags(BottomSheetView view, ReadableArray ancestorFragmentTags) {
        view.ancestorFragmentTags = ancestorFragmentTags;
    }

    @ReactProp(name = "peekHeight")
    public void setPeekHeight(BottomSheetView view, int peekHeight) {
        view.bottomSheetBehavior.setPeekHeight(peekHeight != 0 ? (int) PixelUtil.toPixelFromDIP(peekHeight) : BottomSheetBehavior.PEEK_HEIGHT_AUTO, true);
    }

    @ReactProp(name = "expandedOffset")
    public void setExpandedOffset(BottomSheetView view, int expandedOffset) {
        view.bottomSheetBehavior.setExpandedOffset((int) PixelUtil.toPixelFromDIP(expandedOffset));
        view.requestLayout();
    }

    @ReactProp(name = "fitToContents")
    public void setFitToContents(BottomSheetView view, boolean fitToContents) {
        view.bottomSheetBehavior.setFitToContents(fitToContents);
    }

    @ReactProp(name = "height")
    public void setHeight(BottomSheetView view, double height) {
        view.getLayoutParams().height = height != 0 ? (int) PixelUtil.toPixelFromDIP(height) : ViewGroup.LayoutParams.WRAP_CONTENT;
        view.requestLayout();
        if (view.getParent() != null)
            view.getParent().requestLayout();
    }

    @ReactProp(name = "halfExpandedRatio", defaultFloat = Float.MAX_VALUE)
    public void setHalfExpandedRatio(BottomSheetView view, float halfExpandedRatio) {
        view.bottomSheetBehavior.setHalfExpandedRatio(halfExpandedRatio != Float.MAX_VALUE ? halfExpandedRatio : view.defaultHalfExpandedRatio);
        view.requestLayout();
    }

    @ReactProp(name = "hideable")
    public void setHideable(BottomSheetView view, boolean hideable) {
        view.bottomSheetBehavior.setHideable(hideable);
    }

    @ReactProp(name = "skipCollapsed")
    public void setSkipCollapsed(BottomSheetView view, boolean skipCollapsed) {
        view.bottomSheetBehavior.setSkipCollapsed(skipCollapsed);
    }

    @ReactProp(name = "draggable")
    public void setDraggable(BottomSheetView view, boolean draggable) {
        view.bottomSheetBehavior.setDraggable(draggable);
    }

    @Override
    protected void onAfterUpdateTransaction(@NonNull BottomSheetView view) {
        super.onAfterUpdateTransaction(view);
        view.onAfterUpdateTransaction();
    }

    @Nullable
    @Override
    public Map<String, Object> getExportedCustomDirectEventTypeConstants() {
        return MapBuilder.<String, Object>builder()
            .put("topDetentChanged", MapBuilder.of("registrationName", "onDetentChanged"))
            .build();
    }

    @Nullable
    @Override
    public Map<String, Object> getExportedViewConstants() {
        return MapBuilder.of(
            "Detent",
            MapBuilder.of(
                "hidden", BottomSheetBehavior.STATE_HIDDEN,
                "collapsed", BottomSheetBehavior.STATE_COLLAPSED,
                "halfExpanded", BottomSheetBehavior.STATE_HALF_EXPANDED,
                "expanded", BottomSheetBehavior.STATE_EXPANDED));
    }
}
