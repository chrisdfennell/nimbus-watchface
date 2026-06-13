import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Application;
import Toybox.Weather;
import Toybox.SensorHistory;
import Toybox.Math;

class NimbusView extends WatchUi.WatchFace {

    private var mScreenWidth as Number = 0;
    private var mScreenHeight as Number = 0;
    private var mCenterX as Number = 0;
    private var mCenterY as Number = 0;
    private var mIsSleep as Boolean = true;

    // Settings
    private var mShowSecondsSetting as Boolean = true;
    private var mColorTheme as Number = 3;  // default Midnight Gold

    private var mFontTime as Graphics.FontType or Null = null;
    private var mFontDate as Graphics.FontType or Null = null;
    private var mFontTemp as Graphics.FontType or Null = null;
    private var mFontCond as Graphics.FontType or Null = null;
    private var mFontLabel as Graphics.FontType or Null = null;
    private var mFontValue as Graphics.FontType or Null = null;

    private var mThemes = [
        [0xE8B4A0, 0x8B5E4D, 0xF5D5C8, 0xD4A017], // 0 Rose Gold
        [0x5EB8B8, 0x2F6B6B, 0xA8E0E0, 0x3AA8A8], // 1 Arctic Teal
        [0xE07A3D, 0x8C4720, 0xF5B88A, 0xE85D04], // 2 Ember Orange
        [0xC5A26F, 0x6B5537, 0xE8D5A3, 0xF4A261], // 3 Midnight Gold (default)
        [0x5C8A5E, 0x2F4730, 0x9DC29E, 0x40916C], // 4 Forest Green
        [0xA78BBA, 0x5C4A6B, 0xD4C1E8, 0x9B7EBD], // 5 Lavender Mist
        [0xB8C4CE, 0x5F6B77, 0xE6EBF0, 0x8FA1B3], // 6 Pearl Silver
        [0xF4A261, 0x8C5C2E, 0xF8C58C, 0xE76F51]  // 7 Solar Amber
    ];

    enum WeatherCategory {
        WEATHER_CLEAR,
        WEATHER_CLOUDY,
        WEATHER_RAINY,
        WEATHER_SNOWY,
        WEATHER_STORMY,
        WEATHER_WINDY,
        WEATHER_FOGGY,
        WEATHER_MIXED,
        WEATHER_UNKNOWN
    }

    function initialize() {
        WatchFace.initialize();
        updateSettings();
    }

    function updateSettings() as Void {
        try {
            var app = Application.getApp();
            if (Application has :Properties) {
                mShowSecondsSetting = Application.Properties.getValue("ShowSeconds");
                mColorTheme = Application.Properties.getValue("ColorTheme");
            } else if (app != null) {
                mShowSecondsSetting = app.getProperty("ShowSeconds");
                mColorTheme = app.getProperty("ColorTheme");
            }
        } catch (e) {
            // keep defaults
        }
        sanitizeSettings();
    }

    function sanitizeSettings() as Void {
        if (mColorTheme < 0 || mColorTheme >= mThemes.size()) { mColorTheme = 3; }
    }

    function onLayout(dc as Dc) as Void {
        mScreenWidth = dc.getWidth();
        mScreenHeight = dc.getHeight();
        mCenterX = mScreenWidth / 2;
        mCenterY = mScreenHeight / 2;
        initFonts(dc);
    }

