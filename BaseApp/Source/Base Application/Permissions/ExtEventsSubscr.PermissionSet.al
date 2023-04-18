permissionset 5264 "Ext. Events - Subscr"
{
    Caption = 'External Events - Subscribe';
    Access = Public;
    Assignable = true;
    IncludedPermissionSets = "Ext. Events - Objects";

    Permissions = tabledata "External Event Subscription" = RIMD,
                  tabledata "Ext. Business Event Definition" = R;
}
