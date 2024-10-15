table 31051 "Credit Line"
{
    Caption = 'Credit Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '21.0';
    DataClassification = CustomerContent;

    fields
    {
        field(5; "Credit No."; Code[20])
        {
            Caption = 'Credit No.';
        }
        field(10; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(15; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = 'Customer,Vendor';
            OptionMembers = Customer,Vendor;

            trigger OnValidate()
            begin
                Clear("Source Entry No.");
                Validate("Source Entry No.");
            end;
        }
        field(20; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer."No."
            else
            if ("Source Type" = const(Vendor)) Vendor."No.";
        }
        field(22; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if ("Source Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Source Type" = const(Vendor)) "Vendor Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Source Entry No."; Integer)
        {
            Caption = 'Source Entry No.';
            TableRelation = if ("Source Type" = const(Customer)) "Cust. Ledger Entry"."Entry No." where(Open = const(true))
            else
            if ("Source Type" = const(Vendor)) "Vendor Ledger Entry"."Entry No." where(Open = const(true));

            trigger OnLookup()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
            begin
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            if "Source Entry No." <> 0 then
                                if CustLedgEntry.Get("Source Entry No.") then;
                            CustLedgEntry.SetCurrentKey(Open);
                            CustLedgEntry.SetRange(Open, true);
                            CustLedgEntry.SetRange(Prepayment, false);
                            if ACTION::LookupOK = PAGE.RunModal(0, CustLedgEntry) then
                                Validate("Source Entry No.", CustLedgEntry."Entry No.");
                        end;
                    "Source Type"::Vendor:
                        begin
                            if "Source Entry No." <> 0 then
                                if not VendLedgEntry.Get("Source Entry No.") then;
                            VendLedgEntry.SetCurrentKey(Open);
                            VendLedgEntry.SetRange(Open, true);
                            VendLedgEntry.SetRange(Prepayment, false);
                            if ACTION::LookupOK = PAGE.RunModal(0, VendLedgEntry) then
                                Validate("Source Entry No.", VendLedgEntry."Entry No.");
                        end;
                end;
            end;
        }
        field(30; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(35; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(40; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(45; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(50; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
        }
        field(75; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(77; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(80; "Ledg. Entry Original Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Ledg. Entry Original Amount';
            Editable = false;
        }
        field(85; "Ledg. Entry Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Ledg. Entry Remaining Amount';
        }
        field(87; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(88; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
        }
        field(90; "Ledg. Entry Original Amt.(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledg. Entry Original Amt.(LCY)';
            Editable = false;
        }
        field(95; "Ledg. Entry Rem. Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledg. Entry Rem. Amt. (LCY)';
        }
        field(97; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(98; "Remaining Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Amount (LCY)';
        }
        field(100; "Manual Change Only"; Boolean)
        {
            Caption = 'Manual Change Only';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Credit No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source No.")
        {
            SumIndexFields = "Ledg. Entry Rem. Amt. (LCY)", "Amount (LCY)";
        }
        key(key3; "Credit No.", "Source Type", "Source Entry No.")
        {
            SumIndexFields = "Ledg. Entry Rem. Amt. (LCY)", "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }
}
