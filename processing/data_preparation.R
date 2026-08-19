library(tidyverse)
library(tidyr)
library(readr)
library(sf)

vax<-read.csv('data\\COVID-19-daily-announced-vaccinations-29-September-2021.csv')
death_rate2021<-read.csv('data\\covidDeathRateStd_2021.csv')
death_rate2020<-read.csv('data\\AgeStandardizedDeathRates_2020.csv')
population<- read.csv('data\\population_2021.csv')
IMD<-read.csv('data\\IMD_localAuthority.csv')
pop_density<-read.csv('data\\population-density.csv')

# standardized death rates for 2020 and 2021 from ONS 
deathRate2020<-death_rate2020|>
  select(Area.code, Area.of.usual.residence, Persons..Rate.)|>
  rename(area_code=Area.code,
         area_name=Area.of.usual.residence,
         death_rate2020=Persons..Rate.)
  
deathRate2021<-death_rate2021|>
  select(Area.code, Area.of.usual.residence, Persons..Rate.)|>
  rename(area_code=Area.code,
         area_name=Area.of.usual.residence,
         death_rate2021=Persons..Rate.)

# Countries, regions and authorities names and area codes

authorities<-death_rate2021|>
  distinct(area_code, area_name)


# Clean and prepare vaccination data

# Select age columns
age_cols<- c("Under.18", "X18.24","X25.29", "X30.34" ,"X35.39","X40.44","X45.49" , "X50.54", "X55.59","X60.64", "X65.69","X70.74", "X75.79", "X80.")

# Re-group into 18-39,40-59, 60+ age-groups and convert wide to long data
vax_long <- vax|>
  mutate(across(all_of(age_cols),
                ~ parse_number(as.character(.x))),
         age_18_39=rowSums(across(c("X18.24","X25.29", "X30.34" ,"X35.39"))),
         age_40_59=rowSums(across(c("X40.44","X45.49" , "X50.54", "X55.59"))),
         age_60Plus=rowSums(across(c("X60.64", "X65.69","X70.74", "X75.79", "X80."))))


new_age_cols<-c("Under.18", "age_18_39", "age_40_59", "age_60Plus")

# Select age groups in data set
vax_long<-vax_long|>
  select(Area_code, Area_name,Under.18, age_18_39, age_40_59, age_60Plus)|>
  pivot_longer(
    cols=all_of(new_age_cols),
    names_to = "Age_group",
    values_to = "Vaccinated"
  )

# Rename required columns
vax_long<-vax_long|>
  rename(area_code=Area_code,
         area_name=Area_name,
         age_group=Age_group,
         vaccinated=Vaccinated)


# Use age distributed population to calculate desired population per age group per local authority 

pop_age_cols<-c("Age.0...4",  "Aged.5.9",   "Aged.10.14", "Aged.15.19", "Aged.20.24", "Aged.25.29",
                "Aged.30.34", "Aged.35.39", "Aged.40.44", "Aged.45.49", "Aged.50.54", "Aged.55.59", "Aged.60.64", "Aged.65.69",
                "Aged.70.74", "Aged.75.79", "Aged.80.84", "Aged.85." )

# Sum across age groups
pop_age<-population|>
  mutate(across(all_of(pop_age_cols),
                ~ parse_number(as.character(.x))),
         Under.18=rowSums(across(c("Age.0...4","Aged.5.9","Aged.10.14", "Aged.15.19"))),
         age_18_39=rowSums(across(c("Aged.20.24", "Aged.25.29", "Aged.30.34", "Aged.35.39"))),
         age_40_59=rowSums(across(c("Aged.40.44", "Aged.45.49", "Aged.50.54", "Aged.55.59"))),
         age_60Plus=rowSums(across(c("Aged.60.64", "Aged.65.69","Aged.70.74", "Aged.75.79", "Aged.80.84", "Aged.85."))))

# Filter population per age group by local area district 
new_pop_age_cols = c("Under.18", "age_18_39", "age_40_59", "age_60Plus")

pop_age<-pop_age|>
  select(Area,Under.18, age_18_39, age_40_59, age_60Plus)|>
  filter(str_detect(Area,"^(ladu)"))|>
  pivot_longer(
    cols=all_of(new_pop_age_cols),
    names_to = "age_group",
    values_to = "population"
  )

# Reduce area entries to first 10 characters in area name and rename 
pop_age$Area<-substr(pop_age$Area,10,nchar(pop_age$Area))

pop_age<-pop_age|>
  rename(area_name=Area)

# Join population and vax data, calculate age standardized vaccination rate

# Joine vax data with population data
pop_vax<-vax_long|>
  select("area_code","area_name","age_group","vaccinated")|>
  inner_join(pop_age, by=c("area_name", "age_group"))

# Data frame containing European Standard Populations for selected age_groups
ESP<-data.frame(
  age_group=c("Under.18", "age_18_39", "age_40_59", "age_60Plus"),
  weight=c(21500, 25500, 27500, 25500)
)

# Use true population and ESP to calculate age standardized vaccination rate (ASVR)
pop_vax<-pop_vax|>
  inner_join(ESP, by="age_group")|>
  group_by(area_name, age_group)|>
  summarise(proportion=vaccinated/population,
            standard=proportion*weight)|>
  ungroup()|>
  group_by(area_name)|>
  reframe(std_vax=sum(standard)/100000)




# Population density cleaning

pop_dens<-pop_density|>
  filter(areacd %in% unique(authorities$area_code),
         period == "30/06/2021")|>
  rename(area_code=areacd,
         area_name=areanm,
         pop_dens=value)|>
  select(-area_name, -period)


# IMD cleaning

IMD_avgScore<-IMD|>
  select(Local.Authority.District.code..2019., IMD...Average.score)|>
  rename(area_code=Local.Authority.District.code..2019.,
         IMD_score=IMD...Average.score)

# Join all data frames into a single data set

all_data<-deathRate2020|>
  inner_join(pop_vax, by="area_name")|>
  inner_join(deathRate2021, by='area_code')|>
  inner_join(pop_dens, by="area_code")|>
  inner_join(IMD_avgScore, by='area_code')|>
  inner_join(authorities, by='area_code')|>
  select(area_code, area_name, death_rate2020, death_rate2021, std_vax, IMD_score, pop_dens)

# Ensure numeric data are set to numeric types
all_data<-all_data|>
  mutate(death_rate2020=as.numeric(death_rate2020),
         death_rate2021=as.numeric(death_rate2021),
         std_vax=as.numeric(std_vax))

# Write to csv
write.csv(all_data,'assignment_data.csv', row.names=FALSE)


