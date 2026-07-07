import pandas as pd
import numpy as np
from sklearn.ensemble import HistGradientBoostingRegressor
from sklearn.metrics import mean_absolute_error
import random


def predict_runout_cumulative(df: pd.DataFrame, total_material_weight, x_col="x", y_col="y", max_forecast_days=365):
    """
    df[x_col] = time.time() // 86400
    df[y_col] = cumulative consumed weight, e.g. 1120, 1120, 1180, ...

    total_material_weight = total available material before it runs out,
    e.g. 25000 grams.
    """

    df = df.copy()

    # x is Unix day number, not Unix seconds
    df["date"] = pd.to_datetime(df[x_col].astype(int), unit="D", origin="unix")
    df = df.sort_values("date")

    # # If multiple entries exist for the same day, keep the last cumulative value
    # df = df.groupby("date", as_index=False)[y_col].last()

    # Make it a daily time series
    df = df.set_index("date").asfreq("D")

    # Cumulative consumed weight should stay constant on days with no new reading
    df[y_col] = df[y_col].ffill()

    # Daily consumption is the increase in cumulative consumed weight
    df["consumption"] = df[y_col].diff()

    # No consumption days become 0.
    # Negative values would usually mean a reset/refill/data issue.
    df["consumption"] = df["consumption"].clip(lower=0)

    df = df.dropna()

    current_consumed = float(df[y_col].iloc[-1])

    if current_consumed >= total_material_weight:
        return {
            "runout_date": df.index[-1],
            "message": "Material is already predicted to be empty.",
            "forecast": pd.DataFrame(),
            "model_mae_daily_consumption": None,
            "model": None,
        }

    # Calendar features
    df["day_index"] = (df.index - df.index.min()).days
    df["weekday"] = df.index.weekday  # Monday=0, Sunday=6
    df["is_weekend"] = df["weekday"].isin([5, 6]).astype(int)
    df["month"] = df.index.month
    df["dayofyear"] = df.index.dayofyear

    # Smooth yearly seasonality
    df["year_sin"] = np.sin(2 * np.pi * df["dayofyear"] / 365.25)
    df["year_cos"] = np.cos(2 * np.pi * df["dayofyear"] / 365.25)

    # Recent consumption behavior
    df["consumption_lag_1"] = df["consumption"].shift(1)
    df["consumption_lag_7"] = df["consumption"].shift(7)
    df["consumption_avg_7"] = df["consumption"].rolling(7).mean()
    df["consumption_avg_28"] = df["consumption"].rolling(28).mean()
    # print(df)
    # df = df.dropna()
    # print(df)

    if len(df) < 14:
        raise ValueError(
            "Not enough daily data after feature creation. "
            "Try collecting more data or remove the 28-day rolling average feature."
        )

    features = [
        "day_index",
        "weekday",
        "is_weekend",
        "month",
        "year_sin",
        "year_cos",
        "consumption_lag_1",
        "consumption_lag_7",
        "consumption_avg_7",
        "consumption_avg_28",
    ]

    X = df[features]
    y = df["consumption"]

    model = HistGradientBoostingRegressor(random_state=42)
    model.fit(X, y)

    fitted = model.predict(X)
    mae = mean_absolute_error(y, fitted)

    latest_date = df.index[-1]
    cumulative_consumed = current_consumed

    consumption_history = list(df["consumption"].values)
    forecast = []

    for i in range(1, max_forecast_days + 1):
        future_date = latest_date + pd.Timedelta(days=i)
        recent = pd.Series(consumption_history)

        row = {
            "day_index": (future_date - df.index.min()).days,
            "weekday": future_date.weekday(),
            "is_weekend": int(future_date.weekday() in [5, 6]),
            "month": future_date.month,
            "year_sin": np.sin(2 * np.pi * future_date.dayofyear / 365.25),
            "year_cos": np.cos(2 * np.pi * future_date.dayofyear / 365.25),
            "consumption_lag_1": recent.iloc[-1],
            "consumption_lag_7": recent.iloc[-7] if len(recent) >= 7 else recent.mean(),
            "consumption_avg_7": recent.tail(7).mean(),
            "consumption_avg_28": recent.tail(28).mean(),
        }

        X_future = pd.DataFrame([row])[features]

        predicted_daily_consumption = float(model.predict(X_future)[0])
        predicted_daily_consumption = max(0, predicted_daily_consumption)

        cumulative_consumed += predicted_daily_consumption
        remaining_weight = total_material_weight - cumulative_consumed

        consumption_history.append(predicted_daily_consumption)

        forecast.append({
            "date": future_date,
            "predicted_daily_consumption": predicted_daily_consumption,
            "predicted_cumulative_consumed": cumulative_consumed,
            "predicted_remaining_weight": remaining_weight,
        })

        if cumulative_consumed >= total_material_weight:
            break

    forecast_df = pd.DataFrame(forecast)

    if len(forecast_df) == 0:
        runout_date = None
    elif forecast_df["predicted_cumulative_consumed"].iloc[-1] < total_material_weight:
        runout_date = None
    else:
        runout_date = forecast_df.loc[
            forecast_df["predicted_cumulative_consumed"] >= total_material_weight,
            "date"
        ].iloc[0]

    return {
        "runout_date": runout_date,
        "model_mae_daily_consumption": mae,
        "forecast": forecast_df,
        "model": model,
    }

def predict_runout_from_tuples(data, total_material_weight, max_forecast_days=365):
    """
    data = [
        (unix_day, cumulative_consumed_weight),
        ...
    ]

    Example:
    data = [
        (20635, 1000),
        (20636, 1120),
        (20637, 1120),
        (20638, 1300),
    ]
    """

    df = pd.DataFrame(data, columns=["x", "y"])
    return predict_runout_cumulative(df=df, total_material_weight=total_material_weight, x_col="x", y_col="y", max_forecast_days=max_forecast_days)


if __name__ == "__main__":
    data = []
    cs = 0
    for i in range(30):
        cs+=random.randint(0,20)
        data.append((20641+i, cs))
    result = predict_runout_from_tuples(
        data,
        total_material_weight=1000,
    )

    print(result["runout_date"].strftime("%d.%m.%Y"))