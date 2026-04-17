# --------------------------------------------------------------
# Script de preparación y normalización de datos de régimen de tenencia
# de la vivienda por comunidades autónomas (INE, 2015–2025).
# --------------------------------------------------------------
# Este script transforma la tabla extraída del INE en un formato tidy.
#
# FUNCIONALIDAD:
# - Lee el fichero Excel original del INE con porcentajes de hogares
#   por régimen de tenencia de la vivienda y comunidad autónoma.
# - Limpia filas de cabecera y normaliza los nombres de columnas,
#   reconstruyendo correctamente los años y regímenes.
# - Convierte la tabla a formato largo (tidy).
# - Agrupa los dos tipos de alquiler (precio de mercado e inferior)
#   en un único régimen denominado "Alquiler", sumando sus valores.
# - Genera una tabla final con las variables:
#     comunidad_autonoma, regimen, año, valor
# - Exporta el resultado a un fichero XLSX listo para análisis o visualización.
# --------------------------------------------------------------

library(tidyverse)
library(readxl)
library(writexl)
library(here)

# ----------------------------------------------
# Fuentes de datos originales
# ----------------------------------------------
# INE. Encuesta de condiciones de vivienda
# Hogares por régimen de tenencia de la vivienda y comunidades autónomas. Unidades:  % hogares	
# https://www.ine.es/up/6o6XwK03i6
# No se han incluido las viviendas en cesión

# ---------------------------
# 1. Leer ficheros desde data/input
# ---------------------------
df_raw <- read_excel(
  here("data/input", "2025-2015-Hogares por régimen de tenencia de la vivienda_ccaa.xlsx"),
  col_names = FALSE,
  skip = 6
)

# ---------------------------------------------
# 2.Eliminar filas de cabecera
# ---------------------------------------------
df <- df_raw %>%
  slice(-(1:2)) %>%               # quitar filas de títulos
  rename(comunidad_autónoma = 1) %>%
  mutate(across(-comunidad_autónoma, as.numeric))

# ---------------------------------------------------------
# 3. Reconstruir nombres de columnas
# ---------------------------------------------------------
# Vector de años (orden real del Excel)
anios <- 2025:2015

# Regímenes de tenencia (3 bloques)
regimen <- c(
  rep("Propiedad", length(anios)),
  rep("Alquiler a precio de mercado", length(anios)),
  rep("Alquiler inferior al precio de mercado", length(anios))
)

# Crear nombres correctos por posición
new_names <- c(
  "comunidad_autonoma",
  paste(regimen, rep(anios, 3), sep = "_")
)

# Asignar nombres
names(df) <- new_names

# ---------------------------------------------------------
# 4. Pasar a formato largo (tidy)
# ---------------------------------------------------------
df_long <- df %>%
  pivot_longer(
    cols = -comunidad_autonoma,
    names_to = c("regimen", "año"),
    names_sep = "_",
    values_to = "valor"
  ) %>%
  mutate(año = as.integer(año))

# ---------------------------------------------------------
# 5. Agrupar los tipos alquileres en un único regimen
# ---------------------------------------------------------
df_final <- df_long %>%
    mutate(
      regimen = if_else(
        regimen %in% c(
          "Alquiler a precio de mercado",
          "Alquiler inferior al precio de mercado"
        ),
        "Alquiler",
        regimen
      )
    ) %>%
    group_by(comunidad_autonoma, regimen, año) %>%
    summarise(
      valor = sum(valor, na.rm = TRUE),
      .groups = "drop"
    )

# ----------------------------------------------
# 6. Guardar XLSX final
# ----------------------------------------------
write_xlsx(df_final,
           here("data", "hogares_por_régimen_de_tenencia_de_la_vivienda_ccaa_2025-2015.xlsx"))
