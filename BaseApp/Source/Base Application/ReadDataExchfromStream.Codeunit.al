codeunit 1413 "Read Data Exch. from Stream"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        EventHandled: Boolean;
    begin
        // Fire the get stream event
        OnGetDataExchFileContentEvent(Rec, TempBlob, EventHandled);

        if EventHandled then begin
            "File Name" := 'Data Stream';
            RecordRef.GetTable(Rec);
            TempBlob.ToRecordRef(RecordRef, FieldNo("File Content"));
            RecordRef.SetTable(Rec);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDataExchFileContentEvent(DataExchIdentifier: Record "Data Exch."; var TempBlobResponse: Codeunit "Temp Blob"; var Handled: Boolean)
    begin
        // Event that will return the data stream from the identified subscriber
    end;
}

