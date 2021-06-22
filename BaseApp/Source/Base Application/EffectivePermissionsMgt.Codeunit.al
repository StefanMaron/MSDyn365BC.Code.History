codeunit 9852 "Effective Permissions Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        UserAccountHelper: DotNet NavUserAccountHelper;
        DialogFormatMsg: Label 'Reading objects...@1@@@@@@@@@@@@@@@@@@';
        ChangeAffectsOthersMsg: Label 'Your change in permission set %1 will affect other users that the permission set is assigned to.', Comment = '%1 = permission set ID that was changed';
        ChangeAffectsOthersNameTxt: Label 'Changing permission sets for other users';
        ChangeAffectsOthersDescTxt: Label 'Show a warning when changing a permission set that is assigned to other users.';
        DirectConflictWithIndirectMsg: Label 'This user has been given the Yes permission for the selected object, but their license allows them only the Indirect permission.';
        DirectConflictWithNoneMsg: Label 'This user has been given the Yes permission to the selected object, but the object is not included in their license.';
        IndirectConflictWithNoneMsg: Label 'This user has been given the Indirect permission for the selected object, but the object is not included in their license.';
        IndirectSolutionMsg: Label 'To resolve the conflict, change the permission level to Indirect.';
        NoneSolutionMsg: Label 'To resolve the conflict, set the permission level to blank.';
        SystemPermSetSolutionMsg: Label 'You can only change permission levels in User Defined permission sets. You can replace system and extension permission sets with one that you create.';
        UserListLbl: Label 'See users affected';
        UndoChangeLbl: Label 'Undo change';
        DontShowAgainLbl: Label 'Never show again';
        RevertChangeQst: Label 'Do you want to revert the recent change to permission set %1?', Comment = '%1 = the permission set ID that has been changed.';
        ConflictLbl: Label 'Conflict';

    procedure OpenPageForUser(UserSID: Guid)
    var
        EffectivePermissions: Page "Effective Permissions";
    begin
        EffectivePermissions.SetUserSID(UserSID);
        EffectivePermissions.Run;
    end;

    local procedure GetObjectsInLicense(PlanOrRole: Enum Licenses; var Entitlement: Record Entitlement)
    var
        MembershipEntitlement: Record "Membership Entitlement";
        EntitlementSet: Record "Entitlement Set";
        PermissionSetAgainstLicense: Record "Permission Conflicts Overview";
        Planids: Codeunit "Plan Ids";
        EntitlementFilter: Text;
        PlanId: Text;
    begin
        case PlanOrRole of
            PlanOrRole::Basic:
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Plan");
                    PlanId := Planids.GetBasicPlanId();
                end;
            PlanOrRole::"Team Member":
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Plan");
                    PlanId := Planids.GetTeamMemberPlanId();
                end;
            PlanOrRole::Essential:
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Plan");
                    PlanId := Planids.GetEssentialPlanId();
                end;
            PlanOrRole::Premium:
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Plan");
                    PlanId := Planids.GetPremiumPlanId();
                end;
            PlanOrRole::Device:
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Plan");
                    PlanId := Planids.GetDevicePlanId();
                end;
            PlanOrRole::"External Accountant":
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Plan");
                    PlanId := Planids.GetExternalAccountantPlanId();
                end;
            PlanOrRole::"Internal Admin":
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Role");
                    PlanId := Planids.GetInternalAdminPlanId();
                end;
            PlanOrRole::"Delegated Admin":
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Role");
                    PlanId := Planids.GetDelegatedAdminPlanId();
                end;
            PlanOrRole::HelpDesk:
                begin
                    MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Role");
                    PlanId := Planids.GetHelpDeskPlanId();
                end;
        end;

        PlanId := DelChr(PlanId, '<>', '{}');
        // Filter on plan id, ignoring case sensitivity
        MembershipEntitlement.SetFilter(ID, StrSubstNo('@%1', PlanId));

        if MembershipEntitlement.FindSet() then
            repeat
                EntitlementFilter := EntitlementFilter + MembershipEntitlement."Entitlement Set ID" + '|';
            until MembershipEntitlement.Next() = 0;

        EntitlementFilter := DelChr(EntitlementFilter, '>', '|');

        Entitlement.Reset();
        Entitlement.SetFilter("Entitlement Set ID", EntitlementFilter);
    end;

    internal procedure PopulatePermissionConflictsTable(PlanOrRole: Enum Licenses; RoleId: Code[20]; var PermissionConflicts: Record "Permission Conflicts" temporary)
    var
        Entitlement: Record Entitlement;
        Permission: Record Permission;
        TenantPermission: Record "Tenant Permission";
    begin
        PermissionConflicts.Reset();
        PermissionConflicts.DeleteAll();

        GetObjectsInLicense(PlanOrRole, Entitlement);

        Permission.SetRange("Role ID", RoleId);
        Permission.SetRange("Object Type", Permission."Object Type"::"Table Data");
        if Permission.FindSet() then
            repeat
                Entitlement.SetRange("Object Type", Permission."Object Type"::"Table Data");
                Entitlement.SetFilter("Object ID Range Start", '<=%1', Permission."Object ID");
                Entitlement.SetFilter("Object ID Range End", '>=%1', Permission."Object ID");

                InitializePermissionConflicts(Permission."Object Type", Permission."Object ID", Permission."Read Permission",
                    Permission."Insert Permission", Permission."Modify Permission", Permission."Delete Permission",
                    Permission."Execute Permission", false, PermissionConflicts);

                if Entitlement.FindSet() then
                    repeat
                        UpdatePermissionIfHigherPermission(Entitlement."Read Permission", PermissionConflicts."Entitlement Read Permission");
                        UpdatePermissionIfHigherPermission(Entitlement."Insert Permission", PermissionConflicts."Entitlement Insert Permission");
                        UpdatePermissionIfHigherPermission(Entitlement."Modify Permission", PermissionConflicts."Entitlement Modify Permission");
                        UpdatePermissionIfHigherPermission(Entitlement."Delete Permission", PermissionConflicts."Entitlement Delete Permission");
                        UpdatePermissionIfHigherPermission(Entitlement."Execute Permission", PermissionConflicts."Entitlement Execute Permission");
                    until Entitlement.Next() = 0;

                InsertPermissionConflictIfConflictExists(PermissionConflicts);
            until Permission.Next() = 0;

        TenantPermission.SetRange("Role ID", RoleId);
        TenantPermission.SetRange("Object Type", TenantPermission."Object Type"::"Table Data");
        if TenantPermission.FindSet() then
            repeat
                Entitlement.SetRange("Object Type", TenantPermission."Object Type"::"Table Data");
                Entitlement.SetFilter("Object ID Range Start", '<=%1', TenantPermission."Object ID");
                Entitlement.SetFilter("Object ID Range End", '>=%1', TenantPermission."Object ID");

                InitializePermissionConflicts(TenantPermission."Object Type", TenantPermission."Object ID", TenantPermission."Read Permission",
                    TenantPermission."Insert Permission", TenantPermission."Modify Permission", TenantPermission."Delete Permission",
                    TenantPermission."Execute Permission", true, PermissionConflicts);

                if Entitlement.FindSet() then
                    repeat
                        UpdatePermissionIfHigherPermission(Entitlement."Read Permission", PermissionConflicts."Entitlement Read Permission");
                        UpdatePermissionIfHigherPermission(Entitlement."Insert Permission", PermissionConflicts."Entitlement Insert Permission");
                        UpdatePermissionIfHigherPermission(Entitlement."Modify Permission", PermissionConflicts."Entitlement Modify Permission");
                        UpdatePermissionIfHigherPermission(Entitlement."Delete Permission", PermissionConflicts."Entitlement Delete Permission");
                        UpdatePermissionIfHigherPermission(Entitlement."Execute Permission", PermissionConflicts."Entitlement Execute Permission");
                    until Entitlement.Next() = 0;

                InsertPermissionConflictIfConflictExists(PermissionConflicts);
            until TenantPermission.Next() = 0;
    end;

    local procedure InitializePermissionConflicts(PermissionObjectType: Option; PermissionObjectID: Integer;
                                                    ReadPerm: Option; InsertPerm: Option; ModifyPerm: Option; DeletePerm: Option; ExecutePerm: Option; UserDefined: Boolean;
                                                    var PermissionConflicts: Record "Permission Conflicts")
    begin
        PermissionConflicts.Init();
        PermissionConflicts."Object Type" := PermissionObjectType;
        PermissionConflicts."Object ID" := PermissionObjectID;
        PermissionConflicts."Read Permission" := ConvertToPermission(ReadPerm);
        PermissionConflicts."Insert Permission" := ConvertToPermission(InsertPerm);
        PermissionConflicts."Modify Permission" := ConvertToPermission(ModifyPerm);
        PermissionConflicts."Delete Permission" := ConvertToPermission(DeletePerm);
        PermissionConflicts."Execute Permission" := ConvertToPermission(ExecutePerm);
        PermissionConflicts."Entitlement Read Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."Entitlement Insert Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."Entitlement Modify Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."Entitlement Delete Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."Entitlement Execute Permission" := PermissionConflicts."Entitlement Read Permission"::None;
        PermissionConflicts."User Defined" := UserDefined;
    end;

    local procedure UpdatePermissionIfHigherPermission(Permission: Option; var UpdatePermission: Enum Permission)
    var
        ConvertedPermission: Enum Permission;
    begin
        ConvertedPermission := ConvertToPermission(Permission);
        if ConvertedPermission > UpdatePermission then
            UpdatePermission := ConvertedPermission;
    end;

    local procedure InsertPermissionConflictIfConflictExists(var PermissionConflicts: Record "Permission Conflicts")
    begin
        if (PermissionConflicts."Read Permission" > PermissionConflicts."Entitlement Read Permission") or
            (PermissionConflicts."Insert Permission" > PermissionConflicts."Entitlement Insert Permission") or
            (PermissionConflicts."Modify Permission" > PermissionConflicts."Entitlement Modify Permission") or
            (PermissionConflicts."Delete Permission" > PermissionConflicts."Entitlement Delete Permission") or
            (PermissionConflicts."Execute Permission" > PermissionConflicts."Entitlement Execute Permission") then
            PermissionConflicts.Insert();
    end;

    internal procedure PopulatePermissionConflictsOverviewTable(var PermissionConflictsOverview: Record "Permission Conflicts Overview" temporary; PlansExist: Dictionary of [Guid, Boolean])
    var
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        ProgressBar: Codeunit "Config. Progress Bar";
        PlanIds: Codeunit "Plan Ids";
        PlanOrRole: Enum Licenses;
        CurrentPermissionSet: Integer;
        TotalPermissionSets: Integer;
        ProgressBarTitleLbl: Label 'Loading permission sets';
        ProgressLbl: Label '#1#### of #2####', Comment = '#1 - Current permission set, #2 - Total number of permission sets';
    begin
        TotalPermissionSets := PermissionSet.Count() + TenantPermissionSet.Count();

        ProgressBar.Init(TotalPermissionSets, 1, ProgressBarTitleLbl);
        PermissionConflictsOverview.Reset();
        PermissionConflictsOverview.DeleteAll();

        if PermissionSet.FindSet() then
            repeat
                CurrentPermissionSet += 1;
                ProgressBar.Update(StrSubstNo(ProgressLbl, CurrentPermissionSet, TotalPermissionSets));
                PermissionConflictsOverview.PermissionSetID := PermissionSet."Role ID";
                PermissionConflictsOverview.Type := PermissionConflictsOverview.Type::System;
                if PlansExist.ContainsKey(PlanIds.GetBasicPlanId()) then
                    PermissionConflictsOverview.Basic := IsPermissionSetCoveredByLicense(PlanOrRole::Basic, PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetTeamMemberPlanId()) then
                    PermissionConflictsOverview."Team Member" := IsPermissionSetCoveredByLicense(PlanOrRole::"Team Member", PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetEssentialPlanId()) then
                    PermissionConflictsOverview.Essential := IsPermissionSetCoveredByLicense(PlanOrRole::Essential, PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetPremiumPlanId()) then
                    PermissionConflictsOverview.Premium := IsPermissionSetCoveredByLicense(PlanOrRole::Premium, PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetDevicePlanId()) then
                    PermissionConflictsOverview.Device := IsPermissionSetCoveredByLicense(PlanOrRole::Device, PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetExternalAccountantPlanId()) then
                    PermissionConflictsOverview."External Accountant" := IsPermissionSetCoveredByLicense(PlanOrRole::"External Accountant", PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetInternalAdminPlanId()) then
                    PermissionConflictsOverview."Internal Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"Internal Admin", PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetDelegatedAdminPlanId()) then
                    PermissionConflictsOverview."Delegated Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"Delegated Admin", PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                if PlansExist.ContainsKey(PlanIds.GetHelpDeskPlanId()) then
                    PermissionConflictsOverview.HelpDesk := IsPermissionSetCoveredByLicense(PlanOrRole::HelpDesk, PermissionSet."Role ID", PermissionConflictsOverview.Type::System);
                PermissionConflictsOverview.Insert();
            until PermissionSet.Next() = 0;

        if TenantPermissionSet.FindSet() then
            repeat
                CurrentPermissionSet += 1;
                ProgressBar.Update(StrSubstNo(ProgressLbl, CurrentPermissionSet, TotalPermissionSets));
                PermissionConflictsOverview.PermissionSetID := TenantPermissionSet."Role ID";
                PermissionConflictsOverview.Type := PermissionConflictsOverview.Type::User;
                if PlansExist.ContainsKey(PlanIds.GetBasicPlanId()) then
                    PermissionConflictsOverview.Basic := IsPermissionSetCoveredByLicense(PlanOrRole::Basic, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetTeamMemberPlanId()) then
                    PermissionConflictsOverview."Team Member" := IsPermissionSetCoveredByLicense(PlanOrRole::"Team Member", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetEssentialPlanId()) then
                    PermissionConflictsOverview.Essential := IsPermissionSetCoveredByLicense(PlanOrRole::Essential, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetPremiumPlanId()) then
                    PermissionConflictsOverview.Premium := IsPermissionSetCoveredByLicense(PlanOrRole::Premium, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetDevicePlanId()) then
                    PermissionConflictsOverview.Device := IsPermissionSetCoveredByLicense(PlanOrRole::Device, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetExternalAccountantPlanId()) then
                    PermissionConflictsOverview."External Accountant" := IsPermissionSetCoveredByLicense(PlanOrRole::"External Accountant", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetInternalAdminPlanId()) then
                    PermissionConflictsOverview."Internal Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"Internal Admin", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetDelegatedAdminPlanId()) then
                    PermissionConflictsOverview."Delegated Admin" := IsPermissionSetCoveredByLicense(PlanOrRole::"Delegated Admin", TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                if PlansExist.ContainsKey(PlanIds.GetHelpDeskPlanId()) then
                    PermissionConflictsOverview.HelpDesk := IsPermissionSetCoveredByLicense(PlanOrRole::HelpDesk, TenantPermissionSet."Role ID", PermissionConflictsOverview.Type::User);
                PermissionConflictsOverview.Insert();
            until TenantPermissionSet.Next() = 0;
        ProgressBar.Close();
    end;

    local procedure IsPermissionSetCoveredByLicense(PlanOrRole: Enum Licenses; PermissionSetID: Code[20]; PermissionType: Option): Boolean
    var
        Entitlement: Record Entitlement;
        Permission: Record Permission;
        TenantPermission: Record "Tenant Permission";
        PermissionConflictsOverview: Record "Permission Conflicts Overview";
        PermissionBuffer: Record "Permission Buffer";
    begin
        GetObjectsInLicense(PlanOrRole, Entitlement);

        if PermissionType = PermissionConflictsOverview.Type::System then begin
            Permission.SetRange("Role ID", PermissionSetID);
            Permission.SetRange("Object Type", Permission."Object Type"::"Table Data");
            if Permission.FindSet() then
                repeat
                    FillPermissionBufferFromPermission(PermissionBuffer, Permission);
                    if IsPermissionRestrictedByLicense(PermissionBuffer, Permission."Object Type", Permission."Object ID", Entitlement) then
                        exit(false);
                until Permission.Next() = 0;
            exit(true);
        end else begin
            TenantPermission.SetRange("Role ID", PermissionSetID);
            TenantPermission.SetRange("Object Type", TenantPermission."Object Type"::"Table Data");
            if TenantPermission.FindSet() then
                repeat
                    FillPermissionBufferFromTenantPermission(PermissionBuffer, TenantPermission);
                    if IsPermissionRestrictedByLicense(PermissionBuffer, TenantPermission."Object Type", TenantPermission."Object ID", Entitlement) then
                        exit(false);
                until TenantPermission.Next() = 0;
            exit(true);
        end;
    end;

    local procedure IsPermissionRestrictedByLicense(Permission: Record "Permission Buffer"; PermissionObjectType: Option; PermissionObjectId: Integer; var Entitlement: Record Entitlement) Result: Boolean
    var
        DummyPermission: Record Permission;
        PermissionManager: Codeunit "Permission Manager";
    begin
        Entitlement.SetRange("Object Type", PermissionObjectType);
        Entitlement.SetFilter("Object ID Range Start", '<=%1', PermissionObjectId);
        Entitlement.SetFilter("Object ID Range End", '>=%1', PermissionObjectId);
        if Entitlement.IsEmpty then
            exit(true);
        if not Entitlement.FindFirst() then
            exit(true);

        if PermissionObjectType in [DummyPermission."Object Type"::"Table Data", DummyPermission."Object Type"::System] then begin
            Result := PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Read Permission", Entitlement."Read Permission");
            Result := Result or PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Insert Permission", Entitlement."Insert Permission");
            Result := Result or PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Modify Permission", Entitlement."Modify Permission");
            Result := Result or PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Delete Permission", Entitlement."Delete Permission");

            if PermissionObjectType = DummyPermission."Object Type"::System then
                Result := Result or PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Execute Permission", Entitlement."Execute Permission");
        end else
            Result := PermissionManager.IsFirstPermissionHigherThanSecond(Permission."Execute Permission", Entitlement."Execute Permission");

        exit(Result);
    end;

    procedure PopulatePermissionBuffer(var PermissionBuffer: Record "Permission Buffer"; PassedUserID: Guid; PassedCompanyName: Text[50]; PassedObjectType: Integer; PassedObjectId: Integer)
    var
        AccessControl: Record "Access Control";
        Permission: Record Permission;
        TenantPermission: Record "Tenant Permission";
        PermissionSetBuffer: Record "Permission Set Buffer";
        EnvironmentInfo: Codeunit "Environment Information";
        PermissionCommaStr: Text;
        Read: Integer;
        Insert: Integer;
        Modify: Integer;
        Delete: Integer;
        Execute: Integer;
    begin
        PermissionBuffer.Reset();
        PermissionBuffer.DeleteAll();

        Permission.SetRange("Object Type", PassedObjectType);
        Permission.SetFilter("Object ID", '%1|%2', 0, PassedObjectId);
        TenantPermission.SetRange("Object Type", PassedObjectType);
        TenantPermission.SetFilter("Object ID", '%1|%2', 0, PassedObjectId);

        // find permissions from all permission sets for this user
        AccessControl.SetRange("User Security ID", PassedUserID);
        AccessControl.SetFilter("Company Name", '%1|%2', '', PassedCompanyName);
        if AccessControl.FindSet then
            repeat
                // do not show permission sets for hidden extensions
                if StrPos(UpperCase(AccessControl."App Name"), UpperCase('_Exclude_')) <> 1 then begin
                    PermissionBuffer.Init();
                    PermissionBuffer.Source := PermissionBuffer.Source::Normal;
                    PermissionBuffer."Permission Set" := AccessControl."Role ID";
                    PermissionBuffer.Type := PermissionSetBuffer.GetType(AccessControl.Scope, AccessControl."App ID");
                    if AccessControl.Scope = AccessControl.Scope::System then begin
                        Permission.SetRange("Role ID", AccessControl."Role ID");
                        if Permission.FindFirst then begin
                            FillPermissionBufferFromPermission(PermissionBuffer, Permission);
                            PermissionBuffer.Insert();
                        end;
                    end else begin
                        TenantPermission.SetRange("App ID", AccessControl."App ID");
                        TenantPermission.SetRange("Role ID", AccessControl."Role ID");
                        if TenantPermission.FindFirst then begin
                            FillPermissionBufferFromTenantPermission(PermissionBuffer, TenantPermission);
                            PermissionBuffer.Insert();
                        end;
                    end;
                end;
            until AccessControl.Next = 0;

        // find entitlement permission
        if not EnvironmentInfo.IsSaaS then
            exit;
        PermissionBuffer.Init();
        PermissionBuffer.Source := PermissionBuffer.Source::Entitlement;
        PermissionBuffer."Permission Set" := '';
        PermissionBuffer.Type := PermissionBuffer.Type::System;
        PermissionCommaStr := UserAccountHelper.GetEntitlementPermissionForObject(PassedUserID, PassedObjectType, PassedObjectId);
        ExtractPermissionsFromText(PermissionCommaStr, Read, Insert, Modify, Delete, Execute);
        PermissionBuffer."Read Permission" := Read;
        PermissionBuffer."Insert Permission" := Insert;
        PermissionBuffer."Modify Permission" := Modify;
        PermissionBuffer."Delete Permission" := Delete;
        PermissionBuffer."Execute Permission" := Execute;
        PermissionBuffer.Insert();
    end;

    procedure PopulateEffectivePermissionsBuffer(var Permission: Record Permission; PassedUserID: Guid; PassedCompanyName: Text[50]; PassedObjectType: Integer; PassedObjectId: Integer; ShowAllObjects: Boolean)
    var
        AllObj: Record AllObj;
        Window: Dialog;
        TotalCount: Integer;
        NumObjectsProcessed: Integer;
        TimesToUpdate: Integer;
    begin
        Permission.Reset();
        Permission.DeleteAll();

        if PassedObjectId = 0 then begin
            Window.Open(DialogFormatMsg);
            AllObj.SetFilter("Object Type", '%1|%2|%3|%4|%5|%6|%7|%8|%9',
              Permission."Object Type"::"Table Data",
              Permission."Object Type"::Table,
              Permission."Object Type"::Report,
              Permission."Object Type"::Codeunit,
              Permission."Object Type"::XMLport,
              Permission."Object Type"::MenuSuite,
              Permission."Object Type"::Page,
              Permission."Object Type"::Query,
              Permission."Object Type"::System);
            if not ShowAllObjects then
                FilterOnlyObjectsPresentInUserPermissionSets(AllObj, PassedUserID, PassedCompanyName);
            if AllObj.FindSet then begin
                TotalCount := AllObj.Count();
                // Only update every 10 %
                TimesToUpdate := TotalCount div 10;
                repeat
                    InsertEffectivePermissionForObject(Permission, PassedUserID, PassedCompanyName,
                      AllObj."Object Type", AllObj."Object ID");
                    NumObjectsProcessed += 1;
                    if (NumObjectsProcessed mod TimesToUpdate) = 0 then
                        Window.Update(1, Round(NumObjectsProcessed * 10000 / TotalCount, 1));
                until AllObj.Next = 0;
                Permission.FindFirst;
            end;
            Window.Close;
        end else
            InsertEffectivePermissionForObject(Permission, PassedUserID, PassedCompanyName, PassedObjectType, PassedObjectId);
    end;

    local procedure FilterOnlyObjectsPresentInUserPermissionSets(var AllObj: Record AllObj; PassedUserID: Guid; PassedCompanyName: Text[50])
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", PassedUserID);
        AccessControl.SetFilter("Company Name", '%1|%2', '', PassedCompanyName);
        if AccessControl.FindSet then
            repeat
                case AccessControl.Scope of
                    AccessControl.Scope::System:
                        MarkAllObjFromPermissionSet(AllObj, AccessControl."Role ID");
                    AccessControl.Scope::Tenant:
                        MarkAllObjFromTenantPermissionSet(AllObj, AccessControl."Role ID", AccessControl."App ID");
                end;
            until AccessControl.Next = 0;

        AllObj.MarkedOnly(true);
    end;

    local procedure InsertEffectivePermissionForObject(var Permission: Record Permission; PassedUserID: Guid; PassedCompanyName: Text[50]; PassedObjectType: Integer; PassedObjectId: Integer)
    begin
        Permission.Init();
        Permission."Object Type" := PassedObjectType;
        Permission."Object ID" := PassedObjectId;
        PopulatePermissionRecordWithEffectivePermissionsForObject(Permission, PassedUserID, PassedCompanyName,
          PassedObjectType, PassedObjectId);
        Permission.Insert();
    end;

    local procedure FillPermissionBufferFromPermission(var PermissionBuffer: Record "Permission Buffer"; Permission: Record Permission)
    begin
        PermissionBuffer."Read Permission" := Permission."Read Permission";
        PermissionBuffer."Insert Permission" := Permission."Insert Permission";
        PermissionBuffer."Modify Permission" := Permission."Modify Permission";
        PermissionBuffer."Delete Permission" := Permission."Delete Permission";
        PermissionBuffer."Execute Permission" := Permission."Execute Permission";
    end;

    local procedure FillPermissionBufferFromTenantPermission(var PermissionBuffer: Record "Permission Buffer"; TenantPermission: Record "Tenant Permission")
    begin
        PermissionBuffer."Read Permission" := TenantPermission."Read Permission";
        PermissionBuffer."Insert Permission" := TenantPermission."Insert Permission";
        PermissionBuffer."Modify Permission" := TenantPermission."Modify Permission";
        PermissionBuffer."Delete Permission" := TenantPermission."Delete Permission";
        PermissionBuffer."Execute Permission" := TenantPermission."Execute Permission";
    end;

    local procedure MarkAllObjFromPermissionSet(var AllObj: Record AllObj; PermissionSetID: Code[20])
    var
        Permission: Record Permission;
    begin
        Permission.SetRange("Role ID", PermissionSetID);
        if Permission.FindSet then
            repeat
                MarkAllObj(AllObj, Permission."Object Type", Permission."Object ID");
            until Permission.Next = 0;
    end;

    local procedure MarkAllObjFromTenantPermissionSet(var AllObj: Record AllObj; PermissionSetID: Code[20]; AppID: Guid)
    var
        TenantPermission: Record "Tenant Permission";
    begin
        TenantPermission.SetRange("App ID", AppID);
        TenantPermission.SetRange("Role ID", PermissionSetID);
        if TenantPermission.FindSet then
            repeat
                MarkAllObj(AllObj, TenantPermission."Object Type", TenantPermission."Object ID");
            until TenantPermission.Next = 0;
    end;

    local procedure MarkAllObj(var AllObj: Record AllObj; ObjectTypePassed: Integer; ObjectIDPassed: Integer)
    begin
        if ObjectIDPassed = 0 then begin
            AllObj.SetRange("Object Type", ObjectTypePassed);
            if AllObj.FindSet then
                repeat
                    AllObj.Mark(true);
                until AllObj.Next = 0;
            AllObj.SetRange("Object Type");
            exit;
        end;

        if AllObj.Get(ObjectTypePassed, ObjectIDPassed) then
            AllObj.Mark(true);
    end;

    procedure PopulatePermissionRecordWithEffectivePermissionsForObject(var Permission: Record Permission; PassedUserID: Guid; PassedCompanyName: Text[50]; PassedObjectType: Option; PassedObjectId: Integer)
    var
        PermissionCommaStr: Text;
        Read: Integer;
        Insert: Integer;
        Modify: Integer;
        Delete: Integer;
        Execute: Integer;
    begin
        PermissionCommaStr := UserAccountHelper.GetEffectivePermissionForObject(
            PassedUserID, PassedCompanyName, PassedObjectType, PassedObjectId);
        ExtractPermissionsFromText(PermissionCommaStr, Read, Insert, Modify, Delete, Execute);
        Permission."Read Permission" := Read;
        Permission."Insert Permission" := Insert;
        Permission."Modify Permission" := Modify;
        Permission."Delete Permission" := Delete;
        Permission."Execute Permission" := Execute;
    end;

    local procedure ExtractPermissionsFromText(PermissionCommaStr: Text; var Read: Integer; var Insert: Integer; var Modify: Integer; var Delete: Integer; var Execute: Integer)
    begin
        Evaluate(Read, SelectStr(1, PermissionCommaStr));
        Evaluate(Insert, SelectStr(2, PermissionCommaStr));
        Evaluate(Modify, SelectStr(3, PermissionCommaStr));
        Evaluate(Delete, SelectStr(4, PermissionCommaStr));
        Evaluate(Execute, SelectStr(5, PermissionCommaStr));
    end;

    procedure ModifyPermission(FieldNumChanged: Integer; PermissionBuffer: Record "Permission Buffer"; PassedObjectType: Integer; PassedObjectId: Integer; PassedUserID: Guid)
    var
        TenantPermission: Record "Tenant Permission";
        CallModify: Boolean;
        OldValue: Integer;
    begin
        TenantPermission.Get(PermissionBuffer.GetAppID, PermissionBuffer."Permission Set", PassedObjectType, PassedObjectId);
        case FieldNumChanged of
            TenantPermission.FieldNo("Read Permission"):
                begin
                    OldValue := TenantPermission."Read Permission";
                    CallModify := TenantPermission."Read Permission" <> PermissionBuffer."Read Permission";
                    TenantPermission."Read Permission" := PermissionBuffer."Read Permission";
                end;
            TenantPermission.FieldNo("Insert Permission"):
                begin
                    OldValue := TenantPermission."Insert Permission";
                    CallModify := TenantPermission."Insert Permission" <> PermissionBuffer."Insert Permission";
                    TenantPermission."Insert Permission" := PermissionBuffer."Insert Permission";
                end;
            TenantPermission.FieldNo("Modify Permission"):
                begin
                    OldValue := TenantPermission."Modify Permission";
                    CallModify := TenantPermission."Modify Permission" <> PermissionBuffer."Modify Permission";
                    TenantPermission."Modify Permission" := PermissionBuffer."Modify Permission";
                end;
            TenantPermission.FieldNo("Delete Permission"):
                begin
                    OldValue := TenantPermission."Delete Permission";
                    CallModify := TenantPermission."Delete Permission" <> PermissionBuffer."Delete Permission";
                    TenantPermission."Delete Permission" := PermissionBuffer."Delete Permission";
                end;
            TenantPermission.FieldNo("Execute Permission"):
                begin
                    OldValue := TenantPermission."Execute Permission";
                    CallModify := TenantPermission."Execute Permission" <> PermissionBuffer."Execute Permission";
                    TenantPermission."Execute Permission" := PermissionBuffer."Execute Permission";
                end;
        end;
        if not CallModify then
            exit;
        TenantPermission.Modify();
        SendNotification(PermissionBuffer."Permission Set", PassedObjectType, PassedObjectId, PassedUserID, FieldNumChanged, OldValue);
        OnTenantPermissionModified(TenantPermission."Role ID");
    end;

    local procedure SendNotification(PermissionSetID: Code[20]; PassedObjectType: Integer; PassedObjectId: Integer; UserOnPage: Guid; FieldNumChanged: Integer; OldValue: Integer)
    var
        User: Record User;
        MyNotifications: Record "My Notifications";
        Notification: Notification;
        NotificationID: Guid;
    begin
        MarkUsersWithAssignedPermissionSet(User, PermissionSetID);
        User.SetFilter("User Security ID", '<>%1', UserOnPage);
        if User.IsEmpty then
            exit;

        NotificationID := GetPermissionChangeNotificationId;
        if not MyNotifications.IsEnabled(NotificationID) then
            exit;

        Notification.Id := NotificationID;
        Notification.Message := StrSubstNo(ChangeAffectsOthersMsg, PermissionSetID);
        Notification.SetData('UserOnPage', UserOnPage);
        Notification.SetData('PermissionSetID', PermissionSetID);
        Notification.SetData('ObjectType', Format(PassedObjectType));
        Notification.SetData('ObjectID', Format(PassedObjectId));
        Notification.SetData('FieldNumChanged', Format(FieldNumChanged));
        Notification.SetData('OldValue', Format(OldValue));
        Notification.AddAction(UserListLbl, CODEUNIT::"Effective Permissions Mgt.", 'NotificationShowUsers');
        Notification.AddAction(UndoChangeLbl, CODEUNIT::"Effective Permissions Mgt.", 'NotificationUndoChange');
        Notification.AddAction(DontShowAgainLbl, CODEUNIT::"Effective Permissions Mgt.", 'DisableNotification');
        Notification.Send;
    end;

    procedure NotificationShowUsers(Notification: Notification)
    var
        User: Record User;
        PermissionSetID: Code[20];
    begin
        PermissionSetID := Notification.GetData('PermissionSetID');
        MarkUsersWithAssignedPermissionSet(User, PermissionSetID);
        User.SetFilter("User Security ID", '<>%1', Notification.GetData('UserOnPage'));
        PAGE.RunModal(PAGE::Users, User);
        if Confirm(StrSubstNo(RevertChangeQst, PermissionSetID), false) then
            NotificationUndoChange(Notification);
    end;

    procedure NotificationUndoChange(Notification: Notification)
    var
        TenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
        ObjType: Integer;
        ObjID: Integer;
        FieldNumChanged: Integer;
        OldValue: Integer;
    begin
        Evaluate(ObjType, Notification.GetData('ObjectType'));
        Evaluate(ObjID, Notification.GetData('ObjectID'));
        TenantPermission.Get(ZeroGUID, Notification.GetData('PermissionSetID'), ObjType, ObjID);

        Evaluate(FieldNumChanged, Notification.GetData('FieldNumChanged'));
        Evaluate(OldValue, Notification.GetData('OldValue'));
        case FieldNumChanged of
            TenantPermission.FieldNo("Read Permission"):
                TenantPermission."Read Permission" := OldValue;
            TenantPermission.FieldNo("Insert Permission"):
                TenantPermission."Insert Permission" := OldValue;
            TenantPermission.FieldNo("Modify Permission"):
                TenantPermission."Modify Permission" := OldValue;
            TenantPermission.FieldNo("Delete Permission"):
                TenantPermission."Delete Permission" := OldValue;
            TenantPermission.FieldNo("Execute Permission"):
                TenantPermission."Execute Permission" := OldValue;
        end;
        TenantPermission.Modify();
    end;

    procedure DisableNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(GetPermissionChangeNotificationId);
    end;

    procedure ConvertToPermission(PermissionOption: Option) Permission: enum Permission
    var
        PermissionBuffer: Record "Permission Buffer";
    begin
        case PermissionOption of
            PermissionBuffer."Read Permission"::" ":
                exit(Permission::None);
            PermissionBuffer."Read Permission"::Yes:
                exit(Permission::Direct);
            PermissionBuffer."Read Permission"::Indirect:
                exit(Permission::Indirect);
        end;
    end;

    internal procedure ShowPermissionConflict(Permissions: Enum Permission; EntitlementPermissions: Enum Permission; IsSourceEntitlement: Boolean; IsPermissionSetUserDefined: Boolean)
    var
        ConflictMsg: Text;
        SolutionMsg: Text;
    begin
        if IsSourceEntitlement then
            exit;

        if not ArePermissionsInConflict(Permissions, EntitlementPermissions) then
            exit;

        if (Permissions = Permissions::Direct) and (EntitlementPermissions = EntitlementPermissions::Indirect) then begin
            ConflictMsg := DirectConflictWithIndirectMsg;
            SolutionMsg := IndirectSolutionMsg;
        end;

        if (Permissions = Permissions::Direct) and (EntitlementPermissions = EntitlementPermissions::None) then begin
            ConflictMsg := DirectConflictWithNoneMsg;
            SolutionMsg := NoneSolutionMsg;
        end;

        if (Permissions = Permissions::Indirect) and (EntitlementPermissions = EntitlementPermissions::None) then begin
            ConflictMsg := IndirectConflictWithNoneMsg;
            SolutionMsg := NoneSolutionMsg;
        end;

        if not IsPermissionSetUserDefined then
            SolutionMsg := SystemPermSetSolutionMsg;

        ConflictMsg += '\\'; // an empty line
        ConflictMsg += SolutionMsg;

        Message(ConflictMsg);
    end;

    internal procedure GetPermissionStatus(Permissions: Enum Permission; EntitlementPermissions: Enum Permission; IsSourceEntitlement: Boolean): Text
    var
        PermissionBuffer: Record "Permission Buffer";
    begin
        if IsSourceEntitlement then
            exit(Format(Permissions));

        if not ArePermissionsInConflict(Permissions, EntitlementPermissions) then
            exit(Format(Permissions));

        exit(ConflictLbl);
    end;

    local procedure ArePermissionsInConflict(PermissionsFromPermissionSet: Enum Permission; PermissionsFromEntitlement: Enum Permission): Boolean
    begin
        exit(PermissionsFromPermissionSet > PermissionsFromEntitlement);
    end;

    internal procedure OpenPermissionConflicts(PermissionSetID: Code[20]; PlanOrRole: Enum Licenses)
    var
        PermissionConflictsPage: Page "Permission Conflicts";
    begin
        PermissionConflictsPage.SetPermissionSetId(PermissionSetID);
        PermissionConflictsPage.SetEntitlementId(PlanOrRole);
        PermissionConflictsPage.Run();
    end;

    local procedure MarkUsersWithAssignedPermissionSet(var User: Record User; PermissionSetID: Code[20])
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("Role ID", PermissionSetID);
        if AccessControl.FindSet then
            repeat
                if User.Get(AccessControl."User Security ID") then
                    User.Mark(true);
            until AccessControl.Next = 0;

        User.MarkedOnly(true);
    end;

    local procedure GetPermissionChangeNotificationId(): Guid
    begin
        exit('7E18A509-6579-471A-BF8D-4A9BDABB6008');
    end;

    [EventSubscriber(ObjectType::Page, 1518, 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetPermissionChangeNotificationId, ChangeAffectsOthersNameTxt, ChangeAffectsOthersDescTxt, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTenantPermissionModified(PermissionSetId: Code[20])
    begin
    end;
}

