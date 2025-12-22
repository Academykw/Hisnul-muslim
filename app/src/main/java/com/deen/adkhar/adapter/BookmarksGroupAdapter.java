package com.deen.adkhar.adapter;

import android.content.Context;
import android.graphics.drawable.GradientDrawable;
import android.text.Spannable;
import android.text.SpannableString;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;


import com.deen.adkhar.R;
import com.deen.adkhar.model.Dua;
import com.mikepenz.iconics.view.IconicsButton;

import java.util.List;
import java.util.Locale;

/**
 * Created by Khalid on 31 يوليو.
 */
public class BookmarksGroupAdapter extends BaseAdapter {
    private Context mContext;
    private LayoutInflater mInflater;
    private List<Dua> mList;
    private CharSequence mSearchText = "";

    public BookmarksGroupAdapter(Context context, List<Dua> list) {
        mContext = context;
        mInflater = LayoutInflater.from(mContext);
        mList = list;
    }

    public void setData(List<Dua> list) {
        mList = list;
        notifyDataSetChanged();
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

        ViewHolder holder;
        if (convertView == null) {
            convertView = mInflater.inflate(R.layout.dua_group_item_card, parent, false);
            holder = new ViewHolder();
            holder.tvReference = (TextView) convertView.findViewById(R.id.txtReference);
            holder.tvDuaName = (TextView) convertView.findViewById(R.id.txtDuaName);
            holder.btnFav = (IconicsButton) convertView.findViewById(R.id.button_star_group);
            holder.shape = (GradientDrawable) holder.tvReference.getBackground();
            convertView.setTag(holder);
        } else
            holder = (ViewHolder) convertView.getTag();

        Dua p = getItem(position);
        if (p != null) {
            holder.tvReference.setText("" + p.getReference());
            holder.tvDuaName.setText(p.getTitle());
            
            // Hide the favorite button in the bookmarks group list to avoid confusion, 
            // as these are groups that contain bookmarks.
            holder.btnFav.setVisibility(View.GONE);

            String filter = mSearchText.toString();
            String itemValue = holder.tvDuaName.getText().toString();

            int startPos = itemValue.toLowerCase(Locale.US).indexOf(filter.toLowerCase(Locale.US));

            if (startPos != -1 && filter.length() > 0) {
                Spannable spannable = new SpannableString(itemValue);
                holder.tvDuaName.setText(spannable);
            } else {
                holder.tvDuaName.setText(itemValue);
            }
        }
        return convertView;
    }

    public static class ViewHolder {
        TextView tvDuaName;
        TextView tvReference;
        IconicsButton btnFav;
        GradientDrawable shape;
    }
}
