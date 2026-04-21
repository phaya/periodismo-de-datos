# --------------------------------------------------------------------
# Script de preparación y filtrado de datos del
# Producto Interior Bruto (PIB)
# Maddison Project Database (Our World in Data)
# --------------------------------------------------------------------
# Este script procesa datos históricos de PIB para generar un subconjunto
# limpio, consistente y listo para análisis comparativos y visualización.
#
# FUNCIONALIDAD:
# - Lee un fichero CSV con datos históricos de PIB.
# - Filtra los datos para los países definidos en los parámetros.
# - Limita el rango temporal entre el año inicial y final especificados.
# - Exporta el resultado a un fichero Excel reutilizable.
#
# RESULTADO:
# - Tabla estructurada con datos de PIB por país y año,
#   adecuada para análisis económico, modelización y visualización.
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# FUENTE DE DATOS
# --------------------------------------------------------------------
# Producto Interior Bruto (PIB) – Datos históricos a largo plazo en dólares
# internacionales constantes – Maddison Project Database
#
# DESCRIPCIÓN:
# - Representa la producción económica total de un país o región por año.
# - Los datos están ajustados por inflación y por diferencias en el coste
#   de vida entre países (Paridad de Poder Adquisitivo, PPP).
#
# METADATOS:
# - Última actualización: 26 de abril de 2024
# - Próxima actualización prevista: abril de 2027
# - Rango temporal: año 1 – 2022
# - Unidad: dólares internacionales constantes de 2011
#
# CÓMO CITAR:
#
# Full citation:
# Bolt and van Zanden – Maddison Project Database 2023 – with major processing by Our World in Data.
# “Gross domestic product (GDP) – Maddison Project Database – Long-run data in constant international-$” [dataset].
# Bolt and van Zanden, “Maddison Project Database 2023” [original data].
#
# FUENTE ORIGINAL:
# - Maddison Project Database 2023
# - Procesado y distribuido por Our World in Data
#
# CONSIDERACIONES IMPORTANTES:
# - El Maddison Project Database se basa en contribuciones de múltiples investigadores.
# - El PIB mide el valor total de bienes y servicios producidos anualmente.
# - Permite analizar el crecimiento económico en el muy largo plazo.
# - Incluye estimaciones históricas que pueden remontarse hasta el año 1 d.C.
# - Los valores están ajustados por:
#     * Inflación
#     * Diferencias de coste de vida entre países (PPP)
# - Expresado en dólares internacionales constantes de 2011.
# - Algunas series históricas son reconstrucciones basadas en evidencia limitada.
# - Para datos más recientes (especialmente desde 1990), se recomienda contrastar
#   con fuentes como el Banco Mundial.
# --------------------------------------------------------------------

library(tidyverse)
library(writexl)
library(here)
library(glue)

# ----------------------------------------------
# Parámetros
# ----------------------------------------------
paises <- c("China", "United States")
anio_inicio <- 1949
anio_fin <- 2022

archivo_entrada <- here(
  "data/input/gdp-maddison-project-database",
  "gdp-maddison-project-database.csv"
)

nombre_paises <- paises %>%
  str_to_lower() %>%
  str_replace_all("\\s+", "-") %>%
  str_replace_all("[^a-z0-9\\-]", "") %>%
  paste(collapse = "-")

archivo_salida <- here(
  "data",
  glue("gdp-maddison-project-database-{nombre_paises}-{anio_inicio}-{anio_fin}.xlsx")
)

# ---------------------------
# 1. Leer fichero
# ---------------------------
df_raw <- read.csv(archivo_entrada)

# ---------------------------------------------
# 2. Filtrar países y años
# ---------------------------------------------
df_final <- df_raw %>%
  filter(Entity %in% paises) %>%
  filter(Year >= anio_inicio, Year <= anio_fin)

# ---------------------------------------------
# 3. Exportar resultado
# ---------------------------------------------
write_xlsx(df_final, archivo_salida)
