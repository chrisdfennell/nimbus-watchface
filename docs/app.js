// Nimbus Digital Watch Face Simulator Logic
const canvas = document.getElementById("watchCanvas");
const ctx = canvas.getContext("2d");

// Configuration state matching Connect IQ properties & mock sensors
const state = {
    colorTheme: 3, // Midnight Gold
    isSleep: false,
    showSeconds: true,
    phoneConnected: true,
    solarCharging: false,
    weatherCondition: "CLOUDY",
    temperature: 57,
    steps: 8400,
    heartRate: 76,
    battery: 50,
    calories: 320,
    distance: 4.25,
    floors: 8,
    activeMinutes: 45,
    notifications: 0,
    alarms: 0
};

// Theme color mapping from NimbusView.mc
const themes = [
    ["#E8B4A0", "#8B5E4D", "#F5D5C8"], // 0 Rose Gold
    ["#5EB8B8", "#2F6B6B", "#A8E0E0"], // 1 Arctic Teal
    ["#E07A3D", "#8C4720", "#F5B88A"], // 2 Ember Orange
    ["#C5A26F", "#6B5537", "#E8D5A3"], // 3 Midnight Gold (default)
    ["#5C8A5E", "#2F4730", "#9DC29E"], // 4 Forest Green
    ["#A78BBA", "#5C4A6B", "#D4C1E8"], // 5 Lavender Mist
    ["#B8C4CE", "#5F6B77", "#E6EBF0"], // 6 Pearl Silver
    ["#F4A261", "#8C5C2E", "#F8C58C"]  // 7 Solar Amber
];

// Weather conditions
const WEATHER_CLEAR = "CLEAR";
const WEATHER_CLOUDY = "CLOUDY";
const WEATHER_RAINY = "RAINY";
const WEATHER_SNOWY = "SNOWY";
const WEATHER_STORMY = "STORMY";
const WEATHER_WINDY = "WINDY";
const WEATHER_FOGGY = "FOGGY";
const WEATHER_MIXED = "MIXED";

