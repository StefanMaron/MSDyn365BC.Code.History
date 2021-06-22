page 4000 "Hybrid Cloud Setup Wizard"
{
    Caption = 'Data Migration Setup';
    AdditionalSearchTerms = 'migration,data migration,cloud migration,intelligent,cloud,sync,replication';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Intelligent Cloud Setup";
    Permissions = tabledata 4003 = rimd;

    layout
    {
        area(Content)
        {
            group(Banner1)
            {
                Editable = false;
                Visible = TopBannerVisible and not DoneVisible;
                ShowCaption = false;
                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Banner2)
            {
                Editable = false;
                Visible = TopBannerVisible and DoneVisible;
                ShowCaption = false;
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                ShowCaption = false;
                Visible = IntroVisible;
                group("Para1.1")
                {
                    Caption = 'Welcome to the on-premises to Business Central cloud Data Migration Setup';
                    group("Para1.1.1")
                    {
                        ShowCaption = false;
                        InstructionalText = 'This assisted setup will guide you through the necessary steps to create a configuration that will enable data migration from your on-premises Dynamics solution to your Business Central cloud tenant.  Upon completion of the migration, additional steps may be required before transacting in your Business Central cloud tenant.  See setup checklists for more information.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Warning';
                    group("Para1.2.1")
                    {
                        ShowCaption = false;
                        InstructionalText = 'Migrating data from on-premises to your Business Central cloud solution may overwrite any existing data in your Business Central cloud tenant. Refer to Help for more information.';

                        field(HelpTxt; HelpTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            begin
                                Hyperlink(HelpUrlTxt);
                            end;
                        }
                        group("Para1.2.2")
                        {
                            ShowCaption = false;
                            InstructionalText = 'This migration process leverages Microsoft’s Azure Data Factory, which may offer varying levels of compliance. Refer to the Privacy Notice for more information.';

                            field(PrivacyNotice; PrivacyNoticeTxt)
                            {
                                ApplicationArea = Basic, Suite;
                                ShowCaption = false;

                                trigger OnDrillDown()
                                begin
                                    Hyperlink(PrivacyNoticeUrlTxt);
                                end;
                            }
                            field(AgreePrivacy; AgreePrivacy)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'I accept warning & privacy notice.';
                                ShowCaption = true;

                                trigger OnValidate()
                                begin
                                    if AgreePrivacy then
                                        NextEnabled := true
                                    else
                                        NextEnabled := false;
                                end;
                            }
                        }
                    }
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = ProductTypeVisible;
                group("Para2.1")
                {
                    Caption = 'Choose Your Product';
                    InstructionalText = 'Select the product that you want to migrate data from';
                    group("Para2.1.1")
                    {
                        Caption = '';
                        field("Product Name"; HybridProductType."Display Name")
                        {
                            Caption = 'Product';
                            ApplicationArea = Basic, Suite;
                            AssistEdit = true;
                            Editable = false;

                            trigger OnAssistEdit()
                            var
                                HybridProduct: Page "Hybrid Product Types";
                            begin
                                HybridProduct.SetTableView(HybridProductType);
                                HybridProduct.SetRecord(HybridProductType);
                                HybridProduct.LookupMode(true);
                                HybridProduct.RunModal();
                                HybridProduct.GetRecord(HybridProductType);

                                "Product ID" := HybridProductType.ID;
                                NextEnabled := true;
                            end;
                        }
                    }
                }
            }
            group(Step3)
            {
                Caption = '';
                Visible = SQLServerTypeVisible;
                group("Para3.1")
                {
                    Caption = 'Define your SQL database connection';
                    field("Sql Server Type"; "Sql Server Type")
                    {
                        Caption = 'SQL Configuration';
                        ApplicationArea = Basic, Suite;
                        OptionCaption = 'SQL Server,Azure SQL';

                        trigger OnValidate()
                        begin
                            IsChanged := IsChanged or (rec."Sql Server Type" <> xRec."Sql Server Type");
                        end;
                    }
                }
                group("Para3.2")
                {
                    Caption = '';
                    InstructionalText = 'Enter the connection string to your SQL database';
                    field(SqlConnectionString; SqlConnectionString)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'SQL Connection String';
                        ExtendedDatatype = Masked;
                        ToolTip = ': Server=myServerName\myInstanceName;Database=myDataBase;User Id=myUsername;Password=myPassword;';

                        trigger OnValidate()
                        begin
                            IsChanged := true;
                        end;
                    }
                }
                group("Para3.3")
                {
                    Caption = '';
                    InstructionalText = 'If you already have an integration runtime service instance installed and want to reuse it, specify the Integration Runtime; otherwise leave the field empty to create a new Integration Runtime.';
                    Enabled = ("Sql Server Type" = "Sql Server Type"::SQLServer);
                    field(RuntimeName; RuntimeName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Integration Runtime Name';
                        ToolTip = 'The Integration Runtime name is found in the Microsoft Integration Configuration Manager.';

                        trigger OnValidate()
                        begin
                            IsChanged := true;
                            if RuntimeName = '' then
                                IsRunTimeNameCleared := true;
                        end;
                    }
                }
            }
            group(Step4)
            {
                Caption = '';
                Visible = IRInstructionsVisible;
                group("Para4.1")
                {
                    Caption = 'Instructions';
                    group("Para4.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'The data migration requires an integration runtime service. The runtime service provides a connection between your on-premises solution and your Business Central cloud tenant.';

                        field(DownloadShir; DownloadShirLinkTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '';
                            trigger OnDrillDown()
                            begin
                                Hyperlink(DownloadShirURLTxt);
                            end;
                        }
                        field(RuntimeInstructions2; '2. Install the integration runtime on your on-premises database server')
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(RuntimeInstructions3; '3. Copy the authentication key provided below and paste it into the SHIR')
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(RuntimeInstructions4; '4. Choose Next to verify all the connections are working')
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                    }
                }
                group("4.2")
                {
                    Caption = '';
                    field(RuntimeKey; RuntimeKey)
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = false;
                        Caption = 'Authentication Key:';
                    }
                }
            }
            group(Step5)
            {
                ShowCaption = false;
                Visible = CompanySelectionVisible;
                group("Para5.1")
                {
                    ShowCaption = false;
                    group("Para5.1.1")
                    {
                        ShowCaption = false;
                        part(pageHybridCompanies; "Hybrid Companies")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '';
                            UpdatePropagation = Both;
                        }
                    }
                    group("Para5.1.2")
                    {
                        ShowCaption = false;
                        field(SelectAll; SelectAll)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Migrate all companies';
                            trigger OnValidate();
                            var
                                HybridCompany: Record "Hybrid Company";
                            begin
                                HybridCompany.SetSelected(SelectAll);
                                Commit();
                                CurrPage.Update();
                            end;
                        }
                    }
                    group("Para5.1.3")
                    {
                        ShowCaption = false;
                        group("Para5.1.3.1")
                        {
                            ShowCaption = false;
                            InstructionalText = 'If you have selected a company that does not exist in Business Central, it will automatically be created for you. This may take a few minutes.';
                        }
                    }
                }
            }
            group(Step6)
            {
                Caption = '';
                Visible = ScheduleVisible;
                group("Para6.1")
                {
                    Caption = 'Schedule Data Migration';
                    group("Para6.1.1")
                    {
                        Caption = '';
                        Visible = ScheduleVisible;
                        InstructionalText = 'Specify when to migrate your data to Business Central. To skip this step, select Next. To setup or change your migration schedule in Business Central, search for ''Cloud Migration Management''.';
                        field("Replication Enabled"; "Replication Enabled")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Activate Schedule';
                            ToolTip = 'Activate Migration Schedule';

                            trigger OnValidate()
                            begin
                                IsChanged := IsChanged or (Rec."Replication Enabled" <> xRec."Replication Enabled");
                            end;
                        }
                        field(Recurrence; Recurrence)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Recurrence';
                        }
                        group("Para6.1.1.2")
                        {
                            ShowCaption = false;
                            Visible = (Recurrence = Recurrence::Weekly);
                            grid("Days1")
                            {
                                ShowCaption = false;

                                field(Sunday; Sunday)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Enabled = Recurrence = Recurrence::Weekly;

                                    trigger OnValidate()
                                    begin
                                        IsChanged := IsChanged or (rec.Sunday <> xRec.Sunday);
                                    end;
                                }
                                field(Monday; Monday)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Enabled = Recurrence = Recurrence::Weekly;

                                    trigger OnValidate()
                                    begin
                                        IsChanged := IsChanged or (rec.Monday <> xRec.Monday);
                                    end;
                                }
                                field(Tuesday; Tuesday)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Enabled = Recurrence = Recurrence::Weekly;

                                    trigger OnValidate()
                                    begin
                                        IsChanged := IsChanged or (rec.Tuesday <> xRec.Tuesday);
                                    end;
                                }
                            }
                            grid("Days2")
                            {
                                ShowCaption = false;
                                field(Wednesday; Wednesday)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Enabled = Recurrence = Recurrence::Weekly;

                                    trigger OnValidate()
                                    begin
                                        IsChanged := IsChanged or (rec.Wednesday <> xRec.Wednesday);
                                    end;
                                }
                                field(Thursday; Thursday)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Enabled = Recurrence = Recurrence::Weekly;

                                    trigger OnValidate()
                                    begin
                                        IsChanged := IsChanged or (rec.Thursday <> xRec.Thursday);
                                    end;
                                }
                                field(Friday; Friday)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Enabled = Recurrence = Recurrence::Weekly;

                                    trigger OnValidate()
                                    begin
                                        IsChanged := IsChanged or (rec.Friday <> xRec.Friday);
                                    end;
                                }
                            }
                            grid("Days4")
                            {
                                ShowCaption = false;
                                field(Saturday; Saturday)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Enabled = Recurrence = Recurrence::Weekly;

                                    trigger OnValidate()
                                    begin
                                        IsChanged := IsChanged or (rec.Saturday <> xRec.Saturday);
                                    end;
                                }
                                field(Empty1; '')
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = '';
                                }
                                field(Empty2; '')
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = '';
                                }
                            }
                        }
                    }
                    group("Para6.2.1")
                    {
                        Caption = '';
                        field("Time to Run"; "Time to Run")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Start time';
                            ToolTip = 'Specifies the time at which to start the migration.';

                            trigger OnValidate()
                            begin
                                IsChanged := IsChanged or (rec."Time to Run" <> xRec."Time to Run");
                            end;
                        }
                    }
                }
            }
            group(StepFinish)
            {
                Caption = '';
                Visible = DoneVisible;
                group(AllDone)
                {
                    Caption = 'That''s It!';
                    InstructionalText = 'Choose finish to close the wizard.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackEnabled;
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
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    HybridCompany: Record "Hybrid Company";
                begin
                    if (Step = Step::Intro) and (not IsSaas) then begin
                        NavigateToBusinessCentral();
                        CurrPage.Close();
                    end;

                    if (Step = Step::SQLServerType) then
                        ValidateSqlConnectionString();

                    if Step = Step::ProductType then
                        if HybridProductType."Display Name" = '' then
                            Error(NoProductSelectedErr);

                    if Step = Step::CompanySelection then begin
                        HybridCompany.Reset();
                        HybridCompany.SetRange(Replicate, true);

                        if not HybridCompany.FindSet() then
                            Error(NoCompaniesSelectedErr);

                        HybridCompany.SetRange(Name, CompanyName());

                        if not HybridCompany.IsEmpty() then
                            Error(CannotEnableReplicationForCompanyErr);
                    end;

                    if Step = Step::Schedule then
                        ScheduleReplication();

                    NextStep(false);
                end;
            }

            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    AssistedSetup: Codeunit "Assisted Setup";
                    Info: ModuleInfo;
                begin
                    NavApp.GetCurrentModuleInfo(Info);
                    AssistedSetup.Complete(Info.Id(), PAGE::"Hybrid Cloud Setup Wizard");
                    Validate("Replication User", UserId());
                    CheckAndCleanupTableMapping();

                    CurrPage.Close();
                    HybridCloudManagement.CreateCompanies();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        if not HybridCloudManagement.CanSetupIntelligentCloud() then
            Error(RunWizardPermissionErr);

        LoadTopBanners();

        if not Get() then begin
            Init();
            Insert();
            Commit();
        end;
    end;

    trigger OnOpenPage()
    begin
        IsSaas := EnvironmentInfo.IsSaaS();
        if GetFilter("Product ID") = 'TM' then begin
            IsIntelligentCloud := true;
            Reset();
        end else
            IsIntelligentCloud := false;

        if (GetFilter("Primary Key") = HybridCloudManagement.GetRedirectFilter()) then begin
            Step := Step::ProductType;
            ShowProductTypeStep(false);
        end else
            ShowIntroStep(false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AssistedSetup: Codeunit "Assisted Setup";
    begin
        if CloseAction = Action::OK then
            if (AssistedSetup.ExistsAndIsNotComplete(PAGE::"Hybrid Cloud Setup Wizard")) and IsSaas then
                if not Confirm(HybridNotSetupQst, false) then
                    error('');
    end;

    local procedure CheckAndCleanupTableMapping()
    var
        MigrationTableMapping: Record "Migration Table Mapping";
        IntelligentCloudManagement: Page "Intelligent Cloud Management";
        CanMapTables: Boolean;
    begin
        IntelligentCloudManagement.CanMapCustomTables(CanMapTables);
        if not CanMapTables then
            MigrationTableMapping.DeleteAll();
    end;

    protected var
        [InDataSet]
        ProductSpecificSettingsVisible: Boolean;

    var
        HybridProductType: Record "Hybrid Product Type" temporary;
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        EnvironmentInfo: Codeunit "Environment Information";
        IsChanged: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        ProductTypeVisible: Boolean;
        SQLServerTypeVisible: Boolean;
        IRInstructionsVisible: Boolean;
        CompanySelectionVisible: Boolean;
        ScheduleVisible: Boolean;
        DoneVisible: Boolean;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        IsRunTimeNameCleared: Boolean;
        IsSaas: Boolean;
        SelectAll: Boolean;
        AgreePrivacy: Boolean;
        IsIntelligentCloud: Boolean;
        Step: Option Intro,ProductType,SQLServerType,IRInstructions,CompanySelection,ProductSpecificSettings,Schedule,Done;
        SqlConnectionString: Text;
        RuntimeName: Text;
        RuntimeKey: Text;
        DownloadShirLinkTxt: Label '1. Download the Self Hosted Integration Runtime(SHIR).';
        DownloadShirURLTxt: Label 'https://www.microsoft.com/en-us/download/details.aspx?id=39717', Locked = true;
        PrivacyNoticeTxt: Label 'Privacy Notice';
        PrivacyNoticeUrlTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=724009', Locked = true;
        HelpTxt: Label 'Help';
        HelpUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2009758', Locked = true;
        SqlConnectionStringMissingErr: Label 'Please enter a valid SQL connection string.';
        HybridNotSetupQst: Label 'Your Cloud Migration environment has not been set up.\\Are you sure that you want to exit?';
        NoProductSelectedErr: Label 'You must select a product to continue.';
        NoCompaniesSelectedErr: Label 'You must select at least one company to replicate to continue.';
        NoScheduleTimeErr: Label 'You must set a schedule time to continue.';
        DoneWithSignupMsg: Label 'Redirecting to SaaS Business Central solution.';
        NotificationIdTxt: Label 'ce917438-506c-4724-9b01-13c1b860e851', Locked = true;
        RunWizardPermissionErr: Label 'You do not have permissions to execute this task. Contact your system administrator.';
        CannotEnableReplicationForCompanyErr: Label 'The current company may not be enabled for replication.';

    local procedure NextStep(Backwards: Boolean)
    var
        TempStep: Option;
        ShowSettingsStep: Boolean;
    begin
        TempStep := Step;

        IncrementStep(Backwards, TempStep);

        case TempStep of
            Step::Intro:
                ShowIntroStep(Backwards);
            Step::ProductType:
                ShowProductTypeStep(Backwards);
            Step::SQLServerType:
                ShowSQLServerTypeStep(Backwards);
            Step::IRInstructions:
                if (("Sql Server Type" = "Sql Server Type"::AzureSQL) or (RuntimeName <> '')) then begin
                    IncrementStep(Backwards, Step);
                    NextStep(Backwards);
                    exit;
                end else
                    ShowIRInstructionsStep(Backwards);
            Step::CompanySelection:
                if IsRunTimeNameCleared and (RuntimeKey = '') then begin
                    IncrementStep(true, Step);
                    NextStep(Backwards);
                    exit;
                end else
                    ShowCompanySelectionStep(Backwards);
            Step::ProductSpecificSettings:
                begin
                    HybridCloudManagement.OnBeforeShowProductSpecificSettingsPageStep(HybridProductType, ShowSettingsStep);
                    if not ShowSettingsStep then begin
                        IncrementStep(Backwards, Step);
                        NextStep(Backwards);
                        exit;
                    end else
                        ShowProductSpecificSettingsPage(Backwards);
                end;
            Step::Schedule:
                ShowScheduleStep(Backwards);
            Step::Done:
                ShowDoneStep(Backwards);
        end;

        Step := tempStep;
        CurrPage.Update(true);
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', FORMAT(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', FORMAT(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        IntroVisible := false;
        ProductTypeVisible := false;
        SQLServerTypeVisible := false;
        IRInstructionsVisible := false;
        CompanySelectionVisible := false;
        ProductSpecificSettingsVisible := false;
        ScheduleVisible := false;
        DoneVisible := false;
    end;

    local procedure ShowIntroStep(Backwards: Boolean)
    begin
        ResetWizardControls();
        IntroVisible := true;
        if not AgreePrivacy then
            NextEnabled := false;
        BackEnabled := false;
    end;

    local procedure ShowProductTypeStep(Backwards: Boolean)
    begin
        if not Backwards then
            HybridCloudManagement.OnShowProductTypeStep(HybridProductType);
        ResetWizardControls();
        ProductTypeVisible := true;
    end;

    local procedure ShowSQLServerTypeStep(Backwards: Boolean)
    begin
        if not Backwards then
            HybridCloudManagement.OnShowSQLServerTypeStep(HybridProductType);
        ResetWizardControls();
        SQLServerTypeVisible := true;
    end;

    local procedure ShowIRInstructionsStep(Backwards: Boolean)
    begin
        if not Backwards then
            HybridCloudManagement.HandleShowIRInstructionsStep(HybridProductType, RuntimeName, RuntimeKey);

        ResetWizardControls();
        IRInstructionsVisible := true;
    end;

    local procedure ShowCompanySelectionStep(Backwards: Boolean)
    var
        HybridCompany: Record "Hybrid Company";
    begin
        if not Backwards and IsChanged then begin
            HybridCloudManagement.HandleShowCompanySelectionStep(HybridProductType, SqlConnectionString, ConvertSqlServerTypeToText(), RuntimeName);
            IsChanged := false;
        end;

        ResetWizardControls();
        CompanySelectionVisible := true;

        // Dummy record insert and delete to refresh the list
        HybridCompany.Insert();
        HybridCompany.Delete();

        CurrPage.Update();
    end;

    local procedure ShowProductSpecificSettingsPage(Backwards: Boolean)
    begin
        ResetWizardControls();
        ProductSpecificSettingsVisible := true;
        NextEnabled := true;
    end;

    local procedure ShowScheduleStep(Backwards: Boolean)

    begin
        if not Backwards then
            HybridCloudManagement.OnShowScheduleStep(HybridProductType);
        ResetWizardControls();
        ScheduleVisible := true;
        NextEnabled := true;
    end;

    local procedure ShowDoneStep(Backwards: Boolean)
    begin
        if not Backwards then
            HybridCloudManagement.OnShowDoneStep(HybridProductType);
        ResetWizardControls();
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;
    end;

    local procedure NavigateToBusinessCentral();
    var
        sendNotification: Notification;
    begin
        Hyperlink(HybridCloudManagement.GetSaasWizardRedirectUrl(Rec));
        sendNotification.id := NotificationIdTxt;
        sendNotification.Message := DoneWithSignupMsg;
        sendNotification.Scope := NotificationScope::LocalScope;
        sendNotification.Send();
    end;

    local procedure ScheduleReplication()
    begin
        if "Replication Enabled" and (Format("Time to Run") = '') then
            Error(NoScheduleTimeErr);
        if IsChanged then begin
            SetReplicationSchedule();
            IsChanged := false;
        end;
        NextEnabled := true;
    end;

    local procedure ValidateSqlConnectionString()
    begin
        if SqlConnectionString = '' then
            Error(SqlConnectionStringMissingErr);
    end;

    local procedure IncrementStep(Backwards: Boolean; var Step: Option)
    begin
        if (Backwards) then
            Step -= 1
        else
            Step += 1;
    end;
}