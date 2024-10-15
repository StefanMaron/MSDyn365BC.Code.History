codeunit 11715 "Exp. Launcher Payment Order"
{
    TableNo = "Issued Payment Order Header";

    trigger OnRun()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
        BankAcc: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        IssuedPmtOrdHdr.Copy(Rec);

        BankAcc.Get("Bank Account No.");
        if "Foreign Payment Order" then
            BankExportImportSetup.Get(BankAcc."Foreign Payment Export Format")
        else
            BankExportImportSetup.Get(BankAcc."Payment Export Format");

        BankExportImportSetup.TestField(Direction, BankExportImportSetup.Direction::Export);

        if BankExportImportSetup."Processing Report ID" > 0 then
            RunProcessingReport(BankExportImportSetup, IssuedPmtOrdHdr);

        if BankExportImportSetup."Processing XMLport ID" > 0 then
            RunProcessingXMLPort(BankExportImportSetup, IssuedPmtOrdHdr);

        if BankExportImportSetup."Data Exch. Def. Code" <> '' then
            RunProcessingDataExchDef(IssuedPmtOrdHdr);
    end;

    local procedure RunProcessingReport(BankExportImportSetup: Record "Bank Export/Import Setup"; IssuedPmtOrdHdr: Record "Issued Payment Order Header")
    var
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
    begin
        IssuedPmtOrdLn.SetRange("Payment Order No.", IssuedPmtOrdHdr."No.");
        REPORT.RunModal(BankExportImportSetup."Processing Report ID", false, false, IssuedPmtOrdLn);
    end;

    local procedure RunProcessingXMLPort(BankExportImportSetup: Record "Bank Export/Import Setup"; IssuedPmtOrdHdr: Record "Issued Payment Order Header")
    var
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        IssuedPmtOrdLn.Init();
        IssuedPmtOrdLn.SetRange("Payment Order No.", IssuedPmtOrdHdr."No.");
        XMLPORT.Export(BankExportImportSetup."Processing XMLport ID", OutStr, IssuedPmtOrdLn);
        FileMgt.BLOBExport(TempBlob, StrSubstNo('*.%1', BankExportImportSetup."Default File Type"), true);
    end;

    local procedure RunProcessingDataExchDef(IssuedPmtOrdHdr: Record "Issued Payment Order Header")
    var
        BankAcc: Record "Bank Account";
        GenJnlLn: Record "Gen. Journal Line";
    begin
        BankAcc.Get(IssuedPmtOrdHdr."Bank Account No.");
        BankAcc.TestField("Payment Jnl. Template Name");
        BankAcc.TestField("Payment Jnl. Batch Name");
        IssuedPmtOrdHdr.CreatePmtJnl(BankAcc."Payment Jnl. Template Name", BankAcc."Payment Jnl. Batch Name");

        GenJnlLn.SetRange("Journal Template Name", BankAcc."Payment Jnl. Template Name");
        GenJnlLn.SetRange("Journal Batch Name", BankAcc."Payment Jnl. Batch Name");
        GenJnlLn.SetRange("Document No.", IssuedPmtOrdHdr."No.");

        Commit();
        if not CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJnlLn) then
            PAGE.RunModal(PAGE::"Payment Journal", GenJnlLn);
    end;
}

