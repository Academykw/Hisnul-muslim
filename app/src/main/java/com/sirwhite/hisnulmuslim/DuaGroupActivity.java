package com.sirwhite.hisnulmuslim;


import android.app.SearchManager;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.content.res.Resources;
import android.os.Build;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SearchView;
import androidx.appcompat.widget.Toolbar;
import androidx.loader.app.LoaderManager;
import androidx.loader.content.Loader;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.android.material.snackbar.Snackbar;
import com.google.android.play.core.appupdate.AppUpdateInfo;
import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.install.InstallState;
import com.google.android.play.core.install.InstallStateUpdatedListener;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.InstallStatus;
import com.google.android.play.core.install.model.UpdateAvailability;
import com.google.android.play.core.review.ReviewInfo;
import com.google.android.play.core.review.ReviewManager;
import com.google.android.play.core.review.ReviewManagerFactory;
import com.google.android.play.core.review.model.ReviewErrorCode;
import com.google.android.play.core.tasks.OnSuccessListener;
import com.google.android.ump.ConsentForm;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import com.google.firebase.messaging.FirebaseMessaging;
import com.sirwhite.hisnulmuslim.adapter.DuaGroupAdapter;
import com.sirwhite.hisnulmuslim.loader.DuaGroupLoader;
import com.sirwhite.hisnulmuslim.model.Dua;

import java.util.List;


