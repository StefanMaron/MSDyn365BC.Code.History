codeunit 1997 "Checklist Events"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::LogInManagement, 'OnAfterLogInStart', '', true, true)]
    local procedure OnAfterLogInStart()
    var
        Checklist: Codeunit Checklist;
    begin
        if not (Session.CurrentClientType() in [ClientType::Web, ClientType::Windows, ClientType::Desktop]) then
            exit;

        if not Checklist.ShouldInitializeChecklist() then
            exit;

        Checklist.InitializeGuidedExperienceItems();

        InitializeChecklist();

        Checklist.MarkChecklistSetupAsDone();
    end;

    local procedure InitializeChecklist()
    var
        TempAllProfile: Record "All Profile" temporary;
        Checklist: Codeunit Checklist;
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        GetRoles(TempAllProfile);

        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Assisted Company Setup Wizard", 1000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Azure AD User Update Wizard", 2000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Manual Setup", ObjectType::Page, Page::Users, 3000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Manual Setup", ObjectType::Page, Page::"User Personalization List", 4000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Email Account Wizard", 5000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Data Migration Wizard", 6000, TempAllProfile, false);
        Checklist.Insert(GuidedExperienceType::Learn, 'https://go.microsoft.com/fwlink/?linkid=2152979', 8000, TempAllProfile, false);
    end;

    local procedure GetRoles(var TempAllProfile: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfile, Page::"Business Manager Role Center");
    end;

    local procedure AddRoleToList(var TempAllProfile: Record "All Profile" temporary; RoleCenterID: Integer)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Role Center ID", RoleCenterID);
        if AllProfile.FindFirst() then begin
            TempAllProfile.TransferFields(AllProfile);
            TempAllProfile.Insert();
        end;
    end;
}