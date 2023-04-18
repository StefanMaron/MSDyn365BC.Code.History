codeunit 228 "Test Report-Print"
{

    trigger OnRun()
    begin
    end;

    var
        ReportSelection: Record "Report Selections";
        GenJnlTemplate: Record "Gen. Journal Template";
        VATStmtTmpl: Record "VAT Statement Template";
        ItemJnlTemplate: Record "Item Journal Template";
#if not CLEAN22
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
#endif
        GenJnlLine: Record "Gen. Journal Line";
        VATStmtLine: Record "VAT Statement Line";
        ItemJnlLine: Record "Item Journal Line";
#if not CLEAN22
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
#endif
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlLine: Record "Res. Journal Line";
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlLine: Record "Job Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FAJnlTemplate: Record "FA Journal Template";
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsuranceJnlTempl: Record "Insurance Journal Template";
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlLine: Record "Warehouse Journal Line";

    procedure PrintGenJnlBatch(GenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch.SetRecFilter();
        GenJnlTemplate.Get(GenJnlBatch."Journal Template Name");
        GenJnlTemplate.TestField("Test Report ID");
        REPORT.Run(GenJnlTemplate."Test Report ID", true, false, GenJnlBatch);
    end;

    procedure PrintGenJnlLine(var NewGenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintGenJnlLine(NewGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Copy(NewGenJnlLine);
        OnPrintGenJnlLineOnAfterGenJnlLineCopy(GenJnlLine);
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        GenJnlTemplate.TestField("Test Report ID");
        REPORT.Run(GenJnlTemplate."Test Report ID", true, false, GenJnlLine);
    end;

    procedure PrintVATStmtName(VATStmtName: Record "VAT Statement Name")
    begin
        VATStmtName.SetRecFilter();
        VATStmtTmpl.Get(VATStmtName."Statement Template Name");
        VATStmtTmpl.TestField("VAT Statement Report ID");
        REPORT.Run(VATStmtTmpl."VAT Statement Report ID", true, false, VATStmtName);
    end;

    procedure PrintVATStmtLine(var NewVATStatementLine: Record "VAT Statement Line")
    var
        IsHandled: Boolean;
    begin
        VATStmtLine.Copy(NewVATStatementLine);
        VATStmtLine.SetRange("Statement Template Name", VATStmtLine."Statement Template Name");
        VATStmtLine.SetRange("Statement Name", VATStmtLine."Statement Name");
        VATStmtTmpl.Get(VATStmtLine."Statement Template Name");
        VATStmtTmpl.TestField("VAT Statement Report ID");
        IsHandled := false;
        OnPrintVATStmtLineOnBeforeReportRun(VATStmtTmpl, VATStmtLine, IsHandled);
        if not IsHandled then
            REPORT.Run(VATStmtTmpl."VAT Statement Report ID", true, false, VATStmtLine);
    end;

    procedure PrintItemJnlBatch(ItemJnlBatch: Record "Item Journal Batch")
    begin
        ItemJnlBatch.SetRecFilter();
        ItemJnlTemplate.Get(ItemJnlBatch."Journal Template Name");
        ItemJnlTemplate.TestField("Test Report ID");
        REPORT.Run(ItemJnlTemplate."Test Report ID", true, false, ItemJnlBatch);
    end;

    procedure PrintItemJnlLine(var NewItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.Copy(NewItemJnlLine);
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        ItemJnlTemplate.Get(ItemJnlLine."Journal Template Name");
        ItemJnlTemplate.TestField("Test Report ID");
        REPORT.Run(ItemJnlTemplate."Test Report ID", true, false, ItemJnlLine);
    end;


#if not CLEAN22
    [Scope('OnPrem')]
    [Obsolete('Intrastat related functionalities are moved to Intrastat extensions.', '22.0')]
    procedure PrintIntrastatJnlLine(var NewIntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        FileManagement: Codeunit "File Management";
    begin
        IntrastatJnlLine.Copy(NewIntrastatJnlLine);
        IntrastatJnlLine.SetCurrentKey(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlLine."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlLine."Journal Batch Name");
        IntraJnlTemplate.Get(IntrastatJnlLine."Journal Template Name");
        IntraJnlTemplate.TestField("Checklist Report ID");
        REPORT.SaveAsPdf(IntraJnlTemplate."Checklist Report ID", FileManagement.ServerTempFileName('tmp'), IntrastatJnlLine);
    end;
#endif

    procedure PrintResJnlBatch(ResJnlBatch: Record "Res. Journal Batch")
    begin
        ResJnlBatch.SetRecFilter();
        ResJnlTemplate.Get(ResJnlBatch."Journal Template Name");
        ResJnlTemplate.TestField("Test Report ID");
        REPORT.Run(ResJnlTemplate."Test Report ID", true, false, ResJnlBatch);
    end;

    procedure PrintResJnlLine(var NewResJnlLine: Record "Res. Journal Line")
    begin
        ResJnlLine.Copy(NewResJnlLine);
        ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
        ResJnlTemplate.Get(ResJnlLine."Journal Template Name");
        ResJnlTemplate.TestField("Test Report ID");
        REPORT.Run(ResJnlTemplate."Test Report ID", true, false, ResJnlLine);
    end;

    procedure PrintSalesHeader(NewSalesHeader: Record "Sales Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader := NewSalesHeader;
        SalesHeader.SetRecFilter();
        CalcSalesDiscount(SalesHeader);
        ReportSelection.PrintWithCheckForCust(
            ReportSelection.Usage::"S.Test", SalesHeader, SalesHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintSalesHeaderPrepmt(NewSalesHeader: Record "Sales Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader := NewSalesHeader;
        SalesHeader.SetRecFilter();
        ReportSelection.PrintWithCheckForCust(
            ReportSelection.Usage::"S.Test Prepmt.", SalesHeader, SalesHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintPurchHeader(NewPurchHeader: Record "Purchase Header")
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader := NewPurchHeader;
        PurchHeader.SetRecFilter();
        CalcPurchDiscount(PurchHeader);
        ReportSelection.PrintWithCheckForVend(ReportSelection.Usage::"P.Test", PurchHeader, PurchHeader.FieldNo("Buy-from Vendor No."));
    end;

    procedure PrintPurchHeaderPrepmt(NewPurchHeader: Record "Purchase Header")
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader := NewPurchHeader;
        PurchHeader.SetRecFilter();
        ReportSelection.PrintWithCheckForVend(ReportSelection.Usage::"P.Test Prepmt.", PurchHeader, PurchHeader.FieldNo("Buy-from Vendor No."));
    end;

    procedure PrintBankAccRecon(NewBankAccRecon: Record "Bank Acc. Reconciliation")
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
    begin
        BankAccRecon := NewBankAccRecon;
        BankAccRecon.SetRecFilter();
        ReportSelection.PrintWithCheckForCust(ReportSelection.Usage::"B.Recon.Test", BankAccRecon, 0);
    end;

    procedure PrintFAJnlBatch(FAJnlBatch: Record "FA Journal Batch")
    begin
        FAJnlBatch.SetRecFilter();
        FAJnlTemplate.Get(FAJnlBatch."Journal Template Name");
        FAJnlTemplate.TestField("Test Report ID");
        REPORT.Run(FAJnlTemplate."Test Report ID", true, false, FAJnlBatch);
    end;

    procedure PrintFAJnlLine(var NewFAJnlLine: Record "FA Journal Line")
    begin
        FAJnlLine.Copy(NewFAJnlLine);
        FAJnlLine.SetRange("Journal Template Name", FAJnlLine."Journal Template Name");
        FAJnlLine.SetRange("Journal Batch Name", FAJnlLine."Journal Batch Name");
        FAJnlTemplate.Get(FAJnlLine."Journal Template Name");
        FAJnlTemplate.TestField("Test Report ID");
        REPORT.Run(FAJnlTemplate."Test Report ID", true, false, FAJnlLine);
    end;

    procedure PrintInsuranceJnlBatch(InsuranceJnlBatch: Record "Insurance Journal Batch")
    begin
        InsuranceJnlBatch.SetRecFilter();
        InsuranceJnlTempl.Get(InsuranceJnlBatch."Journal Template Name");
        InsuranceJnlTempl.TestField("Test Report ID");
        REPORT.Run(InsuranceJnlTempl."Test Report ID", true, false, InsuranceJnlBatch);
    end;

    procedure PrintInsuranceJnlLine(var NewInsuranceJnlLine: Record "Insurance Journal Line")
    begin
        InsuranceJnlLine.Copy(NewInsuranceJnlLine);
        InsuranceJnlLine.SetRange("Journal Template Name", InsuranceJnlLine."Journal Template Name");
        InsuranceJnlLine.SetRange("Journal Batch Name", InsuranceJnlLine."Journal Batch Name");
        InsuranceJnlTempl.Get(InsuranceJnlLine."Journal Template Name");
        InsuranceJnlTempl.TestField("Test Report ID");
        REPORT.Run(InsuranceJnlTempl."Test Report ID", true, false, InsuranceJnlLine);
    end;

    procedure PrintServiceHeader(NewServiceHeader: Record "Service Header")
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader := NewServiceHeader;
        ServiceHeader.SetRecFilter();
        CalcServDisc(ServiceHeader);
        ReportSelection.PrintWithCheckForCust(
            ReportSelection.Usage::"SM.Test", ServiceHeader, ServiceHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintWhseJnlBatch(WhseJnlBatch: Record "Warehouse Journal Batch")
    begin
        WhseJnlBatch.SetRecFilter();
        WhseJnlTemplate.Get(WhseJnlBatch."Journal Template Name");
        WhseJnlTemplate.TestField("Test Report ID");
        REPORT.Run(WhseJnlTemplate."Test Report ID", true, false, WhseJnlBatch);
    end;

    procedure PrintWhseJnlLine(var NewWhseJnlLine: Record "Warehouse Journal Line")
    begin
        WhseJnlLine.Copy(NewWhseJnlLine);
        WhseJnlLine.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
        WhseJnlLine.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
        WhseJnlTemplate.Get(WhseJnlLine."Journal Template Name");
        WhseJnlTemplate.TestField("Test Report ID");
        REPORT.Run(WhseJnlTemplate."Test Report ID", true, false, WhseJnlLine);
    end;

    procedure PrintInvtPeriod(NewInvtPeriod: Record "Inventory Period")
    var
        InvtPeriod: Record "Inventory Period";
    begin
        InvtPeriod := NewInvtPeriod;
        InvtPeriod.SetRecFilter();

        ReportSelection.PrintWithCheckForCust(
            ReportSelection.Usage::"Invt.Period Test", InvtPeriod, 0);
    end;

    procedure PrintJobJnlBatch(JobJnlBatch: Record "Job Journal Batch")
    begin
        JobJnlBatch.SetRecFilter();
        JobJnlTemplate.Get(JobJnlBatch."Journal Template Name");
        JobJnlTemplate.TestField("Test Report ID");
        REPORT.Run(JobJnlTemplate."Test Report ID", true, false, JobJnlBatch);
    end;

    procedure PrintJobJnlLine(var NewJobJnlLine: Record "Job Journal Line")
    begin
        JobJnlLine.Copy(NewJobJnlLine);
        JobJnlLine.SetRange("Journal Template Name", JobJnlLine."Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
        JobJnlTemplate.Get(JobJnlLine."Journal Template Name");
        JobJnlTemplate.TestField("Test Report ID");
        REPORT.Run(JobJnlTemplate."Test Report ID", true, false, JobJnlLine);
    end;

    local procedure CalcSalesDiscount(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        if SalesSetup."Calc. Inv. Discount" then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            OnCalcSalesDiscOnAfterSetFilters(SalesLine, SalesHeader);
            SalesLine.FindFirst();
            OnCalcSalesDiscOnBeforeRun(SalesHeader, SalesLine);
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
            Commit();
        end;

        OnAfterCalcSalesDiscount(SalesHeader, SalesLine);
    end;

    local procedure CalcPurchDiscount(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        if PurchSetup."Calc. Inv. Discount" then begin
            PurchLine.Reset();
            PurchLine.SetRange("Document Type", PurchHeader."Document Type");
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            OnCalcPurchDiscOnAfterSetFilters(PurchLine, PurchHeader);
            PurchLine.FindFirst();
            OnCalcPurchDiscOnBeforeRun(PurchHeader, PurchLine);
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
            PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
            Commit();
        end;

        OnAfterCalcPurchDiscount(PurchHeader, PurchLine);
    end;

    local procedure CalcServDisc(var ServHeader: Record "Service Header")
    var
        ServLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        if SalesSetup."Calc. Inv. Discount" then begin
            ServLine.Reset();
            ServLine.SetRange("Document Type", ServHeader."Document Type");
            ServLine.SetRange("Document No.", ServHeader."No.");
            ServLine.FindFirst();
            OnCalcServDiscOnBeforeRun(ServHeader, ServLine);
            CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServLine);
            ServHeader.Get(ServHeader."Document Type", ServHeader."No.");
            Commit();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcSalesDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPurchDiscount(var PurchHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintGenJnlLine(var NewGenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSalesDiscOnAfterSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPurchDiscOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSalesDiscOnBeforeRun(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPurchDiscOnBeforeRun(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcServDiscOnBeforeRun(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintGenJnlLineOnAfterGenJnlLineCopy(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintVATStmtLineOnBeforeReportRun(VATStatementTemplate: Record "VAT Statement Template"; VATStatementLine: Record "VAT Statement Line"; var IsHandled: Boolean)
    begin
    end;
}

