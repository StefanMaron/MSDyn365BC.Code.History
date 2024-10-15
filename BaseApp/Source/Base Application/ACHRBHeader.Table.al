table 10303 "ACH RB Header"
{
    Caption = 'ACH RB Header';

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Client Number"; Text[30])
        {
            Caption = 'Client Number';
        }
        field(3; "File Creation Date"; Integer)
        {
            Caption = 'File Creation Date';
            Description = 'File Creation Date';
        }
        field(4; "Record Type"; Text[10])
        {
            Caption = 'Record Type';
        }
        field(5; "Transaction Code"; Text[10])
        {
            Caption = 'Transaction Code';
        }
        field(6; "Client Name"; Text[30])
        {
            Caption = 'Client Name';
        }
        field(7; "File Creation Number"; Integer)
        {
            Caption = 'File Creation Number';
        }
        field(8; "Currency Type"; Text[30])
        {
            Caption = 'Currency Type';
        }
        field(9; "Record Count"; Integer)
        {
            Caption = 'Record Count';
        }
        field(10; "Input Type"; Text[10])
        {
            Caption = 'Input Type';
        }
        field(11; "Federal ID No."; Text[30])
        {
            Caption = 'Federal ID No.';
        }
        field(12; "Input Qualifier"; Code[30])
        {
            Caption = 'Input Qualifier';
        }
    }

    keys
    {
        key(Key1; "Data Exch. Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

