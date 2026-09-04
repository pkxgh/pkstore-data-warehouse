/*--

In silver layer, we will be keeping same table formats and copy data, however we will clean the data thoroughly.
Things we will be checking:
1. Change data types
2. String values i.e. text cleaning (spaces, dashes etc.)
3. Missing values
4. Renaming values / Standardization
5. Filtering i.e. removing incomplete unncessary rows
6. Deriving new columns 
and so on
--*/

-- Here we will do one by one for each table / file 

-- CRM Tables
-- Table 1: crm_customer_info
SELECT  TOP 10
CAST(CST_ID AS INT) AS CST_ID,
CST_KEY,
TRIM(CST_FIRSTNAME) AS CST_FIRSTNAME,
TRIM(CST_LASTNAME) AS CST_LASTNAME,
CASE TRIM(UPPER(CST_MARITAL_STATUS))
    WHEN 'M' THEN 'Married'
    WHEN 'S' THEN 'Single'
    ELSE 'N/A'
END AS CST_MARITAL_STATUS,
CASE TRIM(UPPER(CST_GNDR))
    WHEN 'M' THEN 'Male'
    WHEN 'F' THEN 'Female'
    ELSE 'N/A'
END AS CST_GNDR,
CAST (CST_CREATE_DATE AS DATE) AS CST_CREATE_DATE
FROM    pk_merch_dw.bronze.crm_customer_info;

-- Table 2: crm_product_info
SELECT TOP 10
CAST(PRD_ID AS INT) AS PRD_ID,
--PRD_KEY,
LEFT(PRD_KEY, 5) AS PRD_CAT,
SUBSTR(PRD_KEY, 7, LEN(PRD_KEY)) AS PRD_KEY,
TRIM(PRD_NM) AS PRD_NM,
IFNULL(PRD_COST,0) AS PRD_COST,
CASE UPPER(TRIM(PRD_LINE))
    WHEN 'M' THEN 'Mountain'
    WHEN 'R' THEN 'Road'
    WHEN 'S' THEN 'Other Sales'
    WHEN 'T' THEN 'Touring'
    ELSE 'N/A'
END AS PRD_LINE,
CAST(PRD_START_DT AS DATE) AS PRD_START_DT,
CAST(PRD_END_DT AS DATE) AS PRD_END_DT,
FROM    pk_merch_dw.bronze.crm_product_info;


-- Table 3: sales_details
SELECT TOP 10 
SLS_ORD_NUM,
SLS_PRD_KEY,
CAST(SLS_CUST_ID AS INT) AS SLS_CST_ID,
CAST(CONCAT(SUBSTR(SLS_ORDER_DT,1,4),'-',SUBSTR(SLS_ORDER_DT,5,2),'-',SUBSTR(SLS_ORDER_DT,7,2)) AS DATE) AS SLS_ORDER_DT,
CAST(CONCAT(SUBSTR(SLS_SHIP_DT,1,4),'-',SUBSTR(SLS_SHIP_DT,5,2),'-',SUBSTR(SLS_SHIP_DT,7,2)) AS DATE) AS SLS_SHIP_DT,
CAST(CONCAT(SUBSTR(SLS_DUE_DT,1,4),'-',SUBSTR(SLS_DUE_DT,5,2),'-',SUBSTR(SLS_DUE_DT,7,2)) AS DATE) AS SLS_DUE_DT,
CASE WHEN CAST(IFNULL(SLS_PRICE,0) AS FLOAT) IS NULL OR CAST(IFNULL(SLS_PRICE,0) AS FLOAT) <=0 
    THEN CAST(IFNULL(SLS_SALES,0) AS FLOAT) / CAST(IFNULL(SLS_QUANTITY,0) AS INT)
    ELSE CAST(IFNULL(SLS_PRICE,0) AS FLOAT)
END AS SLS_PRICE,
CAST(IFNULL(SLS_QUANTITY,0) AS INT) AS SLS_QUANTITY,
CASE WHEN (sls_sales IS NULL) OR (CAST(IFNULL(SLS_SALES,0) AS FLOAT) <= 0) OR (CAST(IFNULL(SLS_SALES,0) AS FLOAT) != CAST(IFNULL(SLS_QUANTITY,0) AS INT) * ABS(CAST(IFNULL(SLS_PRICE,0) AS FLOAT)))
    THEN CAST(IFNULL(SLS_QUANTITY,0) AS INT) * ABS(CAST(IFNULL(SLS_PRICE,0) AS FLOAT)) 
    ELSE CAST(IFNULL(SLS_SALES,0) AS FLOAT)
END AS SLS_SALES
FROM pk_merch_dw.bronze.crm_sales_details;


-- ERP Tables 

-- Table 1: pk_merch_dw.bronze.erp_cust_az12

SELECT TOP 10
CASE WHEN CID LIKE 'NAS%'
    THEN SUBSTR(CID,4,LEN(CID)) 
    ELSE CID 
END AS CID,
CASE WHEN CAST(BDATE AS DATE) > CURRENT_DATE()
    THEN NULL 
    ELSE CAST(BDATE AS DATE) 
END AS BDATE,
CASE WHEN UPPER(TRIM(GEN)) = 'M' OR UPPER(TRIM(GEN)) = 'MALE' 
    THEN 'Male'
 WHEN UPPER(TRIM(GEN)) = 'F' OR UPPER(TRIM(GEN)) = 'FEMALE' 
    THEN 'Female'
 WHEN TRIM(GEN) = ''
    THEN NULL
ELSE 'NA'
END AS GEN
FROM    pk_merch_dw.bronze.erp_cust_az12;



-- Table 2: pk_merch_dw.bronze.erp_loc_a101
SELECT replace(CID, '-', '') AS CID,
CASE WHEN UPPER(TRIM(CNTRY)) = 'DE' THEN 'Germany'
WHEN UPPER(TRIM(CNTRY)) IN ('US', 'USA') THEN 'United States'
WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'NA'
ELSE cntry
END AS CNTRY
FROM pk_merch_dw.bronze.erp_loc_a101;

-- Table 3: pk_merch_dw.bronze.erp_px_cat_g1v2
SELECT ID, CAT, SUBCAT, MAINTENANCE
FROM pk_merch_dw.bronze.erp_px_cat_g1v2;