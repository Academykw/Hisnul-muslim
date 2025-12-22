package com.deen.adkhar.adapter;

import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.Typeface;
import android.preference.PreferenceManager;
import android.text.Html;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;


import com.deen.adkhar.R;
import com.deen.adkhar.database.ExternalDbOpenHelper;
import com.deen.adkhar.database.HisnDatabaseInfo;
import com.deen.adkhar.model.Dua;
import com.mikepenz.iconics.view.IconicsButton;

import java.util.List;

import androidx.recyclerview.widget.RecyclerView;

/**
 * Created by Khalid on 18 أغسطس.
 */

public class BookmarksDetailRecycleAdapter extends RecyclerView.Adapter<BookmarksDetailRecycleAdapter.ViewHolder> {
    private static Typeface sCachedTypeface = null;

    private List<Dua> mDuaData;
    private static float prefArabicFontSize;
    private static float prefOtherFontSize;
    private static String prefArabicFontTypeface;

    private static String myToolbarTitle;

    public BookmarksDetailRecycleAdapter(Context context, List<Dua> items, String toolbarTitle) {
        mDuaData = items;

        final SharedPreferences sharedPreferences =
                PreferenceManager.getDefaultSharedPreferences(context);
        prefArabicFontTypeface =
                sharedPreferences.getString(
                        context.getResources().getString(R.string.pref_font_arabic_typeface),
                        context.getString(R.string.pref_font_arabic_typeface_default));
        prefArabicFontSize =
                sharedPreferences.getInt(
                        context.getResources().getString(R.string.pref_font_arabic_size),
                        context.getResources().getInteger(R.integer.pref_font_arabic_size_default));
        prefOtherFontSize =
                sharedPreferences.getInt(
                        context.getResources().getString(R.string.pref_font_other_size),
                        context.getResources().getInteger(R.integer.pref_font_other_size_default));

        if (sCachedTypeface == null) {
            try {
                sCachedTypeface = Typeface.createFromAsset(
                        context.getAssets(), prefArabicFontTypeface);
            } catch (Exception e) {
                sCachedTypeface = Typeface.DEFAULT;
            }
        }

        myToolbarTitle = toolbarTitle;
    }

    @Override
    public BookmarksDetailRecycleAdapter.ViewHolder onCreateViewHolder(ViewGroup parent,
                                                                       int viewType) {
        View itemLayoutView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.dua_detail_item_card, parent, false);

        return new ViewHolder(itemLayoutView);
    }

    public void deleteRow(int position){
        mDuaData.remove(position);
        notifyItemRemoved(position);
        notifyItemRangeChanged(position, mDuaData.size());
    }

    @Override
    public void onBindViewHolder(final ViewHolder holder, int position) {
        final Dua p = mDuaData.get(position);

        holder.tvDuaNumber.setText(String.valueOf(p.getReference()));
        holder.tvDuaArabic.setText(Html.fromHtml(p.getArabic()));

        holder.tvDuaTranslation.setText(Html.fromHtml(p.getTranslation()));

        if (p.getBook_reference() != null)
            holder.tvDuaReference.setText(Html.fromHtml(p.getBook_reference()));
        else
            holder.tvDuaReference.setText("");

        if (p.getFav()) {
            holder.favButton.setText("{faw-star}");
        } else {
            holder.favButton.setText("{faw-star-o}");
        }

        holder.shareButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                Intent intent = new Intent();
                intent.setAction(Intent.ACTION_SEND);
                intent.putExtra(Intent.EXTRA_TEXT,
                        myToolbarTitle + "\n\n" +
                                holder.tvDuaArabic.getText() + "\n\n" +
                                holder.tvDuaTranslation.getText() + "\n\n" +
                                holder.tvDuaReference.getText() + "\n\n" +
                                v.getResources().getString(R.string.action_share_credit)
                );
                intent.setType("text/plain");
                v.getContext().startActivity(
                        Intent.createChooser(
                                intent,
                                v.getResources().getString(R.string.action_share_title)
                        )
                );
            }
        });

        holder.favButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                boolean isFav = !p.getFav();
                SQLiteDatabase db = ExternalDbOpenHelper.getInstance(v.getContext()).getDb();

                ContentValues values = new ContentValues();
                values.put(HisnDatabaseInfo.DuaTable.FAV, isFav ? 1 : 0);

                String selection = HisnDatabaseInfo.DuaTable.DUA_ID + " = ?";
                String[] selectionArgs = {String.valueOf(p.getReference())};

                int count = db.update(
                        HisnDatabaseInfo.DuaTable.TABLE_NAME,
                        values,
                        selection,
                        selectionArgs);

                if (count == 1) {
                    p.setFav(isFav);
                    if (!isFav) {
                        deleteRow(holder.getAdapterPosition());
                    } else {
                        notifyItemChanged(holder.getAdapterPosition());
                    }
                }
            }
        });
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        public TextView tvDuaNumber;
        public TextView tvDuaArabic;
        public TextView tvDuaTranslation;
        public TextView tvDuaReference;
        public IconicsButton shareButton;
        public IconicsButton favButton;

        public ViewHolder(View itemLayoutView) {
            super(itemLayoutView);
            tvDuaNumber = (TextView) itemLayoutView.findViewById(R.id.txtDuaNumber);
            tvDuaArabic = (TextView) itemLayoutView.findViewById(R.id.txtDuaArabic);
            tvDuaTranslation = (TextView) itemLayoutView.findViewById(R.id.txtDuaTranslation);
            tvDuaReference = (TextView) itemLayoutView.findViewById(R.id.txtDuaReference);
            shareButton = (IconicsButton) itemLayoutView.findViewById(R.id.button_share);
            favButton = (IconicsButton) itemLayoutView.findViewById(R.id.button_star);

            tvDuaArabic.setTypeface(sCachedTypeface);
            tvDuaArabic.setTextSize(prefArabicFontSize);
            tvDuaTranslation.setTextSize(prefOtherFontSize);
            tvDuaReference.setTextSize(prefOtherFontSize);
        }
    }

    @Override
    public int getItemCount() {
        return mDuaData == null ? 0 : mDuaData.size();
    }
}