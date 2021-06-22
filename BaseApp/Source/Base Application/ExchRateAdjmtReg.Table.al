table 86 "Exch. Rate Adjmt. Reg."
{
    Caption = 'Exch. Rate Adjmt. Reg.';
    LookupPageID = "Exchange Rate Adjmt. Register";

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(3; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account";
        }
        field(4; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Posting Group"
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Posting Group"
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account Posting Group";
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(6; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(7; "Adjusted Base"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Adjusted Base';
        }
        field(8; "Adjusted Base (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Adjusted Base (LCY)';
        }
        field(9; "Adjusted Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Adjusted Amt. (LCY)';
        }
        field(10; "Adjusted Base (Add.-Curr.)"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCodeFromGLSetup;
            AutoFormatType = 1;
            Caption = 'Adjusted Base (Add.-Curr.)';
        }
        field(11; "Adjusted Amt. (Add.-Curr.)"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCodeFromGLSetup;
            AutoFormatType = 1;
            Caption = 'Adjusted Amt. (Add.-Curr.)';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure GetCurrencyCodeFromGLSetup(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;
}

