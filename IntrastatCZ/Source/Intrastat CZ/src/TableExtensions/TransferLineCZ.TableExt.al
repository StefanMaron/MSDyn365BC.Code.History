tableextension 31320 "Transfer Line CZ" extends "Transfer Line"
{
    fields
    {
        field(31300; "Statistic Indication CZ"; Code[10])
        {
            Caption = 'Statistic Indication';
            TableRelation = "Statistic Indication CZ".Code where("Tariff No." = field("Tariff No. CZL"));
        }
        modify("Tariff No. CZL")
        {
            trigger OnAfterValidate()
            begin
                if "Tariff No. CZL" <> xRec."Tariff No. CZL" then
                    "Statistic Indication CZ" := '';
            end;
        }
    }
}