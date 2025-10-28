# ========================================
# TRANSLATIONS - ENGLISH & FRENCH
# ========================================

# UI Translations
ui_translations <- list(
  en = list(
    app_title = "Health Service Disruption Mapping",

    # Sidebar
    menu_map = "Disruption Map",
    menu_stats = "Summary Statistics",
    menu_data = "Data Table",
    menu_about = "About",

    # Data Selection Box
    box_data_selection = "Data Selection",
    data_source = "Data Source:",
    data_source_database = "Database",
    data_source_upload = "Upload File",
    select_country = "Select Country:",
    admin_level = "Administrative Level:",
    admin_level_2 = "Level 2 (State/Province)",
    admin_level_3 = "Level 3 (District/LGA)",
    upload_csv = "Upload Disruption CSV:",
    select_year = "Select Year:",
    select_indicator = "Select Indicator:",
    color_scale = "Color Scale:",
    color_continuous = "Continuous",
    color_categorical = "Categories",
    show_labels = "Show Values on Map",

    # Map Box
    box_map = "Disruption Map",
    download_map = "Download Map as PNG",

    # Value Boxes
    total_areas = "Total Areas",
    areas_disruption = "Areas with Disruption",
    stable_areas = "Stable Areas",
    areas_surplus = "Areas with Surplus",

    # Statistics Tab
    box_category_dist = "Disruption Categories Distribution",
    box_top_disrupted = "Top 10 Most Disrupted Areas",
    box_category_summary = "Category Summary by Administrative Area",

    # Data Table
    box_data_details = "Disruption Data Details",
    col_admin2 = "Admin Level 2",
    col_admin3 = "Admin Level 3",
    col_indicator = "Indicator",
    col_period = "Period",
    col_year = "Year",
    col_actual = "Actual",
    col_expected = "Expected",
    col_pct_change = "% Change",
    col_admin_area = "Administrative Area",
    col_category = "Category",
    col_actual_count = "Actual Count",
    col_expected_count = "Expected Count",

    # Legend
    legend_pct_change = "% Change from Expected",
    legend_category = "Disruption Category",

    # Categories
    cat_disruption_high = "Disruption >10%",
    cat_disruption_med = "Disruption 5-10%",
    cat_stable = "Stable",
    cat_surplus_med = "Surplus 5-10%",
    cat_surplus_high = "Surplus >10%",
    cat_insufficient = "Insufficient data",

    # Charts
    chart_distribution = "Distribution of Areas by Disruption Category",
    chart_top10 = "Top 10 Areas with Highest Disruption",
    axis_num_areas = "Number of Areas",
    axis_pct_change = "Percent Change from Expected"
  ),

  fr = list(
    app_title = "Cartographie des Perturbations des Services de Santé",

    # Sidebar
    menu_map = "Carte des Perturbations",
    menu_stats = "Statistiques Récapitulatives",
    menu_data = "Tableau de Données",
    menu_about = "À Propos",

    # Data Selection Box
    box_data_selection = "Sélection des Données",
    data_source = "Source de Données:",
    data_source_database = "Base de Données",
    data_source_upload = "Télécharger un Fichier",
    select_country = "Sélectionner le Pays:",
    admin_level = "Niveau Administratif:",
    admin_level_2 = "Niveau 2 (État/Province)",
    admin_level_3 = "Niveau 3 (District/LGA)",
    upload_csv = "Télécharger un CSV:",
    select_year = "Sélectionner l'Année:",
    select_indicator = "Sélectionner l'Indicateur:",
    color_scale = "Échelle de Couleur:",
    color_continuous = "Continue",
    color_categorical = "Catégories",
    show_labels = "Afficher les Valeurs sur la Carte",

    # Map Box
    box_map = "Carte des Perturbations",
    download_map = "Télécharger la Carte en PNG",

    # Value Boxes
    total_areas = "Zones Totales",
    areas_disruption = "Zones avec Perturbation",
    stable_areas = "Zones Stables",
    areas_surplus = "Zones avec Surplus",

    # Statistics Tab
    box_category_dist = "Distribution des Catégories de Perturbation",
    box_top_disrupted = "Top 10 des Zones les Plus Perturbées",
    box_category_summary = "Résumé des Catégories par Zone Administrative",

    # Data Table
    box_data_details = "Détails des Données de Perturbation",
    col_admin2 = "Niveau Admin 2",
    col_admin3 = "Niveau Admin 3",
    col_indicator = "Indicateur",
    col_period = "Période",
    col_year = "Année",
    col_actual = "Réel",
    col_expected = "Attendu",
    col_pct_change = "% Changement",
    col_admin_area = "Zone Administrative",
    col_category = "Catégorie",
    col_actual_count = "Compte Réel",
    col_expected_count = "Compte Attendu",

    # Legend
    legend_pct_change = "% Changement par Rapport à l'Attendu",
    legend_category = "Catégorie de Perturbation",

    # Categories
    cat_disruption_high = "Perturbation >10%",
    cat_disruption_med = "Perturbation 5-10%",
    cat_stable = "Stable",
    cat_surplus_med = "Surplus 5-10%",
    cat_surplus_high = "Surplus >10%",
    cat_insufficient = "Données Insuffisantes",

    # Charts
    chart_distribution = "Distribution des Zones par Catégorie de Perturbation",
    chart_top10 = "Top 10 des Zones avec la Plus Forte Perturbation",
    axis_num_areas = "Nombre de Zones",
    axis_pct_change = "Pourcentage de Changement par Rapport à l'Attendu"
  )
)

