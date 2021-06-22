permissionset 5656 "D365 CASH FLOW"
{
    Assignable = true;

    Caption = 'Dynamics 365 Cash Flow';
    Permissions = tabledata "Cash Flow Account" = RIMD,
                  tabledata "Cash Flow Account Comment" = RIMD,
                  tabledata "Cash Flow Chart Setup" = RIMD,
                  tabledata "Cash Flow Forecast" = RIMD,
                  tabledata "Cash Flow Forecast Entry" = RIMD,
                  tabledata "Cash Flow Manual Expense" = RIMD,
                  tabledata "Cash Flow Manual Revenue" = RIMD,
                  tabledata "Cash Flow Report Selection" = RIMD,
                  tabledata "Cash Flow Setup" = RIMD,
                  tabledata "Cash Flow Worksheet Line" = RIMD;
}
