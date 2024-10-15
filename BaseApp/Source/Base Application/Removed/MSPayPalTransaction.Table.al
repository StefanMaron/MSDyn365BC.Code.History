table 7862 "MS- PayPal Transaction"
{
    Caption = 'MS- PayPal Transaction';
    ObsoleteReason = 'This table is no longer used by any user.';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account ID"; Code[127])
        {
            Caption = 'Account ID';
        }
        field(2; "Transaction ID"; Text[19])
        {
            Caption = 'Transaction ID';
        }
        field(3; "Transaction Status"; Code[10])
        {
            Caption = 'Transaction Status';
        }
        field(4; "Transaction Date"; DateTime)
        {
            Caption = 'Transaction Date';
        }
        field(6; "Transaction Type"; Code[28])
        {
            Caption = 'Transaction Type';
        }
        field(7; "Currency Code"; Code[3])
        {
            Caption = 'Currency Code';
        }
        field(8; "Gross Amount"; Decimal)
        {
            Caption = 'Gross Amount';
        }
        field(9; "Net Amount"; Decimal)
        {
            Caption = 'Net Amount';
        }
        field(10; "Fee Amount"; Decimal)
        {
            Caption = 'Fee Amount';
        }
        field(11; "Payer E-mail"; Text[127])
        {
            Caption = 'Payer E-mail';
        }
        field(12; "Payer Name"; Text[127])
        {
            Caption = 'Payer Name';
        }
        field(13; "Payer Address"; Text[100])
        {
            Caption = 'Payer Address';
        }
        field(14; Note; Text[250])
        {
            Caption = 'Note';
        }
        field(15; Custom; Text[250])
        {
            Caption = 'Custom';
        }
        field(16; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
        }
        field(101; "Response Date"; DateTime)
        {
            Caption = 'Response Date';
        }
        field(200; Details; BLOB)
        {
            Caption = 'Details';
        }
    }

    keys
    {
        key(Key1; "Account ID", "Transaction ID")
        {
            Clustered = true;
        }
        key(Key2; "Transaction Date")
        {
        }
        key(Key3; "Currency Code")
        {
        }
    }

    fieldgroups
    {
    }
}

