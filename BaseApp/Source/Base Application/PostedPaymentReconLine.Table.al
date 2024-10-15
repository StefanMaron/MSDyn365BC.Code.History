table 1296 "Posted Payment Recon. Line"
{
    Caption = 'Posted Payment Recon. Line';
    PasteIsValid = false;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
#if CLEAN17
            TableRelation = "Bank Account";
#else
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Bank Account"));
#endif
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Posted Payment Recon. Hdr"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Statement Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Statement Amount';
        }
        field(8; Difference; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Difference';
        }
        field(9; "Applied Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Applied Amount';
            Editable = false;
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bank Account Ledger Entry,Check Ledger Entry,Difference';
            OptionMembers = "Bank Account Ledger Entry","Check Ledger Entry",Difference;
        }
        field(11; "Applied Entries"; Integer)
        {
            Caption = 'Applied Entries';
            Editable = false;
        }
        field(12; "Value Date"; Date)
        {
            Caption = 'Value Date';
        }
        field(14; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(15; "Related-Party Name"; Text[250])
        {
            Caption = 'Related-Party Name';
        }
        field(16; "Additional Transaction Info"; Text[100])
        {
            Caption = 'Additional Transaction Info';
        }
        field(17; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(18; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(21; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(22; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                                                          Blocked = CONST(false))
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Account Type" = CONST("IC Partner")) "IC Partner";
        }
        field(23; "Applied Document No."; Text[250])
        {
            Caption = 'Applied Document No.';
        }
        field(24; "Applied Entry No."; Text[250])
        {
            Caption = 'Applied Entry No.';
        }
        field(70; "Transaction ID"; Text[250])
        {
            Caption = 'Transaction ID';
        }
        field(71; Reconciled; Boolean)
        {
            Caption = 'Reconciled';
        }
        field(11700; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11701; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11702; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
#if not CLEAN18
            TableRelation = "Constant Symbol";
#endif
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11705; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11710; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11711; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11715; "Statement Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Statement Amount (LCY)';
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11716; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11717; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11720; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,,,,,Refund';
            OptionMembers = " ",Payment,,,,,Refund;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11725; "Difference (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Difference (LCY)';
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11726; "Applied Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Applied Amount (LCY)';
            Editable = false;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(31000; "Advance Letter Link Code"; Code[30])
        {
            Caption = 'Advance Letter Link Code';
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Statement Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure GetCurrencyCode(): Code[10]
    var
        BankAcc2: Record "Bank Account";
    begin
#if not CLEAN19
        // NAVCZ
        if "Currency Code" <> '' then
            exit("Currency Code");
        // NAVCZ

#endif
        if "Bank Account No." = BankAcc2."No." then
            exit(BankAcc2."Currency Code");

        if BankAcc2.Get("Bank Account No.") then
            exit(BankAcc2."Currency Code");

        exit('');
    end;
}

