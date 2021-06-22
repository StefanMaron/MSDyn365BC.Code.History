codeunit 104030 "Upgrade Plan Permissions"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerDatabase()
    begin
        SetBackupRestorePermissions();
        SetExcelExportActionPermissions();
        RemoveExtensionManagementFromPlan();
        RemoveExtensionManagementFromUsers();
    end;

    var
        BackupRestoreTok: Label 'D365 BACKUP/RESTORE', Locked = true;
        BackupRestoreDescriptionTxt: Label 'Backup or restore database', Comment = 'Maximum length is 30';
        ExcelExportActionTok: Label 'EXCEL EXPORT ACTION', Locked = true;
        ExcelExportActionDescriptionTxt: Label 'D365 Excel Export Action', Locked = true;

    local procedure RemoveExtensionManagementFromPlan()
    var
        UserGroupPlan: Record "User Group Plan";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveExtensionManagementFromPlanUpgradeTag()) then
            exit;

        UserGroupPlan.SetRange("User Group Code", 'D365 EXTENSION MGT');
        UserGroupPlan.DeleteAll();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRemoveExtensionManagementFromPlanUpgradeTag());
    end;

    local procedure RemoveExtensionManagementFromUsers()
    var
        AccessControl: Record "Access Control";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveExtensionManagementFromUsersUpgradeTag()) then
            exit;

        AccessControl.SetRange("Role ID", 'D365 EXTENSION MGT');
        AccessControl.DeleteAll();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRemoveExtensionManagementFromUsersUpgradeTag());
    end;

    local procedure SetBackupRestorePermissions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddBackupRestorePermissionSetUpgradeTag()) then
            exit;

        AddBackupRestorePermissionSet();
        AddBackupRestoreUserGroup();
        AddBackupRestorePermissionSetToGroup();
        AddBackupRestoreUserGroupToDelegatedAdminPlan();
        AddBackupRestoreUserGroupToNavInternalAdmin();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAddBackupRestorePermissionSetUpgradeTag());
    end;

    local procedure AddBackupRestorePermissionSet();
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
    begin
        InsertPermissionSet(CopyStr(BackupRestoreTok, 1, MaxStrLen(PermissionSet."Role ID")),
            CopyStr(BackupRestoreDescriptionTxt, 1, MaxStrLen(PermissionSet.Name)));
        InsertPermission(CopyStr(BackupRestoreTok, 1, MaxStrLen(Permission."Role ID")), 10, 5410, 1, 1, 1, 1, 1);
        InsertPermission(CopyStr(BackupRestoreTok, 1, MaxStrLen(Permission."Role ID")), 10, 5420, 1, 1, 1, 1, 1);
    end;

    local procedure AddBackupRestoreUserGroup();
    var
        UserGroup: Record "User Group";
    begin
        InsertUserGroup(CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroup.Code)),
            CopyStr(BackupRestoreDescriptionTxt, 1, MaxStrLen(UserGroup.Name)), false);
    end;

    local procedure AddBackupRestorePermissionSetToGroup();
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        AddPermissionSetToUserGroup(CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroupPermissionSet."Role ID")),
            CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroupPermissionSet."User Group Code")));
    end;

    local procedure AddBackupRestoreUserGroupToDelegatedAdminPlan();
    var
        UserGroupPlan: Record "User Group Plan";
        PlanIds: Codeunit "Plan Ids";
    begin
        AddUserGroupToPlan(CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetDelegatedAdminPlanId());
    end;

    local procedure AddBackupRestoreUserGroupToNavInternalAdmin();
    var
        UserGroupPlan: Record "User Group Plan";
        PlanIds: Codeunit "Plan Ids";
    begin
        AddUserGroupToPlan(CopyStr(BackupRestoreTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetInternalAdminPlanId());
    end;

    local procedure InsertPermissionSet(PermissionSetID: Code[20]; PermissionSetName: Text[30])
    var
        PermissionSet: Record "Permission Set";
    begin
        if PermissionSet.Get(PermissionSetID) then
            exit;

        PermissionSet."Role ID" := PermissionSetID;
        PermissionSet.Name := PermissionSetName;
        PermissionSet.Insert();
    end;

    local procedure InsertPermission(PermissionSetID: Code[20]; ObjType: Option; ObjId: Integer; ReadPerm: Option; InsertPerm: Option; ModifyPerm: Option; DeletePerm: Option; ExecutePerm: Option)
    var
        Permission: Record Permission;
    begin
        if Permission.Get(PermissionSetID, ObjType, ObjId) then
            exit;

        Permission."Role ID" := PermissionSetID;
        Permission."Object Type" := ObjType;
        Permission."Object ID" := ObjId;
        Permission."Read Permission" := ReadPerm;
        Permission."Insert Permission" := InsertPerm;
        Permission."Modify Permission" := ModifyPerm;
        Permission."Delete Permission" := DeletePerm;
        Permission."Execute Permission" := ExecutePerm;
        Permission.Insert();
    end;

    local procedure InsertUserGroup(UserGroupCode: Code[20]; UserGroupName: Text[50]; AssignToAllNewUsers: Boolean)
    var
        UserGroup: Record 9000;
    begin
        if UserGroup.Get(UserGroupCode) then
            exit;

        UserGroup.Code := UserGroupCode;
        UserGroup.Name := UserGroupName;
        UserGroup."Assign to All New Users" := AssignToAllNewUsers;
        UserGroup.Insert();
    end;

    local procedure AddPermissionSetToUserGroup(PermissionSetId: Code[20]; UserGroupCode: Code[20])
    var
        UserGroupPermissionSet: record "User Group Permission Set";
    begin
        if UserGroupPermissionSet.Get(UserGroupCode, PermissionSetId) then
            exit;

        UserGroupPermissionSet."Role ID" := PermissionSetId;
        UserGroupPermissionSet."User Group Code" := UserGroupCode;
        UserGroupPermissionSet.Insert();
    end;

    local procedure AddUserGroupToPlan(UserGroupCode: Code[20]; PlanId: Guid)
    var
        UserGroupPlan: Record "User Group Plan";
    begin
        if UserGroupPlan.Get(PlanId, UserGroupCode) then
            exit;

        UserGroupPlan."Plan ID" := PlanId;
        UserGroupPlan."User Group Code" := UserGroupCode;
        UserGroupPlan.Insert();
    end;

    local procedure SetExcelExportActionPermissions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetExcelExportActionPermissionSetUpgradeTag()) then
            exit;

        AddExcelExportActionPermissionSet();
        AddExcelExportActionUserGroup();
        AddExcelExportActionPermissionSetToGroup();
        AddExcelExportActionUserGroupToExistingPlans();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetExcelExportActionPermissionSetUpgradeTag());
    end;

    local procedure AddExcelExportActionPermissionSet();
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
    begin
        InsertPermissionSet(CopyStr(ExcelExportActionTok, 1, MaxStrLen(PermissionSet."Role ID")),
            CopyStr(ExcelExportActionDescriptionTxt, 1, MaxStrLen(PermissionSet.Name)));
        InsertPermission(CopyStr(ExcelExportActionTok, 1, MaxStrLen(Permission."Role ID")), 10, 6110, 0, 0, 0, 0, 1);
    end;

    local procedure AddExcelExportActionUserGroup();
    var
        UserGroup: Record "User Group";
    begin
        InsertUserGroup(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroup.Code)),
            CopyStr(ExcelExportActionDescriptionTxt, 1, MaxStrLen(UserGroup.Name)), true);
    end;

    local procedure AddExcelExportActionPermissionSetToGroup();
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        AddPermissionSetToUserGroup(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPermissionSet."Role ID")),
            CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPermissionSet."User Group Code")));
    end;

    local procedure AddExcelExportActionUserGroupToExistingPlans();
    var
        UserGroupPlan: Record "User Group Plan";
        PlanIds: Codeunit "Plan Ids";
    begin
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetBasicPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetTeamMemberPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetEssentialPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetPremiumPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetInvoicingPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetViralSignupPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetExternalAccountantPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetDelegatedAdminPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetInternalAdminPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetTeamMemberISVPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetEssentialISVPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetPremiumISVPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetDeviceISVPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetDevicePlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetBasicFinancialsISVPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetAccountantHubPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetHelpDeskPlanId());
        AddUserGroupToPlan(CopyStr(ExcelExportActionTok, 1, MaxStrLen(UserGroupPlan."User Group Code")),
            PlanIds.GetInfrastructurePlanId());
    end;
}
