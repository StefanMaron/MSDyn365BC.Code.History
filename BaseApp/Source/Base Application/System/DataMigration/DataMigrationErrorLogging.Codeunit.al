namespace System.Integration;

codeunit 1796 "Data Migration Error Logging"
{
    SingleInstance = true;

    procedure SetLastRecordUnderProcessing(NewLastRecordUnderProcessingId: Text)
    begin
        LastRecordUnderProcessingId := NewLastRecordUnderProcessingId;
    end;

    procedure GetLastRecordUnderProcessing(): Text
    begin
        exit(LastRecordUnderProcessingId);
    end;

    procedure ClearLastRecordUnderProcessing()
    begin
        Clear(LastRecordUnderProcessingId);
    end;

    var
        LastRecordUnderProcessingId: Text;
}