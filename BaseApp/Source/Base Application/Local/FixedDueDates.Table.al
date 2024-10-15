table 12172 "Fixed Due Dates"
{
    Caption = 'Fixed Due Dates';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Company,Customer,Vendor';
            OptionMembers = Company,Customer,Vendor;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = IF (Type = CONST(Customer)) Customer
            ELSE
            IF (Type = CONST(Vendor)) Vendor;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Payment Days"; Integer)
        {
            Caption = 'Payment Days';
            MaxValue = 31;
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

