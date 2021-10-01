permissionset 9556 "D365 INV DOC, CREATE"
{
    Assignable = true;

    Caption = 'Dyn. 365 Create inventory doc';
    Permissions = tabledata Employee = R,
                  tabledata "G/L Entry" = R,
                  tabledata "Inventory Setup" = R,
                  tabledata "No. Series" = R,
                  tabledata "Planning Assignment" = Ri,
                  tabledata "Stockkeeping Unit" = RIMD,
                  tabledata "Transfer Header" = RIMD,
                  tabledata "Transfer Line" = RIMD,
                  tabledata "Warehouse Activity Line" = R;
}
