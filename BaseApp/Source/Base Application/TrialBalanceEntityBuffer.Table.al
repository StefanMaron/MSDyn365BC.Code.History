table 5488 "Trial Balance Entity Buffer"
{
    Caption = 'Trial Balance Entity Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(3; "Net Change Debit"; Text[30])
        {
            Caption = 'Net Change Debit';
            DataClassification = SystemMetadata;
        }
        field(4; "Net Change Credit"; Text[30])
        {
            Caption = 'Net Change Credit';
            DataClassification = SystemMetadata;
        }
        field(5; "Balance at Date Debit"; Text[30])
        {
            Caption = 'Balance at Date Debit';
            DataClassification = SystemMetadata;
        }
        field(6; "Balance at Date Credit"; Text[30])
        {
            Caption = 'Balance at Date Credit';
            DataClassification = SystemMetadata;
        }
        field(7; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        field(8; "Total Debit"; Text[30])
        {
            Caption = 'Total Debit';
            DataClassification = SystemMetadata;
        }
        field(9; "Total Credit"; Text[30])
        {
            Caption = 'Total Credit';
            DataClassification = SystemMetadata;
        }
        field(10; "Account Type"; Option)
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Posting,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Posting,Heading,Total,"Begin-Total","End-Total";
        }
        field(11; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account".Id;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

