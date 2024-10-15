permissionset 2073 "D365 COSTACC, EDIT"
{
    Assignable = true;
    Caption = 'Dyn. 365 Edit Cost Accounting';

    Permissions = tabledata "Cost Accounting Setup" = R,
                  tabledata "Cost Allocation Source" = RIMD,
                  tabledata "Cost Allocation Target" = RIMD,
                  tabledata "Cost Budget Buffer" = Rimd,
                  tabledata "Cost Budget Entry" = RIMD,
                  tabledata "Cost Budget Name" = RIMD,
                  tabledata "Cost Budget Register" = RIMD,
                  tabledata "Cost Center" = RIMD,
                  tabledata "Cost Entry" = RIMD,
                  tabledata "Cost Journal Batch" = RIMD,
                  tabledata "Cost Journal Line" = RIMD,
                  tabledata "Cost Journal Template" = RIMD,
                  tabledata "Cost Object" = RIMD,
                  tabledata "Cost Register" = RIMD,
                  tabledata "Cost Type" = RIMD;
}
