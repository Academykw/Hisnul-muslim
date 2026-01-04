package com.deen.adkhar.adapter;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import com.deen.adkhar.R;
import com.mikepenz.iconics.view.IconicsImageView;

import java.io.IOException;
import java.io.InputStream;

public class CategoryGridAdapter extends BaseAdapter {
    private Context context;
    private String[] categories;
    private String[] icons;

    public CategoryGridAdapter(Context context, String[] categories, String[] icons) {
        this.context = context;
        this.categories = categories;
        this.icons = icons;
    }

    @Override
    public int getCount() {
        return categories.length;
    }

    @Override
    public Object getItem(int position) {
        return categories[position];
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        if (convertView == null) {
            convertView = LayoutInflater.from(context).inflate(R.layout.item_grid_category, parent, false);
        }

        TextView name = convertView.findViewById(R.id.category_name);
        IconicsImageView icon = convertView.findViewById(R.id.category_icon);
        ImageView background = convertView.findViewById(R.id.category_background);

        String categoryName = categories[position];
        name.setText(categoryName);
        icon.setIcon(icons[position]);

        // Load background image from assets/img/
        // Matches filename to category name (lowercase, spaces replaced with underscores)
        String fileName = categoryName.toLowerCase().replace(" ", "_").replace("/", "_") + ".png";
        try {
            InputStream is = context.getAssets().open("img/" + fileName);
            Drawable d = Drawable.createFromStream(is, null);
            background.setImageDrawable(d);
            is.close();
        } catch (IOException e) {
            Log.e("CategoryGridAdapter", "Error loading background: " + fileName, e);
            // Optional: set a default background if image missing
            background.setImageResource(android.R.color.darker_gray);
        }

        return convertView;
    }
}