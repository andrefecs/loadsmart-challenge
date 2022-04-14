Welcome to my Analytics Engineer Challenge repository for the Data Enablement Team!

Follow the steps below to reproduce it on your machine:


# 1. Creating the data model on the database
### Note: if you really want to reproduce this section, please be aware you need to create a services account on Google Cloud Platform giving dbt full access to the project on Google Cloud. Also, the dashboard data connection should be changed to your Google Big Query account.
You can find more information [here](https://cloud.google.com/docs/authentication/getting-started#windows).


### Upload given data file
- Upload DataChallenge.csv into a [Google Sheets file](https://docs.google.com/spreadsheets/d/1T4nmRZIoIryG4VZLQJMML07P9W9ukJwp8Itt3_qoMYE/edit?usp=sharing). 

### Create Project on Google Cloud Platform
- On [Google Cloud Platform](https://console.cloud.google.com/?hl=pt-br), create a new project with the information below:
  - Project name: *loadsmart-challenge*
  - Project ID: *loadsmart-challenge-347019*

### Create Dataset on Google Big Query
- Once you have the project created, open BigQuery and select *Create dataset* under *actions* (three dots on *loadsmart-challenge-347019* node)
- Fill the information below and click CREATE DATASET:
  - Keep Project ID as is
  - Dataset ID: *raw_datachallenge*
  - Data location: *southamerica-east1 (São Paulo)*

### Create raw table 
- Once you have the dataset created, select *Create table* under *actions* (three dots on *raw_datachallenge* node)
- Fill the information below and click CREATE TABLE:
  - Create table from: *Google Cloud Storage*
  - Paste Google Sheets link: https://docs.google.com/spreadsheets/d/1T4nmRZIoIryG4VZLQJMML07P9W9ukJwp8Itt3_qoMYE/edit?usp=sharing
  - File format: *CSV*
  - Unselect Source Data Partitioning box
  - Keep Project as is
  - Keep Dataset as is
  - Table: main

### Create view for standardization to make it accessible through SQL
On BigQuery, select *Create dataset* under *actions* (three dots on *loadsmart-challenge-347019* node)
- Fill the information below and click CREATE DATASET:
  - Keep Project ID as is
  - Dataset ID: *reporting*
  - Data location: *southamerica-east1 (São Paulo)*
- Once you have the dataset created, select *Create table* under *actions* (three dots on *reporting* node)
- Compose the query below and save as view under *reporting* dataset:

```SQL
SELECT  *
        , substring(lane, 0 , instr(lane, ',')-1) as lane_origin_city
        , LEFT(substring(lane, instr(lane, ',')+1, instr(lane, ' ')),2) as lane_origin_state
        , substring(LTRIM(substring(lane, instr(lane, ' -> ')), ' -> '), 0 , instr(LTRIM(substring(lane, instr(lane, ' -> ')), ' -> '), ',')-1) as lane_destination_city
        , RIGHT(substring(LTRIM(substring(lane, instr(lane, ' -> ')), ' -> '), instr(LTRIM(substring(lane, instr(lane, ' -> ')), ' -> '), ',')),2) as lane_destination_state
    FROM `loadsmart-challenge-347019.raw_datachallenge.main`
```


# 2. Loading the data with dbt (data build tool)
### Python 3.9 required! Download [here](https://www.python.org/downloads/release/python-390/).


- Open Windows Powershell terminal on the repository folder
- Install dbt with bigquery package:

```
pip install \
  dbt-bigquery
```

- Run code below to check if everything's ok with dbt connection:

```
dbt debug
```

- You'll probably face an error on Connection test. This is due Google Big Query credentials. 
  - If you are reproducing the first section (Creating the data model on the database), follow the steps described [here](https://cloud.google.com/docs/authentication/getting-started#windows) and replace the json file on repository folder (loadsmart-challenge-347019-df7f1b5b5169.json) with the one you'll generate on Service Account setup in Google Cloud Platform.
  - If you skip first section (Creating the data model on the database), run code below on PowerShell terminal:

```
$env:GOOGLE_APPLICATION_CREDENTIALS="loadsmart-challenge-347019-df7f1b5b5169.json"
```

- Debug again to check if everything's ok with dbt connection:

```
dbt debug
```

You should now see the message *All checks passed*:

![image](https://user-images.githubusercontent.com/34288064/163475170-b43205e3-377c-4e83-90b6-8eacaf2b3429.png)


- Once you have all checks passed, run dbt using code below:

```
dbt run
```

- Now the data is sucessfully loaded into the analytical zone in Google Big Query.

### Note: since we're working with just one data source, we don't need to add new tables in dbt. This is why there's just one source and one view published using dbt:

*\models\staging\source.yml*
```SQL
version: 2
sources: 
  - name: stg_reporting
    schema: reporting
    tables:
      - name: main_view
```

*\models\staging\stg_datachallenge.sql*
```SQL
with source as (
    select * from {{ source('stg_reporting', 'main_view')}}
)
select * from source
```


# 3. Resulting dashboard/data set

- The resulting dashboard was built using Google Data Studio, a powefull tool that is easy to connect with Google Big Query using a simple query.
  - You can find the resulting dashboard [here](https://datastudio.google.com/reporting/07c7fd16-a75a-4b26-8c37-e8b211343e21)!
    - Anyone with the link can edit, so feel free to play with the data and check the resulting data set
    - It contains relevant information on a lane level, such as:
      - lane origin city;
      - lane origin state;
      - lane destination city;
      - lane destination state;
      - quote, book, and delivery dates;
      - mileage;
      - prices and P&L;
      - much more!

- The connection of Google Data Studio (GDS) with the resulting table loaded by dbt was made using the SQL query below on *Edit connection with data source* in GDS:

```SQL
SELECT * FROM `loadsmart-challenge-347019.dbt_loadsmart_challenge_reporting.stg_datachallenge`
```



### Resources:
- Learn more about dbt installation guidelines [here](https://docs.getdbt.com/dbt-cli/install/pip).
- Check out [how to set up a Service Account](https://cloud.google.com/docs/authentication/getting-started#windows) for Google Cloud credentials setup.
