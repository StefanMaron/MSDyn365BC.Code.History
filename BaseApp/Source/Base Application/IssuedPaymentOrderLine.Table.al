table 11711 "Issued Payment Order Line"
{
    Caption = 'Issued Payment Order Line';
    DrillDownPageID = "Issued Payment Order Lines";
    LookupPageID = "Issued Payment Order Lines";
    Permissions = TableData "Issued Payment Order Line" = rm;

    fields
    {
        field(1; "Payment Order No."; Code[20])
        {
            Caption = 'Payment Order No.';
            TableRelation = "Issued Payment Order Header"."No.";
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
            TableRelation = IF (Type = CONST(Customer)) Customer."No."
            ELSE
            IF (Type = CONST(Vendor)) Vendor."No."
            ELSE
            IF (Type = CONST("Bank Account")) "Bank Account"."No." WHERE("Account Type" = CONST("Bank Account"));
        }
        field(5; "Cust./Vendor Bank Account Code"; Code[20])
        {
            Caption = 'Cust./Vendor Bank Account Code';
            TableRelation = IF (Type = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("No."));
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
            TableRelation = "Constant Symbol";
        }
        field(10; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
        }
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(12; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(13; "Applies-to Doc. Type"; Option)
        {
            Caption = 'Applies-to Doc. Type';
            Editable = false;
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(14; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            Editable = false;
        }
        field(16; "Applies-to C/V/E Entry No."; Integer)
        {
            Caption = 'Applies-to C/V/E Entry No.';
            TableRelation = IF (Type = CONST(Vendor)) "Vendor Ledger Entry"."Entry No."
            ELSE
            IF (Type = CONST(Customer)) "Cust. Ledger Entry"."Entry No."
            ELSE
            IF (Type = CONST(Employee)) "Employee Ledger Entry"."Entry No.";
            //This property is currently not supported
            //TestTableRelation = false;
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
            TableRelation = IF ("Letter Type" = CONST(Purchase)) "Purch. Advance Letter Header";
        }
        field(152; "Letter Line No."; Integer)
        {
            Caption = 'Letter Line No.';
            TableRelation = IF ("Letter Type" = CONST(Purchase)) "Purch. Advance Letter Line"."Line No." WHERE("Letter No." = FIELD("Letter No."));
        }
        field(190; "VAT Uncertainty Payer"; Boolean)
        {
            Caption = 'VAT Uncertainty Payer';
            Editable = false;
        }
        field(191; "Public Bank Account"; Boolean)
        {
            Caption = 'Public Bank Account';
            Editable = false;
        }
        field(192; "Third Party Bank Account"; Boolean)
        {
            Caption = 'Third Party Bank Account';
            Editable = false;
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

    var
        ReallyCancelLineQst: Label 'Do you want to cancel payment order line?';

    [Scope('OnPrem')]
    procedure LineCancel()
    var
        IssuedPaymentOrderLine: Record "Issued Payment Order Line";
    begin
        if not Confirm(ReallyCancelLineQst, false) then
            Error('');

        IssuedPaymentOrderLine := Rec;
        IssuedPaymentOrderLine.LockTable;
        IssuedPaymentOrderLine.Find;
        IssuedPaymentOrderLine.Status := IssuedPaymentOrderLine.Status::Cancel;
        IssuedPaymentOrderLine.Modify;
    end;

    [Scope('OnPrem')]
    procedure ConvertTypeToGenJnlLineType(): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case Type of
            Type::Customer:
                exit(GenJnlLine."Account Type"::Customer);
            Type::Vendor:
                exit(GenJnlLine."Account Type"::Vendor);
            Type::"Bank Account":
                exit(GenJnlLine."Account Type"::"Bank Account");
        end;
    end;
}

