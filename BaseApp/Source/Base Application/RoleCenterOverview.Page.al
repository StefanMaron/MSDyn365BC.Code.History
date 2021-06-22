page 1486 "Role Center Overview"
{
    Caption = 'Role Center Overview';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            usercontrol("ControlAddin"; "Microsoft.Dynamics.Nav.Client.RoleCenterSelector")
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                var
                    RolecenterSelectorMgt: Codeunit "Rolecenter Selector Mgt.";
                    Json: Text;
                begin
                    Json := RolecenterSelectorMgt.BuildPageDataJsonForRolecenterSelector;
                    CurrPage.ControlAddin.LoadPageDataFromJson(Json);
                    SendJsonToControlAddIn;
                    CurrPage.ControlAddin.SetCurrentProfileId(Format(CurrAllProfile.RecordId));
                end;

                trigger OnAcceptAction()
                begin
                    AcceptAction := true;
                    if not SkipSessionUpdateRequest then
                        ChangeProfile(CurrAllProfile);
                    CurrPage.Close;
                end;

                trigger OnProfileSelected(profileId: Text)
                var
                    AllProfileRecordId: RecordID;
                begin
                    Evaluate(AllProfileRecordId, profileId);
                    if CurrAllProfile.Get(AllProfileRecordId) then begin
                        CurrRoleCenterID := CurrAllProfile."Role Center ID";
                        SendJsonToControlAddIn;
                    end;
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnInit()
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        ConfPersonalizationMgt.GetCurrentProfileNoError(CurrAllProfile);

        if CurrAllProfile.IsEmpty then
            if CurrAllProfile.FindFirst then
                exit;

        CurrRoleCenterID := CurrAllProfile."Role Center ID";
    end;

    var
        CurrAllProfile: Record "All Profile";
        SkipSessionUpdateRequest: Boolean;
        AcceptAction: Boolean;
        CurrRoleCenterID: Integer;

    procedure DelaySessionUpdateRequest()
    begin
        SkipSessionUpdateRequest := true;
    end;

    procedure SetSelectedProfile(SelectedScope: Option; SelectedAppId: Guid; SelectedProfileID: Code[30])
    begin
        if CurrAllProfile.Get(SelectedScope, SelectedAppId, SelectedProfileID) then
            if CurrAllProfile.FindFirst then;
    end;

    procedure GetSelectedProfile(var ProfileScope: Option; var ProfileAppId: Guid; var ProfileId: Code[30])
    begin
        ProfileScope := CurrAllProfile.Scope;
        ProfileAppId := CurrAllProfile."App ID";
        ProfileId := CurrAllProfile."Profile ID";
    end;

    local procedure ChangeProfile(NewAllProfile: Record "All Profile")
    var
        UserPersonalization: Record "User Personalization";
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        SessionSet: SessionSettings;
    begin
        if not ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile) then
            exit;

        ConfPersonalizationMgt.SetCurrentProfile(NewAllProfile);

        UserPersonalization.Get(UserSecurityId);

        with SessionSet do begin
            Init;
            ProfileId := NewAllProfile."Profile ID";
            ProfileAppId := NewAllProfile."App ID";
            ProfileSystemScope := NewAllProfile.Scope = NewAllProfile.Scope::System;
            LanguageId := UserPersonalization."Language ID";
            LocaleId := UserPersonalization."Locale ID";
            Timezone := UserPersonalization."Time Zone";
            RequestSessionUpdate(true);
        end;
    end;

    local procedure SendJsonToControlAddIn()
    var
        RolecenterSelectorMgt: Codeunit "Rolecenter Selector Mgt.";
        Json: Text;
    begin
        Json := RolecenterSelectorMgt.BuildJsonFromPageActionTable(CurrRoleCenterID);
        CurrPage.ControlAddin.LoadRoleCenterFromJson(Json);
    end;

    procedure GetAcceptAction(): Boolean
    begin
        exit(AcceptAction);
    end;
}

