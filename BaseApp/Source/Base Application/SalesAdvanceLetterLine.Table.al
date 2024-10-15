table 31001 "Sales Advance Letter Line"
{
    Caption = 'Sales Advance Letter Line';
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';

    fields
    {
        field(3; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
            TableRelation = "G/L Account";
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Advance Due Date"; Date)
        {
            Caption = 'Advance Due Date';
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
        }
        field(31; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(32; "Amount To Link"; Decimal)
        {
            Caption = 'Amount To Link';
            Editable = false;
            FieldClass = Normal;
        }
        field(33; "Amount Linked"; Decimal)
        {
            Caption = 'Amount Linked';
            Editable = false;
            FieldClass = Normal;
        }
        field(34; "Amount To Invoice"; Decimal)
        {
            Caption = 'Amount To Invoice';
            Editable = false;
        }
        field(35; "Amount Invoiced"; Decimal)
        {
            Caption = 'Amount Invoiced';
            Editable = false;
        }
        field(36; "Amount To Deduct"; Decimal)
        {
            Caption = 'Amount To Deduct';
            Editable = false;
        }
        field(37; "Amount Deducted"; Decimal)
        {
            Caption = 'Amount Deducted';
            Editable = false;
        }
        field(38; "Amount Linked To Journal Line"; Decimal)
        {
            Caption = 'Amount Linked To Journal Line';
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            TableRelation = Job;
        }
        field(47; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(120; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Pending Advance Payment,Pending Advance Invoice,Pending Final Invoice,Closed,Pending Approval';
            OptionMembers = Open,"Pending Advance Payment","Pending Advance Invoice","Pending Final Invoice",Closed,"Pending Approval";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(31015; "Amount To Refund"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            BlankZero = true;
            Caption = 'Amount To Refund';
        }
        field(31016; "Customer Posting Group"; Code[20])
        {
            CalcFormula = Lookup("Sales Advance Letter Header"."Customer Posting Group" where("No." = field("Letter No.")));
            Caption = 'Customer Posting Group';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Customer Posting Group";
        }
        field(31017; "Link Code"; Code[30])
        {
            Caption = 'Link Code';
        }
        field(31018; "Document Linked Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation".Amount where(Type = const(Sale),
                                                                           "Letter No." = field("Letter No."),
                                                                           "Letter Line No." = field("Line No."),
                                                                           "Document No." = field("Doc. No. Filter")));
            Caption = 'Document Linked Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31019; "Doc. No. Filter"; Code[20])
        {
            Caption = 'Doc. No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Header"."No.";
        }
        field(31020; "Semifinished Linked Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Semifinished Linked Amount';
        }
        field(31021; "Document Linked Inv. Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation"."Invoiced Amount" where(Type = const(Sale),
                                                                                      "Letter No." = field("Letter No."),
                                                                                      "Letter Line No." = field("Line No."),
                                                                                      "Document No." = field("Doc. No. Filter")));
            Caption = 'Document Linked Inv. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31022; "Advance G/L Account No."; Code[20])
        {
            Caption = 'Advance G/L Account No.';
            Editable = false;
            TableRelation = "G/L Account";
        }
        field(31023; "Document Linked Ded. Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation"."Deducted Amount" where(Type = const(Sale),
                                                                                      "Letter No." = field("Letter No."),
                                                                                      "Letter Line No." = field("Line No."),
                                                                                      "Document No." = field("Doc. No. Filter")));
            Caption = 'Document Linked Ded. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31024; "Doc. Linked Amount to Deduct"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation"."Amount To Deduct" where(Type = const(Sale),
                                                                                       "Letter No." = field("Letter No."),
                                                                                       "Letter Line No." = field("Line No."),
                                                                                       "Document No." = field("Doc. No. Filter")));
            Caption = 'Doc. Linked Amount to Deduct';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Letter No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Amount Including VAT", "Amount To Link", "Amount Linked", "Amount To Invoice", "Amount Invoiced", "Amount To Deduct", "Amount Deducted";
        }
        key(Key2; "Bill-to Customer No.", Status)
        {
        }
        key(Key3; "Link Code")
        {
        }
    }

    fieldgroups
    {
    }
}

