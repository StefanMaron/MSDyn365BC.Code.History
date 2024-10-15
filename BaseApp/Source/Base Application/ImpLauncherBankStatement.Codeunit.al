#if not CLEAN19
codeunit 11717 "Imp. Launcher Bank Statement"
{
    TableNo = "Bank Statement Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    var
        BankStmtHdr: Record "Bank Statement Header";
        BankAcc: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankStmtHdr.Copy(Rec);

        BankAcc.Get("Bank Account No.");
        BankExportImportSetup.Get(BankAcc."Bank Statement Import Format");
        BankExportImportSetup.TestField(Direction, BankExportImportSetup.Direction::Import);

        if BankExportImportSetup."Processing Report ID" > 0 then
            RunProcessingReport(BankExportImportSetup, BankStmtHdr);

        if BankExportImportSetup."Processing XMLport ID" > 0 then
            RunProcessingXMLPort(BankExportImportSetup, BankStmtHdr);

        if BankExportImportSetup."Data Exch. Def. Code" <> '' then
            RunProcessingDataExchDef(BankStmtHdr);
    end;

    var
        WindowTitleTxt: Label 'Import';

    local procedure RunProcessingReport(BankExportImportSetup: Record "Bank Export/Import Setup"; BankStmtHdr: Record "Bank Statement Header")
    var
        BankStmtLn: Record "Bank Statement Line";
    begin
        BankStmtLn.SetRange("Bank Statement No.", BankStmtHdr."No.");
        REPORT.RunModal(BankExportImportSetup."Processing Report ID", false, false, BankStmtLn);
    end;

    local procedure RunProcessingXMLPort(BankExportImportSetup: Record "Bank Export/Import Setup"; BankStmtHdr: Record "Bank Statement Header")
    var
        BankStmtLn: Record "Bank Statement Line";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        FileMgt.BLOBImportWithFilter(
          TempBlob, WindowTitleTxt, '', BankExportImportSetup.GetFilterText(), BankExportImportSetup."Default File Type");
        BankStmtLn.Init();
        BankStmtLn.SetRange("Bank Statement No.", BankStmtHdr."No.");
        if TempBlob.HasValue() then
            XMLPORT.Import(BankExportImportSetup."Processing XMLport ID", InStr, BankStmtLn);
    end;

    local procedure RunProcessingDataExchDef(BankStmtHdr: Record "Bank Statement Header")
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLn: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccRecon.Init();
        BankAccRecon."Statement Type" := BankAccRecon."Statement Type"::"Payment Application";
        BankAccRecon."Bank Account No." := BankStmtHdr."Bank Account No.";
        BankAccRecon."Statement No." := BankStmtHdr."No.";
        BankAccRecon.Insert();

        Commit();
        if not ImportBankStatement(BankAccRecon) then begin
            BankAccReconLn.SetRange("Statement Type", BankAccRecon."Statement Type");
            BankAccReconLn.SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
            BankAccReconLn.SetRange("Statement No.", BankAccRecon."Statement No.");
            PAGE.RunModal(PAGE::"Payment Reconciliation Journal", BankAccReconLn);
        end;

        if not CreateBankStmtLine(BankAccRecon) then begin
            BankAccRecon.Delete(true);
            Error(GetLastErrorText);
        end;

        BankAccRecon.Delete(true);
    end;

    local procedure ImportBankStatement(var BankAccRecon: Record "Bank Acc. Reconciliation"): Boolean
    var
        ImportBankStatementCZ: Codeunit "Import Bank Statement CZ";
    begin
        exit(ImportBankStatementCZ.Run(BankAccRecon));
    end;

    local procedure CreateBankStmtLine(var BankAccRecon: Record "Bank Acc. Reconciliation"): Boolean
    var
        CreateBankAccStmtLine: Codeunit "Create Bank Acc. Stmt Line";
    begin
        exit(CreateBankAccStmtLine.Run(BankAccRecon));
    end;
}
#endif
