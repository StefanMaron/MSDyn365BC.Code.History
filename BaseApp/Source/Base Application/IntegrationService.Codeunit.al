codeunit 5151 "Integration Service"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    procedure GetDeletedIntegrationItems(var IntegrationRecords: XMLport "Integration Records"; FromDateTime: DateTime; MaxRecords: Integer; PageID: Integer)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        IntegrationRecord.SetCurrentKey("Page ID", "Deleted On");
        IntegrationRecord.SetRange("Page ID", PageID);
        if FromDateTime = 0DT then
            IntegrationRecord.SetFilter("Deleted On", '<>%1', 0DT)
        else
            IntegrationRecord.SetFilter("Deleted On", '>=%1', FromDateTime);
        IntegrationRecords.SetMaxRecords(MaxRecords);
        IntegrationRecords.SetTableView(IntegrationRecord);
    end;

    procedure GetModifiedIntegrationItems(var IntegrationRecords: XMLport "Integration Records"; FromDateTime: DateTime; MaxRecords: Integer; PageID: Integer)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        IntegrationRecord.SetCurrentKey("Page ID", "Modified On");
        IntegrationRecord.SetRange("Page ID", PageID);
        IntegrationRecord.SetFilter("Deleted On", '=%1', 0DT);
        if FromDateTime <> 0DT then
            IntegrationRecord.SetFilter("Modified On", '>=%1', FromDateTime);
        IntegrationRecords.SetMaxRecords(MaxRecords);
        IntegrationRecords.SetTableView(IntegrationRecord);
    end;

    procedure UpdateIntegrationID(RecIDIn: Text[1024]; IntegrationID: Guid)
    var
        IntegrationRecord: Record "Integration Record";
        RecID: RecordID;
    begin
        Evaluate(RecID, RecIDIn);
        IntegrationRecord.SetRange("Record ID", RecID);
        IntegrationRecord.FindFirst;
        IntegrationRecord.Rename(IntegrationID);
    end;

    procedure GetRecIDFromIntegrationID(IntegrationID: Guid): Text[1024]
    var
        IntegrationRecord: Record "Integration Record";
    begin
        if IntegrationRecord.Get(IntegrationID) then
            exit(Format(IntegrationRecord."Record ID"));
    end;

    procedure GetIntegrationIDFromRecID(RecIDIn: Text[1024]): Guid
    var
        IntegrationRecord: Record "Integration Record";
        RecID: RecordID;
    begin
        Evaluate(RecID, RecIDIn);
        IntegrationRecord.SetRange("Record ID", RecID);
        IntegrationRecord.FindFirst;
        exit(IntegrationRecord."Integration ID");
    end;

    procedure GetVersion(): Text[30]
    begin
        exit('1.0.0.0');
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'OnForceIsApiEnabledVerification', '', false, false)]
    local procedure SetOnForceIsApiEnabledVerification(var ForceIsApiEnabledVerification: Boolean)
    begin
        ForceIsApiEnabledVerification := true;
    end;
}

