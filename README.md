# periodismo-de-datos
Conjuntos de datos y script para realizar prácticas de periodismo de datos

## Guía de formato para los conjuntos de datos

El formato de los conjuntos de datos sigue las recomendaciones establecidas por [Tidy Data](https://www.jstatsoft.org/article/view/v059i10) (Wickham, 2014). Los conjuntos de datos se ordenan de tal manera que cada variable es una columna y cada observación (o caso) es una fila.

Los nombres de las variables siguen las reglas descritas a continuación:

* Nomenclatura _snake_case_. Los nombres se escriben en minúsculas y se separan las palabras con guiones bajos evitando el uso de caracteres especiales (ej. comunidad_autónoma).
* Uso del singular. Cada columna representa una unidad de observación (ej. comunidad_autónoma).
* Caracteres latinos. Los nombres se acentúan y se usa la `ñ` (ej. comunidad_autónoma, año).
* Se evitan abreviaturas ambiguas. Solo se usan cuando sean estándar o claramente entendibles (ej. lat, lon).
* Nombres consistentes. Se emplea `Valor` en todas las columnas donde hay datos numéricos.