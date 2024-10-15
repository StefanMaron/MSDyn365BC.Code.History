table 11707 "Issued Bank Statement Line"
{
    Caption = 'Issued Bank Statement Line';
    DrillDownPageID = "Issued Bank Statement Lines";

    fields
    {
        field(1; "Bank Statement No."; Code[20])
        {
            Caption = 'Bank Statement No.';
            TableRelation = "Issued Bank Statement Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,G/L Account';
            OptionMembers = " ",Customer,Vendor,"Bank Account","G/L Account";
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(Customer)) Customer
            ELSE
            IF (Type = CONST(Vendor)) Vendor
            ELSE
            IF (Type = CONST("Bank Account")) "Bank Account" WHERE("Account Type" = CONST("Bank Account"))
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account";
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
        field(25; "Bank Statement Currency Code"; Code[10])
        {
            Caption = 'Bank Statement Currency Code';
            TableRelation = Currency;
        }
        field(26; "Amount (Bank Stat. Currency)"; Decimal)
        {
            AutoFormatExpression = "Bank Statement Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount (Bank Stat. Currency)';
        }
        field(27; "Bank Statement Currency Factor"; Decimal)
        {
            Caption = 'Bank Statement Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
        }
        field(40; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(45; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(70; Name; Text[100])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Bank Statement No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Statement No.", Positive)
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure ConvertTypeToBankAccReconLineAccountType(): Integer
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        case Type of
            Type::Customer:
                exit(BankAccReconLine."Account Type"::Customer);
            Type::Vendor:
                exit(BankAccReconLine."Account Type"::Vendor);
            Type::"Bank Account":
                exit(BankAccReconLine."Account Type"::"Bank Account");
            Type::"G/L Account":
                exit(BankAccReconLine."Account Type"::"G/L Account");
        end;
    end;
}

