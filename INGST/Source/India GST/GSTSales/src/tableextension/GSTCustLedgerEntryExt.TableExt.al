tableextension 18141 "GST Cust. Ledger Entry Ext." extends "Cust. Ledger Entry"
{
    fields
    {
        field(18141; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18142; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18143; "GST on Advance Payment"; Boolean)
        {
            Caption = 'GST on Advance Payment';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18144; "Adv. Pmt. Adjustment"; Boolean)
        {
            Caption = 'Adv. Pmt. Adjustment';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18145; "GST Jurisdiction Type"; enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18146; "Location State Code"; Code[10])
        {
            Caption = 'Location State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18147; "Seller State Code"; Code[10])
        {
            Caption = 'Seller State Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = State;
        }
        field(18148; "Seller GST Reg. No."; Code[20])
        {
            Caption = 'Seller GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18149; "GST Customer Type"; enum "GST Customer Type")
        {
            Caption = 'GST Customer Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18150; "Location GST Reg. No."; Code[20])
        {
            Caption = 'Location GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18151; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18152; "GST in Journal"; Boolean)
        {
            Caption = 'GST in Journal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18153; "Journal Entry"; Boolean)
        {
            Caption = 'Journal Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18154; "GST Without Payment of Duty"; Boolean)
        {
            Caption = 'GST Without Payment of Duty';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18155; "Location ARN No."; Code[20])
        {
            Caption = 'Location ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}