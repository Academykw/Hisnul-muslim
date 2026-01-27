package com.deen.adkhar;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import java.text.NumberFormat;
import java.util.Locale;

import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

public class ZakatCalculatorActivity extends AppCompatActivity {

    private EditText inputAssets;
    private EditText inputLiabilities;
    private EditText inputNisab;
    private TextView zakatResult;
    private TextView zakatBreakdown;
    private Spinner currencySpinner;
    private TextView nisabStatus;
    private final NumberFormat numberFormat = NumberFormat.getNumberInstance(Locale.getDefault());
    private DatabaseReference nisabReference;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_zakat_calculator);

        Toolbar toolbar = findViewById(R.id.my_action_bar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle(getString(R.string.title_activity_zakat_calculator));
        }

        inputAssets = findViewById(R.id.input_assets);
        inputLiabilities = findViewById(R.id.input_liabilities);
        inputNisab = findViewById(R.id.input_nisab);
        Button btnCalculate = findViewById(R.id.btn_calculate_zakat);
        zakatResult = findViewById(R.id.tv_zakat_result);
        zakatBreakdown = findViewById(R.id.tv_zakat_breakdown);
        currencySpinner = findViewById(R.id.spinner_currency);
        nisabStatus = findViewById(R.id.tv_nisab_status);

        btnCalculate.setOnClickListener(v -> calculateZakat());
        currencySpinner.setOnItemSelectedListener(new android.widget.AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(android.widget.AdapterView<?> parent, View view, int position, long id) {
                fetchNisabForCurrency();
            }

            @Override
            public void onNothingSelected(android.widget.AdapterView<?> parent) {
            }
        });

        numberFormat.setMaximumFractionDigits(2);
        numberFormat.setMinimumFractionDigits(2);
        nisabReference = FirebaseDatabase.getInstance().getReference("nisab");

        fetchNisabForCurrency();
        AdBannerHelper.loadBanner(this, R.id.ad_view);
    }

    private void calculateZakat() {
        double assets = parseAmount(inputAssets.getText().toString());
        double liabilities = parseAmount(inputLiabilities.getText().toString());
        double nisab = parseAmount(inputNisab.getText().toString());

        double net = assets - liabilities;
        double zakat = 0.0;
        if (net >= nisab) {
            zakat = net * 0.025;
        }

        String currency = currencySpinner.getSelectedItem().toString();
        String formatted = numberFormat.format(zakat);
        zakatResult.setText(getString(R.string.zakat_result_value, formatted, currency));
        updateBreakdown(net, nisab, currency);
    }

    private void updateBreakdown(double net, double nisab, String currency) {
        String netLabel = getString(R.string.zakat_breakdown_net,
                numberFormat.format(net), currency);
        String nisabLabel = getString(R.string.zakat_breakdown_nisab,
                numberFormat.format(nisab), currency);
        String rateLabel = getString(R.string.zakat_breakdown_rate);
        String statusLabel = net >= nisab
                ? getString(R.string.zakat_breakdown_status_due)
                : getString(R.string.zakat_breakdown_status_not_due);
        String breakdown = netLabel + "\n" + nisabLabel + "\n" + rateLabel + "\n" + statusLabel;
        zakatBreakdown.setText(breakdown);
    }

    private void fetchNisabForCurrency() {
        if (nisabReference == null) {
            nisabStatus.setText(getString(R.string.zakat_nisab_status_error));
            return;
        }
        String currency = currencySpinner.getSelectedItem().toString();
        nisabStatus.setText(getString(R.string.zakat_nisab_status_loading, currency));
        nisabReference.child(currency).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                Double nisabValue = snapshot.getValue(Double.class);
                if (nisabValue == null) {
                    Long nisabLong = snapshot.getValue(Long.class);
                    if (nisabLong != null) {
                        nisabValue = nisabLong.doubleValue();
                    }
                }
                if (nisabValue == null) {
                    nisabStatus.setText(getString(R.string.zakat_nisab_status_missing, currency));
                    return;
                }
                inputNisab.setText(numberFormat.format(nisabValue));
                nisabStatus.setText(getString(R.string.zakat_nisab_status_ready, currency));
            }

            @Override
            public void onCancelled(DatabaseError error) {
                nisabStatus.setText(getString(R.string.zakat_nisab_status_error));
            }
        });
    }

    private double parseAmount(String value) {
        if (TextUtils.isEmpty(value)) {
            return 0.0;
        }
        try {
            return Double.parseDouble(value.replace(",", ""));
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }
}
