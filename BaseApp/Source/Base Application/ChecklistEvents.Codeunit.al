codeunit 1997 "Checklist Events"
{
    var
        YourSalesWithinOutlookVideoLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2170901', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::LogInManagement, 'OnAfterLogInStart', '', true, true)]
    local procedure OnAfterLogInStart()
    var
        Company: Record Company;
        Checklist: Codeunit Checklist;
    begin
        if not (Session.CurrentClientType() in [ClientType::Web, ClientType::Windows, ClientType::Desktop]) then
            exit;

        if not Checklist.ShouldInitializeChecklist(false) then
            exit;

        if not Company.Get(CompanyName()) then
            exit;

        Checklist.InitializeGuidedExperienceItems();

        if Company."Evaluation Company" then
            InitializeChecklistForEvaluationCompanies()
        else
            InitializeChecklistForNonEvaluationCompanies();

        Checklist.MarkChecklistSetupAsDone();
    end;

    local procedure InitializeChecklistForEvaluationCompanies()
    var
        TempAllProfile: Record "All Profile" temporary;
        Checklist: Codeunit Checklist;
        EnvironmentInformation: Codeunit "Environment Information";
        GuidedExperienceType: Enum "Guided Experience Type";
        SpotlightTourType: Enum "Spotlight Tour Type";
    begin
        GetRolesForEvaluationCompany(TempAllProfile);

        Checklist.Insert(GuidedExperienceType::Tour, ObjectType::Page, Page::"Business Manager Role Center", 1000, TempAllProfile, true);
        Checklist.Insert(Page::"Customer List", SpotlightTourType::"Open in Excel", 2000, TempAllProfile, true);

        if EnvironmentInformation.IsSaaS() then
            Checklist.Insert(Page::"Item Card", SpotlightTourType::"Share to Teams", 3000, TempAllProfile, true);

        Checklist.Insert(GuidedExperienceType::Video, YourSalesWithinOutlookVideoLinkTxt, 4000, TempAllProfile, true);
    end;

    local procedure InitializeChecklistForNonEvaluationCompanies()
    var
        TempAllProfile: Record "All Profile" temporary;
        Checklist: Codeunit Checklist;
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        GetRolesForNonEvaluationCompany(TempAllProfile);

        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Assisted Company Setup Wizard", 1000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Azure AD User Update Wizard", 2000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Manual Setup", ObjectType::Page, Page::Users, 3000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Manual Setup", ObjectType::Page, Page::"User Settings List", 4000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Email Account Wizard", 5000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Data Migration Wizard", 6000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::Learn, 'https://go.microsoft.com/fwlink/?linkid=2152979', 8000, TempAllProfile, false);
    end;

    local procedure GetRolesForNonEvaluationCompany(var TempAllProfile: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfile, Page::"Business Manager Role Center");
    end;

    local procedure GetRolesForEvaluationCompany(var TempAllProfile: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfile, 'Business Manager Evaluation');
    end;

    local procedure AddRoleToList(var TempAllProfile: Record "All Profile" temporary; RoleCenterID: Integer)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Role Center ID", RoleCenterID);
        AddRoleToList(AllProfile, TempAllProfile);
    end;

    local procedure AddRoleToList(var TempAllProfile: Record "All Profile" temporary; ProfileID: Code[30])
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Profile ID", ProfileID);
        AddRoleToList(AllProfile, TempAllProfile);
    end;

    local procedure AddRoleToList(var AllProfile: Record "All Profile"; var TempAllProfile: Record "All Profile" temporary)
    begin
        if AllProfile.FindFirst() then begin
            TempAllProfile.TransferFields(AllProfile);
            TempAllProfile.Insert();
        end;
    end;
}