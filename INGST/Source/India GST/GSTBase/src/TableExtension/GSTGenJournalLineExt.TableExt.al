tableextension 18004 "GST Gen. Journal Line Ext" extends "Gen. Journal Line"
{
    fields
    {
        field(18000; "Nature of Supply"; Enum "GST Nature of Supply")
        {
            Caption = 'Nature of Supply';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18001; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            TableRelation = "GST Group";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18002; "GST Group Type"; Enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18004; "Exclude GST in TCS Base"; Boolean)
        {
            Caption = 'Exclude GST in TCS Base';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18006; "GST Place of Supply"; enum "GST Place Of Supply")
        {
            Caption = 'GST Place of Supply';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18007; "GST Customer Type"; enum "GST Customer Type")
        {
            Caption = 'GST Customer Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18008; "GST Vendor Type"; enum "GST Vendor Type")
        {
            Caption = 'GST Vendor Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18009; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "HSN/SAC".Code WHERE("GST Group Code" = FIELD("GST Group Code"));
        }
        field(18010; Exempted; Boolean)
        {
            Caption = 'Exempted';
            DataClassification = EndUserIdentifiableInformation;
        }
        //need to check this field neede or not
        field(18011; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18012; "GST on Advance Payment"; Boolean)
        {
            Caption = 'GST on Advance Payment';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18013; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF ("Account Type" = CONST(Customer)) "Ship-to Address".Code WHERE("Customer No." = FIELD("Account No."));
        }
        field(18014; "Tax Type"; enum "Tax Type")
        {
            Caption = 'Tax Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18015; "GST Jurisdiction Type"; enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18016; "Adv. Pmt. Adjustment"; Boolean)
        {
            Caption = 'Adv. Pmt. Adjustment';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18017; "GST Bill-to/BuyFrom State Code"; Code[10])
        {
            Caption = 'GST Bill-to/BuyFrom State Code';
            Editable = false;
            TableRelation = State;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18018; "GST Ship-to State Code"; Code[10])
        {
            Caption = 'GST Ship-to State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = State;
        }
        field(18019; "Location State Code"; Code[10])
        {
            Caption = 'Location State Code';
            Editable = false;
            TableRelation = State;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18020; "GST Inv. Rounding Precision"; Decimal)
        {
            Caption = 'GST Inv. Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;

            trigger OnValidate()
            begin
                IF ("GST Customer Type" = "GST Customer Type"::" ") AND
                    ("GST Vendor Type" = "GST Vendor Type"::" ")
                THEN
                    TESTFIELD("GST Inv. Rounding Precision", 0);
            end;
        }
        field(18021; "GST Inv. Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Inv. Rounding Type';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                IF ("GST Customer Type" = "GST Customer Type"::" ") AND
                    ("GST Vendor Type" = "GST Vendor Type"::" ")
                THEN
                    TESTFIELD("GST Inv. Rounding Type", "GST Inv. Rounding Type"::Nearest);
            end;
        }
        field(18022; "GST Input Service Distribution"; Boolean)
        {
            Caption = 'GST Input Service Distribution';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18023; "GST Reverse Charge"; Boolean)
        {
            Caption = 'GST Reverse Charge';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18024; "GST Reason Type"; enum "GST Reason Type")
        {
            Caption = 'GST Reason Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18025; "Bank Charge"; Boolean)
        {
            Caption = 'Bank Charge';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18027; "RCM Exempt"; Boolean)
        {
            Caption = 'RCM Exempt';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18028; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF ("Account Type" = CONST(Vendor)) "Order Address".Code WHERE("Vendor No." = FIELD("Account No."));
        }
        field(18029; "Vendor GST Reg. No."; Code[20])
        {
            Caption = 'Vendor GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18030; "Associated Enterprises"; Boolean)
        {
            Caption = 'Associated Enterprises';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18031; "Purch. Invoice Type"; enum "GST Invoice Type")
        {
            Caption = 'Purch. Invoice Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18032; "Inc. GST in TDS Base"; Boolean)
        {
            Caption = 'Inc. GST in TDS Base';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18033; "GST Credit"; enum "GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18034; "GST Without Payment of Duty"; Boolean)
        {
            Caption = 'GST Without Payment of Duty';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18035; "Sales Invoice Type"; enum "Sales Invoice Type")
        {
            Caption = 'Sales Invoice Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18036; "Bill Of Export No."; Text[20])
        {
            Caption = 'Bill Of Export No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18037; "Bill Of Export Date"; Date)
        {
            Caption = 'Bill Of Export Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18040; "Custom Duty Amount"; Decimal)
        {
            Caption = 'Custom Duty Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18041; "GST Assessable Value"; Decimal)
        {
            Caption = 'GST Assessable Value';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18042; "GST in Journal"; Boolean)
        {
            Caption = 'GST in Journal';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18043; "GST Transaction Type"; enum "GST Transaction Type")
        {
            Caption = 'GST Transaction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18044; "Journal Entry"; Boolean)
        {
            Caption = 'Journal Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18045; "Custom Duty Amount (LCY)"; Decimal)
        {
            Caption = 'Custom Duty Amount (LCY)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18046; "Bill of Entry No."; Text[20])
        {
            Caption = 'Bill of Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18047; "Bill of Entry Date"; Date)
        {
            Caption = 'Bill of Entry Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18048; "GST in Journal Allocations"; Boolean)
        {
            Caption = 'GST in Journal Allocations';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18049; "Allocation Line No."; Integer)
        {
            Caption = 'Allocation Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18050; "Journal Line No."; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Journal Line No.';
        }
        field(18051; "Journal Alloc. Template Name"; Code[10])
        {
            Caption = 'Journal Alloc. Template Name';
            TableRelation = "Gen. Journal Template";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18053; "GST Adjustment Entry"; Boolean)
        {
            Caption = 'GST Adjustment Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18054; "Location GST Reg. No."; Code[20])
        {
            Caption = 'Location GST Reg. No.';
            TableRelation = "GST Registration Nos.";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18055; "Customer GST Reg. No."; Code[20])
        {
            Caption = 'Customer GST Reg. No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18056; "Ship-to GST Reg. No."; Code[20])
        {
            Caption = 'Ship-to GST Reg. No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18057; "Order Address GST Reg. No."; Code[20])
        {
            Caption = 'Order Address GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18058; "Order Address State Code"; Code[10])
        {
            Caption = 'Order Address State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18059; "Bill to-Location(POS)"; Code[10])
        {
            Caption = 'Bill to-Location(POS)';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(FALSE));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18060; "Reference Invoice No."; Code[20])
        {
            Caption = 'Reference Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18061; "Without Bill Of Entry"; Boolean)
        {
            Caption = 'Without Bill Of Entry';
            DataClassification = EndUserIdentifiableInformation;


            trigger OnValidate()
            begin
                TESTFIELD("GST Vendor Type", "GST Vendor Type"::SEZ);
            end;
        }
        field(18062; "Amount Excl. GST"; Decimal)
        {
            Caption = 'Amount Excl. GST';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18063; "GST TDS"; Boolean)
        {
            Caption = 'GST TDS';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18064; "GST TDS/TCS %"; Decimal)
        {
            Caption = 'GST TDS/TCS %';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18065; "GST TDS/TCS Base Amount (LCY)"; Decimal)
        {
            Caption = 'GST TDS/TCS Base Amount (LCY)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18066; "GST TDS/TCS Amount (LCY)"; Decimal)
        {
            Caption = 'GST TDS/TCS Amount (LCY)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18067; "GST TCS"; Boolean)
        {
            Caption = 'GST TCS';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18068; "GST TCS State Code"; Code[10])
        {
            Caption = 'GST TCS State Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = State;

            trigger OnValidate()
            begin
                TESTFIELD("GST TCS", FALSE);
            end;
        }
        field(18069; "GST TDS/TCS Base Amount"; Decimal)
        {
            Caption = 'GST TDS/TCS Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18070; "Supply Finish Date"; Enum "GST Rate Change")
        {
            Caption = 'Supply Finish Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18071; "Payment Date"; Enum "GST Rate Change")
        {
            Caption = 'Payment Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18072; "Rate Change Applicable"; Boolean)
        {
            Caption = 'Rate Change Applicable';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                IF NOT ("Account Type" IN ["Account Type"::Customer, "Account Type"::Vendor]) THEN
                    TESTFIELD("Rate Change Applicable", FALSE);
            end;
        }
        field(18073; "POS as Vendor State"; Boolean)
        {
            Caption = 'POS as Vendor State';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18075; "GST On Assessable Value"; Boolean)
        {
            Caption = 'GST On Assessable Value';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18076; "GST Assessable Value Sale(LCY)"; Decimal)
        {
            Caption = 'GST Assessable Value Sale(LCY)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18079; "POS Out Of India"; Boolean)
        {
            Caption = 'POS Out Of India';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18003; "Transaction Type"; Enum "GenJnl Transaction Type")
        {
            Caption = 'Transaction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18005; "Offline Application"; Boolean)
        {
            Caption = 'Offline Application';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18026; "e-Commerce Customer"; Code[20])
        {
            Caption = 'e-Commerce Customer';
            TableRelation = Customer where("e-Commerce Operator" = const(true));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18038; "e-Commerce Merchant Id"; Code[30])
        {
            Caption = 'e-Commerce Merchant Id';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "E-Commerce Merchant"."Merchant Id"
                where(
                    "Merchant Id" = field("e-Commerce Merchant Id"),
                    "Customer No." = field("e-Commerce Customer"));
        }
    }
}