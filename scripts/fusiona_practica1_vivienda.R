# --------------------------------------------------------------
# Script de integración de datos del mercado de la vivienda
# España – Comunidades Autónomas (2018–2025)
# --------------------------------------------------------------
# Este script lee, limpia y combina información socioeconómica
# procedente de distintas fuentes (Idealista e INE) para analizar
# la evolución del mercado de la vivienda en España a nivel de
# comunidad autónoma entre los años 2018 y 2025.
#
# FUNCIONALIDAD:
# 1. Importa varios ficheros Excel con información por CCAA:
#      - Precios de alquiler por metro cuadrado (Idealista).
#      - Precios de compraventa de vivienda por metro cuadrado
#        (Idealista).
#      - Coste laboral por trabajador (INE), desagregado por
#        trimestres.
#      - Hogares según régimen de tenencia de la vivienda (INE).
#      - Población residente total (INE).
#
# 2. Limpia y transforma cada conjunto de datos:
#      - Normaliza el identificador territorial
#        `comunidad_autónoma_ine`.
#      - Filtra los años de interés (2018 y 2025).
#      - Calcula el salario medio anual como la media de los
#        valores trimestrales.
#      - Selecciona exclusivamente los hogares en régimen de
#        alquiler.
#
# 3. Integra todas las fuentes en una única tabla final,
#    utilizando uniones por comunidad autónoma, con las variables:
#         - Precio de vivienda (€/m²)
#         - Precio de alquiler (€/m²)
#         - Salario medio anual
#         - Porcentaje de hogares en alquiler
#         - Población total
#
# 4. Exporta el conjunto de datos final a un archivo Excel
#    listo para su análisis estadístico o visualización.
# --------------------------------------------------------------

library(tidyverse)
library(readxl)
library(here)
library(writexl)

# ---------------------------
# 1. ALQUILER IDEALISTA (€/m²)
# ---------------------------

alquiler_2018 <- read_excel(
  here("data", "2018-idealista_precio_alquiler_ccaa_norm.xlsx")
) %>%
  select(comunidad_autónoma_ine, alquiler_m2_2018 = precio_m2_2018)

alquiler_2025 <- read_excel(
  here("data", "2025-idealista_precio_alquiler_ccaa_norm.xlsx")
) %>%
  select(comunidad_autónoma_ine, alquiler_m2_2025 = precio_m2_2025)

# ---------------------------
# 2. PRECIO DE VIVIENDA IDEALISTA (€/m²)
# ---------------------------

precio_2018 <- read_excel(
  here("data", "2018-idealista_precio_vivienda_ccaa_norm.xlsx")
) %>%
  select(comunidad_autónoma_ine, precio_m2_2018 = precio_m2_2018)

precio_2025 <- read_excel(
  here("data", "2025-idealista_precio_vivienda_ccaa_norm.xlsx")
) %>%
  select(comunidad_autónoma_ine, precio_m2_2025 = precio_m2_2025)

# ---------------------------
# 3. SALARIO MEDIO ANUAL
# (media de los cuatro trimestres)
# ---------------------------

salarios <- read_excel(
  here("data", "coste_laboral_por_trabajador_ccaa_2025-2015.xlsx")
) %>%
  rename(comunidad_autónoma_ine = comunidad_autónoma) %>%
  mutate(año = as.integer(substr(trimestre, 1, 4))) %>%
  filter(año %in% c(2018, 2025)) %>%
  group_by(comunidad_autónoma_ine, año) %>%
  summarise(
    salario_medio_mensual = mean(valor, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = año,
    values_from = salario_medio_mensual,
    names_prefix = "salario_medio_mensual_"
  )

# ---------------------------
# 4. HOGARES EN ALQUILER (%)
# ---------------------------

hogares_alquiler <- read_excel(
  here("data", "hogares_por_régimen_de_tenencia_de_la_vivienda_ccaa_2025-2015.xlsx")
) %>%
  rename(comunidad_autónoma_ine = comunidad_autonoma) %>%
  filter(
    regimen == "Alquiler",
    año %in% c(2018, 2025)
  ) %>%
  select(comunidad_autónoma_ine, año, valor) %>%
  pivot_wider(
    names_from = año,
    values_from = valor,
    names_prefix = "hogares_en_alquiler_pct_"
  )

# ---------------------------
# 5. POBLACIÓN TOTAL
# ---------------------------

poblacion <- read_excel(
  here("data", "poblacion_española_2018-2026.xlsx")
) %>%
  rename(comunidad_autónoma_ine = comunidad_autónoma) %>%
  filter(
    tipo == "Total",
    año %in% c(2018, 2025)
  ) %>%
  select(comunidad_autónoma_ine, año, valor) %>%
  pivot_wider(
    names_from  = año,
    values_from = valor,
    names_prefix = "población_"
  )


# ---------------------------
# 6. TABLA FINAL
# ---------------------------

df_final <- alquiler_2018 %>%
  left_join(alquiler_2025, by = "comunidad_autónoma_ine") %>%
  left_join(precio_2018,   by = "comunidad_autónoma_ine") %>%
  left_join(precio_2025,   by = "comunidad_autónoma_ine") %>%
  left_join(salarios,      by = "comunidad_autónoma_ine") %>%
  left_join(hogares_alquiler, by = "comunidad_autónoma_ine") %>%
  left_join(poblacion,     by = "comunidad_autónoma_ine") %>%
  select(
    comunidad_autónoma_ine,
    precio_m2_2018, precio_m2_2025,
    alquiler_m2_2018, alquiler_m2_2025,
    hogares_en_alquiler_pct_2018, hogares_en_alquiler_pct_2025,
    salario_medio_mensual_2018, salario_medio_mensual_2025,
    población_2018, población_2025
  ) %>%
  arrange(comunidad_autónoma_ine) %>%
  slice(1:17)

# ---------------------------
# 7. EXPORTACIÓN
# ---------------------------

write_xlsx(df_final, here("data", "practica_vivienda_españa.xlsx"))