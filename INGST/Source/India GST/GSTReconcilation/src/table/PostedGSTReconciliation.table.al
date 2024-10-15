table 18284 "Posted GST Reconciliation"
{
    Caption = 'Posted GST Reconciliation';

    fields
    {
        field(1; "GSTIN No."; Code[15])
        {
            Caption = 'GSTIN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "State Code"; Code[10])
        {
            Caption = 'State Code';
            TableRelation = State;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Reconciliation Month"; Integer)
        {
            Caption = 'Reconciliation Month';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Reconciliation Year"; Integer)
        {
            Caption = 'Reconciliation Year';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "GST Component"; Code[10])
        {
            Caption = 'GST Component';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "GST Amount"; Decimal)
        {
            Caption = 'GST Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "GST Prev. Period B/F Amount"; Decimal)
        {
            Caption = 'GST Prev. Period B/F Amount';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "GST Amount Utilized"; Decimal)
        {
            Caption = 'GST Amount Utilized';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "GST Prev. Period C/F Amount"; Decimal)
        {
            Caption = 'GST Prev. Period C/F Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(10; "Source Type"; Enum "GSTReco Source Type")
        {
            Caption = 'Source Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(11; "Payment Posted (Sales)"; Boolean)
        {
            Caption = 'Payment Posted (Sales)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(12; "Payment Posted (Sales Export)"; Boolean)
        {
            Caption = 'Payment Posted (Sales Export)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(13; "Payment Posted (Adv-Rev)"; Boolean)
        {
            Caption = 'Payment Posted (Adv-Rev)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(14; "Payment Posted (Invoice-Rev)"; Boolean)
        {
            Caption = 'Payment Posted (Invoice-Rev)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "GSTIN No.", "State Code", "Reconciliation Month", "Reconciliation Year", "GST Component")
        {
            Clustered = true;
        }
        key(Key2; "GSTIN No.", "Reconciliation Month", "Reconciliation Year", "Source Type")
        {
        }
        key(Key3; "GSTIN No.", "Reconciliation Year", "GST Component", "Source Type")
        {
        }
        key(Key4; "GSTIN No.", "State Code", "GST Component", "Reconciliation Year", "Reconciliation Month")
        {
        }
    }
}
