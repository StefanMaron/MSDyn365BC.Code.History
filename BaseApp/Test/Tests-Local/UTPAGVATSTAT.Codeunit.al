codeunit 142066 "UT PAG VATSTAT"
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
    procedure SetUsageFilterVATStatement()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportUsage: Option "VAT Statement","G/L - VAT Reconciliation","VAT Statement Schedule";
    begin
        // Purpose of the test is to validate SetUsageFilter function of Page ID 26101 Report Selection - VAT.
        // Setup.
        SetUsageFilter(DACHReportSelections.Usage::"VAT Statement", ReportUsage::"VAT Statement", REPORT::"VAT Statement Germany");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterGLVATReconciliation()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportUsage: Option "VAT Statement","G/L - VAT Reconciliation","VAT Statement Schedule";
    begin
        // Purpose of the test is to validate SetUsageFilter function of Page ID 26101 Report Selection - VAT.
        // Setup.
        SetUsageFilter(DACHReportSelections.Usage::"Sales VAT Acc. Proof",
          ReportUsage::"G/L - VAT Reconciliation", REPORT::"G/L - VAT Reconciliation");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterSalesVATStatementSchedule()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportUsage: Option "VAT Statement","G/L - VAT Reconciliation","VAT Statement Schedule";
    begin
        // Purpose of the test is to validate SetUsageFilter function of Page ID 26101 Report Selection - VAT.
        // Setup.
        SetUsageFilter(DACHReportSelections.Usage::"VAT Statement Schedule", ReportUsage::"VAT Statement Schedule", REPORT::"VAT Statement Schedule");
    end;

    local procedure SetUsageFilter(Usage: Option; ReportUsage: Option; ReportID: Integer)
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportSelectionVAT: TestPage "Report Selection - VAT";
    begin
        // Create DACH Report Selections for different Usage.
        CreateDACHReportSelections(DACHReportSelections, Usage, ReportID);
        ReportSelectionVAT.OpenEdit;

        // Exercise: Report Selection VAT Page for different ReportUsage2.
        ReportSelectionVAT.ReportUsage2.SetValue(ReportUsage);
        ReportSelectionVAT.FILTER.SetFilter(Sequence, DACHReportSelections.Sequence);

        // Verify: Verify Report ID is updated on Page Report Selection - VAT for different Usages.
        ReportSelectionVAT."Report ID".AssertEquals(DACHReportSelections."Report ID");
        ReportSelectionVAT.Close;
    end;

    [Test]
    [HandlerFunctions('VATStatementGermanyRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintVATStatement()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatement: TestPage "VAT Statement";
    begin
        // Purpose of the test is to validate Print Action of Page 317 - VAT Statement.
        // Setup.
        VATStatementName.FindFirst;
        VATStatement.OpenEdit;
        VATStatement.CurrentStmtName.SetValue(VATStatementName.Name);

        // Excercise & verify: Invoke Action Print on Page VAT Statement. Opens Report - VAT Statement Germany handled in VATStatementGermanyRequestPageHandler.
        VATStatement.Print.Invoke;
        VATStatement.Close;
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLVATReconciliationVATStatement()
    var
        DACHReportSelections: Record "DACH Report Selections";
        VATStatementAction: Option GLVATReconciliation,VATStatementSchedule;
    begin
        // Purpose of the test is to validate GLVATReconciliation Action of Page 317 - VAT Statement.

        // Setup: Opens Report - G/L - VAT Reconciliation handled in GLVATReconciliationRequestPageHandler.
        VATStatementForDACHReportSelections(DACHReportSelections.Usage::"Sales VAT Acc. Proof",
          VATStatementAction::GLVATReconciliation, REPORT::"G/L - VAT Reconciliation");
    end;

    [Test]
    [HandlerFunctions('VATStatementScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATStatementScheduleFromVATStatement()
    var
        DACHReportSelections: Record "DACH Report Selections";
        VATStatementAction: Option GLVATReconciliation,VATStatementSchedule;
    begin
        // Purpose of the test is to validate VATStatementSchedule Action of Page 317 - VAT Statement.

        // Setup: Opens Report - VAT Statement Schedule handled in VATStatementScheduleRequestPageHandler.
        VATStatementForDACHReportSelections(DACHReportSelections.Usage::"VAT Statement Schedule", VATStatementAction::VATStatementSchedule, REPORT::"VAT Statement Schedule");
    end;

    local procedure VATStatementForDACHReportSelections(Usage: Option; VATStatementAction: Option; ReportID: Integer)
    var
        DACHReportSelections: Record "DACH Report Selections";
        VATStatementName: Record "VAT Statement Name";
        VATStatement: TestPage "VAT Statement";
    begin
        // Open VAT Statement Page.
        CreateDACHReportSelections(DACHReportSelections, Usage, ReportID);
        VATStatementName.FindFirst;
        VATStatement.OpenEdit;
        VATStatement.CurrentStmtName.SetValue(VATStatementName.Name);

        // Excercise & verify: Invoke different Actions on Page - VAT Statement. Verified different Reports opened successfully.
        InvokeVATStatementAction(VATStatement, VATStatementAction);
    end;

    local procedure CreateDACHReportSelections(var DACHReportSelections: Record "DACH Report Selections"; Usage: Option; ReportID: Integer)
    begin
        DACHReportSelections.Usage := Usage;
        DACHReportSelections.Sequence := LibraryUTUtility.GetNewCode10;
        DACHReportSelections."Report ID" := ReportID;
        DACHReportSelections.Insert;
    end;

    local procedure InvokeVATStatementAction(VATStatement: TestPage "VAT Statement"; "Action": Option)
    var
        VATStatementAction: Option GLVATReconciliation,VATStatementSchedule;
    begin
        case Action of
            VATStatementAction::GLVATReconciliation:
                VATStatement.GLVATReconciliation.Invoke;  // Opens handler GLVATReconciliationRequestPageHandler.
            VATStatementAction::VATStatementSchedule:
                VATStatement.VATStatementSchedule.Invoke;  // Opens handler VATStatementScheduleRequestPageHandler.
        end;
        VATStatement.Close;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementGermanyRequestPageHandler(var VATStatementGermany: TestRequestPage "VAT Statement Germany")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationRequestPageHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementScheduleRequestPageHandler(var VATStatementSchedule: TestRequestPage "VAT Statement Schedule")
    begin
    end;
}

