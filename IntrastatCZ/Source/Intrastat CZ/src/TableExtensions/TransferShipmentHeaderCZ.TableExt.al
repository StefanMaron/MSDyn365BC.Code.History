tableextension 31350 "Transfer Shipment Header CZ" extends "Transfer Shipment Header"
{
    fields
    {
        field(31310; "Intrastat Exclude CZ"; Boolean)
        {
            Caption = 'Intrastat Exclude';
            DataClassification = CustomerContent;
        }
    }
}