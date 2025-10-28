# Color Palette Update

## ✅ Changes Made

### 1. **Legend Readability Fixed**
- ❌ **Before**: Scale bar had confusing dashes (e.g., `--50` for -50%)
- ✅ **After**: Clean formatting with clear signs (e.g., `-50%` and `+50%`)
- Legend now uses `between = " to "` for ranges
- Negative values are clear and readable

### 2. **Less Yellow, More Intuitive Colors**

#### Continuous Scale (Updated)

**New 6-color gradient:**
```
Dark Red    → Orange-Red → Light Yellow → Light Green → Medium Green → Dark Green
#d73027     → #fc8d59    → #fee08b      → #d9ef8b     → #91cf60      → #1a9850

Disruption                    Stable                      Surplus
<-------------------------------------------------------------------->
-100%                           0%                         +100%
```

**Color meanings:**
- 🔴 **Dark Red** (#d73027) = Severe disruption (< -50%)
- 🟠 **Orange** (#fc8d59) = Moderate disruption (-25% to -50%)
- 🟡 **Light Yellow** (#fee08b) = Mild disruption (-5% to -25%)
- 🟢 **Light Green** (#d9ef8b) = Mild surplus (+5% to +25%)
- 💚 **Medium Green** (#91cf60) = Moderate surplus (+25% to +50%)
- 🌲 **Dark Green** (#1a9850) = Strong surplus (> +50%)

**Key improvement:** Yellow is now only used minimally around the zero point, making disruption (red) and surplus (green) more distinct.

---

#### Categorical Scale (Updated)

**Before:**
```
Disruption >10%    = #d7191c (dark red)
Disruption 5-10%   = #fdae61 (bright orange-yellow) ← Too yellow
Stable             = #ffffbf (bright yellow) ← Very bright
Surplus 5-10%      = #a6d96a (light green)
Surplus >10%       = #1a9641 (dark green)
Insufficient data  = #999999 (gray)
```

**After:**
```
Disruption >10%    = #d73027 (dark red) ← Slightly adjusted
Disruption 5-10%   = #fc8d59 (orange) ← Less yellow, more orange
Stable             = #ffffcc (very light yellow) ← Much softer
Surplus 5-10%      = #91cf60 (medium green) ← More vibrant
Surplus >10%       = #1a9850 (dark green) ← Slightly adjusted
Insufficient data  = #999999 (gray) ← Unchanged
```

---

## 🎨 Color Psychology

**Why these colors work better:**

1. **Red for Disruption** 🔴
   - Universal signal for problems/danger
   - Grabs attention immediately
   - Dark to light gradient shows severity

2. **Minimal Yellow** 🟡
   - Only used near zero (neutral zone)
   - Light and subtle, not overwhelming
   - Indicates "caution" or "watch" rather than alarm

3. **Green for Surplus** 🟢
   - Universal signal for "good" or "above target"
   - Dark green = strong performance
   - Gradient shows intensity of surplus

4. **Gray for Missing Data** ⚫
   - Neutral, non-distracting
   - Clearly indicates "no data" not "bad data"

---

## 📊 Legend Format Examples

**Before (hard to read):**
```
Legend: % Change from Expected
 --100 - --50  ▇▇▇ (dark red)
 --50 - --25   ▇▇▇ (orange)
 --25 - 0      ▇▇▇ (yellow)
   0 - 25      ▇▇▇ (light green)
  25 - 50      ▇▇▇ (green)
  50 - 100     ▇▇▇ (dark green)
```

**After (clear and readable):**
```
Legend: % Change from Expected
 -100% to -50%  ▇▇▇ (dark red)
  -50% to -25%  ▇▇▇ (orange)
  -25% to 0%    ▇▇▇ (light yellow)
    0% to +25%  ▇▇▇ (light green)
  +25% to +50%  ▇▇▇ (green)
  +50% to +100% ▇▇▇ (dark green)
```

**Key improvements:**
- ✅ Clear negative sign (single dash)
- ✅ Clear positive sign (+ symbol)
- ✅ Percentage symbol on each value
- ✅ "to" separator instead of dash
- ✅ No double dashes or confusion

---

## 🧪 Test the Changes

Run the app and check:

```bash
cd /Users/claireboulange/Desktop/modules/disruption_mapping
R -e "shiny::runApp(launch.browser = TRUE)"
```

**What to verify:**
1. ✅ Legend shows clean numbers (no double dashes)
2. ✅ Negative values have single `-` sign
3. ✅ Positive values have `+` sign (optional in display)
4. ✅ Colors transition smoothly from red → yellow → green
5. ✅ Yellow is minimal and subtle
6. ✅ Disruption areas clearly stand out in red/orange
7. ✅ Surplus areas clearly show in green

---

## 🔄 Reverting Changes (if needed)

If you want to go back to the old color scheme:

**For continuous palette** (in `R/map_functions.R`):
```r
create_continuous_palette <- function() {
  colorNumeric(
    palette = colorRampPalette(c("#d7191c", "#fdae61", "#ffffbf", "#a6d96a", "#1a9641"))(100),
    domain = c(-100, 100),
    na.color = "#999999"
  )
}
```

**For categorical colors** (in `R/indicators.R`):
```r
category_colors <- c(
  "Disruption >10%" = "#d7191c",
  "Disruption 5-10%" = "#fdae61",
  "Stable" = "#ffffbf",
  "Surplus 5-10%" = "#a6d96a",
  "Surplus >10%" = "#1a9641",
  "Insufficient data" = "#999999"
)
```

---

## 📈 Files Modified

1. **R/map_functions.R**
   - Updated `create_continuous_palette()` with new 6-color gradient
   - Updated legend `labFormat` for clearer number display

2. **R/indicators.R**
   - Updated `category_colors` with softer yellow and adjusted reds/greens

---

## 💡 Future Customization

Want different colors? Edit these values:

**In `R/map_functions.R`** (continuous scale):
```r
palette = colorRampPalette(c(
  "YOUR_DARK_RED",   # -100%
  "YOUR_MID_RED",
  "YOUR_YELLOW",     # 0%
  "YOUR_MID_GREEN",
  "YOUR_DARK_GREEN"  # +100%
))(100)
```

**In `R/indicators.R`** (categorical scale):
```r
category_colors <- c(
  "Disruption >10%" = "YOUR_COLOR",
  "Disruption 5-10%" = "YOUR_COLOR",
  # ... etc
)
```

**Color tools:**
- ColorBrewer: https://colorbrewer2.org/
- Coolors: https://coolors.co/
- Adobe Color: https://color.adobe.com/

---

**Questions?** Test the app and adjust colors to your preference!
