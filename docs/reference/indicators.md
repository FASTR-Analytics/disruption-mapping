# Indicators Reference

## Complete Indicator List

The application supports 52+ health indicators across multiple categories.

## Vaccination

| ID | English | French |
|----|---------|--------|
| `vacc_bcg` | BCG vaccine | Vaccin BCG |
| `vacc_opv0` | OPV birth dose | VPO dose naissance |
| `vacc_opv1` | OPV 1st dose | VPO 1ere dose |
| `vacc_opv2` | OPV 2nd dose | VPO 2eme dose |
| `vacc_opv3` | OPV 3rd dose | VPO 3eme dose |
| `vacc_penta1` | Pentavalent 1st dose | Pentavalent 1ere dose |
| `vacc_penta2` | Pentavalent 2nd dose | Pentavalent 2eme dose |
| `vacc_penta3` | Pentavalent 3rd dose | Pentavalent 3eme dose |
| `vacc_pcv1` | PCV 1st dose | VPC 1ere dose |
| `vacc_pcv2` | PCV 2nd dose | VPC 2eme dose |
| `vacc_pcv3` | PCV 3rd dose | VPC 3eme dose |
| `vacc_rota1` | Rotavirus 1st dose | Rotavirus 1ere dose |
| `vacc_rota2` | Rotavirus 2nd dose | Rotavirus 2eme dose |
| `vacc_measles1` | Measles 1st dose | Rougeole 1ere dose |
| `vacc_measles2` | Measles 2nd dose | Rougeole 2eme dose |
| `vacc_yellow_fever` | Yellow fever | Fievre jaune |

## Maternal Health

| ID | English | French |
|----|---------|--------|
| `anc1` | Antenatal care 1st visit | CPN 1ere visite |
| `anc4` | Antenatal care 4th visit | CPN 4eme visite |
| `delivery_facility` | Facility deliveries | Accouchements en etablissement |
| `delivery_sba` | Deliveries by SBA | Accouchements par personnel qualifie |
| `csection` | Caesarean sections | Cesariennes |
| `pnc_mother` | Postnatal care - mother | Soins postnatals - mere |
| `pnc_newborn` | Postnatal care - newborn | Soins postnatals - nouveau-ne |

## Child Health

| ID | English | French |
|----|---------|--------|
| `opd_under5` | OPD visits under 5 | Consultations externes moins de 5 ans |
| `pneumonia_under5` | Pneumonia cases under 5 | Cas de pneumonie moins de 5 ans |
| `diarrhea_under5` | Diarrhea cases under 5 | Cas de diarrhee moins de 5 ans |
| `malaria_under5` | Malaria cases under 5 | Cas de paludisme moins de 5 ans |

## Nutrition

| ID | English | French |
|----|---------|--------|
| `sam_admissions` | SAM admissions | Admissions MAS |
| `mam_admissions` | MAM admissions | Admissions MAM |
| `vitamin_a` | Vitamin A supplementation | Supplementation vitamine A |

## Family Planning

| ID | English | French |
|----|---------|--------|
| `fp_new_users` | FP new users | PF nouveaux utilisateurs |
| `fp_revisits` | FP revisits | PF revisites |

## Adding Custom Indicators

If your data contains indicators not listed here, they will display with their `indicator_common_id` as the label. To add custom labels:

1. Edit `R/indicators.R`
2. Add entries to the `indicator_labels` data frame
3. Provide both English and French translations
