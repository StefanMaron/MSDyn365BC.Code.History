codeunit 9002 "Permission Manager"
{
#if not CLEAN22
    Permissions = TableData "User Group Member" = rid, // Do not add m so the check UserGroupMember.WritePermission() would be false unless the user has direct access
                  TableData "User Group Plan" = rimd;
#endif
    SingleInstance = true;

    var
        OfficePortalUserAdministrationUrlTxt: Label 'https://portal.office.com/admin/default.aspx#ActiveUsersPage', Locked = true;
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
        LocalTok: Label 'LOCAL', Locked = true;
        EnvironmentInfo: Codeunit "Environment Information";
        TestabilityIntelligentCloud: Boolean;
        CannotModifyOtherUsersErr: Label 'You cannot change settings for another user.';
        FoundProfileFromPlanTxt: Label 'Found default profile from plan: %1.', Locked = true;
        NoProfileFromPlanTxt: Label 'No profile could be determined from user plans, picking system wide defaults.', Locked = true;
        TelemetryCategoryTxt: Label 'AL Perm Mgr', Locked = true;
        PlanConfigurationFeatureNameTxt: Label 'Custom Permissions Assignment Per Plan', Locked = true;

    procedure AssignDefaultPermissionsToUser(UserSecurityID: Guid): Boolean
    var
        Company: Text[30];
    begin
        Company := CopyStr(CompanyName(), 1, 30);
        exit(AssignDefaultPermissionsToUser(UserSecurityID, Company));
    end;

    procedure AssignDefaultPermissionsToUser(UserSecurityID: Guid; Company: Text[30]) PermissionsAdded: Boolean
    var
        PlanConfiguration: Codeunit "Plan Configuration";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        UsersInPlans: Query "Users in Plans";
    begin
        // If intelligent cloud is enabled, then assign the intelligent cloud permissions
        if IsIntelligentCloud() then begin
#if not CLEAN22
            AddUserToUserGroup(UserSecurityID, IntelligentCloudTok, Company);
#else
            AddPermissionSetToUser(UserSecurityID, IntelligentCloudTok, Company);
#endif
            PermissionsAdded := true;
            exit;
        end;

        // No plan is assigned to this user
        UsersInPlans.SetRange(User_Security_ID, UserSecurityID);
        if not UsersInPlans.Open() then begin
            PermissionsAdded := false;
            exit;
        end;

        // There is at least a plan assigned (and probably only one)
        while UsersInPlans.Read() do
            if PlanConfiguration.IsCustomized(UsersInPlans.Plan_ID) then begin
                FeatureTelemetry.LogUptake('0000HSP', PlanConfigurationFeatureNameTxt, Enum::"Feature Uptake Status"::Used);
#if not CLEAN22
                OnAssignCustomPermissionsToUser(UserSecurityID, UsersInPlans.Plan_ID, PermissionsAdded);
#endif
                PlanConfiguration.AssignCustomPermissionsToUser(UsersInPlans.Plan_ID, UserSecurityID);
                PermissionsAdded := true;
            end else begin
#if not CLEAN22
                AssignDefaultPermissionsOfThePlanToUser(UserSecurityID, UsersInPlans.Plan_ID, Company);
#endif
                PlanConfiguration.AssignDefaultPermissionsToUser(UsersInPlans.Plan_ID, UserSecurityID, Company);
                PermissionsAdded := true;
            end;
    end;

#if not CLEAN22
    local procedure AssignDefaultPermissionsOfThePlanToUser(UserSecurityID: Guid; PlanID: Guid; Company: Text[30]): Boolean
    var
        UserGroupPlan: Record "User Group Plan";
    begin
        // Get all User Groups in plan
        UserGroupPlan.SetRange("Plan ID", PlanID);
        if not UserGroupPlan.FindSet() then
            exit(false); // nothing to add

        // Assign groups to the current user (if not assigned already)
        repeat
            AddUserToUserGroup(UserSecurityID, UserGroupPlan."User Group Code", Company);
        until UserGroupPlan.Next() = 0;

        exit(true);
    end;
#endif

    procedure ResetUserToDefaultPermissions(UserSecurityID: Guid)
    begin
#if not CLEAN22
        // Remove the user from all assigned user groups and their related permission sets
        RemoveUserFromAllUserGroups(UserSecurityID);
#endif
        // Remove the user from any additional, manually assigned permission sets
        RemoveAllPermissionSetsFromUser(UserSecurityID);

        // Assign all permission sets associated with user's plans
        AssignDefaultPermissionsToUser(UserSecurityID);
    end;

    local procedure RemoveAllPermissionSetsFromUser(UserSecurityID: Guid)
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityID);
        AccessControl.DeleteAll(true);
    end;

