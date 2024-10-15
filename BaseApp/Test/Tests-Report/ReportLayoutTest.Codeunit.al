﻿codeunit 134600 "Report Layout Test"
{
    // SaveAsPDF is not tested for Word scenarios as it currently requires Windows client and an installed Word.

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report Layout]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        WrongRegNoErr: Label 'Wrong Company Registration Number';
        WrongRegNoLblErr: Label 'Wrong "Registration No." field caption';
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTablesUT: Codeunit "Library - Tables UT";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        FileManagement: Codeunit "File Management";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Usage: Option "Order Confirmation","Work Order","Pick Instruction";
        CopyOfTxt: Label 'Copy of %1', Comment = '%1 - custom report layout description';
        DeleteBuiltInLayoutErr: Label 'This is a built-in custom report layout, and it cannot be deleted.';
        IsInitialized: Boolean;
        LineInFileTxt: Label '<ReportDataSet name="Test Report - Default=Word" id="134600">';
        FileNameIsBlankMsg: Label 'File name is blank.';
        LayoutCodeShouldNotChangedErr: Label 'Layout code should not change.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Report Layout Test");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Report Layout Test");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Report Layout Test");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportLayoutSelectionOnInsert()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        // Init
        Initialize();
        ReportLayoutSelection.Init();
        Assert.AreEqual('', ReportLayoutSelection."Company Name", '');

        // Exercise
        asserterror ReportLayoutSelection.Insert(true);
        if ReportLayoutSelection.Get(DetailTrialBalanceReportID, CompanyName) then
            ReportLayoutSelection.Delete();
        ReportLayoutSelection."Report ID" := DetailTrialBalanceReportID;
        ReportLayoutSelection.Insert(true);

        // Verify
        Assert.AreEqual(CompanyName, ReportLayoutSelection."Company Name", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportLayoutSelectionType()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        // Init
        Initialize();
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := DetailTrialBalanceReportID; // does not have a Word layout.
        ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"Custom Layout");
        ReportLayoutSelection."Custom Report Layout Code" := '';

        // Exercise
        ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"RDLC (built-in)");

        // Verify
        Assert.AreEqual('', ReportLayoutSelection."Custom Report Layout Code", '');

        asserterror ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"Word (built-in)");

        asserterror ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"Excel Layout");

        asserterror ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"External Layout");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportLayoutSelectionReportLayoutID()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        // Init
        Initialize();
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := DetailTrialBalanceReportID;
        CustomReportLayout.Init();
        CustomReportLayout."Report ID" := DetailTrialBalanceReportID;
        CustomReportLayout.Code := '';
        CustomReportLayout.Insert(true);

        // Exercise
        ReportLayoutSelection.Validate("Custom Report Layout Code", CustomReportLayout.Code);

        // Verify
        Assert.IsTrue(ReportLayoutSelection.Type = ReportLayoutSelection.Type::"Custom Layout", '');

        // Exercise
        ReportLayoutSelection.Validate("Custom Report Layout Code", '');

        // Verify
        Assert.IsTrue(ReportLayoutSelection.Type = ReportLayoutSelection.Type::"RDLC (built-in)", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportLayoutSelectionReportIsProcessingOnly()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        Initialize();
        // Verify
        Assert.IsFalse(ReportLayoutSelection.IsProcessingOnly(REPORT::"Detail Trial Balance"), '');
        Assert.IsTrue(ReportLayoutSelection.IsProcessingOnly(REPORT::"Copy Sales Document"), '');
        Assert.IsFalse(ReportLayoutSelection.HasWordLayout(REPORT::"Detail Trial Balance"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportLayoutSelectionHasCustomLayout()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        // Init
        Initialize();
        CustomReportLayout.Init();
        CustomReportLayout."Report ID" := DetailTrialBalanceReportID;
        CustomReportLayout.Type := CustomReportLayout.Type::RDLC;
        CustomReportLayout.Code := '';
        CustomReportLayout.Insert(true);

        if ReportLayoutSelection.Get(DetailTrialBalanceReportID, CompanyName) then
            ReportLayoutSelection.Delete();
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := DetailTrialBalanceReportID;
        ReportLayoutSelection.Validate("Custom Report Layout Code", CustomReportLayout.Code);
        ReportLayoutSelection.Insert(true);

        // Verify
        Assert.AreEqual(1, ReportLayoutSelection.HasCustomLayout(DetailTrialBalanceReportID), 'Expected a custom RDLC');

        // Variations
        CustomReportLayout.Type := CustomReportLayout.Type::Word;
        CustomReportLayout.Modify();
        Assert.AreEqual(2, ReportLayoutSelection.HasCustomLayout(DetailTrialBalanceReportID), 'Expected a custom Word');
        CustomReportLayout.Delete();
        Assert.AreEqual(0, ReportLayoutSelection.HasCustomLayout(DetailTrialBalanceReportID), 'Expected default (no layout found)');
        Assert.AreEqual(0, ReportLayoutSelection.HasCustomLayout(99999), 'Expected default (no such report)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTableCustomReportLayoutTriggers()
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        Initialize();
        CustomReportLayout.Init();
        CustomReportLayout."Report ID" := StandardSalesInvoiceReportID;
        CustomReportLayout.Type := CustomReportLayout.Type::Word;
        CustomReportLayout."Company Name" := CompanyName;
        CustomReportLayout.Insert(true);

        Assert.AreNotEqual('', CustomReportLayout.Code, 'Wrong Code.');
        Assert.AreEqual(UserId, CustomReportLayout."Last Modified by User", 'Wrong user ID.');
        Assert.AreNotEqual(Format(0DT), Format(CustomReportLayout."Last Modified"), 'A date-time was expected.');

        CustomReportLayout."Last Modified by User" := '';
        CustomReportLayout."Last Modified" := 0DT;
        CustomReportLayout.Modify(true);

        Assert.AreEqual(UserId, CustomReportLayout."Last Modified by User", 'Wrong user ID.');
        Assert.AreNotEqual(Format(0DT), Format(CustomReportLayout."Last Modified"), 'A date-time was expected.');

        CustomReportLayout.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTableCustomReportLayoutUpdateLayout()
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        Initialize();
        InitCustomReportLayout(CustomReportLayout, CustomReportLayout.Type::Word, true);
        Assert.AreEqual('', CustomReportLayout.TryUpdateLayout(false), '');
        InitCustomReportLayout(CustomReportLayout, CustomReportLayout.Type::RDLC, true);
        Assert.AreEqual('', CustomReportLayout.TryUpdateLayout(false), '');
    end;

    [Scope('OnPrem')]
    procedure TestTableCustomReportLayoutValidateLayout()
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        Initialize();
        // RDLC
        InitCustomReportLayout(CustomReportLayout, CustomReportLayout.Type::RDLC, true);
        Assert.IsTrue(CustomReportLayout.ValidateLayout(false, false), '');
        // Word
        InitCustomReportLayout(CustomReportLayout, CustomReportLayout.Type::Word, true);
        Assert.IsTrue(CustomReportLayout.ValidateLayout(false, false), '');
        CustomReportLayout.ClearLayout;
        Assert.IsFalse(CustomReportLayout.ValidateLayout(false, false), '');
    end;

    [Test]
    [HandlerFunctions('Report134600HandlerCancel')]
    [Scope('OnPrem')]
    procedure TestCustomtLayoutRunReport()
    var
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportLayouts: TestPage "Custom Report Layouts";
    begin
        // Init
        Initialize();
        CustomReportLayout.Init();
        CustomReportLayout."Report ID" := REPORT::"Test Report - Default=Word";
        CustomReportLayout.Code := '';
        CustomReportLayout.Insert(true);
        Commit();  // Necessary as the report is run modally.

        // Exercise - opens a request page for report 134600.
        CustomReportLayouts.OpenView;
        CustomReportLayouts.GotoRecord(CustomReportLayout);
        Assert.AreEqual(REPORT::"Test Report - Default=Word", CustomReportLayouts."Report ID".AsInteger, '');
        CustomReportLayouts.RunReport.Invoke;

        CustomReportLayout.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyRecord()
    var
        CustomReportLayout: Record "Custom Report Layout";
        OldLayoutCode: Code[20];
        NewLayoutCode: Code[20];
    begin
        // Init
        Initialize();
        InitCustomReportLayout(CustomReportLayout, CustomReportLayout.Type::Word, true);
        OldLayoutCode := CustomReportLayout.Code;

        // Execute copy
        NewLayoutCode := CustomReportLayout.CopyReportLayout();

        // Validate
        CustomReportLayout.Get(NewLayoutCode);
        CustomReportLayout.CalcFields(Layout, "Custom XML Part");
        Assert.AreNotEqual(OldLayoutCode, NewLayoutCode, '');
        Assert.IsTrue(CustomReportLayout.Layout.HasValue, 'Missing layout');
        Assert.IsTrue(CustomReportLayout."Custom XML Part".HasValue, 'Missing xml definition');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateCustomRrdlcOk()
    var
        CustomReportLayout: Record "Custom Report Layout";
        LayoutCode: Code[20];
    begin
        // init
        Initialize();
        LayoutCode := CustomReportLayout.InitBuiltInLayout(StandardSalesInvoiceReportID, CustomReportLayout.Type::RDLC.AsInteger());
        CustomReportLayout.Get(LayoutCode);

        // Execute / verify
        Assert.IsTrue(CustomReportLayout.ValidateLayout(false, false), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestValidateCustomRrdlcFailed()
    var
        CustomReportLayout: Record "Custom Report Layout";
        LayoutCode: Code[20];
    begin
        // init
        Initialize();
        LayoutCode := CustomReportLayout.InitBuiltInLayout(StandardSalesInvoiceReportID, CustomReportLayout.Type::RDLC.AsInteger());
        CustomReportLayout.Get(LayoutCode);
        CustomReportLayout."Report ID" := REPORT::"Standard Sales - Order Conf."; // Force invalid rdlc.

        // Execute
        asserterror CustomReportLayout.ValidateLayout(true, false);

        // Validate
        Assert.AreEqual('The RDLC layout action has been canceled because of validation errors.', GetLastErrorText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateCustomRrdlcFailed2()
    var
        CustomReportLayout: Record "Custom Report Layout";
        LayoutCode: Code[20];
    begin
        // init
        Initialize();
        LayoutCode := CustomReportLayout.InitBuiltInLayout(StandardSalesInvoiceReportID, CustomReportLayout.Type::RDLC.AsInteger());
        CustomReportLayout.Get(LayoutCode);
        CustomReportLayout."Report ID" := REPORT::"Standard Sales - Order Conf."; // Force invalid rdlc.

        // Execute
        asserterror CustomReportLayout.ValidateLayout(false, false);

        // Validate
        Assert.IsTrue(StrPos(GetLastErrorText, 'The RDLC layout does not comply with the current report design (for example') = 1, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRepStandardSalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FileManagement: Codeunit "File Management";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDoc: DotNet XmlDocument;
        XmlNode: DotNet XmlNode;
        XmlNodeList: DotNet XmlNodeList;
        FileNameXml: Text;
        i: Integer;
    begin
        Initialize();
        if not SalesInvoiceHeader.FindFirst() then
            exit;
        SalesInvoiceHeader.SetRecFilter();
        InitCompanySetup;
        FileNameXml := FileManagement.ServerTempFileName('xml');
        REPORT.SaveAsXml(REPORT::"Standard Sales - Invoice", FileNameXml, SalesInvoiceHeader);

        // Verify
        XMLDOMManagement.LoadXMLDocumentFromFile(FileNameXml, XmlDoc);
        XmlNode := XmlDoc.DocumentElement;
        XmlNode := XmlNode.FirstChild; // DataItems
        XmlNode := XmlNode.FirstChild; // DataItem Sales_Invoice_Header
        Assert.AreEqual('Header', GetXmlAttribute('name', XmlNode), '');

        XmlNodeList := XmlNode.ChildNodes;
        Assert.AreEqual(2, XmlNodeList.Count, 'Header children.');
        for i := 0 to XmlNodeList.Count - 1 do begin
            XmlNode := XmlNodeList.ItemOf(i);
            case XmlNode.Name of
                'Columns':
                    ValidateHeaderColumns(XmlNode);
                'DataItems':
                    ValidateDataItems(XmlNode);
            end;
        end;

        // Cleanup
        Erase(FileNameXml);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDesignTimeReportSelectionCustomLayouts()
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
        LayoutName: Text[250];
    begin
        // Layout supposedly present in the App table.
        LayoutName := 'TEST-FILE-MS';
        DesignTimeReportSelection.SetSelectedCustomLayout(LayoutName);
        Assert.AreEqual(LayoutName, DesignTimeReportSelection.GetSelectedLayout(), '');
        Assert.AreEqual(LayoutName, DesignTimeReportSelection.GetSelectedCustomLayout(), '');

        // Layout supposedly present in platform table.
        LayoutName := 'TestLayoutWithABigNameAndBigExtensionType';
        asserterror DesignTimeReportSelection.SetSelectedCustomLayout(LayoutName);

        // Clear Design time selections
        DesignTimeReportSelection.SetSelectedCustomLayout('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDesignTimeReportSelectionCustomAndPlatformLayouts()
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
        LayoutName: Text[250];
    begin
        // Layout supposedly present in the App table.
        LayoutName := 'TEST-FILE-MS';
        DesignTimeReportSelection.SetSelectedLayout(LayoutName);
        Assert.AreEqual(LayoutName, DesignTimeReportSelection.GetSelectedLayout(), '');

        // Layout supposedly present in platform table.
        LayoutName := 'TestLayoutWithABigNameAndBigExtensionType';
        DesignTimeReportSelection.SetSelectedLayout(LayoutName);
        Assert.AreEqual(LayoutName, DesignTimeReportSelection.GetSelectedLayout(), '');

        // Clear Design time selections
        DesignTimeReportSelection.SetSelectedLayout('');
    end;

    local procedure TestImportLayoutByType(LayoutType: Enum "Custom Report Layout Type")
    var
        CustomReportLayout: Record "Custom Report Layout";
        FileManagement: Codeunit "File Management";
        DefaultFileName: Text;
        LayoutCode: Code[20];
    begin
        CustomReportLayout.SetRange("Report ID", StandardSalesInvoiceReportID);
        CustomReportLayout.DeleteAll();

        // Init
        CustomReportLayout.Reset();
        LayoutCode := CustomReportLayout.InitBuiltInLayout(StandardSalesInvoiceReportID, LayoutType.AsInteger());
        CustomReportLayout.Get(LayoutCode);

        case LayoutType of
            CustomReportLayout.Type::Word:
                DefaultFileName := CustomReportLayout.ExportReportLayout(FileManagement.ServerTempFileName('docx'), false);
            CustomReportLayout.Type::RDLC:
                DefaultFileName := CustomReportLayout.ExportReportLayout(FileManagement.ServerTempFileName('rdl'), false);
        end;

        LayoutCode := CustomReportLayout.CopyReportLayout();
        CustomReportLayout.Get(LayoutCode);
        CustomReportLayout.ClearLayout;
        Assert.IsFalse(CustomReportLayout.HasLayout, '');

        // Execute
        CustomReportLayout.ImportReportLayout(DefaultFileName);

        // validate
        Assert.IsTrue(CustomReportLayout.HasLayout, '');
    end;

    [Test]
    [HandlerFunctions('ReportLookupHandler')]
    [Scope('OnPrem')]
    procedure TestReportLayoutsPageNew()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayouts: TestPage "Custom Report Layouts";
    begin
        // Init
        Initialize();
        CustomReportLayout.SetRange("Report ID", StandardSalesInvoiceReportID);
        CustomReportLayout.DeleteAll();

        // Exercise
        ReportLayouts.OpenView;
        ReportLayouts.NewLayout.Invoke;
        ReportLayouts.OK.Invoke;

        // Verify
        Assert.AreNotEqual(0, CustomReportLayout.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportDefaultWord()
    var
        FileManagement: Codeunit "File Management";
    begin
        Initialize();
        // Verify start condition
        Assert.IsTrue(REPORT.DefaultLayout(134600) = DEFAULTLAYOUT::Word, '');

        // Execute / verify
        REPORT.SaveAsWord(134600, FileManagement.ServerTempFileName('docx'));
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestNoLayoutSelectionDefaultRDLC()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=RDLC", 0); // No Report Selection, No report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=RDLC");
        VerifySaveAsWord(REPORT::"Test Report - Default=RDLC");
        VerifySaveAsExcel(REPORT::"Test Report - Default=RDLC");
        VerifySchedule(REPORT::"Test Report - Default=RDLC");
        VerifyRun(REPORT::"Test Report - Default=RDLC");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestNoLayoutSelectionDefaultWord()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=Word", 0); // No Report Selection, No report layout

        // VerifySaveAsPdf(REPORT::"Test Report - Default=Word");
        VerifySaveAsWord(REPORT::"Test Report - Default=Word");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Default=Word");
        VerifySchedule(REPORT::"Test Report - Default=Word");
        VerifyRun(REPORT::"Test Report - Default=Word");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestNoLayoutSelectionDefaultNone()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Processing Only", 0); // No Report Selection, No report layout

        asserterror VerifySaveAsPdf(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsWord(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Processing Only");
        VerifySchedule(REPORT::"Test Report - Processing Only");
        VerifyRun(REPORT::"Test Report - Processing Only");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestRDLCLayoutSelectionDefaultRDLC()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=RDLC", 1); // Report Selection = RDLC, No report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=RDLC");
        VerifySaveAsWord(REPORT::"Test Report - Default=RDLC");
        VerifySaveAsExcel(REPORT::"Test Report - Default=RDLC");
        VerifySchedule(REPORT::"Test Report - Default=RDLC");
        VerifyRun(REPORT::"Test Report - Default=RDLC");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestRDLCLayoutSelectionDefaultWord()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=Word", 1); // Report Selection = RDLC, No report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=Word");
        VerifySaveAsWord(REPORT::"Test Report - Default=Word");
        VerifySaveAsExcel(REPORT::"Test Report - Default=Word");
        VerifySchedule(REPORT::"Test Report - Default=Word");
        VerifyRun(REPORT::"Test Report - Default=Word");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestRDLCLayoutSelectionDefaultNone()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Processing Only", 1); // Report Selection = RDLC, No report layout

        asserterror VerifySaveAsPdf(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsWord(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Processing Only");
        VerifySchedule(REPORT::"Test Report - Processing Only");
        VerifyRun(REPORT::"Test Report - Processing Only");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestWordLayoutSelectionDefaultRDLC()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=RDLC", 2); // Report Selection = Word, No report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=RDLC");
        VerifySaveAsWord(REPORT::"Test Report - Default=RDLC");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Default=RDLC");
        VerifySchedule(REPORT::"Test Report - Default=RDLC");
        VerifyRun(REPORT::"Test Report - Default=RDLC");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestWordLayoutSelectionDefaultWord()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=Word", 2); // Report Selection = Word, No report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=Word");
        VerifySaveAsWord(REPORT::"Test Report - Default=Word");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Default=Word");
        VerifySchedule(REPORT::"Test Report - Default=Word");
        VerifyRun(REPORT::"Test Report - Default=Word");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestWordLayoutSelectionDefaultNone()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Processing Only", 2); // Report Selection = Word, No report layout

        asserterror VerifySaveAsPdf(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsWord(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Processing Only");
        VerifySchedule(REPORT::"Test Report - Processing Only");
        VerifyRun(REPORT::"Test Report - Processing Only");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestCustomRDLCLayoutSelectionDefaultRDLC()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=RDLC", 3); // Report Selection = Custom, RDLC report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=RDLC");
        VerifySaveAsWord(REPORT::"Test Report - Default=RDLC");
        VerifySaveAsExcel(REPORT::"Test Report - Default=RDLC");
        VerifySchedule(REPORT::"Test Report - Default=RDLC");
        VerifyRun(REPORT::"Test Report - Default=RDLC");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestCustomRDLCLayoutSelectionDefaultWord()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=Word", 3); // Report Selection = Custom, RDLC report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=Word");
        VerifySaveAsWord(REPORT::"Test Report - Default=Word");
        VerifySaveAsExcel(REPORT::"Test Report - Default=Word");
        VerifySchedule(REPORT::"Test Report - Default=Word");
        VerifyRun(REPORT::"Test Report - Default=Word");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestCustomRDLCLayoutSelectionDefaultNone()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Processing Only", 3); // Report Selection = Custom, RDLC report layout

        asserterror VerifySaveAsPdf(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsWord(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Processing Only");
        VerifySchedule(REPORT::"Test Report - Processing Only");
        VerifyRun(REPORT::"Test Report - Processing Only");
    end;

    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestCustomWordLayoutSelectionDefaultRDLC()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=RDLC", 4); // Report Selection = Custom, Word report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=RDLC");
        VerifySaveAsWord(REPORT::"Test Report - Default=RDLC");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Default=RDLC");
        VerifySchedule(REPORT::"Test Report - Default=RDLC");
        VerifyRun(REPORT::"Test Report - Default=RDLC");
    end;

    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestCustomWordLayoutSelectionDefaultWord()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Default=Word", 4); // Report Selection = Custom, Word report layout

        VerifySaveAsPdf(REPORT::"Test Report - Default=Word");
        VerifySaveAsWord(REPORT::"Test Report - Default=Word");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Default=Word");
        VerifySchedule(REPORT::"Test Report - Default=Word");
        VerifyRun(REPORT::"Test Report - Default=Word");
    end;

    [Test]
    [HandlerFunctions('ScheduleAReportHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestCustomWordLayoutSelectionDefaultNone()
    begin
        // Init
        Initialize();
        InitReportSelection(REPORT::"Test Report - Processing Only", 4); // Report Selection = Custom, Word report layout

        asserterror VerifySaveAsPdf(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsWord(REPORT::"Test Report - Processing Only");
        asserterror VerifySaveAsExcel(REPORT::"Test Report - Processing Only");
        VerifySchedule(REPORT::"Test Report - Processing Only");
        VerifyRun(REPORT::"Test Report - Processing Only");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCompanyRegistationNo()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [Company Information] [UT]
        // [SCENARIO 375887] GetRegistrationNumber and GetRegistrationNumberLbl should return "Registration No." and its caption
        CompanyInformation.Get();
        CompanyInformation.Validate(
          "Registration No.",
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Registration No."), DATABASE::"Company Information"));
        CompanyInformation.Modify();
        Assert.AreEqual(CompanyInformation."Registration No.", CompanyInformation.GetRegistrationNumber(), WrongRegNoErr);
        Assert.AreEqual(
          CompanyInformation.FieldCaption("Registration No."), CompanyInformation.GetRegistrationNumberLbl(), WrongRegNoLblErr);
    end;

    [Test]
    [HandlerFunctions('WorkOrder_RPH')]
    [Scope('OnPrem')]
    procedure SalesOrder_Print_WorkOrder()
    var
        SalesHeader: Record "Sales Header";
        DocumentPrint: Codeunit "Document-Print";
        CustomerNo: Code[20];
    begin
        Initialize();
        // [FEATURE] [Sales] [Order] [Print]
        // [SCENARIO 379027] REP 752 "Work Order" is shown when run "Work Order" action from Sales Order in case of "Order Confirmation" setup in customer document layout

        // [GIVEN] Custom Report Layout "X" with "Report ID" = 752, "Report Name" = "Work Order"
        // [GIVEN] Customer with Document Layout: Usage = "Work Order", "Report ID" = 752, "Customer Report Layout ID" = "X"
        CustomerNo := LibrarySales.CreateCustomerNo();
        AddOrderConfirmationToCustomerDocumentLayout(CustomerNo);

        // [GIVEN] Sales Order for the given customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [WHEN] Run "Work Order" action from Sales Order
        Commit();
        DocumentPrint.PrintSalesOrder(SalesHeader, Usage::"Work Order");

        // [THEN] REP 752 "Work Order" is shown
        // WorkOrder_RPH
    end;

    [Test]
    [HandlerFunctions('PickInstruction_RPH')]
    [Scope('OnPrem')]
    procedure SalesOrder_Print_PickInstruction()
    var
        SalesHeader: Record "Sales Header";
        DocumentPrint: Codeunit "Document-Print";
        CustomerNo: Code[20];
    begin
        Initialize();
        // [FEATURE] [Sales] [Order] [Print]
        // [SCENARIO 379027] REP 214 "Pick Instruction" is shown when run "Pick Instruction" action from Sales Order in case of "Order Confirmation" setup in customer document layout

        // [GIVEN] Custom Report Layout "X" with "Report ID" = 214, "Report Name" = "Pick Instruction"
        // [GIVEN] Customer with Document Layout: Usage = "Pick Instruction", "Report ID" = 214, "Customer Report Layout ID" = "X"
        CustomerNo := LibrarySales.CreateCustomerNo();
        AddOrderConfirmationToCustomerDocumentLayout(CustomerNo);

        // [GIVEN] Sales Order for the given customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [WHEN] Run "Pick Instruction" action from Sales Order
        Commit();
        DocumentPrint.PrintSalesOrder(SalesHeader, Usage::"Pick Instruction");

        // [THEN] REP 214 "Pick Instruction" is shown
        // PickInstruction_RPH
    end;

    [Test]
    [HandlerFunctions('OrderConfirmation_RPH')]
    [Scope('OnPrem')]
    procedure SalesOrder_Print_OrderConfirmation()
    var
        SalesHeader: Record "Sales Header";
        DocumentPrint: Codeunit "Document-Print";
        CustomerNo: Code[20];
    begin
        Initialize();
        // [FEATURE] [Sales] [Order] [Print]
        // [SCENARIO 379027] REP 1305 "Standard Sales - Order Conf." is shown when run "Print Confirmation" action from Sales Order in case of "Order Confirmation" setup in customer document layout

        // [GIVEN] Custom Report Layout "X" with "Report ID" = 1305, "Report Name" = "Standard Sales - Order Conf."
        // [GIVEN] Customer with Document Layout: Usage = "Confirmation Order", "Report ID" = 1305, "Customer Report Layout ID" = "X"
        CustomerNo := LibrarySales.CreateCustomerNo();
        AddOrderConfirmationToCustomerDocumentLayout(CustomerNo);

        // [GIVEN] Sales Order for the given customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [WHEN] Run "Print Confirmation" action from Sales Order
        Commit();
        DocumentPrint.PrintSalesOrder(SalesHeader, Usage::"Order Confirmation");

        // [THEN] REP 1305 "Order Confirmation" is shown
        // OrderConfirmation_RPH
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure JobTaskNosInStandardSalesInvoiceReport()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        Initialize();
        // [FEATURE] [Standard Sales - Invoice] [Report] [Job Task No.] [SaaS]
        // [SCENARIO 213776] In SaaS, Job Task Nos should be shown in "Standard Sales - Invoice" Report

        // [GIVEN] Sales Invoice with two Sales Lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);

        // [GIVEN] Sales Line 1 has "Job Task No." = "123"
        CreateSalesLineWithJobTaskNo(SalesHeader, SalesLine[1]);

        // [GIVEN] Sales Line 2 hase "Job Task No." = "321"
        CreateSalesLineWithJobTaskNo(SalesHeader, SalesLine[2]);

        // [GIVEN] Sales Invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();

        // [WHEN] Run "Standard Sales - Invoice" report
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] The 1st reported line contains "Job Task No." = "123"
        LibraryReportDataset.LoadDataSetFile;
        VerifyJobTaskNo(10000, SalesLine[1]."Job Task No.");

        // [THEN] The 2nd reported line contains "Job Task No." = "321"
        VerifyJobTaskNo(20000, SalesLine[2]."Job Task No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLenghtOfDescriptionCustomReportLayout()
    var
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportSelection: Record "Custom Report Selection";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252058] Length of "Custom Report Layout"."Description" shoud be equal to length of "Custom Report Selection"."Custom Report Description"

        LibraryTablesUT.CompareFieldTypeAndLength(
          CustomReportLayout, CustomReportLayout.FieldNo(Description),
          CustomReportSelection, CustomReportSelection.FieldNo("Custom Report Description"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmation_PrintCompanyInfoFields()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ReportSelections: Record "Report Selections";
        CompanyInfo: Record "Company Information";
        DocumentPrint: Codeunit "Document-Print";
        ReportSelectionUsage: Enum "Report Selection Usage";
        CustomerNo: Code[20];
    begin
        Initialize();
        // [FEATURE] [Sales] [Return Order] [Print]
        // [SCENARIO 382365] REP 6631 "Return Order Confirmation" should print company information and correct description field caption

        // [GIVEN] Company Information has Email = "Email1" and other bank related fields filled
        CompanyInfo.Get();
        CompanyInfo.Validate("E-Mail", RandomEmail);
        CompanyInfo.Validate("Home Page", CopyStr(LibraryRandom.RandText(10),
            1, MaxStrLen(CompanyInfo."Home Page")));
        CompanyInfo.Validate(
            "VAT Registration No.", CopyStr(LibraryRandom.RandText(10),
            1, MaxStrLen(CompanyInfo."VAT Registration No.")));
        CompanyInfo.Validate("Giro No.", CopyStr(LibraryRandom.RandText(10),
            1, MaxStrLen(CompanyInfo."Giro No.")));
        CompanyInfo.Validate("Bank Name", CopyStr(LibraryRandom.RandText(10),
            1, MaxStrLen(CompanyInfo."Bank Name")));
        CompanyInfo.Validate("Bank Account No.", CopyStr(LibraryRandom.RandText(10),
            1, MaxStrLen(CompanyInfo."Bank Account No.")));
        CompanyInfo.Modify(True);

        // [GIVEN] Report 6631 "Return Order Confirmation" selected as primary in Report Selection for Sales Return Order
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.InsertRecord(ReportSelectionUsage::"S.Return", '1', 6631);

        // [GIVEN] Sales Return Order for the given customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        SalesLine.Validate("No.", LibraryInventory.CreateItemNo());
        SalesLine.Modify(True);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "Return Order Confirmation"
        RunReturnOrderConfirmation(SalesHeader, false, false);

        // [THEN] Report contains info about Company email, bank related data and Correct 'Description' column name
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoEMail', CompanyInfo."E-Mail");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoHomePage', CompanyInfo."Home Page");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoVATRegNo', CompanyInfo."VAT Registration No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoGiroNo', CompanyInfo."Giro No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoBankName', CompanyInfo."Bank Name");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoBankAccNo', CompanyInfo."Bank Account No.");
        LibraryReportDataset.AssertElementWithValueExists('Desc_SalesLineCaption', SalesLine.FieldCaption(Description));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintSalesOrderProperFiltering()
    var
        SalesHeader: Record "Sales Header";
        NoSeries: array[2] of Record "No. Series";
        NoSeriesLine: array[2] of Record "No. Series Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentPrint: Codeunit "Document-Print";
        ReportLayoutTest: Codeunit "Report Layout Test";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Order] [Print]
        // [SCENARIO 386769] PrintSalesOrder method should set correct filter on SalesHeader record
        Initialize();

        // [GIVEN] Sales Order "SO" and Sales Quote "SQ" with same Document No.
        CustomerNo := LibrarySales.CreateCustomerNo();
        AddOrderConfirmationToCustomerDocumentLayout(CustomerNo);

        LibraryUtility.CreateNoSeries(NoSeries[1], true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine[1], NoSeries[1].Code, '', '');

        LibraryUtility.CreateNoSeries(NoSeries[2], true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine[2], NoSeries[2].Code, '', '');

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", NoSeries[1].Code);
        SalesReceivablesSetup.Validate("Quote Nos.", NoSeries[2].Code);
        SalesReceivablesSetup.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [WHEN] Run "Print Confirmation" action from Sales Order "SO"
        Commit();
        BindSubscription(ReportLayoutTest);
        DocumentPrint.PrintSalesOrder(SalesHeader, Usage::"Order Confirmation");

        // [THEN] SalesHeader record points to Sales Order "SO"
        // Checked by subscribing to OnBeforePrintSalesOrder event in method PrintSalesOrder of Codeunit "Document-Print"
        // and getting Sales Header RecordId to be sure it point to correct record "SO"
        Assert.ExpectedMessage(Format(SalesHeader.RecordId()), LibraryVariableStorage.DequeueText); // message from MessageHandler
    end;

    [Test]
    [HandlerFunctions('CustomReportLayoutsHandlerCancel')]
    [Scope('OnPrem')]
    procedure VerifyCustomReportNotRevertsBackToRdlc()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
        LayoutCode: Code[20];
    begin
        // [SCENARIO 466237] D365 BC - Custom report reverts back to RDLC when using Select Layout without making a choice (click Cancel).
        Initialize();

        // [GIVEN] Delete and create new Custom Report Layouts
        CustomReportLayout.SetRange("Report ID", CheckStubReportID());
        CustomReportLayout.DeleteAll();

        if ReportLayoutSelection.Get(CheckStubReportID(), CompanyName) then
            ReportLayoutSelection.Delete();

        LayoutCode := CustomReportLayout.InitBuiltInLayout(CheckStubReportID(), CustomReportLayout.Type::RDLC.AsInteger());
        CustomReportLayout.Get(LayoutCode);

        // [THEN] Create report layout selection with new custom layout 
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := CheckStubReportID();
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
        ReportLayoutSelection."Custom Report Layout Code" := CustomReportLayout.Code;
        ReportLayoutSelection.Insert(true);

        // [WHEN] Invoke Select Layout from Report Layout Selection Page
        ReportLayoutSelectionPage.OpenEdit;
        ReportLayoutSelectionPage.Filter.SetFilter("Report ID", Format(CheckStubReportID()));
        ReportLayoutSelectionPage.SelectLayout.Invoke();
        ReportLayoutSelectionPage.Close();

        // [VERIFY] Verify: Report Layout Selection should not change back to RDLC
        ReportLayoutSelection.Get(CheckStubReportID(), CompanyName);
        Assert.AreEqual(LayoutCode, ReportLayoutSelection."Custom Report Layout Code", LayoutCodeShouldNotChangedErr);
    end;

    local procedure InitCustomReportLayout(var CustomReportLayout: Record "Custom Report Layout"; LayoutType: Enum "Custom Report Layout Type"; WithCompanyName: Boolean)
    var
        LayoutCode: Code[20];
    begin
        LayoutCode := CustomReportLayout.InitBuiltInLayout(StandardSalesInvoiceReportID, LayoutType.AsInteger());
        CustomReportLayout.Get(LayoutCode);
        Assert.AreEqual(StandardSalesInvoiceReportID, CustomReportLayout."Report ID", '');
        if WithCompanyName then begin
            CustomReportLayout."Company Name" := CompanyName;
            CustomReportLayout.Modify(true);
        end;
    end;

    local procedure InitReportSelection(ReportID: Integer; Selection: Option "None","RDLC (Built-in)","Word (Built-in)","Custom RDLC","Custom Word","Excel Layout","External Layout")
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        ReportLayoutList: Record "Report Layout List";
        CustomReportLayout: Record "Custom Report Layout";
        LayoutCode: Code[20];
    begin
        if ReportLayoutSelection.Get(ReportID, CompanyName) then
            ReportLayoutSelection.Delete();
        if Selection = Selection::None then
            exit;

        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := ReportID;

        ReportLayoutList.SetRange("Report ID", ReportID);
        TenantReportLayoutSelection."Report ID" := ReportID;
        TenantReportLayoutSelection."Company Name" := CompanyName;

        ReportLayoutSelection."Company Name" := CompanyName;
        case Selection of
            Selection::"RDLC (Built-in)":
                ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            Selection::"Word (Built-in)":
                ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Word (built-in)";
            Selection::"Custom RDLC":
                begin
                    ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
                    LayoutCode := CustomReportLayout.InitBuiltInLayout(ReportID, CustomReportLayout.Type::RDLC.AsInteger());
                    CustomReportLayout.Get(LayoutCode);
                    ReportLayoutSelection."Custom Report Layout Code" := CustomReportLayout.Code;
                end;
            Selection::"Custom Word":
                begin
                    ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
                    LayoutCode := CustomReportLayout.InitBuiltInLayout(ReportID, CustomReportLayout.Type::Word.AsInteger());
                    CustomReportLayout.Get(LayoutCode);
                    ReportLayoutSelection."Custom Report Layout Code" := CustomReportLayout.Code;
                end;
            Selection::"Excel Layout":
                begin
                    SetupSelection(ReportLayoutList, TenantReportLayoutSelection, ReportLayoutList."Layout Format"::Excel);
                    ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Excel Layout";
                end;
            Selection::"External Layout":
                begin
                    SetupSelection(ReportLayoutList, TenantReportLayoutSelection, ReportLayoutList."Layout Format"::Custom);
                    ReportLayoutSelection.Type := ReportLayoutSelection.Type::"External Layout";
                end;
        end;
        ReportLayoutSelection.Insert();
    end;

    local procedure SetupSelection(var ReportLayoutList: Record "Report Layout List"; var TenantReportLayoutSelection: Record "Tenant Report Layout Selection"; LayoutFormat: Integer)
    begin
        UndoSelection(ReportLayoutList."Report ID");
        ReportLayoutList.SetRange(ReportLayoutList."Layout Format", LayoutFormat);
        if (ReportLayoutList.FindFirst()) then begin
            TenantReportLayoutSelection."Layout Name" := ReportLayoutList.Name;
            TenantReportLayoutSelection."App ID" := ReportLayoutList."Application ID";
            TenantReportLayoutSelection.Insert(true);
        end;
    end;

    local procedure UndoSelection(ReportId: Integer)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        TenantReportLayoutSelection.SetRange("Report ID", ReportId);
        TenantReportLayoutSelection.DeleteAll(true);
    end;

    local procedure AddOrderConfirmationToCustomReportLayout(): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        with CustomReportLayout do begin
            Init();
            "Report ID" := REPORT::"Standard Sales - Order Conf.";
            Insert(true);
            exit(Code);
        end;
    end;

    local procedure AddOrderConfirmationToCustomerDocumentLayout(CustomerNo: Code[20])
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        AddCustomerDocumentLayoutReport(
          CustomerNo, CustomReportSelection.Usage::"S.Order", REPORT::"Standard Sales - Order Conf.",
          AddOrderConfirmationToCustomReportLayout);
    end;

    local procedure AddCustomerDocumentLayoutReport(CustomerNo: Code[20]; NewUsage: Enum "Report Selection Usage"; ReportID: Integer; CustomReportLayoutCode: Code[20])
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        with CustomReportSelection do begin
            Init();
            "Source Type" := DATABASE::Customer;
            "Source No." := CustomerNo;
            Usage := NewUsage;
            Sequence := 1;
            "Report ID" := ReportID;
            "Custom Report Layout Code" := CustomReportLayoutCode;
            Insert(true);
        end;
    end;

    local procedure CreateSalesLineWithJobTaskNo(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        LibraryJob.CreateJob(Job);
        JobTask.Init();
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." :=
          LibraryUtility.GenerateRandomCodeWithLength(
            JobTask.FieldNo("Job Task No."), DATABASE::"Job Task", MaxStrLen(JobTask."Job Task No."));
        JobTask.Insert();
        SalesLine.Validate("Job No.", Job."No.");
        SalesLine.Validate("Job Task No.", JobTask."Job Task No.");
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
    end;

    local procedure MockPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader."Applies-to Doc. Type" := SalesCrMemoHeader."Applies-to Doc. Type"::Invoice;
        SalesCrMemoHeader."Applies-to Doc. No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Insert();
    end;

    local procedure FileContainsLine(FileName: Text; ExpectedLine: Text)
    var
        InStr: InStream;
        File: File;
        Line: Text;
    begin
        File.Open(FileName);
        File.CreateInStream(InStr);
        InStr.ReadText(Line);
        InStr.ReadText(Line);
        Assert.IsFalse(InStr.EOS, 'should not be end of file');
        File.Close();
        Assert.AreEqual(ExpectedLine, Line, 'Wrong line in the file');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReportLookupHandler(var ReportLookup: TestPage "Report Layout Lookup")
    begin
        ReportLookup.ReportID.SetValue := StandardSalesInvoiceReportID;
        ReportLookup.AddWord.SetValue := true;
        ReportLookup.AddRDLC.SetValue := true;
        ReportLookup.OK.Invoke;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure Report134600HandlerCancel(var TestReportDefaultWord: Report "Test Report - Default=Word")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ScheduleAReportHandlerCancel(var ScheduleaReport: TestPage "Schedule a Report")
    begin
        ScheduleaReport.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomReportLayoutsHandlerCancel(var CustomReportLayouts: TestPage "Custom Report Layouts")
    begin
        CustomReportLayouts.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    local procedure GetXmlAttribute(AttributeName: Text; XMLNode: DotNet XmlNode): Text
    var
        XMLAttributeNode: DotNet XmlNode;
    begin
        XMLAttributeNode := XMLNode.Attributes.GetNamedItem(AttributeName);
        if IsNull(XMLAttributeNode) then
            exit('');
        exit(Format(XMLAttributeNode.InnerText));
    end;

    local procedure ValidateHeaderColumns(var XMLNode: DotNet XmlNode)
    begin
        XMLNode := XMLNode.FirstChild; // Column BilltoCustNo
        Assert.AreEqual('CompanyAddress1', GetXmlAttribute('name', XMLNode), '');
    end;

    local procedure ValidateDataItems(var XMLNode: DotNet XmlNode)
    var
        XmlNodeList: DotNet XmlNodeList;
        XMLNode2: DotNet XmlNode;
        i: Integer;
        NodeName: Text;
    begin
        XmlNodeList := XMLNode.ChildNodes;
        Assert.IsTrue(0 < XmlNodeList.Count, 'DataItems children.');
        for i := 0 to XmlNodeList.Count - 1 do begin
            XMLNode2 := XmlNodeList.ItemOf(i);
            NodeName := GetXmlAttribute('name', XMLNode2);
            Assert.IsTrue(
              NodeName in ['LetterText',
                           'RightHeader',
                           'LeftHeader',
                           'Line',
                           'VATAmountLine',
                           'VATClauseLine',
                           'ReportTotalsLine',
                           'USReportTotalsLine',
                           'Totals'],
              '');
        end;
    end;

    local procedure VerifyJobTaskNo(LineNo: Integer; JobTaskNo: Code[20])
    begin
        LibraryReportDataset.SetRange('LineNo_Line', LineNo);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('JobTaskNo', JobTaskNo);
    end;

    local procedure InitCompanySetup()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Allow Blank Payment Info." then
            exit;

        CompanyInformation."Allow Blank Payment Info." := true;
        CompanyInformation.Modify();
    end;

    local procedure VerifySaveAsPdf(ReportID: Integer)
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        FileName := FileManagement.ServerTempFileName('pdf');
        REPORT.SaveAsPdf(ReportID, FileName);
        FileManagement.DeleteServerFile(FileName);
    end;

    local procedure VerifySaveAsWord(ReportID: Integer)
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        FileName := FileManagement.ServerTempFileName('docx');
        REPORT.SaveAsWord(ReportID, FileName);
        FileManagement.DeleteServerFile(FileName);
    end;

    local procedure VerifySaveAsExcel(ReportID: Integer)
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        FileName := FileManagement.ServerTempFileName('xlsx');
        REPORT.SaveAsExcel(ReportID, FileName);
        FileManagement.DeleteServerFile(FileName);
    end;

    local procedure VerifySchedule(ReportID: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduleAReport: Page "Schedule a Report";
    begin
        // Init
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", ReportID);
        JobQueueEntry.DeleteAll();

        // Exercise
        ScheduleAReport.ScheduleAReport(ReportID, ''); // Invokes ScheduleAReportHandlerCancel

        // Verify
        Assert.AreEqual(0, JobQueueEntry.Count, 'VerifySchedule');
        JobQueueEntry.DeleteAll();
    end;

    local procedure VerifyRun(ReportID: Integer)
    begin
        if ReportID <> 0 then;
        // REPORT.RUN(ReportID,false,true);
    end;

    local procedure RunReturnOrderConfirmation(SalesHeader: Record "Sales Header"; ShowInternalInformation: Boolean; LogInteraction: Boolean)
    var
        ReturnOrderConfirmation: Report "Return Order Confirmation";
    begin
        Commit(); // Required to run report with request page.
        Clear(ReturnOrderConfirmation);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        ReturnOrderConfirmation.SetTableView(SalesHeader);
        ReturnOrderConfirmation.InitializeRequest(ShowInternalInformation, LogInteraction);
        ReturnOrderConfirmation.Run();
    end;

    local procedure RandomEmail(): Text[80]
    begin
        exit(StrSubstNo('%1@example.com', CreateGuid));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text; var Answer: Boolean)
    begin
        Answer := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    begin
        LibraryVariableStorage.Enqueue(Msg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkOrder_RPH(var WorkOrder: TestRequestPage "Work Order")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PickInstruction_RPH(var PickInstruction: TestRequestPage "Pick Instruction")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderConfirmation_RPH(var OrderConfirmation: TestRequestPage "Standard Sales - Order Conf.")
    begin
    end;

    local procedure StandardSalesInvoiceReportID(): Integer
    begin
        exit(REPORT::"Standard Sales - Invoice");
    end;

    local procedure DetailTrialBalanceReportID(): Integer
    begin
        exit(REPORT::"Detail Trial Balance");
    end;

    local procedure CheckStubReportID(): Integer
    begin
        exit(Report::"Check (Stub/Check/Stub)");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerReturnOrderConfirmation(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Print", 'OnBeforePrintSalesOrder', '', false, false)]
    local procedure OnBeforePrintSalesOrder(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            Message(FORMAT(SalesHeader.RecordId()));
            IsPrinted := true;
        end;
    end;

}

