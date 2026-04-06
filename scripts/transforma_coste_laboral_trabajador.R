
# --------------------------------------------------------------
# Script de preparación y normalización de datos de coste laboral
# por trabajador y comunidades autónomas (INE, 2015–2025).
# --------------------------------------------------------------
# Este script transforma la tabla original del INE en un formato tidy
# listo para su análisis y visualización.
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
  here("data/input", "2015-2025-Coste laboral por trabajador, comunidad autónoma, sectores de actividad.xlsx"),
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

# 4. Eliminar filas de cabecera (filas 1 y 2)
df <- df_raw %>%
      slice(-(1:2))

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
           here("data", "coste_laboral_por_trabajador_ccaa_2025-2015.xlsx"))
