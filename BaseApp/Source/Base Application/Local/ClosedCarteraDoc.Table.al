table 7000004 "Closed Cartera Doc."
{
    Caption = 'Closed Cartera Doc.';
    DrillDownPageID = "Closed Cartera Documents";
    LookupPageID = "Closed Cartera Documents";

    fields
    {
        field(1; Type; Enum "Cartera Document Type")
        {
            Caption = 'Type';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(8; "Dealing Type"; Option)
        {
            Caption = 'Dealing Type';
            Editable = false;
            OptionCaption = 'Collection,Discount';
            OptionMembers = Collection,Discount;
        }
        field(9; "Amount for Collection"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount for Collection';
        }
        field(10; "Amt. for Collection (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amt. for Collection (LCY)';
        }
        field(11; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(12; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(13; Accepted; Option)
        {
            Caption = 'Accepted';
            OptionCaption = 'Not Required,Yes';
            OptionMembers = "Not Required",Yes;
        }
        field(14; Place; Boolean)
        {
            Caption = 'Place';
        }
        field(15; "Collection Agent"; Option)
        {
            Caption = 'Collection Agent';
            OptionCaption = 'Direct,Bank';
            OptionMembers = Direct,Bank;
        }
        field(16; "Bill Gr./Pmt. Order No."; Code[20])
        {
            Caption = 'Bill Gr./Pmt. Order No.';
            TableRelation = IF (Type = CONST(Receivable)) "Closed Bill Group"."No."
            ELSE
            IF (Type = CONST(Payable)) "Closed Payment Order"."No.";
        }
        field(18; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF (Type = CONST(Receivable)) Customer
            ELSE
            IF (Type = CONST(Payable)) Vendor;
        }
        field(19; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(20; "Cust./Vendor Bank Acc. Code"; Code[20])
        {
            Caption = 'Cust./Vendor Bank Acc. Code';
            TableRelation = IF (Type = CONST(Receivable)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Account No."))
            ELSE
            IF (Type = CONST(Payable)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Account No."));
        }
        field(21; "Pmt. Address Code"; Code[10])
        {
            Caption = 'Pmt. Address Code';
            TableRelation = IF (Type = CONST(Receivable)) "Customer Pmt. Address".Code WHERE("Customer No." = FIELD("Account No."))
            ELSE
            IF (Type = CONST(Payable)) "Vendor Pmt. Address".Code WHERE("Vendor No." = FIELD("Account No."));
        }
        field(22; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(23; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(24; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ',Honored,Rejected';
            OptionMembers = ,Honored,Rejected;
        }
        field(25; "Honored/Rejtd. at Date"; Date)
        {
            Caption = 'Honored/Rejtd. at Date';
        }
        field(26; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
        }
        field(27; "Remaining Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Amt. (LCY)';
        }
        field(28; Redrawn; Boolean)
        {
            Caption = 'Redrawn';
        }
        field(29; "Original Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Amount';
        }
        field(30; "Original Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Original Amount (LCY)';
        }
        field(40; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = 'Invoice,,Bill';
            OptionMembers = Invoice,,Bill;
        }
        field(42; Factoring; Option)
        {
            Caption = 'Factoring';
            Editable = false;
            OptionCaption = ' ,Unrisked,Risked';
            OptionMembers = " ",Unrisked,Risked;
        }
        field(49; "From Journal"; Boolean)
        {
            Caption = 'From Journal';
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
        field(10700; "Original Document No."; Code[20])
        {
            Caption = 'Original Document No.';
        }
    }

    keys
    {
        key(Key1; Type, "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Type, "Document No.")
        {
        }
        key(Key3; "Account No.", "Honored/Rejtd. at Date")
        {
        }
        key(Key4; Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn)
        {
            SumIndexFields = "Amount for Collection", "Original Amount", "Amt. for Collection (LCY)", "Original Amount (LCY)";
        }
        key(Key5; "Bank Account No.", "Dealing Type", "Currency Code", Status, Redrawn, "Due Date", "Honored/Rejtd. at Date")
        {
            SumIndexFields = "Amount for Collection", "Original Amount", "Amt. for Collection (LCY)", "Original Amount (LCY)";
        }
        key(Key6; Type, "Bill Gr./Pmt. Order No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Currency Code", Status, Redrawn)
        {
            SumIndexFields = "Amount for Collection", "Original Amount", "Amt. for Collection (LCY)", "Original Amount (LCY)";
        }
        key(Key7; "Bank Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Currency Code", "Dealing Type", Status, Redrawn, "Due Date", "Honored/Rejtd. at Date", "Document Type")
        {
            SumIndexFields = "Amount for Collection", "Original Amount", "Amt. for Collection (LCY)", "Original Amount (LCY)";
        }
        key(Key8; Type, "Bank Account No.", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn, "Document Type")
        {
            SumIndexFields = "Amount for Collection", "Original Amount", "Amt. for Collection (LCY)", "Original Amount (LCY)";
        }
        key(Key9; Type, "Original Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', Type, "Entry No.", "Document No."));
    end;
}

