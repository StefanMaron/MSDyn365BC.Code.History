codeunit 20233 "Tax Setup Matrix Mgmt."
{
    procedure FillColumnArray(TaxType: Code[20]; var AttributeCaption: array[20] of Text; var AttributeValue: array[20] of Text; var RangeAttribute: array[20] of Boolean; var AttributeID: array[20] of Integer; var ColumnCount: Integer)
    var
        TaxRateSetup: Record "Tax Rate Column Setup";
        i: Integer;
    begin
        TaxRateSetup.SetCurrentKey(Sequence);
        TaxRateSetup.SetFilter("Tax Type", '%1|%2', TaxType, '');
        TaxRateSetup.FindSet();

        repeat
            i += 1;
            AttributeID[i] := TaxRateSetup."Column ID";
            AttributeCaption[i] := TaxRateSetup."Column Name";

            case TaxRateSetup."Column Type" of
                TaxRateSetup."Column Type"::Component:
                    AttributeCaption[i] := TaxRateSetup."Column Name" + ' ' + '%';
                TaxRateSetup."Column Type"::"Range From and Range To":
                    begin
                        AttributeCaption[i] := TaxRateSetup."Column Name" + ' From';
                        i += 1;
                        AttributeCaption[i] := TaxRateSetup."Column Name" + ' To';
                        RangeAttribute[i] := true;
                        AttributeID[i] := TaxRateSetup."Column ID";
                    end;
            end;
        until TaxRateSetup.Next() = 0;

        CaptionCount := i;
        ColumnCount := CaptionCount;
    end;

    procedure FillColumnValue(ConfigID: Guid; var AttributeValue: array[20] of Text; var RangeAttribute: array[20] of Boolean; var AttributeID: array[20] of Integer)
    var
        TaxRateValue: Record "Tax Rate Value";
        TaxRateColumnSetup: Record "Tax Rate Column Setup";
        Datatype: Enum "Symbol Data Type";
        i: Integer;
        ColumnIndex: Integer;
    begin
        Clear(AttributeValue);
        for i := 1 to CaptionCount do begin
            TaxRateValue.Reset();
            TaxRateValue.SetRange("Config ID", ConfigID);
            TaxRateValue.SetRange("Column ID", AttributeID[i]);
            if TaxRateValue.FindFirst() then begin
                TaxRateColumnSetup.Reset();
                TaxRateColumnSetup.SetRange("Tax Type", TaxRateValue."Tax Type");
                TaxRateColumnSetup.SetRange("Column ID", TaxRateValue."Column ID");
                if not TaxRateColumnSetup.FindFirst() then
                    Error(RateSetupDoesNotExistErr, TaxRateValue."Column ID", TaxRateValue."Tax Type");

                Datatype := DataTypeMgmt2.GetAttributeDataTypeToVariableDataType(TaxRateColumnSetup.Type);
                if RangeAttribute[i] then
                    AttributeValue[i] := ScriptDataTypeMgmt.ConvertXmlToLocalFormat(TaxRateValue."Value To", Datatype)
                else
                    AttributeValue[i] := ScriptDataTypeMgmt.ConvertXmlToLocalFormat(TaxRateValue.Value, Datatype);

                if TaxRateColumnSetup.Type = TaxRateColumnSetup.Type::Option then begin
                    Evaluate(ColumnIndex, TaxRateValue.Value);
                    if TaxRateColumnSetup."Linked Attribute ID" <> 0 then
                        AttributeValue[i] := TaxAttributeMgmt.GetAttributeOptionText(
                                                TaxRateColumnSetup."Tax Type",
                                                TaxRateColumnSetup."Linked Attribute ID",
                                                ColumnIndex)
                    else
                        AttributeValue[i] := TaxAttributeMgmt.GetAttributeOptionText(
                                                TaxRateColumnSetup."Tax Type",
                                                TaxRateColumnSetup."Attribute ID",
                                                ColumnIndex)
                end;
            end;
        end;
    end;

    procedure UpdateTaxConfigurationValue(ConfigId: Guid; TaxType: Code[20]; AttributeID: array[20] of Integer; Index: Integer; var AttributeValue: array[20] of Text; var RangeAttribute: array[20] of Boolean)
    var
        TaxRateValue: Record "Tax Rate Value";
        TaxRate: Record "Tax Rate";
        TaxRateSetup: Record "Tax Rate Column Setup";
        DataType: Enum "Symbol Data Type";
        XmlValue: Text;
    begin
        TaxRateSetup.SetRange("Column ID", AttributeID[Index]);
        if not TaxRateSetup.FindFirst() then
            Error(RateSetupDoesNotExistErr, AttributeID[Index], TaxType);

        ScriptDataTypeMgmt.FormatAttributeValue(TaxRateSetup.Type, AttributeValue[Index]);
        if TaxRateSetup.Type = TaxRateSetup.Type::Option then
            GetAttributeOptionValue(TaxRateSetup, AttributeValue[Index])
        else
            ValidateAttributeTableRelation(TaxRateSetup, AttributeValue[Index]);

        TaxRateValue.SetRange("Config ID", ConfigId);
        TaxRateValue.SetRange("Tax Type", TaxType);
        TaxRateValue.SetRange("Column ID", AttributeID[Index]);
        TaxRateValue.FindFirst();

        DataType := DataTypeMgmt2.GetAttributeDataTypeToVariableDataType(TaxRateSetup.Type);
        if TaxRateSetup.Type <> TaxRateSetup.Type::Boolean then
            XmlValue := ScriptDataTypeMgmt.ConvertLocalToXmlFormat(AttributeValue[Index], DataType)
        else
            XmlValue := AttributeValue[Index];

        UpdateRangeColumnValue(TaxRateSetup, TaxRateValue, RangeAttribute[Index], XmlValue);
        UpdateOptionColumnValue(TaxRateSetup, TaxRateValue);

        ValidateConfigurationValue(TaxRateValue, TaxRateSetup);
        TaxRateValue.Modify();

        UpdateTaxRateId(TaxRateSetup."Tax Type", ConfigId);
        AttributeValue[Index] := ScriptDataTypeMgmt.ConvertXmlToLocalFormat(XmlValue, DataType);
    end;

    procedure GenerateTaxSetupID(ConfigID: Guid; TaxType: Code[20]) TaxSetupID: Text[2000]
    var
        TaxRateValue: Record "Tax Rate Value";
        TaxRateColumnSetup: Record "Tax Rate Column Setup";
    begin
        TaxRateColumnSetup.SetCurrentKey(Sequence);
        TaxRateColumnSetup.SetRange("Tax Type", TaxType);
        TaxRateColumnSetup.SetFilter("Column Type", '%1|%2|%3|%4|%5',
            TaxRateColumnSetup."Column Type"::"Tax Attributes",
            TaxRateColumnSetup."Column Type"::Value,
            TaxRateColumnSetup."Column Type"::"Range From",
            TaxRateColumnSetup."Column Type"::"Range From and Range To",
            TaxRateColumnSetup."Column Type"::"Range To");

        if TaxRateColumnSetup.FindSet() then
            repeat
                TaxRateValue.SetRange("Config ID", ConfigID);
                TaxRateValue.SetRange("Column ID", TaxRateColumnSetup."Column ID");
                if TaxRateValue.FindFirst() then
                    TaxSetupID += TaxRateValue.Value;
            until TaxRateColumnSetup.Next() = 0;

        CheckForDuplicateSetID(ConfigID, TaxType, TaxSetupID);
    end;

    procedure GenerateTaxRateID(ConfigID: Guid; TaxType: Code[20]) TaxRateID: Text[2000]
    var
        TaxRateValue: Record "Tax Rate Value";
        TaxRateColumnSetup: Record "Tax Rate Column Setup";
    begin
        TaxRateColumnSetup.SetCurrentKey(Sequence);
        TaxRateColumnSetup.SetRange("Tax Type", TaxType);
        TaxRateColumnSetup.SetFilter("Column Type", '%1|%2',
            TaxRateColumnSetup."Column Type"::"Tax Attributes",
            TaxRateColumnSetup."Column Type"::Value);

        if TaxRateColumnSetup.FindSet() then
            repeat
                TaxRateValue.SetRange("Config ID", ConfigID);
                TaxRateValue.SetRange("Column ID", TaxRateColumnSetup."Column ID");
                if TaxRateValue.FindFirst() then
                    TaxRateID += TaxRateValue.Value;
            until TaxRateColumnSetup.Next() = 0;
    end;

    procedure InitializeRateValue(TaxRate: Record "Tax Rate"; TaxType: Code[20])
    var
        TaxRateColumnSetup: Record "Tax Rate Column Setup";
        TaxRateValue: Record "Tax Rate Value";
    begin
        TaxRateColumnSetup.SetCurrentKey(Sequence);
        TaxRateColumnSetup.SetRange("Tax Type", TaxType);
        TaxRateColumnSetup.FindSet();
        repeat
            TaxRateValue.Init();
            TaxRateValue."Config ID" := TaxRate.ID;
            TaxRateValue.ID := CreateGuid();
            TaxRateValue."Tax Type" := TaxType;
            TaxRateValue."Column ID" := TaxRateColumnSetup."Column ID";
            TaxRateValue."Column Type" := TaxRateColumnSetup."Column Type";
            SetDefaultRateValues(TaxRateColumnSetup, TaxRateValue);
            TaxRateValue.Insert();
        until TaxRateColumnSetup.Next() = 0;
    end;

    local procedure GetAttributeOptionValue(TaxRateSetup: Record "Tax Rate Column Setup"; var Value: Text[250])
    begin
        case TaxRateSetup."Column Type" of
            TaxRateSetup."Column Type"::"Tax Attributes":
                TaxTypeObjectHelper.SearchTaxOptionAttribute(
                    TaxRateSetup."Tax Type",
                    TaxRateSetup."Attribute ID",
                    Value);
            TaxRateSetup."Column Type"::Value:
                TaxTypeObjectHelper.SearchTaxOptionAttribute(
                    TaxRateSetup."Tax Type",
                    TaxRateSetup."Linked Attribute ID",
                    Value);
        end
    end;

    local procedure ValidateAttributeTableRelation(TaxRateSetup: Record "Tax Rate Column Setup"; var Value: Text)
    begin
        if TaxRateSetup."Attribute ID" <> 0 then begin
            if TaxRateSetup."Column Type" = TaxRateSetup."Column Type"::"Tax Attributes" then
                ValidateAttributeTableRelation(Value, TaxRateSetup."Attribute ID");
        end else
            if TaxRateSetup."Linked Attribute ID" <> 0 then
                ValidateAttributeTableRelation(Value, TaxRateSetup."Linked Attribute ID");
    end;

    local procedure UpdateRangeColumnValue(TaxRateSetup: Record "Tax Rate Column Setup"; var TaxRateValue: Record "Tax Rate Value"; IsRange: Boolean; Value: Text)
    begin
        if IsRange then
            TaxRateValue."Value To" := CopyStr(Value, 1, 250)
        else
            TaxRateValue.Value := CopyStr(Value, 1, 250);

        if TaxRateSetup."Column Type" in [
            TaxRateSetup."Column Type"::"Range From and Range To",
            TaxRateSetup."Column Type"::"Range From",
            TaxRateSetup."Column Type"::"Range To"] then
            case TaxRateSetup.Type of
                TaxRateSetup.Type::Date:
                    if IsRange then
                        Evaluate(TaxRateValue."Date Value To", Value)
                    else
                        Evaluate(TaxRateValue."Date Value", Value);
                TaxRateSetup.Type::Decimal:
                    if IsRange then
                        Evaluate(TaxRateValue."Decimal Value To", Value)
                    else
                        Evaluate(TaxRateValue."Decimal Value", Value);
            end;
    end;

    local procedure UpdateOptionColumnValue(TaxRateSetup: Record "Tax Rate Column Setup"; var TaxRateValue: Record "Tax Rate Value")
    begin
        if TaxRateSetup.Type = TaxRateSetup.Type::Option then
            if TaxRateSetup."Linked Attribute ID" <> 0 then
                TaxRateValue.Value := Format(TaxAttributeMgmt.GetAttributeOptionIndex(
                    TaxRateSetup."Tax Type",
                    TaxRateSetup."Linked Attribute ID",
                    CopyStr(TaxRateValue.Value, 1, 30)))
            else
                TaxRateValue.Value := Format(TaxAttributeMgmt.GetAttributeOptionIndex(
                    TaxRateSetup."Tax Type",
                    TaxRateSetup."Attribute ID",
                    CopyStr(TaxRateValue.Value, 1, 30)));
    end;

    local procedure UpdateTaxRateId(TaxType: Code[20]; ConfigId: Guid)
    var
        TaxRate: Record "Tax Rate";
    begin
        TaxRate.Get(TaxType, ConfigId);
        TaxRate."Tax Setup ID" := GenerateTaxSetupID(ConfigId, TaxType);
        TaxRate."Tax Rate ID" := GenerateTaxRateID(ConfigId, TaxType);
        TaxRate.Modify();
        UpdateRateIDOnRateValue(ConfigId, TaxRate."Tax Rate ID");
    end;

    local procedure SetDefaultRateValues(TaxRateColumnSetup: Record "Tax Rate Column Setup"; var TaxRateValue: Record "Tax Rate Value")
    begin
        case TaxRateColumnSetup.Type of
            TaxRateColumnSetup.Type::Decimal, TaxRateColumnSetup.Type::Integer, TaxRateColumnSetup.Type::Option:
                begin
                    TaxRateValue.Value := Format(0);
                    TaxRateValue."Value To" := Format(0);
                end;
            TaxRateColumnSetup.Type::Boolean:
                begin
                    TaxRateValue.Value := Format(false);
                    TaxRateValue."Value To" := Format(false);
                end;
        end;
    end;

    local procedure ValidateConfigurationValue(TaxConfigurationValue: Record "Tax Rate Value"; TaxRateSetup: Record "Tax Rate Column Setup")
    var
        DecimalValue: Decimal;
        DecimalValue2: Decimal;
        DateValue1: Date;
        DateValue2: Date;
        ValueCannotBeLessThanZeroErr: Label 'Value cannot be less than 0 for Column %1.', Comment = '%1 = Column Name';
        DecimalValueErr: Label '%1 should not be less than %2.', Comment = '%1 = Decimal2 , %2 = Decimal1';
        DateValueErr: Label '%1 should not be less than %2.', Comment = '%1 = Decimal2 , %2 = Decimal1';
    begin
        case TaxRateSetup.Type of
            TaxRateSetup.Type::Decimal, TaxRateSetup.Type::Integer:
                begin
                    Evaluate(DecimalValue, TaxConfigurationValue.Value);
                    if DecimalValue < 0 then
                        Error(ValueCannotBeLessThanZeroErr, TaxConfigurationValue."Column Name");

                    if TaxRateSetup."Column Type" in [
                        TaxRateSetup."Column Type"::"Range From",
                        TaxRateSetup."Column Type"::"Range From and Range To",
                        TaxRateSetup."Column Type"::"Range To"]
                    then
                        if Evaluate(DecimalValue2, TaxConfigurationValue."Value To") then begin
                            if DecimalValue2 < 0 then
                                Error(ValueCannotBeLessThanZeroErr, TaxConfigurationValue."Column Name");

                            if (DecimalValue2 < DecimalValue) and (DecimalValue2 > 0) then
                                Error(DecimalValueErr, DecimalValue2, DecimalValue);
                        end;
                end;
            TaxRateSetup.Type::Date:
                begin
                    if TaxConfigurationValue."Value To" <> '' then
                        if Evaluate(DateValue1, TaxConfigurationValue.Value) then;

                    if TaxRateSetup."Column Type" in [
                        TaxRateSetup."Column Type"::"Range From",
                        TaxRateSetup."Column Type"::"Range From and Range To",
                        TaxRateSetup."Column Type"::"Range To"]
                    then
                        if Evaluate(DateValue2, TaxConfigurationValue."Value To") then
                            if (DateValue1 <> 0D) or (DateValue2 <> 0D) then
                                if DateValue2 < DateValue1 then
                                    Error(DateValueErr, DateValue2, DateValue1);
                end;
        end;
    end;

    local procedure CheckForDuplicateSetID(
        ConfigID: Guid;
        TaxType: Code[20];
        TaxSetID: Text)
    var
        TaxConfiguration: Record "Tax Rate";
    begin
        TaxConfiguration.SetRange("Tax Type", TaxType);
        TaxConfiguration.SetFilter(ID, '<>%1', ConfigID);
        TaxConfiguration.SetRange("Tax Setup ID", TaxSetID);
        if not TaxConfiguration.IsEmpty() then
            Error(TaxConfigurationAlreadyExistErr);
    end;

    local procedure ValidateAttributeTableRelation(var Value: Text; AttributeID: Integer)
    var
        TaxAttribute: Record "Tax Attribute";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if Value = '' then
            exit;

        TaxAttribute.SetRange(ID, AttributeID);
        if not TaxAttribute.FindFirst() then
            Error(AttributeDoesNotExistErr);

        if TaxAttribute."Refrence Table ID" = 0 then
            exit;

        TaxAttribute.TestField("Refrence Field ID");
        RecRef.Open(TaxAttribute."Refrence Table ID");
        FieldRef := RecRef.Field(TaxAttribute."Refrence Field ID");
        FieldRef.SetFilter(Format(Value));
        RecRef.FindFirst();
        Value := Format(FieldRef.Value());
    end;

    local procedure UpdateRateIDOnRateValue(ConfigId: Guid; KeyValue: Text[2000])
    var
        TaxRateValue: Record "Tax Rate Value";
    begin
        //This will be used to find exact line of Tax Rate on calculation.
        TaxRateValue.SetRange("Config ID", ConfigId);
        if not TaxRateValue.IsEmpty() then
            TaxRateValue.ModifyAll("Tax Rate ID", KeyValue);
    end;

    var
        ScriptDataTypeMgmt: Codeunit "Script Data Type Mgmt.";
        DataTypeMgmt2: Codeunit "Use Case Data Type Mgmt.";
        TaxTypeObjectHelper: Codeunit "Tax Type Object Helper";
        TaxAttributeMgmt: Codeunit "Tax Attribute Management";
        CaptionCount: Integer;
        TaxConfigurationAlreadyExistErr: Label 'Tax Rate already exist with the same setup value.';
        AttributeDoesNotExistErr: Label 'Attribute does not exist with ID %1.', Comment = '%1 = Attribute ID';
        RateSetupDoesNotExistErr: Label 'Rate Setup does not exist with Column ID %1 for Tax Type %2.', Comment = '%1 = Attribute ID,%2 = Tax Type Code';
}