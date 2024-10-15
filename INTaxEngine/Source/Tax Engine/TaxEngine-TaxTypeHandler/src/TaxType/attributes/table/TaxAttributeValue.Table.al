table 20242 "Tax Attribute Value"
{
    Caption = 'Attribute Value';
    LookupPageID = "Tax Attribute Values";
    DrillDownPageID = "Tax Attribute Values";
    DataCaptionFields = Value;
    DataClassification = EndUserIdentifiableInformation;
    Access = Internal;
    Extensible = false;
    fields
    {
        field(1; "Attribute ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Attribute ID';
            NotBlank = true;
            TableRelation = "Tax Attribute".ID;
        }
        field(2; ID; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'ID';
        }
        field(3; Value; Text[30])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Value';
            trigger OnValidate();
            begin
                if xRec.Value = Value then
                    Exit;

                TestField(Value);
                if HasBeenUsed() then
                    if not Confirm(RenameUsedAttributeValueQst) then
                        Error('');

                CheckValueUniqueness(Rec, Value);
            end;
        }
        field(10; "Attribute Name"; Text[250])
        {
            Caption = 'Attribute Name';
            FieldClass = FlowField;
            CalcFormula = Lookup ("Tax Attribute".Name WHERE(ID = Field("Attribute ID")));
        }
        field(11; Description; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Description';
        }
        field(12; "Tax Type"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Tax Type';
            TableRelation = "Tax Type".Code;
        }
    }

    keys
    {
        key(K0; "Tax Type", "Attribute ID", ID)
        {
            Clustered = True;
        }
        key(K1; Value)
        {
        }
    }

    var
        NameAlreadyExistsErr: Label 'The item attribute value with value ''%1'' already exists.', Comment = '%1 - arbitrary name';
        DeleteUsedAttributeValueQst: Label 'This item attribute value has been assigned to at least one item.\\Are you sure you want to delete it?';
        RenameUsedAttributeValueQst: Label 'This item attribute value has been assigned to at least one item.\\Are you sure you want to rename it?';

    trigger OnDelete();
    var
        AttributeValueMapping: Record "Tax Attribute Value Mapping";
    begin
        if HasBeenUsed() then
            if not Confirm(DeleteUsedAttributeValueQst) then
                Error('');
        AttributeValueMapping.SetRange("Attribute ID", "Attribute ID");
        AttributeValueMapping.SetRange("Attribute Value ID", ID);
        AttributeValueMapping.DeleteAll();
    end;

    procedure LookupAttributeValue(AttributeID: Integer; var AttributeValueID: Integer);
    var
        TaxAttributeValue: Record "Tax Attribute Value";
        TaxAttributeValues: page "Tax Attribute Values";
    begin
        TaxAttributeValue.SetRange("Attribute ID", AttributeID);
        TaxAttributeValues.LOOKUPMODE := true;
        TaxAttributeValues.SETTABLEVIEW(TaxAttributeValue);

        if TaxAttributeValue.GET(AttributeID, AttributeValueID) then
            TaxAttributeValues.SETRECORD(TaxAttributeValue);

        if TaxAttributeValues.RunModal() = ACTION::LookupOK then begin
            TaxAttributeValues.GETRECORD(TaxAttributeValue);
            AttributeValueID := TaxAttributeValue.ID;
        end;
    end;

    procedure LoadAttributesFactBoxData(KeyValue: Code[20]);
    var
        AttributeValueMapping: Record "Tax Attribute Value Mapping";
        TaxAttributeValue: Record "Tax Attribute Value";
    begin
        Reset();
        DeleteAll();
        AttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        AttributeValueMapping.SetRange("No.", KeyValue);
        if AttributeValueMapping.FindSet() then
            repeat
                if TaxAttributeValue.GET(AttributeValueMapping."Attribute ID", AttributeValueMapping."Attribute Value ID") then begin
                    TRANSFERFIELDS(TaxAttributeValue);
                    Insert();
                end
            until AttributeValueMapping.Next() = 0;
    end;

    procedure LoadCategoryAttributesFactBoxData(CategoryCode: Code[20]);
    var
        AttributeValueMapping: Record "Tax Attribute Value Mapping";
        TaxAttributeValue: Record "Tax Attribute Value";
    begin
        Reset();
        DeleteAll();

        if CategoryCode = '' then
            Exit;

        AttributeValueMapping.SetRange("Table ID", DATABASE::"Item Category");
        repeat
            AttributeValueMapping.SetRange("No.", CategoryCode);
            if AttributeValueMapping.FindSet() then
                repeat
                    if TaxAttributeValue.GET(AttributeValueMapping."Attribute ID", AttributeValueMapping."Attribute Value ID") then
                        if not AttributeExists(TaxAttributeValue."Attribute ID") then begin
                            TRANSFERFIELDS(TaxAttributeValue);
                            Insert();
                        end;
                until AttributeValueMapping.Next() = 0;
        until CategoryCode = '';
    end;

    procedure HasBeenUsed(): Boolean;
    var
        AttributeValueMapping: Record "Tax Attribute Value Mapping";
    begin
        AttributeValueMapping.SetRange("Attribute ID", "Attribute ID");
        AttributeValueMapping.SetRange("Attribute Value ID", ID);
        Exit(not AttributeValueMapping.IsEmpty());
    end;

    local procedure CheckValueUniqueness(TaxAttributeValue: Record "Tax Attribute Value"; NameToCheck: Text[250]);
    begin
        TaxAttributeValue.SetRange("Attribute ID", "Attribute ID");
        TaxAttributeValue.SetFilter(ID, '<>%1', TaxAttributeValue.ID);
        TaxAttributeValue.SetRange(Value, NameToCheck);
        if not TaxAttributeValue.IsEmpty() then
            Error(NameAlreadyExistsErr, NameToCheck);
    end;

    local procedure AttributeExists(AttributeID: Integer) AttribExist: Boolean;
    begin
        SetRange("Attribute ID", AttributeID);
        AttribExist := not IsEmpty();
        Reset();
    end;
}