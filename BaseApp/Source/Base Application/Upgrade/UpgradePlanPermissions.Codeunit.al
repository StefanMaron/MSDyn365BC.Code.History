codeunit 104030 "Upgrade Plan Permissions"
{
    Subtype = Upgrade;
    Permissions = TableData "User Group Plan" = rimd;

    trigger OnUpgradePerDatabase()
    begin
        SetBackupRestorePermissions();
        SetExcelExportActionPermissions();
        RemoveExtensionManagementFromPlan();
        RemoveExtensionManagementFromUsers();
        SetSmartListDesignerPermissions();
        SetMonitorSensitiveFieldPermisions();
        AddFeatureDataUpdatePernissions();
    end;

    var
        AutomationTok: Label 'D365 AUTOMATION', MaxLength = 20, Locked = true;
        BackupRestoreTok: Label 'D365 BACKUP/RESTORE', Locked = true;
        BackupRestoreDescriptionTxt: Label 'Backup or restore database', Comment = 'Maximum length is 30';
        BasicTok: Label 'D365 BASIC', Locked = true;
        BasicISVTok: Label 'D365 BASIC ISV', Locked = true;
        BusFullTok: Label 'D365 BUS FULL ACCESS', Locked = true;
        PremiumBusFullTok: Label 'D365 BUS PREMIUM', Locked = true;
        FullTok: Label 'D365 FULL ACCESS', Locked = true;
        OnPremBasicTok: Label 'BASIC', Locked = true;
        ReadTok: Label 'D365 READ', Locked = true;
        SecurityTok: Label 'SECURITY', Locked = true;
        TeamMemberTok: Label 'D365 TEAM MEMBER', Locked = true;
        EditInExcelTok: Label 'Edit in Excel - View', Locked = true, MaxLength = 20;
        ExcelExportActionTok: Label 'EXCEL EXPORT ACTION', Locked = true, MaxLength = 20;
        ExcelExportActionDescriptionTxt: Label 'D365 Excel Export Action', Locked = true, MaxLength = 30;
        SmartListDesignerTok: Label 'SMARTLIST DESIGNER', Locked = true;
        SmartListDesignerDescriptionTxt: Label 'SmartList Designer';
        D365MonitorFieldsTxt: Label 'D365 Monitor Fields', Locked = true;
        SecurityUserGroupTok: Label 'D365 SECURITY', Locked = true;
        CannotCreatePermissionSetLbl: Label 'Permission Set %1 is missing from this environment and cannot be created.', Locked = true;

    local procedure AddFeatureDataUpdatePernissions()
    var
        Permission: Record Permission;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAddFeatureDataUpdatePernissionsUpgradeTag()) then
            exit;

        InsertPermission(AutomationTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(BasicTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(BasicISVTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(BusFullTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(PremiumBusFullTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(FullTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(ReadTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 0, 0, 0, 0);
        InsertPermission(TeamMemberTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 0, 1, 0, 0);
        InsertPermission(OnPremBasicTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);
        InsertPermission(SecurityTok, Permission."Object Type"::"Table Data", DATABASE::"Feature Data Update Status", 1, 1, 1, 1, 0);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAddFeatureDataUpdatePernissionsUpgradeTag());
    end;

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

    local procedure AddBackupRestorePermissionSet(): Boolean
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
    begin
        if TryInsertPermissionSet(CopyStr(BackupRestoreTok, 1, MaxStrLen(PermissionSet."Role ID")),
            CopyStr(BackupRestoreDescriptionTxt, 1, MaxStrLen(PermissionSet.Name))) then begin
            InsertPermission(CopyStr(BackupRestoreTok, 1, MaxStrLen(Permission."Role ID")), 10, 5410, 1, 1, 1, 1, 1);
            InsertPermission(CopyStr(BackupRestoreTok, 1, MaxStrLen(Permission."Role ID")), 10, 5420, 1, 1, 1, 1, 1);
            exit(true);
        end;
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

    local procedure TryInsertPermissionSet(PermissionSetID: Code[20]; PermissionSetName: Text[30]): Boolean
    var
        PermissionSet: Record "Permission Set";
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSetting: Codeunit "Server Setting";
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        if ServerSetting.GetUsePermissionSetsFromExtensions() then
            exit(false);

        if PermissionSet.Get(PermissionSetID) then
            exit(false);

        if EnvironmentInformation.IsSaaS() then begin
            TelemetryCustomDimensions.Add(PermissionSet.FieldCaption("Role ID"), PermissionSetID);
            TelemetryCustomDimensions.Add(PermissionSet.FieldCaption(Name), PermissionSetName);
            Session.LogMessage('0000DW1', StrSubstNo(CannotCreatePermissionSetLbl, PermissionSetID), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            exit(false);
        end;

        PermissionSet."Role ID" := PermissionSetID;
        PermissionSet.Name := PermissionSetName;
        PermissionSet.Insert();
        exit(true);
    end;

    local procedure InsertPermission(PermissionSetID: Code[20]; ObjType: Option; ObjId: Integer; ReadPerm: Option; InsertPerm: Option; ModifyPerm: Option; DeletePerm: Option; ExecutePerm: Option)
    var
        Permission: Record Permission;
        PermissionSet: Record "Permission Set";
        EnvironmentInformation: Codeunit "Environment Information";
        ServerSetting: Codeunit "Server Setting";
    begin
        if not PermissionSet.Get(PermissionSetID) then
            exit;
        if Permission.Get(PermissionSetID, ObjType, ObjId) then
            exit;

        if EnvironmentInformation.IsSaaS() then
            exit;

        if ServerSetting.GetUsePermissionSetsFromExtensions() then
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
        UserGroup: Record "User Group";
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
        UserGroupPermissionSet: Record "User Group Permission Set";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange("Role ID", PermissionSetId);
        if not AggregatePermissionSet.FindFirst() then
            exit;
        if UserGroupPermissionSet.Get(UserGroupCode, PermissionSetId, UserGroupPermissionSet.Scope::System, AggregatePermissionSet."App Id") then
            exit;

        UserGroupPermissionSet."Role ID" := PermissionSetId;
        UserGroupPermissionSet."User Group Code" := UserGroupCode;
        UserGroupPermissionSet.Scope := UserGroupPermissionSet.Scope::System;
        UserGroupPermissionSet."App ID" := AggregatePermissionSet."App Id";
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

    local procedure AddExcelExportActionPermissionSet(): Boolean
    begin
        if TryInsertPermissionSet(EditInExcelTok, ExcelExportActionDescriptionTxt) then begin
            InsertPermission(EditInExcelTok, 10, 6110, 0, 0, 0, 0, 1);
            exit(true);
        end;
    end;

    local procedure AddExcelExportActionUserGroup();
    begin
        InsertUserGroup(ExcelExportActionTok, ExcelExportActionDescriptionTxt, true);
    end;

    local procedure AddExcelExportActionPermissionSetToGroup();
    begin
        AddPermissionSetToUserGroup(EditInExcelTok, ExcelExportActionTok);
    end;

    local procedure AddExcelExportActionUserGroupToExistingPlans();
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetBasicPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetTeamMemberPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetEssentialPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetPremiumPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetViralSignupPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetExternalAccountantPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetDelegatedAdminPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetInternalAdminPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetTeamMemberISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetEssentialISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetPremiumISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetDeviceISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetDevicePlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetBasicFinancialsISVPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetAccountantHubPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetHelpDeskPlanId());
        AddUserGroupToPlan(ExcelExportActionTok, PlanIds.GetInfrastructurePlanId());
    end;

    local procedure SetSmartListDesignerPermissions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSmartListDesignerPermissionSetUpgradeTag()) then
            exit;

        AddSmartListDesignerPermissionSet();
        AddSmartListDesignerUserGroup();
        AddSmartListDesignerPermissionSetToGroup();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSmartListDesignerPermissionSetUpgradeTag());
    end;

    local procedure AddSmartListDesignerPermissionSet(): Boolean
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
    begin
        if TryInsertPermissionSet(CopyStr(SmartListDesignerTok, 1, MaxStrLen(PermissionSet."Role ID")),
            CopyStr(SmartListDesignerDescriptionTxt, 1, MaxStrLen(PermissionSet.Name))) then begin
            InsertPermission(CopyStr(SmartListDesignerTok, 1, MaxStrLen(Permission."Role ID")), 10, 9600, 0, 0, 0, 0, 1);
            InsertPermission(CopyStr(SmartListDesignerTok, 1, MaxStrLen(Permission."Role ID")), 10, 9605, 0, 0, 0, 0, 1);
            InsertPermission(CopyStr(SmartListDesignerTok, 1, MaxStrLen(Permission."Role ID")), 10, 9610, 0, 0, 0, 0, 1);
            InsertPermission(CopyStr(SmartListDesignerTok, 1, MaxStrLen(Permission."Role ID")), 10, 9615, 0, 0, 0, 0, 1);
            exit(true);
        end;
    end;

    local procedure AddSmartListDesignerUserGroup();
    var
        UserGroup: Record "User Group";
    begin
        InsertUserGroup(CopyStr(SmartListDesignerTok, 1, MaxStrLen(UserGroup.Code)),
            CopyStr(SmartListDesignerDescriptionTxt, 1, MaxStrLen(UserGroup.Name)), false);
    end;

    local procedure AddSmartListDesignerPermissionSetToGroup();
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        AddPermissionSetToUserGroup(CopyStr(SmartListDesignerTok, 1, MaxStrLen(UserGroupPermissionSet."Role ID")),
            CopyStr(SmartListDesignerTok, 1, MaxStrLen(UserGroupPermissionSet."User Group Code")));
    end;

    local procedure SetMonitorSensitiveFieldPermisions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetMonitorSensitiveFieldPermissionUpgradeTag()) then
            exit;

        AddD365MonitorFieldsToSecurityGroup();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetMonitorSensitiveFieldPermissionUpgradeTag());
    end;

    local procedure AddD365MonitorFieldsToSecurityGroup()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        AddPermissionSetToUserGroup(CopyStr(D365MonitorFieldsTxt, 1, MaxStrLen(UserGroupPermissionSet."Role ID")),
           CopyStr(SecurityUserGroupTok, 1, MaxStrLen(UserGroupPermissionSet."User Group Code")));
    end;
}
