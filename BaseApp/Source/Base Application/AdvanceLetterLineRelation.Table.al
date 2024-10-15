table 31026 "Advance Letter Line Relation"
{
    Caption = 'Advance Letter Line Relation';
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Sale,Purchase';
            OptionMembers = Sale,Purchase;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = IF (Type = CONST(Sale)) "Sales Header"."No." WHERE("Document Type" = FIELD("Document Type"))
            ELSE
            IF (Type = CONST(Purchase)) "Purchase Header"."No." WHERE("Document Type" = FIELD("Document Type"));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            TableRelation = IF (Type = CONST(Sale)) "Sales Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                                                 "Document No." = FIELD("Document No."))
            ELSE
            IF (Type = CONST(Purchase)) "Purchase Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                                                                                                                  "Document No." = FIELD("Document No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(4; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
        }
        field(5; "Letter Line No."; Integer)
        {
            Caption = 'Letter Line No.';
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(7; "Requested Amount"; Decimal)
        {
            Caption = 'Requested Amount';
        }
        field(8; "Invoiced Amount"; Decimal)
        {
            Caption = 'Invoiced Amount';
        }
        field(9; "Deducted Amount"; Decimal)
        {
            Caption = 'Deducted Amount';
        }
        field(20; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Order,Invoice';
            OptionMembers = " ","Order",Invoice;
        }
        field(21; "Amount To Deduct"; Decimal)
        {
            Caption = 'Amount To Deduct';
        }
        field(22; "VAT Doc. VAT Base"; Decimal)
        {
            Caption = 'VAT Doc. VAT Base';
        }
        field(23; "VAT Doc. VAT Amount"; Decimal)
        {
            Caption = 'VAT Doc. VAT Amount';
        }
        field(24; "VAT Doc. VAT Base (LCY)"; Decimal)
        {
            Caption = 'VAT Doc. VAT Base (LCY)';
        }
        field(25; "VAT Doc. VAT Amount (LCY)"; Decimal)
        {
            Caption = 'VAT Doc. VAT Amount (LCY)';
        }
        field(26; "VAT Doc. VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Doc. VAT Difference';
            Editable = false;
        }
        field(27; "Primary Link"; Boolean)
        {
            Caption = 'Primary Link';
        }
    }

    keys
    {
        key(Key1; Type, "Document Type", "Document No.", "Document Line No.", "Letter No.", "Letter Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Invoiced Amount", "Deducted Amount", "Amount To Deduct";
        }
        key(Key2; Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }
}

