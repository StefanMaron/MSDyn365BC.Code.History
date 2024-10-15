table 18317 "Detailed Cr. Adjstmnt. Entry"
{
    Caption = 'Detailed Cr. Adjstmnt. Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Credit Adjustment Type"; Enum "Credit Adjustment Type")
        {
            Caption = 'Credit Adjustment Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Adjusted Doc. Entry No."; Integer)
        {
            Caption = 'Adjusted Doc. Entry No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Detailed GST Ledger Entry";
        }
        field(6; "Adjusted Doc. Entry Type"; Enum "Entry Type")
        {
            Caption = 'Adjusted Doc. Entry Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Adjusted Doc. Transaction Type"; Enum "Detail Ledger Transaction Type")
        {
            Caption = 'Adjusted Doc. Transaction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Adjusted Doc. Type"; Enum "GST Document Type")
        {
            Caption = 'Adjusted Doc. Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Adjusted Doc. No."; Code[20])
        {
            Caption = 'Adjusted Doc. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Adjusted Doc. Line No."; Integer)
        {
            Caption = 'Adjusted Doc. Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "Adjusted Doc. Posting Date"; Date)
        {
            Caption = 'Adjusted Doc. Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; Type; Enum Type)
        {
            Caption = 'Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge";
        }
        field(14; "Product Type"; Enum "Product Type")
        {
            Caption = 'Product Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Source Type"; Enum "Adjustment Entry Source Type")
        {
            Caption = 'Source Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor;
        }
        field(17; "HSN/SAC Code"; Code[8])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "HSN/SAC".Code where("GST Group Code" = FIELD("GST Group Code"));
        }
        field(18; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Component";
        }
        field(19; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Group";
        }
        field(20; "GST Jurisdiction Type"; Enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(21; "GST Base Amount"; Decimal)
        {
            Caption = 'GST Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "GST %"; Decimal)
        {
            Caption = 'GST %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "GST Amount"; Decimal)
        {
            Caption = 'GST Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Adjustment %"; Decimal)
        {
            Caption = 'Adjustment %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "Adjustment Amount"; Decimal)
        {
            Caption = 'Adjustment Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "G/L Account";
        }
        field(28; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Location State Code"; Code[10])
        {
            Caption = 'Location State Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "Buyer/Seller State Code"; Code[10])
        {
            Caption = 'Buyer/Seller State Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = State;
        }
        field(32; "Location  Reg. No."; Code[15])
        {
            Caption = 'Location  Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; "Buyer/Seller Reg. No."; Code[15])
        {
            Caption = 'Buyer/Seller Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(34; "GST Group Type"; Enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "GST Credit"; Enum "Adjustment Entry GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(36; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(37; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DataClassification = EndUserIdentifiableInformation;
            DecimalPlaces = 1 : 6;
        }
        field(38; "GST Rounding Precision"; Decimal)
        {
            Caption = 'GST Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(39; "GST Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(40; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(41; "GST Vendor Type"; Enum "GST Vendor Type")
        {
            Caption = 'GST Vendor Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(42; "Credit Availed"; Boolean)
        {
            Caption = 'Credit Availed';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(43; Paid; Boolean)
        {
            Caption = 'Paid';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(44; Cess; Boolean)
        {
            Caption = 'Cess';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(45; "Input Service Distribution"; Boolean)
        {
            Caption = 'Input Service Distribution';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(46; "Liable to Pay"; Boolean)
        {
            Caption = 'Liable to Pay';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(47; "Payment Document No."; Code[20])
        {
            Caption = 'Payment Document No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(48; "Payment Document Date"; Date)
        {
            Caption = 'Payment Document Date';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(50; "Reverse Charge"; Boolean)
        {
            Caption = 'Reverse Charge';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(51; "Rem. Amt. Updated in DGLE"; Boolean)
        {
            Caption = 'Rem. Amt. Updated in DGLE';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Posting Date")
        {
        }
        key(Key3; "Location  Reg. No.", "GST Component Code", Paid, "Posting Date")
        {
        }
    }
}

