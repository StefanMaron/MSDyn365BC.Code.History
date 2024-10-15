table 20294 "Use Case Field Link"
{
    Caption = 'Use Case Field Link';
    DataClassification = EndUserIdentifiableInformation;
    Access = Public;
    Extensible = false;
    fields
    {
        field(1; "Case ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Case ID';
            TableRelation = "Tax Use Case".ID;
        }
        field(2; "Table Filter ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Table Filter ID';
            TableRelation = "Use Case Event Table Link".ID WHERE("Case ID" = Field("Case ID"));
        }
        field(3; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(4; "Field ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Field ID';
            NotBlank = true;
            TableRelation = Field."No." WHERE(TableNo = Field("Table ID"));
        }
        field(5; "Filter Type"; Option)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Filter Type';
            OptionMembers = "CONST","FILTER";
        }
        field(6; "Value Type"; Option)
        {
            DataClassification = SystemMetadata;
            Caption = 'Value Type';
            OptionMembers = Constant,"Lookup";
        }
        field(8; Value; Text[30])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Value';
            trigger OnValidate();
            begin
                ValidateValue();
            end;
        }
        field(9; "Lookup Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Lookup Table ID';
        }
        field(10; "Lookup Field ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Lookup Field ID';
        }
    }
    keys
    {
        key(K0; "Case ID", "Table Filter ID", "Field ID")
        {
            Clustered = True;
        }
    }
    local procedure ValidateValue();
    var
        FieldDatatype: Enum "Symbol Data Type";
        OptionString: Text;
        OptionIndex: Integer;
    begin
        if "Value Type" = "Value Type"::Constant then begin
            TestField("Table ID");
            TestField("Field ID");
            FieldDatatype := ScriptDataTypeMgmt.GetFieldDatatype("Table ID", "Field ID");
            if FieldDatatype = "Symbol Data Type"::OPTION then begin
                OptionString := ScriptDataTypeMgmt.GetFieldOptionString("Table ID", "Field ID");
                if TypeHelper.IsNumeric(Value) then
                    Value := ScriptDataTypeMgmt.GetOptionText(OptionString, ScriptDataTypeMgmt.Text2Number(Value))
                else begin
                    OptionIndex := TypeHelper.GetOptionNo(UPPERCASE(Value), UPPERCASE(OptionString));
                    if OptionIndex <> -1 then
                        Value := ScriptDataTypeMgmt.GetOptionText(OptionString, OptionIndex);
                end;
            end else
                AppObjectHelper.SearchTableFieldOfType("Lookup Table ID", "Lookup Field ID", Value, FieldDatatype);
        end;
    end;

    var
        AppObjectHelper: Codeunit "App Object Helper";
        ScriptDataTypeMgmt: Codeunit "Script Data Type Mgmt.";
        TypeHelper: Codeunit "Type Helper";
}