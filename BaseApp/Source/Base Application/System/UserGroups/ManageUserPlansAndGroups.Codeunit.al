#if not CLEAN22
namespace System.Security.AccessControl;

codeunit 9021 "Manage User Plans And Groups"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] User groups functionality is deprecated. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    internal procedure SelectUserGroups(var UserGroupPermissionSet: Record "User Group Permission Set")
    var
        UserGroupPermissionSetInternal: Record "User Group Permission Set";
        TempPermissionSetBuffer: Record "Permission Set Buffer" temporary;
        PermissionSets: Page "Permission Sets";
    begin
        PermissionSets.LookupMode(true);
        if PermissionSets.RunModal() <> Action::LookupOK then
            exit;

        PermissionSets.GetSelectedRecords(TempPermissionSetBuffer);

        if TempPermissionSetBuffer.FindSet() then
            repeat
                if not UserGroupPermissionSetInternal.Get(UserGroupPermissionSet."User Group Code", TempPermissionSetBuffer."Role ID", TempPermissionSetBuffer.Scope, TempPermissionSetBuffer."App ID") then begin
                    UserGroupPermissionSet.Init();
                    UserGroupPermissionSet."User Group Code" := UserGroupPermissionSet."User Group Code";
                    UserGroupPermissionSet."Role ID" := TempPermissionSetBuffer."Role ID";
                    UserGroupPermissionSet.Scope := TempPermissionSetBuffer.Scope;
                    UserGroupPermissionSet."App ID" := TempPermissionSetBuffer."App ID";
                    UserGroupPermissionSet.Insert();
                end;
            until TempPermissionSetBuffer.Next() = 0;
    end;
}
#endif