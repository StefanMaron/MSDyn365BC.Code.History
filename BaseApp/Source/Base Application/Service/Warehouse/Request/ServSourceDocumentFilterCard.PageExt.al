namespace Microsoft.Warehouse.Request;

pageextension 6475 "Serv. SourceDocumentFilterCard" extends "Source Document Filter Card"
{
    layout
    {
        addafter("Sales Orders")
        {
            field("Service Orders"; Rec."Service Orders")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies that service lines with a Released to Ship status are retrieved by the function that gets source documents for warehouse shipment.';
            }
        }
    }
}