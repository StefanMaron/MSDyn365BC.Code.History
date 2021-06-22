codeunit 132230 "Library - E2E Plan Permissions"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

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
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('TEAM MEMBER');
        SetUserPlan(PlanIds.GetTeamMemberPlanId);
        SetUserGroupPlan('Finance and Operations, Team Member');
        Commit;
    end;

    procedure SetExternalAccountantPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('ACCOUNTANT');
        SetUserPlan(PlanIds.GetExternalAccountantPlanId);
        SetUserGroupPlan('Finance and Operations, External Accountant');
        Commit;
    end;

    procedure SetBusinessManagerPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetEssentialPlanId);
        SetUserGroupPlan('Finance and Operations');
        Commit;
    end;

    procedure SetPremiumUserPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetPremiumPlanId);
        SetUserGroupPlan('Dynamics 365 Business Central, Premium User');
        Commit;
    end;

    procedure SetInvoicingUserPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetUserPlan(PlanIds.GetInvoicingPlanId);
        SetUserGroupPlan('Microsoft Invoicing');
        Commit;
    end;

    procedure SetTeamMemberISVEmbPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('TEAM MEMBER');
        SetUserPlan(PlanIds.GetTeamMemberISVPlanId);
        SetUserGroupPlan('Dynamics 365 Business Central, Team Member ISV');
        Commit;
    end;

    procedure SetEssentialISVEmbUserPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetEssentialISVPlanId);
        SetUserGroupPlan('Dynamics 365 Business Central, Essential ISV User');
        Commit;
    end;

    procedure SetPremiumISVEmbUserPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetPremiumISVPlanId);
        SetUserGroupPlan('Dynamics 365 Business Central, Premium ISV User');
        Commit;
    end;

    procedure SetDeviceISVEmbUserPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope;
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetDeviceISVPlanId);
        SetUserGroupPlan('Dynamics 365 Business Central Device - Embedded');
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
        SetUserPlan(PlanIds.GetViralSignupPlanId);
        SetUserGroupPlan('Finance and Operations for IWs');
    end;

    local procedure SetUserGroupPlan(PlanName: Text[50])
    var
        UserGroupPlan: Record "User Group Plan";
    begin
        UserGroupPlan.SetRange("Plan Name", PlanName);
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

