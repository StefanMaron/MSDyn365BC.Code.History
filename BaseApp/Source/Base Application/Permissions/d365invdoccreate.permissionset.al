permissionset 9556 "D365 INV DOC, CREATE"
{
    Assignable = true;

    Caption = 'Dyn. 365 Create inventory doc';
    Permissions = tabledata "Planning Assignment" = Ri,
                  tabledata "Stockkeeping Unit" = RIMD,
                  tabledata "Transfer Header" = RIMD,
                  tabledata "Transfer Line" = RIMD;
}
