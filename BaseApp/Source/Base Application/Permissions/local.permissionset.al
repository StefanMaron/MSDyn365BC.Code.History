permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "IRS Groups" = RIMD,
                  tabledata "IRS Numbers" = RIMD,
                  tabledata "IRS Types" = RIMD;
}
