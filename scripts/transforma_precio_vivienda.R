# --------------------------------------------------------------
# Script de preparación y normalización de datos de coste laboral
# por trabajador y comunidades autónomas (INE, 2015–2025).
# --------------------------------------------------------------
# Este script calcula índices trimestrales reales de precios
# de la vivienda y de coste laboral por comunidad autónoma para
# el período 2015–2025. Ambos indicadores se deflactan mediante
# el IPC y se expresan como índices con base 2015 (2015T1 = 100),
# permitiendo analizar su evolución en términos reales.
#
#
# FUNCIONALIDAD:
# - Lee el fichero Excel original del INE con datos de coste laboral
#   ordinario por trabajador, comunidad autónoma y periodo temporal.
# - Corrige la estructura de cabeceras, utilizando la primera fila
#   como nombres de columnas y asignando correctamente la columna
#   de comunidad autónoma.
# - Elimina las filas de cabecera no correspondientes a datos.
# - Convierte la tabla a formato largo (tidy), generando las variables:
#     comunidad_autónoma, trimestre, valor
# - Convierte el coste laboral a formato numérico para su análisis.
# - Exporta el resultado a un fichero XLSX final reutilizable.
# --------------------------------------------------------------

library(tidyverse)
library(readxl)
library(writexl)
library(here)

# ----------------------------------------------
# Fuentes de datos originales
# ----------------------------------------------
# INE. Encuesta trimestral de coste laboral.  Resultado por Comunidades
# autónomas (desde el trimestre 1/2008) 
# Coste laboral por trabajador, comunidad autónoma, sectores de actividad 
# https://www.ine.es/up/bpJBIvlmiG 
# Se toma `coste laboral ordinario. Es el coste medio por trabajador y mes, pero
# excluyendo los pagos extraordinarios o no habituales. Es adecuado para:
# - Comparar costes laborales entre sectores o regiones
# - Analizar la evolución “real” del coste del trabajo
# - Evitar picos artificiales por pagos extraordinarios

# ---------------------------
# 1. Leer ficheros desde data/input
# ---------------------------
df_raw <- read_excel(
  here("data/input", "2015-2025-Índice de Precios de Vivienda (IPV). Base 2015.xlsx"),
  col_names = FALSE,
  skip = 7
)

# ---------------------------------------------
# 2. Arreglar las cabecera
# ---------------------------------------------
nombres <- df_raw[1, ] %>%
  unlist() %>%
  as.character()

# 2. Sustituir el NA por "comunidad_autónoma"
nombres[is.na(nombres)] <- "comunidad_autónoma"

# 3. Asignar nombres a la tabla
names(df_raw) <- nombres

# 4. Eliminar filas de cabecera (filas 1 y 2) y a partur fila 23
df <- df_raw %>%
  slice(-(1:2)) %>%
  slice(-(21:n())) %>%
  mutate(
    comunidad_autónoma = if_else(
      comunidad_autónoma == "Nacional",
        "Total Nacional",
        comunidad_autónoma
    )
  ) %>%
  filter(
    !comunidad_autónoma %in% c("18 Ceuta", "19 Melilla")
  )


# ---------------------------------------------------------
# 4. Pasar a formato largo (tidy)
# ---------------------------------------------------------
df_final <- df %>%
  pivot_longer(
    cols = -comunidad_autónoma,
    names_to = "trimestre",
    values_to = "valor"
  ) %>%
  mutate(valor = as.integer(valor))

# ----------------------------------------------
# 5. Guardar XLSX final
# ----------------------------------------------
write_xlsx(df_final,
           here("data", "índice_precios_vivienda_2025-2015. Base 2015.xlsx"))
