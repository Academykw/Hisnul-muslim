package com.deen.adkhar;

import android.content.Intent;
import android.os.Bundle;
import android.view.MenuItem;
import android.widget.ListView;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.loader.app.LoaderManager;
import androidx.loader.content.Loader;
import com.deen.adkhar.adapter.DuaGroupAdapter;
import com.deen.adkhar.loader.DuaGroupLoader;
import com.deen.adkhar.model.Dua;
import java.util.ArrayList;
import java.util.List;

public class FilteredDuaListActivity extends AppCompatActivity implements LoaderManager.LoaderCallbacks<List<Dua>> {
    private DuaGroupAdapter mAdapter;
    private ListView mListView;
    private ArrayList<Integer> filterIds;
    private String categoryTitle;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_filtered_dua_list);

        filterIds = getIntent().getIntegerArrayListExtra("filter_ids");
        categoryTitle = getIntent().getStringExtra("category_title");

        Toolbar toolbar = findViewById(R.id.filtered_toolbar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle(categoryTitle);
        }

        mListView = findViewById(R.id.filteredListView);
        mListView.setOnItemClickListener((parent, view, position, id) -> {
            Dua selectedDua = (Dua) parent.getAdapter().getItem(position);
            Intent intent = new Intent(this, DuaDetailActivity.class);
            intent.putExtra("dua_id", selectedDua.getReference());
            intent.putExtra("dua_title", selectedDua.getTitle());
            startActivity(intent);
        });

        getSupportLoaderManager().initLoader(0, null, this);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public Loader<List<Dua>> onCreateLoader(int id, Bundle args) {
        return new DuaGroupLoader(this, filterIds);
    }

    @Override
    public void onLoadFinished(Loader<List<Dua>> loader, List<Dua> data) {
        if (mAdapter == null) {
            mAdapter = new DuaGroupAdapter(this, data);
            mListView.setAdapter(mAdapter);
        } else {
            mAdapter.setData(data);
        }
    }

    @Override
    public void onLoaderReset(Loader<List<Dua>> loader) {
        if (mAdapter != null) mAdapter.setData(null);
    }
}
