tableextension 11765 "Service Invoice Line CZL" extends "Service Invoice Line"
{
    fields
    {
        field(31065; "Tariff No. CZL"; Code[20])
        {
            Caption = 'Tariff No.';
            TableRelation = "Tariff Number";
            DataClassification = CustomerContent;
        }
        field(31066; "Statistic Indication CZL"; Code[10])
        {
            Caption = 'Statistic Indication';
            TableRelation = "Statistic Indication CZL".Code WHERE("Tariff No." = FIELD("Tariff No. CZL"));
            DataClassification = CustomerContent;
        }
    }
}