codeunit 132864 "User Groups Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerDatabase', '', false, false)]
    local procedure OnSetupDataPerDatabaseSubscriber()
    begin
        SetupUserGroupPermissionSetRecords();
    end;

    local procedure SetupUserGroupPermissionSetRecords()
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupPermissionSetWithoutAppId: Record "User Group Permission Set";
        NonEmptyAppID: Guid;
        EmptyAppID: Guid;
    begin
        UserGroup.Insert();

        NonEmptyAppID := '00000000-0000-0000-0000-000000000001'; // avoid the guard on inserting empty "App ID"

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 BASIC';
        UserGroupPermissionSet."App ID" := NonEmptyAppID;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 BUS FULL ACCESS';
        UserGroupPermissionSet."App ID" := NonEmptyAppID;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'SECURITY';
        UserGroupPermissionSet."App ID" := EmptyAppID;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'EMAIL SETUP';
        UserGroupPermissionSet."App ID" := NonEmptyAppID;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'EMAIL USAGE';
        UserGroupPermissionSet."App ID" := NonEmptyAppID;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 EXTENSION MGT';
        UserGroupPermissionSet."App ID" := NonEmptyAppID;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'RETENTION POL. SETUP';
        UserGroupPermissionSet."App ID" := NonEmptyAppID;
        UserGroupPermissionSet.Insert();

        if UserGroup.Get('EXCEL EXPORT ACTION') then
            UserGroup.Delete();

        UserGroupPermissionSet.SetRange("User Group Code", 'EXCEL EXPORT ACTION');
        UserGroupPermissionSet.DeleteAll();

        UserGroup.Code := 'EXCEL EXPORT ACTION';
        UserGroup.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'EXCEL EXPORT ACTION';
        UserGroupPermissionSet."App ID" := NonEmptyAppID;
        UserGroupPermissionSet.Insert();

        if UserGroup.Get('EXCEL EXPORT ACTION') then
            UserGroup.Delete();

        UserGroupPermissionSet.SetRange("User Group Code", 'EXCEL EXPORT ACTION');
        UserGroupPermissionSet.DeleteAll();

        UserGroup.Code := 'EXCEL EXPORT ACTION';
        UserGroup.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'EXCEL EXPORT ACTION';
        UserGroupPermissionSet.Insert();
    end;
}
