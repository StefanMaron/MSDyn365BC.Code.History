table 17306 "Tax Diff. Ledger Entry"
{
    Caption = 'Tax Diff. Ledger Entry';
    DrillDownPageID = "Tax Diff. Ledger Entries";
    LookupPageID = "Tax Diff. Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(3; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; "Tax Diff. Type"; Option)
        {
            Caption = 'Tax Diff. Type';
            OptionCaption = 'Constant,Temporary';
            OptionMembers = Constant,"Temporary";
        }
        field(7; "Tax Diff. Code"; Code[10])
        {
            Caption = 'Tax Diff. Code';
        }
        field(8; "Tax Diff. Category"; Option)
        {
            Caption = 'Tax Diff. Category';
            OptionCaption = 'Expense,Income';
            OptionMembers = Expense,Income;
        }
        field(9; "Jurisdiction Code"; Code[10])
        {
            Caption = 'Jurisdiction Code';
        }
        field(10; "Norm Code"; Code[10])
        {
            Caption = 'Norm Code';
        }
        field(11; "Tax Factor"; Decimal)
        {
            Caption = 'Tax Factor';
        }
        field(12; "Tax Diff. Posting Group"; Code[20])
        {
            Caption = 'Tax Diff. Posting Group';
        }
        field(13; "Amount (Base)"; Decimal)
        {
            Caption = 'Amount (Base)';
        }
        field(14; "Amount (Tax)"; Decimal)
        {
            Caption = 'Amount (Tax)';
        }
        field(15; Difference; Decimal)
        {
            Caption = 'Difference';
        }
        field(16; "Tax Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Tax Amount';
            Editable = false;
        }
        field(17; "Asset Tax Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Asset Tax Amount';
            Editable = false;
        }
        field(18; "Liability Tax Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Liability Tax Amount';
            Editable = false;
        }
        field(19; "Disposal Tax Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Disposal Tax Amount';
            Editable = false;
        }
        field(20; "DTA Starting Balance"; Decimal)
        {
            Caption = 'DTA Starting Balance';
        }
        field(21; "DTL Starting Balance"; Decimal)
        {
            Caption = 'DTL Starting Balance';
        }
        field(22; "Disposal Date"; Date)
        {
            Caption = 'Disposal Date';
        }
        field(23; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(26; "Disposal Mode"; Option)
        {
            Caption = 'Disposal Mode';
            OptionCaption = ' ,Write Down,Transform';
            OptionMembers = " ","Write Down",Transform;
        }
        field(27; "DTA Ending Balance"; Decimal)
        {
            Caption = 'DTA Ending Balance';
            Editable = false;
        }
        field(28; "DTL Ending Balance"; Decimal)
        {
            Caption = 'DTL Ending Balance';
            Editable = false;
        }
        field(29; "YTD Amount (Base)"; Decimal)
        {
            BlankZero = true;
            Caption = 'YTD Amount (Base)';
        }
        field(30; "YTD Amount (Tax)"; Decimal)
        {
            BlankZero = true;
            Caption = 'YTD Amount (Tax)';
        }
        field(31; "YTD Difference"; Decimal)
        {
            BlankZero = true;
            Caption = 'YTD Difference';
        }
        field(32; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Future Expense,Fixed Asset,Intangible Asset';
            OptionMembers = " ","Future Expense","Fixed Asset","Intangible Asset";
        }
        field(33; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST("Future Expense")) "Fixed Asset"."No." WHERE("FA Type" = CONST("Future Expense"))
            ELSE
            IF ("Source Type" = CONST("Fixed Asset")) "Fixed Asset"."No." WHERE("FA Type" = CONST("Fixed Assets"))
            ELSE
            IF ("Source Type" = CONST("Intangible Asset")) "Fixed Asset"."No." WHERE("FA Type" = CONST("Intangible Asset"));
        }
        field(34; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(35; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(36; "Partial Disposal"; Boolean)
        {
            Caption = 'Partial Disposal';
        }
        field(37; "Tax Diff. Calc. Mode"; Option)
        {
            Caption = 'Tax Diff. Calc. Mode';
            OptionCaption = ' ,Balance';
            OptionMembers = " ",Balance;
        }
        field(38; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(39; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Tax Diff. Ledger Entry";
        }
        field(40; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Tax Diff. Ledger Entry";
        }
        field(45; "Depr. Bonus Recovery"; Boolean)
        {
            Caption = 'Depr. Bonus Recovery';
        }
        field(46; "Source Entry Type"; Option)
        {
            Caption = 'Source Entry Type';
            OptionCaption = ' ,FA,Depr. Bonus,Disposed FA';
            OptionMembers = " ",FA,"Depr. Bonus","Disposed FA";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";

            trigger OnValidate()
            begin
                ShowDimensions;
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Tax Diff. Code", "Source Type", "Source No.", "Posting Date")
        {
            SumIndexFields = "Tax Amount", "Asset Tax Amount", "Liability Tax Amount", "Disposal Tax Amount", "Amount (Base)", "Amount (Tax)", Difference;
        }
        key(Key3; "Transaction No.")
        {
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Posting Date", "Source Type", "Source No.")
        {
        }
    }

    var
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure ReverseDeprBonusRecover()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        if "Depr. Bonus Recovery" then begin
            TaxRegisterSetup.Get;
            TaxRegisterSetup.TestField("Tax Depreciation Book");
            FALedgerEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
            FALedgerEntry.SetRange("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
            FALedgerEntry.SetRange("FA No.", "Source No.");
            FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
            FALedgerEntry.SetRange("Depr. Bonus", true);
            FALedgerEntry.ModifyAll("Depr. Bonus Recovery Date", 0D);
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "Entry No."));
    end;
}

