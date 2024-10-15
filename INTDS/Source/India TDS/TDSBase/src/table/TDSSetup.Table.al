table 18693 "TDS Setup"
{
    Caption = 'TDS Setup';
    DataClassification = EndUserIdentifiableInformation;
    Access = Public;
    Extensible = true;
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Tax Type"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Tax Type";
        }
        field(3; "TDS Nil Challan Nos."; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }
        field(4; "Nil Pay TDS Document Nos."; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}