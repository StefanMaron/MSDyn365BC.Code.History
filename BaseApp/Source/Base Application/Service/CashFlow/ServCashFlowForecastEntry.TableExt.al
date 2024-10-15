namespace Microsoft.Service.CashFlow;

using Microsoft.CashFlow.Forecast;
using Microsoft.Service.Document;

tableextension 6470 "Serv. Cash Flow Forecast Entry" extends "Cash Flow Forecast Entry"
{
    fields
    {
        modify("Source No.")
        {
            TableRelation = if ("Source Type" = const("Service Orders")) "Service Header"."No." where("Document Type" = const(Order));
        }
    }
}