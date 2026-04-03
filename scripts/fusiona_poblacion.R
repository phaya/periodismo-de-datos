# --------------------------------------------------------------
# Script de procesamiento de datos poblacionales (INE, 2018–2026)
# --------------------------------------------------------------
# Este script lee, limpia y combina datos de población residente 
# publicados por el INE para los años 2018 a 2026. 
# 
# FUNCIONALIDAD:
# 1. Importa dos ficheros Excel con datos poblacionales:
#      - Un archivo específico para 2026.
#      - Un archivo que contiene series para 2018–2025.
# 2. Limpia y transforma ambos conjuntos de datos para estandarizar
#    sus estructuras, corrigiendo cabeceras, generando columnas de año,
#    y pasando de formato ancho a formato largo.
# 3. Combina las series históricas y la información de 2026 en una 
#    única tabla homogénea con columnas:
#         Comunidad | Año | Tipo (Total/Española/Extranjera) | Valor
# 4. Exporta el resultado final a un archivo Excel listo para análisis
#    o visualización.

library(tidyverse)
library(readxl)
library(here)
library(writexl)

# ----------------------------------------------
# Fuentes de datos originales
# ----------------------------------------------
# INE
# Población residente por fecha, sexo, grupo de edad y nacionalidad (agrupación de países)
# Resultados Definitivos: https://www.ine.es/up/wcZCtfesiA
# Población residente por fecha, sexo, grupo de edad y nacionalidad	 (española/extranjera)
# Resultados provisionales: https://www.ine.es/up/WYXEwuL5i6

# ---------------------------
# 1. Leer ficheros desde data/input
# ---------------------------

file_2026 <- here("data", "input", "2026-Población residente por fecha, sexo, grupo de edad y nacionalidad.xlsx")
file_2018_2025 <- here("data", "input", "2025-2018-Población residente por fecha, sexo, grupo de edad y nacionalidad.xlsx")

df_2026_raw <- read_excel(file_2026, sheet = 1, skip = 7)  # Ajustado porque la estructura empieza después del encabezado
df_2018_2025_raw <- read_excel(file_2018_2025, sheet = 1, skip = 6)

# ---------------------------
# 2. Prepara la tabla de 2026
# ---------------------------

df_2026 <- df_2026_raw %>% 
  # Limpia los nombres de columnas en 2026
  rename(
    Comunidad = ...1,
    Total = Total...2,
    Española = Total...3,
    Extranjera = Total...4
  ) %>%
  mutate(Año = 2026) %>%
  # Elimina las dos primeras filas del Excel (cabeceras descriptivas)
  slice(-1, -2) %>%
  # Transforma de formato corto a largo
  pivot_longer(
    cols = c(Total, Española, Extranjera),
    names_to = "Tipo",
    values_to = "Valor"
  ) %>%
  select(Comunidad, Año, Tipo, Valor) %>%
  filter(!is.na(Valor))

# ---------------------------
# 3. Prepara la tabla de 2018-actualidad
# ---------------------------

# ----------------------------
# 3.1 Extraer cabecera con años
# ----------------------------
# La fila 2 contiene los años en columnas 2:N
years <- df_2018_2025_raw[2, -1] %>% unlist() %>% as.character()

# Quedarnos solo con el número del año
years <- str_extract(years, "\\d{4}") %>% as.numeric()

# ----------------------------
# 3.2 Filtrar filas útiles (comunidades + valores)
# ----------------------------
# Las comunidades aparecen cuando la primera columna NO es NA y no es "Total", "Española", "Extranjera"
clean <- df_2018_2025_raw %>%
  rename(Tipo = ...1) %>%
  mutate(Comunidad = case_when(
      !is.na(Tipo) & 
      !Tipo %in% c("Total", "Española", "Extranjera") ~ Tipo,
    TRUE ~ NA_character_
  )) %>%
  fill(Comunidad, .direction = "down") %>%
  # Mantener solo filas que sean Total/Española/Extranjera
  filter(Tipo %in% c("Total", "Española", "Extranjera"))

# ----------------------------
# 3.3 Pasa de columnas anchas a largas
# ----------------------------
# Columnas que contienen los valores de los años
year_cols <- setdiff(names(clean), c("Tipo", "Comunidad"))

# years debe ser: c(2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018)

df_2018_2025 <- clean %>%
  pivot_longer(
    cols = all_of(year_cols),
    names_to = "Colname",
    values_to = "Valor"
  ) %>%
  mutate(
    Año = years[ match(Colname, year_cols) ]
  ) %>%
  select(Comunidad, Año, Tipo, Valor)


# ---------------------------
# 4. Une las series presentes en ambas tablas
# ---------------------------

df_final <- bind_rows(df_2018_2025, df_2026) %>%
            mutate(Valor = as.numeric(Valor))
    
# ---------------------------
# 4. Exportar a Excel
# ---------------------------

write_xlsx(df_final, here("data", "poblacion_española_2018-2026.xlsx"))