table 18245 "GST TDS/TCS Entry"
{
    Caption = 'GST TDS/TCS Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Location GST Reg. No."; Code[15])
        {
            Caption = 'Location GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Location State Code"; Code[10])
        {
            Caption = 'Location State Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Buyer/Seller Reg. No."; Code[20])
        {
            Caption = 'Buyer/Seller Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Buyer/Seller State Code"; Code[10])
        {
            Caption = 'Buyer/Seller State Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = State;
        }
        field(7; "Place of Supply"; Enum "GST Place Of Supply")
        {
            Caption = 'Place of Supply';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Source No."; Code[20])
        {
            Caption = 'Source No.';

            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor;
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Document Type"; Enum "TDSTCS Document Type")
        {
            Caption = 'Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "GST TDS/TCS Base Amount (LCY)"; Decimal)
        {
            Caption = 'GST TDS/TCS Base Amount (LCY)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "GST TDS/TCS Amount (LCY)"; Decimal)
        {
            Caption = 'GST TDS/TCS Amount (LCY)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "GST TDS/TCS %"; Decimal)
        {
            Caption = 'GST TDS/TCS %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "GST Jurisdiction"; Enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "Certificate Received"; Boolean)
        {
            Caption = 'Certificate Received';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Certificated Received Date"; Date)
        {
            Caption = 'Certificated Received Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Certificate No."; Text[100])
        {
            Caption = 'Certificate No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "Payment Document Date"; Date)
        {
            Caption = 'Payment Document Date';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(21; "Payment Document No."; Code[20])
        {
            Caption = 'Payment Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; Paid; Boolean)
        {
            Caption = 'Paid';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; Reversed; Boolean)
        {
            Caption = 'Reversed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; Type; Enum "TDSTCS Type")
        {
            Caption = 'Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "Location ARN No."; Code[20])
        {
            Caption = 'Location ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "Source Type"; Enum "Source Type")
        {
            Caption = 'Source Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "Credit Availed"; Boolean)
        {
            Caption = 'Credit Availed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; "Liable to Pay"; Boolean)
        {
            Caption = 'Liable to Pay';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}

