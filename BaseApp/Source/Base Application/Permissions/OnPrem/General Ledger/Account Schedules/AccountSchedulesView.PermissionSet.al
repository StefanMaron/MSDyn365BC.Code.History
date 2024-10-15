permissionset 5417 "Account Schedules - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read account schedules';
    Permissions =
#if not CLEAN19
                  tabledata "Acc. Sched. Expression Buffer" = R,
                  tabledata "Acc. Schedule Extension" = R,
#endif
                  tabledata "Acc. Schedule Filter Line" = R,
                  tabledata "Acc. Schedule Line" = R,
                  tabledata "Acc. Schedule Name" = RI,
#if not CLEAN19
                  tabledata "Acc. Schedule Result Column" = R,
                  tabledata "Acc. Schedule Result Header" = R,
                  tabledata "Acc. Schedule Result History" = R,
                  tabledata "Acc. Schedule Result Line" = R,
                  tabledata "Acc. Schedule Result Value" = R,
#endif
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
#if not CLEAN20
                  tabledata "Export Acc. Schedule" = R,
#endif
                  tabledata "G/L Account" = R,
                  tabledata "G/L Budget Name" = R;
}
