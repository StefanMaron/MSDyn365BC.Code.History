permissionset 2406 "Map - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'MapPoint Setup';

    Permissions = tabledata "Online Map Parameter Setup" = RIMD,
                  tabledata "Online Map Setup" = RIMD,
#if CLEAN18
                  tabledata "User Setup" = RIMD;
#else
                  tabledata "User Setup" = RIMD,
                  tabledata "User Setup Line" = RIMD;
#endif                  
}
