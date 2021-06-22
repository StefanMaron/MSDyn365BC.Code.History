Codeunit 9020 "User Access Update"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Plan", 'OnUpdateUserAccessForSaaS', '', false, false)]
    local procedure OnUpdateUserAccessForSaaS(UserSecurityID: Guid; var UserGroupsAdded: Boolean);
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        UserGroupsAdded := PermissionManager.UpdateUserAccessForSaaS(UserSecurityID);
    end;
}