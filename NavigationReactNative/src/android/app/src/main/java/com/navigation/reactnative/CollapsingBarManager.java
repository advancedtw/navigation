package com.navigation.reactnative;

import androidx.annotation.Nullable;

import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;

import javax.annotation.Nonnull;

public class CollapsingBarManager extends ViewGroupManager<CollapsingBarView> {

    @Nonnull
    @Override
    public String getName() {
        return "NVCollapsingBar";
    }

    @Nonnull
    @Override
    protected CollapsingBarView createViewInstance(@Nonnull ThemedReactContext reactContext) {
        return new CollapsingBarView(reactContext);
    }

    @ReactProp(name = "title")
    public void setTitle(CollapsingBarView view, @Nullable String title) {
        view.setTitle(title);
    }

    @Override
    public boolean needsCustomLayoutForChildren() {
        return true;
    }
}
