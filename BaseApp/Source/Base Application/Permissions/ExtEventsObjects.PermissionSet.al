permissionset 5263 "Ext. Events - Objects"
{
    Access = Public;
    Assignable = false;

    Permissions = table "External Event Subscription" = X,
                  table "External Event Log Entry" = X,
                  table "External Event Notification" = X,
                  table "Ext. Business Event Definition" = X;
}