// Draw procedural cloud shape
function drawCloud(ctx, x, y, width, height, color) {
    ctx.fillStyle = color;
    const rCenter = height * 0.35;
    const rLeft = height * 0.25;
    const rRight = height * 0.25;
    
    const offsetLeft = width * 0.22;
    const offsetRight = width * 0.22;
    const offsetCenterY = height * 0.10;
    const offsetBottomY = height * 0.15;
    
    ctx.beginPath();
    ctx.arc(x - offsetLeft, y + offsetBottomY, rLeft, 0, Math.PI * 2);
    ctx.arc(x + offsetRight, y + offsetBottomY, rRight, 0, Math.PI * 2);
    ctx.arc(x, y - offsetCenterY, rCenter, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillRect(x - offsetLeft, y + offsetBottomY - rLeft + 1, offsetLeft + offsetRight, rLeft + rRight - 1);
}

// Draw procedural weather icon
function drawWeatherIcon(ctx, x, y, width, height, category, accentColor) {
    switch (category) {
        case WEATHER_CLEAR: {
            const r = height * 0.32;
            ctx.fillStyle = accentColor;
            ctx.beginPath();
            ctx.arc(x, y, r, 0, Math.PI * 2);
            ctx.fill();
            
            ctx.strokeStyle = accentColor;
            ctx.lineWidth = 1.2;
            for (let angle = 0; angle < 2 * Math.PI; angle += Math.PI / 4) {
                const cos = Math.cos(angle);
                const sin = Math.sin(angle);
                ctx.beginPath();
                ctx.moveTo(x + r * 1.35 * cos, y + r * 1.35 * sin);
                ctx.lineTo(x + r * 1.8 * cos, y + r * 1.8 * sin);
                ctx.stroke();
            }
            break;
        }
        case WEATHER_CLOUDY:
            drawCloud(ctx, x, y, width, height, "#B8C4CE");
            break;
            
        case WEATHER_RAINY: {
            drawCloud(ctx, x, y - 2, width, height, "#7E8B96");
            ctx.strokeStyle = "#51A8FF";
            ctx.lineWidth = 1.2;
            const dropY = y + height * 0.35;
            const dropH = height * 0.15;
            
            ctx.beginPath();
            ctx.moveTo(x - 4, dropY); ctx.lineTo(x - 5, dropY + dropH);
            ctx.moveTo(x, dropY + 2); ctx.lineTo(x - 1, dropY + 2 + dropH);
            ctx.moveTo(x + 4, dropY); ctx.lineTo(x + 3, dropY + dropH);
            ctx.stroke();
            break;
        }
        case WEATHER_SNOWY: {
            drawCloud(ctx, x, y - 2, width, height, "#E6EBF0");
            ctx.fillStyle = "#E6F2FF";
            const snowY = y + height * 0.35;
            
            ctx.beginPath();
            ctx.arc(x - 4, snowY, 1.5, 0, Math.PI * 2);
            ctx.arc(x, snowY + 2, 1.5, 0, Math.PI * 2);
            ctx.arc(x + 4, snowY, 1.5, 0, Math.PI * 2);
            ctx.fill();
            break;
        }
        case WEATHER_STORMY: {
            drawCloud(ctx, x, y - 2, width, height, "#5F6B77");
            ctx.fillStyle = "#FFD166";
            ctx.beginPath();
            ctx.moveTo(x + 1, y - 1);
            ctx.lineTo(x - 3, y + 3);
            ctx.lineTo(x - 1, y + 3);
            ctx.lineTo(x - 3, y + 8);
            ctx.lineTo(x + 3, y + 2);
            ctx.lineTo(x, y + 2);
            ctx.closePath();
            ctx.fill();
            break;
        }
        case WEATHER_WINDY: {
            ctx.strokeStyle = "#B8C4CE";
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";
            
            // Draw flowing horizontal wind lines
            ctx.beginPath();
            ctx.moveTo(x - 10, y - 3);
            ctx.bezierCurveTo(x - 5, y - 6, x + 5, y, x + 10, y - 3);
            
            ctx.moveTo(x - 12, y + 1);
            ctx.bezierCurveTo(x - 7, y - 2, x + 3, y + 4, x + 8, y + 1);
            
            ctx.moveTo(x - 8, y + 5);
            ctx.bezierCurveTo(x - 3, y + 2, x + 7, y + 8, x + 11, y + 5);
            ctx.stroke();
            break;
        }
        case WEATHER_FOGGY: {
            ctx.strokeStyle = "#8E9AAB";
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            
            // Horizontal fog bars
            ctx.beginPath();
            ctx.moveTo(x - 9, y - 4); ctx.lineTo(x + 9, y - 4);
            ctx.moveTo(x - 12, y); ctx.lineTo(x + 12, y);
            ctx.moveTo(x - 8, y + 4); ctx.lineTo(x + 8, y + 4);
            ctx.stroke();
            break;
        }
        case WEATHER_MIXED: {
            drawCloud(ctx, x, y - 2, width, height, "#8E9AAB");
            // Raindrop
            ctx.strokeStyle = "#51A8FF";
            ctx.lineWidth = 1;
            const dropY = y + height * 0.35;
            ctx.beginPath();
            ctx.moveTo(x - 3, dropY); ctx.lineTo(x - 4, dropY + 4);
            ctx.stroke();
            
            // Snowflake
            ctx.fillStyle = "#E6F2FF";
            ctx.beginPath();
            ctx.arc(x + 3, dropY + 1, 1.2, 0, Math.PI * 2);
            ctx.fill();
            break;
        }
        default: {
            // Unknown: question mark
            ctx.fillStyle = accentColor;
            ctx.font = "bold 14px 'Inter', sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("?", x, y);
            break;
        }
    }
}

// Draw dynamic battery icon
function drawBatteryIcon(ctx, x, y, percent, isCharging, accentColor) {
    const w = 14;
    const h = 8;
    
    let col = "#FFFFFF";
    if (isCharging) {
        col = "#40916C"; // Green
    } else if (percent < 20) {
        col = "#E07A3D"; // Red/Orange
    } else {
        col = accentColor;
    }
    
    ctx.strokeStyle = "#5F6B77";
    ctx.lineWidth = 1;
    ctx.strokeRect(x - 7, y - 4, w, h);
    ctx.strokeRect(x + 7, y - 2, 2, 4);
    
    let fillW = (w - 4) * (percent / 100.0);
    if (fillW < 1 && percent > 0) fillW = 1;
    if (fillW > w - 4) fillW = w - 4;
    
    ctx.fillStyle = col;
    ctx.fillRect(x - 5, y - 2, fillW, h - 4);
}

// Draw status header row
function drawHeader(ctx, cx, y, accentColor) {
    const batY = y;
    
    // Check states
    const batText = state.battery + "%";
    const showSolar = state.solarCharging;
    const showAlarm = state.alarms > 0;
    const showDnd = state.notifications === 0 && !state.phoneConnected; // DND simulation if disconnected & no notes
    const showNotes = state.notifications > 0;
    
    // Assemble layout items & widths to center the group
    const items = [];
    ctx.font = "bold 10px 'Inter', sans-serif";
    
    // 1. Battery
    const batTextW = ctx.measureText(batText).width;
    items.push({
        id: "battery",
        width: 14 + 4 + batTextW,
        draw: (x) => {
            drawBatteryIcon(ctx, x + 7, batY, state.battery, false, accentColor);
            ctx.fillStyle = "#FFFFFF";
            ctx.textAlign = "left";
            ctx.textBaseline = "middle";
            ctx.fillText(batText, x + 18, batY);
        }
    });
    
    // 2. SolarCharging sun icon
    if (showSolar) {
        items.push({
            id: "solar",
            width: 10 + 4 + ctx.measureText("100").width,
            draw: (x) => {
                ctx.strokeStyle = "#F4A261";
                ctx.fillStyle = "#F4A261";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.arc(x + 3, batY, 2.5, 0, Math.PI * 2);
                ctx.stroke();
                // Sun rays
                for (let i = 0; i < 8; i++) {
                    const angle = i * Math.PI / 4;
                    ctx.beginPath();
                    ctx.moveTo(x + 3 + 3.5 * Math.cos(angle), batY + 3.5 * Math.sin(angle));
                    ctx.lineTo(x + 3 + 5 * Math.cos(angle), batY + 5 * Math.sin(angle));
                    ctx.stroke();
                }
                ctx.fillStyle = "#FFFFFF";
                ctx.textAlign = "left";
                ctx.textBaseline = "middle";
                ctx.fillText("100", x + 11, batY);
            }
        });
    }
    
    // 3. Phone Connection status
    items.push({
        id: "phone",
        width: 8,
        draw: (x) => {
            ctx.lineWidth = 1;
            if (state.phoneConnected) {
                ctx.strokeStyle = accentColor;
                ctx.strokeRect(x, batY - 6, 8, 12);
                ctx.fillStyle = accentColor;
                ctx.fillRect(x + 2, batY + 3, 4, 1.5);
            } else {
                ctx.strokeStyle = "#5F6B77";
                ctx.strokeRect(x, batY - 6, 8, 12);
                ctx.beginPath();
                ctx.moveTo(x - 2, batY - 6);
                ctx.lineTo(x + 10, batY + 6);
                ctx.stroke();
            }
        }
    });
    
    // 4. Alarm
    if (showAlarm) {
        items.push({
            id: "alarm",
            width: 8,
            draw: (x) => {
                ctx.strokeStyle = "#FFFFFF";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.arc(x + 4, batY - 1, 3.5, Math.PI, 0);
                ctx.lineTo(x + 8, batY + 3);
                ctx.lineTo(x, batY + 3);
                ctx.closePath();
                ctx.stroke();
                ctx.fillStyle = "#FFFFFF";
                ctx.beginPath();
                ctx.arc(x + 4, batY + 3, 1.5, 0, Math.PI);
                ctx.fill();
            }
        });
    }
    
    // 5. Notifications / DND
    if (showDnd) {
        items.push({
            id: "dnd",
            width: 8,
            draw: (x) => {
                ctx.strokeStyle = "#A78BBA";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.arc(x + 4, batY, 4, -Math.PI / 4, 3 * Math.PI / 4, false);
                ctx.arc(x + 5.5, batY, 2.8, 3 * Math.PI / 4, -Math.PI / 4, true);
                ctx.closePath();
                ctx.stroke();
            }
        });
    } else if (showNotes) {
        const noteText = state.notifications.toString();
        const noteTextW = ctx.measureText(noteText).width;
        items.push({
            id: "notes",
            width: 14 + 4 + noteTextW,
            draw: (x) => {
                ctx.strokeStyle = accentColor;
                ctx.lineWidth = 1;
                ctx.strokeRect(x, batY - 4, 14, 9);
                ctx.beginPath();
                ctx.moveTo(x, batY - 4);
                ctx.lineTo(x + 7, batY + 1);
                ctx.lineTo(x + 14, batY - 4);
                ctx.stroke();
                
                ctx.fillStyle = "#FFFFFF";
                ctx.textAlign = "left";
                ctx.textBaseline = "middle";
                ctx.fillText(noteText, x + 18, batY);
            }
        });
    }
    
    // Draw centered layout group
    const gap = 16;
    let totalW = 0;
    items.forEach((item, idx) => {
        totalW += item.width + (idx < items.length - 1 ? gap : 0);
    });
    
    let curX = cx - totalW / 2;
    items.forEach(item => {
        item.draw(curX);
        curX += item.width + gap;
    });
}

// Draw digital time & side labels
function drawTimeAndDate(ctx, cx, yTime, yDate, accentColor, highlightColor) {
    const now = new Date();
    let hr = now.getHours();
    const min = now.getMinutes().toString().padStart(2, "0");
    const sec = now.getSeconds().toString().padStart(2, "0");
    
    // Simulate 12-hour format
    hr = hr % 12;
    if (hr === 0) hr = 12;
    const hrStr = hr.toString().padStart(2, "0");
    
    // Font setup
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    
    // 1. Large Digital Clock (Hour in Accent, Minutes in White)
    ctx.font = "bold 77px 'Outfit', sans-serif";
    ctx.fillStyle = accentColor;
    ctx.textAlign = "right";
    ctx.fillText(hrStr, cx - 4, yTime);
    
    ctx.fillStyle = "#FFFFFF";
    ctx.textAlign = "left";
    ctx.fillText(min, cx + 4, yTime);
    
    // 2. Seconds Counter (small, aligned on the right of minutes)
    if (state.showSeconds && !state.isSleep) {
        const minW = ctx.measureText(min).width;
        const secX = cx + 8 + minW;
        ctx.font = "bold 18px 'Roboto Condensed', sans-serif";
        ctx.fillStyle = highlightColor;
        ctx.textAlign = "left";
        ctx.fillText(sec, secX, yTime - 18);
    }
    
    // 3. Side Complications (Steps and Heart Rate, hidden in AOD)
    if (!state.isSleep) {
        ctx.font = "500 9px 'Inter', sans-serif";
        const labelY = yTime - 12;
        const valueY = yTime + 10;
        
        // Steps (Left)
        const leftX = cx - 136;
        ctx.fillStyle = accentColor;
        ctx.textAlign = "center";
        ctx.fillText("STEPS", leftX, labelY);
        ctx.font = "bold 15px 'Roboto Condensed', sans-serif";
        ctx.fillStyle = "#FFFFFF";
        ctx.fillText(state.steps.toLocaleString(), leftX, valueY);
        
        // HR (Right)
        const rightX = cx + 136;
        ctx.font = "500 9px 'Inter', sans-serif";
        ctx.fillStyle = accentColor;
        ctx.fillText("HR", rightX, labelY);
        ctx.font = "bold 15px 'Roboto Condensed', sans-serif";
        ctx.fillStyle = "#FFFFFF";
        ctx.fillText(state.heartRate.toString(), rightX, valueY);
    }
    
    // 4. Date Banner (e.g. FRIDAY, JUN 12)
    const days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];
    const months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
    const dateStr = `${days[now.getDay()]}, ${months[now.getMonth()]} ${now.getDate()}`;
    
    ctx.font = "bold 13px 'Inter', sans-serif";
    ctx.fillStyle = "#E6EBF0";
    ctx.textAlign = "center";
    ctx.fillText(dateStr, cx, yDate);
}

