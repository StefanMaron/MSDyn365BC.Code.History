codeunit 132864 "User Groups Data Setup"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerDatabase', '', false, false)]
    local procedure OnSetupDataPerDatabaseSubscriber()
    begin
        SetupUserGroupPermissionSetRecords();
    end;

    local procedure SetupUserGroupPermissionSetRecords()
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGrpPermTestLibrary: Codeunit "User Grp. Perm. Test Library";
    begin
        BindSubscription(UserGrpPermTestLibrary);
        UserGroup.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 BASIC';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 BUS FULL ACCESS';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'SECURITY';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'EMAIL SETUP';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 EXTENSION MGT';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'RETENTION POL. SETUP';
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
