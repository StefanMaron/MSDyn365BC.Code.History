table 372 "Payment Buffer"
{
    Caption = 'Payment Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = SystemMetadata;
            TableRelation = Vendor;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(3; "Vendor Ledg. Entry No."; Integer)
        {
            Caption = 'Vendor Ledg. Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry";
        }
        field(4; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(6; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(9; "Vendor Ledg. Entry Doc. Type"; Option)
        {
            Caption = 'Vendor Ledg. Entry Doc. Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(10; "Vendor Ledg. Entry Doc. No."; Code[20])
        {
            Caption = 'Vendor Ledg. Entry Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry"."Creditor No." WHERE("Entry No." = FIELD("Vendor Ledg. Entry No."));
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            DataClassification = SystemMetadata;
            Numeric = true;
            TableRelation = "Vendor Ledger Entry"."Payment Reference" WHERE("Entry No." = FIELD("Vendor Ledg. Entry No."));
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry"."Payment Method Code" WHERE("Vendor No." = FIELD("Vendor No."));
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(290; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(32000000; "Message Type"; Option)
        {
            Caption = 'Message Type';
            InitValue = "Reference No.";
            OptionCaption = 'Reference No.,Invoice Information,Message,Long Message,Tax Message';
            OptionMembers = "Reference No.","Invoice Information",Message,"Long Message","Tax Message";
        }
        field(32000001; "Invoice Message"; Text[250])
        {
            Caption = 'Invoice Message';
        }
        field(32000002; "Invoice Message 2"; Text[250])
        {
            Caption = 'Invoice Message 2';
        }
        field(32000003; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(32000004; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
        }
        field(32000005; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Currency Code", "Vendor Ledg. Entry No.", "Dimension Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.")
        {
        }
        key(Key3; "Document No.", "Bal. Account No.")
        {
        }
        key(Key4; "Payment Date", "Vendor No.", "Document No.")
        {
        }
    }

    fieldgroups
    {
    }
}

