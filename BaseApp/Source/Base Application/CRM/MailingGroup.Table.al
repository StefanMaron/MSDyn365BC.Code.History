table 5055 "Mailing Group"
{
    Caption = 'Mailing Group';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Mailing Groups";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "No. of Contacts"; Integer)
        {
            CalcFormula = Count ("Contact Mailing Group" WHERE("Mailing Group Code" = FIELD(Code)));
            Caption = 'No. of Contacts';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CalcFields("No. of Contacts");
        TestField("No. of Contacts", 0);
    end;
}

