table 9805 "Table Filter"
{
    Caption = 'Table Filter';

    fields
    {
        field(1; "Table Number"; Integer)
        {
            Caption = 'Table Number';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Table Name"; Text[30])
        {
            Caption = 'Table Name';
        }
        field(5; "Field Number"; Integer)
        {
            Caption = 'Field Number';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table Number"));

            trigger OnValidate()
            var
                "Field": Record "Field";
                TypeHelper: Codeunit "Type Helper";
            begin
                if xRec."Field Number" = "Field Number" then
                    exit;

                Field.Get("Table Number", "Field Number");
                TypeHelper.TestFieldIsNotObsolete(Field);
                CheckDuplicateField(Field);

                "Field Caption" := Field."Field Caption";
                "Field Filter" := '';
            end;
        }
        field(6; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
        field(7; "Field Caption"; Text[80])
        {
            Caption = 'Field Caption';
        }
        field(8; "Field Filter"; Text[250])
        {
            Caption = 'Field Filter';
        }
    }

    keys
    {
        key(Key1; "Table Number", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'The filter for the field %1 %2 already exists.', Comment = 'The filter for the field <Field Number> <Field Name> already exists. Example: The filter for the field 15 Base Unit of Measure already exists.';

    procedure CheckDuplicateField("Field": Record "Field")
    var
        TableFilter: Record "Table Filter";
    begin
        TableFilter.Copy(Rec);
        Reset();
        SetRange("Table Number", Field.TableNo);
        SetRange("Field Number", Field."No.");
        SetFilter("Line No.", '<>%1', "Line No.");
        if not IsEmpty() then
            Error(Text001, Field."No.", Field."Field Caption");
        Copy(TableFilter);
    end;
}

