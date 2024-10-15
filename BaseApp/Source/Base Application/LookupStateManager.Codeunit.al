codeunit 109 "Lookup State Manager"
{
    SingleInstance = true;
    Access = Internal;

    trigger OnRun()
    begin

    end;

    var
        SavedVariant: Variant;
        RecordSaved: Boolean;

    internal procedure GetSavedRecord(var SavedRecordToReturn: Variant)
    begin
        if SavedVariant.IsRecord() then
            SavedRecordToReturn := SavedVariant;
    end;

    internal procedure ClearSavedRecord()
    begin
        clear(SavedVariant);
        RecordSaved := false;
    end;

    internal procedure IsRecordSaved(): Boolean
    begin
        exit(RecordSaved);
    end;

    internal procedure SaveRecord(var RecordVariant: Variant)
    begin
        SavedVariant := RecordVariant;
        RecordSaved := true;
    end;
}