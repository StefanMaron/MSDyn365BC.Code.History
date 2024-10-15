tableextension 18392 "GST Transfer Line Ext" extends "Transfer Line"
{
    fields
    {
        field(18390; "Transfer Price"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Transfer Prcie';
        }
        field(18391; "Custom Duty Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Custom Duty Amount';
            MinValue = 0;
        }
        field(18392; Amount; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Amount';
            Editable = false;
        }
        field(18393; "GST Credit"; Enum "GST Credit")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'GST Credit';
            Editable = false;
        }
        field(18394; "GST Group Code"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'GST Group Code';
            Editable = false;
        }
        field(18395; "HSN/SAC Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'HSN/SAC Code';
            Editable = false;
        }
        field(18396; Exempted; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Exempted';
            Editable = false;
        }
        field(18397; "GST Assessable Value"; Decimal)
        {
            Caption = 'GST Assessable Value';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
        }
        field(18398; "Amount Added to Inventory"; Decimal)
        {
            Caption = 'Amount Added to Inventory';
            Editable = False;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18399; "Charges to Transfer"; Decimal)
        {
            Caption = 'Charges to Transfer';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }
}