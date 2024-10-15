permissionset 9276 "VAT Report - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'VAT Reports';

    Permissions = tabledata "Fattura Document Type" = RIMD,
                  tabledata "Fattura Header" = RIMD,
                  tabledata "Fattura Line" = RIMD,
                  tabledata "Fattura Setup" = RIMD,
                  tabledata "VAT Report Archive" = Rimd,
                  tabledata "VAT Report Error Log" = RIMD,
                  tabledata "VAT Report Header" = RIMD,
                  tabledata "VAT Report Line" = RIMD,
                  tabledata "VAT Report Line Relation" = RIMD,
                  tabledata "VAT Return Period" = RIMD;
}
