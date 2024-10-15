namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;

codeunit 99000777 "Check Prod. Order Status"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'The update has been interrupted to respect the warning.';
#pragma warning restore AA0074

    procedure SalesLineCheck(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        CheckProdOrderStatus: Page "Check Prod. Order Status";
        OK: Boolean;
    begin
        if GuiAllowed then
            if CheckProdOrderStatus.SalesLineShowWarning(SalesLine) then begin
                Item.Get(SalesLine."No.");
                CheckProdOrderStatus.SetRecord(Item);
                OK := CheckProdOrderStatus.RunModal() = ACTION::Yes;
                Clear(CheckProdOrderStatus);
                if not OK then
                    Error(Text000);
            end;
    end;
}

