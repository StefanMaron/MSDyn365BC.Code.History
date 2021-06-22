codeunit 90 "Purch.-Post"
{
    Permissions = TableData "Sales Header" = m,
                  TableData "Sales Line" = m,
                  TableData "Purchase Line" = imd,
                  TableData "Invoice Post. Buffer" = imd,
                  TableData "Vendor Posting Group" = imd,
                  TableData "Inventory Posting Group" = imd,
                  TableData "Sales Shipment Header" = imd,
                  TableData "Sales Shipment Line" = imd,
                  TableData "Purch. Rcpt. Header" = imd,
                  TableData "Purch. Rcpt. Line" = imd,
                  TableData "Purch. Inv. Header" = imd,
                  TableData "Purch. Inv. Line" = imd,
                  TableData "Purch. Cr. Memo Hdr." = imd,
                  TableData "Purch. Cr. Memo Line" = imd,
                  TableData "Drop Shpt. Post. Buffer" = imd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Value Entry Relation" = rid,
                  TableData "Return Shipment Header" = imd,
                  TableData "Return Shipment Line" = imd;
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchHeader: Record "Purchase Header";
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        EverythingInvoiced: Boolean;
        SavedPreviewMode: Boolean;
        SavedSuppressCommit: Boolean;
        BiggestLineNo: Integer;
        ICGenJnlLineNo: Integer;
        LineCount: Integer;
    begin
        OnBeforePostPurchaseDoc(Rec, PreviewMode, SuppressCommit, HideProgressWindow);
        if not GuiAllowed then
            LockTimeout(false);

        ValidatePostingAndDocumentDate(Rec);

        SavedPreviewMode := PreviewMode;
        SavedSuppressCommit := SuppressCommit;
        ClearAllVariables;
        PreviewMode := SavedPreviewMode;
        SuppressCommit := SavedSuppressCommit;

        GetGLSetup;
        GetCurrency("Currency Code");

        PurchSetup.Get;
        PurchHeader := Rec;
        FillTempLines(PurchHeader, TempPurchLineGlobal);

        // Header
        CheckAndUpdate(PurchHeader);

        TempDeferralHeader.DeleteAll;
        TempDeferralLine.DeleteAll;
        TempInvoicePostBuffer.DeleteAll;
        TempDropShptPostBuffer.DeleteAll;
        EverythingInvoiced := true;

        // Lines
        OnBeforePostLines(TempPurchLineGlobal, PurchHeader, PreviewMode, SuppressCommit);

        LineCount := 0;
        RoundingLineInserted := false;
        AdjustFinalInvWith100PctPrepmt(TempPurchLineGlobal);

        TempVATAmountLineRemainder.DeleteAll;
        TempPurchLineGlobal.CalcVATAmountLines(1, PurchHeader, TempPurchLineGlobal, TempVATAmountLine);

        PurchaseLinesProcessed := false;
        if TempPurchLineGlobal.FindSet then
            repeat
                ItemJnlRollRndg := false;
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(2, LineCount);

                PostPurchLine(
                  PurchHeader, TempPurchLineGlobal, TempInvoicePostBuffer, TempVATAmountLine, TempVATAmountLineRemainder,
                  TempDropShptPostBuffer, EverythingInvoiced, ICGenJnlLineNo);

                if RoundingLineInserted then
                    LastLineRetrieved := true
                else begin
                    BiggestLineNo := MAX(BiggestLineNo, TempPurchLineGlobal."Line No.");
                    LastLineRetrieved := TempPurchLineGlobal.Next = 0;
                    if LastLineRetrieved and PurchSetup."Invoice Rounding" then
                        InvoiceRounding(PurchHeader, TempPurchLineGlobal, false, BiggestLineNo);
                end;
            until LastLineRetrieved;

        OnAfterPostPurchLines(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader, WhseShip, WhseReceive, PurchaseLinesProcessed,
          SuppressCommit, EverythingInvoiced);

        if PurchHeader.IsCreditDocType then begin
            ReverseAmount(TotalPurchLine);
            ReverseAmount(TotalPurchLineLCY);
        end;

        // Post combine shipment of sales order
        PostCombineSalesOrderShipment(PurchHeader, TempDropShptPostBuffer);

        if PurchHeader.Invoice then
            PostGLAndVendor(PurchHeader, TempInvoicePostBuffer);

        if ICGenJnlLineNo > 0 then
            PostICGenJnl;

        MakeInventoryAdjustment;
        UpdateLastPostingNos(PurchHeader);

        OnRunOnBeforeFinalizePosting(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader, GenJnlPostLine, SuppressCommit);

        FinalizePosting(PurchHeader, TempDropShptPostBuffer, EverythingInvoiced);

        Rec := PurchHeader;

        if not (InvtPickPutaway or SuppressCommit) then begin
            Commit;
            UpdateAnalysisView.UpdateAll(0, true);
            UpdateItemAnalysisView.UpdateAll(0, true);
        end;

        OnAfterPostPurchaseDoc(
          Rec, GenJnlPostLine, PurchRcptHeader."No.", ReturnShptHeader."No.", PurchInvHeader."No.", PurchCrMemoHeader."No.",
          SuppressCommit);
        OnAfterPostPurchaseDocDropShipment(SalesShptHeader."No.", SuppressCommit);
    end;

    var
        NothingToPostErr: Label 'There is nothing to post.';
        DropShipmentErr: Label 'A drop shipment from a purchase order cannot be received and invoiced at the same time.';
        PostingLinesMsg: Label 'Posting lines              #2######\', Comment = 'Counter';
        PostingPurchasesAndVATMsg: Label 'Posting purchases and VAT  #3######\', Comment = 'Counter';
        PostingVendorsMsg: Label 'Posting to vendors         #4######\', Comment = 'Counter';
        PostingBalAccountMsg: Label 'Posting to bal. account    #5######', Comment = 'Counter';
        PostingLines2Msg: Label 'Posting lines         #2######', Comment = 'Counter';
        InvoiceNoMsg: Label '%1 %2 -> Invoice %3', Comment = '%1 = Document Type, %2 = Document No, %3 = Invoice No.';
        CreditMemoNoMsg: Label '%1 %2 -> Credit Memo %3', Comment = '%1 = Document Type, %2 = Document No, %3 = Credit Memo No.';
        CannotInvoiceBeforeAssocSalesOrderErr: Label 'You cannot invoice this purchase order before the associated sales orders have been invoiced. Please invoice sales order %1 before invoicing this purchase order.', Comment = '%1 = Document No.';
        ReceiptSameSignErr: Label 'must have the same sign as the receipt';
        ReceiptLinesDeletedErr: Label 'Receipt lines have been deleted.';
        CannotPurchaseResourcesErr: Label 'You cannot purchase resources.';
        PurchaseAlreadyExistsErr: Label 'Purchase %1 %2 already exists for this vendor.', Comment = '%1 = Document Type, %2 = Document No.';
        InvoiceMoreThanReceivedErr: Label 'You cannot invoice order %1 for more than you have received.', Comment = '%1 = Order No.';
        CannotPostBeforeAssosSalesOrderErr: Label 'You cannot post this purchase order before the associated sales orders have been invoiced. Post sales order %1 before posting this purchase order.', Comment = '%1 = Sales Order No.';
        ExtDocNoNeededErr: Label 'You need to enter the document number of the document from the vendor in the %1 field, so that this document stays linked to the original.', Comment = '%1 = Field caption of e.g. Vendor Invoice No.';
        VATAmountTxt: Label 'VAT Amount';
        VATRateTxt: Label '%1% VAT', Comment = '%1 = VAT Rate';
        BlanketOrderQuantityGreaterThanErr: Label 'in the associated blanket order must not be greater than %1', Comment = '%1 = Quantity';
        BlanketOrderQuantityReducedErr: Label 'in the associated blanket order must be reduced';
        ReceiveInvoiceShipErr: Label 'Please enter "Yes" in Receive and/or Invoice and/or Ship.';
        WarehouseRequiredErr: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.', Comment = '%1/%2 = Document Type, %3/%4 - Document No.,%5/%6 = Line No.';
        ReturnShipmentSamesSignErr: Label 'must have the same sign as the return shipment';
        ReturnShipmentInvoicedErr: Label 'Line %1 of the return shipment %2, which you are attempting to invoice, has already been invoiced.', Comment = '%1 = Line No., %2 = Document No.';
        ReceiptInvoicedErr: Label 'Line %1 of the receipt %2, which you are attempting to invoice, has already been invoiced.', Comment = '%1 = Line No., %2 = Document No.';
        QuantityToInvoiceGreaterErr: Label 'The quantity you are attempting to invoice is greater than the quantity in receipt %1.', Comment = '%1 = Receipt No.';
        CannotAssignMoreErr: Label 'You cannot assign more than %1 units in %2 = %3,%4 = %5,%6 = %7.', Comment = '%1 = Quantity, %2/%3 = Document Type, %4/%5 - Document No.,%6/%7 = Line No.';
        MustAssignErr: Label 'You must assign all item charges, if you invoice everything.';
        CannotAssignInvoicedErr: Label 'You cannot assign item charges to the %1 %2 = %3,%4 = %5, %6 = %7, because it has been invoiced.', Comment = '%1 = Purchase Line, %2/%3 = Document Type, %4/%5 - Document No.,%6/%7 = Line No.';
        PurchSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        TempPurchLineGlobal: Record "Purchase Line" temporary;
        JobPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        xPurchLine: Record "Purchase Line";
        PurchLineACY: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ReturnShptHeader: Record "Return Shipment Header";
        SalesShptHeader: Record "Sales Shipment Header";
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        Currency: Record Currency;
        VendLedgEntry: Record "Vendor Ledger Entry";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary;
        WhseShptHeader: Record "Warehouse Shipment Header";
        TempWhseShptHeader: Record "Warehouse Shipment Header" temporary;
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        Location: Record Location;
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecificationInv: Record "Tracking Specification" temporary;
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        Job: Record Job;
        TempICGenJnlLine: Record "Gen. Journal Line" temporary;
        TempPrepmtDeductLCYPurchLine: Record "Purchase Line" temporary;
        TempSKU: Record "Stockkeeping Unit" temporary;
        DeferralPostBuffer: Record "Deferral Posting Buffer";
        TempDeferralHeader: Record "Deferral Header" temporary;
        TempDeferralLine: Record "Deferral Line" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WhsePurchRelease: Codeunit "Whse.-Purch. Release";
        SalesPost: Codeunit "Sales-Post";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        WhsePostRcpt: Codeunit "Whse.-Post Receipt";
        WhsePostShpt: Codeunit "Whse.-Post Shipment";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        JobPostLine: Codeunit "Job Post-Line";
        ServItemMgt: Codeunit ServItemManagement;
        DeferralUtilities: Codeunit "Deferral Utilities";
        UOMMgt: Codeunit "Unit of Measure Management";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        Window: Dialog;
        Usedate: Date;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        ItemLedgShptEntryNo: Integer;
        GenJnlLineDocType: Integer;
        FALineNo: Integer;
        RoundingLineNo: Integer;
        DeferralLineNo: Integer;
        InvDefLineNo: Integer;
        RemQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoicedBase: Decimal;
        RemAmt: Decimal;
        RemDiscAmt: Decimal;
        TotalChargeAmt: Decimal;
        TotalChargeAmtLCY: Decimal;
        LastLineRetrieved: Boolean;
        RoundingLineInserted: Boolean;
        DropShipOrder: Boolean;
        GLSetupRead: Boolean;
        InvoiceGreaterThanReturnShipmentErr: Label 'The quantity you are attempting to invoice is greater than the quantity in return shipment %1.', Comment = '%1 = Return Shipment No.';
        ReturnShipmentLinesDeletedErr: Label 'Return shipment lines have been deleted.';
        InvoiceMoreThanShippedErr: Label 'You cannot invoice return order %1 for more than you have shipped.', Comment = '%1 = Order No.';
        RelatedItemLedgEntriesNotFoundErr: Label 'Related item ledger entries cannot be found.';
        ItemTrackingWrongSignErr: Label 'Item Tracking is signed wrongly.';
        ItemTrackingMismatchErr: Label 'Item Tracking does not match.';
        PostingDateNotAllowedErr: Label '%1 is not within your range of allowed posting dates.', Comment = '%1 - Posting Date field caption';
        ItemTrackQuantityMismatchErr: Label 'The %1 does not match the quantity defined in item tracking.', Comment = '%1 = Quantity';
        CannotBeGreaterThanErr: Label 'cannot be more than %1.', Comment = '%1 = Amount';
        CannotBeSmallerThanErr: Label 'must be at least %1.', Comment = '%1 = Amount';
        ItemJnlRollRndg: Boolean;
        WhseReceive: Boolean;
        WhseShip: Boolean;
        InvtPickPutaway: Boolean;
        PositiveWhseEntrycreated: Boolean;
        PrepAmountToDeductToBigErr: Label 'The total %1 cannot be more than %2.', Comment = '%1 = Prepmt Amt to Deduct, %2 = Max Amount';
        PrepAmountToDeductToSmallErr: Label 'The total %1 must be at least %2.', Comment = '%1 = Prepmt Amt to Deduct, %2 = Max Amount';
        UnpostedInvoiceDuplicateQst: Label 'An unposted invoice for order %1 exists. To avoid duplicate postings, delete order %1 or invoice %2.\Do you still want to post order %1?', Comment = '%1 = Order No.,%2 = Invoice No.';
        InvoiceDuplicateInboxQst: Label 'An invoice for order %1 exists in the IC inbox. To avoid duplicate postings, cancel invoice %2 in the IC inbox.\Do you still want to post order %1?', Comment = '%1 = Order No.';
        PostedInvoiceDuplicateQst: Label 'Posted invoice %1 already exists for order %2. To avoid duplicate postings, do not post order %2.\Do you still want to post order %2?', Comment = '%1 = Invoice No., %2 = Order No.';
        OrderFromSameTransactionQst: Label 'Order %1 originates from the same IC transaction as invoice %2. To avoid duplicate postings, delete order %1 or invoice %2.\Do you still want to post invoice %2?', Comment = '%1 = Order No., %2 = Invoice No.';
        DocumentFromSameTransactionQst: Label 'A document originating from the same IC transaction as document %1 exists in the IC inbox. To avoid duplicate postings, cancel document %2 in the IC inbox.\Do you still want to post document %1?', Comment = '%1 and %2 = Document No.';
        PostedInvoiceFromSameTransactionQst: Label 'Posted invoice %1 originates from the same IC transaction as invoice %2. To avoid duplicate postings, do not post invoice %2.\Do you still want to post invoice %2?', Comment = '%1 and %2 = Invoice No.';
        MustAssignItemChargeErr: Label 'You must assign item charge %1 if you want to invoice it.', Comment = '%1 = Item Charge No.';
        CannotInvoiceItemChargeErr: Label 'You can not invoice item charge %1 because there is no item ledger entry to assign it to.', Comment = '%1 = Item Charge No.';
        PurchaseLinesProcessed: Boolean;
        ReservationDisruptedQst: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment. Do you want to continue?', Comment = 'One or more reservation entries exist for the item with No. = 1000, Location Code = SILVER, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
        ReassignItemChargeErr: Label 'The order line that the item charge was originally assigned to has been fully posted. You must reassign the item charge to the posted receipt or shipment.';
        PreviewMode: Boolean;
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        MixedDerpFAUntilPostingDateErr: Label 'The value in the Depr. Until FA Posting Date field must be the same on lines for the same fixed asset %1.', Comment = '%1 - Fixed Asset No.';
        CannotPostSameMultipleFAWhenDeprBookValueZeroErr: Label 'You cannot select the Depr. Until FA Posting Date check box because there is no previous acquisition entry for fixed asset %1.\\If you want to depreciate new acquisitions, you can select the Depr. Acquisition Cost check box instead.', Comment = '%1 - Fixed Asset No.';
        PostingPreviewNoTok: Label '***', Locked = true;
        InvPickExistsErr: Label 'One or more related inventory picks must be registered before you can post the shipment.';
        InvPutAwayExistsErr: Label 'One or more related inventory put-aways must be registered before you can post the receipt.';
        SuppressCommit: Boolean;
        CheckPurchHeaderMsg: Label 'Check purchase document fields.';
        HideProgressWindow: Boolean;

    procedure CopyToTempLines(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        OnCopyToTempLinesOnAfterSetFilters(PurchLine, PurchHeader);
        if PurchLine.FindSet then
            repeat
                TempPurchLine := PurchLine;
                TempPurchLine.Insert;
            until PurchLine.Next = 0;
    end;

    procedure FillTempLines(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    begin
        TempPurchLine.Reset;
        if TempPurchLine.IsEmpty then
            CopyToTempLines(PurchHeader, TempPurchLine);
    end;

    local procedure ModifyTempLine(var TempPurchLineLocal: Record "Purchase Line" temporary)
    var
        PurchLine: Record "Purchase Line";
    begin
        TempPurchLineLocal.Modify;
        PurchLine.Get(TempPurchLineLocal.RecordId);
        PurchLine.TransferFields(TempPurchLineLocal, false);
        PurchLine.Modify;
    end;

    procedure RefreshTempLines(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    begin
        TempPurchLine.Reset;
        TempPurchLine.SetRange("Prepayment Line", false);
        TempPurchLine.DeleteAll;
        TempPurchLine.Reset;
        CopyToTempLines(PurchHeader, TempPurchLine);
    end;

    local procedure ResetTempLines(var TempPurchLineLocal: Record "Purchase Line" temporary)
    begin
        TempPurchLineLocal.Reset;
        TempPurchLineLocal.Copy(TempPurchLineGlobal, true);

        OnAfterResetTempLines(TempPurchLineGlobal);
    end;

    local procedure CalcInvoice(var PurchHeader: Record "Purchase Header") NewInvoice: Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        with PurchHeader do begin
            ResetTempLines(TempPurchLine);
            TempPurchLine.SetFilter(Quantity, '<>0');
            if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                TempPurchLine.SetFilter("Qty. to Invoice", '<>0');
            NewInvoice := not TempPurchLine.IsEmpty;
            if NewInvoice then
                case "Document Type" of
                    "Document Type"::Order:
                        if not Receive then begin
                            TempPurchLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                            NewInvoice := not TempPurchLine.IsEmpty;
                        end;
                    "Document Type"::"Return Order":
                        if not Ship then begin
                            TempPurchLine.SetFilter("Return Qty. Shipped Not Invd.", '<>0');
                            NewInvoice := not TempPurchLine.IsEmpty;
                        end;
                end;
        end;
        exit(NewInvoice);
    end;

    local procedure CalcInvDiscount(var PurchHeader: Record "Purchase Header")
    var
        PurchaseHeaderCopy: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        with PurchHeader do begin
            if not (PurchSetup."Calc. Inv. Discount" and (Status <> Status::Open)) then
                exit;

            PurchaseHeaderCopy := PurchHeader;
            PurchLine.Reset;
            PurchLine.SetRange("Document Type", "Document Type");
            PurchLine.SetRange("Document No.", "No.");
            OnCalcInvDiscountSetFilter(PurchLine, PurchHeader);
            PurchLine.FindFirst;
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
            RefreshTempLines(PurchHeader, TempPurchLineGlobal);
            Get("Document Type", "No.");
            RestorePurchaseHeader(PurchHeader, PurchaseHeaderCopy);
            if not (PreviewMode or SuppressCommit) then
                Commit;
        end;
        exit;
    end;

    local procedure RestorePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PurchaseHeaderCopy: Record "Purchase Header")
    begin
        with PurchaseHeader do begin
            Invoice := PurchaseHeaderCopy.Invoice;
            Receive := PurchaseHeaderCopy.Receive;
            Ship := PurchaseHeaderCopy.Ship;
            "Posting No." := PurchaseHeaderCopy."Posting No.";
            "Receiving No." := PurchaseHeaderCopy."Receiving No.";
            "Return Shipment No." := PurchaseHeaderCopy."Return Shipment No.";
        end;

        OnAfterRestorePurchaseHeader(PurchaseHeader, PurchaseHeaderCopy);
    end;

    local procedure CheckAndUpdate(var PurchHeader: Record "Purchase Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        CheckDimensions: Codeunit "Check Dimensions";
        ErrorContextElement: Codeunit "Error Context Element";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        SetupRecID: RecordID;
        ModifyHeader: Boolean;
        RefreshTempLinesNeeded: Boolean;
    begin
        with PurchHeader do begin
            // Check
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, CheckPurchHeaderMsg);
            CheckMandatoryHeaderFields(PurchHeader);
            if GenJnlCheckLine.IsDateNotAllowed("Posting Date", SetupRecID) then
                ErrorMessageMgt.LogContextFieldError(
                  FieldNo("Posting Date"), StrSubstNo(PostingDateNotAllowedErr, FieldCaption("Posting Date")),
                  SetupRecID, ErrorMessageMgt.GetFieldNo(SetupRecID.TableNo, GLSetup.FieldName("Allow Posting From")),
                  ForwardLinkMgt.GetHelpCodeForAllowedPostingDate);

            SetPostingFlags(PurchHeader);
            OnCheckAndUpdateOnAfterSetPostingFlags(PurchHeader, TempPurchLineGlobal);

            InitProgressWindow(PurchHeader);

            InvtPickPutaway := "Posting from Whse. Ref." <> 0;
            "Posting from Whse. Ref." := 0;

            CheckDimensions.CheckPurchDim(PurchHeader, TempPurchLineGlobal);

            if Invoice then
                CheckFAPostingPossibility(PurchHeader);

            CheckPostRestrictions(PurchHeader);

            CheckICDocumentDuplicatePosting(PurchHeader);

            if Invoice then
                Invoice := CalcInvoice(PurchHeader);

            if Invoice then
                CopyAndCheckItemCharge(PurchHeader);

            if Invoice and not IsCreditDocType then
                TestField("Due Date");

            if Receive then begin
                Receive := CheckTrackingAndWarehouseForReceive(PurchHeader);
                if not InvtPickPutaway then
                    if CheckIfInvPutawayExists(PurchHeader) then
                        Error(InvPutAwayExistsErr);
            end;

            if Ship then begin
                Ship := CheckTrackingAndWarehouseForShip(PurchHeader);
                if not InvtPickPutaway then
                    if CheckIfInvPickExists then
                        Error(InvPickExistsErr);
            end;

            if not (Receive or Invoice or Ship) then
                Error(NothingToPostErr);

            CheckAssociatedOrderLines(PurchHeader);

            if Invoice and PurchSetup."Ext. Doc. No. Mandatory" then
                CheckExtDocNo(PurchHeader);

            OnAfterCheckPurchDoc(PurchHeader, SuppressCommit, WhseShip, WhseReceive);
            ErrorMessageMgt.Finish(RecordId);

            // Update
            if Invoice then
                CreatePrepmtLines(PurchHeader, true);

            ModifyHeader := UpdatePostingNos(PurchHeader);

            DropShipOrder := UpdateAssosOrderPostingNos(PurchHeader);

            OnBeforePostCommitPurchaseDoc(PurchHeader, GenJnlPostLine, PreviewMode, ModifyHeader, SuppressCommit, TempPurchLineGlobal);
            if not PreviewMode and ModifyHeader then begin
                Modify;
                if not SuppressCommit then
                    Commit;
            end;

            OnCheckAndUpdateOnBeforeCalcInvDiscount(
              PurchHeader, TempWhseRcptHeader, TempWhseShptHeader, WhseReceive, WhseShip, RefreshTempLinesNeeded);
            if RefreshTempLinesNeeded then
                RefreshTempLines(PurchHeader, TempPurchLineGlobal);
            CalcInvDiscount(PurchHeader);
            ReleasePurchDocument(PurchHeader);

            if Receive or Ship then
                ArchiveUnpostedOrder(PurchHeader);

            CheckICPartnerBlocked(PurchHeader);
            SendICDocument(PurchHeader, ModifyHeader);
            UpdateHandledICInboxTransaction(PurchHeader);

            LockTables(PurchHeader);

            SourceCodeSetup.Get;
            SrcCode := SourceCodeSetup.Purchases;

            OnCheckAndUpdateOnAfterSetSourceCode(PurchHeader, SourceCodeSetup, SrcCode);

            InsertPostedHeaders(PurchHeader);

            UpdateIncomingDocument("Incoming Document Entry No.", "Posting Date", GenJnlLineDocNo);
        end;

        OnAfterCheckAndUpdate(PurchHeader, SuppressCommit, PreviewMode);
    end;

    local procedure CheckExtDocNo(PurchaseHeader: Record "Purchase Header")
    begin
        with PurchaseHeader do
            case "Document Type" of
                "Document Type"::Order,
              "Document Type"::Invoice:
                    if "Vendor Invoice No." = '' then
                        Error(ExtDocNoNeededErr, FieldCaption("Vendor Invoice No."));
                else
                    if "Vendor Cr. Memo No." = '' then
                        Error(ExtDocNoNeededErr, FieldCaption("Vendor Cr. Memo No."));
            end;
    end;

    local procedure PostPurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var EverythingInvoiced: Boolean; var ICGenJnlLineNo: Integer)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        InvoicePostBuffer: Record "Invoice Post. Buffer";
        CostBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        with PurchLine do begin
            if Type = Type::Item then
                CostBaseAmount := "Line Amount";
            UpdateQtyPerUnitOfMeasure(PurchLine);

            TestPurchLine(PurchHeader, PurchLine);
            UpdatePurchLineBeforePost(PurchHeader, PurchLine);

            if "Qty. to Invoice" + "Quantity Invoiced" <> Quantity then
                EverythingInvoiced := false;

            OnPostPurchLineOnAfterSetEverythingInvoiced(PurchLine, EverythingInvoiced);

            if Quantity <> 0 then begin
                TestField("No.");
                TestField(Type);
                if not ApplicationAreaMgmt.IsSalesTaxEnabled then begin
                    TestField("Gen. Bus. Posting Group");
                    TestField("Gen. Prod. Posting Group");
                end;
                DivideAmount(PurchHeader, PurchLine, 1, "Qty. to Invoice", TempVATAmountLine, TempVATAmountLineRemainder);
            end else
                TestField(Amount, 0);

            CheckItemReservDisruption(PurchLine);
            RoundAmount(PurchHeader, PurchLine, "Qty. to Invoice");

            if IsCreditDocType then begin
                ReverseAmount(PurchLine);
                ReverseAmount(PurchLineACY);
            end;

            RemQtyToBeInvoiced := "Qty. to Invoice";
            RemQtyToBeInvoicedBase := "Qty. to Invoice (Base)";

            // Job Credit Memo Item Qty Check
            if IsCreditDocType then
                if ("Job No." <> '') and (Type = Type::Item) and ("Qty. to Invoice" <> 0) then
                    JobPostLine.CheckItemQuantityPurchCredit(PurchHeader, PurchLine);

            PostItemTrackingLine(PurchHeader, PurchLine);

            case Type of
                Type::"G/L Account":
                    PostGLAccICLine(PurchHeader, PurchLine, ICGenJnlLineNo);
                Type::Item:
                    PostItemLine(PurchHeader, PurchLine, TempDropShptPostBuffer);
                3:
                    PostResourceLine(PurchHeader, PurchLine);
                Type::"Charge (Item)":
                    PostItemChargeLine(PurchHeader, PurchLine);
            end;

            if (Type >= Type::"G/L Account") and ("Qty. to Invoice" <> 0) then begin
                AdjustPrepmtAmountLCY(PurchHeader, PurchLine);
                FillInvoicePostBuffer(PurchHeader, PurchLine, PurchLineACY, TempInvoicePostBuffer, InvoicePostBuffer);
                InsertPrepmtAdjInvPostingBuf(PurchHeader, PurchLine, TempInvoicePostBuffer, InvoicePostBuffer);
            end;

            IsHandled := false;
            OnPostPurchLineOnBeforeInsertReceiptLine(PurchHeader, PurchLine, IsHandled);
            if not IsHandled then
                if (PurchRcptHeader."No." <> '') and ("Receipt No." = '') and
                   not RoundingLineInserted and not "Prepayment Line"
                then
                    InsertReceiptLine(PurchRcptHeader, PurchLine, CostBaseAmount);

            IsHandled := false;
            OnPostPurchLineOnBeforeInsertReturnShipmentLine(PurchHeader, PurchLine, IsHandled);
            if not IsHandled then
                if (ReturnShptHeader."No." <> '') and ("Return Shipment No." = '') and
                   not RoundingLineInserted
                then
                    InsertReturnShipmentLine(ReturnShptHeader, PurchLine, CostBaseAmount);

            IsHandled := false;
            if PurchHeader.Invoice then
                if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
                    OnPostPurchLineOnBeforeInsertInvoiceLine(PurchHeader, PurchLine, IsHandled);
                    if not IsHandled then begin
                        PurchInvLine.InitFromPurchLine(PurchInvHeader, xPurchLine);
                        ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, CopyStr(PurchInvLine.RowID1, 1, 100));
                        if "Document Type" = "Document Type"::Order then begin
                            PurchInvLine."Order No." := "Document No.";
                            PurchInvLine."Order Line No." := "Line No.";
                        end else
                            if PurchRcptLine.Get("Receipt No.", "Receipt Line No.") then begin
                                PurchInvLine."Order No." := PurchRcptLine."Order No.";
                                PurchInvLine."Order Line No." := PurchRcptLine."Order Line No.";
                            end;
                        OnBeforePurchInvLineInsert(PurchInvLine, PurchInvHeader, PurchLine, SuppressCommit);
                        PurchInvLine.Insert(true);
                        OnAfterPurchInvLineInsert(
                            PurchInvLine, PurchInvHeader, PurchLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit);
                        CreatePostedDeferralScheduleFromPurchDoc(xPurchLine, PurchInvLine.GetDocumentType,
                            PurchInvHeader."No.", PurchInvLine."Line No.", PurchInvHeader."Posting Date");
                    end;
                end else begin // Credit Memo
                    PurchCrMemoLine.InitFromPurchLine(PurchCrMemoHeader, xPurchLine);
                    ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, CopyStr(PurchCrMemoLine.RowID1, 1, 100));
                    if "Document Type" = "Document Type"::"Return Order" then begin
                        PurchCrMemoLine."Order No." := "Document No.";
                        PurchCrMemoLine."Order Line No." := "Line No.";
                    end;
                    OnBeforePurchCrMemoLineInsert(PurchCrMemoLine, PurchCrMemoHeader, PurchLine, SuppressCommit);
                    PurchCrMemoLine.Insert(true);
                    OnAfterPurchCrMemoLineInsert(PurchCrMemoLine, PurchCrMemoHeader, PurchLine, SuppressCommit);
                    CreatePostedDeferralScheduleFromPurchDoc(xPurchLine, PurchCrMemoLine.GetDocumentType,
                      PurchCrMemoHeader."No.", PurchCrMemoLine."Line No.", PurchCrMemoHeader."Posting Date");
                end;
        end;

        OnAfterPostPurchLine(PurchHeader, PurchLine, SuppressCommit);
    end;

    local procedure PostGLAndVendor(var PurchHeader: Record "Purchase Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
        OnBeforePostGLAndVendor(PurchHeader, TempInvoicePostBuffer, PreviewMode, SuppressCommit, GenJnlPostLine);

        with PurchHeader do begin
            // Post purchase and VAT to G/L entries from buffer
            PostInvoicePostingBuffer(PurchHeader, TempInvoicePostBuffer);

            // Check External Document number
            if PurchSetup."Ext. Doc. No. Mandatory" or (GenJnlLineExtDocNo <> '') then
                CheckExternalDocumentNumber(VendLedgEntry, PurchHeader);

            // Post vendor entries
            if GuiAllowed and not HideProgressWindow then
                Window.Update(4, 1);
            PostVendorEntry(
              PurchHeader, TotalPurchLine, TotalPurchLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode);

            UpdatePurchaseHeader(VendLedgEntry);

            // Balancing account
            if "Bal. Account No." <> '' then begin
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(5, 1);
                PostBalancingEntry(
                  PurchHeader, TotalPurchLine, TotalPurchLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode);
            end;
        end;

        OnAfterPostGLAndVendor(PurchHeader, GenJnlPostLine, TotalPurchLine, TotalPurchLineLCY, SuppressCommit);
    end;

    local procedure PostGLAccICLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer)
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGLAccICLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);
        if IsHandled then
            exit;

        if (PurchLine."No." <> '') and not PurchLine."System-Created Entry" then begin
            GLAcc.Get(PurchLine."No.");
            GLAcc.TestField("Direct Posting");
            if (PurchLine."Job No." <> '') and (PurchLine."Qty. to Invoice" <> 0) then begin
                CreateJobPurchLine(JobPurchLine, PurchLine, PurchHeader."Prices Including VAT");
                JobPostLine.PostJobOnPurchaseLine(PurchHeader, PurchInvHeader, PurchCrMemoHeader, JobPurchLine, SrcCode);
            end;
            if (PurchLine."IC Partner Code" <> '') and PurchHeader.Invoice then
                InsertICGenJnlLine(PurchHeader, xPurchLine, ICGenJnlLineNo);

            OnAfterPostAccICLine(PurchLine, SuppressCommit);
        end;
    end;

    local procedure PostItemLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
    begin
        ItemLedgShptEntryNo := 0;
        with PurchHeader do begin
            if RemQtyToBeInvoiced <> 0 then
                ItemLedgShptEntryNo :=
                  PostItemJnlLine(
                    PurchHeader, PurchLine,
                    RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                    RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                    0, '', DummyTrackingSpecification);
            if IsCreditDocType then begin
                if Abs(PurchLine."Return Qty. to Ship") > Abs(RemQtyToBeInvoiced) then
                    ItemLedgShptEntryNo :=
                      PostItemJnlLine(
                        PurchHeader, PurchLine,
                        PurchLine."Return Qty. to Ship" - RemQtyToBeInvoiced,
                        PurchLine."Return Qty. to Ship (Base)" - RemQtyToBeInvoicedBase,
                        0, 0, 0, '', DummyTrackingSpecification);
            end else begin
                if Abs(PurchLine."Qty. to Receive") > Abs(RemQtyToBeInvoiced) then
                    ItemLedgShptEntryNo :=
                      PostItemJnlLine(
                        PurchHeader, PurchLine,
                        PurchLine."Qty. to Receive" - RemQtyToBeInvoiced,
                        PurchLine."Qty. to Receive (Base)" - RemQtyToBeInvoicedBase,
                        0, 0, 0, '', DummyTrackingSpecification);
                if (PurchLine."Qty. to Receive" <> 0) and (PurchLine."Sales Order Line No." <> 0) then begin
                    TempDropShptPostBuffer."Order No." := PurchLine."Sales Order No.";
                    TempDropShptPostBuffer."Order Line No." := PurchLine."Sales Order Line No.";
                    TempDropShptPostBuffer.Quantity := PurchLine."Qty. to Receive";
                    TempDropShptPostBuffer."Quantity (Base)" := PurchLine."Qty. to Receive (Base)";
                    TempDropShptPostBuffer."Item Shpt. Entry No." :=
                      PostAssocItemJnlLine(PurchHeader, PurchLine, TempDropShptPostBuffer.Quantity, TempDropShptPostBuffer."Quantity (Base)");
                    OnBeforeTempDropShptPostBufferInsert(TempDropShptPostBuffer, PurchLine);
                    TempDropShptPostBuffer.Insert;
                end;
            end;

            OnAfterPostItemLine(PurchLine, SuppressCommit, PurchHeader, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase);
        end;
    end;

    local procedure PostItemChargeLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    var
        PurchaseLineBackup: Record "Purchase Line";
    begin
        if not (PurchHeader.Invoice and (PurchLine."Qty. to Invoice" <> 0)) then
            exit;

        ItemJnlRollRndg := true;
        PurchaseLineBackup.Copy(PurchLine);
        if FindTempItemChargeAssgntPurch(PurchaseLineBackup."Line No.") then
            repeat
                OnPostItemChargeLineOnBeforePostItemCharge(TempItemChargeAssgntPurch, PurchHeader, PurchaseLineBackup);
                case TempItemChargeAssgntPurch."Applies-to Doc. Type" of
                    TempItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt:
                        begin
                            PostItemChargePerRcpt(PurchHeader, PurchaseLineBackup);
                            TempItemChargeAssgntPurch.Mark(true);
                        end;
                    TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt":
                        begin
                            PostItemChargePerTransfer(PurchHeader, PurchaseLineBackup);
                            TempItemChargeAssgntPurch.Mark(true);
                        end;
                    TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment":
                        begin
                            PostItemChargePerRetShpt(PurchHeader, PurchaseLineBackup);
                            TempItemChargeAssgntPurch.Mark(true);
                        end;
                    TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment":
                        begin
                            PostItemChargePerSalesShpt(PurchHeader, PurchaseLineBackup);
                            TempItemChargeAssgntPurch.Mark(true);
                        end;
                    TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt":
                        begin
                            PostItemChargePerRetRcpt(PurchHeader, PurchaseLineBackup);
                            TempItemChargeAssgntPurch.Mark(true);
                        end;
                    TempItemChargeAssgntPurch."Applies-to Doc. Type"::Order,
                  TempItemChargeAssgntPurch."Applies-to Doc. Type"::Invoice,
                  TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Order",
                  TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Credit Memo":
                        CheckItemCharge(TempItemChargeAssgntPurch);
                end;
            until TempItemChargeAssgntPurch.Next = 0;
    end;

    local procedure PostItemTrackingLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TrackingSpecificationExists: Boolean;
    begin
        if PurchLine."Prepayment Line" then
            exit;

        if PurchHeader.Invoice then
            if PurchLine."Qty. to Invoice" = 0 then
                TrackingSpecificationExists := false
            else
                TrackingSpecificationExists :=
                  ReservePurchLine.RetrieveInvoiceSpecification(PurchLine, TempTrackingSpecification);

        PostItemTracking(PurchHeader, PurchLine, TempTrackingSpecification, TrackingSpecificationExists);

        if TrackingSpecificationExists then
            SaveInvoiceSpecification(TempTrackingSpecification);

        OnAfterPostItemTrackingLine(PurchHeader, PurchLine, WhseReceive, WhseShip, InvtPickPutaway);
    end;

    local procedure PostItemJnlLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; QtyToBeReceived: Decimal; QtyToBeReceivedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; ItemLedgShptEntryNo: Integer; ItemChargeNo: Code[20]; TrackingSpecification: Record "Tracking Specification"): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        OriginalItemJnlLine: Record "Item Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        TempReservationEntry: Record "Reservation Entry" temporary;
        Factor: Decimal;
        PostWhseJnlLine: Boolean;
        CheckApplToItemEntry: Boolean;
        PostJobConsumptionBeforePurch: Boolean;
        IsHandled: Boolean;
    begin
        if not ItemJnlRollRndg then begin
            RemAmt := 0;
            RemDiscAmt := 0;
        end;

        OnBeforePostItemJnlLine(
          PurchHeader, PurchLine, QtyToBeReceived, QtyToBeReceivedBase, QtyToBeInvoiced, QtyToBeInvoicedBase,
          ItemLedgShptEntryNo, ItemChargeNo, TrackingSpecification, SuppressCommit);

        with ItemJnlLine do begin
            Init;
            CopyFromPurchHeader(PurchHeader);
            CopyFromPurchLine(PurchLine);

            PostItemJnlLineCopyDocumentFields(ItemJnlLine, PurchHeader, PurchLine, QtyToBeInvoiced, QtyToBeReceived);

            if QtyToBeInvoiced <> 0 then
                "Invoice No." := GenJnlLineDocNo;

            CopyTrackingFromSpec(TrackingSpecification);
            "Item Shpt. Entry No." := ItemLedgShptEntryNo;

            Quantity := QtyToBeReceived;
            "Quantity (Base)" := QtyToBeReceivedBase;
            "Invoiced Quantity" := QtyToBeInvoiced;
            "Invoiced Qty. (Base)" := QtyToBeInvoicedBase;

            if ItemChargeNo <> '' then begin
                "Item Charge No." := ItemChargeNo;
                PurchLine."Qty. to Invoice" := QtyToBeInvoiced;
                OnPostItemJnlLineOnAfterCopyItemCharge(ItemJnlLine, TempItemChargeAssgntPurch);
            end;

            if QtyToBeInvoiced <> 0 then begin
                if (QtyToBeInvoicedBase <> 0) and (PurchLine.Type = PurchLine.Type::Item) then
                    Factor := QtyToBeInvoicedBase / PurchLine."Qty. to Invoice (Base)"
                else
                    Factor := QtyToBeInvoiced / PurchLine."Qty. to Invoice";
                OnPostItemJnlLineOnAfterSetFactor(PurchLine, Factor);
                Amount := PurchLine.Amount * Factor + RemAmt;
                if PurchHeader."Prices Including VAT" then
                    "Discount Amount" :=
                      (PurchLine."Line Discount Amount" + PurchLine."Inv. Discount Amount") /
                      (1 + PurchLine."VAT %" / 100) * Factor + RemDiscAmt
                else
                    "Discount Amount" :=
                      (PurchLine."Line Discount Amount" + PurchLine."Inv. Discount Amount") * Factor + RemDiscAmt;
                RemAmt := Amount - Round(Amount);
                RemDiscAmt := "Discount Amount" - Round("Discount Amount");
                Amount := Round(Amount);
                "Discount Amount" := Round("Discount Amount");
            end else begin
                if PurchHeader."Prices Including VAT" then
                    Amount :=
                      (QtyToBeReceived * PurchLine."Direct Unit Cost" * (1 - PurchLine."Line Discount %" / 100) /
                       (1 + PurchLine."VAT %" / 100)) + RemAmt
                else
                    Amount :=
                      (QtyToBeReceived * PurchLine."Direct Unit Cost" * (1 - PurchLine."Line Discount %" / 100)) + RemAmt;
                RemAmt := Amount - Round(Amount);
                if PurchHeader."Currency Code" <> '' then
                    Amount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          PurchHeader."Posting Date", PurchHeader."Currency Code",
                          Amount, PurchHeader."Currency Factor"))
                else
                    Amount := Round(Amount);
            end;

            OnPostItemJnlLineOnAfterPrepareItemJnlLine(ItemJnlLine, PurchLine, PurchHeader);

            if PurchLine."Prod. Order No." <> '' then
                PostItemJnlLineCopyProdOrder(PurchLine, ItemJnlLine, QtyToBeReceived, QtyToBeInvoiced);

            CheckApplToItemEntry := SetCheckApplToItemEntry(PurchLine);

            PostWhseJnlLine := ShouldPostWhseJnlLine(PurchLine, ItemJnlLine, TempWhseJnlLine);

            if QtyToBeReceivedBase <> 0 then begin
                if PurchLine.IsCreditDocType then
                    ReservePurchLine.TransferPurchLineToItemJnlLine(
                      PurchLine, ItemJnlLine, -QtyToBeReceivedBase, CheckApplToItemEntry)
                else
                    ReservePurchLine.TransferPurchLineToItemJnlLine(
                      PurchLine, ItemJnlLine, QtyToBeReceivedBase, CheckApplToItemEntry);

                if CheckApplToItemEntry and PurchLine.IsInventoriableItem then
                    PurchLine.TestField("Appl.-to Item Entry");
            end;

            CollectPurchaseLineReservEntries(TempReservationEntry, ItemJnlLine);
            OriginalItemJnlLine := ItemJnlLine;

            TempHandlingSpecification.Reset;
            TempHandlingSpecification.DeleteAll;

            IsHandled := false;
            OnBeforeItemJnlPostLine(ItemJnlLine, PurchLine, PurchHeader, SuppressCommit, IsHandled, WhseRcptHeader, WhseShptHeader);
            if not IsHandled then
                if PurchLine."Job No." <> '' then begin
                    PostJobConsumptionBeforePurch := IsPurchaseReturn;
                    if PostJobConsumptionBeforePurch then
                        PostItemJnlLineJobConsumption(
                          PurchHeader, PurchLine, OriginalItemJnlLine, TempReservationEntry, QtyToBeInvoiced, QtyToBeReceived,
                          TempHandlingSpecification, 0);
                end;

            ItemJnlPostLine.RunWithCheck(ItemJnlLine);

            if not Subcontracting then
                PostItemJnlLineTracking(
                  PurchLine, TempWhseTrackingSpecification, TempTrackingSpecificationChargeAssmt, PostWhseJnlLine, QtyToBeInvoiced);

            OnBeforePostItemJnlLineJobConsumption(
              ItemJnlLine, PurchLine, PurchInvHeader, PurchCrMemoHeader, QtyToBeInvoiced, QtyToBeInvoicedBase, SrcCode);

            if PurchLine."Job No." <> '' then
                if not PostJobConsumptionBeforePurch then
                    PostItemJnlLineJobConsumption(
                      PurchHeader, PurchLine, OriginalItemJnlLine, TempReservationEntry, QtyToBeInvoiced, QtyToBeReceived,
                      TempHandlingSpecification, "Item Shpt. Entry No.");

            if PostWhseJnlLine then begin
                PostItemJnlLineWhseLine(TempWhseJnlLine, TempWhseTrackingSpecification, PurchLine, PostJobConsumptionBeforePurch);
                OnAfterPostWhseJnlLine(PurchLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit);
            end;
            if (PurchLine.Type = PurchLine.Type::Item) and PurchHeader.Invoice then
                PostItemJnlLineItemCharges(
                  PurchHeader, PurchLine, OriginalItemJnlLine, "Item Shpt. Entry No.", TempTrackingSpecificationChargeAssmt);
        end;

        OnAfterPostItemJnlLine(ItemJnlLine, PurchLine, PurchHeader, ItemJnlPostLine);

        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostItemJnlLineCopyDocumentFields(var ItemJnlLine: Record "Item Journal Line"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; QtyToBeInvoiced: Decimal; QtyToBeReceived: Decimal)
    begin
        OnPostItemJnlLineOnBeforeCopyDocumentFields(ItemJnlLine, PurchHeader, PurchLine, WhseReceive, WhseShip, InvtPickPutaway);

        with ItemJnlLine do
            if QtyToBeReceived = 0 then
                if PurchLine.IsCreditDocType then
                    CopyDocumentFields(
                      "Document Type"::"Purchase Credit Memo", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series")
                else
                    CopyDocumentFields(
                      "Document Type"::"Purchase Invoice", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series")
            else begin
                if PurchLine.IsCreditDocType then
                    CopyDocumentFields(
                      "Document Type"::"Purchase Return Shipment",
                      ReturnShptHeader."No.", ReturnShptHeader."Vendor Authorization No.", SrcCode, ReturnShptHeader."No. Series")
                else
                    CopyDocumentFields(
                      "Document Type"::"Purchase Receipt",
                      PurchRcptHeader."No.", PurchRcptHeader."Vendor Shipment No.", SrcCode, PurchRcptHeader."No. Series");
                if QtyToBeInvoiced <> 0 then begin
                    if "Document No." = '' then
                        if PurchLine."Document Type" = PurchLine."Document Type"::"Credit Memo" then
                            CopyDocumentFields(
                              "Document Type"::"Purchase Credit Memo", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series")
                        else
                            CopyDocumentFields(
                              "Document Type"::"Purchase Invoice", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series");
                end;
            end;

        OnPostItemJnlLineOnAfterCopyDocumentFields(ItemJnlLine, PurchLine, TempWhseRcptHeader, TempWhseShptHeader);
    end;

    local procedure PostItemJnlLineCopyProdOrder(PurchLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeReceived: Decimal; QtyToBeInvoiced: Decimal)
    begin
        with PurchLine do begin
            ItemJnlLine.Subcontracting := true;
            ItemJnlLine."Quantity (Base)" := CalcBaseQty("No.", "Unit of Measure Code", QtyToBeReceived);
            ItemJnlLine."Invoiced Qty. (Base)" := CalcBaseQty("No.", "Unit of Measure Code", QtyToBeInvoiced);
            ItemJnlLine."Unit Cost" := "Unit Cost (LCY)";
            ItemJnlLine."Unit Cost (ACY)" := "Unit Cost";
            ItemJnlLine."Output Quantity (Base)" := ItemJnlLine."Quantity (Base)";
            ItemJnlLine."Output Quantity" := QtyToBeReceived;
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Output;
            ItemJnlLine.Type := ItemJnlLine.Type::"Work Center";
            ItemJnlLine."No." := "Work Center No.";
            ItemJnlLine."Routing No." := "Routing No.";
            ItemJnlLine."Routing Reference No." := "Routing Reference No.";
            ItemJnlLine."Operation No." := "Operation No.";
            ItemJnlLine."Work Center No." := "Work Center No.";
            ItemJnlLine."Unit Cost Calculation" := ItemJnlLine."Unit Cost Calculation"::Units;
            if Finished then
                ItemJnlLine.Finished := Finished;
        end;
        OnAfterPostItemJnlLineCopyProdOrder(ItemJnlLine, PurchLine, PurchRcptHeader, QtyToBeReceived, SuppressCommit);
    end;

    local procedure PostItemJnlLineItemCharges(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var OriginalItemJnlLine: Record "Item Journal Line"; ItemShptEntryNo: Integer; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary)
    var
        ItemChargePurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            ClearItemChargeAssgntFilter;
            TempItemChargeAssgntPurch.SetCurrentKey(
              "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
            TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", "Document Type");
            TempItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", "Document No.");
            TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", "Line No.");
            if TempItemChargeAssgntPurch.Find('-') then
                repeat
                    TestField("Allow Item Charge Assignment");
                    GetItemChargeLine(PurchHeader, ItemChargePurchLine);
                    ItemChargePurchLine.CalcFields("Qty. Assigned");
                    if (ItemChargePurchLine."Qty. to Invoice" <> 0) or
                       (Abs(ItemChargePurchLine."Qty. Assigned") < Abs(ItemChargePurchLine."Quantity Invoiced"))
                    then begin
                        OriginalItemJnlLine."Item Shpt. Entry No." := ItemShptEntryNo;
                        PostItemChargePerOrder(
                          PurchHeader, PurchLine, OriginalItemJnlLine, ItemChargePurchLine, TempTrackingSpecificationChargeAssmt);
                        TempItemChargeAssgntPurch.Mark(true);
                    end;
                until TempItemChargeAssgntPurch.Next = 0;
        end;
    end;

    local procedure PostItemJnlLineTracking(PurchLine: Record "Purchase Line"; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary; PostWhseJnlLine: Boolean; QtyToBeInvoiced: Decimal)
    begin
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) then
            if TempHandlingSpecification.Find('-') then
                repeat
                    TempTrackingSpecification := TempHandlingSpecification;
                    TempTrackingSpecification.SetSourceFromPurchLine(PurchLine);
                    if TempTrackingSpecification.Insert then;
                    if QtyToBeInvoiced <> 0 then begin
                        TempTrackingSpecificationInv := TempTrackingSpecification;
                        if TempTrackingSpecificationInv.Insert then;
                    end;
                    if PostWhseJnlLine then begin
                        TempWhseTrackingSpecification := TempTrackingSpecification;
                        if TempWhseTrackingSpecification.Insert then;
                    end;
                    TempTrackingSpecificationChargeAssmt := TempTrackingSpecification;
                    TempTrackingSpecificationChargeAssmt.Insert;
                until TempHandlingSpecification.Next = 0;
    end;

    local procedure PostItemJnlLineWhseLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; PurchLine: Record "Purchase Line"; PostBefore: Boolean)
    var
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
    begin
        ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempWhseTrackingSpecification, false);
        if TempWhseJnlLine2.Find('-') then
            repeat
                if PurchLine.IsCreditDocType and (PurchLine.Quantity > 0) or
                   PurchLine.IsInvoiceDocType and (PurchLine.Quantity < 0)
                then
                    CreatePositiveEntry(TempWhseJnlLine2, PurchLine."Job No.", PostBefore);
                WhseJnlPostLine.Run(TempWhseJnlLine2);
                if RevertWarehouseEntry(TempWhseJnlLine2, PurchLine."Job No.", PostBefore) then
                    WhseJnlPostLine.Run(TempWhseJnlLine2);
            until TempWhseJnlLine2.Next = 0;
        TempWhseTrackingSpecification.DeleteAll;
    end;

    local procedure ShouldPostWhseJnlLine(PurchLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldPostWhseJnlLine(PurchLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with PurchLine do
            if ("Location Code" <> '') and (Type = Type::Item) and (ItemJnlLine.Quantity <> 0) and
               not ItemJnlLine.Subcontracting
            then begin
                GetLocation("Location Code");
                if (("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and
                    Location."Directed Put-away and Pick") or
                   (Location."Bin Mandatory" and not (WhseReceive or WhseShip or InvtPickPutaway or "Drop Shipment"))
                then begin
                    CreateWhseJnlLine(ItemJnlLine, PurchLine, TempWhseJnlLine);
                    exit(true);
                end;
            end;
    end;

    local procedure PostItemChargePerOrder(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; ItemJnlLine2: Record "Item Journal Line"; ItemChargePurchLine: Record "Purchase Line"; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary)
    var
        NonDistrItemJnlLine: Record "Item Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
        OriginalAmt: Decimal;
        OriginalAmtACY: Decimal;
        OriginalDiscountAmt: Decimal;
        OriginalQty: Decimal;
        QtyToInvoice: Decimal;
        Factor: Decimal;
        TotalChargeAmt2: Decimal;
        TotalChargeAmtLCY2: Decimal;
        SignFactor: Integer;
    begin
        OnBeforePostItemChargePerOrder(
          PurchHeader, PurchLine, ItemJnlLine2, ItemChargePurchLine, TempTrackingSpecificationChargeAssmt, SuppressCommit,
          TempItemChargeAssgntPurch);

        with TempItemChargeAssgntPurch do begin
            PurchLine.TestField("Allow Item Charge Assignment", true);
            ItemJnlLine2."Document No." := GenJnlLineDocNo;
            ItemJnlLine2."External Document No." := GenJnlLineExtDocNo;
            ItemJnlLine2."Item Charge No." := "Item Charge No.";
            ItemJnlLine2.Description := ItemChargePurchLine.Description;
            ItemJnlLine2."Document Line No." := ItemChargePurchLine."Line No.";
            ItemJnlLine2."Unit of Measure Code" := '';
            ItemJnlLine2."Qty. per Unit of Measure" := 1;
            if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                QtyToInvoice :=
                  CalcQtyToInvoice(PurchLine."Return Qty. to Ship (Base)", PurchLine."Qty. to Invoice (Base)")
            else
                QtyToInvoice :=
                  CalcQtyToInvoice(PurchLine."Qty. to Receive (Base)", PurchLine."Qty. to Invoice (Base)");
            if ItemJnlLine2."Invoiced Quantity" = 0 then begin
                ItemJnlLine2."Invoiced Quantity" := ItemJnlLine2.Quantity;
                ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
            end;
            ItemJnlLine2.Amount := "Amount to Assign" * ItemJnlLine2."Invoiced Qty. (Base)" / QtyToInvoice;
            if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                ItemJnlLine2.Amount := -ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost (ACY)" :=
              Round(
                ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                Currency."Unit-Amount Rounding Precision");

            TotalChargeAmt2 := TotalChargeAmt2 + ItemJnlLine2.Amount;
            if PurchHeader."Currency Code" <> '' then
                ItemJnlLine2.Amount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, PurchHeader."Currency Code", TotalChargeAmt2 + TotalPurchLine.Amount, PurchHeader."Currency Factor") -
                  TotalChargeAmtLCY2 - TotalPurchLineLCY.Amount
            else
                ItemJnlLine2.Amount := TotalChargeAmt2 - TotalChargeAmtLCY2;

            TotalChargeAmtLCY2 := TotalChargeAmtLCY2 + ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost" := Round(
                ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)", GLSetup."Unit-Amount Rounding Precision");
            ItemJnlLine2."Applies-to Entry" := ItemJnlLine2."Item Shpt. Entry No.";
            ItemJnlLine2."Overhead Rate" := 0;

            if PurchHeader."Currency Code" <> '' then
                ItemJnlLine2."Discount Amount" := Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code", (ItemChargePurchLine."Inv. Discount Amount" +
                                                           ItemChargePurchLine."Line Discount Amount") *
                      ItemJnlLine2."Invoiced Qty. (Base)" /
                      ItemChargePurchLine."Quantity (Base)" * "Qty. to Assign" / QtyToInvoice,
                      PurchHeader."Currency Factor"), GLSetup."Amount Rounding Precision")
            else
                ItemJnlLine2."Discount Amount" := Round(
                    (ItemChargePurchLine."Line Discount Amount" + ItemChargePurchLine."Inv. Discount Amount") *
                    ItemJnlLine2."Invoiced Qty. (Base)" /
                    ItemChargePurchLine."Quantity (Base)" * "Qty. to Assign" / QtyToInvoice,
                    GLSetup."Amount Rounding Precision");

            ItemJnlLine2."Shortcut Dimension 1 Code" := ItemChargePurchLine."Shortcut Dimension 1 Code";
            ItemJnlLine2."Shortcut Dimension 2 Code" := ItemChargePurchLine."Shortcut Dimension 2 Code";
            ItemJnlLine2."Dimension Set ID" := ItemChargePurchLine."Dimension Set ID";
            ItemJnlLine2."Gen. Prod. Posting Group" := ItemChargePurchLine."Gen. Prod. Posting Group";

            OnPostItemChargePerOrderOnAfterCopyToItemJnlLine(
              ItemJnlLine2, ItemChargePurchLine, GLSetup, QtyToInvoice, TempItemChargeAssgntPurch);
        end;

        with TempTrackingSpecificationChargeAssmt do begin
            Reset;
            SetRange("Source Type", DATABASE::"Purchase Line");
            SetRange("Source ID", TempItemChargeAssgntPurch."Applies-to Doc. No.");
            SetRange("Source Ref. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
            if IsEmpty then
                ItemJnlPostLine.RunWithCheck(ItemJnlLine2)
            else begin
                FindSet;
                NonDistrItemJnlLine := ItemJnlLine2;
                OriginalAmt := NonDistrItemJnlLine.Amount;
                OriginalAmtACY := NonDistrItemJnlLine."Amount (ACY)";
                OriginalDiscountAmt := NonDistrItemJnlLine."Discount Amount";
                OriginalQty := NonDistrItemJnlLine."Quantity (Base)";
                if ("Quantity (Base)" / OriginalQty) > 0 then
                    SignFactor := 1
                else
                    SignFactor := -1;
                repeat
                    Factor := "Quantity (Base)" / OriginalQty * SignFactor;
                    if Abs("Quantity (Base)") < Abs(NonDistrItemJnlLine."Quantity (Base)") then begin
                        ItemJnlLine2."Quantity (Base)" := "Quantity (Base)";
                        ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
                        ItemJnlLine2."Amount (ACY)" :=
                          Round(OriginalAmtACY * Factor, GLSetup."Amount Rounding Precision");
                        ItemJnlLine2.Amount :=
                          Round(OriginalAmt * Factor, GLSetup."Amount Rounding Precision");
                        ItemJnlLine2."Unit Cost (ACY)" :=
                          Round(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                            Currency."Unit-Amount Rounding Precision") * SignFactor;
                        ItemJnlLine2."Unit Cost" :=
                          Round(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                            GLSetup."Unit-Amount Rounding Precision") * SignFactor;
                        ItemJnlLine2."Discount Amount" :=
                          Round(OriginalDiscountAmt * Factor, GLSetup."Amount Rounding Precision");
                        ItemJnlLine2."Item Shpt. Entry No." := "Item Ledger Entry No.";
                        ItemJnlLine2."Applies-to Entry" := "Item Ledger Entry No.";
                        ItemJnlLine2.CopyTrackingFromSpec(TempTrackingSpecificationChargeAssmt);
                        ItemJnlPostLine.RunWithCheck(ItemJnlLine2);
                        ItemJnlLine2."Location Code" := NonDistrItemJnlLine."Location Code";
                        NonDistrItemJnlLine."Quantity (Base)" -= "Quantity (Base)";
                        NonDistrItemJnlLine.Amount -= (ItemJnlLine2.Amount * SignFactor);
                        NonDistrItemJnlLine."Amount (ACY)" -= (ItemJnlLine2."Amount (ACY)" * SignFactor);
                        NonDistrItemJnlLine."Discount Amount" -= (ItemJnlLine2."Discount Amount" * SignFactor);
                    end else begin
                        NonDistrItemJnlLine."Quantity (Base)" := "Quantity (Base)";
                        NonDistrItemJnlLine."Invoiced Qty. (Base)" := "Quantity (Base)";
                        NonDistrItemJnlLine."Unit Cost" :=
                          Round(NonDistrItemJnlLine.Amount / NonDistrItemJnlLine."Invoiced Qty. (Base)",
                            GLSetup."Unit-Amount Rounding Precision") * SignFactor;
                        NonDistrItemJnlLine."Unit Cost (ACY)" :=
                          Round(NonDistrItemJnlLine.Amount / NonDistrItemJnlLine."Invoiced Qty. (Base)",
                            Currency."Unit-Amount Rounding Precision") * SignFactor;
                        NonDistrItemJnlLine."Item Shpt. Entry No." := "Item Ledger Entry No.";
                        NonDistrItemJnlLine."Applies-to Entry" := "Item Ledger Entry No.";
                        NonDistrItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecificationChargeAssmt);
                        ItemJnlPostLine.RunWithCheck(NonDistrItemJnlLine);
                        NonDistrItemJnlLine."Location Code" := ItemJnlLine2."Location Code";
                    end;
                until Next = 0;
            end;
        end;
    end;

    local procedure PostItemChargePerRcpt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        if not PurchRcptLine.Get(
             TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.")
        then
            Error(ReceiptLinesDeletedErr);

        Sign := 1;

        if PurchRcptLine."Item Rcpt. Entry No." <> 0 then
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                TempItemLedgEntry, PurchRcptLine."Quantity (Base)", PurchRcptLine."Item Rcpt. Entry No.")
        else begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.",
              '', 0, PurchRcptLine."Line No.", PurchRcptLine."Quantity (Base)");
        end;

        if DistributeCharge then
            PostDistributeItemCharge(
              PurchHeader, PurchLine, TempItemLedgEntry, PurchRcptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Qty. to Assign", TempItemChargeAssgntPurch."Amount to Assign",
              Sign, PurchRcptLine."Indirect Cost %")
        else
            PostItemCharge(PurchHeader, PurchLine,
              PurchRcptLine."Item Rcpt. Entry No.", PurchRcptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign",
              PurchRcptLine."Indirect Cost %");
    end;

    local procedure PostItemChargePerRetShpt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        ReturnShptLine: Record "Return Shipment Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Sign: Decimal;
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        ReturnShptLine.Get(
          TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");

        IsHandled := false;
        OnPostItemChargePerRetShptOnBeforeTestJobNo(ReturnShptLine, IsHandled);
        if not IsHandled then
            ReturnShptLine.TestField("Job No.", '');

        Sign := GetSign(PurchLine."Line Amount");
        if PurchLine.IsCreditDocType then
            Sign := -Sign;

        if ReturnShptLine."Item Shpt. Entry No." <> 0 then
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                TempItemLedgEntry, -ReturnShptLine."Quantity (Base)", ReturnShptLine."Item Shpt. Entry No.")
        else begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Return Shipment Line", 0, ReturnShptLine."Document No.",
              '', 0, ReturnShptLine."Line No.", ReturnShptLine."Quantity (Base)");
        end;

        if DistributeCharge then
            PostDistributeItemCharge(
              PurchHeader, PurchLine, TempItemLedgEntry, -ReturnShptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Qty. to Assign", Abs(TempItemChargeAssgntPurch."Amount to Assign"),
              Sign, ReturnShptLine."Indirect Cost %")
        else
            PostItemCharge(PurchHeader, PurchLine,
              ReturnShptLine."Item Shpt. Entry No.", -ReturnShptLine."Quantity (Base)",
              Abs(TempItemChargeAssgntPurch."Amount to Assign") * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign",
              ReturnShptLine."Indirect Cost %");
    end;

    local procedure PostItemChargePerTransfer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        TransRcptLine: Record "Transfer Receipt Line";
        ItemApplnEntry: Record "Item Application Entry";
        DummyTrackingSpecification: Record "Tracking Specification";
        PurchLine2: Record "Purchase Line";
        CurrExchRate: Record "Currency Exchange Rate";
        TotalAmountToPostFCY: Decimal;
        TotalAmountToPostLCY: Decimal;
        TotalDiscAmountToPost: Decimal;
        AmountToPostFCY: Decimal;
        AmountToPostLCY: Decimal;
        DiscAmountToPost: Decimal;
        RemAmountToPostFCY: Decimal;
        RemAmountToPostLCY: Decimal;
        RemDiscAmountToPost: Decimal;
        CalcAmountToPostFCY: Decimal;
        CalcAmountToPostLCY: Decimal;
        CalcDiscAmountToPost: Decimal;
    begin
        with TempItemChargeAssgntPurch do begin
            TransRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
            PurchLine2 := PurchLine;
            PurchLine2."No." := "Item No.";
            PurchLine2."Variant Code" := TransRcptLine."Variant Code";
            PurchLine2."Location Code" := TransRcptLine."Transfer-to Code";
            PurchLine2."Bin Code" := '';
            PurchLine2."Line No." := "Document Line No.";

            if TransRcptLine."Item Rcpt. Entry No." = 0 then
                PostItemChargePerITTransfer(PurchHeader, PurchLine, TransRcptLine)
            else begin
                TotalAmountToPostFCY := "Amount to Assign";
                if PurchHeader."Currency Code" <> '' then
                    TotalAmountToPostLCY :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        Usedate, PurchHeader."Currency Code",
                        TotalAmountToPostFCY, PurchHeader."Currency Factor")
                else
                    TotalAmountToPostLCY := TotalAmountToPostFCY;

                TotalDiscAmountToPost :=
                  Round(
                    PurchLine2."Inv. Discount Amount" / PurchLine2.Quantity * "Qty. to Assign",
                    GLSetup."Amount Rounding Precision");
                TotalDiscAmountToPost :=
                  TotalDiscAmountToPost +
                  Round(
                    PurchLine2."Line Discount Amount" * ("Qty. to Assign" / PurchLine2."Qty. to Invoice"),
                    GLSetup."Amount Rounding Precision");

                TotalAmountToPostLCY := Round(TotalAmountToPostLCY, GLSetup."Amount Rounding Precision");

                ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
                ItemApplnEntry.SetRange("Outbound Item Entry No.", TransRcptLine."Item Rcpt. Entry No.");
                ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', TransRcptLine."Item Rcpt. Entry No.");
                ItemApplnEntry.SetRange("Cost Application", true);
                if ItemApplnEntry.FindSet then
                    repeat
                        PurchLine2."Appl.-to Item Entry" := ItemApplnEntry."Item Ledger Entry No.";
                        CalcAmountToPostFCY :=
                          ((TotalAmountToPostFCY / TransRcptLine."Quantity (Base)") * ItemApplnEntry.Quantity) +
                          RemAmountToPostFCY;
                        AmountToPostFCY := Round(CalcAmountToPostFCY);
                        RemAmountToPostFCY := CalcAmountToPostFCY - AmountToPostFCY;
                        CalcAmountToPostLCY :=
                          ((TotalAmountToPostLCY / TransRcptLine."Quantity (Base)") * ItemApplnEntry.Quantity) +
                          RemAmountToPostLCY;
                        AmountToPostLCY := Round(CalcAmountToPostLCY);
                        RemAmountToPostLCY := CalcAmountToPostLCY - AmountToPostLCY;
                        CalcDiscAmountToPost :=
                          ((TotalDiscAmountToPost / TransRcptLine."Quantity (Base)") * ItemApplnEntry.Quantity) +
                          RemDiscAmountToPost;
                        DiscAmountToPost := Round(CalcDiscAmountToPost);
                        RemDiscAmountToPost := CalcDiscAmountToPost - DiscAmountToPost;
                        PurchLine2.Amount := AmountToPostLCY;
                        PurchLine2."Inv. Discount Amount" := DiscAmountToPost;
                        PurchLine2."Line Discount Amount" := 0;
                        PurchLine2."Unit Cost" :=
                          Round(AmountToPostFCY / ItemApplnEntry.Quantity, GLSetup."Unit-Amount Rounding Precision");
                        PurchLine2."Unit Cost (LCY)" :=
                          Round(AmountToPostLCY / ItemApplnEntry.Quantity, GLSetup."Unit-Amount Rounding Precision");
                        if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                            PurchLine2.Amount := -PurchLine2.Amount;
                        PostItemJnlLine(
                          PurchHeader, PurchLine2,
                          0, 0,
                          ItemApplnEntry.Quantity, ItemApplnEntry.Quantity,
                          PurchLine2."Appl.-to Item Entry", "Item Charge No.", DummyTrackingSpecification);
                    until ItemApplnEntry.Next = 0;
            end;
        end;
    end;

    local procedure PostItemChargePerITTransfer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; TransRcptLine: Record "Transfer Receipt Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        with TempItemChargeAssgntPurch do begin
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Transfer Receipt Line", 0, TransRcptLine."Document No.",
              '', 0, TransRcptLine."Line No.", TransRcptLine."Quantity (Base)");
            PostDistributeItemCharge(
              PurchHeader, PurchLine, TempItemLedgEntry, TransRcptLine."Quantity (Base)",
              "Qty. to Assign", "Amount to Assign", 1, 0);
        end;
    end;

    local procedure PostItemChargePerSalesShpt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Sign: Decimal;
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        if not SalesShptLine.Get(
             TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.")
        then
            Error(RelatedItemLedgEntriesNotFoundErr);

        IsHandled := false;
        OnPostItemChargePerSalesShptOnBeforeTestJobNo(SalesShptLine, IsHandled);
        if not IsHandled then
            SalesShptLine.TestField("Job No.", '');

        Sign := -GetSign(SalesShptLine."Quantity (Base)");

        if SalesShptLine."Item Shpt. Entry No." <> 0 then
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                TempItemLedgEntry, -SalesShptLine."Quantity (Base)", SalesShptLine."Item Shpt. Entry No.")
        else begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Sales Shipment Line", 0, SalesShptLine."Document No.",
              '', 0, SalesShptLine."Line No.", SalesShptLine."Quantity (Base)");
        end;

        if DistributeCharge then
            PostDistributeItemCharge(
              PurchHeader, PurchLine, TempItemLedgEntry, -SalesShptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Qty. to Assign", TempItemChargeAssgntPurch."Amount to Assign", Sign, 0)
        else
            PostItemCharge(PurchHeader, PurchLine,
              SalesShptLine."Item Shpt. Entry No.", -SalesShptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign", 0)
    end;

    local procedure PostItemChargePerRetRcpt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Sign: Decimal;
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        if not ReturnRcptLine.Get(
             TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.")
        then
            Error(RelatedItemLedgEntriesNotFoundErr);

        IsHandled := false;
        OnPostItemChargePerSalesRetRcptOnBeforeTestJobNo(ReturnRcptLine, IsHandled);
        if not IsHandled then
            ReturnRcptLine.TestField("Job No.", '');

        Sign := GetSign(ReturnRcptLine."Quantity (Base)");

        if ReturnRcptLine."Item Rcpt. Entry No." <> 0 then
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                TempItemLedgEntry, ReturnRcptLine."Quantity (Base)", ReturnRcptLine."Item Rcpt. Entry No.")
        else begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Return Receipt Line", 0, ReturnRcptLine."Document No.",
              '', 0, ReturnRcptLine."Line No.", ReturnRcptLine."Quantity (Base)");
        end;

        if DistributeCharge then
            PostDistributeItemCharge(
              PurchHeader, PurchLine, TempItemLedgEntry, ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Qty. to Assign", TempItemChargeAssgntPurch."Amount to Assign", Sign, 0)
        else
            PostItemCharge(PurchHeader, PurchLine,
              ReturnRcptLine."Item Rcpt. Entry No.", ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign", 0)
    end;

    local procedure PostDistributeItemCharge(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; NonDistrQuantity: Decimal; NonDistrQtyToAssign: Decimal; NonDistrAmountToAssign: Decimal; Sign: Decimal; IndirectCostPct: Decimal)
    var
        Factor: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
    begin
        if TempItemLedgEntry.FindSet then begin
            repeat
                Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                QtyToAssign := NonDistrQtyToAssign * Factor;
                AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                if Factor < 1 then begin
                    PostItemCharge(PurchHeader, PurchLine,
                      TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                      AmountToAssign * Sign, QtyToAssign, IndirectCostPct);
                    NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                    NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                    NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                end else // the last time
                    PostItemCharge(PurchHeader, PurchLine,
                      TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                      NonDistrAmountToAssign * Sign, NonDistrQtyToAssign, IndirectCostPct);
            until TempItemLedgEntry.Next = 0;
        end else
            Error(RelatedItemLedgEntriesNotFoundErr)
    end;

    local procedure PostAssocItemJnlLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
    begin
        SalesOrderHeader.Get(
          SalesOrderHeader."Document Type"::Order, PurchLine."Sales Order No.");
        SalesOrderLine.Get(
          SalesOrderLine."Document Type"::Order, PurchLine."Sales Order No.", PurchLine."Sales Order Line No.");

        InitAssocItemJnlLine(ItemJnlLine, SalesOrderHeader, SalesOrderLine, PurchHeader, QtyToBeShipped, QtyToBeShippedBase);

        if SalesOrderLine."Job Contract Entry No." = 0 then begin
            TransferReservToItemJnlLine(SalesOrderLine, ItemJnlLine, PurchLine, QtyToBeShippedBase, true);
            OnBeforePostAssocItemJnlLine(ItemJnlLine, SalesOrderLine, SuppressCommit, PurchLine);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            // Handle Item Tracking
            if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
                if TempHandlingSpecification2.FindSet then
                    repeat
                        TempTrackingSpecification := TempHandlingSpecification2;
                        TempTrackingSpecification.SetSourceFromSalesLine(SalesOrderLine);
                        if TempTrackingSpecification.Insert then;
                        ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                        ItemEntryRelation.SetSource(DATABASE::"Sales Shipment Line", 0, SalesOrderHeader."Shipping No.", SalesOrderLine."Line No.");
                        ItemEntryRelation.SetOrderInfo(SalesOrderLine."Document No.", SalesOrderLine."Line No.");
                        ItemEntryRelation.Insert;
                    until TempHandlingSpecification2.Next = 0;
                exit(0);
            end;
        end;

        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostResourceLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostResourceLine(PurchaseHeader, PurchaseLine, IsHandled);
        if not IsHandled then
            Error(CannotPurchaseResourcesErr);
    end;

    local procedure InitAssocItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; SalesOrderHeader: Record "Sales Header"; SalesOrderLine: Record "Sales Line"; PurchHeader: Record "Purchase Header"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        OnBeforeInitAssocItemJnlLine(ItemJnlLine, SalesOrderHeader, SalesOrderLine, PurchHeader);

        with ItemJnlLine do begin
            Init;
            CopyDocumentFields(
              "Document Type"::"Sales Shipment", SalesOrderHeader."Shipping No.", '', SrcCode, SalesOrderHeader."Posting No. Series");

            CopyFromSalesHeader(SalesOrderHeader);
            "Country/Region Code" := GetCountryCode(SalesOrderLine, SalesOrderHeader);
            "Posting Date" := PurchHeader."Posting Date";
            "Document Date" := PurchHeader."Document Date";

            CopyFromSalesLine(SalesOrderLine);
            "Derived from Blanket Order" := SalesOrderLine."Blanket Order No." <> '';
            "Applies-to Entry" := ItemLedgShptEntryNo;

            Quantity := QtyToBeShipped;
            "Quantity (Base)" := QtyToBeShippedBase;
            "Invoiced Quantity" := 0;
            "Invoiced Qty. (Base)" := 0;
            "Source Currency Code" := PurchHeader."Currency Code";

            Amount := SalesOrderLine.Amount * QtyToBeShipped / SalesOrderLine.Quantity;
            if SalesOrderHeader."Currency Code" <> '' then begin
                Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      SalesOrderHeader."Posting Date", SalesOrderHeader."Currency Code",
                      Amount, SalesOrderHeader."Currency Factor"));
                "Discount Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      SalesOrderHeader."Posting Date", SalesOrderHeader."Currency Code",
                      SalesOrderLine."Line Discount Amount", SalesOrderHeader."Currency Factor"));
            end else begin
                Amount := Round(Amount);
                "Discount Amount" := SalesOrderLine."Line Discount Amount";
            end;
        end;

        OnAfterInitAssocItemJnlLine(ItemJnlLine, SalesOrderHeader, SalesOrderLine, PurchHeader);
    end;

    local procedure ReleasePurchDocument(var PurchHeader: Record "Purchase Header")
    var
        PurchaseHeaderCopy: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        LinesWereModified: Boolean;
        PrevStatus: Option;
        IsHandled: Boolean;
    begin
        with PurchHeader do begin
            if not (Status = Status::Open) or (Status = Status::"Pending Prepayment") then
                exit;

            PurchaseHeaderCopy := PurchHeader;
            PrevStatus := Status;
            OnBeforeReleasePurchDoc(PurchHeader);
            LinesWereModified := ReleasePurchaseDocument.ReleasePurchaseHeader(PurchHeader, PreviewMode);
            if LinesWereModified then
                RefreshTempLines(PurchHeader, TempPurchLineGlobal);
            TestStatusRelease(PurchHeader);
            Status := PrevStatus;
            RestorePurchaseHeader(PurchHeader, PurchaseHeaderCopy);
            OnAfterReleasePurchDoc(PurchHeader);
            if not PreviewMode then begin
                Modify;
                if not SuppressCommit then
                    Commit;
            end;
            IsHandled := false;
            OnReleasePurchDocumentOnBeforeSetStatus(PurchHeader, IsHandled);
            if not IsHandled then
                Status := Status::Released;
        end;
    end;

    local procedure TestStatusRelease(PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestStatusRelease(PurchHeader, IsHandled);
        if not IsHandled then
            PurchHeader.TestField(Status, PurchHeader.Status::Released);
    end;

    local procedure TestPurchLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    var
        DummyTrackingSpecification: Record "Tracking Specification";
    begin
        OnBeforeTestPurchLine(PurchLine, PurchHeader, SuppressCommit);

        with PurchLine do begin
            case Type of
                Type::Item:
                    DummyTrackingSpecification.CheckItemTrackingQuantity(
                      DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.",
                      "Qty. to Receive (Base)", "Qty. to Invoice (Base)", PurchHeader.Receive, PurchHeader.Invoice);
                Type::"Charge (Item)":
                    TestPurchLineItemCharge(PurchLine);
                Type::"Fixed Asset":
                    TestPurchLineFixedAsset(PurchLine);
                else
                    TestPurchLineOthers(PurchLine);
            end;
            TestPurchLineJob(PurchLine);

            case "Document Type" of
                "Document Type"::Order:
                    TestField("Return Qty. to Ship", 0);
                "Document Type"::Invoice:
                    begin
                        if "Receipt No." = '' then
                            TestField("Qty. to Receive", Quantity);
                        TestField("Return Qty. to Ship", 0);
                        TestField("Qty. to Invoice", Quantity);
                    end;
                "Document Type"::"Return Order":
                    TestField("Qty. to Receive", 0);
                "Document Type"::"Credit Memo":
                    begin
                        if "Return Shipment No." = '' then
                            TestField("Return Qty. to Ship", Quantity);
                        TestField("Qty. to Receive", 0);
                        TestField("Qty. to Invoice", Quantity);
                    end;
            end;
        end;

        OnAfterTestPurchLine(PurchHeader, PurchLine, WhseReceive, WhseShip);
    end;

    local procedure TestPurchLineItemCharge(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLineItemCharge(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        with PurchaseLine do begin
            TestField(Amount);
            TestField("Job No.", '');
        end;
    end;

    local procedure TestPurchLineJob(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLineJob(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        with PurchaseLine do
            if "Job No." <> '' then
                TestField("Job Task No.");
    end;

    local procedure TestPurchLineFixedAsset(PurchaseLine: Record "Purchase Line")
    var
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FASetup: Record "FA Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLineFixedAsset(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        with PurchaseLine do begin
            TestField("Job No.", '');
            TestField("Depreciation Book Code");
            TestField("FA Posting Type");
            FixedAsset.Get("No.");
            FixedAsset.TestField("Budgeted Asset", false);
            DeprBook.Get("Depreciation Book Code");
            if "Budgeted FA No." <> '' then begin
                FixedAsset.Get("Budgeted FA No.");
                FixedAsset.TestField("Budgeted Asset", true);
            end;
            if "FA Posting Type" = "FA Posting Type"::Maintenance then begin
                TestField("Insurance No.", '');
                TestField("Depr. until FA Posting Date", false);
                TestField("Depr. Acquisition Cost", false);
                DeprBook.TestField("G/L Integration - Maintenance", true);
            end;
            if "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" then begin
                TestField("Maintenance Code", '');
                DeprBook.TestField("G/L Integration - Acq. Cost", true);
            end;
            if "Insurance No." <> '' then begin
                FASetup.Get;
                FASetup.TestField("Insurance Depr. Book", "Depreciation Book Code");
            end;
        end;
    end;

    local procedure TestPurchLineOthers(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLineOthers(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        with PurchaseLine do begin
            TestField("Depreciation Book Code", '');
            TestField("FA Posting Type", 0);
            TestField("Maintenance Code", '');
            TestField("Insurance No.", '');
            TestField("Depr. until FA Posting Date", false);
            TestField("Depr. Acquisition Cost", false);
            TestField("Budgeted FA No.", '');
            TestField("FA Posting Date", 0D);
            TestField("Salvage Value", 0);
            TestField("Duplicate in Depreciation Book", '');
            TestField("Use Duplication List", false);
        end;
    end;

    local procedure UpdateAssocOrder(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
    begin
        TempDropShptPostBuffer.Reset;
        if TempDropShptPostBuffer.IsEmpty then
            exit;
        SalesSetup.Get;
        if TempDropShptPostBuffer.FindSet then begin
            repeat
                SalesOrderHeader.Get(
                  SalesOrderHeader."Document Type"::Order,
                  TempDropShptPostBuffer."Order No.");
                SalesOrderHeader."Last Shipping No." := SalesOrderHeader."Shipping No.";
                SalesOrderHeader."Shipping No." := '';
                SalesOrderHeader.Modify;
                OnUpdateAssocOrderOnAfterSalesOrderHeaderModify(SalesOrderHeader, SalesSetup);
                ReserveSalesLine.UpdateItemTrackingAfterPosting(SalesOrderHeader);
                TempDropShptPostBuffer.SetRange("Order No.", TempDropShptPostBuffer."Order No.");
                repeat
                    SalesOrderLine.Get(
                      SalesOrderLine."Document Type"::Order,
                      TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
                    SalesOrderLine."Quantity Shipped" := SalesOrderLine."Quantity Shipped" + TempDropShptPostBuffer.Quantity;
                    SalesOrderLine."Qty. Shipped (Base)" := SalesOrderLine."Qty. Shipped (Base)" + TempDropShptPostBuffer."Quantity (Base)";
                    SalesOrderLine.InitOutstanding;
                    if SalesSetup."Default Quantity to Ship" <> SalesSetup."Default Quantity to Ship"::Blank then
                        SalesOrderLine.InitQtyToShip
                    else begin
                        SalesOrderLine."Qty. to Ship" := 0;
                        SalesOrderLine."Qty. to Ship (Base)" := 0;
                    end;
                    SalesOrderLine.Modify;
                    OnUpdateAssocOrderOnAfterSalesOrderLineModify(SalesOrderLine, TempDropShptPostBuffer);
                until TempDropShptPostBuffer.Next = 0;
                TempDropShptPostBuffer.SetRange("Order No.");
            until TempDropShptPostBuffer.Next = 0;
            TempDropShptPostBuffer.DeleteAll;
        end;
    end;

    local procedure UpdateAssosOrderPostingNos(PurchHeader: Record "Purchase Header") DropShipment: Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
        SalesOrderHeader: Record "Sales Header";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        with PurchHeader do begin
            ResetTempLines(TempPurchLine);
            TempPurchLine.SetFilter("Sales Order Line No.", '<>0');
            DropShipment := not TempPurchLine.IsEmpty;

            TempPurchLine.SetFilter("Qty. to Receive", '<>0');
            if DropShipment and Receive then
                if TempPurchLine.FindSet then
                    repeat
                        if SalesOrderHeader."No." <> TempPurchLine."Sales Order No." then begin
                            SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, TempPurchLine."Sales Order No.");
                            SalesOrderHeader.TestField("Bill-to Customer No.");
                            SalesOrderHeader.Ship := true;
                            ReleaseSalesDocument.ReleaseSalesHeader(SalesOrderHeader, PreviewMode);
                            if SalesOrderHeader."Shipping No." = '' then begin
                                SalesOrderHeader.TestField("Shipping No. Series");
                                SalesOrderHeader."Shipping No." :=
                                  NoSeriesMgt.GetNextNo(SalesOrderHeader."Shipping No. Series", "Posting Date", true);
                                SalesOrderHeader.Modify;
                            end;
                        end;
                    until TempPurchLine.Next = 0;

            exit(DropShipment);
        end;
    end;

    local procedure UpdateAfterPosting(PurchHeader: Record "Purchase Header")
    var
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        with TempPurchLine do begin
            ResetTempLines(TempPurchLine);
            SetFilter("Blanket Order Line No.", '<>0');
            if FindSet then
                repeat
                    UpdateBlanketOrderLine(TempPurchLine, PurchHeader.Receive, PurchHeader.Ship, PurchHeader.Invoice);
                until Next = 0;
        end;
    end;

    local procedure UpdateLastPostingNos(var PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            if Receive then begin
                "Last Receiving No." := "Receiving No.";
                "Receiving No." := '';
            end;
            if Invoice then begin
                "Last Posting No." := "Posting No.";
                "Posting No." := '';
            end;
            if Ship then begin
                "Last Return Shipment No." := "Return Shipment No.";
                "Return Shipment No." := '';
            end;
        end;
    end;

    local procedure UpdatePostingNos(var PurchHeader: Record "Purchase Header") ModifyHeader: Boolean
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        with PurchHeader do begin
            if Receive and ("Receiving No." = '') then
                if ("Document Type" = "Document Type"::Order) or
                   (("Document Type" = "Document Type"::Invoice) and PurchSetup."Receipt on Invoice")
                then
                    if not PreviewMode then begin
                        TestField("Receiving No. Series");
                        "Receiving No." := NoSeriesMgt.GetNextNo("Receiving No. Series", "Posting Date", true);
                        ModifyHeader := true;
                    end else
                        "Receiving No." := PostingPreviewNoTok;

            if Ship and ("Return Shipment No." = '') then
                if ("Document Type" = "Document Type"::"Return Order") or
                   (("Document Type" = "Document Type"::"Credit Memo") and PurchSetup."Return Shipment on Credit Memo")
                then
                    if not PreviewMode then begin
                        TestField("Return Shipment No. Series");
                        "Return Shipment No." := NoSeriesMgt.GetNextNo("Return Shipment No. Series", "Posting Date", true);
                        ModifyHeader := true;
                    end else
                        "Return Shipment No." := PostingPreviewNoTok;

            if Invoice and ("Posting No." = '') then begin
                if ("No. Series" <> '') or
                   ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"])
                then
                    TestField("Posting No. Series");
                if ("No. Series" <> "Posting No. Series") or
                   ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"])
                then begin
                    if not PreviewMode then begin
                        "Posting No." := NoSeriesMgt.GetNextNo("Posting No. Series", "Posting Date", true);
                        ModifyHeader := true;
                    end else
                        "Posting No." := PostingPreviewNoTok;
                end;
            end;
        end;

        OnAfterUpdatePostingNos(PurchHeader, NoSeriesMgt, SuppressCommit);
    end;

    local procedure UpdatePurchLineBeforePost(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    begin
        OnBeforeUpdatePurchLineBeforePost(PurchLine, PurchHeader, WhseShip, WhseReceive, RoundingLineInserted, SuppressCommit);

        with PurchLine do begin
            if not (PurchHeader.Receive or RoundingLineInserted) then begin
                "Qty. to Receive" := 0;
                "Qty. to Receive (Base)" := 0;
            end;

            if not (PurchHeader.Ship or RoundingLineInserted) then begin
                "Return Qty. to Ship" := 0;
                "Return Qty. to Ship (Base)" := 0;
            end;

            if (PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice) and ("Receipt No." <> '') then begin
                "Quantity Received" := Quantity;
                "Qty. Received (Base)" := "Quantity (Base)";
                "Qty. to Receive" := 0;
                "Qty. to Receive (Base)" := 0;
            end;

            if (PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo") and ("Return Shipment No." <> '')
            then begin
                "Return Qty. Shipped" := Quantity;
                "Return Qty. Shipped (Base)" := "Quantity (Base)";
                "Return Qty. to Ship" := 0;
                "Return Qty. to Ship (Base)" := 0;
            end;

            if PurchHeader.Invoice then begin
                if Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice) then
                    InitQtyToInvoice;
            end else begin
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;
        end;

        OnAfterUpdatePurchLineBeforePost(PurchLine, WhseShip, WhseReceive);
    end;

    local procedure UpdateWhseDocuments()
    begin
        if WhseReceive then begin
            WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
            TempWhseRcptHeader.Delete;
            OnUpdateWhseDocumentsOnAfterUpdateWhseRcpt(WhseRcptHeader);
        end;
        if WhseShip then begin
            WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
            TempWhseShptHeader.Delete;
            OnUpdateWhseDocumentsOnAfterUpdateWhseShpt(WhseShptHeader);
        end;
    end;

    local procedure DeleteAfterPosting(var PurchHeader: Record "Purchase Header")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        PurchLine: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        WarehouseRequest: Record "Warehouse Request";
        SkipDelete: Boolean;
    begin
        OnBeforeDeleteAfterPosting(PurchHeader, PurchInvHeader, PurchCrMemoHeader, SkipDelete, SuppressCommit);
        if SkipDelete then
            exit;

        with PurchHeader do begin
            if HasLinks then
                DeleteLinks;
            Delete;

            ReservePurchLine.DeleteInvoiceSpecFromHeader(PurchHeader);
            ResetTempLines(TempPurchLine);
            if TempPurchLine.FindFirst then
                repeat
                    if TempPurchLine."Deferral Code" <> '' then
                        DeferralUtilities.RemoveOrSetDeferralSchedule(
                          '', DeferralUtilities.GetPurchDeferralDocType, '', '',
                          TempPurchLine."Document Type",
                          TempPurchLine."Document No.",
                          TempPurchLine."Line No.", 0, 0D,
                          TempPurchLine.Description,
                          '',
                          true);
                    if TempPurchLine.HasLinks then
                        TempPurchLine.DeleteLinks;
                until TempPurchLine.Next = 0;

            PurchLine.SetRange("Document Type", "Document Type");
            PurchLine.SetRange("Document No.", "No.");
            OnBeforePurchLineDeleteAll(PurchLine, SuppressCommit);
            PurchLine.DeleteAll;

            DeleteItemChargeAssgnt(PurchHeader);
            PurchCommentLine.DeleteComments("Document Type", "No.");
            WarehouseRequest.DeleteRequest(DATABASE::"Purchase Line", "Document Type", "No.");
        end;

        OnAfterDeleteAfterPosting(PurchHeader, PurchInvHeader, PurchCrMemoHeader, SuppressCommit);
    end;

    local procedure FinalizePosting(var PurchHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; EverythingInvoiced: Boolean)
    var
        TempPurchLine: Record "Purchase Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        OnBeforeFinalizePosting(PurchHeader, TempPurchLineGlobal, EverythingInvoiced, SuppressCommit, GenJnlPostLine);

        with PurchHeader do begin
            if ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"]) and
               (not EverythingInvoiced)
            then begin
                Modify;
                InsertTrackingSpecification(PurchHeader);
                PostUpdateOrderLine(PurchHeader);
                UpdateAssocOrder(TempDropShptPostBuffer);
                UpdateWhseDocuments;
                WhsePurchRelease.Release(PurchHeader);
                UpdateItemChargeAssgnt;
            end else begin
                case "Document Type" of
                    "Document Type"::Invoice:
                        begin
                            PostUpdateInvoiceLine;
                            InsertTrackingSpecification(PurchHeader);
                        end;
                    "Document Type"::"Credit Memo":
                        begin
                            PostUpdateCreditMemoLine;
                            InsertTrackingSpecification(PurchHeader);
                        end;
                    else begin
                            ResetTempLines(TempPurchLine);
                            TempPurchLine.SetFilter("Prepayment %", '<>0');
                            if TempPurchLine.FindSet then
                                repeat
                                    DecrementPrepmtAmtInvLCY(
                                      TempPurchLine, TempPurchLine."Prepmt. Amount Inv. (LCY)", TempPurchLine."Prepmt. VAT Amount Inv. (LCY)");
                                until TempPurchLine.Next = 0;
                        end;
                end;
                UpdateAfterPosting(PurchHeader);
                UpdateWhseDocuments;
                ArchiveManagement.AutoArchivePurchDocument(PurchHeader);
                ApprovalsMgmt.DeleteApprovalEntries(RecordId);
                if not PreviewMode then
                    DeleteAfterPosting(PurchHeader);
            end;

            InsertValueEntryRelation;
        end;

        OnAfterFinalizePostingOnBeforeCommit(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader, GenJnlPostLine, PreviewMode, SuppressCommit);

        if PreviewMode then begin
            if not HideProgressWindow then
                Window.Close;
            GenJnlPostPreview.ThrowError;
        end;
        if not (InvtPickPutaway or SuppressCommit) then
            Commit;

        if GuiAllowed and not HideProgressWindow then
            Window.Close;

        OnAfterFinalizePosting(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader, GenJnlPostLine, PreviewMode, SuppressCommit);

        ClearPostBuffers;
    end;

    local procedure FillInvoicePostBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        GenPostingSetup: Record "General Posting Setup";
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        DeferralAccount: Code[20];
        PurchAccount: Code[20];
    begin
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        InvoicePostBuffer.PreparePurchase(PurchLine);
        InitAmounts(PurchLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, AmtToDefer, AmtToDeferACY, DeferralAccount);
        InitVATBase(PurchLine, TotalVATBase, TotalVATBaseACY);

        OnFillInvoicePostBufferOnAfterInitAmounts(
          PurchHeader, PurchLine, PurchLineACY, TempInvoicePostBuffer, InvoicePostBuffer, TotalAmount, TotalAmountACY);

        if PurchSetup."Discount Posting" in
           [PurchSetup."Discount Posting"::"Invoice Discounts", PurchSetup."Discount Posting"::"All Discounts"]
        then begin
            CalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostBuffer);

            if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
                InvoicePostBuffer.SetSalesTaxForPurchLine(PurchLine);

            if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                GenPostingSetup.TestField("Purch. Inv. Disc. Account");
                if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
                    FillInvoicePostBufferFADiscount(
                      TempInvoicePostBuffer, InvoicePostBuffer, GenPostingSetup, PurchLine."No.",
                      TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
                    InvoicePostBuffer.SetAccount(
                      GenPostingSetup.GetPurchInvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    InvoicePostBuffer.Type := InvoicePostBuffer.Type::"G/L Account";
                    UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer);
                    InvoicePostBuffer.Type := InvoicePostBuffer.Type::"Fixed Asset";
                end else begin
                    InvoicePostBuffer.SetAccount(
                      GenPostingSetup.GetPurchInvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer);
                end;
            end;
        end;

        if PurchSetup."Discount Posting" in
           [PurchSetup."Discount Posting"::"Line Discounts", PurchSetup."Discount Posting"::"All Discounts"]
        then begin
            CalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostBuffer);

            if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
                InvoicePostBuffer.SetSalesTaxForPurchLine(PurchLine);

            if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                GenPostingSetup.TestField("Purch. Line Disc. Account");
                if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
                    FillInvoicePostBufferFADiscount(
                      TempInvoicePostBuffer, InvoicePostBuffer, GenPostingSetup, PurchLine."No.",
                      TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
                    InvoicePostBuffer.SetAccount(
                      GenPostingSetup.GetPurchLineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    InvoicePostBuffer.Type := InvoicePostBuffer.Type::"G/L Account";
                    UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer);
                    InvoicePostBuffer.Type := InvoicePostBuffer.Type::"Fixed Asset";
                end else begin
                    InvoicePostBuffer.SetAccount(
                      GenPostingSetup.GetPurchLineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer);
                end;
            end;
        end;

        DeferralUtilities.AdjustTotalAmountForDeferralsNoBase(
          PurchLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY);

        OnBeforeInvoicePostingBufferSetAmounts(
          PurchLine, TempInvoicePostBuffer, InvoicePostBuffer,
          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);

        if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
            if PurchLine."Deferral Code" <> '' then
                InvoicePostBuffer.SetAmounts(
                  TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, PurchLine."VAT Difference", TotalVATBase, TotalVATBaseACY)
            else
                InvoicePostBuffer.SetAmountsNoVAT(TotalAmount, TotalAmountACY, PurchLine."VAT Difference")
        end else
            if (not PurchLine."Use Tax") or (PurchLine."VAT Calculation Type" <> PurchLine."VAT Calculation Type"::"Sales Tax") then
                InvoicePostBuffer.SetAmounts(
                  TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, PurchLine."VAT Difference", TotalVATBase, TotalVATBaseACY)
            else
                InvoicePostBuffer.SetAmountsNoVAT(TotalAmount, TotalAmountACY, PurchLine."VAT Difference");

        if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
            InvoicePostBuffer.SetSalesTaxForPurchLine(PurchLine);

        if (PurchLine.Type = PurchLine.Type::"G/L Account") or (PurchLine.Type = PurchLine.Type::"Fixed Asset") then
            PurchAccount := PurchLine."No."
        else
            if PurchLine.IsCreditDocType then
                PurchAccount := GenPostingSetup.GetPurchCrMemoAccount
            else
                PurchAccount := GenPostingSetup.GetPurchAccount;

        InvoicePostBuffer.SetAccount(PurchAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
        InvoicePostBuffer."Deferral Code" := PurchLine."Deferral Code";
        OnAfterFillInvoicePostBuffer(InvoicePostBuffer, PurchLine, TempInvoicePostBuffer, SuppressCommit);
        UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer);

        OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer(PurchHeader, PurchLine, InvoicePostBuffer, TempInvoicePostBuffer);

        if PurchLine."Deferral Code" <> '' then begin
            OnBeforeFillDeferralPostingBuffer(
              PurchLine, InvoicePostBuffer, TempInvoicePostBuffer, Usedate, InvDefLineNo, DeferralLineNo, SuppressCommit);
            FillDeferralPostingBuffer(PurchHeader, PurchLine, InvoicePostBuffer, AmtToDefer, AmtToDeferACY, DeferralAccount, PurchAccount);
        end;
    end;

    local procedure FillInvoicePostBufferFADiscount(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; GenPostingSetup: Record "General Posting Setup"; AccountNo: Code[20]; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; TotalVATBase: Decimal; TotalVATBaseACY: Decimal)
    var
        DeprBook: Record "Depreciation Book";
    begin
        DeprBook.Get(InvoicePostBuffer."Depreciation Book Code");
        if DeprBook."Subtract Disc. in Purch. Inv." then begin
            InvoicePostBuffer.SetAccount(AccountNo, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
            UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer);
            InvoicePostBuffer.ReverseAmounts;
            InvoicePostBuffer.SetAccount(
              GenPostingSetup.GetPurchFADiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
            InvoicePostBuffer.Type := InvoicePostBuffer.Type::"G/L Account";
            UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer);
            InvoicePostBuffer.ReverseAmounts;
        end;
    end;

    local procedure UpdateInvoicePostBuffer(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostBuffer."Fixed Asset Line No." := FALineNo;
        end;

        TempInvoicePostBuffer.Update(InvoicePostBuffer, InvDefLineNo, DeferralLineNo);
    end;

    local procedure InsertPrepmtAdjInvPostingBuf(PurchHeader: Record "Purchase Header"; PrepmtPurchLine: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
        AdjAmount: Decimal;
    begin
        with PrepmtPurchLine do
            if "Prepayment Line" then
                if "Prepmt. Amount Inv. (LCY)" <> 0 then begin
                    AdjAmount := -"Prepmt. Amount Inv. (LCY)";
                    TempInvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                      "No.", AdjAmount, PurchHeader."Currency Code" = '');
                    TempInvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                      PurchPostPrepayments.GetCorrBalAccNo(PurchHeader, AdjAmount > 0),
                      -AdjAmount,
                      PurchHeader."Currency Code" = '');
                end else
                    if ("Prepayment %" = 100) and ("Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                        TempInvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                          PurchPostPrepayments.GetInvRoundingAccNo(PurchHeader."Vendor Posting Group"),
                          "Prepmt. VAT Amount Inv. (LCY)", PurchHeader."Currency Code" = '');
    end;

    local procedure GetCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    local procedure DivideAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; PurchLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    var
        OriginalDeferralAmount: Decimal;
    begin
        if RoundingLineInserted and (RoundingLineNo = PurchLine."Line No.") then
            exit;

        OnBeforeDivideAmount(PurchHeader, PurchLine, QtyType, PurchLineQty, TempVATAmountLine, TempVATAmountLineRemainder);

        with PurchLine do
            if (PurchLineQty = 0) or ("Direct Unit Cost" = 0) then begin
                "Line Amount" := 0;
                "Line Discount Amount" := 0;
                "Inv. Discount Amount" := 0;
                "VAT Base Amount" := 0;
                Amount := 0;
                "Amount Including VAT" := 0;
            end else begin
                OriginalDeferralAmount := GetDeferralAmount;
                TempVATAmountLine.Get(
                  "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", "Line Amount" >= 0);
                if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
                    "VAT %" := TempVATAmountLine."VAT %";
                TempVATAmountLineRemainder := TempVATAmountLine;
                if not TempVATAmountLineRemainder.Find then begin
                    TempVATAmountLineRemainder.Init;
                    TempVATAmountLineRemainder.Insert;
                end;
                "Line Amount" := GetLineAmountToHandleInclPrepmt(PurchLineQty) + GetPrepmtDiffToLineAmount(PurchLine);
                if PurchLineQty <> Quantity then
                    "Line Discount Amount" :=
                      Round("Line Discount Amount" * PurchLineQty / Quantity, Currency."Amount Rounding Precision");

                if "Allow Invoice Disc." and (TempVATAmountLine."Inv. Disc. Base Amount" <> 0) then
                    if QtyType = QtyType::Invoicing then
                        "Inv. Discount Amount" := "Inv. Disc. Amount to Invoice"
                    else begin
                        TempVATAmountLineRemainder."Invoice Discount Amount" :=
                          TempVATAmountLineRemainder."Invoice Discount Amount" +
                          TempVATAmountLine."Invoice Discount Amount" * "Line Amount" /
                          TempVATAmountLine."Inv. Disc. Base Amount";
                        "Inv. Discount Amount" :=
                          Round(
                            TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."Invoice Discount Amount" :=
                          TempVATAmountLineRemainder."Invoice Discount Amount" - "Inv. Discount Amount";
                    end;

                if PurchHeader."Prices Including VAT" then begin
                    if (TempVATAmountLine.CalcLineAmount = 0) or ("Line Amount" = 0) then begin
                        TempVATAmountLineRemainder."VAT Amount" := 0;
                        TempVATAmountLineRemainder."Amount Including VAT" := 0;
                    end else begin
                        TempVATAmountLineRemainder."VAT Amount" +=
                          TempVATAmountLine."VAT Amount" * CalcLineAmount / TempVATAmountLine.CalcLineAmount;
                        TempVATAmountLineRemainder."Amount Including VAT" +=
                          TempVATAmountLine."Amount Including VAT" * CalcLineAmount / TempVATAmountLine.CalcLineAmount;
                    end;
                    if "Line Discount %" <> 100 then
                        "Amount Including VAT" :=
                          Round(TempVATAmountLineRemainder."Amount Including VAT", Currency."Amount Rounding Precision")
                    else
                        "Amount Including VAT" := 0;
                    Amount :=
                      Round("Amount Including VAT", Currency."Amount Rounding Precision") -
                      Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision");
                    "VAT Base Amount" :=
                      Round(
                        Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                    TempVATAmountLineRemainder."Amount Including VAT" :=
                      TempVATAmountLineRemainder."Amount Including VAT" - "Amount Including VAT";
                    TempVATAmountLineRemainder."VAT Amount" :=
                      TempVATAmountLineRemainder."VAT Amount" - "Amount Including VAT" + Amount;
                end else
                    if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then begin
                        if "Line Discount %" <> 100 then
                            "Amount Including VAT" := CalcLineAmount
                        else
                            "Amount Including VAT" := 0;
                        Amount := 0;
                        "VAT Base Amount" := 0;
                    end else begin
                        Amount := CalcLineAmount;
                        "VAT Base Amount" :=
                          Round(
                            Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                        if TempVATAmountLine."VAT Base" = 0 then
                            TempVATAmountLineRemainder."VAT Amount" := 0
                        else
                            TempVATAmountLineRemainder."VAT Amount" +=
                              TempVATAmountLine."VAT Amount" * CalcLineAmount / TempVATAmountLine.CalcLineAmount;
                        if "Line Discount %" <> 100 then
                            "Amount Including VAT" :=
                              Amount + Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision")
                        else
                            "Amount Including VAT" := 0;
                        TempVATAmountLineRemainder."VAT Amount" :=
                          TempVATAmountLineRemainder."VAT Amount" - "Amount Including VAT" + Amount;
                    end;

                TempVATAmountLineRemainder.Modify;
                if "Deferral Code" <> '' then
                    CalcDeferralAmounts(PurchHeader, PurchLine, OriginalDeferralAmount);
            end;

        OnAfterDivideAmount(PurchHeader, PurchLine, QtyType, PurchLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
    end;

    local procedure RoundAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; PurchLineQty: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        NoVAT: Boolean;
    begin
        OnBeforeRoundAmount(PurchHeader, PurchLine, PurchLineQty);

        with PurchLine do begin
            IncrAmount(PurchHeader, PurchLine, TotalPurchLine);
            Increment(TotalPurchLine."Net Weight", Round(PurchLineQty * "Net Weight", UOMMgt.WeightRndPrecision));
            Increment(TotalPurchLine."Gross Weight", Round(PurchLineQty * "Gross Weight", UOMMgt.WeightRndPrecision));
            Increment(TotalPurchLine."Unit Volume", Round(PurchLineQty * "Unit Volume", UOMMgt.CubageRndPrecision));
            Increment(TotalPurchLine.Quantity, PurchLineQty);
            if "Units per Parcel" > 0 then
                Increment(TotalPurchLine."Units per Parcel", Round(PurchLineQty / "Units per Parcel", 1, '>'));

            xPurchLine := PurchLine;
            PurchLineACY := PurchLine;
            if PurchHeader."Currency Code" <> '' then begin
                if PurchHeader."Posting Date" = 0D then
                    Usedate := WorkDate
                else
                    Usedate := PurchHeader."Posting Date";

                NoVAT := Amount = "Amount Including VAT";
                "Amount Including VAT" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."Amount Including VAT", PurchHeader."Currency Factor")) -
                  TotalPurchLineLCY."Amount Including VAT";
                if NoVAT then
                    Amount := "Amount Including VAT"
                else
                    Amount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          Usedate, PurchHeader."Currency Code",
                          TotalPurchLine.Amount, PurchHeader."Currency Factor")) -
                      TotalPurchLineLCY.Amount;
                "Line Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."Line Amount", PurchHeader."Currency Factor")) -
                  TotalPurchLineLCY."Line Amount";
                "Line Discount Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."Line Discount Amount", PurchHeader."Currency Factor")) -
                  TotalPurchLineLCY."Line Discount Amount";
                "Inv. Discount Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."Inv. Discount Amount", PurchHeader."Currency Factor")) -
                  TotalPurchLineLCY."Inv. Discount Amount";
                "VAT Difference" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."VAT Difference", PurchHeader."Currency Factor")) -
                  TotalPurchLineLCY."VAT Difference";
                "VAT Base Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      Usedate, PurchHeader."Currency Code",
                      TotalPurchLine."VAT Base Amount", PurchHeader."Currency Factor")) -
                  TotalPurchLineLCY."VAT Base Amount";
            end;

            OnRoundAmountOnBeforeIncrAmount(PurchHeader, PurchLine, PurchLineQty, TotalPurchLine, TotalPurchLineLCY);

            IncrAmount(PurchHeader, PurchLine, TotalPurchLineLCY);
            Increment(TotalPurchLineLCY."Unit Cost (LCY)", Round(PurchLineQty * "Unit Cost (LCY)"));
        end;

        OnAfterRoundAmount(PurchHeader, PurchLine, PurchLineQty);
    end;

    procedure ReverseAmount(var PurchLine: Record "Purchase Line")
    begin
        with PurchLine do begin
            "Qty. to Receive" := -"Qty. to Receive";
            "Qty. to Receive (Base)" := -"Qty. to Receive (Base)";
            "Return Qty. to Ship" := -"Return Qty. to Ship";
            "Return Qty. to Ship (Base)" := -"Return Qty. to Ship (Base)";
            "Qty. to Invoice" := -"Qty. to Invoice";
            "Qty. to Invoice (Base)" := -"Qty. to Invoice (Base)";
            "Line Amount" := -"Line Amount";
            Amount := -Amount;
            "VAT Base Amount" := -"VAT Base Amount";
            "VAT Difference" := -"VAT Difference";
            "Amount Including VAT" := -"Amount Including VAT";
            "Line Discount Amount" := -"Line Discount Amount";
            "Inv. Discount Amount" := -"Inv. Discount Amount";
            "Salvage Value" := -"Salvage Value";
            OnAfterReverseAmount(PurchLine);
        end;
    end;

    local procedure InvoiceRounding(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; UseTempData: Boolean; BiggestLineNo: Integer)
    var
        VendPostingGr: Record "Vendor Posting Group";
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalPurchLine."Amount Including VAT" -
            Round(
              TotalPurchLine."Amount Including VAT", Currency."Invoice Rounding Precision", Currency.InvoiceRoundingDirection),
            Currency."Amount Rounding Precision");

        OnBeforeInvoiceRoundingAmount(
          PurchHeader, TotalPurchLine."Amount Including VAT", UseTempData, InvoiceRoundingAmount, SuppressCommit);
        if InvoiceRoundingAmount <> 0 then begin
            VendPostingGr.Get(PurchHeader."Vendor Posting Group");
            VendPostingGr.TestField("Invoice Rounding Account");
            with PurchLine do begin
                Init;
                BiggestLineNo := BiggestLineNo + 10000;
                "System-Created Entry" := true;
                if UseTempData then begin
                    "Line No." := 0;
                    Type := Type::"G/L Account";
                end else begin
                    "Line No." := BiggestLineNo;
                    Validate(Type, Type::"G/L Account");
                end;
                Validate("No.", VendPostingGr."Invoice Rounding Account");
                Validate(Quantity, 1);
                if IsCreditDocType then
                    Validate("Return Qty. to Ship", Quantity)
                else
                    Validate("Qty. to Receive", Quantity);
                if PurchHeader."Prices Including VAT" then
                    Validate("Direct Unit Cost", InvoiceRoundingAmount)
                else
                    Validate(
                      "Direct Unit Cost",
                      Round(
                        InvoiceRoundingAmount /
                        (1 + (1 - PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                        Currency."Amount Rounding Precision"));
                Validate("Amount Including VAT", InvoiceRoundingAmount);
                "Line No." := BiggestLineNo;
                LastLineRetrieved := false;
                RoundingLineInserted := true;
                RoundingLineNo := "Line No.";
            end;
        end;

        OnAfterInvoiceRoundingAmount(
          PurchHeader, PurchLine, TotalPurchLine, UseTempData, InvoiceRoundingAmount, SuppressCommit);
    end;

    local procedure IncrAmount(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var TotalPurchLine: Record "Purchase Line")
    begin
        with PurchLine do begin
            if PurchHeader."Prices Including VAT" or
               ("VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT")
            then
                Increment(TotalPurchLine."Line Amount", "Line Amount");
            Increment(TotalPurchLine.Amount, Amount);
            Increment(TotalPurchLine."VAT Base Amount", "VAT Base Amount");
            Increment(TotalPurchLine."VAT Difference", "VAT Difference");
            Increment(TotalPurchLine."Amount Including VAT", "Amount Including VAT");
            Increment(TotalPurchLine."Line Discount Amount", "Line Discount Amount");
            Increment(TotalPurchLine."Inv. Discount Amount", "Inv. Discount Amount");
            Increment(TotalPurchLine."Inv. Disc. Amount to Invoice", "Inv. Disc. Amount to Invoice");
            Increment(TotalPurchLine."Prepmt. Line Amount", "Prepmt. Line Amount");
            Increment(TotalPurchLine."Prepmt. Amt. Inv.", "Prepmt. Amt. Inv.");
            Increment(TotalPurchLine."Prepmt Amt to Deduct", "Prepmt Amt to Deduct");
            Increment(TotalPurchLine."Prepmt Amt Deducted", "Prepmt Amt Deducted");
            Increment(TotalPurchLine."Prepayment VAT Difference", "Prepayment VAT Difference");
            Increment(TotalPurchLine."Prepmt VAT Diff. to Deduct", "Prepmt VAT Diff. to Deduct");
            Increment(TotalPurchLine."Prepmt VAT Diff. Deducted", "Prepmt VAT Diff. Deducted");
            OnAfterIncrAmount(TotalPurchLine, PurchLine);
        end;
    end;

    local procedure Increment(var Number: Decimal; Number2: Decimal)
    begin
        Number := Number + Number2;
    end;

    procedure GetPurchLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping)
    begin
        FillTempLines(PurchHeader, TempPurchLineGlobal);
        if QtyType = QtyType::Invoicing then
            CreatePrepmtLines(PurchHeader, false);
        SumPurchLines2(PurchHeader, PurchLine, TempPurchLineGlobal, QtyType, true);
    end;

    procedure SumPurchLines(var NewPurchHeader: Record "Purchase Header"; QtyType: Option General,Invoicing,Shipping; var NewTotalPurchLine: Record "Purchase Line"; var NewTotalPurchLineLCY: Record "Purchase Line"; var VATAmount: Decimal; var VATAmountText: Text[30])
    var
        OldPurchLine: Record "Purchase Line";
    begin
        SumPurchLinesTemp(
          NewPurchHeader, OldPurchLine, QtyType, NewTotalPurchLine, NewTotalPurchLineLCY,
          VATAmount, VATAmountText);
    end;

    procedure SumPurchLinesTemp(var PurchHeader: Record "Purchase Header"; var OldPurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; var NewTotalPurchLine: Record "Purchase Line"; var NewTotalPurchLineLCY: Record "Purchase Line"; var VATAmount: Decimal; var VATAmountText: Text[30])
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchHeader do begin
            SumPurchLines2(PurchHeader, PurchLine, OldPurchLine, QtyType, false);
            VATAmount := TotalPurchLine."Amount Including VAT" - TotalPurchLine.Amount;
            if TotalPurchLine."VAT %" = 0 then
                VATAmountText := VATAmountTxt
            else
                VATAmountText := StrSubstNo(VATRateTxt, TotalPurchLine."VAT %");
            NewTotalPurchLine := TotalPurchLine;
            NewTotalPurchLineLCY := TotalPurchLineLCY;
        end;
    end;

    local procedure SumPurchLines2(PurchHeader: Record "Purchase Header"; var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; InsertPurchLine: Boolean)
    var
        PurchLine: Record "Purchase Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        PurchLineQty: Decimal;
        BiggestLineNo: Integer;
    begin
        TempVATAmountLineRemainder.DeleteAll;
        OldPurchLine.CalcVATAmountLines(QtyType, PurchHeader, OldPurchLine, TempVATAmountLine);
        with PurchHeader do begin
            GetGLSetup;
            PurchSetup.Get;
            GetCurrency("Currency Code");
            OldPurchLine.SetRange("Document Type", "Document Type");
            OldPurchLine.SetRange("Document No.", "No.");
            OnSumPurchLines2OnAfterSetFilters(OldPurchLine, PurchHeader);
            RoundingLineInserted := false;
            if OldPurchLine.FindSet then
                repeat
                    if not RoundingLineInserted then
                        PurchLine := OldPurchLine;
                    case QtyType of
                        QtyType::General:
                            PurchLineQty := PurchLine.Quantity;
                        QtyType::Invoicing:
                            PurchLineQty := PurchLine."Qty. to Invoice";
                        QtyType::Shipping:
                            begin
                                if IsCreditDocType then
                                    PurchLineQty := PurchLine."Return Qty. to Ship"
                                else
                                    PurchLineQty := PurchLine."Qty. to Receive"
                            end;
                    end;
                    DivideAmount(PurchHeader, PurchLine, QtyType, PurchLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
                    PurchLine.Quantity := PurchLineQty;
                    if PurchLineQty <> 0 then begin
                        if (PurchLine.Amount <> 0) and not RoundingLineInserted then
                            if TotalPurchLine.Amount = 0 then
                                TotalPurchLine."VAT %" := PurchLine."VAT %"
                            else
                                if TotalPurchLine."VAT %" <> PurchLine."VAT %" then
                                    TotalPurchLine."VAT %" := 0;
                        RoundAmount(PurchHeader, PurchLine, PurchLineQty);
                        PurchLine := xPurchLine;
                    end;
                    if InsertPurchLine then begin
                        NewPurchLine := PurchLine;
                        NewPurchLine.Insert;
                    end;
                    if RoundingLineInserted then
                        LastLineRetrieved := true
                    else begin
                        BiggestLineNo := MAX(BiggestLineNo, OldPurchLine."Line No.");
                        LastLineRetrieved := OldPurchLine.Next = 0;
                        if LastLineRetrieved and PurchSetup."Invoice Rounding" then
                            InvoiceRounding(PurchHeader, PurchLine, true, BiggestLineNo);
                    end;
                until LastLineRetrieved;
        end;
    end;

    procedure UpdateBlanketOrderLine(PurchLine: Record "Purchase Line"; Receive: Boolean; Ship: Boolean; Invoice: Boolean)
    var
        BlanketOrderPurchLine: Record "Purchase Line";
        ModifyLine: Boolean;
        Sign: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBlanketOrderLine(PurchLine, Receive, Ship, Invoice, IsHandled);
        if IsHandled then
            exit;

        if (PurchLine."Blanket Order No." <> '') and (PurchLine."Blanket Order Line No." <> 0) and
           ((Receive and (PurchLine."Qty. to Receive" <> 0)) or
            (Ship and (PurchLine."Return Qty. to Ship" <> 0)) or
            (Invoice and (PurchLine."Qty. to Invoice" <> 0)))
        then
            if BlanketOrderPurchLine.Get(
                 BlanketOrderPurchLine."Document Type"::"Blanket Order", PurchLine."Blanket Order No.",
                 PurchLine."Blanket Order Line No.")
            then begin
                BlanketOrderPurchLine.TestField(Type, PurchLine.Type);
                BlanketOrderPurchLine.TestField("No.", PurchLine."No.");
                BlanketOrderPurchLine.TestField("Buy-from Vendor No.", PurchLine."Buy-from Vendor No.");

                ModifyLine := false;
                case PurchLine."Document Type" of
                    PurchLine."Document Type"::Order,
                  PurchLine."Document Type"::Invoice:
                        Sign := 1;
                    PurchLine."Document Type"::"Return Order",
                  PurchLine."Document Type"::"Credit Memo":
                        Sign := -1;
                end;
                if Receive and (PurchLine."Receipt No." = '') then begin
                    if BlanketOrderPurchLine."Qty. per Unit of Measure" =
                       PurchLine."Qty. per Unit of Measure"
                    then
                        BlanketOrderPurchLine."Quantity Received" :=
                          BlanketOrderPurchLine."Quantity Received" + Sign * PurchLine."Qty. to Receive"
                    else
                        BlanketOrderPurchLine."Quantity Received" :=
                          BlanketOrderPurchLine."Quantity Received" +
                          Sign *
                          Round(
                            (PurchLine."Qty. per Unit of Measure" /
                             BlanketOrderPurchLine."Qty. per Unit of Measure") * PurchLine."Qty. to Receive",
                            UOMMgt.QtyRndPrecision);
                    BlanketOrderPurchLine."Qty. Received (Base)" :=
                      BlanketOrderPurchLine."Qty. Received (Base)" + Sign * PurchLine."Qty. to Receive (Base)";
                    ModifyLine := true;
                end;
                if Ship and (PurchLine."Return Shipment No." = '') then begin
                    if BlanketOrderPurchLine."Qty. per Unit of Measure" =
                       PurchLine."Qty. per Unit of Measure"
                    then
                        BlanketOrderPurchLine."Quantity Received" :=
                          BlanketOrderPurchLine."Quantity Received" + Sign * PurchLine."Return Qty. to Ship"
                    else
                        BlanketOrderPurchLine."Quantity Received" :=
                          BlanketOrderPurchLine."Quantity Received" +
                          Sign *
                          Round(
                            (PurchLine."Qty. per Unit of Measure" /
                             BlanketOrderPurchLine."Qty. per Unit of Measure") * PurchLine."Return Qty. to Ship",
                            UOMMgt.QtyRndPrecision);
                    BlanketOrderPurchLine."Qty. Received (Base)" :=
                      BlanketOrderPurchLine."Qty. Received (Base)" + Sign * PurchLine."Return Qty. to Ship (Base)";
                    ModifyLine := true;
                end;

                if Invoice then begin
                    if BlanketOrderPurchLine."Qty. per Unit of Measure" =
                       PurchLine."Qty. per Unit of Measure"
                    then
                        BlanketOrderPurchLine."Quantity Invoiced" :=
                          BlanketOrderPurchLine."Quantity Invoiced" + Sign * PurchLine."Qty. to Invoice"
                    else
                        BlanketOrderPurchLine."Quantity Invoiced" :=
                          BlanketOrderPurchLine."Quantity Invoiced" +
                          Sign *
                          Round(
                            (PurchLine."Qty. per Unit of Measure" /
                             BlanketOrderPurchLine."Qty. per Unit of Measure") * PurchLine."Qty. to Invoice",
                            UOMMgt.QtyRndPrecision);
                    BlanketOrderPurchLine."Qty. Invoiced (Base)" :=
                      BlanketOrderPurchLine."Qty. Invoiced (Base)" + Sign * PurchLine."Qty. to Invoice (Base)";
                    ModifyLine := true;
                end;

                if ModifyLine then begin
                    OnUpdateBlanketOrderLineOnBeforeInitOutstanding(BlanketOrderPurchLine, PurchLine, Ship, Receive, Invoice);
                    BlanketOrderPurchLine.InitOutstanding;

                    IsHandled := false;
                    OnUpdateBlanketOrderLineOnBeforeCheck(BlanketOrderPurchLine, PurchLine, IsHandled);
                    if not IsHandled then begin
                        if (BlanketOrderPurchLine.Quantity * BlanketOrderPurchLine."Quantity Received" < 0) or
                           (Abs(BlanketOrderPurchLine.Quantity) < Abs(BlanketOrderPurchLine."Quantity Received"))
                        then
                            BlanketOrderPurchLine.FieldError(
                              "Quantity Received",
                              StrSubstNo(BlanketOrderQuantityGreaterThanErr, BlanketOrderPurchLine.FieldCaption(Quantity)));

                        if (BlanketOrderPurchLine."Quantity (Base)" * BlanketOrderPurchLine."Qty. Received (Base)" < 0) or
                           (Abs(BlanketOrderPurchLine."Quantity (Base)") < Abs(BlanketOrderPurchLine."Qty. Received (Base)"))
                        then
                            BlanketOrderPurchLine.FieldError(
                              "Qty. Received (Base)",
                              StrSubstNo(BlanketOrderQuantityGreaterThanErr, BlanketOrderPurchLine.FieldCaption("Quantity Received")));

                        BlanketOrderPurchLine.CalcFields("Reserved Qty. (Base)");
                        if Abs(BlanketOrderPurchLine."Outstanding Qty. (Base)") < Abs(BlanketOrderPurchLine."Reserved Qty. (Base)") then
                            BlanketOrderPurchLine.FieldError(
                              "Reserved Qty. (Base)", BlanketOrderQuantityReducedErr);
                    end;

                    BlanketOrderPurchLine."Qty. to Invoice" :=
                      BlanketOrderPurchLine.Quantity - BlanketOrderPurchLine."Quantity Invoiced";
                    BlanketOrderPurchLine."Qty. to Receive" :=
                      BlanketOrderPurchLine.Quantity - BlanketOrderPurchLine."Quantity Received";
                    BlanketOrderPurchLine."Qty. to Invoice (Base)" :=
                      BlanketOrderPurchLine."Quantity (Base)" - BlanketOrderPurchLine."Qty. Invoiced (Base)";
                    BlanketOrderPurchLine."Qty. to Receive (Base)" :=
                      BlanketOrderPurchLine."Quantity (Base)" - BlanketOrderPurchLine."Qty. Received (Base)";

                    OnBeforeBlanketOrderPurchLineModify(BlanketOrderPurchLine, PurchLine);
                    BlanketOrderPurchLine.Modify;
                    OnAfterBlanketOrderPurchLineModify(BlanketOrderPurchLine, PurchLine, Ship, Receive, Invoice);
                end;
            end;
    end;

    local procedure UpdatePurchaseHeader(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchaseHeader(VendorLedgerEntry, PurchInvHeader, PurchCrMemoHeader, GenJnlLineDocType, IsHandled);
        if IsHandled then
            exit;

        case GenJnlLineDocType of
            GenJnlLine."Document Type"::Invoice:
                begin
                    FindVendorLedgerEntry(GenJnlLineDocType, GenJnlLineDocNo, VendorLedgerEntry);
                    PurchInvHeader."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
                    PurchInvHeader.Modify;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    FindVendorLedgerEntry(GenJnlLineDocType, GenJnlLineDocNo, VendorLedgerEntry);
                    PurchCrMemoHeader."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
                    PurchCrMemoHeader.Modify;
                end;
        end;

        OnAfterUpdatePurchaseHeader(VendorLedgerEntry, PurchInvHeader, PurchCrMemoHeader, GenJnlLineDocType);
    end;

    local procedure PostVendorEntry(var PurchHeader: Record "Purchase Header"; TotalPurchLine2: Record "Purchase Line"; TotalPurchLineLCY2: Record "Purchase Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35]; SourceCode: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."Posting Description",
              PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
              PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

            CopyDocumentFields(DocType, DocNo, ExtDocNo, SourceCode, '');
            "Account Type" := "Account Type"::Vendor;
            "Account No." := PurchHeader."Pay-to Vendor No.";
            CopyFromPurchHeader(PurchHeader);
            SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");
            "System-Created Entry" := true;

            CopyFromPurchHeaderApplyTo(PurchHeader);
            CopyFromPurchHeaderPayment(PurchHeader);

            Amount := -TotalPurchLine2."Amount Including VAT";
            "Source Currency Amount" := -TotalPurchLine2."Amount Including VAT";
            "Amount (LCY)" := -TotalPurchLineLCY2."Amount Including VAT";
            "Sales/Purch. (LCY)" := -TotalPurchLineLCY2.Amount;
            "Inv. Discount (LCY)" := -TotalPurchLineLCY2."Inv. Discount Amount";

            OnBeforePostVendorEntry(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, PreviewMode, SuppressCommit, GenJnlPostLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostVendorEntry(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure PostBalancingEntry(PurchHeader: Record "Purchase Header"; TotalPurchLine2: Record "Purchase Line"; TotalPurchLineLCY2: Record "Purchase Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35]; SourceCode: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(DocType, DocNo, VendLedgEntry);

        with GenJnlLine do begin
            InitNewLine(
              PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."Posting Description",
              PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
              PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

            CopyDocumentFields(0, DocNo, ExtDocNo, SourceCode, '');
            "Account Type" := "Account Type"::Vendor;
            "Account No." := PurchHeader."Pay-to Vendor No.";
            CopyFromPurchHeader(PurchHeader);
            SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");

            if PurchHeader.IsCreditDocType then
                "Document Type" := "Document Type"::Refund
            else
                "Document Type" := "Document Type"::Payment;

            SetApplyToDocNo(PurchHeader, GenJnlLine, DocType, DocNo);

            Amount := TotalPurchLine2."Amount Including VAT" + VendLedgEntry."Remaining Pmt. Disc. Possible";
            "Source Currency Amount" := Amount;
            VendLedgEntry.CalcFields(Amount);
            if VendLedgEntry.Amount = 0 then
                "Amount (LCY)" := TotalPurchLineLCY2."Amount Including VAT"
            else
                "Amount (LCY)" :=
                  TotalPurchLineLCY2."Amount Including VAT" +
                  Round(VendLedgEntry."Remaining Pmt. Disc. Possible" / VendLedgEntry."Adjusted Currency Factor");
            "Allow Zero-Amount Posting" := true;

            OnBeforePostBalancingEntry(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, PreviewMode, SuppressCommit);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostBalancingEntry(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure SetApplyToDocNo(PurchHeader: Record "Purchase Header"; var GenJnlLine: Record "Gen. Journal Line"; DocType: Option; DocNo: Code[20])
    begin
        with GenJnlLine do begin
            if PurchHeader."Bal. Account Type" = PurchHeader."Bal. Account Type"::"Bank Account" then
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := PurchHeader."Bal. Account No.";
            "Applies-to Doc. Type" := DocType;
            "Applies-to Doc. No." := DocNo;
        end;

        OnAfterSetApplyToDocNo(GenJnlLine, PurchHeader);
    end;

    local procedure FindVendorLedgerEntry(DocType: Option; DocNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange("Document Type", DocType);
        VendorLedgerEntry.SetRange("Document No.", DocNo);
        VendorLedgerEntry.FindLast;
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"): Integer
    begin
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure CheckPostRestrictions(PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        if not PreviewMode then
            PurchaseHeader.OnCheckPurchasePostRestrictions;

        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.CheckBlockedVendOnDocs(Vendor, true);
        PurchaseHeader.ValidatePurchaserOnPurchHeader(PurchaseHeader, true, true);

        if PurchaseHeader."Pay-to Vendor No." <> PurchaseHeader."Buy-from Vendor No." then begin
            Vendor.Get(PurchaseHeader."Pay-to Vendor No.");
            Vendor.CheckBlockedVendOnDocs(Vendor, true);
        end;

        if PurchaseHeader."Buy-from Contact No." <> '' then
            if Contact.Get(PurchaseHeader."Buy-from Contact No.") then
                Contact.CheckIfPrivacyBlocked(true);
        if PurchaseHeader."Pay-to Contact No." <> '' then
            if Contact.Get(PurchaseHeader."Pay-to Contact No.") then
                Contact.CheckIfPrivacyBlocked(true);
    end;

    local procedure CheckFAPostingPossibility(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineToFind: Record "Purchase Line";
        FADepreciationBook: Record "FA Depreciation Book";
        HasBookValue: Boolean;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Fixed Asset");
        PurchaseLine.SetFilter("No.", '<>%1', '');
        if PurchaseLine.FindSet then
            repeat
                PurchaseLineToFind.CopyFilters(PurchaseLine);
                PurchaseLineToFind.SetRange("No.", PurchaseLine."No.");
                PurchaseLineToFind.SetRange("Depr. until FA Posting Date", not PurchaseLine."Depr. until FA Posting Date");
                if not PurchaseLineToFind.IsEmpty then
                    Error(MixedDerpFAUntilPostingDateErr, PurchaseLine."No.");

                if PurchaseLine."Depr. until FA Posting Date" then begin
                    PurchaseLineToFind.SetRange("Depr. until FA Posting Date", true);
                    PurchaseLineToFind.SetFilter("Line No.", '<>%1', PurchaseLine."Line No.");
                    if not PurchaseLineToFind.IsEmpty then begin
                        HasBookValue := false;
                        FADepreciationBook.SetRange("FA No.", PurchaseLine."No.");
                        FADepreciationBook.FindSet;
                        repeat
                            FADepreciationBook.CalcFields("Book Value");
                            HasBookValue := HasBookValue or (FADepreciationBook."Book Value" <> 0);
                        until (FADepreciationBook.Next = 0) or HasBookValue;
                        if not HasBookValue then
                            Error(CannotPostSameMultipleFAWhenDeprBookValueZeroErr, PurchaseLine."No.");
                    end;
                end;
            until PurchaseLine.Next = 0;
    end;

    local procedure DeleteItemChargeAssgnt(PurchHeader: Record "Purchase Header")
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgntPurch.SetRange("Document Type", PurchHeader."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchHeader."No.");
        if not ItemChargeAssgntPurch.IsEmpty then
            ItemChargeAssgntPurch.DeleteAll;
    end;

    local procedure UpdateItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        with TempItemChargeAssgntPurch do begin
            ClearItemChargeAssgntFilter;
            MarkedOnly(true);
            if FindSet then
                repeat
                    ItemChargeAssgntPurch.Get("Document Type", "Document No.", "Document Line No.", "Line No.");
                    ItemChargeAssgntPurch."Qty. Assigned" :=
                      ItemChargeAssgntPurch."Qty. Assigned" + "Qty. to Assign";
                    ItemChargeAssgntPurch."Qty. to Assign" := 0;
                    ItemChargeAssgntPurch."Amount to Assign" := 0;
                    ItemChargeAssgntPurch.Modify;
                until Next = 0;
        end;
    end;

    local procedure UpdatePurchOrderChargeAssgnt(PurchOrderInvLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line")
    var
        PurchOrderLine2: Record "Purchase Line";
        PurchOrderInvLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        DocumentNo: Code[20];
    begin
        with PurchOrderInvLine do begin
            ClearItemChargeAssgntFilter;
            TempItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
            TempItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
            TempItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
            TempItemChargeAssgntPurch.MarkedOnly(true);
            if TempItemChargeAssgntPurch.FindSet then
                repeat
                    if TempItemChargeAssgntPurch."Applies-to Doc. Type" = "Document Type" then begin
                        PurchOrderInvLine2.Get(
                          TempItemChargeAssgntPurch."Applies-to Doc. Type",
                          TempItemChargeAssgntPurch."Applies-to Doc. No.",
                          TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        if PurchOrderLine."Document Type" = PurchOrderLine."Document Type"::Order then begin
                            if not
                               PurchRcptLine.Get(PurchOrderInvLine2."Receipt No.", PurchOrderInvLine2."Receipt Line No.")
                            then
                                Error(ReceiptLinesDeletedErr);
                            PurchOrderLine2.Get(
                              PurchOrderLine2."Document Type"::Order,
                              PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
                            DocumentNo := PurchRcptLine."Order No.";
                        end else begin
                            if not
                               ReturnShptLine.Get(PurchOrderInvLine2."Return Shipment No.", PurchOrderInvLine2."Return Shipment Line No.")
                            then
                                Error(ReturnShipmentLinesDeletedErr);
                            PurchOrderLine2.Get(
                              PurchOrderLine2."Document Type"::"Return Order",
                              ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
                            DocumentNo := ReturnShptLine."Return Order No.";
                        end;
                        if PurchOrderLine2."Document No." = DocumentNo then
                            UpdatePurchChargeAssgntLines(
                              PurchOrderLine,
                              PurchOrderLine2."Document Type",
                              PurchOrderLine2."Document No.",
                              PurchOrderLine2."Line No.",
                              TempItemChargeAssgntPurch."Qty. to Assign");
                    end else
                        UpdatePurchChargeAssgntLines(
                          PurchOrderLine,
                          TempItemChargeAssgntPurch."Applies-to Doc. Type",
                          TempItemChargeAssgntPurch."Applies-to Doc. No.",
                          TempItemChargeAssgntPurch."Applies-to Doc. Line No.",
                          TempItemChargeAssgntPurch."Qty. to Assign");
                until TempItemChargeAssgntPurch.Next = 0;
        end;
    end;

    local procedure UpdatePurchChargeAssgntLines(PurchOrderLine: Record "Purchase Line"; ApplToDocType: Option; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; QtytoAssign: Decimal)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        TempItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        LastLineNo: Integer;
        TotalToAssign: Decimal;
    begin
        ItemChargeAssgntPurch.SetRange("Document Type", PurchOrderLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchOrderLine."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", PurchOrderLine."Line No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", ApplToDocType);
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", ApplToDocNo);
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", ApplToDocLineNo);
        if ItemChargeAssgntPurch.FindFirst then begin
            GetCurrency(PurchOrderLine."Currency Code");
            ItemChargeAssgntPurch."Qty. Assigned" += QtytoAssign;
            ItemChargeAssgntPurch."Qty. to Assign" -= QtytoAssign;
            if ItemChargeAssgntPurch."Qty. to Assign" < 0 then
                ItemChargeAssgntPurch."Qty. to Assign" := 0;
            ItemChargeAssgntPurch."Amount to Assign" :=
              Round(ItemChargeAssgntPurch."Qty. to Assign" * ItemChargeAssgntPurch."Unit Cost", Currency."Amount Rounding Precision");
            ItemChargeAssgntPurch.Modify;
        end else begin
            ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type");
            ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.");
            ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.");
            ItemChargeAssgntPurch.CalcSums("Qty. to Assign");

            TempItemChargeAssgntPurch2.SetRange("Document Type", TempItemChargeAssgntPurch."Document Type");
            TempItemChargeAssgntPurch2.SetRange("Document No.", TempItemChargeAssgntPurch."Document No.");
            TempItemChargeAssgntPurch2.SetRange("Document Line No.", TempItemChargeAssgntPurch."Document Line No.");
            TempItemChargeAssgntPurch2.CalcSums("Qty. to Assign");

            TotalToAssign := ItemChargeAssgntPurch."Qty. to Assign" +
              TempItemChargeAssgntPurch2."Qty. to Assign";

            if ItemChargeAssgntPurch.FindLast then
                LastLineNo := ItemChargeAssgntPurch."Line No.";

            if PurchOrderLine.Quantity < TotalToAssign then
                repeat
                    TotalToAssign := TotalToAssign - ItemChargeAssgntPurch."Qty. to Assign";
                    ItemChargeAssgntPurch."Qty. to Assign" := 0;
                    ItemChargeAssgntPurch."Amount to Assign" := 0;
                    ItemChargeAssgntPurch.Modify;
                until (ItemChargeAssgntPurch.Next(-1) = 0) or
                      (TotalToAssign = PurchOrderLine.Quantity);

            InsertAssocOrderCharge(
              PurchOrderLine,
              ApplToDocType,
              ApplToDocNo,
              ApplToDocLineNo,
              LastLineNo,
              TempItemChargeAssgntPurch."Applies-to Doc. Line Amount");
        end;
    end;

    local procedure InsertAssocOrderCharge(PurchOrderLine: Record "Purchase Line"; ApplToDocType: Option; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; LastLineNo: Integer; ApplToDocLineAmt: Decimal)
    var
        NewItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        with NewItemChargeAssgntPurch do begin
            Init;
            "Document Type" := PurchOrderLine."Document Type";
            "Document No." := PurchOrderLine."Document No.";
            "Document Line No." := PurchOrderLine."Line No.";
            "Line No." := LastLineNo + 10000;
            "Item Charge No." := TempItemChargeAssgntPurch."Item Charge No.";
            "Item No." := TempItemChargeAssgntPurch."Item No.";
            "Qty. Assigned" := TempItemChargeAssgntPurch."Qty. to Assign";
            "Qty. to Assign" := 0;
            "Amount to Assign" := 0;
            Description := TempItemChargeAssgntPurch.Description;
            "Unit Cost" := TempItemChargeAssgntPurch."Unit Cost";
            "Applies-to Doc. Type" := ApplToDocType;
            "Applies-to Doc. No." := ApplToDocNo;
            "Applies-to Doc. Line No." := ApplToDocLineNo;
            "Applies-to Doc. Line Amount" := ApplToDocLineAmt;
            Insert;
        end;
    end;

    local procedure CopyAndCheckItemCharge(PurchHeader: Record "Purchase Header")
    var
        TempPurchLine: Record "Purchase Line" temporary;
        PurchLine: Record "Purchase Line";
        InvoiceEverything: Boolean;
        AssignError: Boolean;
        QtyNeeded: Decimal;
    begin
        TempItemChargeAssgntPurch.Reset;
        TempItemChargeAssgntPurch.DeleteAll;

        // Check for max qty posting
        with TempPurchLine do begin
            ResetTempLines(TempPurchLine);
            SetRange(Type, Type::"Charge (Item)");
            if IsEmpty then
                exit;

            CopyItemChargeForPurchLine(TempItemChargeAssgntPurch, TempPurchLine);

            SetFilter("Qty. to Invoice", '<>0');
            if FindSet then
                repeat
                    OnCopyAndCheckItemChargeOnBeforeLoop(TempPurchLine, PurchHeader);
                    TestField("Job No.", '');
                    if PurchHeader.Invoice and
                       ("Qty. to Receive" + "Return Qty. to Ship" <> 0) and
                       ((PurchHeader.Ship or PurchHeader.Receive) or
                        (Abs("Qty. to Invoice") >
                         Abs("Qty. Rcd. Not Invoiced" + "Qty. to Receive") +
                         Abs("Ret. Qty. Shpd Not Invd.(Base)" + "Return Qty. to Ship")))
                    then
                        TestField("Line Amount");

                    if not PurchHeader.Receive then
                        "Qty. to Receive" := 0;
                    if not PurchHeader.Ship then
                        "Return Qty. to Ship" := 0;
                    if Abs("Qty. to Invoice") >
                       Abs("Quantity Received" + "Qty. to Receive" +
                         "Return Qty. Shipped" + "Return Qty. to Ship" -
                         "Quantity Invoiced")
                    then
                        "Qty. to Invoice" :=
                          "Quantity Received" + "Qty. to Receive" +
                          "Return Qty. Shipped (Base)" + "Return Qty. to Ship (Base)" -
                          "Quantity Invoiced";

                    CalcFields("Qty. to Assign", "Qty. Assigned");
                    if Abs("Qty. to Assign" + "Qty. Assigned") >
                       Abs("Qty. to Invoice" + "Quantity Invoiced")
                    then begin
                        AdjustQtyToAssignForPurchLine(TempPurchLine);

                        CalcFields("Qty. to Assign", "Qty. Assigned");
                        if Abs("Qty. to Assign" + "Qty. Assigned") >
                           Abs("Qty. to Invoice" + "Quantity Invoiced")
                        then
                            Error(CannotAssignMoreErr,
                              "Qty. to Invoice" + "Quantity Invoiced" - "Qty. Assigned",
                              FieldCaption("Document Type"), "Document Type",
                              FieldCaption("Document No."), "Document No.",
                              FieldCaption("Line No."), "Line No.");

                        CopyItemChargeForPurchLine(TempItemChargeAssgntPurch, TempPurchLine);
                    end;
                    if Quantity = "Qty. to Invoice" + "Quantity Invoiced" then begin
                        if "Qty. to Assign" <> 0 then
                            if Quantity = "Quantity Invoiced" then begin
                                TempItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
                                TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", "Document Type");
                                if TempItemChargeAssgntPurch.FindSet then
                                    repeat
                                        PurchLine.Get(
                                          TempItemChargeAssgntPurch."Applies-to Doc. Type",
                                          TempItemChargeAssgntPurch."Applies-to Doc. No.",
                                          TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                                        if PurchLine.Quantity = PurchLine."Quantity Invoiced" then
                                            Error(CannotAssignInvoicedErr, PurchLine.TableCaption,
                                              PurchLine.FieldCaption("Document Type"), PurchLine."Document Type",
                                              PurchLine.FieldCaption("Document No."), PurchLine."Document No.",
                                              PurchLine.FieldCaption("Line No."), PurchLine."Line No.");
                                    until TempItemChargeAssgntPurch.Next = 0;
                            end;
                        if Quantity <> "Qty. to Assign" + "Qty. Assigned" then
                            AssignError := true;
                    end;

                    if ("Qty. to Assign" + "Qty. Assigned") < ("Qty. to Invoice" + "Quantity Invoiced") then
                        Error(MustAssignItemChargeErr, "No.");

                    // check if all ILEs exist
                    QtyNeeded := "Qty. to Assign";
                    TempItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
                    if TempItemChargeAssgntPurch.FindSet then
                        repeat
                            if (TempItemChargeAssgntPurch."Applies-to Doc. Type" <> "Document Type") or
                               (TempItemChargeAssgntPurch."Applies-to Doc. No." <> "Document No.")
                            then
                                QtyNeeded := QtyNeeded - TempItemChargeAssgntPurch."Qty. to Assign"
                            else begin
                                PurchLine.Get(
                                  TempItemChargeAssgntPurch."Applies-to Doc. Type",
                                  TempItemChargeAssgntPurch."Applies-to Doc. No.",
                                  TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                                if ItemLedgerEntryExist(PurchLine, PurchHeader.Receive or PurchHeader.Ship) then
                                    QtyNeeded := QtyNeeded - TempItemChargeAssgntPurch."Qty. to Assign";
                            end;
                        until TempItemChargeAssgntPurch.Next = 0;

                    if QtyNeeded <> 0 then
                        Error(CannotInvoiceItemChargeErr, "No.");
                until Next = 0;

            // Check purchlines
            if AssignError then
                if PurchHeader."Document Type" in
                   [PurchHeader."Document Type"::Invoice, PurchHeader."Document Type"::"Credit Memo"]
                then
                    InvoiceEverything := true
                else begin
                    Reset;
                    SetFilter(Type, '%1|%2', Type::Item, Type::"Charge (Item)");
                    if FindSet then
                        repeat
                            if PurchHeader.Ship or PurchHeader.Receive then
                                InvoiceEverything :=
                                  Quantity = "Qty. to Invoice" + "Quantity Invoiced"
                            else
                                InvoiceEverything :=
                                  (Quantity = "Qty. to Invoice" + "Quantity Invoiced") and
                                  ("Qty. to Invoice" =
                                   "Qty. Rcd. Not Invoiced" + "Return Qty. Shipped Not Invd.");
                        until (Next = 0) or (not InvoiceEverything);
                end;

            if InvoiceEverything and AssignError then
                Error(MustAssignErr);
        end;
    end;

    local procedure CopyItemChargeForPurchLine(var TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; PurchaseLine: Record "Purchase Line")
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        TempItemChargeAssignmentPurch.Reset;
        TempItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        TempItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        if not TempItemChargeAssignmentPurch.IsEmpty then
            TempItemChargeAssignmentPurch.DeleteAll;

        ItemChargeAssgntPurch.Reset;
        ItemChargeAssgntPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssgntPurch.SetFilter("Qty. to Assign", '<>0');
        if ItemChargeAssgntPurch.FindSet then
            repeat
                TempItemChargeAssignmentPurch.Init;
                TempItemChargeAssignmentPurch := ItemChargeAssgntPurch;
                TempItemChargeAssignmentPurch.Insert;
            until ItemChargeAssgntPurch.Next = 0;
    end;

    local procedure AdjustQtyToAssignForPurchLine(var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        with TempPurchaseLine do begin
            CalcFields("Qty. to Assign");

            ItemChargeAssgntPurch.Reset;
            ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
            ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
            ItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
            ItemChargeAssgntPurch.SetFilter("Qty. to Assign", '<>0');
            if ItemChargeAssgntPurch.FindSet then
                repeat
                    ItemChargeAssgntPurch.Validate("Qty. to Assign",
                      "Qty. to Invoice" * Round(ItemChargeAssgntPurch."Qty. to Assign" / "Qty. to Assign",
                        UOMMgt.QtyRndPrecision));
                    ItemChargeAssgntPurch.Modify;
                until ItemChargeAssgntPurch.Next = 0;

            CalcFields("Qty. to Assign");
            if "Qty. to Assign" < "Qty. to Invoice" then begin
                ItemChargeAssgntPurch.Validate("Qty. to Assign",
                  ItemChargeAssgntPurch."Qty. to Assign" + Abs("Qty. to Invoice" - "Qty. to Assign"));
                ItemChargeAssgntPurch.Modify;
            end;

            if "Qty. to Assign" > "Qty. to Invoice" then begin
                ItemChargeAssgntPurch.Validate("Qty. to Assign",
                  ItemChargeAssgntPurch."Qty. to Assign" - Abs("Qty. to Invoice" - "Qty. to Assign"));
                ItemChargeAssgntPurch.Modify;
            end;
        end;
    end;

    local procedure ClearItemChargeAssgntFilter()
    begin
        TempItemChargeAssgntPurch.SetRange("Document Line No.");
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Type");
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. No.");
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.");
        TempItemChargeAssgntPurch.MarkedOnly(false);
    end;

    local procedure GetItemChargeLine(PurchHeader: Record "Purchase Header"; var ItemChargePurchLine: Record "Purchase Line")
    var
        QtyReceived: Decimal;
        QtyReturnShipped: Decimal;
    begin
        with TempItemChargeAssgntPurch do
            if (ItemChargePurchLine."Document Type" <> "Document Type") or
               (ItemChargePurchLine."Document No." <> "Document No.") or
               (ItemChargePurchLine."Line No." <> "Document Line No.")
            then begin
                ItemChargePurchLine.Get("Document Type", "Document No.", "Document Line No.");
                OnGetItemChargeLineOnAfterGet(ItemChargePurchLine, PurchHeader);
                if not PurchHeader.Receive then
                    ItemChargePurchLine."Qty. to Receive" := 0;
                if not PurchHeader.Ship then
                    ItemChargePurchLine."Return Qty. to Ship" := 0;

                if ItemChargePurchLine."Receipt No." = '' then
                    QtyReceived := ItemChargePurchLine."Quantity Received"
                else
                    QtyReceived := "Qty. to Assign";
                if ItemChargePurchLine."Return Shipment No." = '' then
                    QtyReturnShipped := ItemChargePurchLine."Return Qty. Shipped"
                else
                    QtyReturnShipped := "Qty. to Assign";

                if Abs(ItemChargePurchLine."Qty. to Invoice") >
                   Abs(QtyReceived + ItemChargePurchLine."Qty. to Receive" +
                     QtyReturnShipped + ItemChargePurchLine."Return Qty. to Ship" -
                     ItemChargePurchLine."Quantity Invoiced")
                then
                    ItemChargePurchLine."Qty. to Invoice" :=
                      QtyReceived + ItemChargePurchLine."Qty. to Receive" +
                      QtyReturnShipped + ItemChargePurchLine."Return Qty. to Ship" -
                      ItemChargePurchLine."Quantity Invoiced";
            end;
    end;

    local procedure CalcQtyToInvoice(QtyToHandle: Decimal; QtyToInvoice: Decimal): Decimal
    begin
        if Abs(QtyToHandle) > Abs(QtyToInvoice) then
            exit(QtyToHandle);

        exit(QtyToInvoice);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get;
        GLSetupRead := true;
    end;

    local procedure CheckWarehouse(var TempItemPurchLine: Record "Purchase Line" temporary)
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(TempItemPurchLine, IsHandled);
        if IsHandled then
            exit;
        with TempItemPurchLine do begin
            if "Prod. Order No." <> '' then
                exit;
            SetRange(Type, Type::Item);
            SetRange("Drop Shipment", false);
            OnCheckWarehouseOnAfterSetFilters(TempItemPurchLine);
            if FindSet then
                repeat
                    GetLocation("Location Code");
                    case "Document Type" of
                        "Document Type"::Order:
                            if ((Location."Require Receive" or Location."Require Put-away") and (Quantity >= 0)) or
                               ((Location."Require Shipment" or Location."Require Pick") and (Quantity < 0))
                            then begin
                                if Location."Directed Put-away and Pick" then
                                    ShowError := true
                                else
                                    if WhseValidateSourceLine.WhseLinesExist(
                                         DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", 0, Quantity)
                                    then
                                        ShowError := true;
                            end;
                        "Document Type"::"Return Order":
                            if ((Location."Require Receive" or Location."Require Put-away") and (Quantity < 0)) or
                               ((Location."Require Shipment" or Location."Require Pick") and (Quantity >= 0))
                            then begin
                                if Location."Directed Put-away and Pick" then
                                    ShowError := true
                                else
                                    if WhseValidateSourceLine.WhseLinesExist(
                                         DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", 0, Quantity)
                                    then
                                        ShowError := true;
                            end;
                        "Document Type"::Invoice, "Document Type"::"Credit Memo":
                            if Location."Directed Put-away and Pick" then
                                Location.TestField("Adjustment Bin Code");
                    end;
                    if ShowError then
                        Error(
                          WarehouseRequiredErr,
                          FieldCaption("Document Type"), "Document Type",
                          FieldCaption("Document No."), "Document No.",
                          FieldCaption("Line No."), "Line No.");
                until Next = 0;
        end;
    end;

    local procedure CreateWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    var
        WhseMgt: Codeunit "Whse. Management";
        WMSMgt: Codeunit "WMS Management";
    begin
        with PurchLine do begin
            WMSMgt.CheckAdjmtBin(Location, ItemJnlLine.Quantity, true);
            WMSMgt.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, false);
            TempWhseJnlLine."Source Type" := DATABASE::"Purchase Line";
            TempWhseJnlLine."Source Subtype" := "Document Type";
            TempWhseJnlLine."Source Document" := WhseMgt.GetSourceDocument(TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
            TempWhseJnlLine."Source No." := "Document No.";
            TempWhseJnlLine."Source Line No." := "Line No.";
            TempWhseJnlLine."Source Code" := SrcCode;
            case "Document Type" of
                "Document Type"::Order:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rcpt.";
                "Document Type"::Invoice:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted P. Inv.";
                "Document Type"::"Credit Memo":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted P. Cr. Memo";
                "Document Type"::"Return Order":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
            end;
            TempWhseJnlLine."Reference No." := ItemJnlLine."Document No.";
        end;
    end;

    local procedure WhseHandlingRequired(PurchLine: Record "Purchase Line"): Boolean
    var
        WhseSetup: Record "Warehouse Setup";
        IsHandled: Boolean;
        Required: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseHandlingRequired(PurchLine, Required, IsHandled);
        if IsHandled then
            exit(Required);

        if (PurchLine.Type = PurchLine.Type::Item) and (not PurchLine."Drop Shipment") then begin
            if PurchLine."Location Code" = '' then begin
                WhseSetup.Get;
                if PurchLine."Document Type" = PurchLine."Document Type"::"Return Order" then
                    exit(WhseSetup."Require Pick");

                exit(WhseSetup."Require Receive");
            end;

            GetLocation(PurchLine."Location Code");
            if PurchLine."Document Type" = PurchLine."Document Type"::"Return Order" then
                exit(Location."Require Pick");

            exit(Location."Require Receive");
        end;
        exit(false);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure InsertRcptEntryRelation(var PurchRcptLine: Record "Purch. Rcpt. Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempHandlingSpecification.CopySpecification(TempTrackingSpecificationInv);
        TempHandlingSpecification.Reset;
        if TempHandlingSpecification.FindSet then begin
            repeat
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ItemEntryRelation.TransferFieldsPurchRcptLine(PurchRcptLine);
                ItemEntryRelation.Insert;
            until TempHandlingSpecification.Next = 0;
            TempHandlingSpecification.DeleteAll;
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    local procedure InsertReturnEntryRelation(var ReturnShptLine: Record "Return Shipment Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempHandlingSpecification.CopySpecification(TempTrackingSpecificationInv);
        TempHandlingSpecification.Reset;
        if TempHandlingSpecification.FindSet then begin
            repeat
                ItemEntryRelation.Init;
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ItemEntryRelation.TransferFieldsReturnShptLine(ReturnShptLine);
                ItemEntryRelation.Insert;
            until TempHandlingSpecification.Next = 0;
            TempHandlingSpecification.DeleteAll;
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    local procedure CheckTrackingSpecification(PurchHeader: Record "Purchase Header"; var TempItemPurchLine: Record "Purchase Line" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJnlLine: Record "Item Journal Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        PurchLineQtyToHandle: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
        CheckPurchLine: Boolean;
    begin
        // if a PurchaseLine is posted with ItemTracking then tracked quantity must be equal to posted quantity
        if not (PurchHeader."Document Type" in
                [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"])
        then
            exit;

        OnBeforeCheckTrackingSpecification(PurchHeader, TempItemPurchLine);

        TrackingQtyToHandle := 0;

        with TempItemPurchLine do begin
            SetRange(Type, Type::Item);
            if PurchHeader.Receive then begin
                SetFilter("Quantity Received", '<>%1', 0);
                ErrorFieldCaption := FieldCaption("Qty. to Receive");
            end else begin
                SetFilter("Return Qty. Shipped", '<>%1', 0);
                ErrorFieldCaption := FieldCaption("Return Qty. to Ship");
            end;

            if FindSet then begin
                ReservationEntry."Source Type" := DATABASE::"Purchase Line";
                ReservationEntry."Source Subtype" := PurchHeader."Document Type";
                SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
                repeat
                    // Only Item where no SerialNo or LotNo is required
                    Item.Get("No.");
                    if Item."Item Tracking Code" <> '' then begin
                        Inbound := (Quantity * SignFactor) > 0;
                        ItemTrackingCode.Code := Item."Item Tracking Code";
                        ItemTrackingManagement.GetItemTrackingSettings(ItemTrackingCode,
                          ItemJnlLine."Entry Type"::Purchase, Inbound,
                          SNRequired, LotRequired, SNInfoRequired, LotInfoRequired);
                        CheckPurchLine := not SNRequired and not LotRequired;
                        if CheckPurchLine then
                            CheckPurchLine := CheckTrackingExists(TempItemPurchLine);
                    end else
                        CheckPurchLine := false;

                    TrackingQtyToHandle := 0;

                    if CheckPurchLine then begin
                        TrackingQtyToHandle := GetTrackingQuantities(TempItemPurchLine) * SignFactor;
                        if PurchHeader.Receive then
                            PurchLineQtyToHandle := "Qty. to Receive (Base)"
                        else
                            PurchLineQtyToHandle := "Return Qty. to Ship (Base)";
                        if TrackingQtyToHandle <> PurchLineQtyToHandle then
                            Error(ItemTrackQuantityMismatchErr, ErrorFieldCaption);
                    end;
                until Next = 0;
            end;
            if PurchHeader.Receive then
                SetRange("Quantity Received")
            else
                SetRange("Return Qty. Shipped");
        end;
    end;

    local procedure CheckTrackingExists(PurchLine: Record "Purchase Line"): Boolean
    begin
        exit(
          ItemTrackingMgt.ItemTrackingExistsOnDocumentLine(
            DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No."));
    end;

    local procedure GetTrackingQuantities(PurchLine: Record "Purchase Line"): Decimal
    begin
        exit(
          ItemTrackingMgt.CalcQtyToHandleForTrackedQtyOnDocumentLine(
            DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No."));
    end;

    local procedure SaveInvoiceSpecification(var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
        TempInvoicingSpecification.Reset;
        if TempInvoicingSpecification.FindSet then begin
            repeat
                TempInvoicingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Quantity actual Handled (Base)";
                TempInvoicingSpecification."Quantity actual Handled (Base)" := 0;
                TempTrackingSpecification := TempInvoicingSpecification;
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::MODIFY;
                if not TempTrackingSpecification.Insert then begin
                    TempTrackingSpecification.Get(TempInvoicingSpecification."Entry No.");
                    TempTrackingSpecification."Qty. to Invoice (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                    TempTrackingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                    TempTrackingSpecification."Qty. to Invoice" += TempInvoicingSpecification."Qty. to Invoice";
                    TempTrackingSpecification.Modify;
                end;
            until TempInvoicingSpecification.Next = 0;
            TempInvoicingSpecification.DeleteAll;
        end;
    end;

    local procedure InsertTrackingSpecification(PurchHeader: Record "Purchase Header")
    begin
        TempTrackingSpecification.Reset;
        if not TempTrackingSpecification.IsEmpty then begin
            TempTrackingSpecification.InsertSpecification;
            ReservePurchLine.UpdateItemTrackingAfterPosting(PurchHeader);
        end;
    end;

    local procedure CalcBaseQty(ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal): Decimal
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Item.Get(ItemNo);
        exit(Round(Qty * UOMMgt.GetQtyPerUnitOfMeasure(Item, UOMCode), UOMMgt.QtyRndPrecision));
    end;

    local procedure InsertValueEntryRelation()
    var
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        TempValueEntryRelation.Reset;
        if TempValueEntryRelation.FindSet then begin
            repeat
                ValueEntryRelation := TempValueEntryRelation;
                ValueEntryRelation.Insert;
            until TempValueEntryRelation.Next = 0;
            TempValueEntryRelation.DeleteAll;
        end;
    end;

    local procedure PostItemCharge(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal; IndirectCostPct: Decimal)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        PurchLineToPost: Record "Purchase Line";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        with TempItemChargeAssgntPurch do begin
            PurchLineToPost := PurchLine;
            PurchLineToPost."No." := "Item No.";
            PurchLineToPost."Line No." := "Document Line No.";
            PurchLineToPost."Appl.-to Item Entry" := ItemEntryNo;
            PurchLineToPost."Indirect Cost %" := IndirectCostPct;

            PurchLineToPost.Amount := AmountToAssign;

            if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                PurchLineToPost.Amount := -PurchLineToPost.Amount;

            if PurchLineToPost."Currency Code" <> '' then
                PurchLineToPost."Unit Cost" := Round(
                    PurchLineToPost.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision")
            else
                PurchLineToPost."Unit Cost" := Round(
                    PurchLineToPost.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

            TotalChargeAmt := TotalChargeAmt + PurchLineToPost.Amount;
            if PurchHeader."Currency Code" <> '' then
                PurchLineToPost.Amount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, PurchHeader."Currency Code", TotalChargeAmt, PurchHeader."Currency Factor");

            PurchLineToPost.Amount := Round(PurchLineToPost.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
            if PurchHeader."Currency Code" <> '' then
                TotalChargeAmtLCY := TotalChargeAmtLCY + PurchLineToPost.Amount;
            PurchLineToPost."Unit Cost (LCY)" :=
              Round(
                PurchLineToPost.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

            PurchLineToPost."Inv. Discount Amount" := Round(
                PurchLine."Inv. Discount Amount" / PurchLine.Quantity * QtyToAssign,
                GLSetup."Amount Rounding Precision");

            PurchLineToPost."Line Discount Amount" := Round(
                PurchLine."Line Discount Amount" / PurchLine.Quantity * QtyToAssign,
                GLSetup."Amount Rounding Precision");
            PurchLineToPost."Line Amount" := Round(
                PurchLine."Line Amount" / PurchLine.Quantity * QtyToAssign,
                GLSetup."Amount Rounding Precision");
            UpdatePurchLineDimSetIDFromAppliedEntry(PurchLineToPost, PurchLine);
            PurchLine."Inv. Discount Amount" := PurchLine."Inv. Discount Amount" - PurchLineToPost."Inv. Discount Amount";
            PurchLine."Line Discount Amount" := PurchLine."Line Discount Amount" - PurchLineToPost."Line Discount Amount";
            PurchLine."Line Amount" := PurchLine."Line Amount" - PurchLineToPost."Line Amount";
            PurchLine.Quantity := PurchLine.Quantity - QtyToAssign;

            OnPostItemChargeOnBeforePostItemJnlLine(PurchLineToPost, PurchLine, QtyToAssign);

            PostItemJnlLine(
              PurchHeader, PurchLineToPost, 0, 0, QuantityBase, QuantityBase,
              PurchLineToPost."Appl.-to Item Entry", "Item Charge No.", DummyTrackingSpecification);

            OnPostItemChargeOnAfterPostItemJnlLine(PurchHeader, PurchLineToPost);
        end;
    end;

    local procedure SaveTempWhseSplitSpec(PurchLine3: Record "Purchase Line")
    begin
        TempWhseSplitSpecification.Reset;
        TempWhseSplitSpecification.DeleteAll;
        if TempHandlingSpecification.FindSet then
            repeat
                TempWhseSplitSpecification := TempHandlingSpecification;
                TempWhseSplitSpecification."Source Type" := DATABASE::"Purchase Line";
                TempWhseSplitSpecification."Source Subtype" := PurchLine3."Document Type";
                TempWhseSplitSpecification."Source ID" := PurchLine3."Document No.";
                TempWhseSplitSpecification."Source Ref. No." := PurchLine3."Line No.";
                TempWhseSplitSpecification.Insert;
            until TempHandlingSpecification.Next = 0;

        OnAfterSaveTempWhseSplitSpec(PurchLine3, TempWhseSplitSpecification);
    end;

    local procedure TransferReservToItemJnlLine(var SalesOrderLine: Record "Sales Line"; var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line"; QtyToBeShippedBase: Decimal; ApplySpecificItemTracking: Boolean)
    var
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        RemainingQuantity: Decimal;
        CheckApplFromItemEntry: Boolean;
    begin
        // Handle Item Tracking and reservations, also on drop shipment
        if QtyToBeShippedBase = 0 then
            exit;

        if not ApplySpecificItemTracking then
            ReserveSalesLine.TransferSalesLineToItemJnlLine(
              SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
        else begin
            ReserveSalesLine.SetApplySpecificItemTracking(true);
            TempTrackingSpecification.Reset;
            TempTrackingSpecification.SetSourceFilter(
              DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.", false);
            TempTrackingSpecification.SetSourceFilter('', 0);
            if TempTrackingSpecification.IsEmpty then
                ReserveSalesLine.TransferSalesLineToItemJnlLine(
                  SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
            else begin
                ReserveSalesLine.SetOverruleItemTracking(true);
                TempTrackingSpecification.FindSet;
                if TempTrackingSpecification."Quantity (Base)" / QtyToBeShippedBase < 0 then
                    Error(ItemTrackingWrongSignErr);
                repeat
                    ItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification);
                    ItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Item Ledger Entry No.";
                    RemainingQuantity :=
                      ReserveSalesLine.TransferSalesLineToItemJnlLine(
                        SalesOrderLine, ItemJnlLine, TempTrackingSpecification."Quantity (Base)", CheckApplFromItemEntry, false);
                    if RemainingQuantity <> 0 then
                        Error(ItemTrackingMismatchErr);
                until TempTrackingSpecification.Next = 0;
                ItemJnlLine.ClearTracking;
                ItemJnlLine."Applies-to Entry" := 0;
            end;
        end;
    end;

    procedure SetWhseRcptHeader(var WhseRcptHeader2: Record "Warehouse Receipt Header")
    begin
        WhseRcptHeader := WhseRcptHeader2;
        TempWhseRcptHeader := WhseRcptHeader;
        TempWhseRcptHeader.Insert;
    end;

    procedure SetWhseShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptHeader := WhseShptHeader2;
        TempWhseShptHeader := WhseShptHeader;
        TempWhseShptHeader.Insert;
    end;

    local procedure CreatePrepmtLines(PurchHeader: Record "Purchase Header"; CompleteFunctionality: Boolean)
    var
        GLAcc: Record "G/L Account";
        TempPurchLine: Record "Purchase Line" temporary;
        TempExtTextLine: Record "Extended Text Line" temporary;
        GenPostingSetup: Record "General Posting Setup";
        TempPrepmtPurchLine: Record "Purchase Line" temporary;
        TransferExtText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
        Fraction: Decimal;
        VATDifference: Decimal;
        TempLineFound: Boolean;
        PrepmtAmtToDeduct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePrepmtLines(PurchHeader, TempPrepmtPurchLine, CompleteFunctionality, IsHandled);
        if IsHandled then
            exit;

        GetGLSetup;
        with TempPurchLine do begin
            FillTempLines(PurchHeader, TempPurchLineGlobal);
            ResetTempLines(TempPurchLine);
            if not FindLast then
                exit;
            NextLineNo := "Line No." + 10000;
            SetFilter(Quantity, '>0');
            SetFilter("Qty. to Invoice", '>0');
            if FindSet then begin
                if CompleteFunctionality and ("Document Type" = "Document Type"::Invoice) then
                    TestGetRcptPPmtAmtToDeduct;
                repeat
                    if CompleteFunctionality then
                        if PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice then begin
                            if not PurchHeader.Receive and ("Qty. to Invoice" = Quantity - "Quantity Invoiced") then
                                if "Qty. Rcd. Not Invoiced" < "Qty. to Invoice" then
                                    Validate("Qty. to Invoice", "Qty. Rcd. Not Invoiced");
                            Fraction := ("Qty. to Invoice" + "Quantity Invoiced") / Quantity;

                            if "Prepayment %" <> 100 then
                                case true of
                                    ("Prepmt Amt to Deduct" <> 0) and
                                  (Round(Fraction * "Line Amount", Currency."Amount Rounding Precision") < "Prepmt Amt to Deduct"):
                                        FieldError(
                                          "Prepmt Amt to Deduct",
                                          StrSubstNo(
                                            CannotBeGreaterThanErr,
                                            Round(Fraction * "Line Amount", Currency."Amount Rounding Precision")));
                                    ("Prepmt. Amt. Inv." <> 0) and
                                  (Round((1 - Fraction) * "Line Amount", Currency."Amount Rounding Precision") <
                                   Round(
                                     Round(
                                       Round("Direct Unit Cost" * (Quantity - "Quantity Invoiced" - "Qty. to Invoice"),
                                         Currency."Amount Rounding Precision") *
                                       (1 - "Line Discount %" / 100), Currency."Amount Rounding Precision") *
                                     "Prepayment %" / 100, Currency."Amount Rounding Precision")):
                                        FieldError(
                                          "Prepmt Amt to Deduct",
                                          StrSubstNo(
                                            CannotBeSmallerThanErr,
                                            Round(
                                              "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" -
                                              (1 - Fraction) * "Line Amount", Currency."Amount Rounding Precision")));
                                end;
                        end;
                    if "Prepmt Amt to Deduct" <> 0 then begin
                        if ("Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
                           ("Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                        then
                            GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                        GLAcc.Get(GenPostingSetup.GetPurchPrepmtAccount);
                        TempLineFound := false;
                        if PurchHeader."Compress Prepayment" then begin
                            TempPrepmtPurchLine.SetRange("No.", GLAcc."No.");
                            TempPrepmtPurchLine.SetRange("Job No.", "Job No.");
                            TempPrepmtPurchLine.SetRange("Dimension Set ID", "Dimension Set ID");
                            TempLineFound := TempPrepmtPurchLine.FindFirst;
                        end;
                        if TempLineFound then begin
                            PrepmtAmtToDeduct :=
                              TempPrepmtPurchLine."Prepmt Amt to Deduct" +
                              InsertedPrepmtVATBaseToDeduct(
                                PurchHeader, TempPurchLine, TempPrepmtPurchLine."Line No.", TempPrepmtPurchLine."Direct Unit Cost");
                            VATDifference := TempPrepmtPurchLine."VAT Difference";
                            TempPrepmtPurchLine.Validate(
                              "Direct Unit Cost", TempPrepmtPurchLine."Direct Unit Cost" + "Prepmt Amt to Deduct");
                            TempPrepmtPurchLine.Validate("VAT Difference", VATDifference - "Prepmt VAT Diff. to Deduct");
                            TempPrepmtPurchLine."Prepmt Amt to Deduct" := PrepmtAmtToDeduct;
                            if "Prepayment %" < TempPrepmtPurchLine."Prepayment %" then
                                TempPrepmtPurchLine."Prepayment %" := "Prepayment %";
                            OnBeforeTempPrepmtPurchLineModify(TempPrepmtPurchLine, TempPurchLine, PurchHeader, CompleteFunctionality);
                            TempPrepmtPurchLine.Modify;
                        end else begin
                            TempPrepmtPurchLine.Init;
                            TempPrepmtPurchLine."Document Type" := PurchHeader."Document Type";
                            TempPrepmtPurchLine."Document No." := PurchHeader."No.";
                            TempPrepmtPurchLine."Line No." := 0;
                            TempPrepmtPurchLine."System-Created Entry" := true;
                            if CompleteFunctionality then
                                TempPrepmtPurchLine.Validate(Type, TempPrepmtPurchLine.Type::"G/L Account")
                            else
                                TempPrepmtPurchLine.Type := TempPrepmtPurchLine.Type::"G/L Account";
                            TempPrepmtPurchLine.Validate("No.", GenPostingSetup."Purch. Prepayments Account");
                            TempPrepmtPurchLine.Validate(Quantity, -1);
                            TempPrepmtPurchLine."Qty. to Receive" := TempPrepmtPurchLine.Quantity;
                            TempPrepmtPurchLine."Qty. to Invoice" := TempPrepmtPurchLine.Quantity;
                            PrepmtAmtToDeduct := InsertedPrepmtVATBaseToDeduct(PurchHeader, TempPurchLine, NextLineNo, 0);
                            TempPrepmtPurchLine.Validate("Direct Unit Cost", "Prepmt Amt to Deduct");
                            TempPrepmtPurchLine.Validate("VAT Difference", -"Prepmt VAT Diff. to Deduct");
                            TempPrepmtPurchLine."Prepmt Amt to Deduct" := PrepmtAmtToDeduct;
                            TempPrepmtPurchLine."Prepayment %" := "Prepayment %";
                            TempPrepmtPurchLine."Prepayment Line" := true;
                            TempPrepmtPurchLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                            TempPrepmtPurchLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                            TempPrepmtPurchLine."Dimension Set ID" := "Dimension Set ID";
                            TempPrepmtPurchLine."Job No." := "Job No.";
                            TempPrepmtPurchLine."Job Task No." := "Job Task No.";
                            TempPrepmtPurchLine."Job Line Type" := "Job Line Type";
                            TempPrepmtPurchLine."Line No." := NextLineNo;
                            NextLineNo := NextLineNo + 10000;
                            OnBeforeTempPrepmtPurchLineInsert(TempPrepmtPurchLine, TempPurchLine, PurchHeader, CompleteFunctionality);
                            TempPrepmtPurchLine.Insert;

                            TransferExtText.PrepmtGetAnyExtText(
                              TempPrepmtPurchLine."No.", DATABASE::"Purch. Inv. Line",
                              PurchHeader."Document Date", PurchHeader."Language Code", TempExtTextLine);
                            if TempExtTextLine.Find('-') then
                                repeat
                                    TempPrepmtPurchLine.Init;
                                    TempPrepmtPurchLine.Description := TempExtTextLine.Text;
                                    TempPrepmtPurchLine."System-Created Entry" := true;
                                    TempPrepmtPurchLine."Prepayment Line" := true;
                                    TempPrepmtPurchLine."Line No." := NextLineNo;
                                    NextLineNo := NextLineNo + 10000;
                                    TempPrepmtPurchLine.Insert;
                                until TempExtTextLine.Next = 0;
                        end;
                    end;
                until Next = 0
            end;
        end;
        DividePrepmtAmountLCY(TempPrepmtPurchLine, PurchHeader);
        if TempPrepmtPurchLine.FindSet then
            repeat
                TempPurchLineGlobal := TempPrepmtPurchLine;
                TempPurchLineGlobal.Insert;
            until TempPrepmtPurchLine.Next = 0;
    end;

    local procedure InsertedPrepmtVATBaseToDeduct(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PrepmtLineNo: Integer; TotalPrepmtAmtToDeduct: Decimal): Decimal
    var
        PrepmtVATBaseToDeduct: Decimal;
    begin
        with PurchLine do begin
            if PurchHeader."Prices Including VAT" then
                PrepmtVATBaseToDeduct :=
                  Round(
                    (TotalPrepmtAmtToDeduct + "Prepmt Amt to Deduct") / (1 + "Prepayment VAT %" / 100),
                    Currency."Amount Rounding Precision") -
                  Round(
                    TotalPrepmtAmtToDeduct / (1 + "Prepayment VAT %" / 100),
                    Currency."Amount Rounding Precision")
            else
                PrepmtVATBaseToDeduct := "Prepmt Amt to Deduct";
        end;
        with TempPrepmtDeductLCYPurchLine do begin
            TempPrepmtDeductLCYPurchLine := PurchLine;
            if "Document Type" = "Document Type"::Order then
                "Qty. to Invoice" := GetQtyToInvoice(PurchLine, PurchHeader.Receive)
            else
                GetLineDataFromOrder(TempPrepmtDeductLCYPurchLine);
            if ("Prepmt Amt to Deduct" = 0) or ("Document Type" = "Document Type"::Invoice) then
                CalcPrepaymentToDeduct;
            "Line Amount" := GetLineAmountToHandleInclPrepmt("Qty. to Invoice");
            "Attached to Line No." := PrepmtLineNo;
            "VAT Base Amount" := PrepmtVATBaseToDeduct;
            Insert;
        end;

        OnAfterInsertedPrepmtVATBaseToDeduct(
          PurchHeader, PurchLine, PrepmtLineNo, TotalPrepmtAmtToDeduct, TempPrepmtDeductLCYPurchLine, PrepmtVATBaseToDeduct);

        exit(PrepmtVATBaseToDeduct);
    end;

    local procedure DividePrepmtAmountLCY(var PrepmtPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        ActualCurrencyFactor: Decimal;
    begin
        with PrepmtPurchLine do begin
            Reset;
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet then
                repeat
                    if PurchHeader."Currency Code" <> '' then
                        ActualCurrencyFactor :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              PurchHeader."Posting Date",
                              PurchHeader."Currency Code",
                              "Prepmt Amt to Deduct",
                              PurchHeader."Currency Factor")) /
                          "Prepmt Amt to Deduct"
                    else
                        ActualCurrencyFactor := 1;

                    UpdatePrepmtAmountInvBuf("Line No.", ActualCurrencyFactor);
                until Next = 0;
            Reset;
        end;
    end;

    local procedure UpdatePrepmtAmountInvBuf(PrepmtSalesLineNo: Integer; CurrencyFactor: Decimal)
    var
        PrepmtAmtRemainder: Decimal;
    begin
        with TempPrepmtDeductLCYPurchLine do begin
            Reset;
            SetRange("Attached to Line No.", PrepmtSalesLineNo);
            if FindSet(true) then
                repeat
                    "Prepmt. Amount Inv. (LCY)" :=
                      CalcRoundedAmount(CurrencyFactor * "VAT Base Amount", PrepmtAmtRemainder);
                    Modify;
                until Next = 0;
        end;
    end;

    local procedure AdjustPrepmtAmountLCY(PurchHeader: Record "Purchase Header"; var PrepmtPurchLine: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
        PurchInvoiceLine: Record "Purchase Line";
        DeductionFactor: Decimal;
        PrepmtVATPart: Decimal;
        PrepmtVATAmtRemainder: Decimal;
        TotalRoundingAmount: array[2] of Decimal;
        TotalPrepmtAmount: array[2] of Decimal;
        FinalInvoice: Boolean;
        PricesInclVATRoundingAmount: array[2] of Decimal;
    begin
        if PrepmtPurchLine."Prepayment Line" then begin
            PrepmtVATPart :=
              (PrepmtPurchLine."Amount Including VAT" - PrepmtPurchLine.Amount) / PrepmtPurchLine."Direct Unit Cost";

            with TempPrepmtDeductLCYPurchLine do begin
                Reset;
                SetRange("Attached to Line No.", PrepmtPurchLine."Line No.");
                if FindSet(true) then begin
                    FinalInvoice := IsFinalInvoice;
                    repeat
                        PurchLine := TempPrepmtDeductLCYPurchLine;
                        PurchLine.Find;
                        if "Document Type" = "Document Type"::Invoice then begin
                            PurchInvoiceLine := PurchLine;
                            GetPurchOrderLine(PurchLine, PurchInvoiceLine);
                            PurchLine."Qty. to Invoice" := PurchInvoiceLine."Qty. to Invoice";
                        end;
                        if PurchLine."Qty. to Invoice" <> "Qty. to Invoice" then
                            PurchLine."Prepmt Amt to Deduct" := CalcPrepmtAmtToDeduct(PurchLine, PurchHeader.Receive);
                        DeductionFactor :=
                          PurchLine."Prepmt Amt to Deduct" /
                          (PurchLine."Prepmt. Amt. Inv." - PurchLine."Prepmt Amt Deducted");

                        "Prepmt. VAT Amount Inv. (LCY)" :=
                          -CalcRoundedAmount(PurchLine."Prepmt Amt to Deduct" * PrepmtVATPart, PrepmtVATAmtRemainder);
                        if ("Prepayment %" <> 100) or IsFinalInvoice or ("Currency Code" <> '') then
                            CalcPrepmtRoundingAmounts(TempPrepmtDeductLCYPurchLine, PurchLine, DeductionFactor, TotalRoundingAmount);
                        Modify;

                        if PurchHeader."Prices Including VAT" then
                            if (("Prepayment %" <> 100) or IsFinalInvoice) and (DeductionFactor = 1) then begin
                                PricesInclVATRoundingAmount[1] := TotalRoundingAmount[1];
                                PricesInclVATRoundingAmount[2] := TotalRoundingAmount[2];
                            end;

                        if "VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT" then
                            TotalPrepmtAmount[1] += "Prepmt. Amount Inv. (LCY)";
                        TotalPrepmtAmount[2] += "Prepmt. VAT Amount Inv. (LCY)";
                        FinalInvoice := FinalInvoice and IsFinalInvoice;
                    until Next = 0;
                end;
            end;

            UpdatePrepmtPurchLineWithRounding(
              PrepmtPurchLine, TotalRoundingAmount, TotalPrepmtAmount,
              FinalInvoice, PricesInclVATRoundingAmount);
        end;
    end;

    local procedure CalcPrepmtAmtToDeduct(PurchLine: Record "Purchase Line"; Receive: Boolean): Decimal
    begin
        with PurchLine do begin
            "Qty. to Invoice" := GetQtyToInvoice(PurchLine, Receive);
            CalcPrepaymentToDeduct;
            exit("Prepmt Amt to Deduct");
        end;
    end;

    local procedure GetQtyToInvoice(PurchLine: Record "Purchase Line"; Receive: Boolean): Decimal
    var
        AllowedQtyToInvoice: Decimal;
    begin
        with PurchLine do begin
            AllowedQtyToInvoice := "Qty. Rcd. Not Invoiced";
            if Receive then
                AllowedQtyToInvoice := AllowedQtyToInvoice + "Qty. to Receive";
            if "Qty. to Invoice" > AllowedQtyToInvoice then
                exit(AllowedQtyToInvoice);
            exit("Qty. to Invoice");
        end;
    end;

    local procedure GetLineDataFromOrder(var PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchOrderLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            PurchRcptLine.Get("Receipt No.", "Receipt Line No.");
            PurchOrderLine.Get("Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");

            Quantity := PurchOrderLine.Quantity;
            "Qty. Rcd. Not Invoiced" := PurchOrderLine."Qty. Rcd. Not Invoiced";
            "Quantity Invoiced" := PurchOrderLine."Quantity Invoiced";
            "Prepmt Amt Deducted" := PurchOrderLine."Prepmt Amt Deducted";
            "Prepmt. Amt. Inv." := PurchOrderLine."Prepmt. Amt. Inv.";
            "Line Discount Amount" := PurchOrderLine."Line Discount Amount";
        end;
    end;

    local procedure CalcPrepmtRoundingAmounts(var PrepmtPurchLineBuf: Record "Purchase Line"; PurchLine: Record "Purchase Line"; DeductionFactor: Decimal; var TotalRoundingAmount: array[2] of Decimal)
    var
        RoundingAmount: array[2] of Decimal;
    begin
        with PrepmtPurchLineBuf do begin
            if "VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT" then begin
                RoundingAmount[1] :=
                  "Prepmt. Amount Inv. (LCY)" - Round(DeductionFactor * PurchLine."Prepmt. Amount Inv. (LCY)");
                "Prepmt. Amount Inv. (LCY)" := "Prepmt. Amount Inv. (LCY)" - RoundingAmount[1];
                TotalRoundingAmount[1] += RoundingAmount[1];
            end;
            RoundingAmount[2] :=
              "Prepmt. VAT Amount Inv. (LCY)" - Round(DeductionFactor * PurchLine."Prepmt. VAT Amount Inv. (LCY)");
            "Prepmt. VAT Amount Inv. (LCY)" := "Prepmt. VAT Amount Inv. (LCY)" - RoundingAmount[2];
            TotalRoundingAmount[2] += RoundingAmount[2];
        end;
    end;

    local procedure UpdatePrepmtPurchLineWithRounding(var PrepmtPurchLine: Record "Purchase Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal)
    var
        NewAmountIncludingVAT: Decimal;
        Prepmt100PctVATRoundingAmt: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        OnBeforeUpdatePrepmtPurchLineWithRounding(
          PrepmtPurchLine, TotalRoundingAmount, TotalPrepmtAmount, FinalInvoice, PricesInclVATRoundingAmount,
          TotalPurchLine, TotalPurchLineLCY);

        with PrepmtPurchLine do begin
            NewAmountIncludingVAT := TotalPrepmtAmount[1] + TotalPrepmtAmount[2] + TotalRoundingAmount[1] + TotalRoundingAmount[2];
            if "Prepayment %" = 100 then
                TotalRoundingAmount[1] -= "Amount Including VAT" + NewAmountIncludingVAT;
            AmountRoundingPrecision :=
              GetAmountRoundingPrecisionInLCY("Document Type", "Document No.", "Currency Code");

            if (Abs(TotalRoundingAmount[1]) <= AmountRoundingPrecision) and
               (Abs(TotalRoundingAmount[2]) <= AmountRoundingPrecision)
            then begin
                if "Prepayment %" = 100 then
                    Prepmt100PctVATRoundingAmt := TotalRoundingAmount[1];
                TotalRoundingAmount[1] := 0;
            end;
            "Prepmt. Amount Inv. (LCY)" := -TotalRoundingAmount[1];
            Amount := -(TotalPrepmtAmount[1] + TotalRoundingAmount[1]);

            if (PricesInclVATRoundingAmount[1] <> 0) and (TotalRoundingAmount[1] = 0) then begin
                if ("Prepayment %" = 100) and FinalInvoice and
                   (Amount - TotalPrepmtAmount[2] = "Amount Including VAT")
                then
                    Prepmt100PctVATRoundingAmt := 0;
                PricesInclVATRoundingAmount[1] := 0;
            end;

            if ((TotalRoundingAmount[2] <> 0) or FinalInvoice) and (TotalRoundingAmount[1] = 0) then begin
                if ("Prepayment %" = 100) and ("Prepmt. Amount Inv. (LCY)" = 0) then
                    Prepmt100PctVATRoundingAmt += TotalRoundingAmount[2];
                if ("Prepayment %" = 100) or FinalInvoice then
                    TotalRoundingAmount[2] := 0;
            end;

            if (PricesInclVATRoundingAmount[2] <> 0) and (TotalRoundingAmount[2] = 0) then begin
                if Abs(Prepmt100PctVATRoundingAmt) <= AmountRoundingPrecision then
                    Prepmt100PctVATRoundingAmt := 0;
                PricesInclVATRoundingAmount[2] := 0;
            end;

            "Prepmt. VAT Amount Inv. (LCY)" := -(TotalRoundingAmount[2] + Prepmt100PctVATRoundingAmt);
            NewAmountIncludingVAT := Amount - (TotalPrepmtAmount[2] + TotalRoundingAmount[2]);
            if (PricesInclVATRoundingAmount[1] = 0) and (PricesInclVATRoundingAmount[2] = 0) or
               ("Currency Code" <> '') and FinalInvoice
            then
                Increment(
                  TotalPurchLineLCY."Amount Including VAT",
                  -("Amount Including VAT" - NewAmountIncludingVAT + Prepmt100PctVATRoundingAmt));
            if "Currency Code" = '' then
                TotalPurchLine."Amount Including VAT" := TotalPurchLineLCY."Amount Including VAT";
            "Amount Including VAT" := NewAmountIncludingVAT;

            if FinalInvoice and (TotalPurchLine.Amount = 0) and (TotalPurchLine."Amount Including VAT" <> 0) and
               (Abs(TotalPurchLine."Amount Including VAT") <= Currency."Amount Rounding Precision")
            then begin
                "Amount Including VAT" -= TotalPurchLineLCY."Amount Including VAT";
                TotalPurchLine."Amount Including VAT" := 0;
                TotalPurchLineLCY."Amount Including VAT" := 0;
            end;
        end;

        OnAfterUpdatePrepmtPurchLineWithRounding(
          PrepmtPurchLine, TotalRoundingAmount, TotalPrepmtAmount, FinalInvoice, PricesInclVATRoundingAmount,
          TotalPurchLine, TotalPurchLineLCY);
    end;

    local procedure CalcRoundedAmount(Amount: Decimal; var Remainder: Decimal): Decimal
    var
        AmountRnded: Decimal;
    begin
        Amount := Amount + Remainder;
        AmountRnded := Round(Amount, GLSetup."Amount Rounding Precision");
        Remainder := Amount - AmountRnded;
        exit(AmountRnded);
    end;

    local procedure GetPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.Get(PurchLine."Receipt No.", PurchLine."Receipt Line No.");
        PurchOrderLine.Get(
          PurchOrderLine."Document Type"::Order,
          PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
        PurchOrderLine."Prepmt Amt to Deduct" := PurchLine."Prepmt Amt to Deduct";
    end;

    local procedure DecrementPrepmtAmtInvLCY(PurchLine: Record "Purchase Line"; var PrepmtAmountInvLCY: Decimal; var PrepmtVATAmountInvLCY: Decimal)
    begin
        TempPrepmtDeductLCYPurchLine.Reset;
        TempPrepmtDeductLCYPurchLine := PurchLine;
        if TempPrepmtDeductLCYPurchLine.Find then begin
            PrepmtAmountInvLCY := PrepmtAmountInvLCY - TempPrepmtDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)";
            PrepmtVATAmountInvLCY := PrepmtVATAmountInvLCY - TempPrepmtDeductLCYPurchLine."Prepmt. VAT Amount Inv. (LCY)";
        end;
    end;

    local procedure AdjustFinalInvWith100PctPrepmt(var CombinedPurchLine: Record "Purchase Line")
    var
        DiffToLineDiscAmt: Decimal;
    begin
        with TempPrepmtDeductLCYPurchLine do begin
            Reset;
            SetRange("Prepayment %", 100);
            if FindSet(true) then
                repeat
                    if IsFinalInvoice then begin
                        DiffToLineDiscAmt := "Prepmt Amt to Deduct" - "Line Amount";
                        if "Document Type" = "Document Type"::Order then
                            DiffToLineDiscAmt := DiffToLineDiscAmt * Quantity / "Qty. to Invoice";
                        if DiffToLineDiscAmt <> 0 then begin
                            CombinedPurchLine.Get("Document Type", "Document No.", "Line No.");
                            "Line Discount Amount" := CombinedPurchLine."Line Discount Amount" - DiffToLineDiscAmt;
                            Modify;
                        end;
                    end;
                until Next = 0;
            Reset;
        end;
    end;

    local procedure GetPrepmtDiffToLineAmount(PurchLine: Record "Purchase Line"): Decimal
    begin
        with TempPrepmtDeductLCYPurchLine do
            if PurchLine."Prepayment %" = 100 then
                if Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then
                    exit("Prepmt Amt to Deduct" + "Inv. Discount Amount" - "Line Amount");
        exit(0);
    end;

    local procedure InsertICGenJnlLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer)
    var
        ICGLAccount: Record "IC G/L Account";
        Cust: Record Customer;
        Currency: Record Currency;
        ICPartner: Record "IC Partner";
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        PurchHeader.TestField("Buy-from IC Partner Code", '');
        PurchHeader.TestField("Pay-to IC Partner Code", '');
        PurchLine.TestField("IC Partner Ref. Type", PurchLine."IC Partner Ref. Type"::"G/L Account");
        ICGLAccount.Get(PurchLine."IC Partner Reference");
        ICGenJnlLineNo := ICGenJnlLineNo + 1;

        with TempICGenJnlLine do begin
            InitNewLine(PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."Posting Description",
              PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code", PurchLine."Dimension Set ID",
              PurchHeader."Reason Code");
            "Line No." := ICGenJnlLineNo;

            CopyDocumentFields(GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series");

            Validate("Account Type", "Account Type"::"IC Partner");
            Validate("Account No.", PurchLine."IC Partner Code");
            "Source Currency Code" := PurchHeader."Currency Code";
            "Source Currency Amount" := Amount;
            Correction := PurchHeader.Correction;
            "Country/Region Code" := PurchHeader."VAT Country/Region Code";
            "Source Type" := GenJnlLine."Source Type"::Vendor;
            "Source No." := PurchHeader."Pay-to Vendor No.";
            "Source Line No." := PurchLine."Line No.";
            Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            Validate("Bal. Account No.", PurchLine."No.");
            "Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := PurchLine."Dimension Set ID";

            Cust.SetRange("IC Partner Code", PurchLine."IC Partner Code");
            if Cust.FindFirst then begin
                Validate("Bal. Gen. Bus. Posting Group", Cust."Gen. Bus. Posting Group");
                Validate("Bal. VAT Bus. Posting Group", Cust."VAT Bus. Posting Group");
            end;
            Validate("Bal. VAT Prod. Posting Group", PurchLine."VAT Prod. Posting Group");
            "IC Partner Code" := PurchLine."IC Partner Code";
            "IC Partner G/L Acc. No." := PurchLine."IC Partner Reference";
            "IC Direction" := "IC Direction"::Outgoing;
            ICPartner.Get(PurchLine."IC Partner Code");
            if ICPartner."Cost Distribution in LCY" and (PurchLine."Currency Code" <> '') then begin
                "Currency Code" := '';
                "Currency Factor" := 0;
                Currency.Get(PurchLine."Currency Code");
                if PurchHeader.IsCreditDocType then
                    Amount :=
                      -Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          PurchHeader."Posting Date", PurchLine."Currency Code",
                          PurchLine.Amount, PurchHeader."Currency Factor"))
                else
                    Amount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          PurchHeader."Posting Date", PurchLine."Currency Code",
                          PurchLine.Amount, PurchHeader."Currency Factor"));
            end else begin
                Currency.InitRoundingPrecision;
                "Currency Code" := PurchHeader."Currency Code";
                "Currency Factor" := PurchHeader."Currency Factor";
                if PurchHeader.IsCreditDocType then
                    Amount := -PurchLine.Amount
                else
                    Amount := PurchLine.Amount;
            end;
            if "Bal. VAT %" <> 0 then
                Amount := Round(Amount * (1 + "Bal. VAT %" / 100), Currency."Amount Rounding Precision");
            Validate(Amount);
            OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(TempICGenJnlLine, PurchHeader, PurchLine, SuppressCommit);
            Insert;
        end;
    end;

    local procedure PostICGenJnl()
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxExport: Codeunit "IC Outbox Export";
        ICTransactionNo: Integer;
    begin
        TempICGenJnlLine.Reset;
        if TempICGenJnlLine.Find('-') then
            repeat
                ICTransactionNo := ICInboxOutboxMgt.CreateOutboxJnlTransaction(TempICGenJnlLine, false);
                ICInboxOutboxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, TempICGenJnlLine);
                ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICTransactionNo);
                if TempICGenJnlLine.Amount <> 0 then
                    GenJnlPostLine.RunWithCheck(TempICGenJnlLine);
            until TempICGenJnlLine.Next = 0;
    end;

    local procedure TestGetRcptPPmtAmtToDeduct()
    var
        TempPurchLine: Record "Purchase Line" temporary;
        TempRcvdPurchLine: Record "Purchase Line" temporary;
        TempTotalPurchLine: Record "Purchase Line" temporary;
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseOrderLine: Record "Purchase Line";
        MaxAmtToDeduct: Decimal;
    begin
        with TempPurchLine do begin
            ResetTempLines(TempPurchLine);
            SetFilter(Quantity, '>0');
            SetFilter("Qty. to Invoice", '>0');
            SetFilter("Receipt No.", '<>%1', '');
            SetFilter("Prepmt Amt to Deduct", '<>0');
            if IsEmpty then
                exit;

            SetRange("Prepmt Amt to Deduct");
            if FindSet then
                repeat
                    if PurchRcptLine.Get("Receipt No.", "Receipt Line No.") then begin
                        TempRcvdPurchLine := TempPurchLine;
                        TempRcvdPurchLine.Insert;
                        TempPurchRcptLine := PurchRcptLine;
                        if TempPurchRcptLine.Insert then;

                        if not TempTotalPurchLine.Get("Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.")
                        then begin
                            TempTotalPurchLine.Init;
                            TempTotalPurchLine."Document Type" := "Document Type"::Order;
                            TempTotalPurchLine."Document No." := PurchRcptLine."Order No.";
                            TempTotalPurchLine."Line No." := PurchRcptLine."Order Line No.";
                            TempTotalPurchLine.Insert;
                        end;
                        TempTotalPurchLine."Qty. to Invoice" := TempTotalPurchLine."Qty. to Invoice" + "Qty. to Invoice";
                        TempTotalPurchLine."Prepmt Amt to Deduct" := TempTotalPurchLine."Prepmt Amt to Deduct" + "Prepmt Amt to Deduct";
                        AdjustInvLineWith100PctPrepmt(TempPurchLine, TempTotalPurchLine);
                        TempTotalPurchLine.Modify;
                    end;
                until Next = 0;

            if TempRcvdPurchLine.FindSet then
                repeat
                    if TempPurchRcptLine.Get(TempRcvdPurchLine."Receipt No.", TempRcvdPurchLine."Receipt Line No.") then
                        if PurchaseOrderLine.Get(
                             TempRcvdPurchLine."Document Type"::Order, TempPurchRcptLine."Order No.", TempPurchRcptLine."Order Line No.")
                        then
                            if TempTotalPurchLine.Get(
                                 TempRcvdPurchLine."Document Type"::Order, TempPurchRcptLine."Order No.", TempPurchRcptLine."Order Line No.")
                            then begin
                                MaxAmtToDeduct := PurchaseOrderLine."Prepmt. Amt. Inv." - PurchaseOrderLine."Prepmt Amt Deducted";

                                if TempTotalPurchLine."Prepmt Amt to Deduct" > MaxAmtToDeduct then
                                    Error(PrepAmountToDeductToBigErr, FieldCaption("Prepmt Amt to Deduct"), MaxAmtToDeduct);

                                if (TempTotalPurchLine."Qty. to Invoice" = PurchaseOrderLine.Quantity - PurchaseOrderLine."Quantity Invoiced") and
                                   (TempTotalPurchLine."Prepmt Amt to Deduct" <> MaxAmtToDeduct)
                                then
                                    Error(PrepAmountToDeductToSmallErr, FieldCaption("Prepmt Amt to Deduct"), MaxAmtToDeduct);
                            end;
                until TempRcvdPurchLine.Next = 0;
        end;
    end;

    local procedure AdjustInvLineWith100PctPrepmt(var PurchInvoiceLine: Record "Purchase Line"; var TempTotalPurchLine: Record "Purchase Line" temporary)
    var
        PurchOrderLine: Record "Purchase Line";
        DiffAmtToDeduct: Decimal;
    begin
        if PurchInvoiceLine."Prepayment %" = 100 then begin
            PurchOrderLine := TempTotalPurchLine;
            PurchOrderLine.Find;
            if TempTotalPurchLine."Qty. to Invoice" = PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced" then begin
                DiffAmtToDeduct :=
                  PurchOrderLine."Prepmt. Amt. Inv." - PurchOrderLine."Prepmt Amt Deducted" - TempTotalPurchLine."Prepmt Amt to Deduct";
                if DiffAmtToDeduct <> 0 then begin
                    PurchInvoiceLine."Prepmt Amt to Deduct" := PurchInvoiceLine."Prepmt Amt to Deduct" + DiffAmtToDeduct;
                    PurchInvoiceLine."Line Amount" := PurchInvoiceLine."Prepmt Amt to Deduct";
                    PurchInvoiceLine."Line Discount Amount" := PurchInvoiceLine."Line Discount Amount" - DiffAmtToDeduct;
                    ModifyTempLine(PurchInvoiceLine);
                    TempTotalPurchLine."Prepmt Amt to Deduct" := TempTotalPurchLine."Prepmt Amt to Deduct" + DiffAmtToDeduct;
                end;
            end;
        end;
    end;

    procedure ArchiveUnpostedOrder(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveUnpostedOrder(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if not (PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"]) then
            exit;

        PurchSetup.Get;
        if (PurchHeader."Document Type" = PurchHeader."Document Type"::Order) and not PurchSetup."Archive Orders" then
            exit;
        if (PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order") and not PurchSetup."Archive Return Orders" then
            exit;

        PurchLine.Reset;
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Quantity, '<>0');
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
            PurchLine.SetFilter("Qty. to Receive", '<>0')
        else
            PurchLine.SetFilter("Return Qty. to Ship", '<>0');
        if not PurchLine.IsEmpty and not PreviewMode then begin
            RoundDeferralsForArchive(PurchHeader, PurchLine);
            ArchiveManagement.ArchPurchDocumentNoConfirm(PurchHeader);
        end;
    end;

    local procedure PostItemJnlLineJobConsumption(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemJournalLine: Record "Item Journal Line"; var TempPurchReservEntry: Record "Reservation Entry" temporary; QtyToBeInvoiced: Decimal; QtyToBeReceived: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchItemLedgEntryNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPostItemJnlLineJobConsumption(
          PurchHeader, PurchLine, ItemJournalLine, TempPurchReservEntry, QtyToBeInvoiced, QtyToBeReceived,
          TempTrackingSpecification, PurchItemLedgEntryNo, IsHandled, ItemJnlPostLine);
        if IsHandled then
            exit;

        with PurchLine do
            if "Job No." <> '' then begin
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
                Job.Get("Job No.");
                ItemJournalLine."Source No." := Job."Bill-to Customer No.";
                if PurchHeader.Invoice then begin
                    ItemLedgEntry.Reset;
                    ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Return Shipment");
                    ItemLedgEntry.SetRange("Document No.", PurchHeader."Last Return Shipment No.");
                    ItemLedgEntry.SetRange("Item No.", "No.");
                    ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Negative Adjmt.");
                    ItemLedgEntry.SetRange("Completely Invoiced", false);
                    if ItemLedgEntry.FindFirst then
                        ItemJournalLine."Item Shpt. Entry No." := ItemLedgEntry."Entry No.";
                end;
                ItemJournalLine."Source Type" := ItemJournalLine."Source Type"::Customer;
                ItemJournalLine."Discount Amount" := 0;

                GetAppliedItemLedgEntryNo(ItemJournalLine, "Quantity Received");

                if QtyToBeReceived <> 0 then
                    CopyJobConsumptionReservation(
                      TempReservationEntry, TempPurchReservEntry, ItemJournalLine, TempTrackingSpecification,
                      PurchItemLedgEntryNo, IsNonInventoriableItem);

                ItemJnlPostLine.RunPostWithReservation(ItemJournalLine, TempReservationEntry);

                if QtyToBeInvoiced <> 0 then begin
                    "Qty. to Invoice" := QtyToBeInvoiced;
                    JobPostLine.PostJobOnPurchaseLine(PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchLine, SrcCode);
                end;
            end;
    end;

    local procedure CopyJobConsumptionReservation(var TempReservEntryJobCons: Record "Reservation Entry" temporary; var TempReservEntryPurchase: Record "Reservation Entry" temporary; var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchItemLedgEntryNo: Integer; IsNonInventoriableItem: Boolean)
    var
        NextReservationEntryNo: Integer;
    begin
        // Item tracking for consumption
        NextReservationEntryNo := 1;
        if TempReservEntryPurchase.FindSet then
            repeat
                TempReservEntryJobCons := TempReservEntryPurchase;

                with TempReservEntryJobCons do begin
                    "Entry No." := NextReservationEntryNo;
                    Positive := not Positive;
                    "Quantity (Base)" := -"Quantity (Base)";
                    "Shipment Date" := "Expected Receipt Date";
                    "Expected Receipt Date" := 0D;
                    Quantity := -Quantity;
                    "Qty. to Handle (Base)" := -"Qty. to Handle (Base)";
                    "Qty. to Invoice (Base)" := -"Qty. to Invoice (Base)";
                    "Source Subtype" := ItemJournalLine."Entry Type";
                    "Source Ref. No." := ItemJournalLine."Line No.";

                    if not (ItemJournalLine.IsPurchaseReturn or IsNonInventoriableItem) then begin
                        TempTrackingSpecification.SetRange("Serial No.", "Serial No.");
                        TempTrackingSpecification.SetRange("Lot No.", "Lot No.");
                        if TempTrackingSpecification.FindFirst then
                            "Appl.-to Item Entry" := TempTrackingSpecification."Item Ledger Entry No.";
                    end;

                    Insert;
                end;

                NextReservationEntryNo := NextReservationEntryNo + 1;
            until TempReservEntryPurchase.Next = 0
        else
            if not (ItemJournalLine.IsPurchaseReturn or IsNonInventoriableItem) then
                ItemJournalLine."Applies-to Entry" := PurchItemLedgEntryNo;
    end;

    local procedure GetAppliedItemLedgEntryNo(var ItemJournalLine: Record "Item Journal Line"; QtyReceived: Decimal)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Item.Get(ItemJournalLine."Item No.");
        if Item.Type = Item.Type::Inventory then begin
            if QtyReceived > 0 then
                GetAppliedOutboundItemLedgEntryNo(ItemJournalLine)
            else
                if QtyReceived < 0 then
                    GetAppliedInboundItemLedgEntryNo(ItemJournalLine);
        end else
            if ItemJournalLine."Item Shpt. Entry No." > 0 then begin
                ItemLedgerEntry.Get(ItemJournalLine."Item Shpt. Entry No.");
                ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type");
                ItemLedgerEntry.SetRange("Document No.", ItemLedgerEntry."Document No.");
                ItemLedgerEntry.SetRange("Document Line No.", ItemLedgerEntry."Document Line No.");
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
                ItemLedgerEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");
                ItemLedgerEntry.SetRange("Invoiced Quantity", 0);
                if ItemLedgerEntry.FindFirst then
                    ItemJournalLine."Item Shpt. Entry No." := ItemLedgerEntry."Entry No."
            end;
    end;

    local procedure GetAppliedOutboundItemLedgEntryNo(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        with ItemApplicationEntry do begin
            SetRange("Inbound Item Entry No.", ItemJnlLine."Item Shpt. Entry No.");
            if FindLast then
                ItemJnlLine."Item Shpt. Entry No." := "Outbound Item Entry No.";
        end
    end;

    local procedure GetAppliedInboundItemLedgEntryNo(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        with ItemApplicationEntry do begin
            SetRange("Outbound Item Entry No.", ItemJnlLine."Item Shpt. Entry No.");
            if FindLast then
                ItemJnlLine."Item Shpt. Entry No." := "Inbound Item Entry No.";
        end
    end;

    local procedure ItemLedgerEntryExist(PurchLine2: Record "Purchase Line"; ReceiveOrShip: Boolean): Boolean
    var
        HasItemLedgerEntry: Boolean;
    begin
        if ReceiveOrShip then
            // item ledger entry will be created during posting in this transaction
            HasItemLedgerEntry :=
            ((PurchLine2."Qty. to Receive" + PurchLine2."Quantity Received") <> 0) or
            ((PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced") <> 0) or
            ((PurchLine2."Return Qty. to Ship" + PurchLine2."Return Qty. Shipped") <> 0)
        else
            // item ledger entry must already exist
            HasItemLedgerEntry :=
            (PurchLine2."Quantity Received" <> 0) or
            (PurchLine2."Return Qty. Shipped" <> 0);

        exit(HasItemLedgerEntry);
    end;

    local procedure LockTables(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        OnBeforeLockTables(PurchHeader, PreviewMode, SuppressCommit);

        PurchLine.LockTable;
        SalesLine.LockTable;
        GetGLSetup;
        if not GLSetup.OptimGLEntLockForMultiuserEnv then begin
            GLEntry.LockTable;
            if GLEntry.FindLast then;
        end;
    end;

    local procedure "MAX"(number1: Integer; number2: Integer): Integer
    begin
        if number1 > number2 then
            exit(number1);
        exit(number2);
    end;

    procedure CreateJobPurchLine(var JobPurchLine2: Record "Purchase Line"; PurchLine2: Record "Purchase Line"; PricesIncludingVAT: Boolean)
    begin
        JobPurchLine2 := PurchLine2;
        if PricesIncludingVAT then
            if JobPurchLine2."VAT Calculation Type" = JobPurchLine2."VAT Calculation Type"::"Full VAT" then
                JobPurchLine2."Direct Unit Cost" := 0
            else
                JobPurchLine2."Direct Unit Cost" := JobPurchLine2."Direct Unit Cost" / (1 + JobPurchLine2."VAT %" / 100);
    end;

    local procedure RevertWarehouseEntry(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; JobNo: Code[20]; PostJobConsumptionBeforePurch: Boolean): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeRevertWarehouseEntry(TempWhseJnlLine, JobNo, PostJobConsumptionBeforePurch, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if PostJobConsumptionBeforePurch or (JobNo = '') or PositiveWhseEntrycreated then
            exit(false);

        with TempWhseJnlLine do begin
            "Entry Type" := "Entry Type"::"Negative Adjmt.";
            Quantity := -Quantity;
            "Qty. (Base)" := -"Qty. (Base)";
            "From Bin Code" := "To Bin Code";
            "To Bin Code" := '';
        end;
        exit(true);
    end;

    local procedure CreatePositiveEntry(WhseJnlLine: Record "Warehouse Journal Line"; JobNo: Code[20]; PostJobConsumptionBeforePurch: Boolean)
    begin
        if PostJobConsumptionBeforePurch or (JobNo <> '') then begin
            with WhseJnlLine do begin
                Quantity := -Quantity;
                "Qty. (Base)" := -"Qty. (Base)";
                "Qty. (Absolute)" := -"Qty. (Absolute)";
                "To Bin Code" := "From Bin Code";
                "From Bin Code" := '';
            end;
            WhseJnlPostLine.Run(WhseJnlLine);
            PositiveWhseEntrycreated := true;
        end;
    end;

    local procedure UpdateIncomingDocument(IncomingDocNo: Integer; PostingDate: Date; GenJnlLineDocNo: Code[20])
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocNo, PostingDate, GenJnlLineDocNo);
    end;

    local procedure CheckItemCharge(ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        PurchLineForCharge: Record "Purchase Line";
    begin
        with ItemChargeAssignmentPurch do
            case "Applies-to Doc. Type" of
                "Applies-to Doc. Type"::Order,
              "Applies-to Doc. Type"::Invoice:
                    if PurchLineForCharge.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.") then
                        if (PurchLineForCharge."Quantity (Base)" = PurchLineForCharge."Qty. Received (Base)") and
                           (PurchLineForCharge."Qty. Rcd. Not Invoiced (Base)" = 0)
                        then
                            Error(ReassignItemChargeErr);
                "Applies-to Doc. Type"::"Return Order",
              "Applies-to Doc. Type"::"Credit Memo":
                    if PurchLineForCharge.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.") then
                        if (PurchLineForCharge."Quantity (Base)" = PurchLineForCharge."Return Qty. Shipped (Base)") and
                           (PurchLineForCharge."Ret. Qty. Shpd Not Invd.(Base)" = 0)
                        then
                            Error(ReassignItemChargeErr);
            end;
    end;

    procedure InitProgressWindow(PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader.Invoice then
            Window.Open(
              '#1#################################\\' +
              PostingLinesMsg +
              PostingPurchasesAndVATMsg +
              PostingVendorsMsg +
              PostingBalAccountMsg)
        else
            Window.Open(
              '#1############################\\' +
              PostingLines2Msg);

        Window.Update(1, StrSubstNo('%1 %2', PurchHeader."Document Type", PurchHeader."No."));
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure UpdateInvoicedQtyOnPurchRcptLine(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean)
    begin
        OnBeforeUpdateInvoicedQtyOnPurchRcptLine(
          PurchRcptLine, QtyToBeInvoiced, QtyToBeInvoicedBase, SuppressCommit, PurchInvHeader, PurchaseHeader, PurchaseLine);

        with PurchRcptLine do begin
            "Quantity Invoiced" := "Quantity Invoiced" + QtyToBeInvoiced;
            "Qty. Invoiced (Base)" := "Qty. Invoiced (Base)" + QtyToBeInvoicedBase;
            "Qty. Rcd. Not Invoiced" := Quantity - "Quantity Invoiced";
            Modify;
        end;

        OnAfterUpdateInvoicedQtyOnPurchRcptLine(
          PurchInvHeader, PurchRcptLine, PurchaseLine, TempTrackingSpecification, TrackingSpecificationExists,
          QtyToBeInvoiced, QtyToBeInvoicedBase, PurchaseHeader, SuppressCommit);
    end;

    local procedure UpdateInvoicedQtyOnReturnShptLine(var ReturnShptLine: Record "Return Shipment Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
        with ReturnShptLine do begin
            "Quantity Invoiced" := "Quantity Invoiced" - QtyToBeInvoiced;
            "Qty. Invoiced (Base)" := "Qty. Invoiced (Base)" - QtyToBeInvoicedBase;
            "Return Qty. Shipped Not Invd." := Quantity - "Quantity Invoiced";
            Modify;
        end;
    end;

    local procedure UpdateQtyPerUnitOfMeasure(var PurchLine: Record "Purchase Line")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if PurchLine."Qty. per Unit of Measure" = 0 then
            if (PurchLine.Type = PurchLine.Type::Item) and
               (PurchLine."Unit of Measure Code" <> '') and
               ItemUnitOfMeasure.Get(PurchLine."No.", PurchLine."Unit of Measure Code")
            then
                PurchLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure"
            else
                PurchLine."Qty. per Unit of Measure" := 1;
    end;

    local procedure UpdateQtyToBeInvoicedForReceipt(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; PurchLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; InvoicingTrackingSpecification: Record "Tracking Specification")
    begin
        if PurchLine."Qty. to Invoice" * PurchRcptLine.Quantity < 0 then
            PurchLine.FieldError("Qty. to Invoice", ReceiptSameSignErr);
        if TrackingSpecificationExists then begin
            QtyToBeInvoiced := InvoicingTrackingSpecification."Qty. to Invoice";
            QtyToBeInvoicedBase := InvoicingTrackingSpecification."Qty. to Invoice (Base)";
        end else begin
            QtyToBeInvoiced := RemQtyToBeInvoiced - PurchLine."Qty. to Receive";
            QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - PurchLine."Qty. to Receive (Base)";
        end;
        if Abs(QtyToBeInvoiced) > Abs(PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced") then begin
            QtyToBeInvoiced := PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";
            QtyToBeInvoicedBase := PurchRcptLine."Quantity (Base)" - PurchRcptLine."Qty. Invoiced (Base)";
        end;
    end;

    local procedure UpdateQtyToBeInvoicedForReturnShipment(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; PurchLine: Record "Purchase Line"; ReturnShipmentLine: Record "Return Shipment Line"; InvoicingTrackingSpecification: Record "Tracking Specification")
    begin
        if PurchLine."Qty. to Invoice" * ReturnShipmentLine.Quantity > 0 then
            PurchLine.FieldError("Qty. to Invoice", ReturnShipmentSamesSignErr);
        if TrackingSpecificationExists then begin
            QtyToBeInvoiced := InvoicingTrackingSpecification."Qty. to Invoice";
            QtyToBeInvoicedBase := InvoicingTrackingSpecification."Qty. to Invoice (Base)";
        end else begin
            QtyToBeInvoiced := RemQtyToBeInvoiced - PurchLine."Return Qty. to Ship";
            QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - PurchLine."Return Qty. to Ship (Base)";
        end;
        if Abs(QtyToBeInvoiced) > Abs(ReturnShipmentLine.Quantity - ReturnShipmentLine."Quantity Invoiced") then begin
            QtyToBeInvoiced := ReturnShipmentLine."Quantity Invoiced" - ReturnShipmentLine.Quantity;
            QtyToBeInvoicedBase := ReturnShipmentLine."Qty. Invoiced (Base)" - ReturnShipmentLine."Quantity (Base)";
        end;
    end;

    local procedure UpdateRemainingQtyToBeInvoiced(var RemQtyToInvoiceCurrLine: Decimal; var RemQtyToInvoiceCurrLineBase: Decimal; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        RemQtyToInvoiceCurrLine := PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";
        RemQtyToInvoiceCurrLineBase := PurchRcptLine."Quantity (Base)" - PurchRcptLine."Qty. Invoiced (Base)";
        if RemQtyToInvoiceCurrLine > RemQtyToBeInvoiced then begin
            RemQtyToInvoiceCurrLine := RemQtyToBeInvoiced;
            RemQtyToInvoiceCurrLineBase := RemQtyToBeInvoicedBase;
        end;
    end;

    local procedure GetCountryCode(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"): Code[10]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        CountryRegionCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCountryCode(SalesHeader, SalesLine, CountryRegionCode, IsHandled);
        if IsHandled then
            exit(CountryRegionCode);

        if SalesLine."Shipment No." <> '' then begin
            SalesShipmentHeader.Get(SalesLine."Shipment No.");
            exit(
              GetCountryRegionCode(
                SalesLine."Sell-to Customer No.",
                SalesShipmentHeader."Ship-to Code",
                SalesShipmentHeader."Sell-to Country/Region Code"));
        end;
        exit(
          GetCountryRegionCode(
            SalesLine."Sell-to Customer No.",
            SalesHeader."Ship-to Code",
            SalesHeader."Sell-to Country/Region Code"));
    end;

    local procedure GetCountryRegionCode(CustNo: Code[20]; ShipToCode: Code[10]; SellToCountryRegionCode: Code[10]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if ShipToCode <> '' then begin
            ShipToAddress.Get(CustNo, ShipToCode);
            exit(ShipToAddress."Country/Region Code");
        end;
        exit(SellToCountryRegionCode);
    end;

    local procedure CheckItemReservDisruption(PurchLine: Record "Purchase Line")
    var
        Item: Record Item;
        ConfirmManagement: Codeunit "Confirm Management";
        AvailableQty: Decimal;
    begin
        with PurchLine do begin
            if not IsCreditDocType or (Type <> Type::Item) or not ("Return Qty. to Ship (Base)" > 0) then
                exit;

            if Nonstock or "Special Order" or "Drop Shipment" or IsNonInventoriableItem or
               TempSKU.Get("Location Code", "No.", "Variant Code") // Warn against item
            then
                exit;

            Item.Get("No.");
            Item.SetFilter("Location Filter", "Location Code");
            Item.SetFilter("Variant Filter", "Variant Code");
            Item.CalcFields("Reserved Qty. on Inventory", "Net Change");
            CalcFields("Reserved Qty. (Base)");
            AvailableQty := Item."Net Change" - (Item."Reserved Qty. on Inventory" - Abs("Reserved Qty. (Base)"));

            if (Item."Reserved Qty. on Inventory" > 0) and
               (AvailableQty < "Return Qty. to Ship (Base)") and
               (Item."Reserved Qty. on Inventory" > Abs("Reserved Qty. (Base)"))
            then begin
                InsertTempSKU("Location Code", "No.", "Variant Code");
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(
                       ReservationDisruptedQst, FieldCaption("No."), Item."No.", FieldCaption("Location Code"),
                       "Location Code", FieldCaption("Variant Code"), "Variant Code"), true)
                then
                    Error('');
            end;
        end;
    end;

    local procedure InsertTempSKU(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        with TempSKU do begin
            Init;
            "Location Code" := LocationCode;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            Insert;
        end;
    end;

    local procedure UpdatePurchLineDimSetIDFromAppliedEntry(var PurchLineToPost: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        DimensionMgt: Codeunit DimensionManagement;
        DimSetID: array[10] of Integer;
    begin
        DimSetID[1] := PurchLine."Dimension Set ID";
        with PurchLineToPost do begin
            if "Appl.-to Item Entry" <> 0 then begin
                ItemLedgEntry.Get("Appl.-to Item Entry");
                DimSetID[2] := ItemLedgEntry."Dimension Set ID";
            end;
            "Dimension Set ID" :=
              DimensionMgt.GetCombinedDimensionSetID(DimSetID, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    local procedure CheckCertificateOfSupplyStatus(ReturnShptHeader: Record "Return Shipment Header"; ReturnShptLine: Record "Return Shipment Line")
    var
        CertificateOfSupply: Record "Certificate of Supply";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if ReturnShptLine.Quantity <> 0 then
            if VATPostingSetup.Get(ReturnShptHeader."VAT Bus. Posting Group", ReturnShptLine."VAT Prod. Posting Group") and
               VATPostingSetup."Certificate of Supply Required"
            then begin
                CertificateOfSupply.InitFromPurchase(ReturnShptHeader);
                CertificateOfSupply.SetRequired(ReturnShptHeader."No.")
            end;
    end;

    local procedure CheckSalesCertificateOfSupplyStatus(SalesShptHeader: Record "Sales Shipment Header"; SalesShptLine: Record "Sales Shipment Line")
    var
        CertificateOfSupply: Record "Certificate of Supply";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if SalesShptLine.Quantity <> 0 then
            if VATPostingSetup.Get(SalesShptHeader."VAT Bus. Posting Group", SalesShptLine."VAT Prod. Posting Group") and
               VATPostingSetup."Certificate of Supply Required"
            then begin
                CertificateOfSupply.InitFromSales(SalesShptHeader);
                CertificateOfSupply.SetRequired(SalesShptHeader."No.");
            end;
    end;

    local procedure InsertPostedHeaders(var PurchHeader: Record "Purchase Header")
    var
        SalesShptLine: Record "Sales Shipment Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        GenJnlLine: Record "Gen. Journal Line";
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
    begin
        if PreviewMode then
            PostingPreviewEventHandler.PreventCommit;

        OnBeforeInsertPostedHeaders(PurchHeader, TempWhseRcptHeader, TempWhseShptHeader);

        with PurchHeader do begin
            // Insert receipt header
            if Receive then
                if ("Document Type" = "Document Type"::Order) or
                   (("Document Type" = "Document Type"::Invoice) and PurchSetup."Receipt on Invoice")
                then begin
                    if DropShipOrder then begin
                        PurchRcptHeader.LockTable;
                        PurchRcptLine.LockTable;
                        SalesShptHeader.LockTable;
                        SalesShptLine.LockTable;
                    end;
                    InsertReceiptHeader(PurchHeader, PurchRcptHeader);
                    ServItemMgt.CopyReservation(PurchHeader);
                end;

            // Insert return shipment header
            if Ship then
                if ("Document Type" = "Document Type"::"Return Order") or
                   (("Document Type" = "Document Type"::"Credit Memo") and PurchSetup."Return Shipment on Credit Memo")
                then
                    InsertReturnShipmentHeader(PurchHeader, ReturnShptHeader);

            // Insert invoice header or credit memo header
            if Invoice then
                if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
                    InsertInvoiceHeader(PurchHeader, PurchInvHeader);
                    GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    GenJnlLineDocNo := PurchInvHeader."No.";
                    GenJnlLineExtDocNo := "Vendor Invoice No.";
                end else begin // Credit Memo
                    InsertCrMemoHeader(PurchHeader, PurchCrMemoHeader);
                    GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    GenJnlLineDocNo := PurchCrMemoHeader."No.";
                    GenJnlLineExtDocNo := "Vendor Cr. Memo No.";
                end;
        end;

        OnAfterInsertPostedHeaders(PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader);
    end;

    local procedure InsertReceiptHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReceiptHeader(PurchHeader, PurchRcptHeader, IsHandled, SuppressCommit);

        with PurchHeader do begin
            if not IsHandled then begin
                PurchRcptHeader.Init;
                PurchRcptHeader.TransferFields(PurchHeader);
                PurchRcptHeader."No." := "Receiving No.";
                if "Document Type" = "Document Type"::Order then begin
                    PurchRcptHeader."Order No. Series" := "No. Series";
                    PurchRcptHeader."Order No." := "No.";
                end;
                PurchRcptHeader."No. Printed" := 0;
                PurchRcptHeader."Source Code" := SrcCode;
                PurchRcptHeader."User ID" := UserId;
                OnBeforePurchRcptHeaderInsert(PurchRcptHeader, PurchHeader, SuppressCommit);
                PurchRcptHeader.Insert(true);
                OnAfterPurchRcptHeaderInsert(PurchRcptHeader, PurchHeader, SuppressCommit);

                ApprovalsMgmt.PostApprovalEntries(RecordId, PurchRcptHeader.RecordId, PurchRcptHeader."No.");

                if PurchSetup."Copy Comments Order to Receipt" then begin
                    PurchCommentLine.CopyComments(
                      "Document Type", PurchCommentLine."Document Type"::Receipt, "No.", PurchRcptHeader."No.");
                    RecordLinkManagement.CopyLinks(PurchHeader, PurchRcptHeader);
                end;
            end;

            if WhseReceive then begin
                WhseRcptHeader.Get(TempWhseRcptHeader."No.");
                OnBeforeCreatePostedWhseRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, PurchHeader);
                WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, "Receiving No.", "Posting Date");
            end;
            if WhseShip then begin
                WhseShptHeader.Get(TempWhseShptHeader."No.");
                OnBeforeCreatePostedWhseShptHeader(PostedWhseShptHeader, WhseShptHeader, PurchHeader);
                WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, "Receiving No.", "Posting Date");
            end;
        end;
    end;

    local procedure InsertReceiptLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchLine: Record "Purchase Line"; CostBaseAmount: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReceiptLine(PurchRcptHeader, PurchLine, CostBaseAmount, IsHandled);
        if IsHandled then
            exit;

        PurchRcptLine.InitFromPurchLine(PurchRcptHeader, xPurchLine);
        PurchRcptLine."Quantity Invoiced" := RemQtyToBeInvoiced;
        PurchRcptLine."Qty. Invoiced (Base)" := RemQtyToBeInvoicedBase;
        PurchRcptLine."Qty. Rcd. Not Invoiced" := PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";

        if (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."Qty. to Receive" <> 0) then begin
            if WhseReceive then
                if WhseRcptLine.GetWhseRcptLine(
                     WhseRcptHeader."No.", DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
                then begin
                    WhseRcptLine.TestField("Qty. to Receive", PurchRcptLine.Quantity);
                    SaveTempWhseSplitSpec(PurchLine);
                    WhsePostRcpt.CreatePostedRcptLine(
                      WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                end;

            if WhseShip then
                if WhseShptLine.GetWhseShptLine(
                     WhseShptHeader."No.", DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
                then begin
                    WhseShptLine.TestField("Qty. to Ship", -PurchRcptLine.Quantity);
                    SaveTempWhseSplitSpec(PurchLine);
                    WhsePostShpt.CreatePostedShptLine(
                      WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                end;
            PurchRcptLine."Item Rcpt. Entry No." := InsertRcptEntryRelation(PurchRcptLine);
            PurchRcptLine."Item Charge Base Amount" := Round(CostBaseAmount / PurchLine.Quantity * PurchRcptLine.Quantity);
        end;
        OnBeforePurchRcptLineInsert(PurchRcptLine, PurchRcptHeader, PurchLine, SuppressCommit, PostedWhseRcptLine);
        PurchRcptLine.Insert(true);
        OnAfterPurchRcptLineInsert(
          PurchLine, PurchRcptLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit, PurchInvHeader, TempTrackingSpecification);
    end;

    local procedure InsertReturnShipmentHeader(var PurchHeader: Record "Purchase Header"; var ReturnShptHeader: Record "Return Shipment Header")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        with PurchHeader do begin
            ReturnShptHeader.Init;
            ReturnShptHeader.TransferFields(PurchHeader);
            ReturnShptHeader."No." := "Return Shipment No.";
            if "Document Type" = "Document Type"::"Return Order" then begin
                ReturnShptHeader."Return Order No. Series" := "No. Series";
                ReturnShptHeader."Return Order No." := "No.";
            end;
            ReturnShptHeader."No. Series" := "Return Shipment No. Series";
            ReturnShptHeader."No. Printed" := 0;
            ReturnShptHeader."Source Code" := SrcCode;
            ReturnShptHeader."User ID" := UserId;
            OnBeforeReturnShptHeaderInsert(ReturnShptHeader, PurchHeader, SuppressCommit);
            ReturnShptHeader.Insert(true);
            OnAfterReturnShptHeaderInsert(ReturnShptHeader, PurchHeader, SuppressCommit);

            ApprovalsMgmt.PostApprovalEntries(RecordId, ReturnShptHeader.RecordId, ReturnShptHeader."No.");

            if PurchSetup."Copy Cmts Ret.Ord. to Ret.Shpt" then begin
                PurchCommentLine.CopyComments(
                  "Document Type", PurchCommentLine."Document Type"::"Posted Return Shipment", "No.", ReturnShptHeader."No.");
                RecordLinkManagement.CopyLinks(PurchHeader, ReturnShptHeader);
            end;
            if WhseShip then begin
                WhseShptHeader.Get(TempWhseShptHeader."No.");
                OnBeforeCreatePostedWhseShptHeader(PostedWhseShptHeader, WhseShptHeader, PurchHeader);
                WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, "Return Shipment No.", "Posting Date");
            end;
            if WhseReceive then begin
                WhseRcptHeader.Get(TempWhseRcptHeader."No.");
                OnBeforeCreatePostedWhseRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, PurchHeader);
                WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, "Return Shipment No.", "Posting Date");
            end;
        end;
    end;

    local procedure InsertReturnShipmentLine(ReturnShptHeader: Record "Return Shipment Header"; PurchLine: Record "Purchase Line"; CostBaseAmount: Decimal)
    var
        ReturnShptLine: Record "Return Shipment Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        ReturnShptLine.InitFromPurchLine(ReturnShptHeader, xPurchLine);
        ReturnShptLine."Quantity Invoiced" := -RemQtyToBeInvoiced;
        ReturnShptLine."Qty. Invoiced (Base)" := -RemQtyToBeInvoicedBase;
        ReturnShptLine."Return Qty. Shipped Not Invd." := ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced";

        if (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."Return Qty. to Ship" <> 0) then begin
            if WhseShip then
                if WhseShptLine.GetWhseShptLine(
                     WhseShptHeader."No.", DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
                then begin
                    WhseShptLine.TestField("Qty. to Ship", ReturnShptLine.Quantity);
                    SaveTempWhseSplitSpec(PurchLine);
                    WhsePostShpt.CreatePostedShptLine(
                      WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                end;
            if WhseReceive then
                if WhseRcptLine.GetWhseRcptLine(
                     WhseRcptHeader."No.", DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
                then begin
                    WhseRcptLine.TestField("Qty. to Receive", -ReturnShptLine.Quantity);
                    SaveTempWhseSplitSpec(PurchLine);
                    WhsePostRcpt.CreatePostedRcptLine(
                      WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                end;

            ReturnShptLine."Item Shpt. Entry No." := InsertReturnEntryRelation(ReturnShptLine);
            ReturnShptLine."Item Charge Base Amount" := Round(CostBaseAmount / PurchLine.Quantity * ReturnShptLine.Quantity);
        end;
        OnBeforeReturnShptLineInsert(ReturnShptLine, ReturnShptHeader, PurchLine, SuppressCommit);
        ReturnShptLine.Insert(true);
        OnAfterReturnShptLineInsert(
          ReturnShptLine, ReturnShptHeader, PurchLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit,
          TempWhseShptHeader, PurchCrMemoHeader);

        CheckCertificateOfSupplyStatus(ReturnShptHeader, ReturnShptLine);
    end;

    local procedure InsertInvoiceHeader(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        with PurchHeader do begin
            PurchInvHeader.Init;
            PurchInvHeader.TransferFields(PurchHeader);

            PurchInvHeader."No." := "Posting No.";
            if "Document Type" = "Document Type"::Order then begin
                PurchInvHeader."Pre-Assigned No. Series" := '';
                PurchInvHeader."Order No. Series" := "No. Series";
                PurchInvHeader."Order No." := "No.";
            end else begin
                if "Posting No." = '' then
                    PurchInvHeader."No." := "No.";
                PurchInvHeader."Pre-Assigned No. Series" := "No. Series";
                PurchInvHeader."Pre-Assigned No." := "No.";
            end;
            if GuiAllowed and not HideProgressWindow then
                Window.Update(1, StrSubstNo(InvoiceNoMsg, "Document Type", "No.", PurchInvHeader."No."));
            PurchInvHeader."Creditor No." := "Creditor No.";
            PurchInvHeader."Payment Reference" := "Payment Reference";
            PurchInvHeader."Payment Method Code" := "Payment Method Code";
            PurchInvHeader."Source Code" := SrcCode;
            PurchInvHeader."User ID" := UserId;
            PurchInvHeader."No. Printed" := 0;
            OnBeforePurchInvHeaderInsert(PurchInvHeader, PurchHeader, SuppressCommit);
            PurchInvHeader."Draft Invoice SystemId" := PurchHeader.SystemId;
            PurchInvHeader.Insert(true);
            OnAfterPurchInvHeaderInsert(PurchInvHeader, PurchHeader);

            ApprovalsMgmt.PostApprovalEntries(RecordId, PurchInvHeader.RecordId, PurchInvHeader."No.");
            if PurchSetup."Copy Comments Order to Invoice" then begin
                PurchCommentLine.CopyComments(
                  "Document Type", PurchCommentLine."Document Type"::"Posted Invoice", "No.", PurchInvHeader."No.");
                RecordLinkManagement.CopyLinks(PurchHeader, PurchInvHeader);
            end;
        end;
    end;

    local procedure InsertCrMemoHeader(var PurchHeader: Record "Purchase Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        with PurchHeader do begin
            PurchCrMemoHdr.Init;
            PurchCrMemoHdr.TransferFields(PurchHeader);
            if "Document Type" = "Document Type"::"Return Order" then begin
                PurchCrMemoHdr."No." := "Posting No.";
                PurchCrMemoHdr."Pre-Assigned No. Series" := '';
                PurchCrMemoHdr."Return Order No. Series" := "No. Series";
                PurchCrMemoHdr."Return Order No." := "No.";
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(1, StrSubstNo(CreditMemoNoMsg, "Document Type", "No.", PurchCrMemoHdr."No."));
            end else begin
                PurchCrMemoHdr."Pre-Assigned No. Series" := "No. Series";
                PurchCrMemoHdr."Pre-Assigned No." := "No.";
                if "Posting No." <> '' then begin
                    PurchCrMemoHdr."No." := "Posting No.";
                    if GuiAllowed and not HideProgressWindow then
                        Window.Update(1, StrSubstNo(CreditMemoNoMsg, "Document Type", "No.", PurchCrMemoHdr."No."));
                end;
            end;
            PurchCrMemoHdr."Source Code" := SrcCode;
            PurchCrMemoHdr."User ID" := UserId;
            PurchCrMemoHdr."No. Printed" := 0;
            OnBeforePurchCrMemoHeaderInsert(PurchCrMemoHdr, PurchHeader, SuppressCommit);
            PurchCrMemoHdr.Insert(true);
            OnAfterPurchCrMemoHeaderInsert(PurchCrMemoHdr, PurchHeader, SuppressCommit);

            ApprovalsMgmt.PostApprovalEntries(RecordId, PurchCrMemoHdr.RecordId, PurchCrMemoHdr."No.");

            if PurchSetup."Copy Cmts Ret.Ord. to Cr. Memo" then begin
                PurchCommentLine.CopyComments(
                  "Document Type", PurchCommentLine."Document Type"::"Posted Credit Memo", "No.", PurchCrMemoHdr."No.");
                RecordLinkManagement.CopyLinks(PurchHeader, PurchCrMemoHdr);
            end;
        end;
    end;

    local procedure InsertSalesShptHeader(var SalesOrderHeader: Record "Sales Header"; var PurchHeader: Record "Purchase Header"; var SalesShptHeader: Record "Sales Shipment Header")
    begin
        with SalesShptHeader do begin
            Init;
            TransferFields(SalesOrderHeader);
            "No." := SalesOrderHeader."Shipping No.";
            "Order No." := SalesOrderHeader."No.";
            "Posting Date" := PurchHeader."Posting Date";
            "Document Date" := PurchHeader."Document Date";
            "No. Printed" := 0;
            OnBeforeSalesShptHeaderInsert(SalesShptHeader, SalesOrderHeader, SuppressCommit);
            Insert(true);
            OnAfterSalesShptHeaderInsert(SalesShptHeader, SalesOrderHeader, SuppressCommit, PurchHeader);
        end;
    end;

    local procedure InsertSalesShptLine(SalesShptHeader: Record "Sales Shipment Header"; SalesOrderLine: Record "Sales Line"; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; var SalesShptLine: Record "Sales Shipment Line")
    begin
        with SalesShptLine do begin
            Init;
            TransferFields(SalesOrderLine);
            "Posting Date" := SalesShptHeader."Posting Date";
            "Document No." := SalesShptHeader."No.";
            Quantity := DropShptPostBuffer.Quantity;
            "Quantity (Base)" := DropShptPostBuffer."Quantity (Base)";
            "Quantity Invoiced" := 0;
            "Qty. Invoiced (Base)" := 0;
            "Order No." := SalesOrderLine."Document No.";
            "Order Line No." := SalesOrderLine."Line No.";
            "Qty. Shipped Not Invoiced" :=
              Quantity - "Quantity Invoiced";
            if Quantity <> 0 then begin
                "Item Shpt. Entry No." := DropShptPostBuffer."Item Shpt. Entry No.";
                "Item Charge Base Amount" := SalesOrderLine."Line Amount";
            end;
            OnBeforeSalesShptLineInsert(SalesShptLine, SalesShptHeader, SalesOrderLine, SuppressCommit, DropShptPostBuffer);
            Insert;
            OnAfterSalesShptLineInsert(SalesShptLine, SalesShptHeader, SalesOrderLine, SuppressCommit, DropShptPostBuffer);
        end;
    end;

    local procedure GetSign(Value: Decimal): Integer
    begin
        if Value > 0 then
            exit(1);

        exit(-1);
    end;

    local procedure CheckICDocumentDuplicatePosting(PurchHeader: Record "Purchase Header")
    var
        PurchHeader2: Record "Purchase Header";
        ICInboxPurchHeader: Record "IC Inbox Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICDocumentDuplicatePosting(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do begin
            if not Invoice then
                exit;
            if "IC Direction" = "IC Direction"::Outgoing then begin
                PurchInvHeader.SetRange("Your Reference", "No.");
                PurchInvHeader.SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
                PurchInvHeader.SetRange("Pay-to Vendor No.", "Pay-to Vendor No.");
                if PurchInvHeader.FindFirst then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostedInvoiceDuplicateQst, PurchInvHeader."No.", "No."), true)
                    then
                        Error('');
            end;
            if "IC Direction" = "IC Direction"::Incoming then begin
                if "Document Type" = "Document Type"::Order then begin
                    PurchHeader2.SetRange("Document Type", "Document Type"::Invoice);
                    PurchHeader2.SetRange("Vendor Order No.", "Vendor Order No.");
                    if PurchHeader2.FindFirst then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(UnpostedInvoiceDuplicateQst, "No.", PurchHeader2."No."), true)
                        then
                            Error('');
                    ICInboxPurchHeader.SetRange("Document Type", "Document Type"::Invoice);
                    ICInboxPurchHeader.SetRange("Vendor Order No.", "Vendor Order No.");
                    if ICInboxPurchHeader.FindFirst then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(InvoiceDuplicateInboxQst, "No.", ICInboxPurchHeader."No."), true)
                        then
                            Error('');
                    PurchInvHeader.SetRange("Vendor Order No.", "Vendor Order No.");
                    if PurchInvHeader.FindFirst then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(PostedInvoiceDuplicateQst, PurchInvHeader."No.", "No."), true)
                        then
                            Error('');
                end;
                if ("Document Type" = "Document Type"::Invoice) and ("Vendor Order No." <> '') then begin
                    PurchHeader2.SetRange("Document Type", "Document Type"::Order);
                    PurchHeader2.SetRange("Vendor Order No.", "Vendor Order No.");
                    if PurchHeader2.FindFirst then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(OrderFromSameTransactionQst, PurchHeader2."No.", "No."), true)
                        then
                            Error('');
                    ICInboxPurchHeader.SetRange("Document Type", "Document Type"::Order);
                    ICInboxPurchHeader.SetRange("Vendor Order No.", "Vendor Order No.");
                    if ICInboxPurchHeader.FindFirst then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(DocumentFromSameTransactionQst, "No.", ICInboxPurchHeader."No."), true)
                        then
                            Error('');
                    PurchInvHeader.SetRange("Vendor Order No.", "Vendor Order No.");
                    if PurchInvHeader.FindFirst then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(PostedInvoiceFromSameTransactionQst, PurchInvHeader."No.", "No."), true)
                        then
                            Error('');
                    if "Your Reference" <> '' then begin
                        PurchInvHeader.Reset;
                        PurchInvHeader.SetRange("Order No.", "Your Reference");
                        PurchInvHeader.SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
                        PurchInvHeader.SetRange("Pay-to Vendor No.", "Pay-to Vendor No.");
                        if PurchInvHeader.FindFirst then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(PostedInvoiceFromSameTransactionQst, PurchInvHeader."No.", "No."), true)
                            then
                                Error('');
                    end;
                end;
            end;
        end;
    end;

    local procedure CheckICPartnerBlocked(PurchHeader: Record "Purchase Header")
    var
        ICPartner: Record "IC Partner";
    begin
        with PurchHeader do begin
            if "Buy-from IC Partner Code" <> '' then
                if ICPartner.Get("Buy-from IC Partner Code") then
                    ICPartner.TestField(Blocked, false);
            if "Pay-to IC Partner Code" <> '' then
                if ICPartner.Get("Pay-to IC Partner Code") then
                    ICPartner.TestField(Blocked, false);
        end;
    end;

    local procedure SendICDocument(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        IsHandled: Boolean;
    begin
        OnBeforeSendICDocument(PurchHeader, ModifyHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do
            if "Send IC Document" and ("IC Status" = "IC Status"::New) and ("IC Direction" = "IC Direction"::Outgoing) and
               ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"])
            then begin
                ICInboxOutboxMgt.SendPurchDoc(PurchHeader, true);
                "IC Status" := "IC Status"::Pending;
                ModifyHeader := true;
            end;
    end;

    local procedure UpdateHandledICInboxTransaction(PurchHeader: Record "Purchase Header")
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateHandledICInboxTransaction(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do
            if "IC Direction" = "IC Direction"::Incoming then begin
                case "Document Type" of
                    "Document Type"::Invoice:
                        HandledICInboxTrans.SetRange("Document No.", "Vendor Invoice No.");
                    "Document Type"::Order:
                        HandledICInboxTrans.SetRange("Document No.", "Vendor Order No.");
                    "Document Type"::"Credit Memo":
                        HandledICInboxTrans.SetRange("Document No.", "Vendor Cr. Memo No.");
                    "Document Type"::"Return Order":
                        HandledICInboxTrans.SetRange("Document No.", "Vendor Order No.");
                end;
                Vendor.Get("Buy-from Vendor No.");
                HandledICInboxTrans.SetRange("IC Partner Code", Vendor."IC Partner Code");
                HandledICInboxTrans.LockTable;
                if HandledICInboxTrans.FindFirst then begin
                    HandledICInboxTrans.Status := HandledICInboxTrans.Status::Posted;
                    HandledICInboxTrans.Modify;
                end;
            end;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmt: Codeunit "Inventory Adjustment";
    begin
        InvtSetup.Get;
        if InvtSetup."Automatic Cost Adjustment" <>
           InvtSetup."Automatic Cost Adjustment"::Never
        then begin
            InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
            InvtAdjmt.SetJobUpdateProperties(false);
            InvtAdjmt.MakeMultiLevelAdjmt;
        end;
    end;

    local procedure CheckTrackingAndWarehouseForReceive(PurchHeader: Record "Purchase Header") Receive: Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        with TempPurchLine do begin
            ResetTempLines(TempPurchLine);
            SetFilter(Quantity, '<>0');
            if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
                SetFilter("Qty. to Receive", '<>0');
            SetRange("Receipt No.", '');
            Receive := FindFirst;
            WhseReceive := TempWhseRcptHeader.FindFirst;
            WhseShip := TempWhseShptHeader.FindFirst;
            if Receive then begin
                CheckTrackingSpecification(PurchHeader, TempPurchLine);
                if not (WhseReceive or WhseShip or InvtPickPutaway) then
                    CheckWarehouse(TempPurchLine);
            end;
            OnAfterCheckTrackingAndWarehouseForReceive(
              PurchHeader, Receive, SuppressCommit, TempWhseShptHeader, TempWhseRcptHeader, TempPurchLine);
            exit(Receive);
        end;
    end;

    local procedure CheckTrackingAndWarehouseForShip(PurchHeader: Record "Purchase Header") Ship: Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        with TempPurchLine do begin
            ResetTempLines(TempPurchLine);
            SetFilter(Quantity, '<>0');
            SetFilter("Return Qty. to Ship", '<>0');
            SetRange("Return Shipment No.", '');
            Ship := FindFirst;
            WhseReceive := TempWhseRcptHeader.FindFirst;
            WhseShip := TempWhseShptHeader.FindFirst;
            if Ship then begin
                CheckTrackingSpecification(PurchHeader, TempPurchLine);
                if not (WhseShip or WhseReceive or InvtPickPutaway) then
                    CheckWarehouse(TempPurchLine);
            end;
            OnAfterCheckTrackingAndWarehouseForShip(PurchHeader, Ship, SuppressCommit);
            exit(Ship);
        end;
    end;

    local procedure CheckIfInvPutawayExists(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        with TempPurchLine do begin
            ResetTempLines(TempPurchLine);
            SetFilter(Quantity, '<>0');
            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
                SetFilter("Qty. to Receive", '<>0');
            SetRange("Receipt No.", '');
            if IsEmpty then
                exit(false);
            FindSet;
            repeat
                if WarehouseActivityLine.ActivityExists(
                     DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", 0,
                     WarehouseActivityLine."Activity Type"::"Invt. Put-away")
                then
                    exit(true);
            until Next = 0;
            exit(false);
        end;
    end;

    local procedure CheckIfInvPickExists(): Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        with TempPurchLine do begin
            ResetTempLines(TempPurchLine);
            SetFilter(Quantity, '<>0');
            SetFilter("Return Qty. to Ship", '<>0');
            SetRange("Return Shipment No.", '');
            if IsEmpty then
                exit(false);
            FindSet;
            repeat
                if WarehouseActivityLine.ActivityExists(
                     DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", 0,
                     WarehouseActivityLine."Activity Type"::"Invt. Pick")
                then
                    exit(true);
            until Next = 0;
            exit(false);
        end;
    end;

    local procedure CheckAssociatedOrderLines(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        CheckDimensions: Codeunit "Check Dimensions";
        IsHandled: Boolean;
    begin
        with PurchHeader do begin
            PurchLine.Reset;
            PurchLine.SetRange("Document Type", "Document Type");
            PurchLine.SetRange("Document No.", "No.");
            PurchLine.SetFilter("Sales Order Line No.", '<>0');
            OnCheckAssociatedOrderLinesOnAfterSetFilters(PurchLine, PurchHeader);
            if PurchLine.FindSet then
                repeat
                    SalesOrderLine.Get(
                      SalesOrderLine."Document Type"::Order, PurchLine."Sales Order No.", PurchLine."Sales Order Line No.");
                    TempSalesLine := SalesOrderLine;
                    TempSalesLine.Insert;
                    if Invoice then begin
                        if Receive and (PurchLine."Qty. to Invoice" <> 0) and (PurchLine."Qty. to Receive" <> 0) then
                            Error(DropShipmentErr);
                        if Abs(PurchLine."Quantity Received" - PurchLine."Quantity Invoiced") < Abs(PurchLine."Qty. to Invoice")
                        then begin
                            PurchLine."Qty. to Invoice" := PurchLine."Quantity Received" - PurchLine."Quantity Invoiced";
                            PurchLine."Qty. to Invoice (Base)" := PurchLine."Qty. Received (Base)" - PurchLine."Qty. Invoiced (Base)";
                        end;
                        IsHandled := false;
                        OnCheckAssocOrderLinesOnBeforeCheckOrderLine(PurchHeader, PurchLine, IsHandled, SalesOrderLine);
                        if not IsHandled then
                            if Abs(PurchLine.Quantity - (PurchLine."Qty. to Invoice" + PurchLine."Quantity Invoiced")) <
                               Abs(SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced")
                            then
                                Error(CannotInvoiceBeforeAssocSalesOrderErr, PurchLine."Sales Order No.");
                    end;

                    TempSalesHeader."Document Type" := TempSalesHeader."Document Type"::Order;
                    TempSalesHeader."No." := PurchLine."Sales Order No.";
                    if TempSalesHeader.Insert then;
                until PurchLine.Next = 0;
        end;

        if TempSalesHeader.FindSet then
            repeat
                SalesHeader.Get(TempSalesHeader."Document Type"::Order, TempSalesHeader."No.");
                TempSalesLine.SetRange("Document No.", SalesHeader."No.");
                CheckDimensions.CheckSalesDim(SalesHeader, TempSalesLine);
            until TempSalesHeader.Next = 0;
    end;

    local procedure PostCombineSalesOrderShipment(var PurchHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCommentLine: Record "Sales Comment Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        OnBeforePostCombineSalesOrderShipment(PurchHeader, TempDropShptPostBuffer);

        ArchiveSalesOrders(TempDropShptPostBuffer);
        with PurchHeader do
            if TempDropShptPostBuffer.FindSet then begin
                SalesSetup.Get;
                repeat
                    SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, TempDropShptPostBuffer."Order No.");
                    InsertSalesShptHeader(SalesOrderHeader, PurchHeader, SalesShptHeader);
                    ApprovalsMgmt.PostApprovalEntries(RecordId, SalesShptHeader.RecordId, SalesShptHeader."No.");
                    if SalesSetup."Copy Comments Order to Shpt." then begin
                        SalesCommentLine.CopyComments(
                          SalesOrderHeader."Document Type", SalesCommentLine."Document Type"::Shipment,
                          SalesOrderHeader."No.", SalesShptHeader."No.");
                        RecordLinkManagement.CopyLinks(SalesOrderHeader, SalesShptHeader);
                    end;
                    TempDropShptPostBuffer.SetRange("Order No.", TempDropShptPostBuffer."Order No.");
                    repeat
                        SalesOrderLine.Get(
                          SalesOrderLine."Document Type"::Order,
                          TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
                        InsertSalesShptLine(SalesShptHeader, SalesOrderLine, TempDropShptPostBuffer, SalesShptLine);
                        CheckSalesCertificateOfSupplyStatus(SalesShptHeader, SalesShptLine);

                        SalesOrderLine."Qty. to Ship" := SalesShptLine.Quantity;
                        SalesOrderLine."Qty. to Ship (Base)" := SalesShptLine."Quantity (Base)";
                        ServItemMgt.CreateServItemOnSalesLineShpt(SalesOrderHeader, SalesOrderLine, SalesShptLine);
                        OnPostCombineSalesOrderShipmentOnBeforeUpdateBlanketOrderLine(SalesOrderLine, SalesShptLine);
                        SalesPost.UpdateBlanketOrderLine(SalesOrderLine, true, false, false);
                        OnPostCombineSalesOrderShipmentOnAfterUpdateBlanketOrderLine(PurchHeader, TempDropShptPostBuffer, SalesOrderLine);

                        SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
                        SalesOrderLine.SetRange("Document No.", TempDropShptPostBuffer."Order No.");
                        SalesOrderLine.SetRange("Attached to Line No.", TempDropShptPostBuffer."Order Line No.");
                        SalesOrderLine.SetRange(Type, SalesOrderLine.Type::" ");
                        if SalesOrderLine.FindSet then
                            repeat
                                SalesShptLine.Init;
                                SalesShptLine.TransferFields(SalesOrderLine);
                                SalesShptLine."Document No." := SalesShptHeader."No.";
                                SalesShptLine."Order No." := SalesOrderLine."Document No.";
                                SalesShptLine."Order Line No." := SalesOrderLine."Line No.";
                                OnBeforeSalesShptLineInsert(SalesShptLine, SalesShptHeader, SalesOrderLine, SuppressCommit, TempDropShptPostBuffer);
                                SalesShptLine.Insert;
                                OnAfterSalesShptLineInsert(SalesShptLine, SalesShptHeader, SalesOrderLine, SuppressCommit, TempDropShptPostBuffer);
                            until SalesOrderLine.Next = 0;
                        OnPostCombineSalesOrderShipmentOnAfterProcessDropShptPostBuffer(TempDropShptPostBuffer, PurchRcptHeader, SalesShptLine, TempTrackingSpecification);
                    until TempDropShptPostBuffer.Next = 0;
                    TempDropShptPostBuffer.SetRange("Order No.");
                    OnAfterInsertCombinedSalesShipment(SalesShptHeader);
                until TempDropShptPostBuffer.Next = 0;
            end;
    end;

    local procedure PostInvoicePostBufferLine(var PurchHeader: Record "Purchase Header"; InvoicePostBuffer: Record "Invoice Post. Buffer") GLEntryNo: Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              PurchHeader."Posting Date", PurchHeader."Document Date", InvoicePostBuffer."Entry Description",
              InvoicePostBuffer."Global Dimension 1 Code", InvoicePostBuffer."Global Dimension 2 Code",
              InvoicePostBuffer."Dimension Set ID", PurchHeader."Reason Code");

            CopyDocumentFields(GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, '');
            CopyFromPurchHeader(PurchHeader);
            CopyFromInvoicePostBuffer(InvoicePostBuffer);

            if InvoicePostBuffer.Type <> InvoicePostBuffer.Type::"Prepmt. Exch. Rate Difference" then
                "Gen. Posting Type" := "Gen. Posting Type"::Purchase;
            if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
                case InvoicePostBuffer."FA Posting Type" of
                    InvoicePostBuffer."FA Posting Type"::"Acquisition Cost":
                        "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
                    InvoicePostBuffer."FA Posting Type"::Maintenance:
                        "FA Posting Type" := "FA Posting Type"::Maintenance;
                    InvoicePostBuffer."FA Posting Type"::Appreciation:
                        "FA Posting Type" := "FA Posting Type"::Appreciation;
                end;
                CopyFromInvoicePostBufferFA(InvoicePostBuffer);
            end;

            OnBeforePostInvPostBuffer(GenJnlLine, InvoicePostBuffer, PurchHeader, GenJnlPostLine, PreviewMode, SuppressCommit);
            GLEntryNo := RunGenJnlPostLine(GenJnlLine);
            OnAfterPostInvPostBuffer(GenJnlLine, InvoicePostBuffer, PurchHeader, GLEntryNo, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure FindTempItemChargeAssgntPurch(PurchLineNo: Integer): Boolean
    begin
        ClearItemChargeAssgntFilter;
        TempItemChargeAssgntPurch.SetCurrentKey("Applies-to Doc. Type");
        TempItemChargeAssgntPurch.SetRange("Document Line No.", PurchLineNo);
        exit(TempItemChargeAssgntPurch.FindSet);
    end;

    local procedure FillDeferralPostingBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; InvoicePostBuffer: Record "Invoice Post. Buffer"; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        if PurchLine."Deferral Code" <> '' then begin
            DeferralTemplate.Get(PurchLine."Deferral Code");

            if TempDeferralHeader.Get(DeferralUtilities.GetPurchDeferralDocType, '', '',
                 PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
            then begin
                if TempDeferralHeader."Amount to Defer" <> 0 then begin
                    DeferralUtilities.FilterDeferralLines(
                      TempDeferralLine, DeferralUtilities.GetPurchDeferralDocType, '', '',
                      PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
                    // Remainder\Initial deferral pair
                    DeferralPostBuffer.PreparePurch(PurchLine, GenJnlLineDocNo);
                    DeferralPostBuffer."Posting Date" := PurchHeader."Posting Date";
                    DeferralPostBuffer.Description := PurchHeader."Posting Description";
                    DeferralPostBuffer."Period Description" := DeferralTemplate."Period Description";
                    DeferralPostBuffer."Deferral Line No." := InvDefLineNo;
                    DeferralPostBuffer.PrepareInitialPair(
                      InvoicePostBuffer, RemainAmtToDefer, RemainAmtToDeferACY, PurchAccount, DeferralAccount);
                    DeferralPostBuffer.Update(DeferralPostBuffer, InvoicePostBuffer);
                    if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
                        DeferralPostBuffer.PrepareRemainderPurchase(
                          PurchLine, RemainAmtToDefer, RemainAmtToDeferACY, PurchAccount, DeferralAccount, InvDefLineNo);
                        DeferralPostBuffer.Update(DeferralPostBuffer, InvoicePostBuffer);
                    end;

                    // Add the deferral lines for each period to the deferral posting buffer merging when they are the same
                    if TempDeferralLine.FindSet then
                        repeat
                            if (TempDeferralLine."Amount (LCY)" <> 0) or (TempDeferralLine.Amount <> 0) then begin
                                DeferralPostBuffer.PreparePurch(PurchLine, GenJnlLineDocNo);
                                DeferralPostBuffer.InitFromDeferralLine(TempDeferralLine);
                                if PurchLine.IsCreditDocType then
                                    DeferralPostBuffer.ReverseAmounts;
                                DeferralPostBuffer."G/L Account" := PurchAccount;
                                DeferralPostBuffer."Deferral Account" := DeferralAccount;
                                DeferralPostBuffer."Period Description" := DeferralTemplate."Period Description";
                                DeferralPostBuffer."Deferral Line No." := InvDefLineNo;
                                DeferralPostBuffer.Update(DeferralPostBuffer, InvoicePostBuffer);
                            end else
                                Error(ZeroDeferralAmtErr, PurchLine."No.", PurchLine."Deferral Code");

                        until TempDeferralLine.Next = 0

                    else
                        Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code");
                end else
                    Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code")
            end else
                Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code")
        end;
    end;

    local procedure RoundDeferralsForArchive(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        ArchiveManagement.RoundPurchaseDeferralsForArchive(PurchHeader, PurchLine);
    end;

    local procedure GetAmountsForDeferral(PurchLine: Record "Purchase Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        if PurchLine."Deferral Code" <> '' then begin
            DeferralTemplate.Get(PurchLine."Deferral Code");
            DeferralTemplate.TestField("Deferral Account");
            DeferralAccount := DeferralTemplate."Deferral Account";

            if TempDeferralHeader.Get(DeferralUtilities.GetPurchDeferralDocType, '', '',
                 PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
            then begin
                AmtToDeferACY := TempDeferralHeader."Amount to Defer";
                AmtToDefer := TempDeferralHeader."Amount to Defer (LCY)";
            end;

            if PurchLine.IsCreditDocType then begin
                AmtToDefer := -AmtToDefer;
                AmtToDeferACY := -AmtToDeferACY;
            end
        end else begin
            AmtToDefer := 0;
            AmtToDeferACY := 0;
            DeferralAccount := '';
        end;
    end;

    local procedure CheckMandatoryHeaderFields(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.TestField("Document Type");
        PurchHeader.TestField("Buy-from Vendor No.");
        PurchHeader.TestField("Pay-to Vendor No.");
        PurchHeader.TestField("Posting Date");
        PurchHeader.TestField("Document Date");

        OnAfterCheckMandatoryFields(PurchHeader, SuppressCommit);
    end;

    local procedure InitVATAmounts(PurchLine: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        TotalVAT := PurchLine."Amount Including VAT" - PurchLine.Amount;
        TotalVATACY := PurchLineACY."Amount Including VAT" - PurchLineACY.Amount;
        TotalAmount := PurchLine.Amount;
        TotalAmountACY := PurchLineACY.Amount;
    end;

    local procedure InitVATBase(PurchLine: Record "Purchase Line"; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        TotalVATBase := PurchLine."VAT Base Amount";
        TotalVATBaseACY := PurchLineACY."VAT Base Amount";
    end;

    local procedure InitAmounts(PurchLine: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    begin
        InitVATAmounts(PurchLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        GetAmountsForDeferral(PurchLine, AmtToDefer, AmtToDeferACY, DeferralAccount);
    end;

    local procedure CalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        case PurchLine."VAT Calculation Type" of
            PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                InvoicePostBuffer.CalcDiscount(
                  PurchHeader."Prices Including VAT", -PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
            PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                InvoicePostBuffer.CalcDiscountNoVAT(-PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
            PurchLine."VAT Calculation Type"::"Sales Tax":
                if not PurchLine."Use Tax" then // Use Tax is calculated later, based on totals
                    InvoicePostBuffer.CalcDiscount(
                      PurchHeader."Prices Including VAT", -PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount")
                else
                    InvoicePostBuffer.CalcDiscountNoVAT(-PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
        end;
    end;

    local procedure CalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        case PurchLine."VAT Calculation Type" of
            PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                InvoicePostBuffer.CalcDiscount(
                  PurchHeader."Prices Including VAT", -PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
            PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                InvoicePostBuffer.CalcDiscountNoVAT(-PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
            PurchLine."VAT Calculation Type"::"Sales Tax":
                if not PurchLine."Use Tax" then // Use Tax is calculated later, based on totals
                    InvoicePostBuffer.CalcDiscount(
                      PurchHeader."Prices Including VAT", -PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount")
                else
                    InvoicePostBuffer.CalcDiscountNoVAT(-PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
        end;
    end;

    local procedure ClearPostBuffers()
    begin
        Clear(WhsePostRcpt);
        Clear(WhsePostShpt);
        Clear(GenJnlPostLine);
        Clear(JobPostLine);
        Clear(ItemJnlPostLine);
        Clear(WhseJnlPostLine);
    end;

    local procedure ValidatePostingAndDocumentDate(var PurchaseHeader: Record "Purchase Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
        PostingDate: Date;
        ModifyHeader: Boolean;
        PostingDateExists: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
    begin
        OnBeforeValidatePostingAndDocumentDate(PurchaseHeader, SuppressCommit);

        PostingDateExists :=
          BatchProcessingMgt.GetParameterBoolean(
            PurchaseHeader.RecordId, BatchPostParameterTypes.ReplacePostingDate, ReplacePostingDate) and
          BatchProcessingMgt.GetParameterBoolean(
            PurchaseHeader.RecordId, BatchPostParameterTypes.ReplaceDocumentDate, ReplaceDocumentDate) and
          BatchProcessingMgt.GetParameterDate(
            PurchaseHeader.RecordId, BatchPostParameterTypes.PostingDate, PostingDate);

        if PostingDateExists and (ReplacePostingDate or (PurchaseHeader."Posting Date" = 0D)) then begin
            PurchaseHeader."Posting Date" := PostingDate;
            PurchaseHeader.Validate("Currency Code");
            ModifyHeader := true;
        end;

        if PostingDateExists and (ReplaceDocumentDate or (PurchaseHeader."Document Date" = 0D)) then begin
            PurchaseHeader.Validate("Document Date", PostingDate);
            ModifyHeader := true;
        end;

        if ModifyHeader then
            PurchaseHeader.Modify;

        OnAfterValidatePostingAndDocumentDate(PurchaseHeader, SuppressCommit, PreviewMode);
    end;

    local procedure CheckExternalDocumentNumber(var VendLedgEntry: Record "Vendor Ledger Entry"; var PurchaseHeader: Record "Purchase Header")
    var
        VendorMgt: Codeunit "Vendor Mgt.";
        Handled: Boolean;
    begin
        OnBeforeCheckExternalDocumentNumber(VendLedgEntry, PurchaseHeader, Handled, GenJnlLineDocType, GenJnlLineExtDocNo);
        if Handled then
            exit;

        VendLedgEntry.Reset;
        VendLedgEntry.SetCurrentKey("External Document No.");
        VendorMgt.SetFilterForExternalDocNo(
          VendLedgEntry, GenJnlLineDocType, GenJnlLineExtDocNo, PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Document Date");
        if VendLedgEntry.FindFirst then
            Error(
              PurchaseAlreadyExistsErr, VendLedgEntry."Document Type", GenJnlLineExtDocNo);
    end;

    local procedure PostInvoicePostingBuffer(PurchHeader: Record "Purchase Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        LineCount: Integer;
        GLEntryNo: Integer;
    begin
        OnBeforePostInvoicePostBuffer(PurchHeader, TempInvoicePostBuffer, TotalPurchLine, TotalPurchLineLCY);

        LineCount := 0;
        if TempInvoicePostBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                case TempInvoicePostBuffer."VAT Calculation Type" of
                    TempInvoicePostBuffer."VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            VATPostingSetup.Get(
                              TempInvoicePostBuffer."VAT Bus. Posting Group", TempInvoicePostBuffer."VAT Prod. Posting Group");
                            OnPostInvoicePostingBufferOnAfterVATPostingSetupGet(VATPostingSetup);
                            TempInvoicePostBuffer."VAT Amount" :=
                              Round(
                                TempInvoicePostBuffer."VAT Base Amount" *
                                (1 - PurchHeader."VAT Base Discount %" / 100) * VATPostingSetup."VAT %" / 100);
                            TempInvoicePostBuffer."VAT Amount (ACY)" :=
                              Round(
                                TempInvoicePostBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100) *
                                VATPostingSetup."VAT %" / 100, Currency."Amount Rounding Precision");
                        end;
                    TempInvoicePostBuffer."VAT Calculation Type"::"Sales Tax":
                        if TempInvoicePostBuffer."Use Tax" then begin
                            TempInvoicePostBuffer."VAT Amount" :=
                              Round(
                                SalesTaxCalculate.CalculateTax(
                                  TempInvoicePostBuffer."Tax Area Code", TempInvoicePostBuffer."Tax Group Code",
                                  TempInvoicePostBuffer."Tax Liable", PurchHeader."Posting Date",
                                  TempInvoicePostBuffer.Amount, TempInvoicePostBuffer.Quantity, 0));
                            if GLSetup."Additional Reporting Currency" <> '' then
                                TempInvoicePostBuffer."VAT Amount (ACY)" :=
                                  CurrExchRate.ExchangeAmtLCYToFCY(
                                    PurchHeader."Posting Date", GLSetup."Additional Reporting Currency",
                                    TempInvoicePostBuffer."VAT Amount", 0);
                        end;
                end;

                GLEntryNo := PostInvoicePostBufferLine(PurchHeader, TempInvoicePostBuffer);

                if (TempInvoicePostBuffer."Job No." <> '') and
                   (TempInvoicePostBuffer.Type = TempInvoicePostBuffer.Type::"G/L Account")
                then
                    JobPostLine.PostPurchaseGLAccounts(TempInvoicePostBuffer, GLEntryNo);

            until TempInvoicePostBuffer.Next(-1) = 0;

        TempInvoicePostBuffer.DeleteAll;
    end;

    local procedure PostItemTracking(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingSpecificationExists: Boolean)
    var
        QtyToInvoiceBaseInTrackingSpec: Decimal;
    begin
        with PurchHeader do begin
            if TrackingSpecificationExists then begin
                TempTrackingSpecification.CalcSums("Qty. to Invoice (Base)");
                QtyToInvoiceBaseInTrackingSpec := TempTrackingSpecification."Qty. to Invoice (Base)";
                if not TempTrackingSpecification.FindFirst then
                    TempTrackingSpecification.Init;
            end;

            if IsCreditDocType then begin
                if (Abs(RemQtyToBeInvoiced) > Abs(PurchLine."Return Qty. to Ship")) or
                   (Abs(RemQtyToBeInvoiced) >= Abs(QtyToInvoiceBaseInTrackingSpec)) and (QtyToInvoiceBaseInTrackingSpec <> 0)
                then
                    PostItemTrackingForShipment(PurchHeader, PurchLine, TrackingSpecificationExists, TempTrackingSpecification);

                PostItemTrackingCheckShipment(PurchLine, RemQtyToBeInvoiced);
                if Abs(RemQtyToBeInvoiced) > Abs(PurchLine."Return Qty. to Ship") then begin
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        Error(InvoiceGreaterThanReturnShipmentErr, ReturnShptHeader."No.");
                    Error(ReturnShipmentLinesDeletedErr);
                end;
            end else begin
                if (Abs(RemQtyToBeInvoiced) > Abs(PurchLine."Qty. to Receive")) or
                   (Abs(RemQtyToBeInvoiced) >= Abs(QtyToInvoiceBaseInTrackingSpec)) and (QtyToInvoiceBaseInTrackingSpec <> 0)
                then
                    PostItemTrackingForReceipt(PurchHeader, PurchLine, TrackingSpecificationExists, TempTrackingSpecification);

                PostItemTrackingCheckReceipt(PurchLine, RemQtyToBeInvoiced);
                if Abs(RemQtyToBeInvoiced) > Abs(PurchLine."Qty. to Receive") then begin
                    if "Document Type" = "Document Type"::Invoice then
                        Error(QuantityToInvoiceGreaterErr, PurchRcptHeader."No.");
                    Error(ReceiptLinesDeletedErr);
                end;
            end;
        end;
    end;

    local procedure PostItemTrackingCheckShipment(PurchaseLine: Record "Purchase Line"; RemQtyToBeInvoiced: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemTrackingCheckShipment(PurchaseLine, RemQtyToBeInvoiced, IsHandled);
        if IsHandled then
            exit;

        if Abs(RemQtyToBeInvoiced) > Abs(PurchaseLine."Return Qty. to Ship") then begin
            if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo" then
                Error(InvoiceGreaterThanReturnShipmentErr, ReturnShptHeader."No.");
            Error(ReturnShipmentLinesDeletedErr);
        end;
    end;

    local procedure PostItemTrackingCheckReceipt(PurchaseLine: Record "Purchase Line"; RemQtyToBeInvoiced: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemTrackingCheckReceipt(PurchaseLine, RemQtyToBeInvoiced, IsHandled);
        if IsHandled then
            exit;

        if Abs(RemQtyToBeInvoiced) > Abs(PurchaseLine."Qty. to Receive") then begin
            if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Invoice then
                Error(QuantityToInvoiceGreaterErr, PurchRcptHeader."No.");
            Error(ReceiptLinesDeletedErr);
        end;
    end;

    local procedure PostItemTrackingForReceipt(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; TrackingSpecificationExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemEntryRelation: Record "Item Entry Relation";
        EndLoop: Boolean;
        RemQtyToInvoiceCurrLine: Decimal;
        RemQtyToInvoiceCurrLineBase: Decimal;
        QtyToBeInvoiced: Decimal;
        QtyToBeInvoicedBase: Decimal;
        IsHandled: Boolean;
    begin
        with PurchHeader do begin
            EndLoop := false;
            PurchRcptLine.Reset;
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        PurchRcptLine.SetCurrentKey("Order No.", "Order Line No.");
                        PurchRcptLine.SetRange("Order No.", PurchLine."Document No.");
                        PurchRcptLine.SetRange("Order Line No.", PurchLine."Line No.");
                    end;
                "Document Type"::Invoice:
                    begin
                        PurchRcptLine.SetRange("Document No.", PurchLine."Receipt No.");
                        PurchRcptLine.SetRange("Line No.", PurchLine."Receipt Line No.");
                    end;
            end;

            PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
            if PurchRcptLine.FindSet(true, false) then begin
                ItemJnlRollRndg := true;
                repeat
                    if TrackingSpecificationExists then begin
                        ItemEntryRelation.Get(TempTrackingSpecification."Item Ledger Entry No.");
                        PurchRcptLine.Get(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                    end else
                        ItemEntryRelation."Item Entry No." := PurchRcptLine."Item Rcpt. Entry No.";
                    UpdateRemainingQtyToBeInvoiced(RemQtyToInvoiceCurrLine, RemQtyToInvoiceCurrLineBase, PurchRcptLine);
                    PurchRcptLine.TestField("Buy-from Vendor No.", PurchLine."Buy-from Vendor No.");
                    PurchRcptLine.TestField(Type, PurchLine.Type);
                    PurchRcptLine.TestField("No.", PurchLine."No.");
                    PurchRcptLine.TestField("Gen. Bus. Posting Group", PurchLine."Gen. Bus. Posting Group");
                    PurchRcptLine.TestField("Gen. Prod. Posting Group", PurchLine."Gen. Prod. Posting Group");
                    PurchRcptLine.TestField("Job No.", PurchLine."Job No.");
                    PurchRcptLine.TestField("Unit of Measure Code", PurchLine."Unit of Measure Code");
                    PurchRcptLine.TestField("Variant Code", PurchLine."Variant Code");
                    PurchRcptLine.TestField("Prod. Order No.", PurchLine."Prod. Order No.");

                    UpdateQtyToBeInvoicedForReceipt(
                      QtyToBeInvoiced, QtyToBeInvoicedBase,
                      TrackingSpecificationExists, PurchLine, PurchRcptLine, TempTrackingSpecification);

                    if TrackingSpecificationExists then begin
                        TempTrackingSpecification."Quantity actual Handled (Base)" := QtyToBeInvoicedBase;
                        TempTrackingSpecification.Modify;
                    end;

                    if TrackingSpecificationExists then
                        ItemTrackingMgt.AdjustQuantityRounding(
                          RemQtyToInvoiceCurrLine, QtyToBeInvoiced, RemQtyToInvoiceCurrLineBase, QtyToBeInvoicedBase);

                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;

                    UpdateInvoicedQtyOnPurchRcptLine(
                      PurchInvHeader, PurchRcptLine, PurchHeader, PurchLine, QtyToBeInvoiced, QtyToBeInvoicedBase, TrackingSpecificationExists);

                    if PostItemTrackingForReceiptCondition(PurchLine, PurchRcptLine) then
                        PostItemJnlLine(
                          PurchHeader, PurchLine, 0, 0, QtyToBeInvoiced, QtyToBeInvoicedBase,
                          ItemEntryRelation."Item Entry No.", '', TempTrackingSpecification);

                    if TrackingSpecificationExists then
                        EndLoop := (TempTrackingSpecification.Next = 0) or (RemQtyToBeInvoiced = 0)
                    else
                        EndLoop :=
                          (PurchRcptLine.Next = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(PurchLine."Qty. to Receive"));
                until EndLoop;
            end else begin
                IsHandled := false;
                OnPostItemTrackingForReceiptOnBeforeReceiptInvoiceErr(PurchLine, IsHandled);
                if not IsHandled then
                    Error(ReceiptInvoicedErr, PurchLine."Receipt Line No.", PurchLine."Receipt No.");
            end;
        end;
    end;

    local procedure PostItemTrackingForReceiptCondition(PurchLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        Condition: Boolean;
    begin
        Condition := PurchLine.Type = PurchLine.Type::Item;
        OnBeforePostItemTrackingForReceiptCondition(PurchLine, PurchRcptLine, Condition);
        exit(Condition);
    end;

    local procedure PostItemTrackingForShipment(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; TrackingSpecificationExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ReturnShptLine: Record "Return Shipment Line";
        ItemEntryRelation: Record "Item Entry Relation";
        EndLoop: Boolean;
        QtyToBeInvoiced: Decimal;
        QtyToBeInvoicedBase: Decimal;
        IsHandled: Boolean;
    begin
        with PurchHeader do begin
            EndLoop := false;
            ReturnShptLine.Reset;
            case "Document Type" of
                "Document Type"::"Return Order":
                    begin
                        ReturnShptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                        ReturnShptLine.SetRange("Return Order No.", PurchLine."Document No.");
                        ReturnShptLine.SetRange("Return Order Line No.", PurchLine."Line No.");
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        ReturnShptLine.SetRange("Document No.", PurchLine."Return Shipment No.");
                        ReturnShptLine.SetRange("Line No.", PurchLine."Return Shipment Line No.");
                    end;
            end;
            ReturnShptLine.SetFilter("Return Qty. Shipped Not Invd.", '<>0');
            if ReturnShptLine.FindSet(true, false) then begin
                ItemJnlRollRndg := true;
                repeat
                    if TrackingSpecificationExists then begin  // Item Tracking
                        ItemEntryRelation.Get(TempTrackingSpecification."Item Ledger Entry No.");
                        ReturnShptLine.Get(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                    end else
                        ItemEntryRelation."Item Entry No." := ReturnShptLine."Item Shpt. Entry No.";
                    ReturnShptLine.TestField("Buy-from Vendor No.", PurchLine."Buy-from Vendor No.");
                    ReturnShptLine.TestField(Type, PurchLine.Type);
                    ReturnShptLine.TestField("No.", PurchLine."No.");
                    ReturnShptLine.TestField("Gen. Bus. Posting Group", PurchLine."Gen. Bus. Posting Group");
                    ReturnShptLine.TestField("Gen. Prod. Posting Group", PurchLine."Gen. Prod. Posting Group");
                    ReturnShptLine.TestField("Job No.", PurchLine."Job No.");
                    ReturnShptLine.TestField("Unit of Measure Code", PurchLine."Unit of Measure Code");
                    ReturnShptLine.TestField("Variant Code", PurchLine."Variant Code");
                    ReturnShptLine.TestField("Prod. Order No.", PurchLine."Prod. Order No.");
                    UpdateQtyToBeInvoicedForReturnShipment(
                      QtyToBeInvoiced, QtyToBeInvoicedBase,
                      TrackingSpecificationExists, PurchLine, ReturnShptLine, TempTrackingSpecification);

                    if TrackingSpecificationExists then begin
                        TempTrackingSpecification."Quantity actual Handled (Base)" := QtyToBeInvoicedBase;
                        TempTrackingSpecification.Modify;
                    end;

                    if TrackingSpecificationExists then
                        ItemTrackingMgt.AdjustQuantityRounding(
                          RemQtyToBeInvoiced, QtyToBeInvoiced, RemQtyToBeInvoicedBase, QtyToBeInvoicedBase);

                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                    UpdateInvoicedQtyOnReturnShptLine(ReturnShptLine, QtyToBeInvoiced, QtyToBeInvoicedBase);

                    OnAfterUpdateInvoicedQtyOnReturnShptLine(
                      PurchCrMemoHeader, ReturnShptLine, PurchLine, TempTrackingSpecification, TrackingSpecificationExists,
                      QtyToBeInvoiced, QtyToBeInvoicedBase);

                    if PostItemTrackingForShipmentCondition(PurchLine, ReturnShptLine) then
                        PostItemJnlLine(
                          PurchHeader, PurchLine, 0, 0, QtyToBeInvoiced, QtyToBeInvoicedBase,
                          ItemEntryRelation."Item Entry No.", '', TempTrackingSpecification);

                    if TrackingSpecificationExists then
                        EndLoop := (TempTrackingSpecification.Next = 0) or (RemQtyToBeInvoiced = 0)
                    else
                        EndLoop :=
                          (ReturnShptLine.Next = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(PurchLine."Return Qty. to Ship"));
                until EndLoop;
            end else begin
                IsHandled := false;
                OnPostItemTrackingForShipmentOnBeforeReturnShipmentInvoiceErr(PurchLine, IsHandled);
                if not IsHandled then
                    Error(ReturnShipmentInvoicedErr, PurchLine."Return Shipment Line No.", PurchLine."Return Shipment No.");
            end;
        end;
    end;

    local procedure PostItemTrackingForShipmentCondition(PurchLine: Record "Purchase Line"; ReturnShipmentLine: Record "Return Shipment Line"): Boolean
    var
        Condition: Boolean;
    begin
        Condition := PurchLine.Type = PurchLine.Type::Item;
        OnBeforePostItemTrackingForShipmentCondition(PurchLine, ReturnShipmentLine, Condition);
        exit(Condition);
    end;

    local procedure PostUpdateOrderLine(PurchHeader: Record "Purchase Header")
    var
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        OnBeforePostUpdateOrderLine(PurchHeader, TempPurchLineGlobal, SuppressCommit, PurchSetup);

        ResetTempLines(TempPurchLine);
        with TempPurchLine do begin
            SetRange("Prepayment Line", false);
            SetFilter(Quantity, '<>0');
            if FindSet then
                repeat
                    if PurchHeader.Receive then begin
                        "Quantity Received" += "Qty. to Receive";
                        "Qty. Received (Base)" += "Qty. to Receive (Base)";
                    end;
                    if PurchHeader.Ship then begin
                        "Return Qty. Shipped" += "Return Qty. to Ship";
                        "Return Qty. Shipped (Base)" += "Return Qty. to Ship (Base)";
                    end;
                    if PurchHeader.Invoice then begin
                        if "Document Type" = "Document Type"::Order then begin
                            if Abs("Quantity Invoiced" + "Qty. to Invoice") > Abs("Quantity Received") then begin
                                Validate("Qty. to Invoice", "Quantity Received" - "Quantity Invoiced");
                                "Qty. to Invoice (Base)" := "Qty. Received (Base)" - "Qty. Invoiced (Base)";
                            end
                        end else
                            if Abs("Quantity Invoiced" + "Qty. to Invoice") > Abs("Return Qty. Shipped") then begin
                                Validate("Qty. to Invoice", "Return Qty. Shipped" - "Quantity Invoiced");
                                "Qty. to Invoice (Base)" := "Return Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
                            end;

                        "Quantity Invoiced" := "Quantity Invoiced" + "Qty. to Invoice";
                        "Qty. Invoiced (Base)" := "Qty. Invoiced (Base)" + "Qty. to Invoice (Base)";
                        if "Qty. to Invoice" <> 0 then begin
                            "Prepmt Amt Deducted" += "Prepmt Amt to Deduct";
                            "Prepmt VAT Diff. Deducted" += "Prepmt VAT Diff. to Deduct";
                            DecrementPrepmtAmtInvLCY(
                              TempPurchLine, "Prepmt. Amount Inv. (LCY)", "Prepmt. VAT Amount Inv. (LCY)");
                            "Prepmt Amt to Deduct" := "Prepmt. Amt. Inv." - "Prepmt Amt Deducted";
                            "Prepmt VAT Diff. to Deduct" := 0;
                        end;
                    end;

                    UpdateBlanketOrderLine(TempPurchLine, PurchHeader.Receive, PurchHeader.Ship, PurchHeader.Invoice);

                    OnPostUpdateOrderLineOnBeforeInitOutstanding(PurchHeader, TempPurchLine);

                    InitOutstanding;

                    if WhseHandlingRequired(TempPurchLine) or
                       (PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank)
                    then begin
                        if "Document Type" = "Document Type"::"Return Order" then begin
                            "Return Qty. to Ship" := 0;
                            "Return Qty. to Ship (Base)" := 0;
                        end else begin
                            "Qty. to Receive" := 0;
                            "Qty. to Receive (Base)" := 0;
                        end;
                        InitQtyToInvoice;
                    end else begin
                        if "Document Type" = "Document Type"::"Return Order" then
                            InitQtyToShip
                        else
                            InitQtyToReceive2;
                    end;
                    SetDefaultQuantity;
                    OnBeforePostUpdateOrderLineModifyTempLine(TempPurchLine, WhseShip, WhseReceive, SuppressCommit, PurchHeader);
                    ModifyTempLine(TempPurchLine);
                    OnAfterPostUpdateOrderLine(TempPurchLine, WhseShip, WhseReceive, SuppressCommit);
                until Next = 0;
        end;
    end;

    local procedure PostUpdateInvoiceLine()
    var
        PurchOrderLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesOrderLine: Record "Sales Line";
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        ResetTempLines(TempPurchLine);
        with TempPurchLine do begin
            SetFilter("Receipt No.", '<>%1', '');
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet then
                repeat
                    PurchRcptLine.Get("Receipt No.", "Receipt Line No.");
                    PurchOrderLine.Get(
                      PurchOrderLine."Document Type"::Order,
                      PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
                    if Type = Type::"Charge (Item)" then
                        UpdatePurchOrderChargeAssgnt(TempPurchLine, PurchOrderLine);
                    PurchOrderLine."Quantity Invoiced" += "Qty. to Invoice";
                    PurchOrderLine."Qty. Invoiced (Base)" += "Qty. to Invoice (Base)";
                    if Abs(PurchOrderLine."Quantity Invoiced") > Abs(PurchOrderLine."Quantity Received") then
                        Error(InvoiceMoreThanReceivedErr, PurchOrderLine."Document No.");
                    if PurchOrderLine."Sales Order Line No." <> 0 then begin // Drop Shipment
                        SalesOrderLine.Get(
                          SalesOrderLine."Document Type"::Order,
                          PurchOrderLine."Sales Order No.", PurchOrderLine."Sales Order Line No.");
                        if Abs(PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced") <
                           Abs(SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced")
                        then
                            Error(CannotPostBeforeAssosSalesOrderErr, PurchOrderLine."Sales Order No.");
                    end;
                    PurchOrderLine.InitQtyToInvoice;
                    if PurchOrderLine."Prepayment %" <> 0 then begin
                        PurchOrderLine."Prepmt Amt Deducted" += "Prepmt Amt to Deduct";
                        PurchOrderLine."Prepmt VAT Diff. Deducted" += "Prepmt VAT Diff. to Deduct";
                        DecrementPrepmtAmtInvLCY(
                          TempPurchLine, PurchOrderLine."Prepmt. Amount Inv. (LCY)", PurchOrderLine."Prepmt. VAT Amount Inv. (LCY)");
                        PurchOrderLine."Prepmt Amt to Deduct" :=
                          PurchOrderLine."Prepmt. Amt. Inv." - PurchOrderLine."Prepmt Amt Deducted";
                        PurchOrderLine."Prepmt VAT Diff. to Deduct" := 0;
                    end;
                    PurchOrderLine.InitOutstanding;
                    PurchOrderLine.Modify;
                    OnPostUpdateInvoiceLineOnAfterPurchOrderLineModify(PurchOrderLine, TempPurchLine);
                until Next = 0;
        end;
    end;

    local procedure PostUpdateCreditMemoLine()
    var
        PurchOrderLine: Record "Purchase Line";
        ReturnShptLine: Record "Return Shipment Line";
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        ResetTempLines(TempPurchLine);
        with TempPurchLine do begin
            SetFilter("Return Shipment No.", '<>%1', '');
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet then
                repeat
                    ReturnShptLine.Get("Return Shipment No.", "Return Shipment Line No.");
                    PurchOrderLine.Get(
                      PurchOrderLine."Document Type"::"Return Order",
                      ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
                    if Type = Type::"Charge (Item)" then
                        UpdatePurchOrderChargeAssgnt(TempPurchLine, PurchOrderLine);
                    PurchOrderLine."Quantity Invoiced" :=
                      PurchOrderLine."Quantity Invoiced" + "Qty. to Invoice";
                    PurchOrderLine."Qty. Invoiced (Base)" :=
                      PurchOrderLine."Qty. Invoiced (Base)" + "Qty. to Invoice (Base)";
                    if Abs(PurchOrderLine."Quantity Invoiced") > Abs(PurchOrderLine."Return Qty. Shipped") then
                        Error(InvoiceMoreThanShippedErr, PurchOrderLine."Document No.");
                    PurchOrderLine.InitQtyToInvoice;
                    PurchOrderLine.InitOutstanding;
                    PurchOrderLine.Modify;
                until Next = 0;
        end;
    end;

    procedure SetPostingFlags(var PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            case "Document Type" of
                "Document Type"::Order:
                    Ship := false;
                "Document Type"::Invoice:
                    begin
                        Receive := true;
                        Invoice := true;
                        Ship := false;
                    end;
                "Document Type"::"Return Order":
                    Receive := false;
                "Document Type"::"Credit Memo":
                    begin
                        Receive := false;
                        Invoice := true;
                        Ship := true;
                    end;
            end;
            if not (Receive or Invoice or Ship) then
                Error(ReceiveInvoiceShipErr);
        end;
    end;

    local procedure SetCheckApplToItemEntry(PurchLine: Record "Purchase Line"): Boolean
    begin
        with PurchLine do
            exit(
              PurchSetup."Exact Cost Reversing Mandatory" and (Type = Type::Item) and
              (((Quantity < 0) and ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice])) or
               ((Quantity > 0) and IsCreditDocType)) and
              ("Job No." = ''));
    end;

    local procedure CreatePostedDeferralScheduleFromPurchDoc(PurchLine: Record "Purchase Line"; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralAccount: Code[20];
    begin
        if PurchLine."Deferral Code" = '' then
            exit;

        if DeferralTemplate.Get(PurchLine."Deferral Code") then
            DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
             DeferralUtilities.GetPurchDeferralDocType, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            PostedDeferralHeader.InitFromDeferralHeader(TempDeferralHeader, '', '', NewDocumentType,
              NewDocumentNo, NewLineNo, DeferralAccount, PurchLine."Buy-from Vendor No.", PostingDate);
            DeferralUtilities.FilterDeferralLines(
              TempDeferralLine, DeferralUtilities.GetPurchDeferralDocType, '', '',
              PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
            if TempDeferralLine.FindSet then
                repeat
                    PostedDeferralLine.InitFromDeferralLine(
                      TempDeferralLine, '', '', NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount);
                until TempDeferralLine.Next = 0;
        end;

        OnAfterCreatePostedDeferralScheduleFromPurchDoc(PurchLine, PostedDeferralHeader);
    end;

    local procedure CalcDeferralAmounts(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; OriginalDeferralAmount: Decimal)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        CurrExchRate: Record "Currency Exchange Rate";
        TotalAmountLCY: Decimal;
        TotalAmount: Decimal;
        TotalDeferralCount: Integer;
        DeferralCount: Integer;
        UseDate: Date;
    begin
        // Populate temp and calculate the LCY amounts for posting
        if PurchHeader."Posting Date" = 0D then
            UseDate := WorkDate
        else
            UseDate := PurchHeader."Posting Date";

        if DeferralHeader.Get(
             DeferralUtilities.GetPurchDeferralDocType, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            TempDeferralHeader := DeferralHeader;
            if PurchLine.Quantity <> PurchLine."Qty. to Invoice" then
                TempDeferralHeader."Amount to Defer" :=
                  Round(TempDeferralHeader."Amount to Defer" *
                    PurchLine.GetDeferralAmount / OriginalDeferralAmount, Currency."Amount Rounding Precision");
            TempDeferralHeader."Amount to Defer (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, PurchHeader."Currency Code",
                  TempDeferralHeader."Amount to Defer", PurchHeader."Currency Factor"));
            TempDeferralHeader.Insert;

            with DeferralLine do begin
                DeferralUtilities.FilterDeferralLines(
                  DeferralLine, DeferralHeader."Deferral Doc. Type",
                  DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                  PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
                if FindSet then begin
                    TotalDeferralCount := Count;
                    repeat
                        TempDeferralLine.Init;
                        TempDeferralLine := DeferralLine;
                        DeferralCount := DeferralCount + 1;

                        if DeferralCount = TotalDeferralCount then begin
                            TempDeferralLine.Amount := TempDeferralHeader."Amount to Defer" - TotalAmount;
                            TempDeferralLine."Amount (LCY)" := TempDeferralHeader."Amount to Defer (LCY)" - TotalAmountLCY;
                        end else begin
                            if PurchLine.Quantity <> PurchLine."Qty. to Invoice" then
                                TempDeferralLine.Amount :=
                                  Round(TempDeferralLine.Amount *
                                    PurchLine.GetDeferralAmount / OriginalDeferralAmount, Currency."Amount Rounding Precision");

                            TempDeferralLine."Amount (LCY)" :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  UseDate, PurchHeader."Currency Code",
                                  TempDeferralLine.Amount, PurchHeader."Currency Factor"));
                            TotalAmount := TotalAmount + TempDeferralLine.Amount;
                            TotalAmountLCY := TotalAmountLCY + TempDeferralLine."Amount (LCY)";
                        end;
                        OnBeforeTempDeferralLineInsert(TempDeferralLine, DeferralLine, PurchLine, DeferralCount, TotalDeferralCount);
                        TempDeferralLine.Insert;
                    until Next = 0;
                end;
            end;
        end;
    end;

    local procedure GetAmountRoundingPrecisionInLCY(DocType: Option; DocNo: Code[20]; CurrencyCode: Code[10]) AmountRoundingPrecision: Decimal
    var
        PurchHeader: Record "Purchase Header";
    begin
        if CurrencyCode = '' then
            exit(GLSetup."Amount Rounding Precision");
        PurchHeader.Get(DocType, DocNo);
        AmountRoundingPrecision := Currency."Amount Rounding Precision" / PurchHeader."Currency Factor";
        if AmountRoundingPrecision < GLSetup."Amount Rounding Precision" then
            exit(GLSetup."Amount Rounding Precision");
        exit(AmountRoundingPrecision);
    end;

    local procedure CollectPurchaseLineReservEntries(var JobReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        if ItemJournalLine."Job No." <> '' then begin
            JobReservEntry.DeleteAll;
            ItemJnlLineReserve.FindReservEntry(ItemJournalLine, ReservationEntry);
            ReservationEntry.ClearTrackingFilter;
            if ReservationEntry.FindSet then
                repeat
                    JobReservEntry := ReservationEntry;
                    JobReservEntry.Insert;
                until ReservationEntry.Next = 0;
        end;
    end;

    local procedure ArchiveSalesOrders(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
    begin
        if TempDropShptPostBuffer.FindSet then begin
            repeat
                SalesOrderHeader.Get(
                  SalesOrderHeader."Document Type"::Order,
                  TempDropShptPostBuffer."Order No.");
                TempDropShptPostBuffer.SetRange("Order No.", TempDropShptPostBuffer."Order No.");
                repeat
                    SalesOrderLine.Get(
                      SalesOrderLine."Document Type"::Order,
                      TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
                    SalesOrderLine."Qty. to Ship" := TempDropShptPostBuffer.Quantity;
                    SalesOrderLine."Qty. to Ship (Base)" := TempDropShptPostBuffer."Quantity (Base)";
                    SalesOrderLine.Modify;
                until TempDropShptPostBuffer.Next = 0;
                SalesPost.ArchiveUnpostedOrder(SalesOrderHeader);
                TempDropShptPostBuffer.SetRange("Order No.");
            until TempDropShptPostBuffer.Next = 0;
        end;
    end;

    local procedure ClearAllVariables()
    begin
        ClearAll;
        TempPurchLineGlobal.DeleteAll;
        TempItemChargeAssgntPurch.DeleteAll;
        TempHandlingSpecification.DeleteAll;
        TempTrackingSpecification.DeleteAll;
        TempTrackingSpecificationInv.DeleteAll;
        TempWhseSplitSpecification.DeleteAll;
        TempValueEntryRelation.DeleteAll;
        TempICGenJnlLine.DeleteAll;
        TempPrepmtDeductLCYPurchLine.DeleteAll;
        TempSKU.DeleteAll;
        TempDeferralHeader.DeleteAll;
        TempDeferralLine.DeleteAll;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBlanketOrderPurchLineModify(var BlanketOrderPurchLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPurchDoc(var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAndUpdate(var PurchaseHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingAndWarehouseForReceive(var PurchaseHeader: Record "Purchase Header"; var Receive: Boolean; CommitIsSupressed: Boolean; var TempWarehouseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWarehouseReceiptHeader: Record "Warehouse Receipt Header" temporary; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingAndWarehouseForShip(var PurchaseHeader: Record "Purchase Header"; var Ship: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedDeferralScheduleFromPurchDoc(var PurchaseLine: Record "Purchase Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAfterPosting(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDivideAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; PurchLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPurchaseDocDropShipment(SalesShptNo: Code[20]; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostingNos(var PurchaseHeader: Record "Purchase Header"; var NoSeriesMgt: Codeunit NoSeriesManagement; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckMandatoryFields(var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvoicePostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer"; PurchLine: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePosting(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePostingOnBeforeCommit(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrAmount(var TotalPurchLine: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCombinedSalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPostedHeaders(var PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvoiceRoundingAmount(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TotalPurchaseLine: Record "Purchase Line"; UseTempData: Boolean; InvoiceRoundingAmount: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertedPrepmtVATBaseToDeduct(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PrepmtLineNo: Integer; TotalPrepmtAmtToDeduct: Decimal; var TempPrepmtDeductLCYPurchLine: Record "Purchase Line" temporary; var PrepmtVATBaseToDeduct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLineCopyProdOrder(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; QtyToBeReceived: Decimal; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemTrackingLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; WhseReceive: Boolean; WhseShip: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptLineInsert(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; PurchInvHeader: Record "Purch. Inv. Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchLine: Record "Purchase Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnShptHeaderInsert(var ReturnShptHeader: Record "Return Shipment Header"; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnShptLineInsert(var ReturnShptLine: Record "Return Shipment Line"; ReturnShptHeader: Record "Return Shipment Header"; PurchLine: Record "Purchase Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesShptHeaderInsert(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesOrderHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesShptLineInsert(var SalesShptLine: Record "Sales Shipment Line"; SalesShptHeader: Record "Sales Shipment Header"; SalesOrderLine: Record "Sales Line"; CommitIsSuppressed: Boolean; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAccICLine(PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterPostItemLine(PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; PurchaseHeader: Record "Purchase Header"; RemQtyToBeInvoiced: Decimal; RemQtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; PurchHeader: Record "Purchase Header"; GLEntryNo: Integer; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLine(var PurchaseLine: Record "Purchase Line"; ItemLedgEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateOrderLine(var PurchaseLine: Record "Purchase Line"; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostGLAndVendor(var PurchHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; TotalPurchLine: Record "Purchase Line"; TotalPurchLineLCY: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPurchLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPurchLines(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; WhseShip: Boolean; WhseReceive: Boolean; var PurchLinesProcessed: Boolean; CommitIsSuppressed: Boolean; EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleasePurchDoc(var PurchHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetTempLines(var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestorePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PurchaseHeaderCopy: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseAmount(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmount(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveTempWhseSplitSpec(PurchaseLine: Record "Purchase Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestPurchLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; WhseReceive: Boolean; WhseShip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInvoicedQtyOnPurchRcptLine(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseLine: Record "Purchase Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingSpecificationExists: Boolean; var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; var PurchaseHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInvoicedQtyOnReturnShptLine(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line"; TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingSpecificationExists: Boolean; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLineBeforePost(var PurchaseLine: Record "Purchase Line"; WhseShip: Boolean; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePrepmtPurchLineWithRounding(var PrepmtPurchLine: Record "Purchase Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchaseHeader(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; GenJnlLineDocType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostingAndDocumentDate(var PurchaseHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveUnpostedOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderPurchLineModify(var BlanketOrderPurchLine: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExternalDocumentNumber(VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchaseHeader: Record "Purchase Header"; var Handled: Boolean; DocType: Option; ExtDocNo: Text[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICDocumentDuplicatePosting(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTrackingSpecification(PurchHeader: Record "Purchase Header"; var TempItemPurchLine: Record "Purchase Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var TempItemPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedWhseRcptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedWhseShptHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePrepmtLines(PurchaseHeader: Record "Purchase Header"; var TempPrepmtPurchaseLine: Record "Purchase Line" temporary; CompleteFunctionality: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAfterPosting(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var SkipDelete: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDivideAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; PurchLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizePosting(var PurchaseHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary; var EverythingInvoiced: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoiceRoundingAmount(PurchHeader: Record "Purchase Header"; TotalAmountIncludingVAT: Decimal; UseTempData: Boolean; var InvoiceRoundingAmount: Decimal; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPostedHeaders(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReceiptHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var IsHandled: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoicePostingBufferSetAmounts(PurchaseLine: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReceiptLine(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchLine: Record "Purchase Line"; var CostBaseAmount: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeItemJnlPostLine(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; var IsHandled: Boolean; WhseReceiptHeader: Record "Warehouse Receipt Header"; WhseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLockTables(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGLAndVendor(var PurchHeader: Record "Purchase Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGLAccICLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCommitPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; ModifyHeader: Boolean; CommitIsSupressed: Boolean; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineDeleteAll(var PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptLineInsert(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchLine: Record "Purchase Line"; CommitIsSupressed: Boolean; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleasePurchDoc(var PurchHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShptHeaderInsert(var ReturnShptHeader: Record "Return Shipment Header"; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShptLineInsert(var ReturnShptLine: Record "Return Shipment Line"; var ReturnShptHeader: Record "Return Shipment Header"; var PurchLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundAmount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptHeaderInsert(var SalesShptHeader: Record "Sales Shipment Header"; SalesOrderHeader: Record "Sales Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptLineInsert(var SalesShptLine: Record "Sales Shipment Line"; SalesShptHeader: Record "Sales Shipment Header"; SalesLine: Record "Sales Line"; CommitIsSupressed: Boolean; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCombineSalesOrderShipment(var PurchaseHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var PurchHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoicePostBuffer(PurchaseHeader: Record "Purchase Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var QtyToBeReceived: Decimal; var QtyToBeReceivedBase: Decimal; var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; var ItemLedgShptEntryNo: Integer; var ItemChargeNo: Code[20]; var TrackingSpecification: Record "Tracking Specification"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var SalesLine: Record "Sales Line"; CommitIsSupressed: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargePerOrder(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var ItemJnlLine2: Record "Item Journal Line"; var ItemChargePurchLine: Record "Purchase Line"; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary; CommitIsSupressed: Boolean; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePostItemJnlLineJobConsumption(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingCheckReceipt(PurchaseLine: Record "Purchase Line"; RemQtyToBeInvoiced: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingCheckShipment(PurchaseLine: Record "Purchase Line"; RemQtyToBeInvoiced: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingForReceiptCondition(PurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; var Condition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingForShipmentCondition(PurchaseLine: Record "Purchase Line"; ReturnShipmentLine: Record "Return Shipment Line"; var Condition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResourceLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateOrderLine(PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary; CommitIsSuppressed: Boolean; var PurchSetup: Record "Purchases & Payables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateOrderLineModifyTempLine(var TempPurchaseLine: Record "Purchase Line" temporary; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRevertWarehouseEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; JobNo: Code[20]; PostJobConsumption: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendICDocument(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; PurchaseLine: Record "Purchase Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDropShptPostBufferInsert(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempPrepmtPurchLineInsert(var TempPrepmtPurchLine: Record "Purchase Line" temporary; var TempPurchLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header"; CompleteFunctionality: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempPrepmtPurchLineModify(var TempPrepmtPurchLine: Record "Purchase Line" temporary; var TempPurchLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header"; CompleteFunctionality: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBlanketOrderLine(PurchLine: Record "Purchase Line"; Receive: Boolean; Ship: Boolean; Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchaseHeader(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; GenJnlLineDocType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchLineBeforePost(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; WhseShip: Boolean; WhseReceive: Boolean; RoundingLineInserted: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateInvoicedQtyOnPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; CommitIsSupressed: Boolean; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtPurchLineWithRounding(var PrepmtPurchLine: Record "Purchase Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchLineFixedAsset(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchLineItemCharge(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchLineJob(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchLineOthers(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusRelease(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateHandledICInboxTransaction(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostingAndDocumentDate(var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseHandlingRequired(PurchaseLine: Record "Purchase Line"; var Required: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillDeferralPostingBuffer(var PurchLine: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCountryCode(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var CountryRegionCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldPostWhseJnlLine(PurchLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvDiscountSetFilter(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnAfterSetPostingFlags(var PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnAfterSetSourceCode(PurchHeader: Record "Purchase Header"; SourceCodeSetup: Record "Source Code Setup"; var SrcCode: Code[10]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnBeforeCalcInvDiscount(var PurchaseHeader: Record "Purchase Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseReceive: Boolean; WhseShip: Boolean; var RefreshNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAssociatedOrderLinesOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAssocOrderLinesOnBeforeCheckOrderLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarehouseOnAfterSetFilters(var TempItemPurchLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyAndCheckItemChargeOnBeforeLoop(var TempPurchLine: Record "Purchase Line" temporary; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToTempLinesOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostBufferOnAfterInitAmounts(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var PurchLineACY: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemChargeLineOnAfterGet(var ItemChargePurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(var TempICGenJournalLine: Record "Gen. Journal Line" temporary; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCombineSalesOrderShipmentOnAfterUpdateBlanketOrderLine(var PurchaseHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCombineSalesOrderShipmentOnBeforeUpdateBlanketOrderLine(var SalesOrderLine: Record "Sales Line"; SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCombineSalesOrderShipmentOnAfterProcessDropShptPostBuffer(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; PurchRcptHeader: Record "Purch. Rcpt. Header"; SalesShptLine: Record "Sales Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoicePostingBufferOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargeOnAfterPostItemJnlLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargeLineOnBeforePostItemCharge(var TempItemChargeAssgntPurch: record "Item Charge Assignment (Purch)" temporary; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargeOnBeforePostItemJnlLine(var PurchaseLineToPost: Record "Purchase Line"; var PurchaseLine: Record "Purchase Line"; QtyToAssign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerOrderOnAfterCopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line"; GeneralLedgerSetup: Record "General Ledger Setup"; QtyToInvoice: Decimal; var TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerSalesRetRcptOnBeforeTestJobNo(ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerSalesShptOnBeforeTestJobNo(SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerRetShptOnBeforeTestJobNo(ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterCopyDocumentFields(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterCopyItemCharge(var ItemJournalLine: Record "Item Journal Line"; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeCopyDocumentFields(var ItemJournalLine: Record "Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; WhseReceive: Boolean; WhseShip: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineJobConsumption(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemJournalLine: Record "Item Journal Line"; var TempPurchReservEntry: Record "Reservation Entry" temporary; QtyToBeInvoiced: Decimal; QtyToBeReceived: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchItemLedgEntryNo: Integer; var IsHandled: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterSetFactor(var PurchaseLine: Record "Purchase Line"; var Factor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterPrepareItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForReceiptOnBeforeReceiptInvoiceErr(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForShipmentOnBeforeReturnShipmentInvoiceErr(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnAfterSetEverythingInvoiced(PurchaseLine: Record "Purchase Line"; var EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeInsertInvoiceLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeInsertReceiptLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeInsertReturnShipmentLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateInvoiceLineOnAfterPurchOrderLineModify(var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnBeforeInitOutstanding(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleasePurchDocumentOnBeforeSetStatus(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountOnBeforeIncrAmount(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchLineQty: Decimal; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeFinalizePosting(var PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumPurchLines2OnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssocOrderOnAfterSalesOrderHeaderModify(var SalesOrderHeader: Record "Sales Header"; var SalesSetup: Record "Sales & Receivables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssocOrderOnAfterSalesOrderLineModify(var SalesOrderLine: Record "Sales Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBlanketOrderLineOnBeforeCheck(var BlanketOrderPurchLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBlanketOrderLineOnBeforeInitOutstanding(var BlanketOrderPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWhseDocumentsOnAfterUpdateWhseRcpt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWhseDocumentsOnAfterUpdateWhseShpt(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
}

