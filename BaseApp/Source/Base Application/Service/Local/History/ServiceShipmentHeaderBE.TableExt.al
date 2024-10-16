namespace Microsoft.Service.History;

tableextension 11305 "Service Shipment Header BE" extends "Service Shipment Header"
{
    fields
    {
        field(11310; "Enterprise No."; Text[50])
        {
            Caption = 'Enterprise No.';
            DataClassification = CustomerContent;
        }
    }
}