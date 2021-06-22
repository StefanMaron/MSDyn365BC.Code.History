codeunit 132230 "Library - E2E Plan Permissions"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        PlanIds: Codeunit "Plan Ids";

    local procedure SetProfileID(ProfileID: Code[30])
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        AllProfile.SetRange("Profile ID", ProfileID);
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);
        Commit;
    end;

    procedure SetTeamMemberPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('TEAM MEMBER');
        SetUserPlan(PlanIds.GetTeamMemberPlanId());
        SetUserGroupPlan(PlanIds.GetTeamMemberPlanId());
        Commit;
    end;

    procedure SetExternalAccountantPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('ACCOUNTANT');
        SetUserPlan(PlanIds.GetExternalAccountantPlanId());
        SetUserGroupPlan(PlanIds.GetExternalAccountantPlanId());
        Commit;
    end;

    procedure SetBusinessManagerPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetEssentialPlanId());
        SetUserGroupPlan(PlanIds.GetEssentialPlanId());
        Commit;
    end;

    procedure SetPremiumUserPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetPremiumPlanId());
        SetUserGroupPlan(PlanIds.GetPremiumPlanId());
        Commit;
    end;

    procedure SetTeamMemberISVEmbPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('TEAM MEMBER');
        SetUserPlan(PlanIds.GetTeamMemberISVPlanId());
        SetUserGroupPlan(PlanIds.GetTeamMemberISVPlanId());
        Commit;
    end;

    procedure SetEssentialISVEmbUserPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetEssentialISVPlanId());
        SetUserGroupPlan(PlanIds.GetEssentialISVPlanId());
        Commit;
    end;

    procedure SetPremiumISVEmbUserPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetPremiumISVPlanId());
        SetUserGroupPlan(PlanIds.GetPremiumISVPlanId());
        Commit;
    end;

    procedure SetDeviceISVEmbUserPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetDeviceISVPlanId());
        SetUserGroupPlan(PlanIds.GetDeviceISVPlanId());
        Commit;
    end;

    local procedure SetUserPlan(PlanID: Text[50])
    var
        AzureADPlan: Codeunit "Azure AD Plan";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
    begin
        if AzureADPlan.IsPlanAssignedToUser(PlanID, UserSecurityId()) then
            exit;

        if AzureADPlan.DoesUserHavePlans(UserSecurityId()) then
            AzureADPlanTestLibrary.ReassignPlanToUser(UserSecurityId(), PlanID)
        else
            AzureADPlanTestLibrary.AssignUserToPlan(UserSecurityId(), PlanID);
    end;

    procedure SetViralSignupPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetViralSignupPlanId());
        SetUserGroupPlan(PlanIds.GetViralSignupPlanId());
    end;

    local procedure SetUserGroupPlan(PlanID: Guid)
    var
        UserGroupPlan: Record "User Group Plan";
    begin
        UserGroupPlan.SetRange("Plan ID", PlanID);
        if UserGroupPlan.FindSet then begin
            SetFirstUserGroupPermissionSet(UserGroupPlan."User Group Code");
            if UserGroupPlan.Next > 0 then
                AddRemainingUserGroupPermissionSets(UserGroupPlan);
        end;
    end;

    local procedure SetFirstUserGroupPermissionSet(UserGroupCode: Code[20])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        if UserGroupPermissionSet.FindSet then begin
            LibraryLowerPermissions.PushPermissionSetWithoutDefaults(UserGroupPermissionSet."Role ID");
            if UserGroupPermissionSet.Next > 0 then
                repeat
                    LibraryLowerPermissions.AddPermissionSet(UserGroupPermissionSet."Role ID")
                until UserGroupPermissionSet.Next = 0;
        end;
    end;

    local procedure AddRemainingUserGroupPermissionSets(var UserGroupPlan: Record "User Group Plan")
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        repeat
            UserGroupPermissionSet.SetRange("User Group Code", UserGroupPlan."User Group Code");
            if UserGroupPermissionSet.FindSet then
                repeat
                    LibraryLowerPermissions.AddPermissionSet(UserGroupPermissionSet."Role ID")
                until UserGroupPermissionSet.Next = 0;
        until UserGroupPlan.Next = 0;
    end;
}

