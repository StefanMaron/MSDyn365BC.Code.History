table 2113 "O365 Cust. Invoice Discount"
{
    Caption = 'O365 Cust. Invoice Discount';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Minimum Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
            MinValue = 0;
        }
        field(6; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Minimum Amount", "Discount %")
        {
        }
    }
}

