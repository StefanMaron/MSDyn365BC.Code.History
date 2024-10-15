table 31029 "Adv. Letter Line Rel. Buffer"
{
    Caption = 'Adv. Letter Line Rel. Buffer';
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(3; "Doc Line No."; Integer)
        {
            Caption = 'Doc Line No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Letter Line No."; Integer)
        {
            Caption = 'Letter Line No.';
            DataClassification = SystemMetadata;
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(7; "Invoiced Amount"; Decimal)
        {
            Caption = 'Invoiced Amount';
            DataClassification = SystemMetadata;
        }
        field(10; "Doc. Line VAT Bus. Post. Gr."; Code[20])
        {
            Caption = 'Doc. Line VAT Bus. Post. Gr.';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(11; "Doc. Line VAT Prod. Post. Gr."; Code[20])
        {
            Caption = 'Doc. Line VAT Prod. Post. Gr.';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(12; "Doc. Line VAT %"; Decimal)
        {
            Caption = 'Doc. Line VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(13; "Doc. Line Description"; Text[100])
        {
            Caption = 'Doc. Line Description';
            DataClassification = SystemMetadata;
        }
        field(14; "Doc. Line Amount"; Decimal)
        {
            Caption = 'Doc. Line Amount';
            DataClassification = SystemMetadata;
        }
        field(20; "Let. Line VAT Bus. Post. Gr."; Code[20])
        {
            Caption = 'Let. Line VAT Bus. Post. Gr.';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(21; "Let. Line VAT Prod. Post. Gr."; Code[20])
        {
            Caption = 'Let. Line VAT Prod. Post. Gr.';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(22; "Let. Line VAT %"; Decimal)
        {
            Caption = 'Let. Line VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(23; "Let. Line Description"; Text[100])
        {
            Caption = 'Let. Line Description';
            DataClassification = SystemMetadata;
        }
        field(40; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Order,Invoice';
            OptionMembers = "Order",Invoice;
        }
        field(41; Select; Boolean)
        {
            Caption = 'Select';
            DataClassification = SystemMetadata;
        }
        field(54; "VAT Doc. VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Doc. VAT Difference';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Doc Line No.", "Letter No.", "Letter Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
        key(Key2; "Letter No.", "Letter Line No.")
        {
        }
    }

    fieldgroups
    {
    }
}

