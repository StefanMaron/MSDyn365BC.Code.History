codeunit 18351 "Validate Service Trans. Price"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Use Case Event Library", 'OnAddUseCaseEventstoLibrary', '', false, false)]
    local procedure OnAddUseCaseEventstoLibrary()
    var
        TaxUseCaseCU: Codeunit "Use Case Event Library";
    begin
        TaxUseCaseCU.AddUseCaseEventToLibrary('OnAfterTransferPrireUpdate', Database::"Service Transfer Line", 'After Update Transfer Price');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Transfer Line", 'OnAfterValidateEvent', 'Transfer Price', false, false)]
    local procedure HandleServiceLineUseCase(var Rec: Record "Service Transfer Line")
    var
        TaxCaseExecution: Codeunit "Use Case Execution";
    begin
        TaxCaseExecution.HandleEvent('OnAfterTransferPrireUpdate', Rec, '', 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tax Transaction Value", 'OnBeforeTableFilterApplied', '', false, false)]
    local procedure OnBeforeTableFilterApplied(var TaxRecordID: RecordID; LineNoFilter: Integer; DocumentNoFilter: Text)
    var
        ServieTransferLine: Record "Service Transfer Line";
    begin
        ServieTransferLine.Reset();
        ServieTransferLine.SetRange("Document No.", DocumentNoFilter);
        ServieTransferLine.SetRange("Line No.", LineNoFilter);
        if ServieTransferLine.FindFirst() then
            TaxRecordID := ServieTransferLine.RecordId();
    end;
}