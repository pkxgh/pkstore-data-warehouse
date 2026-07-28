/*-- 
Create a database for PK Merchandises named "PK_MERCH_DW" using ACCOUNTADMIN role. 
Inside the PK_MERCH_DW, we will follow medallian architecture i.e. we will be creating 3 layers - Bronze, Silver, and Gold. 
--*/
USE ROLE accountadmin;

CREATE OR REPLACE DATABASE "PK_MERCH_DW";

USE PK_MERCH_DW;

CREATE OR REPLACE SCHEMA PK_MERCH_DW.bronze;

CREATE OR REPLACE SCHEMA PK_MERCH_DW.silver;

CREATE OR REPLACE SCHEMA PK_MERCH_DW.gold;

