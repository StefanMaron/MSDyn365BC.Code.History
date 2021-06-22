codeunit 9313 "Sync.Dep.Fld-PowerBIUrlUtils"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed once the fields are marked as removed.';
    Access = Internal;
    ObsoleteTag = '16.0';

    [Scope('OnPrem')]
    procedure SyncUrlFields(var ObsoleteFieldValue: Text[250]; var ValidFieldValue: Text[2048])
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        // If the valid field is non-empty, it wins
        // If the valid field is empty, and the obsolete is not, the obsolete wins
        // In case the longer value wins and is longer than the max short value, leave the short value empty to avoid broken urls
        if ValidFieldValue <> '' then begin
            ObsoleteFieldValue := '';
            if StrLen(ValidFieldValue) <= MaxStrLen(ObsoleteFieldValue) then
                ObsoleteFieldValue := CopyStr(ValidFieldValue, 1, MaxStrLen(ObsoleteFieldValue));
        end else
            if ObsoleteFieldValue <> '' then
                ValidFieldValue := ObsoleteFieldValue;
    end;

    [Scope('OnPrem')]
    procedure SyncUrlFields(var ObsoleteFieldValue: Text[250]; var ValidFieldValue: Text[2048]; PrevObsoleteFieldValue: Text[250]; PrevValidFieldValue: Text[2048])
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        // If the valid field has changed, it wins
        // If the valid field has not changed, and the obsolete did, the obsolete wins
        // In case the longer value wins and is longer than the max short value, leave the short value empty to avoid broken urls
        if ValidFieldValue <> PrevValidFieldValue then begin
            ObsoleteFieldValue := '';
            if StrLen(ValidFieldValue) <= MaxStrLen(ObsoleteFieldValue) then
                ObsoleteFieldValue := CopyStr(ValidFieldValue, 1, MaxStrLen(ObsoleteFieldValue));
        end else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue;
    end;

}