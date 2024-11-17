show roles;
show grants to role useradmin;

use role useradmin;
create OR REPLACE role DB_EXECUTOR_ROLE COMMENT = 'Role for the users running DBT models';

grant role db_executor_role to user <my-user-name>;
show users;

USE ROLE SYSADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE DB_EXECUTOR_ROLE;
