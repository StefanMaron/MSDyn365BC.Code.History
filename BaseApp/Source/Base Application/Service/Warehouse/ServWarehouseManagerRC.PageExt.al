namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Service.Document;

pageextension 6472 "Serv. Warehouse Manager RC" extends "Warehouse Manager Role Center"
{
    actions
    {
        addafter("Return Orders1")
        {
            action("Orders2")
            {
                ApplicationArea = Service;
                Caption = 'Service Orders';
                RunObject = page "Service Orders";
            }
        }
    }
}