codeunit 99000777 "Check Prod. Order Status"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'The update has been interrupted to respect the warning.';

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
                OK := CheckProdOrderStatus.RunModal = ACTION::Yes;
                Clear(CheckProdOrderStatus);
                if not OK then
                    Error(Text000);
            end;
    end;
}

