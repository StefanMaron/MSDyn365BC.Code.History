codeunit 31094 "Extension Fields Management"
{
    procedure GetRecordExtensionFields(RecordID: RecordID; var FieldValueDictionary: Dictionary of [Text[30], Text])
    var
        FieldCaptionDictionary: Dictionary of [Text[30], Text];
    begin
        GetRecordExtensionFields(RecordID, FieldValueDictionary, FieldCaptionDictionary);
    end;

    procedure GetRecordExtensionFields(RecordID: RecordID; var FieldValueDictionary: Dictionary of [Text[30], Text]; var FieldCaptionDictionary: Dictionary of [Text[30], Text])
    var
        "Field": Record "Field";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldName: Text[30];
    begin
        if FieldValueDictionary.Count = 0 then
            exit;

        RecordRef.Get(RecordId);
        Field.SetRange(TableNo, RecordRef.Number);

        foreach FieldName in FieldValueDictionary.Keys() do begin
            Field.SetRange(FieldName, FieldName);
            if Field.FindFirst() and (Field.ObsoleteState <> Field.ObsoleteState::Removed) then begin
                FieldRef := RecordRef.Field(Field."No.");
                if Field.Class = Field.Class::FlowField then
                    FieldRef.CalcField();
                FieldValueDictionary.Set(FieldName, Format(FieldRef.Value));

                if FieldCaptionDictionary.ContainsKey(FieldName) then
                    FieldCaptionDictionary.Set(FieldName, FieldRef.Caption);
            end;
        end;
    end;

    procedure CopyDictionaryKeys(FromDictionary: Dictionary of [Text[30], Text]; var ToDictionary: Dictionary of [Text[30], Text])
    var
        KeyName: Text[30];
    begin
        foreach KeyName in FromDictionary.Keys() do
            ToDictionary.Set(KeyName, '');
    end;
}