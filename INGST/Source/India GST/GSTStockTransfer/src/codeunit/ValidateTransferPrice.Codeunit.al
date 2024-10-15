codeunit 18393 "Validate Transfer Price"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Use Case Event Library", 'OnAddUseCaseEventstoLibrary', '', false, false)]
    local procedure OnAddUseCaseEventstoLibrary()
    var
        UseCaseEventLibrary: Codeunit "Use Case Event Library";
    begin
        UseCaseEventLibrary.AddUseCaseEventToLibrary('OnAfterTransferPrirce', Database::"Transfer Line", 'After Update Transfer Price');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterValidateEvent', 'Transfer Price', false, false)]
    local procedure HandleServiceLineUseCase(var Rec: Record "Transfer Line")
    var
        TaxCaseExecution: Codeunit "Use Case Execution";
    begin
        TaxCaseExecution.HandleEvent('OnAfterTransferPrirce', Rec, '', 1);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tax Transaction Value", 'OnBeforeTableFilterApplied', '', false, false)]
    local procedure OnBeforeTableFilterApplied(var TaxRecordID: RecordID; LineNoFilter: Integer; DocumentNoFilter: Text)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", DocumentNoFilter);
        TransferLine.SetRange("Line No.", LineNoFilter);
        if TransferLine.FindFirst() then
            TaxRecordID := TransferLine.RecordId();
    end;
}