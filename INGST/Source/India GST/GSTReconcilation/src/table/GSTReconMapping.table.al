table 18282 "GST Recon. Mapping"
{
    Caption = 'GST Recon. Mapping';

    fields
    {
        field(1; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "GST Reconciliation Field No."; Integer)
        {
            Caption = 'GST Reconciliation Field No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "GST Reconciliation Field Name"; Text[30])
        {
            Caption = 'GST Reconciliation Field Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "ISD Ledger Field No."; Integer)
        {
            Caption = 'ISD Ledger Field No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "ISD Ledger Field Name"; Text[30])
        {
            Caption = 'ISD Ledger Field Name';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "GST Component Code", "GST Reconciliation Field No.")
        {
            Clustered = true;
        }
    }
}