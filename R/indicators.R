# ========================================
# INDICATOR DEFINITIONS AND LABELS
# ========================================

# Define indicator labels
indicator_labels <- data.frame(
  indicator_id = c(
    "anc1", "anc1_after20", "anc1_before20", "anc4",
    "bcg",
    "deliv_csection", "deliv_partograph", "deliv_vaginal", "delivery",
    "diabetes_new", "diarrhoea",
    "fully_immunized",
    "gbv_cases", "gbv_referred",
    "gnl_attendance",
    "hiv_tested", "hiv_treated",
    "hypertension_new",
    "ipd", "IPT3",
    "livebirth",
    "mal_diag_treat_ACT", "mal_fever_tested", "mal_positive",
    "mal_positive_micros", "mal_positive_micros_ma", "mal_treatment",
    "malaria_confirmed", "malaria_tested", "malaria_treated",
    "maternal_deaths",
    "measles1", "measles2",
    "neonatal_deaths",
    "new_fp",
    "opd",
    "penta1", "penta3",
    "pnc1", "pnc1_mother", "pnc1_newborn",
    "PW_recieved_LLIN",
    "rr1",
    "sam", "sam_admit",
    "sba",
    "stillbirth",
    "tb_confirmed", "tb_treated",
    "u5_deaths",
    "U5_LLIN",
    "vitaminA"
  ),
  indicator_name = c(
    "Antenatal care 1st visit",
    "ANC 1st visit ≥ 20wks",
    "ANC 1st visit <20wks",
    "Antenatal care 4th visit",
    "BCG vaccine",
    "Deliveries - caesarian section",
    "Deliveries monitored using a partograph",
    "Deliveries - vaginal",
    "Institutional delivery",
    "Diabetes new cases",
    "Diarrhoea cases < 5 years",
    "Fully immunized <1 year",
    "Gender based violence cases seen",
    "Gender based violence cases referred for treatment",
    "General Attendance",
    "HIV tests performed",
    "PLHIV on ART regularly followed",
    "Hypertension new cases",
    "Inpatient visit",
    "IPT3 (pregnant women)",
    "Live births",
    "Persons Clinically diagnosed with Malaria treated with ACT",
    "Persons presenting with fever and tested (RDT and microscopy)",
    "Persons tested positive for malaria (RDT and microscopy)",
    "Persons tested positive for malaria by RDT",
    "Persons tested positive for malaria by RDT",
    "Persons with Confirmed Uncomplicated Malaria treated with ACT",
    "Confirmed malaria cases",
    "Malaria tests performed",
    "Malaria cases treated",
    "Maternal deaths",
    "Measles vaccine 1",
    "Measles vaccine 2",
    "Neonatal deaths",
    "New family planning acceptors",
    "Outpatient visit",
    "Penta vaccine 1",
    "Penta vaccine 3",
    "Postnatal care 1",
    "Postnatal care 1 (mothers)",
    "Postnatal care 1 (newborns)",
    "PW who received LLIN",
    "Measles-Rubella vaccine 1",
    "Children <5 treated for SAM",
    "Children <5 admitted for SAM treatment",
    "Deliveries by Skilled Birth Attendants (SBA)",
    "Still births",
    "TB cases confirmed",
    "TB cases treated",
    "Under 5 deaths",
    "Children <5 yrs who received LLIN",
    "Vitamin A given"
  ),
  stringsAsFactors = FALSE
)

# Define all category levels
all_categories <- c("Disruption >10%", "Disruption 5-10%", "Stable",
                    "Surplus 5-10%", "Surplus >10%", "Insufficient data")

# Define color palette for disruption categories
# RED (disruption) -> YELLOW (stable) -> GREEN (surplus)
category_colors <- c(
  "Disruption >10%" = "#b2182b",    # Dark red (severe disruption)
  "Disruption 5-10%" = "#ef8a62",   # Light red (moderate disruption)
  "Stable" = "#ffffcc",             # Light yellow (stable ±3%)
  "Surplus 5-10%" = "#a1d99b",      # Light green (moderate surplus)
  "Surplus >10%" = "#238b45",       # Dark green (strong surplus)
  "Insufficient data" = "#999999"   # Gray
)
