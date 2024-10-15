// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Globalization;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

page 9192 "Company Creation Wizard"
{
    Caption = 'Create New Company';
    PageType = NavigatePage;
    SourceTable = User;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control6)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT FinalStepVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control8)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND FinalStepVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control10)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to assisted setup for creating a company")
                {
                    Caption = 'Welcome to assisted setup for creating a company';
                    Visible = FirstStepVisible;
                    group(Control12)
                    {
                        InstructionalText = 'This guide will help you create a new company.';
                        ShowCaption = false;
                        Visible = FirstStepVisible;
                    }
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to get started.';
                }
            }
            group(Control13)
            {
                ShowCaption = false;
                Visible = CreationStepVisible;
                group("Specify some basic information")
                {
                    Caption = 'Specify some basic information';
                    Visible = CreationStepVisible;
                    group(Control20)
                    {
                        InstructionalText = 'Enter a name for the company.';
                        ShowCaption = false;
                        field(CompanyName; NewCompanyName)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            ShowMandatory = true;

                            trigger OnValidate()
                            var
                                Company: Record Company;
                            begin
                                NewCompanyName := DelChr(NewCompanyName, '<>');
                                Company.SetFilter(Name, '%1', '@' + NewCompanyName);
                                if not Company.IsEmpty() then
                                    Error(CompanyAlreadyExistsErr);

                                OnAfterValidateCompanyName(NewCompanyName);
                            end;
                        }
                    }
                    group("Select the data and setup to get started.")
                    {
                        Caption = 'Select the data and setup to get started.';
                        group(Control26)
                        {
                            ShowCaption = false;
                            Visible = NOT IsSandbox;
                            field(CompanyData; NewCompanyDataProduction)
                            {
                                ApplicationArea = Basic, Suite;
                                ShowCaption = false;
                                Visible = NOT IsSandbox;

                                trigger OnValidate()
                                begin
                                    NewCompanyData := NewCompanyDataProduction;
                                    UpdateDataDescription();
                                end;
                            }
                        }
                        group(Control27)
                        {
                            ShowCaption = false;
                            Visible = IsSandbox;
                            field(CompanyFullData; NewCompanyDataSandbox)
                            {
                                ApplicationArea = Basic, Suite;
                                ShowCaption = false;
                                Visible = IsSandbox;

                                trigger OnValidate()
                                begin
                                    NewCompanyData := NewCompanyDataSandbox;
                                    UpdateDataDescription();
                                end;
                            }
                        }
                        field(NewCompanyDataDescription; NewCompanyDataDescription)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            MultiLine = true;
                            ShowCaption = false;
                        }
                    }
                    group("Additional Demo Data")
                    {
                        Visible = (AdditionalDemoDataVisible)
                            and ((NewCompanyData = NewCompanyData::"Evaluation Data") or (NewCompanyData = NewCompanyData::"Standard Data"));

                        field("Install Contoso Coffee Demo Data"; InstallAdditionalDemoData)
                        {
                            ApplicationArea = All;
                            ToolTip = 'Install the Contoso Demo Data app on top of the default sample data.';
                            Caption = 'Install the Contoso Demo Data app on top of the default sample data.';
                        }
                    }
                }
            }
            group(Control32)
            {
                ShowCaption = false;
                Visible = AddUsersVisible;
                group("Manage users of the new company.")
                {
                    Caption = 'Manage users of the new company.';
                    Visible = CanManageUser;
                    group(Control30)
                    {
                        InstructionalText = 'Add users to or remove users from the new company.';
                        ShowCaption = false;
                        field(ManageUserLabel; ManageUsersLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Manage Users';
                            Editable = false;
                            ShowCaption = false;
                            Style = AttentionAccent;
                            StyleExpr = TRUE;

                            trigger OnDrillDown()
                            var
                                UserSelection: Codeunit "User Selection";
                            begin
                                Clear(Rec);
                                UserSelection.Open(Rec);
                                ContainUsers := not Rec.IsEmpty();
                                CurrPage.Update(false);
                            end;
                        }
                        group(Users)
                        {
                            Caption = 'Users';
                            Editable = false;
                            Enabled = false;
                            Visible = ContainUsers;
                            repeater(Control38)
                            {
                                ShowCaption = false;
                                field("User Name"; Rec."User Name")
                                {
                                    ApplicationArea = Basic, Suite;
                                    TableRelation = User;
                                    ToolTip = 'Specifies the name that the user must present when signing in. ';
                                }
                                field("Full Name"; Rec."Full Name")
                                {
                                    ApplicationArea = Basic, Suite;
                                    Editable = false;
                                    ToolTip = 'Specifies the full name of the user.';
                                }
                            }
                        }
                    }
                }
                group("The new company will be created without users")
                {
                    Caption = 'The new company will be created without users';
                    Visible = NOT CanManageUser;
                    field(OnlySuperCanLabel; OnlySuperCanManageUsersLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = AttentionAccent;
                        StyleExpr = TRUE;
                    }
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Control19)
                    {
                        InstructionalText = 'Choose Finish to create the company. This can take a few minutes to complete.';
                        ShowCaption = false;
                    }
                    group(Control22)
                    {
                        InstructionalText = 'The company is created and included in the companies list, but before you use it we need time to set up some data and settings for you.';
                        ShowCaption = false;
                        Visible = ConfigurationPackageExists;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        UserPermissions: Codeunit "User Permissions";
    begin
        if not UserPermissions.IsSuper(UserSecurityId()) then
            Error(OnlySuperCanCreateNewCompanyErr);

        LoadTopBanners();
        IsSandbox := EnvironmentInfo.IsSandbox();
        CanManageUser := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
    end;

    trigger OnOpenPage()
    begin
        Step := Step::Start;
        NewCompanyData := NewCompanyData::"Standard Data";
        NewCompanyDataProduction := NewCompanyDataProduction::"Production - Setup Data Only";
        NewCompanyDataSandbox := NewCompanyDataSandbox::"Production - Setup Data Only";
        UpdateDataDescription();
        EnableControls();
        CurrPage.Update(false);

        OnOpenPageCheckAdditionalDemoData(AdditionalDemoDataVisible);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then
            if not CompanyCreated then
                if not Confirm(SetupNotCompletedQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Creation,"Add Users",Finish;
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        CreationStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        SetupNotCompletedQst: Label 'The company has not yet been created.\\Are you sure that you want to exit?';
        ConfigurationPackageExists: Boolean;
        AdditionalDemoDataVisible: Boolean;
        InstallAdditionalDemoData: Boolean;
        NewCompanyName: Text[30];
        NewCompanyData: Enum "Company Data Type (Internal)";
        NewCompanyDataProduction: Enum "Company Data Type (Production)";
        NewCompanyDataSandbox: Enum "Company Data Type (Sandbox)";
        CompanyAlreadyExistsErr: Label 'A company with that name already exists. Try a different name.';
        NewCompanyDataDescription: Text;
        CompanyCreated: Boolean;
        SpecifyCompanyNameErr: Label 'To continue, you must specify a name for the company.';
        NoConfigurationPackageFileDefinedMsg: Label 'No configuration package file is defined for this company type. An empty company will be created.';
        EvaluationDataTxt: Label '\Essential Experience / Cronus Company Sample Data / Setup Data\\Create a company with the Essential functionality scope containing everything you need to evaluate the product for companies with standard processes. For example, sample invoices and ledger entries allow you to view charts and reports.';
        StandardDataTxt: Label '\Essential Experience / Setup Data Only\\Create a company with the Essential functionality scope containing data and setup, such as a chart of accounts and payment methods ready for use by companies with standard processes. Set up your own items and customers, and start posting right away.';
        NoDataTxt: Label '\Any Experience / No Sample Data / No Setup Data\\Create a company with the desired experience for companies with any process complexity, and set it up manually.';
        ExtendedDataTxt: Label '\Advanced Experience / Cronus Company Sample Data / Setup Data\\Create a company with the Advanced functionality scope containing everything you need to evaluate the product for companies with advanced processes. For example, sample items and customers allow you to start posting right away.';
        TrialPeriodTxt: Label '\\You will be able to use this company for a 30-day trial period.';
        EvalPeriodTxt: Label '\\You will be able to use the company to try out the product for as long as you want. ';
        IsSandbox: Boolean;
        LangDifferentFromConfigurationPackageFileMsg: Label 'The language of the configuration package file is different than your current language. The new company will be created in %1.', Comment = '%1 is the language code of the pack';
        CompanySetUpInProgressMsg: Label 'Company %1 has been created, but we are still setting it up for you.\This may take up to 10 minutes, so take a short break before you begin to use it.', Comment = '%1 - a company name';
        AddUsersVisible: Boolean;
        ManageUsersLbl: Label 'Manage Users';
        CanManageUser: Boolean;
        ContainUsers: Boolean;
        OnlySuperCanManageUsersLbl: Label 'Only administrators and super users can sign in to this company and manage users.';
        OnlySuperCanCreateNewCompanyErr: Label 'Only users with the SUPER permission set can create a new company.';

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::Creation:
                ShowCreationStep();
            Step::"Add Users":
                ShowAddUsersStep();
            Step::Finish:
                ShowFinalStep();
        end;
    end;

    local procedure FinishAction()
    var
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        PermissionManager: Codeunit "Permission Manager";
    begin
        AssistedCompanySetup.CreateNewCompany(NewCompanyName);
        OnAfterCreateNewCompany(NewCompanyData.AsInteger(), NewCompanyName);

        AssistedCompanySetup.SetUpNewCompany(NewCompanyName, NewCompanyData.AsInteger(), InstallAdditionalDemoData);

        if Rec.FindSet() then
            repeat
                PermissionManager.AssignDefaultPermissionsToUser(Rec."User Security ID", NewCompanyName);
            until Rec.Next() = 0;

        CompanyCreated := true;
        OnFinishActionOnBeforeCurrPageClose(NewCompanyData.AsInteger(), NewCompanyName);
        CurrPage.Close();
        if not (NewCompanyData in [NewCompanyData::None, NewCompanyData::"Full No Data"]) then
            Message(CompanySetUpInProgressMsg, NewCompanyName);
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if (Step = Step::Creation) and not Backwards then
            if NewCompanyName = '' then
                Error(SpecifyCompanyNameErr);
        if (Step = Step::Creation) and not Backwards then
            ValidateCompanyType();

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;

        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowCreationStep()
    begin
        CreationStepVisible := true;

        FinishActionEnabled := false;
    end;

    local procedure ShowAddUsersStep()
    begin
        AddUsersVisible := true;

        FinishActionEnabled := false;
    end;

    local procedure ShowFinalStep()
    begin
        FinalStepVisible := true;
        NextActionEnabled := false;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := true;
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        CreationStepVisible := false;
        AddUsersVisible := false;
        FinalStepVisible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure ValidateCompanyType()
    var
        ConfigurationPackageFile: Record "Configuration Package File";
        UserPersonalization: Record "User Personalization";
        Language: Codeunit Language;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCompanyType(NewCompanyData, ConfigurationPackageExists, IsHandled);
        if IsHandled then
            exit;

        ConfigurationPackageExists := false;
        if NewCompanyData in [NewCompanyData::None, NewCompanyData::"Full No Data"] then
            exit;
        ConfigurationPackageExists :=
            AssistedCompanySetup.FindConfigurationPackageFile(ConfigurationPackageFile, NewCompanyData.AsInteger());

        if not ConfigurationPackageExists then
            Message(NoConfigurationPackageFileDefinedMsg)
        else begin
            UserPersonalization.Get(UserSecurityId());
            if ConfigurationPackageFile."Language ID" <> UserPersonalization."Language ID" then
                Message(LangDifferentFromConfigurationPackageFileMsg,
                  Language.GetWindowsLanguageName(ConfigurationPackageFile."Language ID"));
        end;
    end;

    local procedure UpdateDataDescription()
    var
        TenantLicenseState: Codeunit "Tenant License State";
    begin
        case NewCompanyData of
            NewCompanyData::"Evaluation Data":
                NewCompanyDataDescription := EvaluationDataTxt;
            NewCompanyData::"Standard Data":
                NewCompanyDataDescription := StandardDataTxt;
            NewCompanyData::"Extended Data":
                NewCompanyDataDescription := ExtendedDataTxt;
            NewCompanyData::None, NewCompanyData::"Full No Data":
                NewCompanyDataDescription := NoDataTxt;
            else
                OnUpdateDataDescriptionCaseElse(NewCompanyData.AsInteger(), NewCompanyDataDescription);
        end;

        if IsSandbox then
            exit;

        if TenantLicenseState.IsPaidMode() then
            exit;

        case NewCompanyData of
            NewCompanyData::"Evaluation Data":
                NewCompanyDataDescription += EvalPeriodTxt;
            NewCompanyData::"Standard Data",
            NewCompanyData::None:
                NewCompanyDataDescription += TrialPeriodTxt;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageCheckAdditionalDemoData(var AdditionalDemoDataVisible: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateNewCompany(NewCompanyData: Option; NewCompanyName: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCompanyName(var NewCompanyName: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCompanyType(NewCompanyData: Enum "Company Data Type (Internal)"; var ConfigurationPackageExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishActionOnBeforeCurrPageClose(NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data"; NewCompanyName: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDataDescriptionCaseElse(NewCompanyData: Option; var NewCompanyDataDescription: Text)
    begin
    end;
}

