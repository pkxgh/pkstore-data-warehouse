/*--
In bronze layer, we will store data as it is coming from the source system. There is no transformation involved. 
Whatever the schema is from source, just store as it is. 

There are 2 sources that we will be working with in this project - CRM & ERP.
Both of them are put under S3 bucket every day at 6am for the previous day data. 

Bucket for CRM: s3://pk-merch-raw-data/crm/
Bucket for ERP: s3://pk-merch-raw-data/erp/

For CRM, There are 3 files coming from CRM sources - CUstomer Info, Product Info, and Sales Details. 
For ERP as well, there are 3 files coming in - Customer, Location, and Product Category

First we will create tables (3x2 = 6) and then write and automate extraction of data from s3.
--*/
USE ROLE accountadmin;

USE DATABASE PK_MERCH_DW;

USE SCHEMA BRONZE;

SHOW OBJECTS;

-- Lets create table for CRM source one by one and make sure data captured is as it is, so data type is TEXT / VARCHAR 

-- Table 1: customer_info 
-- Columns: cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date

CREATE OR REPLACE TABLE BRONZE.crm_customer_info (
cst_id TEXT,
cst_key TEXT,
cst_firstname TEXT,
cst_lastname TEXT,
cst_marital_status TEXT,
cst_gndr TEXT,
cst_create_date TEXT
);

DESCRIBE TABLE bronze.crm_customer_info;

-- Table 2: product_info 
-- Columns: prd_id	prd_key	prd_nm	prd_cost	prd_line	prd_start_dt	prd_end_dt
CREATE OR REPLACE TABLE bronze.crm_product_info (
prd_id TEXT,
prd_key TEXT,
prd_nm TEXT,
prd_cost TEXT,
prd_line TEXT,
prd_start_dt TEXT,
prd_end_dt TEXT
);

SELECT * FROM bronze.crm_product_info;

-- Table 3: sales_details
-- Columns: sls_ord_num	sls_prd_key	sls_cust_id	sls_order_dt	sls_ship_dt	sls_due_dt	sls_sales	sls_quantity	sls_price

CREATE OR REPLACE TABLE bronze.crm_sales_details (
sls_ord_num TEXT,
sls_prd_key TEXT,
sls_cust_id TEXT,
sls_order_dt TEXT,
sls_ship_dt TEXT,
sls_due_dt TEXT,
sls_sales TEXT,
sls_quantity TEXT,
sls_price TEXT
);

SELECT * FROM bronze.crm_sales_details;

-- Lets create tables for ERP sources as well 
-- Table 1: CUST_AZ12
-- Columns: CID	BDATE	GEN
CREATE OR REPLACE TABLE bronze.erp_cust_az12 (
CID TEXT,
BDATE TEXT,
GEN TEXT
);

SELECT * FROM bronze.erp_cust_az12;

-- Table 2: LOC_A101
-- Columns: CID	CNTRY
CREATE OR REPLACE TABLE bronze.erp_loc_a101 (
CID TEXT,
CNTRY TEXT
);

SELECT * FROM bronze.erp_loc_a101;

-- Table 3: PX_CAT_G1V2
-- Columns: ID	CAT	SUBCAT	MAINTENANCE
CREATE OR REPLACE TABLE bronze.erp_px_cat_g1v2 (
ID TEXT,
CAT TEXT, 
SUBCAT TEXT,
MAINTENANCE TEXT
);

SELECT * FROM bronze.erp_px_cat_g1v2;

/*--
Now lets load data from S3. Steps to follows:
1. Create FILE object for CSV 
2. Create S3 integration object to store all S3 config
3. Create STAGE object to receive files  
4. Write COPY INTO script to load files
5. Schedule
--*/

-- Create a FILE object with file type = csv 
-- However, before creating this, lets create a new schema to store all our config objects which will be used across all schemas. Lets call it "MANAGE_DB"
CREATE OR REPLACE SCHEMA pk_merch_dw.manage_db;

CREATE OR REPLACE FILE FORMAT my_csv_format
TYPE = CSV
SKIP_HEADER = 1;

SHOW FILE FORMATS;

-- Step 2: Create an S3 integration object
-- Before that, make sure you have created a Bucket and IAM account to be used for this with S3FullAccess permissions given 
CREATE OR REPLACE STORAGE INTEGRATION S3_STORAGE_INT
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3 
ENABLED =TRUE 
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::087040263476:role/snowflake-access-role'
STORAGE_ALLOWED_LOCATIONS = ('s3://pk-merch-raw-data', 's3://pk-merch-raw-data/crm/', 's3://pk-merch-raw-data/erp/');

SHOW STORAGE INTEGRATIONS;

DESC STORAGE INTEGRATION S3_STORAGE_INT;

-- Create stage with earlier created storage integration object
CREATE OR REPLACE STAGE pk_merch_dw.manage_db.s3_stage
URL = 's3://pk-merch-raw-data'
STORAGE_INTEGRATION = S3_STORAGE_INT;

-- Check staged files 
DESC STAGE pk_merch_dw.manage_db.s3_stage;
LIST @pk_merch_dw.manage_db.s3_stage;

-- Load available CRM files
-- File 1: cust_info
COPY INTO pk_merch_dw.bronze.crm_customer_info
FROM @pk_merch_dw.manage_db.s3_stage/crm/
FILE_FORMAT = pk_merch_dw.manage_db.my_csv_format
FILES = ('cust_info.csv');

SELECT * FROM pk_merch_dw.bronze.crm_customer_info;

-- File 2: prd_info 
LIST @pk_merch_dw.manage_db.s3_stage;
SELECT * FROM pk_merch_dw.bronze.crm_product_info;

COPY INTO pk_merch_dw.bronze.crm_product_info
FROM @pk_merch_dw.manage_db.s3_stage
FILE_FORMAT = pk_merch_dw.manage_db.my_csv_format
FILES = ('crm/prd_info.csv');

-- FIle 3: sales_details 
SELECT * FROM pk_merch_dw.bronze.crm_sales_details;

COPY INTO pk_merch_dw.bronze.crm_sales_details
FROM @pk_merch_dw.manage_db.s3_stage 
FILE_FORMAT = pk_merch_dw.manage_db.my_csv_format
FILES = ('crm/sales_details.csv');

SELECT * FROM pk_merch_dw.bronze.crm_sales_details;

-- Load ERP files
LIST @s3_stage;

-- File 1: CUST_AZ12
COPY INTO pk_merch_dw.bronze.erp_cust_az12
FROM @pk_merch_dw.manage_db.s3_stage
FILE_FORMAT = pk_merch_dw.manage_db.my_csv_format
FILES = ('erp/CUST_AZ12.csv');

SELECT * FROM pk_merch_dw.bronze.erp_cust_az12;

-- File 2: LOC_A101
COPY INTO pk_merch_dw.bronze.erp_loc_a101
FROM @pk_merch_dw.manage_db.s3_stage
FILE_FORMAT = pk_merch_dw.manage_db.my_csv_format
FILES = ('erp/LOC_A101.csv');

SELECT * FROM pk_merch_dw.bronze.erp_loc_a101;

-- FILE 3: 
COPY INTO pk_merch_dw.bronze.erp_px_cat_g1v2
FROM @pk_merch_dw.manage_db.s3_stage
FILE_FORMAT = pk_merch_dw.manage_db.my_csv_format 
FILES = ('erp/PX_CAT_G1V2.csv');

SELECT * FROM pk_merch_dw.bronze.erp_px_cat_g1v2;