    function initFonts(dc as Dc) as Void {
        if (Graphics has :getVectorFont) {
            var face = ["RobotoCondensedBold", "RobotoRegular", "sans-serif"] as Array<String>;
            var faceRegular = ["RobotoCondensedRegular", "RobotoRegular", "sans-serif"] as Array<String>;

            mFontTime = Graphics.getVectorFont({ :face => face, :size => (mScreenWidth * 0.17).toNumber() });
            mFontDate = Graphics.getVectorFont({ :face => face, :size => (mScreenWidth * 0.058).toNumber() });
            mFontTemp = Graphics.getVectorFont({ :face => face, :size => (mScreenWidth * 0.105).toNumber() });
            mFontCond = Graphics.getVectorFont({ :face => faceRegular, :size => (mScreenWidth * 0.052).toNumber() });
            mFontLabel = Graphics.getVectorFont({ :face => face, :size => (mScreenWidth * 0.046).toNumber() });
            mFontValue = Graphics.getVectorFont({ :face => face, :size => (mScreenWidth * 0.054).toNumber() });
        }
        
        // Safety Fallbacks in case vector fonts failed to load or are unsupported
        if (mFontTime == null) { mFontTime = Graphics.FONT_NUMBER_MEDIUM; }
        if (mFontDate == null) { mFontDate = Graphics.FONT_TINY; }
        if (mFontTemp == null) { mFontTemp = Graphics.FONT_LARGE; }
        if (mFontCond == null) { mFontCond = Graphics.FONT_XTINY; }
        if (mFontLabel == null) { mFontLabel = Graphics.FONT_XTINY; }
        if (mFontValue == null) { mFontValue = Graphics.FONT_XTINY; }
    }

    function onShow() as Void {
        updateSettings();
    }

    function onUpdate(dc as Dc) as Void {
        updateSettings();

        var theme = mThemes[mColorTheme];
        var accent = theme[0];
        var accentDark = theme[1];
        var highlight = theme[2];

        // Base deep black background
        var bgColor = 0x05070A;
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // Screen margins and dimensions
        var w = mScreenWidth;
        var h = mScreenHeight;
        var cx = mCenterX;
        var cy = mCenterY;

        // AMOLED burn-in shift in sleep mode
        var deviceSettings = System.getDeviceSettings();
        var burnInX = 0;
        var burnInY = 0;
        var burnInActive = false;
        if ((deviceSettings has :requiresBurnInProtection) && deviceSettings.requiresBurnInProtection && mIsSleep) {
            burnInActive = true;
            var clockTime = System.getClockTime();
            var shift = (clockTime.min % 4);
            if (shift == 1) { burnInX = 4; burnInY = 2; }
            else if (shift == 2) { burnInX = -3; burnInY = 4; }
            else if (shift == 3) { burnInX = 3; burnInY = -4; }
        }

        cx += burnInX;
        cy += burnInY;

        // 1. Draw Header Status Row (Always visible)
        drawHeader(dc, cx, h * 0.08, accent, deviceSettings);

        // 2. Draw Digital Time & Date (Always visible)
        drawTimeAndDate(dc, cx, h * 0.24, h * 0.36, accent, highlight, burnInActive);

        // 3. Draw Weather Info & 5-Day Forecast (Skip in AOD burn-in mode to save power/pixels)
        if (!burnInActive) {
            drawWeatherModule(dc, cx, h * 0.47, h * 0.63, accent, accentDark);
        }

        // 4. Draw Activity Footer Grid (Skip in AOD burn-in mode to save power/pixels)
        if (!burnInActive) {
            drawActivityModule(dc, cx, h * 0.79, accent);
        }
    }

    // --- RENDER METHODS ---

