namespace Microsoft.Pricing.Worksheet;

using Microsoft.Service.Pricing;

tableextension 6475 "Serv. Price Worksheet Line" extends "Price Worksheet Line"
{
    fields
    {
        modify("Product No.")
        {
            TableRelation = if ("Asset Type" = const("Service Cost")) "Service Cost";
        }
    }
}