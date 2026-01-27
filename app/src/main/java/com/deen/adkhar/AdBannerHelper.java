package com.deen.adkhar;

import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.firebase.remoteconfig.FirebaseRemoteConfig;

public final class AdBannerHelper {

    public static final String REMOTE_CONFIG_AD_UNIT = "ad_banner_unit_id";

    private AdBannerHelper() {
    }

    public static void loadBanner(Activity activity, int adViewId) {
        View view = activity.findViewById(adViewId);
        if (view == null) {
            return;
        }

        String unitId = FirebaseRemoteConfig.getInstance().getString(REMOTE_CONFIG_AD_UNIT);
        if (unitId == null || unitId.trim().isEmpty()) {
            unitId = activity.getString(R.string.ad_banner_unit_id);
        }

        AdView adView = null;
        ViewGroup container = null;
        if (view instanceof AdView) {
            adView = (AdView) view;
        } else if (view instanceof ViewGroup) {
            container = (ViewGroup) view;
            if (container.getChildCount() > 0 && container.getChildAt(0) instanceof AdView) {
                adView = (AdView) container.getChildAt(0);
            }
        }
        if (adView != null) {
            String existingId = adView.getAdUnitId();
            if (existingId == null || existingId.trim().isEmpty()) {
                adView.setAdUnitId(unitId);
            } else if (!existingId.equals(unitId) && container != null) {
                container.removeAllViews();
                adView = null;
            }
        }
        if (adView == null) {
            if (container == null) {
                return;
            }
            adView = new AdView(activity);
            adView.setAdSize(AdSize.BANNER);
            adView.setAdUnitId(unitId);
            container.addView(adView);
        }
        adView.loadAd(new AdRequest.Builder().build());
    }
}
