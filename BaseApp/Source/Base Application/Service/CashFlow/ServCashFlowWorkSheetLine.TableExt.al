namespace Microsoft.Service.CashFlow;

using Microsoft.CashFlow.Worksheet;
using Microsoft.Service.Document;

tableextension 6472 "Serv. Cash Flow Worksheet Line" extends "Cash Flow Worksheet Line"
{
    fields
    {
        modify("Source No.")
        {
            TableRelation = if ("Source Type" = const("Service Orders")) "Service Header"."No." where("Document Type" = const(Order));
        }
    }
}