# Helper function to get translation
t <- function(key, lang = "en") {
  ui_translations[[lang]][[key]] %||% key
}

# French indicator labels
indicator_labels_fr <- data.frame(
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
    "CPN 1",
    "CPN 1ère visite ≥ 20 semaines",
    "CPN 1ère visite <20 semaines",
    "CPN 4",
    "Vaccin BCG",
    "Accouchements - césarienne",
    "Accouchements surveillés par partogramme",
    "Accouchements - voie basse",
    "Accouchements institutionels",
    "Nouveaux cas de diabète",
    "Cas de diarrhée < 5 ans",
    "Entièrement vacciné <1 an",
    "Cas de violence basée sur le genre observés",
    "Cas de VBG référés pour traitement",
    "Fréquentation Générale",
    "Tests VIH réalisés",
    "PVVIH sous ARV régulièrement suivis",
    "Nouveaux cas d'hypertension",
    "Visites hospitalières",
    "TPI3 (femmes enceintes)",
    "Naissances vivantes",
    "Personnes diagnostiquées cliniquement avec paludisme traitées par ACT",
    "Personnes présentant de la fièvre testées (TDR et microscopie)",
    "Personnes testées positives pour le paludisme (TDR et microscopie)",
    "Personnes testées positives pour le paludisme par TDR",
    "Personnes testées positives pour le paludisme par TDR",
    "Personnes avec paludisme non compliqué confirmé traitées par ACT",
    "Cas de palu confirmés",
    "Cas de palu testés",
    "Cas de palu traités",
    "Décès maternels",
    "Vaccin rougeole 1",
    "Vaccin rougeole 2",
    "Décès néonatals",
    "Nouveaux accepteurs de planification familiale",
    "Visites ambulatoires",
    "Vaccin Penta 1",
    "Vaccin Penta 3",
    "Soins Postnatals 1",
    "Soins Postnatals 1- Mères",
    "Soins Postnatals 1- Nouveau-né",
    "Femmes enceintes ayant reçu MIILD",
    "Vaccin Rougeole-Rubéole 1",
    "Enfants <5 ans traités pour MAS",
    "Enfants <5 ans admis pour traitement MAS",
    "Accouchement - Personnel Qualifié",
    "Mortinaissances",
    "Cas TB déclarés",
    "Cas TB traités",
    "Décès de moins de 5 ans",
    "Enfants <5 ans ayant reçu MIILD",
    "Vitamine A administrée"
  ),
  stringsAsFactors = FALSE
)
