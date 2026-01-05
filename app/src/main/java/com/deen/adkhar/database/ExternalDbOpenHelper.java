package com.deen.adkhar.database;

import android.content.Context;
import android.content.SharedPreferences;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class ExternalDbOpenHelper extends SQLiteOpenHelper {

    //Path to the device folder with databases
    public static String DB_PATH;

    //Database file name
    public static final String DB_NAME = HisnDatabaseInfo.DB_NAME;
    public static final int DB_VERSION = HisnDatabaseInfo.DB_VERSION;
    private static final String SP_KEY_DB_VER = "db_ver";

    private static ExternalDbOpenHelper sInstance;

    public SQLiteDatabase database;
    public Context context;

    public static ExternalDbOpenHelper getInstance(Context context) {
        if (sInstance == null) {
            sInstance = new ExternalDbOpenHelper(
                    context.getApplicationContext(), DB_NAME);
        }
        return sInstance;
    }

    public SQLiteDatabase getDb() {
        return database;
    }

    private ExternalDbOpenHelper(Context context, String databaseName) {
        super(context, databaseName, null, DB_VERSION);
        this.context = context;
        DB_PATH = context.getDatabasePath(getDatabaseName()).getAbsolutePath();
        openDataBase();
    }

    public ExternalDbOpenHelper(Context context){
        super(context, DB_NAME, null, DB_VERSION);
    }

    //This piece of code will create a database if it’s not yet created or if version changed
    public void createDataBase() {
        SharedPreferences sharedPreferences = context.getSharedPreferences("db_prefs", Context.MODE_PRIVATE);
        int savedVersion = sharedPreferences.getInt(SP_KEY_DB_VER, 0);

        boolean dbExist = checkDataBase();
        if (!dbExist || savedVersion < DB_VERSION) {
            this.getReadableDatabase();
            try {
                copyDataBase();
                sharedPreferences.edit().putInt(SP_KEY_DB_VER, DB_VERSION).apply();
                Log.i(this.getClass().toString(), "Database copied/updated to version " + DB_VERSION);
            } catch (IOException e) {
                Log.e(this.getClass().toString(), "Copying error");
                throw new Error("Error copying database!");
            }
        } else {
            Log.i(this.getClass().toString(), "Database already exists and is up to date");
        }
    }

    //Performing a database existence check
    private boolean checkDataBase() {
        SQLiteDatabase checkDb = null;
        try {
            String path = DB_PATH;
            checkDb = SQLiteDatabase.openDatabase(path, null,
                    SQLiteDatabase.OPEN_READONLY);
        } catch (SQLException e) {
            Log.e(this.getClass().toString(), "Error while checking db");
        }
        if (checkDb != null) {
            checkDb.close();
        }
        return checkDb != null;
    }

    //Method for copying the database
    private void copyDataBase() throws IOException {
        InputStream externalDbStream = context.getAssets().open(DB_NAME);
        String outFileName = DB_PATH;
        OutputStream localDbStream = new FileOutputStream(outFileName);

        byte[] buffer = new byte[1024];
        int bytesRead;
        while ((bytesRead = externalDbStream.read(buffer)) > 0) {
            localDbStream.write(buffer, 0, bytesRead);
        }
        localDbStream.close();
        externalDbStream.close();
    }

    public SQLiteDatabase openDataBase() throws SQLException {
        if (database == null || !database.isOpen()) {
            createDataBase();
            database = SQLiteDatabase.openDatabase(DB_PATH, null,
                    SQLiteDatabase.OPEN_READWRITE);
        }
        return database;
    }

    @Override
    public synchronized void close() {
        if (database != null) {
            database.close();
        }
        super.close();
    }
    @Override
    public void onCreate(SQLiteDatabase db) {}
    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {}
}