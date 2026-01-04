package com.deen.adkhar;


import android.app.SearchManager;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.GridView;
import android.widget.HorizontalScrollView;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SearchView;
import androidx.appcompat.widget.Toolbar;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.loader.app.LoaderManager;
import androidx.loader.content.Loader;


import com.deen.adkhar.adapter.CategoryGridAdapter;
import com.deen.adkhar.adapter.DuaGroupAdapter;
import com.deen.adkhar.loader.DuaGroupLoader;
import com.deen.adkhar.model.Dua;
import com.google.android.play.core.appupdate.AppUpdateInfo;
import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.UpdateAvailability;
import com.google.android.gms.tasks.Task;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;


public class DuaGroupActivity extends AppCompatActivity implements
        LoaderManager.LoaderCallbacks<List<Dua>> {
    private DuaGroupAdapter mAdapter;
    private ListView mListView;
    private GridView mGridView;
    private Toolbar toolbar;
    private HorizontalScrollView optionsScrollView;

    private View btnGridOption;
    private TextView btnListOption;
    private View btnBookmarkOption;
    private View btnSearchOption;
    private MenuItem mSearchMenuItem;

    long back_pressed;


    private static final int RC_APP_UPDATE = 100;
    private AppUpdateManager appUpdateManager;

    private String[] categories = {
            "Illness", "Daily Life", "Travel", "Morning/Night", "Prayer",
            "Wellbeing", "Trials", "Hajj/Umrah", "Quranic Duas", "Azkar"
    };

    private String[] icons = {
            "{faw-medkit}", "{faw-sun-o}", "{faw-plane}", "{faw-moon-o}", "{faw-clock-o}",
            "{faw-heart}", "{faw-exclamation-triangle}", "{faw-bank}", "{faw-book}", "{faw-list}"
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dua_group);

        View rootView = findViewById(R.id.root_dua_group);
        if (rootView != null) {
            ViewCompat.setOnApplyWindowInsetsListener(rootView, (v, windowInsets) -> {
                Insets systemBars = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars());
                v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
                return windowInsets;
            });
        }

        toolbar = (Toolbar) findViewById(R.id.my_action_bar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayShowTitleEnabled(false);
        }

        mListView = (ListView) findViewById(R.id.duaListView);
        mGridView = (GridView) findViewById(R.id.duaGridView);
        optionsScrollView = (HorizontalScrollView) findViewById(R.id.options_scroll_view);

        btnGridOption = findViewById(R.id.option_grid);
        btnListOption = findViewById(R.id.option_list);
        btnBookmarkOption = findViewById(R.id.option_bookmark);
        btnSearchOption = findViewById(R.id.option_search);

        setupOptions();

        mListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view,
                                    int position, long id) {
                openDuaDetail((Dua) parent.getAdapter().getItem(position));
            }
        });

        setupGridView();

        getSupportLoaderManager().initLoader(0, null, this);

        try {
            checkForUpdate();
        } catch (Exception e) {
            Log.e("Update", "Error initializing update manager", e);
        }
    }

    private void setupGridView() {
        CategoryGridAdapter gridAdapter = new CategoryGridAdapter(this, categories, icons);
        mGridView.setAdapter(gridAdapter);
        mGridView.setOnItemClickListener((parent, view, position, id) -> {
            List<Integer> filterIds = getFilterIdsForCategory(position);
            
            // Show ListView, Hide GridView
            mGridView.setVisibility(View.GONE);
            mListView.setVisibility(View.VISIBLE);
            updateOptionUI(false);
            centerViewInScrollView(btnListOption);

            // Reload data with filter
            Bundle args = new Bundle();
            args.putIntegerArrayList("filter_ids", new ArrayList<>(filterIds));
            getSupportLoaderManager().restartLoader(0, args, this);
            
            Toast.makeText(this, "Showing " + categories[position], Toast.LENGTH_SHORT).show();
        });
    }

    private List<Integer> getFilterIdsForCategory(int position) {
        // MAPPING: Actual Group IDs from your SQLite database
        switch (position) {
            case 0: return Arrays.asList(34, 35, 36, 37, 38, 39, 40, 41); // Illness
            case 1: return Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10); // Daily Life
            case 2: return Arrays.asList(81, 82, 83, 84, 85, 86, 87, 88); // Travel
            case 3: return Arrays.asList(27, 28); // Morning/Night
            case 4: return Arrays.asList(11, 12, 13, 14, 15, 16, 17, 18, 19, 20); // Prayer
            case 5: return Arrays.asList(42, 43, 44, 45); // Wellbeing
            case 6: return Arrays.asList(46, 47, 48, 49, 50); // Trials
            case 7: return Arrays.asList(89, 90, 91, 92); // Hajj/Umrah
            case 8: return Arrays.asList(120, 121, 122, 123); // Quranic Duas (Example IDs)
            case 9: return Arrays.asList(21, 22, 23, 24, 25, 26); // Azkar
            default: return new ArrayList<>();
        }
    }

    private void setupOptions() {
        if (btnGridOption != null) {
            btnGridOption.setOnClickListener(v -> {
                mGridView.setVisibility(View.VISIBLE);
                mListView.setVisibility(View.GONE);
                updateOptionUI(true);
                centerViewInScrollView(btnGridOption);
            });
        }

        if (btnListOption != null) {
            btnListOption.setOnClickListener(v -> {
                mGridView.setVisibility(View.GONE);
                mListView.setVisibility(View.VISIBLE);
                updateOptionUI(false);
                centerViewInScrollView(btnListOption);
                // Reset filter to show everything
                getSupportLoaderManager().restartLoader(0, null, this);
            });
        }

        if (btnBookmarkOption != null) {
            btnBookmarkOption.setOnClickListener(v -> {
                startActivity(new Intent(this, BookmarksGroupActivity.class));
            });
        }

        if (btnSearchOption != null) {
            btnSearchOption.setOnClickListener(v -> {
                if (mSearchMenuItem != null) {
                    mSearchMenuItem.expandActionView();
                }
            });
        }
    }

    private void centerViewInScrollView(View view) {
        if (optionsScrollView != null && view != null) {
            int scrollTo = view.getLeft() - (optionsScrollView.getWidth() / 2) + (view.getWidth() / 2);
            optionsScrollView.smoothScrollTo(scrollTo, 0);
        }
    }

    private void updateOptionUI(boolean isGrid) {
        if (isGrid) {
            btnGridOption.setBackgroundResource(R.drawable.bg_option_selected);
            btnListOption.setTextColor(ContextCompat.getColor(this, android.R.color.darker_gray));
        } else {
            btnGridOption.setBackground(null);
            btnListOption.setTextColor(ContextCompat.getColor(this, R.color.red_700));
        }
    }

    private void openDuaDetail(Dua selectedDua) {
        if (selectedDua == null) return;
        Intent intent = new Intent(this, DuaDetailActivity.class);
        intent.putExtra("dua_id", selectedDua.getReference());
        intent.putExtra("dua_title", selectedDua.getTitle());
        startActivity(intent);
    }

    private void checkForUpdate() {
        appUpdateManager = AppUpdateManagerFactory.create(this);
        Task<AppUpdateInfo> appUpdateInfoTask = appUpdateManager.getAppUpdateInfo();

        appUpdateInfoTask.addOnSuccessListener(appUpdateInfo -> {
            if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                    && appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                try {
                    appUpdateManager.startUpdateFlowForResult(
                            appUpdateInfo,
                            AppUpdateType.IMMEDIATE,
                            this,
                            RC_APP_UPDATE);
                } catch (IntentSender.SendIntentException e) {
                    e.printStackTrace();
                }
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (appUpdateManager != null) {
            appUpdateManager.getAppUpdateInfo().addOnSuccessListener(appUpdateInfo -> {
                if (appUpdateInfo.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS) {
                    try {
                        appUpdateManager.startUpdateFlowForResult(
                                appUpdateInfo,
                                AppUpdateType.IMMEDIATE,
                                this,
                                RC_APP_UPDATE);
                    } catch (IntentSender.SendIntentException e) {
                        e.printStackTrace();
                    }
                }
            });
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_dua_group, menu);

        SearchManager searchManager = (SearchManager) getSystemService(Context.SEARCH_SERVICE);
        mSearchMenuItem = menu.findItem(R.id.search);
        if (mSearchMenuItem != null) {
            SearchView searchView = (SearchView) mSearchMenuItem.getActionView();
            searchView.setSearchableInfo(searchManager.getSearchableInfo(getComponentName()));
            searchView.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
                @Override
                public boolean onQueryTextSubmit(String s) {
                    return false;
                }

                @Override
                public boolean onQueryTextChange(String s) {
                    if (mAdapter != null) {
                        mAdapter.getFilter().filter(s);
                    }
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
        List<Integer> filterIds = null;
        if (args != null && args.containsKey("filter_ids")) {
            filterIds = args.getIntegerArrayList("filter_ids");
        }
        return new DuaGroupLoader(this, filterIds);
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


    @Override
    protected void onStop() {
        super.onStop();
    }



    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == RC_APP_UPDATE){
            if (resultCode != RESULT_OK) {
                Log.e("Update", "Update flow failed! Result code: " + resultCode);
            }
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    public void onBackPressed() {
        if (back_pressed + 1000 > System.currentTimeMillis()){
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
        if (mAdapter != null) {
            mAdapter.setData(null);
        }
    }
}