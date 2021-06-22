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
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforePurchaseHeaderOnAfterGetRecord("Purchase Header", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                Window.Update(1, "No.");

                AllLinesDeleted := true;
                ItemChargeAssgntPurch.Reset();
                ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                ItemChargeAssgntPurch.SetRange("Document No.", "No.");
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", "Document Type");
                PurchLine.SetRange("Document No.", "No.");
                PurchLine.SetFilter("Quantity Invoiced", '<>0');
                if PurchLine.Find('-') then begin
                    PurchLine.SetRange("Quantity Invoiced");
                    PurchLine.SetFilter("Outstanding Quantity", '<>0');
                    OnAfterSetPurchLineFilters(PurchLine);
                    if not PurchLine.Find('-') then begin
                        PurchLine.SetRange("Outstanding Quantity");
                        PurchLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                        if not PurchLine.Find('-') then begin
                            PurchLine.LockTable();
                            if not PurchLine.Find('-') then begin
                                PurchLine.SetRange("Qty. Rcd. Not Invoiced");

                                ArchiveManagement.AutoArchivePurchDocument("Purchase Header");

                                if PurchLine.Find('-') then
                                    repeat
                                        PurchLine.CalcFields("Qty. Assigned");
                                        if (PurchLine."Qty. Assigned" = PurchLine."Quantity Invoiced") or
                                           (PurchLine.Type <> PurchLine.Type::"Charge (Item)")
                                        then begin
                                            if PurchLine.Type = PurchLine.Type::"Charge (Item)" then begin
                                                ItemChargeAssgntPurch.SetRange("Document Line No.", PurchLine."Line No.");
                                                ItemChargeAssgntPurch.DeleteAll();
                                            end;
                                            if PurchLine.HasLinks then
                                                PurchLine.DeleteLinks;

                                            OnBeforePurchLineDelete(PurchLine);
                                            PurchLine.Delete();
                                        end else
                                            AllLinesDeleted := false;
                                    until PurchLine.Next = 0;

                                if AllLinesDeleted then begin
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

                                    OnBeforeDeletePurchaseHeader("Purchase Header");
                                    Delete;
                                end;
                                Commit();
                            end;
                        end;
                    end;
                end;
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
        AllLinesDeleted: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
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

