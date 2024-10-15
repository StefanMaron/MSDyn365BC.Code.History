namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;

pageextension 6481 "Serv. Cash Flow Forecast Stat." extends "Cash Flow Forecast Statistics"
{
    layout
    {
        addafter(SalesOrders)
        {
            field(ServiceOrders; Rec.CalcSourceTypeAmount("Cash Flow Source Type"::"Service Orders"))
            {
                ApplicationArea = Service;
                Caption = 'Service Orders';
                ToolTip = 'Specifies amounts related to service orders.';

                trigger OnDrillDown()
                begin
                    Rec.DrillDownSourceTypeEntries("Cash Flow Source Type"::"Service Orders");
                end;
            }
        }
    }
}