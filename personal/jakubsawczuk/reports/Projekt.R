library(tidyverse)
library(sf)
library(dplyr)
library(ggplot2)
library(raster)
library(spData)
library(spDataLarge)
library(caret)

powiaty <- st_read(dsn = 'data/Jednostki_Administracyjne/Powiaty.shp')
powiaty
powiaty$JPT_KOD_JE <- paste0(powiaty$JPT_KOD_JE, '000')

wynagrodzenia <- readxl::read_xlsx('Wynagrodzenia.xlsx', sheet = 2)
wynagrodzenia %>% mutate(wynagrodzenia_ogolem = Ogolem) -> nowewynagrodzenia
nowewynagrodzenia

malzenstwa <- readxl::read_xlsx('Malzenstwa.xlsx', sheet = 2)
malzenstwa %>% mutate(malzenstwa_ogolem = `ogółem`) -> nowemalzenstwa
nowemalzenstwa

rozwody  <- readxl::read_xlsx('Rozwody.xlsx', sheet = 2)
rozwody %>% mutate(rozwody_ogolem = `ogółem`) -> nowerozwody
nowerozwody

skolaryzacja  <- readxl::read_xlsx('Skolaryzacja.xlsx', sheet = 2)
skolaryzacja

tab1 <- powiaty %>% left_join(nowemalzenstwa,by = c('JPT_KOD_JE' = 'Kod'))
tab2 <- tab1 %>% left_join(nowerozwody,by = c('JPT_KOD_JE' = 'Kod'))
tab3 <- tab2 %>% left_join(skolaryzacja, by = c('JPT_KOD_JE' = 'Kod'))
polaczona <- tab3 %>% left_join(nowewynagrodzenia,by = c('JPT_KOD_JE' = 'Kod'))

polaczona

wykres <- ggplot(polaczona, aes(fill = polaczona$`brutto szkoły podstawowe`)) + 
  geom_sf()

######  Modelowanie:

polaczona.df <- st_set_geometry(polaczona,NULL)
summary(polaczona.df)

cvCtrl <- trainControl(method = 'repeatedcv',number = 10, repeats = 2)

## Robimy model

#zwr�� uwag� na struktur� danych polaczona.df. Jest tam pe�no zmiennych 
# tekstowych (w tym zmienna, kt�r� pr�bujesz modelowa�). Ten model nie ma sensu.
# Uporz�dkuj dane, zamie� je do postaci numerycznej i wybierz tylko te zmienne,
# kt�re mog� mie� znaczenie (np. zmienna Nazwa, albo kody s� zb�dne)
Model <- train(data = polaczona.df,
               malzenstwa_ogolem ~ .,
                     method = "glm", 
                     metric = "RMSE",
                     tuneLength = 5, trControl = cvCtrl)

summary(Model)
