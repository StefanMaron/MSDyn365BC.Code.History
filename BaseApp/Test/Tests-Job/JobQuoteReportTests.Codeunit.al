codeunit 136314 "Job Quote Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [New Job Reports]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        ReportLayoutSelection: Record "Report Layout Selection";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;
        AmountErr: Label 'Total amount must be equal.';
        RollingBackChangesErr: Label 'Rolling back changes...';
        CurrencyField: Option "Local Currency","Foreign Currency";
        AmountField: Option " ",Quantity,"Unit Price","Total Price";
        ValueNotFoundErr: Label 'Value must exist.';
        QuantityTxt: Label 'Quantity';
        UnitCostTxt: Label 'Unit Cost';
        TotalCostTxt: Label 'Total Cost';
        JobTaskNoTxt: Label 'Job Task No.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Quote Report Tests");
        BindActiveDirectoryMockEvents;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Quote Report Tests");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        RemoveReportLayout;

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Quote Report Tests");
    end;

    local procedure TearDown()
    begin
        Clear(Job);
        asserterror Error(RollingBackChangesErr);
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPlanningLineReportHeading()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize;
        SetReportLayoutForRDLC;
        // [WHEN] Job Quote report is run
        SetupForJobQuote(JobPlanningLine);

        // [THEN] Verify Job Quote report header information
        VerifyJobQuoteReportHeading(Job);

        // Cleanup
        RemoveReportLayout;
        TearDown;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintPreviewJobQuoteFromJobCard()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize;
        SetReportLayoutForRDLC;
        // [WHEN] Job Quote report is run
        SetupForJobQuote(JobPlanningLine);

        // [THEN] Verify contents on Job Quote report
        VerifyJobQuoteReport(JobPlanningLine, QuantityTxt, UnitCostTxt, TotalCostTxt, JobTaskNoTxt);

        // Cleanup
        RemoveReportLayout;
        TearDown;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,PostandSendPageHandlerNo')]
    [Scope('OnPrem')]
    procedure PrintPreviewJobQuoteFromJobList()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobList: TestPage "Job List";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize;
        SetReportLayoutForCustomWord;
        SetupForJobQuote(JobPlanningLine);

        // [WHEN] Job list is opened with the newly-created job
        JobList.Trap;
        PAGE.Run(PAGE::"Job List", Job);

        // [WHEN] Run "Send Job Quote" action
        JobList."Send Job Quote".Invoke;

        // [THEN] Post and Send Confirmation for the Job Quote page appears -- Page 365

        // Cleanup
        RemoveReportLayout;
        TearDown
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,PostandSendPageHandlerYes,SendEmailModalPageHandler')]
    [Scope('OnPrem')]
    procedure SendJobQuoteFromJobCardSMTPSetup() // To be removed together with deprecated SMTP objects
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(false);
        SendJobQuoteFromJobCardInternal();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,PostandSendPageHandlerYes,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SendJobQuoteFromJobCard()
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
        SendJobQuoteFromJobCardInternal();
    end;

    procedure SendJobQuoteFromJobCardInternal()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobCard: TestPage "Job Card";
        LibraryWorkflow: Codeunit "Library - Workflow";
        EmailFeature: Codeunit "Email Feature";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize;
        SetReportLayoutForRDLC;
        SetupForJobQuote(JobPlanningLine);
        if EmailFeature.IsEnabled() then
            LibraryWorkflow.SetUpEmailAccount();

        // [THEN] Verify contents on Job Quote report
        VerifyJobQuoteReport(JobPlanningLine, QuantityTxt, UnitCostTxt, TotalCostTxt, JobTaskNoTxt);

        // [WHEN] Job card is opened with the newly-created job
        JobCard.Trap;
        PAGE.Run(PAGE::"Job Card", Job);

        // [WHEN] Run "Send Job Quote" action
        CreateDocumentLayoutForCustomer(Job);
        JobCard."Send Job Quote".Invoke;

        // [THEN] Post and Send Confirmation for the Job Quote page appears -- Page 365

        // Cleanup
        RemoveReportLayout;
        TearDown;
    end;

    local procedure RunJobQuoteReport(No: Code[20])
    var
        Job: Record Job;
        JobQuote: Report "Job Quote";
    begin
        Job.SetRange("No.", No);
        Clear(JobQuote);
        JobQuote.SetTableView(Job);
        LibraryReportValidation.SetFileName(CreateGuid);
        JobQuote.SaveAsExcel(LibraryReportValidation.GetFileName);
        LibraryReportValidation.DownloadFile;
    end;

    local procedure VerifyJobQuoteReport(JobPlanningLine: Record "Job Planning Line"; Column: Text[250]; Column2: Text[250]; Column3: Text[250]; Column4: Text[250])
    begin
        LibraryReportValidation.OpenFile;
        LibraryReportValidation.SetRange(JobPlanningLine.FieldCaption("Job Task No."), Format(JobPlanningLine."Job Task No."));
        LibraryReportValidation.SetColumn(Column);
        Assert.AreEqual(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine.Quantity), true, ValueNotFoundErr);
        LibraryReportValidation.SetColumn(Column2);
        Assert.AreEqual(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Unit Price"), true, ValueNotFoundErr);
        LibraryReportValidation.SetColumn(Column3);
        Assert.AreEqual(LibraryReportValidation.CheckIfDecimalValueExists(JobPlanningLine."Total Price"), true, ValueNotFoundErr);
        LibraryReportValidation.SetColumn(Column4);
        Assert.AreEqual(LibraryReportValidation.CheckIfValueExists(JobPlanningLine."Job Task No."), true, ValueNotFoundErr);

        Assert.AreEqual(JobPlanningLine.Quantity * JobPlanningLine."Unit Price", JobPlanningLine."Total Price", AmountErr);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [Scope('OnPrem')]
    procedure SetupAmountArray(var NewAmountField: array[8] of Option ,Quantity,"Unit Cost","Total Cost"; AmountOption: Option; AmountOption2: Option; AmountOption3: Option)
    begin
        NewAmountField[1] := AmountOption;
        NewAmountField[2] := AmountOption2;
        NewAmountField[3] := AmountOption3;
        NewAmountField[4] := AmountField::" ";
        NewAmountField[5] := AmountField::" ";
        NewAmountField[6] := AmountField::" ";
        NewAmountField[7] := AmountField::" ";
        NewAmountField[8] := AmountField::" ";
    end;

    [Scope('OnPrem')]
    procedure SetupCurrencyArray(var NewCurrencyField: array[8] of Option)
    var
        Counter: Integer;
    begin
        for Counter := 1 to 8 do
            NewCurrencyField[Counter] := CurrencyField;
    end;

    local procedure SetReportLayoutForRDLC()
    begin
        SetReportLayout(ReportLayoutSelection.Type::"RDLC (built-in)", '');
    end;

    local procedure SetReportLayoutForCustomWord()
    var
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportLayoutCode: Code[20];
    begin
        Clear(CustomReportLayout);
        CustomReportLayout.SetRange("Report ID", REPORT::"Job Quote");
        CustomReportLayout.SetRange("Company Name", CompanyName);
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        if CustomReportLayout.FindFirst then
            CustomReportLayoutCode := CustomReportLayout.Code;

        SetReportLayout(ReportLayoutSelection.Type::"Custom Layout", CustomReportLayoutCode);
    end;

    local procedure SetReportLayout(LayoutSelection: Integer; CustomReportLayoutCode: Code[20])
    begin
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := REPORT::"Job Quote";
        ReportLayoutSelection."Company Name" := CompanyName;
        ReportLayoutSelection.Type := LayoutSelection;
        ReportLayoutSelection."Custom Report Layout Code" := CustomReportLayoutCode;
        ReportLayoutSelection.Insert();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostandSendPageHandlerNo(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.No.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostandSendPageHandlerYes(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.Yes.Invoke;
    end;

    local procedure SetupForJobQuote(var JobPlanningLine: Record "Job Planning Line")
    var
        JobReportsII: Codeunit "Job Reports II";
        NewAmountField: array[8] of Option;
        NewCurrencyField: array[8] of Option;
    begin
        JobReportsII.CreateInitialSetupForJob(Job);

        // 1. Setup: Create Job and Job Task with Currency and create Job Planning Lines for Schedule.
        SetupAmountArray(NewAmountField, AmountField::Quantity, AmountField::"Unit Price", AmountField::"Total Price");
        SetupCurrencyArray(NewCurrencyField);

        // 2. Exercise: Run Jobs Quote Report.
        RunJobQuoteReport(Job."No.");

        // 3. Set up table buffer for report
        JobPlanningLine.SetFilter("Job No.", '=%1', Job."No.");
        JobPlanningLine.SetFilter("Line Type", '>%1', JobPlanningLine."Line Type"::Budget);
        JobPlanningLine.FindFirst;
    end;

    local procedure RemoveReportLayout()
    begin
        Clear(ReportLayoutSelection);
        ReportLayoutSelection.SetRange("Report ID", REPORT::"Job Quote");
        ReportLayoutSelection.SetRange("Company Name", CompanyName);
        ReportLayoutSelection.DeleteAll();
    end;

    local procedure VerifyJobQuoteReportHeading(Job: Record Job)
    begin
        LibraryReportValidation.OpenFile;
        with Job do
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExists(StrSubstNo('%1: %2: %3', TableCaption, FieldCaption("No."), "No.")),
              ValueNotFoundErr);
    end;

    local procedure CreateDocumentLayoutForCustomer(var Job: Record Job)
    var
        Customer: Record Customer;
        CustomReportSelection: Record "Custom Report Selection";
    begin
        if Customer.Get(Job."Bill-to Customer No.") then begin
            CustomReportSelection.DeleteAll();
            CustomReportSelection.Init();
            CustomReportSelection."Source Type" := DATABASE::Customer;
            CustomReportSelection."Source No." := Customer."No.";
            CustomReportSelection.Usage := CustomReportSelection.Usage::JQ;
            CustomReportSelection.Sequence := 1;
            CustomReportSelection."Report ID" := REPORT::"Job Quote";
            CustomReportSelection."Use for Email Attachment" := true;
            CustomReportSelection.Insert();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SendEmailModalPageHandler(var EmailDialog: TestPage "Email Dialog")
    begin
        EmailDialog.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;
}

