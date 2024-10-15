namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Comment;
using Microsoft.Purchases.History;
using Microsoft.Utilities;
using Microsoft.Warehouse.Request;
using System.Automation;

report 499 "Delete Invoiced Purch. Orders"
{
    AccessByPermission = TableData "Purchase Header" = RD;
    ApplicationArea = Suite;
    Caption = 'Delete Invoiced Purchase Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.";
            RequestFilterHeading = 'Purchase Order';

            trigger OnAfterGetRecord()
            var
                PurchLineReserve: Codeunit "Purch. Line-Reserve";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                PostPurchDelete: Codeunit "PostPurch-Delete";
                IsHandled: Boolean;
                ItemChargeComplete: Boolean;
                ShouldDeleteLinks: Boolean;
                SuppressCommit: Boolean;
            begin
                IsHandled := false;
                OnBeforePurchaseHeaderOnAfterGetRecord("Purchase Header", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    Window.Update(1, "No.");

                ItemChargeAssgntPurch.Reset();
                ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                ItemChargeAssgntPurch.SetRange("Document No.", "No.");

                // Continue only if there are invoiced lines in the purchase document
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", "Document Type");
                PurchLine.SetRange("Document No.", "No.");
                PurchLine.SetFilter("Quantity Invoiced", '<>0');
                OnAfterGetRecordPurchaseHeaderOnBeforeCheckInvoicedPurchaseLineIsEmpty(PurchLine, "Purchase Header");
                if PurchLine.IsEmpty() then
                    exit;

                // Continue only if there are no outstanding quantity to receive
                PurchLine.SetRange("Quantity Invoiced");
                PurchLine.SetFilter("Outstanding Quantity", '<>0');
                OnAfterSetPurchLineFilters(PurchLine);
                if not PurchLine.IsEmpty() then
                    exit;

                // Continue only if all lines are received and invoiced
                PurchLine.SetRange("Outstanding Quantity");
                PurchLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                if not PurchLine.IsEmpty() then
                    exit;

                // Find if there are any uninvoiced item charges
                PurchLine.SetRange("Qty. Rcd. Not Invoiced");
                ItemChargeComplete := true;
                PurchLine.SetRange(Type, PurchLine.Type::"Charge (Item)");
                if PurchLine.FindSet() then
                    repeat
                        PurchLine.CalcFields("Qty. Assigned");
                        if (PurchLine."Qty. Assigned" <> PurchLine."Quantity Invoiced") and
                           not IsPostedUnassignedItemChargeWithZeroAmount(PurchLine)
                        then
                            ItemChargeComplete := false;
                    until (PurchLine.Next() = 0) or not ItemChargeComplete;

                PurchLine.SetRange(Type);
                if not ItemChargeComplete then
                    exit;

                // The purchase order can be deleted. Archive and delete the document
                // Archive the purchase document
                IsHandled := false;
                OnBeforeAutoArchivePurchDocument("Purchase Header", IsHandled);
                if not IsHandled then
                    ArchiveManagement.AutoArchivePurchDocument("Purchase Header");

                // Delete lines and then the header
                PurchLine.LockTable();
                if PurchLine.Find('-') then
                    repeat
                        if PurchLine.Type = PurchLine.Type::"Charge (Item)" then begin
                            ItemChargeAssgntPurch.SetRange("Document Line No.", PurchLine."Line No.");
                            ItemChargeAssgntPurch.DeleteAll();
                        end;
                        ShouldDeleteLinks := PurchLine.HasLinks();
                        OnPurchaseHeaderOnAfterGetRecordOnAfterCalcShouldDeleteLinks(PurchLine, ShouldDeleteLinks);
                        if ShouldDeleteLinks then
                            PurchLine.DeleteLinks();

                        OnBeforePurchLineDelete(PurchLine);
                        PurchLine.Delete();
                        OnAfterPurchLineDelete(PurchLine);
                    until PurchLine.Next() = 0;

                PostPurchDelete.DeleteHeader(
                "Purchase Header", PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader,
                ReturnShptHeader, PrepmtPurchInvHeader, PrepmtPurchCrMemoHeader);

                PurchLineReserve.DeleteInvoiceSpecFromHeader("Purchase Header");

                PurchCommentLine.SetRange("Document Type", "Document Type");
                PurchCommentLine.SetRange("No.", "No.");
                PurchCommentLine.DeleteAll();

                WhseRequest.SetRange("Source Type", DATABASE::"Purchase Line");
                WhseRequest.SetRange("Source Subtype", "Document Type");
                WhseRequest.SetRange("Source No.", "No.");
                if not WhseRequest.IsEmpty() then
                    WhseRequest.DeleteAll(true);

                ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                IsHandled := false;
                OnPurchaseHeaderOnAfterGetRecordOnBeforeDeleteLinks("Purchase Header", IsHandled);
                if not IsHandled then
                    if HasLinks then
                        DeleteLinks();

                IsHandled := false;
                OnBeforeDeletePurchaseHeader("Purchase Header", IsHandled);
                if not IsHandled then
                    Delete();
                OnAfterDeletePurchaseHeader("Purchase Header", SuppressCommit);

                if not SuppressCommit then
                    Commit();
            end;

            trigger OnPreDataItem()
            begin
                if GuiAllowed() then
                    Window.Open(Text000Txt);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ReturnShptHeader: Record "Return Shipment Header";
        PrepmtPurchInvHeader: Record "Purch. Inv. Header";
        PrepmtPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCommentLine: Record "Purch. Comment Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        WhseRequest: Record "Warehouse Request";
        ArchiveManagement: Codeunit ArchiveManagement;

        Text000Txt: Label 'Processing purch. orders #1##########';

    protected var
        Window: Dialog;

    local procedure IsPostedUnassignedItemChargeWithZeroAmount(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        PurchaseLine.CalcFields("Qty. Assigned");
        if (PurchaseLine.Type = PurchaseLine.Type::"Charge (Item)") and
           (PurchaseLine.Quantity = PurchaseLine."Quantity Invoiced") and
           (PurchaseLine."Qty. Assigned" = 0) and
           (PurchaseLine.Amount = 0)
        then
            exit(true);

        exit(false);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineDelete(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoArchivePurchDocument(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineDelete(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderOnAfterGetRecord(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseHeaderOnAfterGetRecordOnAfterCalcShouldDeleteLinks(var PurchaseLine: Record "Purchase Line"; var ShouldDeleteLinks: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseHeaderOnAfterGetRecordOnBeforeDeleteLinks(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordPurchaseHeaderOnBeforeCheckInvoicedPurchaseLineIsEmpty(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

