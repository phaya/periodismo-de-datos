# ------------------------------------------------------------------
# Script para normalizar nombre de CC. AA. segun nomenclatura del INE
# ------------------------------------------------------------------
#
# Este script lee un archivo Excel que contiene una columna
# con nombres de comunidades autónomas (potencialmente con
# errores, variantes o formatos no homogéneos) y genera una
# versión normalizada utilizando los nombres oficiales del INE.
#
# FUNCIONALIDAD:
# - Detecta automáticamente la columna de comunidad autónoma
# - Limpia el texto (tildes, mayúsculas, puntuación, espacios)
# - Permite variantes por comunidad mediante una tabla:
#     * canonico
#     * variante
# - Asigna una comunidad canónica mediante Distancia de Levenshtein
#   sobre las variantes disponibles
# - Crea nuevas columnas:
#     * comunidad_autónoma_ine → nombre oficial INE
#     * numero_cambios → distancia respecto al valor original
#
# Notas:
# - La normalización es tolerante a errores tipográficos
# - Puedes añadir todas las variantes que necesites en la tabla
# ------------------------------------------------------------------

library(readxl)
library(writexl)
library(dplyr)
library(stringr)
library(purrr)
library(tibble)
library(here)

# -------------------------------------------------------
# Distancia de Levenshtein implementada desde cero
# -------------------------------------------------------
levenshtein <- function(a, b) {
  a <- as.character(a)
  b <- as.character(b)
  
  a_chars <- unlist(strsplit(a, ""))
  b_chars <- unlist(strsplit(b, ""))
  
  n <- length(a_chars)
  m <- length(b_chars)
  
  dist <- matrix(0, nrow = n + 1, ncol = m + 1)
  
  dist[, 1] <- 0:n
  dist[1, ] <- 0:m
  
  for (i in 2:(n + 1)) {
    for (j in 2:(m + 1)) {
      costo <- ifelse(a_chars[i - 1] == b_chars[j - 1], 0, 1)
      dist[i, j] <- min(
        dist[i - 1, j] + 1,        # eliminación
        dist[i, j - 1] + 1,        # inserción
        dist[i - 1, j - 1] + costo # sustitución
      )
    }
  }
  
  dist[n + 1, m + 1]
}

# -------------------------------------------------------
# Limpieza de texto para comparar mejor
# -------------------------------------------------------
limpiar_texto <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  x <- tolower(x)
  x <- gsub("[[:punct:]]", " ", x)
  x <- gsub("\\s+", " ", x)
  x <- trimws(x)
  x
}

# ------------------------------------------------------------------
# Limpieza de nombres de columnas en para adaptar formato snake_case
# ------------------------------------------------------------------
limpiar_nombres_columnas <- function(nombres) {
  nombres <- tolower(nombres)
  nombres <- gsub("[[:punct:]]", "_", nombres)
  nombres <- gsub("\\s+", "_", nombres)
  nombres <- gsub("_+", "_", nombres)
  nombres <- gsub("^_|_$", "", nombres)
  nombres
}

# -------------------------------------------------------
# Tabla oficial de comunidades + variantes
# Cada fila representa una variante posible de un nombre canónico
# -------------------------------------------------------
comunidades_tabla <- tribble(
  ~canonico,                          ~variante,
  "Total Nacional",                   "Total Nacional",
  "Total Nacional",                   "Nacional",
  "Total Nacional",                   "España",
  
  "01 Andalucía",                     "01 Andalucía",
  "01 Andalucía",                     "Andalucía",
  "01 Andalucía",                     "Andalucia",
  
  "02 Aragón",                        "02 Aragón",
  "02 Aragón",                        "Aragón",
  "02 Aragón",                        "Aragon",
  
  "03 Asturias, Principado de",       "03 Asturias, Principado de",
  "03 Asturias, Principado de",       "Asturias",
  "03 Asturias, Principado de",       "Principado de Asturias",
  
  "04 Balears, Illes",                "04 Balears, Illes",
  "04 Balears, Illes",                "Balears, Illes",
  "04 Balears, Illes",                "Illes Balears",
  "04 Balears, Illes",                "Islas Baleares",
  "04 Balears, Illes",                "Baleares",
  
  "05 Canarias",                      "05 Canarias",
  "05 Canarias",                      "Canarias",
  "05 Canarias",                      "Islas Canarias",
  
  "06 Cantabria",                     "06 Cantabria",
  "06 Cantabria",                     "Cantabria",
  
  "07 Castilla y León",               "07 Castilla y León",
  "07 Castilla y León",               "Castilla y León",
  "07 Castilla y León",               "Castilla y Leon",
  
  "08 Castilla - La Mancha",          "08 Castilla - La Mancha",
  "08 Castilla - La Mancha",          "Castilla - La Mancha",
  "08 Castilla - La Mancha",          "Castilla La Mancha",
  "08 Castilla - La Mancha",          "Castilla-La Mancha",
  
  "09 Cataluña",                      "09 Cataluña",
  "09 Cataluña",                      "Cataluña",
  "09 Cataluña",                      "Cataluna",
  "09 Cataluña",                      "Catalunya",
  
  "10 Comunitat Valenciana",          "10 Comunitat Valenciana",
  "10 Comunitat Valenciana",          "Comunitat Valenciana",
  "10 Comunitat Valenciana",          "Comunidad Valenciana",
  "10 Comunitat Valenciana",          "Valencia",
  
  "11 Extremadura",                   "11 Extremadura",
  "11 Extremadura",                   "Extremadura",
  
  "12 Galicia",                       "12 Galicia",
  "12 Galicia",                       "Galicia",
  
  "13 Madrid, Comunidad de",          "13 Madrid, Comunidad de",
  "13 Madrid, Comunidad de",          "Madrid",
  "13 Madrid, Comunidad de",          "Comunidad de Madrid",
  
  "14 Murcia, Región de",             "14 Murcia, Región de",
  "14 Murcia, Región de",             "Murcia",
  "14 Murcia, Región de",             "Región de Murcia",
  "14 Murcia, Región de",             "Region de Murcia",
  
  "15 Navarra, Comunidad Foral de",   "15 Navarra, Comunidad Foral de",
  "15 Navarra, Comunidad Foral de",   "Navarra",
  "15 Navarra, Comunidad Foral de",   "Comunidad Foral de Navarra",
  
  "16 País Vasco",                    "16 País Vasco",
  "16 País Vasco",                    "País Vasco",
  "16 País Vasco",                    "Pais Vasco",
  "16 País Vasco",                    "Euskadi",
  
  "17 Rioja, La",                     "17 Rioja, La",
  "17 Rioja, La",                     "Rioja, La",
  "17 Rioja, La",                     "La Rioja",
  
  "18 Ceuta",                         "18 Ceuta",
  "18 Ceuta",                         "Ceuta",
  
  "19 Melilla",                       "19 Melilla",
  "19 Melilla",                       "Melilla"
)

