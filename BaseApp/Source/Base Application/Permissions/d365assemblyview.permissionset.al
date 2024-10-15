permissionset 2912 "D365 ASSEMBLY, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View assembly';
    Permissions = tabledata "Assemble-to-Order Link" = R,
                  tabledata "Assembly Header" = R,
                  tabledata "Assembly Line" = R,
                  tabledata "Assembly Setup" = R,
                  tabledata "Item Identifier" = R,
                  tabledata "Posted Assemble-to-Order Link" = R,
                  tabledata "Posted Assembly Header" = R,
                  tabledata "Posted Assembly Line" = R;
}
