table 2105 "O365 Payment History Buffer"
{
    Caption = 'O365 Payment History Buffer';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ledger Entry No."; Integer)
        {
            Caption = 'Ledger Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Entry";
        }
        field(2; Type; Enum "Gen. Journal Document Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            AutoFormatExpression = '1';
            AutoFormatType = 10;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Date Received"; Date)
        {
            Caption = 'Date Received';
            DataClassification = SystemMetadata;
        }
        field(5; "Payment Method"; Code[10])
        {
            Caption = 'Payment Method';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Ledger Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Date Received", Type, Amount, "Payment Method")
        {
        }
    }
}

