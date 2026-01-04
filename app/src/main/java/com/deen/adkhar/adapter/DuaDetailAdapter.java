package com.deen.adkhar.adapter;

import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.Typeface;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.preference.PreferenceManager;
import android.text.Html;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;
import android.widget.Toast;


import com.deen.adkhar.R;
import com.deen.adkhar.database.ExternalDbOpenHelper;
import com.deen.adkhar.database.HisnDatabaseInfo;
import com.deen.adkhar.model.Dua;
import com.mikepenz.iconics.view.IconicsButton;

import java.io.IOException;
import java.util.List;

public class DuaDetailAdapter extends BaseAdapter {
    private static Typeface sCachedTypeface = null;

    private List<Dua> mList;
    private LayoutInflater mInflater;
    private Context mContext;

    private final float prefArabicFontSize;
    private final float prefOtherFontSize;
    private final String prefArabicFontTypeface;

    private String myToolbarTitle;
    private MediaPlayer mediaPlayer;

    public DuaDetailAdapter(Context context, List<Dua> items, String toolbarTitle) {
        mContext = context;
        mInflater = LayoutInflater.from(context);
        mList = items;

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

    public void setData(List<Dua> items) {
        mList = items;
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
    public View getView(int position, View convertView, final ViewGroup parent) {
        final ViewHolder mHolder;
        final Dua p = getItem(position);

        if (convertView == null) {
            convertView = mInflater.inflate(R.layout.dua_detail_item_card, parent, false);

            mHolder = new ViewHolder();
            mHolder.tvDuaNumber = (TextView) convertView.findViewById(R.id.txtDuaNumber);

            mHolder.tvDuaArabic = (TextView) convertView.findViewById(R.id.txtDuaArabic);
            mHolder.tvDuaArabic.setTypeface(sCachedTypeface);
            mHolder.tvDuaArabic.setTextSize(prefArabicFontSize);

            mHolder.btnPlay = (IconicsButton) convertView.findViewById(R.id.button_play);

            mHolder.tvDuaTransliteration = (TextView) convertView.findViewById(R.id.txtDuaTransliteration);
            mHolder.tvDuaTransliteration.setTextSize(prefOtherFontSize);

            mHolder.tvDuaTranslation = (TextView) convertView.findViewById(R.id.txtDuaTranslation);
            mHolder.tvDuaTranslation.setTextSize(prefOtherFontSize);

            mHolder.tvDuaReference = (TextView) convertView.findViewById(R.id.txtDuaReference);
            mHolder.tvDuaReference.setTextSize(prefOtherFontSize);

            mHolder.shareButton = (IconicsButton) convertView.findViewById(R.id.button_share);
            mHolder.favButton = (IconicsButton) convertView.findViewById(R.id.button_star);

            mHolder.shareButton.setOnClickListener(new View.OnClickListener() {
                public void onClick(View v) {
                    Intent intent = new Intent();
                    intent.setAction(Intent.ACTION_SEND);
                    intent.putExtra(Intent.EXTRA_TEXT,
                            myToolbarTitle + "\n\n" +
                                    mHolder.tvDuaArabic.getText() + "\n\n" +
                                    mHolder.tvDuaTransliteration.getText() + "\n\n" +
                                    mHolder.tvDuaTranslation.getText() + "\n\n" +
                                    mHolder.tvDuaReference.getText() + "\n\n" +
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

            mHolder.favButton.setOnClickListener(new View.OnClickListener() {
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
                        notifyDataSetChanged();
                    }
                }
            });
            convertView.setTag(mHolder);
        } else {
            mHolder = (ViewHolder) convertView.getTag();
        }


        if (p != null) {
            mHolder.tvDuaNumber.setText("" + p.getReference());
            mHolder.tvDuaArabic.setText(Html.fromHtml(p.getArabic()));

            if (p.getTransliteration() != null) {
                mHolder.tvDuaTransliteration.setVisibility(View.VISIBLE);
                mHolder.tvDuaTransliteration.setText(Html.fromHtml(p.getTransliteration()));
            } else {
                mHolder.tvDuaTransliteration.setVisibility(View.GONE);
            }

            mHolder.tvDuaTranslation.setText(Html.fromHtml(p.getTranslation()));

            if (p.getBook_reference() != null)
                mHolder.tvDuaReference.setText(Html.fromHtml(p.getBook_reference()));
            else
                mHolder.tvDuaReference.setText("");

            if (p.getFav()) {
                mHolder.favButton.setText("{faw-star}");
            } else {
                mHolder.favButton.setText("{faw-star-o}");
            }

            mHolder.btnPlay.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    playAudio(p.getReference());
                }
            });
        }


        return convertView;
    }

    private void playAudio(int reference) {
        if (mediaPlayer != null) {
            mediaPlayer.release();
            mediaPlayer = null;
        }

        String fileName = "a" + reference + ".mp3";
        try {
            mediaPlayer = new MediaPlayer();
            mediaPlayer.setAudioAttributes(
                    new AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .build()
            );
            
            // Assuming audio files are in assets/audio/
            android.content.res.AssetFileDescriptor afd = mContext.getAssets().openFd("audio/" + fileName);
            mediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            afd.close();
            
            mediaPlayer.prepare();
            mediaPlayer.start();
        } catch (IOException e) {
            Log.e("DuaDetailAdapter", "Error playing audio: " + fileName, e);
            Toast.makeText(mContext, "Audio not found for this Dua", Toast.LENGTH_SHORT).show();
        }
    }

    public void releaseMediaPlayer() {
        if (mediaPlayer != null) {
            mediaPlayer.release();
            mediaPlayer = null;
        }
    }

    public static class ViewHolder {
        TextView tvDuaNumber;
        TextView tvDuaArabic;
        IconicsButton btnPlay;
        TextView tvDuaTransliteration;
        TextView tvDuaReference;
        TextView tvDuaTranslation;
        IconicsButton shareButton;
        IconicsButton favButton;
    }
}