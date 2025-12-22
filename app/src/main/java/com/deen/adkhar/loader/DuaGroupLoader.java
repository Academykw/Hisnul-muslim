package com.deen.adkhar.loader;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.deen.adkhar.database.HisnDatabaseInfo;
import com.deen.adkhar.model.Dua;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class DuaGroupLoader extends AbstractQueryLoader<List<Dua>> {

    public DuaGroupLoader(Context context) {
        super(context);
    }

    public Locale deviceLocale;
    public String groupTitleLanguage;

    @Override
    public List<Dua> loadInBackground() {
        List<Dua> results = null;
        Cursor duaGroupCursor = null;
        try {
            final SQLiteDatabase database = mDbHelper.getDb();
            // Query to get groups and a flag if any dua in that group is faved
            String query = "SELECT g." + HisnDatabaseInfo.DuaGroupTable._ID + ", " +
                    "g." + HisnDatabaseInfo.DuaGroupTable.ENGLISH_TITLE + ", " +
                    "(SELECT COUNT(*) FROM " + HisnDatabaseInfo.DuaTable.TABLE_NAME + 
                    " WHERE " + HisnDatabaseInfo.DuaTable.GROUP_ID + " = g." + HisnDatabaseInfo.DuaGroupTable._ID + 
                    " AND " + HisnDatabaseInfo.DuaTable.FAV + " = 1) as fav_count " +
                    "FROM " + HisnDatabaseInfo.DuaGroupTable.TABLE_NAME + " g " +
                    "ORDER BY g." + HisnDatabaseInfo.DuaGroupTable._ID;
            
            duaGroupCursor = database.rawQuery(query, null);

            if (duaGroupCursor != null && duaGroupCursor.moveToFirst()) {
                results = new ArrayList<>();
                do {
                    int dua_group_id = duaGroupCursor.getInt(0);
                    String dua_group_title = duaGroupCursor.getString(1);
                    boolean is_faved = duaGroupCursor.getInt(2) > 0;
                    results.add(new Dua(dua_group_id, dua_group_title, is_faved));
                } while (duaGroupCursor.moveToNext());
            }
        } finally {
            if (duaGroupCursor != null) {
                duaGroupCursor.close();
            }
        }

        return results;
    }
}