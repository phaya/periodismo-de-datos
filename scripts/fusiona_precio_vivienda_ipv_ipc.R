# ------------------------------------------------------------
# Este script calcula índices trimestrales reales de precios
# de la vivienda y de coste laboral por comunidad autónoma para
# el período 2015–2025. Ambos indicadores se deflactan mediante
# el IPC y se expresan como índices con base 2015 (2015T1 = 100),
# permitiendo analizar su evolución en términos reales.
#
# FUNCIONALIDAD
# 1. Lee el IPC mensual y lo transforma en IPC trimestral
#    (índice general), rebasándolo a base 2015.
# 2. Lee el índice de precios de la vivienda y el coste laboral
#    por trabajador.
# 3. Deflacta ambas series utilizando el IPC y las convierte
#    en índices reales con base 2015 por comunidad autónoma.
# 4. Integra los resultados en una única base de datos y los
#    guarda en un archivo Excel.
# ------------------------------------------------------------

library(tidyverse)
library(readxl)
library(lubridate)
library(writexl)
library(here)

# ----------------------------
# 1. Leer IPC mensual (base 2025)
# ----------------------------
ipc <- read_excel(
  here("data/índice_precios_consumo_2025-2015. Base 2025.xlsx")
)

# ----------------------------
# 2. IPC trimestral - índice general
# ----------------------------

ipc_trimestral <- ipc %>%
  mutate(
    anio = as.integer(str_sub(mes, 1, 4)),
    mes_num = as.integer(str_sub(mes, 6, 7)),
    trimestre = paste0(anio, "T", ceiling(mes_num / 3))
  ) %>%
  filter(índice == "Índice general") %>%
  group_by(trimestre) %>%
  summarise(
    ipc_base_2025 = mean(valor, na.rm = TRUE),
    .groups = "drop"
  )

# ----------------------------
# 3. Pasar IPC a base 2015
# ----------------------------
ipc_base_2015T1_factor <- ipc_trimestral %>%
  filter(trimestre == "2015T1") %>%
  pull(ipc_base_2025)

ipc_trimestral <- ipc_trimestral %>%
  mutate(
    ipc_base_2015T1 = ipc_base_2025 / ipc_base_2015T1_factor * 100
  ) %>%
  select(trimestre, ipc_base_2015T1)

# ----------------------------
# 4. Leer índice de precios de la vivienda (base 2015)
# ----------------------------
ipv <- read_excel(
  here("data/índice_precios_vivienda_2025-2015. Base 2015.xlsx")
)

# ----------------------------
# 5. Leer coste laboral por trabajador (base 2015)
# ----------------------------
coste_laboral <- read_excel(
  here("data/coste_laboral_por_trabajador_ccaa_2025-2015. Base 2015.xlsx")
)

# ----------------------------
# 6. Deflactar índice de precios de vivienda
# ----------------------------

ipv_real <- ipv %>%
  left_join(ipc_trimestral, by = "trimestre") %>%
  mutate(
    ipv_nominal = valor,
    ipv_real = ipv_nominal / ipc_base_2015T1 * 100
  ) %>%
  group_by(comunidad_autónoma) %>%
  mutate(
    base_2015 = ipv_real[trimestre == "2015T1"],
    ipv_real_indice_2015 = ipv_real / base_2015 * 100
  ) %>%
  ungroup() %>%
  select(
    comunidad_autónoma,
    trimestre,
    ipv_nominal,
    ipv_real_indice_2015
  )


# ----------------------------
# 7. Deflactar coste laboral y convertirlo en índice (base 2015)
# ----------------------------
coste_laboral_real <- coste_laboral %>%
  left_join(ipc_trimestral, by = "trimestre") %>%
  mutate(
    coste_laboral_nominal = valor,
    coste_laboral_real = coste_laboral_nominal / ipc_base_2015T1 * 100
  ) %>%
  group_by(comunidad_autónoma) %>%
  mutate(
    base_2015 = coste_laboral_real[trimestre == "2015T1"],
    coste_laboral_real_indice_2015 = coste_laboral_real / base_2015 * 100
  ) %>%
  ungroup() %>%
  select(
    comunidad_autónoma,
    trimestre,
    coste_laboral_nominal,
    coste_laboral_real_indice_2015
  )

# ----------------------------
# 8. Unir vivienda y coste laboral
# ----------------------------
resultado_final <- ipv_real %>%
  left_join(
    coste_laboral_real,
    by = c("comunidad_autónoma", "trimestre")
  ) %>%
  arrange(comunidad_autónoma, trimestre)

# ----------------------------
# 9. Guardar resultado final
# ----------------------------
write_xlsx(
  resultado_final,
  here("data/ipv_coste_laboral_terminos_reales_ccaa_2025-2015. Base 2015.xlsx")
)