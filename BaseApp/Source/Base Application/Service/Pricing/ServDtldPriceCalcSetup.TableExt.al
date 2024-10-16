namespace Microsoft.Pricing.Calculation;

using Microsoft.Service.Pricing;

tableextension 6473 "Serv. Dtld. Price Calc. Setup" extends "Dtld. Price Calculation Setup"
{
    fields
    {
        modify("Product No.")
        {
            TableRelation = if ("Asset Type" = const("Service Cost")) "Service Cost";
        }
    }
}