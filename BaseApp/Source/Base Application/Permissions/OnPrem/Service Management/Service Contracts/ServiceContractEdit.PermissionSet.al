permissionset 5768 "Service Contract - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create Service Contracts';

    Permissions = tabledata Contact = R,
                  tabledata "Contract Change Log" = RIMD,
                  tabledata "Contract Gain/Loss Entry" = RIMD,
                  tabledata "Contract Group" = RIMD,
                  tabledata "Contract/Service Discount" = RIMD,
                  tabledata Currency = R,
                  tabledata Customer = R,
                  tabledata "Filed Contract Line" = RIMD,
                  tabledata "Filed Service Contract Header" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Service Comment Line" = RIMD,
                  tabledata "Service Contract Account Group" = RIMD,
                  tabledata "Service Contract Header" = RIMD,
                  tabledata "Service Contract Line" = RIMD,
                  tabledata "Service Contract Template" = RIMD,
                  tabledata "Service Document Register" = RIMD,
                  tabledata "Service Header" = R,
                  tabledata "Service Hour" = RIMD,
                  tabledata "Service Item" = RM,
                  tabledata "Service Item Log" = RIMD,
                  tabledata "Service Ledger Entry" = RIMD,
                  tabledata "Service Mgt. Setup" = R,
                  tabledata "Service Order Type" = R,
                  tabledata "Service Register" = RIMD,
                  tabledata "Service Zone" = R,
                  tabledata "Ship-to Address" = R,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Warranty Ledger Entry" = RIMD;
}
