permissionset 650 "Reten. Pol. Setup - BaseApp"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "Error Message" = IMD,
                  tabledata "Error Message Register" = IMD,
                  tabledata "Job Queue Category" = ri,
                  tabledata "Job Queue Log Entry" = IMD;
}