table 18206 "ISD Ledger"
{
    Caption = 'ISD Ledger';

    fields
    {
        field(1; "GST Reg. No."; Code[20])
        {
            Caption = 'GST Reg. No.';
            TableRelation = "GST Registration Nos.";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Period Month"; Integer)
        {
            Caption = 'Period Month';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Period Year"; Integer)
        {
            Caption = 'Period Year';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Opening Balance"; Decimal)
        {
            Caption = 'Opening Balance';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "ITC Received"; Decimal)
        {
            Caption = 'ITC Received';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "ITC Reversal"; Decimal)
        {
            Caption = 'ITC Reversal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Distributed as Component 1"; Decimal)
        {
            Caption = 'Distributed as Component 1';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Distributed as Component 2"; Decimal)
        {
            Caption = 'Distributed as Component 2';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Distributed as Component 3"; Decimal)
        {
            Caption = 'Distributed as Component 3';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "Distributed as Component 4"; Decimal)
        {
            Caption = 'Distributed as Component 4';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Distributed as Component 5"; Decimal)
        {
            Caption = 'Distributed as Component 5';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Distributed as Component 6"; Decimal)
        {
            Caption = 'Distributed as Component 6';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Distributed as Component 7"; Decimal)
        {
            Caption = 'Distributed as Component 7';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Distributed as Component 8"; Decimal)
        {
            Caption = 'Distributed as Component 8';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "Closing Balance"; Decimal)
        {
            Caption = 'Closing Balance';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "GST Reg. No.", "Period Month", "Period Year", "GST Component Code")
        {
            Clustered = true;
        }
        key(Key2; "GST Reg. No.", "GST Component Code", "Period Year", "Period Month")
        {
        }
    }
}
