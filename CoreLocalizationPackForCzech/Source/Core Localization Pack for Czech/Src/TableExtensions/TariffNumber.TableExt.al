tableextension 11753 "Tariff Number CZL" extends "Tariff Number"
{
    fields
    {
        field(11765; "Statement Code CZL"; Code[10])
        {
            Caption = 'Statement Code';
            TableRelation = "Commodity CZL".Code;
            DataClassification = CustomerContent;
        }
        field(11766; "VAT Stat. UoM Code CZL"; Code[10])
        {
            Caption = 'VAT Stat. Unit of Measure Code';
            TableRelation = "Unit of Measure";
            DataClassification = CustomerContent;
        }
        field(11767; "Allow Empty UoM Code CZL"; Boolean)
        {
            Caption = 'Allow Empty Unit of Meas.Code';
            DataClassification = CustomerContent;
        }
        field(11768; "Statement Limit Code CZL"; Code[10])
        {
            Caption = 'Statement Limit Code';
            TableRelation = "Commodity CZL".Code;
            DataClassification = CustomerContent;
        }
    }
}