    function drawHeader(dc as Dc, cx as Number, y as Float, accentColor as Number, deviceSettings as System.DeviceSettings) as Void {
        var stats = System.getSystemStats();
        var battery = stats.battery;
        var isCharging = stats.charging;
        var batY = y.toNumber();

        var showSolar = (stats has :solarIntensity) && (stats.solarIntensity != null);
        var showAlarm = deviceSettings.alarmCount > 0;
        var showDnd = (deviceSettings has :doNotDisturb) && deviceSettings.doNotDisturb;
        var showNotes = !showDnd && (deviceSettings.notificationCount > 0);

        // Track items to draw
        var count = 0;
        var ids = new [5] as Array<Number>;
        var widths = new [5] as Array<Number>;
        
        // Item 0: Battery (always visible)
        var batText = battery.format("%d") + "%";
        var batTextW = 0;
        if (mFontValue != null) {
            batTextW = dc.getTextWidthInPixels(batText, mFontValue);
        }
        ids[count] = 0;
        widths[count] = 14 + 4 + batTextW; // Battery Icon is 14px + 4px gap + text
        count++;

        // Item 1: Solar charging rate
        var solText = "";
        if (showSolar) {
            var solarVal = stats.solarIntensity;
            solText = solarVal.toString();
            var solTextW = 0;
            if (mFontValue != null) {
                solTextW = dc.getTextWidthInPixels(solText, mFontValue);
            }
            ids[count] = 1;
            widths[count] = 10 + 4 + solTextW; // Solar sun icon is 10px + 4px gap + text
            count++;
        }

        // Item 2: Phone status (always visible status icon)
        ids[count] = 2;
        widths[count] = 8; // Phone rect is 8px
        count++;

        // Item 3: Alarm icon
        if (showAlarm) {
            ids[count] = 3;
            widths[count] = 8; // Alarm bell is 8px
            count++;
        }

        // Item 4: Notification count or DND status
        var noteText = "";
        if (showDnd) {
            ids[count] = 4;
            widths[count] = 8; // DND moon crescent is 8px
            count++;
        } else if (showNotes) {
            noteText = deviceSettings.notificationCount.toString();
            var noteTextW = 0;
            if (mFontValue != null) {
                noteTextW = dc.getTextWidthInPixels(noteText, mFontValue);
            }
            ids[count] = 5;
            widths[count] = 14 + 4 + noteTextW; // Envelope is 14px + 4px gap + text
            count++;
        }

        // Gap spacing between elements
        var gap = 16;
        
        // Calculate total width of all visible elements
        var totalWidth = 0;
        for (var i = 0; i < count; i++) {
            totalWidth += widths[i];
        }
        totalWidth += (count - 1) * gap;

        // Start coordinate to align centered group
        var currentX = cx - (totalWidth / 2);
        
        // Draw elements from left to right
        for (var i = 0; i < count; i++) {
            var id = ids[i];
            var w = widths[i];
            
            if (id == 0) {
                // Battery
                drawBatteryIcon(dc, currentX + 7, batY, battery.toNumber(), isCharging, accentColor);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                if (mFontValue != null) {
                    dc.drawText(currentX + 18, batY, mFontValue, batText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            } 
            else if (id == 1) {
                // Solar intensity
                dc.setColor(0xF4A261, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawCircle(currentX + 3, batY, 3);
                dc.drawLine(currentX - 1, batY, currentX + 7, batY);
                dc.drawLine(currentX + 3, batY - 4, currentX + 3, batY + 4);
                
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                if (mFontValue != null) {
                    dc.drawText(currentX + 11, batY, mFontValue, solText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            } 
            else if (id == 2) {
                // Phone status
                dc.setPenWidth(1);
                if (deviceSettings.phoneConnected) {
                    dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
                    dc.drawRectangle(currentX, batY - 6, 8, 12);
                    dc.drawLine(currentX + 2, batY + 4, currentX + 6, batY + 4);
                } else {
                    dc.setColor(0x5F6B77, Graphics.COLOR_TRANSPARENT);
                    dc.drawRectangle(currentX, batY - 6, 8, 12);
                    dc.drawLine(currentX - 2, batY - 6, currentX + 10, batY + 6);
                }
            } 
            else if (id == 3) {
                // Alarm icon
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(currentX + 4, batY, 4);
                dc.drawLine(currentX + 4, batY, currentX + 4, batY - 2);
                dc.drawLine(currentX + 4, batY, currentX + 6, batY);
            } 
            else if (id == 4) {
                // DND crescent moon
                dc.setColor(0xA78BBA, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(currentX + 4, batY, 4, Graphics.ARC_CLOCKWISE, 45, 225);
            } 
            else if (id == 5) {
                // Notification envelope
                dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(currentX, batY - 4, 14, 9);
                dc.drawLine(currentX, batY - 4, currentX + 7, batY + 1);
                dc.drawLine(currentX + 14, batY - 4, currentX + 7, batY + 1);
                
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                if (mFontValue != null) {
                    dc.drawText(currentX + 18, batY, mFontValue, noteText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            }
            
            currentX += w + gap;
        }
    }

    function drawTimeAndDate(dc as Dc, cx as Number, yTime as Float, yDate as Float, accentColor as Number, highlightColor as Number, burnIn as Boolean) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var minute = clockTime.min;
        var second = clockTime.sec;

        var deviceSettings = System.getDeviceSettings();
        var is24 = deviceSettings.is24Hour;
        if (!is24) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }

        var hourStr = hour.format("%02d");
        var minStr = minute.format("%02d");
        var secStr = second.format("%02d");

        var fontTime = mFontTime;
        var fontDate = mFontDate;
        var fontValue = mFontValue;
        var fontLabel = mFontLabel;

        if (fontTime == null || fontDate == null || fontValue == null || fontLabel == null) {
            return;
        }

        // Draw Time: Hour (accent) and Minute (white) side-by-side
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 3, yTime.toNumber(), fontTime, hourStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 3, yTime.toNumber(), fontTime, minStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw Seconds if setting is enabled and not in low power mode
        if (mShowSecondsSetting && !mIsSleep && !burnIn) {
            var minWidth = dc.getTextWidthInPixels(minStr, fontTime);
            var secX = cx + 5 + minWidth + 4;
            dc.setColor(highlightColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(secX, yTime.toNumber() - 8, fontValue, secStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw Steps on the left and HR on the right (Skip in AOD burn-in mode)
        if (!burnIn) {
            // Steps
            var steps = 0;
            var info = ActivityMonitor.getInfo();
            if (info != null && info.steps != null) {
                steps = info.steps;
            }
            var leftColX = cx - (mScreenWidth * 0.30).toNumber();
            dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftColX, yTime.toNumber() - 12, fontLabel, "STEPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftColX, yTime.toNumber() + 8, fontValue, steps.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Heart Rate
            var hrStr = "--";
            var liveHr = getHeartRate();
            if (liveHr != null) {
                hrStr = liveHr.toString();
            }
            var rightColX = cx + (mScreenWidth * 0.30).toNumber();
            dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightColX, yTime.toNumber() - 12, fontLabel, "HR", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightColX, yTime.toNumber() + 8, fontValue, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Draw Date: e.g. "FRIDAY, JUN 12"
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dayName = info.day_of_week.toUpper();
        var monthName = info.month.toUpper();
        var dateStr = dayName + ", " + monthName + " " + info.day;

        dc.setColor(0xE6EBF0, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, yDate.toNumber(), fontDate, dateStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawWeatherModule(dc as Dc, cx as Number, yCurrent as Float, yForecast as Float, accentColor as Number, grayColor as Number) as Void {
        var curTemp = null;
        var curCond = null;
        var todayHigh = null;
        var todayLow = null;
        var dailyForecast = null;
        var humidity = null;
        var windSpeed = null;
        var precipChance = null;

        if (Toybox has :Weather) {
            var weatherInfo = Weather.getCurrentConditions();
            if (weatherInfo != null) {
                curTemp = weatherInfo.temperature;
                curCond = weatherInfo.condition;
                humidity = weatherInfo.relativeHumidity;
                windSpeed = weatherInfo.windSpeed;
                precipChance = weatherInfo.precipitationChance;
            }
            dailyForecast = Weather.getDailyForecast();
            if (dailyForecast != null && dailyForecast.size() > 0) {
                todayHigh = dailyForecast[0].highTemperature;
                todayLow = dailyForecast[0].lowTemperature;
            }
        }

        var fontTemp = mFontTemp;
        var fontCond = mFontCond;
        var fontLabel = mFontLabel;
        var fontValue = mFontValue;

        if (fontTemp == null || fontCond == null || fontLabel == null || fontValue == null) {
            return;
        }

        // A. Draw Live Weather Box
        var iconSize = (mScreenWidth * 0.09).toNumber();
        var currentY = yCurrent.toNumber();
        var curCategory = getWeatherCategory(curCond);

        // Weather Icon (Left-ish)
        drawWeatherIcon(dc, cx - 55, currentY, iconSize, iconSize, curCategory, accentColor);

        // Temp (Center-ish)
        var tempStr = (curTemp != null) ? formatTemp(curTemp) : "--°";
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 20, currentY, fontTemp, tempStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // High/Low and Secondary metrics (Right-ish)
        var metricsY = currentY - 8;
        var hiLoStr = "H:" + ((todayHigh != null) ? formatTempRaw(todayHigh) : "--°") + " L:" + ((todayLow != null) ? formatTempRaw(todayLow) : "--°");
        dc.setColor(0xE6EBF0, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 40, metricsY, fontValue, hiLoStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Extra details: precip, humidity, wind drawn as a CENTERED row below the temp so
        // nothing runs off the right edge (a big problem on round MIP screens).
        var detailY = currentY + 22;
        var elementGap = 14;
        var iconGap = 4;

        // Collect the metrics that are actually available (kind: 0=precip, 1=humidity, 2=wind)
        var dKind = [-1, -1, -1];
        var dText = ["", "", ""];
        var dCount = 0;

        if (precipChance != null) {
            dKind[dCount] = 0;
            dText[dCount] = precipChance.format("%d") + "%";
            dCount++;
        }
        if (humidity != null) {
            dKind[dCount] = 1;
            dText[dCount] = humidity.format("%d") + "%";
            dCount++;
        }
        if (windSpeed != null && windSpeed > 0) {
            var systemSettings = System.getDeviceSettings();
            var windText;
            if (systemSettings.distanceUnits == System.UNIT_STATUTE) {
                windText = (windSpeed * 2.23694).toNumber().toString() + " mph";
            } else {
                windText = (windSpeed * 3.6).toNumber().toString() + " kmh";
            }
            dKind[dCount] = 2;
            dText[dCount] = windText;
            dCount++;
        }

        // Measure total width so the row can be centered
        var totalW = 0;
        for (var i = 0; i < dCount; i++) {
            var iw = (dKind[i] == 2) ? 11 : 8;
            totalW += iw + iconGap + dc.getTextWidthInPixels(dText[i], fontCond);
            if (i > 0) { totalW += elementGap; }
        }

        var dx = cx - (totalW / 2);
        for (var i = 0; i < dCount; i++) {
            if (i > 0) { dx += elementGap; }
            var kind = dKind[i];
            var iw = (kind == 2) ? 11 : 8;
            if (kind == 0) {
                drawRaindropIcon(dc, dx, detailY, accentColor);
            } else if (kind == 1) {
                drawHumidityIcon(dc, dx, detailY, 0x9DB4C8);
            } else {
                drawWindIcon(dc, dx, detailY, accentColor);
            }
            dx += iw + iconGap;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dx, detailY, fontCond, dText[i], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dx += dc.getTextWidthInPixels(dText[i], fontCond);
        }


        // B. Draw 5-Day Forecast Row
        var forecastY = yForecast.toNumber();
        
        // Draw division line
        dc.setColor(0x1B2430, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - (mScreenWidth * 0.38).toNumber(), forecastY - 14, cx + (mScreenWidth * 0.38).toNumber(), forecastY - 14);

        if (dailyForecast != null && dailyForecast.size() > 0) {
            var forecastSize = dailyForecast.size();
            var totalCols = 5;
            if (forecastSize < totalCols) { totalCols = forecastSize; }
            
            var colWidth = mScreenWidth * 0.76;
            var spacing = colWidth / (totalCols - 1);
            var startX = cx - (colWidth / 2);

            for (var i = 0; i < totalCols; i++) {
                var f = dailyForecast[i];
                var fTime = f.forecastTime;
                var fHigh = f.highTemperature;
                var fLow = f.lowTemperature;
                var fCond = f.condition;

                var colX = (startX + i * spacing).toNumber();

                // Day Label (e.g. MON)
                var fInfo = Gregorian.info(fTime, Time.FORMAT_MEDIUM);
                var fDayStr = fInfo.day_of_week.toUpper();
                dc.setColor(0xE6EBF0, Graphics.COLOR_TRANSPARENT);
                dc.drawText(colX, forecastY - 4, fontLabel, fDayStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                // Icon
                var fCategory = getWeatherCategory(fCond);
                drawWeatherIcon(dc, colX, forecastY + 13, (mScreenWidth * 0.05).toNumber(), (mScreenWidth * 0.05).toNumber(), fCategory, accentColor);

                // Range (e.g. 80/62)
                var rangeStr = ((fHigh != null) ? formatTempRaw(fHigh) : "--") + "/" + ((fLow != null) ? formatTempRaw(fLow) : "--");
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(colX, forecastY + 28, fontLabel, rangeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            dc.setColor(0x5F6B77, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, forecastY + 10, fontCond, "CONNECT PHONE FOR FORECAST", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function drawActivityModule(dc as Dc, cx as Number, yRow as Float, accentColor as Number) as Void {
        var info = ActivityMonitor.getInfo();
        var systemSettings = System.getDeviceSettings();
        
        var calories = 0;
        var distanceStr = "0.0";
        var floors = 0;
        var activeMinutes = 0;

        if (info != null) {
            if (info.calories != null) { calories = info.calories; }
            if (info.floorsClimbed != null) { floors = info.floorsClimbed; }
            if (info.activeMinutesWeek != null && info.activeMinutesWeek.total != null) {
                activeMinutes = info.activeMinutesWeek.total;
            }
            if (info.distance != null) {
                var distanceKm = info.distance.toFloat() / 100000.0;
                if (systemSettings.distanceUnits == System.UNIT_STATUTE) {
                    var distanceMi = distanceKm * 0.621371;
                    distanceStr = distanceMi.format("%.2f");
                } else {
                    distanceStr = distanceKm.format("%.2f");
                }
            }
        }

        var fontLabel = mFontLabel;
        var fontValue = mFontValue;

        if (fontLabel == null || fontValue == null) {
            return;
        }

        // Layout spacing for 4 Columns
        var colW = mScreenWidth * 0.20;
        var col1X = (cx - 1.5 * colW).toNumber();
        var col2X = (cx - 0.5 * colW).toNumber();
        var col3X = (cx + 0.5 * colW).toNumber();
        var col4X = (cx + 1.5 * colW).toNumber();

        var rY = yRow.toNumber();

        // Col 1: Calories
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1X, rY - 6, fontLabel, "CAL", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1X, rY + 6, fontValue, calories.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Col 2: Distance
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col2X, rY - 6, fontLabel, "DIST", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col2X, rY + 6, fontValue, distanceStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Col 3: Floors
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col3X, rY - 6, fontLabel, "FLOORS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col3X, rY + 6, fontValue, floors.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Col 4: Active Minutes
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col4X, rY - 6, fontLabel, "ACTIVE", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col4X, rY + 6, fontValue, activeMinutes.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // --- DRAW UTILITIES ---

    function drawBatteryIcon(dc as Dc, x as Number, y as Number, percent as Number, isCharging as Boolean, accentColor as Number) as Void {
        var w = 14;
        var h = 8;
        
        var col = 0xFFFFFF; // white
        if (isCharging) {
            col = 0x40916C; // green
        } else if (percent < 20) {
            col = 0xE07A3D; // red/orange
        } else {
            col = accentColor;
        }
        
        dc.setColor(0x5F6B77, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(x - 7, y - 4, w, h);
        dc.drawRectangle(x + 7, y - 2, 2, 4); // tip
        
        var fillW = ((w - 4) * (percent / 100.0)).toNumber();
        if (fillW < 1 && percent > 0) { fillW = 1; }
        if (fillW > w - 4) { fillW = w - 4; }
        
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x - 5, y - 2, fillW, h - 4);
    }

    function formatTempRaw(tempC as Number or Float or Null) as String {
        if (tempC == null) { return "--"; }
        var systemSettings = System.getDeviceSettings();
        var tempVal = tempC;
        if (systemSettings.temperatureUnits == System.UNIT_STATUTE) {
            tempVal = (tempC * 9.0 / 5.0) + 32.0;
        }
        return tempVal.toNumber().toString();
    }

    function formatTemp(tempC as Number or Float or Null) as String {
        var raw = formatTempRaw(tempC);
        if (raw.equals("--")) { return "--"; }
        return raw + "°";
    }

    function getWeatherCategory(cond as Number or Null) as WeatherCategory {
        if (cond == null) { return WEATHER_UNKNOWN; }
        switch (cond) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_MOSTLY_CLEAR:
            case Weather.CONDITION_FAIR:
                return WEATHER_CLEAR;

            case Weather.CONDITION_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_THIN_CLOUDS:
                return WEATHER_CLOUDY;

            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_LIGHT_SHOWERS:
            case Weather.CONDITION_HEAVY_SHOWERS:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
                return WEATHER_RAINY;

            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:
            case Weather.CONDITION_FLURRIES:
            case Weather.CONDITION_CHANCE_OF_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
            case Weather.CONDITION_ICE:
            case Weather.CONDITION_ICE_SNOW:
                return WEATHER_SNOWY;

            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
            case Weather.CONDITION_TROPICAL_STORM:
            case Weather.CONDITION_HURRICANE:
            case Weather.CONDITION_TORNADO:
                return WEATHER_STORMY;

            case Weather.CONDITION_WINDY:
            case Weather.CONDITION_SQUALL:
                return WEATHER_WINDY;

            case Weather.CONDITION_FOG:
            case Weather.CONDITION_HAZE:
            case Weather.CONDITION_HAZY:
            case Weather.CONDITION_MIST:
            case Weather.CONDITION_SMOKE:
            case Weather.CONDITION_DUST:
            case Weather.CONDITION_SAND:
            case Weather.CONDITION_SANDSTORM:
            case Weather.CONDITION_VOLCANIC_ASH:
                return WEATHER_FOGGY;

            case Weather.CONDITION_WINTRY_MIX:
            case Weather.CONDITION_HAIL:
            case Weather.CONDITION_LIGHT_RAIN_SNOW:
            case Weather.CONDITION_HEAVY_RAIN_SNOW:
            case Weather.CONDITION_RAIN_SNOW:
            case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_FREEZING_RAIN:
            case Weather.CONDITION_SLEET:
                return WEATHER_MIXED;

            default:
                return WEATHER_UNKNOWN;
        }
    }

    function getWeatherLabel(category as WeatherCategory) as String {
        switch (category) {
            case WEATHER_CLEAR: return "CLEAR";
            case WEATHER_CLOUDY: return "CLOUDY";
            case WEATHER_RAINY: return "RAINY";
            case WEATHER_SNOWY: return "SNOWY";
            case WEATHER_STORMY: return "STORMY";
            case WEATHER_WINDY: return "WINDY";
            case WEATHER_FOGGY: return "FOGGY";
            case WEATHER_MIXED: return "MIXED";
            default: return "UNKNOWN";
        }
    }

    function drawCloud(dc as Dc, x as Number, y as Number, width as Number, height as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var rCenter = (height * 0.35).toNumber();
        var rLeft = (height * 0.25).toNumber();
        var rRight = (height * 0.25).toNumber();
        
        var offsetLeft = (width * 0.22).toNumber();
        var offsetRight = (width * 0.22).toNumber();
        var offsetCenterY = (height * 0.10).toNumber();
        var offsetBottomY = (height * 0.15).toNumber();
        
        dc.fillCircle(x - offsetLeft, y + offsetBottomY, rLeft);
        dc.fillCircle(x + offsetRight, y + offsetBottomY, rRight);
        dc.fillCircle(x, y - offsetCenterY, rCenter);
        dc.fillRectangle(x - offsetLeft, y + offsetBottomY - rLeft + 2, offsetLeft + offsetRight, rLeft + rRight - 2);
    }

    function drawWeatherIcon(dc as Dc, x as Number, y as Number, width as Number, height as Number, category as WeatherCategory, accentColor as Number) as Void {
        switch (category) {
            case WEATHER_CLEAR:
                var r = (height * 0.32).toNumber();
                dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, r);
                dc.setPenWidth(1);
                for (var angle = 0.0; angle < 2 * Math.PI; angle += Math.PI / 4.0) {
                    var cos = Math.cos(angle);
                    var sin = Math.sin(angle);
                    var x1 = x + (r * 1.35 * cos).toNumber();
                    var y1 = y + (r * 1.35 * sin).toNumber();
                    var x2 = x + (r * 1.8 * cos).toNumber();
                    var y2 = y + (r * 1.8 * sin).toNumber();
                    dc.drawLine(x1, y1, x2, y2);
                }
                break;

            case WEATHER_CLOUDY:
                drawCloud(dc, x, y, width, height, 0xB8C4CE);
                break;

            case WEATHER_RAINY:
                drawCloud(dc, x, y - 2, width, height, 0x7E8B96);
                dc.setColor(0x51A8FF, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                var dropY = y + (height * 0.35).toNumber();
                var dropH = (height * 0.15).toNumber();
                dc.drawLine(x - 4, dropY, x - 5, dropY + dropH);
                dc.drawLine(x, dropY + 2, x - 1, dropY + 2 + dropH);
                dc.drawLine(x + 4, dropY, x + 3, dropY + dropH);
                break;

            case WEATHER_SNOWY:
                drawCloud(dc, x, y - 2, width, height, 0xE6EBF0);
                dc.setColor(0xE6F2FF, Graphics.COLOR_TRANSPARENT);
                var snowY = y + (height * 0.35).toNumber();
                dc.fillCircle(x - 4, snowY, 1.5);
                dc.fillCircle(x, snowY + 2, 1.5);
                dc.fillCircle(x + 4, snowY, 1.5);
                break;

            case WEATHER_STORMY:
                drawCloud(dc, x, y - 2, width, height, 0x5F6B77);
                dc.setColor(0xFFD166, Graphics.COLOR_TRANSPARENT);
                var pts = [
                    [x + 1, y - 1],
                    [x - 3, y + 3],
                    [x - 1, y + 3],
                    [x - 3, y + 8],
                    [x + 3, y + 2],
                    [x, y + 2]
                ];
                dc.fillPolygon(pts);
                break;

            case WEATHER_WINDY:
                dc.setColor(0xB8C4CE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1.5);
                var w = (width * 0.4).toNumber();
                dc.drawLine(x - w, y - 4, x + w - 2, y - 4);
                dc.drawLine(x - w + 2, y, x + w, y);
                dc.drawLine(x - w, y + 4, x + w - 4, y + 4);
                break;

            case WEATHER_FOGGY:
                dc.setColor(0x7E8B96, Graphics.COLOR_TRANSPARENT);
                var fw = (width * 0.4).toNumber();
                dc.fillRectangle(x - fw, y - 5, 2 * fw, 2);
                dc.fillRectangle(x - fw + 2, y - 1, 2 * fw - 4, 2);
                dc.fillRectangle(x - fw + 1, y + 3, 2 * fw - 2, 2);
                break;

            case WEATHER_MIXED:
                drawCloud(dc, x, y - 2, width, height, 0x98A5B0);
                var mixY = y + (height * 0.35).toNumber();
                dc.setColor(0x51A8FF, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(x - 4, mixY, x - 5, mixY + 4);
                dc.setColor(0xE6F2FF, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x + 2, mixY + 1, 1.5);
                break;

            default:
                dc.setColor(0x5F6B77, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawCircle(x, y, (height * 0.32).toNumber());
                break;
        }
    }

    function getHeartRate() as Number or Null {
        try {
            var hr = null;
            if (Activity has :getActivityInfo) {
                var info = Activity.getActivityInfo();
                if (info != null) {
                    hr = info.currentHeartRate;
                }
            }

            if (hr == null && (Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
                var hrHistory = SensorHistory.getHeartRateHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
                if (hrHistory != null) {
                    var sample = hrHistory.next();
                    if (sample != null && sample.data != null) {
                        hr = sample.data;
                    }
                }
            }
            return hr;
        } catch (e) {
            return null;
        }
    }

    function drawRaindropIcon(dc as Dc, x as Number, y as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + 4, y + 2, 2);
        var pts = [
            [x + 2, y + 2],
            [x + 6, y + 2],
            [x + 4, y - 3]
        ];
        dc.fillPolygon(pts);
    }

    function drawHumidityIcon(dc as Dc, x as Number, y as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(x + 4, y + 2, 2);
        dc.drawLine(x + 2, y + 2, x + 4, y - 3);
        dc.drawLine(x + 6, y + 2, x + 4, y - 3);
    }

    function drawWindIcon(dc as Dc, x as Number, y as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x, y - 2, x + 9, y - 2);
        dc.drawLine(x + 2, y, x + 11, y);
        dc.drawLine(x + 1, y + 2, x + 7, y + 2);
    }

    function onHide() as Void {}
    
    function onExitSleep() as Void { 
        mIsSleep = false; 
        WatchUi.requestUpdate(); 
    }
    
    function onEnterSleep() as Void { 
        mIsSleep = true; 
        WatchUi.requestUpdate(); 
    }
}
