namespace Microsoft.Sales.Customer;

using Microsoft.Service.Setup;

tableextension 6466 "Serv. Ship-To Address" extends "Ship-to Address"
{
    fields
    {
        field(5900; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            DataClassification = CustomerContent;
            TableRelation = "Service Zone";
        }
    }
}