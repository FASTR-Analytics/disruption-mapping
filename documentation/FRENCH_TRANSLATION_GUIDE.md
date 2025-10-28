# French Translation Feature Guide

## ✅ Feature Complete!

Your app now supports **bilingual operation** - English and French with a single button click.

---

## 🌍 How It Works

### Language Toggle Button

Located in the **top-right corner** of the app header:
- **Button shows "FR"** when app is in English → Click to switch to French
- **Button shows "EN"** when app is in French → Click to switch to English

The button is styled in FASTR teal (#0f706d) to match your theme.

---

## 📋 What Gets Translated

### 1. **Indicator Names** (44 indicators)
All health indicators have French translations:

| English | Français |
|---------|----------|
| Antenatal care 1st visit | Soins prénatals 1ère visite |
| BCG vaccine | Vaccin BCG |
| Institutional delivery | Accouchement institutionnel |
| Measles vaccine 1 | Vaccin rougeole 1 |
| Outpatient visit | Visite ambulatoire |
| ... (all 44 indicators) | ... |

### 2. **UI Labels**
- Data Selection → Sélection des Données
- Select Country → Sélectionner le Pays
- Administrative Level → Niveau Administratif
- Select Indicator → Sélectionner l'Indicateur
- Color Scale → Échelle de Couleur
- Show Values on Map → Afficher les Valeurs sur la Carte
- Download Map as PNG → Télécharger la Carte en PNG

### 3. **Disruption Categories**
- Disruption >10% → Perturbation >10%
- Disruption 5-10% → Perturbation 5-10%
- Stable → Stable (same)
- Surplus 5-10% → Surplus 5-10% (same)
- Surplus >10% → Surplus >10% (same)
- Insufficient data → Données Insuffisantes

### 4. **Chart Labels**
- Number of Areas → Nombre de Zones
- Percent Change from Expected → Pourcentage de Changement par Rapport à l'Attendu
- Distribution of Areas by Disruption Category → Distribution des Zones par Catégorie de Perturbation
- Top 10 Areas with Highest Disruption → Top 10 des Zones avec la Plus Forte Perturbation

### 5. **Table Column Headers**
- Admin Level 2 → Niveau Admin 2
- Admin Level 3 → Niveau Admin 3
- Indicator → Indicateur
- Period → Période
- Year → Année
- Actual → Réel
- Expected → Attendu
- % Change → % Changement
- Administrative Area → Zone Administrative
- Category → Catégorie
- Actual Count → Compte Réel
- Expected Count → Compte Attendu

### 6. **Value Boxes**
- Total Areas → Zones Totales
- Areas with Disruption → Zones avec Perturbation
- Stable Areas → Zones Stables
- Areas with Surplus → Zones avec Surplus

---

## 🎬 User Experience

### Switching Languages

1. **User opens app** → Defaults to English
2. **User clicks "FR" button** → Everything switches to French instantly
   - Indicator dropdown updates to French names
   - All UI labels change to French
   - Charts and tables update
   - Categories translate
3. **User clicks "EN" button** → Everything switches back to English

### What Updates Automatically

When language changes:
- ✅ Indicator dropdown list
- ✅ All UI text and labels
- ✅ Chart titles and axes
- ✅ Table column headers
- ✅ Category names in tables and charts
- ✅ Value box labels
- ✅ Legend titles

### What Stays the Same

- ❌ Data values (numbers don't change)
- ❌ Area names (geographic names stay as-is)
- ❌ Country names (stay as-is in dropdown)
- ❌ Map visualization (only legend title changes)

---

## 🧪 Testing the Feature

```bash
cd /Users/claireboulange/Desktop/modules/disruption_mapping
R -e "shiny::runApp(launch.browser = TRUE)"
```

**Test checklist:**
1. ✅ App loads in English by default
2. ✅ FR button visible in top-right
3. ✅ Click FR → App switches to French
4. ✅ Button changes to "EN"
5. ✅ Indicator dropdown shows French names
6. ✅ Upload data → Charts show French labels
7. ✅ Tables show French column headers
8. ✅ Click EN → Everything switches back to English

---

## 📁 Implementation Files

### New File Created
**`R/translations.R`** - Complete translation dictionary
- English translations in `ui_translations$en`
- French translations in `ui_translations$fr`
- Helper function `t(key, lang)` to get translations
- French indicator labels in `indicator_labels_fr`

### Files Modified
**`R/ui_components.R`**
- Added language toggle button to header

**`app.R`**
- Sources translations.R
- Added reactive language state `rv$lang`
- Language toggle observer
- Reactive translation function `tr()`
- Reactive `current_indicator_labels()` based on language
- Updated all charts, tables, and labels to use translations

---

## 🔧 How to Add More Translations

### Add New UI Text

Edit `R/translations.R`:

```r
ui_translations <- list(
  en = list(
    # ... existing translations ...
    new_label = "New English Text"
  ),
  fr = list(
    # ... existing translations ...
    new_label = "Nouveau Texte Français"
  )
)
```

Use in app:
```r
# In app.R
tr()("new_label")  # Returns text in current language
```

### Add New Indicator

Edit `R/translations.R`:

```r
# Add to indicator_labels (English) in R/indicators.R
# Then add French version:
indicator_labels_fr <- rbind(
  indicator_labels_fr,
  data.frame(
    indicator_id = "new_indicator",
    indicator_name = "Nom de l'Indicateur en Français",
    stringsAsFactors = FALSE
  )
)
```

---

## 🌐 Language Support Details

### Default Language
- App starts in **English** (`rv$lang = "en"`)
- Can be changed in app.R if you want French default

### Fallback Behavior
- If translation key not found, shows the key itself
- Prevents app crashes from missing translations
- Helps identify untranslated items

### Translation Function
```r
t(key, lang)  # Get translation for key in specified language
tr()(key)     # Get translation in current reactive language
```

---

## 📊 Translation Coverage

**Full Coverage:**
- ✅ 44/44 indicators translated
- ✅ All UI labels translated
- ✅ All chart labels translated
- ✅ All table headers translated
- ✅ All categories translated
- ✅ All value box labels translated

**Not Translated** (by design):
- Area/place names (geographic proper nouns)
- Country codes
- Data values
- File names

---

## 🎨 Button Styling

The FR/EN button uses FASTR theme colors:
- Background: `#0f706d` (FASTR teal)
- Hover: `#1a8b86` (lighter teal)
- Text: White
- Positioned in header dropdown area

---

## 🚀 Deployment

French translations work in all deployment modes:
- ✅ Local (RStudio)
- ✅ Docker/Hugging Face
- ✅ Shiny Server

No additional configuration needed!

---

## 💡 Pro Tips

1. **Test both languages** when uploading new data
2. **Export maps** work in both languages (indicator names in filename)
3. **Database mode** supports French translations automatically
4. **Categories in exports** use current language

---

## 📝 Example Use Cases

### Francophone Countries
Perfect for:
- Guinea
- Senegal
- Mali
- Burkina Faso
- Niger
- Other French-speaking regions

### Bilingual Reporting
- Present to French-speaking stakeholders
- Switch to English for international audience
- Same app, two audiences

### Training
- Train users in their preferred language
- Documentation can reference French interface

---

## ❓ Troubleshooting

**Button doesn't show:**
- Check that FR button is in header
- Verify `R/translations.R` is sourced

**Labels don't change:**
- Check browser console for errors
- Verify reactive `tr()` function is used
- Check that `rv$lang` updates correctly

**Some text stays in English:**
- Check if that text uses `tr()` function
- Add missing translation to `R/translations.R`

---

**Bilingual support complete!** 🇬🇧 🇫🇷

Your app now serves both English and French-speaking users with a single click!
