tableextension 18391 "GST Transfer Header Ext" extends "Transfer Header"
{
    fields
    {
        field(18391; "Vendor No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(18392; "Bill Of Entry No."; Text[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Bill Of Entry No.';
        }
        field(18393; "Bill Of Entry Date"; Date)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Bill Of Entry Date';
        }
        field(18394; "Vendor Invoice No."; code[20])
        {
            Caption = 'Vendor Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18395; "Load Unreal Prof Amt on Invt."; Boolean)
        {
            Caption = 'Load Unreal Prof Amt on Invt.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18396; "Time of Removal"; Time)
        {
            Caption = 'Time of Removal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18397; "LR/RR No."; Date)
        {
            Caption = 'LR/RR No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18398; "LR/RR Date"; Date)
        {
            Caption = 'LR/RR Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18399; "Vehicle No."; Code[20])
        {
            Caption = 'Vehicle No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18400; "Mode of Transport"; text[15])
        {
            Caption = 'Mode of Transport';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18401; "Distance (Km)"; Decimal)
        {
            Caption = 'Distance (Km)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18402; "Vehicle Type"; Enum "GST Vehicle Type")
        {
            Caption = 'Vehicle Type';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}