# Indicator Labels Update - October 2024

## ✅ What Was Updated

Added **8 new health indicators** with both English and French labels to support additional data from Sierra Leone and other countries.

---

## 🆕 New Indicators Added

### HIV/AIDS Indicators
| Indicator ID | English Label | French Label |
|-------------|---------------|--------------|
| `hiv_tested` | HIV tests performed | Tests VIH réalisés |
| `hiv_treated` | PLHIV on ART regularly followed | PVVIH sous ARV régulièrement suivis |

### Malaria Indicators
| Indicator ID | English Label | French Label |
|-------------|---------------|--------------|
| `malaria_confirmed` | Confirmed malaria cases | Cas de palu confirmés |
| `malaria_tested` | Malaria tests performed | Cas de palu testés |
| `malaria_treated` | Malaria cases treated | Cas de palu traités |

### Tuberculosis Indicators
| Indicator ID | English Label | French Label |
|-------------|---------------|--------------|
| `tb_confirmed` | TB cases confirmed | Cas TB déclarés |
| `tb_treated` | TB cases treated | Cas TB traités |

### Vaccination Indicators
| Indicator ID | English Label | French Label |
|-------------|---------------|--------------|
| `rr1` | Measles-Rubella vaccine 1 | Vaccin Rougeole-Rubéole 1 |

---

## 📊 Total Indicators Now Supported

**52 indicators** covering:
- Maternal Health (8 indicators)
- Child Health & Immunization (10 indicators)
- Malaria (9 indicators)
- HIV/AIDS (2 indicators)
- Tuberculosis (2 indicators)
- Nutrition (4 indicators)
- Family Planning (3 indicators)
- GBV (2 indicators)
- General Services (4 indicators)
- Other conditions (8 indicators)

---

## ✏️ Updated Existing Labels

### IPT3
- **English**: Changed from "IPT3" to **"IPT3 (pregnant women)"**
- **French**: Changed from "TPI3" to **"TPI3 (femmes enceintes)"**

### Shortened French Labels (for better display)
- **anc1**: "Soins prénatals 1ère visite" → **"CPN 1"**
- **anc4**: "Soins prénatals 4ème visite" → **"CPN 4"**
- **delivery**: "Accouchement institutionnel" → **"Accouchements institutionels"**
- **ipd**: "Visite en hospitalisation" → **"Visites hospitalières"**
- **opd**: "Visite ambulatoire" → **"Visites ambulatoires"**
- **pnc1_mother**: "Soins postnatals 1 (mères)" → **"Soins Postnatals 1- Mères"**
- **pnc1_newborn**: "Soins postnatals 1 (nouveau-nés)" → **"Soins Postnatals 1- Nouveau-né"**
- **sba**: "Accouchements par personnel qualifié (SBA)" → **"Accouchement - Personnel Qualifié"**

---

## 📂 Files Updated

### `R/indicators.R`
- Added 8 new indicator IDs
- Added corresponding English labels
- Now contains **52 total indicators** (was 44)

### `R/translations.R`
- Added 8 new indicator French translations
- Updated existing French labels for better consistency
- Matches all indicators in `indicators.R`

---

## 🎯 Use Cases

### Sierra Leone Data
The new indicators were specifically added to support Sierra Leone's health data which includes:
- HIV testing and treatment metrics
- Malaria confirmation and treatment tracking
- TB case management
- Measles-Rubella vaccination

### Other Countries
All indicators are now available for any country using the disruption mapping tool.

---

## 🧪 Testing

To verify the updates:

1. **Restart your app:**
```bash
cd /Users/claireboulange/Desktop/modules/disruption_mapping
R -e "shiny::runApp()"
```

2. **Check English labels:**
- Load data with the new indicator IDs
- Verify indicator dropdown shows English names correctly
- Check map, heatmap, and statistics display

3. **Check French labels:**
- Click **FR** button to switch language
- Verify all indicators translate properly
- Check that new indicators appear in French

4. **Test heatmap:**
- Go to **Heatmap** tab
- Verify all 52 indicators display in the matrix
- Check labels are readable

---

## 📋 Complete Indicator List

### All 52 Supported Indicators:

