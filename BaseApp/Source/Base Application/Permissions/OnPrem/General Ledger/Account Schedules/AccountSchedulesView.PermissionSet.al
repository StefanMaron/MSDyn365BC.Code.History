#if not CLEAN20
permissionset 5417 "Account Schedules - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read account schedules';
    Permissions =
                  tabledata "Acc. Schedule Filter Line" = R,
                  tabledata "Acc. Schedule Line" = R,
                  tabledata "Acc. Schedule Name" = RI,
                  tabledata "Financial Report" = RI,
                  tabledata "Financial Report User Filters" = RIMD,
                  tabledata "Analysis View" = R,
                  tabledata "Analysis View Budget Entry" = R,
                  tabledata "Analysis View Entry" = R,
                  tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
                  tabledata "Column Layout" = R,
                  tabledata "Column Layout Name" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Value" = R,
                  tabledata "Export Acc. Schedule" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Budget Name" = R;
}

#endif