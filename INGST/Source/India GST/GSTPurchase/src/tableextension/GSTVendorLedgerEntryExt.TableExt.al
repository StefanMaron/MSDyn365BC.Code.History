tableextension 18093 "GST Vendor Ledger Entry Ext" extends "Vendor Ledger Entry"
{
    fields
    {
        field(18080; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18081; "GST on Advance Payment"; Boolean)
        {
            Caption = 'GST on Advance Payment';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18082; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18083; "GST Reverse Charge"; Boolean)
        {
            Caption = 'GST Reverse Charge';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18084; "Adv. Pmt. Adjustment"; Boolean)
        {
            Caption = 'Adv. Pmt. Adjustment';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18085; "Location State Code"; Code[10])
        {
            Caption = 'Location State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18086; "Buyer State Code"; Code[10])
        {
            Caption = 'Buyer State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = State;
        }
        field(18087; "Buyer GST Reg. No."; Code[20])
        {
            Caption = 'Buyer GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18088; "GST Vendor Type"; enum "GST Vendor Type")
        {
            Caption = 'GST Vendor Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18089; "Location GST Reg. No."; Code[20])
        {
            Caption = 'Location GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18090; "GST Jurisdiction Type"; enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18091; "GST Input Service Distribution"; Boolean)
        {
            Caption = 'GST Input Service Distribution';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18092; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18093; "RCM Exempt"; Boolean)
        {
            Caption = 'RCM Exempt';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18094; "GST in Journal"; Boolean)
        {
            Caption = 'GST in Journal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18095; "Journal Entry"; Boolean)
        {
            Caption = 'Journal Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18096; "Location ARN No."; Code[20])
        {
            Caption = 'Location ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18097; "Provisional Entry"; Boolean)
        {
            Caption = 'Provisional Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}