function drawRaindropIcon(ctx, x, y, color) {
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(x + 4, y + 2, 2, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(x + 2, y + 2);
    ctx.lineTo(x + 6, y + 2);
    ctx.lineTo(x + 4, y - 3);
    ctx.closePath();
    ctx.fill();
}

function drawHumidityIcon(ctx, x, y, color) {
    ctx.strokeStyle = color;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(x + 4, y + 2, 2, 0, Math.PI * 2);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x + 2, y + 2);
    ctx.lineTo(x + 4, y - 3);
    ctx.lineTo(x + 6, y + 2);
    ctx.stroke();
}

function drawWindIcon(ctx, x, y, color) {
    ctx.strokeStyle = color;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x, y - 2); ctx.lineTo(x + 9, y - 2);
    ctx.moveTo(x + 2, y); ctx.lineTo(x + 11, y);
    ctx.moveTo(x + 1, y + 2); ctx.lineTo(x + 7, y + 2);
    ctx.stroke();
}

// Draw weather forecast metrics
function drawWeatherModule(ctx, cx, yCurrent, yForecast, accentColor, grayColor) {
    // Current temperature representation
    const tempStr = state.temperature + "°";
    const condLabel = state.weatherCondition;
    
    // Set weather presets for mockup high/low
    const todayHigh = 64;
    const todayLow = 51;
    
    // Draw Current Weather Layout
    ctx.textBaseline = "middle";
    
    // Weather Icon (Left alignment)
    drawWeatherIcon(ctx, cx - 55, yCurrent, 40, 40, condLabel, accentColor);
    
    // Temp value (Center alignment)
    ctx.font = "bold 42px 'Outfit', sans-serif";
    ctx.fillStyle = "#FFFFFF";
    ctx.textAlign = "left";
    ctx.fillText(tempStr, cx - 20, yCurrent);
    
    // High / Low temperatures range
    ctx.font = "bold 14px 'Roboto Condensed', sans-serif";
    ctx.fillStyle = grayColor;
    const rangeY = yCurrent - 10;
    ctx.fillText(`H:${todayHigh}° L:${todayLow}°`, cx + 40, rangeY);
    
    // Secondary metrics: precip, humidity, wind drawn programmatically
    let detailX = cx + 40;
    const detailY = rangeY + 18;
    const elementGap = 12;
    const iconGap = 4;
    
    ctx.font = "10px 'Inter', sans-serif";
    ctx.textAlign = "left";
    ctx.textBaseline = "middle";
    
    // 1. Precip
    const prcText = "16%";
    drawRaindropIcon(ctx, detailX, detailY, accentColor);
    detailX += 8 + iconGap;
    ctx.fillStyle = "#FFFFFF";
    ctx.fillText(prcText, detailX, detailY);
    detailX += ctx.measureText(prcText).width + elementGap;
    
    // 2. Humidity
    const humText = "62%";
    drawHumidityIcon(ctx, detailX, detailY, grayColor);
    detailX += 8 + iconGap;
    ctx.fillStyle = "#FFFFFF";
    ctx.fillText(humText, detailX, detailY);
    detailX += ctx.measureText(humText).width + elementGap;
    
    // 3. Wind
    const windText = "1 mph";
    drawWindIcon(ctx, detailX, detailY, accentColor);
    detailX += 11 + iconGap;
    ctx.fillStyle = "#FFFFFF";
    ctx.fillText(windText, detailX, detailY);
    
    // Weather status name below (e.g. CLOUDY)
    ctx.font = "bold 10px 'Inter', sans-serif";
    ctx.fillStyle = accentColor;
    ctx.textAlign = "center";
    ctx.fillText(condLabel, cx, yCurrent + 26);
    
    // Daily Forecast row below
    const forecastY = yForecast;
    
    // Division Line
    ctx.strokeStyle = "#1B2430";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(cx - 170, forecastY - 14);
    ctx.lineTo(cx + 170, forecastY - 14);
    ctx.stroke();
    
    // 5 Columns Daily Forecast
    const forecastData = [
        { day: "FRI", temp: "64/51", cond: "CLOUDY" },
        { day: "SAT", temp: "69/59", cond: "CLOUDY" },
        { day: "SUN", temp: "68/59", cond: "CLOUDY" },
        { day: "MON", temp: "64/53", cond: "CLOUDY" },
        { day: "TUE", temp: "62/51", cond: "CLOUDY" }
    ];
    
    // Override the forecast conditions based on the current weather setting to match states
    forecastData.forEach(f => f.cond = condLabel);
    
    const colW = 340 / 4;
    const startX = cx - 170;
    
    forecastData.forEach((f, idx) => {
        const colX = startX + idx * colW;
        
        // Day Label
        ctx.font = "bold 9px 'Inter', sans-serif";
        ctx.fillStyle = "#B8C4CE";
        ctx.textAlign = "center";
        ctx.fillText(f.day, colX, forecastY - 4);
        
        // Weather Icon
        drawWeatherIcon(ctx, colX, forecastY + 13, 22, 22, f.cond, accentColor);
        
        // High/low temperature ranges
        ctx.font = "bold 10px 'Roboto Condensed', sans-serif";
        ctx.fillStyle = "#FFFFFF";
        ctx.fillText(f.temp, colX, forecastY + 28);
    });
}

