Codeunit 9021 "Manage User Plans And Groups"
{

    internal procedure SelectUserGroups(var UserGroupPermissionSet: Record "User Group Permission Set")
    var
        TempPermissionSetBuffer: Record "Permission Set Buffer" temporary;
        PermissionSets: Page "Permission Sets";
    begin
        PermissionSets.LookupMode(true);
        if PermissionSets.RunModal() <> Action::LookupOK then
            exit;

        PermissionSets.GetSelectedRecords(TempPermissionSetBuffer);

        if TempPermissionSetBuffer.FindSet() then
            repeat
                UserGroupPermissionSet.Init();
                UserGroupPermissionSet."Role ID" := TempPermissionSetBuffer."Role ID";
                UserGroupPermissionSet.Scope := TempPermissionSetBuffer.Scope;
                UserGroupPermissionSet."App ID" := TempPermissionSetBuffer."App ID";
                UserGroupPermissionSet.Insert();
            until TempPermissionSetBuffer.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Plan", 'OnCanCurrentUserManagePlansAndGroups', '', false, false)]
    local procedure OnCanCurrentUserManagePlansAndGroups(var CanManage: Boolean)
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        CanManage := PermissionManager.CanCurrentUserManagePlansAndGroups();
    end;
}