**Maternal Health:**
1. anc1 - Antenatal care 1st visit / CPN 1
2. anc1_after20 - ANC 1st visit ≥ 20wks
3. anc1_before20 - ANC 1st visit <20wks
4. anc4 - Antenatal care 4th visit / CPN 4
5. delivery - Institutional delivery / Accouchements institutionels
6. deliv_csection - Deliveries - caesarian section
7. deliv_partograph - Deliveries monitored using a partograph
8. deliv_vaginal - Deliveries - vaginal

**Postnatal Care:**
9. pnc1 - Postnatal care 1
10. pnc1_mother - Postnatal care 1 (mothers)
11. pnc1_newborn - Postnatal care 1 (newborns)

**Child Health & Immunization:**
12. bcg - BCG vaccine
13. penta1 - Penta vaccine 1
14. penta3 - Penta vaccine 3
15. measles1 - Measles vaccine 1
16. measles2 - Measles vaccine 2
17. rr1 - Measles-Rubella vaccine 1 ⭐ NEW
18. fully_immunized - Fully immunized <1 year

**Malaria:**
19. mal_diag_treat_ACT - Persons Clinically diagnosed with Malaria treated with ACT
20. mal_fever_tested - Persons presenting with fever and tested
21. mal_positive - Persons tested positive for malaria
22. mal_positive_micros - Persons tested positive for malaria by RDT
23. mal_positive_micros_ma - Persons tested positive for malaria by RDT
24. mal_treatment - Persons with Confirmed Uncomplicated Malaria treated with ACT
25. malaria_confirmed - Confirmed malaria cases ⭐ NEW
26. malaria_tested - Malaria tests performed ⭐ NEW
27. malaria_treated - Malaria cases treated ⭐ NEW

**HIV/AIDS:**
28. hiv_tested - HIV tests performed ⭐ NEW
29. hiv_treated - PLHIV on ART regularly followed ⭐ NEW

**Tuberculosis:**
30. tb_confirmed - TB cases confirmed ⭐ NEW
31. tb_treated - TB cases treated ⭐ NEW

**Nutrition:**
32. sam - Children <5 treated for SAM
33. sam_admit - Children <5 admitted for SAM treatment
34. vitaminA - Vitamin A given
35. diarrhoea - Diarrhoea cases < 5 years

**Family Planning:**
36. new_fp - New family planning acceptors
37. PW_recieved_LLIN - PW who received LLIN
38. U5_LLIN - Children <5 yrs who received LLIN

**GBV:**
39. gbv_cases - Gender based violence cases seen
40. gbv_referred - Gender based violence cases referred for treatment

**General Services:**
41. opd - Outpatient visit
42. ipd - Inpatient visit
43. gnl_attendance - General Attendance
44. sba - Deliveries by Skilled Birth Attendants

**Other Conditions:**
45. diabetes_new - Diabetes new cases
46. hypertension_new - Hypertension new cases
47. IPT3 - IPT3 (pregnant women)
48. livebirth - Live births
49. maternal_deaths - Maternal deaths
50. neonatal_deaths - Neonatal deaths
51. u5_deaths - Under 5 deaths
52. stillbirth - Still births

---

## 🔄 Backward Compatibility

✅ **All existing indicators retained** - No breaking changes
✅ **Existing data still works** - All previous indicator IDs unchanged
✅ **French translations updated** - Improved consistency across all labels

---

## 💡 Next Steps

If you need to add more indicators in the future:

1. **Edit `R/indicators.R`:**
   - Add indicator ID to the `indicator_id` vector
   - Add English label to the `indicator_name` vector
   - Maintain alphabetical/logical order

2. **Edit `R/translations.R`:**
   - Add same indicator ID to `indicator_labels_fr`
   - Add French label
   - Keep same order as English version

3. **Test:**
   - Restart app
   - Upload data with new indicator
   - Verify both EN and FR display correctly

---

## 📞 Support

If you encounter issues with indicator labels:
1. Check that your data uses the exact `indicator_id` values listed above
2. Verify case sensitivity (e.g., `IPT3` not `ipt3`)
3. Restart the app after making changes
4. Clear browser cache if labels don't update

---

**Your app now supports 52 health indicators with full bilingual labels!** 🌍✨
