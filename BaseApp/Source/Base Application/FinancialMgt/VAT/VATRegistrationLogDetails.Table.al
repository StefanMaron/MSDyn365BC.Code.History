table 227 "VAT Registration Log Details"
{
    Caption = 'VAT Registration Log Details';

    fields
    {
        field(1; "Log Entry No."; Integer)
        {
            Caption = 'Log Entry No.';
            TableRelation = "VAT Registration Log";
        }
        field(2; "Field Name"; Enum "VAT Reg. Log Details Field")
        {
            Caption = 'Field Name';
        }
        field(10; "Account Type"; Enum "VAT Registration Log Account Type")
        {
            Caption = 'Account Type';
        }
        field(11; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(20; "Requested"; Text[150])
        {
            Caption = 'Requested';
        }
        field(21; "Response"; Text[150])
        {
            Caption = 'Response';
        }
        field(22; "Current Value"; Text[150])
        {
            Caption = 'Current Value';
        }
        field(23; Status; Enum "VAT Reg. Log Details Field Status")
        {
            Caption = 'Status';
        }
    }

    keys
    {
        key(PK; "Log Entry No.", "Field Name")
        {
            Clustered = true;
        }
    }
}
