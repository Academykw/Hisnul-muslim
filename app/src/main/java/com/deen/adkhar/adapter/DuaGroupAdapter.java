package com.deen.adkhar.adapter;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.drawable.GradientDrawable;
import android.text.Spannable;
import android.text.SpannableString;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Filter;
import android.widget.Filterable;
import android.widget.TextView;


import com.deen.adkhar.R;
import com.deen.adkhar.database.ExternalDbOpenHelper;
import com.deen.adkhar.database.HisnDatabaseInfo;
import com.deen.adkhar.model.Dua;
import com.mikepenz.iconics.view.IconicsButton;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class DuaGroupAdapter extends BaseAdapter implements Filterable {
    private Context mContext;
    private LayoutInflater mInflater;
    private List<Dua> mList;
    private CharSequence mSearchText = "";

    public DuaGroupAdapter(Context context, List<Dua> list) {
        mContext = context;
        mInflater = LayoutInflater.from(mContext);
        mList = list;
    }

    public void setData(List<Dua> list) {
        mList = list;
        notifyDataSetChanged();
    }

    @Override
    public Filter getFilter() {
        return new Filter() {
            @Override
            protected FilterResults performFiltering(CharSequence constraint) {
                final ExternalDbOpenHelper helper = ExternalDbOpenHelper.getInstance(mContext);
                final SQLiteDatabase db = helper.openDataBase();

                final List<Dua> duas = new ArrayList<>();
                Cursor c = null;
                try {
                    String query = "SELECT g." + HisnDatabaseInfo.DuaGroupTable._ID + ", " +
                            "g." + HisnDatabaseInfo.DuaGroupTable.ENGLISH_TITLE + ", " +
                            "(SELECT COUNT(*) FROM " + HisnDatabaseInfo.DuaTable.TABLE_NAME + 
                            " WHERE " + HisnDatabaseInfo.DuaTable.GROUP_ID + " = g." + HisnDatabaseInfo.DuaGroupTable._ID + 
                            " AND " + HisnDatabaseInfo.DuaTable.FAV + " = 1) as fav_count " +
                            "FROM " + HisnDatabaseInfo.DuaGroupTable.TABLE_NAME + " g " +
                            "WHERE g." + HisnDatabaseInfo.DuaGroupTable.ENGLISH_TITLE + " LIKE ?" +
                            "ORDER BY g." + HisnDatabaseInfo.DuaGroupTable._ID;
                    
                    c = db.rawQuery(query, new String[]{"%" + constraint + "%"});
                    
                    if (c != null && c.moveToFirst()) {
                        do {
                            final Dua dua = new Dua(c.getInt(0), c.getString(1), c.getInt(2) > 0);
                            duas.add(dua);
                        } while (c.moveToNext());
                    }
                } finally {
                    if (c != null) {
                        c.close();
                    }
                }

                final FilterResults results = new FilterResults();
                results.values = duas;
                results.count = duas.size();
                return results;
            }

            @Override
            protected void publishResults(CharSequence constraint, Filter.FilterResults results) {
                mSearchText = constraint;
                if (results.count > 0) {
                    mList = (List<Dua>) results.values;
                    notifyDataSetChanged();
                } else {
                    notifyDataSetInvalidated();
                }
            }
        };
    }

    @Override
    public int getCount() {
        return mList == null ? 0 : mList.size();
    }

    @Override
    public Dua getItem(int position) {
        return mList.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        final ViewHolder mHolder;
        if (convertView == null) {
            convertView = mInflater.inflate(R.layout.dua_group_item_card, parent, false);
            mHolder = new ViewHolder();
            mHolder.tvReference = (TextView) convertView.findViewById(R.id.txtReference);
            mHolder.tvDuaName = (TextView) convertView.findViewById(R.id.txtDuaName);
            mHolder.btnFav = (IconicsButton) convertView.findViewById(R.id.button_star_group);
            mHolder.shape = (GradientDrawable) mHolder.tvReference.getBackground();
            convertView.setTag(mHolder);
        } else {
            mHolder = (ViewHolder) convertView.getTag();
        }

        final Dua p = getItem(position);
        if (p != null) {
            mHolder.tvReference.setText("" + p.getReference());
            mHolder.tvDuaName.setText(p.getTitle());
            
            if (p.getFav()) {
                mHolder.btnFav.setText("{faw-star}");
            } else {
                mHolder.btnFav.setText("{faw-star-o}");
            }

            mHolder.btnFav.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    boolean newFavStatus = !p.getFav();
                    updateGroupFavStatus(p.getReference(), newFavStatus);
                    p.setFav(newFavStatus);
                    notifyDataSetChanged();
                }
            });

            String filter = mSearchText.toString();
            String itemValue = mHolder.tvDuaName.getText().toString();

            int startPos = itemValue.toLowerCase(Locale.US).indexOf(filter.toLowerCase(Locale.US));

            if (startPos != -1 && filter.length() > 0) {
                Spannable spannable = new SpannableString(itemValue);
                // Highlight logic could be added here if needed, but keeping it simple as per original
                mHolder.tvDuaName.setText(spannable);
            } else {
                mHolder.tvDuaName.setText(itemValue);
            }
        }
        return convertView;
    }

    private void updateGroupFavStatus(int groupId, boolean isFav) {
        ExternalDbOpenHelper helper = ExternalDbOpenHelper.getInstance(mContext);
        SQLiteDatabase db = helper.openDataBase();
        
        ContentValues values = new ContentValues();
        values.put(HisnDatabaseInfo.DuaTable.FAV, isFav ? 1 : 0);
        
        db.update(HisnDatabaseInfo.DuaTable.TABLE_NAME, 
                values, 
                HisnDatabaseInfo.DuaTable.GROUP_ID + " = ?", 
                new String[]{String.valueOf(groupId)});
    }

    public static class ViewHolder {
        TextView tvDuaName;
        TextView tvReference;
        IconicsButton btnFav;
        GradientDrawable shape;
    }
}