#' Amlodipine Clinical Trial Dataset
#'
#' Data from clinical trials comparing Amlodipine to placebo.
#'
#' @format A data frame with 8 rows and 7 variables:
#' \describe{
#'   \item{study}{Study label}
#'   \item{n.amlo}{Sample size in Amlodipine group}
#'   \item{mean.amlo}{Mean change in Amlodipine group}
#'   \item{var.amlo}{Variance in Amlodipine group}
#'   \item{n.plac}{Sample size in placebo group}
#'   \item{mean.plac}{Mean change in placebo group}
#'   \item{var.plac}{Variance in placebo group}
#' }
#'
#' @usage data(amlodipine)
#' @source Normand, S.L.T. (1999). Meta-analysis of Amlodipine trials.
"amlodipine"

#' Example Dataset: dat_bcg
#'
#' This dataset contains results from clinical trials evaluating the efficacy of Bacillus Calmette-Guérin (BCG) vaccine against tuberculosis.
#'
#' @format A data frame with 13 rows and 11 variables:
#' \describe{
#'   \item{trial}{Trial ID}
#'   \item{author}{First author of the study}
#'   \item{year}{Year of publication}
#'   \item{tpos}{Number of tuberculosis cases in the treatment group (BCG vaccinated)}
#'   \item{tneg}{Number without tuberculosis in the treatment group}
#'   \item{cpos}{Number of tuberculosis cases in the control group (not vaccinated)}
#'   \item{cneg}{Number without tuberculosis in the control group}
#'   \item{ablat}{Latitude of the study location}
#'   \item{alloc}{Randomization method (e.g., random, alternate)}
#'   \item{npos}{Total sample size in the treatment group}
#'   \item{region}{Region of the study (e.g., North America, Europe)}
#' }
#'
#' @details
#' This dataset is commonly used in meta-analysis examples to explore heterogeneity of BCG vaccine efficacy across different regions.
#'
#' @usage data(dat_bcg)
#' @source Colditz et al., 1994. Meta-analysis of BCG vaccine efficacy.
"dat_bcg"


#' Fleiss1993bin: Aspirin After Myocardial Infarction Dataset (Binary Outcomes)
#'
#' This dataset contains binary outcome data from randomized controlled trials
#' investigating the effect of aspirin versus placebo on mortality after myocardial infarction.
#'
#' @format A data frame with 7 rows and 6 variables:
#' \describe{
#'   \item{study}{Study label}
#'   \item{year}{Publication year}
#'   \item{d.asp}{Number of deaths in the aspirin (treatment) group}
#'   \item{n.asp}{Number of participants in the aspirin (treatment) group}
#'   \item{d.plac}{Number of deaths in the placebo (control) group}
#'   \item{n.plac}{Number of participants in the placebo (control) group}
#' }
#'
#' @details
#' This dataset is often used in examples to illustrate meta-analysis methods for binary outcomes,
#' such as risk ratios, odds ratios, and risk differences.
#'
#' @usage data(Fleiss1993bin)
#' @source Fleiss, J.L. (1993). *The statistical basis of meta-analysis*. Statistical Methods in Medical Research.
#' Adapted for use in the `meta` package.
#' @keywords datasets
#' @examples
#' data(Fleiss1993bin)
#' head(Fleiss1993bin)
"Fleiss1993bin"


#' Example dataset: Olkin95
#'
#' This dataset contains event counts from a set of studies comparing treatment and control groups.
#'
#' @format A data frame with 70 rows and 6 variables:
#' \describe{
#'   \item{author}{Author name}
#'   \item{year}{Year of publication}
#'   \item{event.e}{Number of events in the experimental group}
#'   \item{n.e}{Total participants in the experimental group}
#'   \item{event.c}{Number of events in the control group}
#'   \item{n.c}{Total participants in the control group}
#' }
#'
#' @usage data(Olkin95)
#' @source Extracted from the `meta` package for demonstration purposes.
"Olkin95"


#' Caffeine and Endurance Performance Dataset
#'
#' This dataset contains data from randomized trials evaluating the effect of caffeine
#' ingestion on endurance performance, measured as time to exhaustion or distance covered.
#'
#' @format A data frame with 8 rows and 12 variables:
#' \describe{
#'   \item{study}{Study label}
#'   \item{year}{Year of publication}
#'   \item{h.caf}{Number of events in the caffeine group}
#'   \item{n.caf}{Sample size in the caffeine group}
#'   \item{h.decaf}{Number of events in the decaffeinated group}
#'   \item{n.decaf}{Sample size in the decaffeinated group}
#'   \item{D1}{Risk of bias domain 1 (e.g., "low", "some", "high")}
#'   \item{D2}{Risk of bias domain 2}
#'   \item{D3}{Risk of bias domain 3}
#'   \item{D4}{Risk of bias domain 4}
#'   \item{D5}{Risk of bias domain 5}
#'   \item{rob}{Overall risk of bias}
#' }
#' @details
#' This dataset is commonly used in meta-analyses of continuous outcomes to demonstrate methods for pooling mean differences
#' or standardized mean differences.
#'
#' @usage data(caffeine)
#' @source Adapted from `meta` package example datasets.
#' @keywords datasets
#' @examples
#' data(caffeine)
#' head(caffeine)
"caffeine"


