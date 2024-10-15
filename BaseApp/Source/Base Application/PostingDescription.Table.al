table 11785 "Posting Description"
{
    Caption = 'Posting Description';
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of posting description will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Sales Document,Purchase Document,Post Inventory Cost,Finance Charge,Service Document';
            OptionMembers = "Sales Document","Purchase Document","Post Inventory Cost","Finance Charge","Service Document";
        }
        field(4; "Posting Description Formula"; Text[50])
        {
            Caption = 'Posting Description Formula';
        }
        field(5; "Validate on Posting"; Boolean)
        {
            Caption = 'Validate on Posting';
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

}

