// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 9018 "Azure AD Plan Impl."
{
    Access = Internal;

    Permissions = TableData Plan = rimd,
                  TableData "User Plan" = rimd,
                  TableData User = rimd,
                  TableData "Membership Entitlement" = rimd;

    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
        AzureADGraph: Codeunit "Azure AD Graph";
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        IsTest: Boolean;
        UserSetupCategoryTxt: Label 'User Setup', Locked = true;
        DeviceGroupNameTxt: Label 'Dynamics 365 Business Central Device Users', Locked = true;
        DevicePlanFoundMsg: Label 'Device plan %1 found for user %2', Locked = true;
        NotBCUserMsg: Label 'User %1 is not a Business Central user', Locked = true;
        MixedPlansNonAdminErr: Label 'All users must be assigned to the same license, either Basic, Essential, or Premium. %1 and %2 are assigned to different licenses, for example, but there may be other mismatches. Your system administrator or Microsoft partner can verify license assignments in your Microsoft 365 admin portal.\\We will sign you out when you choose the OK button.', Comment = '%1 = %2 = Authnetication email.';
        MixedPlansAdminErr: Label 'Before you can update user information, go to your Microsoft 365 admin center and make sure that all users are assigned to the same Business Central license, either Basic, Essential, or Premium. For example, we found that users %1 and %2 are assigned to different licenses, but there may be other mismatches.', Comment = '%1 = %2 = Authnetication email.';
        MixedPlansMsg: Label 'One or more users are not assigned to the same Business Central license. For example, we found that users %1 and %2 are assigned to different licenses, but there may be other mismatches. In your Microsoft 365 admin center, make sure that all users are assigned to the same Business Central license, either Basic, Essential, or Premium.  Afterward, update Business Central by opening the Users page and using the ''Update Users from Office 365'' action.', Comment = '%1 = %2 = Authnetication email.';
        UserPlanAssignedMsg: Label 'User %1 is assigned plan %2', Locked = true;
        UserHasNoPlansMsg: Label 'User %1 has no Business Central plans assigned', Locked = true;
        DeviceUserCannotBeFirstUserErr: Label 'The device user cannot be the first user to log into the system.';
        UserGotPlanTxt: Label 'The Graph User with the authentication email %1 has a plan with ID %2 named %3.', Comment = '%1 = Authentication email (email); %2 = subscription plan ID (guid); %3 = Plan name (tex1t)', Locked = true;
        PlansDifferentCheckTxt: Label 'Checking if plans different for graph user with authentication email %1 and BC user with security ID %2.', Comment = '%1 = Authentication email (email); %2 = user security ID (guid)', Locked = true;
        PlanCountDifferentTxt: Label 'The count of plans in BC is %1 and count of plans in Graph is %2.', Locked = true;
        GraphUserHasExtraPlanTxt: Label 'Graph user has plan with ID %1 and named %2 that BC user does not have.', Locked = true, Comment = '%1 = Plan ID (guid); %2 = Plan name';
        MixedPlansExistTxt: Label 'Check for mixed plans. Basic plan exists: %1, Essentials plan exists: %2; Premium plan exists: %3.', Locked = true;
        UsersWithMixedPlansTxt: Label 'Check for mixed plans. First conflicting user: [%1], second conflicting user [%3].', Locked = true;
        CheckingForMixedPlansTxt: Label 'Checking for mixed plans...', Locked = true;

    procedure IsPlanAssigned(PlanGUID: Guid): Boolean
    var
        UsersInPlans: Query "Users in Plans";
    begin
        UsersInPlans.SetRange(User_State, UsersInPlans.User_State::Enabled);
        UsersInPlans.SetRange(Plan_ID, PlanGUID);

        if UsersInPlans.Open() then
            exit(UsersInPlans.Read());
    end;

    procedure IsPlanAssignedToUser(PlanGUID: Guid): Boolean
    begin
        exit(IsPlanAssignedToUser(PlanGUID, UserSecurityId()));
    end;

    procedure IsPlanAssignedToUser(PlanGUID: Guid; UserGUID: Guid): Boolean
    var
        UserPlan: Record "User Plan";
    begin
        UserPlan.SetRange("User Security ID", UserGUID);
        UserPlan.SetRange("Plan ID", PlanGUID);
        exit(not UserPlan.IsEmpty());
    end;

    procedure IsGraphUserEntitledFromServicePlan(var GraphUser: DotNet UserInfo): Boolean
    var
        AssignedPlan: DotNet ServicePlanInfo;
        ServicePlanIdValue: Variant;
    begin
        if not IsNull(GraphUser.AssignedPlans()) then
            foreach AssignedPlan IN GraphUser.AssignedPlans() do
                if Format(AssignedPlan.CapabilityStatus()) = 'Enabled' then begin
                    ServicePlanIdValue := AssignedPlan.ServicePlanId();
                    if IsBCServicePlan(ServicePlanIdValue) then
                        exit(TRUE);
                end;

        if IsDeviceRole(GraphUser) then
            exit(true);

        exit(FALSE);
    end;

    procedure UpdateUserPlans(UserSecurityId: Guid; var GraphUser: DotNet UserInfo; AppendPermissionsOnNewPlan: Boolean; RemoveUserGroupsOnDeletePlan: Boolean)
    var
        TempPlan: Record Plan temporary;
        UserPlan: Record "User Plan";
        HasUserBeenSetupBefore: Boolean;
    begin
        GetGraphUserPlans(TempPlan, GraphUser);

        // Has the user been setup earlier?
        UserPlan.SetRange("User Security ID", UserSecurityId);
        HasUserBeenSetupBefore := not (UserPlan.IsEmpty() and UserLoginTimeTracker.IsFirstLogin(UserSecurityId));

        // Have any plans been removed from this user in O365, since last time he logged-in to NAV?
        RemoveUnassignedUserPlans(TempPlan, UserSecurityId, RemoveUserGroupsOnDeletePlan);

        // Have any plans been added to this user in O365, since last time he logged-in to NAV?
        AddNewlyAssignedUserPlans(TempPlan, UserSecurityId, HasUserBeenSetupBefore, AppendPermissionsOnNewPlan);
    end;

    procedure UpdateUserPlans(UserSecurityId: Guid; AppendPermissionsOnNewPlan: Boolean; RemoveUserGroupsOnDeletePlan: Boolean)
    var
        GraphUser: DotNet UserInfo;
    begin
        if AzureADGraphUser.GetGraphUser(UserSecurityID, true, GraphUser) then
            UpdateUserPlans(UserSecurityId, GraphUser, AppendPermissionsOnNewPlan, RemoveUserGroupsOnDeletePlan);
    end;

    procedure UpdateUserPlans()
    var
        User: Record User;
    begin
        User.SetFilter("License Type", '<>%1', User."License Type"::"External User");
        User.SetFilter("Windows Security ID", '%1', '');

        if not User.FindSet() then
            exit;

        repeat
            UpdateUserPlans(User."User Security ID", true, true);
        until User.Next() = 0;
    end;

    procedure RefreshUserPlanAssignments(UserSecurityID: Guid)
    var
        User: Record User;
        UsersInPlan: Query "Users in Plans";
        GraphUser: DotNet UserInfo;
        UserPlanExists: Boolean;
    begin
        if not User.GET(UserSecurityID) then
            exit;

        if not AzureADGraphUser.GetGraphUser(UserSecurityID, GraphUser) then
            exit;

        // Is this the first user being setup
        if UsersInPlan.Open() then
            if UsersInPlan.Read() then
                UserPlanExists := true;

        if not UserPlanExists then
            if IsDeviceRole(GraphUser) then
                Error(DeviceUserCannotBeFirstUserErr);

        UpdateUserFromAzureGraph(User, GraphUser);
        UpdateUserPlans(User."User Security ID", GraphUser, true, true);
    end;

    [TryFunction]
    procedure TryGetAzureUserPlanRoleCenterId(var RoleCenterID: Integer; UserSecurityID: Guid)
    begin
        RoleCenterID := GetAzureUserPlanRoleCenterId(UserSecurityID);
    end;

    procedure DoPlansExist(): Boolean
    var
        Plan: Record Plan;
    begin
        exit(not Plan.IsEmpty());
    end;

    procedure DoUserPlansExist(): Boolean
    var
        UserPlan: Record "User Plan";
    begin
        exit(not UserPlan.IsEmpty());
    end;

    procedure DoesPlanExist(PlanGUID: Guid): Boolean
    var
        Plan: Record Plan;
    begin
        exit(Plan.Get(PlanGUID));
    end;

    procedure DoesUserHavePlans(UserSecurityId: Guid): Boolean
    var
        UserPlan: Record "User Plan";
    begin
        UserPlan.SetRange("User Security ID", UserSecurityId);
        exit(not UserPlan.IsEmpty());
    end;

    procedure GetAvailablePlansCount(): Integer
    var
        Plan: Record Plan;
    begin
        exit(Plan.Count());
    end;

    procedure SetTestInProgress(EnableTestability: Boolean)
    begin
        IsTest := EnableTestability;
        AzureADGraph.SetTestInProgress(EnableTestability);
        AzureADGraphUser.SetTestInProgress(EnableTestability);
    end;

    procedure CheckMixedPlans()
    var
        DummyDictionary: Dictionary of [Text, List of [Text]];
    begin
        CheckMixedPlans(DummyDictionary, false);
    end;

    procedure CheckMixedPlans(PlanNamesPerUserFromGraph: Dictionary of [Text, List of [Text]]; ErrorOutForAdmin: Boolean)
    var
        Company: Record Company;
        AzureADPlan: Codeunit "Azure AD Plan";
        EnvironmentInfo: Codeunit "Environment Information";
        CanManageUsers: Boolean;
        UserAuthenticationEmailFirst: Text;
        UserAuthenticationEmailSecond: Text;
        FirstConflictingPlanName: Text;
        SecondConflictingPlanName: Text;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;


        if not GuiAllowed() then
            exit;

        if Company.Get(CompanyName()) then
            if Company."Evaluation Company" then
                exit;

        if not DoPlansExist() then
            exit;

        if not DoUserPlansExist() then
            exit;

        SendTraceTag('0000BPB', UserSetupCategoryTxt, Verbosity::Normal, CheckingForMixedPlansTxt, DataClassification::SystemMetadata);
        if not MixedPlansExist(PlanNamesPerUserFromGraph, UserAuthenticationEmailFirst, UserAuthenticationEmailSecond, FirstConflictingPlanName, SecondConflictingPlanName) then
            exit;

        AzureADPlan.OnCanCurrentUserManagePlansAndGroups(CanManageUsers);
        if not CanManageUsers then
            Error(MixedPlansNonAdminErr, UserAuthenticationEmailFirst, UserAuthenticationEmailSecond);

        if ErrorOutForAdmin then
            Error(MixedPlansAdminErr, UserAuthenticationEmailFirst, UserAuthenticationEmailSecond);

        Message(MixedPlansMsg, UserAuthenticationEmailFirst, UserAuthenticationEmailSecond);
    end;

    procedure MixedPlansExist(): Boolean
    var
        EmptyDictionary: Dictionary of [Text, List of [Text]];
        FirstConflictingID: Text;
        SecondConflictingID: Text;
        FirstConflictingPlanName: Text;
        SecondConflictingPlanName: Text;
    begin
        exit(MixedPlansExist(EmptyDictionary, FirstConflictingID, SecondConflictingID, FirstConflictingPlanName, SecondConflictingPlanName));
    end;

    procedure MixedPlansExist(PlanNamesPerUserFromGraph: Dictionary of [Text, List of [Text]]; var UserAuthenticationEmailFirstConflicting: Text; var UserAuthenticationEmailSecondConflicting: Text; var FirstConflictingPlanName: Text; var SecondConflictingPlanName: Text): Boolean
    var
        PlanIds: Codeunit "Plan Ids";
        UsersInPlans: Query "Users in Plans";
        PlanNamesPerUser: Dictionary of [Text, List of [Text]];
        AuthenticationObjectIDs: List of [Text];
        BasicPlanExists: Boolean;
        EssentialsPlanExists: Boolean;
        PremiumPlanExists: Boolean;
        PlanNames: List of [Text];
        UserAuthenticationObjectId: Text;
        CurrentUserPlanList: List of [Text];
    begin
        // Get content of the User plan table into a new Dictionary
        UsersInPlans.SetRange(User_State, UsersInPlans.User_State::Enabled);
        if UsersInPlans.Open() then
            while UsersInPlans.Read() do begin
                UserAuthenticationObjectId := AzureADGraphUser.GetUserAuthenticationObjectId(UsersInPlans.User_Security_ID);
                if UserAuthenticationObjectId <> '' then begin
                    Clear(CurrentUserPlanList);
                    if PlanNamesPerUser.ContainsKey(UserAuthenticationObjectId) then
                        CurrentUserPlanList := PlanNamesPerUser.Get(UserAuthenticationObjectId);
                    CurrentUserPlanList.Add(UsersInPlans.Plan_Name);
                    PlanNamesPerUser.Set(UserAuthenticationObjectId, CurrentUserPlanList);
                end;
            end;

        // update the dictionary with the values from input
        foreach UserAuthenticationObjectId in PlanNamesPerUserFromGraph.Keys do
            PlanNamesPerUser.Set(UserAuthenticationObjectId, PlanNamesPerUserFromGraph.Get(UserAuthenticationObjectId));

        BasicPlanExists := PlansExist(PlanNamesPerUser, PlanIds.GetBasicPlanId(), AuthenticationObjectIDs, PlanNames);
        EssentialsPlanExists := PlansExist(PlanNamesPerUser, PlanIds.GetEssentialPlanId(), AuthenticationObjectIDs, PlanNames);
        PremiumPlanExists := PlansExist(PlanNamesPerUser, PlanIds.GetPremiumPlanId(), AuthenticationObjectIDs, PlanNames);

        SendTraceTag('0000BPC', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(MixedPlansExistTxt, BasicPlanExists, EssentialsPlanExists, PremiumPlanExists), DataClassification::SystemMetadata);

        if PlanNames.Count() > 1 then begin
            UserAuthenticationEmailFirstConflicting := GetAuthenticationEmailFromAuthenticationObjectID(AuthenticationObjectIDs.Get(1));
            UserAuthenticationEmailSecondConflicting := GetAuthenticationEmailFromAuthenticationObjectID(AuthenticationObjectIDs.Get(2));
            FirstConflictingPlanName := PlanNames.Get(1);
            SecondConflictingPlanName := PlanNames.Get(2);
            SendTraceTag('0000BPD', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(UsersWithMixedPlansTxt, UserAuthenticationEmailFirstConflicting, UserAuthenticationEmailSecondConflicting), DataClassification::EndUserIdentifiableInformation);
            exit(true);
        end;
    end;

    local procedure GetAuthenticationEmailFromAuthenticationObjectID(UserAuthenticationObjectID: Text): Text
    var
        User: Record User;
        GraphUser: DotNet UserInfo;
    begin
        if AzureADGraphUser.GetUser(UserAuthenticationObjectID, User) then
            exit(User."Authentication Email")
        else begin
            AzureADGraph.GetUserByObjectId(UserAuthenticationObjectID, GraphUser);
            exit(AzureADGraphUser.GetAuthenticationEmail(GraphUser));
        end;
    end;

    local procedure PlansExist(var PlanNamesPerUser: Dictionary of [Text, List of [Text]]; PlanId: Guid; var AuthenticationObjectIDs: List of [Text]; var PlanNames: List of [Text]): Boolean
    var
        Plan: Record Plan;
        CurrentAuthenticationObjectId: Text;
        PlanNameList: List of [Text];
    begin
        Plan.Get(PlanId);
        foreach CurrentAuthenticationObjectId in PlanNamesPerUser.Keys() do begin
            PlanNameList := PlanNamesPerUser.Get(CurrentAuthenticationObjectId);
            if PlanNameList.Contains(Plan.Name) then begin
                AuthenticationObjectIDs.Add(CurrentAuthenticationObjectId);
                PlanNames.Add(Plan.Name);
                exit(true);
            end;
        end;
    end;

    local procedure RemoveUnassignedUserPlans(var TempPlan: Record Plan temporary; UserSecurityID: Guid; RemoveUserGroupsOnDeletePlan: Boolean)
    var
        NavUserPlan: Record "User Plan";
        TempNavUserPlan: Record "User Plan" temporary;
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        // Have any plans been removed from this user in O365, since last time he logged-in to Business Central?

        // Get all plans assigned to the user, in NAV
        NavUserPlan.SetRange("User Security ID", UserSecurityID);
        if not NavUserPlan.FindSet() then
            exit;

        repeat
            TempNavUserPlan.COPY(NavUserPlan, FALSE);
            TempNavUserPlan.Insert();
        until NavUserPlan.Next() = 0;

        // Get all plans assigned to the user in Office
        if TempPlan.FindSet() then
            // And remove them from the list of plans assigned to the user
            repeat
                TempNavUserPlan.SetRange("Plan ID", TempPlan."Plan ID");
                if not TempNavUserPlan.IsEmpty() then
                    TempNavUserPlan.DeleteAll();
            until TempPlan.Next() = 0;

        // if any plans belong to the user in NAV, but not in Office, de-assign them
        TempNavUserPlan.SetRange("Plan ID");
        if TempNavUserPlan.FindSet() then
            repeat
                NavUserPlan.SetRange("Plan ID", TempNavUserPlan."Plan ID");
                if NavUserPlan.FindFirst() then begin
                    NavUserPlan.LockTable();
                    NavUserPlan.Delete();
                    if RemoveUserGroupsOnDeletePlan then
                        AzureADPlan.OnRemoveUserGroupsForUserAndPlan(NavUserPlan."Plan ID", NavUserPlan."User Security ID");
                    if not IsTest then
                        Commit(); // Finalize the transaction. Else any further error can rollback and create elevation of privilege
                end;
            until TempNavUserPlan.Next() = 0;
    end;

    local procedure GetGraphUserPlans(var TempPlan: Record "Plan" temporary; var GraphUser: DotNet UserInfo)
    var
        AssignedPlan: DotNet ServicePlanInfo;
        DirectoryRole: DotNet RoleInfo;
        ServicePlanIdValue: Variant;
        HaveAssignedPlans: Boolean;
        DevicesPlanId: Guid;
        DevicesPlanName: Text;
        SystemRoleAdded: Boolean;

    begin
        TempPlan.Reset();
        TempPlan.DeleteAll();

        // Loop through assigned Azure AD Plans
        if not IsNull(GraphUser.AssignedPlans()) then
            foreach AssignedPlan in GraphUser.AssignedPlans() do
                if Format(AssignedPlan.CapabilityStatus()) = 'Enabled' then begin
                    ServicePlanIdValue := AssignedPlan.ServicePlanId();
                    if IsBCServicePlan(ServicePlanIdValue) or IsTest then begin
                        HaveAssignedPlans := true;
                        AddToTempPlan(ServicePlanIdValue, Format(AssignedPlan.ServicePlanName()), TempPlan);
                        SendTraceTag('00009KY', UserSetupCategoryTxt, Verbosity::Normal,
                          StrSubstNo(UserPlanAssignedMsg, Format(GraphUser.DisplayName()), Format(ServicePlanIdValue)), DataClassification::EndUserIdentifiableInformation);
                    end;
                end;

        if not HaveAssignedPlans then
            SendTraceTag('00009KZ', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(UserHasNoPlansMsg, Format(GraphUser.DisplayName())),
                DataClassification::EndUserIdentifiableInformation);

        // Loop through Azure AD Roles
        if not IsNull(GraphUser.Roles()) then
            foreach DirectoryRole in GraphUser.Roles() do
                if IsBCServicePlan(DirectoryRole.RoleTemplateId()) then begin
                    AddToTempPlan(Format(DirectoryRole.RoleTemplateId()), Format(DirectoryRole.DisplayName()), TempPlan);
                    SendTraceTag('00009L0', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(UserPlanAssignedMsg, Format(GraphUser.DisplayName()), Format(DirectoryRole.RoleTemplateId())),
                        DataClassification::EndUserIdentifiableInformation);
                    SystemRoleAdded := true;
                end;

        // If there are no Azure AD Plans and no system roles assigned, then check if its a device user
        if HaveAssignedPlans or SystemRoleAdded then
            exit;

        if IsDeviceRole(GraphUser) then begin
            GetDevicesPlanInfo(DevicesPlanId, DevicesPlanName);
            SendTraceTag('00009L6', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(DevicePlanFoundMsg, DevicesPlanName, Format(GraphUser.DisplayName())), DataClassification::EndUserIdentifiableInformation);
            AddToTempPlan(DevicesPlanId, DevicesPlanName, TempPlan);
        end else
            SendTraceTag('00009L7', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(NotBCUserMsg, Format(GraphUser.DisplayName())), DataClassification::EndUserIdentifiableInformation);
    end;

    local procedure IsDeviceRole(var GraphUser: DotNet UserInfo): Boolean
    var
        GroupInfo: DotNet GroupInfo;
    begin
        if IsNull(GraphUser) then
            exit(false);

        if IsNull(GraphUser.Groups()) then
            exit(false);

        foreach GroupInfo in GraphUser.Groups() do
            if not IsNull(GroupInfo.DisplayName()) then
                if GroupInfo.DisplayName().ToUpper() = UpperCase(DeviceGroupNameTxt) then
                    exit(true);
        exit(false);
    end;

    local procedure GetDevicesPlanInfo(var PlanId: Guid; var PlanName: Text)
    var
        MembershipEntitlement: Record "Membership Entitlement";
        PlanIds: Codeunit "Plan Ids";
    begin
        if IsTest then begin
            PlanId := PlanIds.GetDevicePlanId();
            exit;
        end;

        MembershipEntitlement.SetRange(Type, MembershipEntitlement.Type::"Azure AD Device Plan");
        if MembershipEntitlement.FindFirst() then begin
            Evaluate(PlanId, MembershipEntitlement.Id);
            PlanName := MembershipEntitlement.Name;
        end;

    end;

    local procedure InsertFromTempPlan(TempPlan: Record Plan temporary)
    var
        Plan: Record Plan;
    begin
        if not Plan.Get(TempPlan."Plan ID") then begin
            Plan.Copy(TempPlan);
            Plan.Insert();
        end;
    end;

    local procedure UpdateUserFromAzureGraph(var User: Record User; var GraphUser: DotNet UserInfo): Boolean
    var
        IsUserModified: Boolean;
    begin
        AzureADGraphUser.GetGraphUser(User."User Security ID", GraphUser);
        IsUserModified := AzureADGraphUser.UpdateUserFromAzureGraph(User, GraphUser);
        exit(IsUserModified);
    end;

    local procedure IsBCServicePlan(ServicePlanId: Guid): Boolean
    var
        Plan: Record "Plan";
    begin
        if IsNullGuid(ServicePlanId) then
            exit(false);

        exit(Plan.GET(ServicePlanId));
    end;

    local procedure GetAzureUserPlanRoleCenterId(UserSecurityID: Guid): Integer
    var
        TempPlan: Record "Plan" temporary;
        User: Record User;
        GraphUser: DotNet UserInfo;
    begin
        if not User.GET(UserSecurityID) then
            exit(0);

        if not AzureADGraphUser.GetGraphUser(UserSecurityID, GraphUser) then
            exit(0);

        GetGraphUserPlans(TempPlan, GraphUser);

        TempPlan.SetFilter("Role Center ID", '<>0');

        if not TempPlan.FindFirst() then
            exit(0);

        exit(TempPlan."Role Center ID");
    end;

    local procedure AddNewlyAssignedUserPlans(var Plan: Record Plan; UserSecurityID: Guid; UserHadBeenSetupBefore: Boolean; AppendPermissionsOnNewPlan: Boolean)
    var
        UserPlan: Record "User Plan";
        AzureADPlan: Codeunit "Azure AD Plan";
        UserPermissions: Codeunit "User Permissions";
        UserGroupsAdded: Boolean;
    begin
        // Have any plans been added to this user in O365, since last time he logged-in to NAV?
        // For each plan assigned to the user in Office
        if Plan.FindSet() then
            repeat
                // Does this assignment exist in NAV? If not, add it.
                UserPlan.SetRange("Plan ID", Plan."Plan ID");
                UserPlan.SetRange("User Security ID", UserSecurityID);
                if UserPlan.IsEmpty() then begin
                    InsertFromTempPlan(Plan);
                    UserPlan.LockTable();
                    UserPlan.Init();
                    UserPlan."Plan ID" := Plan."Plan ID";
                    UserPlan."User Security ID" := UserSecurityID;
                    UserPlan.Insert();
                    // The SUPER role is replaced with O365 FULL ACCESS for new users.
                    // This happens only for users who are created from O365 (i.e. are added to plans)
                    if AppendPermissionsOnNewPlan then
                        AzureADPlan.OnUpdateUserAccessForSaaS(UserPlan."User Security ID", UserGroupsAdded);
                end;
            until Plan.Next() = 0;

        // Only remove SUPER if other permissions are granted (to avoid user lockout)
        if UserGroupsAdded then begin
            if not UserHadBeenSetupBefore then
                if not IsUserAdmin(UserSecurityID) then
                    UserPermissions.RemoveSuperPermissions(UserSecurityID);
            if not IsTest then
                Commit(); // Finalize the transaction. Else any further error can rollback and create elevation of privilege
        end;
    end;

    local procedure AddToTempPlan(ServicePlanId: Guid; ServicePlanName: Text; var TempPlan: Record "Plan" temporary)
    var
        Plan: Record "Plan";
    begin
        WITH TempPlan do begin
            if GET(ServicePlanId) then
                exit;

            if Plan.GET(ServicePlanId) then;

            Init();
            "Plan ID" := ServicePlanId;
            Name := CopyStr(ServicePlanName, 1, MaxStrLen(Name));
            if IsTest then
                "Role Center ID" := 9022
            else
                "Role Center ID" := Plan."Role Center ID";
            Insert();
        end;
    end;

    local procedure IsUserAdmin(SecurityID: Guid): Boolean
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        exit(
            IsPlanAssignedToUser(PlanIds.GetInternalAdminPlanId(), SecurityID)
            or IsPlanAssignedToUser(PlanIds.GetDelegatedAdminPlanId(), SecurityID));
    end;

    procedure GetPlanIDs(GraphUser: DotNet UserInfo; var PlanIDs: List of [Guid])
    var
        TempPlan: Record Plan temporary;
    begin
        Clear(PlanIDs);
        GetGraphUserPlans(TempPlan, GraphUser);
        if TempPlan.FindSet() then
            repeat
                PlanIDs.Add(TempPlan."Plan ID");
            until TempPlan.Next() = 0;
    end;

    procedure GetPlanNames(GraphUser: DotNet UserInfo; var PlanNames: List of [Text])
    var
        TempPlan: Record Plan temporary;
        Plan: Record Plan;
    begin
        Clear(PlanNames);
        GetGraphUserPlans(TempPlan, GraphUser);
        if TempPlan.FindSet() then
            repeat
                // use the Business Central plan name instead of the Office Plan name, if possible.
                if Plan.Get(TempPlan."Plan ID") then begin
                    PlanNames.Add(Plan.Name);
                    SendTraceTag('0000BK0', UserSetupCategoryTxt, Verbosity::Verbose, StrSubstNo(UserGotPlanTxt, AzureADGraphUser.GetAuthenticationEmail(GraphUser), Plan."Plan ID", Plan.Name), DataClassification::EndUserIdentifiableInformation);
                end else begin
                    PlanNames.Add(TempPlan.Name);
                    SendTraceTag('0000BK1', UserSetupCategoryTxt, Verbosity::Verbose, StrSubstNo(UserGotPlanTxt, AzureADGraphUser.GetAuthenticationEmail(GraphUser), TempPlan."Plan ID", TempPlan.Name), DataClassification::EndUserIdentifiableInformation);
                end;

            until TempPlan.Next() = 0;
    end;

    procedure GetPlanNames(UserSecID: Guid; var PlanNames: List of [Text])
    var
        UserPlan: Record "User Plan";
    begin
        Clear(PlanNames);
        UserPlan.SetRange("User Security ID", UserSecID);
        if UserPlan.FindSet() then
            repeat
                UserPlan.CalcFields("Plan Name");
                PlanNames.Add(UserPlan."Plan Name");
            until UserPlan.Next() = 0;
    end;

    procedure CheckIfPlansDifferent(GraphUser: DotNet UserInfo; UserSecID: Guid): Boolean
    var
        TempPlan: Record Plan temporary;
        UserPlan: Record "User Plan";
        Plan: Record Plan;
        UserPlanCount: Integer;
        TempPlanCount: Integer;
    begin
        SendTraceTag('0000BK2', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(PlansDifferentCheckTxt, AzureADGraphUser.GetAuthenticationEmail(GraphUser), UserSecID), DataClassification::EndUserIdentifiableInformation);

        GetGraphUserPlans(TempPlan, GraphUser);

        UserPlan.SetRange("User Security ID", UserSecID);
        UserPlanCount := UserPlan.Count();
        TempPlanCount := TempPlan.Count();
        if UserPlanCount <> TempPlanCount then begin
            SendTraceTag('0000BK3', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(PlanCountDifferentTxt, UserPlanCount, TempPlanCount), DataClassification::SystemMetadata);
            exit(true);
        end;

        if TempPlan.FindSet() then
            repeat
                if not UserPlan.Get(TempPlan."Plan ID", UserSecID) then begin
                    if Plan.Get(TempPlan."Plan ID") then
                        SendTraceTag('0000BK4', UserSetupCategoryTxt, Verbosity::Normal, StrSubstNo(GraphUserHasExtraPlanTxt, TempPlan."Plan ID", Plan.Name), DataClassification::SystemMetadata);
                    exit(true);
                end;
            until TempPlan.Next() = 0;
    end;

}

