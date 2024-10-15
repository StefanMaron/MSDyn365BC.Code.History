table 11731 "Cash Document Line"
{
    Caption = 'Cash Document Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '20.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
        }
        field(2; "Cash Document No."; Code[20])
        {
            Caption = 'Cash Document No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = ' ,Payment,,,,,Refund';
            OptionMembers = " ",Payment,,,,,Refund;
        }
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = ' ,G/L Account,Customer,Vendor,Bank Account,Fixed Asset,Employee';
            OptionMembers = " ","G/L Account",Customer,Vendor,"Bank Account","Fixed Asset",Employee;
        }
        field(6; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(" ")) "Standard Text"
            else
            if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const(Employee)) Employee
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(7; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if ("Account Type" = const("Fixed Asset")) "FA Posting Group"
            else
            if ("Account Type" = const("Bank Account")) "Bank Account Posting Group"
            else
            if ("Account Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Account Type" = const(Vendor)) "Vendor Posting Group";
        }
        field(14; "Applies-To Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-To Doc. Type';

            trigger OnValidate()
            begin
                if "Applies-To Doc. Type" <> xRec."Applies-To Doc. Type" then
                    Validate("Applies-To Doc. No.", '');
            end;
        }
        field(15; "Applies-To Doc. No."; Code[20])
        {
            Caption = 'Applies-To Doc. No.';
        }
        field(16; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(17; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(18; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
        }
        field(20; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(22; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(26; "Cash Document Type"; Option)
        {
            Caption = 'Cash Document Type';
            Editable = false;
            OptionCaption = ' ,Receipt,Withdrawal';
            OptionMembers = " ",Receipt,Withdrawal;
        }
        field(28; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(29; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(30; "Prepayment Type"; Option)
        {
            Caption = 'Prepayment Type';
            OptionCaption = ' ,Prepayment,Advance';
            OptionMembers = " ",Prepayment,Advance;

            trigger OnValidate()
            begin
                TestField(Prepayment, "Prepayment Type" <> "Prepayment Type"::" ");
                if "Prepayment Type" = "Prepayment Type"::Advance then begin
                    TestField("Applies-To Doc. Type", 0);
                    TestField("Applies-To Doc. No.", '');
                end;
            end;
        }
        field(36; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(40; "Cash Desk Event"; Code[10])
        {
            Caption = 'Cash Desk Event';
        }
        field(42; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(43; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(51; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(52; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        field(53; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(55; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
        }
        field(56; "Amount Including VAT (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Including VAT (LCY)';
            Editable = false;
        }
        field(57; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        field(59; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(60; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(62; "VAT Difference (LCY)"; Decimal)
        {
            Caption = 'VAT Difference (LCY)';
        }
        field(63; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(65; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(70; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(71; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(72; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(75; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                TestField("Gen. Posting Type", "Gen. Posting Type"::Purchase);
            end;
        }
        field(90; "FA Posting Type"; Option)
        {
            Caption = 'FA Posting Type';
            OptionCaption = ' ,Acquisition Cost,,,Appreciation,,Custom 2,,Maintenance';
            OptionMembers = " ","Acquisition Cost",,,Appreciation,,"Custom 2",,Maintenance;
        }
        field(91; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(92; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;

            trigger OnValidate()
            begin
                if "Maintenance Code" <> '' then
                    TestField("FA Posting Type", "FA Posting Type"::Maintenance);
            end;
        }
        field(93; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                "Use Duplication List" := false;
            end;
        }
        field(94; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';

            trigger OnValidate()
            begin
                "Duplicate in Depreciation Book" := '';
            end;
        }
        field(98; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(602; "VAT % (Non Deductible)"; Decimal)
        {
            Caption = 'VAT % (Non Deductible)';
            MaxValue = 100;
            MinValue = 0;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Non-deductible VAT has been removed and this field should not be used.';
            ObsoleteTag = '18.0';
        }
        field(603; "VAT Base (Non Deductible)"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'VAT Base (Non Deductible)';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Non-deductible VAT has been removed and this field should not be used.';
            ObsoleteTag = '18.0';
        }
        field(604; "VAT Amount (Non Deductible)"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'VAT Amount (Non Deductible)';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Non-deductible VAT has been removed and this field should not be used.';
            ObsoleteTag = '18.0';
        }
        field(31001; "Advance Letter Link Code"; Code[30])
        {
            Caption = 'Advance Letter Link Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(31125; "EET Transaction"; Boolean)
        {
            Caption = 'EET Transaction';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "Cash Desk No.", "Cash Document No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key2; "Cash Desk No.", "Cash Document No.", "External Document No.", "VAT Identifier")
        {
            SumIndexFields = "Amount Including VAT", "Amount Including VAT (LCY)", "VAT Base Amount", "VAT Base Amount (LCY)", "VAT Amount", "VAT Amount (LCY)";
        }
    }

    fieldgroups
    {
    }
}