// Draw bottom activity columns grid
function drawActivityModule(ctx, cx, yRow, accentColor) {
    const colW = 90;
    const columns = [
        { label: "CAL", val: state.calories.toString() },
        { label: "DIST", val: state.distance.toFixed(2) },
        { label: "FLOORS", val: state.floors.toString() },
        { label: "ACTIVE", val: state.activeMinutes.toString() }
    ];
    
    const startX = cx - 1.5 * colW;
    
    columns.forEach((col, idx) => {
        const colX = startX + idx * colW;
        
        // Label
        ctx.font = "bold 10px 'Inter', sans-serif";
        ctx.fillStyle = accentColor;
        ctx.textAlign = "center";
        ctx.fillText(col.label, colX, yRow - 6);
        
        // Value
        ctx.font = "bold 14px 'Roboto Condensed', sans-serif";
        ctx.fillStyle = "#FFFFFF";
        ctx.fillText(col.val, colX, yRow + 8);
    });
}

// Draw the watch face
function drawWatchFace() {
    const cx = canvas.width / 2;
    const cy = canvas.height / 2;
    
    const theme = themes[state.colorTheme];
    const accent = theme[0];
    const accentDark = theme[1];
    const highlight = theme[2];
    const bgColor = "#05070A";
    
    // Clear screen
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Canvas background
    ctx.fillStyle = bgColor;
    ctx.beginPath();
    ctx.arc(cx, cy, cx, 0, Math.PI * 2);
    ctx.fill();
    
    // Calculate AMOLED active shift offset (only in sleep mode)
    let burnInX = 0;
    let burnInY = 0;
    if (state.isSleep) {
        const now = new Date();
        const shift = now.getMinutes() % 4;
        if (shift === 1) { burnInX = 4; burnInY = 2; }
        else if (shift === 2) { burnInX = -3; burnInY = 4; }
        else if (shift === 3) { burnInX = 3; burnInY = -4; }
    }
    
    const activeCenterX = cx + burnInX;
    const activeCenterY = cy + burnInY;
    
    // 1. Draw Header Status Row (Always visible)
    drawHeader(ctx, activeCenterX, 36 + burnInY, accent);
    
    // 2. Draw Digital Time & Date (Always visible)
    drawTimeAndDate(ctx, activeCenterX, 127 + burnInY, 172 + burnInY, accent, highlight);
    
    // 3. Draw Weather Module (Hidden in Sleep Mode)
    if (!state.isSleep) {
        drawWeatherModule(ctx, activeCenterX, 222 + burnInY, 295 + burnInY, accent, accentDark);
    }
    
    // 4. Draw Activity Module (Hidden in Sleep Mode)
    if (!state.isSleep) {
        drawActivityModule(ctx, activeCenterX, 368 + burnInY, accent);
    }
}

