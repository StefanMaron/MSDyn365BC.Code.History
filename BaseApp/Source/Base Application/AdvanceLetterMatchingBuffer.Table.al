table 31035 "Advance Letter Matching Buffer"
{
    Caption = 'Advance Letter Matching Buffer';
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
        }
        field(2; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Customer,Vendor';
            OptionMembers = Customer,Vendor;
        }
        field(6; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = SystemMetadata;
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(15; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
        }
        field(20; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(25; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
        field(26; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
        field(27; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Letter Type", "Letter No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

