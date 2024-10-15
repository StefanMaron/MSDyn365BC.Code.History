tableextension 31306 "Purch. Cr. Memo Line CZ" extends "Purch. Cr. Memo Line"
{
    fields
    {
        field(31300; "Statistic Indication CZ"; Code[10])
        {
            Caption = 'Statistic Indication';
            TableRelation = "Statistic Indication CZ".Code where("Tariff No." = field("Tariff No. CZL"));
        }
    }
}