#if not CLEAN22
    [Obsolete('User groups are replaced with security groups, where group membership is specified in M365 admin portal.', '22.0')]
    procedure AddUserToUserGroup(UserSecurityID: Guid; UserGroupCode: Code[20]; Company: Text[30])
    var
        UserGroupMember: Record "User Group Member";
    begin
        if not UserGroupMember.Get(UserGroupCode, UserSecurityID, Company) then begin
            UserGroupMember.Init();
            UserGroupMember."Company Name" := Company;
            UserGroupMember."User Security ID" := UserSecurityID;
            UserGroupMember."User Group Code" := UserGroupCode;
            UserGroupMember.Insert(true);
        end;
    end;

    [Obsolete('Replaced with the AssignDefaultPermissionsToUser procedure.', '22.0')]
    procedure AddUserToDefaultUserGroups(UserSecurityID: Guid): Boolean
    begin
        exit(AssignDefaultPermissionsToUser(UserSecurityID));
    end;

    [Obsolete('Replaced with the AssignDefaultPermissionsToUser procedure.', '22.0')]
    procedure AddUserToDefaultUserGroupsForCompany(UserSecurityID: Guid; Company: Text[30]) PermissionsAdded: Boolean
    begin
        exit(AssignDefaultPermissionsToUser(UserSecurityID, Company));
    end;

    local procedure RemoveUserFromAllUserGroups(UserSecurityID: Guid)
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Security ID", UserSecurityID);
        UserGroupMember.DeleteAll(true);
    end;

    [Obsolete('Replaced with the ResetUserToDefaultPermissions procedure.', '22.0')]
    procedure ResetUserToDefaultUserGroups(UserSecurityID: Guid)
    begin
        ResetUserToDefaultPermissions(UserSecurityID);
    end;
#endif

    procedure GetOfficePortalUserAdminUrl(): Text
    begin
        exit(OfficePortalUserAdministrationUrlTxt);
    end;

    procedure UpdateUserAccessForSaaS(UserSID: Guid) UserGroupsAdded: Boolean
    begin
        if not AllowUpdateUserAccessForSaaS(UserSID) then
            exit;

        if AssignDefaultPermissionsToUser(UserSID) then begin
            AssignDefaultRoleCenterToUser(UserSID);
            UserGroupsAdded := true;
        end;
    end;

    local procedure AllowUpdateUserAccessForSaaS(UserSID: Guid): Boolean
    var
        User: Record User;
        Plan: Query Plan;
        UsersInPlans: Query "Users in Plans";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit(false);

        if IsNullGuid(UserSID) then
            exit(false);

        // Don't demote external users (like the sync daemon) and AAD groups
        User.Get(UserSID);
        if User."License Type" in [User."License Type"::"External User", User."License Type"::"AAD Group"] then
            exit(false);

        // Don't demote users which don't come from Office365 (have no plans assigned)
        // Note: all users who come from O365, if they don't have a plan, they don't get a license (hence, no SUPER role)

        UsersInPlans.SetFilter(User_Security_ID, User."User Security ID");
        if not UsersInPlans.Open() then
            exit(false);

        // Don't demote users that have an invalid plan(likely coming from 1.5)
        while UsersInPlans.Read() do begin
            Plan.SetFilter(Plan_ID, UsersInPlans.Plan_ID);
            if not Plan.Open() then
                exit(false);
            Plan.Read();
            if Plan.Role_Center_ID = 0 then
                exit(false);
            Plan.Close();
        end;

        exit(true);
    end;

