codeunit 80 "Sales-Post"
{
    Permissions = TableData "Sales Line" = imd,
                  TableData "Purchase Header" = m,
                  TableData "Purchase Line" = m,
                  TableData "Invoice Post. Buffer" = imd,
                  TableData "Sales Shipment Header" = imd,
                  TableData "Sales Shipment Line" = imd,
                  TableData "Sales Invoice Header" = imd,
                  TableData "Sales Invoice Line" = imd,
                  TableData "Sales Cr.Memo Header" = imd,
                  TableData "Sales Cr.Memo Line" = imd,
                  TableData "Purch. Rcpt. Header" = imd,
                  TableData "Purch. Rcpt. Line" = imd,
                  TableData "Drop Shpt. Post. Buffer" = imd,
                  TableData "General Posting Setup" = imd,
                  TableData "Posted Assemble-to-Order Link" = i,
                  TableData "Item Entry Relation" = ri,
                  TableData "Value Entry Relation" = rid,
                  TableData "Return Receipt Header" = imd,
                  TableData "Return Receipt Line" = imd;
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
        TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempServiceItem2: Record "Service Item" temporary;
        TempServiceItemComp2: Record "Service Item Component" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        HasATOShippedNotInvoiced: Boolean;
        EverythingInvoiced: Boolean;
        SavedPreviewMode: Boolean;
        SavedSuppressCommit: Boolean;
        BiggestLineNo: Integer;
        ICGenJnlLineNo: Integer;
        LineCount: Integer;
    begin
        OnBeforePostSalesDoc(Rec, SuppressCommit, PreviewMode, HideProgressWindow);
        if not GuiAllowed then
            LockTimeout(false);

        ValidatePostingAndDocumentDate(Rec);

        SavedPreviewMode := PreviewMode;
        SavedSuppressCommit := SuppressCommit;
        ClearAllVariables;
        SuppressCommit := SavedSuppressCommit;
        PreviewMode := SavedPreviewMode;

        GetGLSetup;
        GetCurrency("Currency Code");

        SalesSetup.Get;
        SalesHeader := Rec;
        FillTempLines(SalesHeader, TempSalesLineGlobal);
        TempServiceItem2.DeleteAll;
        TempServiceItemComp2.DeleteAll;

        // Check that the invoice amount is zero or greater
        if SalesHeader.Invoice then
            if "Document Type" in ["Document Type"::Invoice, "Document Type"::Order] then begin
                TempSalesLineGlobal.CalcVATAmountLines(1, SalesHeader, TempSalesLineGlobal, TempVATAmountLine);
                if TempVATAmountLine.GetTotalLineAmount(false, '') < 0 then
                    Error(TotalInvoiceAmountNegativeErr);
            end;

        // Header
        CheckAndUpdate(SalesHeader);

        TempDeferralHeader.DeleteAll;
        TempDeferralLine.DeleteAll;
        TempInvoicePostBuffer.DeleteAll;
        TempDropShptPostBuffer.DeleteAll;
        EverythingInvoiced := true;

        // Lines
        OnBeforePostLines(TempSalesLineGlobal, SalesHeader, SuppressCommit, PreviewMode);

        LineCount := 0;
        RoundingLineInserted := false;
        AdjustFinalInvWith100PctPrepmt(TempSalesLineGlobal);

        TempVATAmountLineRemainder.DeleteAll;
        TempSalesLineGlobal.CalcVATAmountLines(1, SalesHeader, TempSalesLineGlobal, TempVATAmountLine);

        SalesLinesProcessed := false;
        if TempSalesLineGlobal.FindSet then
            repeat
                ItemJnlRollRndg := false;
                LineCount := LineCount + 1;
                if not HideProgressWindow then
                    Window.Update(2, LineCount);

                PostSalesLine(
                  SalesHeader, TempSalesLineGlobal, EverythingInvoiced, TempInvoicePostBuffer, TempVATAmountLine, TempVATAmountLineRemainder,
                  TempItemLedgEntryNotInvoiced, HasATOShippedNotInvoiced, TempDropShptPostBuffer, ICGenJnlLineNo,
                  TempServiceItem2, TempServiceItemComp2);

                if RoundingLineInserted then
                    LastLineRetrieved := true
                else begin
                    BiggestLineNo := MAX(BiggestLineNo, TempSalesLineGlobal."Line No.");
                    LastLineRetrieved := TempSalesLineGlobal.Next = 0;
                    if LastLineRetrieved and SalesSetup."Invoice Rounding" then
                        InvoiceRounding(SalesHeader, TempSalesLineGlobal, false, BiggestLineNo);
                end;
            until LastLineRetrieved;

        OnAfterPostSalesLines(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, WhseShip, WhseReceive, SalesLinesProcessed,
          SuppressCommit, EverythingInvoiced);

        if not SalesHeader.IsCreditDocType then begin
            ReverseAmount(TotalSalesLine);
            ReverseAmount(TotalSalesLineLCY);
            TotalSalesLineLCY."Unit Cost (LCY)" := -TotalSalesLineLCY."Unit Cost (LCY)";
        end;

        PostDropOrderShipment(SalesHeader, TempDropShptPostBuffer);
        if SalesHeader.Invoice then
            PostGLAndCustomer(SalesHeader, TempInvoicePostBuffer, CustLedgEntry);

        if ICGenJnlLineNo > 0 then
            PostICGenJnl;

        MakeInventoryAdjustment;
        UpdateLastPostingNos(SalesHeader);

        OnRunOnBeforeFinalizePosting(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, GenJnlPostLine, SuppressCommit);

        FinalizePosting(SalesHeader, EverythingInvoiced, TempDropShptPostBuffer);

        Rec := SalesHeader;
        SynchBOMSerialNo(TempServiceItem2, TempServiceItemComp2);
        if not (InvtPickPutaway or SuppressCommit) then begin
            Commit;
            UpdateAnalysisView.UpdateAll(0, true);
            UpdateItemAnalysisView.UpdateAll(0, true);
        end;

        OnAfterPostSalesDoc(
          Rec, GenJnlPostLine, SalesShptHeader."No.", ReturnRcptHeader."No.",
          SalesInvHeader."No.", SalesCrMemoHeader."No.", SuppressCommit, InvtPickPutaway);
        OnAfterPostSalesDocDropShipment(PurchRcptHeader."No.", SuppressCommit);
    end;

    var
        NothingToPostErr: Label 'There is nothing to post.';
        PostingLinesMsg: Label 'Posting lines              #2######\', Comment = 'Counter';
        PostingSalesAndVATMsg: Label 'Posting sales and VAT      #3######\', Comment = 'Counter';
        PostingCustomersMsg: Label 'Posting to customers       #4######\', Comment = 'Counter';
        PostingBalAccountMsg: Label 'Posting to bal. account    #5######', Comment = 'Counter';
        PostingLines2Msg: Label 'Posting lines              #2######', Comment = 'Counter';
        InvoiceNoMsg: Label '%1 %2 -> Invoice %3', Comment = '%1 = Document Type, %2 = Document No, %3 = Invoice No.';
        CreditMemoNoMsg: Label '%1 %2 -> Credit Memo %3', Comment = '%1 = Document Type, %2 = Document No, %3 = Credit Memo No.';
        DropShipmentErr: Label 'You cannot ship sales order line %1. The line is marked as a drop shipment and is not yet associated with a purchase order.', Comment = '%1 = Line No.';
        ShipmentSameSignErr: Label 'must have the same sign as the shipment';
        ShipmentLinesDeletedErr: Label 'The shipment lines have been deleted.';
        InvoiceMoreThanShippedErr: Label 'You cannot invoice more than you have shipped for order %1.', Comment = '%1 = Order No.';
        VATAmountTxt: Label 'VAT Amount';
        VATRateTxt: Label '%1% VAT', Comment = '%1 = VAT Rate';
        BlanketOrderQuantityGreaterThanErr: Label 'in the associated blanket order must not be greater than %1', Comment = '%1 = Quantity';
        BlanketOrderQuantityReducedErr: Label 'in the associated blanket order must not be reduced';
        ShipInvoiceReceiveErr: Label 'Please enter "Yes" in Ship and/or Invoice and/or Receive.';
        WarehouseRequiredErr: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.', Comment = '%1/%2 = Document Type, %3/%4 - Document No.,%5/%6 = Line No.';
        ReturnReceiptSameSignErr: Label 'must have the same sign as the return receipt';
        ReturnReceiptInvoicedErr: Label 'Line %1 of the return receipt %2, which you are attempting to invoice, has already been invoiced.', Comment = '%1 = Line No., %2 = Document No.';
        ShipmentInvoiceErr: Label 'Line %1 of the shipment %2, which you are attempting to invoice, has already been invoiced.', Comment = '%1 = Line No., %2 = Document No.';
        QuantityToInvoiceGreaterErr: Label 'The quantity you are attempting to invoice is greater than the quantity in shipment %1.', Comment = '%1 = Document No.';
        CannotAssignMoreErr: Label 'You cannot assign more than %1 units in %2 = %3, %4 = %5,%6 = %7.', Comment = '%1 = Quantity, %2/%3 = Document Type, %4/%5 - Document No.,%6/%7 = Line No.';
        MustAssignErr: Label 'You must assign all item charges, if you invoice everything.';
        Item: Record Item;
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        TempSalesLineGlobal: Record "Sales Line" temporary;
        xSalesLine: Record "Sales Line";
        SalesLineACY: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        Currency: Record Currency;
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
        TempATOTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecificationInv: Record "Tracking Specification" temporary;
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        JobTaskSalesLine: Record "Sales Line";
        TempICGenJnlLine: Record "Gen. Journal Line" temporary;
        TempPrepmtDeductLCYSalesLine: Record "Sales Line" temporary;
        TempSKU: Record "Stockkeeping Unit" temporary;
        DeferralPostBuffer: Record "Deferral Posting Buffer";
        TempDeferralHeader: Record "Deferral Header" temporary;
        TempDeferralLine: Record "Deferral Line" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        WhsePostRcpt: Codeunit "Whse.-Post Receipt";
        WhsePostShpt: Codeunit "Whse.-Post Shipment";
        PurchPost: Codeunit "Purch.-Post";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        JobPostLine: Codeunit "Job Post-Line";
        ServItemMgt: Codeunit ServItemManagement;
        AsmPost: Codeunit "Assembly-Post";
        DeferralUtilities: Codeunit "Deferral Utilities";
        UOMMgt: Codeunit "Unit of Measure Management";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        Window: Dialog;
        UseDate: Date;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        GenJnlLineDocType: Integer;
        ItemLedgShptEntryNo: Integer;
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
        CannotAssignInvoicedErr: Label 'You cannot assign item charges to the %1 %2 = %3,%4 = %5, %6 = %7, because it has been invoiced.', Comment = '%1 = Sales Line, %2/%3 = Document Type, %4/%5 - Document No.,%6/%7 = Line No.';
        InvoiceMoreThanReceivedErr: Label 'You cannot invoice more than you have received for return order %1.', Comment = '%1 = Order No.';
        ReturnReceiptLinesDeletedErr: Label 'The return receipt lines have been deleted.';
        InvoiceGreaterThanReturnReceiptErr: Label 'The quantity you are attempting to invoice is greater than the quantity in return receipt %1.', Comment = '%1 = Receipt No.';
        ItemJnlRollRndg: Boolean;
        RelatedItemLedgEntriesNotFoundErr: Label 'Related item ledger entries cannot be found.';
        ItemTrackingWrongSignErr: Label 'Item Tracking is signed wrongly.';
        ItemTrackingMismatchErr: Label 'Item Tracking does not match.';
        WhseShip: Boolean;
        WhseReceive: Boolean;
        InvtPickPutaway: Boolean;
        PostingDateNotAllowedErr: Label '%1 is not within your range of allowed posting dates.', Comment = '%1 - Posting Date field caption';
        ItemTrackQuantityMismatchErr: Label 'The %1 does not match the quantity defined in item tracking.', Comment = '%1 = Quantity';
        CannotBeGreaterThanErr: Label 'cannot be more than %1.', Comment = '%1 = Amount';
        CannotBeSmallerThanErr: Label 'must be at least %1.', Comment = '%1 = Amount';
        JobContractLine: Boolean;
        GLSetupRead: Boolean;
        ItemTrkgAlreadyOverruled: Boolean;
        PrepAmountToDeductToBigErr: Label 'The total %1 cannot be more than %2.', Comment = '%1 = Prepmt Amt to Deduct, %2 = Max Amount';
        PrepAmountToDeductToSmallErr: Label 'The total %1 must be at least %2.', Comment = '%1 = Prepmt Amt to Deduct, %2 = Max Amount';
        MustAssignItemChargeErr: Label 'You must assign item charge %1 if you want to invoice it.', Comment = '%1 = Item Charge No.';
        CannotInvoiceItemChargeErr: Label 'You can not invoice item charge %1 because there is no item ledger entry to assign it to.', Comment = '%1 = Item Charge No.';
        SalesLinesProcessed: Boolean;
        AssemblyCheckProgressMsg: Label '#1#################################\\Checking Assembly #2###########', Comment = '%1 = Text, %2 = Progress bar';
        AssemblyPostProgressMsg: Label '#1#################################\\Posting Assembly #2###########', Comment = '%1 = Text, %2 = Progress bar';
        AssemblyFinalizeProgressMsg: Label '#1#################################\\Finalizing Assembly #2###########', Comment = '%1 = Text, %2 = Progress bar';
        ReassignItemChargeErr: Label 'The order line that the item charge was originally assigned to has been fully posted. You must reassign the item charge to the posted receipt or shipment.';
        ReservationDisruptedQst: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment. Do you want to continue?', Comment = 'One or more reservation entries exist for the item with No. = 1000, Location Code = SILVER, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.', Comment = '%1 = Document Type';
        PreviewMode: Boolean;
        TotalInvoiceAmountNegativeErr: Label 'The total amount for the invoice must be 0 or greater.';
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        DownloadShipmentAlsoQst: Label 'You can also download the Sales - Shipment document now. Alternatively, you can access it from the Posted Sales Shipments window later.\\Do you want to download the Sales - Shipment document now?';
        SuppressCommit: Boolean;
        PostingPreviewNoTok: Label '***', Locked = true;
        InvPickExistsErr: Label 'One or more related inventory picks must be registered before you can post the shipment.';
        InvPutAwayExistsErr: Label 'One or more related inventory put-aways must be registered before you can post the receipt.';
        CheckSalesHeaderMsg: Label 'Check sales document fields.';
        HideProgressWindow: Boolean;

    procedure CopyToTempLines(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        OnCopyToTempLinesOnAfterSetFilters(SalesLine, SalesHeader);
        if SalesLine.FindSet then
            repeat
                TempSalesLine := SalesLine;
                TempSalesLine.Insert;
            until SalesLine.Next = 0;
    end;

    procedure FillTempLines(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
        TempSalesLine.Reset;
        if TempSalesLine.IsEmpty then
            CopyToTempLines(SalesHeader, TempSalesLine);
    end;

    local procedure ModifyTempLine(var TempSalesLineLocal: Record "Sales Line" temporary)
    var
        SalesLine: Record "Sales Line";
    begin
        TempSalesLineLocal.Modify;
        SalesLine := TempSalesLineLocal;
        SalesLine.Modify;
    end;

    procedure RefreshTempLines(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
        TempSalesLine.Reset;
        TempSalesLine.SetRange("Prepayment Line", false);
        TempSalesLine.DeleteAll;
        TempSalesLine.Reset;
        CopyToTempLines(SalesHeader, TempSalesLine);
    end;

    local procedure ResetTempLines(var TempSalesLineLocal: Record "Sales Line" temporary)
    begin
        TempSalesLineLocal.Reset;
        TempSalesLineLocal.Copy(TempSalesLineGlobal, true);
        OnAfterResetTempLines(TempSalesLineLocal);
    end;

    local procedure CalcInvoice(SalesHeader: Record "Sales Header") NewInvoice: Boolean
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        with SalesHeader do begin
            ResetTempLines(TempSalesLine);
            TempSalesLine.SetFilter(Quantity, '<>0');
            if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                TempSalesLine.SetFilter("Qty. to Invoice", '<>0');
            NewInvoice := not TempSalesLine.IsEmpty;
            if NewInvoice then
                case "Document Type" of
                    "Document Type"::Order:
                        if not Ship then begin
                            TempSalesLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                            NewInvoice := not TempSalesLine.IsEmpty;
                        end;
                    "Document Type"::"Return Order":
                        if not Receive then begin
                            TempSalesLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
                            NewInvoice := not TempSalesLine.IsEmpty;
                        end;
                end;
            exit(NewInvoice);
        end;
    end;

    local procedure CalcInvDiscount(var SalesHeader: Record "Sales Header")
    var
        SalesHeaderCopy: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        with SalesHeader do begin
            if not (SalesSetup."Calc. Inv. Discount" and (Status <> Status::Open)) then
                exit;

            SalesHeaderCopy := SalesHeader;
            SalesLine.Reset;
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            OnCalcInvDiscountSetFilter(SalesLine, SalesHeader);
            SalesLine.FindFirst;
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            RefreshTempLines(SalesHeader, TempSalesLineGlobal);
            Get("Document Type", "No.");
            RestoreSalesHeader(SalesHeader, SalesHeaderCopy);
            if not (PreviewMode or SuppressCommit) then
                Commit;
        end;
    end;

    local procedure RestoreSalesHeader(var SalesHeader: Record "Sales Header"; SalesHeaderCopy: Record "Sales Header")
    begin
        with SalesHeader do begin
            Invoice := SalesHeaderCopy.Invoice;
            Receive := SalesHeaderCopy.Receive;
            Ship := SalesHeaderCopy.Ship;
            "Posting No." := SalesHeaderCopy."Posting No.";
            "Shipping No." := SalesHeaderCopy."Shipping No.";
            "Return Receipt No." := SalesHeaderCopy."Return Receipt No.";
        end;

        OnAfterRestoreSalesHeader(SalesHeader, SalesHeaderCopy);
    end;

    local procedure CheckAndUpdate(var SalesHeader: Record "Sales Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        CheckDimensions: Codeunit "Check Dimensions";
        ErrorContextElement: Codeunit "Error Context Element";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        SetupRecID: RecordID;
        ModifyHeader: Boolean;
        RefreshTempLinesNeeded: Boolean;
    begin
        with SalesHeader do begin
            // Check
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, CheckSalesHeaderMsg);
            CheckMandatoryHeaderFields(SalesHeader);
            if GenJnlCheckLine.IsDateNotAllowed("Posting Date", SetupRecID) then
                ErrorMessageMgt.LogContextFieldError(
                  FieldNo("Posting Date"), StrSubstNo(PostingDateNotAllowedErr, FieldCaption("Posting Date")),
                  SetupRecID, ErrorMessageMgt.GetFieldNo(SetupRecID.TableNo, GLSetup.FieldName("Allow Posting From")),
                  ForwardLinkMgt.GetHelpCodeForAllowedPostingDate);

            SetPostingFlags(SalesHeader);
            if not HideProgressWindow then
                InitProgressWindow(SalesHeader);

            InvtPickPutaway := "Posting from Whse. Ref." <> 0;
            "Posting from Whse. Ref." := 0;

            CheckDimensions.CheckSalesDim(SalesHeader, TempSalesLineGlobal);

            CheckPostRestrictions(SalesHeader);

            if Invoice then
                Invoice := CalcInvoice(SalesHeader);

            if Invoice then
                CopyAndCheckItemCharge(SalesHeader);

            if Invoice and not IsCreditDocType then
                TestField("Due Date");

            if Ship then begin
                InitPostATOs(SalesHeader);
                Ship := CheckTrackingAndWarehouseForShip(SalesHeader);
                if not InvtPickPutaway then
                    if CheckIfInvPickExists(SalesHeader) then
                        Error(InvPickExistsErr);
            end;

            if Receive then begin
                Receive := CheckTrackingAndWarehouseForReceive(SalesHeader);
                if not InvtPickPutaway then
                    if CheckIfInvPutawayExists then
                        Error(InvPutAwayExistsErr);
            end;

            if not (Ship or Invoice or Receive) then
                Error(NothingToPostErr);

            if ("Shipping Advice" = "Shipping Advice"::Complete) and Ship then
                CheckShippingAdvice;

            CheckAssosOrderLines(SalesHeader);

            OnAfterCheckSalesDoc(SalesHeader, SuppressCommit, WhseShip, WhseReceive);
            ErrorMessageMgt.Finish(RecordId);

            // Update
            if Invoice then
                CreatePrepaymentLines(SalesHeader, true);

            ModifyHeader := UpdatePostingNos(SalesHeader);

            DropShipOrder := UpdateAssosOrderPostingNos(SalesHeader);

            OnBeforePostCommitSalesDoc(SalesHeader, GenJnlPostLine, PreviewMode, ModifyHeader, SuppressCommit, TempSalesLineGlobal);
            if not PreviewMode and ModifyHeader then begin
                Modify;
                if not SuppressCommit then
                    Commit;
            end;

            RefreshTempLinesNeeded := false;
            OnCheckAndUpdateOnBeforeCalcInvDiscount(
              SalesHeader, TempWhseRcptHeader, TempWhseShptHeader, WhseReceive, WhseShip, RefreshTempLinesNeeded);
            if RefreshTempLinesNeeded then
                RefreshTempLines(SalesHeader, TempSalesLineGlobal);

            CalcInvDiscount(SalesHeader);
            ReleaseSalesDocument(SalesHeader);

            if Ship or Receive then
                ArchiveUnpostedOrder(SalesHeader);

            CheckICPartnerBlocked(SalesHeader);
            SendICDocument(SalesHeader, ModifyHeader);
            UpdateHandledICInboxTransaction(SalesHeader);

            LockTables(SalesHeader);

            SourceCodeSetup.Get;
            SrcCode := SourceCodeSetup.Sales;

            InsertPostedHeaders(SalesHeader);

            UpdateIncomingDocument("Incoming Document Entry No.", "Posting Date", GenJnlLineDocNo);
        end;

        OnAfterCheckAndUpdate(SalesHeader, SuppressCommit, PreviewMode);
    end;

    local procedure PostSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var EverythingInvoiced: Boolean; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var ICGenJnlLineNo: Integer; var TempServiceItem2: Record "Service Item" temporary; var TempServiceItemComp2: Record "Service Item Component" temporary)
    var
        SalesShptLine: Record "Sales Shipment Line";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempPostedATOLink: Record "Posted Assemble-to-Order Link" temporary;
        InvoicePostBuffer: Record "Invoice Post. Buffer";
        CostBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        with SalesLine do begin
            if Type = Type::Item then
                CostBaseAmount := "Line Amount";
            if "Qty. per Unit of Measure" = 0 then
                "Qty. per Unit of Measure" := 1;

            TestSalesLine(SalesHeader, SalesLine);

            TempPostedATOLink.Reset;
            TempPostedATOLink.DeleteAll;
            if SalesHeader.Ship then
                PostATO(SalesHeader, SalesLine, TempPostedATOLink);

            UpdateSalesLineBeforePost(SalesHeader, SalesLine);

            TestUpdatedSalesLine(SalesLine);
            OnPostSalesLineOnAfterTestUpdatedSalesLine(SalesLine, EverythingInvoiced);

            if "Qty. to Invoice" + "Quantity Invoiced" <> Quantity then
                EverythingInvoiced := false;

            OnPostSalesLineOnAfterSetEverythingInvoiced(SalesLine, EverythingInvoiced);

            if Quantity <> 0 then
                DivideAmount(SalesHeader, SalesLine, 1, "Qty. to Invoice", TempVATAmountLine, TempVATAmountLineRemainder);

            CheckItemReservDisruption(SalesLine);
            RoundAmount(SalesHeader, SalesLine, "Qty. to Invoice");

            if not IsCreditDocType then begin
                ReverseAmount(SalesLine);
                ReverseAmount(SalesLineACY);
            end;

            RemQtyToBeInvoiced := "Qty. to Invoice";
            RemQtyToBeInvoicedBase := "Qty. to Invoice (Base)";

            OnPostSalesLineOnBeforePostItemTrackingLine(SalesHeader, SalesLine, WhseShip, WhseReceive, InvtPickPutaway);

            PostItemTrackingLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, HasATOShippedNotInvoiced);

            OnPostSalesLineOnAfterPostItemTrackingLine(SalesHeader, SalesLine, WhseShip, WhseReceive, InvtPickPutaway);

            case Type of
                Type::"G/L Account":
                    PostGLAccICLine(SalesHeader, SalesLine, ICGenJnlLineNo);
                Type::Item:
                    PostItemLine(SalesHeader, SalesLine, TempDropShptPostBuffer, TempPostedATOLink);
                Type::Resource:
                    PostResJnlLine(SalesHeader, SalesLine, JobTaskSalesLine);
                Type::"Charge (Item)":
                    PostItemChargeLine(SalesHeader, SalesLine);
            end;

            if (Type >= Type::"G/L Account") and ("Qty. to Invoice" <> 0) then begin
                AdjustPrepmtAmountLCY(SalesHeader, SalesLine);
                FillInvoicePostingBuffer(SalesHeader, SalesLine, SalesLineACY, TempInvoicePostBuffer, InvoicePostBuffer);
                InsertPrepmtAdjInvPostingBuf(SalesHeader, SalesLine, TempInvoicePostBuffer, InvoicePostBuffer);
            end;

            IsHandled := false;
            OnPostSalesLineOnBeforeTestJobNo(SalesLine, IsHandled);
            if not IsHandled then
                if not ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) then
                    TestField("Job No.", '');

            IsHandled := false;
            OnPostSalesLineOnBeforeInsertShipmentLine(
              SalesHeader, SalesLine, IsHandled, SalesLineACY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo);
            if not IsHandled then
                if (SalesShptHeader."No." <> '') and ("Shipment No." = '') and
                   not RoundingLineInserted and not "Prepayment Line"
                then
                    InsertShipmentLine(SalesHeader, SalesShptHeader, SalesLine, CostBaseAmount, TempServiceItem2, TempServiceItemComp2);

            IsHandled := false;
            OnPostSalesLineOnBeforeInsertReturnReceiptLine(SalesHeader, SalesLine, IsHandled);
            if (ReturnRcptHeader."No." <> '') and ("Return Receipt No." = '') and
               not RoundingLineInserted
            then
                InsertReturnReceiptLine(ReturnRcptHeader, SalesLine, CostBaseAmount);

            IsHandled := false;
            if SalesHeader.Invoice then
                if SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice] then begin
                    OnPostSalesLineOnBeforeInsertInvoiceLine(SalesHeader, SalesLine, IsHandled);
                    if not IsHandled then begin
                        SalesInvLine.InitFromSalesLine(SalesInvHeader, xSalesLine);
                        ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, SalesInvLine.RowID1);
                        if "Document Type" = "Document Type"::Order then begin
                            SalesInvLine."Order No." := "Document No.";
                            SalesInvLine."Order Line No." := "Line No.";
                        end else
                            if SalesShptLine.Get("Shipment No.", "Shipment Line No.") then begin
                                SalesInvLine."Order No." := SalesShptLine."Order No.";
                                SalesInvLine."Order Line No." := SalesShptLine."Order Line No.";
                            end;
                        OnBeforeSalesInvLineInsert(SalesInvLine, SalesInvHeader, xSalesLine, SuppressCommit);
                        SalesInvLine.Insert(true);
                        OnAfterSalesInvLineInsert(
                          SalesInvLine, SalesInvHeader, xSalesLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit,
                          SalesHeader, TempItemChargeAssgntSales);
                        CreatePostedDeferralScheduleFromSalesDoc(xSalesLine, SalesInvLine.GetDocumentType,
                          SalesInvHeader."No.", SalesInvLine."Line No.", SalesInvHeader."Posting Date");
                    end;
                end else begin
                    OnPostSalesLineOnBeforeInsertCrMemoLine(SalesHeader, SalesLine, IsHandled);
                    if not IsHandled then begin
                        SalesCrMemoLine.InitFromSalesLine(SalesCrMemoHeader, xSalesLine);
                        ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, SalesCrMemoLine.RowID1);
                        if "Document Type" = "Document Type"::"Return Order" then begin
                            SalesCrMemoLine."Order No." := "Document No.";
                            SalesCrMemoLine."Order Line No." := "Line No.";
                        end;
                        OnBeforeSalesCrMemoLineInsert(SalesCrMemoLine, SalesCrMemoHeader, xSalesLine, SuppressCommit);
                        SalesCrMemoLine.Insert(true);
                        OnAfterSalesCrMemoLineInsert(
                          SalesCrMemoLine, SalesCrMemoHeader, SalesHeader, xSalesLine, TempItemChargeAssgntSales, SuppressCommit);
                        CreatePostedDeferralScheduleFromSalesDoc(xSalesLine, SalesCrMemoLine.GetDocumentType,
                          SalesCrMemoHeader."No.", SalesCrMemoLine."Line No.", SalesCrMemoHeader."Posting Date");
                    end;
                end;
        end;

        OnAfterPostSalesLine(SalesHeader, SalesLine, SuppressCommit);
    end;

    local procedure PostGLAndCustomer(var SalesHeader: Record "Sales Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        OnBeforePostGLAndCustomer(SalesHeader, TempInvoicePostBuffer, CustLedgEntry, SuppressCommit, PreviewMode, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        with SalesHeader do begin
            // Post sales and VAT to G/L entries from posting buffer
            PostInvoicePostBuffer(SalesHeader, TempInvoicePostBuffer);

            // Post customer entry
            if GuiAllowed and not HideProgressWindow then
                Window.Update(4, 1);
            PostCustomerEntry(
              SalesHeader, TotalSalesLine, TotalSalesLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode);

            UpdateSalesHeader(CustLedgEntry);

            // Balancing account
            if "Bal. Account No." <> '' then begin
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(5, 1);
                PostBalancingEntry(
                  SalesHeader, TotalSalesLine, TotalSalesLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode);
            end;
        end;

        OnAfterPostGLAndCustomer(SalesHeader, GenJnlPostLine, TotalSalesLine, TotalSalesLineLCY, SuppressCommit);
    end;

    local procedure PostGLAccICLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var ICGenJnlLineNo: Integer)
    var
        GLAcc: Record "G/L Account";
    begin
        if (SalesLine."No." <> '') and not SalesLine."System-Created Entry" then begin
            GLAcc.Get(SalesLine."No.");
            GLAcc.TestField("Direct Posting", true);
            if (SalesLine."IC Partner Code" <> '') and SalesHeader.Invoice then
                InsertICGenJnlLine(SalesHeader, xSalesLine, ICGenJnlLineNo);
        end;
    end;

    local procedure PostItemLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var TempPostedATOLink: Record "Posted Assemble-to-Order Link" temporary)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        SalesLineToShip: Record "Sales Line";
        QtyToInvoice: Decimal;
        QtyToInvoiceBase: Decimal;
    begin
        ItemLedgShptEntryNo := 0;
        QtyToInvoice := RemQtyToBeInvoiced;
        QtyToInvoiceBase := RemQtyToBeInvoicedBase;

        with SalesHeader do begin
            if (SalesLine."Qty. to Ship" <> 0) and (SalesLine."Purch. Order Line No." <> 0) then begin
                TempDropShptPostBuffer."Order No." := SalesLine."Purchase Order No.";
                TempDropShptPostBuffer."Order Line No." := SalesLine."Purch. Order Line No.";
                TempDropShptPostBuffer.Quantity := -SalesLine."Qty. to Ship";
                TempDropShptPostBuffer."Quantity (Base)" := -SalesLine."Qty. to Ship (Base)";
                TempDropShptPostBuffer."Item Shpt. Entry No." :=
                  PostAssocItemJnlLine(SalesHeader, SalesLine, TempDropShptPostBuffer.Quantity, TempDropShptPostBuffer."Quantity (Base)");
                TempDropShptPostBuffer.Insert;
                SalesLine."Appl.-to Item Entry" := TempDropShptPostBuffer."Item Shpt. Entry No.";
            end;

            Clear(TempPostedATOLink);
            TempPostedATOLink.SetRange("Order No.", SalesLine."Document No.");
            TempPostedATOLink.SetRange("Order Line No.", SalesLine."Line No.");
            if TempPostedATOLink.FindFirst then
                PostATOAssocItemJnlLine(SalesHeader, SalesLine, TempPostedATOLink, QtyToInvoice, QtyToInvoiceBase);

            if QtyToInvoice <> 0 then
                ItemLedgShptEntryNo :=
                  PostItemJnlLine(
                    SalesHeader, SalesLine,
                    QtyToInvoice, QtyToInvoiceBase,
                    QtyToInvoice, QtyToInvoiceBase,
                    0, '', DummyTrackingSpecification, false);

            // Invoice discount amount is also included in expected sales amount posted for shipment or return receipt.
            MakeSalesLineToShip(SalesLineToShip, SalesLine);

            if SalesLineToShip.IsCreditDocType then begin
                if Abs(SalesLineToShip."Return Qty. to Receive") > Abs(QtyToInvoice) then
                    ItemLedgShptEntryNo :=
                      PostItemJnlLine(
                        SalesHeader, SalesLineToShip,
                        SalesLineToShip."Return Qty. to Receive" - QtyToInvoice,
                        SalesLineToShip."Return Qty. to Receive (Base)" - QtyToInvoiceBase,
                        0, 0, 0, '', DummyTrackingSpecification, false);
            end else begin
                if Abs(SalesLineToShip."Qty. to Ship") > Abs(QtyToInvoice) + Abs(TempPostedATOLink."Assembled Quantity") then
                    ItemLedgShptEntryNo :=
                      PostItemJnlLine(
                        SalesHeader, SalesLineToShip,
                        SalesLineToShip."Qty. to Ship" - TempPostedATOLink."Assembled Quantity" - QtyToInvoice,
                        SalesLineToShip."Qty. to Ship (Base)" - TempPostedATOLink."Assembled Quantity (Base)" - QtyToInvoiceBase,
                        0, 0, 0, '', DummyTrackingSpecification, false);
            end;
        end;
    end;

    local procedure PostItemChargeLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        SalesLineBackup: Record "Sales Line";
    begin
        if not (SalesHeader.Invoice and (SalesLine."Qty. to Invoice" <> 0)) then
            exit;

        ItemJnlRollRndg := true;
        SalesLineBackup.Copy(SalesLine);
        if FindTempItemChargeAssgntSales(SalesLineBackup."Line No.") then
            repeat
                case TempItemChargeAssgntSales."Applies-to Doc. Type" of
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::Shipment:
                        begin
                            PostItemChargePerShpt(SalesHeader, SalesLineBackup);
                            TempItemChargeAssgntSales.Mark(true);
                        end;
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::"Return Receipt":
                        begin
                            PostItemChargePerRetRcpt(SalesHeader, SalesLineBackup);
                            TempItemChargeAssgntSales.Mark(true);
                        end;
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::Order,
                  TempItemChargeAssgntSales."Applies-to Doc. Type"::Invoice,
                  TempItemChargeAssgntSales."Applies-to Doc. Type"::"Return Order",
                  TempItemChargeAssgntSales."Applies-to Doc. Type"::"Credit Memo":
                        CheckItemCharge(TempItemChargeAssgntSales);
                end;
            until TempItemChargeAssgntSales.Next = 0;
    end;

    local procedure PostItemTrackingLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean)
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TrackingSpecificationExists: Boolean;
    begin
        if SalesLine."Prepayment Line" then
            exit;

        if SalesHeader.Invoice then
            if SalesLine."Qty. to Invoice" = 0 then
                TrackingSpecificationExists := false
            else
                TrackingSpecificationExists :=
                  ReserveSalesLine.RetrieveInvoiceSpecification(SalesLine, TempTrackingSpecification);

        PostItemTracking(
          SalesHeader, SalesLine, TrackingSpecificationExists, TempTrackingSpecification,
          TempItemLedgEntryNotInvoiced, HasATOShippedNotInvoiced);

        if TrackingSpecificationExists then
            SaveInvoiceSpecification(TempTrackingSpecification);
    end;

    local procedure PostItemJnlLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; ItemLedgShptEntryNo: Integer; ItemChargeNo: Code[20]; TrackingSpecification: Record "Tracking Specification"; IsATO: Boolean): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseTrackingSpecification: Record "Tracking Specification" temporary;
        OriginalItemJnlLine: Record "Item Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
        PostWhseJnlLine: Boolean;
        InvDiscAmountPerShippedQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(
          SalesHeader, SalesLine, QtyToBeShipped, QtyToBeShippedBase, QtyToBeInvoiced, QtyToBeInvoicedBase,
          ItemLedgShptEntryNo, ItemChargeNo, TrackingSpecification, IsATO, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        if not ItemJnlRollRndg then begin
            RemAmt := 0;
            RemDiscAmt := 0;
        end;

        with ItemJnlLine do begin
            Init;
            CopyFromSalesHeader(SalesHeader);
            CopyFromSalesLine(SalesLine);
            "Country/Region Code" := GetCountryCode(SalesLine, SalesHeader);

            CopyTrackingFromSpec(TrackingSpecification);
            "Item Shpt. Entry No." := ItemLedgShptEntryNo;

            Quantity := -QtyToBeShipped;
            "Quantity (Base)" := -QtyToBeShippedBase;
            "Invoiced Quantity" := -QtyToBeInvoiced;
            "Invoiced Qty. (Base)" := -QtyToBeInvoicedBase;

            PostItemJnlLineCopyDocumentFields(ItemJnlLine, SalesHeader, SalesLine, QtyToBeShipped, QtyToBeInvoiced);

            if QtyToBeInvoiced <> 0 then
                "Invoice No." := GenJnlLineDocNo;

            "Assemble to Order" := IsATO;
            if "Assemble to Order" then
                "Applies-to Entry" := SalesLine.FindOpenATOEntry('', '')
            else
                "Applies-to Entry" := SalesLine."Appl.-to Item Entry";

            if ItemChargeNo <> '' then begin
                "Item Charge No." := ItemChargeNo;
                SalesLine."Qty. to Invoice" := QtyToBeInvoiced;
            end else
                "Applies-from Entry" := SalesLine."Appl.-from Item Entry";

            if QtyToBeInvoiced <> 0 then begin
                Amount := -(SalesLine.Amount * (QtyToBeInvoiced / SalesLine."Qty. to Invoice") - RemAmt);
                if SalesHeader."Prices Including VAT" then
                    "Discount Amount" :=
                      -((SalesLine."Line Discount Amount" + SalesLine."Inv. Discount Amount") /
                        (1 + SalesLine."VAT %" / 100) * (QtyToBeInvoiced / SalesLine."Qty. to Invoice") - RemDiscAmt)
                else
                    "Discount Amount" :=
                      -((SalesLine."Line Discount Amount" + SalesLine."Inv. Discount Amount") *
                        (QtyToBeInvoiced / SalesLine."Qty. to Invoice") - RemDiscAmt);
                RemAmt := Amount - Round(Amount);
                RemDiscAmt := "Discount Amount" - Round("Discount Amount");
                Amount := Round(Amount);
                "Discount Amount" := Round("Discount Amount");
            end else begin
                InvDiscAmountPerShippedQty := Abs(SalesLine."Inv. Discount Amount") * QtyToBeShipped / SalesLine.Quantity;
                Amount := QtyToBeShipped * SalesLine."Unit Price";
                if SalesHeader."Prices Including VAT" then
                    Amount :=
                      -((Amount * (1 - SalesLine."Line Discount %" / 100) - InvDiscAmountPerShippedQty) /
                        (1 + SalesLine."VAT %" / 100) - RemAmt)
                else
                    Amount :=
                      -(Amount * (1 - SalesLine."Line Discount %" / 100) - InvDiscAmountPerShippedQty - RemAmt);
                RemAmt := Amount - Round(Amount);
                if SalesHeader."Currency Code" <> '' then
                    Amount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          SalesHeader."Posting Date", SalesHeader."Currency Code",
                          Amount, SalesHeader."Currency Factor"))
                else
                    Amount := Round(Amount);
            end;

            if not JobContractLine then begin
                PostItemJnlLineBeforePost(ItemJnlLine, SalesLine, TempWhseJnlLine, PostWhseJnlLine, QtyToBeShippedBase);

                OriginalItemJnlLine := ItemJnlLine;
                if not IsItemJnlPostLineHandled(ItemJnlLine, SalesLine, SalesHeader) then
                    ItemJnlPostLine.RunWithCheck(ItemJnlLine);

                if IsATO then
                    PostItemJnlLineTracking(
                      SalesLine, TempWhseTrackingSpecification, PostWhseJnlLine, QtyToBeInvoiced, TempATOTrackingSpecification)
                else
                    PostItemJnlLineTracking(SalesLine, TempWhseTrackingSpecification, PostWhseJnlLine, QtyToBeInvoiced, TempHandlingSpecification);

                IsHandled := false;
                OnPostItemJnlLineOnBeforePostItemJnlLineWhseLine(
                  ItemJnlLine, TempWhseJnlLine, TempWhseTrackingSpecification, TempTrackingSpecification, IsHandled);
                if not IsHandled then
                    PostItemJnlLineWhseLine(TempWhseJnlLine, TempWhseTrackingSpecification);

                OnAfterPostItemJnlLineWhseLine(SalesLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit);

                if (SalesLine.Type = SalesLine.Type::Item) and SalesHeader.Invoice then
                    PostItemJnlLineItemCharges(SalesHeader, SalesLine, OriginalItemJnlLine, "Item Shpt. Entry No.");
            end;

            OnAfterPostItemJnlLine(ItemJnlLine, SalesLine, SalesHeader, ItemJnlPostLine);

            exit("Item Shpt. Entry No.");
        end;
    end;

    local procedure PostItemJnlLineCopyDocumentFields(var ItemJnlLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; QtyToBeShipped: Decimal; QtyToBeInvoiced: Decimal)
    begin
        with ItemJnlLine do
            if QtyToBeShipped = 0 then
                if SalesLine.IsCreditDocType then
                    CopyDocumentFields(
                      "Document Type"::"Sales Credit Memo", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, SalesHeader."Posting No. Series")
                else
                    CopyDocumentFields(
                      "Document Type"::"Sales Invoice", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, SalesHeader."Posting No. Series")
            else begin
                if SalesLine.IsCreditDocType then
                    CopyDocumentFields(
                      "Document Type"::"Sales Return Receipt",
                      ReturnRcptHeader."No.", ReturnRcptHeader."External Document No.", SrcCode, ReturnRcptHeader."No. Series")
                else
                    CopyDocumentFields(
                      "Document Type"::"Sales Shipment", SalesShptHeader."No.", SalesShptHeader."External Document No.", SrcCode,
                      SalesShptHeader."No. Series");
                if QtyToBeInvoiced <> 0 then begin
                    if "Document No." = '' then
                        if SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo" then
                            CopyDocumentFields(
                              "Document Type"::"Sales Credit Memo", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, SalesHeader."Posting No. Series")
                        else
                            CopyDocumentFields(
                              "Document Type"::"Sales Invoice", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, SalesHeader."Posting No. Series");
                    "Posting No. Series" := SalesHeader."Posting No. Series";
                end;
            end;

        OnPostItemJnlLineOnAfterCopyDocumentFields(ItemJnlLine, SalesLine, TempWhseRcptHeader, TempWhseShptHeader);
    end;

    local procedure PostItemJnlLineItemCharges(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var OriginalItemJnlLine: Record "Item Journal Line"; ItemShptEntryNo: Integer)
    var
        ItemChargeSalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            ClearItemChargeAssgntFilter;
            TempItemChargeAssgntSales.SetCurrentKey(
              "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
            TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type", "Document Type");
            TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.", "Document No.");
            TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", "Line No.");
            if TempItemChargeAssgntSales.FindSet then
                repeat
                    TestField("Allow Item Charge Assignment");
                    GetItemChargeLine(SalesHeader, ItemChargeSalesLine);
                    ItemChargeSalesLine.CalcFields("Qty. Assigned");
                    if (ItemChargeSalesLine."Qty. to Invoice" <> 0) or
                       (Abs(ItemChargeSalesLine."Qty. Assigned") < Abs(ItemChargeSalesLine."Quantity Invoiced"))
                    then begin
                        OriginalItemJnlLine."Item Shpt. Entry No." := ItemShptEntryNo;
                        PostItemChargePerOrder(SalesHeader, SalesLine, OriginalItemJnlLine, ItemChargeSalesLine);
                        TempItemChargeAssgntSales.Mark(true);
                    end;
                until TempItemChargeAssgntSales.Next = 0;
        end;
    end;

    local procedure PostItemJnlLineTracking(SalesLine: Record "Sales Line"; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; PostWhseJnlLine: Boolean; QtyToBeInvoiced: Decimal; var TempTrackingSpec: Record "Tracking Specification" temporary)
    begin
        if ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpec) then
            if TempTrackingSpec.FindSet then
                repeat
                    TempTrackingSpecification := TempTrackingSpec;
                    TempTrackingSpecification.SetSourceFromSalesLine(SalesLine);
                    if TempTrackingSpecification.Insert then;
                    if QtyToBeInvoiced <> 0 then begin
                        TempTrackingSpecificationInv := TempTrackingSpecification;
                        if TempTrackingSpecificationInv.Insert then;
                    end;
                    if PostWhseJnlLine then begin
                        TempWhseTrackingSpecification := TempTrackingSpecification;
                        if TempWhseTrackingSpecification.Insert then;
                    end;
                until TempTrackingSpec.Next = 0;
    end;

    local procedure PostItemJnlLineWhseLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary)
    var
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
    begin
        ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempWhseTrackingSpecification, false);
        if TempWhseJnlLine2.FindSet then
            repeat
                WhseJnlPostLine.Run(TempWhseJnlLine2);
            until TempWhseJnlLine2.Next = 0;
        TempWhseTrackingSpecification.DeleteAll;
    end;

    local procedure PostItemJnlLineBeforePost(var ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var PostWhseJnlLine: Boolean; QtyToBeShippedBase: Decimal)
    var
        CheckApplFromItemEntry: Boolean;
    begin
        with ItemJnlLine do begin
            if SalesSetup."Exact Cost Reversing Mandatory" and (SalesLine.Type = SalesLine.Type::Item) then
                if SalesLine.IsCreditDocType then
                    CheckApplFromItemEntry := SalesLine.Quantity > 0
                else
                    CheckApplFromItemEntry := SalesLine.Quantity < 0;

            if (SalesLine."Location Code" <> '') and (SalesLine.Type = SalesLine.Type::Item) and (Quantity <> 0) then
                if ShouldPostWhseJnlLine(SalesLine) then begin
                    CreateWhseJnlLine(ItemJnlLine, SalesLine, TempWhseJnlLine);
                    PostWhseJnlLine := true;
                end;

            OnPostItemJnlLineOnBeforeTransferReservToItemJnlLine(SalesLine, ItemJnlLine);

            if QtyToBeShippedBase <> 0 then begin
                if SalesLine.IsCreditDocType then
                    ReserveSalesLine.TransferSalesLineToItemJnlLine(SalesLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
                else
                    TransferReservToItemJnlLine(
                      SalesLine, ItemJnlLine, -QtyToBeShippedBase, TempTrackingSpecification, CheckApplFromItemEntry);

                if CheckApplFromItemEntry and SalesLine.IsInventoriableItem then
                    SalesLine.TestField("Appl.-from Item Entry");
            end;
        end;

        OnAfterPostItemJnlLineBeforePost(ItemJnlLine, SalesLine);
    end;

    local procedure ShouldPostWhseJnlLine(SalesLine: Record "Sales Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeShouldPostWhseJnlLine(SalesLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with SalesLine do begin
            GetLocation("Location Code");
            if (("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and
                Location."Directed Put-away and Pick") or
               (Location."Bin Mandatory" and not (WhseShip or WhseReceive or InvtPickPutaway or "Drop Shipment"))
            then
                exit(true);
        end;
        exit(false);
    end;

    local procedure PostItemChargePerOrder(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; ItemJnlLine2: Record "Item Journal Line"; ItemChargeSalesLine: Record "Sales Line")
    var
        NonDistrItemJnlLine: Record "Item Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
        QtyToInvoice: Decimal;
        Factor: Decimal;
        OriginalAmt: Decimal;
        OriginalDiscountAmt: Decimal;
        OriginalQty: Decimal;
        SignFactor: Integer;
        TotalChargeAmt2: Decimal;
        TotalChargeAmtLCY2: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforePostItemChargePerOrder(SalesHeader, SalesLine, ItemJnlLine2, ItemChargeSalesLine, SuppressCommit);

        IsHandled := false;
        OnPostItemChargePerOrderOnBeforeTestJobNo(SalesLine, IsHandled);
        if not IsHandled then
            SalesLine.TestField("Job No.", '');
        SalesLine.TestField("Allow Item Charge Assignment", true);

        with TempItemChargeAssgntSales do begin
            ItemJnlLine2."Document No." := GenJnlLineDocNo;
            ItemJnlLine2."External Document No." := GenJnlLineExtDocNo;
            ItemJnlLine2."Item Charge No." := "Item Charge No.";
            ItemJnlLine2.Description := ItemChargeSalesLine.Description;
            ItemJnlLine2."Unit of Measure Code" := '';
            ItemJnlLine2."Qty. per Unit of Measure" := 1;
            ItemJnlLine2."Applies-from Entry" := 0;
            if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                QtyToInvoice :=
                  CalcQtyToInvoice(SalesLine."Return Qty. to Receive (Base)", SalesLine."Qty. to Invoice (Base)")
            else
                QtyToInvoice :=
                  CalcQtyToInvoice(SalesLine."Qty. to Ship (Base)", SalesLine."Qty. to Invoice (Base)");
            if ItemJnlLine2."Invoiced Quantity" = 0 then begin
                ItemJnlLine2."Invoiced Quantity" := ItemJnlLine2.Quantity;
                ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
            end;
            ItemJnlLine2."Document Line No." := ItemChargeSalesLine."Line No.";

            ItemJnlLine2.Amount := "Amount to Assign" * ItemJnlLine2."Invoiced Qty. (Base)" / QtyToInvoice;
            if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                ItemJnlLine2.Amount := -ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost (ACY)" :=
              Round(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                Currency."Unit-Amount Rounding Precision");

            TotalChargeAmt2 := TotalChargeAmt2 + ItemJnlLine2.Amount;
            if SalesHeader."Currency Code" <> '' then
                ItemJnlLine2.Amount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    UseDate, SalesHeader."Currency Code", TotalChargeAmt2 + TotalSalesLine.Amount, SalesHeader."Currency Factor") -
                  TotalChargeAmtLCY2 - TotalSalesLineLCY.Amount
            else
                ItemJnlLine2.Amount := TotalChargeAmt2 - TotalChargeAmtLCY2;

            TotalChargeAmtLCY2 := TotalChargeAmtLCY2 + ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost" := Round(
                ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)", GLSetup."Unit-Amount Rounding Precision");
            ItemJnlLine2."Applies-to Entry" := ItemJnlLine2."Item Shpt. Entry No.";

            if SalesHeader."Currency Code" <> '' then
                ItemJnlLine2."Discount Amount" := Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      ItemChargeSalesLine."Inv. Discount Amount" * ItemJnlLine2."Invoiced Qty. (Base)" /
                      ItemChargeSalesLine."Quantity (Base)" * "Qty. to Assign" / QtyToInvoice,
                      SalesHeader."Currency Factor"), GLSetup."Amount Rounding Precision")
            else
                ItemJnlLine2."Discount Amount" := Round(
                    ItemChargeSalesLine."Inv. Discount Amount" * ItemJnlLine2."Invoiced Qty. (Base)" /
                    ItemChargeSalesLine."Quantity (Base)" * "Qty. to Assign" / QtyToInvoice,
                    GLSetup."Amount Rounding Precision");

            if SalesLine.IsCreditDocType then
                ItemJnlLine2."Discount Amount" := -ItemJnlLine2."Discount Amount";
            ItemJnlLine2."Shortcut Dimension 1 Code" := ItemChargeSalesLine."Shortcut Dimension 1 Code";
            ItemJnlLine2."Shortcut Dimension 2 Code" := ItemChargeSalesLine."Shortcut Dimension 2 Code";
            ItemJnlLine2."Dimension Set ID" := ItemChargeSalesLine."Dimension Set ID";
            ItemJnlLine2."Gen. Prod. Posting Group" := ItemChargeSalesLine."Gen. Prod. Posting Group";

            OnPostItemChargePerOrderOnAfterCopyToItemJnlLine(
              ItemJnlLine2, ItemChargeSalesLine, GLSetup, QtyToInvoice, TempItemChargeAssgntSales);
        end;

        with TempTrackingSpecificationInv do begin
            Reset;
            SetRange("Source Type", DATABASE::"Sales Line");
            SetRange("Source ID", TempItemChargeAssgntSales."Applies-to Doc. No.");
            SetRange("Source Ref. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
            if IsEmpty then
                ItemJnlPostLine.RunWithCheck(ItemJnlLine2)
            else begin
                FindSet;
                NonDistrItemJnlLine := ItemJnlLine2;
                OriginalAmt := NonDistrItemJnlLine.Amount;
                OriginalDiscountAmt := NonDistrItemJnlLine."Discount Amount";
                OriginalQty := NonDistrItemJnlLine."Quantity (Base)";
                if ("Quantity (Base)" / OriginalQty) > 0 then
                    SignFactor := 1
                else
                    SignFactor := -1;
                repeat
                    Factor := "Quantity (Base)" / OriginalQty * SignFactor;
                    if Abs("Quantity (Base)") < Abs(NonDistrItemJnlLine."Quantity (Base)") then begin
                        ItemJnlLine2."Quantity (Base)" := -"Quantity (Base)";
                        ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
                        ItemJnlLine2.Amount :=
                          Round(OriginalAmt * Factor, GLSetup."Amount Rounding Precision");
                        ItemJnlLine2."Discount Amount" :=
                          Round(OriginalDiscountAmt * Factor, GLSetup."Amount Rounding Precision");
                        ItemJnlLine2."Unit Cost" :=
                          Round(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                            GLSetup."Unit-Amount Rounding Precision") * SignFactor;
                        ItemJnlLine2."Item Shpt. Entry No." := "Item Ledger Entry No.";
                        ItemJnlLine2."Applies-to Entry" := "Item Ledger Entry No.";
                        ItemJnlLine2.CopyTrackingFromSpec(TempTrackingSpecificationInv);
                        ItemJnlPostLine.RunWithCheck(ItemJnlLine2);
                        ItemJnlLine2."Location Code" := NonDistrItemJnlLine."Location Code";
                        NonDistrItemJnlLine."Quantity (Base)" -= ItemJnlLine2."Quantity (Base)";
                        NonDistrItemJnlLine.Amount -= ItemJnlLine2.Amount;
                        NonDistrItemJnlLine."Discount Amount" -= ItemJnlLine2."Discount Amount";
                    end else begin // the last time
                        NonDistrItemJnlLine."Quantity (Base)" := -"Quantity (Base)";
                        NonDistrItemJnlLine."Invoiced Qty. (Base)" := -"Quantity (Base)";
                        NonDistrItemJnlLine."Unit Cost" :=
                          Round(NonDistrItemJnlLine.Amount / NonDistrItemJnlLine."Invoiced Qty. (Base)",
                            GLSetup."Unit-Amount Rounding Precision");
                        NonDistrItemJnlLine."Item Shpt. Entry No." := "Item Ledger Entry No.";
                        NonDistrItemJnlLine."Applies-to Entry" := "Item Ledger Entry No.";
                        NonDistrItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecificationInv);
                        ItemJnlPostLine.RunWithCheck(NonDistrItemJnlLine);
                        NonDistrItemJnlLine."Location Code" := ItemJnlLine2."Location Code";
                    end;
                until Next = 0;
            end;
        end;
    end;

    local procedure PostItemChargePerShpt(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        if not SalesShptLine.Get(
             TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.")
        then
            Error(ShipmentLinesDeletedErr);

        IsHandled := false;
        OnPostItemChargePerShptOnBeforeTestJobNo(SalesShptLine, IsHandled);
        if not IsHandled then
            SalesShptLine.TestField("Job No.", '');

        if SalesShptLine."Item Shpt. Entry No." <> 0 then
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                TempItemLedgEntry, -SalesShptLine."Quantity (Base)", SalesShptLine."Item Shpt. Entry No.")
        else begin
            DistributeCharge := true;
            if not ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
                 DATABASE::"Sales Shipment Line", 0, SalesShptLine."Document No.",
                 '', 0, SalesShptLine."Line No.", -SalesShptLine."Quantity (Base)")
            then
                Error(RelatedItemLedgEntriesNotFoundErr);
        end;

        if DistributeCharge then
            PostDistributeItemCharge(
              SalesHeader, SalesLine, TempItemLedgEntry, SalesShptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Qty. to Assign", TempItemChargeAssgntSales."Amount to Assign")
        else
            PostItemCharge(SalesHeader, SalesLine,
              SalesShptLine."Item Shpt. Entry No.", SalesShptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign",
              TempItemChargeAssgntSales."Qty. to Assign");
    end;

    local procedure PostItemChargePerRetRcpt(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        if not ReturnRcptLine.Get(
             TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.")
        then
            Error(ShipmentLinesDeletedErr);

        IsHandled := false;
        OnPostItemChargePerRetRcptOnBeforeTestFieldJobNo(ReturnRcptLine, IsHandled);
        if not IsHandled then
            ReturnRcptLine.TestField("Job No.", '');

        if ReturnRcptLine."Item Rcpt. Entry No." <> 0 then
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                TempItemLedgEntry, ReturnRcptLine."Quantity (Base)", ReturnRcptLine."Item Rcpt. Entry No.")
        else begin
            DistributeCharge := true;
            if not ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
                 DATABASE::"Return Receipt Line", 0, ReturnRcptLine."Document No.",
                 '', 0, ReturnRcptLine."Line No.", ReturnRcptLine."Quantity (Base)")
            then
                Error(RelatedItemLedgEntriesNotFoundErr);
        end;

        if DistributeCharge then
            PostDistributeItemCharge(
              SalesHeader, SalesLine, TempItemLedgEntry, ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Qty. to Assign", TempItemChargeAssgntSales."Amount to Assign")
        else
            PostItemCharge(SalesHeader, SalesLine,
              ReturnRcptLine."Item Rcpt. Entry No.", ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign",
              TempItemChargeAssgntSales."Qty. to Assign")
    end;

    local procedure PostDistributeItemCharge(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; NonDistrQuantity: Decimal; NonDistrQtyToAssign: Decimal; NonDistrAmountToAssign: Decimal)
    var
        Factor: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
    begin
        if TempItemLedgEntry.FindSet then
            repeat
                Factor := Abs(TempItemLedgEntry.Quantity / NonDistrQuantity);
                QtyToAssign := NonDistrQtyToAssign * Factor;
                AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                if Factor < 1 then begin
                    PostItemCharge(SalesHeader, SalesLine,
                      TempItemLedgEntry."Entry No.", -TempItemLedgEntry.Quantity,
                      AmountToAssign, QtyToAssign);
                    NonDistrQuantity := NonDistrQuantity + TempItemLedgEntry.Quantity;
                    NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                    NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                end else // the last time
                    PostItemCharge(SalesHeader, SalesLine,
                      TempItemLedgEntry."Entry No.", -TempItemLedgEntry.Quantity,
                      NonDistrAmountToAssign, NonDistrQtyToAssign);
            until TempItemLedgEntry.Next = 0
        else
            Error(RelatedItemLedgEntriesNotFoundErr);
    end;

    local procedure PostAssocItemJnlLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        PurchOrderHeader.Get(
          PurchOrderHeader."Document Type"::Order, SalesLine."Purchase Order No.");
        PurchOrderLine.Get(
          PurchOrderLine."Document Type"::Order, SalesLine."Purchase Order No.", SalesLine."Purch. Order Line No.");

        InitAssocItemJnlLine(ItemJnlLine, PurchOrderHeader, PurchOrderLine, SalesHeader, QtyToBeShipped, QtyToBeShippedBase);

        IsHandled := false;
        OnPostAssocItemJnlLineOnBeforePost(ItemJnlLine, PurchOrderLine, IsHandled);
        if (PurchOrderLine."Job No." = '') or IsHandled then begin
            TransferReservFromPurchLine(PurchOrderLine, ItemJnlLine, SalesLine, QtyToBeShippedBase);
            OnBeforePostAssocItemJnlLine(ItemJnlLine, PurchOrderLine, SuppressCommit, SalesLine);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);

            // Handle Item Tracking
            if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
                if TempHandlingSpecification2.FindSet then
                    repeat
                        TempTrackingSpecification := TempHandlingSpecification2;
                        TempTrackingSpecification.SetSourceFromPurchLine(PurchOrderLine);
                        if TempTrackingSpecification.Insert then;
                        ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                        ItemEntryRelation.SetSource(DATABASE::"Purch. Rcpt. Line", 0, PurchOrderHeader."Receiving No.", PurchOrderLine."Line No.");
                        ItemEntryRelation.SetOrderInfo(PurchOrderLine."Document No.", PurchOrderLine."Line No.");
                        ItemEntryRelation.Insert;
                    until TempHandlingSpecification2.Next = 0;
                exit(0);
            end;
        end;

        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure InitAssocItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; PurchOrderHeader: Record "Purchase Header"; PurchOrderLine: Record "Purchase Line"; SalesHeader: Record "Sales Header"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal)
    begin
        OnBeforeInitAssocItemJnlLine(ItemJnlLine, PurchOrderHeader, PurchOrderLine, SalesHeader);

        with ItemJnlLine do begin
            Init;
            "Entry Type" := "Entry Type"::Purchase;
            CopyDocumentFields(
              "Document Type"::"Purchase Receipt", PurchOrderHeader."Receiving No.", PurchOrderHeader."No.", SrcCode,
              PurchOrderHeader."Posting No. Series");

            CopyFromPurchHeader(PurchOrderHeader);
            "Posting Date" := SalesHeader."Posting Date";
            "Document Date" := SalesHeader."Document Date";
            CopyFromPurchLine(PurchOrderLine);

            Quantity := QtyToBeShipped;
            "Quantity (Base)" := QtyToBeShippedBase;
            "Invoiced Quantity" := 0;
            "Invoiced Qty. (Base)" := 0;
            "Source Currency Code" := SalesHeader."Currency Code";
            Amount := Round(PurchOrderLine.Amount * QtyToBeShipped / PurchOrderLine.Quantity);
            "Discount Amount" := PurchOrderLine."Line Discount Amount";

            "Applies-to Entry" := 0;
        end;

        OnAfterInitAssocItemJnlLine(ItemJnlLine, PurchOrderHeader, PurchOrderLine, SalesHeader);
    end;

    local procedure ReleaseSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesHeaderCopy: Record "Sales Header";
        TempAsmHeader: Record "Assembly Header" temporary;
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        LinesWereModified: Boolean;
        SavedStatus: Option;
    begin
        with SalesHeader do begin
            if not (Status = Status::Open) or (Status = Status::"Pending Prepayment") then
                exit;

            SalesHeaderCopy := SalesHeader;
            SavedStatus := Status;
            GetOpenLinkedATOs(TempAsmHeader);
            OnBeforeReleaseSalesDoc(SalesHeader);
            LinesWereModified := ReleaseSalesDocument.ReleaseSalesHeader(SalesHeader, PreviewMode);
            if LinesWereModified then
                RefreshTempLines(SalesHeader, TempSalesLineGlobal);
            TestField(Status, Status::Released);
            Status := SavedStatus;
            RestoreSalesHeader(SalesHeader, SalesHeaderCopy);
            ReopenAsmOrders(TempAsmHeader);
            OnAfterReleaseSalesDoc(SalesHeader);
            if not (PreviewMode or SuppressCommit) then begin
                Modify;
                Commit;
            end;
            Status := Status::Released;
        end;
    end;

    local procedure TestSalesLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesLine(SalesHeader, SalesLine, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        with SalesLine do begin
            case Type of
                Type::Item:
                    DummyTrackingSpecification.CheckItemTrackingQuantity(
                      DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.",
                      "Qty. to Ship (Base)", "Qty. to Invoice (Base)", SalesHeader.Ship, SalesHeader.Invoice);
                Type::"Charge (Item)":
                    TestSalesLineItemCharge(SalesLine);
                Type::"Fixed Asset":
                    TestSalesLineFixedAsset(SalesLine)
                else
                    TestSalesLineOthers(SalesLine);
            end;
            TestSalesLineJob(SalesLine);

            if Type = Type::Item then
                DummyTrackingSpecification.CheckItemTrackingQuantity(
                  DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.",
                  "Qty. to Ship (Base)", "Qty. to Invoice (Base)", SalesHeader.Ship, SalesHeader.Invoice);

            case "Document Type" of
                "Document Type"::Order:
                    TestField("Return Qty. to Receive", 0);
                "Document Type"::Invoice:
                    begin
                        if "Shipment No." = '' then
                            TestField("Qty. to Ship", Quantity);
                        TestField("Return Qty. to Receive", 0);
                        TestField("Qty. to Invoice", Quantity);
                    end;
                "Document Type"::"Return Order":
                    TestField("Qty. to Ship", 0);
                "Document Type"::"Credit Memo":
                    begin
                        if "Return Receipt No." = '' then
                            TestField("Return Qty. to Receive", Quantity);
                        TestField("Qty. to Ship", 0);
                        TestField("Qty. to Invoice", Quantity);
                    end;
            end;

            OnAfterTestSalesLine(SalesHeader, SalesLine, WhseShip, WhseReceive, SuppressCommit);
        end;
    end;

    local procedure TestSalesLineItemCharge(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesLineItemCharge(SalesLine, IsHandled);
        if IsHandled then
            exit;

        with SalesLine do begin
            TestField(Amount);
            TestField("Job No.", '');
            TestField("Job Contract Entry No.", 0);
        end;
    end;

    local procedure TestSalesLineFixedAsset(SalesLine: Record "Sales Line")
    var
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesLineFixedAsset(SalesLine, IsHandled);
        if IsHandled then
            exit;

        with SalesLine do begin
            TestField("Job No.", '');
            TestField("Depreciation Book Code");
            DeprBook.Get("Depreciation Book Code");
            DeprBook.TestField("G/L Integration - Disposal", true);
            FixedAsset.Get("No.");
            FixedAsset.TestField("Budgeted Asset", false);
        end;
    end;

    local procedure TestSalesLineJob(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesLineJob(SalesLine, IsHandled);
        if IsHandled then
            exit;

        with SalesLine do
            if not ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) then
                TestField("Job No.", '');
    end;

    local procedure TestSalesLineOthers(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesLineOthers(SalesLine, IsHandled);
        if IsHandled then
            exit;

        with SalesLine do begin
            TestField("Depreciation Book Code", '');
            TestField("Depr. until FA Posting Date", false);
            TestField("FA Posting Date", 0D);
            TestField("Duplicate in Depreciation Book", '');
            TestField("Use Duplication List", false);
        end;
    end;

    local procedure TestUpdatedSalesLine(SalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            if "Drop Shipment" then begin
                if Type <> Type::Item then
                    TestField("Drop Shipment", false);
                if ("Qty. to Ship" <> 0) and ("Purch. Order Line No." = 0) then
                    Error(DropShipmentErr, "Line No.");
            end;

            if Quantity = 0 then
                TestField(Amount, 0)
            else begin
                TestField("No.");
                TestField(Type);
                if not ApplicationAreaMgmt.IsSalesTaxEnabled then begin
                    TestField("Gen. Bus. Posting Group");
                    TestField("Gen. Prod. Posting Group");
                end;
            end;
        end;
    end;

    local procedure UpdatePostingNos(var SalesHeader: Record "Sales Header") ModifyHeader: Boolean
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        OnBeforeUpdatePostingNos(SalesHeader, NoSeriesMgt, SuppressCommit, ModifyHeader);
        with SalesHeader do begin
            IsHandled := false;
            OnBeforeUpdateShippingNo(SalesHeader, WhseShip, WhseReceive, InvtPickPutaway, PreviewMode, ModifyHeader, IsHandled);
            if not IsHandled then
                if Ship and ("Shipping No." = '') then
                    if ("Document Type" = "Document Type"::Order) or
                       (("Document Type" = "Document Type"::Invoice) and SalesSetup."Shipment on Invoice")
                    then
                        if not PreviewMode then begin
                            TestField("Shipping No. Series");
                            "Shipping No." := NoSeriesMgt.GetNextNo("Shipping No. Series", "Posting Date", true);
                            ModifyHeader := true;
                        end else
                            "Shipping No." := PostingPreviewNoTok;

            if Receive and ("Return Receipt No." = '') then
                if ("Document Type" = "Document Type"::"Return Order") or
                   (("Document Type" = "Document Type"::"Credit Memo") and SalesSetup."Return Receipt on Credit Memo")
                then
                    if not PreviewMode then begin
                        TestField("Return Receipt No. Series");
                        "Return Receipt No." := NoSeriesMgt.GetNextNo("Return Receipt No. Series", "Posting Date", true);
                        ModifyHeader := true;
                    end else
                        "Return Receipt No." := PostingPreviewNoTok;

            IsHandled := false;
            OnBeforeUpdatePostingNo(SalesHeader, PreviewMode, ModifyHeader, IsHandled);
            if not IsHandled then
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

        OnAfterUpdatePostingNos(SalesHeader, NoSeriesMgt, SuppressCommit);
    end;

    local procedure UpdateAssocOrder(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
    begin
        TempDropShptPostBuffer.Reset;
        if TempDropShptPostBuffer.IsEmpty then
            exit;
        Clear(PurchOrderHeader);
        TempDropShptPostBuffer.FindSet;
        repeat
            if PurchOrderHeader."No." <> TempDropShptPostBuffer."Order No." then begin
                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, TempDropShptPostBuffer."Order No.");
                PurchOrderHeader."Last Receiving No." := PurchOrderHeader."Receiving No.";
                PurchOrderHeader."Receiving No." := '';
                PurchOrderHeader.Modify;
                ReservePurchLine.UpdateItemTrackingAfterPosting(PurchOrderHeader);
            end;
            PurchOrderLine.Get(
              PurchOrderLine."Document Type"::Order,
              TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
            PurchOrderLine."Quantity Received" := PurchOrderLine."Quantity Received" + TempDropShptPostBuffer.Quantity;
            PurchOrderLine."Qty. Received (Base)" := PurchOrderLine."Qty. Received (Base)" + TempDropShptPostBuffer."Quantity (Base)";
            PurchOrderLine.InitOutstanding;
            PurchOrderLine.ClearQtyIfBlank;
            PurchOrderLine.InitQtyToReceive;
            OnUpdateAssocOrderOnBeforeModifyPurchLine(PurchOrderLine, TempDropShptPostBuffer);
            PurchOrderLine.Modify;
            OnUpdateAssocOrderOnAfterModifyPurchLine(PurchOrderLine, TempDropShptPostBuffer);
        until TempDropShptPostBuffer.Next = 0;
        TempDropShptPostBuffer.DeleteAll;
    end;

    local procedure UpdateAssocLines(var SalesOrderLine: Record "Sales Line")
    var
        PurchOrderLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAssocLines(SalesOrderLine, IsHandled);
        if IsHandled then
            exit;

        PurchOrderLine.Get(
          PurchOrderLine."Document Type"::Order,
          SalesOrderLine."Purchase Order No.", SalesOrderLine."Purch. Order Line No.");
        PurchOrderLine."Sales Order No." := '';
        PurchOrderLine."Sales Order Line No." := 0;
        PurchOrderLine.Modify;
        SalesOrderLine."Purchase Order No." := '';
        SalesOrderLine."Purch. Order Line No." := 0;
    end;

    local procedure UpdateAssosOrderPostingNos(SalesHeader: Record "Sales Header") DropShipment: Boolean
    var
        TempSalesLine: Record "Sales Line" temporary;
        PurchOrderHeader: Record "Purchase Header";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        with SalesHeader do begin
            ResetTempLines(TempSalesLine);
            TempSalesLine.SetFilter("Purch. Order Line No.", '<>0');
            DropShipment := not TempSalesLine.IsEmpty;

            TempSalesLine.SetFilter("Qty. to Ship", '<>0');
            if DropShipment and Ship then
                if TempSalesLine.FindSet then
                    repeat
                        if PurchOrderHeader."No." <> TempSalesLine."Purchase Order No." then begin
                            PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, TempSalesLine."Purchase Order No.");
                            PurchOrderHeader.TestField("Pay-to Vendor No.");
                            PurchOrderHeader.Receive := true;
                            ReleasePurchaseDocument.ReleasePurchaseHeader(PurchOrderHeader, PreviewMode);
                            if PurchOrderHeader."Receiving No." = '' then begin
                                PurchOrderHeader.TestField("Receiving No. Series");
                                PurchOrderHeader."Receiving No." :=
                                  NoSeriesMgt.GetNextNo(PurchOrderHeader."Receiving No. Series", "Posting Date", true);
                                PurchOrderHeader.Modify;
                            end;
                        end;
                    until TempSalesLine.Next = 0;

            exit(DropShipment);
        end;
    end;

    local procedure UpdateAfterPosting(SalesHeader: Record "Sales Header")
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        with TempSalesLine do begin
            ResetTempLines(TempSalesLine);
            SetFilter("Qty. to Assemble to Order", '<>0');
            if FindSet then
                repeat
                    FinalizePostATO(TempSalesLine);
                until Next = 0;

            ResetTempLines(TempSalesLine);
            SetFilter("Blanket Order Line No.", '<>0');
            if FindSet then
                repeat
                    UpdateBlanketOrderLine(TempSalesLine, SalesHeader.Ship, SalesHeader.Receive, SalesHeader.Invoice);
                until Next = 0;
        end;

        OnAfterUpdateAfterPosting(SalesHeader, TempSalesLine);
    end;

    local procedure UpdateLastPostingNos(var SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            if Ship then begin
                "Last Shipping No." := "Shipping No.";
                "Shipping No." := '';
            end;
            if Invoice then begin
                "Last Posting No." := "Posting No.";
                "Posting No." := '';
            end;
            if Receive then begin
                "Last Return Receipt No." := "Return Receipt No.";
                "Return Receipt No." := '';
            end;
        end;
    end;

    local procedure UpdateSalesLineBeforePost(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        OnBeforeUpdateSalesLineBeforePost(SalesLine, SalesHeader, WhseShip, WhseReceive, RoundingLineInserted, SuppressCommit);

        with SalesLine do begin
            if not (SalesHeader.Ship or RoundingLineInserted) then begin
                "Qty. to Ship" := 0;
                "Qty. to Ship (Base)" := 0;
            end;
            if not (SalesHeader.Receive or RoundingLineInserted) then begin
                "Return Qty. to Receive" := 0;
                "Return Qty. to Receive (Base)" := 0;
            end;

            JobContractLine := false;
            if (Type = Type::Item) or (Type = Type::"G/L Account") or (Type = Type::" ") then
                if "Job Contract Entry No." > 0 then
                    PostJobContractLine(SalesHeader, SalesLine);
            if Type = Type::Resource then
                JobTaskSalesLine := SalesLine;

            if (SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice) and ("Shipment No." <> '') then begin
                "Quantity Shipped" := Quantity;
                "Qty. Shipped (Base)" := "Quantity (Base)";
                "Qty. to Ship" := 0;
                "Qty. to Ship (Base)" := 0;
            end;

            if (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo") and ("Return Receipt No." <> '') then begin
                "Return Qty. Received" := Quantity;
                "Return Qty. Received (Base)" := "Quantity (Base)";
                "Return Qty. to Receive" := 0;
                "Return Qty. to Receive (Base)" := 0;
            end;

            if SalesHeader.Invoice then begin
                if Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice) then
                    InitQtyToInvoice;
            end else begin
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;

            if (Type = Type::Item) and ("No." <> '') then begin
                GetItem(Item);
                if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment then
                    GetUnitCost;
            end;
        end;

        OnAfterUpdateSalesLineBeforePost(SalesLine, SalesHeader, WhseShip, WhseReceive, SuppressCommit);
    end;

    local procedure UpdateWhseDocuments(SalesHeader: Record "Sales Header")
    begin
        if WhseReceive then begin
            WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
            TempWhseRcptHeader.Delete;
        end;
        if WhseShip then begin
            WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
            TempWhseShptHeader.Delete;
        end;

        OnAfterUpdateWhseDocuments(SalesHeader, WhseShip, WhseReceive, WhseShptHeader, WhseRcptHeader);
    end;

    local procedure DeleteAfterPosting(var SalesHeader: Record "Sales Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        WarehouseRequest: Record "Warehouse Request";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        SkipDelete: Boolean;
    begin
        OnBeforeDeleteAfterPosting(SalesHeader, SalesInvHeader, SalesCrMemoHeader, SkipDelete, SuppressCommit);
        if SkipDelete then
            exit;

        with SalesHeader do begin
            if HasLinks then
                DeleteLinks;
            Delete;
            ReserveSalesLine.DeleteInvoiceSpecFromHeader(SalesHeader);
            DeleteATOLinks(SalesHeader);
            ResetTempLines(TempSalesLine);
            if TempSalesLine.FindFirst then
                repeat
                    if TempSalesLine."Deferral Code" <> '' then
                        DeferralUtilities.RemoveOrSetDeferralSchedule(
                          '', DeferralUtilities.GetSalesDeferralDocType, '', '', TempSalesLine."Document Type",
                          TempSalesLine."Document No.", TempSalesLine."Line No.", 0, 0D, TempSalesLine.Description, '', true);
                    if TempSalesLine.HasLinks then
                        TempSalesLine.DeleteLinks;
                until TempSalesLine.Next = 0;

            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            OnBeforeSalesLineDeleteAll(SalesLine, SuppressCommit);
            SalesLine.DeleteAll;
            if EnvInfoProxy.IsInvoicing and CustInvoiceDisc.Get("Invoice Disc. Code") then
                CustInvoiceDisc.Delete; // Cleanup of autogenerated cust. invoice discounts

            DeleteItemChargeAssgnt(SalesHeader);
            SalesCommentLine.DeleteComments("Document Type", "No.");
            WarehouseRequest.DeleteRequest(DATABASE::"Sales Line", "Document Type", "No.");
        end;

        OnAfterDeleteAfterPosting(SalesHeader, SalesInvHeader, SalesCrMemoHeader, SuppressCommit);
    end;

    local procedure FinalizePosting(var SalesHeader: Record "Sales Header"; EverythingInvoiced: Boolean; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        TempSalesLine: Record "Sales Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        WhseSalesRelease: Codeunit "Whse.-Sales Release";
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        OnBeforeFinalizePosting(SalesHeader, TempSalesLineGlobal, EverythingInvoiced, SuppressCommit, GenJnlPostLine);

        with SalesHeader do begin
            if ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"]) and
               (not EverythingInvoiced)
            then begin
                Modify;
                InsertTrackingSpecification(SalesHeader);
                PostUpdateOrderLine(SalesHeader);
                UpdateAssocOrder(TempDropShptPostBuffer);
                UpdateWhseDocuments(SalesHeader);
                WhseSalesRelease.Release(SalesHeader);
                UpdateItemChargeAssgnt;
            end else begin
                case "Document Type" of
                    "Document Type"::Invoice:
                        begin
                            PostUpdateInvoiceLine;
                            InsertTrackingSpecification(SalesHeader);
                        end;
                    "Document Type"::"Credit Memo":
                        begin
                            PostUpdateReturnReceiptLine;
                            InsertTrackingSpecification(SalesHeader);
                        end;
                    else begin
                            UpdateAssocOrder(TempDropShptPostBuffer);
                            if DropShipOrder then
                                InsertTrackingSpecification(SalesHeader);

                            ResetTempLines(TempSalesLine);
                            TempSalesLine.SetFilter("Purch. Order Line No.", '<>0');
                            if TempSalesLine.FindSet then
                                repeat
                                    UpdateAssocLines(TempSalesLine);
                                    TempSalesLine.Modify;
                                until TempSalesLine.Next = 0;

                            ResetTempLines(TempSalesLine);
                            TempSalesLine.SetFilter("Prepayment %", '<>0');
                            if TempSalesLine.FindSet then
                                repeat
                                    DecrementPrepmtAmtInvLCY(
                                      TempSalesLine, TempSalesLine."Prepmt. Amount Inv. (LCY)", TempSalesLine."Prepmt. VAT Amount Inv. (LCY)");
                                    TempSalesLine.Modify;
                                until TempSalesLine.Next = 0;
                        end;
                end;
                UpdateAfterPosting(SalesHeader);
                UpdateEmailParameters(SalesHeader);
                UpdateWhseDocuments(SalesHeader);
                ArchiveManagement.AutoArchiveSalesDocument(SalesHeader);
                ApprovalsMgmt.DeleteApprovalEntries(RecordId);
                if not PreviewMode then
                    DeleteAfterPosting(SalesHeader);
            end;

            InsertValueEntryRelation;

            OnAfterFinalizePostingOnBeforeCommit(
              SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, GenJnlPostLine, SuppressCommit, PreviewMode);

            if PreviewMode then begin
                if not HideProgressWindow then
                    Window.Close;
                GenJnlPostPreview.ThrowError;
            end;
            if not (InvtPickPutaway or SuppressCommit) then
                Commit;

            if not HideProgressWindow then
                Window.Close;

            IsHandled := false;
            OnFinalizePostingOnBeforeCreateOutboxSalesTrans(SalesHeader, IsHandled);
            if not IsHandled then
                if Invoice and ("Bill-to IC Partner Code" <> '') then
                    if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                        ICInboxOutboxMgt.CreateOutboxSalesInvTrans(SalesInvHeader)
                    else
                        ICInboxOutboxMgt.CreateOutboxSalesCrMemoTrans(SalesCrMemoHeader);

            OnAfterFinalizePosting(
              SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader,
              GenJnlPostLine, SuppressCommit, PreviewMode);

            ClearPostBuffers;
        end;
    end;

    local procedure FillInvoicePostingBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer")
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
        SalesAccount: Code[20];
    begin
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        InvoicePostBuffer.PrepareSales(SalesLine);

        TotalVAT := SalesLine."Amount Including VAT" - SalesLine.Amount;
        TotalVATACY := SalesLineACY."Amount Including VAT" - SalesLineACY.Amount;
        TotalAmount := SalesLine.Amount;
        TotalAmountACY := SalesLineACY.Amount;
        TotalVATBase := SalesLine."VAT Base Amount";
        TotalVATBaseACY := SalesLineACY."VAT Base Amount";

        OnAfterInvoicePostingBufferAssignAmounts(SalesLine, TotalAmount, TotalAmountACY);

        if SalesLine."Deferral Code" <> '' then
            GetAmountsForDeferral(SalesLine, AmtToDefer, AmtToDeferACY, DeferralAccount)
        else begin
            AmtToDefer := 0;
            AmtToDeferACY := 0;
            DeferralAccount := '';
        end;

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            CalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostBuffer);
            if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                InvoicePostBuffer.SetAccount(
                  GenPostingSetup.GetSalesInvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, true);
            end;
        end;

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            CalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostBuffer);
            if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                InvoicePostBuffer.SetAccount(
                  GenPostingSetup.GetSalesLineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, true);
            end;
        end;

        OnFillInvoicePostingBufferOnBeforeDeferrals(SalesLine, TotalAmount, TotalAmountACY, UseDate);
        DeferralUtilities.AdjustTotalAmountForDeferralsNoBase(
          SalesLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY);

        OnBeforeInvoicePostingBufferSetAmounts(
          SalesLine, TempInvoicePostBuffer, InvoicePostBuffer,
          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);

        InvoicePostBuffer.SetAmounts(
          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, SalesLine."VAT Difference", TotalVATBase, TotalVATBaseACY);

        OnAfterInvoicePostingBufferSetAmounts(InvoicePostBuffer, SalesLine);

        if (SalesLine.Type = SalesLine.Type::"G/L Account") or (SalesLine.Type = SalesLine.Type::"Fixed Asset") then
            SalesAccount := SalesLine."No."
        else
            if SalesLine.IsCreditDocType then
                SalesAccount := GenPostingSetup.GetSalesCrMemoAccount
            else
                SalesAccount := GenPostingSetup.GetSalesAccount;

        InvoicePostBuffer.SetAccount(SalesAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
        InvoicePostBuffer."Deferral Code" := SalesLine."Deferral Code";
        OnAfterFillInvoicePostBuffer(InvoicePostBuffer, SalesLine, TempInvoicePostBuffer, SuppressCommit);
        UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, false);

        OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer(SalesHeader, SalesLine, InvoicePostBuffer, TempInvoicePostBuffer);

        if SalesLine."Deferral Code" <> '' then begin
            OnBeforeFillDeferralPostingBuffer(
              SalesLine, InvoicePostBuffer, TempInvoicePostBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit);
            FillDeferralPostingBuffer(SalesHeader, SalesLine, InvoicePostBuffer, AmtToDefer, AmtToDeferACY, DeferralAccount, SalesAccount);
            OnAfterFillDeferralPostingBuffer(
              SalesLine, InvoicePostBuffer, TempInvoicePostBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit);
        end;
    end;

    local procedure UpdateInvoicePostBuffer(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; InvoicePostBuffer: Record "Invoice Post. Buffer"; ForceGLAccountType: Boolean)
    var
        RestoreFAType: Boolean;
    begin
        if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostBuffer."Fixed Asset Line No." := FALineNo;
            if ForceGLAccountType then begin
                RestoreFAType := true;
                InvoicePostBuffer.Type := InvoicePostBuffer.Type::"G/L Account";
            end;
        end;

        TempInvoicePostBuffer.Update(InvoicePostBuffer, InvDefLineNo, DeferralLineNo);

        if RestoreFAType then
            TempInvoicePostBuffer.Type := TempInvoicePostBuffer.Type::"Fixed Asset";
    end;

    local procedure InsertPrepmtAdjInvPostingBuf(SalesHeader: Record "Sales Header"; PrepmtSalesLine: Record "Sales Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        AdjAmount: Decimal;
    begin
        with PrepmtSalesLine do
            if "Prepayment Line" then
                if "Prepmt. Amount Inv. (LCY)" <> 0 then begin
                    AdjAmount := -"Prepmt. Amount Inv. (LCY)";
                    InvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                      "No.", AdjAmount, SalesHeader."Currency Code" = '');
                    InvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                      SalesPostPrepayments.GetCorrBalAccNo(SalesHeader, AdjAmount > 0),
                      -AdjAmount, SalesHeader."Currency Code" = '');
                end else
                    if ("Prepayment %" = 100) and ("Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                        InvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                          SalesPostPrepayments.GetInvRoundingAccNo(SalesHeader."Customer Posting Group"),
                          "Prepmt. VAT Amount Inv. (LCY)", SalesHeader."Currency Code" = '');
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

    local procedure DivideAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; SalesLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    var
        OriginalDeferralAmount: Decimal;
    begin
        if RoundingLineInserted and (RoundingLineNo = SalesLine."Line No.") then
            exit;

        OnBeforeDivideAmount(SalesHeader, SalesLine, QtyType, SalesLineQty, TempVATAmountLine, TempVATAmountLineRemainder);

        with SalesLine do
            if (SalesLineQty = 0) or ("Unit Price" = 0) then begin
                "Line Amount" := 0;
                "Line Discount Amount" := 0;
                "Inv. Discount Amount" := 0;
                "VAT Base Amount" := 0;
                Amount := 0;
                "Amount Including VAT" := 0;
            end else begin
                OriginalDeferralAmount := GetDeferralAmount;
                TempVATAmountLine.Get("VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Line Amount" >= 0);
                if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
                    "VAT %" := TempVATAmountLine."VAT %";
                TempVATAmountLineRemainder := TempVATAmountLine;
                if not TempVATAmountLineRemainder.Find then begin
                    TempVATAmountLineRemainder.Init;
                    TempVATAmountLineRemainder.Insert;
                end;
                "Line Amount" := GetLineAmountToHandleInclPrepmt(SalesLineQty) + GetPrepmtDiffToLineAmount(SalesLine);
                if SalesLineQty <> Quantity then
                    "Line Discount Amount" :=
                      Round("Line Discount Amount" * SalesLineQty / Quantity, Currency."Amount Rounding Precision");

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

                if SalesHeader."Prices Including VAT" then begin
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
                        Amount * (1 - SalesHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
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
                            Amount * (1 - SalesHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
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
                    CalcDeferralAmounts(SalesHeader, SalesLine, OriginalDeferralAmount);
            end;

        OnAfterDivideAmount(SalesHeader, SalesLine, QtyType, SalesLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
    end;

    local procedure RoundAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineQty: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        NoVAT: Boolean;
    begin
        OnBeforeRoundAmount(SalesHeader, SalesLine, SalesLineQty);

        with SalesLine do begin
            IncrAmount(SalesHeader, SalesLine, TotalSalesLine);
            Increment(TotalSalesLine."Net Weight", Round(SalesLineQty * "Net Weight", UOMMgt.WeightRndPrecision));
            Increment(TotalSalesLine."Gross Weight", Round(SalesLineQty * "Gross Weight", UOMMgt.WeightRndPrecision));
            Increment(TotalSalesLine."Unit Volume", Round(SalesLineQty * "Unit Volume", UOMMgt.CubageRndPrecision));
            Increment(TotalSalesLine.Quantity, SalesLineQty);
            if "Units per Parcel" > 0 then
                Increment(
                  TotalSalesLine."Units per Parcel",
                  Round(SalesLineQty / "Units per Parcel", 1, '>'));

            xSalesLine := SalesLine;
            SalesLineACY := SalesLine;

            if SalesHeader."Currency Code" <> '' then begin
                if SalesHeader."Posting Date" = 0D then
                    UseDate := WorkDate
                else
                    UseDate := SalesHeader."Posting Date";

                NoVAT := Amount = "Amount Including VAT";
                "Amount Including VAT" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."Amount Including VAT", SalesHeader."Currency Factor")) -
                  TotalSalesLineLCY."Amount Including VAT";
                if NoVAT then
                    Amount := "Amount Including VAT"
                else
                    Amount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          UseDate, SalesHeader."Currency Code",
                          TotalSalesLine.Amount, SalesHeader."Currency Factor")) -
                      TotalSalesLineLCY.Amount;
                "Line Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."Line Amount", SalesHeader."Currency Factor")) -
                  TotalSalesLineLCY."Line Amount";
                "Line Discount Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."Line Discount Amount", SalesHeader."Currency Factor")) -
                  TotalSalesLineLCY."Line Discount Amount";
                "Inv. Discount Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."Inv. Discount Amount", SalesHeader."Currency Factor")) -
                  TotalSalesLineLCY."Inv. Discount Amount";
                "VAT Difference" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."VAT Difference", SalesHeader."Currency Factor")) -
                  TotalSalesLineLCY."VAT Difference";
                "VAT Base Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, SalesHeader."Currency Code",
                      TotalSalesLine."VAT Base Amount", SalesHeader."Currency Factor")) -
                  TotalSalesLineLCY."VAT Base Amount";
            end;

            OnRoundAmountOnBeforeIncrAmount(SalesHeader, SalesLine, SalesLineQty, TotalSalesLine, TotalSalesLineLCY);

            IncrAmount(SalesHeader, SalesLine, TotalSalesLineLCY);
            Increment(TotalSalesLineLCY."Unit Cost (LCY)", Round(SalesLineQty * "Unit Cost (LCY)"));
        end;

        OnAfterRoundAmount(SalesHeader, SalesLine, SalesLineQty);
    end;

    procedure ReverseAmount(var SalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            "Qty. to Ship" := -"Qty. to Ship";
            "Qty. to Ship (Base)" := -"Qty. to Ship (Base)";
            "Return Qty. to Receive" := -"Return Qty. to Receive";
            "Return Qty. to Receive (Base)" := -"Return Qty. to Receive (Base)";
            "Qty. to Invoice" := -"Qty. to Invoice";
            "Qty. to Invoice (Base)" := -"Qty. to Invoice (Base)";
            "Line Amount" := -"Line Amount";
            Amount := -Amount;
            "VAT Base Amount" := -"VAT Base Amount";
            "VAT Difference" := -"VAT Difference";
            "Amount Including VAT" := -"Amount Including VAT";
            "Line Discount Amount" := -"Line Discount Amount";
            "Inv. Discount Amount" := -"Inv. Discount Amount";
            OnAfterReverseAmount(SalesLine);
        end;
    end;

    local procedure InvoiceRounding(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; UseTempData: Boolean; BiggestLineNo: Integer)
    var
        CustPostingGr: Record "Customer Posting Group";
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalSalesLine."Amount Including VAT" -
            Round(
              TotalSalesLine."Amount Including VAT", Currency."Invoice Rounding Precision", Currency.InvoiceRoundingDirection),
            Currency."Amount Rounding Precision");

        OnBeforeInvoiceRoundingAmount(
          SalesHeader, TotalSalesLine."Amount Including VAT", UseTempData, InvoiceRoundingAmount, SuppressCommit, TotalSalesLine);
        if InvoiceRoundingAmount <> 0 then begin
            CustPostingGr.Get(SalesHeader."Customer Posting Group");
            with SalesLine do begin
                Init;
                BiggestLineNo := BiggestLineNo + 10000;
                "System-Created Entry" := true;
                if UseTempData then begin
                    "Line No." := 0;
                    Type := Type::"G/L Account";
                    SetHideValidationDialog(true);
                end else begin
                    "Line No." := BiggestLineNo;
                    Validate(Type, Type::"G/L Account");
                end;
                Validate("No.", CustPostingGr.GetInvRoundingAccount);
                Validate(Quantity, 1);
                if IsCreditDocType then
                    Validate("Return Qty. to Receive", Quantity)
                else
                    Validate("Qty. to Ship", Quantity);
                if SalesHeader."Prices Including VAT" then
                    Validate("Unit Price", InvoiceRoundingAmount)
                else
                    Validate(
                      "Unit Price",
                      Round(
                        InvoiceRoundingAmount /
                        (1 + (1 - SalesHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                        Currency."Amount Rounding Precision"));
                Validate("Amount Including VAT", InvoiceRoundingAmount);
                "Line No." := BiggestLineNo;
                LastLineRetrieved := false;
                RoundingLineInserted := true;
                RoundingLineNo := "Line No.";
            end;
        end;

        OnAfterInvoiceRoundingAmount(SalesHeader, SalesLine, TotalSalesLine, UseTempData, InvoiceRoundingAmount, SuppressCommit);
    end;

    local procedure IncrAmount(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TotalSalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            if SalesHeader."Prices Including VAT" or
               ("VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT")
            then
                Increment(TotalSalesLine."Line Amount", "Line Amount");
            Increment(TotalSalesLine.Amount, Amount);
            Increment(TotalSalesLine."VAT Base Amount", "VAT Base Amount");
            Increment(TotalSalesLine."VAT Difference", "VAT Difference");
            Increment(TotalSalesLine."Amount Including VAT", "Amount Including VAT");
            Increment(TotalSalesLine."Line Discount Amount", "Line Discount Amount");
            Increment(TotalSalesLine."Inv. Discount Amount", "Inv. Discount Amount");
            Increment(TotalSalesLine."Inv. Disc. Amount to Invoice", "Inv. Disc. Amount to Invoice");
            Increment(TotalSalesLine."Prepmt. Line Amount", "Prepmt. Line Amount");
            Increment(TotalSalesLine."Prepmt. Amt. Inv.", "Prepmt. Amt. Inv.");
            Increment(TotalSalesLine."Prepmt Amt to Deduct", "Prepmt Amt to Deduct");
            Increment(TotalSalesLine."Prepmt Amt Deducted", "Prepmt Amt Deducted");
            Increment(TotalSalesLine."Prepayment VAT Difference", "Prepayment VAT Difference");
            Increment(TotalSalesLine."Prepmt VAT Diff. to Deduct", "Prepmt VAT Diff. to Deduct");
            Increment(TotalSalesLine."Prepmt VAT Diff. Deducted", "Prepmt VAT Diff. Deducted");
            OnAfterIncrAmount(TotalSalesLine, SalesLine, SalesHeader);
        end;
    end;

    local procedure Increment(var Number: Decimal; Number2: Decimal)
    begin
        Number := Number + Number2;
    end;

    procedure GetSalesLines(var SalesHeader: Record "Sales Header"; var NewSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping)
    var
        TotalAdjCostLCY: Decimal;
    begin
        FillTempLines(SalesHeader, TempSalesLineGlobal);
        if QtyType = QtyType::Invoicing then
            CreatePrepaymentLines(SalesHeader, false);
        SumSalesLines2(SalesHeader, NewSalesLine, TempSalesLineGlobal, QtyType, true, false, TotalAdjCostLCY);
    end;

    procedure GetSalesLinesTemp(var SalesHeader: Record "Sales Header"; var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping)
    var
        TotalAdjCostLCY: Decimal;
    begin
        OldSalesLine.SetSalesHeader(SalesHeader);
        SumSalesLines2(SalesHeader, NewSalesLine, OldSalesLine, QtyType, true, false, TotalAdjCostLCY);
    end;

    procedure SumSalesLines(var NewSalesHeader: Record "Sales Header"; QtyType: Option General,Invoicing,Shipping; var NewTotalSalesLine: Record "Sales Line"; var NewTotalSalesLineLCY: Record "Sales Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        OldSalesLine: Record "Sales Line";
    begin
        SumSalesLinesTemp(
          NewSalesHeader, OldSalesLine, QtyType, NewTotalSalesLine, NewTotalSalesLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
    end;

    procedure SumSalesLinesTemp(var SalesHeader: Record "Sales Header"; var OldSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; var NewTotalSalesLine: Record "Sales Line"; var NewTotalSalesLineLCY: Record "Sales Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesHeader do begin
            SumSalesLines2(SalesHeader, SalesLine, OldSalesLine, QtyType, false, true, TotalAdjCostLCY);
            ProfitLCY := TotalSalesLineLCY.Amount - TotalSalesLineLCY."Unit Cost (LCY)";
            if TotalSalesLineLCY.Amount = 0 then
                ProfitPct := 0
            else
                ProfitPct := Round(ProfitLCY / TotalSalesLineLCY.Amount * 100, 0.1);
            VATAmount := TotalSalesLine."Amount Including VAT" - TotalSalesLine.Amount;
            if TotalSalesLine."VAT %" = 0 then
                VATAmountText := VATAmountTxt
            else
                VATAmountText := StrSubstNo(VATRateTxt, TotalSalesLine."VAT %");
            NewTotalSalesLine := TotalSalesLine;
            NewTotalSalesLineLCY := TotalSalesLineLCY;
        end;
    end;

    local procedure SumSalesLines2(SalesHeader: Record "Sales Header"; var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; InsertSalesLine: Boolean; CalcAdCostLCY: Boolean; var TotalAdjCostLCY: Decimal)
    var
        SalesLine: Record "Sales Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        SalesLineQty: Decimal;
        AdjCostLCY: Decimal;
        BiggestLineNo: Integer;
        IsHandled: Boolean;
    begin
        TotalAdjCostLCY := 0;
        TempVATAmountLineRemainder.DeleteAll;
        OldSalesLine.CalcVATAmountLines(QtyType, SalesHeader, OldSalesLine, TempVATAmountLine);
        with SalesHeader do begin
            GetGLSetup;
            SalesSetup.Get;
            GetCurrency("Currency Code");
            OldSalesLine.SetRange("Document Type", "Document Type");
            OldSalesLine.SetRange("Document No.", "No.");
            OnSumSalesLines2SetFilter(OldSalesLine, SalesHeader, InsertSalesLine);
            RoundingLineInserted := false;
            if OldSalesLine.FindSet then
                repeat
                    if not RoundingLineInserted then
                        SalesLine := OldSalesLine;
                    case QtyType of
                        QtyType::General:
                            SalesLineQty := SalesLine.Quantity;
                        QtyType::Invoicing:
                            SalesLineQty := SalesLine."Qty. to Invoice";
                        QtyType::Shipping:
                            begin
                                if IsCreditDocType then
                                    SalesLineQty := SalesLine."Return Qty. to Receive"
                                else
                                    SalesLineQty := SalesLine."Qty. to Ship";
                            end;
                    end;
                    IsHandled := false;
                    OnSumSalesLines2OnBeforeDivideAmount(OldSalesLine, IsHandled);
                    if not IsHandled then
                        DivideAmount(SalesHeader, SalesLine, QtyType, SalesLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
                    SalesLine.Quantity := SalesLineQty;
                    if SalesLineQty <> 0 then begin
                        if (SalesLine.Amount <> 0) and not RoundingLineInserted then
                            if TotalSalesLine.Amount = 0 then
                                TotalSalesLine."VAT %" := SalesLine."VAT %"
                            else
                                if TotalSalesLine."VAT %" <> SalesLine."VAT %" then
                                    TotalSalesLine."VAT %" := 0;
                        RoundAmount(SalesHeader, SalesLine, SalesLineQty);

                        if (QtyType in [QtyType::General, QtyType::Invoicing]) and
                           not InsertSalesLine and CalcAdCostLCY
                        then begin
                            AdjCostLCY := CostCalcMgt.CalcSalesLineCostLCY(SalesLine, QtyType);
                            TotalAdjCostLCY := TotalAdjCostLCY + GetSalesLineAdjCostLCY(SalesLine, QtyType, AdjCostLCY);
                        end;

                        SalesLine := xSalesLine;
                    end;
                    if InsertSalesLine then begin
                        NewSalesLine := SalesLine;
                        NewSalesLine.Insert;
                    end;
                    if RoundingLineInserted then
                        LastLineRetrieved := true
                    else begin
                        BiggestLineNo := MAX(BiggestLineNo, OldSalesLine."Line No.");
                        LastLineRetrieved := OldSalesLine.Next = 0;
                        if LastLineRetrieved and SalesSetup."Invoice Rounding" then
                            InvoiceRounding(SalesHeader, SalesLine, true, BiggestLineNo);
                    end;
                until LastLineRetrieved;
        end;
    end;

    local procedure GetSalesLineAdjCostLCY(SalesLine2: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; AdjCostLCY: Decimal): Decimal
    begin
        with SalesLine2 do begin
            if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                AdjCostLCY := -AdjCostLCY;

            case true of
                "Shipment No." <> '', "Return Receipt No." <> '':
                    exit(AdjCostLCY);
                QtyType = QtyType::General:
                    exit(Round("Outstanding Quantity" * "Unit Cost (LCY)") + AdjCostLCY);
                "Document Type" in ["Document Type"::Order, "Document Type"::Invoice]:
                    begin
                        if "Qty. to Invoice" > "Qty. to Ship" then
                            exit(Round("Qty. to Ship" * "Unit Cost (LCY)") + AdjCostLCY);
                        exit(Round("Qty. to Invoice" * "Unit Cost (LCY)"));
                    end;
                IsCreditDocType:
                    begin
                        if "Qty. to Invoice" > "Return Qty. to Receive" then
                            exit(Round("Return Qty. to Receive" * "Unit Cost (LCY)") + AdjCostLCY);
                        exit(Round("Qty. to Invoice" * "Unit Cost (LCY)"));
                    end;
            end;
        end;
    end;

    procedure UpdateBlanketOrderLine(SalesLine: Record "Sales Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    var
        BlanketOrderSalesLine: Record "Sales Line";
        xBlanketOrderSalesLine: Record "Sales Line";
        ModifyLine: Boolean;
        Sign: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBlanketOrderLine(SalesLine, Ship, Receive, Invoice, IsHandled);
        if IsHandled then
            exit;

        if (SalesLine."Blanket Order No." <> '') and (SalesLine."Blanket Order Line No." <> 0) and
           ((Ship and (SalesLine."Qty. to Ship" <> 0)) or
            (Receive and (SalesLine."Return Qty. to Receive" <> 0)) or
            (Invoice and (SalesLine."Qty. to Invoice" <> 0)))
        then
            if BlanketOrderSalesLine.Get(
                 BlanketOrderSalesLine."Document Type"::"Blanket Order", SalesLine."Blanket Order No.",
                 SalesLine."Blanket Order Line No.")
            then begin
                BlanketOrderSalesLine.TestField(Type, SalesLine.Type);
                BlanketOrderSalesLine.TestField("No.", SalesLine."No.");
                BlanketOrderSalesLine.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");

                ModifyLine := false;
                case SalesLine."Document Type" of
                    SalesLine."Document Type"::Order,
                  SalesLine."Document Type"::Invoice:
                        Sign := 1;
                    SalesLine."Document Type"::"Return Order",
                  SalesLine."Document Type"::"Credit Memo":
                        Sign := -1;
                end;
                if Ship and (SalesLine."Shipment No." = '') then begin
                    xBlanketOrderSalesLine := BlanketOrderSalesLine;

                    if BlanketOrderSalesLine."Qty. per Unit of Measure" = SalesLine."Qty. per Unit of Measure" then
                        BlanketOrderSalesLine."Quantity Shipped" += Sign * SalesLine."Qty. to Ship"
                    else
                        BlanketOrderSalesLine."Quantity Shipped" +=
                          Sign *
                          Round(
                            (SalesLine."Qty. per Unit of Measure" /
                             BlanketOrderSalesLine."Qty. per Unit of Measure") * SalesLine."Qty. to Ship",
                            UOMMgt.QtyRndPrecision);
                    BlanketOrderSalesLine."Qty. Shipped (Base)" += Sign * SalesLine."Qty. to Ship (Base)";
                    ModifyLine := true;

                    AsmPost.UpdateBlanketATO(xBlanketOrderSalesLine, BlanketOrderSalesLine);
                end;
                if Receive and (SalesLine."Return Receipt No." = '') then begin
                    if BlanketOrderSalesLine."Qty. per Unit of Measure" =
                       SalesLine."Qty. per Unit of Measure"
                    then
                        BlanketOrderSalesLine."Quantity Shipped" += Sign * SalesLine."Return Qty. to Receive"
                    else
                        BlanketOrderSalesLine."Quantity Shipped" +=
                          Sign *
                          Round(
                            (SalesLine."Qty. per Unit of Measure" /
                             BlanketOrderSalesLine."Qty. per Unit of Measure") * SalesLine."Return Qty. to Receive",
                            UOMMgt.QtyRndPrecision);
                    BlanketOrderSalesLine."Qty. Shipped (Base)" += Sign * SalesLine."Return Qty. to Receive (Base)";
                    ModifyLine := true;
                end;
                if Invoice then begin
                    if BlanketOrderSalesLine."Qty. per Unit of Measure" =
                       SalesLine."Qty. per Unit of Measure"
                    then
                        BlanketOrderSalesLine."Quantity Invoiced" += Sign * SalesLine."Qty. to Invoice"
                    else
                        BlanketOrderSalesLine."Quantity Invoiced" +=
                          Sign *
                          Round(
                            (SalesLine."Qty. per Unit of Measure" /
                             BlanketOrderSalesLine."Qty. per Unit of Measure") * SalesLine."Qty. to Invoice",
                            UOMMgt.QtyRndPrecision);
                    BlanketOrderSalesLine."Qty. Invoiced (Base)" += Sign * SalesLine."Qty. to Invoice (Base)";
                    ModifyLine := true;
                end;

                if ModifyLine then begin
                    OnUpdateBlanketOrderLineOnBeforeInitOutstanding(BlanketOrderSalesLine, SalesLine);
                    BlanketOrderSalesLine.InitOutstanding;

                    IsHandled := false;
                    OnUpdateBlanketOrderLineOnBeforeCheck(BlanketOrderSalesLine, SalesLine, IsHandled);
                    if not IsHandled then begin
                        if (BlanketOrderSalesLine.Quantity * BlanketOrderSalesLine."Quantity Shipped" < 0) or
                           (Abs(BlanketOrderSalesLine.Quantity) < Abs(BlanketOrderSalesLine."Quantity Shipped"))
                        then
                            BlanketOrderSalesLine.FieldError(
                              "Quantity Shipped", StrSubstNo(BlanketOrderQuantityGreaterThanErr, BlanketOrderSalesLine.FieldCaption(Quantity)));
                        if (BlanketOrderSalesLine."Quantity (Base)" * BlanketOrderSalesLine."Qty. Shipped (Base)" < 0) or
                           (Abs(BlanketOrderSalesLine."Quantity (Base)") < Abs(BlanketOrderSalesLine."Qty. Shipped (Base)"))
                        then
                            BlanketOrderSalesLine.FieldError(
                              "Qty. Shipped (Base)",
                              StrSubstNo(BlanketOrderQuantityGreaterThanErr, BlanketOrderSalesLine.FieldCaption("Quantity (Base)")));
                        BlanketOrderSalesLine.CalcFields("Reserved Qty. (Base)");
                        if Abs(BlanketOrderSalesLine."Outstanding Qty. (Base)") < Abs(BlanketOrderSalesLine."Reserved Qty. (Base)") then
                            BlanketOrderSalesLine.FieldError(
                              "Reserved Qty. (Base)", BlanketOrderQuantityReducedErr);
                    end;

                    BlanketOrderSalesLine."Qty. to Invoice" :=
                      BlanketOrderSalesLine.Quantity - BlanketOrderSalesLine."Quantity Invoiced";
                    BlanketOrderSalesLine."Qty. to Ship" :=
                      BlanketOrderSalesLine.Quantity - BlanketOrderSalesLine."Quantity Shipped";
                    BlanketOrderSalesLine."Qty. to Invoice (Base)" :=
                      BlanketOrderSalesLine."Quantity (Base)" - BlanketOrderSalesLine."Qty. Invoiced (Base)";
                    BlanketOrderSalesLine."Qty. to Ship (Base)" :=
                      BlanketOrderSalesLine."Quantity (Base)" - BlanketOrderSalesLine."Qty. Shipped (Base)";

                    OnBeforeBlanketOrderSalesLineModify(BlanketOrderSalesLine, SalesLine);
                    BlanketOrderSalesLine.Modify;
                    OnAfterUpdateBlanketOrderLine(BlanketOrderSalesLine, SalesLine, Ship, Receive, Invoice);
                end;
            end;
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"): Integer
    begin
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure DeleteItemChargeAssgnt(SalesHeader: Record "Sales Header")
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.SetRange("Document Type", SalesHeader."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesHeader."No.");
        if not ItemChargeAssgntSales.IsEmpty then
            ItemChargeAssgntSales.DeleteAll;
    end;

    local procedure UpdateItemChargeAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        with TempItemChargeAssgntSales do begin
            ClearItemChargeAssgntFilter;
            MarkedOnly(true);
            if FindSet then
                repeat
                    ItemChargeAssgntSales.Get("Document Type", "Document No.", "Document Line No.", "Line No.");
                    ItemChargeAssgntSales."Qty. Assigned" :=
                      ItemChargeAssgntSales."Qty. Assigned" + "Qty. to Assign";
                    ItemChargeAssgntSales."Qty. to Assign" := 0;
                    ItemChargeAssgntSales."Amount to Assign" := 0;
                    ItemChargeAssgntSales.Modify;
                until Next = 0;
        end;
    end;

    local procedure UpdateSalesOrderChargeAssgnt(SalesOrderInvLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line")
    var
        SalesOrderLine2: Record "Sales Line";
        SalesOrderInvLine2: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        with SalesOrderInvLine do begin
            ClearItemChargeAssgntFilter;
            TempItemChargeAssgntSales.SetRange("Document Type", "Document Type");
            TempItemChargeAssgntSales.SetRange("Document No.", "Document No.");
            TempItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
            TempItemChargeAssgntSales.MarkedOnly(true);
            if TempItemChargeAssgntSales.FindSet then
                repeat
                    if TempItemChargeAssgntSales."Applies-to Doc. Type" = "Document Type" then begin
                        SalesOrderInvLine2.Get(
                          TempItemChargeAssgntSales."Applies-to Doc. Type",
                          TempItemChargeAssgntSales."Applies-to Doc. No.",
                          TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                        if SalesOrderLine."Document Type" = SalesOrderLine."Document Type"::Order then begin
                            if not
                               SalesShptLine.Get(SalesOrderInvLine2."Shipment No.", SalesOrderInvLine2."Shipment Line No.")
                            then
                                Error(ShipmentLinesDeletedErr);
                            SalesOrderLine2.Get(
                              SalesOrderLine2."Document Type"::Order,
                              SalesShptLine."Order No.", SalesShptLine."Order Line No.");
                        end else begin
                            if not
                               ReturnRcptLine.Get(SalesOrderInvLine2."Return Receipt No.", SalesOrderInvLine2."Return Receipt Line No.")
                            then
                                Error(ReturnReceiptLinesDeletedErr);
                            SalesOrderLine2.Get(
                              SalesOrderLine2."Document Type"::"Return Order",
                              ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.");
                        end;
                        UpdateSalesChargeAssgntLines(
                          SalesOrderLine,
                          SalesOrderLine2."Document Type",
                          SalesOrderLine2."Document No.",
                          SalesOrderLine2."Line No.",
                          TempItemChargeAssgntSales."Qty. to Assign");
                    end else
                        UpdateSalesChargeAssgntLines(
                          SalesOrderLine,
                          TempItemChargeAssgntSales."Applies-to Doc. Type",
                          TempItemChargeAssgntSales."Applies-to Doc. No.",
                          TempItemChargeAssgntSales."Applies-to Doc. Line No.",
                          TempItemChargeAssgntSales."Qty. to Assign");
                until TempItemChargeAssgntSales.Next = 0;
        end;
    end;

    local procedure UpdateSalesChargeAssgntLines(SalesOrderLine: Record "Sales Line"; ApplToDocType: Option; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; QtyToAssign: Decimal)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        LastLineNo: Integer;
        TotalToAssign: Decimal;
    begin
        ItemChargeAssgntSales.SetRange("Document Type", SalesOrderLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesOrderLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
        ItemChargeAssgntSales.SetRange("Applies-to Doc. Type", ApplToDocType);
        ItemChargeAssgntSales.SetRange("Applies-to Doc. No.", ApplToDocNo);
        ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", ApplToDocLineNo);
        if ItemChargeAssgntSales.FindFirst then begin
            ItemChargeAssgntSales."Qty. Assigned" := ItemChargeAssgntSales."Qty. Assigned" + QtyToAssign;
            ItemChargeAssgntSales."Qty. to Assign" := 0;
            ItemChargeAssgntSales."Amount to Assign" := 0;
            ItemChargeAssgntSales.Modify;
        end else begin
            ItemChargeAssgntSales.SetRange("Applies-to Doc. Type");
            ItemChargeAssgntSales.SetRange("Applies-to Doc. No.");
            ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.");
            ItemChargeAssgntSales.CalcSums("Qty. to Assign");

            // calculate total qty. to assign of the invoice charge line
            TempItemChargeAssgntSales2.SetRange("Document Type", TempItemChargeAssgntSales."Document Type");
            TempItemChargeAssgntSales2.SetRange("Document No.", TempItemChargeAssgntSales."Document No.");
            TempItemChargeAssgntSales2.SetRange("Document Line No.", TempItemChargeAssgntSales."Document Line No.");
            TempItemChargeAssgntSales2.CalcSums("Qty. to Assign");

            TotalToAssign := ItemChargeAssgntSales."Qty. to Assign" +
              TempItemChargeAssgntSales2."Qty. to Assign";

            if ItemChargeAssgntSales.FindLast then
                LastLineNo := ItemChargeAssgntSales."Line No.";

            if SalesOrderLine.Quantity < TotalToAssign then
                repeat
                    TotalToAssign := TotalToAssign - ItemChargeAssgntSales."Qty. to Assign";
                    ItemChargeAssgntSales."Qty. to Assign" := 0;
                    ItemChargeAssgntSales."Amount to Assign" := 0;
                    ItemChargeAssgntSales.Modify;
                until (ItemChargeAssgntSales.Next(-1) = 0) or
                      (TotalToAssign = SalesOrderLine.Quantity);

            InsertAssocOrderCharge(
              SalesOrderLine,
              ApplToDocType,
              ApplToDocNo,
              ApplToDocLineNo,
              LastLineNo,
              TempItemChargeAssgntSales."Applies-to Doc. Line Amount");
        end;
    end;

    local procedure InsertAssocOrderCharge(SalesOrderLine: Record "Sales Line"; ApplToDocType: Option; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; LastLineNo: Integer; ApplToDocLineAmt: Decimal)
    var
        NewItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        with NewItemChargeAssgntSales do begin
            Init;
            "Document Type" := SalesOrderLine."Document Type";
            "Document No." := SalesOrderLine."Document No.";
            "Document Line No." := SalesOrderLine."Line No.";
            "Line No." := LastLineNo + 10000;
            "Item Charge No." := TempItemChargeAssgntSales."Item Charge No.";
            "Item No." := TempItemChargeAssgntSales."Item No.";
            "Qty. Assigned" := TempItemChargeAssgntSales."Qty. to Assign";
            "Qty. to Assign" := 0;
            "Amount to Assign" := 0;
            Description := TempItemChargeAssgntSales.Description;
            "Unit Cost" := TempItemChargeAssgntSales."Unit Cost";
            "Applies-to Doc. Type" := ApplToDocType;
            "Applies-to Doc. No." := ApplToDocNo;
            "Applies-to Doc. Line No." := ApplToDocLineNo;
            "Applies-to Doc. Line Amount" := ApplToDocLineAmt;
            Insert;
        end;
    end;

    local procedure CopyAndCheckItemCharge(SalesHeader: Record "Sales Header")
    var
        TempSalesLine: Record "Sales Line" temporary;
        SalesLine: Record "Sales Line";
        InvoiceEverything: Boolean;
        AssignError: Boolean;
        QtyNeeded: Decimal;
    begin
        TempItemChargeAssgntSales.Reset;
        TempItemChargeAssgntSales.DeleteAll;

        // Check for max qty posting
        with TempSalesLine do begin
            ResetTempLines(TempSalesLine);
            SetRange(Type, Type::"Charge (Item)");
            if IsEmpty then
                exit;

            ItemChargeAssgntSales.Reset;
            ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
            ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
            ItemChargeAssgntSales.SetFilter("Qty. to Assign", '<>0');
            if ItemChargeAssgntSales.FindSet then
                repeat
                    TempItemChargeAssgntSales.Init;
                    TempItemChargeAssgntSales := ItemChargeAssgntSales;
                    TempItemChargeAssgntSales.Insert;
                until ItemChargeAssgntSales.Next = 0;

            SetFilter("Qty. to Invoice", '<>0');
            if FindSet then
                repeat
                    OnCopyAndCheckItemChargeOnBeforeLoop(TempSalesLine, SalesHeader);
                    TestField("Job No.", '');
                    TestField("Job Contract Entry No.", 0);
                    if ("Qty. to Ship" + "Return Qty. to Receive" <> 0) and
                       ((SalesHeader.Ship or SalesHeader.Receive) or
                        (Abs("Qty. to Invoice") >
                         Abs("Qty. Shipped Not Invoiced" + "Qty. to Ship") +
                         Abs("Ret. Qty. Rcd. Not Invd.(Base)" + "Return Qty. to Receive")))
                    then
                        TestField("Line Amount");

                    if not SalesHeader.Ship then
                        "Qty. to Ship" := 0;
                    if not SalesHeader.Receive then
                        "Return Qty. to Receive" := 0;
                    if Abs("Qty. to Invoice") >
                       Abs("Quantity Shipped" + "Qty. to Ship" + "Return Qty. Received" + "Return Qty. to Receive" - "Quantity Invoiced")
                    then
                        "Qty. to Invoice" :=
                          "Quantity Shipped" + "Qty. to Ship" + "Return Qty. Received" + "Return Qty. to Receive" - "Quantity Invoiced";

                    CalcFields("Qty. to Assign", "Qty. Assigned");
                    if Abs("Qty. to Assign" + "Qty. Assigned") > Abs("Qty. to Invoice" + "Quantity Invoiced") then
                        Error(CannotAssignMoreErr,
                          "Qty. to Invoice" + "Quantity Invoiced" - "Qty. Assigned",
                          FieldCaption("Document Type"), "Document Type",
                          FieldCaption("Document No."), "Document No.",
                          FieldCaption("Line No."), "Line No.");
                    if Quantity = "Qty. to Invoice" + "Quantity Invoiced" then begin
                        if "Qty. to Assign" <> 0 then
                            if Quantity = "Quantity Invoiced" then begin
                                TempItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
                                TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type", "Document Type");
                                if TempItemChargeAssgntSales.FindSet then
                                    repeat
                                        SalesLine.Get(
                                          TempItemChargeAssgntSales."Applies-to Doc. Type",
                                          TempItemChargeAssgntSales."Applies-to Doc. No.",
                                          TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                                        if SalesLine.Quantity = SalesLine."Quantity Invoiced" then
                                            Error(CannotAssignInvoicedErr, SalesLine.TableCaption,
                                              SalesLine.FieldCaption("Document Type"), SalesLine."Document Type",
                                              SalesLine.FieldCaption("Document No."), SalesLine."Document No.",
                                              SalesLine.FieldCaption("Line No."), SalesLine."Line No.");
                                    until TempItemChargeAssgntSales.Next = 0;
                            end;
                        if Quantity <> "Qty. to Assign" + "Qty. Assigned" then
                            AssignError := true;
                    end;

                    if ("Qty. to Assign" + "Qty. Assigned") < ("Qty. to Invoice" + "Quantity Invoiced") then
                        Error(MustAssignItemChargeErr, "No.");

                    // check if all ILEs exist
                    QtyNeeded := "Qty. to Assign";
                    TempItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
                    if TempItemChargeAssgntSales.FindSet then
                        repeat
                            if (TempItemChargeAssgntSales."Applies-to Doc. Type" <> "Document Type") or
                               (TempItemChargeAssgntSales."Applies-to Doc. No." <> "Document No.")
                            then
                                QtyNeeded := QtyNeeded - TempItemChargeAssgntSales."Qty. to Assign"
                            else begin
                                SalesLine.Get(
                                  TempItemChargeAssgntSales."Applies-to Doc. Type",
                                  TempItemChargeAssgntSales."Applies-to Doc. No.",
                                  TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                                if ItemLedgerEntryExist(SalesLine, SalesHeader.Ship or SalesHeader.Receive) then
                                    QtyNeeded := QtyNeeded - TempItemChargeAssgntSales."Qty. to Assign";
                            end;
                        until TempItemChargeAssgntSales.Next = 0;

                    if QtyNeeded > 0 then
                        Error(CannotInvoiceItemChargeErr, "No.");
                until Next = 0;

            // Check saleslines
            if AssignError then
                if SalesHeader."Document Type" in
                   [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"]
                then
                    InvoiceEverything := true
                else begin
                    Reset;
                    SetFilter(Type, '%1|%2', Type::Item, Type::"Charge (Item)");
                    if FindSet then
                        repeat
                            if SalesHeader.Ship or SalesHeader.Receive then
                                InvoiceEverything :=
                                  Quantity = "Qty. to Invoice" + "Quantity Invoiced"
                            else
                                InvoiceEverything :=
                                  (Quantity = "Qty. to Invoice" + "Quantity Invoiced") and
                                  ("Qty. to Invoice" =
                                   "Qty. Shipped Not Invoiced" + "Ret. Qty. Rcd. Not Invd.(Base)");
                        until (Next = 0) or (not InvoiceEverything);
                end;

            if InvoiceEverything and AssignError then
                Error(MustAssignErr);
        end;
    end;

    local procedure ClearItemChargeAssgntFilter()
    begin
        TempItemChargeAssgntSales.SetRange("Document Line No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.");
        TempItemChargeAssgntSales.MarkedOnly(false);
    end;

    local procedure GetItemChargeLine(SalesHeader: Record "Sales Header"; var ItemChargeSalesLine: Record "Sales Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        QtyShippedNotInvd: Decimal;
        QtyReceivedNotInvd: Decimal;
    begin
        with TempItemChargeAssgntSales do
            if (ItemChargeSalesLine."Document Type" <> "Document Type") or
               (ItemChargeSalesLine."Document No." <> "Document No.") or
               (ItemChargeSalesLine."Line No." <> "Document Line No.")
            then begin
                ItemChargeSalesLine.Get("Document Type", "Document No.", "Document Line No.");
                if not SalesHeader.Ship then
                    ItemChargeSalesLine."Qty. to Ship" := 0;
                if not SalesHeader.Receive then
                    ItemChargeSalesLine."Return Qty. to Receive" := 0;
                if ItemChargeSalesLine."Shipment No." <> '' then begin
                    SalesShptLine.Get(ItemChargeSalesLine."Shipment No.", ItemChargeSalesLine."Shipment Line No.");
                    QtyShippedNotInvd := "Qty. to Assign" - "Qty. Assigned";
                end else
                    QtyShippedNotInvd := ItemChargeSalesLine."Quantity Shipped";
                if ItemChargeSalesLine."Return Receipt No." <> '' then begin
                    ReturnReceiptLine.Get(ItemChargeSalesLine."Return Receipt No.", ItemChargeSalesLine."Return Receipt Line No.");
                    QtyReceivedNotInvd := "Qty. to Assign" - "Qty. Assigned";
                end else
                    QtyReceivedNotInvd := ItemChargeSalesLine."Return Qty. Received";
                if Abs(ItemChargeSalesLine."Qty. to Invoice") >
                   Abs(QtyShippedNotInvd + ItemChargeSalesLine."Qty. to Ship" +
                     QtyReceivedNotInvd + ItemChargeSalesLine."Return Qty. to Receive" -
                     ItemChargeSalesLine."Quantity Invoiced")
                then
                    ItemChargeSalesLine."Qty. to Invoice" :=
                      QtyShippedNotInvd + ItemChargeSalesLine."Qty. to Ship" +
                      QtyReceivedNotInvd + ItemChargeSalesLine."Return Qty. to Receive" -
                      ItemChargeSalesLine."Quantity Invoiced";
            end;
    end;

    local procedure CalcQtyToInvoice(QtyToHandle: Decimal; QtyToInvoice: Decimal): Decimal
    begin
        if Abs(QtyToHandle) > Abs(QtyToInvoice) then
            exit(-QtyToHandle);

        exit(-QtyToInvoice);
    end;

    local procedure CheckWarehouse(var TempItemSalesLine: Record "Sales Line" temporary)
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
    begin
        with TempItemSalesLine do begin
            SetRange(Type, Type::Item);
            SetRange("Drop Shipment", false);
            if FindSet then
                repeat
                    GetLocation("Location Code");
                    case "Document Type" of
                        "Document Type"::Order:
                            if ((Location."Require Receive" or Location."Require Put-away") and (Quantity < 0)) or
                               ((Location."Require Shipment" or Location."Require Pick") and (Quantity >= 0))
                            then begin
                                if Location."Directed Put-away and Pick" then
                                    ShowError := true
                                else
                                    if WhseValidateSourceLine.WhseLinesExist(
                                         DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0, Quantity)
                                    then
                                        ShowError := true;
                            end;
                        "Document Type"::"Return Order":
                            if ((Location."Require Receive" or Location."Require Put-away") and (Quantity >= 0)) or
                               ((Location."Require Shipment" or Location."Require Pick") and (Quantity < 0))
                            then begin
                                if Location."Directed Put-away and Pick" then
                                    ShowError := true
                                else
                                    if WhseValidateSourceLine.WhseLinesExist(
                                         DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0, Quantity)
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

    local procedure CreateWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    var
        WhseMgt: Codeunit "Whse. Management";
        WMSMgt: Codeunit "WMS Management";
    begin
        with SalesLine do begin
            WMSMgt.CheckAdjmtBin(Location, ItemJnlLine.Quantity, true);
            WMSMgt.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, false);
            TempWhseJnlLine."Source Type" := DATABASE::"Sales Line";
            TempWhseJnlLine."Source Subtype" := "Document Type";
            TempWhseJnlLine."Source Code" := SrcCode;
            TempWhseJnlLine."Source Document" := WhseMgt.GetSourceDocument(TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
            TempWhseJnlLine."Source No." := "Document No.";
            TempWhseJnlLine."Source Line No." := "Line No.";
            case "Document Type" of
                "Document Type"::Order:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Shipment";
                "Document Type"::Invoice:
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted S. Inv.";
                "Document Type"::"Credit Memo":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted S. Cr. Memo";
                "Document Type"::"Return Order":
                    TempWhseJnlLine."Reference Document" :=
                      TempWhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
            end;
            TempWhseJnlLine."Reference No." := ItemJnlLine."Document No.";
        end;
    end;

    local procedure WhseHandlingRequired(SalesLine: Record "Sales Line"): Boolean
    var
        WhseSetup: Record "Warehouse Setup";
        IsHandled: Boolean;
        Required: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseHandlingRequired(SalesLine, Required, IsHandled);
        if IsHandled then
            exit(Required);

        if (SalesLine.Type = SalesLine.Type::Item) and (not SalesLine."Drop Shipment") then begin
            if SalesLine."Location Code" = '' then begin
                WhseSetup.Get;
                if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
                    exit(WhseSetup."Require Receive");

                exit(WhseSetup."Require Shipment");
            end;

            GetLocation(SalesLine."Location Code");
            if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
                exit(Location."Require Receive");

            exit(Location."Require Shipment");
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

    local procedure InsertShptEntryRelation(var SalesShptLine: Record "Sales Shipment Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempHandlingSpecification.CopySpecification(TempTrackingSpecificationInv);
        TempHandlingSpecification.CopySpecification(TempATOTrackingSpecification);
        TempHandlingSpecification.Reset;
        if TempHandlingSpecification.FindSet then begin
            repeat
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ItemEntryRelation.TransferFieldsSalesShptLine(SalesShptLine);
                ItemEntryRelation.Insert;
            until TempHandlingSpecification.Next = 0;
            TempHandlingSpecification.DeleteAll;
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    local procedure InsertReturnEntryRelation(var ReturnRcptLine: Record "Return Receipt Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempHandlingSpecification.CopySpecification(TempTrackingSpecificationInv);
        TempHandlingSpecification.CopySpecification(TempATOTrackingSpecification);
        TempHandlingSpecification.Reset;
        if TempHandlingSpecification.FindSet then begin
            repeat
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ItemEntryRelation.TransferFieldsReturnRcptLine(ReturnRcptLine);
                ItemEntryRelation.Insert;
            until TempHandlingSpecification.Next = 0;
            TempHandlingSpecification.DeleteAll;
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    local procedure CheckTrackingSpecification(SalesHeader: Record "Sales Header"; var TempItemSalesLine: Record "Sales Line" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJnlLine: Record "Item Journal Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        SalesLineQtyToHandle: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
        CheckSalesLine: Boolean;
    begin
        // if a SalesLine is posted with ItemTracking then tracked quantity must be equal to posted quantity
        if not (SalesHeader."Document Type" in
                [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order"])
        then
            exit;

        TrackingQtyToHandle := 0;

        with TempItemSalesLine do begin
            SetRange(Type, Type::Item);
            if SalesHeader.Ship then begin
                SetFilter("Quantity Shipped", '<>%1', 0);
                ErrorFieldCaption := FieldCaption("Qty. to Ship");
            end else begin
                SetFilter("Return Qty. Received", '<>%1', 0);
                ErrorFieldCaption := FieldCaption("Return Qty. to Receive");
            end;

            if FindSet then begin
                ReservationEntry."Source Type" := DATABASE::"Sales Line";
                ReservationEntry."Source Subtype" := SalesHeader."Document Type";
                SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
                repeat
                    // Only Item where no SerialNo or LotNo is required
                    GetItem(Item);
                    if Item."Item Tracking Code" <> '' then begin
                        Inbound := (Quantity * SignFactor) > 0;
                        ItemTrackingCode.Code := Item."Item Tracking Code";
                        ItemTrackingManagement.GetItemTrackingSettings(ItemTrackingCode,
                          ItemJnlLine."Entry Type"::Sale, Inbound,
                          SNRequired, LotRequired, SNInfoRequired, LotInfoRequired);
                        CheckSalesLine := not SNRequired and not LotRequired;
                        if CheckSalesLine then
                            CheckSalesLine := CheckTrackingExists(TempItemSalesLine);
                    end else
                        CheckSalesLine := false;

                    TrackingQtyToHandle := 0;

                    if CheckSalesLine then begin
                        TrackingQtyToHandle := GetTrackingQuantities(TempItemSalesLine) * SignFactor;
                        if SalesHeader.Ship then
                            SalesLineQtyToHandle := "Qty. to Ship (Base)"
                        else
                            SalesLineQtyToHandle := "Return Qty. to Receive (Base)";
                        if TrackingQtyToHandle <> SalesLineQtyToHandle then
                            Error(ItemTrackQuantityMismatchErr, ErrorFieldCaption);
                    end;
                until Next = 0;
            end;
            if SalesHeader.Ship then
                SetRange("Quantity Shipped")
            else
                SetRange("Return Qty. Received");
        end;
    end;

    local procedure CheckTrackingExists(SalesLine: Record "Sales Line"): Boolean
    begin
        exit(
          ItemTrackingMgt.ItemTrackingExistsOnDocumentLine(
            DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No."));
    end;

    local procedure GetTrackingQuantities(SalesLine: Record "Sales Line"): Decimal
    begin
        exit(
          ItemTrackingMgt.CalcQtyToHandleForTrackedQtyOnDocumentLine(
            DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No."));
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

    local procedure InsertTrackingSpecification(SalesHeader: Record "Sales Header")
    begin
        TempTrackingSpecification.Reset;
        if not TempTrackingSpecification.IsEmpty then begin
            TempTrackingSpecification.InsertSpecification;
            ReserveSalesLine.UpdateItemTrackingAfterPosting(SalesHeader);
        end;
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

    local procedure SetPaymentInstructions(SalesHeader: Record "Sales Header")
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
        OutStream: OutStream;
    begin
        if not O365PaymentInstructions.Get(SalesHeader."Payment Instructions Id") then
            exit;

        SalesInvHeader."Payment Instructions".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(O365PaymentInstructions.GetPaymentInstructionsInCurrentLanguage);

        SalesInvHeader."Payment Instructions Name" := O365PaymentInstructions.GetNameInCurrentLanguage;
    end;

    local procedure PostItemCharge(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        SalesLineToPost: Record "Sales Line";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        with TempItemChargeAssgntSales do begin
            SalesLineToPost := SalesLine;
            SalesLineToPost."No." := "Item No.";
            SalesLineToPost."Appl.-to Item Entry" := ItemEntryNo;
            if not ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) then
                SalesLineToPost.Amount := -AmountToAssign
            else
                SalesLineToPost.Amount := AmountToAssign;

            if SalesLineToPost."Currency Code" <> '' then
                SalesLineToPost."Unit Cost" := Round(
                    SalesLineToPost.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision")
            else
                SalesLineToPost."Unit Cost" := Round(
                    SalesLineToPost.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");
            TotalChargeAmt := TotalChargeAmt + SalesLineToPost.Amount;

            if SalesHeader."Currency Code" <> '' then
                SalesLineToPost.Amount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    UseDate, SalesHeader."Currency Code", TotalChargeAmt, SalesHeader."Currency Factor");
            SalesLineToPost."Inv. Discount Amount" := Round(
                SalesLine."Inv. Discount Amount" / SalesLine.Quantity * QtyToAssign,
                GLSetup."Amount Rounding Precision");
            SalesLineToPost."Line Discount Amount" := Round(
                SalesLine."Line Discount Amount" / SalesLine.Quantity * QtyToAssign,
                GLSetup."Amount Rounding Precision");
            SalesLineToPost."Line Amount" := Round(
                SalesLine."Line Amount" / SalesLine.Quantity * QtyToAssign,
                GLSetup."Amount Rounding Precision");
            SalesLine."Inv. Discount Amount" := SalesLine."Inv. Discount Amount" - SalesLineToPost."Inv. Discount Amount";
            SalesLine."Line Discount Amount" := SalesLine."Line Discount Amount" - SalesLineToPost."Line Discount Amount";
            SalesLine."Line Amount" := SalesLine."Line Amount" - SalesLineToPost."Line Amount";
            SalesLine.Quantity := SalesLine.Quantity - QtyToAssign;
            SalesLineToPost.Amount := Round(SalesLineToPost.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
            if SalesHeader."Currency Code" <> '' then
                TotalChargeAmtLCY := TotalChargeAmtLCY + SalesLineToPost.Amount;
            SalesLineToPost."Unit Cost (LCY)" := Round(
                SalesLineToPost.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");
            UpdateSalesLineDimSetIDFromAppliedEntry(SalesLineToPost, SalesLine);
            SalesLineToPost."Line No." := "Document Line No.";

            OnPostItemChargeOnBeforePostItemJnlLine(SalesLineToPost, SalesLine, QtyToAssign);

            PostItemJnlLine(
              SalesHeader, SalesLineToPost, 0, 0, -QuantityBase, -QuantityBase,
              SalesLineToPost."Appl.-to Item Entry", "Item Charge No.", DummyTrackingSpecification, false);
        end;
    end;

    local procedure SaveTempWhseSplitSpec(var SalesLine3: Record "Sales Line"; var TempSrcTrackingSpec: Record "Tracking Specification" temporary)
    begin
        TempWhseSplitSpecification.Reset;
        TempWhseSplitSpecification.DeleteAll;
        if TempSrcTrackingSpec.FindSet then
            repeat
                TempWhseSplitSpecification := TempSrcTrackingSpec;
                TempWhseSplitSpecification.SetSource(
                  DATABASE::"Sales Line", SalesLine3."Document Type", SalesLine3."Document No.", SalesLine3."Line No.", '', 0);
                TempWhseSplitSpecification.Insert;
            until TempSrcTrackingSpec.Next = 0;
    end;

    local procedure TransferReservToItemJnlLine(var SalesOrderLine: Record "Sales Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeShippedBase: Decimal; var TempTrackingSpecification2: Record "Tracking Specification" temporary; var CheckApplFromItemEntry: Boolean)
    var
        RemainingQuantity: Decimal;
    begin
        // Handle Item Tracking and reservations, also on drop shipment
        if QtyToBeShippedBase = 0 then
            exit;

        Clear(ReserveSalesLine);
        if not SalesOrderLine."Drop Shipment" then
            if not HasSpecificTracking(SalesOrderLine."No.") and HasInvtPickLine(SalesOrderLine) then
                ReserveSalesLine.TransferSalesLineToItemJnlLine(
                  SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, true)
            else
                ReserveSalesLine.TransferSalesLineToItemJnlLine(
                  SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
        else begin
            ReserveSalesLine.SetApplySpecificItemTracking(true);
            TempTrackingSpecification2.Reset;
            TempTrackingSpecification2.SetSourceFilter(
              DATABASE::"Purchase Line", 1, SalesOrderLine."Purchase Order No.", SalesOrderLine."Purch. Order Line No.", false);
            TempTrackingSpecification2.SetSourceFilter('', 0);
            if TempTrackingSpecification2.IsEmpty then
                ReserveSalesLine.TransferSalesLineToItemJnlLine(
                  SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
            else begin
                ReserveSalesLine.SetOverruleItemTracking(true);
                ReserveSalesLine.SetItemTrkgAlreadyOverruled(ItemTrkgAlreadyOverruled);
                TempTrackingSpecification2.FindSet;
                if TempTrackingSpecification2."Quantity (Base)" / QtyToBeShippedBase < 0 then
                    Error(ItemTrackingWrongSignErr);
                repeat
                    ItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification2);
                    ItemJnlLine."Applies-to Entry" := TempTrackingSpecification2."Item Ledger Entry No.";
                    RemainingQuantity :=
                      ReserveSalesLine.TransferSalesLineToItemJnlLine(
                        SalesOrderLine, ItemJnlLine, TempTrackingSpecification2."Quantity (Base)", CheckApplFromItemEntry, false);
                    if RemainingQuantity <> 0 then
                        Error(ItemTrackingMismatchErr);
                until TempTrackingSpecification2.Next = 0;
                ItemJnlLine.ClearTracking;
                ItemJnlLine."Applies-to Entry" := 0;
            end;
        end;
    end;

    local procedure TransferReservFromPurchLine(var PurchOrderLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; QtyToBeShippedBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        RemainingQuantity: Decimal;
        CheckApplToItemEntry: Boolean;
    begin
        // Handle Item Tracking on Drop Shipment
        ItemTrkgAlreadyOverruled := false;
        if QtyToBeShippedBase = 0 then
            exit;

        ReservEntry.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", true);
        ReservEntry.SetSourceFilter('', 0);
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        if not ReservEntry.IsEmpty then
            ItemTrackingMgt.SumUpItemTracking(ReservEntry, TempTrackingSpecification2, false, true);
        TempTrackingSpecification2.SetFilter("Qty. to Handle (Base)", '<>0');
        if TempTrackingSpecification2.IsEmpty then begin
            ReserveSalesLine.SetApplySpecificItemTracking(true);
            ReservePurchLine.TransferPurchLineToItemJnlLine(
              PurchOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplToItemEntry)
        end else begin
            ReservePurchLine.SetOverruleItemTracking(true);
            ItemTrkgAlreadyOverruled := true;
            TempTrackingSpecification2.FindSet;
            if -TempTrackingSpecification2."Quantity (Base)" / QtyToBeShippedBase < 0 then
                Error(ItemTrackingWrongSignErr);
            if ReservePurchLine.ReservEntryExist(PurchOrderLine) then
                repeat
                    ItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification2);
                    RemainingQuantity :=
                      ReservePurchLine.TransferPurchLineToItemJnlLine(
                        PurchOrderLine, ItemJnlLine,
                        -TempTrackingSpecification2."Qty. to Handle (Base)", CheckApplToItemEntry);
                    if RemainingQuantity <> 0 then
                        Error(ItemTrackingMismatchErr);
                until TempTrackingSpecification2.Next = 0;
            ItemJnlLine.ClearTracking;
            ItemJnlLine."Applies-to Entry" := 0;
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

    local procedure GetItem(SalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            TestField(Type, Type::Item);
            TestField("No.");
            if "No." <> Item."No." then
                Item.Get("No.");
        end;
    end;

    local procedure CreatePrepaymentLines(SalesHeader: Record "Sales Header"; CompleteFunctionality: Boolean)
    var
        GLAcc: Record "G/L Account";
        TempSalesLine: Record "Sales Line" temporary;
        TempExtTextLine: Record "Extended Text Line" temporary;
        GenPostingSetup: Record "General Posting Setup";
        TempPrepmtSalesLine: Record "Sales Line" temporary;
        TransferExtText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
        Fraction: Decimal;
        VATDifference: Decimal;
        TempLineFound: Boolean;
        PrepmtAmtToDeduct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePrepaymentLines(SalesHeader, TempPrepmtSalesLine, CompleteFunctionality, IsHandled);
        if IsHandled then
            exit;

        GetGLSetup;
        with TempSalesLine do begin
            FillTempLines(SalesHeader, TempSalesLineGlobal);
            ResetTempLines(TempSalesLine);
            if not FindLast then
                exit;
            NextLineNo := "Line No." + 10000;
            SetFilter(Quantity, '>0');
            SetFilter("Qty. to Invoice", '>0');
            TempPrepmtSalesLine.SetHasBeenShown;
            if FindSet then begin
                if CompleteFunctionality and ("Document Type" = "Document Type"::Invoice) then
                    TestGetShipmentPPmtAmtToDeduct;
                repeat
                    if CompleteFunctionality then
                        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then begin
                            if not SalesHeader.Ship and ("Qty. to Invoice" = Quantity - "Quantity Invoiced") then
                                if "Qty. Shipped Not Invoiced" < "Qty. to Invoice" then
                                    Validate("Qty. to Invoice", "Qty. Shipped Not Invoiced");
                            Fraction := ("Qty. to Invoice" + "Quantity Invoiced") / Quantity;

                            if "Prepayment %" <> 100 then
                                case true of
                                    ("Prepmt Amt to Deduct" <> 0) and
                                  ("Prepmt Amt to Deduct" > Round(Fraction * "Line Amount", Currency."Amount Rounding Precision")):
                                        FieldError(
                                          "Prepmt Amt to Deduct",
                                          StrSubstNo(CannotBeGreaterThanErr,
                                            Round(Fraction * "Line Amount", Currency."Amount Rounding Precision")));
                                    ("Prepmt. Amt. Inv." <> 0) and
                                  (Round((1 - Fraction) * "Line Amount", Currency."Amount Rounding Precision") <
                                   Round(
                                     Round(
                                       Round("Unit Price" * (Quantity - "Quantity Invoiced" - "Qty. to Invoice"),
                                         Currency."Amount Rounding Precision") *
                                       (1 - ("Line Discount %" / 100)), Currency."Amount Rounding Precision") *
                                     "Prepayment %" / 100, Currency."Amount Rounding Precision")):
                                        FieldError(
                                          "Prepmt Amt to Deduct",
                                          StrSubstNo(CannotBeSmallerThanErr,
                                            Round(
                                              "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" - (1 - Fraction) * "Line Amount",
                                              Currency."Amount Rounding Precision")));
                                end;
                        end;
                    if "Prepmt Amt to Deduct" <> 0 then begin
                        if ("Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
                           ("Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                        then
                            GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                        GLAcc.Get(GenPostingSetup.GetSalesPrepmtAccount);
                        TempLineFound := false;
                        if SalesHeader."Compress Prepayment" then begin
                            TempPrepmtSalesLine.SetRange("No.", GLAcc."No.");
                            TempPrepmtSalesLine.SetRange("Dimension Set ID", "Dimension Set ID");
                            TempLineFound := TempPrepmtSalesLine.FindFirst;
                        end;
                        if TempLineFound then begin
                            PrepmtAmtToDeduct :=
                              TempPrepmtSalesLine."Prepmt Amt to Deduct" +
                              InsertedPrepmtVATBaseToDeduct(
                                SalesHeader, TempSalesLine, TempPrepmtSalesLine."Line No.", TempPrepmtSalesLine."Unit Price");
                            VATDifference := TempPrepmtSalesLine."VAT Difference";
                            TempPrepmtSalesLine.Validate(
                              "Unit Price", TempPrepmtSalesLine."Unit Price" + "Prepmt Amt to Deduct");
                            TempPrepmtSalesLine.Validate("VAT Difference", VATDifference - "Prepmt VAT Diff. to Deduct");
                            TempPrepmtSalesLine."Prepmt Amt to Deduct" := PrepmtAmtToDeduct;
                            if "Prepayment %" < TempPrepmtSalesLine."Prepayment %" then
                                TempPrepmtSalesLine."Prepayment %" := "Prepayment %";
                            OnBeforeTempPrepmtSalesLineModify(TempPrepmtSalesLine, TempSalesLine, SalesHeader, CompleteFunctionality);
                            TempPrepmtSalesLine.Modify;
                        end else begin
                            TempPrepmtSalesLine.Init;
                            TempPrepmtSalesLine."Document Type" := SalesHeader."Document Type";
                            TempPrepmtSalesLine."Document No." := SalesHeader."No.";
                            TempPrepmtSalesLine."Line No." := 0;
                            TempPrepmtSalesLine."System-Created Entry" := true;
                            if CompleteFunctionality then
                                TempPrepmtSalesLine.Validate(Type, TempPrepmtSalesLine.Type::"G/L Account")
                            else
                                TempPrepmtSalesLine.Type := TempPrepmtSalesLine.Type::"G/L Account";
                            TempPrepmtSalesLine.Validate("No.", GenPostingSetup."Sales Prepayments Account");
                            TempPrepmtSalesLine.Validate(Quantity, -1);
                            TempPrepmtSalesLine."Qty. to Ship" := TempPrepmtSalesLine.Quantity;
                            TempPrepmtSalesLine."Qty. to Invoice" := TempPrepmtSalesLine.Quantity;
                            PrepmtAmtToDeduct := InsertedPrepmtVATBaseToDeduct(SalesHeader, TempSalesLine, NextLineNo, 0);
                            TempPrepmtSalesLine.Validate("Unit Price", "Prepmt Amt to Deduct");
                            TempPrepmtSalesLine.Validate("VAT Difference", -"Prepmt VAT Diff. to Deduct");
                            TempPrepmtSalesLine."Prepmt Amt to Deduct" := PrepmtAmtToDeduct;
                            TempPrepmtSalesLine."Prepayment %" := "Prepayment %";
                            TempPrepmtSalesLine."Prepayment Line" := true;
                            TempPrepmtSalesLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                            TempPrepmtSalesLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                            TempPrepmtSalesLine."Dimension Set ID" := "Dimension Set ID";
                            TempPrepmtSalesLine."Line No." := NextLineNo;
                            NextLineNo := NextLineNo + 10000;
                            OnBeforeTempPrepmtSalesLineInsert(TempPrepmtSalesLine, TempSalesLine, SalesHeader, CompleteFunctionality);
                            TempPrepmtSalesLine.Insert;

                            TransferExtText.PrepmtGetAnyExtText(
                              TempPrepmtSalesLine."No.", DATABASE::"Sales Invoice Line",
                              SalesHeader."Document Date", SalesHeader."Language Code", TempExtTextLine);
                            if TempExtTextLine.Find('-') then
                                repeat
                                    TempPrepmtSalesLine.Init;
                                    TempPrepmtSalesLine.Description := TempExtTextLine.Text;
                                    TempPrepmtSalesLine."System-Created Entry" := true;
                                    TempPrepmtSalesLine."Prepayment Line" := true;
                                    TempPrepmtSalesLine."Line No." := NextLineNo;
                                    NextLineNo := NextLineNo + 10000;
                                    TempPrepmtSalesLine.Insert;
                                until TempExtTextLine.Next = 0;
                        end;
                    end;
                until Next = 0
            end;
        end;
        DividePrepmtAmountLCY(TempPrepmtSalesLine, SalesHeader);
        if TempPrepmtSalesLine.FindSet then
            repeat
                TempSalesLineGlobal := TempPrepmtSalesLine;
                TempSalesLineGlobal.Insert;
            until TempPrepmtSalesLine.Next = 0;
    end;

    local procedure InsertedPrepmtVATBaseToDeduct(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PrepmtLineNo: Integer; TotalPrepmtAmtToDeduct: Decimal): Decimal
    var
        PrepmtVATBaseToDeduct: Decimal;
    begin
        with SalesLine do begin
            if SalesHeader."Prices Including VAT" then
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
        with TempPrepmtDeductLCYSalesLine do begin
            TempPrepmtDeductLCYSalesLine := SalesLine;
            if "Document Type" = "Document Type"::Order then
                "Qty. to Invoice" := GetQtyToInvoice(SalesLine, SalesHeader.Ship)
            else
                GetLineDataFromOrder(TempPrepmtDeductLCYSalesLine);
            if ("Prepmt Amt to Deduct" = 0) or ("Document Type" = "Document Type"::Invoice) then
                CalcPrepaymentToDeduct;
            "Line Amount" := GetLineAmountToHandleInclPrepmt("Qty. to Invoice");
            "Attached to Line No." := PrepmtLineNo;
            "VAT Base Amount" := PrepmtVATBaseToDeduct;
            Insert;
        end;

        OnAfterInsertedPrepmtVATBaseToDeduct(
          SalesHeader, SalesLine, PrepmtLineNo, TotalPrepmtAmtToDeduct, TempPrepmtDeductLCYSalesLine, PrepmtVATBaseToDeduct);

        exit(PrepmtVATBaseToDeduct);
    end;

    local procedure DividePrepmtAmountLCY(var PrepmtSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        ActualCurrencyFactor: Decimal;
    begin
        with PrepmtSalesLine do begin
            Reset;
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet then
                repeat
                    if SalesHeader."Currency Code" <> '' then
                        ActualCurrencyFactor :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              SalesHeader."Posting Date",
                              SalesHeader."Currency Code",
                              "Prepmt Amt to Deduct",
                              SalesHeader."Currency Factor")) /
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
        with TempPrepmtDeductLCYSalesLine do begin
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

    local procedure AdjustPrepmtAmountLCY(SalesHeader: Record "Sales Header"; var PrepmtSalesLine: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Line";
        DeductionFactor: Decimal;
        PrepmtVATPart: Decimal;
        PrepmtVATAmtRemainder: Decimal;
        TotalRoundingAmount: array[2] of Decimal;
        TotalPrepmtAmount: array[2] of Decimal;
        FinalInvoice: Boolean;
        PricesInclVATRoundingAmount: array[2] of Decimal;
    begin
        if PrepmtSalesLine."Prepayment Line" then begin
            PrepmtVATPart :=
              (PrepmtSalesLine."Amount Including VAT" - PrepmtSalesLine.Amount) / PrepmtSalesLine."Unit Price";

            with TempPrepmtDeductLCYSalesLine do begin
                Reset;
                SetRange("Attached to Line No.", PrepmtSalesLine."Line No.");
                if FindSet(true) then begin
                    FinalInvoice := IsFinalInvoice;
                    repeat
                        SalesLine := TempPrepmtDeductLCYSalesLine;
                        SalesLine.Find;
                        if "Document Type" = "Document Type"::Invoice then begin
                            SalesInvoiceLine := SalesLine;
                            GetSalesOrderLine(SalesLine, SalesInvoiceLine);
                            SalesLine."Qty. to Invoice" := SalesInvoiceLine."Qty. to Invoice";
                        end;
                        if SalesLine."Qty. to Invoice" <> "Qty. to Invoice" then
                            SalesLine."Prepmt Amt to Deduct" := CalcPrepmtAmtToDeduct(SalesLine, SalesHeader.Ship);
                        DeductionFactor :=
                          SalesLine."Prepmt Amt to Deduct" /
                          (SalesLine."Prepmt. Amt. Inv." - SalesLine."Prepmt Amt Deducted");

                        "Prepmt. VAT Amount Inv. (LCY)" :=
                          CalcRoundedAmount(SalesLine."Prepmt Amt to Deduct" * PrepmtVATPart, PrepmtVATAmtRemainder);
                        if ("Prepayment %" <> 100) or IsFinalInvoice or ("Currency Code" <> '') then
                            CalcPrepmtRoundingAmounts(TempPrepmtDeductLCYSalesLine, SalesLine, DeductionFactor, TotalRoundingAmount);
                        Modify;

                        if SalesHeader."Prices Including VAT" then
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

            UpdatePrepmtSalesLineWithRounding(
              PrepmtSalesLine, TotalRoundingAmount, TotalPrepmtAmount,
              FinalInvoice, PricesInclVATRoundingAmount);
        end;
    end;

    local procedure CalcPrepmtAmtToDeduct(SalesLine: Record "Sales Line"; Ship: Boolean): Decimal
    begin
        with SalesLine do begin
            "Qty. to Invoice" := GetQtyToInvoice(SalesLine, Ship);
            CalcPrepaymentToDeduct;
            exit("Prepmt Amt to Deduct");
        end;
    end;

    local procedure GetQtyToInvoice(SalesLine: Record "Sales Line"; Ship: Boolean): Decimal
    var
        AllowedQtyToInvoice: Decimal;
    begin
        with SalesLine do begin
            AllowedQtyToInvoice := "Qty. Shipped Not Invoiced";
            if Ship then
                AllowedQtyToInvoice := AllowedQtyToInvoice + "Qty. to Ship";
            if "Qty. to Invoice" > AllowedQtyToInvoice then
                exit(AllowedQtyToInvoice);
            exit("Qty. to Invoice");
        end;
    end;

    local procedure GetLineDataFromOrder(var SalesLine: Record "Sales Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        SalesOrderLine: Record "Sales Line";
    begin
        with SalesLine do begin
            SalesShptLine.Get("Shipment No.", "Shipment Line No.");
            SalesOrderLine.Get("Document Type"::Order, SalesShptLine."Order No.", SalesShptLine."Order Line No.");

            Quantity := SalesOrderLine.Quantity;
            "Qty. Shipped Not Invoiced" := SalesOrderLine."Qty. Shipped Not Invoiced";
            "Quantity Invoiced" := SalesOrderLine."Quantity Invoiced";
            "Prepmt Amt Deducted" := SalesOrderLine."Prepmt Amt Deducted";
            "Prepmt. Amt. Inv." := SalesOrderLine."Prepmt. Amt. Inv.";
            "Line Discount Amount" := SalesOrderLine."Line Discount Amount";
        end;
    end;

    local procedure CalcPrepmtRoundingAmounts(var PrepmtSalesLineBuf: Record "Sales Line"; SalesLine: Record "Sales Line"; DeductionFactor: Decimal; var TotalRoundingAmount: array[2] of Decimal)
    var
        RoundingAmount: array[2] of Decimal;
    begin
        with PrepmtSalesLineBuf do begin
            if "VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT" then begin
                RoundingAmount[1] :=
                  "Prepmt. Amount Inv. (LCY)" - Round(DeductionFactor * SalesLine."Prepmt. Amount Inv. (LCY)");
                "Prepmt. Amount Inv. (LCY)" := "Prepmt. Amount Inv. (LCY)" - RoundingAmount[1];
                TotalRoundingAmount[1] += RoundingAmount[1];
            end;
            RoundingAmount[2] :=
              "Prepmt. VAT Amount Inv. (LCY)" - Round(DeductionFactor * SalesLine."Prepmt. VAT Amount Inv. (LCY)");
            "Prepmt. VAT Amount Inv. (LCY)" := "Prepmt. VAT Amount Inv. (LCY)" - RoundingAmount[2];
            TotalRoundingAmount[2] += RoundingAmount[2];
        end;
    end;

    local procedure UpdatePrepmtSalesLineWithRounding(var PrepmtSalesLine: Record "Sales Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal)
    var
        NewAmountIncludingVAT: Decimal;
        Prepmt100PctVATRoundingAmt: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        OnBeforeUpdatePrepmtSalesLineWithRounding(
          PrepmtSalesLine, TotalRoundingAmount, TotalPrepmtAmount, FinalInvoice, PricesInclVATRoundingAmount,
          TotalSalesLine, TotalSalesLineLCY);

        with PrepmtSalesLine do begin
            NewAmountIncludingVAT := TotalPrepmtAmount[1] + TotalPrepmtAmount[2] + TotalRoundingAmount[1] + TotalRoundingAmount[2];
            if "Prepayment %" = 100 then
                TotalRoundingAmount[1] += "Amount Including VAT" - NewAmountIncludingVAT;
            AmountRoundingPrecision :=
              GetAmountRoundingPrecisionInLCY("Document Type", "Document No.", "Currency Code");

            if (Abs(TotalRoundingAmount[1]) <= AmountRoundingPrecision) and
               (Abs(TotalRoundingAmount[2]) <= AmountRoundingPrecision)
            then begin
                if "Prepayment %" = 100 then
                    Prepmt100PctVATRoundingAmt := TotalRoundingAmount[1];
                TotalRoundingAmount[1] := 0;
            end;
            "Prepmt. Amount Inv. (LCY)" := TotalRoundingAmount[1];
            Amount := TotalPrepmtAmount[1] + TotalRoundingAmount[1];

            if (PricesInclVATRoundingAmount[1] <> 0) and (TotalRoundingAmount[1] = 0) then begin
                if ("Prepayment %" = 100) and FinalInvoice and
                   (Amount + TotalPrepmtAmount[2] = "Amount Including VAT")
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

            "Prepmt. VAT Amount Inv. (LCY)" := TotalRoundingAmount[2] + Prepmt100PctVATRoundingAmt;
            NewAmountIncludingVAT := Amount + TotalPrepmtAmount[2] + TotalRoundingAmount[2];
            if (PricesInclVATRoundingAmount[1] = 0) and (PricesInclVATRoundingAmount[2] = 0) or
               ("Currency Code" <> '') and FinalInvoice
            then
                Increment(
                  TotalSalesLineLCY."Amount Including VAT",
                  "Amount Including VAT" - NewAmountIncludingVAT - Prepmt100PctVATRoundingAmt);
            if "Currency Code" = '' then
                TotalSalesLine."Amount Including VAT" := TotalSalesLineLCY."Amount Including VAT";
            "Amount Including VAT" := NewAmountIncludingVAT;

            if FinalInvoice and (TotalSalesLine.Amount = 0) and (TotalSalesLine."Amount Including VAT" <> 0) and
               (Abs(TotalSalesLine."Amount Including VAT") <= Currency."Amount Rounding Precision")
            then begin
                "Amount Including VAT" += TotalSalesLineLCY."Amount Including VAT";
                TotalSalesLine."Amount Including VAT" := 0;
                TotalSalesLineLCY."Amount Including VAT" := 0;
            end;
        end;

        OnAfterUpdatePrepmtSalesLineWithRounding(
          PrepmtSalesLine, TotalRoundingAmount, TotalPrepmtAmount, FinalInvoice, PricesInclVATRoundingAmount,
          TotalSalesLine, TotalSalesLineLCY);
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

    local procedure GetSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
    begin
        SalesShptLine.Get(SalesLine."Shipment No.", SalesLine."Shipment Line No.");
        SalesOrderLine.Get(
          SalesOrderLine."Document Type"::Order,
          SalesShptLine."Order No.", SalesShptLine."Order Line No.");
        SalesOrderLine."Prepmt Amt to Deduct" := SalesLine."Prepmt Amt to Deduct";
    end;

    local procedure DecrementPrepmtAmtInvLCY(SalesLine: Record "Sales Line"; var PrepmtAmountInvLCY: Decimal; var PrepmtVATAmountInvLCY: Decimal)
    begin
        TempPrepmtDeductLCYSalesLine.Reset;
        TempPrepmtDeductLCYSalesLine := SalesLine;
        if TempPrepmtDeductLCYSalesLine.Find then begin
            PrepmtAmountInvLCY := PrepmtAmountInvLCY - TempPrepmtDeductLCYSalesLine."Prepmt. Amount Inv. (LCY)";
            PrepmtVATAmountInvLCY := PrepmtVATAmountInvLCY - TempPrepmtDeductLCYSalesLine."Prepmt. VAT Amount Inv. (LCY)";
        end;
    end;

    local procedure AdjustFinalInvWith100PctPrepmt(var CombinedSalesLine: Record "Sales Line")
    var
        DiffToLineDiscAmt: Decimal;
    begin
        with TempPrepmtDeductLCYSalesLine do begin
            Reset;
            SetRange("Prepayment %", 100);
            if FindSet(true) then
                repeat
                    if IsFinalInvoice then begin
                        DiffToLineDiscAmt := "Prepmt Amt to Deduct" - "Line Amount";
                        if "Document Type" = "Document Type"::Order then
                            DiffToLineDiscAmt := DiffToLineDiscAmt * Quantity / "Qty. to Invoice";
                        if DiffToLineDiscAmt <> 0 then begin
                            CombinedSalesLine.Get("Document Type", "Document No.", "Line No.");
                            "Line Discount Amount" := CombinedSalesLine."Line Discount Amount" - DiffToLineDiscAmt;
                            Modify;
                        end;
                    end;
                until Next = 0;
            Reset;
        end;
    end;

    local procedure GetPrepmtDiffToLineAmount(SalesLine: Record "Sales Line"): Decimal
    begin
        with TempPrepmtDeductLCYSalesLine do
            if SalesLine."Prepayment %" = 100 then
                if Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
                    exit("Prepmt Amt to Deduct" + "Inv. Discount Amount" - "Line Amount");
        exit(0);
    end;

    local procedure PostJobContractLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostJobContractLine(SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."Job Contract Entry No." = 0 then
            exit;
        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice) and
           (SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo")
        then
            SalesLine.TestField("Job Contract Entry No.", 0);

        SalesLine.TestField("Job No.");
        SalesLine.TestField("Job Task No.");

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            SalesLine."Document No." := SalesInvHeader."No.";
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            SalesLine."Document No." := SalesCrMemoHeader."No.";
        JobContractLine := true;
        JobPostLine.PostInvoiceContractLine(SalesHeader, SalesLine);
    end;

    local procedure InsertICGenJnlLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var ICGenJnlLineNo: Integer)
    var
        ICGLAccount: Record "IC G/L Account";
        Vend: Record Vendor;
        ICPartner: Record "IC Partner";
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        SalesHeader.TestField("Sell-to IC Partner Code", '');
        SalesHeader.TestField("Bill-to IC Partner Code", '');
        SalesLine.TestField("IC Partner Ref. Type", SalesLine."IC Partner Ref. Type"::"G/L Account");
        ICGLAccount.Get(SalesLine."IC Partner Reference");
        ICGenJnlLineNo := ICGenJnlLineNo + 1;

        with TempICGenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."Posting Description",
              SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code", SalesLine."Dimension Set ID",
              SalesHeader."Reason Code");
            "Line No." := ICGenJnlLineNo;

            CopyDocumentFields(GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, SalesHeader."Posting No. Series");

            Validate("Account Type", "Account Type"::"IC Partner");
            Validate("Account No.", SalesLine."IC Partner Code");
            "Source Currency Code" := SalesHeader."Currency Code";
            "Source Currency Amount" := Amount;
            Correction := SalesHeader.Correction;
            "Country/Region Code" := SalesHeader."VAT Country/Region Code";
            "Source Type" := GenJnlLine."Source Type"::Customer;
            "Source No." := SalesHeader."Bill-to Customer No.";
            "Source Line No." := SalesLine."Line No.";
            Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            Validate("Bal. Account No.", SalesLine."No.");
            "Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := SalesLine."Dimension Set ID";

            Vend.SetRange("IC Partner Code", SalesLine."IC Partner Code");
            if Vend.FindFirst then begin
                Validate("Bal. Gen. Bus. Posting Group", Vend."Gen. Bus. Posting Group");
                Validate("Bal. VAT Bus. Posting Group", Vend."VAT Bus. Posting Group");
            end;
            Validate("Bal. VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
            "IC Partner Code" := SalesLine."IC Partner Code";
            "IC Partner G/L Acc. No." := SalesLine."IC Partner Reference";
            "IC Direction" := "IC Direction"::Outgoing;
            ICPartner.Get(SalesLine."IC Partner Code");
            if ICPartner."Cost Distribution in LCY" and (SalesLine."Currency Code" <> '') then begin
                "Currency Code" := '';
                "Currency Factor" := 0;
                Currency.Get(SalesLine."Currency Code");
                if SalesHeader.IsCreditDocType then
                    Amount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          SalesHeader."Posting Date", SalesLine."Currency Code",
                          SalesLine.Amount, SalesHeader."Currency Factor"))
                else
                    Amount :=
                      -Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          SalesHeader."Posting Date", SalesLine."Currency Code",
                          SalesLine.Amount, SalesHeader."Currency Factor"));
            end else begin
                Currency.InitRoundingPrecision;
                "Currency Code" := SalesHeader."Currency Code";
                "Currency Factor" := SalesHeader."Currency Factor";
                if SalesHeader.IsCreditDocType then
                    Amount := SalesLine.Amount
                else
                    Amount := -SalesLine.Amount;
            end;
            if "Bal. VAT %" <> 0 then
                Amount := Round(Amount * (1 + "Bal. VAT %" / 100), Currency."Amount Rounding Precision");
            Validate(Amount);
            OnBeforeInsertICGenJnlLine(TempICGenJnlLine, SalesHeader, SalesLine, SuppressCommit);
            Insert;
        end;
    end;

    local procedure PostICGenJnl()
    var
        ICInOutBoxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxExport: Codeunit "IC Outbox Export";
        ICTransactionNo: Integer;
    begin
        TempICGenJnlLine.Reset;
        TempICGenJnlLine.SetFilter(Amount, '<>%1', 0);
        if TempICGenJnlLine.Find('-') then
            repeat
                ICTransactionNo := ICInOutBoxMgt.CreateOutboxJnlTransaction(TempICGenJnlLine, false);
                ICInOutBoxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, TempICGenJnlLine);
                ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICTransactionNo);
                GenJnlPostLine.RunWithCheck(TempICGenJnlLine);
            until TempICGenJnlLine.Next = 0;
    end;

    local procedure TestGetShipmentPPmtAmtToDeduct()
    var
        TempSalesLine: Record "Sales Line" temporary;
        TempShippedSalesLine: Record "Sales Line" temporary;
        TempTotalSalesLine: Record "Sales Line" temporary;
        TempSalesShptLine: Record "Sales Shipment Line" temporary;
        SalesShptLine: Record "Sales Shipment Line";
        SalesOrderLine: Record "Sales Line";
        MaxAmtToDeduct: Decimal;
    begin
        with TempSalesLine do begin
            ResetTempLines(TempSalesLine);
            SetFilter(Quantity, '>0');
            SetFilter("Qty. to Invoice", '>0');
            SetFilter("Shipment No.", '<>%1', '');
            SetFilter("Prepmt Amt to Deduct", '<>0');
            if IsEmpty then
                exit;

            SetRange("Prepmt Amt to Deduct");
            if FindSet then
                repeat
                    if SalesShptLine.Get("Shipment No.", "Shipment Line No.") then begin
                        TempShippedSalesLine := TempSalesLine;
                        TempShippedSalesLine.Insert;
                        TempSalesShptLine := SalesShptLine;
                        if TempSalesShptLine.Insert then;

                        if not TempTotalSalesLine.Get("Document Type"::Order, SalesShptLine."Order No.", SalesShptLine."Order Line No.") then begin
                            TempTotalSalesLine.Init;
                            TempTotalSalesLine."Document Type" := "Document Type"::Order;
                            TempTotalSalesLine."Document No." := SalesShptLine."Order No.";
                            TempTotalSalesLine."Line No." := SalesShptLine."Order Line No.";
                            TempTotalSalesLine.Insert;
                        end;
                        TempTotalSalesLine."Qty. to Invoice" := TempTotalSalesLine."Qty. to Invoice" + "Qty. to Invoice";
                        TempTotalSalesLine."Prepmt Amt to Deduct" := TempTotalSalesLine."Prepmt Amt to Deduct" + "Prepmt Amt to Deduct";
                        AdjustInvLineWith100PctPrepmt(TempSalesLine, TempTotalSalesLine);
                        TempTotalSalesLine.Modify;
                    end;
                until Next = 0;

            if TempShippedSalesLine.FindSet then
                repeat
                    if TempSalesShptLine.Get(TempShippedSalesLine."Shipment No.", TempShippedSalesLine."Shipment Line No.") then
                        if SalesOrderLine.Get(
                             TempShippedSalesLine."Document Type"::Order, TempSalesShptLine."Order No.", TempSalesShptLine."Order Line No.")
                        then
                            if TempTotalSalesLine.Get(
                                 TempShippedSalesLine."Document Type"::Order, TempSalesShptLine."Order No.", TempSalesShptLine."Order Line No.")
                            then begin
                                MaxAmtToDeduct := SalesOrderLine."Prepmt. Amt. Inv." - SalesOrderLine."Prepmt Amt Deducted";

                                if TempTotalSalesLine."Prepmt Amt to Deduct" > MaxAmtToDeduct then
                                    Error(PrepAmountToDeductToBigErr, FieldCaption("Prepmt Amt to Deduct"), MaxAmtToDeduct);

                                if (TempTotalSalesLine."Qty. to Invoice" = SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced") and
                                   (TempTotalSalesLine."Prepmt Amt to Deduct" <> MaxAmtToDeduct)
                                then
                                    Error(PrepAmountToDeductToSmallErr, FieldCaption("Prepmt Amt to Deduct"), MaxAmtToDeduct);
                            end;
                until TempShippedSalesLine.Next = 0;
        end;
    end;

    local procedure AdjustInvLineWith100PctPrepmt(var SalesInvoiceLine: Record "Sales Line"; var TempTotalSalesLine: Record "Sales Line" temporary)
    var
        SalesOrderLine: Record "Sales Line";
        DiffAmtToDeduct: Decimal;
    begin
        if SalesInvoiceLine."Prepayment %" = 100 then begin
            SalesOrderLine := TempTotalSalesLine;
            SalesOrderLine.Find;
            if TempTotalSalesLine."Qty. to Invoice" = SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced" then begin
                DiffAmtToDeduct :=
                  SalesOrderLine."Prepmt. Amt. Inv." - SalesOrderLine."Prepmt Amt Deducted" - TempTotalSalesLine."Prepmt Amt to Deduct";
                if DiffAmtToDeduct <> 0 then begin
                    SalesInvoiceLine."Prepmt Amt to Deduct" := SalesInvoiceLine."Prepmt Amt to Deduct" + DiffAmtToDeduct;
                    SalesInvoiceLine."Line Amount" := SalesInvoiceLine."Prepmt Amt to Deduct";
                    SalesInvoiceLine."Line Discount Amount" := SalesInvoiceLine."Line Discount Amount" - DiffAmtToDeduct;
                    ModifyTempLine(SalesInvoiceLine);
                    TempTotalSalesLine."Prepmt Amt to Deduct" := TempTotalSalesLine."Prepmt Amt to Deduct" + DiffAmtToDeduct;
                end;
            end;
        end;
    end;

    procedure ArchiveUnpostedOrder(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveUnpostedOrder(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get;
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order"]) then
            exit;

        SalesSetup.Get;
        if (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) and not SalesSetup."Archive Orders" then
            exit;
        if (SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order") and not SalesSetup."Archive Return Orders" then
            exit;

        SalesLine.Reset;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Quantity, '<>0');
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            SalesLine.SetFilter("Qty. to Ship", '<>0')
        else
            SalesLine.SetFilter("Return Qty. to Receive", '<>0');
        if not SalesLine.IsEmpty and not PreviewMode then begin
            RoundDeferralsForArchive(SalesHeader, SalesLine);
            ArchiveManagement.ArchSalesDocumentNoConfirm(SalesHeader);
        end;
    end;

    local procedure SynchBOMSerialNo(var ServItemTmp3: Record "Service Item" temporary; var ServItemTmpCmp3: Record "Service Item Component" temporary)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        TempSalesShipMntLine: Record "Sales Shipment Line" temporary;
        ServItemTmpCmp4: Record "Service Item Component" temporary;
        ServItemCompLocal: Record "Service Item Component";
        TempItemLedgEntry2: Record "Item Ledger Entry" temporary;
        ChildCount: Integer;
        EndLoop: Boolean;
    begin
        if not ServItemTmpCmp3.Find('-') then
            exit;

        if not ServItemTmp3.Find('-') then
            exit;

        TempSalesShipMntLine.DeleteAll;
        repeat
            Clear(TempSalesShipMntLine);
            TempSalesShipMntLine."Document No." := ServItemTmp3."Sales/Serv. Shpt. Document No.";
            TempSalesShipMntLine."Line No." := ServItemTmp3."Sales/Serv. Shpt. Line No.";
            if TempSalesShipMntLine.Insert then;
        until ServItemTmp3.Next = 0;

        if not TempSalesShipMntLine.Find('-') then
            exit;

        ServItemTmp3.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        Clear(ItemLedgEntry);
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");

        repeat
            ChildCount := 0;
            ServItemTmpCmp4.DeleteAll;
            ServItemTmp3.SetRange("Sales/Serv. Shpt. Document No.", TempSalesShipMntLine."Document No.");
            ServItemTmp3.SetRange("Sales/Serv. Shpt. Line No.", TempSalesShipMntLine."Line No.");
            if ServItemTmp3.Find('-') then
                repeat
                    ServItemTmpCmp3.SetRange(Active, true);
                    ServItemTmpCmp3.SetRange("Parent Service Item No.", ServItemTmp3."No.");
                    if ServItemTmpCmp3.Find('-') then
                        repeat
                            ChildCount += 1;
                            ServItemTmpCmp4 := ServItemTmpCmp3;
                            ServItemTmpCmp4.Insert;
                        until ServItemTmpCmp3.Next = 0;
                until ServItemTmp3.Next = 0;
            ItemLedgEntry.SetRange("Document No.", TempSalesShipMntLine."Document No.");
            ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
            ItemLedgEntry.SetRange("Document Line No.", TempSalesShipMntLine."Line No.");
            if ItemLedgEntry.FindFirst and ServItemTmpCmp4.Find('-') then begin
                Clear(ItemLedgEntry2);
                ItemLedgEntry2.Get(ItemLedgEntry."Entry No.");
                EndLoop := false;
                repeat
                    if ItemLedgEntry2."Item No." = ServItemTmpCmp4."No." then
                        EndLoop := true
                    else
                        if ItemLedgEntry2.Next = 0 then
                            EndLoop := true;
                until EndLoop;
                ItemLedgEntry2.SetRange("Entry No.", ItemLedgEntry2."Entry No.", ItemLedgEntry2."Entry No." + ChildCount - 1);
                if ItemLedgEntry2.FindSet then
                    repeat
                        TempItemLedgEntry2 := ItemLedgEntry2;
                        TempItemLedgEntry2.Insert;
                    until ItemLedgEntry2.Next = 0;
                repeat
                    if ServItemCompLocal.Get(
                         ServItemTmpCmp4.Active,
                         ServItemTmpCmp4."Parent Service Item No.",
                         ServItemTmpCmp4."Line No.")
                    then begin
                        TempItemLedgEntry2.SetRange("Item No.", ServItemCompLocal."No.");
                        if TempItemLedgEntry2.FindFirst then begin
                            ServItemCompLocal."Serial No." := TempItemLedgEntry2."Serial No.";
                            ServItemCompLocal.Modify;
                            TempItemLedgEntry2.Delete;
                        end;
                    end;
                until ServItemTmpCmp4.Next = 0;
            end;
        until TempSalesShipMntLine.Next = 0;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get;
        GLSetupRead := true;
    end;

    local procedure LockTables(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
    begin
        OnBeforeLockTables(SalesHeader, PreviewMode, SuppressCommit);

        SalesLine.LockTable;
        ItemChargeAssgntSales.LockTable;
        PurchOrderLine.LockTable;
        PurchOrderHeader.LockTable;
        GetGLSetup;
        if not GLSetup.OptimGLEntLockForMultiuserEnv then begin
            GLEntry.LockTable;
            if GLEntry.FindLast then;
        end;
    end;

    local procedure PostCustomerEntry(var SalesHeader: Record "Sales Header"; TotalSalesLine2: Record "Sales Line"; TotalSalesLineLCY2: Record "Sales Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35]; SourceCode: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."Posting Description",
              SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
              SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

            CopyDocumentFields(DocType, DocNo, ExtDocNo, SourceCode, '');
            "Account Type" := "Account Type"::Customer;
            "Account No." := SalesHeader."Bill-to Customer No.";
            CopyFromSalesHeader(SalesHeader);
            SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");

            "System-Created Entry" := true;

            CopyFromSalesHeaderApplyTo(SalesHeader);
            CopyFromSalesHeaderPayment(SalesHeader);

            Amount := -TotalSalesLine2."Amount Including VAT";
            "Source Currency Amount" := -TotalSalesLine2."Amount Including VAT";
            "Amount (LCY)" := -TotalSalesLineLCY2."Amount Including VAT";
            "Sales/Purch. (LCY)" := -TotalSalesLineLCY2.Amount;
            "Profit (LCY)" := -(TotalSalesLineLCY2.Amount - TotalSalesLineLCY2."Unit Cost (LCY)");
            "Inv. Discount (LCY)" := -TotalSalesLineLCY2."Inv. Discount Amount";

            OnBeforePostCustomerEntry(GenJnlLine, SalesHeader, TotalSalesLine2, TotalSalesLineLCY2, SuppressCommit, PreviewMode);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostCustomerEntry(GenJnlLine, SalesHeader, TotalSalesLine2, TotalSalesLineLCY2, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure UpdateSalesHeader(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case GenJnlLineDocType of
            GenJnlLine."Document Type"::Invoice:
                begin
                    FindCustLedgEntry(GenJnlLineDocType, GenJnlLineDocNo, CustLedgerEntry);
                    SalesInvHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    SalesInvHeader.Modify;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    FindCustLedgEntry(GenJnlLineDocType, GenJnlLineDocNo, CustLedgerEntry);
                    SalesCrMemoHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    SalesCrMemoHeader.Modify;
                end;
        end;

        OnAfterUpdateSalesHeader(CustLedgerEntry, SalesInvHeader, SalesCrMemoHeader, GenJnlLineDocType);
    end;

    local procedure MakeSalesLineToShip(var SalesLineToShip: Record "Sales Line"; SalesLineInvoiced: Record "Sales Line")
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        ResetTempLines(TempSalesLine);
        TempSalesLine := SalesLineInvoiced;
        TempSalesLine.Find;

        SalesLineToShip := SalesLineInvoiced;
        SalesLineToShip."Inv. Discount Amount" := TempSalesLine."Inv. Discount Amount";
    end;

    local procedure "MAX"(number1: Integer; number2: Integer): Integer
    begin
        if number1 > number2 then
            exit(number1);
        exit(number2);
    end;

    local procedure PostBalancingEntry(SalesHeader: Record "Sales Header"; TotalSalesLine2: Record "Sales Line"; TotalSalesLineLCY2: Record "Sales Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35]; SourceCode: Code[10])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        EntryFound: Boolean;
    begin
        EntryFound := false;
        OnPostBalancingEntryOnBeforeFindCustLedgEntry(
          SalesHeader, TotalSalesLine2, DocType, DocNo, ExtDocNo, CustLedgEntry, EntryFound);
        if not EntryFound then
            FindCustLedgEntry(DocType, DocNo, CustLedgEntry);

        with GenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."Posting Description",
              SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
              SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

            CopyDocumentFields(0, DocNo, ExtDocNo, SourceCode, '');
            "Account Type" := "Account Type"::Customer;
            "Account No." := SalesHeader."Bill-to Customer No.";
            CopyFromSalesHeader(SalesHeader);
            SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");

            if SalesHeader.IsCreditDocType then
                "Document Type" := "Document Type"::Refund
            else
                "Document Type" := "Document Type"::Payment;

            SetApplyToDocNo(SalesHeader, GenJnlLine, DocType, DocNo);

            Amount := TotalSalesLine2."Amount Including VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
            "Source Currency Amount" := Amount;
            CustLedgEntry.CalcFields(Amount);
            if CustLedgEntry.Amount = 0 then
                "Amount (LCY)" := TotalSalesLineLCY2."Amount Including VAT"
            else
                "Amount (LCY)" :=
                  TotalSalesLineLCY2."Amount Including VAT" +
                  Round(CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");
            "Allow Zero-Amount Posting" := true;

            OnBeforePostBalancingEntry(GenJnlLine, SalesHeader, TotalSalesLine2, TotalSalesLineLCY2, SuppressCommit, PreviewMode);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostBalancingEntry(GenJnlLine, SalesHeader, TotalSalesLine2, TotalSalesLineLCY2, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure SetApplyToDocNo(SalesHeader: Record "Sales Header"; var GenJnlLine: Record "Gen. Journal Line"; DocType: Option; DocNo: Code[20])
    begin
        with GenJnlLine do begin
            if SalesHeader."Bal. Account Type" = SalesHeader."Bal. Account Type"::"Bank Account" then
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := SalesHeader."Bal. Account No.";
            "Applies-to Doc. Type" := DocType;
            "Applies-to Doc. No." := DocNo;
        end;

        OnAfterSetApplyToDocNo(GenJnlLine, SalesHeader);
    end;

    local procedure FindCustLedgEntry(DocType: Option; DocNo: Code[20]; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.SetRange("Document Type", DocType);
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast;
    end;

    local procedure ItemLedgerEntryExist(SalesLine2: Record "Sales Line"; ShipOrReceive: Boolean): Boolean
    var
        HasItemLedgerEntry: Boolean;
    begin
        if ShipOrReceive then
            // item ledger entry will be created during posting in this transaction
            HasItemLedgerEntry :=
            ((SalesLine2."Qty. to Ship" + SalesLine2."Quantity Shipped") <> 0) or
            ((SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced") <> 0) or
            ((SalesLine2."Return Qty. to Receive" + SalesLine2."Return Qty. Received") <> 0)
        else
            // item ledger entry must already exist
            HasItemLedgerEntry :=
            (SalesLine2."Quantity Shipped" <> 0) or
            (SalesLine2."Return Qty. Received" <> 0);

        exit(HasItemLedgerEntry);
    end;

    local procedure CheckPostRestrictions(SalesHeader: Record "Sales Header")
    var
        Contact: Record Contact;
    begin
        with SalesHeader do begin
            if not PreviewMode then
                OnCheckSalesPostRestrictions;

            CheckCustBlockage(SalesHeader, "Sell-to Customer No.", true);
            ValidateSalesPersonOnSalesHeader(SalesHeader, true, true);

            if "Bill-to Customer No." <> "Sell-to Customer No." then
                CheckCustBlockage(SalesHeader, "Bill-to Customer No.", false);

            if "Sell-to Contact No." <> '' then
                if Contact.Get("Sell-to Contact No.") then
                    Contact.CheckIfPrivacyBlocked(true);
            if "Bill-to Contact No." <> '' then
                if Contact.Get("Bill-to Contact No.") then
                    Contact.CheckIfPrivacyBlocked(true);
        end;
    end;

    local procedure CheckCustBlockage(SalesHeader: Record "Sales Header"; CustCode: Code[20]; ExecuteDocCheck: Boolean)
    var
        Cust: Record Customer;
        TempSalesLine: Record "Sales Line" temporary;
    begin
        with SalesHeader do begin
            Cust.Get(CustCode);
            if Receive then
                Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, true)
            else begin
                if Ship and CheckDocumentType(SalesHeader, ExecuteDocCheck) then begin
                    ResetTempLines(TempSalesLine);
                    TempSalesLine.SetFilter("Qty. to Ship", '<>0');
                    TempSalesLine.SetRange("Shipment No.", '');
                    if not TempSalesLine.IsEmpty then
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", true, true);
                end else
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, true);
            end;
        end;
    end;

    local procedure CheckDocumentType(SalesHeader: Record "Sales Header"; ExecuteDocCheck: Boolean): Boolean
    begin
        with SalesHeader do
            if ExecuteDocCheck then
                exit(
                  ("Document Type" = "Document Type"::Order) or
                  (("Document Type" = "Document Type"::Invoice) and SalesSetup."Shipment on Invoice"));
        exit(true);
    end;

    local procedure UpdateWonOpportunities(var SalesHeader: Record "Sales Header")
    var
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
    begin
        with SalesHeader do
            if "Document Type" = "Document Type"::Order then begin
                Opp.Reset;
                Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
                Opp.SetRange("Sales Document Type", Opp."Sales Document Type"::Order);
                Opp.SetRange("Sales Document No.", "No.");
                Opp.SetRange(Status, Opp.Status::Won);
                if Opp.FindFirst then begin
                    Opp."Sales Document Type" := Opp."Sales Document Type"::"Posted Invoice";
                    Opp."Sales Document No." := SalesInvHeader."No.";
                    Opp.Modify;
                    OpportunityEntry.Reset;
                    OpportunityEntry.SetCurrentKey(Active, "Opportunity No.");
                    OpportunityEntry.SetRange(Active, true);
                    OpportunityEntry.SetRange("Opportunity No.", Opp."No.");
                    if OpportunityEntry.FindFirst then begin
                        OpportunityEntry."Calcd. Current Value (LCY)" := OpportunityEntry.GetSalesDocValue(SalesHeader);
                        OpportunityEntry.Modify;
                    end;
                end;
            end;
    end;

    local procedure UpdateQtyToBeInvoicedForShipment(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; HasATOShippedNotInvoiced: Boolean; SalesLine: Record "Sales Line"; SalesShptLine: Record "Sales Shipment Line"; InvoicingTrackingSpecification: Record "Tracking Specification"; ItemLedgEntryNotInvoiced: Record "Item Ledger Entry")
    begin
        if TrackingSpecificationExists then begin
            QtyToBeInvoiced := InvoicingTrackingSpecification."Qty. to Invoice";
            QtyToBeInvoicedBase := InvoicingTrackingSpecification."Qty. to Invoice (Base)";
        end else
            if HasATOShippedNotInvoiced then begin
                QtyToBeInvoicedBase := ItemLedgEntryNotInvoiced.Quantity - ItemLedgEntryNotInvoiced."Invoiced Quantity";
                if Abs(QtyToBeInvoicedBase) > Abs(RemQtyToBeInvoicedBase) then
                    QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - SalesLine."Qty. to Ship (Base)";
                QtyToBeInvoiced := Round(QtyToBeInvoicedBase / SalesShptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            end else begin
                QtyToBeInvoiced := RemQtyToBeInvoiced - SalesLine."Qty. to Ship";
                QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - SalesLine."Qty. to Ship (Base)";
            end;

        if Abs(QtyToBeInvoiced) > Abs(SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced") then begin
            QtyToBeInvoiced := -(SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced");
            QtyToBeInvoicedBase := -(SalesShptLine."Quantity (Base)" - SalesShptLine."Qty. Invoiced (Base)");
        end;
    end;

    local procedure UpdateQtyToBeInvoicedForReturnReceipt(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; SalesLine: Record "Sales Line"; ReturnReceiptLine: Record "Return Receipt Line"; InvoicingTrackingSpecification: Record "Tracking Specification")
    begin
        if TrackingSpecificationExists then begin
            QtyToBeInvoiced := InvoicingTrackingSpecification."Qty. to Invoice";
            QtyToBeInvoicedBase := InvoicingTrackingSpecification."Qty. to Invoice (Base)";
        end else begin
            QtyToBeInvoiced := RemQtyToBeInvoiced - SalesLine."Return Qty. to Receive";
            QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - SalesLine."Return Qty. to Receive (Base)";
        end;
        if Abs(QtyToBeInvoiced) >
           Abs(ReturnReceiptLine.Quantity - ReturnReceiptLine."Quantity Invoiced")
        then begin
            QtyToBeInvoiced := ReturnReceiptLine.Quantity - ReturnReceiptLine."Quantity Invoiced";
            QtyToBeInvoicedBase := ReturnReceiptLine."Quantity (Base)" - ReturnReceiptLine."Qty. Invoiced (Base)";
        end;
    end;

    local procedure UpdateRemainingQtyToBeInvoiced(SalesShptLine: Record "Sales Shipment Line"; var RemQtyToInvoiceCurrLine: Decimal; var RemQtyToInvoiceCurrLineBase: Decimal)
    begin
        RemQtyToInvoiceCurrLine := -SalesShptLine.Quantity + SalesShptLine."Quantity Invoiced";
        RemQtyToInvoiceCurrLineBase := -SalesShptLine."Quantity (Base)" + SalesShptLine."Qty. Invoiced (Base)";
        if RemQtyToInvoiceCurrLine < RemQtyToBeInvoiced then begin
            RemQtyToInvoiceCurrLine := RemQtyToBeInvoiced;
            RemQtyToInvoiceCurrLineBase := RemQtyToBeInvoicedBase;
        end;
    end;

    local procedure IsEndLoopForShippedNotInvoiced(RemQtyToBeInvoiced: Decimal; TrackingSpecificationExists: Boolean; var HasATOShippedNotInvoiced: Boolean; var SalesShptLine: Record "Sales Shipment Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; var ItemLedgEntryNotInvoiced: Record "Item Ledger Entry"; SalesLine: Record "Sales Line"): Boolean
    begin
        if TrackingSpecificationExists then
            exit((InvoicingTrackingSpecification.Next = 0) or (RemQtyToBeInvoiced = 0));

        if HasATOShippedNotInvoiced then begin
            HasATOShippedNotInvoiced := ItemLedgEntryNotInvoiced.Next <> 0;
            if not HasATOShippedNotInvoiced then
                exit(not SalesShptLine.FindSet or (Abs(RemQtyToBeInvoiced) <= Abs(SalesLine."Qty. to Ship")));
            exit(Abs(RemQtyToBeInvoiced) <= Abs(SalesLine."Qty. to Ship"));
        end;

        exit((SalesShptLine.Next = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(SalesLine."Qty. to Ship")));
    end;

    procedure SetItemEntryRelation(var ItemEntryRelation: Record "Item Entry Relation"; var SalesShptLine: Record "Sales Shipment Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; var ItemLedgEntryNotInvoiced: Record "Item Ledger Entry"; TrackingSpecificationExists: Boolean; HasATOShippedNotInvoiced: Boolean)
    begin
        if TrackingSpecificationExists then begin
            ItemEntryRelation.Get(InvoicingTrackingSpecification."Item Ledger Entry No.");
            SalesShptLine.Get(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
        end else
            if HasATOShippedNotInvoiced then begin
                ItemEntryRelation."Item Entry No." := ItemLedgEntryNotInvoiced."Entry No.";
                SalesShptLine.Get(ItemLedgEntryNotInvoiced."Document No.", ItemLedgEntryNotInvoiced."Document Line No.");
            end else
                ItemEntryRelation."Item Entry No." := SalesShptLine."Item Shpt. Entry No.";
    end;

    local procedure PostATOAssocItemJnlLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var PostedATOLink: Record "Posted Assemble-to-Order Link"; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
    begin
        with PostedATOLink do begin
            DummyTrackingSpecification.Init;
            if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
                "Assembled Quantity" := -"Assembled Quantity";
                "Assembled Quantity (Base)" := -"Assembled Quantity (Base)";
                if Abs(RemQtyToBeInvoiced) >= Abs("Assembled Quantity") then begin
                    ItemLedgShptEntryNo :=
                      PostItemJnlLine(
                        SalesHeader, SalesLine,
                        "Assembled Quantity", "Assembled Quantity (Base)",
                        "Assembled Quantity", "Assembled Quantity (Base)",
                        0, '', DummyTrackingSpecification, true);
                    RemQtyToBeInvoiced -= "Assembled Quantity";
                    RemQtyToBeInvoicedBase -= "Assembled Quantity (Base)";
                end else begin
                    if RemQtyToBeInvoiced <> 0 then
                        ItemLedgShptEntryNo :=
                          PostItemJnlLine(
                            SalesHeader, SalesLine,
                            RemQtyToBeInvoiced,
                            RemQtyToBeInvoicedBase,
                            RemQtyToBeInvoiced,
                            RemQtyToBeInvoicedBase,
                            0, '', DummyTrackingSpecification, true);

                    ItemLedgShptEntryNo :=
                      PostItemJnlLine(
                        SalesHeader, SalesLine,
                        "Assembled Quantity" - RemQtyToBeInvoiced,
                        "Assembled Quantity (Base)" - RemQtyToBeInvoicedBase,
                        0, 0,
                        0, '', DummyTrackingSpecification, true);

                    RemQtyToBeInvoiced := 0;
                    RemQtyToBeInvoicedBase := 0;
                end;
            end;
        end;
    end;

    local procedure GetOpenLinkedATOs(var TempAsmHeader: Record "Assembly Header" temporary)
    var
        TempSalesLine: Record "Sales Line" temporary;
        AsmHeader: Record "Assembly Header";
    begin
        with TempSalesLine do begin
            ResetTempLines(TempSalesLine);
            if FindSet then
                repeat
                    if AsmToOrderExists(AsmHeader) then
                        if AsmHeader.Status = AsmHeader.Status::Open then begin
                            TempAsmHeader.TransferFields(AsmHeader);
                            TempAsmHeader.Insert;
                        end;
                until Next = 0;
        end;
    end;

    local procedure ReopenAsmOrders(var TempAsmHeader: Record "Assembly Header" temporary)
    var
        AsmHeader: Record "Assembly Header";
    begin
        if TempAsmHeader.Find('-') then
            repeat
                AsmHeader.Get(TempAsmHeader."Document Type", TempAsmHeader."No.");
                AsmHeader.Status := AsmHeader.Status::Open;
                AsmHeader.Modify;
            until TempAsmHeader.Next = 0;
    end;

    local procedure InitPostATO(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        AsmHeader: Record "Assembly Header";
        Window: Dialog;
    begin
        if SalesLine.AsmToOrderExists(AsmHeader) then begin
            if not HideProgressWindow then begin
                Window.Open(AssemblyCheckProgressMsg);
                Window.Update(1,
                  StrSubstNo('%1 %2 %3 %4',
                    SalesLine."Document Type", SalesLine."Document No.", SalesLine.FieldCaption("Line No."), SalesLine."Line No."));
                Window.Update(2, StrSubstNo('%1 %2', AsmHeader."Document Type", AsmHeader."No."));
            end;

            SalesLine.CheckAsmToOrder(AsmHeader);
            if not HasQtyToAsm(SalesLine, AsmHeader) then
                exit;

            AsmPost.SetPostingDate(true, SalesHeader."Posting Date");
            AsmPost.InitPostATO(AsmHeader);

            if not HideProgressWindow then
                Window.Close;
        end;
    end;

    local procedure InitPostATOs(SalesHeader: Record "Sales Header")
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        with TempSalesLine do begin
            FindNotShippedLines(SalesHeader, TempSalesLine);
            SetFilter("Qty. to Assemble to Order", '<>0');
            if FindSet then
                repeat
                    InitPostATO(SalesHeader, TempSalesLine);
                until Next = 0;
        end;
    end;

    local procedure PostATO(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempPostedATOLink: Record "Posted Assemble-to-Order Link" temporary)
    var
        AsmHeader: Record "Assembly Header";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        Window: Dialog;
    begin
        if SalesLine.AsmToOrderExists(AsmHeader) then begin
            if not HideProgressWindow then begin
                Window.Open(AssemblyPostProgressMsg);
                Window.Update(1,
                  StrSubstNo('%1 %2 %3 %4',
                    SalesLine."Document Type", SalesLine."Document No.", SalesLine.FieldCaption("Line No."), SalesLine."Line No."));
                Window.Update(2, StrSubstNo('%1 %2', AsmHeader."Document Type", AsmHeader."No."));
            end;

            SalesLine.CheckAsmToOrder(AsmHeader);
            if not HasQtyToAsm(SalesLine, AsmHeader) then
                exit;
            if AsmHeader."Remaining Quantity (Base)" = 0 then
                exit;

            PostedATOLink.Init;
            PostedATOLink."Assembly Document Type" := PostedATOLink."Assembly Document Type"::Assembly;
            PostedATOLink."Assembly Document No." := AsmHeader."Posting No.";
            PostedATOLink."Document Type" := PostedATOLink."Document Type"::"Sales Shipment";
            PostedATOLink."Document No." := SalesHeader."Shipping No.";
            PostedATOLink."Document Line No." := SalesLine."Line No.";

            PostedATOLink."Assembly Order No." := AsmHeader."No.";
            PostedATOLink."Order No." := SalesLine."Document No.";
            PostedATOLink."Order Line No." := SalesLine."Line No.";

            PostedATOLink."Assembled Quantity" := AsmHeader."Quantity to Assemble";
            PostedATOLink."Assembled Quantity (Base)" := AsmHeader."Quantity to Assemble (Base)";

            OnPostATOOnBeforePostedATOLinkInsert(PostedATOLink);
            PostedATOLink.Insert;

            TempPostedATOLink := PostedATOLink;
            TempPostedATOLink.Insert;

            AsmPost.PostATO(AsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlPostLine);

            if not HideProgressWindow then
                Window.Close;
        end;
    end;

    local procedure FinalizePostATO(var SalesLine: Record "Sales Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
        AsmHeader: Record "Assembly Header";
        Window: Dialog;
    begin
        if SalesLine.AsmToOrderExists(AsmHeader) then begin
            if not HideProgressWindow then begin
                Window.Open(AssemblyFinalizeProgressMsg);
                Window.Update(1,
                  StrSubstNo('%1 %2 %3 %4',
                    SalesLine."Document Type", SalesLine."Document No.", SalesLine.FieldCaption("Line No."), SalesLine."Line No."));
                Window.Update(2, StrSubstNo('%1 %2', AsmHeader."Document Type", AsmHeader."No."));
            end;

            SalesLine.CheckAsmToOrder(AsmHeader);
            AsmHeader.TestField("Remaining Quantity (Base)", 0);
            AsmPost.FinalizePostATO(AsmHeader);
            ATOLink.Get(AsmHeader."Document Type", AsmHeader."No.");
            ATOLink.Delete;

            if not HideProgressWindow then
                Window.Close;
        end;
    end;

    local procedure CheckATOLink(SalesLine: Record "Sales Line")
    var
        AsmHeader: Record "Assembly Header";
    begin
        if SalesLine."Qty. to Asm. to Order (Base)" = 0 then
            exit;
        if SalesLine.AsmToOrderExists(AsmHeader) then
            SalesLine.CheckAsmToOrder(AsmHeader);
    end;

    local procedure DeleteATOLinks(SalesHeader: Record "Sales Header")
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        with ATOLink do begin
            SetCurrentKey(Type, "Document Type", "Document No.");
            SetRange(Type, Type::Sale);
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            if not IsEmpty then
                DeleteAll;
        end;
    end;

    local procedure HasQtyToAsm(SalesLine: Record "Sales Line"; AsmHeader: Record "Assembly Header"): Boolean
    begin
        if SalesLine."Qty. to Asm. to Order (Base)" = 0 then
            exit(false);
        if SalesLine."Qty. to Ship (Base)" = 0 then
            exit(false);
        if AsmHeader."Quantity to Assemble (Base)" = 0 then
            exit(false);
        exit(true);
    end;

    local procedure GetATOItemLedgEntriesNotInvoiced(SalesLine: Record "Sales Line"; var ItemLedgEntryNotInvoiced: Record "Item Ledger Entry"): Boolean
    var
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntryNotInvoiced.Reset;
        ItemLedgEntryNotInvoiced.DeleteAll;
        if PostedATOLink.FindLinksFromSalesLine(SalesLine) then
            repeat
                ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
                ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
                ItemLedgEntry.SetRange("Document No.", PostedATOLink."Document No.");
                ItemLedgEntry.SetRange("Document Line No.", PostedATOLink."Document Line No.");
                ItemLedgEntry.SetRange("Assemble to Order", true);
                ItemLedgEntry.SetRange("Completely Invoiced", false);
                if ItemLedgEntry.FindSet then
                    repeat
                        if ItemLedgEntry.Quantity <> ItemLedgEntry."Invoiced Quantity" then begin
                            ItemLedgEntryNotInvoiced := ItemLedgEntry;
                            ItemLedgEntryNotInvoiced.Insert;
                        end;
                    until ItemLedgEntry.Next = 0;
            until PostedATOLink.Next = 0;

        exit(ItemLedgEntryNotInvoiced.FindSet);
    end;

    procedure SetWhseJnlRegisterCU(var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        WhseJnlPostLine := WhseJnlRegisterLine;
    end;

    local procedure PostWhseShptLines(var WhseShptLine2: Record "Warehouse Shipment Line"; SalesShptLine2: Record "Sales Shipment Line"; var SalesLine2: Record "Sales Line")
    var
        ATOWhseShptLine: Record "Warehouse Shipment Line";
        NonATOWhseShptLine: Record "Warehouse Shipment Line";
        ATOLineFound: Boolean;
        NonATOLineFound: Boolean;
        TotalSalesShptLineQty: Decimal;
    begin
        WhseShptLine2.GetATOAndNonATOLines(ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound);
        if ATOLineFound then
            TotalSalesShptLineQty += ATOWhseShptLine."Qty. to Ship";
        if NonATOLineFound then
            TotalSalesShptLineQty += NonATOWhseShptLine."Qty. to Ship";
        SalesShptLine2.TestField(Quantity, TotalSalesShptLineQty);

        SaveTempWhseSplitSpec(SalesLine2, TempATOTrackingSpecification);
        WhsePostShpt.SetWhseJnlRegisterCU(WhseJnlPostLine);
        if ATOLineFound and (ATOWhseShptLine."Qty. to Ship (Base)" > 0) then
            WhsePostShpt.CreatePostedShptLine(
              ATOWhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);

        SaveTempWhseSplitSpec(SalesLine2, TempHandlingSpecification);
        if NonATOLineFound and (NonATOWhseShptLine."Qty. to Ship (Base)" > 0) then
            WhsePostShpt.CreatePostedShptLine(
              NonATOWhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
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

    local procedure UpdateIncomingDocument(IncomingDocNo: Integer; PostingDate: Date; GenJnlLineDocNo: Code[20])
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocNo, PostingDate, GenJnlLineDocNo);
    end;

    local procedure CheckItemCharge(ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    var
        SalesLineForCharge: Record "Sales Line";
    begin
        with ItemChargeAssgntSales do
            case "Applies-to Doc. Type" of
                "Applies-to Doc. Type"::Order,
              "Applies-to Doc. Type"::Invoice:
                    if SalesLineForCharge.Get(
                         "Applies-to Doc. Type",
                         "Applies-to Doc. No.",
                         "Applies-to Doc. Line No.")
                    then
                        if (SalesLineForCharge."Quantity (Base)" = SalesLineForCharge."Qty. Shipped (Base)") and
                           (SalesLineForCharge."Qty. Shipped Not Invd. (Base)" = 0)
                        then
                            Error(ReassignItemChargeErr);
                "Applies-to Doc. Type"::"Return Order",
              "Applies-to Doc. Type"::"Credit Memo":
                    if SalesLineForCharge.Get(
                         "Applies-to Doc. Type",
                         "Applies-to Doc. No.",
                         "Applies-to Doc. Line No.")
                    then
                        if (SalesLineForCharge."Quantity (Base)" = SalesLineForCharge."Return Qty. Received (Base)") and
                           (SalesLineForCharge."Ret. Qty. Rcd. Not Invd.(Base)" = 0)
                        then
                            Error(ReassignItemChargeErr);
            end;
    end;

    local procedure CheckItemReservDisruption(SalesLine: Record "Sales Line")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        AvailableQty: Decimal;
    begin
        with SalesLine do begin
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) or
               (Type <> Type::Item) or not ("Qty. to Ship (Base)" > 0)
            then
                exit;
            if ("Job Contract Entry No." <> 0) or
               Nonstock or "Special Order" or "Drop Shipment" or
               IsNonInventoriableItem or FullQtyIsForAsmToOrder or
               TempSKU.Get("Location Code", "No.", "Variant Code") // Warn against item
            then
                exit;

            Item.SetFilter("Location Filter", "Location Code");
            Item.SetFilter("Variant Filter", "Variant Code");
            Item.CalcFields("Reserved Qty. on Inventory", "Net Change");
            CalcFields("Reserved Qty. (Base)");
            AvailableQty := Item."Net Change" - (Item."Reserved Qty. on Inventory" - "Reserved Qty. (Base)");

            if (Item."Reserved Qty. on Inventory" > 0) and
               (AvailableQty < "Qty. to Ship (Base)") and
               (Item."Reserved Qty. on Inventory" > "Reserved Qty. (Base)")
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

    procedure InitProgressWindow(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.Invoice then
            Window.Open(
              '#1#################################\\' +
              PostingLinesMsg +
              PostingSalesAndVATMsg +
              PostingCustomersMsg +
              PostingBalAccountMsg)
        else
            Window.Open(
              '#1#################################\\' +
              PostingLines2Msg);

        Window.Update(1, StrSubstNo('%1 %2', SalesHeader."Document Type", SalesHeader."No."));
    end;

    local procedure CheckCertificateOfSupplyStatus(SalesShptHeader: Record "Sales Shipment Header"; SalesShptLine: Record "Sales Shipment Line")
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

    local procedure HasSpecificTracking(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(ItemNo);
        if Item."Item Tracking Code" <> '' then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            exit(ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking");
        end;
    end;

    local procedure HasInvtPickLine(SalesLine: Record "Sales Line"): Boolean
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        with WhseActivityLine do begin
            SetRange("Activity Type", "Activity Type"::"Invt. Pick");
            SetRange("Source Type", DATABASE::"Sales Line");
            SetRange("Source Subtype", SalesLine."Document Type");
            SetRange("Source No.", SalesLine."Document No.");
            SetRange("Source Line No.", SalesLine."Line No.");
            exit(not IsEmpty);
        end;
    end;

    local procedure InsertPostedHeaders(var SalesHeader: Record "Sales Header")
    var
        SalesShptLine: Record "Sales Shipment Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        GenJnlLine: Record "Gen. Journal Line";
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        IsHandled: Boolean;
    begin
        if PreviewMode then
            PostingPreviewEventHandler.PreventCommit;

        OnBeforeInsertPostedHeaders(SalesHeader, TempWhseShptHeader, TempWhseRcptHeader);

        with SalesHeader do begin
            // Insert shipment header
            if Ship then begin
                if ("Document Type" = "Document Type"::Order) or
                   (("Document Type" = "Document Type"::Invoice) and SalesSetup."Shipment on Invoice")
                then begin
                    if DropShipOrder then begin
                        PurchRcptHeader.LockTable;
                        PurchRcptLine.LockTable;
                        SalesShptHeader.LockTable;
                        SalesShptLine.LockTable;
                    end;
                    InsertShipmentHeader(SalesHeader, SalesShptHeader);
                end;

                ServItemMgt.CopyReservationEntry(SalesHeader);
                if ("Document Type" = "Document Type"::Invoice) and
                   (not SalesSetup."Shipment on Invoice")
                then
                    ServItemMgt.CreateServItemOnSalesInvoice(SalesHeader);
            end;

            ServItemMgt.DeleteServItemOnSaleCreditMemo(SalesHeader);

            // Insert return receipt header
            if Receive then
                if ("Document Type" = "Document Type"::"Return Order") or
                   (("Document Type" = "Document Type"::"Credit Memo") and SalesSetup."Return Receipt on Credit Memo")
                then
                    InsertReturnReceiptHeader(SalesHeader, ReturnRcptHeader);

            IsHandled := false;
            OnInsertPostedHeadersOnBeforeInsertInvoiceHeader(SalesHeader, IsHandled);
            if not IsHandled then
                // Insert invoice header or credit memo header
                if Invoice then
                    if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
                        InsertInvoiceHeader(SalesHeader, SalesInvHeader);
                        GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                        GenJnlLineDocNo := SalesInvHeader."No.";
                        GenJnlLineExtDocNo := SalesInvHeader."External Document No.";
                    end else begin // Credit Memo
                        InsertCrMemoHeader(SalesHeader, SalesCrMemoHeader);
                        GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                        GenJnlLineDocNo := SalesCrMemoHeader."No.";
                        GenJnlLineExtDocNo := SalesCrMemoHeader."External Document No.";
                    end;
        end;
    end;

    local procedure InsertShipmentHeader(var SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        with SalesHeader do begin
            SalesShptHeader.Init;
            CalcFields("Work Description");
            SalesShptHeader.TransferFields(SalesHeader);

            SalesShptHeader."No." := "Shipping No.";
            if "Document Type" = "Document Type"::Order then begin
                SalesShptHeader."Order No. Series" := "No. Series";
                SalesShptHeader."Order No." := "No.";
                if SalesSetup."Ext. Doc. No. Mandatory" then
                    TestField("External Document No.");
            end;
            SalesShptHeader."Source Code" := SrcCode;
            SalesShptHeader."User ID" := UserId;
            SalesShptHeader."No. Printed" := 0;
            OnBeforeSalesShptHeaderInsert(SalesShptHeader, SalesHeader, SuppressCommit);
            SalesShptHeader.Insert(true);
            OnAfterSalesShptHeaderInsert(SalesShptHeader, SalesHeader, SuppressCommit);

            ApprovalsMgmt.PostApprovalEntries(RecordId, SalesShptHeader.RecordId, SalesShptHeader."No.");

            if SalesSetup."Copy Comments Order to Shpt." then begin
                SalesCommentLine.CopyComments(
                  "Document Type", SalesCommentLine."Document Type"::Shipment, "No.", SalesShptHeader."No.");
                RecordLinkManagement.CopyLinks(SalesHeader, SalesShptHeader);
            end;
            if WhseShip then begin
                WhseShptHeader.Get(TempWhseShptHeader."No.");
                OnBeforeCreatePostedWhseShptHeader(PostedWhseShptHeader, WhseShptHeader, SalesHeader);
                WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, "Shipping No.", "Posting Date");
            end;
            if WhseReceive then begin
                WhseRcptHeader.Get(TempWhseRcptHeader."No.");
                OnBeforeCreatePostedWhseRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, SalesHeader);
                WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, "Shipping No.", "Posting Date");
            end;
        end;
    end;

    local procedure InsertReturnReceiptHeader(var SalesHeader: Record "Sales Header"; var ReturnRcptHeader: Record "Return Receipt Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        OnBeforeInsertReturnReceiptHeader(SalesHeader, ReturnRcptHeader, IsHandled, SuppressCommit);

        with SalesHeader do begin
            if not IsHandled then begin
                ReturnRcptHeader.Init;
                ReturnRcptHeader.TransferFields(SalesHeader);
                ReturnRcptHeader."No." := "Return Receipt No.";
                if "Document Type" = "Document Type"::"Return Order" then begin
                    ReturnRcptHeader."Return Order No. Series" := "No. Series";
                    ReturnRcptHeader."Return Order No." := "No.";
                    if SalesSetup."Ext. Doc. No. Mandatory" then
                        TestField("External Document No.");
                end;
                ReturnRcptHeader."No. Series" := "Return Receipt No. Series";
                ReturnRcptHeader."Source Code" := SrcCode;
                ReturnRcptHeader."User ID" := UserId;
                ReturnRcptHeader."No. Printed" := 0;
                OnBeforeReturnRcptHeaderInsert(ReturnRcptHeader, SalesHeader, SuppressCommit);
                ReturnRcptHeader.Insert(true);
                OnAfterReturnRcptHeaderInsert(ReturnRcptHeader, SalesHeader, SuppressCommit);

                ApprovalsMgmt.PostApprovalEntries(RecordId, ReturnRcptHeader.RecordId, ReturnRcptHeader."No.");

                if SalesSetup."Copy Cmts Ret.Ord. to Ret.Rcpt" then begin
                    SalesCommentLine.CopyComments(
                      "Document Type", SalesCommentLine."Document Type"::"Posted Return Receipt", "No.", ReturnRcptHeader."No.");
                    RecordLinkManagement.CopyLinks(SalesHeader, ReturnRcptHeader);
                end;
            end;

            if WhseReceive then begin
                WhseRcptHeader.Get(TempWhseRcptHeader."No.");
                OnBeforeCreatePostedWhseRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, SalesHeader);
                WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, "Return Receipt No.", "Posting Date");
            end;
            if WhseShip then begin
                WhseShptHeader.Get(TempWhseShptHeader."No.");
                OnBeforeCreatePostedWhseShptHeader(PostedWhseShptHeader, WhseShptHeader, SalesHeader);
                WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, "Return Receipt No.", "Posting Date");
            end;
        end;
    end;

    local procedure InsertInvoiceHeader(var SalesHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        SegManagement: Codeunit SegManagement;
    begin
        with SalesHeader do begin
            SalesInvHeader.Init;
            CalcFields("Work Description");
            SalesInvHeader.TransferFields(SalesHeader);

            SalesInvHeader."No." := "Posting No.";
            if "Document Type" = "Document Type"::Order then begin
                if SalesSetup."Ext. Doc. No. Mandatory" then
                    TestField("External Document No.");
                SalesInvHeader."Pre-Assigned No. Series" := '';
                SalesInvHeader."Order No. Series" := "No. Series";
                SalesInvHeader."Order No." := "No.";
            end else begin
                if "Posting No." = '' then
                    SalesInvHeader."No." := "No.";
                SalesInvHeader."Pre-Assigned No. Series" := "No. Series";
                SalesInvHeader."Pre-Assigned No." := "No.";
            end;
            if GuiAllowed and not HideProgressWindow then
                Window.Update(1, StrSubstNo(InvoiceNoMsg, "Document Type", "No.", SalesInvHeader."No."));
            SalesInvHeader."Source Code" := SrcCode;
            SalesInvHeader."User ID" := UserId;
            SalesInvHeader."No. Printed" := 0;
            SalesInvHeader."Draft Invoice SystemId" := SalesHeader.SystemId;
            SetPaymentInstructions(SalesHeader);
            OnBeforeSalesInvHeaderInsert(SalesInvHeader, SalesHeader, SuppressCommit);
            SalesInvHeader.Insert(true);
            OnAfterSalesInvHeaderInsert(SalesInvHeader, SalesHeader, SuppressCommit);

            UpdateWonOpportunities(SalesHeader);
            SegManagement.CreateCampaignEntryOnSalesInvoicePosting(SalesInvHeader);

            ApprovalsMgmt.PostApprovalEntries(RecordId, SalesInvHeader.RecordId, SalesInvHeader."No.");

            if SalesSetup."Copy Comments Order to Invoice" then begin
                SalesCommentLine.CopyComments(
                  "Document Type", SalesCommentLine."Document Type"::"Posted Invoice", "No.", SalesInvHeader."No.");
                RecordLinkManagement.CopyLinks(SalesHeader, SalesInvHeader);
            end;
        end;
    end;

    local procedure InsertCrMemoHeader(var SalesHeader: Record "Sales Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        with SalesHeader do begin
            SalesCrMemoHeader.Init;
            CalcFields("Work Description");
            SalesCrMemoHeader.TransferFields(SalesHeader);
            if "Document Type" = "Document Type"::"Return Order" then begin
                SalesCrMemoHeader."No." := "Posting No.";
                if SalesSetup."Ext. Doc. No. Mandatory" then
                    TestField("External Document No.");
                SalesCrMemoHeader."Pre-Assigned No. Series" := '';
                SalesCrMemoHeader."Return Order No. Series" := "No. Series";
                SalesCrMemoHeader."Return Order No." := "No.";
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(1, StrSubstNo(CreditMemoNoMsg, "Document Type", "No.", SalesCrMemoHeader."No."));
            end else begin
                SalesCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
                SalesCrMemoHeader."Pre-Assigned No." := "No.";
                if "Posting No." <> '' then begin
                    SalesCrMemoHeader."No." := "Posting No.";
                    if GuiAllowed and not HideProgressWindow then
                        Window.Update(1, StrSubstNo(CreditMemoNoMsg, "Document Type", "No.", SalesCrMemoHeader."No."));
                end;
            end;
            SalesCrMemoHeader."Source Code" := SrcCode;
            SalesCrMemoHeader."User ID" := UserId;
            SalesCrMemoHeader."No. Printed" := 0;
            SalesCrMemoHeader."Draft Cr. Memo SystemId" := SalesCrMemoHeader.SystemId;
            OnBeforeSalesCrMemoHeaderInsert(SalesCrMemoHeader, SalesHeader, SuppressCommit);
            SalesCrMemoHeader.Insert(true);
            OnAfterSalesCrMemoHeaderInsert(SalesCrMemoHeader, SalesHeader, SuppressCommit);

            ApprovalsMgmt.PostApprovalEntries(RecordId, SalesCrMemoHeader.RecordId, SalesCrMemoHeader."No.");

            if SalesSetup."Copy Cmts Ret.Ord. to Cr. Memo" then begin
                SalesCommentLine.CopyComments(
                  "Document Type", SalesCommentLine."Document Type"::"Posted Credit Memo", "No.", SalesCrMemoHeader."No.");
                RecordLinkManagement.CopyLinks(SalesHeader, SalesCrMemoHeader);
            end;
        end;
    end;

    local procedure InsertPurchRcptHeader(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        with PurchRcptHeader do begin
            Init;
            TransferFields(PurchaseHeader);
            "No." := PurchaseHeader."Receiving No.";
            "Order No." := PurchaseHeader."No.";
            "Posting Date" := SalesHeader."Posting Date";
            "Document Date" := SalesHeader."Document Date";
            "No. Printed" := 0;
            OnBeforePurchRcptHeaderInsert(PurchRcptHeader, PurchaseHeader, SalesHeader, SuppressCommit);
            Insert;
            OnAfterPurchRcptHeaderInsert(PurchRcptHeader, PurchaseHeader, SalesHeader, SuppressCommit);
        end;
    end;

    local procedure InsertPurchRcptLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchOrderLine: Record "Purchase Line"; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        with PurchRcptLine do begin
            Init;
            TransferFields(PurchOrderLine);
            "Posting Date" := PurchRcptHeader."Posting Date";
            "Document No." := PurchRcptHeader."No.";
            Quantity := DropShptPostBuffer.Quantity;
            "Quantity (Base)" := DropShptPostBuffer."Quantity (Base)";
            "Quantity Invoiced" := 0;
            "Qty. Invoiced (Base)" := 0;
            "Order No." := PurchOrderLine."Document No.";
            "Order Line No." := PurchOrderLine."Line No.";
            "Qty. Rcd. Not Invoiced" := Quantity - "Quantity Invoiced";
            if Quantity <> 0 then begin
                "Item Rcpt. Entry No." := DropShptPostBuffer."Item Shpt. Entry No.";
                "Item Charge Base Amount" := PurchOrderLine."Line Amount"
            end;
            OnBeforePurchRcptLineInsert(PurchRcptLine, PurchRcptHeader, PurchOrderLine, DropShptPostBuffer, SuppressCommit);
            Insert;
            OnAfterPurchRcptLineInsert(PurchRcptLine, PurchRcptHeader, PurchOrderLine, DropShptPostBuffer, SuppressCommit);
        end;
    end;

    local procedure InsertShipmentLine(SalesHeader: Record "Sales Header"; SalesShptHeader: Record "Sales Shipment Header"; SalesLine: Record "Sales Line"; CostBaseAmount: Decimal; var TempServiceItem2: Record "Service Item" temporary; var TempServiceItemComp2: Record "Service Item Component" temporary)
    var
        SalesShptLine: Record "Sales Shipment Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        TempServiceItem1: Record "Service Item" temporary;
        TempServiceItemComp1: Record "Service Item Component" temporary;
    begin
        SalesShptLine.InitFromSalesLine(SalesShptHeader, xSalesLine);
        SalesShptLine."Quantity Invoiced" := -RemQtyToBeInvoiced;
        SalesShptLine."Qty. Invoiced (Base)" := -RemQtyToBeInvoicedBase;
        SalesShptLine."Qty. Shipped Not Invoiced" := SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced";

        if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."Qty. to Ship" <> 0) then begin
            if WhseShip then
                if WhseShptLine.GetWhseShptLine(
                     WhseShptHeader."No.", DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
                then
                    PostWhseShptLines(WhseShptLine, SalesShptLine, SalesLine);

            if WhseReceive then
                if WhseRcptLine.GetWhseRcptLine(
                     WhseRcptHeader."No.", DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
                then begin
                    WhseRcptLine.TestField("Qty. to Receive", -SalesShptLine.Quantity);
                    SaveTempWhseSplitSpec(SalesLine, TempHandlingSpecification);
                    WhsePostRcpt.CreatePostedRcptLine(
                      WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                end;

            SalesShptLine."Item Shpt. Entry No." :=
              InsertShptEntryRelation(SalesShptLine); // ItemLedgShptEntryNo
            SalesShptLine."Item Charge Base Amount" :=
              Round(CostBaseAmount / SalesLine.Quantity * SalesShptLine.Quantity);
        end;
        OnBeforeSalesShptLineInsert(
          SalesShptLine, SalesShptHeader, SalesLine, SuppressCommit, PostedWhseShptLine, SalesHeader, WhseShip, WhseReceive,
          ItemLedgShptEntryNo);
        SalesShptLine.Insert(true);
        OnAfterSalesShptLineInsert(
          SalesShptLine, SalesLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit, SalesInvHeader);

        CheckCertificateOfSupplyStatus(SalesShptHeader, SalesShptLine);

        OnInvoiceSalesShptLine(SalesShptLine, SalesInvHeader."No.", xSalesLine."Line No.", xSalesLine."Qty. to Invoice", SuppressCommit);

        ServItemMgt.CreateServItemOnSalesLineShpt(SalesHeader, xSalesLine, SalesShptLine);
        if SalesLine."BOM Item No." <> '' then begin
            ServItemMgt.ReturnServItemComp(TempServiceItem1, TempServiceItemComp1);
            if TempServiceItem1.FindSet then
                repeat
                    TempServiceItem2 := TempServiceItem1;
                    if TempServiceItem2.Insert then;
                until TempServiceItem1.Next = 0;
            if TempServiceItemComp1.FindSet then
                repeat
                    TempServiceItemComp2 := TempServiceItemComp1;
                    if TempServiceItemComp2.Insert then;
                until TempServiceItemComp1.Next = 0;
        end;
    end;

    local procedure InsertReturnReceiptLine(ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line"; CostBaseAmount: Decimal)
    var
        ReturnRcptLine: Record "Return Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        OnBeforeInsertReturnReceiptLine(SalesLine, ReturnRcptLine, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase);
        ReturnRcptLine.InitFromSalesLine(ReturnRcptHeader, xSalesLine);
        ReturnRcptLine."Quantity Invoiced" := RemQtyToBeInvoiced;
        ReturnRcptLine."Qty. Invoiced (Base)" := RemQtyToBeInvoicedBase;
        ReturnRcptLine."Return Qty. Rcd. Not Invd." := ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";

        if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."Return Qty. to Receive" <> 0) then begin
            if WhseReceive then
                if WhseRcptLine.GetWhseRcptLine(
                     WhseRcptHeader."No.", DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
                then begin
                    WhseRcptLine.TestField("Qty. to Receive", ReturnRcptLine.Quantity);
                    SaveTempWhseSplitSpec(SalesLine, TempHandlingSpecification);
                    WhsePostRcpt.CreatePostedRcptLine(
                      WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                end;

            if WhseShip then
                if WhseShptLine.GetWhseShptLine(
                     WhseShptHeader."No.", DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
                then begin
                    WhseShptLine.TestField("Qty. to Ship", -ReturnRcptLine.Quantity);
                    SaveTempWhseSplitSpec(SalesLine, TempHandlingSpecification);
                    WhsePostShpt.SetWhseJnlRegisterCU(WhseJnlPostLine);
                    WhsePostShpt.CreatePostedShptLine(
                      WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                end;

            ReturnRcptLine."Item Rcpt. Entry No." :=
              InsertReturnEntryRelation(ReturnRcptLine); // ItemLedgShptEntryNo;
            ReturnRcptLine."Item Charge Base Amount" :=
              Round(CostBaseAmount / SalesLine.Quantity * ReturnRcptLine.Quantity);
        end;
        OnBeforeReturnRcptLineInsert(ReturnRcptLine, ReturnRcptHeader, SalesLine, SuppressCommit);
        ReturnRcptLine.Insert(true);
        OnAfterReturnRcptLineInsert(
          ReturnRcptLine, ReturnRcptHeader, SalesLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit, SalesCrMemoHeader);
    end;

    local procedure CheckICPartnerBlocked(SalesHeader: Record "Sales Header")
    var
        ICPartner: Record "IC Partner";
    begin
        with SalesHeader do begin
            if "Sell-to IC Partner Code" <> '' then
                if ICPartner.Get("Sell-to IC Partner Code") then
                    ICPartner.TestField(Blocked, false);
            if "Bill-to IC Partner Code" <> '' then
                if ICPartner.Get("Bill-to IC Partner Code") then
                    ICPartner.TestField(Blocked, false);
        end;
    end;

    local procedure SendICDocument(var SalesHeader: Record "Sales Header"; var ModifyHeader: Boolean)
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendICDocument(SalesHeader, ModifyHeader, IsHandled);
        if IsHandled then
            exit;

        with SalesHeader do
            if "Send IC Document" and ("IC Status" = "IC Status"::New) and ("IC Direction" = "IC Direction"::Outgoing) and
               ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"])
            then begin
                ICInboxOutboxMgt.SendSalesDoc(SalesHeader, true);
                "IC Status" := "IC Status"::Pending;
                ModifyHeader := true;
            end;
    end;

    local procedure UpdateHandledICInboxTransaction(SalesHeader: Record "Sales Header")
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateHandledICInboxTransaction(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        with SalesHeader do
            if "IC Direction" = "IC Direction"::Incoming then begin
                HandledICInboxTrans.SetRange("Document No.", "External Document No.");
                Customer.Get("Sell-to Customer No.");
                HandledICInboxTrans.SetRange("IC Partner Code", Customer."IC Partner Code");
                HandledICInboxTrans.LockTable;
                if HandledICInboxTrans.FindFirst then begin
                    HandledICInboxTrans.Status := HandledICInboxTrans.Status::Posted;
                    HandledICInboxTrans.Modify;
                end;
            end;
    end;

    procedure GetPostedDocumentRecord(SalesHeader: Record "Sales Header"; var PostedSalesDocumentVariant: Variant)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        with SalesHeader do
            case "Document Type" of
                "Document Type"::Order:
                    if Invoice then begin
                        SalesInvHeader.Get("Last Posting No.");
                        SalesInvHeader.SetRecFilter;
                        PostedSalesDocumentVariant := SalesInvHeader;
                    end;
                "Document Type"::Invoice:
                    begin
                        if "Last Posting No." = '' then
                            SalesInvHeader.Get("No.")
                        else
                            SalesInvHeader.Get("Last Posting No.");

                        SalesInvHeader.SetRecFilter;
                        PostedSalesDocumentVariant := SalesInvHeader;
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        if "Last Posting No." = '' then
                            SalesCrMemoHeader.Get("No.")
                        else
                            SalesCrMemoHeader.Get("Last Posting No.");
                        SalesCrMemoHeader.SetRecFilter;
                        PostedSalesDocumentVariant := SalesCrMemoHeader;
                    end;
                "Document Type"::"Return Order":
                    if Invoice then begin
                        if "Last Posting No." = '' then
                            SalesCrMemoHeader.Get("No.")
                        else
                            SalesCrMemoHeader.Get("Last Posting No.");
                        SalesCrMemoHeader.SetRecFilter;
                        PostedSalesDocumentVariant := SalesCrMemoHeader;
                    end;
                else begin
                        IsHandled := false;
                        OnGetPostedDocumentRecordElseCase(SalesHeader, PostedSalesDocumentVariant, IsHandled);
                        if not IsHandled then
                            Error(NotSupportedDocumentTypeErr, "Document Type");
                    end;
            end;
    end;

    [Scope('OnPrem')]
    procedure SendPostedDocumentRecord(SalesHeader: Record "Sales Header"; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        OfficeManagement: Codeunit "Office Management";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        with SalesHeader do
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        OnSendSalesDocument(Invoice and Ship, SuppressCommit);
                        if Invoice then begin
                            SalesInvHeader.Get("Last Posting No.");
                            SalesInvHeader.SetRecFilter;
                            SalesInvHeader.SendProfile(DocumentSendingProfile);
                        end;
                        if Ship and Invoice and not OfficeManagement.IsAvailable then
                            if not ConfirmManagement.GetResponseOrDefault(DownloadShipmentAlsoQst, true) then
                                exit;
                        if Ship then begin
                            SalesShipmentHeader.Get("Last Shipping No.");
                            SalesShipmentHeader.SetRecFilter;
                            SalesShipmentHeader.SendProfile(DocumentSendingProfile);
                        end;
                    end;
                "Document Type"::Invoice:
                    begin
                        if "Last Posting No." = '' then
                            SalesInvHeader.Get("No.")
                        else
                            SalesInvHeader.Get("Last Posting No.");

                        SalesInvHeader.SetRecFilter;
                        SalesInvHeader.SendProfile(DocumentSendingProfile);
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        if "Last Posting No." = '' then
                            SalesCrMemoHeader.Get("No.")
                        else
                            SalesCrMemoHeader.Get("Last Posting No.");
                        SalesCrMemoHeader.SetRecFilter;
                        SalesCrMemoHeader.SendProfile(DocumentSendingProfile);
                    end;
                "Document Type"::"Return Order":
                    if Invoice then begin
                        if "Last Posting No." = '' then
                            SalesCrMemoHeader.Get("No.")
                        else
                            SalesCrMemoHeader.Get("Last Posting No.");
                        SalesCrMemoHeader.SetRecFilter;
                        SalesCrMemoHeader.SendProfile(DocumentSendingProfile);
                    end;
                else begin
                        IsHandled := false;
                        OnSendPostedDocumentRecordElseCase(SalesHeader, DocumentSendingProfile, IsHandled);
                        if not IsHandled then
                            Error(NotSupportedDocumentTypeErr, "Document Type");
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
            InvtAdjmt.SetJobUpdateProperties(true);
            InvtAdjmt.MakeMultiLevelAdjmt;
        end;
    end;

    local procedure FindNotShippedLines(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
        with TempSalesLine do begin
            ResetTempLines(TempSalesLine);
            SetFilter(Quantity, '<>0');
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                SetFilter("Qty. to Ship", '<>0');
            SetRange("Shipment No.", '');
        end;
    end;

    local procedure CheckTrackingAndWarehouseForShip(SalesHeader: Record "Sales Header") Ship: Boolean
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        with TempSalesLine do begin
            FindNotShippedLines(SalesHeader, TempSalesLine);
            Ship := FindFirst;
            WhseShip := TempWhseShptHeader.FindFirst;
            WhseReceive := TempWhseRcptHeader.FindFirst;
            OnCheckTrackingAndWarehouseForShipOnBeforeCheck(SalesHeader, TempWhseShptHeader, TempWhseRcptHeader, Ship, TempSalesLine);
            if Ship then begin
                CheckTrackingSpecification(SalesHeader, TempSalesLine);
                if not (WhseShip or WhseReceive or InvtPickPutaway) then
                    CheckWarehouse(TempSalesLine);
            end;
            OnAfterCheckTrackingAndWarehouseForShip(SalesHeader, Ship, SuppressCommit, TempWhseShptHeader, TempWhseRcptHeader, TempSalesLine);
            exit(Ship);
        end;
    end;

    local procedure CheckTrackingAndWarehouseForReceive(SalesHeader: Record "Sales Header") Receive: Boolean
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        with TempSalesLine do begin
            ResetTempLines(TempSalesLine);
            SetFilter(Quantity, '<>0');
            SetFilter("Return Qty. to Receive", '<>0');
            SetRange("Return Receipt No.", '');
            Receive := FindFirst;
            WhseShip := TempWhseShptHeader.FindFirst;
            WhseReceive := TempWhseRcptHeader.FindFirst;
            OnCheckTrackingAndWarehouseForReceiveOnBeforeCheck(SalesHeader, TempWhseShptHeader, TempWhseRcptHeader, Receive);
            if Receive then begin
                CheckTrackingSpecification(SalesHeader, TempSalesLine);
                if not (WhseReceive or WhseShip or InvtPickPutaway) then
                    CheckWarehouse(TempSalesLine);
            end;
            OnAfterCheckTrackingAndWarehouseForReceive(SalesHeader, Receive, SuppressCommit, TempWhseShptHeader, TempWhseRcptHeader);
            exit(Receive);
        end;
    end;

    local procedure CheckIfInvPickExists(SalesHeader: Record "Sales Header"): Boolean
    var
        TempSalesLine: Record "Sales Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        with TempSalesLine do begin
            FindNotShippedLines(SalesHeader, TempSalesLine);
            if IsEmpty then
                exit(false);
            FindSet;
            repeat
                if WarehouseActivityLine.ActivityExists(
                     DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0,
                     WarehouseActivityLine."Activity Type"::"Invt. Pick")
                then
                    exit(true);
            until Next = 0;
            exit(false);
        end;
    end;

    local procedure CheckIfInvPutawayExists(): Boolean
    var
        TempSalesLine: Record "Sales Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        with TempSalesLine do begin
            ResetTempLines(TempSalesLine);
            SetFilter(Quantity, '<>0');
            SetFilter("Return Qty. to Receive", '<>0');
            SetRange("Return Receipt No.", '');
            if IsEmpty then
                exit(false);
            FindSet;
            repeat
                if WarehouseActivityLine.ActivityExists(
                     DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0,
                     WarehouseActivityLine."Activity Type"::"Invt. Put-away")
                then
                    exit(true);
            until Next = 0;
            exit(false);
        end;
    end;

    local procedure CalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostBuffer.CalcDiscountNoVAT(-SalesLine."Inv. Discount Amount", -SalesLineACY."Inv. Discount Amount")
        else
            InvoicePostBuffer.CalcDiscount(
              SalesHeader."Prices Including VAT", -SalesLine."Inv. Discount Amount", -SalesLineACY."Inv. Discount Amount");
    end;

    local procedure CalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostBuffer.CalcDiscountNoVAT(-SalesLine."Line Discount Amount", -SalesLineACY."Line Discount Amount")
        else
            InvoicePostBuffer.CalcDiscount(
              SalesHeader."Prices Including VAT", -SalesLine."Line Discount Amount", -SalesLineACY."Line Discount Amount");
    end;

    local procedure FindTempItemChargeAssgntSales(SalesLineNo: Integer): Boolean
    begin
        ClearItemChargeAssgntFilter;
        TempItemChargeAssgntSales.SetCurrentKey("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SetRange("Document Line No.", SalesLineNo);
        exit(TempItemChargeAssgntSales.FindSet);
    end;

    local procedure UpdateInvoicedQtyOnShipmentLine(var SalesShptLine: Record "Sales Shipment Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
        with SalesShptLine do begin
            "Quantity Invoiced" := "Quantity Invoiced" - QtyToBeInvoiced;
            "Qty. Invoiced (Base)" := "Qty. Invoiced (Base)" - QtyToBeInvoicedBase;
            "Qty. Shipped Not Invoiced" := Quantity - "Quantity Invoiced";
            Modify;
        end;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure PostDropOrderShipment(var SalesHeader: Record "Sales Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        OnBeforePostDropOrderShipment(SalesHeader, TempDropShptPostBuffer);

        ArchivePurchaseOrders(TempDropShptPostBuffer);
        with SalesHeader do
            if TempDropShptPostBuffer.FindSet then begin
                PurchSetup.Get;
                repeat
                    PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, TempDropShptPostBuffer."Order No.");
                    InsertPurchRcptHeader(PurchOrderHeader, SalesHeader, PurchRcptHeader);
                    ApprovalsMgmt.PostApprovalEntries(RecordId, PurchRcptHeader.RecordId, PurchRcptHeader."No.");
                    if PurchSetup."Copy Comments Order to Receipt" then begin
                        PurchCommentLine.CopyComments(
                          PurchOrderHeader."Document Type", PurchCommentLine."Document Type"::Receipt,
                          PurchOrderHeader."No.", PurchRcptHeader."No.");
                        RecordLinkManagement.CopyLinks(PurchOrderHeader, PurchRcptHeader);
                    end;
                    TempDropShptPostBuffer.SetRange("Order No.", TempDropShptPostBuffer."Order No.");
                    repeat
                        PurchOrderLine.Get(
                          PurchOrderLine."Document Type"::Order,
                          TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
                        InsertPurchRcptLine(PurchRcptHeader, PurchOrderLine, TempDropShptPostBuffer);
                        PurchPost.UpdateBlanketOrderLine(PurchOrderLine, true, false, false);
                    until TempDropShptPostBuffer.Next = 0;
                    TempDropShptPostBuffer.SetRange("Order No.");
                    OnAfterInsertDropOrderPurchRcptHeader(PurchRcptHeader);
                until TempDropShptPostBuffer.Next = 0;
            end;
    end;

    local procedure PostInvoicePostBuffer(SalesHeader: Record "Sales Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    var
        LineCount: Integer;
        GLEntryNo: Integer;
    begin
        OnBeforePostInvoicePostBuffer(SalesHeader, TempInvoicePostBuffer, TotalSalesLine, TotalSalesLineLCY);

        LineCount := 0;
        if TempInvoicePostBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                GLEntryNo := PostInvoicePostBufferLine(SalesHeader, TempInvoicePostBuffer);

                if (TempInvoicePostBuffer."Job No." <> '') and
                   (TempInvoicePostBuffer.Type = TempInvoicePostBuffer.Type::"G/L Account")
                then
                    JobPostLine.PostSalesGLAccounts(TempInvoicePostBuffer, GLEntryNo);

            until TempInvoicePostBuffer.Next(-1) = 0;

        TempInvoicePostBuffer.DeleteAll;
    end;

    local procedure PostInvoicePostBufferLine(SalesHeader: Record "Sales Header"; InvoicePostBuffer: Record "Invoice Post. Buffer") GLEntryNo: Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", InvoicePostBuffer."Entry Description",
              InvoicePostBuffer."Global Dimension 1 Code", InvoicePostBuffer."Global Dimension 2 Code",
              InvoicePostBuffer."Dimension Set ID", SalesHeader."Reason Code");

            CopyDocumentFields(GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, '');

            CopyFromSalesHeader(SalesHeader);

            CopyFromInvoicePostBuffer(InvoicePostBuffer);
            if InvoicePostBuffer.Type <> InvoicePostBuffer.Type::"Prepmt. Exch. Rate Difference" then
                "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
                "FA Posting Type" := "FA Posting Type"::Disposal;
                CopyFromInvoicePostBufferFA(InvoicePostBuffer);
            end;

            OnBeforePostInvPostBuffer(GenJnlLine, InvoicePostBuffer, SalesHeader, SuppressCommit, GenJnlPostLine, PreviewMode);
            GLEntryNo := RunGenJnlPostLine(GenJnlLine);
            OnAfterPostInvPostBuffer(GenJnlLine, InvoicePostBuffer, SalesHeader, GLEntryNo, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure PostItemTracking(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TrackingSpecificationExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean)
    var
        QtyToInvoiceBaseInTrackingSpec: Decimal;
    begin
        with SalesHeader do begin
            if TrackingSpecificationExists then begin
                TempTrackingSpecification.CalcSums("Qty. to Invoice (Base)");
                QtyToInvoiceBaseInTrackingSpec := TempTrackingSpecification."Qty. to Invoice (Base)";
                if not TempTrackingSpecification.FindFirst then
                    TempTrackingSpecification.Init;
            end;

            if SalesLine.IsCreditDocType then begin
                if (Abs(RemQtyToBeInvoiced) > Abs(SalesLine."Return Qty. to Receive")) or
                   (Abs(RemQtyToBeInvoiced) >= Abs(QtyToInvoiceBaseInTrackingSpec)) and (QtyToInvoiceBaseInTrackingSpec <> 0)
                then
                    PostItemTrackingForReceipt(
                      SalesHeader, SalesLine, TrackingSpecificationExists, TempTrackingSpecification);

                if Abs(RemQtyToBeInvoiced) > Abs(SalesLine."Return Qty. to Receive") then begin
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        Error(InvoiceGreaterThanReturnReceiptErr, SalesLine."Return Receipt No.");
                    Error(ReturnReceiptLinesDeletedErr);
                end;
            end else begin
                if (Abs(RemQtyToBeInvoiced) > Abs(SalesLine."Qty. to Ship")) or
                   (Abs(RemQtyToBeInvoiced) >= Abs(QtyToInvoiceBaseInTrackingSpec)) and (QtyToInvoiceBaseInTrackingSpec <> 0)
                then
                    PostItemTrackingForShipment(
                      SalesHeader, SalesLine, TrackingSpecificationExists, TempTrackingSpecification,
                      TempItemLedgEntryNotInvoiced, HasATOShippedNotInvoiced);

                if Abs(RemQtyToBeInvoiced) > Abs(SalesLine."Qty. to Ship") then begin
                    if "Document Type" = "Document Type"::Invoice then
                        Error(QuantityToInvoiceGreaterErr, SalesLine."Shipment No.");
                    Error(ShipmentLinesDeletedErr);
                end;
            end;
        end;
    end;

    local procedure PostItemTrackingForReceipt(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TrackingSpecificationExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        ReturnRcptLine: Record "Return Receipt Line";
        SalesShptLine: Record "Sales Shipment Line";
        EndLoop: Boolean;
        QtyToBeInvoiced: Decimal;
        QtyToBeInvoicedBase: Decimal;
    begin
        with SalesHeader do begin
            EndLoop := false;
            ReturnRcptLine.Reset;
            case "Document Type" of
                "Document Type"::"Return Order":
                    begin
                        ReturnRcptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                        ReturnRcptLine.SetRange("Return Order No.", SalesLine."Document No.");
                        ReturnRcptLine.SetRange("Return Order Line No.", SalesLine."Line No.");
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        ReturnRcptLine.SetRange("Document No.", SalesLine."Return Receipt No.");
                        ReturnRcptLine.SetRange("Line No.", SalesLine."Return Receipt Line No.");
                    end;
            end;
            ReturnRcptLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
            OnPostItemTrackingForReceiptOnAfterSetFilters(ReturnRcptLine, SalesHeader, SalesLine);
            if ReturnRcptLine.Find('-') then begin
                ItemJnlRollRndg := true;
                repeat
                    if TrackingSpecificationExists then begin  // Item Tracking
                        ItemEntryRelation.Get(TempTrackingSpecification."Item Ledger Entry No.");
                        ReturnRcptLine.Get(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                    end else
                        ItemEntryRelation."Item Entry No." := ReturnRcptLine."Item Rcpt. Entry No.";
                    ReturnRcptLine.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
                    ReturnRcptLine.TestField(Type, SalesLine.Type);
                    ReturnRcptLine.TestField("No.", SalesLine."No.");
                    ReturnRcptLine.TestField("Gen. Bus. Posting Group", SalesLine."Gen. Bus. Posting Group");
                    ReturnRcptLine.TestField("Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group");
                    ReturnRcptLine.TestField("Job No.", SalesLine."Job No.");
                    ReturnRcptLine.TestField("Unit of Measure Code", SalesLine."Unit of Measure Code");
                    ReturnRcptLine.TestField("Variant Code", SalesLine."Variant Code");
                    if SalesLine."Qty. to Invoice" * ReturnRcptLine.Quantity < 0 then
                        SalesLine.FieldError("Qty. to Invoice", ReturnReceiptSameSignErr);
                    UpdateQtyToBeInvoicedForReturnReceipt(
                      QtyToBeInvoiced, QtyToBeInvoicedBase,
                      TrackingSpecificationExists, SalesLine, ReturnRcptLine, TempTrackingSpecification);

                    if TrackingSpecificationExists then begin
                        TempTrackingSpecification."Quantity actual Handled (Base)" := QtyToBeInvoicedBase;
                        TempTrackingSpecification.Modify;
                    end;

                    if TrackingSpecificationExists then
                        ItemTrackingMgt.AdjustQuantityRounding(
                          RemQtyToBeInvoiced, QtyToBeInvoiced,
                          RemQtyToBeInvoicedBase, QtyToBeInvoicedBase);

                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                    ReturnRcptLine."Quantity Invoiced" :=
                      ReturnRcptLine."Quantity Invoiced" + QtyToBeInvoiced;
                    ReturnRcptLine."Qty. Invoiced (Base)" :=
                      ReturnRcptLine."Qty. Invoiced (Base)" + QtyToBeInvoicedBase;
                    ReturnRcptLine."Return Qty. Rcd. Not Invd." :=
                      ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";

                    OnPostItemTrackingForReceiptOnBeforeReturnRcptLineModify(SalesHeader, ReturnRcptLine);
                    ReturnRcptLine.Modify;

                    OnBeforePostItemTrackingReturnRcpt(
                      SalesInvHeader, SalesShptLine, TempTrackingSpecification, TrackingSpecificationExists,
                      SalesCrMemoHeader, ReturnRcptLine, SalesLine, QtyToBeInvoiced, QtyToBeInvoicedBase);

                    if PostItemTrackingForReceiptCondition(SalesLine, ReturnRcptLine) then
                        PostItemJnlLine(
                          SalesHeader, SalesLine, 0, 0, QtyToBeInvoiced, QtyToBeInvoicedBase,
                          ItemEntryRelation."Item Entry No.", '', TempTrackingSpecification, false);

                    OnAfterPostItemTrackingReturnRcpt(
                      SalesInvHeader, SalesShptLine, TempTrackingSpecification, TrackingSpecificationExists,
                      SalesCrMemoHeader, ReturnRcptLine, SalesLine, QtyToBeInvoiced, QtyToBeInvoicedBase);

                    if TrackingSpecificationExists then
                        EndLoop := (TempTrackingSpecification.Next = 0) or (RemQtyToBeInvoiced = 0)
                    else
                        EndLoop :=
                          (ReturnRcptLine.Next = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(SalesLine."Return Qty. to Receive"));
                until EndLoop;
            end else
                Error(
                  ReturnReceiptInvoicedErr,
                  SalesLine."Return Receipt Line No.", SalesLine."Return Receipt No.");
        end;
    end;

    local procedure PostItemTrackingForReceiptCondition(SalesLine: Record "Sales Line"; ReturnRcptLine: Record "Return Receipt Line"): Boolean
    var
        Condition: Boolean;
    begin
        Condition := SalesLine.Type = SalesLine.Type::Item;
        OnBeforePostItemTrackingForReceiptCondition(SalesLine, ReturnRcptLine, Condition);
        exit(Condition);
    end;

    local procedure PostItemTrackingForShipment(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TrackingSpecificationExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        SalesShptLine: Record "Sales Shipment Line";
        RemQtyToInvoiceCurrLine: Decimal;
        RemQtyToInvoiceCurrLineBase: Decimal;
        QtyToBeInvoiced: Decimal;
        QtyToBeInvoicedBase: Decimal;
    begin
        with SalesHeader do begin
            SalesShptLine.Reset;
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        SalesShptLine.SetCurrentKey("Order No.", "Order Line No.");
                        SalesShptLine.SetRange("Order No.", SalesLine."Document No.");
                        SalesShptLine.SetRange("Order Line No.", SalesLine."Line No.");
                    end;
                "Document Type"::Invoice:
                    begin
                        SalesShptLine.SetRange("Document No.", SalesLine."Shipment No.");
                        SalesShptLine.SetRange("Line No.", SalesLine."Shipment Line No.");
                    end;
            end;

            if not TrackingSpecificationExists then
                HasATOShippedNotInvoiced := GetATOItemLedgEntriesNotInvoiced(SalesLine, TempItemLedgEntryNotInvoiced);

            SalesShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
            if SalesShptLine.FindFirst then begin
                ItemJnlRollRndg := true;
                repeat
                    SetItemEntryRelation(
                      ItemEntryRelation, SalesShptLine,
                      TempTrackingSpecification, TempItemLedgEntryNotInvoiced,
                      TrackingSpecificationExists, HasATOShippedNotInvoiced);

                    UpdateRemainingQtyToBeInvoiced(SalesShptLine, RemQtyToInvoiceCurrLine, RemQtyToInvoiceCurrLineBase);

                    SalesShptLine.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
                    SalesShptLine.TestField(Type, SalesLine.Type);
                    SalesShptLine.TestField("No.", SalesLine."No.");
                    SalesShptLine.TestField("Gen. Bus. Posting Group", SalesLine."Gen. Bus. Posting Group");
                    SalesShptLine.TestField("Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group");
                    SalesShptLine.TestField("Job No.", SalesLine."Job No.");
                    SalesShptLine.TestField("Unit of Measure Code", SalesLine."Unit of Measure Code");
                    SalesShptLine.TestField("Variant Code", SalesLine."Variant Code");
                    if -SalesLine."Qty. to Invoice" * SalesShptLine.Quantity < 0 then
                        SalesLine.FieldError("Qty. to Invoice", ShipmentSameSignErr);

                    UpdateQtyToBeInvoicedForShipment(
                      QtyToBeInvoiced, QtyToBeInvoicedBase,
                      TrackingSpecificationExists, HasATOShippedNotInvoiced,
                      SalesLine, SalesShptLine,
                      TempTrackingSpecification, TempItemLedgEntryNotInvoiced);

                    if TrackingSpecificationExists then begin
                        TempTrackingSpecification."Quantity actual Handled (Base)" := QtyToBeInvoicedBase;
                        TempTrackingSpecification.Modify;
                    end;

                    if TrackingSpecificationExists or HasATOShippedNotInvoiced then
                        ItemTrackingMgt.AdjustQuantityRounding(
                          RemQtyToInvoiceCurrLine, QtyToBeInvoiced,
                          RemQtyToInvoiceCurrLineBase, QtyToBeInvoicedBase);

                    RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                    RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                    OnBeforeUpdateInvoicedQtyOnShipmentLine(SalesShptLine, SalesLine, SalesHeader, SalesInvHeader, SuppressCommit);
                    UpdateInvoicedQtyOnShipmentLine(SalesShptLine, QtyToBeInvoiced, QtyToBeInvoicedBase);
                    OnInvoiceSalesShptLine(SalesShptLine, SalesInvHeader."No.", SalesLine."Line No.", -QtyToBeInvoiced, SuppressCommit);

                    OnBeforePostItemTrackingForShipment(
                      SalesInvHeader, SalesShptLine, TempTrackingSpecification, TrackingSpecificationExists, SalesLine,
                      QtyToBeInvoiced, QtyToBeInvoicedBase);

                    if PostItemTrackingForShipmentCondition(SalesLine, SalesShptLine) then
                        PostItemJnlLine(
                          SalesHeader, SalesLine, 0, 0, QtyToBeInvoiced, QtyToBeInvoicedBase,
                          ItemEntryRelation."Item Entry No.", '', TempTrackingSpecification, false);

                    OnAfterPostItemTrackingForShipment(
                      SalesInvHeader, SalesShptLine, TempTrackingSpecification, TrackingSpecificationExists, SalesLine,
                      QtyToBeInvoiced, QtyToBeInvoicedBase);
                until IsEndLoopForShippedNotInvoiced(
                        RemQtyToBeInvoiced, TrackingSpecificationExists, HasATOShippedNotInvoiced,
                        SalesShptLine, TempTrackingSpecification, TempItemLedgEntryNotInvoiced, SalesLine);
            end else
                Error(
                  ShipmentInvoiceErr, SalesLine."Shipment Line No.", SalesLine."Shipment No.");
        end;
    end;

    local procedure PostItemTrackingForShipmentCondition(SalesLine: Record "Sales Line"; SalesShptLine: Record "Sales Shipment Line"): Boolean
    var
        Condition: Boolean;
    begin
        Condition := SalesLine.Type = SalesLine.Type::Item;
        OnBeforePostItemTrackingForShipmentCondition(SalesLine, SalesShptLine, Condition);
        exit(Condition);
    end;

    local procedure PostUpdateOrderLine(SalesHeader: Record "Sales Header")
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        OnBeforePostUpdateOrderLine(SalesHeader, TempSalesLineGlobal, SuppressCommit);

        ResetTempLines(TempSalesLine);
        with TempSalesLine do begin
            SetRange("Prepayment Line", false);
            SetFilter(Quantity, '<>0');
            if FindSet then
                repeat
                    OnPostUpdateOrderLineOnBeforeInitTempSalesLineQuantities(SalesHeader, TempSalesLine);
                    if SalesHeader.Ship then begin
                        "Quantity Shipped" += "Qty. to Ship";
                        "Qty. Shipped (Base)" += "Qty. to Ship (Base)";
                    end;
                    if SalesHeader.Receive then begin
                        "Return Qty. Received" += "Return Qty. to Receive";
                        "Return Qty. Received (Base)" += "Return Qty. to Receive (Base)";
                    end;
                    if SalesHeader.Invoice then begin
                        if "Document Type" = "Document Type"::Order then begin
                            if Abs("Quantity Invoiced" + "Qty. to Invoice") > Abs("Quantity Shipped") then begin
                                Validate("Qty. to Invoice", "Quantity Shipped" - "Quantity Invoiced");
                                "Qty. to Invoice (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
                            end
                        end else
                            if Abs("Quantity Invoiced" + "Qty. to Invoice") > Abs("Return Qty. Received") then begin
                                Validate("Qty. to Invoice", "Return Qty. Received" - "Quantity Invoiced");
                                "Qty. to Invoice (Base)" := "Return Qty. Received (Base)" - "Qty. Invoiced (Base)";
                            end;

                        "Quantity Invoiced" += "Qty. to Invoice";
                        "Qty. Invoiced (Base)" += "Qty. to Invoice (Base)";
                        if "Qty. to Invoice" <> 0 then begin
                            "Prepmt Amt Deducted" += "Prepmt Amt to Deduct";
                            "Prepmt VAT Diff. Deducted" += "Prepmt VAT Diff. to Deduct";
                            DecrementPrepmtAmtInvLCY(
                              TempSalesLine, "Prepmt. Amount Inv. (LCY)", "Prepmt. VAT Amount Inv. (LCY)");
                            "Prepmt Amt to Deduct" := "Prepmt. Amt. Inv." - "Prepmt Amt Deducted";
                            "Prepmt VAT Diff. to Deduct" := 0;
                        end;
                    end;

                    UpdateBlanketOrderLine(TempSalesLine, SalesHeader.Ship, SalesHeader.Receive, SalesHeader.Invoice);

                    OnPostUpdateOrderLineOnBeforeInitOutstanding(SalesHeader, TempSalesLine);

                    InitOutstanding;
                    CheckATOLink(TempSalesLine);
                    if WhseHandlingRequired(TempSalesLine) or
                       (SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank)
                    then begin
                        if "Document Type" = "Document Type"::"Return Order" then begin
                            "Return Qty. to Receive" := 0;
                            "Return Qty. to Receive (Base)" := 0;
                        end else begin
                            "Qty. to Ship" := 0;
                            "Qty. to Ship (Base)" := 0;
                        end;
                        InitQtyToInvoice;
                    end else begin
                        if "Document Type" = "Document Type"::"Return Order" then
                            InitQtyToReceive
                        else
                            InitQtyToShip2;
                    end;

                    if ("Purch. Order Line No." <> 0) and (Quantity = "Quantity Invoiced") then
                        UpdateAssocLines(TempSalesLine);
                    SetDefaultQuantity;
                    OnBeforePostUpdateOrderLineModifyTempLine(TempSalesLine, WhseShip, WhseReceive, SuppressCommit);
                    ModifyTempLine(TempSalesLine);
                    OnAfterPostUpdateOrderLineModifyTempLine(TempSalesLine, WhseShip, WhseReceive, SuppressCommit);
                until Next = 0;
        end;
    end;

    local procedure PostUpdateInvoiceLine()
    var
        SalesOrderLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesOrderHeader: Record "Sales Header" temporary;
        CRMSalesDocumentPostingMgt: Codeunit "CRM Sales Document Posting Mgt";
    begin
        ResetTempLines(TempSalesLine);
        with TempSalesLine do begin
            SetFilter("Shipment No.", '<>%1', '');
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet then
                repeat
                    SalesShptLine.Get("Shipment No.", "Shipment Line No.");
                    SalesOrderLine.Get(
                      SalesOrderLine."Document Type"::Order,
                      SalesShptLine."Order No.", SalesShptLine."Order Line No.");
                    if Type = Type::"Charge (Item)" then
                        UpdateSalesOrderChargeAssgnt(TempSalesLine, SalesOrderLine);
                    SalesOrderLine."Quantity Invoiced" += "Qty. to Invoice";
                    SalesOrderLine."Qty. Invoiced (Base)" += "Qty. to Invoice (Base)";
                    if Abs(SalesOrderLine."Quantity Invoiced") > Abs(SalesOrderLine."Quantity Shipped") then
                        Error(InvoiceMoreThanShippedErr, SalesOrderLine."Document No.");
                    SalesOrderLine.InitQtyToInvoice;
                    if SalesOrderLine."Prepayment %" <> 0 then begin
                        SalesOrderLine."Prepmt Amt Deducted" += "Prepmt Amt to Deduct";
                        SalesOrderLine."Prepmt VAT Diff. Deducted" += "Prepmt VAT Diff. to Deduct";
                        DecrementPrepmtAmtInvLCY(
                          TempSalesLine, SalesOrderLine."Prepmt. Amount Inv. (LCY)", SalesOrderLine."Prepmt. VAT Amount Inv. (LCY)");
                        SalesOrderLine."Prepmt Amt to Deduct" :=
                          SalesOrderLine."Prepmt. Amt. Inv." - SalesOrderLine."Prepmt Amt Deducted";
                        SalesOrderLine."Prepmt VAT Diff. to Deduct" := 0;
                    end;
                    SalesOrderLine.InitOutstanding;
                    SalesOrderLine.Modify;
                    if not TempSalesOrderHeader.Get(SalesOrderLine."Document Type", SalesOrderLine."Document No.") then begin
                        TempSalesOrderHeader."Document Type" := SalesOrderLine."Document Type";
                        TempSalesOrderHeader."No." := SalesOrderLine."Document No.";
                        TempSalesOrderHeader.Insert;
                    end;
                until Next = 0;
            CRMSalesDocumentPostingMgt.CheckShippedOrders(TempSalesOrderHeader);
        end;
    end;

    local procedure PostUpdateReturnReceiptLine()
    var
        SalesOrderLine: Record "Sales Line";
        ReturnRcptLine: Record "Return Receipt Line";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        ResetTempLines(TempSalesLine);
        with TempSalesLine do begin
            SetFilter("Return Receipt No.", '<>%1', '');
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet then
                repeat
                    ReturnRcptLine.Get("Return Receipt No.", "Return Receipt Line No.");
                    SalesOrderLine.Get(
                      SalesOrderLine."Document Type"::"Return Order",
                      ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.");
                    if Type = Type::"Charge (Item)" then
                        UpdateSalesOrderChargeAssgnt(TempSalesLine, SalesOrderLine);
                    SalesOrderLine."Quantity Invoiced" += "Qty. to Invoice";
                    SalesOrderLine."Qty. Invoiced (Base)" += "Qty. to Invoice (Base)";
                    if Abs(SalesOrderLine."Quantity Invoiced") > Abs(SalesOrderLine."Return Qty. Received") then
                        Error(InvoiceMoreThanReceivedErr, SalesOrderLine."Document No.");
                    SalesOrderLine.InitQtyToInvoice;
                    SalesOrderLine.InitOutstanding;
                    SalesOrderLine.Modify;
                until Next = 0;
        end;
    end;

    local procedure FillDeferralPostingBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostBuffer: Record "Invoice Post. Buffer"; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; SalesAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(SalesLine."Deferral Code");

        if TempDeferralHeader.Get(DeferralUtilities.GetSalesDeferralDocType, '', '',
             SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            if TempDeferralHeader."Amount to Defer" <> 0 then begin
                DeferralUtilities.FilterDeferralLines(
                  TempDeferralLine, DeferralUtilities.GetSalesDeferralDocType, '', '',
                  SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

                // Remainder\Initial deferral pair
                DeferralPostBuffer.PrepareSales(SalesLine, GenJnlLineDocNo);
                DeferralPostBuffer."Posting Date" := SalesHeader."Posting Date";
                DeferralPostBuffer.Description := SalesHeader."Posting Description";
                DeferralPostBuffer."Period Description" := DeferralTemplate."Period Description";
                DeferralPostBuffer."Deferral Line No." := InvDefLineNo;
                DeferralPostBuffer.PrepareInitialPair(
                  InvoicePostBuffer, RemainAmtToDefer, RemainAmtToDeferACY, SalesAccount, DeferralAccount);
                DeferralPostBuffer.Update(DeferralPostBuffer, InvoicePostBuffer);
                if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
                    DeferralPostBuffer.PrepareRemainderSales(
                      SalesLine, RemainAmtToDefer, RemainAmtToDeferACY, SalesAccount, DeferralAccount, InvDefLineNo);
                    DeferralPostBuffer.Update(DeferralPostBuffer, InvoicePostBuffer);
                end;

                // Add the deferral lines for each period to the deferral posting buffer merging when they are the same
                if TempDeferralLine.FindSet then
                    repeat
                        if (TempDeferralLine."Amount (LCY)" <> 0) or (TempDeferralLine.Amount <> 0) then begin
                            DeferralPostBuffer.PrepareSales(SalesLine, GenJnlLineDocNo);
                            DeferralPostBuffer.InitFromDeferralLine(TempDeferralLine);
                            if not SalesLine.IsCreditDocType then
                                DeferralPostBuffer.ReverseAmounts;
                            DeferralPostBuffer."G/L Account" := SalesAccount;
                            DeferralPostBuffer."Deferral Account" := DeferralAccount;
                            DeferralPostBuffer."Period Description" := DeferralTemplate."Period Description";
                            DeferralPostBuffer."Deferral Line No." := InvDefLineNo;
                            DeferralPostBuffer.Update(DeferralPostBuffer, InvoicePostBuffer);
                        end else
                            Error(ZeroDeferralAmtErr, SalesLine."No.", SalesLine."Deferral Code");

                    until TempDeferralLine.Next = 0

                else
                    Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code");
            end else
                Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code")
        end else
            Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code");
    end;

    local procedure RoundDeferralsForArchive(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        ArchiveManagement.RoundSalesDeferralsForArchive(SalesHeader, SalesLine);
    end;

    local procedure GetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(SalesLine."Deferral Code");
        DeferralTemplate.TestField("Deferral Account");
        DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(DeferralUtilities.GetSalesDeferralDocType, '', '',
             SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            AmtToDeferACY := TempDeferralHeader."Amount to Defer";
            AmtToDefer := TempDeferralHeader."Amount to Defer (LCY)";
        end;

        if not SalesLine.IsCreditDocType then begin
            AmtToDefer := -AmtToDefer;
            AmtToDeferACY := -AmtToDeferACY;
        end;
    end;

    local procedure CheckMandatoryHeaderFields(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("Document Type");
        SalesHeader.TestField("Sell-to Customer No.");
        SalesHeader.TestField("Bill-to Customer No.");
        SalesHeader.TestField("Posting Date");
        SalesHeader.TestField("Document Date");

        OnAfterCheckMandatoryFields(SalesHeader, SuppressCommit);
    end;

    local procedure ClearPostBuffers()
    begin
        Clear(WhsePostRcpt);
        Clear(WhsePostShpt);
        Clear(GenJnlPostLine);
        Clear(ResJnlPostLine);
        Clear(JobPostLine);
        Clear(ItemJnlPostLine);
        Clear(WhseJnlPostLine);
    end;

    procedure SetPostingFlags(var SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            case "Document Type" of
                "Document Type"::Order:
                    Receive := false;
                "Document Type"::Invoice:
                    begin
                        Ship := true;
                        Invoice := true;
                        Receive := false;
                    end;
                "Document Type"::"Return Order":
                    Ship := false;
                "Document Type"::"Credit Memo":
                    begin
                        Ship := false;
                        Invoice := true;
                        Receive := true;
                    end;
            end;
            if not (Ship or Invoice or Receive) then
                Error(ShipInvoiceReceiveErr);
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure ClearAllVariables()
    begin
        ClearAll;
        TempSalesLineGlobal.DeleteAll;
        TempItemChargeAssgntSales.DeleteAll;
        TempHandlingSpecification.DeleteAll;
        TempATOTrackingSpecification.DeleteAll;
        TempTrackingSpecification.DeleteAll;
        TempTrackingSpecificationInv.DeleteAll;
        TempWhseSplitSpecification.DeleteAll;
        TempValueEntryRelation.DeleteAll;
        TempICGenJnlLine.DeleteAll;
        TempPrepmtDeductLCYSalesLine.DeleteAll;
        TempSKU.DeleteAll;
        TempDeferralHeader.DeleteAll;
        TempDeferralLine.DeleteAll;
    end;

    local procedure CheckAssosOrderLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        CheckDimensions: Codeunit "Check Dimensions";
    begin
        with SalesHeader do begin
            SalesLine.Reset;
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            SalesLine.SetFilter("Purch. Order Line No.", '<>0');
            if SalesLine.FindSet then
                repeat
                    PurchaseOrderLine.Get(
                      PurchaseOrderLine."Document Type"::Order, SalesLine."Purchase Order No.", SalesLine."Purch. Order Line No.");
                    TempPurchaseLine := PurchaseOrderLine;
                    TempPurchaseLine.Insert;

                    TempPurchaseHeader."Document Type" := TempPurchaseHeader."Document Type"::Order;
                    TempPurchaseHeader."No." := SalesLine."Purchase Order No.";
                    if TempPurchaseHeader.Insert then;
                until SalesLine.Next = 0;
        end;

        if TempPurchaseHeader.FindSet then
            repeat
                PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, TempPurchaseHeader."No.");
                TempPurchaseLine.SetRange("Document No.", TempPurchaseHeader."No.");
                CheckDimensions.CheckPurchDim(PurchaseHeader, TempPurchaseLine);
            until TempPurchaseHeader.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCommitSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; var ModifyHeader: Boolean; var CommitIsSuppressed: Boolean; var TempSalesLineGlobal: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAndUpdate(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingAndWarehouseForReceive(var SalesHeader: Record "Sales Header"; var Receive: Boolean; CommitIsSuppressed: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingAndWarehouseForShip(var SalesHeader: Record "Sales Header"; var Ship: Boolean; CommitIsSuppressed: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedDeferralScheduleFromSalesDoc(var SalesLine: Record "Sales Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAfterPosting(SalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvoicePostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer"; SalesLine: Record "Sales Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillDeferralPostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvoicePostingBufferAssignAmounts(SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvoicePostingBufferSetAmounts(var InvoicePostBuffer: Record "Invoice Post. Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrAmount(var TotalSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvoiceRoundingAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TotalSalesLine: Record "Sales Line"; UseTempData: Boolean; InvoiceRoundingAmount: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDropOrderPurchRcptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertedPrepmtVATBaseToDeduct(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PrepmtLineNo: Integer; TotalPrepmtAmtToDeduct: Decimal; var TempPrepmtDeductLCYSalesLine: Record "Sales Line" temporary; var PrepmtVATBaseToDeduct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSalesDocDropShipment(PurchRcptNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var SalesHeader: Record "Sales Header"; GLEntryNo: Integer; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSalesLines(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; WhseShip: Boolean; WhseReceive: Boolean; var SalesLinesProcessed: Boolean; CommitIsSuppressed: Boolean; EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostingNos(var SalesHeader: Record "Sales Header"; var NoSeriesMgt: Codeunit NoSeriesManagement; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckMandatoryFields(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesLine: Record "Sales Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; var SalesHeader: Record "Sales Header"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesShptHeaderInsert(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesShptLineInsert(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; ItemShptLedEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptLineInsert(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchOrderLine: Record "Purchase Line"; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnRcptHeaderInsert(var ReturnReceiptHeader: Record "Return Receipt Header"; SalesHeader: Record "Sales Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnRcptLineInsert(var ReturnRcptLine: Record "Return Receipt Line"; ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line"; ItemShptLedEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePosting(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePostingOnBeforeCommit(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetTempLines(var TempSalesLineLocal: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreSalesHeader(var SalesHeader: Record "Sales Header"; SalesHeaderCopy: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAfterPosting(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesHeader(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; GenJnlLineDocType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLineBeforePost(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveUnpostedOrder(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedWhseRcptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePrepaymentLines(SalesHeader: Record "Sales Header"; var TempPrepmtSalesLine: Record "Sales Line" temporary; CompleteFunctionality: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderSalesLineModify(var BlanketOrderSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedWhseShptHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizePosting(var SalesHeader: Record "Sales Header"; var TempSalesLineGlobal: Record "Sales Line" temporary; var EverythingInvoiced: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertICGenJnlLine(var ICGenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPostedHeaders(var SalesHeader: Record "Sales Header"; var TempWarehouseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWarehouseReceiptHeader: Record "Warehouse Receipt Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReturnReceiptHeader(SalesHeader: Record "Sales Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var Handled: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoiceRoundingAmount(SalesHeader: Record "Sales Header"; TotalAmountIncludingVAT: Decimal; UseTempData: Boolean; var InvoiceRoundingAmount: Decimal; CommitIsSuppressed: Boolean; var TotalSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJnlPostLine(var ItemJournalLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLockTables(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineDeleteAll(var SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptHeaderInsert(var SalesShptHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptLineInsert(var SalesShptLine: Record "Sales Shipment Line"; SalesShptHeader: Record "Sales Shipment Header"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean; PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; SalesHeader: Record "Sales Header"; WhseShip: Boolean; WhseReceive: Boolean; ItemLedgShptEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptLineInsert(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchOrderLine: Record "Purchase Line"; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnRcptHeaderInsert(var ReturnRcptHeader: Record "Return Receipt Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnRcptLineInsert(var ReturnRcptLine: Record "Return Receipt Line"; ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoicePostBuffer(SalesHeader: Record "Sales Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJobContractLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line"; CommitIsSuppressed: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePostItemJnlLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var QtyToBeShipped: Decimal; var QtyToBeShippedBase: Decimal; var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; var ItemLedgShptEntryNo: Integer; var ItemChargeNo: Code[20]; var TrackingSpecification: Record "Tracking Specification"; var IsATO: Boolean; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargePerOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ItemJnlLine2: Record "Item Journal Line"; var ItemChargeSalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePostingNos(var SalesHeader: Record "Sales Header"; var NoSeriesMgt: Codeunit NoSeriesManagement; CommitIsSuppressed: Boolean; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLineBeforePost(var ItemJournalLine: Record "Item Journal Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLineWhseLine(SalesLine: Record "Sales Line"; ItemLedgEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemTrackingReturnRcpt(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentLine: Record "Sales Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemTrackingForShipment(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentLine: Record "Sales Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; SalesLine: Record "Sales Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestSalesLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateOrderLineModifyTempLine(SalesLine: Record "Sales Line"; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostGLAndCustomer(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; TotalSalesLine: Record "Sales Line"; TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostResJnlLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; JobTaskSalesLine: Record "Sales Line"; ResJnlLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseAmount(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDivideAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; SalesLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBlanketOrderLine(var BlanketOrderSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePrepmtSalesLineWithRounding(var PrepmtSalesLine: Record "Sales Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseDocuments(SalesHeader: Record "Sales Header"; WhseShip: Boolean; WhseReceive: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseRcptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostingAndDocumentDate(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDivideAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; var SalesLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoicePostingBufferSetAmounts(SalesLine: Record "Sales Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundAmount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDropOrderShipment(var SalesHeader: Record "Sales Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGLAndCustomer(var SalesHeader: Record "Sales Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var CustLedgerEntry: Record "Cust. Ledger Entry"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingReturnRcpt(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentLine: Record "Sales Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingForShipment(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentLine: Record "Sales Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; SalesLine: Record "Sales Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateOrderLine(SalesHeader: Record "Sales Header"; var TempSalesLineGlobal: Record "Sales Line" temporary; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateOrderLineModifyTempLine(var TempSalesLine: Record "Sales Line" temporary; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostingAndDocumentDate(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateInvoicedQtyOnShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendICDocument(var SalesHeader: Record "Sales Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesLineFixedAsset(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesLineItemCharge(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesLineJob(SalesLine: Record "Sales Line"; var SkipTestJobNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesLineOthers(SalesLine: Record "Sales Line"; var SkipTestJobNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempPrepmtSalesLineInsert(var TempPrepmtSalesLine: Record "Sales Line" temporary; var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header"; CompleteFunctionality: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempPrepmtSalesLineModify(var TempPrepmtSalesLine: Record "Sales Line" temporary; var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header"; CompleteFunctionality: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAssocLines(var SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBlanketOrderLine(SalesLine: Record "Sales Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateHandledICInboxTransaction(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePostingNo(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtSalesLineWithRounding(var PrepmtSalesLine: Record "Sales Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLineBeforePost(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; WhseShip: Boolean; WhseReceive: Boolean; RoundingLineInserted: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShippingNo(var SalesHeader: Record "Sales Header"; WhseShip: Boolean; WhseReceive: Boolean; InvtPickPutaway: Boolean; PreviewMode: Boolean; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseHandlingRequired(SalesLine: Record "Sales Line"; var Required: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvoiceSalesShptLine(SalesShipmentLine: Record "Sales Shipment Line"; InvoiceNo: Code[20]; InvoiceLineNo: Integer; QtyToInvoice: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    local procedure PostResJnlLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobTaskSalesLine: Record "Sales Line")
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        if SalesLine."Qty. to Invoice" = 0 then
            exit;

        with ResJnlLine do begin
            Init;
            CopyFromSalesHeader(SalesHeader);
            CopyDocumentFields(GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, SalesHeader."Posting No. Series");
            CopyFromSalesLine(SalesLine);

            ResJnlPostLine.RunWithCheck(ResJnlLine);
            if JobTaskSalesLine."Job Contract Entry No." > 0 then
                PostJobContractLine(SalesHeader, JobTaskSalesLine);
        end;

        OnAfterPostResJnlLine(SalesHeader, SalesLine, JobTaskSalesLine, ResJnlLine);
    end;

    local procedure ValidatePostingAndDocumentDate(var SalesHeader: Record "Sales Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
        PostingDate: Date;
        ModifyHeader: Boolean;
        PostingDateExists: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
    begin
        OnBeforeValidatePostingAndDocumentDate(SalesHeader, SuppressCommit);

        PostingDateExists :=
          BatchProcessingMgt.GetParameterBoolean(SalesHeader.RecordId, BatchPostParameterTypes.ReplacePostingDate, ReplacePostingDate) and
          BatchProcessingMgt.GetParameterBoolean(
            SalesHeader.RecordId, BatchPostParameterTypes.ReplaceDocumentDate, ReplaceDocumentDate) and
          BatchProcessingMgt.GetParameterDate(SalesHeader.RecordId, BatchPostParameterTypes.PostingDate, PostingDate);

        if PostingDateExists and (ReplacePostingDate or (SalesHeader."Posting Date" = 0D)) then begin
            SalesHeader."Posting Date" := PostingDate;
            SalesHeader.SynchronizeAsmHeader;
            SalesHeader.Validate("Currency Code");
            ModifyHeader := true;
        end;

        if PostingDateExists and (ReplaceDocumentDate or (SalesHeader."Document Date" = 0D)) then begin
            SalesHeader.Validate("Document Date", PostingDate);
            ModifyHeader := true;
        end;

        if ModifyHeader then
            SalesHeader.Modify;

        OnAfterValidatePostingAndDocumentDate(SalesHeader, SuppressCommit, PreviewMode);
    end;

    local procedure UpdateSalesLineDimSetIDFromAppliedEntry(var SalesLineToPost: Record "Sales Line"; SalesLine: Record "Sales Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        DimensionMgt: Codeunit DimensionManagement;
        DimSetID: array[10] of Integer;
    begin
        DimSetID[1] := SalesLine."Dimension Set ID";
        with SalesLineToPost do begin
            if "Appl.-to Item Entry" <> 0 then begin
                ItemLedgEntry.Get("Appl.-to Item Entry");
                DimSetID[2] := ItemLedgEntry."Dimension Set ID";
            end;
            "Dimension Set ID" :=
              DimensionMgt.GetCombinedDimensionSetID(DimSetID, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    local procedure CalcDeferralAmounts(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; OriginalDeferralAmount: Decimal)
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
        if SalesHeader."Posting Date" = 0D then
            UseDate := WorkDate
        else
            UseDate := SalesHeader."Posting Date";

        if DeferralHeader.Get(
             DeferralUtilities.GetSalesDeferralDocType, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            TempDeferralHeader := DeferralHeader;
            if SalesLine.Quantity <> SalesLine."Qty. to Invoice" then
                TempDeferralHeader."Amount to Defer" :=
                  Round(TempDeferralHeader."Amount to Defer" *
                    SalesLine.GetDeferralAmount / OriginalDeferralAmount, Currency."Amount Rounding Precision");
            TempDeferralHeader."Amount to Defer (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, SalesHeader."Currency Code",
                  TempDeferralHeader."Amount to Defer", SalesHeader."Currency Factor"));
            TempDeferralHeader.Insert;

            with DeferralLine do begin
                DeferralUtilities.FilterDeferralLines(
                  DeferralLine, DeferralHeader."Deferral Doc. Type",
                  DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                  DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
                if FindSet then begin
                    TotalDeferralCount := Count;
                    repeat
                        DeferralCount := DeferralCount + 1;
                        TempDeferralLine.Init;
                        TempDeferralLine := DeferralLine;

                        if DeferralCount = TotalDeferralCount then begin
                            TempDeferralLine.Amount := TempDeferralHeader."Amount to Defer" - TotalAmount;
                            TempDeferralLine."Amount (LCY)" := TempDeferralHeader."Amount to Defer (LCY)" - TotalAmountLCY;
                        end else begin
                            if SalesLine.Quantity <> SalesLine."Qty. to Invoice" then
                                TempDeferralLine.Amount :=
                                  Round(TempDeferralLine.Amount *
                                    SalesLine.GetDeferralAmount / OriginalDeferralAmount, Currency."Amount Rounding Precision");

                            TempDeferralLine."Amount (LCY)" :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  UseDate, SalesHeader."Currency Code",
                                  TempDeferralLine.Amount, SalesHeader."Currency Factor"));
                            TotalAmount := TotalAmount + TempDeferralLine.Amount;
                            TotalAmountLCY := TotalAmountLCY + TempDeferralLine."Amount (LCY)";
                        end;

                        OnBeforeTempDeferralLineInsert(TempDeferralLine, DeferralLine, SalesLine, DeferralCount, TotalDeferralCount);
                        TempDeferralLine.Insert;
                    until Next = 0;
                end;
            end;
        end;
    end;

    local procedure CreatePostedDeferralScheduleFromSalesDoc(SalesLine: Record "Sales Line"; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralAccount: Code[20];
    begin
        if SalesLine."Deferral Code" = '' then
            exit;

        if DeferralTemplate.Get(SalesLine."Deferral Code") then
            DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
             DeferralUtilities.GetSalesDeferralDocType, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            PostedDeferralHeader.InitFromDeferralHeader(TempDeferralHeader, '', '',
              NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount, SalesLine."Sell-to Customer No.", PostingDate);
            DeferralUtilities.FilterDeferralLines(
              TempDeferralLine, DeferralUtilities.GetSalesDeferralDocType, '', '',
              SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
            if TempDeferralLine.FindSet then
                repeat
                    PostedDeferralLine.InitFromDeferralLine(
                      TempDeferralLine, '', '', NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount);
                until TempDeferralLine.Next = 0;
        end;

        OnAfterCreatePostedDeferralScheduleFromSalesDoc(SalesLine, PostedDeferralHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendSalesDocument(ShipAndInvoice: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    local procedure GetAmountRoundingPrecisionInLCY(DocType: Option; DocNo: Code[20]; CurrencyCode: Code[10]) AmountRoundingPrecision: Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        if CurrencyCode = '' then
            exit(GLSetup."Amount Rounding Precision");
        SalesHeader.Get(DocType, DocNo);
        AmountRoundingPrecision := Currency."Amount Rounding Precision" / SalesHeader."Currency Factor";
        if AmountRoundingPrecision < GLSetup."Amount Rounding Precision" then
            exit(GLSetup."Amount Rounding Precision");
        exit(AmountRoundingPrecision);
    end;

    local procedure UpdateEmailParameters(SalesHeader: Record "Sales Header")
    var
        FindEmailParameter: Record "Email Parameter";
        RenameEmailParameter: Record "Email Parameter";
    begin
        if SalesHeader."Last Posting No." = '' then
            exit;
        FindEmailParameter.SetRange("Document No", SalesHeader."No.");
        FindEmailParameter.SetRange("Document Type", SalesHeader."Document Type");
        if FindEmailParameter.FindSet then
            repeat
                RenameEmailParameter.Copy(FindEmailParameter);
                RenameEmailParameter.Rename(
                  SalesHeader."Last Posting No.", FindEmailParameter."Document Type", FindEmailParameter."Parameter Type");
            until FindEmailParameter.Next = 0;
    end;

    local procedure ArchivePurchaseOrders(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
    begin
        if TempDropShptPostBuffer.FindSet then begin
            repeat
                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, TempDropShptPostBuffer."Order No.");
                TempDropShptPostBuffer.SetRange("Order No.", TempDropShptPostBuffer."Order No.");
                repeat
                    PurchOrderLine.Get(
                      PurchOrderLine."Document Type"::Order,
                      TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
                    PurchOrderLine."Qty. to Receive" := TempDropShptPostBuffer.Quantity;
                    PurchOrderLine."Qty. to Receive (Base)" := TempDropShptPostBuffer."Quantity (Base)";
                    PurchOrderLine.Modify;
                until TempDropShptPostBuffer.Next = 0;
                PurchPost.ArchiveUnpostedOrder(PurchOrderHeader);
                TempDropShptPostBuffer.SetRange("Order No.");
            until TempDropShptPostBuffer.Next = 0;
        end;
    end;

    local procedure IsItemJnlPostLineHandled(var ItemJnlLine: Record "Item Journal Line"; var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeItemJnlPostLine(ItemJnlLine, SalesLine, SalesHeader, SuppressCommit, IsHandled);
        exit(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAfterPosting(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SkipDelete: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostingBufferOnBeforeDeferrals(var SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillDeferralPostingBuffer(var SalesLine: Record "Sales Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCountryCode(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var CountryRegionCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReturnReceiptLine(SalesLine: Record "Sales Line"; ReturnRcptLine: Record "Return Receipt Line"; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingForReceiptCondition(SalesLine: Record "Sales Line"; ReturnRcptLine: Record "Return Receipt Line"; var Condition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingForShipmentCondition(SalesLine: Record "Sales Line"; SalesShptLine: Record "Sales Shipment Line"; var Condition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldPostWhseJnlLine(SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvDiscountSetFilter(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyAndCheckItemChargeOnBeforeLoop(var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToTempLinesOnAfterSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPostedHeadersOnBeforeInsertInvoiceHeader(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumSalesLines2OnBeforeDivideAmount(var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumSalesLines2SetFilter(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; InsertSalesLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnAfterTestUpdatedSalesLine(var SalesLine: Record "Sales Line"; var EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnBeforeInitOutstanding(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnBeforeInitTempSalesLineQuantities(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnBeforeCalcInvDiscount(var SalesHeader: Record "Sales Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseReceive: Boolean; WhseShip: Boolean; var RefreshNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTrackingAndWarehouseForShipOnBeforeCheck(var SalesHeader: Record "Sales Header"; var TempWhseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWhseReceiptHeader: Record "Warehouse Receipt Header" temporary; var Ship: Boolean; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTrackingAndWarehouseForReceiveOnBeforeCheck(var SalesHeader: Record "Sales Header"; var TempWhseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWhseReceiptHeader: Record "Warehouse Receipt Header" temporary; var Receive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizePostingOnBeforeCreateOutboxSalesTrans(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAssocItemJnlLineOnBeforePost(var ItemJournalLine: Record "Item Journal Line"; PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostATOOnBeforePostedATOLinkInsert(var PostedATOLink: Record "Posted Assemble-to-Order Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35]; var CustLedgerEntry: Record "Cust. Ledger Entry"; var EntryFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterCopyDocumentFields(var ItemJournalLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforePostItemJnlLineWhseLine(var ItemJnlLine: Record "Item Journal Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeTransferReservToItemJnlLine(SalesLine: Record "Sales Line"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargeOnBeforePostItemJnlLine(var SalesLineToPost: Record "Sales Line"; var SalesLine: Record "Sales Line"; QtyToAssign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerOrderOnAfterCopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var SalesLine: Record "Sales Line"; GeneralLedgerSetup: Record "General Ledger Setup"; QtyToInvoice: Decimal; var TempItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerOrderOnBeforeTestJobNo(SalesLine: Record "Sales Line"; var SkipTestJobNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerShptOnBeforeTestJobNo(SalesShipmentLine: Record "Sales Shipment Line"; var SkipTestJobNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerRetRcptOnBeforeTestFieldJobNo(ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForReceiptOnAfterSetFilters(var ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnBeforeInsertCrMemoLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnBeforeInsertInvoiceLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnBeforeInsertReturnReceiptLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnBeforeInsertShipmentLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean; SalesLineACY: Record "Sales Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnAfterSetEverythingInvoiced(SalesLine: Record "Sales Line"; var EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnBeforeTestJobNo(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnAfterPostItemTrackingLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseShip: Boolean; WhseReceive: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesLineOnBeforePostItemTrackingLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseShip: Boolean; WhseReceive: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountOnBeforeIncrAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineQty: Decimal; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeFinalizePosting(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPostedDocumentRecordElseCase(SalesHeader: Record "Sales Header"; var PostedSalesDocumentVariant: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForReceiptOnBeforeReturnRcptLineModify(SalesHeader: Record "Sales Header"; var ReturnRcptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendPostedDocumentRecordElseCase(SalesHeader: Record "Sales Header"; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssocOrderOnAfterModifyPurchLine(var PurchOrderLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssocOrderOnBeforeModifyPurchLine(var PurchOrderLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBlanketOrderLineOnBeforeCheck(var BlanketOrderSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBlanketOrderLineOnBeforeInitOutstanding(var BlanketOrderSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    begin
    end;
}

