codeunit 702 "Sync.Dep.Fld-Utilities"
{
    Access = Public;

    trigger OnRun()
    begin

    end;

    /// <summary>
    /// Gets the previous record - xRec is not the previous version of the record it is the previous record on the page.
    /// If the update was not started from page, xRec will be same as the Rec.
    /// This function MUST be called before the update of the record is done, for example from OnBeforeModify trigger.
    /// </summary>
    /// <param name="CurrentRecord">Current record that we want to get a previous version of.</param>
    /// <param name="PreviousRecordRef">Previous record.</param>
    /// <returns>A boolean that indicates whether the previous record exists.</returns>
    procedure GetPreviousRecord(CurrentRecord: variant; var PreviousRecordRef: RecordRef): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        CurrentRecordRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(CurrentRecord, CurrentRecordRef) then
            exit(false);

        if (CurrentRecordRef.IsTemporary()) then
            exit(false);

        PreviousRecordRef.Open(CurrentRecordRef.Number());
        exit(PreviousRecordRef.GetBySystemId(CurrentRecordRef.Field(CurrentRecordRef.SystemIdNo()).Value));
    end;

    procedure SyncFields(var ObsoleteFieldValue: Boolean; var ValidFieldValue: Boolean)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if ValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue;
        if ObsoleteFieldValue then
            ValidFieldValue := ObsoleteFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Boolean; var ValidFieldValue: Boolean; PrevObsoleteFieldValue: Boolean; PrevValidFieldValue: Boolean)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Text; var ValidFieldValue: Text)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if ValidFieldValue <> '' then
            ObsoleteFieldValue := ValidFieldValue;
        if ObsoleteFieldValue <> '' then
            ValidFieldValue := ObsoleteFieldValue;
    end;

    procedure SyncFields(var ObsoleteFieldValue: Text; var ValidFieldValue: Text; PrevObsoleteFieldValue: Text; PrevValidFieldValue: Text)
    begin
        if ObsoleteFieldValue = ValidFieldValue then
            exit;

        if (ObsoleteFieldValue = PrevObsoleteFieldValue) and (ValidFieldValue = PrevValidFieldValue) then
            exit;

        if ValidFieldValue <> PrevValidFieldValue then
            ObsoleteFieldValue := ValidFieldValue
        else
            if ObsoleteFieldValue <> PrevObsoleteFieldValue then
                ValidFieldValue := ObsoleteFieldValue
            else
                ObsoleteFieldValue := ValidFieldValue;
    end;
}