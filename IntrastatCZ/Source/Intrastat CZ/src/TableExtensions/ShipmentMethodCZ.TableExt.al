tableextension 31324 "Shipment Method CZ" extends "Shipment Method"
{
    fields
    {
        field(31300; "Intrastat Deliv. Grp. Code CZ"; Code[10])
        {
            Caption = 'Intrastat Delivery Group Code';
            DataClassification = CustomerContent;
            TableRelation = "Intrastat Delivery Group CZ".Code;
        }
        field(31305; "Incl. Item Charges (Amt.) CZ"; Boolean)
        {
            Caption = 'Include Item Charges (Amount)';
            DataClassification = CustomerContent;
        }
    }
}