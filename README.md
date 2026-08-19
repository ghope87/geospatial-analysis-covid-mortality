# Geospatial Analysis of COVID-19 Mortality in England

A geospatial and statistical analysis examining variation in COVID-19 mortality across English local authorities during 2021, with a focus on vaccination uptake, deprivation and population density.

## Project Overview

This project investigates whether geographical variation in vaccination uptake, deprivation and population density can help explain differences in age-standardized COVID-19 mortality rates (ASCMR) across English local authorities.

Data from multiple public sources were prepared and combined using local authority codes. The final analytical dataset contained 287 local authorities.

## Data Sources

The analysis uses publicly available data from:

- Office for National Statistics (ONS) — COVID-19 mortality
- NHS England — COVID-19 vaccination uptake
- UK Government — Index of Multiple Deprivation (IMD) 2019
- NOMIS / ONS — population and population density

Vaccination uptake was age-standardized after aggregating population and vaccination data into broad age groups.

## Analytical Workflow

<img width="964" height="636" alt="COVID_analysis_workflow" src="https://github.com/user-attachments/assets/3c997eaf-bb89-4347-8c6c-90b73beaf049" />


## Key Findings

- Higher vaccination uptake was associated with lower 2021 COVID-19 mortality.
- Higher population density was associated with higher mortality.
- IMD score was associated with mortality in the baseline model but was no longer statistically significant after vaccination uptake was included.
- Adding vaccination uptake increased adjusted R² from approximately **0.42 to 0.47**.
- Model residuals exhibited significant spatial autocorrelation (**Moran's I = 0.470, p < 0.001**), indicating that important spatially structured factors were not fully captured by the OLS model.

The spatial dependence in model residuals means that OLS inferential statistics should be interpreted cautiously and suggests that additional socioeconomic, demographic or spatial variables could improve the model.

## Tools

- **R**
- **Quarto**
- **sf**
- **ggplot2**
- Spatial statistics
- Multiple linear regression
- Geospatial data processing and visualisation

## HTML Report

The HTML report can be found here:

[COVID19_Report.html](https://github.com/user-attachments/files/31218344/COVID19_Report.html)[COVID19_Report.html](https://github.com/user-attachments/files/31218274/COVID19_Report.html)


