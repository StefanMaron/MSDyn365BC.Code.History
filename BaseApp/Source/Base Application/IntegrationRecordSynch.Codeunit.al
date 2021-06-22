codeunit 5336 "Integration Record Synch."
{

    trigger OnRun()
    begin
        TransferFields();
    end;

    var
        TempParameterTempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        TempTempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        ParameterSourceRecordRef: RecordRef;
        ParameterDestinationRecordRef: RecordRef;
        ParameterOnlyModified: Boolean;
        AnyFieldModified: Boolean;
        BidirectionalFieldModified: Boolean;

    procedure SetFieldMapping(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary)
    begin
        if TempParameterTempIntegrationFieldMapping.IsEmpty() then
            TempParameterTempIntegrationFieldMapping.Reset();
        TempParameterTempIntegrationFieldMapping.Copy(TempIntegrationFieldMapping, true);
        ResetFieldModifiedFlags();
    end;

    procedure SetParameters(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; OnlyTransferModifiedFields: Boolean)
    begin
        ParameterSourceRecordRef := SourceRecordRef;
        ParameterDestinationRecordRef := DestinationRecordRef;
        ParameterOnlyModified := OnlyTransferModifiedFields;
        ResetFieldModifiedFlags();
    end;

    procedure GetWasModified(): Boolean
    begin
        exit(AnyFieldModified);
    end;

    [Scope('OnPrem')]
    procedure GetWasBidirectionalFieldModified(): Boolean
    begin
        exit(BidirectionalFieldModified);
    end;

    [Scope('OnPrem')]
    procedure GetBidirectionalFieldModifiedContext(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary)
    begin
        TempIntegrationFieldMapping.Init();
        TempIntegrationFieldMapping.TransferFields(TempTempIntegrationFieldMapping);
        TempIntegrationFieldMapping.Insert();
    end;

    local procedure SetBidirectionalFieldModifiedContext(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary)
    begin
        TempTempIntegrationFieldMapping.Init();
        TempTempIntegrationFieldMapping.TransferFields(TempIntegrationFieldMapping);
        TempTempIntegrationFieldMapping.Insert();
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

    local procedure ResetFieldModifiedFlags()
    begin
        AnyFieldModified := false;
        BidirectionalFieldModified := false;
        TempTempIntegrationFieldMapping.DeleteAll();
    end;

    local procedure TransferFields()
    var
        IsBidirectional: Boolean;
    begin
        ResetFieldModifiedFlags();
        TempParameterTempIntegrationFieldMapping.FindSet();
        repeat
            IsBidirectional := TempParameterTempIntegrationFieldMapping.Bidirectional;
            if TransferField(
              TempParameterTempIntegrationFieldMapping."Source Field No.",
              TempParameterTempIntegrationFieldMapping."Destination Field No.",
              TempParameterTempIntegrationFieldMapping."Constant Value",
              TempParameterTempIntegrationFieldMapping."Not Null",
              TempParameterTempIntegrationFieldMapping."Validate Destination Field") then begin
                AnyFieldModified := true;
                if IsBidirectional and (not BidirectionalFieldModified) then begin
                    BidirectionalFieldModified := true;
                    SetBidirectionalFieldModifiedContext(TempParameterTempIntegrationFieldMapping);
                end;
            end;
        until TempParameterTempIntegrationFieldMapping.Next() = 0;
    end;

    local procedure TransferField(SourceFieldNo: Integer; DestinationFieldNo: Integer; ConstantValue: Text; SkipNullValue: Boolean; ValidateDestinationField: Boolean): Boolean
    var
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        CurrValue: Text;
        IsModified: Boolean;
    begin
        DestinationFieldRef := ParameterDestinationRecordRef.Field(DestinationFieldNo);
        if SourceFieldNo < 1 then begin // using ConstantValue as a source value
            if (not ParameterOnlyModified) or IsConstantDiffToDestination(ConstantValue, DestinationFieldRef) then begin
                CurrValue := Format(DestinationFieldRef.Value);
                if OutlookSynchTypeConv.EvaluateTextToFieldRef(ConstantValue, DestinationFieldRef, true) then
                    IsModified := (CurrValue <> Format(DestinationFieldRef.Value)) or not ParameterOnlyModified;
            end;
        end else begin
            SourceFieldRef := ParameterSourceRecordRef.Field(SourceFieldNo);
            if SourceFieldRef.Class = FieldClass::FlowField then
                SourceFieldRef.CalcField();
            if (not ParameterOnlyModified) or IsFieldModified(SourceFieldRef, DestinationFieldRef) then begin
                CurrValue := Format(DestinationFieldRef.Value);
                if TransferFieldData(SourceFieldRef, DestinationFieldRef, ValidateDestinationField, SkipNullValue) then
                    IsModified := (CurrValue <> Format(DestinationFieldRef.Value)) or not ParameterOnlyModified;
            end;
        end;
        exit(IsModified);
    end;

    local procedure TransferFieldData(var SourceFieldRef: FieldRef; var DestinationFieldRef: FieldRef; ValidateDestinationField: Boolean; SkipNullGUID: Boolean): Boolean
    var
        NewValue: Variant;
        CurrValue: Text;
        IsModified: Boolean;
        IsValueFound: Boolean;
        NeedsConversion: Boolean;
    begin
        // OnTransferFieldData is an event for handling an exceptional mapping that is not implemented by integration records
        OnTransferFieldData(SourceFieldRef, DestinationFieldRef, NewValue, IsValueFound, NeedsConversion);
        if not IsValueFound then
            NewValue := SourceFieldRef.Value
        else
            if not NeedsConversion then begin
                if SkipNullGUID and NewValue.IsGuid() then
                    if IsNullGuid(NewValue) then
                        exit(false);
                IsModified := SetDestinationValue(DestinationFieldRef, NewValue, ValidateDestinationField);
                exit(IsModified);
            end;

        if not NeedsConversion and
           (SourceFieldRef.Type = DestinationFieldRef.Type) and (DestinationFieldRef.Length >= SourceFieldRef.Length)
        then begin
            IsModified := SetDestinationValue(DestinationFieldRef, NewValue, ValidateDestinationField);
            exit(IsModified);
        end;
        CurrValue := Format(DestinationFieldRef.Value);
        if OutlookSynchTypeConv.EvaluateTextToFieldRef(Format(NewValue), DestinationFieldRef, ValidateDestinationField) then
            IsModified := (CurrValue <> Format(DestinationFieldRef.Value)) or not ParameterOnlyModified;
        exit(IsModified);
    end;

    local procedure SetDestinationValue(var DestinationFieldRef: FieldRef; NewValue: Variant; ValidateDestinationField: Boolean): Boolean
    var
        CurrValue: Text;
        IsModified: Boolean;
    begin
        CurrValue := Format(DestinationFieldRef.Value);
        IsModified := (CurrValue <> Format(NewValue)) or not ParameterOnlyModified;
        DestinationFieldRef.Value := NewValue;
        if IsModified and ValidateDestinationField then
            DestinationFieldRef.Validate();
        exit(IsModified);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    begin
    end;
}

