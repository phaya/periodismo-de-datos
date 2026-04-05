# --------------------------------------------------------------
# Script de procesamiento de viviendas (Fomento, 2018–2026)
# --------------------------------------------------------------
# Este script procesa los datos del antiguo Ministerio de Fomento sobre el
# número de viviendas libres iniciadas y terminadas en España.
#
# FUNCIONALIDAD:
#  1. Toma como entrada dos ficheros Excel con datos de 1991–2025.
#      - Un archivo con la serie anual de viviendas iniciadas.
#      - Un archivo con la serie anual de viviendas terminadas
#  2. Extrae los nombres de columna desde una fila interna de cada fichero.
#  3. Limpia los datos conservando únicamente las comunidades autónomas válidas.
#  4. Transforma los datasets al formato largo (long format).
#  5. Fusiona ambas series por región y año.
#  6. Exporta un fichero XLSX final preparado para análisis posteriores.
# --------------------------------------------------------------

library(tidyverse)
library(readxl)
library(writexl)
library(here)

# ----------------------------------------------
# Fuentes de datos originales
# ----------------------------------------------
# Ministerio de Fomento
# Número de viviendas libres iniciadas y terminadas. Series anuales
# https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=32000000

# ----------------------------------------------
# 0. Definir comunidades autónomas válidas
# ----------------------------------------------
comunidades <- c(
  "Andalucía", "Aragón", "Asturias (Principado de )", "Balears (Illes)",
  "Canarias", "Cantabria", "Castilla y León", "Castilla-La Mancha",
  "Cataluña", "Comunidad Valenciana", "Extremadura", "Galicia",
  "Madrid (Comunidad de)", "Murcia (Región de)",
  "Navarra (Comunidad Foral de)", "País Vasco", "Rioja (La)", 
  "Ceuta", "Melilla"
)

# ----------------------------------------------
# 1. Leer ficheros sin nombres
# ----------------------------------------------
iniciadas_raw <- read_excel(
  here("data/input", "1991-2025-Número de viviendas libres iniciadas.xls"),
  col_names = FALSE
)

terminadas_raw <- read_excel(
  here("data/input", "1991-2025-Número de viviendas libres terminadas.xls"),
  col_names = FALSE
)

# ----------------------------------------------
# 2. Extraer fila 11 como nombres de columna
#    La primera columna es el nombre de la región
# ----------------------------------------------
nombres_iniciadas  <- c("region", as.character(iniciadas_raw[6, -1]))
nombres_terminadas <- c("region", as.character(terminadas_raw[6, -1]))

# Asignar nombres
colnames(iniciadas_raw)  <- nombres_iniciadas
colnames(terminadas_raw) <- nombres_terminadas

# ----------------------------------------------
# 3. Mantener solo las comunidades autónomas
# ----------------------------------------------
iniciadas <- iniciadas_raw %>%
  filter(region %in% comunidades)

terminadas <- terminadas_raw %>%
  filter(region %in% comunidades)

# ----------------------------------------------
# 5. Pivotear a formato largo
# ----------------------------------------------
iniciadas_long <- iniciadas %>%
  pivot_longer(
    cols = -region,
    names_to = "año",
    values_to = "viviendas_iniciadas"
  )

terminadas_long <- terminadas %>%
  pivot_longer(
    cols = -region,
    names_to = "año",
    values_to = "viviendas_terminadas"
  )

# ----------------------------------------------
# 7. Fusionar por región + año
# ----------------------------------------------
datos_final <- iniciadas_long %>%
  inner_join(terminadas_long, by = c("region", "año")) %>%
  rename(comunidad_autónoma = region)

# ----------------------------------------------
# 8. Guardar XLSX final
# ----------------------------------------------
write_xlsx(datos_final,
          here("data", "viviendas_iniciadas_terminadas_españa_1991_2025.xlsx"))