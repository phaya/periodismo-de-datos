# ------------------------------------------------------------------
# Script para normalizar nombre de CC. AA. segun nomeclatura del INE
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
# - Asigna una comunidad canónica mediante Distancia de Levenshtein 
#    (coincidencia más cercana)
# - Crea nuevas columnas:
#     * comunidad_autónoma_normalizada → nombre oficial INE
#     * numero_cambios → distancia respecto al valor original
#
# Notas:
# - La normalización es tolerante a errores tipográficos
# ------------------------------------------------------------------

library(readxl)
library(writexl)
library(dplyr)
library(stringr)
library(purrr)
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

# -------------------------------------------------------
# Tabla oficial de comunidades
# -------------------------------------------------------
comunidades <- c(
  "Total Nacional",
  "01 Andalucía",
  "02 Aragón",
  "03 Asturias, Principado de",
  "04 Balears, Illes",
  "05 Canarias",
  "06 Cantabria",
  "07 Castilla y León",
  "08 Castilla - La Mancha",
  "09 Cataluña",
  "10 Comunitat Valenciana",
  "11 Extremadura",
  "12 Galicia",
  "13 Madrid, Comunidad de",
  "14 Murcia, Región de",
  "15 Navarra, Comunidad Foral de",
  "16 País Vasco",
  "17 Rioja, La",
  "18 Ceuta",
  "19 Melilla"
)

# Versión limpiada para comparar
comunidades_ref <- limpiar_texto(comunidades)

# -------------------------------------------------------
# Devuelve:
#   - comunidad canónica más cercana
#   - distancia mínima (número de cambios)
# -------------------------------------------------------
normalizar_comunidad_info <- function(x, ref_original, ref_limpio) {
  if (is.na(x) || trimws(as.character(x)) == "") {
    return(list(
      comunidad = NA_character_,
      cambios = NA_integer_
    ))
  }
  
  x_limpio <- limpiar_texto(x)
  
  distancias <- sapply(ref_limpio, function(r) levenshtein(x_limpio, r))
  idx <- which.min(distancias)
  
  list(
    comunidad = ref_original[idx],
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
      info_normalizacion = map(
        .data[[col_comunidad]],
        ~ normalizar_comunidad_info(.x, comunidades_limpias, comunidades_ref)
      ),
      comunidad_autónoma_ine = map_chr(info_normalizacion, "comunidad"),
      numero_cambios = map_int(info_normalizacion, "cambios")
    ) %>%
    select(-info_normalizacion)
  
  return(df_normalizado)
}

# -------------------------------------------------------
# EJECUCIÓN
# -------------------------------------------------------
df_normalizado <- normalizar_excel(
  here("data", "viviendas_iniciadas_terminadas_españa_1991_2025.xlsx"),
  hoja = 1
)

df_normalizado %>%
  select(-numero_cambios) %>%
  write_xlsx(
    here("data", "viviendas_iniciadas_terminadas_españa_1991_2025_norm.xlsx")
  )