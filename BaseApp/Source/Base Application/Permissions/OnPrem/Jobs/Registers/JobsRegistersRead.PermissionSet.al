permissionset 3871 "Jobs Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read job registers';

    Permissions = tabledata "Job Ledger Entry" = R,
                  tabledata "Job Register" = R;
}
