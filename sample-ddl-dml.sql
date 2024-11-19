show roles;
show grants to role useradmin;

use role useradmin;
create OR REPLACE role DB_EXECUTOR_ROLE COMMENT = 'Role for the users running DBT models';

show roles;
grant role DB_EXECUTOR_ROLE to user KIARASHZ;
show users;


USE ROLE SYSADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE DB_EXECUTOR_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE  DB_EXECUTOR_ROLE;

SHOW WAREHOUSES;

USE ROLE ACCOUNTADMIN;
SHOW WAREHOUSES;

CREATE DATABASE DATA_ENG_DBT;

ALTER WAREHOUSE "COMPUTE_WH" SET
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Default Warehouse';

use role useradmin;
create user if not exists DBT_EXECUTOR COMMENT = 'User running DBT commands'
PASSWORD = 'ki@Te3l' default_warehouse = 'COMPUTE_WAREHOUE'
DEFAULT_ROLE='DBT_EXECUTOR_ROLE';

GRANT ROLE DB_EXECUTOR_ROLE TO USER DBT_EXECUTOR;

USE ROLE DB_EXECUTOR_ROLE;

SELECT $1 as ORDER_KEY, $2 as CUST_KEY
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;

SELECT 1 + 1 as sum, current_date as today;

SELECT * FROM ( VALUES
  ('IT', 'ITA', 'Italy')
 ,('US', 'USA', 'United States of America')
 ,('SF', 'FIN', 'Finland (Suomi)')
  as inline_table (code_2, code_3, country_name)
);


SELECT count(*)
FROM "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1"."LINEITEM" as l
    ,"SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1"."ORDERS"   as o
    ,"SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1"."CUSTOMER" as c
    ,"SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1"."PART"     as p
WHERE o.O_ORDERKEY = l.L_ORDERKEY
  and c.C_CUSTKEY  = o.O_CUSTKEY
  and p.P_PARTKEY  = l.L_PARTKEY
;

WITH
monthly_totals as (
  SELECT
    YEAR(O_ORDERDATE) as year,
    MONTH(O_ORDERDATE) as month,
    sum(O_TOTALPRICE) as month_tot
  FROM "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1"."ORDERS"
  GROUP BY YEAR(O_ORDERDATE), MONTH(O_ORDERDATE)
)
SELECT year, month, month_tot
       ,avg(month_tot) over(partition by YEAR) as year_avg
FROM monthly_totals
QUALIFY month_tot > year_avg
ORDER BY YEAR, MONTH;


SELECT
  O_ORDERKEY,
  O_CUSTKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  avg(O_TOTALPRICE) over(partition by O_ORDERDATE) as daily_avg,
  sum(O_TOTALPRICE) over(partition by O_ORDERDATE) as daily_total,
  sum(O_TOTALPRICE) over(partition by
          DATE_TRUNC(MONTH, O_ORDERDATE)) as monthly_total,
  O_TOTALPRICE / daily_avg * 100 as avg_pct,
  O_TOTALPRICE / daily_total * 100 as day_pct,
  O_TOTALPRICE / monthly_total * 100 as month_pct
FROM "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1"."ORDERS"
QUALIFY row_number() over(partition by O_ORDERDATE
                          order by O_TOTALPRICE DESC) <= 5
order by O_ORDERDATE, O_TOTALPRICE desc;
