codeunit 20236 "Transaction Value Helper"
{
    procedure ClearValues(CaseID: Guid; RecRef: RecordRef)
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.Reset();
        TaxTransactionValue.SetRange("Case ID", CaseID);
        TaxTransactionValue.SetRange("Tax Record ID", RecRef.RecordId());
        if not TaxTransactionValue.IsEmpty() then
            TaxTransactionValue.DeleteAll(true);
    end;

    procedure UpdateCaseID(var SourceRecordRef: RecordRef; TaxType: Code[20]; CaseID: Guid)
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.Reset();
        TaxTransactionValue.SetRange("Tax Type", TaxType);
        TaxTransactionValue.SetRange("Tax Record ID", SourceRecordRef.RecordId());
        if not TaxTransactionValue.IsEmpty() then
            TaxTransactionValue.ModifyAll("Case ID", CaseID);
    end;
}