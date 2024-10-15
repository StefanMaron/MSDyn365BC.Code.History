table 2155 "O365 Payment Instructions"
{
    Caption = 'O365 Payment Instructions';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(5; Name; Text[20])
        {
            Caption = 'Name';
        }
        field(6; "Payment Instructions"; Text[250])
        {
            Caption = 'Payment Instruction';
        }
        field(7; "Payment Instructions Blob"; BLOB)
        {
            Caption = 'Payment Instructions Blob';
        }
        field(8; Default; Boolean)
        {
            Caption = 'Default';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
