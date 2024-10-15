codeunit 11406 "Imp. SEPA CAMT Pre-Mapping"
{
    TableNo = "CBG Statement Line";

    trigger OnRun()
    var
        ImpBankTransDataUpdates: Codeunit "Imp. Bank Trans. Data Updates";
    begin
        ImpBankTransDataUpdates.InheritDataFromParentToChildNodes("Data Exch. Entry No.");
    end;
}

