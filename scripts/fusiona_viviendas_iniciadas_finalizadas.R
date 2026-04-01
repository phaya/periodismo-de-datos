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