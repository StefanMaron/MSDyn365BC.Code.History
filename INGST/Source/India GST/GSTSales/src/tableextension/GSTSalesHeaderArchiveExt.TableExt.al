tableextension 18146 "GST Sales Header Archive Ext" extends "Sales Header Archive"
{
    fields
    {
        field(18141; Trading; Boolean)
        {
            Caption = 'Trading';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18142; "Nature of Supply"; Enum "GST Nature Of Supply")
        {
            Caption = 'Nature of Supply';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18143; "GST Customer Type"; Enum "GST Customer Type")
        {
            Caption = 'GST Customer Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18144; "GST Without Payment of Duty"; Boolean)
        {
            Caption = 'GST Without Payment of Duty';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18145; "Invoice Type"; Enum "Sales Invoice Type")
        {
            Caption = 'Invoice Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18146; "Bill Of Export No."; code[20])
        {
            Caption = 'Bill Of Export No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18147; "Bill Of Export Date"; date)
        {
            Caption = 'Bill Of Export Date';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18148; "E-Commerce Customer"; Code[20])
        {
            caption = 'E-Commerce Customer';
            TableRelation = Customer WHERE("e-Commerce Operator" = CONST(true));
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18149; "E-Commerce Merchant Id"; code[30])
        {
            caption = 'E-Commerce Merchant Id';
            TableRelation = "e-Commerce Merchant"."Merchant Id" WHERE("Merchant Id" = FIELD("e-Commerce Merchant Id"),
                                    "Customer No." = FIELD("e-Commerce Customer"));
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18150; "GST Bill-to State Code"; Code[10])
        {
            Caption = 'GST Bill-to State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = State;
        }
        field(18151; "GST Ship-to State Code"; Code[10])
        {
            Caption = 'GST Ship-to State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = State;
        }
        field(18152; "Location State Code"; code[10])
        {
            Caption = 'Location State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = state;
        }
        field(18153; "GST Reason Type"; enum "GST Reason Type")
        {
            Caption = 'GST Reason Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18154; "Location GST Reg. No."; Code[20])
        {
            Caption = 'Location GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Registration Nos.";
            Editable = false;
        }
        field(18155; "Customer GST Reg. No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Customer GST Reg. No.';
            Editable = false;
        }
        field(18156; "Ship-to GST Reg. No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Ship-to GST Reg. No.';
            Editable = false;
        }
        field(18157; "Distance (Km)"; Decimal)
        {
            Caption = 'Distance (Km)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18158; "Vehicle Type"; Enum "GST Vehicle Type")
        {
            Caption = 'Vehicle Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18159; "Reference Invoice No."; Code[20])
        {
            Caption = 'Reference Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18160; "E-Way Bill No."; Text[50])
        {
            Caption = 'E-Way Bill No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18161; "Supply Finish Date"; Enum "GST Rate Change")
        {
            Caption = 'Supply Finish Date';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18162; "Payment Date"; Enum "GST Rate Change")
        {
            Caption = 'Payment Date';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18163; "Rate Change Applicable"; Boolean)
        {
            Caption = 'Rate Change Applicable';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18164; "POS Out Of India"; Boolean)
        {
            Caption = 'POS Out Of India';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18165; "GST Invoice"; Boolean)
        {
            Caption = 'GST Invoice';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18166; State; Code[10])
        {
            Caption = 'State';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = State;
            Editable = false;
        }
        field(18167; "Vehicle No."; Code[20])
        {
            Caption = 'Vehicle No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }
}