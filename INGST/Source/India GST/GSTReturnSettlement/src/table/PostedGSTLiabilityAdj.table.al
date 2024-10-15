table 18321 "Posted GST Liability Adj."
{
    Caption = 'Posted GST Liability Adj.';
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "USER ID"; Code[50])
        {
            Caption = 'USER ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Adjustment Amount"; Decimal)
        {
            Caption = 'Adjustment Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Adjusted Doc. Entry No."; Integer)
        {
            Caption = 'Adjusted Doc. Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Adjusted Doc. Entry Type"; Enum "Entry Type")
        {
            Caption = 'Adjusted Doc. Entry Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Transaction Type"; Enum "Detail Ledger Transaction Type")
        {
            Caption = 'Transaction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Document Type"; Enum "GST Document Type")
        {
            Caption = 'Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Adjusted Doc. Posting Date"; Date)
        {
            Caption = 'Adjusted Doc. Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; Type; Enum Type)
        {
            Caption = 'Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "No."; Code[20])
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
        field(13; "Product Type"; Enum "Product Type")
        {
            Caption = 'Product Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Source Type"; Enum "Adjustment Entry Source Type")
        {
            Caption = 'Source Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor;
        }
        field(16; "HSN/SAC Code"; Code[8])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "HSN/SAC".Code where("GST Group Code" = FIELD("GST Group Code"));
        }
        field(17; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Component";
        }
        field(18; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Group";
        }
        field(19; "GST Jurisdiction Type"; Enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "GST Base Amount"; Decimal)
        {
            Caption = 'GST Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(21; "GST %"; Decimal)
        {
            Caption = 'GST %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "GST Amount"; Decimal)
        {
            Caption = 'GST Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            TableRelation = "G/L Account";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Location  Reg. No."; Code[15])
        {
            Caption = 'Location  Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "Buyer/Seller Reg. No."; Code[15])
        {
            Caption = 'Buyer/Seller Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; "GST Group Type"; Enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "GST Credit"; Enum "Adjustment Entry GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "GST Rounding Precision"; Decimal)
        {
            Caption = 'GST Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "GST Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "GST Vendor Type"; Enum "GST Vendor Type")
        {
            Caption = 'GST Vendor Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; Cess; Boolean)
        {
            Caption = 'Cess';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(34; "Input Service Distribution"; Boolean)
        {
            Caption = 'Input Service Distribution';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "Credit Availed"; Boolean)
        {
            Caption = 'Credit Availed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(36; "Liable to Pay"; Boolean)
        {
            Caption = 'Liable to Pay';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(37; "Credit Adjustment Type"; Enum "Cr Libty Adjustment Type")
        {
            Caption = 'Credit Adjustment Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(38; Paid; Boolean)
        {
            Caption = 'Paid';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(39; "Payment Document No."; Code[20])
        {
            Caption = 'Payment Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(40; "Payment Document Date"; Date)
        {
            Caption = 'Payment Document Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(41; "Adjustment Document No."; Code[20])
        {
            Caption = 'Adjustment Document No.';
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
