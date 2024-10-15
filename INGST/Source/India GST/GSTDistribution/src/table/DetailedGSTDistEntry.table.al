table 18200 "Detailed GST Dist. Entry"
{
    Caption = 'Detailed GST Dist. Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Detailed GST Ledger Entry No."; Integer)
        {
            Caption = 'Detailed GST Ledger Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Dist. Location Code"; Code[10])
        {
            Caption = 'Dist. Location Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Dist. Location State Code"; Code[10])
        {
            Caption = 'Dist. Location State  Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Dist. GST Regn. No."; Code[20])
        {
            Caption = 'Dist. GST Regn. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Dist. GST Credit"; Enum "GST Distribution Credit Type")
        {
            Caption = 'Dist. GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "ISD Document Type"; Enum "Adjustment Document Type")
        {
            Caption = 'ISD Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "ISD Document No."; Code[20])
        {
            Caption = 'ISD Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "ISD Posting Date"; Date)
        {
            Caption = 'ISD Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "Supplier GST Reg. No."; Code[20])
        {
            Caption = 'Supplier GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Vendor Address"; Text[100])
        {
            Caption = 'Vendor Address';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Vendor State Code"; Code[10])
        {
            Caption = 'Vendor State Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Document Type"; Enum "GST Document Type")
        {
            Caption = 'Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Vendor Document Date"; Date)
        {
            Caption = 'Vendor Document Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "GST Base Amount"; Decimal)
        {
            Caption = 'GST Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(21; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "GST %"; Decimal)
        {
            Caption = 'GST%';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "GST Amount"; Decimal)
        {
            Caption = 'GST Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Rcpt. Location Code"; Code[10])
        {
            Caption = 'Rcpt. Location Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "Rcpt. GST Reg. No."; Code[20])
        {
            Caption = 'Rcpt. GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Rcpt. Location State Code"; Code[10])
        {
            Caption = 'Rcpt. Location State Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "Rcpt. GST Credit"; Enum "GST Distribution Credit Type")
        {
            Caption = 'Rcpt. GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; "Distribution Jurisdiction"; Enum "GST Jurisdiction Type")
        {
            Caption = 'Distribution Jurisdiction';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "Location Distribution %"; Decimal)
        {
            Caption = 'Location Distribution %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Distributed Component Code"; Code[10])
        {
            Caption = 'Distributed Component Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "Rcpt. Component Code"; Code[10])
        {
            Caption = 'Rcpt. Component Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "Distribution Amount"; Decimal)
        {
            Caption = 'Distribution Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; "Pre Dist. Invoice No."; Code[20])
        {
            Caption = 'Pre Dist. Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(36; Reversal; Boolean)
        {
            Caption = 'Reversal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(37; "Reversal Date"; Date)
        {
            Caption = 'Reversal Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(38; "Original Dist. Invoice No."; Code[20])
        {
            Caption = 'Original Dist. Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(39; "Original Dist. Invoice Date"; Date)
        {
            Caption = 'Original Dist. Invoice Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(40; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(41; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "G/L Account";
        }
        field(42; "GST Rounding Precision"; Decimal)
        {
            Caption = 'GST Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(43; "GST Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(44; Cess; Boolean)
        {
            Caption = 'Cess';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(45; Paid; Boolean)
        {
            Caption = 'Paid';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(46; "Credit Availed"; Boolean)
        {
            Caption = 'Credit Availed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(47; "Payment Document No."; Code[20])
        {
            Caption = 'Payment Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(48; "Payment Document Date"; Date)
        {
            Caption = 'Payment Document Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(49; "Invoice Type"; Enum "GST Invoice Type")
        {
            Caption = 'Invoice Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(50; "Service Account No."; Code[20])
        {
            Caption = 'Service Account No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
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

