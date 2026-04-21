# Gross domestic product (GDP) - Data package

This data package contains the data that powers the chart ["Gross domestic product (GDP)"](https://ourworldindata.org/grapher/gdp-maddison-project-database?v=1&csvType=full&useColumnShortNames=false) on the Our World in Data website.

## CSV Structure

The high level structure of the CSV file is that each row is an observation for an entity (usually a country or region) and a timepoint (usually a year).

The first two columns in the CSV file are "Entity" and "Code". "Entity" is the name of the entity (e.g. "United States"). "Code" is the OWID internal entity code that we use if the entity is a country or region. For most countries, this is the same as the [iso alpha-3](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) code of the entity (e.g. "USA") - for non-standard countries like historical countries these are custom codes.

The third column is either "Year" or "Day". If the data is annual, this is "Year" and contains only the year as an integer. If the column is "Day", the column contains a date string in the form "YYYY-MM-DD".

The remaining columns are the data columns, each of which is a time series. If the CSV data is downloaded using the "full data" option, then each column corresponds to one time series below. If the CSV data is downloaded using the "only selected data visible in the chart" option then the data columns are transformed depending on the chart type and thus the association with the time series might not be as straightforward.


## Metadata.json structure

The .metadata.json file contains metadata about the data package. The "charts" key contains information to recreate the chart, like the title, subtitle etc.. The "columns" key contains information about each of the columns in the csv, like the unit, timespan covered, citation for the data etc..

## About the data

Our World in Data is almost never the original producer of the data - almost all of the data we use has been compiled by others. If you want to re-use data, it is your responsibility to ensure that you adhere to the sources' license and to credit them correctly. Please note that a single time series may have more than one source - e.g. when we stich together data from different time periods by different producers or when we calculate per capita metrics using population data from a second source.

### How we process data at Our World In Data
All data and visualizations on Our World in Data rely on data sourced from one or several original data providers. Preparing this original data involves several processing steps. Depending on the data, this can include standardizing country names and world region definitions, converting units, calculating derived indicators such as per capita measures, as well as adding or adapting metadata such as the name or the description given to an indicator.
[Read about our data pipeline](https://docs.owid.io/projects/etl/)

## Detailed information about each time series


## Gross domestic product (GDP) – Long-run data in constant international-$ – Maddison Project Database
Total economic output of a country or region per year. This data is adjusted for inflation and differences in living costs between countries.
Last updated: April 26, 2024  
Next update: April 2027  
Date range: 1–2022  
Unit: international-$ in 2011 prices  


### How to cite this data

#### In-line citation
If you have limited space (e.g. in data visualizations), you can use this abbreviated in-line citation:  
Bolt and van Zanden – Maddison Project Database 2023 – with major processing by Our World in Data

#### Full citation
Bolt and van Zanden – Maddison Project Database 2023 – with major processing by Our World in Data. “Gross domestic product (GDP) – Maddison Project Database – Long-run data in constant international-$” [dataset]. Bolt and van Zanden, “Maddison Project Database 2023” [original data].
Source: Bolt and van Zanden – Maddison Project Database 2023 – with major processing by Our World In Data

### What you should know about this data
* The Maddison Project Database is based on the work of many researchers who have produced estimates of economic growth and population for individual countries. The full list of sources for this historical data is given in [the original dataset](https://dataverse.nl/api/access/datafile/421302).
* Gross domestic product (GDP) is a measure of the total value added from the production of goods and services in a country or region each year.
* This indicator provides information on economic growth and income levels in the _very long run_. Some country estimates are available as far back as 1 CE, and regional estimates as far back as 1820 CE.
* This data is adjusted for inflation and differences in living costs between countries.
* This data is expressed in [international-$](#dod:int_dollar_abbreviation) at 2011 prices, using a combination of 2011 and 1990 PPPs for historical data.
* Time series for former countries and territories are calculated forward by estimating values based on their last official borders.
* For more regularly updated estimates of GDP per capita since 1990, see the [World Bank's indicator](https://ourworldindata.org/grapher/gdp-worldbank).

### Source

#### Bolt and van Zanden – Maddison Project Database
Retrieved on: 2024-04-26  
Retrieved from: https://www.rug.nl/ggdc/historicaldevelopment/maddison/releases/maddison-project-database-2023  

#### Notes on our processing step for this indicator
Estimates of GDP are not provided directly from the source, so we obtained them by multiplying GDP per capita by population.


    