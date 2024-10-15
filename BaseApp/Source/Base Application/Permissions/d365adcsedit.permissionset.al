permissionset 1778 "D365 ADCS, EDIT"
{
    Assignable = true;

    Caption = 'Dynamics 365 Create ADCS';
    Permissions = tabledata "ADCS User" = RIMD,
                  tabledata "Miniform Function" = RIMD,
                  tabledata "Miniform Function Group" = RIMD,
                  tabledata "Miniform Header" = RIMD,
                  tabledata "Miniform Line" = RIMD;
}
