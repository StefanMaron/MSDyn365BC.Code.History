table 5601 "FA Ledger Entry"
{
    Caption = 'FA Ledger Entry';
    DrillDownPageID = "FA Ledger Entries";
    LookupPageID = "FA Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "G/L Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'G/L Entry No.';
            TableRelation = "G/L Entry";
        }
        field(3; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            TableRelation = "Fixed Asset";
        }
        field(4; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(7; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(8; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(9; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(12; "FA Posting Category"; Option)
        {
            Caption = 'FA Posting Category';
            OptionCaption = ' ,Disposal,Bal. Disposal';
            OptionMembers = " ",Disposal,"Bal. Disposal";
        }
        field(13; "FA Posting Type"; Enum "FA Ledger Entry FA Posting Type")
        {
            Caption = 'FA Posting Type';
        }
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(15; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Debit Amount';
        }
        field(16; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit Amount';
        }
        field(17; "Reclassification Entry"; Boolean)
        {
            Caption = 'Reclassification Entry';
        }
        field(18; "Part of Book Value"; Boolean)
        {
            Caption = 'Part of Book Value';
        }
        field(19; "Part of Depreciable Basis"; Boolean)
        {
            Caption = 'Part of Depreciable Basis';
        }
        field(20; "Disposal Calculation Method"; Option)
        {
            Caption = 'Disposal Calculation Method';
            OptionCaption = ' ,Net,Gross';
            OptionMembers = " ",Net,Gross;
        }
        field(21; "Disposal Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Disposal Entry No.';
        }
        field(22; "No. of Depreciation Days"; Integer)
        {
            Caption = 'No. of Depreciation Days';
        }
        field(23; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(24; "FA No./Budgeted FA No."; Code[20])
        {
            Caption = 'FA No./Budgeted FA No.';
            TableRelation = "Fixed Asset";
        }
        field(25; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";
        }
        field(26; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(27; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";
        }
        field(28; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(29; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(32; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(33; "Depreciation Method"; Enum "FA Depreciation Method")
        {
            Caption = 'Depreciation Method';
        }
        field(34; "Depreciation Starting Date"; Date)
        {
            Caption = 'Depreciation Starting Date';
        }
        field(35; "Straight-Line %"; Decimal)
        {
            Caption = 'Straight-Line %';
            DecimalPlaces = 1 : 1;
        }
        field(36; "No. of Depreciation Years"; Decimal)
        {
            Caption = 'No. of Depreciation Years';
            DecimalPlaces = 0 : 3;
        }
        field(37; "Fixed Depr. Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Fixed Depr. Amount';
        }
        field(38; "Declining-Balance %"; Decimal)
        {
            Caption = 'Declining-Balance %';
            DecimalPlaces = 1 : 1;
        }
        field(39; "Depreciation Table Code"; Code[10])
        {
            Caption = 'Depreciation Table Code';
            TableRelation = "Depreciation Table Header";
        }
        field(40; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(41; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(42; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(43; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(44; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(45; "Bal. Account No."; Code[20])
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
        field(46; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(47; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        field(48; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(49; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(50; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";
        }
        field(51; "FA Exchange Rate"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'FA Exchange Rate';
        }
        field(52; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(53; "Result on Disposal"; Option)
        {
            Caption = 'Result on Disposal';
            OptionCaption = ' ,Gain,Loss';
            OptionMembers = " ",Gain,Loss;
        }
        field(54; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(55; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
        field(56; "Canceled from FA No."; Code[20])
        {
            Caption = 'Canceled from FA No.';
            TableRelation = "Fixed Asset";
        }
        field(57; "Depreciation Ending Date"; Date)
        {
            Caption = 'Depreciation Ending Date';
        }
        field(58; "Use FA Ledger Check"; Boolean)
        {
            Caption = 'Use FA Ledger Check';
        }
        field(59; "Automatic Entry"; Boolean)
        {
            Caption = 'Automatic Entry';
        }
        field(60; "Depr. Starting Date (Custom 1)"; Date)
        {
            Caption = 'Depr. Starting Date (Custom 1)';
        }
        field(61; "Depr. Ending Date (Custom 1)"; Date)
        {
            Caption = 'Depr. Ending Date (Custom 1)';
        }
        field(62; "Accum. Depr. % (Custom 1)"; Decimal)
        {
            Caption = 'Accum. Depr. % (Custom 1)';
            DecimalPlaces = 1 : 1;
        }
        field(63; "Depr. % this year (Custom 1)"; Decimal)
        {
            Caption = 'Depr. % this year (Custom 1)';
            DecimalPlaces = 1 : 1;
        }
        field(64; "Property Class (Custom 1)"; Option)
        {
            Caption = 'Property Class (Custom 1)';
            OptionCaption = ' ,Personal Property,Real Property';
            OptionMembers = " ","Personal Property","Real Property";
        }
        field(65; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(66; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(67; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(68; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(69; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(70; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(71; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(72; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(73; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(74; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(12405; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(12429; "Prepmt. Diff. Appln. Entry No."; Integer)
        {
            Caption = 'Prepmt. Diff. Appln. Entry No.';
            Editable = false;
        }
        field(12450; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(12451; "Item Entry No."; Integer)
        {
            Caption = 'Item Entry No.';
            TableRelation = "Item Ledger Entry" WHERE("Entry No." = FIELD("Item Entry No."));
        }
        field(12452; "Value Entry No."; Integer)
        {
            Caption = 'Value Entry No.';
            TableRelation = "Value Entry" WHERE("Entry No." = FIELD("Value Entry No."));
        }
        field(12453; "Need Cost Posted to G/L"; Boolean)
        {
            Caption = 'Need Cost Posted to G/L';
        }
        field(12454; "Corr. Value Entry No."; Integer)
        {
            Caption = 'Corr. Value Entry No.';
            TableRelation = "Value Entry" WHERE("Entry No." = FIELD("Corr. Value Entry No."));
        }
        field(12470; "Initial Acquisition"; Boolean)
        {
            Caption = 'Initial Acquisition';
        }
        field(12486; "FA Charge No."; Code[20])
        {
            Caption = 'FA Charge No.';
            Editable = false;
            TableRelation = "FA Charge";
        }
        field(12491; "Depr. Period Starting Date"; Date)
        {
            Caption = 'Depr. Period Starting Date';
            TableRelation = "Accounting Period";
        }
        field(17201; "Depr. Bonus"; Boolean)
        {
            Caption = 'Depr. Bonus';
        }
        field(17202; "Depr. Bonus %"; Decimal)
        {
            Caption = 'Depr. Bonus %';
        }
        field(17205; "Sales Gain Amount"; Decimal)
        {
            Caption = 'Sales Gain Amount';
        }
        field(17206; "Sales Loss Amount"; Decimal)
        {
            Caption = 'Sales Loss Amount';
        }
        field(17300; "Depr. Amount w/o Normalization"; Decimal)
        {
            BlankZero = true;
            Caption = 'Depr. Amount w/o Normalization';
        }
        field(17301; "Depr. Group Elimination"; Boolean)
        {
            Caption = 'Depr. Group Elimination';
        }
        field(17302; "Tax Difference Code"; Code[10])
        {
            Caption = 'Tax Difference Code';
            TableRelation = "Tax Difference" WHERE("Source Code Mandatory" = CONST(true));
        }
        field(17303; "Belonging to Manufacturing"; Option)
        {
            Caption = 'Belonging to Manufacturing';
            OptionCaption = ' ,Production,Nonproduction';
            OptionMembers = " ",Production,Nonproduction;
        }
        field(17304; "FA Type"; Option)
        {
            Caption = 'FA Type';
            OptionCaption = 'Fixed Assets,Intangible Asset,Future Expense';
            OptionMembers = "Fixed Assets","Intangible Asset","Future Expense";
        }
        field(17305; "Depreciation Group"; Code[10])
        {
            Caption = 'Depreciation Group';
            TableRelation = "Depreciation Group";

            trigger OnValidate()
            var
                c: Text[1];
            begin
            end;
        }
        field(17306; "Depr. Bonus Recovery Date"; Date)
        {
            Caption = 'Depr. Bonus Recovery Date';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "FA No.", "Depreciation Book Code", "FA Posting Date")
        {
            SumIndexFields = Amount, Quantity;
        }
        key(Key3; "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date", "Part of Book Value", "Reclassification Entry", "FA Location Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Initial Acquisition", "Employee No.", "Depr. Bonus", "Depr. Group Elimination")
        {
            SumIndexFields = Amount, Quantity, "Depr. Amount w/o Normalization";
        }
        key(Key4; "FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date")
        {
            SumIndexFields = Amount, Quantity;
        }
        key(Key5; "FA No.", "Depreciation Book Code", "Part of Depreciable Basis", "FA Posting Date")
        {
            SumIndexFields = Amount, Quantity;
        }
        key(Key6; "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date")
        {
            SumIndexFields = Amount, Quantity;
        }
        key(Key7; "Canceled from FA No.", "Depreciation Book Code", "FA Posting Date", "FA Location Code", "Global Dimension 1 Code", "Global Dimension 2 Code")
        {
        }
        key(Key8; "Document No.", "Posting Date")
        {
        }
        key(Key9; "G/L Entry No.")
        {
        }
        key(Key10; "Document Type", "Document No.")
        {
        }
        key(Key11; "Transaction No.")
        {
        }
        key(Key12; "FA No.", "Entry No.", "Document No.")
        {
            SumIndexFields = Amount, Quantity;
        }
        key(Key13; "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date", "Depr. Bonus")
        {
            SumIndexFields = Amount, Quantity;
        }
        key(Key14; "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Document No.")
        {
        }
        key(Key15; "FA No.", "Depreciation Book Code", "FA Posting Date", Reversed, "Tax Difference Code")
        {
            SumIndexFields = Amount;
        }
        key(Key16; "Depreciation Book Code", "FA Posting Date", "FA Posting Category", "FA Posting Type", "Belonging to Manufacturing", "FA Type", "Depreciation Group", "Depr. Bonus", "Depr. Group Elimination", "Tax Difference Code", Quantity, "Reclassification Entry", "Depr. Bonus Recovery Date", "Depr. Bonus %", "FA No.")
        {
            SumIndexFields = Amount, "Sales Gain Amount", "Sales Loss Amount";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "FA No.", "FA Posting Date", "FA Posting Type", "Document Type")
        {
        }
    }

    var
        FAJnlSetup: Record "FA Journal Setup";
        DimMgt: Codeunit DimensionManagement;
        NextLineNo: Integer;
        Text17201: Label 'There are Depreciation entries with Posting Date later than %1. Cancel these entries and try again.';
        Text17202: Label 'There are Depreciation Bonus entries with Posting Date later than %1. Cancel these entries and try again.';
        Text12400: Label 'You have to reverse realized VAT Entry No. %1 first before you can update %2 No. %3.';

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure MoveToGenJnl(var GenJnlLine: Record "Gen. Journal Line")
    begin
        NextLineNo := GenJnlLine."Line No.";
        GenJnlLine."Line No." := 0;
        GenJnlLine.Init();
        FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
        GenJnlLine."FA Posting Type" := "Gen. Journal Line FA Posting Type".FromInteger(ConvertPostingType() + 1);
        GenJnlLine."Posting Date" := "Posting Date";
        GenJnlLine."FA Posting Date" := "FA Posting Date";
        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
            GenJnlLine."FA Posting Date" := 0D;
        GenJnlLine."FA Location Code" := "FA Location Code";
        GenJnlLine."Employee No." := "Employee No.";
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Fixed Asset");
        GenJnlLine.Validate("Account No.", "FA No.");
        GenJnlLine.Validate("Depreciation Book Code", "Depreciation Book Code");
        GenJnlLine.Validate(Amount, Amount);
        GenJnlLine.Validate(Correction, Correction);
        GenJnlLine."Document Type" := "Document Type";
        GenJnlLine."Document No." := "Document No.";
        GenJnlLine."Document Date" := "Document Date";
        GenJnlLine."External Document No." := "External Document No.";
        if "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" then
            GenJnlLine.Quantity := Quantity;
        GenJnlLine."No. of Depreciation Days" := "No. of Depreciation Days";
        GenJnlLine."FA Reclassification Entry" := "Reclassification Entry";
        GenJnlLine."Index Entry" := "Index Entry";
        GenJnlLine."Line No." := NextLineNo;
        GenJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := "Dimension Set ID";
        GenJnlLine."Tax Difference Code" := "Tax Difference Code";

        OnAfterMoveToGenJnlLine(GenJnlLine, Rec);
    end;

    procedure MoveToFAJnl(var FAJnlLine: Record "FA Journal Line")
    begin
        NextLineNo := FAJnlLine."Line No.";
        FAJnlLine."Line No." := 0;
        FAJnlLine.Init();
        FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
        FAJnlLine."FA Posting Type" := "FA Journal Line FA Posting Type".FromInteger(ConvertPostingType());
        FAJnlLine."Posting Date" := "Posting Date";
        FAJnlLine."FA Posting Date" := "FA Posting Date";
        if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
            FAJnlLine."Posting Date" := 0D;
        FAJnlLine."Location Code" := "FA Location Code";
        FAJnlLine."Employee No." := "Employee No.";
        FAJnlLine.Validate("FA No.", "FA No.");
        FAJnlLine.Validate("Depreciation Book Code", "Depreciation Book Code");
        FAJnlLine.Validate(Amount, Amount);
        FAJnlLine.Validate(Correction, Correction);
        if "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" then
            FAJnlLine.Quantity := Quantity;
        FAJnlLine."Document Type" := "Document Type";
        FAJnlLine."Document No." := "Document No.";
        FAJnlLine."Document Date" := "Document Date";
        FAJnlLine."External Document No." := "External Document No.";
        FAJnlLine."No. of Depreciation Days" := "No. of Depreciation Days";
        FAJnlLine."FA Reclassification Entry" := "Reclassification Entry";
        FAJnlLine."Index Entry" := "Index Entry";
        FAJnlLine."Line No." := NextLineNo;
        FAJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
        FAJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
        FAJnlLine."Dimension Set ID" := "Dimension Set ID";
        FAJnlLine."Tax Difference Code" := "Tax Difference Code";

        OnAfterMoveToFAJnlLine(FAJnlLine, Rec);
    end;

    procedure ConvertPostingType(): Option
    var
        FAJnlLine: Record "FA Journal Line";
    begin
        case "FA Posting Type" of
            "FA Posting Type"::"Acquisition Cost":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Acquisition Cost";
            "FA Posting Type"::Depreciation:
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::Depreciation;
            "FA Posting Type"::"Write-Down":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Write-Down";
            "FA Posting Type"::Appreciation:
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::Appreciation;
            "FA Posting Type"::"Custom 1":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Custom 1";
            "FA Posting Type"::"Custom 2":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Custom 2";
            "FA Posting Type"::"Proceeds on Disposal":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::Disposal;
            "FA Posting Type"::"Salvage Value":
                FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Salvage Value";
            else
                OnAfterConvertPostingTypeElse(FAJnlLine, Rec);
        end;
        exit(FAJnlLine."FA Posting Type".AsInteger());
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "Entry No."));
    end;

    [Scope('OnPrem')]
    procedure UnMarkAsDeprBonusBase(var FALedgEntry: Record "FA Ledger Entry"; MarkEntry: Boolean)
    var
        FALedgEntry1: Record "FA Ledger Entry";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        FALedgEntry1.Copy(FALedgEntry);
        with FALedgEntry1 do begin
            if Find('-') then
                repeat
                    if ("FA Posting Type" = "FA Posting Type"::"Acquisition Cost") or
                       ("FA Posting Type" = "FA Posting Type"::Appreciation)
                    then begin
                        TaxRegisterSetup.Get();
                        TestField("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
                        CheckLaterDepreciation(FALedgEntry1);
                        "Depr. Bonus" := MarkEntry;
                        CODEUNIT.Run(CODEUNIT::"FA Entry - Edit", FALedgEntry1);
                    end;
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckLaterDepreciation(FALedgEntry2: Record "FA Ledger Entry")
    var
        FALedgEntry1: Record "FA Ledger Entry";
    begin
        with FALedgEntry1 do begin
            Reset;
            SetCurrentKey(
              "FA No.", "Depreciation Book Code", "FA Posting Category",
              "FA Posting Type", "FA Posting Date", "Depr. Bonus");
            SetRange("FA No.", FALedgEntry2."FA No.");
            SetRange("Depreciation Book Code", FALedgEntry2."Depreciation Book Code");
            SetRange("FA Posting Category", "FA Posting Category"::" ");
            SetRange("FA Posting Type", "FA Posting Type"::Depreciation);
            SetRange("Depr. Bonus", false);
            SetRange("FA Posting Date", FALedgEntry2."FA Posting Date", 99991231D);
            CalcSums(Amount);
            if Amount <> 0 then
                Error(Text17201, FALedgEntry2."Posting Date");
            SetRange("Depr. Bonus", true);
            SetRange("FA Posting Date", FALedgEntry2."FA Posting Date", 99991231D);
            CalcSums(Amount);
            if Amount <> 0 then
                Error(Text17202, FALedgEntry2."Posting Date");
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckRealizedVAT(EntryNo: Integer)
    var
        RealVATEntryNo: Integer;
    begin
        if Get(EntryNo) then begin
            RealVATEntryNo := FindLastRealizedVATEntry;
            if RealVATEntryNo <> 0 then
                Error(Text12400, RealVATEntryNo, TableCaption, "Entry No.")
        end;
    end;

    [Scope('OnPrem')]
    procedure FindLastRealizedVATEntry(): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey(Type, "Object Type", "Object No.");
        VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
        VATEntry.SetRange("Object No.", "FA No.");
        VATEntry.SetRange("FA Ledger Entry No.", "Entry No.");
        VATEntry.SetRange(Reversed, false);
        if VATEntry.FindLast() then
            exit(VATEntry."Entry No.");
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetAmountToRealize(VATEntryNo: Integer): Decimal
    var
        VATEntry: Record "VAT Entry";
        RemainingBase: Decimal;
        TotalAmount: Decimal;
        TotalAmountRnded: Decimal;
        BaseAmount: Decimal;
        TotalUnrealBase: Decimal;
    begin
        if Amount + CalcRealizedVATBase(0) = 0 then
            exit(0);
        VATEntry.SetCurrentKey(Type, "Object Type", "Object No.");
        VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
        VATEntry.SetRange("Object No.", "FA No.");
        VATEntry.SetRange("Posting Date", 0D, "Posting Date");
        VATEntry.SetRange("FA Ledger Entry No.", 0);
        VATEntry.CalcSums("Remaining Unrealized Base", "Unrealized Base");
        if VATEntry."Remaining Unrealized Base" = 0 then
            exit(0);
        TotalUnrealBase := VATEntry."Unrealized Base";
        if VATEntry.FindSet() then
            repeat
                TotalAmount := TotalAmount + VATEntry."Unrealized Base" / TotalUnrealBase * Amount;
                RemainingBase := Round(TotalAmount) - TotalAmountRnded;
                TotalAmountRnded := TotalAmountRnded + RemainingBase;
                BaseAmount := RemainingBase + CalcRealizedVATBase(VATEntry."Entry No.");
                if VATEntry."Entry No." = VATEntryNo then
                    exit(BaseAmount);
            until VATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcRealizedVATBase(VATEntryNo: Integer): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey(Type, "Object Type", "Object No.");
        VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
        VATEntry.SetRange("Object No.", "FA No.");
        VATEntry.SetRange("FA Ledger Entry No.", "Entry No.");
        if VATEntryNo <> 0 then
            VATEntry.SetRange("Unrealized VAT Entry No.", VATEntryNo);
        VATEntry.CalcSums(Base);
        exit(VATEntry.Base);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertPostingTypeElse(var FAJournalLine: Record "FA Journal Line"; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveToGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveToFAJnlLine(var FAJournalLine: Record "FA Journal Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;
}

