codeunit 11521 "SEPA CAMT 053 Bank Rec. Lines"
{
    TableNo = "Bank Acc. Reconciliation Line";

    trigger OnRun()
    var
        ImpSEPACAMTBankRecLines: Codeunit "Imp. SEPA CAMT Bank Rec. Lines";
        ImportType: Option W1,CH053,CH054;
    begin
        ImpSEPACAMTBankRecLines.SetImportType(ImportType::CH053);
        ImpSEPACAMTBankRecLines.Run(Rec);
    end;
}

