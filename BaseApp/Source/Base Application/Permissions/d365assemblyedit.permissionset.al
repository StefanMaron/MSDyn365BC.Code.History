permissionset 6218 "D365 ASSEMBLY, EDIT"
{
    Assignable = true;

    Caption = 'Dynamics 365 Create assembly';
    Permissions = tabledata "Assemble-to-Order Link" = RIMD,
                  tabledata "Assembly Header" = RIMD,
                  tabledata "Assembly Line" = RIMD,
                  tabledata "Assembly Setup" = Rimd,
                  tabledata "BOM Component" = RIMD,
                  tabledata "Item Identifier" = Rimd,
                  tabledata "Posted Assemble-to-Order Link" = RIMD,
                  tabledata "Posted Assembly Header" = RIMD,
                  tabledata "Posted Assembly Line" = RIMD;
}
