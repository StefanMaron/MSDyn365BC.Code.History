tableextension 18009 "GST Location Ext" extends Location
{
    fields
    {
        field(18000; "GST Registration No."; code[20])
        {
            Caption = 'GST Registration No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Registration Nos." WHERE("State Code" = FIELD("State Code"));
            trigger onvalidate()
            var
                GSTRegistrationNos: Record "GST Registration Nos.";
            begin
                "GST Input Service Distributor" := FALSE;
                IF GSTRegistrationNos.GET("GST Registration No.") THEN
                    "GST Input Service Distributor" := GSTRegistrationNos."Input Service Distributor";
            end;
        }
        field(18001; "GST Input Service Distributor"; Boolean)
        {
            Caption = 'GST Input Service Distributor';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18002; "Location ARN No."; code[20])
        {
            Caption = 'Location ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18003; "Bonded warehouse"; Boolean)
        {
            Caption = 'Bonded warehouse';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18004; "Subcontracting Location"; Boolean)
        {
            Caption = 'Subcontracting Location';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18005; "Subcontractor No."; code[20])
        {
            Caption = 'Subcontractor No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = vendor;
        }
        field(18006; "Export or Deemed Export"; Boolean)
        {
            Caption = 'Export or Deemed Export';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18007; "Input Service Distributor"; Boolean)
        {
            Caption = 'Input Service Distributor';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18008; "Trading Location"; Boolean)
        {
            Caption = 'Trading Location';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18009; "Posted Dist. Invoice Nos."; code[10])
        {
            Caption = 'Posted Dist. Invoice Nos.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }
        field(18010; "Posted Dist. Cr. Memo Nos."; code[10])
        {
            Caption = 'Posted Dist. Cr. Memo Nos.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }
        field(18011; "Composition"; Boolean)
        {
            Caption = 'Composition';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18012; "Composition Type"; Enum "Composition Type")
        {
            Caption = 'Composition Type';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}