/// <summary>
/// Upgrade to code to fix references of obsolete permission sets.
/// </summary>
codeunit 104042 "Upgrade Permission Sets"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        ReplaceObsoletePermissionSets();
    end;

    local procedure ReplaceObsoletePermissionSets()
    var
        ServerSettings: Codeunit "Server Setting";
    begin
        // Run the upgrade code only if the new permission system is enabled (permissions sets come from extensions) 
        if not ServerSettings.GetUsePermissionSetsFromExtensions() then
            exit;

        ReplacePermissionSet('EMAIL SETUP', 'Email - Admin');
        ReplacePermissionSet('EMAIL USAGE', 'Email - Edit');
        ReplacePermissionSet('D365 EXTENSION MGT', 'Exten. Mgt. - Admin');
        ReplacePermissionSet('RETENTION POL. SETUP', 'Retention Pol. Admin');
    end;

    local procedure ReplacePermissionSet(OldPermissionSet: Code[20]; NewPermissionSet: Code[20])
    var
        AccessControl: Record "Access Control";
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        // Change the Access Control entries that point to the old permission set to point to the new one
        AccessControl.SetRange("Role ID", OldPermissionSet);
        if AccessControl.FindSet() then
            repeat
                AccessControl.Rename(AccessControl."User Security ID", NewPermissionSet, AccessControl."Company Name", AccessControl.Scope, AccessControl."App ID");
            until AccessControl.Next() = 0;

        // Change the User Group Permission Set entries that point to the old permission set to point to the new one
        UserGroupPermissionSet.SetRange("Role ID", OldPermissionSet);
        if UserGroupPermissionSet.FindSet() then
            repeat
                UserGroupPermissionSet.Rename(UserGroupPermissionSet."User Group Code", NewPermissionSet, UserGroupPermissionSet.Scope, UserGroupPermissionSet."App ID");
            until UserGroupPermissionSet.Next() = 0;
    end;
}
