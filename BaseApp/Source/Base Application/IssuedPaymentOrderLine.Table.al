table 11711 "Issued Payment Order Line"
{
    Caption = 'Issued Payment Order Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Payment Order No."; Code[20])
        {
            Caption = 'Payment Order No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Employee';
            OptionMembers = " ",Customer,Vendor,"Bank Account",Employee;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Customer)) Customer."No."
            else
            if (Type = const(Vendor)) Vendor."No."
            else
            if (Type = const("Bank Account")) "Bank Account"."No.";
        }
        field(5; "Cust./Vendor Bank Account Code"; Code[20])
        {
            Caption = 'Cust./Vendor Bank Account Code';
            TableRelation = if (Type = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("No."))
            else
            if (Type = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("No."));
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Account No."; Text[30])
        {
            Caption = 'Account No.';
        }
        field(8; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
        }
        field(9; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
        }
        field(10; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
        }
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(12; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(13; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            Editable = false;
        }
        field(14; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            Editable = false;
        }
        field(16; "Applies-to C/V/E Entry No."; Integer)
        {
            Caption = 'Applies-to C/V/E Entry No.';
            TableRelation = if (Type = const(Vendor)) "Vendor Ledger Entry"."Entry No."
            else
            if (Type = const(Customer)) "Cust. Ledger Entry"."Entry No."
            else
            if (Type = const(Employee)) "Employee Ledger Entry"."Entry No.";
        }
        field(17; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
        field(18; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(20; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(24; "Applied Currency Code"; Code[10])
        {
            Caption = 'Applied Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(25; "Payment Order Currency Code"; Code[10])
        {
            Caption = 'Payment Order Currency Code';
            TableRelation = Currency;
        }
        field(26; "Amount(Payment Order Currency)"; Decimal)
        {
            AutoFormatExpression = "Payment Order Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount(Payment Order Currency)';
        }
        field(27; "Payment Order Currency Factor"; Decimal)
        {
            Caption = 'Payment Order Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
        }
        field(30; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(40; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(45; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(60; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ' ,Cancel';
            OptionMembers = " ",Cancel;
        }
        field(70; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(150; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            OptionCaption = ' ,,Purchase';
            OptionMembers = " ",,Purchase;
        }
        field(151; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
        }
        field(152; "Letter Line No."; Integer)
        {
            Caption = 'Letter Line No.';
        }
        field(190; "VAT Uncertainty Payer"; Boolean)
        {
            Caption = 'VAT Uncertainty Payer';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(191; "Public Bank Account"; Boolean)
        {
            Caption = 'Public Bank Account';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(192; "Third Party Bank Account"; Boolean)
        {
            Caption = 'Third Party Bank Account';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(200; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
    }

    keys
    {
        key(Key1; "Payment Order No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Payment Order No.", Positive)
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key3; Type, "Applies-to C/V/E Entry No.", Status)
        {
            SumIndexFields = "Amount (LCY)", Amount;
        }
        key(Key4; "Letter Type", "Letter No.", Status)
        {
            SumIndexFields = "Amount (LCY)", Amount;
        }
    }

    fieldgroups
    {
    }
}