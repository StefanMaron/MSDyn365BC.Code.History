codeunit 20103 "AMC Bank Imp.-Pre-Mapping"
{
    TableNo = "Bank Acc. Reconciliation Line";

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        AMCBankPrePostProcessXMLImport: Codeunit "AMC Bank Pre&Post Process";
    begin
        DataExch.Get("Data Exch. Entry No.");
        AMCBankPrePostProcessXMLImport.PreProcessFile(DataExch, StmtNoPathFilterTxt);
        AMCBankPrePostProcessXMLImport.PreProcessBankAccount(DataExch, "Bank Account No.", StmtBankAccNoPathFilterTxt, '', CurrCodePathFilterTxt);
    end;

    var
        StmtBankAccNoPathFilterTxt: Label '/reportExportResponse/return/finsta/statement/ownbankaccount/bankaccount', Locked = true; //AMC-JN
        CurrCodePathFilterTxt: Label '=''/reportExportResponse/return/finsta/statement/ownbankaccount/currency''|=''/reportExportResponse/return/finsta/statement/finstatransus/amountdetails/currency''', Locked = true; //AMC-JN
        StmtNoPathFilterTxt: Label '/reportExportResponse/return/finsta/statement/statementno', Locked = true; //AMC-JN
}

