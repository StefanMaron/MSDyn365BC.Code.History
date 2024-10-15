codeunit 142035 "UT PAG INTRASTAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";

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
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Checklist", 11013, 'Intrastat - Checklist DE');  // Report ID of - Intrastat - Checklist DE.

        // Exercise & verify: Update Usage as Checklist Report on  Report Selection - Intrastat. Verify Report ID and Report Name - DACH Report Selections is updated on the Page.
        OpenAndVerifyReportSelectionIntrastat(
          ReportUsage::Checklist, DACHReportSelections.Sequence,
          DACHReportSelections."Report ID", DACHReportSelections."Report Name");
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
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Form", 11012, 'Intrastat - Form DE');  // Report ID of - Intrastat - Form DE.

        // Exercise & verify: Update Usage as Form on  Report Selection - Intrastat. Verify Report ID and Report Name - DACH Report Selections is updated on the Page.
        OpenAndVerifyReportSelectionIntrastat(
          ReportUsage::Form, DACHReportSelections.Sequence,
          DACHReportSelections."Report ID", DACHReportSelections."Report Name");
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
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disklabel", 593, 'Intrastat - Make Disk Tax Auth');  // Report ID of - Intrastat - Make Disk Tax Auth.

        // Exercise & verify: Update Usage as Disklabel on  Report Selection - Intrastat. Verify Report ID and Report Name - DACH Report Selections is updated on the Page.
        OpenAndVerifyReportSelectionIntrastat(
          ReportUsage::Disklabel, DACHReportSelections.Sequence,
          DACHReportSelections."Report ID", DACHReportSelections."Report Name");
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
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disk", 11014, 'Intrastat - Disk Tax Auth DE');  // Report ID of - Intrastat - Disk Tax Auth DE.

        // Exercise & verify: Update Usage as Disk on Report Selection - Intrastat. Verify Report ID and report Name - DACH Report Selections is updated on the Page.
        OpenAndVerifyReportSelectionIntrastat(
          ReportUsage::Disk, DACHReportSelections.Sequence,
          DACHReportSelections."Report ID", DACHReportSelections."Report Name");
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
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Form", 11012, 'Intrastat - Form DE');  // Report ID of Intrastat - Form DE.
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Invokes Action - Form on Intrastat Journal page. Added ReportHandler - IntrastatFormDEReportHandler.
        Commit();  // Commit required for explicit commit used in function TemplateSelection of Codeunit 350, IntraJnlManagement called by OnOpenPage Trigger of Intrastat Journal Page.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.Form.Invoke;  // Invokes IntrastatFormDEReportHandler.
        IntrastatJournal.Close();
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDEReportHandler')]
    [Scope('OnPrem')]
    procedure OnActionCheckListIntrastatJournalPage()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        TempIntrastatJnlTemplate: Record "Intrastat Jnl. Template" temporary;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Purpose of the test is to validate Action - Checklist on Intrastat Journal Page.
        if IntrastatJnlTemplate.FindSet() then
            repeat
                TempIntrastatJnlTemplate := IntrastatJnlTemplate;
                TempIntrastatJnlTemplate.Insert();
            until IntrastatJnlTemplate.Next() = 0;
        IntrastatJnlTemplate.DeleteAll();

        // Setup: Create DACH Report Selections for Usage Intrastat Checklist.
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Checklist", 11013, 'Intrastat - Checklist DE');  // Report ID of - Intrastat - Checklist DE.
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        IntrastatJnlTemplate.Validate("Page ID");
        IntrastatJnlTemplate.Modify(true);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Invokes Action - Checklist on Intrastat Journal page. Added ReportHandler - IntrastatChecklistReportPageHandler.
        Commit();  // Commit required for explicit commit used  in function TemplateSelection of Codeunit 350, IntraJnlManagement called by OnOpenPage Trigger of Intrastat Journal Page.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.ChecklistReport.Invoke;  // Invokes IntrastatChecklistReportPageHandler.
        IntrastatJournal.Close();

        IntrastatJnlTemplate.DeleteAll();
        if TempIntrastatJnlTemplate.FindSet() then
            repeat
                IntrastatJnlTemplate := TempIntrastatJnlTemplate;
                IntrastatJnlTemplate.Insert();
            until TempIntrastatJnlTemplate.Next() = 0;
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
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disk", 11014, 'Intrastat - Disk Tax Auth DE');  // Report ID of - Intrastat - Disk Tax Auth DE.
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Invokes Action - MakeDiskette on Intrastat Journal page. Added ReportHandler - IntrastatDiskTaxAuthDEReportPageHandler.
        Commit();  // Commit required for explicit commit used in function TemplateSelection of Codeunit 350, IntraJnlManagement called by OnOpenPage Trigger of Intrastat Journal Page.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.CreateFile.Invoke;  // Invokes IntrastatDiskTaxAuthDEReportPageHandler.
        IntrastatJournal.Close();
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
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disklabel", 593, 'Intrastat - Make Disk Tax Auth');  // Report ID of - Intrastat - Make Disk Tax Auth.
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Invokes Action - Disklabels on Intrastat Journal page. Added ReportHandler - IntrastatMakeDiskTaxAuthReportPageHandler.
        Commit();  // Commit required for explicit commit used in function TemplateSelection of Codeunit 350, IntraJnlManagement called by OnOpenPage Trigger of Intrastat Journal Page.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.DiskLabels.Invoke;  // Invokes IntrastatMakeDiskTaxAuthReportPageHandler.
        IntrastatJournal.Close();
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERPH')]
    [Scope('OnPrem')]
    procedure RunReportIntrastatFormDEFromIntrastatJournalPage()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Form",
          REPORT::"Intrastat - Form DE", 'Intrastat - Form DE');  // Report ID of Intrastat - Form DE.
        Commit();
        IntrastatJournal.OpenView;
        IntrastatJournal.Form.Invoke; // no error occured when report exists
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskLabelsRPH')]
    [Scope('OnPrem')]
    procedure RunReportIntrastatDiskLabelsFromIntrastatJournalPage()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disklabel",
          REPORT::"Intrastat  Disk (Labels)", 'Intrastat - Make Disk Tax Auth');  // Report ID of - Intrastat - Make Disk Tax Auth.
        Commit();
        IntrastatJournal.OpenView;
        IntrastatJournal.DiskLabels.Invoke; // no error occured when report exists
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDERPH')]
    [Scope('OnPrem')]
    procedure RunReportIntrastatDiskTaxAuthDEFromIntrastatJournalPage()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        UpdateReceiptsShipmentsOnIntrastatSetup(true, true);
        CreateDACHReportSelections(
          DACHReportSelections, DACHReportSelections.Usage::"Intrastat Disk",
          REPORT::"Intrastat - Disk Tax Auth DE", 'Intrastat - Disk Tax Auth DE');  // Report ID of - Intrastat - Disk Tax Auth DE.
        Commit();
        IntrastatJournal.OpenView;
        IntrastatJournal.CreateFile.Invoke; // no error occured when report exists
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
        ReportSelectionIntrastat.Close();
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
    procedure IntrastatChecklistDEReportHandler(var IntrastatChecklistDE: Report "Intrastat - Checklist DE")
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatFormDERPH(var IntrastatFormDE: TestRequestPage "Intrastat - Form DE")
    begin
        IntrastatFormDE.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatDiskLabelsRPH(var IntrastatDiskLabels: TestRequestPage "Intrastat  Disk (Labels)")
    begin
        IntrastatDiskLabels.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatDiskTaxAuthDERPH(var IntrastatDiskTaxAuthDE: TestRequestPage "Intrastat - Disk Tax Auth DE")
    begin
        IntrastatDiskTaxAuthDE.Cancel.Invoke;
    end;
}

