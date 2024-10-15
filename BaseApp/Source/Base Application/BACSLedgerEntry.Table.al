table 10550 "BACS Ledger Entry"
{
    Caption = 'BACS Ledger Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Vendor Bank Account";
        }
        field(3; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank;
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(9; "BACS Date"; Date)
        {
            Caption = 'BACS Date';
        }
        field(13; "Entry Status"; Option)
        {
            Caption = 'Entry Status';
            OptionCaption = ',Exported,Voided,Posted,Financially Voided';
            OptionMembers = ,Exported,Voided,Posted,"Financially Voided";
        }
        field(14; "Original Entry Status"; Option)
        {
            Caption = 'Original Entry Status';
            OptionCaption = ' ,Exported,Voided,Posted,Financially Voided';
            OptionMembers = " ",Exported,Voided,Posted,"Financially Voided";
        }
        field(15; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(16; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(17; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(18; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed,BACS Entry Applied';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed,"BACS Entry Applied";
        }
        field(19; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(20; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                                        "Statement No." = FIELD("Statement No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(21; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(23; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(24; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(35; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(36; "Register No."; Integer)
        {
            Caption = 'Register No.';
            TableRelation = "BACS Register";
            //This property is currently not supported
            //TestTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Entry Status")
        {
        }
        key(Key3; "Bank Account Ledger Entry No.", "Entry Status")
        {
        }
        key(Key4; "Bank Account No.", "BACS Date")
        {
        }
        key(Key5; "Bank Account No.", Open)
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
        key(Key7; "Entry Status")
        {
        }
        key(Key8; "Bal. Account No.", "Entry Status")
        {
        }
        key(Key9; "Bal. Account No.", Open)
        {
        }
        key(Key10; "Bal. Account No.", "BACS Date")
        {
        }
        key(Key11; "Register No.", "Bal. Account No.", "Statement Status", "Statement No.")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "BACS Date", "Bank Account No.", Description)
        {
        }
    }

    [Scope('OnPrem')]
    procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAccount: Record "Bank Account";
    begin
        if "Bank Account No." = BankAccount."No." then
            exit(BankAccount."Currency Code");

        if BankAccount.Get("Bank Account No.") then
            exit(BankAccount."Currency Code");

        exit('');
    end;
}

