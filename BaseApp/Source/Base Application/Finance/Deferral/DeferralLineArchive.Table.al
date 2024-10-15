namespace Microsoft.Finance.Deferral;

table 5128 "Deferral Line Archive"
{
    Caption = 'Deferral Line Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
            TableRelation = "Deferral Header Archive"."Deferral Doc. Type";
        }
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
            TableRelation = "Deferral Header Archive"."Document Type";
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Deferral Header Archive"."Document No.";
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Deferral Header Archive"."Line No.";
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.", "Posting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

