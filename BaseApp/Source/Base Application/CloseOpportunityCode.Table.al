table 5094 "Close Opportunity Code"
{
    Caption = 'Close Opportunity Code';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Close Opportunity Codes";

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
        field(3; "No. of Opportunities"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE("Close Opportunity Code" = FIELD(Code)));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Won,Lost';
            OptionMembers = Won,Lost;
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
        fieldgroup(DropDown; "Code", Description, Type)
        {
        }
    }
}

