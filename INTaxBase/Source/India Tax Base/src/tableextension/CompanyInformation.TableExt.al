tableextension 18543 "CompanyInformation" extends "Company Information"
{
    fields
    {
        field(18543; "State Code"; Code[10])
        {
            TableRelation = "State";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18544; "T.A.N. No."; Code[10])
        {
            TableRelation = "TAN Nos.";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18545; "P.A.N. Status"; enum "Company P.A.N.Status")
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                PANNotReqLbl: Label 'PANNOTREQD';
            begin
                IF "P.A.N. Status" = "P.A.N. Status"::"Not available" THEN
                    "P.A.N. No." := PANNotReqLbl
                ELSE
                    "P.A.N. No." := '';
            end;
        }
        field(18546; "PAO Code"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18547; "PAO Registration No."; Code[7])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18548; "DDO Code"; Code[7])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18549; "DDO Registration No."; Code[7])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18550; "Ministry Type"; Enum "Ministry Type")
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18551; "P.A.N. No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18552; "Ministry Code"; Code[3])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF ("Ministry Type" = CONST(Others)) "Ministry" WHERE("Other Ministry" = FILTER('Yes'))
            ELSE
            IF ("Ministry Type" = CONST(Regular)) Ministry WHERE("Other Ministry" = filter('No'));
        }
        field(18553; "Deductor Category"; Code[1])
        {
            TableRelation = "Deductor Category";
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                DeductorCategory: Record "Deductor Category";
            begin
                DeductorCategory.GET("Deductor Category");
                IF NOT DeductorCategory."DDO Code Mandatory" THEN BEGIN
                    "DDO Code" := '';
                    "DDO Registration No." := '';
                END;
                IF NOT DeductorCategory."PAO Code Mandatory" THEN BEGIN
                    "PAO Code" := '';
                    "PAO Registration No." := '';
                END;
                IF NOT DeductorCategory."Ministry Details Mandatory" THEN
                    "Ministry Code" := '';
            end;
        }
        field(18554; "Company Status"; Enum "Company Status")
        {
            DataClassification = CustomerContent;
        }
    }
}