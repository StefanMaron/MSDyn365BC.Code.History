namespace Microsoft.Service.History;

using Microsoft.Utilities;

tableextension 6477 "Serv. Certificate of Supply" extends "Certificate of Supply"
{
    fields
    {
        modify("Document No.")
        {
            TableRelation = if ("Document Type" = filter("Service Shipment")) "Service Shipment Header"."No.";
        }
    }
}