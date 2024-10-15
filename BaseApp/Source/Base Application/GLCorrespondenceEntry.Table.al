table 12401 "G/L Correspondence Entry"
{
    Caption = 'G/L Correspondence Entry';
    DataCaptionFields = "Debit Account No.", "Credit Account No.";
    DrillDownPageID = "G/L Correspondence Entries";
    LookupPageID = "G/L Correspondence Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Debit Account No."; Code[20])
        {
            Caption = 'Debit Account No.';
            TableRelation = "G/L Account";
        }
        field(5; "Debit Source No."; Code[20])
        {
            Caption = 'Debit Source No.';
            TableRelation = IF ("Debit Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Debit Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Debit Source Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Debit Source Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(6; "Credit Account No."; Code[20])
        {
            Caption = 'Credit Account No.';
            TableRelation = "G/L Account";
        }
        field(7; "Credit Source No."; Code[20])
        {
            Caption = 'Credit Source No.';
            TableRelation = IF ("Credit Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Credit Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Credit Source Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Credit Source Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(9; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(10; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(11; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(12; "Debit Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1,Debit ';
            Caption = 'Debit Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(13; "Debit Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2,Debit ';
            Caption = 'Debit Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(14; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(15; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(16; "Debit Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Debit Source Type';
        }
        field(17; "Credit Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Credit Source Type';
        }
        field(18; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(20; "Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
        }
        field(48; "Credit Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1,Credit ';
            Caption = 'Credit Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(49; "Credit Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2,Credit ';
            Caption = 'Credit Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(50; "Debit Entry No."; Integer)
        {
            Caption = 'Debit Entry No.';
            TableRelation = "G/L Entry";
        }
        field(51; "Credit Entry No."; Integer)
        {
            Caption = 'Credit Entry No.';
            TableRelation = "G/L Entry";
        }
        field(52; "Debit Dimension Set ID"; Integer)
        {
            Caption = 'Debit Dimension Set ID';
            TableRelation = "Dimension Set Entry";
        }
        field(53; "Credit Dimension Set ID"; Integer)
        {
            Caption = 'Credit Dimension Set ID';
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Transaction No.", "Debit Account No.", "Credit Account No.")
        {
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
        key(Key4; "Debit Account No.", "Credit Account No.", "Debit Global Dimension 1 Code", "Debit Global Dimension 2 Code", "Business Unit Code", "Posting Date", "Credit Global Dimension 1 Code", "Credit Global Dimension 2 Code")
        {
            SumIndexFields = Amount, "Amount (ACY)";
        }
        key(Key5; "Debit Account No.", "Credit Account No.", "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Credit Account No.", "Debit Account No.", "Posting Date")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        NavigateForm: Page Navigate;
        GLSetupRead: Boolean;

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    [Scope('OnPrem')]
    procedure Navigate()
    begin
        NavigateForm.SetDoc("Posting Date", "Document No.");
        NavigateForm.Run;
    end;
}

