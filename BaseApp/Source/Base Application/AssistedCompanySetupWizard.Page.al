page 1803 "Assisted Company Setup Wizard"
{
    Caption = 'Company Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    PromotedActionCategories = 'New,Process,Report,Step 4,Step 5';
    ShowFilter = false;
    SourceTable = "Config. Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT DoneVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND DoneVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                Visible = IntroVisible;
                group("Welcome to Company Setup.")
                {
                    Caption = 'Welcome to Company Setup.';
                    InstructionalText = 'To prepare Dynamics 365 Business Central for first use, you must specify some basic information about your company. This information is used on your external documents, such as sales invoices, and includes your company logo and bank information. You must also set up the fiscal year.';
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next so you can specify basic company information.';
                }
            }
            group(Control18)
            {
                ShowCaption = false;
                Visible = SelectTypeVisible AND TypeSelectionEnabled;
                group("Standard Setup")
                {
                    Caption = 'Standard Setup';
                    InstructionalText = 'The company will be ready to use when Setup has completed.';
                    Visible = StandardVisible;
                    field(Standard; TypeStandard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Set up as Standard';

                        trigger OnValidate()
                        begin
                            if TypeStandard then
                                TypeEvaluation := false;
                            CalcCompanyData;
                        end;
                    }
                }
                group("Evaluation Setup")
                {
                    Caption = 'Evaluation Setup';
                    InstructionalText = 'The company will be set up in demonstration mode for exploring and testing.';
                    Visible = EvaluationVisible;
                    field(Evaluation; TypeEvaluation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Set up as Evaluation';

                        trigger OnValidate()
                        begin
                            if TypeEvaluation then
                                TypeStandard := false;
                            CalcCompanyData;
                        end;
                    }
                }
                group(Important)
                {
                    Caption = 'Important';
                    InstructionalText = 'You cannot change your choice of setup after you choose Next.';
                    Visible = TypeStandard OR TypeEvaluation;
                }
            }
            group(Control56)
            {
                ShowCaption = false;
                Visible = CompanyDetailsVisible;
                group("Specify your company's address information and logo.")
                {
                    Caption = 'Specify your company''s address information and logo.';
                    InstructionalText = 'This is used in invoices and other documents where general information about your company is printed.';
                    field(Name; Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Company Name';
                        NotBlank = true;
                        ShowMandatory = true;
                    }
                    field(Address; Address)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(City; City)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        TableRelation = "Country/Region".Code;
                    }
                    field("VAT Registration No."; "VAT Registration No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                    field("Industrial Classification"; "Industrial Classification")
                    {
                        ApplicationArea = Basic, Suite;
                        NotBlank = true;
                        ShowMandatory = true;
                        Visible = false;
                    }
                    field(Picture; Picture)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Company Logo';

                        trigger OnValidate()
                        begin
                            LogoPositionOnDocumentsShown := Picture.HasValue;
                            if LogoPositionOnDocumentsShown then begin
                                if "Logo Position on Documents" = "Logo Position on Documents"::"No Logo" then
                                    "Logo Position on Documents" := "Logo Position on Documents"::Right;
                            end else
                                "Logo Position on Documents" := "Logo Position on Documents"::"No Logo";
                            CurrPage.Update(true);
                        end;
                    }
                }
            }
            group(Control45)
            {
                ShowCaption = false;
                Visible = CommunicationDetailsVisible;
                group("Specify the contact details for your company.")
                {
                    Caption = 'Specify the contact details for your company.';
                    InstructionalText = 'This is used in invoices and other documents where general information about your company is printed.';
                    field("Phone No."; "Phone No.")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        var
                            TypeHelper: Codeunit "Type Helper";
                        begin
                            if "Phone No." = '' then
                                exit;

                            if not TypeHelper.IsPhoneNumber("Phone No.") then
                                Error(InvalidPhoneNumberErr)
                        end;
                    }
                    field("E-Mail"; "E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        ExtendedDatatype = EMail;

                        trigger OnValidate()
                        var
                            MailManagement: Codeunit "Mail Management";
                        begin
                            if "E-Mail" = '' then
                                exit;

                            MailManagement.CheckValidEmailAddress("E-Mail");
                        end;
                    }
                    field("Home Page"; "Home Page")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        var
                            WebRequestHelper: Codeunit "Web Request Helper";
                        begin
                            if "Home Page" = '' then
                                exit;

                            WebRequestHelper.IsValidUriWithoutProtocol("Home Page");
                        end;
                    }
                }
            }
            group(Control29)
            {
                ShowCaption = false;
                Visible = BankStatementConfirmationVisible;
                group("Bank Feed Service")
                {
                    Caption = 'Bank Feed Service';
                    InstructionalText = 'You can use a bank feeds service to import electronic bank statements from your bank to quickly process payments.';
                    field(UseBankStatementFeed; UseBankStatementFeed)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use a bank feed service';
                    }
                }
                group("NOTE:")
                {
                    Caption = 'NOTE:';
                    InstructionalText = 'When you choose Next, you accept the terms of use for the bank feed service.';
                    Visible = UseBankStatementFeed;
                    field(TermsOfUseLbl; TermsOfUseLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            HyperLink(TermsOfUseUrlTxt);
                        end;
                    }
                }
            }
            group("Select bank account.")
            {
                Caption = 'Select bank account.';
                Visible = SelectBankAccountVisible;
                part(OnlineBanckAccountLinkPagePart; "Online Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control37)
            {
                ShowCaption = false;
                Visible = PaymentDetailsVisible;
                group("Specify your company's bank information.")
                {
                    Caption = 'Specify your company''s bank information.';
                    InstructionalText = 'This information is included on documents that you send to customer and vendors to inform about payments to your bank account.';
                    field("Bank Name"; "Bank Name")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Bank Branch No."; "Bank Branch No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Bank Account No."; "Bank Account No.")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        begin
                            ShowBankAccountCreationWarning := not ValidateBankAccountNotEmpty;
                        end;
                    }
                    field("SWIFT Code"; "SWIFT Code")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(IBAN; IBAN)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                group(" ")
                {
                    Caption = ' ';
                    InstructionalText = 'To create a bank account that is linked to the related online bank account, you must specify the bank account information above.';
                    Visible = ShowBankAccountCreationWarning;
                }
            }
            group(Control6)
            {
                ShowCaption = false;
                Visible = AccountingPeriodVisible;
                group("Specify the start date of the company's fiscal year.")
                {
                    Caption = 'Specify the start date of the company''s fiscal year.';
                    InstructionalText = 'Specify the start of the company''s fiscal year, or select the Skip for Now field if you want to define accounting periods later.';
                    field(AccountingPeriodStartDate; AccountingPeriodStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Year Start Date';
                        Editable = NOT SkipAccountingPeriod;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            if (not SkipAccountingPeriod) and (AccountingPeriodStartDate = 0D) then
                                Error(AccountingPeriodStartDateBlankErr);
                            UserAccountingPeriodStartDate := AccountingPeriodStartDate;
                        end;
                    }
                    field(SkipAccountingPeriod; SkipAccountingPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip for Now';

                        trigger OnValidate()
                        begin
                            if SkipAccountingPeriod then
                                Clear(AccountingPeriodStartDate)
                            else
                                AccountingPeriodStartDate := UserAccountingPeriodStartDate;
                        end;
                    }
                }
            }
            group(Control57)
            {
                ShowCaption = false;
                Visible = CostingMethodVisible;
                group("Specify the costing method for your inventory valuation.")
                {
                    Caption = 'Specify the costing method for your inventory valuation.';
                    group(Control122)
                    {
                        InstructionalText = 'The costing method works together with the posting date and sequence to determine how to record the cost flow.';
                        ShowCaption = false;
                        field("Cost Method"; CostMethodeLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            begin
                                HyperLink(CostMethodUrlTxt);
                            end;
                        }
                        field("Costing Method"; InventorySetup."Default Costing Method")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Costing Method';
                            ShowMandatory = true;

                            trigger OnValidate()
                            var
                                ExistingInventorySetup: Record "Inventory Setup";
                            begin
                                if not ExistingInventorySetup.Get then begin
                                    InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
                                    InventorySetup."Automatic Cost Posting" := true;
                                end;

                                if InventorySetup."Default Costing Method" = InventorySetup."Default Costing Method"::Average then begin
                                    InventorySetup."Average Cost Period" := InventorySetup."Average Cost Period"::Day;
                                    InventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type"::Item;
                                end;

                                if not InventorySetup.Modify then
                                    InventorySetup.Insert;
                            end;
                        }
                    }
                }
            }
            group(Control9)
            {
                ShowCaption = false;
                Visible = DoneVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Choose Finish to prepare the application for first use. This will take a few moments.';
                    field(HelpLbl; HelpLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            HyperLink(HelpLinkTxt);
                        end;
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
                begin
                    if (Step = Step::"Select Type") and not (TypeStandard or TypeEvaluation) then
                        if not Confirm(NoSetupTypeSelectedQst, false) then
                            Error('');
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
                    AssistedCompanySetup: Codeunit "Assisted Company Setup";
                    Info: ModuleInfo;
                    ErrorText: Text;
                begin
                    AssistedCompanySetup.WaitForPackageImportToComplete;
                    BankAccount.TransferFields(TempBankAccount, true);
                    AssistedCompanySetup.ApplyUserInput(Rec, BankAccount, AccountingPeriodStartDate, TypeEvaluation);

                    UpdateCompanyDisplayNameIfNameChanged;

                    NavApp.GetCurrentModuleInfo(Info);
                    AssistedSetup.Complete(Info.Id(), PAGE::"Assisted Company Setup Wizard");
                    if (BankAccount."No." <> '') and (not TempOnlineBankAccLink.IsEmpty) then
                        if not TryLinkBankAccount then
                            ErrorText := GetLastErrorText;
                    CurrPage.Close;

                    if ErrorText <> '' then begin
                        Message(StrSubstNo(BankAccountLinkingFailedMsg, ErrorText));
                        PAGE.Run(PAGE::"Bank Account List");
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LogoPositionOnDocumentsShown := Picture.HasValue;
    end;

    trigger OnInit()
    begin
        InitializeRecord;
        LoadTopBanners;
    end;

    trigger OnOpenPage()
    begin
        ResetWizardControls;
        ShowIntroStep;
        TypeSelectionEnabled := LoadConfigTypes and not PackageImported;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
    begin
        if CloseAction = ACTION::OK then begin
            NavApp.GetCurrentModuleInfo(Info);
            if AssistedSetup.ExistsAndIsNotComplete(Info.Id(), PAGE::"Assisted Company Setup Wizard") then
                if not Confirm(NotSetUpQst, false) then
                    Error('');
        end;
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        TempSavedBankAccount: Record "Bank Account" temporary;
        TempBankAccount: Record "Bank Account" temporary;
        BankAccount: Record "Bank Account";
        TempOnlineBankAccLink: Record "Online Bank Acc. Link" temporary;
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        InventorySetup: Record "Inventory Setup";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
        AccountingPeriodStartDate: Date;
        UserAccountingPeriodStartDate: Date;
        CompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        TypeStandard: Boolean;
        TypeEvaluation: Boolean;
        Step: Option Intro,Sync,"Select Type","Company Details","Communication Details",BankStatementFeed,SelectBankAccont,"Payment Details","Accounting Period","Costing Method",Done;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        SelectTypeVisible: Boolean;
        CompanyDetailsVisible: Boolean;
        CommunicationDetailsVisible: Boolean;
        PaymentDetailsVisible: Boolean;
        AccountingPeriodVisible: Boolean;
        CostingMethodVisible: Boolean;
        DoneVisible: Boolean;
        TypeSelectionEnabled: Boolean;
        StandardVisible: Boolean;
        EvaluationVisible: Boolean;
        SkipAccountingPeriod: Boolean;
        NotSetUpQst: Label 'The application has not been set up. Setup will continue the next time you start the program.\\Are you sure that you want to exit?';
        HideBankStatementProvider: Boolean;
        NoSetupTypeSelectedQst: Label 'You have not selected any setup type. If you proceed, the application will not be fully functional, until you set it up manually.\\Do you want to continue?';
        HelpLbl: Label 'Learn more about setting up your company';
        HelpLinkTxt: Label 'http://go.microsoft.com/fwlink/?LinkId=746160', Locked = true;
        BankStatementConfirmationVisible: Boolean;
        UseBankStatementFeed: Boolean;
        UseBankStatementFeedInitialized: Boolean;
        BankAccountInformationUpdated: Boolean;
        SelectBankAccountVisible: Boolean;
        TermsOfUseLbl: Label 'Envestnet Yodlee Terms of Use';
        TermsOfUseUrlTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=746179', Locked = true;
        LogoPositionOnDocumentsShown: Boolean;
        ShowBankAccountCreationWarning: Boolean;
        InvalidPhoneNumberErr: Label 'The phone number is invalid.';
        CostMethodeLbl: Label 'Learn more';
        CostMethodUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=858295', Locked = true;
        BankAccountLinkingFailedMsg: Label 'Linking the company bank account failed with the following message:\''%1''\Link the company bank account from the Bank Accounts page.', Comment = '%1 - an error message';
        AccountingPeriodStartDateBlankErr: Label 'You have not specified a start date for the fiscal year. You must either specify a date in the Fiscal Year Start Date field or select the Skip for Now field.';

    local procedure NextStep(Backwards: Boolean)
    begin
        ResetWizardControls;

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Intro:
                ShowIntroStep;
            Step::Sync:
                ShowSyncStep(Backwards);
            Step::"Select Type":
                if not TypeSelectionEnabled then
                    NextStep(Backwards)
                else
                    ShowSelectTypeStep;
            Step::"Company Details":
                if TypeEvaluation then begin
                    Step := Step::Done;
                    ShowDoneStep;
                end else
                    ShowCompanyDetailsStep;
            Step::"Communication Details":
                ShowCommunicationDetailsStep;
            Step::BankStatementFeed:
                if not ShowBankStatementFeedStep then
                    NextStep(Backwards)
                else
                    ShowBankStatementFeedConfirmation;
            Step::SelectBankAccont:
                begin
                    if not Backwards then
                        ShowOnlineBankStatement;
                    if not ShowSelectBankAccountStep then
                        NextStep(Backwards)
                    else
                        ShowSelectBankAccount;
                end;
            Step::"Payment Details":
                begin
                    if not Backwards then
                        PopulateBankAccountInformation;
                    ShowPaymentDetailsStep;
                    ShowBankAccountCreationWarning := not ValidateBankAccountNotEmpty;
                end;
            Step::"Accounting Period":
                if SkipAccountingPeriod then
                    NextStep(Backwards)
                else
                    ShowAccountingPeriodStep;
            Step::"Costing Method":
                ShowCostingMethodStep;
            Step::Done:
                ShowDoneStep;
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        IntroVisible := true;
        BackEnabled := false;
    end;

    local procedure ShowSyncStep(Backwards: Boolean)
    begin
        NextStep(Backwards);
    end;

    local procedure ShowSelectTypeStep()
    begin
        SelectTypeVisible := true;
    end;

    local procedure ShowCompanyDetailsStep()
    begin
        CompanyDetailsVisible := true;
        if TypeSelectionEnabled then begin
            StartConfigPackageImport;
            BackEnabled := false;
        end;
    end;

    local procedure ShowCommunicationDetailsStep()
    begin
        CommunicationDetailsVisible := true;
    end;

    local procedure ShowPaymentDetailsStep()
    begin
        PaymentDetailsVisible := true;
    end;

    local procedure ShowOnlineBankStatement()
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if CompanyInformationMgt.IsDemoCompany then
            exit;

        if HideBankStatementProvider then
            exit;

        TempOnlineBankAccLink.Reset;
        TempOnlineBankAccLink.DeleteAll;

        if not TempBankAccount.StatementProvidersExist then
            exit;

        if UseBankStatementFeed then begin
            TempBankAccount.SimpleLinkStatementProvider(TempOnlineBankAccLink);
            if TempOnlineBankAccLink.FindFirst then
                if not TempOnlineBankAccLink.IsEmpty then begin
                    CurrPage.OnlineBanckAccountLinkPagePart.PAGE.SetRecs(TempOnlineBankAccLink);
                    HideBankStatementProvider := true;
                end;
        end else begin
            TempBankAccount.UnlinkStatementProvider;
            TempBankAccount.DisableStatementProviders;
        end;
    end;

    local procedure ShowAccountingPeriodStep()
    begin
        AccountingPeriodVisible := true;
    end;

    local procedure ShowCostingMethodStep()
    begin
        if InventorySetup.Get then;
        CostingMethodVisible := true;
    end;

    local procedure ShowDoneStep()
    begin
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;
        if TypeEvaluation then begin
            StartConfigPackageImport;
            BackEnabled := false;
        end;
    end;

    local procedure ResetWizardControls()
    begin
        CompanyData := CompanyData::None;

        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        IntroVisible := false;
        SelectTypeVisible := false;
        CompanyDetailsVisible := false;
        CommunicationDetailsVisible := false;
        BankStatementConfirmationVisible := false;
        SelectBankAccountVisible := false;
        PaymentDetailsVisible := false;
        AccountingPeriodVisible := false;
        CostingMethodVisible := false;
        DoneVisible := false;
    end;

    local procedure InitializeRecord()
    var
        CompanyInformation: Record "Company Information";
        AccountingPeriod: Record "Accounting Period";
    begin
        Init;

        if CompanyInformation.Get then begin
            TransferFields(CompanyInformation);
            if Name = '' then
                Name := CompanyName;
        end else
            Name := CompanyName;

        SkipAccountingPeriod := not AccountingPeriod.IsEmpty;
        if not SkipAccountingPeriod then begin
            AccountingPeriodStartDate := CalcDate('<-CY>', Today);
            UserAccountingPeriodStartDate := AccountingPeriodStartDate;
        end;

        Insert;
    end;

    local procedure CalcCompanyData()
    begin
        CompanyData := CompanyData::None;
        if TypeStandard then
            CompanyData := CompanyData::"Standard Data";
        if TypeEvaluation then
            CompanyData := CompanyData::"Evaluation Data";
    end;

    local procedure StartConfigPackageImport()
    begin
        if not TypeSelectionEnabled then
            exit;
        if CompanyData in [CompanyData::None, CompanyData::"Full No Data"] then
            exit;
        if AssistedCompanySetup.IsCompanySetupInProgress(CompanyName) then
            exit;
        AssistedCompanySetup.FillCompanyData(CompanyName, CompanyData);
    end;

    local procedure LoadConfigTypes(): Boolean
    begin
        StandardVisible :=
          AssistedCompanySetup.ExistsConfigurationPackageFile(CompanyData::"Standard Data");
        EvaluationVisible :=
          AssistedCompanySetup.ExistsConfigurationPackageFile(CompanyData::"Evaluation Data");
        exit(StandardVisible or EvaluationVisible);
    end;

    local procedure PackageImported(): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        AssistedCompanySetupStatus.Get(CompanyName);
        exit(AssistedCompanySetupStatus."Package Imported" or AssistedCompanySetupStatus."Import Failed");
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType)) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure PopulateBankAccountInformation()
    begin
        if BankAccountInformationUpdated then
            if TempOnlineBankAccLink.Count = 0 then begin
                RestoreBankAccountInformation(TempSavedBankAccount);
                exit;
            end;

        if TempOnlineBankAccLink.Count = 1 then
            TempOnlineBankAccLink.FindFirst
        else
            CurrPage.OnlineBanckAccountLinkPagePart.PAGE.GetRecord(TempOnlineBankAccLink);

        if (TempBankAccount."Bank Account No." = TempOnlineBankAccLink."Bank Account No.") and
           (TempBankAccount.Name = TempOnlineBankAccLink.Name)
        then
            exit;

        if not IsBankAccountFormatValid(TempOnlineBankAccLink."Bank Account No.") then
            Clear(TempOnlineBankAccLink."Bank Account No.");

        if not BankAccountInformationUpdated then
            StoreBankAccountInformation(TempSavedBankAccount);

        TempBankAccount.Init;
        TempBankAccount.CreateNewAccount(TempOnlineBankAccLink);
        RestoreBankAccountInformation(TempBankAccount);
        BankAccountInformationUpdated := true;
    end;

    local procedure StoreBankAccountInformation(var BufferBankAccount: Record "Bank Account")
    begin
        if not BufferBankAccount.IsEmpty then
            exit;
        BufferBankAccount.Init;
        BufferBankAccount."Bank Account No." := "Bank Account No.";
        BufferBankAccount.Name := "Bank Name";
        BufferBankAccount."Bank Branch No." := "Bank Branch No.";
        BufferBankAccount."SWIFT Code" := "SWIFT Code";
        BufferBankAccount.IBAN := IBAN;
        BufferBankAccount.Insert;
    end;

    local procedure RestoreBankAccountInformation(var BufferBankAccount: Record "Bank Account")
    begin
        if BufferBankAccount.IsEmpty then
            exit;
        "Bank Account No." := BufferBankAccount."Bank Account No.";
        "Bank Name" := BufferBankAccount.Name;
        "Bank Branch No." := BufferBankAccount."Bank Branch No.";
        "SWIFT Code" := BufferBankAccount."SWIFT Code";
        IBAN := BufferBankAccount.IBAN;
    end;

    local procedure ShowBankStatementFeedConfirmation()
    begin
        BankStatementConfirmationVisible := true;
    end;

    local procedure ShowBankStatementFeedStep(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        BankStatementProviderExists: Boolean;
    begin
        if not GeneralLedgerSetup.Get then
            exit(false);

        if GeneralLedgerSetup."LCY Code" = '' then
            exit(false);

        BankStatementProviderExists := BankAccount.StatementProvidersExist;

        if not UseBankStatementFeedInitialized then begin
            UseBankStatementFeed := BankStatementProviderExists;
            UseBankStatementFeedInitialized := true;
        end;

        exit(BankStatementProviderExists);
    end;

    local procedure ShowSelectBankAccountStep(): Boolean
    begin
        exit(TempOnlineBankAccLink.Count > 1);
    end;

    local procedure ShowSelectBankAccount()
    begin
        SelectBankAccountVisible := true;
    end;

    local procedure IsBankAccountFormatValid(BankAccount: Text): Boolean
    var
        VarInt: Integer;
        Which: Text;
    begin
        Which := ' -';
        exit(Evaluate(VarInt, DelChr(BankAccount, '=', Which)));
    end;

    local procedure ValidateBankAccountNotEmpty(): Boolean
    begin
        exit(("Bank Account No." <> '') or TempOnlineBankAccLink.IsEmpty);
    end;

    [TryFunction]
    local procedure TryLinkBankAccount()
    begin
        BankAccount.OnMarkAccountLinkedEvent(TempOnlineBankAccLink, BankAccount);
    end;

    local procedure UpdateCompanyDisplayNameIfNameChanged()
    var
        Company: Record Company;
    begin
        if COMPANYPROPERTY.DisplayName = Name then
            exit;

        Company.Get(CompanyName);
        Company."Display Name" := Name;
        Company.Modify;
    end;
}

