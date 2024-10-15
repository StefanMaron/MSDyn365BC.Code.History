codeunit 104060 "Upgrade App ID Permissions"
{
    Subtype = Upgrade;
    
    trigger OnUpgradePerDatabase()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ServerSettings: Codeunit "Server Setting";
    begin
        if not ServerSettings.GetUsePermissionSetsFromExtensions() then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetUserGroupsSetAppIdUpgradeTag()) then
            exit;

        SetAppIdOnAccessControl();
        SetAppIdOnUserGroupPermissionSet();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetUserGroupsSetAppIdUpgradeTag());
    end;

    local procedure SetAppIdOnAccessControl()
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetFilter("Role ID", '<>%1&<>%2', 'SECURITY', 'SUPER');
        if AccessControl.FindSet() then
            repeat
                AggregatePermissionSet.SetRange("Role Id", AccessControl."Role ID");
                if AggregatePermissionSet.FindFirst() then
                    AccessControl.Rename(AccessControl."User Security ID", AccessControl."Role ID", AccessControl."Company Name", AccessControl.Scope, AggregatePermissionSet."App ID")
            until AccessControl.Next() = 0;
        
    end;

    local procedure SetAppIdOnUserGroupPermissionSet()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        UserGroupPermissionSet.SetRange(Scope, UserGroupPermissionSet.Scope::System);
        UserGroupPermissionSet.SetFilter("Role ID", '<>%1', 'SECURITY');
        if UserGroupPermissionSet.FindSet() then
             repeat
                AggregatePermissionSet.SetRange("Role Id", UserGroupPermissionSet."Role ID");
                if AggregatePermissionSet.FindFirst() then
                    UserGroupPermissionSet.Rename(
                        UserGroupPermissionSet."User Group Code",
                        UserGroupPermissionSet."Role ID", 
                        UserGroupPermissionSet.Scope,
                        AggregatePermissionSet."App ID");
            until UserGroupPermissionSet.Next() = 0;
    end;

}