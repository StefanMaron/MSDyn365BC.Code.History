table 18685 "Acknowledgement Setup"
{
    Caption = 'Acknowledgement Setup';
    DataClassification = EndUserIdentifiableInformation;
    DrillDownPageId = "Acknowledgement Setup";
    LookupPageId = "Acknowledgement Setup";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Financial Year"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnLookup()
            var
                TaxAccountingPeriod: Record "Tax Accounting Period";
            begin
                if Page.RunModal(Page::"Tax Accounting Periods", TaxAccountingPeriod) = Action::LookupOK then//AS
                    "Financial Year" := TaxAccountingPeriod."Financial Year";
            end;
        }
        field(2; Quarter; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Acknowledgment No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Location"; Code[20])
        {
            TableRelation = Location;
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Financial Year")
        {
            Clustered = true;
        }
    }
}