#if not CLEAN22
    [Obsolete('User groups are replaced with security groups, use the method Add on the Security Group codeunit.', '22.0')]
    procedure AddUserGroupFromExtension(UserGroupCode: Code[20]; RoleID: Code[20]; AppGuid: Guid)
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroup: Record "User Group";
    begin
        if not EnvironmentInfo.IsSaaS() then
            if not UserGroup.Get(UserGroupCode) then
                exit;

        UserGroupPermissionSet.Init();
        UserGroupPermissionSet."User Group Code" := UserGroupCode;
        UserGroupPermissionSet."Role ID" := RoleID;
        UserGroupPermissionSet."App ID" := AppGuid;
        UserGroupPermissionSet.Scope := UserGroupPermissionSet.Scope::Tenant;
        if not UserGroupPermissionSet.Find() then
            UserGroupPermissionSet.Insert(true);
    end;
#endif

    local procedure AssignDefaultRoleCenterToUser(UserSecurityID: Guid)
    var
        UserPersonalization: Record "User Personalization";
        AllProfile: Record "All Profile";
        UsersInPlans: Query "Users in Plans";
        Plan: Query Plan;
        IsAllProfileFiltered: Boolean;
    begin
        UsersInPlans.SetRange(User_Security_ID, UserSecurityID);
        if not UsersInPlans.Open() then
            exit; // this user has no plans assigned, so they'll get the app-wide default role center
        UsersInPlans.Read();

        Plan.SetRange(Plan_ID, UsersInPlans.Plan_ID);
        Plan.Open();
        Plan.Read();

        if Plan.Role_Center_ID = Page::"Business Manager Role Center" then
            FilterProfileToBusinessManagerEvaluationForCronus(AllProfile, IsAllProfileFiltered)
        else
            AllProfile.SetRange("Role Center ID", Plan.Role_Center_ID);

        if not AllProfile.FindFirst() then
            exit; // the plan does not have a role center, so they'll get the app-wide default role center

        // Create the user personalization record
        if not UserPersonalization.Get(UserSecurityID) then begin
            UserPersonalization.Init();
            UserPersonalization.Validate("User SID", UserSecurityID);
            UserPersonalization.Validate("Profile ID", AllProfile."Profile ID");
            UserPersonalization.Validate("App ID", AllProfile."App ID");
            UserPersonalization.Validate(Scope, AllProfile.Scope);
            UserPersonalization.Insert();
        end else
            if IsAllProfileFiltered then begin
                UserPersonalization.Validate("Profile ID", AllProfile."Profile ID");
                UserPersonalization.Validate("App ID", AllProfile."App ID");
                UserPersonalization.Validate(Scope, AllProfile.Scope);
                UserPersonalization.Modify();
            end;
    end;

    /// <summary>
    /// This procedure retrieves a Default Profile ID to be used for a user, in case there is no valid 
    /// custom profile set for them in their User Personalization. 
    /// </summary>
    /// <param name="UserSecurityID">The SID for the User to find a default profile for</param>
    /// <param name="AllProfile">The returned AllProfile that is the default for the specified user</param>
    /// <remarks>
    /// <list type="number">
    ///   <item><description>If we can provide a tailored default for the user (from the Plan/License), return that, otherwise</description></item>
    ///   <item><description>If there is any system-wide default AllProfile in the table, return it, otherwise</description></item>
    ///   <item><description>Find the default Role Center ID for the system (which checks the Plan/License again and has some additional 
    ///   defaulting logic), and if there is a profile for it return it, otherwise</description></item>
    ///   <item><description>Fall back to just return the first AllProfile available in the table</description></item>
    /// </list>
    /// </remarks>
    [Scope('OnPrem')]
    procedure GetDefaultProfileID(UserSecurityID: Guid; var AllProfile: Record "All Profile")
    var
        UsersInPlans: Query "Users in Plans";
        Plan: Query Plan;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        UsersInPlans.SetRange(User_Security_ID, UserSecurityID);
        if UsersInPlans.Open() then
            while UsersInPlans.Read() do begin
                // NOTE: if in the future we support multiple plans per user, we need here to specify which plan to choose
                Plan.SetFilter(Plan_ID, UsersInPlans.Plan_ID);
                if Plan.Open() then
                    if Plan.Read() then begin
                        AllProfile.SetRange("Role Center ID", Plan.Role_Center_ID);
                        if AllProfile.FindFirst() then begin
                            Session.LogMessage('0000DUK', StrSubstNo(FoundProfileFromPlanTxt, AllProfile."Profile ID"), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
                            exit;
                        end;
                    end;

                Clear(Plan);
            end;

        Session.LogMessage('0000DUL', NoProfileFromPlanTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);

        AllProfile.Reset();
        AllProfile.SetRange("Default Role Center", true);
        if AllProfile.FindFirst() then
            exit;

        AllProfile.Reset();
        AllProfile.SetRange("Role Center ID", ConfPersonalizationMgt.DefaultRoleCenterID());
        if AllProfile.FindFirst() then
            exit;

        AllProfile.Reset();
        if AllProfile.FindFirst() then
            exit;
    end;

    procedure CanCurrentUserManagePlansAndGroups(): Boolean
    var
        AccessControl: Record "Access Control";
#if not CLEAN22
        UserGroupMember: Record "User Group Member";
        UserGroupAccessControl: Record "User Group Access Control";
        UserGroupPermissionSet: Record "User Group Permission Set";
#endif
    begin
#if not CLEAN22
        exit(
          UserGroupMember.WritePermission and
          AccessControl.WritePermission and UserGroupAccessControl.WritePermission and
          UserGroupPermissionSet.WritePermission);
#else
        exit(AccessControl.WritePermission());
#endif
    end;

    procedure GenerateHashForPermissionSet(PermissionSetId: Code[20]): Text[250]
    var
        Permission: Record Permission;
        CryptographyManagement: Codeunit "Cryptography Management";
        InputText: Text;
        ObjectType: Integer;
    begin
        InputText += PermissionSetId;
        Permission.SetRange("Role ID", PermissionSetId);
        if Permission.FindSet() then
            repeat
                ObjectType := Permission."Object Type";
                InputText += Format(ObjectType);
                InputText += Format(Permission."Object ID");
                if ObjectType = Permission."Object Type"::"Table Data" then begin
                    InputText += GetCharRepresentationOfPermission(Permission."Read Permission");
                    InputText += GetCharRepresentationOfPermission(Permission."Insert Permission");
                    InputText += GetCharRepresentationOfPermission(Permission."Modify Permission");
                    InputText += GetCharRepresentationOfPermission(Permission."Delete Permission");
                end else
                    InputText += GetCharRepresentationOfPermission(Permission."Execute Permission");
                InputText += Format(Permission."Security Filter", 0, 9);
            until Permission.Next() = 0;

        exit(CopyStr(CryptographyManagement.GenerateHash(InputText, 2), 1, 250)); // 2 corresponds to SHA256
    end;

    local procedure FilterProfileToBusinessManagerEvaluationForCronus(var AllProfile: Record "All Profile"; var IsFiltered: Boolean)
    var
        Company: Record Company;
    begin
        if Company.Get(CompanyName()) then
            if Company."Evaluation Company" then
                if Company.Name.ToLower().StartsWith('cronus') then begin
                    AllProfile.SetRange("Profile ID", 'Business Manager Evaluation');
                    IsFiltered := true;
                end;
    end;

    local procedure GetCharRepresentationOfPermission(PermissionOption: Integer): Text[1]
    begin
        exit(StrSubstNo('%1', PermissionOption));
    end;

    procedure IsFirstPermissionHigherThanSecond(First: Option; Second: Option): Boolean
    var
        Permission: Record Permission;
    begin
        case First of
            Permission."Read Permission"::" ":
                exit(false);
            Permission."Read Permission"::Indirect:
                exit(Second = Permission."Read Permission"::" ");
            Permission."Read Permission"::Yes:
                exit(Second in [Permission."Read Permission"::Indirect, Permission."Read Permission"::" "]);
        end;
    end;

#if not CLEAN22
    [Obsolete('Use the ResetUsersToIntelligentCloud procedure instead.', '22.0')]
    procedure ResetUsersToIntelligentCloudUserGroup()
    begin
        ResetUsersToIntelligentCloudPermissions();
    end;
#endif

    procedure ResetUsersToIntelligentCloudPermissions()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        IntelligentCloud: Record "Intelligent Cloud";
        UserPermissions: Codeunit "User Permissions";
        UserSelection: Codeunit "User Selection";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        if not IntelligentCloud.Get() then
            exit;

        if IntelligentCloud.Enabled then begin
            UserSelection.FilterSystemUserAndAADGroupUsers(User);
            User.SetFilter("Windows Security ID", '=''''');

            if User.Count = 0 then
                exit;

            repeat
                if not UserPermissions.IsSuper(User."User Security ID") and not IsNullGuid(User."User Security ID") then begin
                    AccessControl.SetRange("User Security ID", User."User Security ID");
                    if AccessControl.FindSet() then
                        repeat
                            RemoveExistingPermissionsAndAddIntelligentCloud(AccessControl."User Security ID", AccessControl."Company Name");
                        until AccessControl.Next() = 0;
                end;
            until User.Next() = 0;
        end;
    end;

    procedure IsIntelligentCloud(): Boolean
    var
        IntelligentCloud: Record "Intelligent Cloud";
    begin
        if TestabilityIntelligentCloud then
            exit(true);

        if IntelligentCloud.Get() then
            exit(IntelligentCloud.Enabled);
    end;

    local procedure RemoveExistingPermissionsAndAddIntelligentCloud(UserSecurityID: Guid; CompanyName: Text[30])
    var
        AccessControl: Record "Access Control";
#if not CLEAN22
        UserGroupMember: Record "User Group Member";
#endif
    begin
        // Remove User from all Permission Sets for the company
        AccessControl.SetRange("User Security ID", UserSecurityID);
        AccessControl.SetRange("Company Name", CompanyName);
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetFilter("Role ID", '<>%1', IntelligentCloudTok);
        AccessControl.SetFilter("Role ID", '<>%1', LocalTok);
        AccessControl.DeleteAll(true);

#if not CLEAN22
        // Remove User from all User Groups for the company
        UserGroupMember.SetRange("User Security ID", UserSecurityID);
        UserGroupMember.SetRange("Company Name", CompanyName);
        UserGroupMember.SetFilter("User Group Code", '<>%1', IntelligentCloudTok);
        if not UserGroupMember.IsEmpty() then begin
            UserGroupMember.DeleteAll(true);
            AddUserToUserGroup(UserSecurityID, IntelligentCloudTok, CompanyName)
        end else
            AddPermissionSetToUser(UserSecurityID, IntelligentCloudTok, CompanyName);
#else
        AddPermissionSetToUser(UserSecurityID, IntelligentCloudTok, CompanyName);
#endif
    end;

    procedure SetTestabilityIntelligentCloud(EnableIntelligentCloudForTest: Boolean)
    begin
        TestabilityIntelligentCloud := EnableIntelligentCloudForTest;
    end;

    local procedure AddPermissionSetToUser(UserSecurityID: Guid; RoleID: Code[20]; Company: Text[30])
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityID);
        AccessControl.SetRange("Role ID", RoleID);
        AccessControl.SetRange("Company Name", Company);

        if not AccessControl.IsEmpty() then
            exit;

        AccessControl.Init();
        AccessControl."Company Name" := Company;
        AccessControl."User Security ID" := UserSecurityID;
        AccessControl."Role ID" := RoleID;
        AccessControl.Insert(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnBeforeModifyEvent', '', true, true)]
    procedure CheckCurrentUserCanModifyUser(var Rec: Record User; var xRec: Record user; RunTrigger: Boolean)
    var
        LoggedInUser: Record User;
        UserPermissions: Codeunit "User Permissions";
        CurrentUserSecurityId: Guid;
    begin
        if Rec.IsTemporary() then
            exit;

        Rec.TestField("User Name");
        CurrentUserSecurityId := UserSecurityId();
        if not LoggedInUser.Get(CurrentUserSecurityId) then // Current user is Super from when there were no users in the system
            exit;
        if LoggedInUser."User Security ID" = Rec."User Security ID" then
            exit;
        if not UserPermissions.CanManageUsersOnTenant(CurrentUserSecurityId) then
            Error(CannotModifyOtherUsersErr);
    end;

#if not CLEAN22
    [Obsolete('Custom permissions are handled within BaseApp and System Application.', '22.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAssignCustomPermissionsToUser(UserSecurityID: Guid; PlanId: Guid; var PermissionsAssigned: Boolean)
    begin
    end;
#endif
}

