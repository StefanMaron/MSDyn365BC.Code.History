table 20235 "Tax Attribute Value Selection"
{
    Caption = 'Attribute Value Selection';
    DataClassification = EndUserIdentifiableInformation;
    Access = Internal;
    Extensible = false;
    fields
    {
        field(1; "Attribute Name"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Attribute Name';
            NotBlank = true;
            trigger OnValidate();
            var
                TaxAttribute: Record "Tax Attribute";
            begin
                xRec.SetRange("Attribute Name", "Attribute Name");
                if not xRec.IsEmpty() then
                    Error(AttributeValueAlreadySpecifiedErr, "Attribute Name");

                TaxAttribute.SetRange(Name, "Attribute Name");
                if not TaxAttribute.FindFirst() then
                    Error(AttributeNameDoesNotExistErr, "Attribute Name");

                if "Attribute ID" <> TaxAttribute.ID then begin
                    Validate("Attribute ID", TaxAttribute.ID);
                    Validate("Attribute Type", TaxAttribute.Type);
                    Validate(Value, '');
                end;
            end;
        }
        field(2; Value; Text[30])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Value';
            trigger OnValidate();
            var
                GenericAttributeValue: Record "Tax Attribute Value";
                DecimalValue: Decimal;
                IntegerValue: Integer;
            begin
                if Value = '' then
                    Exit;

                Case "Attribute Type" of
                    "Attribute Type"::Decimal:
                        begin
                            DecimalValue := 0;
                            Evaluate(DecimalValue, Value);
                        end;
                    "Attribute Type"::Integer:
                        begin
                            IntegerValue := 0;
                            Evaluate(IntegerValue, Value);
                        end;
                end;
            end;
        }
        field(3; "Attribute ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Attribute ID';
        }
        field(7; "Attribute Type"; Option)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Attribute Type';
            OptionMembers = Option,Text,Integer,Decimal;
            OptionCaption = 'Option,Text,Integer,Decimal';
        }
        field(8; "Inherited-From Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Inherited-From Table ID';
        }
        field(9; "Inherited-From Key Value"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Inherited-From Key Value';
        }
        field(10; "Inheritance Level"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Inheritance Level';
        }
    }

    keys
    {
        key(K0; "Attribute Name")
        {
            Clustered = True;
        }
        key(K1; "Inheritance Level", "Attribute Name")
        {
        }
    }

    var
        AttributeValueBlockedErr: Label 'The attribute value ''%1'' is blocked.', Comment = '%1 - arbitrary name';
        AttributeValueDoesntExistErr: Label 'The attribute value ''%1'' doesn''t exist.', Comment = '%1 - arbitrary name';
        AttributeValueAlreadySpecifiedErr: Label 'You have already specified a value for attribute ''%1''.', Comment = '%1 - attribute name';

    procedure PopulateAttributeValueSelection(var TempGenericAttributeValue: Record "Tax Attribute Value" Temporary);
    begin
        if TempGenericAttributeValue.FindSet() then
            repeat
                InsertRecord(TempGenericAttributeValue, 0, '');
            until TempGenericAttributeValue.Next() = 0;
    end;

    procedure PopulateAttributeValue(var TempNewGenericAttributeValue: Record "Tax Attribute Value" Temporary);

    var
        GenericAttributeValue: Record "Tax Attribute Value";
        ValDecimal: Decimal;
    begin
        if FindSet() then
            repeat
                TempNewGenericAttributeValue.Init();
                TempNewGenericAttributeValue."Attribute ID" := "Attribute ID";
                GenericAttributeValue.Reset();
                GenericAttributeValue.SetRange("Attribute ID", "Attribute ID");
                Case "Attribute Type" of
                    "Attribute Type"::Option,
                    "Attribute Type"::Text,
                    "Attribute Type"::Integer:
                        begin
                            TempNewGenericAttributeValue.Value := Value;
                            GenericAttributeValue.SetRange(Value, Value);
                        end;
                    "Attribute Type"::Decimal:
                        if Value <> '' then begin
                            Evaluate(ValDecimal, Value);
                            GenericAttributeValue.SetRange(Value, Format(ValDecimal, 0, 9));
                            if GenericAttributeValue.IsEmpty() then begin
                                GenericAttributeValue.SetRange(Value, Format(ValDecimal));
                                if GenericAttributeValue.IsEmpty() then
                                    GenericAttributeValue.SetRange(Value, Value);
                            end;
                            TempNewGenericAttributeValue.Value := Format(ValDecimal);
                        end;
                end;
                if not GenericAttributeValue.FindFirst() then
                    InsertAttributeValue(GenericAttributeValue, Rec);
                TempNewGenericAttributeValue.ID := GenericAttributeValue.ID;
                TempNewGenericAttributeValue.Insert();
            until Next() = 0;
    end;

    procedure InsertAttributeValue(var GenericAttributeValue: Record "Tax Attribute Value"; TempAttributeValueSelection: Record "Tax Attribute Value Selection" Temporary);

    var
        ValDecimal: Decimal;
    begin
        Clear(GenericAttributeValue);
        GenericAttributeValue."Attribute ID" := TempAttributeValueSelection."Attribute ID";
        Case TempAttributeValueSelection."Attribute Type" of
            TempAttributeValueSelection."Attribute Type"::Option,
          TempAttributeValueSelection."Attribute Type"::Text:
                GenericAttributeValue.Value := TempAttributeValueSelection.Value;
            TempAttributeValueSelection."Attribute Type"::Integer:
                GenericAttributeValue.Validate(Value, TempAttributeValueSelection.Value);
            TempAttributeValueSelection."Attribute Type"::Decimal:
                if TempAttributeValueSelection.Value <> '' then begin
                    Evaluate(ValDecimal, TempAttributeValueSelection.Value);
                    GenericAttributeValue.Validate(Value, Format(ValDecimal));
                end;
        end;
        GenericAttributeValue.Insert();
    end;

    procedure InsertRecord(var TaxAttributeValue: Record "Tax Attribute Value" Temporary; DefinedOnTableID: Integer; DefinedOnKeyValue: Code[20]);

    var
        TaxAttribute: Record "Tax Attribute";
        ValueDecimal: Decimal;
    begin
        "Attribute ID" := TaxAttributeValue."Attribute ID";
        TaxAttribute.SetRange(ID, TaxAttributeValue."Attribute ID");
        TaxAttribute.FindFirst();
        "Attribute Name" := TaxAttribute.Name;
        "Attribute Type" := TaxAttribute.Type;
        if IsNotBlankDecimal(TaxAttributeValue.Value) then begin
            if not Evaluate(ValueDecimal, TaxAttributeValue.Value, 9) then
                Evaluate(ValueDecimal, TaxAttributeValue.Value);
            Value := Format(ValueDecimal);
        end else
            Value := Format(TaxAttributeValue.Value);

        "Inherited-From Table ID" := DefinedOnTableID;
        "Inherited-From Key Value" := DefinedOnKeyValue;
        Insert();
    end;

    procedure FindAttributeValue(var GenericAttributeValue: Record "Tax Attribute Value"): Boolean;
    begin
        Exit(FindAttributeValueFromRecord(GenericAttributeValue, Rec));
    end;

    procedure FindAttributeValueFromRecord(var GenericAttributeValue: Record "Tax Attribute Value"; AttributeValueSelection: Record "Tax Attribute Value Selection"): Boolean;

    var
        ValDecimal: Decimal;
    begin
        GenericAttributeValue.Reset();
        GenericAttributeValue.SetRange("Attribute ID", AttributeValueSelection."Attribute ID");
        GenericAttributeValue.SetRange(Value, AttributeValueSelection.Value);
        Exit(GenericAttributeValue.FindFirst());
    end;

    procedure GetAttributeValueID(var TempGenericAttributeValueToInsert: Record "Tax Attribute Value" Temporary): Integer;
    var
        GenericAttributeValue: Record "Tax Attribute Value";
        ValDecimal: Decimal;
    begin
        if not FindAttributeValue(GenericAttributeValue) then begin
            GenericAttributeValue."Attribute ID" := "Attribute ID";
            if IsNotBlankDecimal(Value) then begin
                Evaluate(ValDecimal, Value);
                GenericAttributeValue.Validate(Value, Format(ValDecimal));
            end else
                GenericAttributeValue.Value := Value;
            GenericAttributeValue.Insert();
        end;
        TempGenericAttributeValueToInsert.TRANSFERFIELDS(GenericAttributeValue);
        TempGenericAttributeValueToInsert.Insert();
        Exit(GenericAttributeValue.ID);
    end;

    procedure IsNotBlankDecimal(TextValue: Text[250]): Boolean;
    var
        TaxAttribute: Record "Tax Attribute";
    begin
        TaxAttribute.SetRange(ID, "Attribute ID");
        if not TaxAttribute.FindFirst() then
            Error(AttributeDoesNotExistErr, "Attribute ID");

        Exit((TextValue <> '') and (TaxAttribute.Type = TaxAttribute.Type::Decimal));
    end;

    var
        AttributeDoesNotExistErr: Label 'Attribute does not exist with ID %1.', Comment = '%1 = Attribute ID';
        AttributeNameDoesNotExistErr: Label 'Attribute does not exist with Name %1.', Comment = '%1 = Attribute Name';
}