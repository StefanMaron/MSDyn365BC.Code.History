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
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.";
            RequestFilterHeading = 'Purchase Order';

            trigger OnAfterGetRecord()
            var
                ReservePurchLine: Codeunit "Purch. Line-Reserve";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                PostPurchDelete: Codeunit "PostPurch-Delete";
                PostCodeCheck: Codeunit "Post Code Check";
                IsHandled: Boolean;
                ItemChargeComplete: Boolean;
            begin
                IsHandled := false;
                OnBeforePurchaseHeaderOnAfterGetRecord("Purchase Header", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                Window.Update(1, "No.");

                ItemChargeAssgntPurch.Reset();
                ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                ItemChargeAssgntPurch.SetRange("Document No.", "No.");

                // Continue only if there are invoiced lines in the purchase document
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", "Document Type");
                PurchLine.SetRange("Document No.", "No.");
                PurchLine.SetFilter("Quantity Invoiced", '<>0');
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
                        if PurchLine."Qty. Assigned" <> PurchLine."Quantity Invoiced" then
                            ItemChargeComplete := false;
                    until (PurchLine.Next() = 0) or not ItemChargeComplete;

                PurchLine.SetRange(Type);
                if not ItemChargeComplete then
                    exit;

                // The purchase order can be deleted. Archive and delete the document
                // Archive the purchase document
                ArchiveManagement.AutoArchivePurchDocument("Purchase Header");
                
                // Delete lines and then the header
                PurchLine.LockTable();
                if PurchLine.Find('-') then
                    repeat
                        if PurchLine.Type = PurchLine.Type::"Charge (Item)" then begin
                            ItemChargeAssgntPurch.SetRange("Document Line No.", PurchLine."Line No.");
                            ItemChargeAssgntPurch.DeleteAll();
                        end;
                        if PurchLine.HasLinks then
                            PurchLine.DeleteLinks;

                        OnBeforePurchLineDelete(PurchLine);
                        PurchLine.Delete();
                        OnAfterPurchLineDelete(PurchLine);
                    until PurchLine.Next = 0;

                PostPurchDelete.DeleteHeader(
                "Purchase Header", PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader,
                ReturnShptHeader, PrepmtPurchInvHeader, PrepmtPurchCrMemoHeader);

                ReservePurchLine.DeleteInvoiceSpecFromHeader("Purchase Header");

                PurchCommentLine.SetRange("Document Type", "Document Type");
                PurchCommentLine.SetRange("No.", "No.");
                PurchCommentLine.DeleteAll();

                WhseRequest.SetRange("Source Type", DATABASE::"Purchase Line");
                WhseRequest.SetRange("Source Subtype", "Document Type");
                WhseRequest.SetRange("Source No.", "No.");
                if not WhseRequest.IsEmpty then
                    WhseRequest.DeleteAll(true);

                ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                if HasLinks then
                    DeleteLinks;

                PostCodeCheck.DeleteAllAddressID(
                    DATABASE::"Purchase Header", GetPosition);
                                
                OnBeforeDeletePurchaseHeader("Purchase Header");
                Delete;
                OnAfterDeletePurchaseHeader("Purchase Header");

                Commit();
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000);
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
        Text000: Label 'Processing purch. orders #1##########';
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
        Window: Dialog;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineDelete(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineDelete(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderOnAfterGetRecord(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}

