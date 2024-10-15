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
        if DestinationFieldRef.Type() = FieldType::Option then begin
            ConstantOptionIndex := TextToOptionValue(ConstantValue, DestinationFieldRef);
            CurrentOptionIndex := TextToOptionValue(Format(DestinationFieldRef.Value()), DestinationFieldRef);
            exit(CurrentOptionIndex <> ConstantOptionIndex);
        end;
        exit(GetTextValue(DestinationFieldRef) <> ConstantValue);
    end;

    local procedure TextToOptionValue(InputText: Text; var FieldRef: FieldRef): Integer
    var
        IntVar: Integer;
    begin
        IntVar := OutlookSynchTypeConv.TextToOptionValue(InputText, FieldRef.OptionCaption());
        if IntVar < 0 then
            IntVar := OutlookSynchTypeConv.TextToOptionValue(InputText, FieldRef.OptionMembers());
        exit(IntVar);
    end;

    local procedure EvaluateTextToFieldRef(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    begin
        if FieldRef.Type = FieldType::Option then
            exit(EvaluateTextToOptionFieldRef(InputText, FieldRef, ToValidate));
        if FieldRef.Type = FieldType::Blob then begin
            SetTextValue(FieldRef, InputText);
            exit(true);
        end;
        exit(OutlookSynchTypeConv.EvaluateTextToFieldRef(InputText, FieldRef, ToValidate));
    end;

    local procedure EvaluateTextToOptionFieldRef(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        NewValue: Integer;
        OldValue: Integer;
    begin
        if FieldRef.Type <> FieldType::Option then
            exit(false);

        if FieldRef.Class in [FieldClass::FlowField, FieldClass::FlowFilter] then
            exit(true);

        if not Evaluate(NewValue, InputText) then
            NewValue := TextToOptionValue(InputText, FieldRef);

        if NewValue < 0 then
            exit(false);

        if ToValidate then begin
            OldValue := FieldRef.Value();
            if OldValue <> NewValue then
                FieldRef.Validate(NewValue);
        end else
            FieldRef.Value := NewValue;

        exit(true);
    end;

    local procedure IsFieldModified(var SourceFieldRef: FieldRef; var DestinationFieldRef: FieldRef): Boolean
    begin
        if DestinationFieldRef.Type = FieldType::Code then
            exit(Format(DestinationFieldRef.Value) <> UpperCase(DelChr(Format(SourceFieldRef.Value), '<>')));

        if DestinationFieldRef.Type = FieldType::Blob then
            exit(GetTextValue(DestinationFieldRef) <> GetTextValue(SourceFieldRef));

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
                CurrValue := GetTextValue(DestinationFieldRef);
                if EvaluateTextToFieldRef(ConstantValue, DestinationFieldRef, true) then
                    IsModified := (CurrValue <> GetTextValue(DestinationFieldRef)) or not ParameterOnlyModified;
            end;
        end else begin
            SourceFieldRef := ParameterSourceRecordRef.Field(SourceFieldNo);
            if (SourceFieldRef.Class = FieldClass::FlowField) or (SourceFieldRef.Type = FieldType::Blob) then
                if not IsExternalTable(SourceFieldRef.Record().Number()) then
                    SourceFieldRef.CalcField();
            if (not ParameterOnlyModified) or IsFieldModified(SourceFieldRef, DestinationFieldRef) then begin
                CurrValue := GetTextValue(DestinationFieldRef);
                if TransferFieldData(SourceFieldRef, DestinationFieldRef, ValidateDestinationField, SkipNullValue) then
                    IsModified := (CurrValue <> GetTextValue(DestinationFieldRef)) or not ParameterOnlyModified;
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
            if DestinationFieldRef.Type = FieldType::Blob then
                NewValue := GetTextValue(SourceFieldRef)
            else
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
        CurrValue := GetTextValue(DestinationFieldRef);
        if EvaluateTextToFieldRef(Format(NewValue), DestinationFieldRef, ValidateDestinationField) then
            IsModified := (CurrValue <> GetTextValue(DestinationFieldRef)) or not ParameterOnlyModified;
        exit(IsModified);
    end;

    local procedure SetDestinationValue(var DestinationFieldRef: FieldRef; NewValue: Variant; ValidateDestinationField: Boolean): Boolean
    var
        CurrValue: Text;
        IsModified: Boolean;
    begin
        CurrValue := GetTextValue(DestinationFieldRef);
        IsModified := (CurrValue <> Format(NewValue)) or not ParameterOnlyModified;
        if DestinationFieldRef.Type <> FieldType::Blob then
            DestinationFieldRef.Value := NewValue
        else
            SetTextValue(DestinationFieldRef, Format(NewValue));
        if IsModified and ValidateDestinationField then
            DestinationFieldRef.Validate();
        exit(IsModified);
    end;

    internal procedure GetTextValue(var FieldRef: FieldRef): Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        FieldValue: Text;
    begin
        if FieldRef.Type <> FieldType::Blob then
            exit(Format(FieldRef.Value));
        TempBlob.FromFieldRef(FieldRef);
        if TempBlob.HasValue() then begin
            TempBlob.CreateInStream(InStream, GetBlobFieldEncoding(FieldRef));
            InStream.Read(FieldValue);
        end;
        exit(FieldValue);
    end;

    internal procedure SetTextValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        if FieldRef.Type <> FieldType::Blob then begin
            FieldRef.Value := FieldValue;
            exit;
        end;

        if FieldValue <> '' then begin
            TempBlob.CreateOutStream(OutStream, GetBlobFieldEncoding(FieldRef));
            OutStream.Write(FieldValue);
        end;
        TempBlob.ToFieldRef(FieldRef);
    end;

    local procedure GetBlobFieldEncoding(var FieldRef: FieldRef): TextEncoding
    var
        Encoding: TextEncoding;
        Handled: Boolean;
    begin
        OnGetBlobFieldEncoding(FieldRef.Record().Number(), FieldRef.Number(), Encoding, Handled);
        if Handled then
            exit(Encoding);
        if IsExternalTable(FieldRef.Record().Number()) then
            exit(TextEncoding::UTF16);
        exit(TextEncoding::UTF8);
    end;

    local procedure IsExternalTable(TableId: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableId) then
            exit(TableMetadata.TableType <> TableMetadata.TableType::Normal);
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBlobFieldEncoding(TableNo: Integer; FieldNo: Integer; var Encoding: TextEncoding; var Handled: Boolean)
    begin
    end;
}

