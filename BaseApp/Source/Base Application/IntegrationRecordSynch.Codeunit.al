codeunit 5336 "Integration Record Synch."
{

    trigger OnRun()
    begin
        WasModified := TransferFields;
    end;

    var
        TempParameterTempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        ParameterSourceRecordRef: RecordRef;
        ParameterDestinationRecordRef: RecordRef;
        ParameterOnlyModified: Boolean;
        WasModified: Boolean;

    procedure SetFieldMapping(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary)
    begin
        if TempParameterTempIntegrationFieldMapping.IsEmpty then
            TempParameterTempIntegrationFieldMapping.Reset();
        TempParameterTempIntegrationFieldMapping.Copy(TempIntegrationFieldMapping, true);
    end;

    procedure SetParameters(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; OnlyTransferModifiedFields: Boolean)
    begin
        ParameterSourceRecordRef := SourceRecordRef;
        ParameterDestinationRecordRef := DestinationRecordRef;
        ParameterOnlyModified := OnlyTransferModifiedFields;
    end;

    procedure GetWasModified(): Boolean
    begin
        exit(WasModified);
    end;

    local procedure IsConstantDiffToDestination(ConstantValue: Text; DestinationFieldRef: FieldRef): Boolean
    var
        ConstantOptionIndex: Integer;
        CurrentOptionIndex: Integer;
    begin
        if DestinationFieldRef.Type = FieldType::Option then begin
            ConstantOptionIndex := OutlookSynchTypeConv.TextToOptionValue(ConstantValue, DestinationFieldRef.OptionCaption);
            CurrentOptionIndex :=
              OutlookSynchTypeConv.TextToOptionValue(Format(DestinationFieldRef.Value), DestinationFieldRef.OptionCaption);
            exit(CurrentOptionIndex <> ConstantOptionIndex);
        end;
        exit(Format(DestinationFieldRef.Value) <> ConstantValue);
    end;

    local procedure IsFieldModified(var SourceFieldRef: FieldRef; var DestinationFieldRef: FieldRef): Boolean
    begin
        if DestinationFieldRef.Type = FieldType::Code then
            exit(Format(DestinationFieldRef.Value) <> UpperCase(DelChr(Format(SourceFieldRef.Value), '<>')));

        if DestinationFieldRef.Length <> SourceFieldRef.Length then begin
            if DestinationFieldRef.Length < SourceFieldRef.Length then
                exit(Format(DestinationFieldRef.Value) <> CopyStr(Format(SourceFieldRef), 1, DestinationFieldRef.Length));
            exit(CopyStr(Format(DestinationFieldRef.Value), 1, SourceFieldRef.Length) <> Format(SourceFieldRef));
        end;

        exit(Format(DestinationFieldRef.Value) <> Format(SourceFieldRef.Value));
    end;

    local procedure TransferFields() AnyFieldWasModified: Boolean
    begin
        with TempParameterTempIntegrationFieldMapping do begin
            FindSet;
            repeat
                AnyFieldWasModified :=
                  AnyFieldWasModified or
                  TransferField(
                    "Source Field No.", "Destination Field No.", "Constant Value",
                    "Not Null", "Validate Destination Field");
            until Next = 0;
        end;
    end;

    local procedure TransferField(SourceFieldNo: Integer; DestinationFieldNo: Integer; ConstantValue: Text; SkipNullValue: Boolean; ValidateDestinationField: Boolean): Boolean
    var
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
    begin
        DestinationFieldRef := ParameterDestinationRecordRef.Field(DestinationFieldNo);
        if SourceFieldNo < 1 then begin // using ConstantValue as a source value
            if (not ParameterOnlyModified) or IsConstantDiffToDestination(ConstantValue, DestinationFieldRef) then
                exit(OutlookSynchTypeConv.EvaluateTextToFieldRef(ConstantValue, DestinationFieldRef, true));
        end else begin
            SourceFieldRef := ParameterSourceRecordRef.Field(SourceFieldNo);
            if SourceFieldRef.Class = FieldClass::FlowField then
                SourceFieldRef.CalcField;
            if (not ParameterOnlyModified) or IsFieldModified(SourceFieldRef, DestinationFieldRef) then
                exit(TransferFieldData(SourceFieldRef, DestinationFieldRef, ValidateDestinationField, SkipNullValue));
        end;
        exit(false);
    end;

    local procedure TransferFieldData(var SourceFieldRef: FieldRef; var DestinationFieldRef: FieldRef; ValidateDestinationField: Boolean; SkipNullGUID: Boolean): Boolean
    var
        NewValue: Variant;
        IsValueFound: Boolean;
        NeedsConversion: Boolean;
    begin
        // OnTransferFieldData is an event for handling an exceptional mapping that is not implemented by integration records
        OnTransferFieldData(SourceFieldRef, DestinationFieldRef, NewValue, IsValueFound, NeedsConversion);
        if not IsValueFound then
            NewValue := SourceFieldRef.Value
        else
            if not NeedsConversion then begin
                if SkipNullGUID and NewValue.IsGuid then
                    if IsNullGuid(NewValue) then
                        exit(false);
                exit(SetDestinationValue(DestinationFieldRef, NewValue, ValidateDestinationField));
            end;

        if not NeedsConversion and
           (SourceFieldRef.Type = DestinationFieldRef.Type) and (DestinationFieldRef.Length >= SourceFieldRef.Length)
        then
            exit(SetDestinationValue(DestinationFieldRef, SourceFieldRef.Value, ValidateDestinationField));
        exit(OutlookSynchTypeConv.EvaluateTextToFieldRef(Format(NewValue), DestinationFieldRef, ValidateDestinationField));
    end;

    local procedure SetDestinationValue(var DestinationFieldRef: FieldRef; NewValue: Variant; ValidateDestinationField: Boolean): Boolean
    var
        CurrValue: Variant;
        IsModified: Boolean;
    begin
        CurrValue := Format(DestinationFieldRef.Value);
        IsModified := (Format(CurrValue) <> Format(NewValue)) or not ParameterOnlyModified;
        DestinationFieldRef.Value := NewValue;
        if IsModified and ValidateDestinationField then
            DestinationFieldRef.Validate;
        exit(IsModified);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    begin
    end;
}

