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
    begin
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
        UserGroupPermissionSet."Role ID" := 'EMAIL USAGE';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 EXTENSION MGT';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'RETENTION POL. SETUP';
        UserGroupPermissionSet.Insert();
    end;
}
