tableextension 18394 "GST Transfer Shipment Line Ext" extends "Transfer Shipment Line"
{
    fields
    {
        field(18390; "Custom Duty Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Custom Duty Amount';
            MinValue = 0;
        }
        field(18391; Amount; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Amount';
            Editable = false;
        }
        field(18392; "GST Credit"; Enum "GST Credit")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'GST Credit';
            Editable = false;
        }
        field(18393; "GST Group Code"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'GST Group Code';
            Editable = false;
        }
        field(18394; "HSN/SAC Code"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'HSN/SAC Code';
            Editable = false;
        }
        field(18395; Exempted; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Exempted';
            Editable = false;
        }
        field(18396; "GST Assessable Value"; Decimal)
        {
            Caption = 'GST Assessable Value';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
        }
        field(18397; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}
