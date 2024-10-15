#if not CLEAN22
codeunit 11200 "Requisition Subscribers"
{
    // codeunit "Req. Wksh.-Make Order"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnAfterInsertPurchOrderHeader', '', false, false)]
    local procedure OnAfterInsertPurchOrderHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseOrderHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; SpecialOrder: Boolean)
    var
        SalesHeader: Record "Sales Header";
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        if (RequisitionLine."Sales Order No." = '') or (RequisitionLine."Sales Order Line No." = 0) or (not RequisitionLine."Drop Shipment") then
            exit;

        SalesHeader.SetLoadFields("EU 3-Party Trade");
        if not SalesHeader.Get(SalesHeader."Document Type"::Order, RequisitionLine."Sales Order No.") then
            exit;

        if not FeatureKeyManagement.IsEU3PartyTradePurchaseEnabled() then
            PurchaseOrderHeader.Validate("EU 3-Party Trade", SalesHeader."EU 3-Party Trade");
    end;
}
#endif