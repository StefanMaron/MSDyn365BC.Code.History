codeunit 1261 "Imp. SEPA CAMT Bank Rec. Lines"
{
    TableNo = "Bank Acc. Reconciliation Line";

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        DataExch.Get("Data Exch. Entry No.");
        RecRef.GetTable(Rec);
        PreProcess(Rec);
        ProcessDataExch.ProcessAllLinesColumnMapping(DataExch, RecRef);
        PostProcess(Rec)
    end;

    var
        StatementIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Id', Locked = true;
        IBANTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/IBAN', Locked = true;
        BankIDTxt: Label '/Document/BkToCstmrStmt/Stmt/Acct/Id/Othr/Id', Locked = true;
        CurrencyTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt[@Ccy]', Locked = true;
        BalTypeTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd', Locked = true;
        ClosingBalTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/Amt', Locked = true;
        StatementDateTxt: Label '/Document/BkToCstmrStmt/Stmt/CreDtTm', Locked = true;
        CrdDbtIndTxt: Label '/Document/BkToCstmrStmt/Stmt/Bal/CdtDbtInd', Locked = true;

    local procedure PreProcess(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        DataExch: Record "Data Exch.";
        PrePostProcessXMLImport: Codeunit "Pre & Post Process XML Import";
    begin
        DataExch.Get(BankAccReconciliationLine."Data Exch. Entry No.");
        PrePostProcessXMLImport.PreProcessFile(DataExch, StatementIDTxt);
        PrePostProcessXMLImport.PreProcessBankAccount(
          DataExch, BankAccReconciliationLine."Bank Account No.", IBANTxt, BankIDTxt, CurrencyTxt);
    end;

    local procedure PostProcess(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        DataExch: Record "Data Exch.";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PrePostProcessXMLImport: Codeunit "Pre & Post Process XML Import";
        RecRef: RecordRef;
    begin
        DataExch.Get(BankAccReconciliationLine."Data Exch. Entry No.");
        BankAccReconciliation.Get(
          BankAccReconciliationLine."Statement Type",
          BankAccReconciliationLine."Bank Account No.",
          BankAccReconciliationLine."Statement No.");

        RecRef.GetTable(BankAccReconciliation);
        PrePostProcessXMLImport.PostProcessStatementEndingBalance(DataExch, RecRef,
          BankAccReconciliation.FieldNo("Statement Ending Balance"), 'CLBD', BalTypeTxt, ClosingBalTxt, CrdDbtIndTxt, 4);
        PrePostProcessXMLImport.PostProcessStatementDate(DataExch, RecRef, BankAccReconciliation.FieldNo("Statement Date"),
          StatementDateTxt);
    end;
}

