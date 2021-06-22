codeunit 134194 "Test Adv. Intrastat Checklist"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat] [Advanced Intrastat Checklist]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;
        FilterStringParseErr: Label 'Could not parse the filter expression. Use the lookup action, or type a string in the following format: "Type: Shipment, Quantity: <>0".';
        AdvChecklistErr: Label 'There are one or more errors. For details, see the journal error FactBox.';

    [Test]
    procedure InsertFieldsFromPage()
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        AdvancedIntrastatChecklistTestPage: TestPage "Advanced Intrastat Checklist";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Insert a new field setup from page
        Initialize();
        LibraryLowerPermissions.SetO365Basic();

        AdvancedIntrastatChecklistTestPage.OpenEdit();
        AdvancedIntrastatChecklistTestPage."Object Type".SetValue(AdvancedIntrastatChecklist."Object Type"::Report);
        AdvancedIntrastatChecklistTestPage."Object Id".SetValue(Report::"Intrastat - Checklist");
        AdvancedIntrastatChecklistTestPage."Field No.".SetValue(IntrastatJnlLine.FieldNo("Document No."));
        AdvancedIntrastatChecklistTestPage.Next();
        AdvancedIntrastatChecklistTestPage."Object Type".SetValue(AdvancedIntrastatChecklist."Object Type"::Codeunit);
        AdvancedIntrastatChecklistTestPage."Object Id".SetValue(Codeunit::"Test Adv. Intrastat Checklist");
        AdvancedIntrastatChecklistTestPage."Field No.".SetValue(IntrastatJnlLine.FieldNo(Type));
        AdvancedIntrastatChecklistTestPage.Previous();
        AdvancedIntrastatChecklistTestPage."Object Name".AssertEquals('Intrastat - Checklist');
        AdvancedIntrastatChecklistTestPage."Field Name".AssertEquals('Document No.');
        AdvancedIntrastatChecklistTestPage.Next();
        AdvancedIntrastatChecklistTestPage."Object Name".AssertEquals('Test Adv. Intrastat Checklist');
        AdvancedIntrastatChecklistTestPage."Field Name".AssertEquals('Type');
        AdvancedIntrastatChecklistTestPage.Close();

        AdvancedIntrastatChecklist.Get(
            AdvancedIntrastatChecklist."Object Type"::Report, Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo("Document No."));
        AdvancedIntrastatChecklist.Get(
            AdvancedIntrastatChecklist."Object Type"::Codeunit, Codeunit::"Test Adv. Intrastat Checklist", IntrastatJnlLine.FieldNo(Type));
    end;

    [Test]
    procedure FilterExpression()
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 395476] Test "Filter Expression" formula
        Initialize();

        AdvancedIntrastatChecklist.Validate("Filter Expression", 'Type: Shipment');
        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment);
        AdvancedIntrastatChecklist.TestField("Filter Expression", IntrastatJnlLine.GetFilters());
        AdvancedIntrastatChecklist.TestField("Record View String", IntrastatJnlLine.GetView(false));

        AdvancedIntrastatChecklist.Validate("Filter Expression", ' type  :    receipt');
        IntrastatJnlLine.Reset();
        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Receipt);
        AdvancedIntrastatChecklist.TestField("Filter Expression", IntrastatJnlLine.GetFilters());
        AdvancedIntrastatChecklist.TestField("Record View String", IntrastatJnlLine.GetView(false));

        AdvancedIntrastatChecklist.Validate("Filter Expression", 'Quantity:>0');
        IntrastatJnlLine.Reset();
        IntrastatJnlLine.SetFilter(Quantity, '>%1', 0);
        AdvancedIntrastatChecklist.TestField("Filter Expression", IntrastatJnlLine.GetFilters());
        AdvancedIntrastatChecklist.TestField("Record View String", IntrastatJnlLine.GetView(false));

        AdvancedIntrastatChecklist.Validate("Filter Expression", ' supplementary units : true ');
        IntrastatJnlLine.Reset();
        IntrastatJnlLine.SetRange("Supplementary Units", true);
        AdvancedIntrastatChecklist.TestField("Filter Expression", IntrastatJnlLine.GetFilters());
        AdvancedIntrastatChecklist.TestField("Record View String", IntrastatJnlLine.GetView(false));

        AdvancedIntrastatChecklist.Validate("Filter Expression", 'type:shipment, quantity:<0 ,quantity : <0 , supplementary units:false');
        IntrastatJnlLine.Reset();
        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment);
        IntrastatJnlLine.SetFilter(Quantity, '<%1', 0);
        IntrastatJnlLine.SetRange("Supplementary Units", false);
        AdvancedIntrastatChecklist.TestField("Filter Expression", IntrastatJnlLine.GetFilters());
        AdvancedIntrastatChecklist.TestField("Record View String", IntrastatJnlLine.GetView(false));

        asserterror AdvancedIntrastatChecklist.Validate("Filter Expression", 'qwerty');
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(FilterStringParseErr);
    end;

    [Test]
    procedure IsAdvancedChecklistReportField()
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntraJnlManagement: Codeunit IntraJnlManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 395476] IsAdvancedChecklistReportField() returns True in case of existing field setup
        Initialize();

        Assert.IsFalse(
          IntraJnlManagement.IsAdvancedChecklistReportField(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo(Type), ''), '');

        AdvancedIntrastatChecklist."Object Type" := AdvancedIntrastatChecklist."Object Type"::Report;
        AdvancedIntrastatChecklist.Insert();
        Assert.IsFalse(
          IntraJnlManagement.IsAdvancedChecklistReportField(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo(Type), ''), '');

        AdvancedIntrastatChecklist."Object Type" := AdvancedIntrastatChecklist."Object Type"::Report;
        AdvancedIntrastatChecklist."Object Id" := Report::"Intrastat - Checklist";
        AdvancedIntrastatChecklist.Insert();
        Assert.IsFalse(
          IntraJnlManagement.IsAdvancedChecklistReportField(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo(Type), ''), '');

        AdvancedIntrastatChecklist."Object Type" := AdvancedIntrastatChecklist."Object Type"::Report;
        AdvancedIntrastatChecklist."Object Id" := Report::"Intrastat - Checklist";
        AdvancedIntrastatChecklist."Field No." := IntrastatJnlLine.FieldNo(Type);
        AdvancedIntrastatChecklist.Insert();
        Assert.IsTrue(
          IntraJnlManagement.IsAdvancedChecklistReportField(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo(Type), ''), '');

        AdvancedIntrastatChecklist.Validate("Filter Expression", 'Type: Shipment');
        AdvancedIntrastatChecklist.Modify();
        Assert.IsTrue(
          IntraJnlManagement.IsAdvancedChecklistReportField(
            Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo(Type), 'Type: Shipment'), '');
        Assert.IsFalse(
          IntraJnlManagement.IsAdvancedChecklistReportField(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo(Type), ''), '');
    end;

    [Test]
    procedure ValidateReportWithAdvancedChecklist()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntraJnlManagement: Codeunit IntraJnlManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 395476] ValidateReportWithAdvancedChecklist() basic tests
        Initialize();

        Assert.IsTrue(
          IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Checklist", false), '');
        Assert.IsTrue(
          IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Checklist", true), '');

        CreateFieldSetup(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo(Quantity), '');
        Assert.IsFalse(
          IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Checklist", false), '');
        asserterror IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Checklist", true);
        VerifyError();

        IntrastatJnlLine.Type := IntrastatJnlLine.Type::Receipt;
        IntrastatJnlLine.Quantity := 1;
        CreateFieldSetup(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo("Transaction Type"), 'Type: Shipment');
        Assert.IsTrue(
          IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Checklist", false), '');
        Assert.IsTrue(
          IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Checklist", true), '');

        IntrastatJnlLine.Type := IntrastatJnlLine.Type::Shipment;
        Assert.IsFalse(
          IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Checklist", false), '');
        asserterror IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Checklist", true);
        VerifyError();
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    procedure IntrastatChecklist_NoErrors()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 502 "Intrastat - Checklist" in case of no errors
        Initialize();
        CreateJournalLine(IntrastatJnlLine);

        RunChecklistReport(IntrastatJnlLine);

        VerifyNoBatchError(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    procedure IntrastatChecklist_SingleError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 502 "Intrastat - Checklist" in case of single error
        Initialize();
        CreateJournalLine(IntrastatJnlLine);
        CreateFieldSetup(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo("Item No."), '');

        RunChecklistReport(IntrastatJnlLine);

        VerifyBatchSingleError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Item No."));
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    procedure IntrastatChecklist_TwoErrors()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 502 "Intrastat - Checklist" in case of two errors
        Initialize();
        CreateJournalLine(IntrastatJnlLine);
        CreateFieldSetup(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo("Item No."), '');
        CreateFieldSetup(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo("Tariff No."), '');

        RunChecklistReport(IntrastatJnlLine);

        VerifyBatchTwoErrors(IntrastatJnlLine, IntrastatJnlLine.FieldName("Tariff No."), IntrastatJnlLine.FieldName("Item No."));
    end;

    [Test]
    [HandlerFunctions('IntrastatFormRPH')]
    procedure IntrastatForm_NoErrors()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 501 "Intrastat - Form" in case of no errors
        Initialize();
        CreateJournalLine(IntrastatJnlLine);

        RunIntrastatForm(IntrastatJnlLine);

        VerifyNoBatchError(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('IntrastatFormRPH')]
    procedure IntrastatForm_SingleError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 501 "Intrastat - Form" in case of single error
        Initialize();
        CreateJournalLine(IntrastatJnlLine);
        CreateFieldSetup(Report::"Intrastat - Form", IntrastatJnlLine.FieldNo("Item No."), '');

        asserterror RunIntrastatForm(IntrastatJnlLine);

        VerifyError();
        VerifyBatchSingleError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Item No."));
    end;

    [Test]
    [HandlerFunctions('IntrastatFormRPH')]
    procedure IntrastatForm_TwoErrors()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 501 "Intrastat - Form" in case of two errors
        Initialize();
        CreateJournalLine(IntrastatJnlLine);
        CreateFieldSetup(Report::"Intrastat - Form", IntrastatJnlLine.FieldNo("Item No."), '');
        CreateFieldSetup(Report::"Intrastat - Form", IntrastatJnlLine.FieldNo("Tariff No."), '');

        asserterror RunIntrastatForm(IntrastatJnlLine);

        VerifyError();
        VerifyBatchTwoErrors(IntrastatJnlLine, IntrastatJnlLine.FieldName("Tariff No."), IntrastatJnlLine.FieldName("Item No."));
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRPH')]
    procedure IntrastatMakeDiskTaxAuth_NoErrors()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 593 "Intrastat - Make Disk Tax Auth" in case of no errors
        Initialize();
        IntrastatJnlBatch.DeleteAll();
        CreateJournalLine(IntrastatJnlLine);

        RunIntrastatMakeDiskTaxAuth(IntrastatJnlLine);

        VerifyNoBatchError(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRPH')]
    procedure IntrastatMakeDiskTaxAuth_SingleError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 593 "Intrastat - Make Disk Tax Auth" in case of single error
        Initialize();
        IntrastatJnlBatch.DeleteAll();
        CreateJournalLine(IntrastatJnlLine);
        CreateFieldSetup(Report::"Intrastat - Make Disk Tax Auth", IntrastatJnlLine.FieldNo("Item No."), '');

        asserterror RunIntrastatMakeDiskTaxAuth(IntrastatJnlLine);

        VerifyError();
        VerifyBatchSingleError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Item No."));
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRPH')]
    procedure IntrastatMakeDiskTaxAuth_TwoErrors()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395476] Report 593 "Intrastat - Make Disk Tax Auth" in case of two errors
        Initialize();
        IntrastatJnlBatch.DeleteAll();
        CreateJournalLine(IntrastatJnlLine);
        CreateFieldSetup(Report::"Intrastat - Make Disk Tax Auth", IntrastatJnlLine.FieldNo("Item No."), '');
        CreateFieldSetup(Report::"Intrastat - Make Disk Tax Auth", IntrastatJnlLine.FieldNo("Tariff No."), '');

        asserterror RunIntrastatMakeDiskTaxAuth(IntrastatJnlLine);

        VerifyError();
        VerifyBatchTwoErrors(IntrastatJnlLine, IntrastatJnlLine.FieldName("Tariff No."), IntrastatJnlLine.FieldName("Item No."));
    end;

    local procedure Initialize()
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
    begin
        AdvancedIntrastatChecklist.DeleteAll();

        IF IsInitialized THEN
            EXIT;

        EnableSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure EnableSetup()
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IF NOT IntrastatSetup.Get THEN
            IntrastatSetup.Insert();
#if not CLEAN19
        IntrastatSetup."Use Advanced Checklist" := true;
#endif
        IntrastatSetup."Report Receipts" := true;
        IntrastatSetup."Report Shipments" := true;
        IntrastatSetup.Modify;
    end;

    local procedure CreateFieldSetup(ReportId: Integer; FieldNo: Integer; FilterExpression: Text)
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
    begin
        AdvancedIntrastatChecklist.Init();
        AdvancedIntrastatChecklist.Validate("Object Type", AdvancedIntrastatChecklist."Object Type"::Report);
        AdvancedIntrastatChecklist.Validate("Object Id", ReportId);
        AdvancedIntrastatChecklist.Validate("Field No.", FieldNo);
        AdvancedIntrastatChecklist.Validate(
          "Filter Expression",
          CopyStr(FilterExpression, 1, MaxStrLen(AdvancedIntrastatChecklist."Filter Expression")));
        AdvancedIntrastatChecklist.Insert();
    end;

    local procedure CreateJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate("Statistics Period", Format(WorkDate(), 0, '<Year,2><Month,2>'));
        IntrastatJnlBatch.Validate("Currency Identifier", 'EUR');
        IntrastatJnlBatch.Modify(true);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);
        IntrastatJnlLine.Validate(Type, IntrastatJnlLine.Type::Shipment);
        IntrastatJnlLine.Validate("Country/Region Code", 'DE');
        IntrastatJnlLine.Modify(true);
    end;

    local procedure RunChecklistReport(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        IntrastatJnlBatch.SetRecFilter();
        Commit();
        Report.Run(Report::"Intrastat - Checklist", true, false, IntrastatJnlBatch);
    end;

    local procedure RunIntrastatForm(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        IntrastatJnlBatch.SetRecFilter();
        Commit();
        Report.Run(Report::"Intrastat - Form", true, false, IntrastatJnlBatch);
    end;

    local procedure RunIntrastatMakeDiskTaxAuth(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatMakeDiskTaxAuth: Report "Intrastat - Make Disk Tax Auth";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        IntrastatJnlBatch.SetRecFilter();
        Commit();
        IntrastatMakeDiskTaxAuth.InitializeRequest(LibraryReportDataset.GetFileName());
        IntrastatMakeDiskTaxAuth.SetTableView(IntrastatJnlBatch);
        IntrastatMakeDiskTaxAuth.UseRequestPage(true);
        IntrastatMakeDiskTaxAuth.Run();
    end;

    local procedure VerifyError()
    begin
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(AdvChecklistErr);
    end;

    local procedure VerifyBatchSingleError(IntrastatJnlLine: Record "Intrastat Jnl. Line"; FieldName: Text)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ErrorMessage: Record "Error Message";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        ErrorMessage.SetContext(IntrastatJnlBatch);
        Assert.AreEqual(1, ErrorMessage.ErrorMessageCount(ErrorMessage."Message Type"::Error), '');
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(FieldName, ErrorMessage.Description);
    end;

    local procedure VerifyBatchTwoErrors(IntrastatJnlLine: Record "Intrastat Jnl. Line"; FieldName1: Text; FieldName2: Text)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ErrorMessage: Record "Error Message";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        ErrorMessage.SetContext(IntrastatJnlBatch);
        Assert.AreEqual(2, ErrorMessage.ErrorMessageCount(ErrorMessage."Message Type"::Error), '');
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(FieldName1, ErrorMessage.Description);
        ErrorMessage.Next();
        Assert.ExpectedMessage(FieldName2, ErrorMessage.Description);
    end;

    local procedure VerifyNoBatchError(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ErrorMessage: Record "Error Message";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        ErrorMessage.SetContext(IntrastatJnlBatch);
        Assert.AreEqual(0, ErrorMessage.ErrorMessageCount(ErrorMessage."Message Type"::Error), '');
    end;

    [RequestPageHandler]
    procedure IntrastatChecklistRPH(var IntrastatChecklist: TestRequestPage "Intrastat - Checklist")
    begin
        IntrastatChecklist.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure IntrastatFormRPH(var IntrastatForm: TestRequestPage "Intrastat - Form")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatForm."Intrastat Jnl. Line".SetFilter(Type, Format(IntrastatJnlLine.Type::Shipment));
        IntrastatForm.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure IntrastatMakeDiskTaxAuthRPH(var IntrastatMakeDiskTaxAuth: TestRequestPage "Intrastat - Make Disk Tax Auth")
    begin
        IntrastatMakeDiskTaxAuth.OK().Invoke();
    end;
}

