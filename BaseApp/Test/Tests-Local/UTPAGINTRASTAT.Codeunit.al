codeunit 142035 "UT PAG INTRASTAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileManagement: Codeunit "File Management";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterCheckListReportSelectionIntrastat()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportUsage: Option Checklist,Form,Disk,Disklabel;
    begin
        // Purpose of the test is to validate Function - SetUsageFilter of Page Report Selection - Intrastat.

        // Setup: Create DACH Report Selections for Usage Intrastat Checklist.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Checklist", 11013, 'Intrastat - Checklist DE');  // Report ID of - Intrastat - Checklist DE.

        // Exercise & verify: Update Usage as Checklist Report on  Report Selection - Intrastat. Verify Report ID and Report Name - DACH Report Selections is updated on the Page.
        OpenAndVerifyReportSelectionIntrastat(ReportUsage::Checklist, DACHReportSelections.Sequence, DACHReportSelections."Report ID", DACHReportSelections."Report Name");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterFormReportSelectionIntrastat()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportUsage: Option Checklist,Form,Disk,Disklabel;
    begin
        // Purpose of the test is to validate Function - SetUsageFilter of Page Report Selection - Intrastat.

        // Setup: Create DACH Report Selections for Usage Intrastat Form.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Form", 11012, 'Intrastat - Form DE');  // Report ID of - Intrastat - Form DE.

        // Exercise & verify: Update Usage as Form on  Report Selection - Intrastat. Verify Report ID and Report Name - DACH Report Selections is updated on the Page.
        OpenAndVerifyReportSelectionIntrastat(ReportUsage::Form, DACHReportSelections.Sequence, DACHReportSelections."Report ID", DACHReportSelections."Report Name");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterDiskLabelReportSelectionIntrastat()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportUsage: Option Checklist,Form,Disk,Disklabel;
    begin
        // Purpose of the test is to validate Function - SetUsageFilter of Page Report Selection - Intrastat.

        // Setup: Create DACH Report Selections for Usage Intrastat Disklabel.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disklabel", 593, 'Intrastat - Make Disk Tax Auth');  // Report ID of - Intrastat - Make Disk Tax Auth.

        // Exercise & verify: Update Usage as Disklabel on  Report Selection - Intrastat. Verify Report ID and Report Name - DACH Report Selections is updated on the Page.
        OpenAndVerifyReportSelectionIntrastat(ReportUsage::Disklabel, DACHReportSelections.Sequence, DACHReportSelections."Report ID", DACHReportSelections."Report Name");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterDiskReportSelectionIntrastat()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportUsage: Option Checklist,Form,Disk,Disklabel;
    begin
        // Purpose of the test is to validate Function - SetUsageFilter of Page Report Selection - Intrastat.

        // Setup: Create DACH Report Selections for Usage Intrastat Disk.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disk", 11014, 'Intrastat - Disk Tax Auth DE');  // Report ID of - Intrastat - Disk Tax Auth DE.

        // Exercise & verify: Update Usage as Disk on Report Selection - Intrastat. Verify Report ID and report Name - DACH Report Selections is updated on the Page.
        OpenAndVerifyReportSelectionIntrastat(ReportUsage::Disk, DACHReportSelections.Sequence, DACHReportSelections."Report ID", DACHReportSelections."Report Name");
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDEReportHandler')]
    [Scope('OnPrem')]
    procedure OnActionFormIntrastatJournalPage()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Purpose of the test is to validate Action - Form on Intrastat Journal Page.

        // Setup: Create DACH Report Selections with Usage Intrastat Form.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Form", 11012, 'Intrastat - Form DE');  // Report ID of Intrastat - Form DE.
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Invokes Action - Form on Intrastat Journal page. Added ReportHandler - IntrastatFormDEReportHandler.
        Commit();  // Commit required for explicit commit used in function TemplateSelection of Codeunit 350, IntraJnlManagement called by OnOpenPage Trigger of Intrastat Journal Page.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.Form.Invoke;  // Invokes IntrastatFormDEReportHandler.
        IntrastatJournal.Close;
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistReportHandler')]
    [Scope('OnPrem')]
    procedure OnActionCheckListIntrastatJournalPage()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Purpose of the test is to validate Action - Checklist on Intrastat Journal Page.

        // Setup: Create DACH Report Selections for Usage Intrastat Checklist.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Checklist", 11013, 'Intrastat - Checklist DE');  // Report ID of - Intrastat - Checklist DE.
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Invokes Action - Checklist on Intrastat Journal page. Added ReportHandler - IntrastatChecklistReportPageHandler.
        Commit();  // Commit required for explicit commit used  in function TemplateSelection of Codeunit 350, IntraJnlManagement called by OnOpenPage Trigger of Intrastat Journal Page.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.ChecklistReport.Invoke;  // Invokes IntrastatChecklistReportPageHandler.
        IntrastatJournal.Close;
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDEReportHandler')]
    [Scope('OnPrem')]
    procedure OnActionMakeDisketteIntrastatJournalPage()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Purpose of the test is to validate Action - MakeDiskette on Intrastat Journal Page.
        UpdateReceiptsShipmentsOnIntrastatSetup(true, true);

        // Setup: Create DACH Report Selections for Usage Intrastat Disk.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disk", 11014, 'Intrastat - Disk Tax Auth DE');  // Report ID of - Intrastat - Disk Tax Auth DE.
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Invokes Action - MakeDiskette on Intrastat Journal page. Added ReportHandler - IntrastatDiskTaxAuthDEReportPageHandler.
        Commit();  // Commit required for explicit commit used in function TemplateSelection of Codeunit 350, IntraJnlManagement called by OnOpenPage Trigger of Intrastat Journal Page.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.CreateFile.Invoke;  // Invokes IntrastatDiskTaxAuthDEReportPageHandler.
        IntrastatJournal.Close;
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthReportHandler')]
    [Scope('OnPrem')]
    procedure OnActionDiskLabelsIntrastatJournalPage()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Purpose of the test is to validate Action - Disklabels on Intrastat Journal Page.

        // Setup: Create DACH Report Selections for Usage Intrastat Disklabel.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disklabel", 593, 'Intrastat - Make Disk Tax Auth');  // Report ID of - Intrastat - Make Disk Tax Auth.
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Invokes Action - Disklabels on Intrastat Journal page. Added ReportHandler - IntrastatMakeDiskTaxAuthReportPageHandler.
        Commit();  // Commit required for explicit commit used in function TemplateSelection of Codeunit 350, IntraJnlManagement called by OnOpenPage Trigger of Intrastat Journal Page.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.DiskLabels.Invoke;  // Invokes IntrastatMakeDiskTaxAuthReportPageHandler.
        IntrastatJournal.Close;
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDESaveAsPDFReportHandler')]
    [Scope('OnPrem')]
    procedure PrintIntrastatFormDE()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
        CountryRegion: Record "Country/Region";
        TransactionType: Record "Transaction Type";
        TransportMethod: Record "Transport Method";
        IntrastatArea: record "Area";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 333888] Report "Intrastat - Form DE" can be printed without errors

        // [GIVEN]: Create DACH Report Selections with Usage Intrastat Form.
        CreateDACHReportSelections(DACHReportSelections, DACHReportSelections.Usage::"Intrastat Form", 11012, 'Intrastat - Form DE');
        // [GIVEN] Prepare intrastat journal line to print
        CreateIntrastatJournalLineToPrint(IntrastatJnlLine);

        // [WHEN] Report "Intrastat - Form DE" is being printed
        Commit();
        LibraryVariableStorage.Enqueue(IntrastatJnlLine.Type);

        IntrastatJournal.OpenEdit;
        IntrastatJournal.Form.Invoke;
        IntrastatJournal.Close;
        // [THEN] No RDLC rendering errors
    end;

    local procedure CreateDACHReportSelections(var DACHReportSelections: Record "DACH Report Selections"; Usage: Option; ReportID: Integer; ReportName: Text[80])
    begin
        DACHReportSelections.DeleteAll();

        DACHReportSelections.Usage := Usage;
        DACHReportSelections.Sequence := LibraryUTUtility.GetNewCode10;
        DACHReportSelections.Insert();
        DACHReportSelections."Report ID" := ReportID;
        DACHReportSelections."Report Name" := ReportName;
        DACHReportSelections.Modify();
    end;

    local procedure CreateIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        IntrastatJnlLine."Journal Template Name" := JournalTemplateName;
        IntrastatJnlLine."Journal Batch Name" := JournalBatchName;
        IntrastatJnlLine."Line No." := 1;
        IntrastatJnlLine.Insert();
    end;

    local procedure CreateIntrastatJournalLineToPrint(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
        CountryRegion: Record "Country/Region";
        TransactionType: Record "Transaction Type";
        TransportMethod: Record "Transport Method";
        IntrastatArea: record "Area";
    begin
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);
        LibraryERM.FindCountryRegion(CountryRegion);
        CountryRegion."Intrastat Code" := CountryRegion.Code;
        CountryRegion.Modify();
        IntrastatJnlLine."Country/Region Code" := CountryRegion.Code;
        IntrastatJnlLine."Tariff No." := LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number");
        TransactionType.FindFirst();
        IntrastatJnlLine."Transaction Type" := TransactionType.Code;
        TransportMethod.FindFirst();
        IntrastatJnlLine."Transport Method" := TransportMethod.Code;
        IntrastatJnlLine."Total Weight" := 1;
        IntrastatJnlLine."Area" := LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number");
        IntrastatJnlLine."Transaction Specification" := LibraryUtility.CreateCodeRecord(DATABASE::"Transaction Specification");
        IntrastatJnlLine."Country/Region of Origin Code" := CountryRegion.Code;
        IntrastatJnlLine.Modify();
    end;

    local procedure CreateIntrastatJnlTemplateAndBatch(var IntrastatJnlTemplate: Record "Intrastat Jnl. Template"; var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlTemplate.DeleteAll();
        IntrastatJnlTemplate.Name := LibraryUTUtility.GetNewCode10;
        IntrastatJnlTemplate.Insert();

        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Name := LibraryUTUtility.GetNewCode10;
        IntrastatJnlBatch.Insert();
    end;

    local procedure OpenAndVerifyReportSelectionIntrastat(ReportUsage: Option; Sequence: Text[10]; ReportID: Integer; ReportName: Text[80])
    var
        ReportSelectionIntrastat: TestPage "Report Selection - Intrastat";
    begin
        ReportSelectionIntrastat.OpenEdit;
        ReportSelectionIntrastat.ReportUsage2.SetValue(ReportUsage);
        ReportSelectionIntrastat.FILTER.SetFilter(Sequence, Sequence);
        ReportSelectionIntrastat."Report ID".AssertEquals(ReportID);
        ReportSelectionIntrastat."Report Name".AssertEquals(ReportName);
        ReportSelectionIntrastat.Close;
    end;

    local procedure UpdateReceiptsShipmentsOnIntrastatSetup(ReportReceipts: Boolean; ReportShipments: Boolean)
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IntrastatSetup.Get();
        IntrastatSetup."Report Receipts" := ReportReceipts;
        IntrastatSetup."Report Shipments" := ReportShipments;
        IntrastatSetup.Modify();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportHandler(var IntrastatFormDE: Report "Intrastat - Form DE")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure IntrastatFormDESaveAsPDFReportHandler(var IntrastatFormDE: Report "Intrastat - Form DE")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange(Type, LibraryVariableStorage.DequeueInteger());
        IntrastatFormDE.SetTableView(IntrastatJnlLine);
        IntrastatFormDE.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure IntrastatChecklistReportHandler(var IntrastatChecklistDE: Report "Intrastat - Checklist DE")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure IntrastatDiskTaxAuthDEReportHandler(var IntrastatDiskTaxAuthDE: Report "Intrastat - Disk Tax Auth DE")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure IntrastatMakeDiskTaxAuthReportHandler(var IntrastatMakeDiskTaxAuth: Report "Intrastat - Make Disk Tax Auth")
    begin
    end;
}

