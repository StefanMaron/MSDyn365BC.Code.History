table 11736 "Posted Cash Document Line"
{
    Caption = 'Posted Cash Document Line';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
            TableRelation = "Bank Account"."No." WHERE("Account Type" = CONST("Cash Desk"));
        }
        field(2; "Cash Document No."; Code[20])
        {
            Caption = 'Cash Document No.';
            TableRelation = "Posted Cash Document Header"."No." WHERE("Cash Desk No." = FIELD("Cash Desk No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Document Type"; Option)
        {
            Caption = 'Document Type';
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
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"."No."
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor."No."
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"."No." WHERE("Account Type" = CONST("Bank Account"))
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset"."No.";

            trigger OnLookup()
            var
                GLAcc: Record "G/L Account";
                Customer: Record Customer;
                Vendor: Record Vendor;
                BankAcc: Record "Bank Account";
                StdText: Record "Standard Text";
                FA: Record "Fixed Asset";
            begin
                case "Account Type" of
                    "Account Type"::" ":
                        begin
                            if not StdText.Get("Account No.") then
                                Clear(StdText);
                            if PAGE.RunModal(0, StdText) = ACTION::LookupOK then;
                        end;
                    "Account Type"::"G/L Account":
                        begin
                            if not GLAcc.Get("Account No.") then
                                Clear(GLAcc);
                            if PAGE.RunModal(0, GLAcc) = ACTION::LookupOK then;
                        end;
                    "Account Type"::Customer:
                        begin
                            if not Customer.Get("Account No.") then
                                Clear(Customer);
                            if PAGE.RunModal(0, Customer) = ACTION::LookupOK then;
                        end;
                    "Account Type"::Vendor:
                        begin
                            if not Vendor.Get("Account No.") then
                                Clear(Vendor);
                            if PAGE.RunModal(0, Vendor) = ACTION::LookupOK then;
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            if not BankAcc.Get("Account No.") then
                                Clear(BankAcc);
                            if PAGE.RunModal(PAGE::"Bank Account List", BankAcc) = ACTION::LookupOK then;
                        end;
                    "Account Type"::"Fixed Asset":
                        begin
                            if not FA.Get("Account No.") then
                                Clear(FA);
                            if PAGE.RunModal(0, FA) = ACTION::LookupOK then;
                        end;
                end;
            end;
        }
        field(7; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = IF ("Account Type" = CONST("Fixed Asset")) "FA Posting Group"
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account Posting Group"
            ELSE
            IF ("Account Type" = CONST(Customer)) "Customer Posting Group"
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Posting Group";
        }
        field(13; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(14; "Applies-To Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-To Doc. Type';
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
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(26; "Cash Document Type"; Option)
        {
            Caption = 'Cash Document Type';
            OptionCaption = ' ,Receipt,Withdrawal';
            OptionMembers = " ",Receipt,Withdrawal;
        }
        field(27; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(28; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(40; "Cash Desk Event"; Code[10])
        {
            Caption = 'Cash Desk Event';
            TableRelation = "Cash Desk Event".Code WHERE("Cash Document Type" = FIELD("Cash Document Type"));
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
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(52; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        field(53; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
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
            AutoFormatExpression = "Currency Code";
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
        }
        field(72; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(75; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(90; "FA Posting Type"; Option)
        {
            Caption = 'FA Posting Type';
            OptionCaption = ' ,Acquisition Cost,Depreciation,Write-Down,Appreciation,Custom 1,Custom 2,Disposal,Maintenance';
            OptionMembers = " ","Acquisition Cost",Depreciation,"Write-Down",Appreciation,"Custom 1","Custom 2",Disposal,Maintenance;
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
        }
        field(93; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(94; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
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

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(602; "VAT % (Non Deductible)"; Decimal)
        {
            Caption = 'VAT % (Non Deductible)';
            MaxValue = 100;
            MinValue = 0;
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(603; "VAT Base (Non Deductible)"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Base (Non Deductible)';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(604; "VAT Amount (Non Deductible)"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Amount (Non Deductible)';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(31125; "EET Transaction"; Boolean)
        {
            Caption = 'EET Transaction';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '18.0';
        }
    }

    keys
    {
        key(Key1; "Cash Desk No.", "Cash Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Cash Desk No.", "Cash Document No.", "External Document No.", "VAT Identifier")
        {
            SumIndexFields = "Amount Including VAT", "Amount Including VAT (LCY)", "VAT Base Amount", "VAT Base Amount (LCY)", "VAT Amount", "VAT Amount (LCY)";
        }
        key(Key3; "Cash Desk No.", "Cash Document Type")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Cash Document No.", "Line No."));
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure ExtStatistics()
    var
        PostedCashDocLine: Record "Posted Cash Document Line";
    begin
        TestField("Cash Desk No.");
        TestField("Cash Document No.");
        TestField("Line No.");

        PostedCashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        PostedCashDocLine.SetRange("Cash Document No.", "Cash Document No.");
        PostedCashDocLine.SetRange("Line No.", "Line No.");
        PAGE.RunModal(PAGE::"Posted Cash Doc. Statistics", PostedCashDocLine);
    end;
}

