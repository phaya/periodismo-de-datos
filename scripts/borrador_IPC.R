# --------------------------------------------------------------------
# Script de preparación y normalización de datos del
# Índice de Precios de Consumo (IPC)
# Base 2025, por comunidades autónomas y periodos (INE, 2015–2025)
# --------------------------------------------------------------------
# Este script transforma la tabla original del INE en un formato tidy
# listo para su análisis y visualización.
#
# FUNCIONALIDAD:
# - Lee el fichero Excel original del INE con datos del IPC
#   (Base 2025) por comunidad autónoma y periodo temporal.
# - Corrige la estructura de cabeceras, utilizando la primera fila
#   útil como nombres de columnas y asignando correctamente la columna
#   de comunidad autónoma.
# - Elimina las filas de cabecera y notas que no corresponden a datos.
# - Convierte la tabla a formato largo (tidy), generando las variables:
#     comunidad_autónoma, mes, valor
# - Convierte el índice de precios a formato numérico para su análisis.
# - Excluye observaciones fuera del periodo de estudio (p. ej. 2026).
# - Exporta el resultado a un fichero XLSX final reutilizable.
#
# RESULTADO:
# - Tabla tidy con una observación por comunidad autónoma y mes,
#   adecuada para análisis temporal, comparaciones territoriales y
#   visualización.
# --------------------------------------------------------------------

library(tidyverse)
library(readxl)
library(writexl)
library(here)

# ----------------------------------------------
# Fuentes de datos originales
# ----------------------------------------------
# INE. Encuesta trimestral de coste laboral.  Resultado por Comunidades
# autónomas (desde el mes 1/2015) 
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
  here("data/input", "2015-2025-Índice de Precios de Consumo. Base 2025.xlsx"),
  col_names = FALSE,
  skip = 7
)

# ---------------------------------------------
# 2. Arreglar las cabecera
# ---------------------------------------------
nombres <- df_raw[1, ] %>%
  unlist() %>%
  as.character()

# 2. Sustituir el NA por "índice"
nombres[is.na(nombres)] <- "índice"

# 3. Asignar nombres a la tabla
names(df_raw) <- nombres

# 4. Eliminar filas de cabecera (filas 1 y 2) y a partur fila 23
df <- df_raw %>%
  slice(-(1:1)) %>%
  slice(-(14:n()))

# ---------------------------------------------------------
# 4. Pasar a formato largo (tidy)
# ---------------------------------------------------------
df_final <- df %>%
  pivot_longer(
    cols = -índice,
    names_to = "mes",
    values_to = "valor"
  ) %>%
  mutate(valor = as.integer(valor)) %>%
  # Elimina los meses de 2026
  filter(!grepl("^2026", mes))

# ----------------------------------------------
# 5. Guardar XLSX final
# ----------------------------------------------
write_xlsx(df_final,
           here("data", "índice_precios_consumo_2025-2015. Base 2025.xlsx"))
