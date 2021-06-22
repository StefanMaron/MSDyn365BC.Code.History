Codeunit 9021 "Manage User Plans And Groups"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Plan", 'OnCanCurrentUserManagePlansAndGroups', '', false, false)]
    local procedure OnCanCurrentUserManagePlansAndGroups(var CanManage: Boolean)
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        CanManage := PermissionManager.CanCurrentUserManagePlansAndGroups();
    end;
}