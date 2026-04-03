library(readxl)
library(writexl)
library(dplyr)
library(stringr)
library(purrr)
library(here)

# -------------------------------------------------------
# Algoritmo Levenshtein implementado desde cero
# -------------------------------------------------------
levenshtein <- function(a, b) {
  a_chars <- unlist(strsplit(a, ""))
  b_chars <- unlist(strsplit(b, ""))
  
  n <- length(a_chars)
  m <- length(b_chars)
  
  dist <- matrix(0, nrow = n + 1, ncol = m + 1)
  
  dist[1:(n+1), 1] <- 0:n
  dist[1, 1:(m+1)] <- 0:m
  
  for (i in 2:(n+1)) {
    for (j in 2:(m+1)) {
      costo <- ifelse(a_chars[i-1] == b_chars[j-1], 0, 1)
      dist[i, j] <- min(
        dist[i-1, j] + 1,       # eliminación
        dist[i, j-1] + 1,       # inserción
        dist[i-1, j-1] + costo  # sustitución
      )
    }
  }
  
  dist[n+1, m+1]
}

# -------------------------------------------------------
# Tabla oficial INE (conservar nombre sin código numérico)
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

comunidades_limpias <- str_replace(comunidades, "^[0-9]{2} ", "")

# -------------------------------------------------------
# Función de normalización por distancia mínima
# -------------------------------------------------------
normalizar_comunidad <- function(x, ref, umbral = 8) {
  distancias <- sapply(ref, function(r) levenshtein(x, r))
  
  idx <- which.min(distancias)
  dmin <- distancias[idx]
  mejor <- ref[idx]
  
  if (dmin > umbral) {
    warning(paste0("Advertencia: '", x, 
                   "' no se normaliza (distancia = ", dmin, ")"))
    return(x)
  }
  
  mejor
}

# -------------------------------------------------------
# PROCESO COMPLETO:
#   1. Leer Excel
#   2. Normalizar nombres
#   3. Escribir nuevo Excel
# -------------------------------------------------------
normalizar_excel <- function(input_excel,
                             hoja = 1,
                             umbral = 8) {
  
  df <- read_excel(input_excel, sheet = hoja)
  
  if (!"Comunidad" %in% names(df)) {
    stop("ERROR: el Excel debe incluir una columna llamada 'Comunidad'.")
  }
  
  df_normalizado <- df %>%
    mutate(
      Comunidad_normalizada = map_chr(
        Comunidad,
        ~ normalizar_comunidad(.x, comunidades_limpias, umbral = umbral)
      )
    )
  
  return(df_normalizado)
}

# -------------------------------------------------------
# EJEMPLO:
# resultado <- normalizar_excel("entrada.xlsx", hoja = 1, 
#                                umbral = 8)
# -------------------------------------------------------
df_normalizado <- normalizar_excel(here("data","viviendas_iniciadas_terminadas_españa_1991_2025.xlsx"))
write_xlsx(df_normalizado, 
           here("data","viviendas_iniciadas_terminadas_españa_1991_2025_norm.xlsx"))
