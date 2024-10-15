tableextension 18011 "GST Service Cost Ext" extends "Service Cost"
{
    fields
    {
        field(18000; "GST Group Code"; code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Group";
        }
        field(18001; "HSN/SAC Code"; code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "HSN/SAC".Code WHERE("GST Group Code" = FIELD("GST Group Code"));
        }
        field(18002; "GST Credit Availment"; Boolean)
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(18003; Exempted; boolean)
        {
            Caption = 'Exempted';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

}