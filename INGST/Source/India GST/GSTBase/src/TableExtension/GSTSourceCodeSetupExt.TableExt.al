tableextension 18012 "GST Source Code Setup Ext" extends "Source Code Setup"
{
    fields
    {
        field(18000; "Service Transfer Shipment"; code[10])
        {
            Caption = 'Service Transfer Shipment';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
        }
        field(18001; "Service Transfer Receipt"; code[10])
        {
            Caption = 'Service Transfer Receipt';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
        }
        field(18002; "GST Credit Adjustment Journal"; code[10])
        {
            Caption = 'GST Credit Adjustment Journal';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
        }
        field(18003; "GST Settlement"; Code[10])
        {
            Caption = 'GST Settlement';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
        }
        field(18004; "GST Distribution"; code[10])
        {
            Caption = 'GST Distribution';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
        }
        field(18005; "GST Liability Adjustment"; Code[10])
        {
            Caption = 'GST Liability Adjustment';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
        }
        field(18006; "GST Adjustment Journal"; Code[10])
        {
            Caption = 'GST Adjustment Journal';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
        }
    }
}