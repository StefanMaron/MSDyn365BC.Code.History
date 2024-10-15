table 32000003 "Foreign Payment Types"
{
    Caption = 'Foreign Payment Types';
    LookupPageID = "Payment Method Codes";

    fields
    {
        field(1; "Code"; Code[1])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Code Type"; Option)
        {
            Caption = 'Code Type';
            OptionCaption = 'Payment Method,Service Fee';
            OptionMembers = "Payment Method","Service Fee";
        }
        field(3; Description; Text[35])
        {
            Caption = 'Description';
        }
        field(4; Banks; Text[100])
        {
            Caption = 'Banks';
        }
    }

    keys
    {
        key(Key1; "Code", "Code Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

