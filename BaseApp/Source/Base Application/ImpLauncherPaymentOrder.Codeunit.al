#if not CLEAN19
codeunit 11716 "Imp. Launcher Payment Order"
{
    TableNo = "Payment Order Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    var
        PmtOrdHdr: Record "Payment Order Header";
        BankAcc: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        PmtOrdHdr.Copy(Rec);

        BankAcc.Get("Bank Account No.");
        BankExportImportSetup.Get(BankAcc."Payment Import Format");
        BankExportImportSetup.TestField(Direction, BankExportImportSetup.Direction::Import);

        if BankExportImportSetup."Processing Report ID" > 0 then
            RunProcessingReport(BankExportImportSetup, PmtOrdHdr);

        if BankExportImportSetup."Processing XMLport ID" > 0 then
            RunProcessingXMLPort(BankExportImportSetup, PmtOrdHdr);

        if BankExportImportSetup."Data Exch. Def. Code" <> '' then
            Error(NotSupportedErr,
              BankExportImportSetup.FieldCaption("Data Exch. Def. Code"), BankExportImportSetup.TableCaption);
    end;

    var
        WindowTitleTxt: Label 'Import';
        NotSupportedErr: Label 'The %1 from %2 is not supported for import Payment Orders.', Comment = '%1=FIELDCAPTION,%2=TABLECAPTION';

    local procedure RunProcessingReport(BankExportImportSetup: Record "Bank Export/Import Setup"; PmtOrdHdr: Record "Payment Order Header")
    var
        PmtOrdLn: Record "Payment Order Line";
    begin
        PmtOrdLn.SetRange("Payment Order No.", PmtOrdHdr."No.");
        REPORT.RunModal(BankExportImportSetup."Processing Report ID", false, false, PmtOrdLn);
    end;

    local procedure RunProcessingXMLPort(BankExportImportSetup: Record "Bank Export/Import Setup"; PmtOrdHdr: Record "Payment Order Header")
    var
        PmtOrdLn: Record "Payment Order Line";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        FileMgt.BLOBImportWithFilter(
          TempBlob, WindowTitleTxt, '', BankExportImportSetup.GetFilterText(), BankExportImportSetup."Default File Type");
        PmtOrdLn.Init();
        PmtOrdLn.SetRange("Payment Order No.", PmtOrdHdr."No.");
        if TempBlob.HasValue() then
            XMLPORT.Import(BankExportImportSetup."Processing XMLport ID", InStr, PmtOrdLn);
    end;
}
#endif