# Versión limpiada de las variantes para comparar
comunidades_tabla <- comunidades_tabla %>%
  mutate(variante_limpia = limpiar_texto(variante))

# -------------------------------------------------------
# Devuelve:
#   - comunidad canónica más cercana
#   - distancia mínima (número de cambios)
# -------------------------------------------------------
normalizar_comunidad_info <- function(x, tabla_variantes) {
  if (is.na(x) || trimws(as.character(x)) == "") {
    return(list(
      comunidad = NA_character_,
      cambios = NA_integer_
    ))
  }
  
  x_limpio <- limpiar_texto(x)
  
  distancias <- sapply(tabla_variantes$variante_limpia, function(v) {
    levenshtein(x_limpio, v)
  })
  
  idx <- which.min(distancias)
  
  list(
    comunidad = tabla_variantes$canonico[idx],
    cambios = unname(distancias[idx])
  )
}

# -------------------------------------------------------
# Lee el Excel y añade:
#   - comunidad_autónoma_ine
#   - numero_cambios
# -------------------------------------------------------
normalizar_excel <- function(input_excel, hoja = 1) {
  df <- read_excel(input_excel, sheet = hoja)
  
  print(names(df))
  
  posibles_nombres <- c(
    "comunidad_autónoma",
    "Comunidad autónoma",
    "Comunidad Autónoma",
    "Comunidad",
    "comunidad"
  )
  
  col_encontrada <- intersect(posibles_nombres, names(df))
  
  if (length(col_encontrada) == 0) {
    stop("ERROR: no encuentro la columna de comunidad autónoma.")
  }
  
  col_comunidad <- col_encontrada[1]
  
  df_normalizado <- df %>%
    mutate(
      info_normalizacion = map(.data[[col_comunidad]], ~ normalizar_comunidad_info(.x, comunidades_tabla)),
      comunidad_autónoma_ine = map_chr(info_normalizacion, "comunidad"),
      numero_cambios = map_int(info_normalizacion, "cambios")
    ) %>%
    select(-info_normalizacion)
  
  # normalizamos nombre de variable también
  names(df_normalizado)[names(df_normalizado) == col_comunidad] <- "comunidad_autónoma"
  # Limpiar TODOS los nombres de columnas (snake_case)
  names(df_normalizado) <- limpiar_nombres_columnas(names(df_normalizado))
  
  return(df_normalizado)
}

lee_normaliza_escribe <- function(input_excel, hoja = 1, output_excel) {
  df_normalizado <- normalizar_excel(
    input_excel,
    hoja
  )
  
  df_normalizado %>%
    select(-numero_cambios) %>%
    write_xlsx(output_excel)
  
  return(df_normalizado)
}
# -------------------------------------------------------
# EJECUCIÓN
# -------------------------------------------------------
lee_normaliza_escribe(
  here("data", "viviendas_iniciadas_terminadas_españa_1991_2025.xlsx"),
  hoja = 1,
  here("data", "viviendas_iniciadas_terminadas_españa_1991_2025_norm.xlsx")
)

df_normalizado <- 
  lee_normaliza_escribe(
    here("data/input", "2025-idealista_precio_vivienda_ccaa.xlsx"),
    hoja = 1,
    here("data", "2025-idealista_precio_vivienda_ccaa_norm.xlsx")
  )