// Tick loop
function tick() {
    drawWatchFace();
    requestAnimationFrame(tick);
}

// Setup Event Listeners for UI interaction
document.querySelectorAll(".theme-btn").forEach(btn => {
    btn.addEventListener("click", (e) => {
        document.querySelectorAll(".theme-btn").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        state.colorTheme = parseInt(btn.getAttribute("data-theme"));
    });
});

const sleepCheckbox = document.getElementById("sleepMode");
sleepCheckbox.addEventListener("change", (e) => {
    state.isSleep = e.target.checked;
});

const secondsCheckbox = document.getElementById("showSeconds");
secondsCheckbox.addEventListener("change", (e) => {
    state.showSeconds = e.target.checked;
});

const phoneCheckbox = document.getElementById("phoneConnected");
phoneCheckbox.addEventListener("change", (e) => {
    state.phoneConnected = e.target.checked;
});

const solarCheckbox = document.getElementById("solarCharging");
solarCheckbox.addEventListener("change", (e) => {
    state.solarCharging = e.target.checked;
});

const weatherSelect = document.getElementById("weatherCondition");
weatherSelect.addEventListener("change", (e) => {
    state.weatherCondition = e.target.value;
});

const tempInput = document.getElementById("tempInput");
const tempVal = document.getElementById("tempVal");
tempInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.temperature = val;
    tempVal.textContent = val + "°F";
});

