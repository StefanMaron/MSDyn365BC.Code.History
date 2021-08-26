/// <summary>
/// Upgrade code to fix references of obsolete permission sets.
/// </summary>
codeunit 104042 "Upgrade Permission Sets"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        ReplaceObsoletePermissionSets();
#if not CLEAN19
        UpdateExcelExportActionUserGroup();
#endif
    end;

#if not CLEAN19
    local procedure UpdateExcelExportActionUserGroup()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetExportExcelReportUpgradeTag()) then
            exit;

        AggregatePermissionSet.SetRange("Role ID", 'Export Report Excel');
        if not AggregatePermissionSet.FindFirst() then
            exit;

        if UserGroupPermissionSet.Get('EXCEL EXPORT ACTION', 'Export Report Excel', UserGroupPermissionSet.Scope::System, AggregatePermissionSet."App ID") then
            exit;
        
        UserGroupPermissionSet."User Group Code" := 'EXCEL EXPORT ACTION';
        UserGroupPermissionSet."Role ID" := 'Export Report Excel';
        UserGroupPermissionSet.Scope := UserGroupPermissionSet.Scope::System;
        UserGroupPermissionSet."App ID" := AggregatePermissionSet."App ID";
        UserGroupPermissionSet.Insert();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetExportExcelReportUpgradeTag());
    end;
#endif

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
        OldAccessControl: Record "Access Control";
        NewAccessControl: Record "Access Control";
        OldUserGroupPermissionSet: Record "User Group Permission Set";
        NewUserGroupPermissionSet: Record "User Group Permission Set";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        AggregatePermissionSet.SetRange("Role ID", NewPermissionSet);
        if not AggregatePermissionSet.FindFirst() then begin
            Session.LogMessage('0000FGT', 
                StrSubstNo(NewPermissionSetNotFoundTxt, OldPermissionSet, NewPermissionSet),
                Verbosity::Normal,
                DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher,
                'Category',
                TelemetryCategoryTxt);
            exit;
        end;

        // User Groups need to be updated first as they result in modifications to Access Control
        // Change the User Group Permission Set entries that point to the old permission set to point to the new one
        OldUserGroupPermissionSet.SetRange("Role ID", OldPermissionSet);
        if OldUserGroupPermissionSet.FindSet() then
            repeat
                if NewUserGroupPermissionSet.Get(OldUserGroupPermissionSet."User Group Code", NewPermissionSet, AggregatePermissionSet.Scope, AggregatePermissionSet."App ID") then
                    OldUserGroupPermissionSet.Delete()
                else
                    OldUserGroupPermissionSet.Rename(OldUserGroupPermissionSet."User Group Code", NewPermissionSet, AggregatePermissionSet.Scope, AggregatePermissionSet."App ID");
            until OldUserGroupPermissionSet.Next() = 0;

        // Change the Access Control entries that point to the old permission set to point to the new one
        OldAccessControl.SetRange("Role ID", OldPermissionSet);
        if OldAccessControl.FindSet() then
            repeat
                if NewAccessControl.Get(OldAccessControl."User Security ID", NewPermissionSet, OldAccessControl."Company Name", AggregatePermissionSet.Scope, AggregatePermissionSet."App ID") then
                    OldAccessControl.Delete()
                else
                    OldAccessControl.Rename(OldAccessControl."User Security ID", NewPermissionSet, OldAccessControl."Company Name", AggregatePermissionSet.Scope, AggregatePermissionSet."App ID");
            until OldAccessControl.Next() = 0;
    end;

    var
        NewPermissionSetNotFoundTxt: Label 'Skipping the upgrade of %1 to %2, as we could not find the permission set %2.', Locked = true;
        TelemetryCategoryTxt: Label 'AL SaaS upgrade', Locked = true;
}