public class DuaGroupActivity extends AppCompatActivity implements
        LoaderManager.LoaderCallbacks<List<Dua>> {
    private DuaGroupAdapter mAdapter;
    private ListView mListView;
    private Toolbar toolbar;
    private AdView mAdView;
    long back_pressed;

    private AppUpdateManager mAppUpdateManager;
    private static final int RC_APP_UPDATE = 100;


    //gdpr
    private ConsentInformation consentInformation;
    private ConsentForm consentForm;



    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dua_group);

        MobileAds.initialize(this, new OnInitializationCompleteListener() {
            @Override
            public void onInitializationComplete(InitializationStatus initializationStatus) {
            }
        });



        mAdView = findViewById(R.id.adView);
        AdRequest adRequest = new AdRequest.Builder().build();
        mAdView.loadAd(adRequest);

     // LoaddAdss();

        ConsentRequestParameters params = new ConsentRequestParameters
                .Builder()
                .setTagForUnderAgeOfConsent(false)
                .build();

        consentInformation = UserMessagingPlatform.getConsentInformation(this);
        consentInformation.requestConsentInfoUpdate(
                this,
                params,
                new ConsentInformation.OnConsentInfoUpdateSuccessListener() {
                    @Override
                    public void onConsentInfoUpdateSuccess() {
                        // The consent information state was updated.
                        // You are now ready to check if a form is available.
                    }
                },
                new ConsentInformation.OnConsentInfoUpdateFailureListener() {
                    @Override
                    public void onConsentInfoUpdateFailure(FormError formError) {
                        // Handle the error.
                    }
                });
        consentInformation.requestConsentInfoUpdate(
                this,
                params,
                new ConsentInformation.OnConsentInfoUpdateSuccessListener() {
                    @Override
                    public void onConsentInfoUpdateSuccess() {
                        // The consent information state was updated.
                        // You are now ready to check if a form is available.
                        if (consentInformation.isConsentFormAvailable()) {
                            loadForm();
                        }
                    }
                },
                new ConsentInformation.OnConsentInfoUpdateFailureListener() {
                    @Override
                    public void onConsentInfoUpdateFailure(FormError formError) {
                        // Handle the error.
                    }
                });


        mAppUpdateManager= AppUpdateManagerFactory.create(this);
        mAppUpdateManager.getAppUpdateInfo().addOnSuccessListener(new OnSuccessListener<AppUpdateInfo>() {
            @Override
            public void onSuccess(AppUpdateInfo result) {

                if (result.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                        && result.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)){
                    try {
                        mAppUpdateManager.startUpdateFlowForResult(result,AppUpdateType.FLEXIBLE,DuaGroupActivity.this,
                                RC_APP_UPDATE );
                    } catch (IntentSender.SendIntentException e) {
                        e.printStackTrace();
                    }
                }

            }
        });





        FirebaseMessaging.getInstance().subscribeToTopic("News")
                .addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull Task<Void> task) {
                        String msg = "Done";
                        if (!task.isSuccessful()) {
                            msg = "Failed";
                        }

                    }
                });

        mAppUpdateManager.registerListener(installStateUpdatedListener);


        toolbar = (Toolbar) findViewById(R.id.my_action_bar);
        View mToolbarShadow = findViewById(R.id.view_toolbar_shadow);
        setSupportActionBar(toolbar);

        mListView = (ListView) findViewById(R.id.duaListView);
        mListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view,
                                    int position, long id) {
                //LoaddAdss();
                Intent intent;
                intent = new Intent(getBaseContext(),
                        DuaDetailActivity.class);

                Dua SelectedDua = (Dua) parent.getAdapter().getItem(position);
                int dua_id = SelectedDua.getReference();
                String dua_title = SelectedDua.getTitle();

                intent.putExtra("dua_id", dua_id);
                intent.putExtra("dua_title", dua_title);

                startActivity(intent);
            }
        });

        if (Build.VERSION.SDK_INT >= 21) {
            mToolbarShadow.setVisibility(View.GONE);
        }


        // For Beta Testing
        Resources resource = getResources();
        String beta_version = resource.getString(R.string.beta_version);
        Toast.makeText(this, "Beta Version: " + beta_version, Toast.LENGTH_SHORT).show();
        // End of Beta Testing

        getSupportLoaderManager().initLoader(0, null, this);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_dua_group, menu);

        SearchManager searchManager = (SearchManager) getSystemService(Context.SEARCH_SERVICE);
        SearchView searchView = (SearchView) menu.findItem(R.id.search).getActionView();
        if(searchView != null) {
            searchView.setSearchableInfo(searchManager.getSearchableInfo(getComponentName()));
            searchView.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
                @Override
                public boolean onQueryTextSubmit(String s) {
                    return false;
                }

                @Override
                public boolean onQueryTextChange(String s) {
                    mAdapter.getFilter().filter(s);
                    return true;
                }
            });
        }
        return true;
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        int id = item.getItemId();
        if (id == R.id.action_settings) {
            Intent intent = new Intent(this, PreferencesActivity.class);
            this.startActivity(intent);
        } else if (id == R.id.action_bookmarks) {
            Intent intent = new Intent(this, BookmarksGroupActivity.class);
            this.startActivity(intent);
        } else if (id == R.id.action_about) {
            Intent intent = new Intent(this, AboutActivity.class);
            this.startActivity(intent);
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public Loader<List<Dua>> onCreateLoader(int id, Bundle args) {
        return new DuaGroupLoader(this);
    }

    @Override
    public void onLoadFinished(Loader<List<Dua>> loader, List<Dua> data) {
        if (mAdapter == null) {
            mAdapter = new DuaGroupAdapter(this,data);
            mListView.setAdapter(mAdapter);
        } else {
            mAdapter.setData(data);
        }
    }
    private InstallStateUpdatedListener installStateUpdatedListener = new InstallStateUpdatedListener() {
        @Override
        public void onStateUpdate(InstallState state) {

            if (state.installStatus()  == InstallStatus.DOWNLOADED){
                showCompletedUpdate();
            }
        }
    };

    @Override
    protected void onStop() {

        if ( mAppUpdateManager != null) mAppUpdateManager.unregisterListener(installStateUpdatedListener);
        super.onStop();
    }

    private void showCompletedUpdate() {
        Snackbar snackbar = Snackbar.make(findViewById(android.R.id.content),"NEW APP UPDATE IS AVAILABLE!",
                Snackbar.LENGTH_INDEFINITE);
        snackbar.setAction("INSTALL", new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mAppUpdateManager.completeUpdate();
            }
        });


        snackbar.show();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == RC_APP_UPDATE  && requestCode != RESULT_OK){
            Toast.makeText(this,"cancel", Toast.LENGTH_SHORT).show();
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    public void onBackPressed() {
        if (back_pressed + 1000 > System.currentTimeMillis()){
           // LoaddAdss();
            super.onBackPressed();
        }
        else{
            Toast.makeText(getBaseContext(),
                            "Press once again to exit!", Toast.LENGTH_SHORT)
                    .show();

        }
        back_pressed = System.currentTimeMillis();
    }


    @Override
    public void onLoaderReset(Loader<List<Dua>> loader) {
        mAdapter.setData(null);
    }


    public void LoaddAdss(){

        MobileAds.initialize(this, new OnInitializationCompleteListener() {
            @Override
            public void onInitializationComplete(InitializationStatus initializationStatus) {
            }
        });


        AdRequest adRequest = new AdRequest.Builder().build();

        InterstitialAd.load(this,"ca-app-pub-8797909986753585/4456878156", adRequest,
                new InterstitialAdLoadCallback() {
                    @Override
                    public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {

                        Toast.makeText(DuaGroupActivity.this,"Ad Loaded", Toast.LENGTH_SHORT).show();
                        interstitialAd.show(DuaGroupActivity.this);
                        interstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                            @Override
                            public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                                super.onAdFailedToShowFullScreenContent(adError);
                                //Toast.makeText(MainActivity.this, "Faild to show Ad", Toast.LENGTH_SHORT).show();
                            }

                            @Override
                            public void onAdShowedFullScreenContent() {
                                super.onAdShowedFullScreenContent();
                                //Toast.makeText(MainActivity.this,"Ad Shown Successfully",Toast.LENGTH_SHORT).show();
                            }

                            @Override
                            public void onAdDismissedFullScreenContent() {
                                super.onAdDismissedFullScreenContent();
                                // Toast.makeText(MainActivity.this,"Ad Dismissed / Closed",Toast.LENGTH_SHORT).show();
                            }

                            @Override
                            public void onAdImpression() {
                                super.onAdImpression();
                                // Toast.makeText(MainActivity.this,"Ad Impression Count",Toast.LENGTH_SHORT).show();
                            }

                            @Override
                            public void onAdClicked() {
                                super.onAdClicked();
                                //Toast.makeText(MainActivity.this,"Ad Clicked",Toast.LENGTH_SHORT).show();
                            }
                        });
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                        //Toast.makeText(MainActivity.this,"Failed to Load Ad because="+loadAdError.getMessage(),Toast.LENGTH_SHORT).show();
                    }
                });


    }
    public void loadForm() {
        // Loads a consent form. Must be called on the main thread.
        UserMessagingPlatform.loadConsentForm(
                this,
                new UserMessagingPlatform.OnConsentFormLoadSuccessListener() {
                    @Override
                    public void onConsentFormLoadSuccess(ConsentForm consentForm) {
                        DuaGroupActivity.this.consentForm = consentForm;
                        if (consentInformation.getConsentStatus() == ConsentInformation.ConsentStatus.REQUIRED) {
                            consentForm.show(
                                    DuaGroupActivity.this,
                                    new ConsentForm.OnConsentFormDismissedListener() {
                                        @Override
                                        public void onConsentFormDismissed(@Nullable FormError formError) {
                                            if (consentInformation.getConsentStatus() == ConsentInformation.ConsentStatus.OBTAINED) {
                                                // App can start requesting ads.
                                            }

                                            // Handle dismissal by reloading form.
                                            loadForm();
                                        }
                                    });
                        }
                    }
                },
                new UserMessagingPlatform.OnConsentFormLoadFailureListener() {
                    @Override
                    public void onConsentFormLoadFailure(FormError formError) {
                        // Handle Error.
                    }
                }
        );
}
}