const stepsInput = document.getElementById("stepsInput");
const stepsVal = document.getElementById("stepsVal");
stepsInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.steps = val;
    stepsVal.textContent = val.toLocaleString();
});

const hrInput = document.getElementById("hrInput");
const hrVal = document.getElementById("hrVal");
hrInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.heartRate = val;
    hrVal.textContent = val + " BPM";
});

const batteryInput = document.getElementById("batteryInput");
const batteryVal = document.getElementById("batteryVal");
batteryInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.battery = val;
    batteryVal.textContent = val + "%";
});

const calInput = document.getElementById("calInput");
const calVal = document.getElementById("calVal");
calInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.calories = val;
    calVal.textContent = val + " kcal";
});

const distanceInput = document.getElementById("distanceInput");
const distanceVal = document.getElementById("distanceVal");
distanceInput.addEventListener("input", (e) => {
    const val = parseFloat(e.target.value);
    state.distance = val;
    distanceVal.textContent = val.toFixed(2) + " mi";
});

const floorsInput = document.getElementById("floorsInput");
const floorsVal = document.getElementById("floorsVal");
floorsInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.floors = val;
    floorsVal.textContent = val.toString();
});

const activeInput = document.getElementById("activeInput");
const activeVal = document.getElementById("activeVal");
activeInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.activeMinutes = val;
    activeVal.textContent = val + " min";
});

const notesInput = document.getElementById("notesInput");
const notesVal = document.getElementById("notesVal");
notesInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.notifications = val;
    notesVal.textContent = val.toString();
});

const alarmsInput = document.getElementById("alarmsInput");
const alarmsVal = document.getElementById("alarmsVal");
alarmsInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.alarms = val;
    alarmsVal.textContent = val.toString();
});

// Run
tick();
