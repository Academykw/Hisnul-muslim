package com.deen.adkhar.adapter;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.deen.adkhar.R;

import java.util.ArrayList;
import java.util.List;

public class HijrahCalendarAdapter extends RecyclerView.Adapter<HijrahCalendarAdapter.DayViewHolder> {

    public static final class DayCell {
        public final boolean isEmpty;
        public final int hijriDay;
        public final String gregorianLabel;
        public final String celebrationLabel;
        public final boolean isToday;

        private DayCell(boolean isEmpty, int hijriDay, String gregorianLabel, String celebrationLabel, boolean isToday) {
            this.isEmpty = isEmpty;
            this.hijriDay = hijriDay;
            this.gregorianLabel = gregorianLabel;
            this.celebrationLabel = celebrationLabel;
            this.isToday = isToday;
        }

        public static DayCell empty() {
            return new DayCell(true, 0, "", "", false);
        }

        public static DayCell of(int hijriDay, String gregorianLabel, String celebrationLabel, boolean isToday) {
            return new DayCell(false, hijriDay, gregorianLabel, celebrationLabel, isToday);
        }
    }

    private final List<DayCell> items = new ArrayList<>();

    public void setItems(List<DayCell> newItems) {
        items.clear();
        items.addAll(newItems);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public DayViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_hijrah_day, parent, false);
        return new DayViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull DayViewHolder holder, int position) {
        DayCell cell = items.get(position);
        if (cell.isEmpty) {
            holder.hijriDay.setText("");
            holder.gregorianDay.setText("");
            holder.celebrationDay.setText("");
            holder.celebrationDay.setVisibility(View.GONE);
            holder.itemView.setBackgroundColor(Color.TRANSPARENT);
            holder.itemView.setAlpha(0.3f);
        } else {
            holder.hijriDay.setText(String.valueOf(cell.hijriDay));
            holder.gregorianDay.setText(cell.gregorianLabel);
            if (cell.celebrationLabel == null || cell.celebrationLabel.isEmpty()) {
                holder.celebrationDay.setText("");
                holder.celebrationDay.setVisibility(View.GONE);
            } else {
                holder.celebrationDay.setText(cell.celebrationLabel);
                holder.celebrationDay.setVisibility(View.VISIBLE);
            }
            int bgRes = cell.isToday ? R.drawable.bg_hijrah_day_today : R.drawable.bg_hijrah_day;
            holder.itemView.setBackgroundResource(bgRes);
            holder.itemView.setAlpha(1.0f);
        }
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    static class DayViewHolder extends RecyclerView.ViewHolder {
        final TextView hijriDay;
        final TextView gregorianDay;
        final TextView celebrationDay;

        DayViewHolder(@NonNull View itemView) {
            super(itemView);
            hijriDay = itemView.findViewById(R.id.tv_hijrah_day);
            gregorianDay = itemView.findViewById(R.id.tv_gregorian_day);
            celebrationDay = itemView.findViewById(R.id.tv_hijrah_label);
        }
    }
}