#' Cisapride and Reflux Esophagitis Dataset
#'
#' This dataset provides data from randomized controlled trials evaluating the efficacy
#' of Cisapride versus placebo in healing reflux esophagitis.
#'
#' @format A data frame with 13 rows and 5 variables:
#' \describe{
#'   \item{study}{Study label}
#'   \item{event.cisa}{Number of healed patients in the cisapride group}
#'   \item{n.cisa}{Total number of patients in the cisapride group}
#'   \item{event.plac}{Number of healed patients in the placebo group}
#'   \item{n.plac}{Total number of patients in the placebo group}
#' }
#'
#' @details
#' This dataset is used to illustrate meta-analytic methods for binary outcomes like risk ratios and odds ratios.
#'
#' @usage data(cisapride)
#' @source Adapted from `meta` package example datasets.
#' @keywords datasets
#' @examples
#' data(cisapride)
#' head(cisapride)
"cisapride"


#' Lung Cancer and Smoking Cohort Study Dataset
#'
#' Data from cohort studies investigating the association between smoking and lung cancer.
#'
#' @format A data frame with 7 rows and 6 variables:
#' \describe{
#'   \item{study}{Study label}
#'   \item{participants}{Number of participants in the study}
#'   \item{d.smokers}{Number of lung cancer deaths among smokers}
#'   \item{py.smokers}{Person-years among smokers}
#'   \item{d.nonsmokers}{Number of lung cancer deaths among non-smokers}
#'   \item{py.nonsmokers}{Person-years among non-smokers}
#' }

#'
#' @details
#' This dataset is often used for meta-analysis of cohort study data to calculate relative risks (RR) for smoking.
#'
#' @usage data(lungcancer)
#' @source Adapted from `meta` package examples.
#' @keywords datasets
#' @examples
#' data(lungcancer)
#' head(lungcancer)
"lungcancer"


#' Portal Vein Thrombosis After Splenectomy Dataset
#'
#' This dataset contains data from studies evaluating the incidence of portal vein thrombosis
#' following splenectomy.
#'
#' @format A data frame with 28 rows and 8 variables:
#' \describe{
#'   \item{id}{Study identifier}
#'   \item{treat.exp}{Experimental treatment group label}
#'   \item{logOR}{Log odds ratio}
#'   \item{selogOR}{Standard error of the log odds ratio}
#'   \item{bleed.exp}{Number of bleeding events in the experimental group}
#'   \item{n.exp}{Sample size in the experimental group}
#'   \item{bleed.plac}{Number of bleeding events in the placebo/control group}
#'   \item{n.plac}{Sample size in the placebo/control group}
#' }

#'
#' @details
#' Useful for demonstrating meta-analyses involving rare event binary outcomes.
#'
#' @usage data(Pagliaro1992)
#' @source Pagliaro et al., 1992. Adapted for meta-analysis teaching purposes.
#' @keywords datasets
#' @examples
#' data(Pagliaro1992)
#' head(Pagliaro1992)
"Pagliaro1992"

#' Normand 1999 Meta-analysis Dataset (Continuous Outcomes)
#'
#' Data from a meta-analysis of continuous outcomes, including means and standard deviations
#' for treatment and control groups across different studies.
#'
#' @format A data frame with 9 rows and 8 variables:
#' \describe{
#'   \item{study}{Study ID}
#'   \item{source}{Study source or name}
#'   \item{n1i}{Sample size in treatment group}
#'   \item{m1i}{Mean in treatment group}
#'   \item{sd1i}{Standard deviation in treatment group}
#'   \item{n2i}{Sample size in control group}
#'   \item{m2i}{Mean in control group}
#'   \item{sd2i}{Standard deviation in control group}
#' }
#'
#' @details
#' This dataset is suitable for meta-analysis of mean differences between two groups (treatment vs control).
#'
#' @usage data(dat_normand1999)
#' @keywords datasets
#' @examples
#' data(dat_normand1999)
#' head(dat_normand1999)
#'
#' @docType data
#' @name dat_normand1999
NULL
