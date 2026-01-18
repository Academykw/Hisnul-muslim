package com.deen.adkhar;

import java.util.Calendar;

public final class HijriCalendarUtils {

    private HijriCalendarUtils() {
    }

    public static final class HijriDate {
        public final int year;
        public final int month;
        public final int day;

        public HijriDate(int year, int month, int day) {
            this.year = year;
            this.month = month;
            this.day = day;
        }
    }

    public static final class GregorianDate {
        public final int year;
        public final int month;
        public final int day;

        public GregorianDate(int year, int month, int day) {
            this.year = year;
            this.month = month;
            this.day = day;
        }
    }

    public static HijriDate fromGregorian(int year, int month, int day) {
        int jd = julianDayFromGregorian(year, month, day);
        return hijriFromJulian(jd);
    }

    public static GregorianDate toGregorian(int hijriYear, int hijriMonth, int hijriDay) {
        int jd = julianDayFromHijri(hijriYear, hijriMonth, hijriDay);
        return gregorianFromJulian(jd);
    }

    public static int getDaysInHijriMonth(int hijriYear, int hijriMonth) {
        int jdStart = julianDayFromHijri(hijriYear, hijriMonth, 1);
        int nextYear = hijriYear;
        int nextMonth = hijriMonth + 1;
        if (nextMonth > 12) {
            nextMonth = 1;
            nextYear += 1;
        }
        int jdNext = julianDayFromHijri(nextYear, nextMonth, 1);
        return jdNext - jdStart;
    }

    public static String getHijriMonthName(int hijriMonth) {
        switch (hijriMonth) {
            case 0: return "Muharram";
            case 1: return "Safar";
            case 2: return "Rabi al-Awwal";
            case 3: return "Rabi al-Thani";
            case 4: return "Jumada al-Ula";
            case 5: return "Jumada al-Thaniyah";
            case 6: return "Rajab";
            case 7: return "Shaban";
            case 8: return "Ramadan";
            case 9: return "Shawwal";
            case 10: return "Dhul Qadah";
            case 11: return "Dhul Hijjah";
            default: return "";
        }
    }

    public static int getDayOfWeek(GregorianDate gregorian) {
        Calendar calendar = Calendar.getInstance();
        calendar.set(gregorian.year, gregorian.month - 1, gregorian.day, 0, 0, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        return calendar.get(Calendar.DAY_OF_WEEK);
    }

    private static int julianDayFromHijri(int year, int month, int day) {
        return day
                + (int) Math.ceil(29.5 * (month - 1))
                + (year - 1) * 354
                + (int) Math.floor((3 + 11 * year) / 30.0)
                + 1948439
                - 1;
    }

    private static HijriDate hijriFromJulian(int julianDay) {
        int year = (int) Math.floor((30.0 * (julianDay - 1948439) + 10646) / 10631.0);
        int month = (int) Math.min(12,
                Math.ceil((julianDay - 29 - julianDayFromHijri(year, 1, 1)) / 29.5) + 1);
        int day = julianDay - julianDayFromHijri(year, month, 1) + 1;
        return new HijriDate(year, month, day);
    }

    private static int julianDayFromGregorian(int year, int month, int day) {
        int a = (14 - month) / 12;
        int y = year + 4800 - a;
        int m = month + 12 * a - 3;
        return day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
    }

    private static GregorianDate gregorianFromJulian(int julianDay) {
        int a = julianDay + 32044;
        int b = (4 * a + 3) / 146097;
        int c = a - (146097 * b) / 4;
        int d = (4 * c + 3) / 1461;
        int e = c - (1461 * d) / 4;
        int m = (5 * e + 2) / 153;

        int day = e - (153 * m + 2) / 5 + 1;
        int month = m + 3 - 12 * (m / 10);
        int year = 100 * b + d - 4800 + (m / 10);
        return new GregorianDate(year, month, day);
    }
}
