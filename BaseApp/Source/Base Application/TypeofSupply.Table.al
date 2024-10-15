table 10500 "Type of Supply"
{
    Caption = 'Type of Supply';
    LookupPageID = "Postcode Search";
    ObsoleteReason = 'Removed based on feedback.';
    ObsoleteState = Pending;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            ObsoleteReason = 'Removed based on feedback.';
            ObsoleteState = Pending;
        }
        field(10; Description; Text[30])
        {
            Caption = 'Description';
            ObsoleteReason = 'Removed based on feedback.';
            ObsoleteState = Pending;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
            ObsoleteReason = 'Removed based on feedback.';
            ObsoleteState = Pending;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }
}

