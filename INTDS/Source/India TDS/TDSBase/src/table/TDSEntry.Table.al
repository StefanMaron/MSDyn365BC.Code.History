table 18689 "TDS Entry"
{
    Caption = 'TDS Entry';
    DataClassification = EndUserIdentifiableInformation;
    LookupPageId = "TDS Entries";
    DrillDownPageId = "TDS Entries";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
            AutoIncrement = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "T.A.N. No."; Code[10])
        {
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Section"; Code[10])
        {
            Caption = 'Section';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Assessee Code"; Code[10])
        {
            Caption = 'Assessee Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "TDS Category"; Code[10])
        {
            Caption = 'TDS Category';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "TDS Certificate No."; Code[20])
        {
            Caption = 'TDS Certificate No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "TDS Base Amount"; Decimal)
        {
            Caption = 'TDS Base Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "TDS Paid"; Boolean)
        {
            Caption = 'TDS Paid';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "TDS %"; Decimal)
        {
            Caption = 'TDS %';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "TDS Amount"; Decimal)
        {
            Caption = 'TDS Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Surcharge %"; Decimal)
        {
            Caption = 'Surcharge %';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Surcharge Amount"; Decimal)
        {
            Caption = 'Surcharge Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "eCess %"; Decimal)
        {
            Caption = 'eCess %';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "eCess Amount"; Decimal)
        {
            Caption = 'eCess Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "SHE Cess %"; Decimal)
        {
            Caption = 'SHE Cess %';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "SHE Cess Amount"; Decimal)
        {
            Caption = 'SHE Cess Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Concessional Code"; Code[10])
        {
            Caption = 'Concessional Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Concessional Form No."; Code[20])
        {
            Caption = 'Concessional Form No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "Deductee PAN No."; Code[20])
        {
            Caption = 'Deductee PAN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(21; "Non Resident Payments"; Boolean)
        {
            Caption = 'Non Resident Payments';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "Nature of Remittance"; Code[20])
        {
            Caption = 'Nature of Remittance';
            Editable = false;
            TableRelation = "TDS Nature of Remittance";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "Act Applicable"; Code[10])
        {
            Caption = 'Act Applicable';
            Editable = false;
            TableRelation = "Act Applicable";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Work Tax %"; Decimal)
        {
            Caption = 'Work Tax %';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "Work Tax Amount"; Decimal)
        {
            Caption = 'Work Tax Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Work Tax Base Amount"; Decimal)
        {
            Caption = 'Work Tax Base Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "Invoice Amount"; Decimal)
        {
            Caption = 'Invoice Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; "Challan Date"; Date)
        {
            Caption = 'Challan Date';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "Challan No."; Code[20])
        {
            Caption = 'Challan No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "Work Tax Paid"; Boolean)
        {
            Caption = 'Work Tax Paid';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(34; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "Account Type"; enum "TDS Account Type")
        {
            Caption = 'Account Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(36; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor;
        }
        field(37; "Party Type"; Enum "TDS Party Type")
        {
            Caption = 'Party Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(38; "Party Code"; Code[20])
        {
            Caption = 'Party Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(39; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(40; "TDS Adjustment"; Boolean)
        {
            Caption = 'TDS Adjustment';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(41; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(42; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(43; "TDS Amount Including Surcharge"; Decimal)
        {
            Caption = 'TDS Amount Including Surcharge';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(44; "Applied To"; Code[20])
        {
            Caption = 'Applied To';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(45; Adjusted; Boolean)
        {
            Caption = 'Adjusted';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(46; "Adjusted TDS %"; Decimal)
        {
            Caption = 'Adjusted TDS %';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(47; "Bal. TDS Including SHE CESS"; Decimal)
        {
            Caption = 'Bal. TDS Including SHE CESS';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(48; "Pay TDS Document No."; Code[20])
        {
            Caption = 'Pay TDS Document No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(49; "Applies To"; Boolean)
        {
            Caption = 'Applies To';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(50; Applied; Boolean)
        {
            Caption = 'Applied';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(51; "Remaining Surcharge Amount"; Decimal)
        {
            Caption = 'Remaining Surcharge Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(52; "Remaining TDS Amount"; Decimal)
        {
            Caption = 'Remaining TDS Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(53; "Adjusted Surcharge %"; Decimal)
        {
            Caption = 'Adjusted Surcharge %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(54; "TDS Extra Base Amount"; Decimal)
        {
            Caption = 'TDS Extra Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(55; "TDS Line Amount"; Decimal)
        {
            Caption = 'TDS Line Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(56; "Total TDS Including SHE CESS"; Decimal)
        {
            Caption = 'Total TDS Including SHE CESS';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(57; "Adjusted eCESS %"; Decimal)
        {
            Caption = 'Adjusted eCESS %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(58; "Per Contract"; Boolean)
        {
            Caption = 'Per Contract';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(59; "Party Account No."; Code[20])
        {
            Caption = 'Party Account No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(60; Reversed; Boolean)
        {
            Caption = 'Reversed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(61; "Reversed by Entry No."; Integer)
        {
            Caption = 'Reversed by Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(62; "Reversed Entry No."; Integer)
        {
            Caption = 'Reversed Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(63; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(64; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(65; "Party P.A.N. No."; Code[20])
        {
            Caption = 'Party P.A.N. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(66; "Check/DD No."; Code[10])
        {
            Caption = 'Check/DD No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(67; "Check Date"; Date)
        {
            Caption = 'Check Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(68; "TDS Payment Date"; Date)
        {
            Caption = 'TDS Payment Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(69; "Challan Register Entry No."; Integer)
        {
            Caption = 'Challan Register Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(70; Duplicate; Boolean)
        {
            Caption = 'Duplicate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(71; "Adjusted SHE CESS %"; Decimal)
        {
            Caption = 'Adjusted SHE CESS %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(72; "Original TDS Base Amount"; Decimal)
        {
            Caption = 'Original TDS Base Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(73; "TDS Base Amount Adjusted"; Boolean)
        {
            Caption = 'TDS Base Amount Adjusted';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(74; "Receipt Number"; Text[8])
        {
            Caption = 'Receipt Number';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(75; "Payment Amount"; Decimal)
        {
            Caption = 'Payment Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(76; "Adjusted Work Tax %"; Decimal)
        {
            Caption = 'Adjusted Work Tax %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(77; "Original Work Tax Base Amount"; Decimal)
        {
            Caption = 'Original Work Tax Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(78; "Work Tax Base Amount Adjusted"; Boolean)
        {
            Caption = 'Work Tax Base Amount Adjusted';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(79; "Work Tax Nature Of Deduction"; Code[10])
        {
            Caption = 'Work Tax Nature Of Deduction';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(80; "Currency Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Currency;
        }
        field(81; "Currency Factor"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(82; "Work Tax Account"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax Account';
            TableRelation = "G/L Account";
        }
        field(83; "Pay Work Tax Document No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Pay Work Tax Document No.';
        }
        field(84; "Balance Work Tax Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Balance Work Tax Amount';
        }

        field(85; "Surcharge Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Surcharge Base Amount';
        }
        field(86; "Pay Work Tax"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Pay Work Tax';
        }
        field(87; "G/L Entry No."; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'G/L Entry No.';
        }
        field(88; "BSR Code"; Code[7])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(89; "Minor Head Code"; Enum "Minor Head Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(90; "NIL Challan Indicator"; Boolean)
        {
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
        key(Key2; "Account Type")
        {
        }
        key(Key3; "Posting Date", "Assessee Code", Applied, "Per Contract")
        {
            SumIndexFields = "TDS Base Amount", "TDS Amount Including Surcharge", "Surcharge Amount", "Invoice Amount", "Bal. TDS Including SHE CESS", "TDS Amount", "TDS Extra Base Amount";
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
        key(Key5; "Posting Date", "Assessee Code", Applied)
        {
            SumIndexFields = "Invoice Amount", "Payment Amount";
        }
        key(Key6; "Posting Date", "Assessee Code", "Document Type")
        {
            SumIndexFields = "TDS Base Amount", "TDS Amount Including Surcharge", "Surcharge Amount", "Invoice Amount", "Bal. TDS Including SHE CESS", "TDS Amount", "TDS Extra Base Amount";
        }
        key(Key7; "Pay TDS Document No.", "Posting Date")
        {
        }
        key(Key8; "TDS Certificate No.")
        {
        }
        key(Key9; "Transaction No.")
        {
        }
        key(Key10; "Posting Date", "Document No.")
        {
        }
        key(Key11; "Challan No.")
        {
        }
    }
    trigger OnInsert()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorEntry: Record "Detailed Vendor Ledg. Entry";
        TDSValidations: Codeunit "TDS Validations";
    begin
        VendLedgerEntry.SetRange("Transaction No.", Rec."Transaction No.");
        if VendLedgerEntry.FindFirst() then begin
            if VendLedgerEntry."Document Type" = VendLedgerEntry."Document Type"::Invoice then
                VendLedgerEntry."Total TDS Including SHE CESS" := -Rec."Total TDS Including SHE CESS"
            else
                if VendLedgerEntry."Document Type" = VendLedgerEntry."Document Type"::Payment then
                    VendLedgerEntry."Total TDS Including SHE CESS" := Rec."Total TDS Including SHE CESS";

            if VendLedgerEntry."TDS Section Code" = '' then
                VendLedgerEntry."TDS Section Code" := Rec.Section;
            VendLedgerEntry.Modify();
        end;

        if "Currency Code" <> '' then begin
            "TDS Base Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."TDS Base Amount", Rec."Currency Factor", Rec."Posting Date");
            "TDS Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."TDS Amount", Rec."Currency Factor", Rec."Posting Date");
            "Surcharge Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."Surcharge Amount", Rec."Currency Factor", Rec."Posting Date");
            "Surcharge Base Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."Surcharge Base Amount", Rec."Currency Factor", Rec."Posting Date");
            "eCESS Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."eCESS Amount", Rec."Currency Factor", Rec."Posting Date");
            "SHE Cess Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."SHE Cess Amount", Rec."Currency Factor", Rec."Posting Date");
            "TDS Amount Including Surcharge" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."TDS Amount Including Surcharge", Rec."Currency Factor", Rec."Posting Date");
            "Bal. TDS Including SHE CESS" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."Bal. TDS Including SHE CESS", Rec."Currency Factor", Rec."Posting Date");
            "Invoice Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."Invoice Amount", Rec."Currency Factor", Rec."Posting Date");
            "Remaining Surcharge Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."Remaining Surcharge Amount", Rec."Currency Factor", Rec."Posting Date");
            "Remaining TDS Amount" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."Remaining TDS Amount", Rec."Currency Factor", Rec."Posting Date");
            "Total TDS Including SHE CESS" := TDSValidations.ConvertTDSAmountToLCY(Rec."Currency Code", Rec."Total TDS Including SHE CESS", Rec."Currency Factor", Rec."Posting Date");
        end;

        if Rec."Document Type" = Rec."Document Type"::Invoice then begin
            DetailedVendorEntry.SetRange("Vendor Ledger Entry No.", VendLedgerEntry."Entry No.");
            DetailedVendorEntry.CalcSums("Amount (LCY)");
            Rec."TDS Line Amount" := abs(DetailedVendorEntry."Amount (LCY)") + Rec."Total TDS Including SHE CESS";
        end;
    end;
}