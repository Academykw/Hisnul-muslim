package com.deen.adkhar;

import android.os.Bundle;
import android.text.TextUtils;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.deen.adkhar.adapter.HijrahCalendarAdapter;
import com.github.msarhan.ummalqura.calendar.UmmalquraCalendar;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;

public class HijrahCalendarActivity extends AppCompatActivity {

    private TextView monthTitle;
    private TextView eventsLabel;
    private HijrahCalendarAdapter adapter;
    private int hijriYear;
    private int hijriMonth;
    private int hijriTodayDay;
    private int hijriTodayYear;
    private int hijriTodayMonth;
    private SimpleDateFormat gregorianFormatter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hijrah_calendar);

        Toolbar toolbar = findViewById(R.id.my_action_bar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle(getString(R.string.title_activity_hijrah_calendar));
        }

        monthTitle = findViewById(R.id.tv_hijrah_month);
        eventsLabel = findViewById(R.id.tv_hijrah_events);
        ImageView btnPrev = findViewById(R.id.btn_hijrah_prev);
        ImageView btnNext = findViewById(R.id.btn_hijrah_next);
        RecyclerView recyclerView = findViewById(R.id.rv_hijrah_calendar);

        adapter = new HijrahCalendarAdapter();
        recyclerView.setLayoutManager(new GridLayoutManager(this, 7));
        recyclerView.setAdapter(adapter);

        UmmalquraCalendar todayHijri = new UmmalquraCalendar();
        hijriTodayYear = todayHijri.get(Calendar.YEAR);
        hijriTodayMonth = todayHijri.get(Calendar.MONTH);
        hijriTodayDay = todayHijri.get(Calendar.DAY_OF_MONTH);
        hijriYear = hijriTodayYear;
        hijriMonth = hijriTodayMonth;
        gregorianFormatter = new SimpleDateFormat("d MMM", Locale.getDefault());

        btnPrev.setOnClickListener(v -> shiftMonth(-1));
        btnNext.setOnClickListener(v -> shiftMonth(1));

        updateMonth();
        AdBannerHelper.loadBanner(this, R.id.ad_view);
    }

    private void shiftMonth(int delta) {
        hijriMonth += delta;
        if (hijriMonth < 1) {
            hijriMonth = 12;
            hijriYear -= 1;
        } else if (hijriMonth > 12) {
            hijriMonth = 1;
            hijriYear += 1;
        }
        updateMonth();
    }

    private void updateMonth() {
        String title = HijriCalendarUtils.getHijriMonthName(hijriMonth) + " " + hijriYear;
        monthTitle.setText(title);
        adapter.setItems(buildMonthCells());
        eventsLabel.setText(buildMonthEventsLabel());
    }

    private List<HijrahCalendarAdapter.DayCell> buildMonthCells() {
        List<HijrahCalendarAdapter.DayCell> cells = new ArrayList<>();
        UmmalquraCalendar firstHijri = new UmmalquraCalendar();
        firstHijri.clear();
        firstHijri.set(Calendar.YEAR, hijriYear);
        firstHijri.set(Calendar.MONTH, hijriMonth);
        firstHijri.set(Calendar.DAY_OF_MONTH, 1);

        int firstDayOfWeek = firstHijri.get(Calendar.DAY_OF_WEEK);
        int leadingBlanks = firstDayOfWeek - Calendar.SUNDAY;
        for (int i = 0; i < leadingBlanks; i++) {
            cells.add(HijrahCalendarAdapter.DayCell.empty());
        }

        UmmalquraCalendar hijriDate = (UmmalquraCalendar) firstHijri.clone();
        while (hijriDate.get(Calendar.MONTH) == hijriMonth) {
            int day = hijriDate.get(Calendar.DAY_OF_MONTH);
            String label = gregorianFormatter.format(hijriDate.getTime());
            boolean isToday = hijriYear == hijriTodayYear
                    && hijriMonth == hijriTodayMonth
                    && day == hijriTodayDay;
            String celebration = getCelebrationLabel(hijriMonth, day);
            cells.add(HijrahCalendarAdapter.DayCell.of(day, label, celebration, isToday));
            hijriDate.add(Calendar.DAY_OF_MONTH, 1);
        }

        int remainder = cells.size() % 7;
        if (remainder != 0) {
            for (int i = 0; i < 7 - remainder; i++) {
                cells.add(HijrahCalendarAdapter.DayCell.empty());
            }
        }

        return cells;
    }

    private String getCelebrationLabel(int month, int day) {
        if (month == 9 && day == 1) {
            return getString(R.string.hijrah_eid_fitr);
        }
        if (month == 11 && day == 10) {
            return getString(R.string.hijrah_eid_adha);
        }
        return "";
    }

    private String buildMonthEventsLabel() {
        List<String> events = new ArrayList<>();
        if (hijriMonth == 9) {
            events.add(getString(R.string.hijrah_event_eid_fitr));
        }
        if (hijriMonth == 11) {
            events.add(getString(R.string.hijrah_event_eid_adha));
        }
        if (events.isEmpty()) {
            return getString(R.string.hijrah_events_none);
        }
        String joined = TextUtils.join(", ", events);
        return getString(R.string.hijrah_events_prefix, joined);
    }
}
