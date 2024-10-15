table 10863 "Payment Step Ledger"
{
    Caption = 'Payment Step Ledger';

    fields
    {
        field(1; "Payment Class"; Text[30])
        {
            Caption = 'Payment Class';
            TableRelation = "Payment Class";
        }
        field(2; Line; Integer)
        {
            Caption = 'Line';
        }
        field(3; Sign; Option)
        {
            Caption = 'Sign';
            OptionCaption = 'Debit,Credit';
            OptionMembers = Debit,Credit;
        }
        field(4; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; "Accounting Type"; Option)
        {
            Caption = 'Accounting Type';
            OptionCaption = 'Payment Line Account,Associated G/L Account,Setup Account,G/L Account / Month,G/L Account / Week,Bal. Account Previous Entry,Header Payment Account';
            OptionMembers = "Payment Line Account","Associated G/L Account","Setup Account","G/L Account / Month","G/L Account / Week","Bal. Account Previous Entry","Header Payment Account";

            trigger OnValidate()
            begin
                Validate(Root);
            end;
        }
        field(9; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(10; "Account No."; Code[20])
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
            //This property is currently not supported
            //TestTableRelation = true;
            ValidateTableRelation = true;
        }
        field(11; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(12; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(13; Root; Code[20])
        {
            Caption = 'Root';
        }
        field(14; "Detail Level"; Option)
        {
            Caption = 'Detail Level';
            OptionCaption = 'Line,Account,Due Date';
            OptionMembers = Line,Account,"Due Date";
        }
        field(16; Application; Option)
        {
            Caption = 'Application';
            OptionCaption = 'None,Applied Entry,Entry Previous Step,Memorized Entry';
            OptionMembers = "None","Applied Entry","Entry Previous Step","Memorized Entry";
        }
        field(17; "Memorize Entry"; Boolean)
        {
            Caption = 'Memorize Entry';
        }
        field(18; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder;
        }
        field(19; "Document No."; Option)
        {
            Caption = 'Document No.';
            OptionCaption = 'Header No.,Document ID Line';
            OptionMembers = "Header No.","Document ID Line";
        }
    }

    keys
    {
        key(Key1; "Payment Class", Line, Sign)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

