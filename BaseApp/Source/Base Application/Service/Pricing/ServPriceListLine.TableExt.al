namespace Microsoft.Pricing.Worksheet;

using Microsoft.Service.Pricing;

tableextension 6474 "Serv. Price List Line" extends "Price Worksheet Line"
{
    fields
    {
        modify("Product No.")
        {
            TableRelation = if ("Asset Type" = const("Service Cost")) "Service Cost";
        }
    }
}