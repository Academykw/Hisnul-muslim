package com.deen.adkhar.loader;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.deen.adkhar.database.HisnDatabaseInfo;
import com.deen.adkhar.model.Dua;

import java.util.ArrayList;
import java.util.List;

public class DuaGroupLoader extends AbstractQueryLoader<List<Dua>> {

    private List<Integer> mFilterIds;

    public DuaGroupLoader(Context context) {
        super(context);
    }

    public DuaGroupLoader(Context context, List<Integer> filterIds) {
        super(context);
        this.mFilterIds = filterIds;
    }

    @Override
    public List<Dua> loadInBackground() {
        List<Dua> results = null;
        Cursor duaGroupCursor = null;
        try {
            final SQLiteDatabase database = mDbHelper.getDb();
            
            StringBuilder queryBuilder = new StringBuilder();
            queryBuilder.append("SELECT g.").append(HisnDatabaseInfo.DuaGroupTable._ID).append(", ")
                    .append("g.").append(HisnDatabaseInfo.DuaGroupTable.ENGLISH_TITLE).append(", ")
                    .append("(SELECT COUNT(*) FROM ").append(HisnDatabaseInfo.DuaTable.TABLE_NAME)
                    .append(" WHERE ").append(HisnDatabaseInfo.DuaTable.GROUP_ID).append(" = g.").append(HisnDatabaseInfo.DuaGroupTable._ID)
                    .append(" AND ").append(HisnDatabaseInfo.DuaTable.FAV).append(" = 1) as fav_count ")
                    .append("FROM ").append(HisnDatabaseInfo.DuaGroupTable.TABLE_NAME).append(" g ");

            if (mFilterIds != null && !mFilterIds.isEmpty()) {
                queryBuilder.append(" WHERE g.").append(HisnDatabaseInfo.DuaGroupTable._ID).append(" IN (");
                for (int i = 0; i < mFilterIds.size(); i++) {
                    queryBuilder.append(mFilterIds.get(i));
                    if (i < mFilterIds.size() - 1) queryBuilder.append(",");
                }
                queryBuilder.append(") ");
            }

            queryBuilder.append(" ORDER BY g.").append(HisnDatabaseInfo.DuaGroupTable._ID);
            
            duaGroupCursor = database.rawQuery(queryBuilder.toString(), null);

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