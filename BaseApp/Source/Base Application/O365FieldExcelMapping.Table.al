table 2112 "O365 Field Excel Mapping"
{
    Caption = 'O365 Field Excel Mapping';
    ReplicateData = false;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(2; "Table Name"; Text[30])
        {
            CalcFormula = Lookup ("Table Metadata".Name WHERE(ID = FIELD("Table ID")));
            Caption = 'Table Name';
            FieldClass = FlowField;
        }
        field(3; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table ID"));
        }
        field(4; "Field Name"; Text[30])
        {
            CalcFormula = Lookup (Field.FieldName WHERE(TableNo = FIELD("Table ID"),
                                                        "No." = FIELD("Field ID")));
            Caption = 'Field Name';
            FieldClass = FlowField;
        }
        field(5; "Excel Column Name"; Text[30])
        {
            Caption = 'Excel Column Name';
        }
        field(6; "Excel Column No."; Integer)
        {
            Caption = 'Excel Column No.';

            trigger OnValidate()
            begin
                if "Excel Column No." <> 0 then
                    ValidateMappingDuplicates;
            end;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure ValidateMappingDuplicates()
    var
        SavedO365FieldExcelMapping: Record "O365 Field Excel Mapping";
    begin
        SavedO365FieldExcelMapping := Rec;

        if FindDuplicatedMapping then
            ClearExcelColumnNo;

        Reset;
        Rec := SavedO365FieldExcelMapping;
    end;

    local procedure FindDuplicatedMapping(): Boolean
    begin
        SetRange("Table ID", "Table ID");
        SetRange("Excel Column No.", "Excel Column No.");
        SetFilter("Field ID", '<>%1', "Field ID");
        exit(FindFirst);
    end;

    local procedure ClearExcelColumnNo()
    begin
        "Excel Column No." := 0;
        Modify;
    end;
}

