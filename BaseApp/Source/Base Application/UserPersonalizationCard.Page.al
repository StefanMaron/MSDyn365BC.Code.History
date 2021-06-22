page 9172 "User Personalization Card"
{
    Caption = 'User Personalization Card';
    DataCaptionExpression = "User ID";
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "User Personalization";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User ID';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the user ID of a user who is using Database Server Authentication to log on to Business Central.';

                    trigger OnAssistEdit()
                    var
                        UserPersonalization: Record "User Personalization";
                        User: Record User;
                        UserSelection: Codeunit "User Selection";
                    begin
                        if not UserSelection.Open(User) then
                            exit;

                        if (User."User Security ID" <> "User SID") and not IsNullGuid(User."User Security ID") then begin
                            if UserPersonalization.Get(User."User Security ID") then begin
                                UserPersonalization.CalcFields("User ID");
                                Error(Text000, TableCaption, UserPersonalization."User ID");
                            end;

                            Validate("User SID", User."User Security ID");
                            CalcFields("User ID");

                            CurrPage.Update;
                        end;
                    end;
                }
                field(ProfileID; ProfileID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    DrillDown = false;
                    Editable = false;
                    LookupPageID = "Profile List";
                    ToolTip = 'Specifies the ID of the profile that is associated with the current user.';

                    trigger OnAssistEdit()
                    var
                        AllProfileTable: Record "All Profile";
                    begin
                        if PAGE.RunModal(PAGE::"Available Roles", AllProfileTable) = ACTION::LookupOK then begin
                            "Profile ID" := AllProfileTable."Profile ID";
                            "App ID" := AllProfileTable."App ID";
                            Scope := AllProfileTable.Scope;
                            ProfileID := "Profile ID";
                            SetRestartRequiredIfChangeIsForCurrentUser;
                        end
                    end;
                }
                field("Language ID"; "Language ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Language ID';
                    ToolTip = 'Specifies the ID of the language that Microsoft Windows is set up to run for the selected user.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Language: Codeunit Language;
                    begin
                        Language.LookupApplicationLanguageId("Language ID");

                        if "Language ID" <> xRec."Language ID" then begin
                            Validate("Language ID", "Language ID");
                            SetRestartRequiredIfChangeIsForCurrentUser;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        Language: Codeunit Language;
                    begin
                        Language.ValidateApplicationLanguageId("Language ID");
                        SetRestartRequiredIfChangeIsForCurrentUser;
                    end;
                }
                field("Locale ID"; "Locale ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Locale ID';
                    Importance = Additional;
                    TableRelation = "Windows Language"."Language ID";
                    ToolTip = 'Specifies the ID of the locale that Microsoft Windows is set up to run for the selected user.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Language: Codeunit Language;
                    begin
                        Language.LookupWindowsLanguageId("Locale ID");

                        if "Locale ID" <> xRec."Locale ID" then begin
                            Validate("Locale ID", "Locale ID");
                            SetRestartRequiredIfChangeIsForCurrentUser;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        Language: Codeunit Language;
                    begin
                        Language.ValidateWindowsLanguageId("Locale ID");
                        SetRestartRequiredIfChangeIsForCurrentUser;
                    end;
                }
                field("Time Zone"; "Time Zone")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time Zone';
                    Importance = Additional;
                    ToolTip = 'Specifies the time zone that Microsoft Windows is set up to run for the selected user.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(ConfPersMgt.LookupTimeZone(Text))
                    end;

                    trigger OnValidate()
                    begin
                        ConfPersMgt.ValidateTimeZone("Time Zone");
                        SetRestartRequiredIfChangeIsForCurrentUser;
                    end;
                }
                field(Company; Company)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company that is associated with the user.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("User &Personalization")
            {
                Caption = 'User &Personalization';
                Image = Grid;
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View or edit a list of all users who have personalized their user interface by customizing one or more pages.';

                    trigger OnAction()
                    var
                        UserPersList: Page "User Personalization List";
                    begin
                        UserPersList.LookupMode := true;
                        UserPersList.SetRecord(Rec);
                        if UserPersList.RunModal = ACTION::LookupOK then
                            UserPersList.GetRecord(Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("C&lear Personalized Pages")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&lear Personalized Pages';
                    Image = Cancel;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Delete all personalizations made by the specified user across display targets.';

                    trigger OnAction()
                    begin
                        ConfPersMgt.ClearUserPersonalization(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ProfileID := "Profile ID";
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        TestField("User SID");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        TestField("User SID");
    end;

    trigger OnOpenPage()
    begin
        HideExternalUsers;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if RequiresRestart and (CloseAction <> ACTION::Cancel) then
            RestartSession;
    end;

    var
        ConfPersMgt: Codeunit "Conf./Personalization Mgt.";
        Text000: Label '%1 %2 already exists.', Comment = 'User Personalization User1 already exists.';
        AccountantTxt: Label 'ACCOUNTANT', Comment = 'Please translate all caps';
        ProjectManagerTxt: Label 'PROJECT MANAGER', Comment = 'Please translate all caps';
        TeamMemberTxt: Label 'TEAM MEMBER', Comment = 'Please translate all caps';
        ExperienceMsg: Label 'You are changing to a Role Center that has more functionality. To display the full functionality for this role, your Experience setting will be set to Essential.';
        ProfileID: Code[30];
        RequiresRestart: Boolean;

    local procedure HideExternalUsers()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        CalcFields("License Type");
        SetFilter("License Type", '<>%1', "License Type"::"External User");
        FilterGroup := OriginalFilterGroup;
    end;

    procedure SetExperienceToEssential(SelectedProfileID: Text[30])
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if CompanyInformationMgt.IsDemoCompany then
            if ExperienceTierSetup.Get(CompanyName) then
                if ExperienceTierSetup.Basic then
                    if (SelectedProfileID = TeamMemberTxt) or
                       (SelectedProfileID = AccountantTxt) or
                       (SelectedProfileID = ProjectManagerTxt)
                    then begin
                        Message(ExperienceMsg);
                        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
                    end;
    end;

    local procedure SetRestartRequiredIfChangeIsForCurrentUser()
    begin
        if ((UserSecurityId = "User SID") or IsNullGuid("User SID")) and (CompanyName = Company) then
            RequiresRestart := true;
    end;

    local procedure RestartSession()
    var
        UserPersonalization: Record "User Personalization";
        CurrentUserSessionSettings: SessionSettings;
        ProfileScope: Option System,Tenant;
    begin
        UserPersonalization.Get(UserSecurityId);

        CurrentUserSessionSettings.Init();
        CurrentUserSessionSettings.ProfileId := UserPersonalization."Profile ID";
        CurrentUserSessionSettings.ProfileAppId := UserPersonalization."App ID";
        CurrentUserSessionSettings.ProfileSystemScope := UserPersonalization.Scope = ProfileScope::System;
        CurrentUserSessionSettings.LanguageId := UserPersonalization."Language ID";
        CurrentUserSessionSettings.LocaleId := UserPersonalization."Locale ID";
        CurrentUserSessionSettings.Timezone := UserPersonalization."Time Zone";

        CurrentUserSessionSettings.RequestSessionUpdate(true);
    end;
}

