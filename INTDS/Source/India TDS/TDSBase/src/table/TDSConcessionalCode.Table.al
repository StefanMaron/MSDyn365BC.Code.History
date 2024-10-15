table 18688 "TDS Concessional Code"
{
    Caption = 'TDS Concessional Code';
    DataClassification = EndUserIdentifiableInformation;
    DrillDownPageId = "TDS Concessional Codes";
    LookupPageId = "TDS Concessional Codes";
    DataCaptionFields = "Vendor No.", "Section";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Section; Code[10])
        {
            Caption = 'Section';
            TableRelation = "Allowed Sections"."TDS Section" where("Vendor No" = Field("Vendor No."));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Concessional Code"; Code[10])
        {
            Caption = 'Concessional Code';
            TableRelation = "Concessional Code";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Certificate No."; Code[20])
        {
            Caption = 'Certificate No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "End Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                ShorterEndDateErr: Label 'End Date should not be greater than the Start Date';
            begin
                if "End Date" < "Start Date" then
                    Error(ShorterEndDateErr);
            end;
        }
    }

    keys
    {
        key(PK; "Vendor No.", Section, "Concessional Code", "Certificate No.", "Start Date", "End Date")
        {
            Clustered = true;
        }
    }
}