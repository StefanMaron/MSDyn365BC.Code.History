codeunit 18438 "GST Item Charge Subscribers"
{
    var
        TaxTypeSetup: Record "Tax Type Setup";
        GSTApplicationSessionMgt: Codeunit "GST Application Session Mgt.";

    local procedure GetItemChargeGSTAmount(PurchaseLine: Record "Purchase Line"; QtyFactor: Decimal) GSTAmountLoaded: Decimal;
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        if (PurchaseLine.Type = PurchaseLine.Type::"Charge (Item)") and
            (PurchaseLine."GST Credit" = PurchaseLine."GST Credit"::"Non-Availment")
        then begin
            if not TaxTypeSetup.Get() then
                exit;

            TaxTypeSetup.TestField(Code);

            TaxTransactionValue.SetRange("Tax Type", TaxTypeSetup.Code);
            TaxTransactionValue.SetRange("Tax Record ID", PurchaseLine.RecordId);
            TaxTransactionValue.SetFilter(Percent, '<>%1', 0);
            if TaxTransactionValue.FindSet() then
                repeat
                    GSTAmountLoaded += TaxTransactionValue.Amount;
                until TaxTransactionValue.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostItemChargePerOrder', '', false, false)]
    local procedure PurchPostOnBeforePostItemChargePerOrder(
        var PurchHeader: Record "Purchase Header";
        var PurchLine: Record "Purchase Line";
        var ItemJnlLine2: Record "Item Journal Line";
        var ItemChargePurchLine: Record "Purchase Line";
        var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary;
        CommitIsSupressed: Boolean;
        var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    var
        PurchaseLine: Record "Purchase Line";
        GSTAmountLoaded: Decimal;
    begin
        PurchaseLine.Get(PurchLine."Document Type", PurchLine."Document No.", TempItemChargeAssgntPurch."Document Line No.");
        GSTAmountLoaded :=
        GetItemChargeGSTAmount(PurchaseLine, (ItemChargePurchLine."Qty. to Invoice (Base)" / ItemChargePurchLine."Quantity (Base)"));
        if PurchHeader."Document Type" in [PurchHeader."Document Type"::"Credit Memo", PurchHeader."Document Type"::"Return Order"] then
            TempItemChargeAssgntPurch."Amount to Assign" -= GSTAmountLoaded * TempItemChargeAssgntPurch."Qty. to Assign"
        else
            TempItemChargeAssgntPurch."Amount to Assign" += GSTAmountLoaded * TempItemChargeAssgntPurch."Qty. to Assign";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnPostItemChargeOnBeforePostItemJnlLine', '', false, false)]
    local procedure PurchPostOnPostItemChargeOnBeforePostItemJnlLine(
        var PurchaseLineToPost: Record "Purchase Line";
        var PurchaseLine: Record "Purchase Line";
        QtyToAssign: Decimal;
        var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    var
        GSTAmountLoaded: Decimal;
    begin
        GSTAmountLoaded :=
            GetItemChargeGSTAmount(PurchaseLine, (PurchaseLine."Qty. to Invoice (Base)" / PurchaseLine."Quantity (Base)"));
        GSTApplicationSessionMgt.SetGSTAmountLoaded(GSTAmountLoaded * TempItemChargeAssgntPurch."Qty. to Assign");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnPostItemJnlLineOnAfterPrepareItemJnlLine', '', false, false)]
    local procedure PurchPostOnPostItemJnlLineOnAfterPrepareItemJnlLine(
        var ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header")
    var
        TaxTypeSetup: Record "Tax Type Setup";
        TaxTransactionValue: Record "Tax Transaction Value";
        GSTAmountLoaded: Decimal;
        Factor: Decimal;
    begin
        if (PurchaseLine.Type = PurchaseLine.Type::"Charge (Item)") and
            (PurchaseLine."GST Credit" = PurchaseLine."GST Credit"::"Non-Availment")
        then begin
            GSTAmountLoaded := GSTApplicationSessionMgt.GetGSTAmountLoaded();
            if PurchaseLine."Qty. to Invoice" <> 0 then
                Factor := (ItemJournalLine."Invoiced Quantity" / PurchaseLine."Qty. to Invoice");

            if PurchaseHeader."Document Type" in [
                PurchaseHeader."Document Type"::"Credit Memo",
                PurchaseHeader."Document Type"::"Return Order"]
            then
                ItemJournalLine.Amount := ItemJournalLine.Amount - Round(GSTAmountLoaded * Factor)
            else
                ItemJournalLine.Amount := ItemJournalLine.Amount + Round(GSTAmountLoaded * Factor);
            GSTApplicationSessionMgt.SetGSTAmountLoaded(0);
        end;
    end;
}