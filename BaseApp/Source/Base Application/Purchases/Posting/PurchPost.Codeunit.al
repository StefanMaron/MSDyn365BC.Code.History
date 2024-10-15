﻿namespace Microsoft.Purchases.Posting;

using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
#if not CLEAN23
using Microsoft.Finance.SalesTax;
#endif
using Microsoft.Finance.VAT.Calculation;
#if not CLEAN23
using Microsoft.Finance.VAT.Ledger;
#endif
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.WithholdingTax;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Service.Item;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using System.Automation;
using System.Utilities;
using System.Environment.Configuration;

codeunit 90 "Purch.-Post"
{
    Permissions = TableData "Sales Header" = rm,
                  TableData "Sales Line" = rm,
                  TableData "Purchase Line" = rimd,
                  TableData "G/L Register" = rimd,
#if not CLEAN23
                  TableData "Invoice Post. Buffer" = rimd,
#endif                  
                  TableData "Vendor Posting Group" = rimd,
                  TableData "Inventory Posting Group" = rimd,
                  TableData "Sales Shipment Header" = rimd,
                  TableData "Sales Shipment Line" = rimd,
                  TableData "Purch. Rcpt. Header" = rimd,
                  TableData "Purch. Rcpt. Line" = rimd,
                  TableData "Purch. Inv. Header" = rimd,
                  TableData "Purch. Inv. Line" = rimd,
                  TableData "Purch. Cr. Memo Hdr." = rimd,
                  TableData "Purch. Cr. Memo Line" = rimd,
                  TableData "Drop Shpt. Post. Buffer" = rimd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Value Entry Relation" = rid,
                  TableData "Return Shipment Header" = rimd,
                  TableData "Return Shipment Line" = rimd,
                  tabledata "G/L Entry" = r;
    TableNo = "Purchase Header";

    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    internal procedure RunWithCheck(var PurchaseHeader2: Record "Purchase Header")
    var
        PurchHeader: Record "Purchase Header";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        ErrorContextElementProcessLines: Codeunit "Error Context Element";
        ErrorContextElementPostLine: Codeunit "Error Context Element";
        ZeroPurchLineRecID: RecordId;
        EverythingInvoiced: Boolean;
        SavedPreviewMode: Boolean;
        SavedSuppressCommit: Boolean;
        SavedCalledBy: Integer;
        BiggestLineNo: Integer;
        ICGenJnlLineNo: Integer;
        SavedHideProgressWindow: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostPurchaseDoc(PurchaseHeader2, PreviewMode, SuppressCommit, HideProgressWindow, ItemJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed then
            LockTimeout(false);

        ValidatePostingAndDocumentDate(PurchaseHeader2);

        SavedPreviewMode := PreviewMode;
        SavedSuppressCommit := SuppressCommit;
        SavedHideProgressWindow := HideProgressWindow;
        SavedCalledBy := CalledBy;
        ClearAllVariables();
        PreviewMode := SavedPreviewMode;
        SuppressCommit := SavedSuppressCommit;
        HideProgressWindow := SavedHideProgressWindow;
        CalledBy := SavedCalledBy;

        GetGLSetup();
        GetPurchSetup();
        GetInvoicePostingSetup();
        GetCurrency(PurchaseHeader2."Currency Code");

        PurchHeader := PurchaseHeader2;
        OnRunOnBeforeFillTempLines(PreviewMode, GenJnlLineDocNo);
        FillTempLines(PurchHeader, TempPurchLineGlobal);
        OnRunOnAfterFillTempLines(PurchHeader);

        // Header
        CheckAndUpdate(PurchHeader);

#if not CLEAN23
        if UseLegacyInvoicePosting() then begin
            TempInvoicePostBufferReverseCharge.Reset();
            TempInvoicePostBufferReverseCharge.DeleteAll();
            TempDeferralHeader.DeleteAll();
            TempDeferralLine.DeleteAll();
            TempInvoicePostBuffer.DeleteAll();
            TempInvoicePostBufferGST.DeleteAll();
        end else
#endif
        InvoicePostingInterface.ClearBuffers();

        TempDropShptPostBuffer.DeleteAll();
        EverythingInvoiced := true;

        // Lines
        GetZeroPurchLineRecID(PurchHeader, ZeroPurchLineRecID);
        ErrorMessageMgt.PushContext(ErrorContextElementProcessLines, ZeroPurchLineRecID, 0, PostDocumentLinesMsg);
        OnBeforePostLines(TempPurchLineGlobal, PurchHeader, PreviewMode, SuppressCommit, TempPurchLineGlobal);

        LineCount := 0;
        RoundingLineInserted := false;
        AdjustFinalInvWith100PctPrepmt(TempPurchLineGlobal);

        TempVATAmountLineRemainder.DeleteAll();
        TempPurchLineGlobal.CalcVATAmountLines(1, PurchHeader, TempPurchLineGlobal, TempVATAmountLine);


        OnRunOnAfterCalcVATAmountLines(PurchHeader, TempPurchLineGlobal, TempVATAmountLine);

        PurchaseLinesProcessed := false;
        if TempPurchLineGlobal.FindSet() then
            repeat
                IsHandled := false;
                OnRunOnBeforePostPurchLine(TempPurchLineGlobal, PurchHeader, IsHandled);
                if not IsHandled then begin
                    ErrorMessageMgt.PushContext(ErrorContextElementPostLine, TempPurchLineGlobal.RecordId, 0, PostDocumentLinesMsg);
                    ItemJnlRollRndg := false;
                    LineCount := LineCount + 1;
                    if GuiAllowed and not HideProgressWindow then
                        Window.Update(2, LineCount);

                    PostPurchLine(
                      PurchHeader, TempPurchLineGlobal, TempVATAmountLine, TempVATAmountLineRemainder,
                      TempDropShptPostBuffer, EverythingInvoiced, ICGenJnlLineNo);
                    OnRunOnAfterPostPurchLine(TempPurchLineGlobal, PurchInvHeader, PurchCrMemoHeader, PurchRcptHeader, ReturnShptHeader);
                end;

                if RoundingLineInserted then
                    LastLineRetrieved := true
                else begin
                    BiggestLineNo := MAX(BiggestLineNo, TempPurchLineGlobal."Line No.");
                    LastLineRetrieved := TempPurchLineGlobal.Next() = 0;
                    if LastLineRetrieved and PurchSetup."Invoice Rounding" then
                        InvoiceRounding(PurchHeader, TempPurchLineGlobal, false, BiggestLineNo);
                    OnRunOnAfterInvoiceRounding(PurchHeader, TempPurchLineGlobal);
                end;
                ErrorMessageMgt.PopContext(ErrorContextElementPostLine);
            until LastLineRetrieved;

        OnAfterProcessPurchLines(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader,
          WhseShip, WhseReceive, PurchaseLinesProcessed, SuppressCommit, EverythingInvoiced);

        ErrorMessageMgt.PopContext(ErrorContextElementProcessLines);
        ErrorMessageMgt.Finish(ZeroPurchLineRecID);

        if PurchHeader.IsCreditDocType() then begin
            ReverseAmount(TotalPurchLine);
            ReverseAmount(TotalPurchLineLCY);
        end;

        // Post combine shipment of sales order
        PostCombineSalesOrderShipment(PurchHeader, TempDropShptPostBuffer);

        OnRunOnBeforePostInvoice(PurchHeader, EverythingInvoiced);

        if PurchHeader.Invoice then
            PostInvoice(PurchHeader);

        OnRunOnAfterPostInvoice(PurchHeader, PurchRcptHeader, ReturnShptHeader, PurchInvHeader, PurchCrMemoHeader, PreviewMode, Window, SrcCode, GenJnlLineDocType, GenJnlLineDocNo, GenJnlPostLine);

        if ICGenJnlLineNo > 0 then
            PostICGenJnl(PurchHeader);
        IsHandled := false;
        OnRunOnBeforeMakeInventoryAdjustment(PurchHeader, GenJnlPostLine, ItemJnlPostLine, PreviewMode, PurchRcptHeader, PurchInvHeader, IsHandled);
        if not IsHandled then
            MakeInventoryAdjustment();
        UpdateLastPostingNos(PurchHeader);

        OnRunOnBeforeFinalizePosting(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader, GenJnlPostLine, SuppressCommit);
        FinalizePosting(PurchHeader, TempDropShptPostBuffer, EverythingInvoiced);
        UpdateTaxForPostedDoc(PurchHeader);

        PurchaseHeader2 := PurchHeader;

        CommitAndUpdateAnalysisVeiw();

        OnAfterPostPurchaseDoc(
          PurchaseHeader2, GenJnlPostLine, PurchRcptHeader."No.", ReturnShptHeader."No.", PurchInvHeader."No.", PurchCrMemoHeader."No.",
          SuppressCommit);

        OnAfterPostPurchaseDocDropShipment(SalesShptHeader."No.", SuppressCommit);
    end;

    var
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
        [SecurityFiltering(SecurityFilter::Ignored)]
        GLEntry: Record "G/L Entry";
        TempPurchLineGlobal: Record "Purchase Line" temporary;
#if not CLEAN23
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
#endif
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
#if not CLEAN23
        TempInvoicePostBufferReverseCharge: Record "Invoice Post. Buffer" temporary;
        TempInvoicePostBufferGST: Record "Invoice Post. Buffer" temporary;
#endif
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        SourceCodeSetup: Record "Source Code Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
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
        WHTEntry: Record "WHT Entry";
        TempPrepmtLineNoBuf: Record "Line Number Buffer" temporary;
        TempPrepmtVATAmtBuf: Record "Purchase Line" temporary;
        AddCurrency: Record Currency;
        TempSKU: Record "Stockkeeping Unit" temporary;
#if not CLEAN23
        DeferralPostBuffer: Record "Deferral Posting Buffer";
#endif
        TempDeferralHeader: Record "Deferral Header" temporary;
        TempDeferralLine: Record "Deferral Line" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
#if not CLEAN23
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
#endif
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
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
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        DeferralUtilities: Codeunit "Deferral Utilities";
        UOMMgt: Codeunit "Unit of Measure Management";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        WHTManagement: Codeunit WHTManagement;
        InvoicePostingInterface: Interface "Invoice Posting";
        IsInterfaceInitialized: Boolean;
        Window: Dialog;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        ItemLedgShptEntryNo: Integer;
        GenJnlLineDocType: Enum "Gen. Journal Document Type";
        LineCount: Integer;
#if not CLEAN23
        FALineNo: Integer;
        DeferralLineNo: Integer;
        InvDefLineNo: Integer;
#endif
        RoundingLineNo: Integer;
        RemQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoicedBase: Decimal;
        RemAmt: Decimal;
        RemDiscAmt: Decimal;
        TotalChargeAmt: Decimal;
        TotalChargeAmtLCY: Decimal;
        RoundedPrevTotalChargeAmt: Decimal;
        PreciseTotalChargeAmt: Decimal;
        RoundedPrevTotalChargeAmtACY: Decimal;
        PreciseTotalChargeAmtACY: Decimal;
        LastLineRetrieved: Boolean;
        RoundingLineInserted: Boolean;
        DropShipOrder: Boolean;
        GLSetupRead: Boolean;
        LogErrorMode: Boolean;
        PurchSetupRead: Boolean;
        InvoiceGreaterThanReturnShipmentErr: Label 'The quantity you are attempting to invoice is greater than the quantity in return shipment %1.', Comment = '%1 = Return Shipment No.';
        ReturnShipmentLinesDeletedErr: Label 'Return shipment lines have been deleted.';
        InvoiceMoreThanShippedErr: Label 'You cannot invoice return order %1 for more than you have shipped.', Comment = '%1 = Order No.';
        RelatedItemLedgEntriesNotFoundErr: Label 'Related item ledger entries cannot be found.';
        ItemTrackingWrongSignErr: Label 'Item Tracking is signed wrongly.';
        ItemTrackingMismatchErr: Label 'Item Tracking does not match.';
        PostingDateNotAllowedErr: Label '%1 is not within your range of allowed posting dates.', Comment = '%1 - Posting Date field caption';
        ItemTrackQuantityMismatchErr: Label 'The %1 does not match the quantity defined in item tracking for item %2.', Comment = '%1 = Quantity, %2 - item no.';
        CannotBeGreaterThanErr: Label 'cannot be more than %1.', Comment = '%1 = Amount';
        CannotBeSmallerThanErr: Label 'must be at least %1.', Comment = '%1 = Amount';
        ItemJnlRollRndg: Boolean;
        WhseReceive: Boolean;
        WhseShip: Boolean;
        InvtPickPutaway: Boolean;
        DocumentIsReadyToBeChecked: Boolean;
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
        CurrencyFactor: Decimal;
        TotalWHTAmount: Decimal;
        PurLine: Record "Purchase Line";
        InvDiscAmt: Decimal;
        InvDiscAmount: Decimal;
        ReservationDisruptedQst: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment. Do you want to continue?', Comment = 'One or more reservation entries exist for the item with No. = 1000, Location Code = SILVER, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
        ReassignItemChargeErr: Label 'The order line that the item charge was originally assigned to has been fully posted. You must reassign the item charge to the posted receipt or shipment.';
        CalledBy: Integer;
        PreviewMode: Boolean;
#if not CLEAN23
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
#endif
        MixedDerpFAUntilPostingDateErr: Label 'The value in the Depr. Until FA Posting Date field must be the same on lines for the same fixed asset %1.', Comment = '%1 - Fixed Asset No.';
        CannotPostSameMultipleFAWhenDeprBookValueZeroErr: Label 'You cannot select the Depr. Until FA Posting Date check box because there is no previous acquisition entry for fixed asset %1.\\If you want to depreciate new acquisitions, you can select the Depr. Acquisition Cost check box instead.', Comment = '%1 - Fixed Asset No.';
        PostingPreviewNoTok: Label '***', Locked = true;
        InvPickExistsErr: Label 'One or more related inventory picks must be registered before you can post the shipment.';
        InvPutAwayExistsErr: Label 'One or more related inventory put-aways must be registered before you can post the receipt.';
        SuppressCommit: Boolean;
        OrderArchived: Boolean;
        CheckPurchHeaderMsg: Label 'Check purchase document fields.';
        CheckPurchLineMsg: Label 'Check purchase document line.';
        HideProgressWindow: Boolean;
        OverReceiptApprovalErr: Label 'There are lines with over-receipt required for approval.';
        PostDocumentLinesMsg: Label 'Post document lines.';
        SetupBlockedErr: Label 'Setup is blocked in %1 for %2 %3 and %4 %5.', Comment = '%1 - General/VAT Posting Setup, %2 %3 %4 %5 - posting groups.';
        PurchRcptHeaderConflictErr: Label 'Cannot post the purchase receipt because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Receiving No.';
        ReturnShptHeaderConflictErr: Label 'Cannot post the return shipment because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Return Shipment No.';
        PurchInvHeaderConflictErr: Label 'Cannot post the purchase invoice because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Posting No.';
        PurchCrMemoHeaderConflictErr: Label 'Cannot post the purchase credit memo because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Posting No.';
        PurchLinePostCategoryTok: Label 'Purchase Line Post', Locked = true;
        SameIdFoundLbl: Label 'Same line id found.', Locked = true;
        EmptyIdFoundLbl: Label 'Empty line id found.', Locked = true;
        ItemReservDisruptionLbl: Label 'Confirm Item Reservation Disruption', Locked = true;
        ItemChargeZeroAmountErr: Label 'The amount for item charge %1 cannot be 0.', Comment = '%1 = Item Charge No.';
        ConfirmUsageWithBlankLineTypeQst: Label 'Usage will not be linked to the project planning line because the Line Type field is empty.\\Do you want to continue?';
        ConfirmUsageWithBlankJobPlanningLineNoQst: Label 'Usage will not be linked to the project planning line because the Project Planning Line No field is empty.\\Do you want to continue?';

    local procedure GetZeroPurchLineRecID(PurchHeader: Record "Purchase Header"; var PurchLineRecID: RecordId)
    var
        ZeroPurchLine: Record "Purchase Line";
    begin
        ZeroPurchLine."Document Type" := PurchHeader."Document Type";
        ZeroPurchLine."Document No." := PurchHeader."No.";
        ZeroPurchLine."Line No." := 0;
        PurchLineRecID := ZeroPurchLine.RecordId;
    end;

    procedure CopyToTempLines(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        OnCopyToTempLinesOnAfterSetFilters(PurchLine, PurchHeader);
        if PurchLine.FindSet() then
            repeat
                OnCopyToTempLinesLoop(PurchLine);
                UpdateChargeItemPurchaseLineGenProdPostingGroup(PurchLine);
                TempPurchLine := PurchLine;
                TempPurchLine.Insert();
            until PurchLine.Next() = 0;

        OnAfterCopyToTempLines(TempPurchLine);
    end;

    local procedure CommitAndUpdateAnalysisVeiw()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCommitAndUpdateAnalysisVeiw(InvtPickPutaway, SuppressCommit, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        if not (InvtPickPutaway or SuppressCommit or PreviewMode) then begin
            Commit();
            UpdateAnalysisView.UpdateAll(0, true);
            UpdateItemAnalysisView.UpdateAll(0, true);
        end;
    end;

    procedure FillTempLines(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    begin
        TempPurchLine.Reset();
        if TempPurchLine.IsEmpty() then
            CopyToTempLines(PurchHeader, TempPurchLine);
    end;

    local procedure ModifyTempLine(var TempPurchLineLocal: Record "Purchase Line" temporary)
    var
        PurchLine: Record "Purchase Line";
    begin
        OnBeforeModifyTempLine(TempPurchLineLocal);
        TempPurchLineLocal.Modify();
        PurchLine.Get(TempPurchLineLocal.RecordId);
        PurchLine.TransferFields(TempPurchLineLocal, false);
        PurchLine.Modify();
        OnAfterModifyTempLine(PurchLine);
    end;

    procedure RefreshTempLines(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    begin
        TempPurchLine.Reset();
        TempPurchLine.SetRange("Prepayment Line", false);
        TempPurchLine.DeleteAll();
        TempPurchLine.Reset();
        CopyToTempLines(PurchHeader, TempPurchLine);

        OnAfterRefreshTempLines(TempPurchLine);
    end;

    procedure ResetTempLines(var TempPurchLineLocal: Record "Purchase Line" temporary)
    begin
        TempPurchLineLocal.Reset();
        TempPurchLineLocal.Copy(TempPurchLineGlobal, true);

        OnAfterResetTempLines(TempPurchLineGlobal);
    end;

    procedure CalcInvoice(var PurchHeader: Record "Purchase Header") NewInvoice: Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInvoice(PurchHeader, NewInvoice, IsHandled);
        if IsHandled then
            exit(NewInvoice);

        ResetTempLines(TempPurchLine);
        IsHandled := false;
        OnCalcInvoiceOnAfterResetTempLines(PurchHeader, TempPurchLine, NewInvoice, IsHandled);
        if IsHandled then
            exit(NewInvoice);

        TempPurchLine.SetFilter(Quantity, '<>0');
        if PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"] then
            TempPurchLine.SetFilter("Qty. to Invoice", '<>0');
        NewInvoice := not TempPurchLine.IsEmpty();
        if NewInvoice then
            case PurchHeader."Document Type" of
                PurchHeader."Document Type"::Order:
                    if not PurchHeader.Receive then begin
                        TempPurchLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                        NewInvoice := not TempPurchLine.IsEmpty();
                    end;
                PurchHeader."Document Type"::"Return Order":
                    if not PurchHeader.Ship then begin
                        TempPurchLine.SetFilter("Return Qty. Shipped Not Invd.", '<>0');
                        NewInvoice := not TempPurchLine.IsEmpty();
                    end;
            end;
        exit(NewInvoice);
    end;

    local procedure CalcInvDiscount(var PurchHeader: Record "Purchase Header")
    var
        PurchaseHeaderCopy: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if not (PurchSetup."Calc. Inv. Discount" and (PurchHeader.Status <> PurchHeader.Status::Open)) then
            exit;

        PurchaseHeaderCopy := PurchHeader;
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        OnCalcInvDiscountSetFilter(PurchLine, PurchHeader);
        PurchLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
        RefreshTempLines(PurchHeader, TempPurchLineGlobal);
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        RestorePurchaseHeader(PurchHeader, PurchaseHeaderCopy);
        IsHandled := false;
        OnCalcInvDiscountOnBeforeDoCommit(PurchHeader, IsHandled);
        if not IsHandled then
            if not (PreviewMode or SuppressCommit) then
                Commit();
        OnAfterCalcInvDiscount(PurchHeader, TempPurchLineGlobal);
        exit;
    end;

    local procedure RestorePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PurchaseHeaderCopy: Record "Purchase Header")
    begin
        PurchaseHeader.Invoice := PurchaseHeaderCopy.Invoice;
        PurchaseHeader.Receive := PurchaseHeaderCopy.Receive;
        PurchaseHeader.Ship := PurchaseHeaderCopy.Ship;
        PurchaseHeader."Posting No." := PurchaseHeaderCopy."Posting No.";
        PurchaseHeader."Receiving No." := PurchaseHeaderCopy."Receiving No.";
        PurchaseHeader."Return Shipment No." := PurchaseHeaderCopy."Return Shipment No.";

        OnAfterRestorePurchaseHeader(PurchaseHeader, PurchaseHeaderCopy);
    end;

    local procedure CheckAndUpdate(var PurchHeader: Record "Purchase Header")
    var
        ModifyHeader: Boolean;
        RefreshTempLinesNeeded: Boolean;
        IsHandled: Boolean;
    begin
        DocumentIsReadyToBeChecked := true;
        CheckPurchDocument(PurchHeader);

        if GuiAllowed and not HideProgressWindow then
            InitProgressWindow(PurchHeader);

        if PurchHeader.Invoice then
            CreatePrepmtLines(PurchHeader, true);

        ModifyHeader := UpdatePostingNos(PurchHeader);

        DropShipOrder := UpdateAssosOrderPostingNos(PurchHeader);

        OnBeforePostCommitPurchaseDoc(PurchHeader, GenJnlPostLine, PreviewMode, ModifyHeader, SuppressCommit, TempPurchLineGlobal);
        if not PreviewMode and ModifyHeader then begin
            PurchHeader.Modify();
            IsHandled := false;
            OnCheckAndUpdateOnBeforeOnBeforeDoCommit(PurchHeader, IsHandled);
            if (not IsHandled) and (not SuppressCommit) then
                Commit();
        end;

        OnCheckAndUpdateOnBeforeCalcInvDiscount(
          PurchHeader, TempWhseRcptHeader, TempWhseShptHeader, WhseReceive, WhseShip, RefreshTempLinesNeeded);
        if RefreshTempLinesNeeded then
            RefreshTempLines(PurchHeader, TempPurchLineGlobal);
        CalcInvDiscount(PurchHeader);
        ReleasePurchDocument(PurchHeader);

        HandleArchiveUnpostedOrder(PurchHeader);

        CheckICPartnerBlocked(PurchHeader);
        SendICDocument(PurchHeader, ModifyHeader);
        UpdateHandledICInboxTransaction(PurchHeader);

        LockTables(PurchHeader);

        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Purchases;

        OnCheckAndUpdateOnAfterSetSourceCode(PurchHeader, SourceCodeSetup, SrcCode);

        InsertPostedHeaders(PurchHeader);
        OnCheckAndUpdateOnAfterInsertPostedHeaders(PurchHeader);

        IsHandled := false;
        OnCheckAndUpdateOnBeforeUpdateIncomingDocument(PurchHeader, IsHandled);
        if not IsHandled then
            UpdateIncomingDocument(PurchHeader."Incoming Document Entry No.", PurchHeader."Posting Date", GenJnlLineDocNo);

        CheckOverReceipt(PurchHeader);

        OnAfterCheckAndUpdate(PurchHeader, SuppressCommit, PreviewMode);
    end;

    local procedure HandleArchiveUnpostedOrder(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnCheckAndUpdateOnBeforeArchiveUnpostedOrder(PurchHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader.Receive or PurchHeader.Ship then
            ArchiveUnpostedOrder(PurchHeader);

        OnCheckAndUpdateOnAfterArchiveUnpostedOrder(PurchHeader, Currency, PreviewMode);
    end;

    procedure CheckPurchDocument(var PurchHeader: Record "Purchase Header")
    var
        CheckDimensions: Codeunit "Check Dimensions";
        ErrorContextElement: Codeunit "Error Context Element";
        CopyAndCheckItemChargeNeeded: Boolean;
        IsHandled: Boolean;
    begin
        if not DocumentIsReadyToBeChecked then
            PrepareCheckDocument(PurchHeader);
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchHeader.RecordId, 0, CheckPurchHeaderMsg);
        CheckMandatoryHeaderFields(PurchHeader);
        GetGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            PurchHeader.TestField("Journal Templ. Name", ErrorInfo.Create());

        CheckPostingDate(PurchHeader);
        CheckVATDate(PurchHeader);

        if PurchHeader.IsCreditDocType() and GLSetup.GSTEnabled(PurchHeader."Document Date") and GLSetup."Adjustment Mandatory" then
            PurchHeader.TestField("Reason Code");

        CheckWHTApplication(PurchHeader);

        OnCheckAndUpdateOnBeforeSetPostingFlags(PurchHeader, TempPurchLineGlobal);
        if LogErrorMode then
            SetLogErrorModePostingFlags(PurchHeader)
        else
            SetPostingFlags(PurchHeader);
        OnCheckAndUpdateOnAfterSetPostingFlags(PurchHeader, TempPurchLineGlobal);

        InvtPickPutaway := PurchHeader."Posting from Whse. Ref." <> 0;
        PurchHeader."Posting from Whse. Ref." := 0;
        OnCheckAndUpdateOnAfterClearPostingFromWhseRef(PurchHeader, InvtPickPutaway);

        IsHandled := false;
        OnCheckPurchDocumentOnBeforeCheckPurchDim(PurchHeader, TempPurchLineGlobal, IsHandled);
        if not IsHandled then
            CheckDimensions.CheckPurchDim(PurchHeader, TempPurchLineGlobal);

        if PurchHeader.Invoice then
            CheckFAPostingPossibility(PurchHeader);

        CheckPostRestrictions(PurchHeader);

        if ((PurchHeader."Buy-from IC Partner Code" <> '') or (PurchHeader."Pay-to IC Partner Code" <> '')) then
            CheckICDocumentDuplicatePosting(PurchHeader);

        if PurchHeader.Invoice then
            PurchHeader.Invoice := CalcInvoice(PurchHeader);

        CopyAndCheckItemChargeNeeded := PurchHeader.Invoice;
        OnCheckAndUpdateOnAfterCalcCopyAndCheckItemChargeNeeded(PurchHeader, CopyAndCheckItemChargeNeeded);
        if CopyAndCheckItemChargeNeeded then
            CopyAndCheckItemCharge(PurchHeader);
        OnCheckAndUpdateOnAfterCopyAndCheckItemCharge(PurchHeader);

        if PurchHeader.Invoice and not PurchHeader.IsCreditDocType() then
            PurchHeader.TestField("Due Date", ErrorInfo.Create());

        if PurchHeader.Receive then begin
            PurchHeader.Receive := CheckTrackingAndWarehouseForReceive(PurchHeader);
            if not InvtPickPutaway then
                if CheckIfInvPutawayExists(PurchHeader) then
                    Error(ErrorInfo.Create(InvPutAwayExistsErr, true, PurchHeader));
        end;

        if PurchHeader.Ship then begin
            PurchHeader.Ship := CheckTrackingAndWarehouseForShip(PurchHeader);
            if not InvtPickPutaway then
                if CheckIfInvPickExists() then
                    Error(ErrorInfo.Create(InvPickExistsErr, true, PurchHeader));
        end;

        CheckHeaderPostingType(PurchHeader);

        CheckAssociatedOrderLines(PurchHeader);

        if PurchHeader.Invoice and PurchSetup."Ext. Doc. No. Mandatory" then
            CheckExtDocNo(PurchHeader);
        ErrorMessageMgt.PopContext(ErrorContextElement);

        CheckPurchLines(PurchHeader);

        OnAfterCheckPurchDoc(PurchHeader, SuppressCommit, WhseShip, WhseReceive, PreviewMode, ErrorMessageMgt);
        if not LogErrorMode then
            ErrorMessageMgt.Finish(PurchHeader.RecordId);
    end;

    local procedure CheckPurchLines(var PurchHeader: Record "Purchase Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        if TempPurchLineGlobal.FindSet() then
            repeat
                ErrorMessageMgt.PushContext(ErrorContextElement, TempPurchLineGlobal.RecordId(), 0, CheckPurchLineMsg);
                TestPurchLine(PurchHeader, TempPurchLineGlobal);
            until TempPurchLineGlobal.Next() = 0;
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    local procedure CheckExtDocNo(PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckExtDocNo(PurchaseHeader, GenJnlLineDocType, GenJnlLineExtDocNo, IsHandled);
        if IsHandled then
            exit;

        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order,
              PurchaseHeader."Document Type"::Invoice:
                if PurchaseHeader."Vendor Invoice No." = '' then
                    Error(
                        ErrorInfo.Create(
                            StrSubstNo(ExtDocNoNeededErr, PurchaseHeader.FieldCaption("Vendor Invoice No.")),
                            true,
                            PurchaseHeader));
            else
                if PurchaseHeader."Vendor Cr. Memo No." = '' then
                    Error(
                        ErrorInfo.Create(
                            StrSubstNo(ExtDocNoNeededErr, PurchaseHeader.FieldCaption("Vendor Cr. Memo No.")),
                            true,
                            PurchaseHeader));
        end;
    end;

    procedure PrepareCheckDocument(var PurchaseHeader: Record "Purchase Header")
    begin
        OnBeforePrepareCheckDocument(PurchaseHeader);
        GetGLSetup();
        GetPurchSetup();
        GetInvoicePostingSetup();
        GetCurrency(PurchaseHeader."Currency Code");
        FillTempLines(PurchaseHeader, TempPurchLineGlobal);
        LogErrorMode := true;
        DocumentIsReadyToBeChecked := true;
    end;

    local procedure SetLogErrorModePostingFlags(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Receive := PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::Invoice];
        PurchaseHeader.Ship := PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."Document Type"::"Credit Memo"];
        PurchaseHeader.Invoice := true;
    end;

    local procedure PostPurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var EverythingInvoiced: Boolean; var ICGenJnlLineNo: Integer)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        SearchPurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SearchPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        CostBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostPurchLine(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        if PurchLine.Type = PurchLine.Type::Item then
            CostBaseAmount := PurchLine."Line Amount";
        UpdateQtyPerUnitOfMeasure(PurchLine);

        UpdatePurchLineBeforePost(PurchHeader, PurchLine);

        if PurchLine."Qty. to Invoice" + PurchLine."Quantity Invoiced" <> PurchLine.Quantity then
            EverythingInvoiced := false;

        OnPostPurchLineOnAfterSetEverythingInvoiced(PurchLine, EverythingInvoiced, PurchHeader);

        if PurchLine.Quantity <> 0 then begin
            PurchLine.TestField("No.");
            PurchLine.TestField(Type);
            IsHandled := false;
            OnPostPurchLineOnBeforeTestGeneralPostingGroups(PurchLine, IsHandled);
            if not IsHandled then
                if not ApplicationAreaMgmt.IsSalesTaxEnabled() then begin
                    PurchLine.TestField("Gen. Bus. Posting Group");
                    PurchLine.TestField("Gen. Prod. Posting Group");
                end;
            IsHandled := false;
            OnPostPurchLineOnBeforeDivideAmount(PurchHeader, PurchLine, TempVATAmountLine, TempVATAmountLineRemainder, IsHandled);
            if not IsHandled then
                DivideAmount(PurchHeader, PurchLine, 1, PurchLine."Qty. to Invoice", TempVATAmountLine, TempVATAmountLineRemainder);
        end else
            PurchLine.TestField(Amount, 0);

        CheckItemReservDisruption(PurchLine);
        OnPostPurchLineOnBeforeRoundAmount(PurchHeader, PurchLine, PurchInvHeader, PurchCrMemoHeader, SrcCode);
        RoundAmount(PurchHeader, PurchLine, PurchLine."Qty. to Invoice");

        if PurchLine.IsCreditDocType() then begin
            ReverseAmount(PurchLine);
            ReverseAmount(PurchLineACY);
        end;

        RemQtyToBeInvoiced := PurchLine."Qty. to Invoice";
        RemQtyToBeInvoicedBase := PurchLine."Qty. to Invoice (Base)";

#if not CLEAN23
        if UseLegacyInvoicePosting() then
            CheckJobCreditPurchLine(PurchHeader, PurchLine)
        else
#endif
            InvoicePostingInterface.CheckCreditLine(PurchHeader, PurchLine);

        PostItemTrackingLine(PurchHeader, PurchLine);

        OnPostPurchLineOnBeforePostByType(PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchLine, PurchLineACY, SrcCode);
        case PurchLine.Type of
            PurchLine.Type::"G/L Account":
                PostGLAccICLine(PurchHeader, PurchLine, ICGenJnlLineNo);
            PurchLine.Type::Item:
                PostItemLine(PurchHeader, PurchLine, TempDropShptPostBuffer);
            PurchLine.Type::Resource:
                PostResourceLine(PurchHeader, PurchLine);
            PurchLine.Type::"Charge (Item)":
                PostItemChargeLine(PurchHeader, PurchLine);
            else
                OnPostPurchLineOnTypeCaseElse(PurchHeader, PurchLine, PurchInvHeader, PurchCrMemoHeader, SrcCode, GenJnlPostLine);
        end;

        OnPostPurchLineOnAfterPostByType(PurchHeader, PurchLine, GenJnlPostLine, GenJnlLineDocNo, GenJnlLineExtDocNo, GenJnlLineDocType, SrcCode);

        if (PurchLine.Type <> PurchLine.Type::" ") and (PurchLine."Qty. to Invoice" <> 0) then begin
            AdjustPrepmtAmountLCY(PurchHeader, PurchLine);
#if not CLEAN23
            if UseLegacyInvoicePosting() then begin
                FillInvoicePostBuffer(PurchHeader, PurchLine, PurchLineACY);
                InsertTempInvoicePostBufferReverseCharge(TempInvoicePostBuffer);
                FillInvoicePostBufferGST(PurchHeader, PurchLine, PurchLineACY);
            end else
#endif
                InvoicePostingInterface.PrepareLine(PurchHeader, PurchLine, PurchLineACY);
        end;

        IsHandled := false;
        OnPostPurchLineOnBeforeInsertReceiptLine(
            PurchHeader, PurchLine, IsHandled, PurchRcptHeader, RoundingLineInserted, CostBaseAmount, xPurchLine, ReturnShptHeader, TempTrackingSpecification, ItemLedgShptEntryNo, SrcCode, PreviewMode);
        if not IsHandled then
            if (PurchRcptHeader."No." <> '') and (PurchLine."Receipt No." = '') and
               not RoundingLineInserted and not PurchLine."Prepayment Line"
            then
                InsertReceiptLine(PurchRcptHeader, PurchLine, CostBaseAmount);

        IsHandled := false;
        OnPostPurchLineOnBeforeInsertReturnShipmentLine(PurchHeader, PurchLine, IsHandled, ReturnShptHeader, TempPurchLineGlobal, RoundingLineInserted, xPurchLine);
        if not IsHandled then
            if (ReturnShptHeader."No." <> '') and (PurchLine."Return Shipment No." = '') and
               not RoundingLineInserted
            then
                InsertReturnShipmentLine(ReturnShptHeader, PurchLine, CostBaseAmount);

        OnPostPurchLineOnAfterInsertReturnShipmentLine(PurchHeader, PurchLine, ReturnShptHeader, TempPurchLineGlobal, RoundingLineInserted, xPurchLine, PurchCrMemoHeader);

        IsHandled := false;
        if PurchHeader.Invoice then
            if PurchLine."Document Type" in [PurchLine."Document Type"::Order, PurchLine."Document Type"::Invoice] then begin
                OnPostPurchLineOnBeforeInsertInvoiceLine(PurchHeader, PurchLine, IsHandled, PurchInvLine);
                if not IsHandled then begin
                    PurchInvLine.InitFromPurchLine(PurchInvHeader, xPurchLine);
                    ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, CopyStr(PurchInvLine.RowID1(), 1, 100));
                    if GLSetup.CheckFullGSTonPrepayment(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group") then
                        if PurchLine."Prepayment Line" then
                            PurchInvLine."Inv. Discount Amount" := -InvDiscAmt
                        else
                            PurchInvLine."Inv. Discount Amount" := xPurchLine."Inv. Discount Amount";
                    SetInvoiceOrderNo(PurchLine, PurchInvLine);

                    OnBeforePurchInvLineInsert(PurchInvLine, PurchInvHeader, PurchLine, SuppressCommit, xPurchLine);
                    if not IsNullGuid(PurchLine.SystemId) then begin
                        SearchPurchInvLine.SetRange(SystemId, PurchLine.SystemId);
                        if SearchPurchInvLine.IsEmpty() then begin
                            PurchInvLine.SystemId := PurchLine.SystemId;
                            PurchInvLine.Insert(true, true);
                        end else begin
                            Session.LogMessage('0000DD4', SameIdFoundLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PurchLinePostCategoryTok);
                            PurchInvLine.Insert(true);
                        end;
                    end else begin
                        PurchInvLine.Insert(true);
                        Session.LogMessage('0000DDA', EmptyIdFoundLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PurchLinePostCategoryTok);
                    end;
                    OnAfterPurchInvLineInsert(
                        PurchInvLine, PurchInvHeader, PurchLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit,
                        PurchHeader, PurchRcptHeader, TempWhseRcptHeader, ItemJnlPostLine);
#if not CLEAN23
                    if UseLegacyInvoicePosting() then
                        CreatePostedDeferralScheduleFromPurchDoc(xPurchLine, PurchInvLine.GetDocumentType(),
                            PurchInvHeader."No.", PurchInvLine."Line No.", PurchInvHeader."Posting Date")
                    else
#endif
                        InvoicePostingInterface.CreatePostedDeferralSchedule(
                            xPurchLine, PurchInvLine.GetDocumentType(),
                            PurchInvHeader."No.", PurchInvLine."Line No.", PurchInvHeader."Posting Date");
                    OnPostPurchLineOnAfterCreatePostedDeferralScheduleFromPurchDoc(
                        PurchInvLine, PurchInvHeader, PurchLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit, xPurchLine);
                    SavePrepmtVATDeducted(PurchLine);
                end;
            end else begin // Credit Memo
                OnPostPurchLineOnBeforeInsertCrMemoLine(PurchHeader, PurchLine, IsHandled, PurchCrMemoLine, xPurchLine);
                if not IsHandled then begin
                    PurchCrMemoLine.InitFromPurchLine(PurchCrMemoHeader, xPurchLine);
                    ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, CopyStr(PurchCrMemoLine.RowID1(), 1, 100));
                    SetCreditMemoOrderNo(PurchLine, PurchCrMemoLine);
                    OnBeforePurchCrMemoLineInsert(PurchCrMemoLine, PurchCrMemoHeader, PurchLine, SuppressCommit, xPurchLine);
                    if not IsNullGuid(PurchLine.SystemId) then begin
                        SearchPurchCrMemoLine.SetRange(SystemId, PurchLine.SystemId);
                        if SearchPurchCrMemoLine.IsEmpty() then begin
                            PurchCrMemoLine.SystemId := PurchLine.SystemId;
                            PurchCrMemoLine.Insert(true, true);
                        end else begin
                            Session.LogMessage('0000DD5', SameIdFoundLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PurchLinePostCategoryTok);
                            PurchCrMemoLine.Insert(true);
                        end;
                    end else begin
                        PurchCrMemoLine.Insert(true);
                        Session.LogMessage('0000DDB', EmptyIdFoundLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PurchLinePostCategoryTok);
                    end;
                    OnAfterPurchCrMemoLineInsert(PurchCrMemoLine, PurchCrMemoHeader, PurchLine, SuppressCommit, PurchHeader, GenJnlLineDocNo, RoundingLineInserted, ItemJnlPostLine);
#if not CLEAN23
                    if UseLegacyInvoicePosting() then
                        CreatePostedDeferralScheduleFromPurchDoc(xPurchLine, PurchCrMemoLine.GetDocumentType(),
                            PurchCrMemoHeader."No.", PurchCrMemoLine."Line No.", PurchCrMemoHeader."Posting Date")
                    else
#endif
                        InvoicePostingInterface.CreatePostedDeferralSchedule(
                            xPurchLine, PurchCrMemoLine.GetDocumentType(),
                            PurchCrMemoHeader."No.", PurchCrMemoLine."Line No.", PurchCrMemoHeader."Posting Date");

                    OnPostPurchLineOnAfterCreatePostedDeferralScheduleFromPurchDocCrMemo(
                        PurchCrMemoLine, PurchCrMemoHeader, PurchLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit, xPurchLine);
                end;
            end;

        OnAfterPostPurchLine(
            PurchHeader, PurchLine, SuppressCommit, PurchInvLine, PurchCrMemoLine, PurchInvHeader, PurchCrMemoHeader, PurchLineACY,
            GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, xPurchLine);
    end;

    local procedure SetInvoiceOrderNo(PurchaseLine: Record "Purchase Line"; var PurchInvLine: Record "Purch. Inv. Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then begin
            PurchInvLine."Order No." := PurchaseLine."Document No.";
            PurchInvLine."Order Line No." := PurchaseLine."Line No.";
        end else
            if PurchRcptLine.Get(PurchaseLine."Receipt No.", PurchaseLine."Receipt Line No.") then begin
                PurchInvLine."Order No." := PurchRcptLine."Order No.";
                PurchInvLine."Order Line No." := PurchRcptLine."Order Line No.";
            end;
    end;

    local procedure SetCreditMemoOrderNo(PurchaseLine: Record "Purchase Line"; var PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then begin
            PurchCrMemoLine."Order No." := PurchaseLine."Document No.";
            PurchCrMemoLine."Order Line No." := PurchaseLine."Line No.";
        end else
            if ReturnShipmentLine.Get(PurchaseLine."Return Shipment No.", PurchaseLine."Return Shipment Line No.") then begin
                PurchCrMemoLine."Order No." := ReturnShipmentLine."Return Order No.";
                PurchCrMemoLine."Order Line No." := ReturnShipmentLine."Return Order Line No.";
            end;
    end;

#if not CLEAN23
    local procedure CheckJobCreditPurchLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemQuantityPurchCredit(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        if PurchLine.IsCreditDocType() then
            if (PurchLine."Job No." <> '') and (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."Qty. to Invoice" <> 0) then
                JobPostLine.CheckItemQuantityPurchCredit(PurchHeader, PurchLine);
    end;
#endif

    local procedure PostInvoice(var PurchHeader: Record "Purchase Header")
    var
        TotalAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostInvoice(PurchHeader, PreviewMode, SuppressCommit, GenJnlPostLine, IsHandled, Window, HideProgressWindow, TotalPurchLine, TotalPurchLineLCY, InvoicePostingInterface, InvoicePostingParameters, GenJnlLineDocNo, GenJnlLineExtDocNo, GenJnlLineDocType, SrcCode);
        if IsHandled then
            exit;

        // Post purchase and VAT to G/L entries from buffer
#if not CLEAN23
        if UseLegacyInvoicePosting() then
            PostInvoicePostingBuffer(PurchHeader, TotalAmount)
        else begin
#endif
            GetInvoicePostingParameters();
            InvoicePostingInterface.SetParameters(InvoicePostingParameters);
            InvoicePostingInterface.SetTotalLines(TotalPurchLine, TotalPurchLineLCY);
            InvoicePostingInterface.PostLines(PurchHeader, GenJnlPostLine, Window, TotalAmount);
#if not CLEAN23
        end;
#endif
        OnPostInvoiceOnAfterPostLines(PurchHeader, SrcCode, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, GenJnlPostLine, TotalPurchLine, TotalPurchLineLCY);

        // Check External Document number
        if PurchSetup."Ext. Doc. No. Mandatory" or (GenJnlLineExtDocNo <> '') then
            CheckExternalDocumentNumber(VendLedgEntry, PurchHeader);

        // Post WHT
        if GLSetup."Enable WHT" then
            PostWHT(PurchHeader, TotalAmount, TotalWHTAmount);

        // Post vendor entries
        if GuiAllowed and not HideProgressWindow then
            Window.Update(4, 1);

#if not CLEAN23
        if UseLegacyInvoicePosting() then
            PostVendorEntry(
                PurchHeader, TotalPurchLine, TotalPurchLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, TotalWHTAmount)
        else
#endif
            InvoicePostingInterface.PostLedgerEntry(PurchHeader, GenJnlPostLine);

        UpdatePurchaseHeader(VendLedgEntry, PurchHeader);

        // Balancing account
        if PurchHeader."Bal. Account No." <> '' then begin
            if GuiAllowed and not HideProgressWindow then
                Window.Update(5, 1);
            OnPostInvoiceOnBeforePostBalancingEntry(PurchHeader, LineCount);
#if not CLEAN23
            OnPostGLAndVendorOnBeforePostBalancingEntry(PurchHeader, TempInvoicePostBuffer);
            if UseLegacyInvoicePosting() then
                PostBalancingEntry(
                    PurchHeader, TotalPurchLine, TotalPurchLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode)
            else
#endif
                InvoicePostingInterface.PostBalancingEntry(PurchHeader, GenJnlPostLine);
        end;

        OnAfterPostInvoice(PurchHeader, GenJnlPostLine, TotalPurchLine, TotalPurchLineLCY, SuppressCommit, VendLedgEntry);
    end;

    local procedure PostGLAccICLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGLAccICLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);
        if IsHandled then
            exit;

        if (PurchLine."No." <> '') and not PurchLine."System-Created Entry" then begin
            CheckGLAccDirectPosting(PurchLine);
            if (PurchLine."Job No." <> '') and (PurchLine."Qty. to Invoice" <> 0) then begin
                IsHandled := false;
                OnPostGLAccICLineOnBeforeCreateJobPurchLine(PurchHeader, PurchLine, IsHandled);
                if not IsHandled then begin
                    CreateJobPurchLine(JobPurchLine, PurchLine, PurchHeader."Prices Including VAT");
                    OnPostGLAccICLineOnAfterCreateJobPurchLine(PurchHeader);
#if not CLEAN23
                    if UseLegacyInvoicePosting() then
                        JobPostLine.PostJobOnPurchaseLine(PurchHeader, PurchInvHeader, PurchCrMemoHeader, JobPurchLine, SrcCode)
                    else
#endif
                    InvoicePostingInterface.PrepareJobLine(PurchHeader, JobPurchLine, PurchLineACY);
                end;
            end;
            OnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine(PurchHeader, PurchLine, xPurchLine, ICGenJnlLineNo);
            if (PurchLine."IC Partner Code" <> '') and PurchHeader.Invoice then
                InsertICGenJnlLine(PurchHeader, xPurchLine, ICGenJnlLineNo);

            OnAfterPostAccICLine(PurchLine, SuppressCommit, PurchHeader, PurchInvHeader, PurchCrMemoHeader);
        end;
    end;

    local procedure CheckGLAccDirectPosting(PurchaseLine: Record "Purchase Line")
    var
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccDirectPosting(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        GLAccount.Get(PurchaseLine."No.");
        GLAccount.TestField("Direct Posting");
    end;

    local procedure PostItemLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemLine(PurchHeader, PurchLine, PurchRcptHeader, RemQtyToBeInvoiced, TempPurchLineGlobal, TempDropShptPostBuffer, RemQtyToBeInvoicedBase, IsHandled);
        if IsHandled then
            exit;

        ItemLedgShptEntryNo := 0;
        if RemQtyToBeInvoiced <> 0 then
            ItemLedgShptEntryNo :=
              PostItemJnlLine(
                PurchHeader, PurchLine,
                RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                RemQtyToBeInvoiced, RemQtyToBeInvoicedBase,
                0, '', DummyTrackingSpecification);

        OnPostItemLineOnBeforePostShipReceive(PurchHeader, PurchLine, TempDropShptPostBuffer, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase);
        if PurchHeader.IsCreditDocType() then begin
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
            ProcessAssocItemJnlLine(PurchHeader, PurchLine, TempDropShptPostBuffer);
        end;

        OnAfterPostItemLine(PurchLine, SuppressCommit, PurchHeader, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase, TempDropShptPostBuffer);
    end;

    local procedure ProcessAssocItemJnlLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessAssocItemJnlLine(PurchLine, IsHandled, TempDropShptPostBuffer, TempTrackingSpecification, ItemLedgShptEntryNo);
        if IsHandled then
            exit;

        if (PurchLine."Qty. to Receive" <> 0) and (PurchLine."Sales Order Line No." <> 0) then begin
            TempDropShptPostBuffer."Order No." := PurchLine."Sales Order No.";
            TempDropShptPostBuffer."Order Line No." := PurchLine."Sales Order Line No.";
            TempDropShptPostBuffer.Quantity := PurchLine."Qty. to Receive";
            TempDropShptPostBuffer."Quantity (Base)" := PurchLine."Qty. to Receive (Base)";
            OnProcessAssocItemJnlLineOnAfterInitTempDropShptPostBuffer(PurchLine, TempDropShptPostBuffer);

            TempDropShptPostBuffer."Item Shpt. Entry No." :=
              PostAssocItemJnlLine(PurchHeader, PurchLine, TempDropShptPostBuffer.Quantity, TempDropShptPostBuffer."Quantity (Base)");
            OnBeforeTempDropShptPostBufferInsert(TempDropShptPostBuffer, PurchLine);
            TempDropShptPostBuffer.Insert();
        end;

        OnAfterProcessAssocItemJnlLine(PurchLine, TempDropShptPostBuffer);
    end;

    local procedure PostItemChargeLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    var
        PurchaseLineBackup: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemChargeLineProcedure(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        if not IsItemChargeLineWithQuantityToInvoice(PurchHeader, PurchLine) then
            exit;

        ItemJnlRollRndg := true;
        PurchaseLineBackup.Copy(PurchLine);
        if FindTempItemChargeAssgntPurch(PurchaseLineBackup."Line No.") then
            repeat
                OnPostItemChargeLineOnBeforePostItemCharge(TempItemChargeAssgntPurch, PurchHeader, PurchaseLineBackup, GenJnlLineDocNo);
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

                OnPostItemChargeLineOnAfterPostItemCharge(TempItemChargeAssgntPurch, PurchHeader, PurchaseLineBackup, PurchLine);
            until TempItemChargeAssgntPurch.Next() = 0;
    end;

    local procedure IsItemChargeLineWithQuantityToInvoice(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeIsItemChargeLineWithQuantityToInvoice(PurchHeader, PurchLine, Result, IsHandled);
        if IsHandled then
            exit;

        exit(PurchHeader.Invoice and (PurchLine."Qty. to Invoice" <> 0));
    end;

    local procedure PostItemTrackingLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TrackingSpecificationExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemTrackingLineOnPostPurchLine(PurchHeader, PurchLine, IsHandled, TempTrackingSpecification, PurchInvHeader, PurchCrMemoHeader, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase);
        if IsHandled then
            exit;

        if PurchLine."Prepayment Line" then
            exit;

        RetrieveInvoiceTrackingSpecificationIfExists(PurchHeader, PurchLine, TempTrackingSpecification, TrackingSpecificationExists);

        PostItemTracking(PurchHeader, PurchLine, TempTrackingSpecification, TrackingSpecificationExists);

        if TrackingSpecificationExists then
            SaveInvoiceSpecification(TempTrackingSpecification);

        OnAfterPostItemTrackingLine(PurchHeader, PurchLine, WhseReceive, WhseShip, InvtPickPutaway);
    end;

    local procedure RetrieveInvoiceTrackingSpecificationIfExists(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean)
    begin
        if PurchaseHeader.Invoice then
            if PurchaseLine."Qty. to Invoice" = 0 then
                TrackingSpecificationExists := false
            else
                TrackingSpecificationExists :=
                  PurchLineReserve.RetrieveInvoiceSpecification(PurchaseLine, TempTrackingSpecification);

        OnAfterRetrieveInvoiceTrackingSpecificationIfExists(PurchaseHeader, PurchaseLine, TempTrackingSpecification, TrackingSpecificationExists);
    end;

    procedure PostItemJnlLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; QtyToBeReceived: Decimal; QtyToBeReceivedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; ItemLedgShptEntryNo: Integer; ItemChargeNo: Code[20]; TrackingSpecification: Record "Tracking Specification") Result: Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        OriginalItemJnlLine: Record "Item Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        PostWhseJnlLine: Boolean;
        CheckApplToItemEntry: Boolean;
        PostJobConsumptionBeforePurch: Boolean;
        IsHandled: Boolean;
    begin
        ClearRemAmt(PurchHeader);

        IsHandled := false;
        OnBeforePostItemJnlLine(
          PurchHeader, PurchLine, QtyToBeReceived, QtyToBeReceivedBase, QtyToBeInvoiced, QtyToBeInvoicedBase,
          ItemLedgShptEntryNo, ItemChargeNo, TrackingSpecification, SuppressCommit, IsHandled, ItemJnlPostLine, Result);
        if IsHandled then
            exit(Result);

        ItemJnlLine.Init();
        ItemJnlLine.CopyFromPurchHeader(PurchHeader);
        ItemJnlLine.CopyFromPurchLine(PurchLine);
        ItemJnlLine."Vendor Exchange Rate (ACY)" := PurchHeader."Vendor Exchange Rate (ACY)";

        PostItemJnlLineCopyDocumentFields(ItemJnlLine, PurchHeader, PurchLine, QtyToBeInvoiced, QtyToBeReceived);

        if QtyToBeInvoiced <> 0 then
            ItemJnlLine."Invoice No." := GenJnlLineDocNo;

        ItemJnlLine.CopyTrackingFromSpec(TrackingSpecification);
        ItemJnlLine."Item Shpt. Entry No." := ItemLedgShptEntryNo;

        ItemJnlLine.Quantity := QtyToBeReceived;
        ItemJnlLine."Quantity (Base)" := QtyToBeReceivedBase;
        ItemJnlLine."Invoiced Quantity" := QtyToBeInvoiced;
        ItemJnlLine."Invoiced Qty. (Base)" := QtyToBeInvoicedBase;

        if ItemChargeNo <> '' then begin
            ItemJnlLine."Item Charge No." := ItemChargeNo;
            PurchLine."Qty. to Invoice" := QtyToBeInvoiced;
            OnPostItemJnlLineOnAfterCopyItemCharge(ItemJnlLine, TempItemChargeAssgntPurch);
        end;

        OnPostItemJnlLineOnBeforeInitAmount(ItemJnlLine, PurchHeader, PurchLine);
        if QtyToBeInvoiced <> 0 then
            CalcItemJnlLineToBeInvoicedAmounts(ItemJnlLine, PurchHeader, PurchLine, QtyToBeInvoiced, QtyToBeInvoicedBase)
        else
            CalcItemJnlLineToBeReceivedAmounts(ItemJnlLine, PurchHeader, PurchLine, QtyToBeReceived);

        OnPostItemJnlLineOnAfterPrepareItemJnlLine(
            ItemJnlLine, PurchLine, PurchHeader, PreviewMode, GenJnlLineDocNo, TrackingSpecification, QtyToBeReceived);

        if PurchLine."Prod. Order No." <> '' then
            PostItemJnlLineCopyProdOrder(PurchLine, ItemJnlLine, QtyToBeReceived, QtyToBeInvoiced);

        CheckApplToItemEntry := SetCheckApplToItemEntry(PurchLine, PurchHeader, ItemJnlLine);

        IsHandled := false;
        OnPostItemJnlLineOnAfterSetCheckApplToItemEntry(PurchLine, IsHandled);
        if not IsHandled then begin
            PostWhseJnlLine := ShouldPostWhseJnlLine(PurchLine, ItemJnlLine, TempWhseJnlLine);

            if QtyToBeReceivedBase <> 0 then begin
                if PurchLine.IsCreditDocType() then
                    PurchLineReserve.TransferPurchLineToItemJnlLine(
                      PurchLine, ItemJnlLine, -QtyToBeReceivedBase, CheckApplToItemEntry)
                else
                    PurchLineReserve.TransferPurchLineToItemJnlLine(
                      PurchLine, ItemJnlLine, QtyToBeReceivedBase, CheckApplToItemEntry);

                if CheckApplToItemEntry and PurchLine.IsInventoriableItem() then
                    PurchLine.TestField("Appl.-to Item Entry");
            end;

            CollectPurchaseLineReservEntries(TempReservationEntry, ItemJnlLine);
            OriginalItemJnlLine := ItemJnlLine;

            TempHandlingSpecification.Reset();
            TempHandlingSpecification.DeleteAll();

            IsHandled := false;
            OnBeforeItemJnlPostLine(ItemJnlLine, PurchLine, PurchHeader, SuppressCommit, IsHandled, WhseRcptHeader, WhseShptHeader, TempItemChargeAssgntPurch, TempWhseRcptHeader, PurchInvHeader, PurchCrMemoHeader);
            if not IsHandled then
                if PurchLine."Job No." <> '' then begin
                    PostJobConsumptionBeforePurch := ItemJnlLine.IsPurchaseReturn();
                    if PostJobConsumptionBeforePurch then
                        PostItemJnlLineJobConsumption(
                          PurchHeader, PurchLine, OriginalItemJnlLine, TempReservationEntry, QtyToBeInvoiced, QtyToBeReceived,
                          TempHandlingSpecification, 0);
                end;

            IsHandled := false;
            OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck(ItemJnlLine, PurchLine, DropShipOrder, PurchHeader, WhseReceive, QtyToBeReceived, QtyToBeReceivedBase, QtyToBeInvoiced, QtyToBeInvoicedBase, IsHandled);
            if not IsHandled then
                RunItemJnlPostLine(ItemJnlLine);

            OnPostItemJnlLineOnAfterItemJnlPostLineRunWithCheck(ItemJnlLine, PurchLine, PurchHeader, QtyToBeReceived, WhseReceive, TempWhseRcptHeader, QtyToBeReceivedBase);

            if not ItemJnlLine.Subcontracting then
                PostItemJnlLineTracking(
                  PurchLine, TempWhseTrackingSpecification, TempTrackingSpecificationChargeAssmt, PostWhseJnlLine, QtyToBeInvoiced);

            OnBeforePostItemJnlLineJobConsumption(
              ItemJnlLine, PurchLine, PurchInvHeader, PurchCrMemoHeader, QtyToBeInvoiced, QtyToBeInvoicedBase, SrcCode);

            if PurchLine."Job No." <> '' then
                if not PostJobConsumptionBeforePurch then
                    PostItemJnlLineJobConsumption(
                      PurchHeader, PurchLine, OriginalItemJnlLine, TempReservationEntry, QtyToBeInvoiced, QtyToBeReceived,
                      TempHandlingSpecification, ItemJnlLine."Item Shpt. Entry No.");

            OnPostItemJnlLineOnAfterPostItemJnlLineJobConsumption(ItemJnlLine, PurchHeader, PurchLine, OriginalItemJnlLine, TempReservationEntry, TempHandlingSpecification, QtyToBeInvoiced, QtyToBeReceived);

            if PostWhseJnlLine then begin
                OnPostItemJnlLineOnBeforePostWhseJnlLine(TempHandlingSpecification, TempWhseJnlLine, ItemJnlLine);
                PostItemJnlLineWhseLine(TempWhseJnlLine, TempWhseTrackingSpecification, PurchLine, PostJobConsumptionBeforePurch);
                OnAfterPostWhseJnlLine(PurchLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit);
            end;
            if (PurchLine.Type = PurchLine.Type::Item) and PurchHeader.Invoice then
                PostItemJnlLineItemCharges(
                  PurchHeader, PurchLine, OriginalItemJnlLine, ItemJnlLine."Item Shpt. Entry No.", TempTrackingSpecificationChargeAssmt);
        end;

        OnAfterPostItemJnlLine(ItemJnlLine, PurchLine, PurchHeader, ItemJnlPostLine, WhseJnlPostLine);

        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure CalcItemJnlLineToBeInvoicedAmounts(var ItemJnlLine: Record "Item Journal Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    var
        Factor: Decimal;
    begin
        if (QtyToBeInvoicedBase <> 0) and (PurchaseLine.Type = PurchaseLine.Type::Item) then
            Factor := QtyToBeInvoicedBase / PurchaseLine."Qty. to Invoice (Base)"
        else
            Factor := QtyToBeInvoiced / PurchaseLine."Qty. to Invoice";
        OnPostItemJnlLineOnAfterSetFactor(PurchaseLine, Factor, GenJnlLineExtDocNo, ItemJnlLine);
        ItemJnlLine.Amount :=
            (PurchaseLine.Amount + NonDeductibleVAT.GetNonDeductibleVATAmountForItemCost(PurchaseLine)) * Factor + RemAmt;
        if PurchaseHeader."Prices Including VAT" then
            ItemJnlLine."Discount Amount" :=
                (PurchaseLine."Line Discount Amount" + PurchaseLine."Inv. Discount Amount") /
                (1 + PurchaseLine."VAT %" / 100) * Factor + RemDiscAmt
        else
            ItemJnlLine."Discount Amount" :=
                (PurchaseLine."Line Discount Amount" + PurchaseLine."Inv. Discount Amount") * Factor + RemDiscAmt;
        RemAmt := ItemJnlLine.Amount - Round(ItemJnlLine.Amount);
        RemDiscAmt := ItemJnlLine."Discount Amount" - Round(ItemJnlLine."Discount Amount");
        ItemJnlLine.Amount := Round(ItemJnlLine.Amount);
        ItemJnlLine."Discount Amount" := Round(ItemJnlLine."Discount Amount");
    end;

    local procedure CalcItemJnlLineToBeReceivedAmounts(var ItemJnlLine: Record "Item Journal Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToBeReceived: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcItemJnlLineToBeReceivedAmounts(ItemJnlLine, PurchaseHeader, PurchaseLine, QtyToBeReceived, RemAmt, IsHandled);
        if IsHandled then
            exit;

        if PurchaseHeader."Prices Including VAT" then
            ItemJnlLine.Amount :=
                (QtyToBeReceived * PurchaseLine."Direct Unit Cost" * (1 - PurchaseLine."Line Discount %" / 100) /
                (1 + PurchaseLine."VAT %" / 100)) + RemAmt
        else
            ItemJnlLine.Amount :=
                (QtyToBeReceived * PurchaseLine."Direct Unit Cost" * (1 - PurchaseLine."Line Discount %" / 100)) + RemAmt;
        RemAmt := ItemJnlLine.Amount - Round(ItemJnlLine.Amount);
        if PurchaseHeader."Currency Code" <> '' then
            ItemJnlLine.Amount :=
                Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader."Posting Date", PurchaseHeader."Currency Code",
                    ItemJnlLine.Amount, PurchaseHeader."Currency Factor"))
        else
            ItemJnlLine.Amount := Round(ItemJnlLine.Amount);
    end;


    local procedure ClearRemAmt(PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearRemAmt(PurchHeader, IsHandled, ItemJnlRollRndg, RemAmt, RemDiscAmt);
        if IsHandled then
            exit;

        if not ItemJnlRollRndg then begin
            RemAmt := 0;
            RemDiscAmt := 0;
        end;
    end;

    local procedure PostItemJnlLineCopyDocumentFields(var ItemJnlLine: Record "Item Journal Line"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; QtyToBeInvoiced: Decimal; QtyToBeReceived: Decimal)
    begin
        OnPostItemJnlLineOnBeforeCopyDocumentFields(ItemJnlLine, PurchHeader, PurchLine, WhseReceive, WhseShip, InvtPickPutaway);

        if QtyToBeReceived = 0 then
            if PurchLine.IsCreditDocType() then
                ItemJnlLine.CopyDocumentFields(
                  ItemJnlLine."Document Type"::"Purchase Credit Memo", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series")
            else
                ItemJnlLine.CopyDocumentFields(
                  ItemJnlLine."Document Type"::"Purchase Invoice", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series")
        else begin
            if PurchLine.IsCreditDocType() then
                ItemJnlLine.CopyDocumentFields(
                  ItemJnlLine."Document Type"::"Purchase Return Shipment",
                  ReturnShptHeader."No.", ReturnShptHeader."Vendor Authorization No.", SrcCode, ReturnShptHeader."No. Series")
            else
                ItemJnlLine.CopyDocumentFields(
                  ItemJnlLine."Document Type"::"Purchase Receipt",
                  PurchRcptHeader."No.", PurchRcptHeader."Vendor Shipment No.", SrcCode, PurchRcptHeader."No. Series");
            if QtyToBeInvoiced <> 0 then
                if ItemJnlLine."Document No." = '' then
                    if PurchLine."Document Type" = PurchLine."Document Type"::"Credit Memo" then
                        ItemJnlLine.CopyDocumentFields(
                          ItemJnlLine."Document Type"::"Purchase Credit Memo", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series")
                    else
                        ItemJnlLine.CopyDocumentFields(
                          ItemJnlLine."Document Type"::"Purchase Invoice", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series");
        end;

        OnPostItemJnlLineOnAfterCopyDocumentFields(ItemJnlLine, PurchLine, TempWhseRcptHeader, TempWhseShptHeader, PurchRcptHeader, GenJnlLineExtDocNo, QtyToBeInvoiced);
    end;

    local procedure PostItemJnlLineCopyProdOrder(PurchLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeReceived: Decimal; QtyToBeInvoiced: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLineCopyProdOrder(PurchLine, ItemJnlLine, QtyToBeReceived, QtyToBeInvoiced, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.Subcontracting := true;
        ItemJnlLine."Quantity (Base)" := CalcBaseQty(PurchLine."No.", PurchLine."Unit of Measure Code", QtyToBeReceived, PurchLine."Qty. Rounding Precision (Base)");
        ItemJnlLine."Invoiced Qty. (Base)" := CalcBaseQty(PurchLine."No.", PurchLine."Unit of Measure Code", QtyToBeInvoiced, PurchLine."Qty. Rounding Precision (Base)");
        ItemJnlLine."Unit Cost" := PurchLine."Unit Cost (LCY)";
        ItemJnlLine."Unit Cost (ACY)" := PurchLine."Unit Cost";
        ItemJnlLine."Output Quantity (Base)" := ItemJnlLine."Quantity (Base)";
        ItemJnlLine."Output Quantity" := QtyToBeReceived;
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Output;
        ItemJnlLine.Type := ItemJnlLine.Type::"Work Center";
        ItemJnlLine."No." := PurchLine."Work Center No.";
        ItemJnlLine."Routing No." := PurchLine."Routing No.";
        ItemJnlLine."Routing Reference No." := PurchLine."Routing Reference No.";
        ItemJnlLine."Operation No." := PurchLine."Operation No.";
        ItemJnlLine."Work Center No." := PurchLine."Work Center No.";
        ItemJnlLine."Unit Cost Calculation" := ItemJnlLine."Unit Cost Calculation"::Units;
        if PurchLine.Finished then
            ItemJnlLine.Finished := PurchLine.Finished;
        OnAfterPostItemJnlLineCopyProdOrder(ItemJnlLine, PurchLine, PurchRcptHeader, QtyToBeReceived, SuppressCommit, QtyToBeInvoiced);
    end;

    local procedure PostItemJnlLineItemCharges(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var OriginalItemJnlLine: Record "Item Journal Line"; ItemShptEntryNo: Integer; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary)
    var
        ItemChargePurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLineItemCharges(PurchHeader, PurchLine, IsHandled);
        if not IsHandled then begin
            ClearItemChargeAssgntFilter();
            TempItemChargeAssgntPurch.SetCurrentKey(
            "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
            TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", PurchLine."Document Type");
            TempItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", PurchLine."Document No.");
            TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", PurchLine."Line No.");
            if TempItemChargeAssgntPurch.Find('-') then
                repeat
                    PurchLine.TestField("Allow Item Charge Assignment");
                    GetItemChargeLine(PurchHeader, ItemChargePurchLine);
                    OnPostItemJnlLineItemChargesOnAfterGetItemChargeLine(ItemChargePurchLine, PurchLine);
                    ItemChargePurchLine.CalcFields("Qty. Assigned");
                    if (ItemChargePurchLine."Qty. to Invoice" <> 0) or
                    (Abs(ItemChargePurchLine."Qty. Assigned") < Abs(ItemChargePurchLine."Quantity Invoiced"))
                    then begin
                        OriginalItemJnlLine."Item Shpt. Entry No." := ItemShptEntryNo;
                        PostItemChargePerOrder(
                        PurchHeader, PurchLine, OriginalItemJnlLine, ItemChargePurchLine, TempTrackingSpecificationChargeAssmt);
                        TempItemChargeAssgntPurch.Mark(true);
                    end;
                until TempItemChargeAssgntPurch.Next() = 0;
        end;

        OnAfterPostItemJnlLineItemCharges(PurchHeader, PurchLine);
    end;

    local procedure PostItemJnlLineTracking(PurchLine: Record "Purchase Line"; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary; PostWhseJnlLine: Boolean; QtyToBeInvoiced: Decimal)
    begin
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) then begin
            OnPostItemJnlLineTrackingOnBeforeTempHandlingSpecificationFind(PurchLine, TempHandlingSpecification);
            if TempHandlingSpecification.Find('-') then
                repeat
                    TempTrackingSpecification := TempHandlingSpecification;
                    TempTrackingSpecification.SetSourceFromPurchLine(PurchLine);
                    if TempTrackingSpecification.Insert() then;
                    if QtyToBeInvoiced <> 0 then begin
                        TempTrackingSpecificationInv := TempTrackingSpecification;
                        if TempTrackingSpecificationInv.Insert() then;
                    end;
                    if PostWhseJnlLine then begin
                        TempWhseTrackingSpecification := TempTrackingSpecification;
                        if TempWhseTrackingSpecification.Insert() then;
                    end;
                    TempTrackingSpecificationChargeAssmt := TempTrackingSpecification;
                    TempTrackingSpecificationChargeAssmt.Insert();
                until TempHandlingSpecification.Next() = 0;
        end;
    end;

    local procedure PostItemJnlLineWhseLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; PurchLine: Record "Purchase Line"; PostBefore: Boolean)
    var
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        PositiveWhseEntryCreated: Boolean;
    begin
        ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempWhseTrackingSpecification, false);
        OnPostItemJnlLineWhseLineOnBeforeTempWhseJnlLine2Find(TempWhseJnlLine2, PurchLine, WhseReceive, WhseShip, InvtPickPutaway);
        if TempWhseJnlLine2.Find('-') then
            repeat
                PositiveWhseEntryCreated := false;
                if PurchLine.IsCreditDocType() and (PurchLine.Quantity > 0) or
                   PurchLine.IsInvoiceDocType() and (PurchLine.Quantity < 0)
                then
                    PositiveWhseEntryCreated := CreatePositiveEntry(TempWhseJnlLine2, PurchLine."Job No.", PostBefore);

                OnPostItemJnlLineWhseLineOnBeforePostSingleLine(WhseShip, WhseReceive, InvtPickPutaway, TempWhseJnlLine2);
                WhseJnlPostLine.Run(TempWhseJnlLine2);

                if not PositiveWhseEntryCreated then
                    if RevertWarehouseEntry(TempWhseJnlLine2, PurchLine."Job No.", PostBefore) then begin
                        WhseJnlPostLine.Run(TempWhseJnlLine2);
                        OnPostItemJnlLineWhseLineOnAfterPostRevert(TempWhseJnlLine2, PurchLine);
                    end;
            until TempWhseJnlLine2.Next() = 0;
        TempWhseTrackingSpecification.DeleteAll();
    end;

    local procedure ShouldPostWhseJnlLine(PurchLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldPostWhseJnlLine(PurchLine, Result, IsHandled, ItemJnlLine, TempWhseJnlLine, WhseReceive, WhseShip, InvtPickPutaway, SrcCode);
        if IsHandled then
            exit(Result);

        if (PurchLine."Location Code" <> '') and (PurchLine.Type = PurchLine.Type::Item) and (ItemJnlLine.Quantity <> 0) and
            not ItemJnlLine.Subcontracting and PurchLine.IsInventoriableItem()
        then begin
            GetLocation(PurchLine."Location Code");
            if ((PurchLine."Document Type" in [PurchLine."Document Type"::Invoice, PurchLine."Document Type"::"Credit Memo"]) and
                Location."Directed Put-away and Pick") or
               (Location."Bin Mandatory" and not (WhseReceive or WhseShip or InvtPickPutaway or PurchLine."Drop Shipment"))
            then begin
                CreateWhseJnlLine(ItemJnlLine, PurchLine, TempWhseJnlLine);
                exit(true);
            end;
        end;
    end;

    local procedure PostItemChargePerOrder(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; ItemJnlLine2: Record "Item Journal Line"; ItemChargePurchLine: Record "Purchase Line"; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary)
    var
        QtyToInvoice: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemChargePerOrder(
          PurchHeader, PurchLine, ItemJnlLine2, ItemChargePurchLine, TempTrackingSpecificationChargeAssmt, SuppressCommit,
          TempItemChargeAssgntPurch, IsHandled);
        if not IsHandled then begin
            PurchLine.TestField("Allow Item Charge Assignment", true);
            ItemJnlLine2."Document No." := GenJnlLineDocNo;
            ItemJnlLine2."External Document No." := GenJnlLineExtDocNo;
            ItemJnlLine2."Item Charge No." := TempItemChargeAssgntPurch."Item Charge No.";
            ItemJnlLine2.Description := ItemChargePurchLine.Description;
            ItemJnlLine2."Document Line No." := ItemChargePurchLine."Line No.";
            ItemJnlLine2."Unit of Measure Code" := '';
            ItemJnlLine2."Qty. per Unit of Measure" := 1;
            if TempItemChargeAssgntPurch."Document Type" in [TempItemChargeAssgntPurch."Document Type"::"Return Order", TempItemChargeAssgntPurch."Document Type"::"Credit Memo"] then
                QtyToInvoice :=
                CalcQtyToInvoice(PurchLine."Return Qty. to Ship (Base)", PurchLine."Qty. to Invoice (Base)")
            else
                QtyToInvoice :=
                CalcQtyToInvoice(PurchLine."Qty. to Receive (Base)", PurchLine."Qty. to Invoice (Base)");
            if ItemJnlLine2."Invoiced Quantity" = 0 then begin
                ItemJnlLine2."Invoiced Quantity" := ItemJnlLine2.Quantity;
                ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";
            end;
            ItemJnlLine2.Amount := TempItemChargeAssgntPurch."Amount to Handle" * ItemJnlLine2."Invoiced Qty. (Base)" / QtyToInvoice;
            if TempItemChargeAssgntPurch."Document Type" in [TempItemChargeAssgntPurch."Document Type"::"Return Order", TempItemChargeAssgntPurch."Document Type"::"Credit Memo"] then
                ItemJnlLine2.Amount := -ItemJnlLine2.Amount;
            ItemJnlLine2."Unit Cost (ACY)" :=
            Round(
                ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                Currency."Unit-Amount Rounding Precision");

            PreciseTotalChargeAmt += ItemJnlLine2.Amount;

            if PurchHeader."Currency Code" <> '' then
                ItemJnlLine2.Amount :=
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchHeader.GetUseDate(), PurchHeader."Currency Code", PreciseTotalChargeAmt + TotalPurchLine.Amount, PurchHeader."Currency Factor") -
                RoundedPrevTotalChargeAmt - TotalPurchLineLCY.Amount
            else
                ItemJnlLine2.Amount := PreciseTotalChargeAmt - RoundedPrevTotalChargeAmt;

            RoundedPrevTotalChargeAmt += Round(ItemJnlLine2.Amount, GLSetup."Amount Rounding Precision");

            ItemJnlLine2."Unit Cost" := Round(
                ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)", GLSetup."Unit-Amount Rounding Precision");
            ItemJnlLine2."Applies-to Entry" := ItemJnlLine2."Item Shpt. Entry No.";
            ItemJnlLine2."Overhead Rate" := 0;

            if PurchHeader."Currency Code" <> '' then
                ItemJnlLine2."Discount Amount" := Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                      (ItemChargePurchLine."Inv. Discount Amount" + ItemChargePurchLine."Line Discount Amount") *
                       ItemJnlLine2."Invoiced Qty. (Base)" /
                      ItemChargePurchLine."Quantity (Base)" * TempItemChargeAssgntPurch."Qty. to Handle" / QtyToInvoice,
                      PurchHeader."Currency Factor"), GLSetup."Amount Rounding Precision")
            else
                ItemJnlLine2."Discount Amount" := Round(
                    (ItemChargePurchLine."Line Discount Amount" + ItemChargePurchLine."Inv. Discount Amount") *
                    ItemJnlLine2."Invoiced Qty. (Base)" /
                    ItemChargePurchLine."Quantity (Base)" * TempItemChargeAssgntPurch."Qty. to Handle" / QtyToInvoice,
                    GLSetup."Amount Rounding Precision");

            ItemJnlLine2."Shortcut Dimension 1 Code" := ItemChargePurchLine."Shortcut Dimension 1 Code";
            ItemJnlLine2."Shortcut Dimension 2 Code" := ItemChargePurchLine."Shortcut Dimension 2 Code";
            ItemJnlLine2."Dimension Set ID" := ItemChargePurchLine."Dimension Set ID";
            ItemJnlLine2."Gen. Prod. Posting Group" := ItemChargePurchLine."Gen. Prod. Posting Group";

            OnPostItemChargePerOrderOnAfterCopyToItemJnlLine(
                ItemJnlLine2, ItemChargePurchLine, GLSetup, QtyToInvoice, TempItemChargeAssgntPurch, PurchLine);

            PostItemTrackingItemChargePerOrder(PurchHeader, ItemJnlLine2, TempTrackingSpecificationChargeAssmt);
        end;

        OnAfterPostItemChargePerOrder(PurchHeader, PurchLine);
    end;

    local procedure PostItemTrackingItemChargePerOrder(PurchHeader: Record "Purchase Header"; var ItemJnlLine2: Record "Item Journal Line"; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary)
    var
        NonDistrItemJnlLine: Record "Item Journal Line";
        OriginalAmt: Decimal;
        OriginalAmtACY: Decimal;
        OriginalDiscountAmt: Decimal;
        OriginalQty: Decimal;
        SignFactor: Integer;
        Factor: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemTrackingItemChargePerOrder(TempTrackingSpecificationInv, IsHandled, ItemJnlLine2, TempTrackingSpecificationChargeAssmt);
        if IsHandled then
            exit;

        TempTrackingSpecificationChargeAssmt.Reset();
        TempTrackingSpecificationChargeAssmt.SetRange("Source Type", DATABASE::"Purchase Line");
        TempTrackingSpecificationChargeAssmt.SetRange("Source ID", TempItemChargeAssgntPurch."Applies-to Doc. No.");
        TempTrackingSpecificationChargeAssmt.SetRange("Source Ref. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
        if TempTrackingSpecificationChargeAssmt.IsEmpty() then
            RunItemJnlPostLine(ItemJnlLine2)
        else begin
            TempTrackingSpecificationChargeAssmt.FindSet();
            NonDistrItemJnlLine := ItemJnlLine2;
            OriginalAmt := NonDistrItemJnlLine.Amount;
            OriginalAmtACY := NonDistrItemJnlLine."Amount (ACY)";
            OriginalDiscountAmt := NonDistrItemJnlLine."Discount Amount";
            OriginalQty := NonDistrItemJnlLine."Quantity (Base)";
            if (TempTrackingSpecificationChargeAssmt."Quantity (Base)" / OriginalQty) > 0 then
                SignFactor := 1
            else
                SignFactor := -1;
            repeat
                Factor := TempTrackingSpecificationChargeAssmt."Quantity (Base)" / OriginalQty * SignFactor;
                OnPostItemTrackingItemChargePerOrderOnAfterCalcFactor(NonDistrItemJnlLine, ItemJnlLine2, TempTrackingSpecificationChargeAssmt, SignFactor, Factor);
                if Abs(TempTrackingSpecificationChargeAssmt."Quantity (Base)") < Abs(NonDistrItemJnlLine."Quantity (Base)") then begin
                    ItemJnlLine2."Quantity (Base)" := TempTrackingSpecificationChargeAssmt."Quantity (Base)";
                    ItemJnlLine2."Invoiced Qty. (Base)" := ItemJnlLine2."Quantity (Base)";

                    if PurchHeader."Currency Code" <> '' then begin
                        PreciseTotalChargeAmt +=
                          CurrExchRate.ExchangeAmtLCYToFCY(
                            PurchHeader.GetUseDate(), PurchHeader."Currency Code", OriginalAmt * Factor, PurchHeader."Currency Factor");
                        ItemJnlLine2.Amount :=
                          CurrExchRate.ExchangeAmtFCYToLCY(
                            PurchHeader.GetUseDate(), PurchHeader."Currency Code", PreciseTotalChargeAmt + TotalPurchLine.Amount, PurchHeader."Currency Factor") -
                          RoundedPrevTotalChargeAmt - TotalPurchLineLCY.Amount;
                    end else begin
                        PreciseTotalChargeAmt += OriginalAmt * Factor;
                        ItemJnlLine2.Amount := PreciseTotalChargeAmt - RoundedPrevTotalChargeAmt;
                    end;

                    PreciseTotalChargeAmtACY += OriginalAmtACY * Factor;
                    ItemJnlLine2."Amount (ACY)" := PreciseTotalChargeAmtACY - RoundedPrevTotalChargeAmtACY;

                    ItemJnlLine2.Amount :=
                        Round(ItemJnlLine2.Amount, GLSetup."Amount Rounding Precision");
                    ItemJnlLine2."Amount (ACY)" :=
                        Round(ItemJnlLine2."Amount (ACY)", Currency."Amount Rounding Precision");

                    RoundedPrevTotalChargeAmt += ItemJnlLine2.Amount;
                    RoundedPrevTotalChargeAmtACY += ItemJnlLine2."Amount (ACY)";

                    ItemJnlLine2."Unit Cost (ACY)" :=
                      Round(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                        Currency."Unit-Amount Rounding Precision") * SignFactor;
                    ItemJnlLine2."Unit Cost" :=
                      Round(ItemJnlLine2.Amount / ItemJnlLine2."Invoiced Qty. (Base)",
                        GLSetup."Unit-Amount Rounding Precision") * SignFactor;
                    ItemJnlLine2."Discount Amount" :=
                      Round(OriginalDiscountAmt * Factor, GLSetup."Amount Rounding Precision");
                    ItemJnlLine2."Item Shpt. Entry No." := TempTrackingSpecificationChargeAssmt."Item Ledger Entry No.";
                    ItemJnlLine2."Applies-to Entry" := TempTrackingSpecificationChargeAssmt."Item Ledger Entry No.";
                    ItemJnlLine2.CopyTrackingFromSpec(TempTrackingSpecificationChargeAssmt);
                    RunItemJnlPostLine(ItemJnlLine2);
                    ItemJnlLine2."Location Code" := NonDistrItemJnlLine."Location Code";
                    OnPostItemTrackingItemChargePerOrderOnAfterUpdateItemJnlLine2LocationCode(ItemJnlLine2);
                    NonDistrItemJnlLine."Quantity (Base)" -= TempTrackingSpecificationChargeAssmt."Quantity (Base)";
                    NonDistrItemJnlLine.Amount -= (ItemJnlLine2.Amount * SignFactor);
                    NonDistrItemJnlLine."Amount (ACY)" -= (ItemJnlLine2."Amount (ACY)" * SignFactor);
                    NonDistrItemJnlLine."Discount Amount" -= (ItemJnlLine2."Discount Amount" * SignFactor);
                end else begin
                    NonDistrItemJnlLine."Quantity (Base)" := TempTrackingSpecificationChargeAssmt."Quantity (Base)";
                    NonDistrItemJnlLine."Invoiced Qty. (Base)" := TempTrackingSpecificationChargeAssmt."Quantity (Base)";
                    NonDistrItemJnlLine."Unit Cost" :=
                      Round(NonDistrItemJnlLine.Amount / NonDistrItemJnlLine."Invoiced Qty. (Base)",
                        GLSetup."Unit-Amount Rounding Precision") * SignFactor;
                    NonDistrItemJnlLine."Unit Cost (ACY)" :=
                      Round(NonDistrItemJnlLine.Amount / NonDistrItemJnlLine."Invoiced Qty. (Base)",
                        Currency."Unit-Amount Rounding Precision") * SignFactor;
                    NonDistrItemJnlLine."Item Shpt. Entry No." := TempTrackingSpecificationChargeAssmt."Item Ledger Entry No.";
                    NonDistrItemJnlLine."Applies-to Entry" := TempTrackingSpecificationChargeAssmt."Item Ledger Entry No.";
                    NonDistrItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecificationChargeAssmt);
                    RunItemJnlPostLine(NonDistrItemJnlLine);
                    NonDistrItemJnlLine."Location Code" := ItemJnlLine2."Location Code";
                end;
            until TempTrackingSpecificationChargeAssmt.Next() = 0;
        end;
    end;

    local procedure PostItemChargePerRcpt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Sign: Decimal;
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemChargePerRcpt(PurchHeader, PurchLine, TempItemChargeAssgntPurch, IsHandled);
        if IsHandled then
            exit;

        if not PurchRcptLine.Get(
             TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.")
        then
            Error(ReceiptLinesDeletedErr);
        OnPostItemChargePerRcptOnAfterPurchRcptLineGet(PurchRcptLine, PurchLine);

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

        OnPostItemChargePerRcptOnAfterCalcDistributeCharge(PurchHeader, PurchLine, PurchRcptLine, TempItemLedgEntry, DistributeCharge);

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
        Sign: Decimal;
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemChargePerRetShpt(PurchHeader, PurchLine, TempItemChargeAssgntPurch, IsHandled);
        if IsHandled then
            exit;

        ReturnShptLine.Get(
          TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");

        IsHandled := false;
        OnPostItemChargePerRetShptOnBeforeTestJobNo(ReturnShptLine, IsHandled, PurchLine);
        if not IsHandled then
            ReturnShptLine.TestField("Job No.", '');

        Sign := GetSign(PurchLine."Line Amount");
        if PurchLine.IsCreditDocType() then
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
        OnPostItemChargePerRetShptOnAfterCalcDistributeCharge(PurchHeader, PurchLine, ReturnShptLine, TempItemLedgEntry, DistributeCharge);

        if DistributeCharge then
            PostDistributeItemCharge(
              PurchHeader, PurchLine, TempItemLedgEntry, -ReturnShptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Qty. to Handle", Abs(TempItemChargeAssgntPurch."Amount to Handle"),
              Sign, ReturnShptLine."Indirect Cost %")
        else
            PostItemCharge(PurchHeader, PurchLine,
              ReturnShptLine."Item Shpt. Entry No.", -ReturnShptLine."Quantity (Base)",
              Abs(TempItemChargeAssgntPurch."Amount to Handle") * Sign,
              TempItemChargeAssgntPurch."Qty. to Handle",
              ReturnShptLine."Indirect Cost %");

        OnAfterPostItemChargePerRetShpt(PurchLine);
    end;

    local procedure PostItemChargePerTransfer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        TransRcptLine: Record "Transfer Receipt Line";
        ItemApplnEntry: Record "Item Application Entry";
        DummyTrackingSpecification: Record "Tracking Specification";
        PurchLine2: Record "Purchase Line";
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
        TransRcptLine.Get(TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
        PurchLine2 := PurchLine;
        PurchLine2."No." := TempItemChargeAssgntPurch."Item No.";
        PurchLine2."Variant Code" := TransRcptLine."Variant Code";
        PurchLine2."Location Code" := TransRcptLine."Transfer-to Code";
        PurchLine2."Bin Code" := '';
        PurchLine2."Line No." := TempItemChargeAssgntPurch."Document Line No.";
        OnPostItemChargePerTransferOnAfterInitPurchLine2(TransRcptLine, PurchLine2);

        if TransRcptLine."Item Rcpt. Entry No." = 0 then
            PostItemChargePerITTransfer(PurchHeader, PurchLine, TransRcptLine)
        else begin
            TotalAmountToPostFCY := TempItemChargeAssgntPurch."Amount to Assign";
            if PurchHeader."Currency Code" <> '' then
                TotalAmountToPostLCY :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                    TotalAmountToPostFCY, PurchHeader."Currency Factor")
            else
                TotalAmountToPostLCY := TotalAmountToPostFCY;

            TotalDiscAmountToPost :=
              Round(
                PurchLine2."Inv. Discount Amount" / PurchLine2.Quantity * TempItemChargeAssgntPurch."Qty. to Assign",
                GLSetup."Amount Rounding Precision");
            TotalDiscAmountToPost :=
              TotalDiscAmountToPost +
              Round(
                PurchLine2."Line Discount Amount" * (TempItemChargeAssgntPurch."Qty. to Assign" / PurchLine2."Qty. to Invoice"),
                GLSetup."Amount Rounding Precision");

            TotalAmountToPostLCY := Round(TotalAmountToPostLCY, GLSetup."Amount Rounding Precision");

            ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
            ItemApplnEntry.SetRange("Outbound Item Entry No.", TransRcptLine."Item Rcpt. Entry No.");
            ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', TransRcptLine."Item Rcpt. Entry No.");
            ItemApplnEntry.SetRange("Cost Application", true);
            if ItemApplnEntry.FindSet() then
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
                    if TempItemChargeAssgntPurch."Document Type" in [TempItemChargeAssgntPurch."Document Type"::"Return Order", TempItemChargeAssgntPurch."Document Type"::"Credit Memo"] then
                        PurchLine2.Amount := -PurchLine2.Amount;
                    OnPostItemChargePerTransferOnBeforePostItemJnlLine(PurchHeader, PurchLine2, ItemApplnEntry, TransRcptLine, TempItemChargeAssgntPurch);
                    PostItemJnlLine(
                      PurchHeader, PurchLine2,
                      0, 0,
                      ItemApplnEntry.Quantity, ItemApplnEntry.Quantity,
                      PurchLine2."Appl.-to Item Entry", TempItemChargeAssgntPurch."Item Charge No.", DummyTrackingSpecification);
                until ItemApplnEntry.Next() = 0;
        end;

        OnAfterPostItemChargePerTransfer(PurchLine);
    end;

    local procedure PostItemChargePerITTransfer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; TransRcptLine: Record "Transfer Receipt Line")
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemChargePerITTransfer(PurchHeader, PurchLine, TransRcptLine, TempItemChargeAssgntPurch, IsHandled);
        if not IsHandled then begin
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgerEntry,
                DATABASE::"Transfer Receipt Line", 0, TransRcptLine."Document No.",
                '', 0, TransRcptLine."Line No.", TransRcptLine."Quantity (Base)");
            OnPostItemChargePerITTransferOnAfterCollectItemEntryRelation(PurchHeader, PurchLine, TransRcptLine, TempItemLedgerEntry);
            PostDistributeItemCharge(
                PurchHeader, PurchLine, TempItemLedgerEntry, TransRcptLine."Quantity (Base)",
                TempItemChargeAssgntPurch."Qty. to Assign", TempItemChargeAssgntPurch."Amount to Assign", 1, 0);
        end;
    end;

    local procedure PostItemChargePerSalesShpt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Sign: Decimal;
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemChargePerSalesShpt(TempItemChargeAssgntPurch, PurchLine, IsHandled);
        if IsHandled then
            exit;

        if not SalesShptLine.Get(
             TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.")
        then
            Error(RelatedItemLedgEntriesNotFoundErr);

        IsHandled := false;
        OnPostItemChargePerSalesShptOnBeforeTestJobNo(SalesShptLine, IsHandled, PurchLine);
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
        OnPostItemChargePerSalesShptOnAfterCalcDistributeCharge(PurchHeader, PurchLine, SalesShptLine, TempItemLedgEntry, DistributeCharge);

        if DistributeCharge then
            PostDistributeItemCharge(
              PurchHeader, PurchLine, TempItemLedgEntry, -SalesShptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Qty. to Assign", TempItemChargeAssgntPurch."Amount to Assign", Sign, 0)
        else
            PostItemCharge(PurchHeader, PurchLine,
              SalesShptLine."Item Shpt. Entry No.", -SalesShptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              TempItemChargeAssgntPurch."Qty. to Assign", 0);

        OnAfterPostItemChargePerSalesShpt(PurchLine);
    end;

    local procedure PostItemChargePerRetRcpt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Sign: Decimal;
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemChargePerRetRcpt(PurchHeader, PurchLine, TempItemChargeAssgntPurch, IsHandled);
        if IsHandled then
            exit;

        if not ReturnRcptLine.Get(
             TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.")
        then
            Error(RelatedItemLedgEntriesNotFoundErr);

        IsHandled := false;
        OnPostItemChargePerSalesRetRcptOnBeforeTestJobNo(ReturnRcptLine, IsHandled, PurchLine);
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
        OnPostItemChargePerRetRcptOnAfterCalcDistributeCharge(PurchHeader, PurchLine, ReturnRcptLine, TempItemLedgEntry, DistributeCharge);

        if DistributeCharge then
            PostDistributeItemCharge(
              PurchHeader, PurchLine, TempItemLedgEntry, ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Qty. to Handle", TempItemChargeAssgntPurch."Amount to Assign", Sign, 0)
        else
            PostItemCharge(PurchHeader, PurchLine,
              ReturnRcptLine."Item Rcpt. Entry No.", ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Handle" * Sign,
              TempItemChargeAssgntPurch."Qty. to Handle", 0);

        OnAfterPostItemChargePerRetRcpt(PurchLine);
    end;

    procedure PostDistributeItemCharge(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; NonDistrQuantity: Decimal; NonDistrQtyToAssign: Decimal; NonDistrAmountToAssign: Decimal; Sign: Decimal; IndirectCostPct: Decimal)
    var
        Factor: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDistributeItemCharge(PurchHeader, PurchLine, TempItemLedgEntry, NonDistrQuantity, NonDistrQtyToAssign, NonDistrAmountToAssign, Sign, IndirectCostPct, IsHandled);
        if IsHandled then
            exit;

        if TempItemLedgEntry.FindSet() then begin
            repeat
                Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                QtyToAssign := NonDistrQtyToAssign * Factor;
                AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                OnPostDistributeItemChargeOnAfterCalcAmountToAssign(PurchLine, TempItemLedgEntry, QtyToAssign, AmountToAssign, Sign, Factor);
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
            until TempItemLedgEntry.Next() = 0;
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
        ErrorContextElementSalesLine: Codeunit "Error Context Element";
        IsHandled: Boolean;
        ItemShptEntryNo: Integer;
    begin
        SalesOrderHeader.Get(
          SalesOrderHeader."Document Type"::Order, PurchLine."Sales Order No.");
        SalesOrderLine.Get(
          SalesOrderLine."Document Type"::Order, PurchLine."Sales Order No.", PurchLine."Sales Order Line No.");
        ErrorMessageMgt.PushContext(ErrorContextElementSalesLine, SalesOrderLine.RecordId, 0, '');

        IsHandled := false;
        OnPostAssocItemJnlLineOnBeforeInitAssocItemJnlLine(SalesOrderLine, ItemShptEntryNo, IsHandled);
        if IsHandled then
            exit(ItemShptEntryNo);

        InitAssocItemJnlLine(ItemJnlLine, SalesOrderHeader, SalesOrderLine, PurchHeader, QtyToBeShipped, QtyToBeShippedBase);

        IsHandled := false;
        OnPostAssocItemJnlLineOnBeforePost(ItemJnlLine, SalesOrderLine, IsHandled);
        if (SalesOrderLine."Job Contract Entry No." = 0) or IsHandled then begin
            TransferReservToItemJnlLine(SalesOrderLine, ItemJnlLine, PurchLine, QtyToBeShippedBase, true);
            OnBeforePostAssocItemJnlLine(ItemJnlLine, SalesOrderLine, SuppressCommit, PurchLine);
            RunItemJnlPostLine(ItemJnlLine);
            OnAfterPostAssocItemJnlLine(ItemJnlLine, ItemJnlPostLine);
            // Handle Item Tracking
            if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
                if TempHandlingSpecification2.FindSet() then
                    repeat
                        TempTrackingSpecification := TempHandlingSpecification2;
                        TempTrackingSpecification.SetSourceFromSalesLine(SalesOrderLine);
                        if TempTrackingSpecification.Insert() then;
                        ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                        ItemEntryRelation.SetSource(DATABASE::"Sales Shipment Line", 0, SalesOrderHeader."Shipping No.", SalesOrderLine."Line No.");
                        ItemEntryRelation.SetOrderInfo(SalesOrderLine."Document No.", SalesOrderLine."Line No.");
                        ItemEntryRelation.Insert();
                    until TempHandlingSpecification2.Next() = 0;
                exit(0);
            end;
        end;

        IsHandled := false;
        ItemShptEntryNo := ItemJnlLine."Item Shpt. Entry No.";
        OnPostAssocItemJnlLineOnBeforeExit(SalesOrderHeader, ItemShptEntryNo, IsHandled);
        exit(ItemShptEntryNo);
    end;

    local procedure PostResourceLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostResourceLine(PurchaseHeader, PurchaseLine, IsHandled,
            SrcCode, GenJnlLineExtDocNo, GenJnlLineDocNo, PurchInvHeader, PurchCrMemoHeader, JobPurchLine);
        if not IsHandled then
            PostResJnlLine(PurchaseHeader, PurchaseLine);
    end;

    local procedure InitAssocItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; SalesOrderHeader: Record "Sales Header"; SalesOrderLine: Record "Sales Line"; PurchHeader: Record "Purchase Header"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal)
    begin
        OnBeforeInitAssocItemJnlLine(ItemJnlLine, SalesOrderHeader, SalesOrderLine, PurchHeader);

        ItemJnlLine.Init();
        ItemJnlLine.CopyDocumentFields(
          ItemJnlLine."Document Type"::"Sales Shipment", SalesOrderHeader."Shipping No.", '', SrcCode, SalesOrderHeader."Posting No. Series");

        ItemJnlLine.CopyFromSalesHeader(SalesOrderHeader);
        ItemJnlLine."Country/Region Code" := GetCountryCode(SalesOrderLine, SalesOrderHeader);
        ItemJnlLine."Posting Date" := PurchHeader."Posting Date";
        ItemJnlLine."Document Date" := PurchHeader."Document Date";

        ItemJnlLine.CopyFromSalesLine(SalesOrderLine);
        ItemJnlLine."Derived from Blanket Order" := SalesOrderLine."Blanket Order No." <> '';
        ItemJnlLine."Applies-to Entry" := ItemLedgShptEntryNo;

        ItemJnlLine.Quantity := QtyToBeShipped;
        ItemJnlLine."Quantity (Base)" := QtyToBeShippedBase;
        ItemJnlLine."Invoiced Quantity" := 0;
        ItemJnlLine."Invoiced Qty. (Base)" := 0;
        ItemJnlLine."Source Currency Code" := PurchHeader."Currency Code";

        ItemJnlLine.Amount := SalesOrderLine.Amount * QtyToBeShipped / SalesOrderLine.Quantity;
        if SalesOrderHeader."Currency Code" <> '' then begin
            ItemJnlLine.Amount :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  SalesOrderHeader."Posting Date", SalesOrderHeader."Currency Code",
                  ItemJnlLine.Amount, SalesOrderHeader."Currency Factor"));
            ItemJnlLine."Discount Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  SalesOrderHeader."Posting Date", SalesOrderHeader."Currency Code",
                  SalesOrderLine."Line Discount Amount", SalesOrderHeader."Currency Factor"));
        end else begin
            ItemJnlLine.Amount := Round(ItemJnlLine.Amount);
            ItemJnlLine."Discount Amount" := SalesOrderLine."Line Discount Amount";
        end;

        OnAfterInitAssocItemJnlLine(ItemJnlLine, SalesOrderHeader, SalesOrderLine, PurchHeader, QtyToBeShipped);
    end;

    local procedure ReleasePurchDocument(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderCopy: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        LinesWereModified: Boolean;
        PrevStatus: Enum "Purchase Document Status";
        IsHandled: Boolean;
    begin
        if not (PurchaseHeader.Status = PurchaseHeader.Status::Open) or (PurchaseHeader.Status = PurchaseHeader.Status::"Pending Prepayment") then
            exit;

        PurchaseHeaderCopy := PurchaseHeader;
        PrevStatus := PurchaseHeader.Status;
        OnBeforeReleasePurchDoc(PurchaseHeader, PreviewMode);
        LinesWereModified := ReleasePurchaseDocument.ReleasePurchaseHeader(PurchaseHeader, PreviewMode);
        if LinesWereModified then
            RefreshTempLines(PurchaseHeader, TempPurchLineGlobal);
        TestStatusRelease(PurchaseHeader);
        PurchaseHeader.Status := PrevStatus;
        RestorePurchaseHeader(PurchaseHeader, PurchaseHeaderCopy);
        OnAfterReleasePurchDoc(PurchaseHeader);
        if not PreviewMode then begin
            PurchaseHeader.Modify();
            IsHandled := false;
            OnReleasePurchDocumentOnBeforeDoCommit(PurchaseHeader, IsHandled);
            if (not IsHandled) and (not SuppressCommit) then
                Commit();
        end;
        IsHandled := false;
        OnReleasePurchDocumentOnBeforeSetStatus(PurchaseHeader, IsHandled);
        if not IsHandled then
            PurchaseHeader.Status := PurchaseHeader.Status::Released;
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

    procedure TestPurchLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLine(PurchaseLine, PurchaseHeader, SuppressCommit, IsHandled);
        if not IsHandled then begin
            case PurchaseLine.Type of
                PurchaseLine.Type::Item:
                    case PurchaseHeader."Document Type" of
                        PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::Invoice:
                            DummyTrackingSpecification.CheckItemTrackingQuantity(
                              DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.",
                              PurchaseLine."Qty. to Receive (Base)", PurchaseLine."Qty. to Invoice (Base)", PurchaseHeader.Receive, PurchaseHeader.Invoice);
                        PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::"Return Order":
                            DummyTrackingSpecification.CheckItemTrackingQuantity(
                              DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.",
                              PurchaseLine."Return Qty. to Ship (Base)", PurchaseLine."Qty. to Invoice (Base)", PurchaseHeader.Ship, PurchaseHeader.Invoice);
                        else
                            OnTestPurchLineOnTypeCaseOnDocumentTypeCaseElse(PurchaseHeader, PurchaseLine);
                    end;
                PurchaseLine.Type::"Charge (Item)":
                    TestPurchLineItemCharge(PurchaseLine);
                PurchaseLine.Type::"Fixed Asset":
                    TestPurchLineFixedAsset(PurchaseLine);
                else
                    TestPurchLineOthers(PurchaseLine);
            end;

            TestPurchLineJob(PurchaseLine);

            case PurchaseHeader."Document Type" of
                PurchaseHeader."Document Type"::Order:
                    PurchaseLine.TestField("Return Qty. to Ship", 0, ErrorInfo.Create());
                PurchaseHeader."Document Type"::Invoice:
                    begin
                        IsHandled := false;
                        OnTestPurchLineOnBeforeTestFieldQtyToReceive(PurchaseLine, IsHandled);
                        if not IsHandled then
                            if PurchaseLine."Receipt No." = '' then
                                PurchaseLine.TestField("Qty. to Receive", PurchaseLine.Quantity, ErrorInfo.Create());
                        PurchaseLine.TestField("Return Qty. to Ship", 0, ErrorInfo.Create());
                        PurchaseLine.TestField("Qty. to Invoice", PurchaseLine.Quantity, ErrorInfo.Create());
                    end;
                PurchaseHeader."Document Type"::"Return Order":
                    PurchaseLine.TestField("Qty. to Receive", 0, ErrorInfo.Create());
                PurchaseHeader."Document Type"::"Credit Memo":
                    begin
                        IsHandled := false;
                        OnTestPurchLineOnBeforeTestFieldReturnQtyToShip(PurchaseLine, IsHandled);
                        if not IsHandled then
                            if PurchaseLine."Return Shipment No." = '' then
                                PurchaseLine.TestField("Return Qty. to Ship", PurchaseLine.Quantity, ErrorInfo.Create());
                        IsHandled := false;
                        OnTestPurchLineOnBeforetestFieldQtyToReceive(PurchaseLine, IsHandled);
                        if not IsHandled then
                            PurchaseLine.TestField("Qty. to Receive", 0, ErrorInfo.Create());
                        PurchaseLine.TestField("Qty. to Invoice", PurchaseLine.Quantity, ErrorInfo.Create());
                    end;
            end;

            if PurchaseLine."Blanket Order No." <> '' then
                PurchaseLine.TestField("Blanket Order Line No.", ErrorInfo.Create());
        end;

        CheckBlockedPostingGroups(PurchaseLine);

        OnAfterTestPurchLine(PurchaseHeader, PurchaseLine, WhseReceive, WhseShip);
    end;

    procedure CheckBlockedPostingGroups(PurchaseLine: Record "Purchase Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
    begin
        if not PurchaseLine.HasTypeToFillMandatoryFields() then
            exit;

        if GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group") then
            if GeneralPostingSetup.Blocked then
                ErrorMessageMgt.LogContextFieldError(
                  PurchaseLine.FieldNo("Gen. Prod. Posting Group"),
                  StrSubstNo(
                      SetupBlockedErr, GeneralPostingSetup.TableCaption(),
                      GeneralPostingSetup.FieldCaption("Gen. Bus. Posting Group"), GeneralPostingSetup."Gen. Bus. Posting Group",
                      GeneralPostingSetup.FieldCaption("Gen. Prod. Posting Group"), GeneralPostingSetup."Gen. Prod. Posting Group"),
                  GeneralPostingSetup.RecordId(), GeneralPostingSetup.FieldNo(Blocked),
                  ForwardLinkMgt.GetHelpCodeForFinancePostingGroups());

        if VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then
            if VATPostingSetup.Blocked then
                ErrorMessageMgt.LogContextFieldError(
                    PurchaseLine.FieldNo("VAT Prod. Posting Group"),
                    StrSubstNo(
                        SetupBlockedErr, VATPostingSetup.TableCaption(),
                        VATPostingSetup.FieldCaption("VAT Bus. Posting Group"), VATPostingSetup."VAT Bus. Posting Group",
                        VATPostingSetup.FieldCaption("VAT Prod. Posting Group"), VATPostingSetup."VAT Prod. Posting Group"),
                    VATPostingSetup.RecordId(), VATPostingSetup.FieldNo(Blocked),
                    ForwardLinkMgt.GetHelpCodeForFinanceSetupVAT());
    end;

    local procedure TestPurchLineItemCharge(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLineItemCharge(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if (PurchaseLine.Amount = 0) and (PurchaseLine.Quantity <> 0) then
            Error(ErrorInfo.Create(StrSubstNo(ItemChargeZeroAmountErr, PurchaseLine."No."), true, PurchaseLine));
        PurchaseLine.TestField("Job No.", '', ErrorInfo.Create());
    end;

    local procedure TestPurchLineJob(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLineJob(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine."Job No." <> '' then
            PurchaseLine.TestField("Job Task No.", ErrorInfo.Create());
    end;

    local procedure TestPurchLineFixedAsset(PurchaseLine: Record "Purchase Line")
    var
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FACheckConsistency: Codeunit "FA Check Consistency";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLineFixedAsset(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if (PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order) and
           (PurchaseLine."Qty. to Invoice (Base)" = 0)
        then
            exit;

        PurchaseLine.TestField("Job No.", '', ErrorInfo.Create());
        PurchaseLine.TestField("Depreciation Book Code", ErrorInfo.Create());
        PurchaseLine.TestField("FA Posting Type", ErrorInfo.Create());
        FixedAsset.Get(PurchaseLine."No.");
        FixedAsset.TestField("Budgeted Asset", false, ErrorInfo.Create());
        DeprBook.Get(PurchaseLine."Depreciation Book Code");
        if FADepreciationBook.Get(PurchaseLine."No.", PurchaseLine."Depreciation Book Code") then
            FACheckConsistency.CheckDisposalDate(FADepreciationBook, FixedAsset);
        if PurchaseLine."Budgeted FA No." <> '' then begin
            FixedAsset.Get(PurchaseLine."Budgeted FA No.");
            FixedAsset.TestField("Budgeted Asset", true, ErrorInfo.Create());
        end;
        if PurchaseLine."FA Posting Type" = PurchaseLine."FA Posting Type"::Maintenance then begin
            PurchaseLine.TestField("Insurance No.", '', ErrorInfo.Create());
            PurchaseLine.TestField("Depr. until FA Posting Date", false, ErrorInfo.Create());
            PurchaseLine.TestField("Depr. Acquisition Cost", false, ErrorInfo.Create());
            DeprBook.TestField("G/L Integration - Maintenance", true, ErrorInfo.Create());
        end;
        if PurchaseLine."FA Posting Type" = PurchaseLine."FA Posting Type"::"Acquisition Cost" then begin
            PurchaseLine.TestField("Maintenance Code", '', ErrorInfo.Create());
            DeprBook.TestField("G/L Integration - Acq. Cost", true, ErrorInfo.Create());
        end;
        if PurchaseLine."Insurance No." <> '' then begin
            FASetup.Get();
            FASetup.TestField("Insurance Depr. Book", PurchaseLine."Depreciation Book Code", ErrorInfo.Create());
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

        PurchaseLine.TestField("Depreciation Book Code", '', ErrorInfo.Create());
        PurchaseLine.TestField("FA Posting Type", 0, ErrorInfo.Create());
        PurchaseLine.TestField("Maintenance Code", '', ErrorInfo.Create());
        PurchaseLine.TestField("Insurance No.", '', ErrorInfo.Create());
        PurchaseLine.TestField("Depr. until FA Posting Date", false, ErrorInfo.Create());
        PurchaseLine.TestField("Depr. Acquisition Cost", false, ErrorInfo.Create());
        PurchaseLine.TestField("Budgeted FA No.", '', ErrorInfo.Create());
        PurchaseLine.TestField("FA Posting Date", 0D, ErrorInfo.Create());
        PurchaseLine.TestField("Salvage Value", 0, ErrorInfo.Create());
        PurchaseLine.TestField("Duplicate in Depreciation Book", '', ErrorInfo.Create());
        PurchaseLine.TestField("Use Duplication List", false, ErrorInfo.Create());
    end;

    procedure UpdateAssocOrder(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        DummyPurchaseHeader: Record "Purchase Header";
    begin
        UpdateAssociatedSalesOrder(TempDropShptPostBuffer, DummyPurchaseHeader);
    end;

    local procedure UpdateAssociatedSalesOrder(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; PurchaseHeader: Record "Purchase Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAssocOrder(TempDropShptPostBuffer, IsHandled, SuppressCommit, PurchaseHeader);
        if IsHandled then
            exit;

        TempDropShptPostBuffer.Reset();
        if TempDropShptPostBuffer.IsEmpty() then
            exit;
        SalesSetup.Get();
        if TempDropShptPostBuffer.FindSet() then begin
            repeat
                SalesOrderHeader.Get(
                  SalesOrderHeader."Document Type"::Order,
                  TempDropShptPostBuffer."Order No.");
                CheckAndUpdateAssocOrderPostingDate(SalesOrderHeader, PurchaseHeader."Posting Date");
                SalesOrderHeader."Last Shipping No." := SalesOrderHeader."Shipping No.";
                SalesOrderHeader."Shipping No." := '';
                SalesOrderHeader.Modify();
                OnUpdateAssocOrderOnAfterSalesOrderHeaderModify(SalesOrderHeader, SalesSetup);
                SalesLineReserve.UpdateItemTrackingAfterPosting(SalesOrderHeader);
                TempDropShptPostBuffer.SetRange("Order No.", TempDropShptPostBuffer."Order No.");
                repeat
                    SalesOrderLine.Get(
                      SalesOrderLine."Document Type"::Order,
                      TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
                    SalesOrderLine."Quantity Shipped" := SalesOrderLine."Quantity Shipped" + TempDropShptPostBuffer.Quantity;
                    SalesOrderLine."Qty. Shipped (Base)" := SalesOrderLine."Qty. Shipped (Base)" + TempDropShptPostBuffer."Quantity (Base)";
                    OnUpdateAssociatedSalesOrderBeforeInitOutstanding(TempDropShptPostBuffer, SalesOrderLine, SalesOrderHeader);
                    SalesOrderLine.InitOutstanding();
                    if SalesSetup."Default Quantity to Ship" <> SalesSetup."Default Quantity to Ship"::Blank then
                        SalesOrderLine.InitQtyToShip()
                    else begin
                        SalesOrderLine."Qty. to Ship" := 0;
                        SalesOrderLine."Qty. to Ship (Base)" := 0;
                    end;
                    OnUpdateAssocOrderOnBeforeSalesOrderLineModify(SalesOrderLine, TempDropShptPostBuffer, SalesOrderHeader);
                    SalesOrderLine.Modify();
                    OnUpdateAssocOrderOnAfterSalesOrderLineModify(SalesOrderLine, TempDropShptPostBuffer, SalesOrderHeader, SalesShptHeader);
                until TempDropShptPostBuffer.Next() = 0;
                TempDropShptPostBuffer.SetRange("Order No.");
                OnUpdateAssocOrderOnAfterOrderNoClearFilter(TempDropShptPostBuffer);
            until TempDropShptPostBuffer.Next() = 0;
            OnUpdateAssociatedSalesOrderOnBeforeClearTempDropShptPostBuffer(TempDropShptPostBuffer);
            TempDropShptPostBuffer.DeleteAll();
        end;
    end;

    local procedure UpdateAssosOrderPostingNos(PurchaseHeader: Record "Purchase Header") DropShipment: Boolean
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        SalesOrderHeader: Record "Sales Header";
        NoSeries: Codeunit "No. Series";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        IsHandled: Boolean;
    begin
        ResetTempLines(TempPurchaseLine);
        TempPurchaseLine.SetFilter("Sales Order Line No.", '<>0');
        DropShipment := not TempPurchaseLine.IsEmpty();

        IsHandled := false;
        OnBeforeUpdateAssosOrderPostingNos(TempPurchaseLine, PurchaseHeader, DropShipment, IsHandled);
        if IsHandled then
            exit(DropShipment);

        TempPurchaseLine.SetFilter("Qty. to Receive", '<>0');
        if DropShipment and PurchaseHeader.Receive then
            if TempPurchaseLine.FindSet() then
                repeat
                    if SalesOrderHeader."No." <> TempPurchaseLine."Sales Order No." then begin
                        SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, TempPurchaseLine."Sales Order No.");
                        IsHandled := false;
                        OnUpdateAssosOrderPostingNosOnBeforeTestFieldBilltoCustomerNo(SalesOrderHeader, IsHandled);
                        if not IsHandled then
                            SalesOrderHeader.TestField("Bill-to Customer No.");
                        SalesOrderHeader.Ship := true;
                        OnUpdateAssosOrderPostingNosOnBeforeReleaseSalesHeader(PurchaseHeader, SalesOrderHeader);
                        ReleaseSalesDocument.ReleaseSalesHeader(SalesOrderHeader, PreviewMode);
                        if SalesOrderHeader."Shipping No." = '' then begin
                            SalesOrderHeader.TestField("Shipping No. Series");
                            SalesOrderHeader."Shipping No." :=
                                NoSeries.GetNextNo(SalesOrderHeader."Shipping No. Series", PurchaseHeader."Posting Date");
                            SalesOrderHeader.Modify();
                        end;
                        OnUpdateAssosOrderPostingNosOnAfterReleaseSalesHeader(PurchaseHeader, SalesOrderHeader);
                    end;
                until TempPurchaseLine.Next() = 0;

        exit(DropShipment);
    end;

    procedure CheckAndUpdateAssocOrderPostingDate(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        OriginalDocumentDate: Date;
    begin
        if (PostingDate <> 0D) and (SalesHeader."Posting Date" <> PostingDate) then begin
            ReleaseSalesDocument.Reopen(SalesHeader);
            ReleaseSalesDocument.SetSkipCheckReleaseRestrictions();

            OriginalDocumentDate := SalesHeader."Document Date";
            SalesHeader.SetHideValidationDialog(true);
            SalesHeader.Validate("Posting Date", PostingDate);

            SalesReceivablesSetup.SetLoadFields("Link Doc. Date To Posting Date");
            SalesReceivablesSetup.GetRecordOnce();
            if SalesReceivablesSetup."Link Doc. Date To Posting Date" then
                SalesHeader.Validate("Document Date", PostingDate)
            else begin
                OnCheckAndUpdateAssocOrderPostingDateOnBeforeValidateDocumentDate(SalesHeader, OriginalDocumentDate);
                SalesHeader.Validate("Document Date", OriginalDocumentDate);
            end;

            ReleaseSalesDocument.Run(SalesHeader);
        end;
    end;

    local procedure UpdateAfterPosting(PurchHeader: Record "Purchase Header")
    var
        TempPurchLine: Record "Purchase Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAfterPosting(PurchHeader, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        ResetTempLines(TempPurchLine);
        TempPurchLine.SetFilter("Blanket Order Line No.", '<>0');
        if TempPurchLine.FindSet() then
            repeat
                UpdateBlanketOrderLine(TempPurchLine, PurchHeader.Receive, PurchHeader.Ship, PurchHeader.Invoice);
            until TempPurchLine.Next() = 0;
    end;

    local procedure UpdateLastPostingNos(var PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader.Receive then begin
            PurchHeader."Last Receiving No." := PurchHeader."Receiving No.";
            PurchHeader."Receiving No." := '';
        end;
        if PurchHeader.Invoice then begin
            PurchHeader."Last Posting No." := PurchHeader."Posting No.";
            PurchHeader."Posting No." := '';
        end;
        if PurchHeader.Ship then begin
            PurchHeader."Last Return Shipment No." := PurchHeader."Return Shipment No.";
            PurchHeader."Return Shipment No." := '';
        end;

        OnAfterUpdateLastPostingNos(PurchHeader);
    end;

    local procedure UpdatePostingNos(var PurchHeader: Record "Purchase Header") ModifyHeader: Boolean
    var
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesMgt: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
        ShouldUpdateReceivingNo: Boolean;
    begin
        IsHandled := false;
#if not CLEAN24
        OnBeforeUpdatePostingNos(PurchHeader, NoSeriesMgt, ModifyHeader, SuppressCommit, IsHandled);
#else
        OnBeforeUpdatePostingNos(PurchHeader, ModifyHeader, SuppressCommit, IsHandled);
#endif
        if IsHandled then
            exit;

        UpdateReceivingNoTelemetry(PurchHeader);
        ShouldUpdateReceivingNo := PurchHeader.Receive and (PurchHeader."Receiving No." = '');
        OnUpdatePostingNosOnAfterCalcShouldUpdateReceivingNo(PurchHeader, PreviewMode, ModifyHeader, ShouldUpdateReceivingNo);
        if ShouldUpdateReceivingNo then
            if (PurchHeader."Document Type" = PurchHeader."Document Type"::Order) or
               ((PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice) and PurchSetup."Receipt on Invoice")
            then
                if not PreviewMode then begin
                    ResetPostingNoSeriesFromSetup(PurchHeader."Receiving No. Series", PurchSetup."Posted Receipt Nos.");
                    PurchHeader.TestField("Receiving No. Series");
                    PurchHeader."Receiving No." := NoSeries.GetNextNo(PurchHeader."Receiving No. Series", PurchHeader."Posting Date");
                    ModifyHeader := true;

                    // Check for posting conflicts.
                    if PurchRcptHeader.Get(PurchHeader."Receiving No.") then
                        Error(PurchRcptHeaderConflictErr, PurchHeader."Receiving No.");

                end else begin
                    PurchHeader."Receiving No." := PostingPreviewNoTok;
                    OnSetPostingPreviewDocumentNo(PurchHeader."Receiving No.");
                end;

        if PurchHeader.Ship and (PurchHeader."Return Shipment No." = '') then
            if (PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order") or
               ((PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo") and PurchSetup."Return Shipment on Credit Memo")
            then
                if not PreviewMode then begin
                    ResetPostingNoSeriesFromSetup(PurchHeader."Return Shipment No. Series", PurchSetup."Posted Return Shpt. Nos.");
                    PurchHeader.TestField("Return Shipment No. Series");
                    PurchHeader."Return Shipment No." := NoSeries.GetNextNo(PurchHeader."Return Shipment No. Series", PurchHeader."Posting Date");
                    ModifyHeader := true;
                    OnUpdatePostingNosOnAfterSetReturnShipmentNoFromNos(PurchHeader);

                    // Check for posting conflicts.
                    if ReturnShptHeader.Get(PurchHeader."Return Shipment No.") then
                        Error(ReturnShptHeaderConflictErr, PurchHeader."Return Shipment No.");

                end else begin
                    PurchHeader."Return Shipment No." := PostingPreviewNoTok;
                    OnSetPostingPreviewDocumentNo(PurchHeader."Return Shipment No.");
                end;

        IsHandled := false;
        OnUpdatePostingNosOnBeforeUpdatePostingNo(PurchHeader, PreviewMode, ModifyHeader, IsHandled);
        if not IsHandled then
            if PurchHeader.Invoice and (PurchHeader."Posting No." = '') then begin
                if (PurchHeader."No. Series" <> '') or
                   (PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"])
                then begin
                    if PurchHeader."Document Type" in [PurchHeader."Document Type"::"Return Order"] then
                        ResetPostingNoSeriesFromSetup(PurchHeader."Posting No. Series", PurchSetup."Posted Credit Memo Nos.")
                    else
                        if (PurchHeader."Document Type" <> PurchHeader."Document Type"::"Credit Memo") then
                            ResetPostingNoSeriesFromSetup(PurchHeader."Posting No. Series", PurchSetup."Posted Invoice Nos.");
                    if PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo" then
                        if (PurchSetup."Posted Credit Memo Nos." <> '') and (PurchHeader."Posting No. Series" = '') then
                            CheckDefaultNoSeries(PurchSetup."Posted Credit Memo Nos.");
                    PurchHeader.TestField("Posting No. Series");
                end;
                if (PurchHeader."No. Series" <> PurchHeader."Posting No. Series") or
                   (PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"])
                then
                    if not PreviewMode then begin
                        IsHandled := false;
                        OnUpdatePostingNosOnInvoiceOnBeforeSetPostingNo(PurchHeader, IsHandled);
                        if not IsHandled then
                            PurchHeader."Posting No." := NoSeries.GetNextNo(PurchHeader."Posting No. Series", PurchHeader."Posting Date");
                        ModifyHeader := true;
                    end;
                if PreviewMode then begin
                    PurchHeader."Posting No." := PostingPreviewNoTok;
                    OnSetPostingPreviewDocumentNo(PurchHeader."Posting No.");
                end;
                // Check for posting conflicts.
                if not PreviewMode then
                    if PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice] then begin
                        if PurchInvHeader.Get(PurchHeader."Posting No.") then
                            Error(PurchInvHeaderConflictErr, PurchHeader."Posting No.");
                    end else
                        if PurchCrMemoHeader.Get(PurchHeader."Posting No.") then
                            Error(PurchCrMemoHeaderConflictErr, PurchHeader."Posting No.");
            end;

#if not CLEAN24
        OnAfterUpdatePostingNos(PurchHeader, NoSeriesMgt, SuppressCommit, PreviewMode, ModifyHeader);
#else
        OnAfterUpdatePostingNos(PurchHeader, SuppressCommit, PreviewMode, ModifyHeader);
#endif
    end;

    local procedure ResetPostingNoSeriesFromSetup(var PostingNoSeries: Code[20]; SetupNoSeries: Code[20])
    begin
        if (PostingNoSeries = '') and (SetupNoSeries <> '') then
            PostingNoSeries := SetupNoSeries;
    end;

    local procedure UpdatePurchLineBeforePost(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        InitQtyToInvoiceNeeded: Boolean;
    begin
        OnBeforeUpdatePurchLineBeforePost(PurchLine, PurchHeader, WhseShip, WhseReceive, RoundingLineInserted, SuppressCommit);

        if not (PurchHeader.Receive or RoundingLineInserted) then begin
            PurchLine."Qty. to Receive" := 0;
            PurchLine."Qty. to Receive (Base)" := 0;
        end;

        if not (PurchHeader.Ship or RoundingLineInserted) then begin
            PurchLine."Return Qty. to Ship" := 0;
            PurchLine."Return Qty. to Ship (Base)" := 0;
        end;

        if (PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice) and (PurchLine."Receipt No." <> '') then begin
            PurchLine."Quantity Received" := PurchLine.Quantity;
            PurchLine."Qty. Received (Base)" := PurchLine."Quantity (Base)";
            PurchLine."Qty. to Receive" := 0;
            PurchLine."Qty. to Receive (Base)" := 0;
        end;

        if (PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo") and (PurchLine."Return Shipment No." <> '')
        then begin
            PurchLine."Return Qty. Shipped" := PurchLine.Quantity;
            PurchLine."Return Qty. Shipped (Base)" := PurchLine."Quantity (Base)";
            PurchLine."Return Qty. to Ship" := 0;
            PurchLine."Return Qty. to Ship (Base)" := 0;
        end;

        if PurchHeader.Invoice then begin
            InitQtyToInvoiceNeeded := Abs(PurchLine."Qty. to Invoice") > Abs(PurchLine.MaxQtyToInvoice());
            OnUpdatePurchLineBeforePostOnAfterCalcInitQtyToInvoiceNeeded(PurchHeader, PurchLine, InitQtyToInvoiceNeeded);
            if InitQtyToInvoiceNeeded then
                PurchLine.InitQtyToInvoice();
        end else begin
            PurchLine."Qty. to Invoice" := 0;
            PurchLine."Qty. to Invoice (Base)" := 0;
        end;

        OnAfterUpdatePurchLineBeforePost(PurchLine, WhseShip, WhseReceive, PurchHeader, RoundingLineInserted);
    end;

    local procedure UpdateWhseDocuments()
    begin
        if WhseReceive then begin
            WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
            TempWhseRcptHeader.Delete();
            OnUpdateWhseDocumentsOnAfterUpdateWhseRcpt(WhseRcptHeader);
        end;
        if WhseShip then begin
            WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
            TempWhseShptHeader.Delete();
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
        OnBeforeDeleteAfterPosting(PurchHeader, PurchInvHeader, PurchCrMemoHeader, SkipDelete, SuppressCommit, TempPurchLine, TempPurchLineGlobal, GenJnlPostLine);
        if SkipDelete then
            exit;

        if PurchHeader.HasLinks then
            PurchHeader.DeleteLinks();
        WarehouseRequest.DeleteRequest(DATABASE::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.");

        PurchHeader.Delete();

        PurchLineReserve.DeleteInvoiceSpecFromHeader(PurchHeader);
        ResetTempLines(TempPurchLine);
        if TempPurchLine.FindFirst() then
            repeat
                if TempPurchLine."Deferral Code" <> '' then
                    DeferralUtilities.RemoveOrSetDeferralSchedule(
                        '', "Deferral Document Type"::Purchase.AsInteger(), '', '', TempPurchLine."Document Type".AsInteger(),
                        TempPurchLine."Document No.", TempPurchLine."Line No.", 0, 0D, TempPurchLine.Description, '', true);
                if TempPurchLine.HasLinks then
                    TempPurchLine.DeleteLinks();
            until TempPurchLine.Next() = 0;

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        OnBeforePurchLineDeleteAll(PurchLine, SuppressCommit, TempPurchLine);
        PurchLine.DeleteAll();

        DeleteItemChargeAssgnt(PurchHeader);
        PurchCommentLine.DeleteComments(PurchHeader."Document Type".AsInteger(), PurchHeader."No.");

        OnAfterDeleteAfterPosting(PurchHeader, PurchInvHeader, PurchCrMemoHeader, SuppressCommit);
    end;

    local procedure FinalizePosting(var PurchHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; EverythingInvoiced: Boolean)
    var
        TempPurchLine: Record "Purchase Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        OnBeforeFinalizePosting(PurchHeader, TempPurchLineGlobal, EverythingInvoiced, SuppressCommit, GenJnlPostLine);

        if (PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"]) and
           (not EverythingInvoiced)
        then begin
            PurchHeader.Modify();
            InsertTrackingSpecification(PurchHeader);
            PostUpdateOrderLine(PurchHeader);
            UpdateAssociatedSalesOrder(TempDropShptPostBuffer, PurchHeader);

            IsHandled := false;
            OnFinalizePostingOnBeforeUpdateWhseDocuments(PurchHeader, WhseRcptHeader, TempWhseRcptHeader, WhseShptHeader, TempWhseShptHeader, WhseReceive, WhseShip, IsHandled);
            if not IsHandled then
                UpdateWhseDocuments();
            WhsePurchRelease.Release(PurchHeader);
            UpdateItemChargeAssgnt(PurchHeader);
            OnFinalizePostingOnAfterUpdateItemChargeAssgnt(PurchHeader, TempDropShptPostBuffer, EverythingInvoiced, TempPurchLine, TempPurchLineGlobal, GenJnlPostLine);
        end else begin
            OnFinalizePostingOnBeforeInsertTrackingSpecification(TempDropShptPostBuffer, PurchHeader, TempTrackingSpecification, EverythingInvoiced, TempPurchLine, TempPurchLineGlobal);
            case PurchHeader."Document Type" of
                PurchHeader."Document Type"::Invoice:
                    begin
                        PostUpdateInvoiceLine(PurchHeader);
                        InsertTrackingSpecification(PurchHeader);
                        PostUpdateOrderNo(PurchInvHeader);
                    end;
                PurchHeader."Document Type"::"Credit Memo":
                    begin
                        PostUpdateCreditMemoLine(PurchHeader);
                        InsertTrackingSpecification(PurchHeader);
                        PostUpdateOrderNo(PurchCrMemoHeader);
                    end;
                else begin
                    ResetTempLines(TempPurchLine);
                    TempPurchLine.SetFilter("Prepayment %", '<>0');
                    if TempPurchLine.FindSet() then
                        repeat
                            DecrementPrepmtAmtInvLCY(
                              PurchHeader, TempPurchLine, TempPurchLine."Prepmt. Amount Inv. (LCY)", TempPurchLine."Prepmt. VAT Amount Inv. (LCY)");
                        until TempPurchLine.Next() = 0;
                end;
            end;
            IsHandled := false;
            OnFinalizePostingOnBeforeUpdateAfterPosting(PurchHeader, TempDropShptPostBuffer, EverythingInvoiced, IsHandled, TempPurchLine);
            if not IsHandled then begin
                UpdateAfterPosting(PurchHeader);
                UpdateWhseDocuments();
                if not OrderArchived then
                    ArchiveManagement.AutoArchivePurchDocument(PurchHeader);
                DeleteApprovalEntries(PurchHeader);
                if not PreviewMode then
                    DeleteAfterPosting(PurchHeader);
            end;
        end;

        OnFinalizePostingOnBeforeInsertValueEntryRelation(PurchHeader, PurchInvHeader, PurchCrMemoHeader);
        InsertValueEntryRelation();

        OnAfterFinalizePostingOnBeforeCommit(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader, GenJnlPostLine, PreviewMode, SuppressCommit, EverythingInvoiced);

        if PreviewMode and (CalledBy = 0) then begin
            if not HideProgressWindow then
                Window.Close();
            GenJnlPostPreview.ThrowError();
        end;
        IsHandled := false;
        OnFinalizePostingOnBeforeCommit(PreviewMode, IsHandled);
        if not IsHandled then
            if not (InvtPickPutaway or SuppressCommit or PreviewMode) then
                Commit();

        if GuiAllowed and not HideProgressWindow then
            Window.Close();

        OnAfterFinalizePosting(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader, GenJnlPostLine, PreviewMode, SuppressCommit);

        ClearPostBuffers();
    end;

    local procedure DeleteApprovalEntries(var PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteApprovalEntries(PurchaseHeader, IsHandled, PurchInvHeader, PurchCrMemoHeader);
        if IsHandled then
            exit;

        ApprovalsMgmt.DeleteApprovalEntries(PurchaseHeader.RecordId());

        OnAfterDeleteApprovalEntries(PurchaseHeader, PurchInvHeader, PurchCrMemoHeader, PurchRcptHeader);
    end;

#if not CLEAN23
    local procedure InsertTempInvoicePostBufferReverseCharge(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
        TempInvoicePostBufferReverseCharge := TempInvoicePostBuffer;
        if not TempInvoicePostBufferReverseCharge.Insert() then
            TempInvoicePostBufferReverseCharge.Modify();
    end;
#endif

#if not CLEAN23
    local procedure FillInvoicePostBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostBuffer: Record "Invoice Post. Buffer";
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
        AdjAmount: Decimal;
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        PurchInvHeaderPrepmt1: Record "Purch. Inv. Header";
        WHTEntryPrePmt1: Record "WHT Entry";
        TotalWHTAmtTobeDeducted1: Decimal;
        TotalWHTAmountToBeDeductedLCY: Decimal;
        TotalWHTAmountToBeDeductedACY: Integer;
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        TotalNonDedVATBase: Decimal;
        TotalNonDedVATAmount: Decimal;
        TotalNonDedVATBaseACY: Decimal;
        TotalNonDedVATAmountACY: Decimal;
        TotalNonDedVATAmountDiff: Decimal;
        DeferralAccount: Code[20];
        PurchAccount: Code[20];
        IsHandled: Boolean;
        ShouldCalcDiscounts: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillInvoicePostBuffer(PurchHeader, PurchLine, PurchLineACY, InvoicePostBuffer, IsHandled, TempInvoicePostBuffer);
        if IsHandled then
            exit;

        GetGeneralPostingSetup(GenPostingSetup, PurchLine);

        OnFillInvoicePostBufferOnBeforePreparePurchase(PurchHeader, PurchLine, InvoicePostBuffer, PurchLineACY, GenPostingSetup);
        InvoicePostBuffer.PreparePurchase(PurchLine);
        InitAmounts(PurchLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, AmtToDefer, AmtToDeferACY, DeferralAccount, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff);
        InitVATBase(PurchLine, TotalVATBase, TotalVATBaseACY);

        OnFillInvoicePostBufferOnAfterInitAmounts(
          PurchHeader, PurchLine, PurchLineACY, TempInvoicePostBuffer, InvoicePostBuffer, TotalAmount, TotalAmountACY);

        PurchInvHeaderPrepmt1.Reset();
        PurchInvHeaderPrepmt1.SetRange("Prepayment Order No.", PurchLine."Document No.");
        PurchInvHeaderPrepmt1.SetRange("Prepayment Invoice", true);
        if PurchInvHeaderPrepmt1.FindSet() then
            repeat
                WHTEntryPrePmt1.SetRange("Document Type", WHTEntryPrePmt1."Document Type"::Invoice);
                WHTEntryPrePmt1.SetRange("Document No.", PurchInvHeaderPrepmt1."No.");
                WHTEntryPrePmt1.SetRange("Gen. Bus. Posting Group", GenPostingSetup."Gen. Bus. Posting Group");
                WHTEntryPrePmt1.SetRange("Gen. Prod. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
                if WHTEntryPrePmt1.FindSet() then
                    repeat
                        TotalWHTAmountToBeDeductedLCY := TotalWHTAmountToBeDeductedLCY + WHTEntryPrePmt1."Unrealized Amount (LCY)";
                        TotalWHTAmtTobeDeducted1 := TotalWHTAmtTobeDeducted1 + WHTEntryPrePmt1."Unrealized Amount";
                    until WHTEntryPrePmt1.Next() = 0;
            until PurchInvHeaderPrepmt1.Next() = 0;
        if GLSetup."Additional Reporting Currency" <> '' then
            TotalWHTAmountToBeDeductedACY :=
              CurrExchRate.ExchangeAmtLCYToFCY(
                PurchHeader."Posting Date", GLSetup."Additional Reporting Currency",
                TotalWHTAmtTobeDeducted1, 0);

        if PurchLine."Prepayment Line" then begin
            TotalAmount := TotalAmount + TotalWHTAmountToBeDeductedLCY;
            TotalAmountACY := TotalAmountACY + TotalWHTAmountToBeDeductedACY;
        end else begin
            TotalAmount := TotalAmount;
            TotalAmountACY := TotalAmountACY;
        end;

        if PurchSetup."Discount Posting" in
           [PurchSetup."Discount Posting"::"Invoice Discounts", PurchSetup."Discount Posting"::"All Discounts"]
        then begin
            IsHandled := false;
            OnFillInvoicePostBufferOnBeforeProcessInvoiceDiscounts(PurchLine, IsHandled);
            if not IsHandled then begin
                CalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostBuffer);

                if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
                    InvoicePostBuffer.SetSalesTaxForPurchLine(PurchLine);

                if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                    GenPostingSetup.TestField("Purch. Inv. Disc. Account");
                    if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
                        FillInvoicePostBufferFADiscount(
                          InvoicePostBuffer, GenPostingSetup, PurchLine."No.",
                          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff);
                        InvoicePostBuffer.SetAccount(
                          GenPostingSetup.GetPurchInvDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
#if not CLEAN23                        
                        NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff, InvoicePostBuffer);
#endif                        
                        InvoicePostBuffer.Type := InvoicePostBuffer.Type::"G/L Account";
                        UpdateInvoicePostBuffer(InvoicePostBuffer);
                        InvoicePostBuffer.Type := InvoicePostBuffer.Type::"Fixed Asset";
                    end else begin
                        InvoicePostBuffer.SetAccount(
                          GenPostingSetup.GetPurchInvDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
#if not CLEAN23
                        NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff, InvoicePostBuffer);
#endif                        
                        UpdateInvoicePostBuffer(InvoicePostBuffer);
                    end;
                end;
            end;
        end;

        ShouldCalcDiscounts :=
            PurchSetup."Discount Posting" in
            [PurchSetup."Discount Posting"::"Line Discounts", PurchSetup."Discount Posting"::"All Discounts"];
        OnFillInvoicePostBufferOnAfterSetShouldCalcDiscounts(PurchHeader, PurchLine, ShouldCalcDiscounts);
        if ShouldCalcDiscounts then begin
            if PurchLine."Allocation Account No." = '' then
                CalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostBuffer);

            if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
                InvoicePostBuffer.SetSalesTaxForPurchLine(PurchLine);

            if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                GenPostingSetup.TestField("Purch. Line Disc. Account");
                if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
                    FillInvoicePostBufferFADiscount(
                      InvoicePostBuffer, GenPostingSetup, PurchLine."No.",
                      TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff);
                    InvoicePostBuffer.SetAccount(
                      GenPostingSetup.GetPurchLineDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
#if not CLEAN23
                    NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff, InvoicePostBuffer);
#endif                    
                    InvoicePostBuffer.Type := InvoicePostBuffer.Type::"G/L Account";
                    UpdateInvoicePostBuffer(InvoicePostBuffer);
                    InvoicePostBuffer.Type := InvoicePostBuffer.Type::"Fixed Asset";
                end else begin
                    InvoicePostBuffer.SetAccount(
                      GenPostingSetup.GetPurchLineDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
#if not CLEAN23
                    NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff, InvoicePostBuffer);
#endif                    
                    UpdateInvoicePostBuffer(InvoicePostBuffer);
                end;
                OnFillInvoicePostingBufferOnAfterSetLineDiscAccount(PurchLine, GenPostingSetup, InvoicePostBuffer, TempInvoicePostBuffer);
            end;
        end;

        DeferralUtilities.AdjustTotalAmountForDeferralsNoBase(
          PurchLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY);

        IsHandled := false;
        OnBeforeInvoicePostingBufferSetAmounts(
            PurchLine, TempInvoicePostBuffer, InvoicePostBuffer,
            TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled, PurchLineACY);
        if not IsHandled then
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
            if PurchLine.IsCreditDocType() then
                PurchAccount := GenPostingSetup.GetPurchCrMemoAccount()
            else
                PurchAccount := GenPostingSetup.GetPurchAccount();

        OnFillInvoicePostingBufferOnBeforeSetAccount(PurchHeader, PurchLine, PurchAccount, GenJnlLineDocNo);

        InvoicePostBuffer.SetAccount(PurchAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
#if not CLEAN23
        NonDeductibleVAT.SetNonDeductibleVAT(InvoicePostBuffer, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff);
#endif        
        InvoicePostBuffer."Deferral Code" := PurchLine."Deferral Code";
        if PurchLine."Prepayment Line" then
            if GLSetup.CheckFullGSTonPrepayment(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group") then begin
                InvoicePostBuffer."VAT Base Amount" := Round(PurchLine."VAT Base Amount", Currency."Amount Rounding Precision");
                InvoicePostBuffer."VAT Base Amount (ACY)" := Round(PurchLineACY."VAT Base Amount", Currency."Amount Rounding Precision");
            end;
        OnAfterFillInvoicePostBuffer(InvoicePostBuffer, PurchLine, TempInvoicePostBuffer, SuppressCommit, PurchHeader, GenJnlLineDocNo, GenJnlPostLine);
        UpdateInvoicePostBuffer(InvoicePostBuffer);

        OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer(PurchHeader, PurchLine, InvoicePostBuffer, TempInvoicePostBuffer, GenJnlLineDocNo, GenJnlPostLine);

        if PurchLine."Deferral Code" <> '' then begin
            OnBeforeFillDeferralPostingBuffer(
              PurchLine, InvoicePostBuffer, TempInvoicePostBuffer, PurchHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
            FillDeferralPostingBuffer(PurchHeader, PurchLine, InvoicePostBuffer, AmtToDefer, AmtToDeferACY, DeferralAccount, PurchAccount);
        end;

        if PurchLine."Prepayment Line" then
            if PurchLine."Prepmt. Amount Inv. (LCY)" <> 0 then begin
                AdjAmount := -PurchLine."Prepmt. Amount Inv. (LCY)";
                TempInvoicePostBuffer.PreparePrepmtAdjBuffer(
                    InvoicePostBuffer, PurchLine."No.", AdjAmount, PurchHeader."Currency Code" = '');
                TempInvoicePostBuffer.PreparePrepmtAdjBuffer(
                    InvoicePostBuffer, PurchPostPrepayments.GetCorrBalAccNo(PurchHeader, AdjAmount > 0),
                    -AdjAmount, PurchHeader."Currency Code" = '');
            end else
                if (PurchLine."Prepayment %" = 100) and (PurchLine."Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                    TempInvoicePostBuffer.PreparePrepmtAdjBuffer(
                        InvoicePostBuffer, PurchPostPrepayments.GetInvRoundingAccNo(PurchHeader."Vendor Posting Group"),
                        PurchLine."Prepmt. VAT Amount Inv. (LCY)", PurchHeader."Currency Code" = '');
    end;
#endif

#if not CLEAN23
    local procedure FillInvoicePostBufferFADiscount(var InvoicePostBuffer: Record "Invoice Post. Buffer"; GenPostingSetup: Record "General Posting Setup"; AccountNo: Code[20]; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; TotalVATBase: Decimal; TotalVATBaseACY: Decimal; TotalNonDedVATBase: Decimal; TotalNonDedVATAmount: Decimal; TotalNonDedVATBaseACY: Decimal; TotalNonDedVATAmountACY: Decimal; TotalNonDedVATAmountDiff: Decimal)
    var
        DeprBook: Record "Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillInvoicePostBufferFADiscount(TempInvoicePostBuffer, InvoicePostBuffer, IsHandled);
        if IsHandled then
            exit;

        DeprBook.Get(InvoicePostBuffer."Depreciation Book Code");
        if DeprBook."Subtract Disc. in Purch. Inv." then begin
            InvoicePostBuffer.SetAccount(AccountNo, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
#if not CLEAN23
            NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff, InvoicePostBuffer);
#endif            
            UpdateInvoicePostBuffer(InvoicePostBuffer);
            InvoicePostBuffer.ReverseAmounts();
            InvoicePostBuffer.SetAccount(
              GenPostingSetup.GetPurchFADiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
#if not CLEAN23
            NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATAmountDiff, InvoicePostBuffer);
#endif            
            InvoicePostBuffer.Type := InvoicePostBuffer.Type::"G/L Account";
            UpdateInvoicePostBuffer(InvoicePostBuffer);
            InvoicePostBuffer.ReverseAmounts();
        end;
    end;
#endif

#if not CLEAN23
    local procedure UpdateInvoicePostBuffer(InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostBuffer."Fixed Asset Line No." := FALineNo;
        end;

        TempInvoicePostBuffer.Update(InvoicePostBuffer, InvDefLineNo, DeferralLineNo);
    end;
#endif

    procedure GetCurrency(CurrencyCode: Code[10])
    begin
        Currency.Initialize(CurrencyCode, true);

        OnAfterGetCurrency(CurrencyCode, Currency);
    end;

    procedure DivideAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; PurchLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    var
        FullGST: Boolean;
        OriginalDeferralAmount: Decimal;
        IsHandled: Boolean;
    begin
        GetGLSetup();
        if RoundingLineInserted and (RoundingLineNo = PurchLine."Line No.") then
            exit;
        GetCurrencyFactorACY(PurchHeader);

        IsHandled := false;
        OnBeforeDivideAmount(PurchHeader, PurchLine, QtyType, PurchLineQty, TempVATAmountLine, TempVATAmountLineRemainder, IsHandled);
        if IsHandled then
            exit;

        if (PurchLineQty = 0) or (PurchLine."Direct Unit Cost" = 0) then begin
            PurchLine."Line Amount" := 0;
            PurchLine."Line Discount Amount" := 0;
            PurchLine."Inv. Discount Amount" := 0;
            PurchLine."VAT Base Amount" := 0;
            PurchLine.Amount := 0;
            PurchLine."Amount Including VAT" := 0;
            PurchLine."Amount (ACY)" := 0;
            PurchLine."VAT Base (ACY)" := 0;
            PurchLine."Amount Including VAT (ACY)" := 0;
            OnDivideAmountOnAfterClearAmounts(PurchHeader, PurchLine, PurchLineQty);
        end else begin
            OriginalDeferralAmount := PurchLine.GetDeferralAmount();
            FullGST :=
              (PurchLine."Prepayment Line" or (PurchLine."Prepmt. Line Amount" <> 0)) and
              GLSetup.CheckFullGSTonPrepayment(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group");
            IsHandled := false;
            OnDivideAmountOnBeforeTempVATAmountLineGet(PurchLine, TempVATAmountLine, IsHandled);
            if not IsHandled then
                TempVATAmountLine.Get(
                    PurchLine."VAT Identifier", PurchLine."VAT Calculation Type", PurchLine."Tax Group Code", PurchLine."Use Tax", PurchLine."Line Amount" >= 0, FullGST);
            if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
                PurchLine."VAT %" := TempVATAmountLine."VAT %";
            TempVATAmountLineRemainder := TempVATAmountLine;
            if not TempVATAmountLineRemainder.Find() then begin
                TempVATAmountLineRemainder.Init();
                TempVATAmountLineRemainder.Insert();
            end;
            CalcLineAmountAndLineDiscountAmount(PurchHeader, PurchLine, PurchLineQty);

            OnDivideAmountOnAfterCalcLineAmountAndLineDiscountAmount(PurchHeader, PurchLine, PurchLineQty);

            if PurchLine."Allow Invoice Disc." and (TempVATAmountLine."Inv. Disc. Base Amount" <> 0) then
                if QtyType = QtyType::Invoicing then
                    PurchLine."Inv. Discount Amount" := PurchLine."Inv. Disc. Amount to Invoice"
                else begin
                    TempVATAmountLineRemainder."Invoice Discount Amount" :=
                      TempVATAmountLineRemainder."Invoice Discount Amount" +
                      TempVATAmountLine."Invoice Discount Amount" * PurchLine."Line Amount" /
                      TempVATAmountLine."Inv. Disc. Base Amount";
                    PurchLine."Inv. Discount Amount" :=
                      Round(
                        TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                    TempVATAmountLineRemainder."Invoice Discount Amount" :=
                      TempVATAmountLineRemainder."Invoice Discount Amount" - PurchLine."Inv. Discount Amount";
                end;

            if PurchHeader."Prices Including VAT" then begin
                if (TempVATAmountLine.CalcLineAmount() = 0) or (PurchLine."Line Amount" = 0) then begin
                    TempVATAmountLineRemainder."VAT Amount" := 0;
                    TempVATAmountLineRemainder."Amount Including VAT" := 0;
                end else begin
                    TempVATAmountLineRemainder."VAT Amount" +=
                      TempVATAmountLine."VAT Amount" * PurchLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                    TempVATAmountLineRemainder."Amount Including VAT" +=
                      TempVATAmountLine."Amount Including VAT" * PurchLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                end;
                CalculateAmountsInclVAT(PurchHeader, PurchLine, TempVATAmountLine, TempVATAmountLineRemainder, FullGST);
                TempVATAmountLineRemainder."Amount Including VAT" :=
                  TempVATAmountLineRemainder."Amount Including VAT" - PurchLine."Amount Including VAT";
                TempVATAmountLineRemainder."VAT Amount" :=
                  TempVATAmountLineRemainder."VAT Amount" - PurchLine."Amount Including VAT" + PurchLine.Amount;
            end else
                if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Full VAT" then begin
                    IsHandled := false;
                    OnDivideAmountOnBeforeCalcAmountsForFullVAT(PurchHeader, PurchLine, IsHandled);
                    if not IsHandled then
                        if PurchLine."Line Discount %" <> 100 then
                            PurchLine."Amount Including VAT" := PurchLine.CalcLineAmount()
                        else
                            PurchLine."Amount Including VAT" := 0;
                    PurchLine.Amount := 0;
                    PurchLine."VAT Base Amount" := 0;
                end else begin
                    PurchLine.Amount := PurchLine.CalcLineAmount();
                    if FullGST and PurchLine."Prepayment Line" then
                        PurchLine."VAT Base Amount" := Round(TempVATAmountLine."VAT Base", Currency."Amount Rounding Precision")
                    else
                        PurchLine."VAT Base Amount" :=
                          Round(
                            PurchLine.Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                    OnDivideAmountOnAfterCalcVATBaseAmount(PurchLine);
                    if TempVATAmountLine."VAT Base" = 0 then begin
                        TempVATAmountLineRemainder."VAT Amount" := 0;
                        TempVATAmountLineRemainder."VAT Amount (ACY)" := 0;
                    end else
                        if PurchLine."Prepayment Line" and FullGST then begin
                            TempVATAmountLineRemainder."VAT Amount" +=
                              TempVATAmountLine."VAT Amount" * PurchLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                            TempVATAmountLineRemainder."VAT Amount (ACY)" +=
                              TempVATAmountLine."VAT Amount (ACY)" * PurchLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                        end else begin
                            TempVATAmountLineRemainder."VAT Amount" +=
                              TempVATAmountLine."VAT Amount" * PurchLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                            TempVATAmountLineRemainder."VAT Amount (ACY)" +=
                              TempVATAmountLine."VAT Amount (ACY)" * PurchLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                        end;
                    PurchLine."Amount Including VAT" :=
                      PurchLine.Amount + Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision");
                    IsHandled := false;
                    OnDivideAmountOnBeforeAmountIncludingVATAmountRound(PurchLine, TempVATAmountLineRemainder, Currency, IsHandled);
                    if not IsHandled then
                        if PurchLine."Line Discount %" <> 100 then
                            PurchLine."Amount Including VAT" :=
                                PurchLine.Amount + Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision")
                        else
                            PurchLine."Amount Including VAT" := 0;
                    TempVATAmountLineRemainder."VAT Amount" :=
                      TempVATAmountLineRemainder."VAT Amount" - PurchLine."Amount Including VAT" + PurchLine.Amount;
                    if (PurchHeader."Vendor Exchange Rate (ACY)" <> 0) or
                       ((PurchHeader."Vendor Exchange Rate (ACY)" = 1) and
                        (PurchLine."Currency Code" <> GLSetup."Additional Reporting Currency"))
                    then begin
                        PurchLine."Amount (ACY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              PurchHeader."Posting Date", GLSetup."Additional Reporting Currency",
                              Round(CurrExchRate.ExchangeAmtFCYToLCY(
                                  PurchHeader."Posting Date", PurchLine."Currency Code", PurchLine.Amount,
                                  PurchHeader."Currency Factor"), Currency."Amount Rounding Precision"), CurrencyFactor),
                            AddCurrency."Amount Rounding Precision");
                        PurchLine."VAT Base (ACY)" :=
                          Round(
                            PurchLine."Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                        PurchLine."Amount Including VAT (ACY)" :=
                          PurchLine."Amount (ACY)" + Round(TempVATAmountLineRemainder."VAT Amount (ACY)", Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount (ACY)" :=
                          TempVATAmountLineRemainder."VAT Amount (ACY)" - PurchLine."Amount Including VAT (ACY)" + PurchLine."Amount (ACY)";
                    end;
                end;

            NonDeductibleVAT.DivideNonDeductibleVATInPurchaseLine(
                PurchLine, TempVATAmountLineRemainder, TempVATAmountLine, Currency, PurchLine.CalcLineAmount(), TempVATAmountLine.CalcLineAmount());

            OnDivideAmountOnBeforeTempVATAmountLineRemainderModify(PurchHeader, PurchLine, TempVATAmountLine, TempVATAmountLineRemainder, Currency);
            TempVATAmountLineRemainder.Modify();
#pragma warning disable AA0005
            if PurchLine."Deferral Code" <> '' then begin
#if not CLEAN23
                if UseLegacyInvoicePosting() then
                    CalcDeferralAmounts(PurchHeader, PurchLine, OriginalDeferralAmount)
                else begin
#endif
                    GetInvoicePostingSetup();
                    InvoicePostingInterface.CalcDeferralAmounts(PurchHeader, PurchLine, OriginalDeferralAmount);
#if not CLEAN23
                end;
#endif
#pragma warning restore AA0005
            end;
        end;

        OnAfterDivideAmount(PurchHeader, PurchLine, QtyType, PurchLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
    end;

    local procedure CalcLineAmountAndLineDiscountAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; PurchLineQty: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLineAmountAndLineDiscountAmount(PurchHeader, PurchLine, PurchLineQty, IsHandled, Currency);
        if IsHandled then
            exit;

        PurchLine."Line Amount" := PurchLine.GetLineAmountToHandleInclPrepmt(PurchLineQty) + GetPrepmtDiffToLineAmount(PurchLine);
        if PurchLineQty <> PurchLine.Quantity then
            PurchLine."Line Discount Amount" :=
              Round(PurchLine."Line Discount Amount" * PurchLineQty / PurchLine.Quantity, Currency."Amount Rounding Precision");
    end;

    local procedure CalculateAmountsInclVAT(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; FullGST: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateAmountsInclVAT(PurchHeader, PurchLine, TempVATAmountLine, TempVATAmountLineRemainder, Currency, IsHandled);
        if IsHandled then
            exit;

        if PurchLine."Line Discount %" <> 100 then
            PurchLine."Amount Including VAT" :=
                Round(TempVATAmountLineRemainder."Amount Including VAT", Currency."Amount Rounding Precision")
        else
            PurchLine."Amount Including VAT" := 0;
        PurchLine.Amount :=
            Round(PurchLine."Amount Including VAT", Currency."Amount Rounding Precision") -
            Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision");
        if FullGST then
            PurchLine."VAT Base Amount" := TempVATAmountLine."VAT Base"
        else
            PurchLine."VAT Base Amount" :=
                Round(
                    PurchLine.Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
    end;

    local procedure RoundAmount(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchLineQty: Decimal)
    var
        NoVAT: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeRoundAmount(PurchaseHeader, PurchaseLine, PurchLineQty);

        IncrAmount(PurchaseHeader, PurchaseLine, TotalPurchLine);
        Increment(TotalPurchLine."Net Weight", Round(PurchLineQty * PurchaseLine."Net Weight", UOMMgt.WeightRndPrecision()));
        Increment(TotalPurchLine."Gross Weight", Round(PurchLineQty * PurchaseLine."Gross Weight", UOMMgt.WeightRndPrecision()));
        Increment(TotalPurchLine."Unit Volume", Round(PurchLineQty * PurchaseLine."Unit Volume", UOMMgt.CubageRndPrecision()));
        Increment(TotalPurchLine.Quantity, PurchLineQty);
        if PurchaseLine."Units per Parcel" > 0 then
            Increment(TotalPurchLine."Units per Parcel", Round(PurchLineQty / PurchaseLine."Units per Parcel", 1, '>'));

        xPurchLine := PurchaseLine;
        PurchLineACY := PurchaseLine;
        IsHandled := false;
        OnRoundAmountOnBeforeCalculateLCYAmounts(xPurchLine, PurchLineACY, PurchaseHeader, IsHandled);
        if not IsHandled then
            if PurchaseHeader."Currency Code" <> '' then
                RoundAmountInCurrency(PurchaseHeader, PurchaseLine);

        IsHandled := false;
        OnRoundAmountOnBeforeIncrAmount(PurchaseHeader, PurchaseLine, PurchLineQty, TotalPurchLine, TotalPurchLineLCY, xPurchLine, CurrExchRate, NoVAT, IsHandled, NonDeductibleVAT);
        if not IsHandled then begin
            IncrAmount(PurchaseHeader, PurchaseLine, TotalPurchLineLCY);
            Increment(TotalPurchLineLCY."Unit Cost (LCY)", Round(PurchLineQty * PurchaseLine."Unit Cost (LCY)"));
        end;

        OnAfterRoundAmount(PurchaseHeader, PurchaseLine, PurchLineQty);
    end;

    local procedure RoundAmountInCurrency(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        NoVAT: Boolean;
    begin
        GetCurrencyFactorACY(PurchaseHeader);
        NoVAT := PurchaseLine.Amount = PurchaseLine."Amount Including VAT";
        PurchaseLine."Amount Including VAT" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchLine."Amount Including VAT", PurchaseHeader."Currency Factor")) -
                TotalPurchLineLCY."Amount Including VAT";
        if NoVAT then
            PurchaseLine.Amount := PurchaseLine."Amount Including VAT"
        else
            PurchaseLine.Amount :=
                Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchLine.Amount, PurchaseHeader."Currency Factor")) -
                TotalPurchLineLCY.Amount;
        PurchaseLine."Line Amount" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchLine."Line Amount", PurchaseHeader."Currency Factor")) -
            TotalPurchLineLCY."Line Amount";
        if (PurchaseHeader."Vendor Exchange Rate (ACY)" <> 0) or
           ((PurchaseHeader."Vendor Exchange Rate (ACY)" = 1) and
            (PurchaseLine."Currency Code" <> GLSetup."Additional Reporting Currency"))
        then begin
            PurchLineACY."Inv. Discount Amount" :=
                Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                        PurchaseHeader."Posting Date", GLSetup."Additional Reporting Currency",
                        Round(CurrExchRate.ExchangeAmtFCYToLCY(
                            PurchaseHeader."Posting Date", PurchaseLine."Currency Code", PurchaseLine."Inv. Discount Amount",
                            PurchaseHeader."Currency Factor"), Currency."Amount Rounding Precision"), CurrencyFactor),
                    AddCurrency."Amount Rounding Precision");
            PurchLineACY."Line Discount Amount" :=
                Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                        PurchaseHeader."Posting Date", GLSetup."Additional Reporting Currency",
                        Round(CurrExchRate.ExchangeAmtFCYToLCY(
                            PurchaseHeader."Posting Date", PurchaseLine."Currency Code", PurchaseLine."Line Discount Amount",
                            PurchaseHeader."Currency Factor"), Currency."Amount Rounding Precision"), CurrencyFactor),
                AddCurrency."Amount Rounding Precision");
        end;
        PurchaseLine."Line Discount Amount" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchLine."Line Discount Amount", PurchaseHeader."Currency Factor")) -
            TotalPurchLineLCY."Line Discount Amount";
        PurchaseLine."Inv. Discount Amount" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchLine."Inv. Discount Amount", PurchaseHeader."Currency Factor")) -
            TotalPurchLineLCY."Inv. Discount Amount";
        PurchaseLine."VAT Difference" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchLine."VAT Difference", PurchaseHeader."Currency Factor")) -
            TotalPurchLineLCY."VAT Difference";
        PurchaseLine."VAT Base Amount" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchLine."VAT Base Amount", PurchaseHeader."Currency Factor")) -
            TotalPurchLineLCY."VAT Base Amount";
        PurchaseLine."Amount (ACY)" :=
            Round(PurchaseLine."Amount (ACY)", AddCurrency."Amount Rounding Precision");
        PurchaseLine."VAT Difference (ACY)" :=
            Round(PurchaseLine."VAT Difference (ACY)", AddCurrency."Amount Rounding Precision");
        PurchaseLine."VAT Base (ACY)" :=
            Round(PurchaseLine."VAT Base (ACY)", AddCurrency."Amount Rounding Precision");
        PurchaseLine."Amount Including VAT (ACY)" :=
            Round(PurchaseLine."Amount Including VAT (ACY)", AddCurrency."Amount Rounding Precision");
        NonDeductibleVAT.RoundNonDeductibleVAT(PurchaseHeader, PurchaseLine, TotalPurchLine, TotalPurchLineLCY);
    end;

    procedure ReverseAmount(var PurchLine: Record "Purchase Line")
    begin
        PurchLine."Qty. to Receive" := -PurchLine."Qty. to Receive";
        PurchLine."Qty. to Receive (Base)" := -PurchLine."Qty. to Receive (Base)";
        PurchLine."Return Qty. to Ship" := -PurchLine."Return Qty. to Ship";
        PurchLine."Return Qty. to Ship (Base)" := -PurchLine."Return Qty. to Ship (Base)";
        PurchLine."Qty. to Invoice" := -PurchLine."Qty. to Invoice";
        PurchLine."Qty. to Invoice (Base)" := -PurchLine."Qty. to Invoice (Base)";
        PurchLine."Line Amount" := -PurchLine."Line Amount";
        PurchLine.Amount := -PurchLine.Amount;
        PurchLine."VAT Base Amount" := -PurchLine."VAT Base Amount";
        PurchLine."VAT Difference" := -PurchLine."VAT Difference";
        PurchLine."Amount Including VAT" := -PurchLine."Amount Including VAT";
        PurchLine."Line Discount Amount" := -PurchLine."Line Discount Amount";
        PurchLine."Inv. Discount Amount" := -PurchLine."Inv. Discount Amount";
        PurchLine."Amount (ACY)" := -PurchLine."Amount (ACY)";
        PurchLine."VAT Base (ACY)" := -PurchLine."VAT Base (ACY)";
        PurchLine."VAT Difference (ACY)" := -PurchLine."VAT Difference (ACY)";
        PurchLine."Amount Including VAT (ACY)" := -PurchLine."Amount Including VAT (ACY)";
        PurchLine."Salvage Value" := -PurchLine."Salvage Value";
        NonDeductibleVAT.Reverse(PurchLine);
        OnAfterReverseAmount(PurchLine);
    end;

    local procedure InvoiceRounding(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; UseTempData: Boolean; BiggestLineNo: Integer)
    var
        VendPostingGr: Record "Vendor Posting Group";
        InvoiceRoundingAmount: Decimal;
        InvoiceRoundingAmountACY: Decimal;
    begin
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalPurchLine."Amount Including VAT" -
            Round(
              TotalPurchLine."Amount Including VAT", Currency."Invoice Rounding Precision", Currency.InvoiceRoundingDirection()),
            Currency."Amount Rounding Precision");

        OnBeforeInvoiceRoundingAmount(
          PurchHeader, TotalPurchLine."Amount Including VAT", UseTempData, InvoiceRoundingAmount, SuppressCommit, PurchLine);
        if InvoiceRoundingAmount <> 0 then begin
            VendPostingGr.Get(PurchHeader."Vendor Posting Group");
            VendPostingGr.TestField("Invoice Rounding Account");
            PurchLine.Init();
            BiggestLineNo := BiggestLineNo + 10000;
            PurchLine."System-Created Entry" := true;
            if UseTempData then begin
                PurchLine."Line No." := 0;
                PurchLine.Type := PurchLine.Type::"G/L Account";
            end else begin
                PurchLine."Line No." := BiggestLineNo;
                PurchLine.Validate(Type, PurchLine.Type::"G/L Account");
            end;
            PurchLine.Validate("No.", VendPostingGr.GetInvRoundingAccount());
            PurchLine.Validate(Quantity, 1);
            if PurchLine.IsCreditDocType() then
                PurchLine.Validate("Return Qty. to Ship", PurchLine.Quantity)
            else
                PurchLine.Validate("Qty. to Receive", PurchLine.Quantity);
            if PurchHeader."Prices Including VAT" then
                PurchLine.Validate("Direct Unit Cost", InvoiceRoundingAmount)
            else
                PurchLine.Validate(
                  "Direct Unit Cost",
                  Round(
                    InvoiceRoundingAmount /
                    (1 + (1 - PurchHeader."VAT Base Discount %" / 100) * PurchLine."VAT %" / 100),
                    Currency."Amount Rounding Precision"));
            PurchLine.Validate("Amount Including VAT", InvoiceRoundingAmount);
            if TotalPurchLine."Amount Including VAT (ACY)" <> 0 then begin
                if (PurchHeader."Currency Code" <> GLSetup."Additional Reporting Currency") and (PurchHeader."Currency Code" <> '') then
                    InvoiceRoundingAmountACY := Round(CurrExchRate.ExchangeAmtLCYToFCY(
                          PurchHeader."Posting Date", GLSetup."Additional Reporting Currency",
                          Round(CurrExchRate.ExchangeAmtFCYToLCY(
                              PurchHeader."Posting Date", PurchLine."Currency Code", InvoiceRoundingAmount,
                              PurchHeader."Currency Factor"), Currency."Amount Rounding Precision"), CurrencyFactor),
                        AddCurrency."Amount Rounding Precision")
                else
                    if (PurchHeader."Currency Code" = GLSetup."Additional Reporting Currency") and (PurchHeader."Currency Code" <> '') then
                        InvoiceRoundingAmountACY := InvoiceRoundingAmount
                    else
                        if PurchHeader."Currency Code" = '' then
                            InvoiceRoundingAmountACY := Round(CurrExchRate.ExchangeAmtLCYToFCY(
                                  PurchHeader."Posting Date", GLSetup."Additional Reporting Currency", InvoiceRoundingAmount,
                                  CurrencyFactor), AddCurrency."Amount Rounding Precision");
                PurchLine.Validate("Amount Including VAT (ACY)", InvoiceRoundingAmountACY);
            end;
            PurchLine."Line No." := BiggestLineNo;
            LastLineRetrieved := false;
            RoundingLineInserted := true;
            RoundingLineNo := PurchLine."Line No.";
        end;

        OnAfterInvoiceRoundingAmount(
          PurchHeader, PurchLine, TotalPurchLine, UseTempData, InvoiceRoundingAmount, SuppressCommit, RoundingLineInserted, RoundingLineNo);
    end;

    procedure IncrAmount(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var TotalPurchLine: Record "Purchase Line")
    begin
        if PurchHeader."Prices Including VAT" or
           (PurchLine."VAT Calculation Type" <> PurchLine."VAT Calculation Type"::"Full VAT")
        then
            Increment(TotalPurchLine."Line Amount", PurchLine."Line Amount");
        Increment(TotalPurchLine.Amount, PurchLine.Amount);
        Increment(TotalPurchLine."VAT Base Amount", PurchLine."VAT Base Amount");
        Increment(TotalPurchLine."VAT Difference", PurchLine."VAT Difference");
        Increment(TotalPurchLine."Amount Including VAT", PurchLine."Amount Including VAT");
        Increment(TotalPurchLine."VAT Base (ACY)", PurchLine."VAT Base (ACY)");
        Increment(TotalPurchLine."VAT Difference (ACY)", PurchLine."VAT Difference (ACY)");
        Increment(TotalPurchLine."Amount Including VAT (ACY)", PurchLine."Amount Including VAT (ACY)");
        Increment(TotalPurchLine."Amount (ACY)", PurchLine."Amount (ACY)");
        Increment(TotalPurchLine."Line Discount Amount", PurchLine."Line Discount Amount");
        Increment(TotalPurchLine."Inv. Discount Amount", PurchLine."Inv. Discount Amount");
        Increment(TotalPurchLine."Inv. Disc. Amount to Invoice", PurchLine."Inv. Disc. Amount to Invoice");
        Increment(TotalPurchLine."Prepmt. Line Amount", PurchLine."Prepmt. Line Amount");
        Increment(TotalPurchLine."Prepmt. Amt. Inv.", PurchLine."Prepmt. Amt. Inv.");
        Increment(TotalPurchLine."Prepmt Amt to Deduct", PurchLine."Prepmt Amt to Deduct");
        Increment(TotalPurchLine."Prepmt Amt Deducted", PurchLine."Prepmt Amt Deducted");
        Increment(TotalPurchLine."Prepayment VAT Difference", PurchLine."Prepayment VAT Difference");
        Increment(TotalPurchLine."Prepmt VAT Diff. to Deduct", PurchLine."Prepmt VAT Diff. to Deduct");
        Increment(TotalPurchLine."Prepmt VAT Diff. Deducted", PurchLine."Prepmt VAT Diff. Deducted");
        NonDeductibleVAT.Increment(TotalPurchLine, PurchLine);

        OnAfterIncrAmount(TotalPurchLine, PurchLine);
    end;

    local procedure Increment(var Number: Decimal; Number2: Decimal)
    begin
        Number := Number + Number2;
    end;

    procedure GetPurchLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping)
    begin
        OnBeforeGetPurchLines(PurchHeader);
        FillTempLines(PurchHeader, TempPurchLineGlobal);
        OnGetPurchLinesOnAfterFillTempLines(PurchHeader, PurchLine, QtyType, TempPurchLineGlobal);
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
        OnBeforeSumPurchLinesTemp(PurchHeader);
        SumPurchLines2(PurchHeader, PurchLine, OldPurchLine, QtyType, false);
        VATAmount := TotalPurchLine."Amount Including VAT" - TotalPurchLine.Amount;
        if TotalPurchLine."VAT %" = 0 then
            VATAmountText := VATAmountTxt
        else
            VATAmountText := StrSubstNo(VATRateTxt, TotalPurchLine."VAT %");
        NewTotalPurchLine := TotalPurchLine;
        NewTotalPurchLineLCY := TotalPurchLineLCY;
    end;

    procedure SumPurchLines2(PurchHeader: Record "Purchase Header"; var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; InsertPurchLine: Boolean)
    var
        PurchLine: Record "Purchase Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        IsHandled: Boolean;
        PurchLineQty: Decimal;
        BiggestLineNo: Integer;
    begin
        IsHandled := false;
        OnBeforeSumPurchLines2(QtyType, PurchHeader, OldPurchLine, TempVATAmountLine, InsertPurchLine, IsHandled);
        if IsHandled then
            exit;

        TempVATAmountLineRemainder.DeleteAll();
        OldPurchLine.CalcVATAmountLines(QtyType, PurchHeader, OldPurchLine, TempVATAmountLine);

        GetGLSetup();
        GetPurchSetup();
        GetCurrency(PurchHeader."Currency Code");
        OldPurchLine.SetRange("Document Type", PurchHeader."Document Type");
        OldPurchLine.SetRange("Document No.", PurchHeader."No.");
        OnSumPurchLines2OnAfterSetFilters(OldPurchLine, PurchHeader);
        RoundingLineInserted := false;
        if OldPurchLine.FindSet() then
            repeat
                if not RoundingLineInserted then
                    PurchLine := OldPurchLine;
                OnSumPurchLines2OnAfterIsRoundingLineInserted(PurchHeader, PurchLine, OldPurchLine, RoundingLineInserted);
                case QtyType of
                    QtyType::General:
                        PurchLineQty := PurchLine.Quantity;
                    QtyType::Invoicing:
                        PurchLineQty := PurchLine."Qty. to Invoice";
                    QtyType::Shipping:
                        if PurchHeader.IsCreditDocType() then
                            PurchLineQty := PurchLine."Return Qty. to Ship"
                        else
                            PurchLineQty := PurchLine."Qty. to Receive"
                end;

                OnSumPurchLines2OnBeforeDivideAmount(PurchHeader, PurchLine, QtyType);
                DivideAmount(PurchHeader, PurchLine, QtyType, PurchLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
                OnSumPurchLines2OnAfterDivideAmount(PurchHeader, PurchLine, QtyType, PurchLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
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
                    NewPurchLine.Insert();
                end;
                if RoundingLineInserted then
                    LastLineRetrieved := true
                else begin
                    BiggestLineNo := MAX(BiggestLineNo, OldPurchLine."Line No.");
                    LastLineRetrieved := OldPurchLine.Next() = 0;
                    if LastLineRetrieved and PurchSetup."Invoice Rounding" then
                        InvoiceRounding(PurchHeader, PurchLine, true, BiggestLineNo);
                end;
            until LastLineRetrieved;

        OnAfterSumPurchLines2(PurchHeader, OldPurchLine, NewPurchLine);
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
                OnUpdateBlanketOrderLineOnAfterCheckBlanketOrderPurchLine(BlanketOrderPurchLine, PurchLine);

                ModifyLine := false;
                case PurchLine."Document Type" of
                    PurchLine."Document Type"::Order,
                  PurchLine."Document Type"::Invoice:
                        Sign := 1;
                    PurchLine."Document Type"::"Return Order",
                  PurchLine."Document Type"::"Credit Memo":
                        Sign := -1;
                    else
                        OnUpdateBlanketOrderLineOnTypeCaseElse(PurchLine, Sign);
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
                            UOMMgt.QtyRndPrecision());
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
                            UOMMgt.QtyRndPrecision());
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
                            UOMMgt.QtyRndPrecision());
                    BlanketOrderPurchLine."Qty. Invoiced (Base)" :=
                      BlanketOrderPurchLine."Qty. Invoiced (Base)" + Sign * PurchLine."Qty. to Invoice (Base)";
                    ModifyLine := true;
                end;

                if ModifyLine then begin
                    OnUpdateBlanketOrderLineOnBeforeInitOutstanding(BlanketOrderPurchLine, PurchLine, Ship, Receive, Invoice);
                    BlanketOrderPurchLine.InitOutstanding();

                    IsHandled := false;
                    OnUpdateBlanketOrderLineOnBeforeCheck(BlanketOrderPurchLine, PurchLine, IsHandled, Ship, Receive, Invoice);
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
                    if (PurchLine.Quantity = PurchLine."Quantity Received") or (PurchLine."Quantity Received" = 0) then
                        BlanketOrderPurchLine."Qty. to Receive" :=
                            BlanketOrderPurchLine.Quantity - BlanketOrderPurchLine."Quantity Received";
                    BlanketOrderPurchLine."Qty. to Invoice (Base)" :=
                        BlanketOrderPurchLine."Quantity (Base)" - BlanketOrderPurchLine."Qty. Invoiced (Base)";
                    if (PurchLine."Quantity (Base)" = PurchLine."Qty. Received (Base)") or (PurchLine."Qty. Received (Base)" = 0) then
                        BlanketOrderPurchLine."Qty. to Receive (Base)" :=
                            BlanketOrderPurchLine."Quantity (Base)" - BlanketOrderPurchLine."Qty. Received (Base)";

                    OnBeforeBlanketOrderPurchLineModify(BlanketOrderPurchLine, PurchLine, Ship, Receive, Invoice);
                    BlanketOrderPurchLine.Modify();
                    OnAfterBlanketOrderPurchLineModify(BlanketOrderPurchLine, PurchLine, Ship, Receive, Invoice);
                end;
            end;
    end;

    local procedure UpdatePurchaseHeader(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchaseHeader: Record "Purchase Header")
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchaseHeader(VendorLedgerEntry, PurchInvHeader, PurchCrMemoHeader, GenJnlLineDocType.AsInteger(), IsHandled, PurchaseHeader);
        if IsHandled then
            exit;

        case GenJnlLineDocType of
            GenJnlLine."Document Type"::Invoice:
                begin
                    FindVendorLedgerEntry(GenJnlLineDocType, GenJnlLineDocNo, VendorLedgerEntry);
                    PurchInvHeader."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
                    PurchInvHeader.Modify();
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    FindVendorLedgerEntry(GenJnlLineDocType, GenJnlLineDocNo, VendorLedgerEntry);
                    PurchCrMemoHeader."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
                    PurchCrMemoHeader.Modify();
                end;
        end;

        OnAfterUpdatePurchaseHeader(VendorLedgerEntry, PurchInvHeader, PurchCrMemoHeader, GenJnlLineDocType.AsInteger(), GenJnlLineDocNo, PreviewMode);
    end;

#if not CLEAN23
    local procedure PostVendorEntry(var PurchHeader: Record "Purchase Header"; TotalPurchLine2: Record "Purchase Line"; TotalPurchLineLCY2: Record "Purchase Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Code[35]; SourceCode: Code[10]; TotalWHTAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPostVendorEntryOnBeforeInitNewLine(PurchHeader, TotalPurchLine, TotalPurchLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PurchHeader."Posting Description",
            PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
            PurchHeader."Dimension Set ID", PurchHeader."Reason Code");
        OnPostVendorEntryOnAfterInitNewLine(PurchHeader, GenJnlLine);

        GenJnlLine.CopyDocumentFields(DocType, DocNo, ExtDocNo, SourceCode, '');
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := PurchHeader."Pay-to Vendor No.";
        GenJnlLine.CopyFromPurchHeader(PurchHeader);
        GenJnlLine.SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");
        GenJnlLine."WHT Business Posting Group" := TempPurchLineGlobal."WHT Business Posting Group";
        GenJnlLine."WHT Product Posting Group" := TempPurchLineGlobal."WHT Product Posting Group";
        GenJnlLine."Vendor Exchange Rate (ACY)" := PurchHeader."Vendor Exchange Rate (ACY)";
        GenJnlLine."System-Created Entry" := true;

        GenJnlLine.CopyFromPurchHeaderApplyTo(PurchHeader);
        GenJnlLine.CopyFromPurchHeaderPayment(PurchHeader);
        GenJnlLine.Adjustment := PurchHeader.Adjustment;
        GenJnlLine."BAS Adjustment" := PurchHeader."BAS Adjustment";
        GenJnlLine."Adjustment Applies-to" := PurchHeader."Adjustment Applies-to";

        InitGenJnlLineAmountFieldsFromTotalPurchLine(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, TotalWHTAmount);

        IsHandled := false;
        OnBeforePostVendorEntry(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, PreviewMode, SuppressCommit, GenJnlPostLine, IsHandled);
        if not IsHandled then
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostVendorEntry(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, SuppressCommit, GenJnlPostLine);
    end;
#endif

#if not CLEAN23
    local procedure InitGenJnlLineAmountFieldsFromTotalPurchLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine2: Record "Purchase Line"; var TotalPurchLineLCY2: Record "Purchase Line"; TotalWHTAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitGenJnlLineAmountFieldsFromTotalPurchLine(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, IsHandled);
        if IsHandled then
            exit;

        if TotalWHTAmount <> 0 then begin
            GenJnlLine.Amount := -(TotalPurchLine."Amount Including VAT" - TotalWHTAmount);
            GenJnlLine."Source Currency Amount" :=
              -(TotalPurchLine2."Amount Including VAT" - TotalWHTAmount);
            if PurchHeader."Currency Code" <> '' then
                GenJnlLine."Amount (LCY)" :=
                  -(TotalPurchLineLCY2."Amount Including VAT" -
                    Round(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        PurchHeader."Posting Date", PurchHeader."Currency Code", TotalWHTAmount, PurchHeader."Currency Factor")))
            else
                GenJnlLine."Amount (LCY)" :=
                  -(TotalPurchLineLCY2."Amount Including VAT" - TotalWHTAmount);
        end else begin
            GenJnlLine.Amount := -TotalPurchLine2."Amount Including VAT";
            GenJnlLine."Source Currency Amount" := -TotalPurchLine2."Amount Including VAT";
            GenJnlLine."Amount (LCY)" := -TotalPurchLineLCY2."Amount Including VAT";
        end;
        GenJnlLine."Amount Including VAT (ACY)" := -TotalPurchLineLCY2."Amount Including VAT (ACY)";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalPurchLineLCY2.Amount;
        GenJnlLine."Inv. Discount (LCY)" := -TotalPurchLineLCY2."Inv. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible" := -TotalPurchLine2."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            PurchHeader.GetUseDate(), PurchHeader."Currency Code", -TotalPurchLine2."Pmt. Discount Amount", PurchHeader."Currency Factor");
    end;
#endif

#if not CLEAN23
    local procedure PostBalancingEntry(PurchHeader: Record "Purchase Header"; TotalPurchLine2: Record "Purchase Line"; TotalPurchLineLCY2: Record "Purchase Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Code[35]; SourceCode: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        EntryFound: Boolean;
        IsHandled: Boolean;
    begin
        EntryFound := false;
        IsHandled := false;
        OnPostBalancingEntryOnBeforeFindVendLedgEntry(
          PurchHeader, TotalPurchLine2, DocType.AsInteger(), DocNo, ExtDocNo, VendLedgEntry2, EntryFound, IsHandled);
        if IsHandled then
            exit;

        if not EntryFound then
            FindVendorLedgerEntry(DocType, DocNo, VendLedgEntry2);

        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PurchHeader."Posting Description",
            PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
            PurchHeader."Dimension Set ID", PurchHeader."Reason Code");
        OnPostBalancingEntryOnAfterInitNewLine(PurchHeader, GenJnlLine);

        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Purchases);
        if GenJnlTemplate.FindFirst() then begin
            GenJnlLine.Validate("Journal Template Name", GenJnlTemplate.Name);
            GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
            if GenJnlBatch.FindFirst() then
                GenJnlLine.Validate("Journal Batch Name", GenJnlBatch.Name);
        end;
        GenJnlLine."WHT Business Posting Group" := TempPurchLineGlobal."WHT Business Posting Group";
        GenJnlLine."WHT Product Posting Group" := TempPurchLineGlobal."WHT Product Posting Group";

        GenJnlLine.CopyDocumentFields(Enum::"Gen. Journal Document Type"::" ", DocNo, ExtDocNo, SourceCode, '');
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := PurchHeader."Pay-to Vendor No.";
        GenJnlLine.CopyFromPurchHeader(PurchHeader);
        GenJnlLine.SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");

        if PurchHeader.IsCreditDocType() then
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund
        else
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;

        SetApplyToDocNo(PurchHeader, GenJnlLine, DocType, DocNo);

        GenJnlLine.Amount := TotalPurchLine2."Amount Including VAT" + VendLedgEntry2."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        VendLedgEntry2.CalcFields(Amount);
        if VendLedgEntry2.Amount = 0 then begin
            GenJnlLine."Amount (LCY)" := TotalPurchLineLCY2."Amount Including VAT";
            GenJnlLine."Amount Including VAT (ACY)" := TotalPurchLineLCY2."Amount Including VAT (ACY)"
        end else begin
            GenJnlLine."Amount (LCY)" :=
              TotalPurchLineLCY2."Amount Including VAT" +
              Round(VendLedgEntry2."Remaining Pmt. Disc. Possible" / VendLedgEntry2."Adjusted Currency Factor");
            GenJnlLine."Amount Including VAT (ACY)" := TotalPurchLineLCY2."Amount Including VAT (ACY)"
        end;
        GenJnlLine."Allow Zero-Amount Posting" := true;
        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalPurchLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            PurchHeader.GetUseDate(), PurchHeader."Currency Code", TotalPurchLine."Pmt. Discount Amount", PurchHeader."Currency Factor");

        OnBeforePostBalancingEntry(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, PreviewMode, SuppressCommit, VendLedgEntry);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostBalancingEntry(GenJnlLine, PurchHeader, TotalPurchLine2, TotalPurchLineLCY2, SuppressCommit, GenJnlPostLine);
    end;
#endif

#if not CLEAN23
    local procedure SetApplyToDocNo(PurchHeader: Record "Purchase Header"; var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        if PurchHeader."Bal. Account Type" = PurchHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := PurchHeader."Bal. Account No.";
        GenJnlLine."Applies-to Doc. Type" := DocType;
        GenJnlLine."Applies-to Doc. No." := DocNo;

        OnAfterSetApplyToDocNo(GenJnlLine, PurchHeader);
    end;
#endif

    local procedure FindVendorLedgerEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange("Document Type", DocType);
        VendorLedgerEntry.SetRange("Document No.", DocNo);
        VendorLedgerEntry.FindLast();
    end;

#if not CLEAN23
    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"): Integer
    begin
        OnBeforeRunGenJnlPostLine(GenJnlLine);
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;
#endif

    local procedure CheckPostRestrictions(PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostRestrictions(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        if not PreviewMode then
            PurchaseHeader.CheckPurchasePostRestrictions();

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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFAPostingPossibility(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Fixed Asset");
        PurchaseLine.SetFilter("No.", '<>%1', '');
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLineToFind.CopyFilters(PurchaseLine);
                PurchaseLineToFind.SetRange("No.", PurchaseLine."No.");
                PurchaseLineToFind.SetRange("Depr. until FA Posting Date", not PurchaseLine."Depr. until FA Posting Date");
                if not PurchaseLineToFind.IsEmpty() then
                    Error(ErrorInfo.Create(StrSubstNo(MixedDerpFAUntilPostingDateErr, PurchaseLine."No."), true, PurchaseLine));

                if PurchaseLine."Depr. until FA Posting Date" then begin
                    PurchaseLineToFind.SetRange("Depr. until FA Posting Date", true);
                    PurchaseLineToFind.SetFilter("Line No.", '<>%1', PurchaseLine."Line No.");
                    if not PurchaseLineToFind.IsEmpty() then begin
                        HasBookValue := false;
                        FADepreciationBook.SetRange("FA No.", PurchaseLine."No.");
                        FADepreciationBook.FindSet();
                        repeat
                            FADepreciationBook.CalcFields("Book Value");
                            HasBookValue := HasBookValue or (FADepreciationBook."Book Value" <> 0);
                        until (FADepreciationBook.Next() = 0) or HasBookValue;
                        if not HasBookValue then
                            Error(ErrorInfo.Create(StrSubstNo(CannotPostSameMultipleFAWhenDeprBookValueZeroErr, PurchaseLine."No."), true, PurchaseLine));
                    end;
                end;
            until PurchaseLine.Next() = 0;
    end;

    local procedure DeleteItemChargeAssgnt(PurchHeader: Record "Purchase Header")
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgntPurch.SetRange("Document Type", PurchHeader."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchHeader."No.");
        if not ItemChargeAssgntPurch.IsEmpty() then
            ItemChargeAssgntPurch.DeleteAll();

        OnAfterDeleteItemChargeAssgnt(PurchHeader);
    end;

    local procedure UpdateItemChargeAssgnt(var PurchHeader: Record "Purchase Header")
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemChargeAssgnt(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        ClearItemChargeAssgntFilter();
        TempItemChargeAssgntPurch.MarkedOnly(true);
        if TempItemChargeAssgntPurch.FindSet() then
            repeat
                ItemChargeAssgntPurch.Get(TempItemChargeAssgntPurch."Document Type", TempItemChargeAssgntPurch."Document No.", TempItemChargeAssgntPurch."Document Line No.", TempItemChargeAssgntPurch."Line No.");
                ItemChargeAssgntPurch."Qty. Assigned" += ItemChargeAssgntPurch."Qty. to Handle";
                ItemChargeAssgntPurch."Qty. to Assign" -= ItemChargeAssgntPurch."Qty. to Handle";
                ItemChargeAssgntPurch."Amount to Assign" -= ItemChargeAssgntPurch."Amount to Handle";
                ItemChargeAssgntPurch."Qty. to Handle" := 0;
                ItemChargeAssgntPurch."Amount to Handle" := 0;
                ItemChargeAssgntPurch.Modify();
            until TempItemChargeAssgntPurch.Next() = 0;
    end;

    procedure UpdatePurchOrderChargeAssgnt(PurchOrderInvLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line")
    var
        PurchOrderLine2: Record "Purchase Line";
        PurchOrderInvLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        DocumentNo: Code[20];
    begin
        ClearItemChargeAssgntFilter();
        TempItemChargeAssgntPurch.SetRange("Document Type", PurchOrderInvLine."Document Type");
        TempItemChargeAssgntPurch.SetRange("Document No.", PurchOrderInvLine."Document No.");
        TempItemChargeAssgntPurch.SetRange("Document Line No.", PurchOrderInvLine."Line No.");
        TempItemChargeAssgntPurch.MarkedOnly(true);
        if TempItemChargeAssgntPurch.FindSet() then
            repeat
                if TempItemChargeAssgntPurch."Applies-to Doc. Type" = PurchOrderInvLine."Document Type" then begin
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
                          TempItemChargeAssgntPurch."Qty. to Handle");
                end else
                    UpdatePurchChargeAssgntLines(
                      PurchOrderLine,
                      TempItemChargeAssgntPurch."Applies-to Doc. Type",
                      TempItemChargeAssgntPurch."Applies-to Doc. No.",
                      TempItemChargeAssgntPurch."Applies-to Doc. Line No.",
                      TempItemChargeAssgntPurch."Qty. to Handle");
            until TempItemChargeAssgntPurch.Next() = 0;
    end;

    local procedure UpdatePurchChargeAssgntLines(PurchOrderLine: Record "Purchase Line"; ApplToDocType: Enum "Purchase Applies-to Document Type"; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; QtytoHandle: Decimal)
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
        if ItemChargeAssgntPurch.FindFirst() then begin
            GetCurrency(PurchOrderLine."Currency Code");
            ItemChargeAssgntPurch."Qty. Assigned" += QtyToHandle;
            ItemChargeAssgntPurch."Qty. to Assign" -= QtyToHandle;
            ItemChargeAssgntPurch."Qty. to Handle" -= QtyToHandle;
            if ItemChargeAssgntPurch."Qty. to Assign" < 0 then
                ItemChargeAssgntPurch."Qty. to Assign" := 0;
            ItemChargeAssgntPurch."Amount to Assign" :=
              Round(ItemChargeAssgntPurch."Qty. to Assign" * ItemChargeAssgntPurch."Unit Cost", Currency."Amount Rounding Precision");
            if ItemChargeAssgntPurch."Qty. to Handle" < 0 then
                ItemChargeAssgntPurch."Qty. to Handle" := 0;
            ItemChargeAssgntPurch."Amount to Handle" :=
              Round(ItemChargeAssgntPurch."Qty. to Handle" * ItemChargeAssgntPurch."Unit Cost", Currency."Amount Rounding Precision");
            ItemChargeAssgntPurch.Modify();
        end else begin
            ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type");
            ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.");
            ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.");
            ItemChargeAssgntPurch.CalcSums("Qty. to Assign", "Qty. to Handle");

            TempItemChargeAssgntPurch2.SetRange("Document Type", TempItemChargeAssgntPurch."Document Type");
            TempItemChargeAssgntPurch2.SetRange("Document No.", TempItemChargeAssgntPurch."Document No.");
            TempItemChargeAssgntPurch2.SetRange("Document Line No.", TempItemChargeAssgntPurch."Document Line No.");
            TempItemChargeAssgntPurch2.CalcSums("Qty. to Assign", "Qty. to Handle");

            TotalToAssign := ItemChargeAssgntPurch."Qty. to Handle" +
              TempItemChargeAssgntPurch2."Qty. to Handle";

            if ItemChargeAssgntPurch.FindLast() then
                LastLineNo := ItemChargeAssgntPurch."Line No.";

            if PurchOrderLine.Quantity < TotalToAssign then
                repeat
                    TotalToAssign -= ItemChargeAssgntPurch."Qty. to Handle";
                    ItemChargeAssgntPurch."Qty. to Assign" -= ItemChargeAssgntPurch."Qty. to Handle";
                    ItemChargeAssgntPurch."Amount to Assign" -= ItemChargeAssgntPurch."Amount to Handle";
                    ItemChargeAssgntPurch."Qty. to Handle" := 0;
                    ItemChargeAssgntPurch."Amount to Handle" := 0;
                    ItemChargeAssgntPurch.Modify();
                until (ItemChargeAssgntPurch.Next(-1) = 0) or
                      (TotalToAssign = PurchOrderLine.Quantity);

            InsertAssocOrderCharge(
              PurchOrderLine, ApplToDocType, ApplToDocNo, ApplToDocLineNo, LastLineNo,
              TempItemChargeAssgntPurch."Applies-to Doc. Line Amount");
        end;
    end;

    local procedure InsertAssocOrderCharge(PurchOrderLine: Record "Purchase Line"; ApplToDocType: Enum "Purchase Applies-to Document Type"; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; LastLineNo: Integer; ApplToDocLineAmt: Decimal)
    var
        NewItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        NewItemChargeAssgntPurch.Init();
        NewItemChargeAssgntPurch."Document Type" := PurchOrderLine."Document Type";
        NewItemChargeAssgntPurch."Document No." := PurchOrderLine."Document No.";
        NewItemChargeAssgntPurch."Document Line No." := PurchOrderLine."Line No.";
        NewItemChargeAssgntPurch."Line No." := LastLineNo + 10000;
        NewItemChargeAssgntPurch."Item Charge No." := TempItemChargeAssgntPurch."Item Charge No.";
        NewItemChargeAssgntPurch."Item No." := TempItemChargeAssgntPurch."Item No.";
        NewItemChargeAssgntPurch."Qty. Assigned" := TempItemChargeAssgntPurch."Qty. to Handle";
        NewItemChargeAssgntPurch."Qty. to Handle" := 0;
        NewItemChargeAssgntPurch."Amount to Handle" := 0;
        NewItemChargeAssgntPurch.Description := TempItemChargeAssgntPurch.Description;
        NewItemChargeAssgntPurch."Unit Cost" := TempItemChargeAssgntPurch."Unit Cost";
        NewItemChargeAssgntPurch."Applies-to Doc. Type" := ApplToDocType;
        NewItemChargeAssgntPurch."Applies-to Doc. No." := ApplToDocNo;
        NewItemChargeAssgntPurch."Applies-to Doc. Line No." := ApplToDocLineNo;
        NewItemChargeAssgntPurch."Applies-to Doc. Line Amount" := ApplToDocLineAmt;
        OnInsertAssocOrderChargeOnBeforeInsert(TempItemChargeAssgntPurch, NewItemChargeAssgntPurch);
        NewItemChargeAssgntPurch.Insert();
    end;

    procedure CopyAndCheckItemCharge(PurchHeader: Record "Purchase Header")
    var
        TempPurchLine: Record "Purchase Line" temporary;
        InvoiceEverything: Boolean;
        AssignError: Boolean;
    begin
        TempItemChargeAssgntPurch.Reset();
        TempItemChargeAssgntPurch.DeleteAll();

        // Check for max qty posting
        ResetTempLines(TempPurchLine);
        TempPurchLine.SetRange(Type, TempPurchLine.Type::"Charge (Item)");
        OnCopyAndCheckItemChargeOnBeforeCheckIfEmpty(TempPurchLine);
        if TempPurchLine.IsEmpty() then
            exit;

        CopyItemChargeForPurchLine(TempItemChargeAssgntPurch, TempPurchLine);

        TempPurchLine.SetFilter("Qty. to Invoice", '<>0');
        if TempPurchLine.FindSet() then
            repeat
                OnCopyAndCheckItemChargeOnBeforeLoop(TempPurchLine, PurchHeader);
                CopyAndCheckItemChargeTempPurchLine(PurchHeader, TempPurchLine, AssignError);
            until TempPurchLine.Next() = 0;

        // Check purchlines
        if AssignError then
            if PurchHeader."Document Type" in
               [PurchHeader."Document Type"::Invoice, PurchHeader."Document Type"::"Credit Memo"]
            then
                InvoiceEverything := true
            else begin
                TempPurchLine.Reset();
                TempPurchLine.SetFilter(Type, '%1|%2', TempPurchLine.Type::Item, TempPurchLine.Type::"Charge (Item)");
                CalculateInvoiceEverything(TempPurchLine, PurchHeader, InvoiceEverything);
            end;

        if InvoiceEverything and AssignError then
            Error(ErrorInfo.Create(MustAssignErr, true, PurchHeader));
    end;

    local procedure CalculateInvoiceEverything(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header"; var InvoiceEverything: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateInvoiceEverything(TempPurchaseLine, PurchaseHeader, InvoiceEverything, IsHandled);
        if IsHandled then
            exit;

        if TempPurchaseLine.FindSet() then
            repeat
                if PurchaseHeader.Ship or PurchaseHeader.Receive then
                    InvoiceEverything := TempPurchaseLine.Quantity = TempPurchaseLine."Qty. to Invoice" + TempPurchaseLine."Quantity Invoiced"
                else
                    InvoiceEverything := (TempPurchaseLine.Quantity = TempPurchaseLine."Qty. to Invoice" + TempPurchaseLine."Quantity Invoiced") and
                      (TempPurchaseLine."Qty. to Invoice" = TempPurchaseLine."Qty. Rcd. Not Invoiced" + TempPurchaseLine."Return Qty. Shipped Not Invd.");
            until (TempPurchaseLine.Next() = 0) or (not InvoiceEverything);
    end;

    local procedure CopyAndCheckItemChargeTempPurchLine(PurchHeader: Record "Purchase Header"; TempPurchLine: Record "Purchase Line" temporary; var AssignError: Boolean)
    var
        PurchLine: Record "Purchase Line";
        QtyNeeded: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyAndCheckItemChargeTempPurchLine(PurchHeader, TempPurchLine, TempItemChargeAssgntPurch, IsHandled, AssignError);
        if IsHandled then
            exit;

        TempPurchLine.TestField("Job No.", '');
        if PurchHeader.Invoice and
           (TempPurchLine."Qty. to Receive" + TempPurchLine."Return Qty. to Ship" <> 0) and
           ((PurchHeader.Ship or PurchHeader.Receive) or
            (Abs(TempPurchLine."Qty. to Invoice") >
             Abs(TempPurchLine."Qty. Rcd. Not Invoiced" + TempPurchLine."Qty. to Receive") +
             Abs(TempPurchLine."Ret. Qty. Shpd Not Invd.(Base)" + TempPurchLine."Return Qty. to Ship")))
        then
            TempPurchLine.TestField("Line Amount");

        if not PurchHeader.Receive then
            TempPurchLine."Qty. to Receive" := 0;
        if not PurchHeader.Ship then
            TempPurchLine."Return Qty. to Ship" := 0;
        if Abs(TempPurchLine."Qty. to Invoice") >
           Abs(TempPurchLine."Quantity Received" + TempPurchLine."Qty. to Receive" +
             TempPurchLine."Return Qty. Shipped" + TempPurchLine."Return Qty. to Ship" -
             TempPurchLine."Quantity Invoiced")
        then
            TempPurchLine."Qty. to Invoice" :=
              TempPurchLine."Quantity Received" + TempPurchLine."Qty. to Receive" +
              TempPurchLine."Return Qty. Shipped (Base)" + TempPurchLine."Return Qty. to Ship (Base)" -
              TempPurchLine."Quantity Invoiced";

        TempPurchLine.CalcFields("Qty. to Assign", "Qty. Assigned", "Item Charge Qty. to Handle");
        if Abs(TempPurchLine."Item Charge Qty. to Handle" + TempPurchLine."Qty. Assigned") >
           Abs(TempPurchLine."Qty. to Invoice" + TempPurchLine."Quantity Invoiced")
        then begin
            AdjustQtyToAssignForPurchLine(TempPurchLine);

            TempPurchLine.CalcFields("Qty. to Assign", "Qty. Assigned", "Item Charge Qty. to Handle");
            if Abs(TempPurchLine."Item Charge Qty. to Handle" + TempPurchLine."Qty. Assigned") >
               Abs(TempPurchLine."Qty. to Invoice" + TempPurchLine."Quantity Invoiced")
            then
                Error(CannotAssignMoreErr,
                  TempPurchLine."Qty. to Invoice" + TempPurchLine."Quantity Invoiced" - TempPurchLine."Qty. Assigned",
                  TempPurchLine.FieldCaption("Document Type"), TempPurchLine."Document Type",
                  TempPurchLine.FieldCaption("Document No."), TempPurchLine."Document No.",
                  TempPurchLine.FieldCaption("Line No."), TempPurchLine."Line No.");

            CopyItemChargeForPurchLine(TempItemChargeAssgntPurch, TempPurchLine);
        end;
        if TempPurchLine.Quantity = TempPurchLine."Qty. to Invoice" + TempPurchLine."Quantity Invoiced" then begin
            if TempPurchLine."Item Charge Qty. to Handle" <> 0 then
                if TempPurchLine.Quantity = TempPurchLine."Quantity Invoiced" then begin
                    TempItemChargeAssgntPurch.SetRange("Document Line No.", TempPurchLine."Line No.");
                    TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", TempPurchLine."Document Type");
                    if TempItemChargeAssgntPurch.FindSet() then
                        repeat
                            PurchLine.Get(
                              TempItemChargeAssgntPurch."Applies-to Doc. Type",
                              TempItemChargeAssgntPurch."Applies-to Doc. No.",
                              TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            if PurchLine.Quantity = PurchLine."Quantity Invoiced" then
                                Error(CannotAssignInvoicedErr, PurchLine.TableCaption(),
                                  PurchLine.FieldCaption("Document Type"), PurchLine."Document Type",
                                  PurchLine.FieldCaption("Document No."), PurchLine."Document No.",
                                  PurchLine.FieldCaption("Line No."), PurchLine."Line No.");
                        until TempItemChargeAssgntPurch.Next() = 0;
                end;
            if TempPurchLine.Quantity <> TempPurchLine."Item Charge Qty. to Handle" + TempPurchLine."Qty. Assigned" then
                AssignError := true;
        end;

        if (TempPurchLine."Item Charge Qty. to Handle" + TempPurchLine."Qty. Assigned") < (TempPurchLine."Qty. to Invoice" + TempPurchLine."Quantity Invoiced") then
            Error(MustAssignItemChargeErr, TempPurchLine."No.");

        // check if all ILEs exist
        QtyNeeded := TempPurchLine."Item Charge Qty. to Handle";
        TempItemChargeAssgntPurch.SetRange("Document Line No.", TempPurchLine."Line No.");
        if TempItemChargeAssgntPurch.FindSet() then
            repeat
                if (TempItemChargeAssgntPurch."Applies-to Doc. Type" <> TempPurchLine."Document Type") or
                   (TempItemChargeAssgntPurch."Applies-to Doc. No." <> TempPurchLine."Document No.")
                then
                    QtyNeeded := QtyNeeded - TempItemChargeAssgntPurch."Qty. to Handle"
                else begin
                    PurchLine.Get(
                      TempItemChargeAssgntPurch."Applies-to Doc. Type",
                      TempItemChargeAssgntPurch."Applies-to Doc. No.",
                      TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                    if ItemLedgerEntryExist(PurchLine, PurchHeader.Receive or PurchHeader.Ship) then
                        QtyNeeded := QtyNeeded - TempItemChargeAssgntPurch."Qty. to Handle";
                end;
            until TempItemChargeAssgntPurch.Next() = 0;

        if QtyNeeded <> 0 then
            Error(CannotInvoiceItemChargeErr, TempPurchLine."No.");
    end;

    local procedure CopyItemChargeForPurchLine(var TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; PurchaseLine: Record "Purchase Line")
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        TempItemChargeAssignmentPurch.Reset();
        TempItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        TempItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        if not TempItemChargeAssignmentPurch.IsEmpty() then
            TempItemChargeAssignmentPurch.DeleteAll();

        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssgntPurch.SetFilter("Qty. to Assign", '<>0');
        if ItemChargeAssgntPurch.FindSet() then
            repeat
                TempItemChargeAssignmentPurch.Init();
                TempItemChargeAssignmentPurch := ItemChargeAssgntPurch;
                TempItemChargeAssignmentPurch.Insert();
            until ItemChargeAssgntPurch.Next() = 0;
    end;

    local procedure AdjustQtyToAssignForPurchLine(var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        TempPurchaseLine.CalcFields("Qty. to Assign");

        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", TempPurchaseLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", TempPurchaseLine."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", TempPurchaseLine."Line No.");
        ItemChargeAssgntPurch.SetFilter("Qty. to Assign", '<>0');
        if ItemChargeAssgntPurch.FindSet() then
            repeat
                ItemChargeAssgntPurch.Validate("Qty. to Assign",
                  TempPurchaseLine."Qty. to Invoice" * Round(ItemChargeAssgntPurch."Qty. to Assign" / TempPurchaseLine."Qty. to Assign",
                    UOMMgt.QtyRndPrecision()));
                ItemChargeAssgntPurch.Modify();
            until ItemChargeAssgntPurch.Next() = 0;

        TempPurchaseLine.CalcFields("Qty. to Assign");
        if TempPurchaseLine."Qty. to Assign" < TempPurchaseLine."Qty. to Invoice" then begin
            ItemChargeAssgntPurch.Validate("Qty. to Assign",
              ItemChargeAssgntPurch."Qty. to Assign" + Abs(TempPurchaseLine."Qty. to Invoice" - TempPurchaseLine."Qty. to Assign"));
            ItemChargeAssgntPurch.Modify();
        end;

        if TempPurchaseLine."Qty. to Assign" > TempPurchaseLine."Qty. to Invoice" then begin
            ItemChargeAssgntPurch.Validate("Qty. to Assign",
              ItemChargeAssgntPurch."Qty. to Assign" - Abs(TempPurchaseLine."Qty. to Invoice" - TempPurchaseLine."Qty. to Assign"));
            ItemChargeAssgntPurch.Modify();
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
        if (ItemChargePurchLine."Document Type" <> TempItemChargeAssgntPurch."Document Type") or
            (ItemChargePurchLine."Document No." <> TempItemChargeAssgntPurch."Document No.") or
            (ItemChargePurchLine."Line No." <> TempItemChargeAssgntPurch."Document Line No.")
        then begin
            ItemChargePurchLine.Get(TempItemChargeAssgntPurch."Document Type", TempItemChargeAssgntPurch."Document No.", TempItemChargeAssgntPurch."Document Line No.");
            OnGetItemChargeLineOnAfterGet(ItemChargePurchLine, PurchHeader);
            if not PurchHeader.Receive then
                ItemChargePurchLine."Qty. to Receive" := 0;
            if not PurchHeader.Ship then
                ItemChargePurchLine."Return Qty. to Ship" := 0;

            if ItemChargePurchLine."Receipt No." = '' then
                QtyReceived := ItemChargePurchLine."Quantity Received"
            else
                QtyReceived := TempItemChargeAssgntPurch."Qty. to Handle";
            if ItemChargePurchLine."Return Shipment No." = '' then
                QtyReturnShipped := ItemChargePurchLine."Return Qty. Shipped"
            else
                QtyReturnShipped := TempItemChargeAssgntPurch."Qty. to Handle";

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
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetPurchSetup()
    begin
        if not PurchSetupRead then
            PurchSetup.Get();

        PurchSetupRead := true;

        OnAfterGetPurchSetup(PurchSetup);
    end;

    local procedure GetInvoicePostingSetup()
    var
        IsHandled: Boolean;
    begin
        if IsInterfaceInitialized then
            exit;

#if not CLEAN23
        GetPurchSetup();
        if UseLegacyInvoicePosting() then
            exit;
#endif
        IsHandled := false;
        OnBeforeGetInvoicePostingSetup(InvoicePostingInterface, IsHandled);
        if not IsHandled then
            InvoicePostingInterface := Enum::"Purchase Invoice Posting"::"Invoice Posting (v.19)";

        InvoicePostingInterface.Check(Database::"Purchase Header");
        IsInterfaceInitialized := true;

        InvoicePostingInterface.SetHideProgressWindow(HideProgressWindow);
        InvoicePostingInterface.SetPreviewMode(PreviewMode);
        InvoicePostingInterface.SetSuppressCommit(SuppressCommit);
    end;

    local procedure GetInvoicePostingParameters()
    begin
        Clear(InvoicePostingParameters);
        InvoicePostingParameters."Document Type" := GenJnlLineDocType;
        InvoicePostingParameters."Document No." := GenJnlLineDocNo;
        InvoicePostingParameters."External Document No." := GenJnlLineExtDocNo;
        InvoicePostingParameters."Source Code" := SrcCode;
        InvoicePostingParameters."Auto Document No." := '';
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

        if TempItemPurchLine."Prod. Order No." <> '' then
            exit;

        TempItemPurchLine.SetRange(Type, TempItemPurchLine.Type::Item);
        TempItemPurchLine.SetRange("Drop Shipment", false);
        OnCheckWarehouseOnAfterSetFilters(TempItemPurchLine);
        if TempItemPurchLine.FindSet() then
            repeat
                if TempItemPurchLine.IsInventoriableItem() then begin
                    GetLocation(TempItemPurchLine."Location Code");
                    case TempItemPurchLine."Document Type" of
                        TempItemPurchLine."Document Type"::Order:
                            if ((Location."Require Receive" or Location."Require Put-away") and (TempItemPurchLine.Quantity >= 0)) or
                               ((Location."Require Shipment" or Location."Require Pick") and (TempItemPurchLine.Quantity < 0))
                            then begin
                                if Location."Directed Put-away and Pick" then
                                    ShowError := true
                                else
                                    if WhseValidateSourceLine.WhseLinesExist(
                                         DATABASE::"Purchase Line", TempItemPurchLine."Document Type".AsInteger(), TempItemPurchLine."Document No.", TempItemPurchLine."Line No.", 0, TempItemPurchLine.Quantity)
                                    then
                                        ShowError := true;
                            end;
                        TempItemPurchLine."Document Type"::"Return Order":
                            if ((Location."Require Receive" or Location."Require Put-away") and (TempItemPurchLine.Quantity < 0)) or
                               ((Location."Require Shipment" or Location."Require Pick") and (TempItemPurchLine.Quantity >= 0))
                            then begin
                                if Location."Directed Put-away and Pick" then
                                    ShowError := true
                                else
                                    if WhseValidateSourceLine.WhseLinesExist(
                                         DATABASE::"Purchase Line", TempItemPurchLine."Document Type".AsInteger(), TempItemPurchLine."Document No.", TempItemPurchLine."Line No.", 0, TempItemPurchLine.Quantity)
                                    then
                                        ShowError := true;
                            end;
                        TempItemPurchLine."Document Type"::Invoice, TempItemPurchLine."Document Type"::"Credit Memo":
                            if Location."Directed Put-away and Pick" then
                                Location.TestField("Adjustment Bin Code");
                    end;
                    if ShowError then
                        Error(
                          WarehouseRequiredErr,
                          TempItemPurchLine.FieldCaption("Document Type"), TempItemPurchLine."Document Type",
                          TempItemPurchLine.FieldCaption("Document No."), TempItemPurchLine."Document No.",
                          TempItemPurchLine.FieldCaption("Line No."), TempItemPurchLine."Line No.");
                end;
            until TempItemPurchLine.Next() = 0;
    end;

    local procedure CreateWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    var
        WhseMgt: Codeunit "Whse. Management";
        WMSMgt: Codeunit "WMS Management";
    begin
        WMSMgt.CheckAdjmtBin(Location, ItemJnlLine.Quantity, true);
        WMSMgt.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, false);
        TempWhseJnlLine.CheckBin(true);
        TempWhseJnlLine."Source Type" := DATABASE::"Purchase Line";
        TempWhseJnlLine."Source Subtype" := PurchLine."Document Type".AsInteger();
        TempWhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
        TempWhseJnlLine."Source No." := PurchLine."Document No.";
        TempWhseJnlLine."Source Line No." := PurchLine."Line No.";
        TempWhseJnlLine."Source Code" := SrcCode;
        case PurchLine."Document Type" of
            PurchLine."Document Type"::Order:
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted Rcpt.";
            PurchLine."Document Type"::Invoice:
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted P. Inv.";
            PurchLine."Document Type"::"Credit Memo":
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted P. Cr. Memo";
            PurchLine."Document Type"::"Return Order":
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
        end;
        TempWhseJnlLine."Reference No." := ItemJnlLine."Document No.";

        OnAfterCreateWhseJnlLine(PurchLine, TempWhseJnlLine);
    end;

    procedure WhseHandlingRequiredExternal(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit(WhseHandlingRequired(PurchaseLine));
    end;

    local procedure WhseHandlingRequired(PurchLine: Record "Purchase Line") Required: Boolean
    var
        WhseSetup: Record "Warehouse Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseHandlingRequired(PurchLine, Required, IsHandled);
        if IsHandled then
            exit(Required);

        if PurchLine.IsInventoriableItem() and (not PurchLine."Drop Shipment") then begin
            if PurchLine."Location Code" = '' then begin
                WhseSetup.Get();
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

    local procedure InsertRcptEntryRelation(var PurchRcptLine: Record "Purch. Rcpt. Line") Result: Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertRcptEntryRelation(xPurchLine, PurchRcptLine, TempHandlingSpecification, TempTrackingSpecificationInv, ItemLedgShptEntryNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempHandlingSpecification.CopySpecification(TempTrackingSpecificationInv);
        TempHandlingSpecification.Reset();
        if TempHandlingSpecification.FindSet() then begin
            repeat
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ItemEntryRelation.TransferFieldsPurchRcptLine(PurchRcptLine);
                ItemEntryRelation.Insert();
            until TempHandlingSpecification.Next() = 0;
            TempHandlingSpecification.DeleteAll();
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    local procedure InsertReturnEntryRelation(var ReturnShptLine: Record "Return Shipment Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
        Result: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReturnEntryRelation(ReturnShptLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempHandlingSpecification.CopySpecification(TempTrackingSpecificationInv);
        TempHandlingSpecification.Reset();
        if TempHandlingSpecification.FindSet() then begin
            repeat
                ItemEntryRelation.Init();
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ItemEntryRelation.TransferFieldsReturnShptLine(ReturnShptLine);
                ItemEntryRelation.Insert();
            until TempHandlingSpecification.Next() = 0;
            TempHandlingSpecification.DeleteAll();
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    local procedure CheckTrackingSpecification(PurchHeader: Record "Purchase Header"; var TempItemPurchLine: Record "Purchase Line" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemJnlLine: Record "Item Journal Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        PurchLineQtyToHandle: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        CheckPurchLine: Boolean;
        IsHandled: Boolean;
    begin
        // if a PurchaseLine is posted with ItemTracking then tracked quantity must be equal to posted quantity
        if not (PurchHeader."Document Type" in
                [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"])
        then
            exit;

        OnBeforeCheckTrackingSpecification(PurchHeader, TempItemPurchLine);

        TrackingQtyToHandle := 0;

        TempItemPurchLine.SetRange(Type, TempItemPurchLine.Type::Item);
        if PurchHeader.Receive then begin
            TempItemPurchLine.SetFilter("Quantity Received", '<>%1', 0);
            ErrorFieldCaption := TempItemPurchLine.FieldCaption("Qty. to Receive");
        end else begin
            TempItemPurchLine.SetFilter("Return Qty. Shipped", '<>%1', 0);
            ErrorFieldCaption := TempItemPurchLine.FieldCaption("Return Qty. to Ship");
        end;

        if TempItemPurchLine.FindSet() then begin
            ReservationEntry."Source Type" := DATABASE::"Purchase Line";
            ReservationEntry."Source Subtype" := PurchHeader."Document Type".AsInteger();
            SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
            repeat
                // Only Item where no SerialNo or LotNo is required
                Item.Get(TempItemPurchLine."No.");
                if Item."Item Tracking Code" <> '' then begin
                    Inbound := (TempItemPurchLine.Quantity * SignFactor) > 0;
                    ItemTrackingCode.Code := Item."Item Tracking Code";

                    IsHandled := false;
                    OnCheckTrackingSpecificationOnBeforeGetItemTrackingSetup(TempItemPurchLine, ItemTrackingSetup, IsHandled);
                    if not IsHandled then
                        ItemTrackingManagement.GetItemTrackingSetup(
                           ItemTrackingCode, ItemJnlLine."Entry Type"::Purchase, Inbound, ItemTrackingSetup);
                    CheckPurchLine := not ItemTrackingSetup.TrackingRequired();
                    if CheckPurchLine then
                        CheckPurchLine := CheckTrackingExists(TempItemPurchLine);
                end else
                    CheckPurchLine := false;

                TrackingQtyToHandle := 0;

                if CheckPurchLine then begin
                    TrackingQtyToHandle := GetTrackingQuantities(TempItemPurchLine) * SignFactor;
                    if PurchHeader.Receive then
                        PurchLineQtyToHandle := TempItemPurchLine."Qty. to Receive (Base)"
                    else
                        PurchLineQtyToHandle := TempItemPurchLine."Return Qty. to Ship (Base)";
                    if TrackingQtyToHandle <> PurchLineQtyToHandle then
                        Error(ItemTrackQuantityMismatchErr, ErrorFieldCaption, TempItemPurchLine."No.");
                end;
            until TempItemPurchLine.Next() = 0;
        end;
        if PurchHeader.Receive then
            TempItemPurchLine.SetRange("Quantity Received")
        else
            TempItemPurchLine.SetRange("Return Qty. Shipped");
        OnAfterCheckTrackingSpecification(PurchHeader, TempItemPurchLine)
    end;

    local procedure CheckTrackingExists(PurchLine: Record "Purchase Line"): Boolean
    begin
        exit(
          ItemTrackingMgt.ItemTrackingExistsOnDocumentLine(
            DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No."));
    end;

    procedure GetTrackingQuantities(PurchLine: Record "Purchase Line"): Decimal
    begin
        exit(
          ItemTrackingMgt.CalcQtyToHandleForTrackedQtyOnDocumentLine(
            DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No."));
    end;

    local procedure SaveInvoiceSpecification(var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
        TempInvoicingSpecification.Reset();
        if TempInvoicingSpecification.FindSet() then begin
            repeat
                TempInvoicingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Quantity actual Handled (Base)";
                TempInvoicingSpecification."Quantity actual Handled (Base)" := 0;
                OnSaveInvoiceSpecificationOnBeforeAssignTempInvoicingSpecification(TempInvoicingSpecification);
                TempTrackingSpecification := TempInvoicingSpecification;
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::MODIFY;
                if not TempTrackingSpecification.Insert() then begin
                    TempTrackingSpecification.Get(TempInvoicingSpecification."Entry No.");
                    TempTrackingSpecification."Qty. to Invoice (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                    TempTrackingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                    TempTrackingSpecification."Qty. to Invoice" += TempInvoicingSpecification."Qty. to Invoice";
                    OnSaveInvoiceSpecificationOnBeforeTempTrackingSpecificationModify(TempTrackingSpecification, TempInvoicingSpecification);
                    TempTrackingSpecification.Modify();
                end;
                OnSaveInvoiceSpecificationOnAfterUpdateTempTrackingSpecification(TempTrackingSpecification, TempInvoicingSpecification);
            until TempInvoicingSpecification.Next() = 0;
            TempInvoicingSpecification.DeleteAll();
        end;
    end;

    local procedure InsertTrackingSpecification(PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTrackingSpecification(PurchHeader, TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        TempTrackingSpecification.Reset();
        if not TempTrackingSpecification.IsEmpty() then begin
            TempTrackingSpecification.InsertSpecification();
            PurchLineReserve.UpdateItemTrackingAfterPosting(PurchHeader);
        end;
    end;

    local procedure CalcBaseQty(ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; QtyRoundingPrecision: Decimal): Decimal
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Item.Get(ItemNo);
        exit(UOMMgt.CalcBaseQty(ItemNo, '', UOMCode, Qty, UOMMgt.GetQtyPerUnitOfMeasure(Item, UOMCode), QtyRoundingPrecision));
    end;

    local procedure InsertValueEntryRelation()
    var
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        TempValueEntryRelation.Reset();
        if TempValueEntryRelation.FindSet() then begin
            repeat
                ValueEntryRelation := TempValueEntryRelation;
                ValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0;
            TempValueEntryRelation.DeleteAll();
        end;
    end;

    procedure PostItemCharge(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal; IndirectCostPct: Decimal)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        PurchLineToPost: Record "Purchase Line";
    begin
        PurchLineToPost := PurchLine;
        PurchLineToPost."No." := TempItemChargeAssgntPurch."Item No.";
        PurchLineToPost."Line No." := TempItemChargeAssgntPurch."Document Line No.";
        PurchLineToPost."Appl.-to Item Entry" := ItemEntryNo;
        PurchLineToPost."Indirect Cost %" := IndirectCostPct;

        PurchLineToPost.Amount := AmountToAssign;

        if TempItemChargeAssgntPurch."Document Type" in [TempItemChargeAssgntPurch."Document Type"::"Return Order", TempItemChargeAssgntPurch."Document Type"::"Credit Memo"] then
            PurchLineToPost.Amount := -PurchLineToPost.Amount;

        if PurchLineToPost."Currency Code" <> '' then
            PurchLineToPost."Unit Cost" := Round(
                PurchLineToPost.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision")
        else
            PurchLineToPost."Unit Cost" := Round(
                PurchLineToPost.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

        TotalChargeAmt := TotalChargeAmt + PurchLineToPost.Amount;
        OnPostItemChargeOnAfterCalcTotalChargeAmt(PurchLineToPost, QtyToAssign, PurchLine, xPurchLine);

        if PurchHeader."Currency Code" <> '' then
            PurchLineToPost.Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                PurchHeader.GetUseDate(), PurchHeader."Currency Code", TotalChargeAmt, PurchHeader."Currency Factor");

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
        NonDeductibleVAT.Update(PurchLineToPost, QtyToAssign, QuantityBase, GLSetup."Amount Rounding Precision");
        PurchLine.Quantity := PurchLine.Quantity - QtyToAssign;

        OnPostItemChargeOnBeforePostItemJnlLine(PurchLineToPost, PurchLine, QtyToAssign, TempItemChargeAssgntPurch, PurchInvHeader);

        PostItemJnlLine(
          PurchHeader, PurchLineToPost, 0, 0, QuantityBase, QuantityBase,
          PurchLineToPost."Appl.-to Item Entry", TempItemChargeAssgntPurch."Item Charge No.", DummyTrackingSpecification);

        OnPostItemChargeOnAfterPostItemJnlLine(PurchHeader, PurchLineToPost, TempItemChargeAssgntPurch);
    end;

    local procedure SaveTempWhseSplitSpec(PurchLine3: Record "Purchase Line")
    begin
        TempWhseSplitSpecification.Reset();
        TempWhseSplitSpecification.DeleteAll();
        if TempHandlingSpecification.FindSet() then
            repeat
                TempWhseSplitSpecification := TempHandlingSpecification;
                TempWhseSplitSpecification."Source Type" := DATABASE::"Purchase Line";
                TempWhseSplitSpecification."Source Subtype" := PurchLine3."Document Type".AsInteger();
                TempWhseSplitSpecification."Source ID" := PurchLine3."Document No.";
                TempWhseSplitSpecification."Source Ref. No." := PurchLine3."Line No.";
                TempWhseSplitSpecification.Insert();
            until TempHandlingSpecification.Next() = 0;

        OnAfterSaveTempWhseSplitSpec(PurchLine3, TempWhseSplitSpecification);
    end;

    local procedure TransferReservToItemJnlLine(var SalesOrderLine: Record "Sales Line"; var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line"; QtyToBeShippedBase: Decimal; ApplySpecificItemTracking: Boolean)
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        RemainingQuantity: Decimal;
        CheckApplFromItemEntry: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferReservToItemJnlLine(SalesOrderLine, ItemJnlLine, PurchLine, QtyToBeShippedBase, ApplySpecificItemTracking, IsHandled);
        if IsHandled then
            exit;

        // Handle Item Tracking and reservations, also on drop shipment
        if QtyToBeShippedBase = 0 then
            exit;

        if not ApplySpecificItemTracking then
            SalesLineReserve.TransferSalesLineToItemJnlLine(
              SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
        else begin
            SalesLineReserve.SetApplySpecificItemTracking(true);
            TempTrackingSpecification.Reset();
            TempTrackingSpecification.SetSourceFilter(
              DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.", false);
            TempTrackingSpecification.SetSourceFilter('', 0);
            if TempTrackingSpecification.IsEmpty() then
                SalesLineReserve.TransferSalesLineToItemJnlLine(
                  SalesOrderLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
            else begin
                SalesLineReserve.SetOverruleItemTracking(true);
                TempTrackingSpecification.FindSet();
                if TempTrackingSpecification."Quantity (Base)" / QtyToBeShippedBase < 0 then
                    Error(ItemTrackingWrongSignErr);
                repeat
                    ItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification);
                    ItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Item Ledger Entry No.";
                    RemainingQuantity :=
                      SalesLineReserve.TransferSalesLineToItemJnlLine(
                        SalesOrderLine, ItemJnlLine, TempTrackingSpecification."Quantity (Base)", CheckApplFromItemEntry, false);
                    if RemainingQuantity <> 0 then
                        Error(ItemTrackingMismatchErr);
                until TempTrackingSpecification.Next() = 0;
                ItemJnlLine.ClearTracking();
                ItemJnlLine."Applies-to Entry" := 0;
            end;
        end;
    end;

    procedure SetWhseRcptHeader(var WhseRcptHeader2: Record "Warehouse Receipt Header")
    begin
        WhseRcptHeader := WhseRcptHeader2;
        TempWhseRcptHeader := WhseRcptHeader;
        TempWhseRcptHeader.Insert();
    end;

    procedure SetWhseShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptHeader := WhseShptHeader2;
        TempWhseShptHeader := WhseShptHeader;
        TempWhseShptHeader.Insert();
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
        ShouldCalcAmounts: Boolean;
        ShouldTestGetReceiptPPmtAmtToDeduct: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePrepmtLines(PurchHeader, TempPrepmtPurchLine, CompleteFunctionality, IsHandled, TempPurchLineGlobal);
        if IsHandled then
            exit;

        GetGLSetup();
        FillTempLines(PurchHeader, TempPurchLineGlobal);
        ResetTempLines(TempPurchLine);
        if not TempPurchLine.FindLast() then
            exit;
        NextLineNo := TempPurchLine."Line No." + 10000;
        TempPurchLine.SetFilter(Quantity, '>0');
        TempPurchLine.SetFilter("Qty. to Invoice", '>0');
        OnCreatePrepmtLinesOnAfterTempPurchLineSetFilters(TempPurchLine);
        if TempPurchLine.FindSet() then begin
            ShouldTestGetReceiptPPmtAmtToDeduct := CompleteFunctionality and (TempPurchLine."Document Type" = TempPurchLine."Document Type"::Invoice);
            OnCreatePrepaymentLinesOnBeforeShouldTestGetReceiptPPmtAmtToDeduct(PurchHeader, CompleteFunctionality, ShouldTestGetReceiptPPmtAmtToDeduct);
            if ShouldTestGetReceiptPPmtAmtToDeduct then
                TestGetRcptPPmtAmtToDeduct();
            repeat
                if CompleteFunctionality then begin
                    ShouldCalcAmounts := PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice;
                    OnCreatePrepmtLinesOnAfterShouldCalcAmounts(PurchHeader, ShouldCalcAmounts, TempPurchLine);
                    if ShouldCalcAmounts then begin
                        if not PurchHeader.Receive and (TempPurchLine."Qty. to Invoice" = TempPurchLine.Quantity - TempPurchLine."Quantity Invoiced") then
                            if TempPurchLine."Qty. Rcd. Not Invoiced" < TempPurchLine."Qty. to Invoice" then
                                TempPurchLine.Validate("Qty. to Invoice", TempPurchLine."Qty. Rcd. Not Invoiced");
                        Fraction := (TempPurchLine."Qty. to Invoice" + TempPurchLine."Quantity Invoiced") / TempPurchLine.Quantity;

                        CheckPrepmtAmtToDeduct(PurchHeader, TempPurchLine, Fraction);
                    end;
                end;
                if TempPurchLine."Prepmt Amt to Deduct" <> 0 then begin
                    if (TempPurchLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
                       (TempPurchLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                    then
                        GetGeneralPostingSetup(GenPostingSetup, TempPurchLine);

                    IsHandled := false;
                    OnCreatePrepaymentLinesOnBeforeGetPurchPrepmtAccount(GLAcc, TempPurchLine, PurchHeader, GenPostingSetup, CompleteFunctionality, IsHandled);
                    if not IsHandled then
                        GLAcc.Get(GenPostingSetup.GetPurchPrepmtAccount());
                    OnCreatePrepaymentLinesOnAfterGetPurchPrepmtAccount(GLAcc, TempPurchLine, PurchHeader, CompleteFunctionality);
                    TempLineFound := false;
                    if PurchHeader."Compress Prepayment" then begin
                        TempPrepmtPurchLine.SetRange("No.", GLAcc."No.");
                        TempPrepmtPurchLine.SetRange("Job No.", TempPurchLine."Job No.");
                        TempPrepmtPurchLine.SetRange("Dimension Set ID", TempPurchLine."Dimension Set ID");
                        OnCreatePrepmtLinesOnAfterTempPrepmtPurchLineSetFilters(TempPrepmtPurchLine, TempPurchLine);
                        TempLineFound := TempPrepmtPurchLine.FindFirst();
                    end;
                    if TempLineFound then begin
                        PrepmtAmtToDeduct :=
                          TempPrepmtPurchLine."Prepmt Amt to Deduct" +
                          InsertedPrepmtVATBaseToDeduct(
                            PurchHeader, TempPurchLine, TempPrepmtPurchLine."Line No.", TempPrepmtPurchLine."Direct Unit Cost");
                        VATDifference := TempPrepmtPurchLine."VAT Difference";
                        TempPrepmtPurchLine.Validate(
                          "Direct Unit Cost", TempPrepmtPurchLine."Direct Unit Cost" + TempPurchLine."Prepmt Amt to Deduct");
                        TempPrepmtPurchLine.Validate("VAT Difference", VATDifference - TempPurchLine."Prepmt VAT Diff. to Deduct");
                        TempPrepmtPurchLine."Prepmt Amt to Deduct" := PrepmtAmtToDeduct;
                        if TempPurchLine."Prepayment %" < TempPrepmtPurchLine."Prepayment %" then
                            TempPrepmtPurchLine."Prepayment %" := TempPurchLine."Prepayment %";
                        if GLSetup.CheckFullGSTonPrepayment(TempPurchLine."VAT Bus. Posting Group", TempPurchLine."VAT Prod. Posting Group") then
                            TempPrepmtPurchLine."VAT Base Amount" := TempPrepmtPurchLine."VAT Base Amount" +
                              Round(
                                TempPrepmtPurchLine.Quantity * (TempPurchLine."Prepmt. VAT Base Amt." * TempPurchLine."Qty. to Invoice" / TempPurchLine.Quantity),
                                Currency."Amount Rounding Precision");
                        OnBeforeTempPrepmtPurchLineModify(TempPrepmtPurchLine, TempPurchLine, PurchHeader, CompleteFunctionality);
                        TempPrepmtPurchLine.Modify();
                        FillPrepmtLineNoBuf(TempPurchLine."Line No.", TempPrepmtPurchLine."Line No.");
                    end else begin
                        TempPrepmtPurchLine.Init();
                        TempPrepmtPurchLine."Document Type" := PurchHeader."Document Type";
                        TempPrepmtPurchLine."Document No." := PurchHeader."No.";
                        TempPrepmtPurchLine."Line No." := 0;
                        TempPrepmtPurchLine."System-Created Entry" := true;
                        OnCreatePrepmtLinesOnAfterInitTempPrepmtPurchLineFromPurchHeader(TempPrepmtPurchLine);
                        if CompleteFunctionality then
                            TempPrepmtPurchLine.Validate(Type, TempPrepmtPurchLine.Type::"G/L Account")
                        else
                            TempPrepmtPurchLine.Type := TempPrepmtPurchLine.Type::"G/L Account";
                        TempPrepmtPurchLine.Validate("No.", GLAcc."No.");
                        TempPrepmtPurchLine.Validate(Quantity, -1);
                        TempPrepmtPurchLine."Qty. to Receive" := TempPrepmtPurchLine.Quantity;
                        TempPrepmtPurchLine."Qty. to Invoice" := TempPrepmtPurchLine.Quantity;
                        OnCreatePrepaymentLinesOnBeforeInsertedPrepmtVATBaseToDeduct(TempPrepmtPurchLine, PurchHeader, TempPurchLine);
                        PrepmtAmtToDeduct := InsertedPrepmtVATBaseToDeduct(PurchHeader, TempPurchLine, NextLineNo, 0);
                        TempPrepmtPurchLine.Validate("Direct Unit Cost", TempPurchLine."Prepmt Amt to Deduct");
                        TempPrepmtPurchLine.Validate("VAT Difference", -TempPurchLine."Prepmt VAT Diff. to Deduct");
                        TempPrepmtPurchLine."Prepmt Amt to Deduct" := PrepmtAmtToDeduct;
                        TempPrepmtPurchLine."Prepayment %" := TempPurchLine."Prepayment %";
                        TempPrepmtPurchLine."Prepayment Line" := true;
                        TempPrepmtPurchLine."Shortcut Dimension 1 Code" := TempPurchLine."Shortcut Dimension 1 Code";
                        TempPrepmtPurchLine."Shortcut Dimension 2 Code" := TempPurchLine."Shortcut Dimension 2 Code";
                        TempPrepmtPurchLine."Dimension Set ID" := TempPurchLine."Dimension Set ID";
                        TempPrepmtPurchLine."Job No." := TempPurchLine."Job No.";
                        TempPrepmtPurchLine."Job Task No." := TempPurchLine."Job Task No.";
                        TempPrepmtPurchLine."Job Line Type" := TempPurchLine."Job Line Type";
                        TempPrepmtPurchLine."Line No." := NextLineNo;
                        NextLineNo := NextLineNo + 10000;
                        FillPrepmtLineNoBuf(TempPurchLine."Line No.", TempPrepmtPurchLine."Line No.");
                        if GLSetup.CheckFullGSTonPrepayment(TempPurchLine."VAT Bus. Posting Group", TempPurchLine."VAT Prod. Posting Group") then begin
                            TempPrepmtPurchLine."VAT Base Amount" :=
                              Round(
                                TempPrepmtPurchLine.Quantity * TempPurchLine."Prepmt. VAT Base Amt." * TempPurchLine."Qty. to Invoice" / TempPurchLine.Quantity,
                                Currency."Amount Rounding Precision");
                            PurLine.Reset();
                            InvDiscAmount := 0;
                            PurLine.SetFilter("Document No.", TempPurchLine."Document No.");
                            if PurLine.Find('-') then
                                repeat
                                    InvDiscAmount += (PurLine."Inv. Discount Amount" * PurLine."Prepayment %" / 100);
                                until PurLine.Next() = 0;
                            InvDiscAmt := InvDiscAmount;
                        end;
                        OnBeforeTempPrepmtPurchLineInsert(TempPrepmtPurchLine, TempPurchLine, PurchHeader, CompleteFunctionality);
                        TempPrepmtPurchLine.Insert();

                        TransferExtText.PrepmtGetAnyExtText(
                          TempPrepmtPurchLine."No.", DATABASE::"Purch. Inv. Line",
                          PurchHeader."Document Date", PurchHeader."Language Code", TempExtTextLine);
                        if TempExtTextLine.Find('-') then
                            repeat
                                TempPrepmtPurchLine.Init();
                                TempPrepmtPurchLine.Description := TempExtTextLine.Text;
                                TempPrepmtPurchLine."System-Created Entry" := true;
                                TempPrepmtPurchLine."Prepayment Line" := true;
                                TempPrepmtPurchLine."Line No." := NextLineNo;
                                NextLineNo := NextLineNo + 10000;
                                TempPrepmtPurchLine.Insert();
                            until TempExtTextLine.Next() = 0;
                    end;
                end;
            until TempPurchLine.Next() = 0
        end;
        DividePrepmtAmountLCY(TempPrepmtPurchLine, PurchHeader);
        if TempPrepmtPurchLine.FindSet() then
            repeat
                TempPurchLineGlobal := TempPrepmtPurchLine;
                TempPurchLineGlobal.Insert();
            until TempPrepmtPurchLine.Next() = 0;
    end;

    local procedure CheckPrepmtAmtToDeduct(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; Fraction: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPrepmtAmtToDeduct(PurchaseHeader, TempPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if TempPurchaseLine."Prepayment %" <> 100 then
            case true of
                (TempPurchaseLine."Prepmt Amt to Deduct" <> 0) and
              (Round(Fraction * TempPurchaseLine."Line Amount", Currency."Amount Rounding Precision") < TempPurchaseLine."Prepmt Amt to Deduct"):
                    TempPurchaseLine.FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(
                        CannotBeGreaterThanErr,
                        Round(Fraction * TempPurchaseLine."Line Amount", Currency."Amount Rounding Precision")));
                (TempPurchaseLine."Prepmt. Amt. Inv." <> 0) and
              (Round((1 - Fraction) * TempPurchaseLine."Line Amount", Currency."Amount Rounding Precision") <
               Round(
                 Round(
                   Round(TempPurchaseLine."Direct Unit Cost" * (TempPurchaseLine.Quantity - TempPurchaseLine."Quantity Invoiced" - TempPurchaseLine."Qty. to Invoice"),
                     Currency."Amount Rounding Precision") *
                   (1 - TempPurchaseLine."Line Discount %" / 100), Currency."Amount Rounding Precision") *
                 TempPurchaseLine."Prepayment %" / 100, Currency."Amount Rounding Precision")):
                    TempPurchaseLine.FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(
                        CannotBeSmallerThanErr,
                        Round(
                          TempPurchaseLine."Prepmt. Amt. Inv." - TempPurchaseLine."Prepmt Amt Deducted" -
                          (1 - Fraction) * TempPurchaseLine."Line Amount", Currency."Amount Rounding Precision")));
            end;
    end;

    local procedure InsertedPrepmtVATBaseToDeduct(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PrepmtLineNo: Integer; TotalPrepmtAmtToDeduct: Decimal): Decimal
    var
        PrepmtVATBaseToDeduct: Decimal;
        GSTAmount: Decimal;
        GSTBase: Decimal;
    begin
        if PurchHeader."Prices Including VAT" then
            if GLSetup.CheckFullGSTonPrepayment(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group") then begin
                GSTBase := Round(PurchLine."Prepmt. VAT Base Amt." * PurchLine."Qty. to Invoice" / PurchLine.Quantity, Currency."Amount Rounding Precision");
                GSTAmount := Round(GSTBase * PurchLine."Prepayment VAT %" / 100, Currency."Amount Rounding Precision");
                PrepmtVATBaseToDeduct := PurchLine."Prepmt Amt to Deduct" - GSTAmount;
            end else
                PrepmtVATBaseToDeduct :=
                  Round(
                    (TotalPrepmtAmtToDeduct + PurchLine."Prepmt Amt to Deduct") / (1 + PurchLine."Prepayment VAT %" / 100),
                    Currency."Amount Rounding Precision") -
                  Round(
                    TotalPrepmtAmtToDeduct / (1 + PurchLine."Prepayment VAT %" / 100),
                    Currency."Amount Rounding Precision")
        else
            PrepmtVATBaseToDeduct := PurchLine."Prepmt Amt to Deduct";

        TempPrepmtDeductLCYPurchLine := PurchLine;
        if TempPrepmtDeductLCYPurchLine."Document Type" = TempPrepmtDeductLCYPurchLine."Document Type"::Order then
            TempPrepmtDeductLCYPurchLine."Qty. to Invoice" := GetQtyToInvoice(PurchLine, PurchHeader.Receive)
        else
            GetLineDataFromOrder(TempPrepmtDeductLCYPurchLine);
        if (TempPrepmtDeductLCYPurchLine."Prepmt Amt to Deduct" = 0) or (TempPrepmtDeductLCYPurchLine."Document Type" = TempPrepmtDeductLCYPurchLine."Document Type"::Invoice) then
            TempPrepmtDeductLCYPurchLine.CalcPrepaymentToDeduct();
        TempPrepmtDeductLCYPurchLine."Line Amount" := TempPrepmtDeductLCYPurchLine.GetLineAmountToHandleInclPrepmt(TempPrepmtDeductLCYPurchLine."Qty. to Invoice");
        TempPrepmtDeductLCYPurchLine."Attached to Line No." := PrepmtLineNo;
        TempPrepmtDeductLCYPurchLine."VAT Base Amount" := PrepmtVATBaseToDeduct;
        TempPrepmtDeductLCYPurchLine.Insert();

        OnAfterInsertedPrepmtVATBaseToDeduct(
          PurchHeader, PurchLine, PrepmtLineNo, TotalPrepmtAmtToDeduct, TempPrepmtDeductLCYPurchLine, PrepmtVATBaseToDeduct);

        exit(PrepmtVATBaseToDeduct);
    end;

    local procedure DividePrepmtAmountLCY(var PrepmtPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    var
        ActualCurrencyFactor: Decimal;
    begin
        PrepmtPurchLine.Reset();
        PrepmtPurchLine.SetFilter(Type, '<>%1', PrepmtPurchLine.Type::" ");
        if PrepmtPurchLine.FindSet() then
            repeat
                if PurchHeader."Currency Code" <> '' then
                    ActualCurrencyFactor :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          PurchHeader."Posting Date",
                          PurchHeader."Currency Code",
                          PrepmtPurchLine."Prepmt Amt to Deduct",
                          PurchHeader."Currency Factor")) /
                      PrepmtPurchLine."Prepmt Amt to Deduct"
                else
                    ActualCurrencyFactor := 1;

                UpdatePrepmtAmountInvBuf(PrepmtPurchLine."Line No.", ActualCurrencyFactor);
            until PrepmtPurchLine.Next() = 0;
        PrepmtPurchLine.Reset();
    end;

    local procedure UpdatePrepmtAmountInvBuf(PrepmtSalesLineNo: Integer; CurrencyFactor: Decimal)
    var
        PrepmtAmtRemainder: Decimal;
    begin
        TempPrepmtDeductLCYPurchLine.Reset();
        TempPrepmtDeductLCYPurchLine.SetRange("Attached to Line No.", PrepmtSalesLineNo);
        if TempPrepmtDeductLCYPurchLine.FindSet(true) then
            repeat
                TempPrepmtDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)" :=
                  CalcRoundedAmount(CurrencyFactor * TempPrepmtDeductLCYPurchLine."VAT Base Amount", PrepmtAmtRemainder);
                TempPrepmtDeductLCYPurchLine.Modify();
            until TempPrepmtDeductLCYPurchLine.Next() = 0;
    end;

    local procedure AdjustPrepmtAmountLCY(PurchHeader: Record "Purchase Header"; var PrepmtPurchLine: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
        PurchInvoiceLine: Record "Purchase Line";
        TempPurchaseLineReceiptBuffer: Record "Purchase Line" temporary;
        DeductionFactor: Decimal;
        PrepmtVATPart: Decimal;
        PrepmtVATAmtRemainder: Decimal;
        TotalRoundingAmount: array[2] of Decimal;
        TotalPrepmtAmount: array[2] of Decimal;
        FinalInvoice: Boolean;
        PricesInclVATRoundingAmount: array[2] of Decimal;
        CurrentLineFinalInvoice: Boolean;
    begin
        if PrepmtPurchLine."Prepayment Line" then begin
            PrepmtVATPart :=
              (PrepmtPurchLine."Amount Including VAT" - PrepmtPurchLine.Amount) / PrepmtPurchLine."Direct Unit Cost";

            TempPrepmtDeductLCYPurchLine.Reset();
            TempPrepmtDeductLCYPurchLine.SetRange("Attached to Line No.", PrepmtPurchLine."Line No.");
            if TempPrepmtDeductLCYPurchLine.FindSet(true) then begin
                FinalInvoice := true;
                repeat
                    PurchLine := TempPrepmtDeductLCYPurchLine;
                    PurchLine.Find();

                    if TempPrepmtDeductLCYPurchLine."Document Type" = TempPrepmtDeductLCYPurchLine."Document Type"::Invoice then begin
                        PurchInvoiceLine := PurchLine;
                        GetPurchOrderLine(PurchLine, PurchInvoiceLine);
                        PurchLine."Qty. to Invoice" := PurchInvoiceLine."Qty. to Invoice";

                        TempPurchaseLineReceiptBuffer := PurchLine;
                        if TempPurchaseLineReceiptBuffer.Find() then begin
                            TempPurchaseLineReceiptBuffer."Qty. to Invoice" += TempPrepmtDeductLCYPurchLine."Qty. to Invoice";
                            TempPurchaseLineReceiptBuffer.Modify();
                        end else begin
                            TempPurchaseLineReceiptBuffer.Quantity := TempPrepmtDeductLCYPurchLine.Quantity;
                            TempPurchaseLineReceiptBuffer."Qty. to Invoice" := TempPrepmtDeductLCYPurchLine."Qty. to Invoice";
                            TempPurchaseLineReceiptBuffer.Insert();
                        end;
                        CurrentLineFinalInvoice := TempPurchaseLineReceiptBuffer.IsFinalInvoice();
                    end else begin
                        CurrentLineFinalInvoice := TempPrepmtDeductLCYPurchLine.IsFinalInvoice();
                        FinalInvoice := FinalInvoice and CurrentLineFinalInvoice;
                    end;

                    if PurchLine."Qty. to Invoice" <> TempPrepmtDeductLCYPurchLine."Qty. to Invoice" then
                        PurchLine."Prepmt Amt to Deduct" := CalcPrepmtAmtToDeduct(PurchLine, PurchHeader.Receive);
                    DeductionFactor :=
                      PurchLine."Prepmt Amt to Deduct" /
                      (PurchLine."Prepmt. Amt. Inv." - PurchLine."Prepmt Amt Deducted");

                    TempPrepmtDeductLCYPurchLine."Prepmt. VAT Amount Inv. (LCY)" :=
                      -CalcRoundedAmount(PurchLine."Prepmt Amt to Deduct" * PrepmtVATPart, PrepmtVATAmtRemainder);
                    if (TempPrepmtDeductLCYPurchLine."Prepayment %" <> 100) or CurrentLineFinalInvoice or (TempPrepmtDeductLCYPurchLine."Currency Code" <> '') then
                        CalcPrepmtRoundingAmounts(TempPrepmtDeductLCYPurchLine, PurchLine, DeductionFactor, TotalRoundingAmount);
                    TempPrepmtDeductLCYPurchLine.Modify();

                    if PurchHeader."Prices Including VAT" then
                        if ((TempPrepmtDeductLCYPurchLine."Prepayment %" <> 100) or CurrentLineFinalInvoice) and (DeductionFactor = 1) then begin
                            PricesInclVATRoundingAmount[1] := TotalRoundingAmount[1];
                            PricesInclVATRoundingAmount[2] := TotalRoundingAmount[2];
                        end;

                    if TempPrepmtDeductLCYPurchLine."VAT Calculation Type" <> TempPrepmtDeductLCYPurchLine."VAT Calculation Type"::"Full VAT" then
                        TotalPrepmtAmount[1] += TempPrepmtDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)";
                    TotalPrepmtAmount[2] += TempPrepmtDeductLCYPurchLine."Prepmt. VAT Amount Inv. (LCY)";
                until TempPrepmtDeductLCYPurchLine.Next() = 0;
            end;

            if FinalInvoice then
                if TempPurchaseLineReceiptBuffer.FindSet() then
                    repeat
                        if not TempPurchaseLineReceiptBuffer.IsFinalInvoice() then
                            FinalInvoice := false;
                    until not FinalInvoice or (TempPurchaseLineReceiptBuffer.Next() = 0);

            UpdatePrepmtPurchLineWithRounding(
              PrepmtPurchLine, TotalRoundingAmount, TotalPrepmtAmount,
              FinalInvoice, PricesInclVATRoundingAmount);
        end;
    end;

    local procedure CalcPrepmtAmtToDeduct(PurchLine: Record "Purchase Line"; Receive: Boolean): Decimal
    begin
        PurchLine."Qty. to Invoice" := GetQtyToInvoice(PurchLine, Receive);
        PurchLine.CalcPrepaymentToDeduct();
        exit(PurchLine."Prepmt Amt to Deduct");
    end;

    local procedure GetQtyToInvoice(PurchLine: Record "Purchase Line"; Receive: Boolean): Decimal
    var
        AllowedQtyToInvoice: Decimal;
    begin
        AllowedQtyToInvoice := PurchLine."Qty. Rcd. Not Invoiced";
        if Receive then
            AllowedQtyToInvoice := AllowedQtyToInvoice + PurchLine."Qty. to Receive";
        if PurchLine."Qty. to Invoice" > AllowedQtyToInvoice then
            exit(AllowedQtyToInvoice);
        exit(PurchLine."Qty. to Invoice");
    end;

    local procedure GetLineDataFromOrder(var PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchOrderLine: Record "Purchase Line";
    begin
        PurchRcptLine.Get(PurchLine."Receipt No.", PurchLine."Receipt Line No.");
        PurchOrderLine.Get(PurchLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");

        PurchLine.Quantity := PurchOrderLine.Quantity;
        PurchLine."Qty. Rcd. Not Invoiced" := PurchOrderLine."Qty. Rcd. Not Invoiced";
        PurchLine."Quantity Invoiced" := PurchOrderLine."Quantity Invoiced";
        PurchLine."Prepmt Amt Deducted" := PurchOrderLine."Prepmt Amt Deducted";
        PurchLine."Prepmt. Amt. Inv." := PurchOrderLine."Prepmt. Amt. Inv.";
        PurchLine."Line Discount Amount" := PurchOrderLine."Line Discount Amount";
        OnAfterGetLineDataFromOrder(PurchLine, PurchOrderLine);
    end;

    local procedure CalcPrepmtRoundingAmounts(var PrepmtPurchLineBuf: Record "Purchase Line"; PurchLine: Record "Purchase Line"; DeductionFactor: Decimal; var TotalRoundingAmount: array[2] of Decimal)
    var
        RoundingAmount: array[2] of Decimal;
    begin
        if PrepmtPurchLineBuf."VAT Calculation Type" <> PrepmtPurchLineBuf."VAT Calculation Type"::"Full VAT" then begin
            RoundingAmount[1] :=
              PrepmtPurchLineBuf."Prepmt. Amount Inv. (LCY)" - Round(DeductionFactor * PurchLine."Prepmt. Amount Inv. (LCY)");
            PrepmtPurchLineBuf."Prepmt. Amount Inv. (LCY)" := PrepmtPurchLineBuf."Prepmt. Amount Inv. (LCY)" - RoundingAmount[1];
            TotalRoundingAmount[1] += RoundingAmount[1];
        end;
        RoundingAmount[2] :=
          PrepmtPurchLineBuf."Prepmt. VAT Amount Inv. (LCY)" - Round(DeductionFactor * PurchLine."Prepmt. VAT Amount Inv. (LCY)");
        PrepmtPurchLineBuf."Prepmt. VAT Amount Inv. (LCY)" := PrepmtPurchLineBuf."Prepmt. VAT Amount Inv. (LCY)" - RoundingAmount[2];
        TotalRoundingAmount[2] += RoundingAmount[2];
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

        NewAmountIncludingVAT := TotalPrepmtAmount[1] + TotalPrepmtAmount[2] + TotalRoundingAmount[1] + TotalRoundingAmount[2];
        if PrepmtPurchLine."Prepayment %" = 100 then
            TotalRoundingAmount[1] -= PrepmtPurchLine."Amount Including VAT" + NewAmountIncludingVAT;

        AmountRoundingPrecision :=
          GetAmountRoundingPrecisionInLCY(PrepmtPurchLine."Document Type", PrepmtPurchLine."Document No.", PrepmtPurchLine."Currency Code");

        if (Abs(TotalRoundingAmount[1]) <= AmountRoundingPrecision) and
           (Abs(TotalRoundingAmount[2]) <= AmountRoundingPrecision) and
           (PrepmtPurchLine."Prepayment %" = 100)
        then begin
            Prepmt100PctVATRoundingAmt := TotalRoundingAmount[1];
            TotalRoundingAmount[1] := 0;
        end;

        if (PricesInclVATRoundingAmount[1] <> 0) and (PricesInclVATRoundingAmount[1] = TotalRoundingAmount[1]) and
           (PricesInclVATRoundingAmount[2] = 0) and (PricesInclVATRoundingAmount[2] = TotalRoundingAmount[2])
           and FinalInvoice and (PrepmtPurchLine."Prepayment %" <> 100)
        then begin
            PricesInclVATRoundingAmount[1] := 0;
            TotalRoundingAmount[1] := 0;
        end;

        PrepmtPurchLine."Prepmt. Amount Inv. (LCY)" := -TotalRoundingAmount[1];
        PrepmtPurchLine.Amount := -(TotalPrepmtAmount[1] + TotalRoundingAmount[1]);

        if (PricesInclVATRoundingAmount[1] <> 0) and (TotalRoundingAmount[1] = 0) then begin
            if (PrepmtPurchLine."Prepayment %" = 100) and FinalInvoice and
               (PrepmtPurchLine.Amount - TotalPrepmtAmount[2] = PrepmtPurchLine."Amount Including VAT")
            then
                Prepmt100PctVATRoundingAmt := 0;
            PricesInclVATRoundingAmount[1] := 0;
        end;

        if ((TotalRoundingAmount[2] <> 0) or FinalInvoice) and (TotalRoundingAmount[1] = 0) then begin
            if (PrepmtPurchLine."Prepayment %" = 100) and (PrepmtPurchLine."Prepmt. Amount Inv. (LCY)" = 0) then
                Prepmt100PctVATRoundingAmt += TotalRoundingAmount[2];
            if (PrepmtPurchLine."Prepayment %" = 100) or FinalInvoice then
                TotalRoundingAmount[2] := 0;
        end;

        if (PricesInclVATRoundingAmount[2] <> 0) and (TotalRoundingAmount[2] = 0) then begin
            if Abs(Prepmt100PctVATRoundingAmt) <= AmountRoundingPrecision then
                Prepmt100PctVATRoundingAmt := 0;
            PricesInclVATRoundingAmount[2] := 0;
        end;

        PrepmtPurchLine."Prepmt. VAT Amount Inv. (LCY)" := -(TotalRoundingAmount[2] + Prepmt100PctVATRoundingAmt);
        NewAmountIncludingVAT := PrepmtPurchLine.Amount - (TotalPrepmtAmount[2] + TotalRoundingAmount[2]);
        if (PricesInclVATRoundingAmount[1] = 0) and (PricesInclVATRoundingAmount[2] = 0) or
           (PrepmtPurchLine."Currency Code" <> '') and FinalInvoice or
           GLSetup.CheckFullGSTonPrepayment(PrepmtPurchLine."VAT Bus. Posting Group", PrepmtPurchLine."VAT Prod. Posting Group")
        then
            Increment(
              TotalPurchLineLCY."Amount Including VAT",
              -(PrepmtPurchLine."Amount Including VAT" - NewAmountIncludingVAT + Prepmt100PctVATRoundingAmt));
        if PrepmtPurchLine."Currency Code" = '' then
            TotalPurchLine."Amount Including VAT" := TotalPurchLineLCY."Amount Including VAT";
        PrepmtPurchLine."Amount Including VAT" := NewAmountIncludingVAT;

        if FinalInvoice and (TotalPurchLine.Amount = 0) and (TotalPurchLine."Amount Including VAT" <> 0) and
           (Abs(TotalPurchLine."Amount Including VAT") <= Currency."Amount Rounding Precision")
        then begin
            PrepmtPurchLine."Amount Including VAT" -= TotalPurchLineLCY."Amount Including VAT";
            TotalPurchLine."Amount Including VAT" := 0;
            TotalPurchLineLCY."Amount Including VAT" := 0;
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

    procedure DecrementPrepmtAmtInvLCY(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var PrepmtAmountInvLCY: Decimal; var PrepmtVATAmountInvLCY: Decimal)
    begin
        TempPrepmtDeductLCYPurchLine.Reset();
        if TempPrepmtDeductLCYPurchLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.") then begin
            PrepmtAmountInvLCY := PrepmtAmountInvLCY - TempPrepmtDeductLCYPurchLine."Prepmt. Amount Inv. (LCY)";
            PrepmtVATAmountInvLCY := PrepmtVATAmountInvLCY - TempPrepmtDeductLCYPurchLine."Prepmt. VAT Amount Inv. (LCY)";
        end;

        OnAfterDecrementPrepmtAmtInvLCY(PurchaseHeader, PurchaseLine, PrepmtAmountInvLCY, PrepmtVATAmountInvLCY);
    end;

    local procedure AdjustFinalInvWith100PctPrepmt(var CombinedPurchLine: Record "Purchase Line")
    var
        DiffToLineDiscAmt: Decimal;
    begin
        TempPrepmtDeductLCYPurchLine.Reset();
        TempPrepmtDeductLCYPurchLine.SetRange("Prepayment %", 100);
        if TempPrepmtDeductLCYPurchLine.FindSet(true) then
            repeat
                if TempPrepmtDeductLCYPurchLine.IsFinalInvoice() then begin
                    DiffToLineDiscAmt := TempPrepmtDeductLCYPurchLine."Prepmt Amt to Deduct" - TempPrepmtDeductLCYPurchLine."Line Amount";
                    if TempPrepmtDeductLCYPurchLine."Document Type" = TempPrepmtDeductLCYPurchLine."Document Type"::Order then
                        DiffToLineDiscAmt := DiffToLineDiscAmt * TempPrepmtDeductLCYPurchLine.Quantity / TempPrepmtDeductLCYPurchLine."Qty. to Invoice";
                    if DiffToLineDiscAmt <> 0 then begin
                        CombinedPurchLine.Get(TempPrepmtDeductLCYPurchLine."Document Type", TempPrepmtDeductLCYPurchLine."Document No.", TempPrepmtDeductLCYPurchLine."Line No.");
                        TempPrepmtDeductLCYPurchLine."Line Discount Amount" := CombinedPurchLine."Line Discount Amount" - DiffToLineDiscAmt;
                        TempPrepmtDeductLCYPurchLine.Modify();
                    end;
                end;
            until TempPrepmtDeductLCYPurchLine.Next() = 0;
        TempPrepmtDeductLCYPurchLine.Reset();
    end;

    procedure GetPrepmtDiffToLineAmount(PurchLine: Record "Purchase Line"): Decimal
    begin
        if PurchLine."Prepayment %" = 100 then
            if TempPrepmtDeductLCYPurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then
                exit(TempPrepmtDeductLCYPurchLine."Prepmt Amt to Deduct" + TempPrepmtDeductLCYPurchLine."Inv. Disc. Amount to Invoice" - TempPrepmtDeductLCYPurchLine."Line Amount");
        exit(0);
    end;

    local procedure InsertICGenJnlLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer)
    var
        ICGLAccount: Record "IC G/L Account";
        Currency: Record Currency;
        ICPartner: Record "IC Partner";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertICGenJnlLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);
        if IsHandled then
            exit;

        PurchHeader.TestField("Buy-from IC Partner Code", '');
        PurchHeader.TestField("Pay-to IC Partner Code", '');
        PurchLine.TestField("IC Partner Ref. Type", PurchLine."IC Partner Ref. Type"::"G/L Account");
        ICGLAccount.Get(PurchLine."IC Partner Reference");
        ICGenJnlLineNo := ICGenJnlLineNo + 1;

        TempICGenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PurchHeader."Posting Description",
            PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code", PurchLine."Dimension Set ID",
            PurchHeader."Reason Code");
        TempICGenJnlLine."Line No." := ICGenJnlLineNo;

        TempICGenJnlLine.CopyDocumentFields(GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchHeader."Posting No. Series");
        OnInsertICGenJnlLineOnAfterCopyDocumentFields(PurchHeader, PurchLine, TempICGenJnlLine);

        TempICGenJnlLine."Account Type" := TempICGenJnlLine."Account Type"::"IC Partner";
        TempICGenJnlLine.Validate("Account No.", PurchLine."IC Partner Code");
        TempICGenJnlLine."Source Currency Code" := PurchHeader."Currency Code";
        TempICGenJnlLine."Source Currency Amount" := TempICGenJnlLine.Amount;
        TempICGenJnlLine.Correction := PurchHeader.Correction;
        TempICGenJnlLine."Country/Region Code" := PurchHeader."VAT Country/Region Code";
        TempICGenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        TempICGenJnlLine."Source No." := PurchHeader."Pay-to Vendor No.";
        TempICGenJnlLine."Source Line No." := PurchLine."Line No.";
        TempICGenJnlLine.Validate("Bal. Account Type", TempICGenJnlLine."Bal. Account Type"::"G/L Account");
        TempICGenJnlLine.Validate("Bal. Account No.", PurchLine."No.");
        TempICGenJnlLine."Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        TempICGenJnlLine."Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        TempICGenJnlLine."Dimension Set ID" := PurchLine."Dimension Set ID";

        ValidateICPartnerBusPostingGroups(PurchLine);
        TempICGenJnlLine.Validate("Bal. VAT Prod. Posting Group", PurchLine."VAT Prod. Posting Group");
        TempICGenJnlLine."IC Partner Code" := PurchLine."IC Partner Code";
#if not CLEAN22
        TempICGenJnlLine."IC Partner G/L Acc. No." := PurchLine."IC Partner Reference";
#endif
        TempICGenJnlLine."IC Account Type" := TempICGenJnlLine."IC Account Type"::"G/L Account";
        TempICGenJnlLine."IC Account No." := PurchLine."IC Partner Reference";
        TempICGenJnlLine."IC Direction" := TempICGenJnlLine."IC Direction"::Outgoing;
        ICPartner.Get(PurchLine."IC Partner Code");
        if ICPartner."Cost Distribution in LCY" and (PurchLine."Currency Code" <> '') then begin
            TempICGenJnlLine."Currency Code" := '';
            TempICGenJnlLine."Currency Factor" := 0;
            Currency.Get(PurchLine."Currency Code");
            if PurchHeader.IsCreditDocType() then
                TempICGenJnlLine.Amount :=
                  -Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchHeader."Posting Date", PurchLine."Currency Code",
                      PurchLine.Amount, PurchHeader."Currency Factor"))
            else
                TempICGenJnlLine.Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchHeader."Posting Date", PurchLine."Currency Code",
                      PurchLine.Amount, PurchHeader."Currency Factor"));
        end else begin
            Currency.InitRoundingPrecision();
            TempICGenJnlLine."Currency Code" := PurchHeader."Currency Code";
            TempICGenJnlLine."Currency Factor" := PurchHeader."Currency Factor";
            if PurchHeader.IsCreditDocType() then
                TempICGenJnlLine.Amount := -PurchLine.Amount
            else
                TempICGenJnlLine.Amount := PurchLine.Amount;
        end;
        if TempICGenJnlLine."Bal. VAT %" <> 0 then
            TempICGenJnlLine.Amount := Round(TempICGenJnlLine.Amount * (1 + TempICGenJnlLine."Bal. VAT %" / 100), Currency."Amount Rounding Precision");
        TempICGenJnlLine.Validate(Amount);
        TempICGenJnlLine."Journal Template Name" := PurchLine.GetJnlTemplateName();
        OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(TempICGenJnlLine, PurchHeader, PurchLine, SuppressCommit);
        TempICGenJnlLine.Insert();
    end;

    local procedure ValidateICPartnerBusPostingGroups(var PurchaseLine: Record "Purchase Line")
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateICPartnerBusPostingGroups(TempICGenJnlLine, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        Customer.SetCurrentKey("IC Partner Code");
        Customer.SetRange("IC Partner Code", PurchaseLine."IC Partner Code");
        if Customer.FindFirst() then begin
            TempICGenJnlLine.Validate("Bal. Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
            TempICGenJnlLine.Validate("Bal. VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        end;
    end;

    local procedure PostICGenJnl(PurchHeader: Record "Purchase Header")
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxExport: Codeunit "IC Outbox Export";
        ICTransactionNo: Integer;
    begin
        TempICGenJnlLine.Reset();
        if TempICGenJnlLine.Find('-') then
            repeat
                ICTransactionNo := ICInboxOutboxMgt.CreateOutboxJnlTransaction(TempICGenJnlLine, false);
                ICInboxOutboxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, TempICGenJnlLine);
                ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICTransactionNo);
                if PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo" then
                    GenJnlPostLine.SetReversalDocument(true);
                if TempICGenJnlLine.Amount <> 0 then
                    GenJnlPostLine.RunWithCheck(TempICGenJnlLine);
            until TempICGenJnlLine.Next() = 0;
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
        ResetTempLines(TempPurchLine);
        TempPurchLine.SetFilter(Quantity, '>0');
        TempPurchLine.SetFilter("Qty. to Invoice", '>0');
        TempPurchLine.SetFilter("Receipt No.", '<>%1', '');
        TempPurchLine.SetFilter("Prepmt Amt to Deduct", '<>0');
        if TempPurchLine.IsEmpty() then
            exit;

        TempPurchLine.SetRange("Prepmt Amt to Deduct");
        if TempPurchLine.FindSet() then
            repeat
                if PurchRcptLine.Get(TempPurchLine."Receipt No.", TempPurchLine."Receipt Line No.") then begin
                    TempRcvdPurchLine := TempPurchLine;
                    TempRcvdPurchLine.Insert();
                    TempPurchRcptLine := PurchRcptLine;
                    if TempPurchRcptLine.Insert() then;

                    if not TempTotalPurchLine.Get(TempPurchLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.")
                    then begin
                        TempTotalPurchLine.Init();
                        TempTotalPurchLine."Document Type" := TempPurchLine."Document Type"::Order;
                        TempTotalPurchLine."Document No." := PurchRcptLine."Order No.";
                        TempTotalPurchLine."Line No." := PurchRcptLine."Order Line No.";
                        TempTotalPurchLine.Insert();
                    end;
                    TempTotalPurchLine."Qty. to Invoice" := TempTotalPurchLine."Qty. to Invoice" + TempPurchLine."Qty. to Invoice";
                    TempTotalPurchLine."Prepmt Amt to Deduct" := TempTotalPurchLine."Prepmt Amt to Deduct" + TempPurchLine."Prepmt Amt to Deduct";
                    AdjustInvLineWith100PctPrepmt(TempPurchLine, TempTotalPurchLine);
                    TempTotalPurchLine.Modify();
                end;
            until TempPurchLine.Next() = 0;

        if TempRcvdPurchLine.FindSet() then
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
                                Error(PrepAmountToDeductToBigErr, TempPurchLine.FieldCaption("Prepmt Amt to Deduct"), MaxAmtToDeduct);

                            if (TempTotalPurchLine."Qty. to Invoice" = PurchaseOrderLine.Quantity - PurchaseOrderLine."Quantity Invoiced") and
                               (PurchaseOrderLine."Prepmt Amt to Deduct" <> MaxAmtToDeduct)
                            then
                                Error(PrepAmountToDeductToSmallErr, TempPurchLine.FieldCaption("Prepmt Amt to Deduct"), MaxAmtToDeduct);
                        end;
            until TempRcvdPurchLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyFactorACY(PurchHeader: Record "Purchase Header")
    begin
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then begin
            AddCurrency.Get(GLSetup."Additional Reporting Currency");
            if (PurchHeader."Vendor Exchange Rate (ACY)" <> 0) and (PurchHeader."Currency Code" = '') then
                CurrencyFactor :=
                  CurrExchRate.ExchangeRateFactorFRS21(
                    GetDate(PurchHeader), GLSetup."Additional Reporting Currency", PurchHeader."Vendor Exchange Rate (ACY)")
            else
                CurrencyFactor :=
                  CurrExchRate.ExchangeRate(
                    GetDate(PurchHeader), GLSetup."Additional Reporting Currency");
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertGenJournalWHT(var PurchHeader: Record "Purchase Header"; var GenJnlLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := PurchHeader."Posting Date";
        GenJnlLine."Document Date" := PurchHeader."Document Date";
        GenJnlLine.Description := PurchHeader."Posting Description";
        GenJnlLine."Shortcut Dimension 1 Code" := PurchHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PurchHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PurchHeader."Dimension Set ID";
        GenJnlLine."Reason Code" := PurchHeader."Reason Code";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := AccountNo;
        GenJnlLine."Document Type" := GenJnlLineDocType;
        GenJnlLine."Document No." := GenJnlLineDocNo;
        GenJnlLine."External Document No." := GenJnlLineExtDocNo;
        GenJnlLine."Currency Code" := PurchHeader."Currency Code";
        GenJnlLine.Amount := -WHTEntry.Amount;
        GenJnlLine."Vendor Exchange Rate (ACY)" := PurchHeader."Vendor Exchange Rate (ACY)";
        GenJnlLine."Amount Including VAT (ACY)" := -TotalPurchLineLCY."Amount Including VAT (ACY)";
        GenJnlLine."Source Currency Code" := PurchHeader."Currency Code";
        GenJnlLine."Source Currency Amount" := -WHTEntry.Amount;
        if PurchHeader."Currency Code" <> '' then
            GenJnlLine."Amount (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PurchHeader."Posting Date", PurchHeader."Currency Code", -WHTEntry.Amount, PurchHeader."Currency Factor"));
        if PurchHeader."Currency Code" = '' then
            GenJnlLine."Currency Factor" := 1
        else
            GenJnlLine."Currency Factor" := PurchHeader."Currency Factor";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalPurchLineLCY.Amount;
        GenJnlLine.Correction := PurchHeader.Correction;
        GenJnlLine."Inv. Discount (LCY)" := -TotalPurchLineLCY."Inv. Discount Amount";
        GenJnlLine."Sell-to/Buy-from No." := PurchHeader."Buy-from Vendor No.";
        GenJnlLine."Bill-to/Pay-to No." := PurchHeader."Pay-to Vendor No.";
        GenJnlLine."Salespers./Purch. Code" := PurchHeader."Purchaser Code";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."On Hold" := PurchHeader."On Hold";
        GenJnlLine."Allow Application" := PurchHeader."Bal. Account No." = '';
        GenJnlLine."Due Date" := PurchHeader."Due Date";
        GenJnlLine."Payment Terms Code" := PurchHeader."Payment Terms Code";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        GenJnlLine."Source No." := PurchHeader."Pay-to Vendor No.";
        GenJnlLine."Source Code" := SrcCode;
        GenJnlLine."Posting No. Series" := PurchHeader."Posting No. Series";
        GenJnlLine."IC Partner Code" := PurchHeader."Pay-to IC Partner Code";
        GenJnlLine.Adjustment := PurchHeader.Adjustment;
        GenJnlLine."BAS Adjustment" := PurchHeader."BAS Adjustment";
        GenJnlLine."Adjustment Applies-to" := PurchHeader."Adjustment Applies-to";
    end;

    local procedure AdjustInvLineWith100PctPrepmt(var PurchInvoiceLine: Record "Purchase Line"; var TempTotalPurchLine: Record "Purchase Line" temporary)
    var
        PurchOrderLine: Record "Purchase Line";
        DiffAmtToDeduct: Decimal;
    begin
        if PurchInvoiceLine."Prepayment %" = 100 then begin
            PurchOrderLine.Get(TempTotalPurchLine."Document Type", TempTotalPurchLine."Document No.", TempTotalPurchLine."Line No.");
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
        OnBeforeArchiveUnpostedOrder(PurchHeader, IsHandled, OrderArchived, PreviewMode);
        if IsHandled then
            exit;

        if not (PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"]) then
            exit;

        GetPurchSetup();
        if (PurchHeader."Document Type" = PurchHeader."Document Type"::Order) and not PurchSetup."Archive Orders" then
            exit;
        if (PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order") and not PurchSetup."Archive Return Orders" then
            exit;

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Quantity, '<>0');
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
            PurchLine.SetFilter("Qty. to Receive", '<>0')
        else
            PurchLine.SetFilter("Return Qty. to Ship", '<>0');
        if not PurchLine.IsEmpty() and not PreviewMode then begin
            ArchiveManagement.RoundPurchaseDeferralsForArchive(PurchHeader, PurchLine);
            ArchiveManagement.ArchPurchDocumentNoConfirm(PurchHeader);
            OrderArchived := true;
        end;
    end;

    local procedure PostItemJnlLineJobConsumption(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemJournalLine: Record "Item Journal Line"; var TempPurchReservEntry: Record "Reservation Entry" temporary; QtyToBeInvoiced: Decimal; QtyToBeReceived: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchItemLedgEntryNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPostItemJnlLineJobConsumption(
          PurchHeader, PurchLine, ItemJournalLine, TempPurchReservEntry, QtyToBeInvoiced, QtyToBeReceived,
          TempTrackingSpecification, PurchItemLedgEntryNo, IsHandled, ItemJnlPostLine, PurchInvHeader, PurchCrMemoHeader, SrcCode);
        if IsHandled then
            exit;

        if PurchLine."Job No." <> '' then begin
            ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
            Job.Get(PurchLine."Job No.");
            ItemJournalLine."Source No." := Job."Bill-to Customer No.";
            if PurchHeader.Invoice then begin
                ItemLedgEntry.Reset();
                ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Return Shipment");
                if PurchLine."Return Shipment No." <> '' then
                    ItemLedgEntry.SetRange("Document No.", PurchLine."Return Shipment No.")
                else
                    ItemLedgEntry.SetRange("Document No.", PurchHeader."Last Return Shipment No.");
                ItemLedgEntry.SetRange("Item No.", PurchLine."No.");
                ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Negative Adjmt.");
                ItemLedgEntry.SetRange("Completely Invoiced", false);
                OnPostItemJnlLineJobConsumptionOnAfterItemLedgEntrySetFilters(ItemLedgEntry, PurchLine, ItemJournalLine);
                if ItemLedgEntry.FindFirst() then
                    ItemJournalLine."Item Shpt. Entry No." := ItemLedgEntry."Entry No.";
            end;
            JobPlanningLine.SetLoadFields("Job Contract Entry No.");
            if JobPlanningLine.Get(PurchLine."Job No.", PurchLine."Job Task No.", PurchLine."Job Planning Line No.") then
                ItemJournalLine."Job Contract Entry No." := JobPlanningLine."Job Contract Entry No.";
            ItemJournalLine."Source Type" := ItemJournalLine."Source Type"::Customer;
            ItemJournalLine."Discount Amount" := 0;

            GetAppliedItemLedgEntryNo(ItemJournalLine, PurchLine."Quantity Received");

            if QtyToBeReceived <> 0 then
                CopyJobConsumptionReservation(
                  TempReservationEntry, TempPurchReservEntry, ItemJournalLine, TempTrackingSpecification,
                  PurchItemLedgEntryNo, PurchLine.IsNonInventoriableItem());

            OnPostItemJnlLineJobConsumptionOnBeforeRunItemJnlPostLineWithReservation(ItemJournalLine, TempReservationEntry, PurchLine);
            RunItemJnlPostLineWithReservation(ItemJournalLine, TempReservationEntry);

            IsHandled := false;
            OnPostItemJnlLineJobConsumptionOnBeforeJobPost(
                PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchRcptHeader, ReturnShptHeader, PurchLine, SrcCode, QtyToBeReceived, IsHandled, QtyToBeInvoiced);
            if IsHandled then
                exit;

            if PurchLine."Job Line Type" = PurchLine."Job Line Type"::" " then
                ValidateMatchingJobPlanningLine(PurchLine);

            if QtyToBeInvoiced <> 0 then begin
                PurchLine."Qty. to Invoice" := QtyToBeInvoiced;
#if not CLEAN23
                if UseLegacyInvoicePosting() then
                    JobPostLine.PostJobOnPurchaseLine(PurchHeader, PurchInvHeader, PurchCrMemoHeader, PurchLine, SrcCode)
                else
#endif
                    InvoicePostingInterface.PrepareJobLine(PurchHeader, PurchLine, PurchLineACY);
            end;
        end;
    end;

    local procedure CopyJobConsumptionReservation(var TempReservEntryJobCons: Record "Reservation Entry" temporary; var TempReservEntryPurchase: Record "Reservation Entry" temporary; var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchItemLedgEntryNo: Integer; NonInventoriableItem: Boolean)
    var
        NextReservationEntryNo: Integer;
    begin
        // Item tracking for consumption
        NextReservationEntryNo := 1;
        if TempReservEntryPurchase.FindSet() then
            repeat
                TempReservEntryJobCons := TempReservEntryPurchase;

                TempReservEntryJobCons."Entry No." := NextReservationEntryNo;
                TempReservEntryJobCons.Positive := not TempReservEntryJobCons.Positive;
                TempReservEntryJobCons."Quantity (Base)" := -TempReservEntryJobCons."Quantity (Base)";
                TempReservEntryJobCons."Shipment Date" := TempReservEntryJobCons."Expected Receipt Date";
                TempReservEntryJobCons."Expected Receipt Date" := 0D;
                TempReservEntryJobCons.Quantity := -TempReservEntryJobCons.Quantity;
                TempReservEntryJobCons."Qty. to Handle (Base)" := -TempReservEntryJobCons."Qty. to Handle (Base)";
                TempReservEntryJobCons."Qty. to Invoice (Base)" := -TempReservEntryJobCons."Qty. to Invoice (Base)";
                TempReservEntryJobCons."Source Subtype" := ItemJournalLine."Entry Type".AsInteger();
                TempReservEntryJobCons."Source Ref. No." := ItemJournalLine."Line No.";

                UpdateJobConsumptionReservationApplToItemEntry(TempReservEntryJobCons, ItemJournalLine, TempTrackingSpecification, NonInventoriableItem);

                TempReservEntryJobCons.Insert();

                NextReservationEntryNo := NextReservationEntryNo + 1;
            until TempReservEntryPurchase.Next() = 0
        else
            if not (ItemJournalLine.IsPurchaseReturn() or NonInventoriableItem) then
                ItemJournalLine."Applies-to Entry" := PurchItemLedgEntryNo;
    end;

    local procedure UpdateJobConsumptionReservationApplToItemEntry(var TempReservEntryJobCons: Record "Reservation Entry" temporary; var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; NonInventoriableItem: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobConsumptionReservationApplToItemEntry(TempReservEntryJobCons, ItemJournalLine, NonInventoriableItem, IsHandled);
        if IsHandled then
            exit;

        if not (ItemJournalLine.IsPurchaseReturn() or NonInventoriableItem) then begin
            TempTrackingSpecification.SetRange("Serial No.", TempReservEntryJobCons."Serial No.");
            TempTrackingSpecification.SetRange("Lot No.", TempReservEntryJobCons."Lot No.");
            if TempTrackingSpecification.FindFirst() then
                TempReservEntryJobCons."Appl.-to Item Entry" := TempTrackingSpecification."Item Ledger Entry No.";
        end;
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
                if ItemLedgerEntry.FindFirst() then
                    ItemJournalLine."Item Shpt. Entry No." := ItemLedgerEntry."Entry No."
            end;
    end;

    local procedure GetAppliedOutboundItemLedgEntryNo(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemJnlLine."Item Shpt. Entry No.");
        if ItemApplicationEntry.FindLast() then
            ItemJnlLine."Item Shpt. Entry No." := ItemApplicationEntry."Outbound Item Entry No.";

        OnAfterGetAppliedOutboundItemLedgEntryNo(ItemJnlLine, ItemApplicationEntry);
    end;

    local procedure GetAppliedInboundItemLedgEntryNo(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemJnlLine."Item Shpt. Entry No.");
        if ItemApplicationEntry.FindLast() then
            ItemJnlLine."Item Shpt. Entry No." := ItemApplicationEntry."Inbound Item Entry No.";
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
        InvSetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLockTables(PurchHeader, PreviewMode, SuppressCommit, IsHandled, TempPurchLineGlobal);
        if not IsHandled then
            exit;

        PurchLine.LockTable();
        SalesLine.LockTable();
        if not InvSetup.OptimGLEntLockForMultiuserEnv() then begin
            GLEntry.LockTable();
            if GLEntry.FindLast() then;
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

        OnAfterCreateJobPurchLine(JobPurchLine2, PurchLine2);
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

        if PostJobConsumptionBeforePurch or (JobNo = '') then
            exit(false);

        TempWhseJnlLine."Entry Type" := TempWhseJnlLine."Entry Type"::"Negative Adjmt.";
        TempWhseJnlLine.Quantity := -TempWhseJnlLine.Quantity;
        TempWhseJnlLine."Qty. (Base)" := -TempWhseJnlLine."Qty. (Base)";
        TempWhseJnlLine."From Bin Code" := TempWhseJnlLine."To Bin Code";
        TempWhseJnlLine."To Bin Code" := '';

        OnAfterRevertWarehouseEntry(TempWhseJnlLine);
        exit(true);
    end;

    local procedure CreatePositiveEntry(WhseJnlLine: Record "Warehouse Journal Line"; JobNo: Code[20]; PostJobConsumptionBeforePurch: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePositiveEntry(WhseJnlLine, JobNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not PostJobConsumptionBeforePurch and (JobNo = '') then
            exit(false);

        WhseJnlLine.Quantity := -WhseJnlLine.Quantity;
        WhseJnlLine."Qty. (Base)" := -WhseJnlLine."Qty. (Base)";
        WhseJnlLine."Qty. (Absolute)" := -WhseJnlLine."Qty. (Absolute)";
        WhseJnlLine."To Bin Code" := WhseJnlLine."From Bin Code";
        WhseJnlLine."From Bin Code" := '';

        OnCreatePositiveOnBeforeWhseJnlPostLine(WhseJnlLine);
        WhseJnlPostLine.Run(WhseJnlLine);

        exit(true);
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
        case ItemChargeAssignmentPurch."Applies-to Doc. Type" of
            ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order,
              ItemChargeAssignmentPurch."Applies-to Doc. Type"::Invoice:
                if PurchLineForCharge.Get(ItemChargeAssignmentPurch."Applies-to Doc. Type", ItemChargeAssignmentPurch."Applies-to Doc. No.", ItemChargeAssignmentPurch."Applies-to Doc. Line No.") then
                    if (PurchLineForCharge."Quantity (Base)" = PurchLineForCharge."Qty. Received (Base)") and
                       (PurchLineForCharge."Qty. Rcd. Not Invoiced (Base)" = 0)
                    then
                        Error(ReassignItemChargeErr);
            ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Order",
              ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Credit Memo":
                if PurchLineForCharge.Get(ItemChargeAssignmentPurch."Applies-to Doc. Type", ItemChargeAssignmentPurch."Applies-to Doc. No.", ItemChargeAssignmentPurch."Applies-to Doc. Line No.") then
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

    procedure SetCalledBy(NewCalledBy: Integer)
    begin
        CalledBy := NewCalledBy;
    end;

    local procedure UpdateInvoicedQtyOnPurchRcptLine(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        OnBeforeUpdateInvoicedQtyOnPurchRcptLine(
          PurchRcptLine, QtyToBeInvoiced, QtyToBeInvoicedBase, SuppressCommit, PurchInvHeader, PurchaseHeader, PurchaseLine);

        PurchRcptLine."Quantity Invoiced" := PurchRcptLine."Quantity Invoiced" + QtyToBeInvoiced;
        PurchRcptLine."Qty. Invoiced (Base)" := PurchRcptLine."Qty. Invoiced (Base)" + QtyToBeInvoicedBase;
        PurchRcptLine."Qty. Rcd. Not Invoiced" := PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";
        PurchRcptLine.Modify();

        OnAfterUpdateInvoicedQtyOnPurchRcptLine(
          PurchInvHeader, PurchRcptLine, PurchaseLine, TempTrackingSpecification, TrackingSpecificationExists,
          QtyToBeInvoiced, QtyToBeInvoicedBase, PurchaseHeader, SuppressCommit);
    end;

    local procedure UpdateInvoicedQtyOnReturnShptLine(var ReturnShptLine: Record "Return Shipment Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
        ReturnShptLine."Quantity Invoiced" := ReturnShptLine."Quantity Invoiced" - QtyToBeInvoiced;
        ReturnShptLine."Qty. Invoiced (Base)" := ReturnShptLine."Qty. Invoiced (Base)" - QtyToBeInvoicedBase;
        ReturnShptLine."Return Qty. Shipped Not Invd." := ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced";
        ReturnShptLine.Modify();
    end;

    local procedure UpdateQtyPerUnitOfMeasure(var PurchLine: Record "Purchase Line")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Skip UoM validation for partially received/shipped documents and lines fetch through "Get Receipts Lines"
        if (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."No." <> '') and (PurchLine."Qty. Received (Base)" = 0) and (PurchLine."Receipt No." = '') and (PurchLine."Return Qty. Shipped (Base)" = 0) and (PurchLine."Return Shipment No." = '') then
            PurchLine.TestField("Unit of Measure Code");

        if PurchLine."Qty. per Unit of Measure" = 0 then
            if (PurchLine.Type = PurchLine.Type::Item) and
               ItemUnitOfMeasure.Get(PurchLine."No.", PurchLine."Unit of Measure Code")
            then
                PurchLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure"
            else
                PurchLine."Qty. per Unit of Measure" := 1;
    end;

    local procedure UpdateQtyToBeInvoicedForReceipt(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; PurchLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; InvoicingTrackingSpecification: Record "Tracking Specification")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyToBeInvoicedForReceipt(
            QtyToBeInvoiced, QtyToBeInvoicedBase, TrackingSpecificationExists, PurchLine, PurchRcptLine, InvoicingTrackingSpecification, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase, IsHandled);
        if IsHandled then
            exit;

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
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyToBeInvoicedForReturnShipment(QtyToBeInvoiced, QtyToBeInvoicedBase, TrackingSpecificationExists, PurchLine, ReturnShipmentLine, InvoicingTrackingSpecification, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase, IsHandled);
        if IsHandled then
            exit;

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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemReservDisruption(PurchLine, IsHandled);
        if IsHandled then
            exit;

        if not PurchLine.IsCreditDocType() or (PurchLine.Type <> PurchLine.Type::Item) or not (PurchLine."Return Qty. to Ship (Base)" > 0) then
            exit;

        if PurchLine.Nonstock or PurchLine."Special Order" or PurchLine."Drop Shipment" or PurchLine.IsNonInventoriableItem() or
           TempSKU.Get(PurchLine."Location Code", PurchLine."No.", PurchLine."Variant Code")
        then
            exit;

        Item.Get(PurchLine."No.");
        Item.SetFilter("Location Filter", PurchLine."Location Code");
        Item.SetFilter("Variant Filter", PurchLine."Variant Code");
        Item.CalcFields("Reserved Qty. on Inventory", "Net Change");
        PurchLine.CalcFields("Reserved Qty. (Base)");
        AvailableQty := Item."Net Change" - (Item."Reserved Qty. on Inventory" - Abs(PurchLine."Reserved Qty. (Base)"));

        if (Item."Reserved Qty. on Inventory" > 0) and
           (AvailableQty < PurchLine."Return Qty. to Ship (Base)") and
           (Item."Reserved Qty. on Inventory" > Abs(PurchLine."Reserved Qty. (Base)"))
        then begin
            InsertTempSKU(PurchLine."Location Code", PurchLine."No.", PurchLine."Variant Code");
            IsHandled := false;
            OnCheckItemReservDisruptionOnAfterInsertTempSKU(Item, IsHandled);
            if not IsHandled then
                if Location.BinMandatory(PurchLine."Location Code") then begin
                    Session.LogMessage('0000GKM', ItemReservDisruptionLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PurchLinePostCategoryTok);
                    if not ConfirmManagement.GetResponseOrDefault(
                        StrSubstNo(
                            ReservationDisruptedQst, PurchLine.FieldCaption("No."), Item."No.", PurchLine.FieldCaption("Location Code"),
                            PurchLine."Location Code", PurchLine.FieldCaption("Variant Code"), PurchLine."Variant Code"), true)
                    then
                        Error('');
                end;
        end;
    end;

    local procedure InsertTempSKU(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        TempSKU.Init();
        TempSKU."Location Code" := LocationCode;
        TempSKU."Item No." := ItemNo;
        TempSKU."Variant Code" := VariantCode;
        TempSKU.Insert();
    end;

    local procedure UpdatePurchLineDimSetIDFromAppliedEntry(var PurchaseLineToPost: Record "Purchase Line"; PurchaseLine: Record "Purchase Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        DimensionMgt: Codeunit DimensionManagement;
        DimSetID: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchLineDimSetIDFromAppliedEntry(PurchaseLineToPost, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        DimSetID[1] := PurchaseLine."Dimension Set ID";
        if PurchaseLineToPost."Appl.-to Item Entry" <> 0 then begin
            ItemLedgerEntry.Get(PurchaseLineToPost."Appl.-to Item Entry");
            DimSetID[2] := ItemLedgerEntry."Dimension Set ID";
        end;
        PurchaseLineToPost."Dimension Set ID" :=
            DimensionMgt.GetCombinedDimensionSetID(DimSetID, PurchaseLineToPost."Shortcut Dimension 1 Code", PurchaseLineToPost."Shortcut Dimension 2 Code");

        OnAfterUpdatePurchLineDimSetIDFromAppliedEntry(PurchaseLineToPost, PurchaseLine);
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

    procedure CheckSalesCertificateOfSupplyStatus(SalesShptHeader: Record "Sales Shipment Header"; SalesShptLine: Record "Sales Shipment Line")
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
        IsHandled: Boolean;
    begin
        if PreviewMode then
            PostingPreviewEventHandler.PreventCommit();

        IsHandled := false;
        OnBeforeInsertPostedHeaders(PurchHeader, TempWhseRcptHeader, TempWhseShptHeader, GenJnlPostLine, PurchRcptHeader, IsHandled);
        if not IsHandled then begin
            // Insert receipt header
            if PurchHeader.Receive then
                if (PurchHeader."Document Type" = PurchHeader."Document Type"::Order) or
                   ((PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice) and PurchSetup."Receipt on Invoice")
                then begin
                    if DropShipOrder then begin
                        PurchRcptHeader.LockTable();
                        PurchRcptLine.LockTable();
                        SalesShptHeader.LockTable();
                        SalesShptLine.LockTable();
                    end;
                    InsertReceiptHeader(PurchHeader, PurchRcptHeader);
                    ServItemMgt.CopyReservation(PurchHeader);
                end;

            // Insert return shipment header
            if PurchHeader.Ship then
                if (PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order") or
                   ((PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo") and PurchSetup."Return Shipment on Credit Memo")
                then
                    InsertReturnShipmentHeader(PurchHeader, ReturnShptHeader);

            // Insert invoice header or credit memo header
            if PurchHeader.Invoice then begin
                IsHandled := false;
                OnInsertPostedHeadersOnAfterInvoice(PurchHeader, GenJnlLine, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, IsHandled);
                if not IsHandled then
                    if PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice] then begin
                        InsertInvoiceHeader(PurchHeader, PurchInvHeader);
                        GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                        GenJnlLineDocNo := PurchInvHeader."No.";
                        GenJnlLineExtDocNo := PurchHeader."Vendor Invoice No.";
                    end else begin // Credit Memo
                        InsertCrMemoHeader(PurchHeader, PurchCrMemoHeader);
                        GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                        GenJnlLineDocNo := PurchCrMemoHeader."No.";
                        GenJnlLineExtDocNo := PurchHeader."Vendor Cr. Memo No.";
                    end;
#if not CLEAN23
                if not UseLegacyInvoicePosting() then begin
#endif
                    GetInvoicePostingParameters();
                    InvoicePostingInterface.SetParameters(InvoicePostingParameters);
#if not CLEAN23
                end;
#endif
            end;
        end;
        OnAfterInsertPostedHeaders(PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader, ReturnShptHeader, PurchSetup, Window);
    end;

    local procedure InsertReceiptHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReceiptHeader(PurchHeader, PurchRcptHeader, IsHandled, SuppressCommit);

        if not IsHandled then begin
            PurchRcptHeader.Init();
            PurchRcptHeader.TransferFields(PurchHeader);
            PurchRcptHeader."No." := PurchHeader."Receiving No.";
            if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then begin
                PurchRcptHeader."Order No. Series" := PurchHeader."No. Series";
                PurchRcptHeader."Order No." := PurchHeader."No.";
            end;
            PurchRcptHeader."No. Printed" := 0;
            PurchRcptHeader."Source Code" := SrcCode;
            PurchRcptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchRcptHeader."User ID"));
            OnBeforePurchRcptHeaderInsert(PurchRcptHeader, PurchHeader, SuppressCommit, TempWhseRcptHeader, WhseReceive, TempWhseShptHeader, WhseShip);
            PurchRcptHeader.Insert(true);
            OnAfterPurchRcptHeaderInsert(PurchRcptHeader, PurchHeader, SuppressCommit, PreviewMode);

            ApprovalsMgmt.PostApprovalEntries(PurchHeader.RecordId, PurchRcptHeader.RecordId, PurchRcptHeader."No.");

            if PurchSetup."Copy Comments Order to Receipt" then begin
                PurchCommentLine.CopyComments(
                  PurchHeader."Document Type".AsInteger(), PurchCommentLine."Document Type"::Receipt.AsInteger(), PurchHeader."No.", PurchRcptHeader."No.");
                RecordLinkManagement.CopyLinks(PurchHeader, PurchRcptHeader);
            end;
        end;

        if WhseReceive then begin
            WhseRcptHeader.Get(TempWhseRcptHeader."No.");
            OnBeforeCreatePostedWhseRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, PurchHeader);
            WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, PurchHeader."Receiving No.", PurchHeader."Posting Date");
        end;
        if WhseShip then begin
            WhseShptHeader.Get(TempWhseShptHeader."No.");
            OnBeforeCreatePostedWhseShptHeader(PostedWhseShptHeader, WhseShptHeader, PurchHeader);
            WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, PurchHeader."Receiving No.", PurchHeader."Posting Date");
        end;

        OnAfterInsertReceiptHeader(PurchHeader, PurchRcptHeader, TempWhseRcptHeader, WhseReceive, SuppressCommit);
    end;

    procedure InsertReceiptLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchLine: Record "Purchase Line"; CostBaseAmount: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        ShouldGetWhseRcptLine: Boolean;
        ShouldGetWhseShptLine: Boolean;
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

        OnInsertReceiptLineOnAfterInitPurchRcptLine(PurchRcptLine, PurchLine, ItemLedgShptEntryNo, xPurchLine, PurchRcptHeader, CostBaseAmount, PostedWhseRcptHeader, WhseRcptHeader, WhseRcptLine);

        IsHandled := false;
        OnInsertReceiptLineOnBeforeProcessWhseShptRcpt(PurchLine, IsHandled, CostBaseAmount, PurchRcptLine);
        if not IsHandled then
            if (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."Qty. to Receive" <> 0) then begin
                ShouldGetWhseRcptLine := WhseReceive and PurchLine.IsInventoriableItem();
                OnInsertReceiptLineOnAfterCalcShouldGetWhseRcptLine(PurchRcptHeader, PurchLine, PostedWhseRcptHeader, WhseRcptHeader, CostBaseAmount, WhseReceive, WhseShip, ShouldGetWhseRcptLine, xPurchLine, PurchRcptLine);
                if ShouldGetWhseRcptLine then
                    if WhseRcptLine.GetWhseRcptLine(
                         WhseRcptHeader."No.", DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.")
                    then begin
                        OnInsertReceiptLineOnAfterGetWhseRcptLine(WhseRcptLine, PurchRcptLine);
                        CheckWhseRcptLineQtyToReceive(WhseRcptLine, PurchRcptLine);
                        SaveTempWhseSplitSpec(PurchLine);
                        OnInsertReceiptLineOnBeforeCreatePostedRcptLine(PurchRcptLine, WhseRcptLine, PostedWhseRcptHeader);
                        WhsePostRcpt.CreatePostedRcptLine(
                          WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                    end;

                ShouldGetWhseShptLine := WhseShip and PurchLine.IsInventoriableItem();
                OnInsertReceiptLineOnAfterCalcShouldGetWhseShptLine(PurchRcptHeader, PurchLine, PostedWhseShptHeader, WhseShptHeader, CostBaseAmount, WhseReceive, WhseShip, ShouldGetWhseShptLine);
                if ShouldGetWhseShptLine then
                    if WhseShptLine.GetWhseShptLine(
                         WhseShptHeader."No.", DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.")
                    then begin
                        WhseShptLine.TestField("Qty. to Ship", -PurchRcptLine.Quantity);
                        SaveTempWhseSplitSpec(PurchLine);
                        OnInsertReceiptLineOnBeforeCreatePostedShptLine(PurchRcptLine, WhseShptLine, PostedWhseShptHeader);
                        WhsePostShpt.CreatePostedShptLine(
                          WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                    end;
                PurchRcptLine."Item Rcpt. Entry No." := InsertRcptEntryRelation(PurchRcptLine);
                PurchRcptLine."Item Charge Base Amount" := Round(CostBaseAmount / PurchLine.Quantity * PurchRcptLine.Quantity);
            end;
        PurchRcptLineInsert(PurchRcptLine, PurchRcptHeader, PurchLine);
    end;

    local procedure CheckWhseRcptLineQtyToReceive(var WhseRcptLine: Record "Warehouse Receipt Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseRcptLineQtyToReceive(WhseRcptLine, PurchRcptLine, IsHandled);
        if IsHandled then
            exit;

        WhseRcptLine.TestField("Qty. to Receive", PurchRcptLine.Quantity);
    end;

    local procedure InsertReturnShipmentHeader(var PurchHeader: Record "Purchase Header"; var ReturnShptHeader: Record "Return Shipment Header")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReturnShipmentHeader(PurchHeader, ReturnShptHeader, IsHandled);
        if not IsHandled then begin
            ReturnShptHeader.Init();
            ReturnShptHeader.TransferFields(PurchHeader);
            ReturnShptHeader."No." := PurchHeader."Return Shipment No.";
            if PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order" then begin
                ReturnShptHeader."Return Order No. Series" := PurchHeader."No. Series";
                ReturnShptHeader."Return Order No." := PurchHeader."No.";
            end;
            ReturnShptHeader."No. Series" := PurchHeader."Return Shipment No. Series";
            ReturnShptHeader."No. Printed" := 0;
            ReturnShptHeader."Source Code" := SrcCode;
            ReturnShptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReturnShptHeader."User ID"));
            OnBeforeReturnShptHeaderInsert(ReturnShptHeader, PurchHeader, SuppressCommit, TempWhseRcptHeader, WhseReceive, TempWhseShptHeader, WhseShip);
            ReturnShptHeader.Insert(true);
            OnAfterReturnShptHeaderInsert(ReturnShptHeader, PurchHeader, SuppressCommit);

            ApprovalsMgmt.PostApprovalEntries(PurchHeader.RecordId, ReturnShptHeader.RecordId, ReturnShptHeader."No.");

            if PurchSetup."Copy Cmts Ret.Ord. to Ret.Shpt" then begin
                PurchCommentLine.CopyComments(
                  PurchHeader."Document Type".AsInteger(), PurchCommentLine."Document Type"::"Posted Return Shipment".AsInteger(), PurchHeader."No.", ReturnShptHeader."No.");
                RecordLinkManagement.CopyLinks(PurchHeader, ReturnShptHeader);
            end;
        end;
        if WhseShip then begin
            WhseShptHeader.Get(TempWhseShptHeader."No.");
            OnBeforeCreatePostedWhseShptHeader(PostedWhseShptHeader, WhseShptHeader, PurchHeader);
            WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, PurchHeader."Return Shipment No.", PurchHeader."Posting Date");
        end;
        if WhseReceive then begin
            WhseRcptHeader.Get(TempWhseRcptHeader."No.");
            OnBeforeCreatePostedWhseRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, PurchHeader);
            WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, PurchHeader."Return Shipment No.", PurchHeader."Posting Date");
        end;

        OnAfterInsertReturnShipmentHeader(PurchHeader, ReturnShptHeader);
    end;

    local procedure InsertReturnShipmentLine(ReturnShptHeader: Record "Return Shipment Header"; PurchLine: Record "Purchase Line"; CostBaseAmount: Decimal)
    var
        ReturnShptLine: Record "Return Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReturnShipmentLine(ReturnShptHeader, PurchLine, CostBaseAmount, IsHandled);
        if IsHandled then
            exit;

        ReturnShptLine.InitFromPurchLine(ReturnShptHeader, xPurchLine);
        ReturnShptLine."Quantity Invoiced" := -RemQtyToBeInvoiced;
        ReturnShptLine."Qty. Invoiced (Base)" := -RemQtyToBeInvoicedBase;
        ReturnShptLine."Return Qty. Shipped Not Invd." := ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced";
        OnInsertReturnShipmentLineOnAfterReturnShptLineInit(ReturnShptHeader, ReturnShptLine, PurchLine, xPurchLine, CostBaseAmount, WhseShip, WhseReceive);

        CreateWhseLineFromReturnShptLine(ReturnShptLine, PurchLine, CostBaseAmount);

        OnBeforeReturnShptLineInsert(ReturnShptLine, ReturnShptHeader, PurchLine, SuppressCommit);
        ReturnShptLine.Insert(true);
        OnAfterReturnShptLineInsert(
          ReturnShptLine, ReturnShptHeader, PurchLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit,
          TempWhseShptHeader, PurchCrMemoHeader, xPurchLine);

        CheckCertificateOfSupplyStatus(ReturnShptHeader, ReturnShptLine);
    end;

    local procedure CreateWhseLineFromReturnShptLine(var ReturnShptLine: Record "Return Shipment Line"; PurchLine: Record "Purchase Line"; CostBaseAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseLineFromReturnShptLine(ReturnShptLine, PurchLine, CostBaseAmount, IsHandled);
        if IsHandled then
            exit;

        if (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."Return Qty. to Ship" <> 0) then begin
            if WhseShip then
                CreatePostedWhseShptLine(PurchLine, ReturnShptLine);

            if WhseReceive then
                CreatePostedRcptLine(PurchLine, ReturnShptLine);

            ReturnShptLine."Item Shpt. Entry No." := InsertReturnEntryRelation(ReturnShptLine);
            ReturnShptLine."Item Charge Base Amount" := Round(CostBaseAmount / PurchLine.Quantity * ReturnShptLine.Quantity);
        end;
    end;

    local procedure CreatePostedWhseShptLine(PurchLine: Record "Purchase Line"; ReturnShptLine: Record "Return Shipment Line")
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePostedWhseShptLine(PurchLine, ReturnShptLine, IsHandled);
        if IsHandled then
            exit;

        if WhseShptLine.GetWhseShptLine(
            WhseShptHeader."No.", DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.")
        then begin
            OnInsertReturnShipmentLineOnAfterGetWhseShptLine(WhseShptLine, ReturnShptLine);
            WhseShptLine.TestField("Qty. to Ship", ReturnShptLine.Quantity);
            SaveTempWhseSplitSpec(PurchLine);
            OnCreatePostedWhseShptLineOnBeforeCreatePostedShptLine(ReturnShptLine, WhseShptLine, PostedWhseShptHeader);
            WhsePostShpt.CreatePostedShptLine(
              WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
        end;
    end;

    local procedure CreatePostedRcptLine(PurchLine: Record "Purchase Line"; ReturnShptLine: Record "Return Shipment Line")
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePostedRcptLine(PurchLine, ReturnShptLine, IsHandled);
        if IsHandled then
            exit;

        if WhseRcptLine.GetWhseRcptLine(
            WhseRcptHeader."No.", DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.")
        then begin
            WhseRcptLine.TestField("Qty. to Receive", -ReturnShptLine.Quantity);
            SaveTempWhseSplitSpec(PurchLine);
            OnCreatePostedRcptLineOnBeforeCreatePostedRcptLine(ReturnShptLine, WhseRcptLine, PostedWhseRcptHeader);
            WhsePostRcpt.CreatePostedRcptLine(
              WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
        end;
    end;

    local procedure InsertInvoiceHeader(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertInvoiceHeader(PurchHeader, PurchInvHeader, IsHandled, Window, HideProgressWindow, SrcCode, PurchCommentLine, RecordLinkManagement);
        if IsHandled then
            exit;

        PurchInvHeader.Init();
        PurchInvHeader.TransferFields(PurchHeader);

        PurchInvHeader."No." := PurchHeader."Posting No.";
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then begin
            PurchInvHeader."Pre-Assigned No. Series" := '';
            PurchInvHeader."Order No. Series" := PurchHeader."No. Series";
            PurchInvHeader."Order No." := PurchHeader."No.";
        end else begin
            if PurchHeader."Posting No." = '' then
                PurchInvHeader."No." := PurchHeader."No.";
            PurchInvHeader."Pre-Assigned No. Series" := PurchHeader."No. Series";
            PurchInvHeader."Pre-Assigned No." := PurchHeader."No.";
        end;
        if GuiAllowed and not HideProgressWindow then
            Window.Update(1, StrSubstNo(InvoiceNoMsg, PurchHeader."Document Type", PurchHeader."No.", PurchInvHeader."No."));
        PurchInvHeader."Creditor No." := PurchHeader."Creditor No.";
        PurchInvHeader."Payment Reference" := PurchHeader."Payment Reference";
        PurchInvHeader."Payment Method Code" := PurchHeader."Payment Method Code";
        PurchInvHeader."Source Code" := SrcCode;
        PurchInvHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchInvHeader."User ID"));
        PurchInvHeader."No. Printed" := 0;
        OnBeforePurchInvHeaderInsert(PurchInvHeader, PurchHeader, SuppressCommit);

        if PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice then
            PurchInvHeader."Draft Invoice SystemId" := PurchHeader.SystemId;

        if PurchHeader."Remit-to Code" <> '' then
            PurchInvHeader."Remit-to Code" := PurchHeader."Remit-to Code";

        PurchInvHeader.Insert(true);
        OnAfterPurchInvHeaderInsert(PurchInvHeader, PurchHeader, PreviewMode);

        ApprovalsMgmt.PostApprovalEntries(PurchHeader.RecordId, PurchInvHeader.RecordId, PurchInvHeader."No.");
        if PurchSetup."Copy Comments Order to Invoice" then begin
            PurchCommentLine.CopyComments(
              PurchHeader."Document Type".AsInteger(), PurchCommentLine."Document Type"::"Posted Invoice".AsInteger(), PurchHeader."No.", PurchInvHeader."No.");
            IsHandled := false;
            OnInsertInvoiceHeaderOnBeforeCopyLinks(PurchHeader, PurchInvHeader, IsHandled);
            if not IsHandled then
                RecordLinkManagement.CopyLinks(PurchHeader, PurchInvHeader);
        end;

        OnAfterInsertInvoiceHeader(PurchHeader, PurchInvHeader);
    end;

    local procedure InsertCrMemoHeader(var PurchHeader: Record "Purchase Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCommentLine: Record "Purch. Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInserCrMemoHeader(PurchHeader, PurchCrMemoHdr, HideProgressWindow, Window, IsHandled, SrcCode, PurchCrMemoHeader, PurchCommentLine);
        if IsHandled then
            exit;

        PurchCrMemoHdr.Init();
        PurchCrMemoHdr.TransferFields(PurchHeader);
        if PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order" then begin
            PurchCrMemoHdr."No." := PurchHeader."Posting No.";
            PurchCrMemoHdr."Pre-Assigned No. Series" := '';
            PurchCrMemoHdr."Return Order No. Series" := PurchHeader."No. Series";
            PurchCrMemoHdr."Return Order No." := PurchHeader."No.";
            if GuiAllowed and not HideProgressWindow then
                Window.Update(1, StrSubstNo(CreditMemoNoMsg, PurchHeader."Document Type", PurchHeader."No.", PurchCrMemoHdr."No."));
        end else begin
            PurchCrMemoHdr."Pre-Assigned No. Series" := PurchHeader."No. Series";
            PurchCrMemoHdr."Pre-Assigned No." := PurchHeader."No.";
            if PurchHeader."Posting No." <> '' then begin
                PurchCrMemoHdr."No." := PurchHeader."Posting No.";
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(1, StrSubstNo(CreditMemoNoMsg, PurchHeader."Document Type", PurchHeader."No.", PurchCrMemoHdr."No."));
            end;
        end;
        PurchCrMemoHdr."Source Code" := SrcCode;
        PurchCrMemoHdr."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchCrMemoHdr."User ID"));
        PurchCrMemoHdr."No. Printed" := 0;
        PurchCrMemoHdr."Draft Cr. Memo SystemId" := PurchCrMemoHdr.SystemId;
        OnBeforePurchCrMemoHeaderInsert(PurchCrMemoHdr, PurchHeader, SuppressCommit);
        PurchCrMemoHdr.Insert(true);
        OnAfterPurchCrMemoHeaderInsert(PurchCrMemoHdr, PurchHeader, SuppressCommit, PreviewMode);

        ApprovalsMgmt.PostApprovalEntries(PurchHeader.RecordId, PurchCrMemoHdr.RecordId, PurchCrMemoHdr."No.");

        if PurchSetup."Copy Cmts Ret.Ord. to Cr. Memo" then begin
            PurchCommentLine.CopyComments(
              PurchHeader."Document Type".AsInteger(), PurchCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), PurchHeader."No.", PurchCrMemoHdr."No.");
            RecordLinkManagement.CopyLinks(PurchHeader, PurchCrMemoHdr);
        end;

        OnAfterInsertCrMemoHeader(PurchHeader, PurchCrMemoHdr);
    end;

    local procedure InsertSalesShptHeader(var SalesOrderHeader: Record "Sales Header"; var PurchHeader: Record "Purchase Header"; var SalesShptHeader: Record "Sales Shipment Header")
    begin
        SalesShptHeader.Init();
        SalesOrderHeader.CalcFields("Work Description");
        SalesShptHeader.TransferFields(SalesOrderHeader);
        SalesShptHeader."No." := SalesOrderHeader."Shipping No.";
        SalesShptHeader."Order No." := SalesOrderHeader."No.";
        SalesShptHeader."Posting Date" := PurchHeader."Posting Date";
        SalesShptHeader."Document Date" := PurchHeader."Document Date";
        SalesShptHeader."No. Printed" := 0;
        OnBeforeSalesShptHeaderInsert(SalesShptHeader, SalesOrderHeader, SuppressCommit, PurchHeader);
        SalesShptHeader.Insert(true);
        OnAfterSalesShptHeaderInsert(SalesShptHeader, SalesOrderHeader, SuppressCommit, PurchHeader);
    end;

    local procedure InsertSalesShptLine(SalesShptHeader: Record "Sales Shipment Header"; SalesOrderLine: Record "Sales Line"; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; var SalesShptLine: Record "Sales Shipment Line")
    begin
        SalesShptLine.Init();
        SalesShptLine.TransferFields(SalesOrderLine);
        SalesShptLine."Posting Date" := SalesShptHeader."Posting Date";
        SalesShptLine."Document No." := SalesShptHeader."No.";
        SalesShptLine.Quantity := DropShptPostBuffer.Quantity;
        SalesShptLine."Quantity (Base)" := DropShptPostBuffer."Quantity (Base)";
        SalesShptLine."Quantity Invoiced" := 0;
        SalesShptLine."Qty. Invoiced (Base)" := 0;
        SalesShptLine."Order No." := SalesOrderLine."Document No.";
        SalesShptLine."Order Line No." := SalesOrderLine."Line No.";
        SalesShptLine."Qty. Shipped Not Invoiced" :=
          SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced";
        if SalesShptLine.Quantity <> 0 then begin
            SalesShptLine."Item Shpt. Entry No." := DropShptPostBuffer."Item Shpt. Entry No.";
            SalesShptLine."Item Charge Base Amount" := SalesOrderLine."Line Amount";
        end;
        OnBeforeSalesShptLineInsert(SalesShptLine, SalesShptHeader, SalesOrderLine, SuppressCommit, DropShptPostBuffer);
        SalesShptLine.Insert();
        OnAfterSalesShptLineInsert(SalesShptLine, SalesShptHeader, SalesOrderLine, SuppressCommit, DropShptPostBuffer, TempPurchLineGlobal);
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
        PurchInvHeader2: Record "Purch. Inv. Header";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
        ShouldCheckPosted: Boolean;
        ShouldCheckUnposted: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICDocumentDuplicatePosting(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if not PurchHeader.Invoice then
            exit;

        ShouldCheckPosted := PurchHeader."IC Direction" = PurchHeader."IC Direction"::Outgoing;
        OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted(PurchHeader, ShouldCheckPosted);
        if ShouldCheckPosted then begin
            PurchInvHeader2.SetRange("Your Reference", PurchHeader."No.");
            PurchInvHeader2.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
            PurchInvHeader2.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
            if PurchInvHeader2.FindFirst() then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(PostedInvoiceDuplicateQst, PurchInvHeader2."No.", PurchHeader."No."), true)
                then
                    Error('');
        end;

        ShouldCheckUnposted := PurchHeader."IC Direction" = PurchHeader."IC Direction"::Incoming;
        OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted(PurchHeader, ShouldCheckUnposted);
        if ShouldCheckUnposted then begin
            if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then begin
                PurchHeader2.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
                PurchHeader2.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if PurchHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(UnpostedInvoiceDuplicateQst, PurchHeader."No.", PurchHeader2."No."), true)
                    then
                        Error('');
                ICInboxPurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
                ICInboxPurchHeader.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if ICInboxPurchHeader.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(InvoiceDuplicateInboxQst, PurchHeader."No.", ICInboxPurchHeader."No."), true)
                    then
                        Error('');
                PurchInvHeader2.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if PurchInvHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostedInvoiceDuplicateQst, PurchInvHeader2."No.", PurchHeader."No."), true)
                    then
                        Error('');
            end;
            if (PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice) and (PurchHeader."Vendor Order No." <> '') then begin
                PurchHeader2.SetRange("Document Type", PurchHeader."Document Type"::Order);
                PurchHeader2.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if PurchHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(OrderFromSameTransactionQst, PurchHeader2."No.", PurchHeader."No."), true)
                    then
                        Error('');
                ICInboxPurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                ICInboxPurchHeader.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if ICInboxPurchHeader.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(DocumentFromSameTransactionQst, PurchHeader."No.", ICInboxPurchHeader."No."), true)
                    then
                        Error('');
                PurchInvHeader2.SetRange("Vendor Order No.", PurchHeader."Vendor Order No.");
                if PurchInvHeader2.FindFirst() then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostedInvoiceFromSameTransactionQst, PurchInvHeader2."No.", PurchHeader."No."), true)
                    then
                        Error('');
                if (PurchHeader."Your Reference" <> '') and (StrLen(PurchHeader."Your Reference") <= MaxStrLen(PurchInvHeader2."Order No.")) then begin
                    PurchInvHeader2.Reset();
                    PurchInvHeader2.SetRange("Order No.", PurchHeader."Your Reference");
                    PurchInvHeader2.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
                    PurchInvHeader2.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
                    if PurchInvHeader2.FindFirst() then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(PostedInvoiceFromSameTransactionQst, PurchInvHeader2."No.", PurchHeader."No."), true)
                        then
                            Error('');
                end;
            end;
        end;
    end;

    local procedure CheckICPartnerBlocked(PurchHeader: Record "Purchase Header")
    var
        ICPartner: Record "IC Partner";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICPartnerBlocked(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader."Buy-from IC Partner Code" <> '' then
            if ICPartner.Get(PurchHeader."Buy-from IC Partner Code") then
                ICPartner.TestField(Blocked, false);
        if PurchHeader."Pay-to IC Partner Code" <> '' then
            if ICPartner.Get(PurchHeader."Pay-to IC Partner Code") then
                ICPartner.TestField(Blocked, false);
    end;

    local procedure SendICDocument(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        IsHandled: Boolean;
    begin
        OnBeforeSendICDocument(PurchHeader, ModifyHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader."Send IC Document" and (PurchHeader."IC Status" = PurchHeader."IC Status"::New) and (PurchHeader."IC Direction" = PurchHeader."IC Direction"::Outgoing) and
            (PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::"Return Order"])
        then begin
            ICInboxOutboxMgt.SendPurchDoc(PurchHeader, true);
            PurchHeader."IC Status" := PurchHeader."IC Status"::Pending;
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

        if PurchHeader."IC Direction" = PurchHeader."IC Direction"::Incoming then begin
            case PurchHeader."Document Type" of
                PurchHeader."Document Type"::Invoice:
                    HandledICInboxTrans.SetRange("Document No.", PurchHeader."Vendor Invoice No.");
                PurchHeader."Document Type"::Order:
                    HandledICInboxTrans.SetRange("Document No.", PurchHeader."Vendor Order No.");
                PurchHeader."Document Type"::"Credit Memo":
                    HandledICInboxTrans.SetRange("Document No.", PurchHeader."Vendor Cr. Memo No.");
                PurchHeader."Document Type"::"Return Order":
                    HandledICInboxTrans.SetRange("Document No.", PurchHeader."Vendor Order No.");
            end;
            Vendor.Get(PurchHeader."Buy-from Vendor No.");
            HandledICInboxTrans.SetRange("IC Partner Code", Vendor."IC Partner Code");
            HandledICInboxTrans.LockTable();
            if HandledICInboxTrans.FindFirst() then begin
                HandledICInboxTrans.Status := HandledICInboxTrans.Status::Posted;
                HandledICInboxTrans.Modify();
            end;
        end;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeInventoryAdjustment(IsHandled);
        if IsHandled then
            exit;

        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
    end;

#if not CLEAN23
    [Scope('OnPrem')]
    [Obsolete('Replaced by new implementation of Purchase Invoice Posting', '20.0')]
    procedure InsertGST(PurchHeader: Record "Purchase Header"; InvoicePostBuffer: Record "Invoice Post. Buffer"; VATEntryNo: Integer)
    var
        GSTPurchEntry: Record "GST Purchase Entry";
        PurchLine3: Record "Purchase Line";
        PurchInvLine3: Record "Purch. Inv. Line";
        PurchCrMemoLine3: Record "Purch. Cr. Memo Line";
        EntryNo: Integer;
    begin
        if not GLSetup."GST Report" then
            exit;

        if VATEntryNo = 0 then
            exit;

        if GSTPurchEntry.FindLast() then
            EntryNo := GSTPurchEntry."Entry No." + 1
        else
            EntryNo := 1;

        TempInvoicePostBufferGST.Reset();
        if InvoicePostBuffer."Fixed Asset Line No." <> 0 then
            TempInvoicePostBufferGST.SetRange("Fixed Asset Line No.", InvoicePostBuffer."Fixed Asset Line No.");
        TempInvoicePostBufferGST.SetRange(Type, InvoicePostBuffer.Type);
        TempInvoicePostBufferGST.SetRange("G/L Account", InvoicePostBuffer."G/L Account");
        TempInvoicePostBufferGST.SetRange("Gen. Bus. Posting Group", InvoicePostBuffer."Gen. Bus. Posting Group");
        TempInvoicePostBufferGST.SetRange("Gen. Prod. Posting Group", InvoicePostBuffer."Gen. Prod. Posting Group");
        TempInvoicePostBufferGST.SetRange("VAT Bus. Posting Group", InvoicePostBuffer."VAT Bus. Posting Group");
        TempInvoicePostBufferGST.SetRange("VAT Prod. Posting Group", InvoicePostBuffer."VAT Prod. Posting Group");
        TempInvoicePostBufferGST.SetRange("Tax Area Code", InvoicePostBuffer."Tax Area Code");
        TempInvoicePostBufferGST.SetRange("Tax Group Code", InvoicePostBuffer."Tax Group Code");
        TempInvoicePostBufferGST.SetRange("Tax Liable", InvoicePostBuffer."Tax Liable");
        TempInvoicePostBufferGST.SetRange("Use Tax", InvoicePostBuffer."Use Tax");
        TempInvoicePostBufferGST.SetRange("Dimension Set ID", InvoicePostBuffer."Dimension Set ID");
        TempInvoicePostBufferGST.SetRange("Job No.", InvoicePostBuffer."Job No.");
        TempInvoicePostBufferGST.SetRange("Deferral Code", InvoicePostBuffer."Deferral Code");
        if TempInvoicePostBufferGST.FindSet() then
            repeat
                GSTPurchEntry.Init();
                GSTPurchEntry."Entry No." := EntryNo;
                GSTPurchEntry."GST Entry No." := VATEntryNo;

                GSTPurchEntry."Posting Date" := PurchHeader."Posting Date";

                case PurchHeader."Document Type" of
                    PurchHeader."Document Type"::Order,
                    PurchHeader."Document Type"::Invoice:
                        begin
                            GSTPurchEntry."Document Type" := GSTPurchEntry."Document Type"::Invoice;
                            GSTPurchEntry."Document No." := PurchInvHeader."No.";
                            if PurchLine3.Get(PurchHeader."Document Type", PurchHeader."No.", TempInvoicePostBufferGST."Fixed Asset Line No.") then begin
                                GSTPurchEntry."Document Line Code" := PurchLine3."No.";
                                GSTPurchEntry."Document Line Description" := PurchLine3.Description;
                            end else
                                if PurchInvLine3.Get(PurchInvHeader."No.", TempInvoicePostBufferGST."Fixed Asset Line No.") then begin
                                    GSTPurchEntry."Document Line Code" := PurchInvLine3."No.";
                                    GSTPurchEntry."Document Line Description" := PurchInvLine3.Description;
                                end;
                        end;
                    PurchHeader."Document Type"::"Return Order",
                    PurchHeader."Document Type"::"Credit Memo":
                        begin
                            GSTPurchEntry."Document Type" := GSTPurchEntry."Document Type"::"Credit Memo";
                            GSTPurchEntry."Document No." := PurchCrMemoHeader."No.";
                            if PurchLine3.Get(PurchHeader."Document Type", PurchHeader."No.", TempInvoicePostBufferGST."Fixed Asset Line No.") then begin
                                GSTPurchEntry."Document Line Code" := PurchLine3."No.";
                                GSTPurchEntry."Document Line Description" := PurchLine3.Description;
                            end else
                                if PurchCrMemoLine3.Get(PurchCrMemoHeader."No.", TempInvoicePostBufferGST."Fixed Asset Line No.") then begin
                                    GSTPurchEntry."Document Line Code" := PurchCrMemoLine3."No.";
                                    GSTPurchEntry."Document Line Description" := PurchCrMemoLine3.Description;
                                end;
                        end;
                end;
                GSTPurchEntry."Document Line No." := TempInvoicePostBufferGST."Fixed Asset Line No.";
                GSTPurchEntry."Document Line Type" := TempInvoicePostBufferGST.Type;
                GSTPurchEntry."Vendor No." := PurchHeader."Buy-from Vendor No.";
                GSTPurchEntry."Vendor Name" := PurchHeader."Buy-from Vendor Name";
                GSTPurchEntry."GST Entry Type" := GSTPurchEntry."GST Entry Type"::Purchase;
                GSTPurchEntry."GST Base" := TempInvoicePostBufferGST."VAT Base Amount";
                GSTPurchEntry.Amount := TempInvoicePostBufferGST."VAT Amount";
                GSTPurchEntry."VAT Calculation Type" := TempInvoicePostBufferGST."VAT Calculation Type";
                GSTPurchEntry."VAT Bus. Posting Group" := TempInvoicePostBufferGST."VAT Bus. Posting Group";
                GSTPurchEntry."VAT Prod. Posting Group" := TempInvoicePostBufferGST."VAT Prod. Posting Group";
                GSTPurchEntry.Insert();
                EntryNo += 1;
            until TempInvoicePostBufferGST.Next() = 0;
    end;
#endif

#if not CLEAN23
    local procedure FillInvoicePostBufferGST(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostBuffer: Record "Invoice Post. Buffer";
    begin
        if not GLSetup."GST Report" then
            exit;
        GLSetup.Get();
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        Clear(InvoicePostBuffer);
        if PurchLine."Qty. to Invoice" <> 0 then begin
            InvoicePostBuffer.Type := PurchLine.Type;
            InvoicePostBuffer."Fixed Asset Line No." := PurchLine."Line No.";
            if (PurchLine.Type = PurchLine.Type::"G/L Account") or (PurchLine.Type = PurchLine.Type::"Fixed Asset") then begin
                InvoicePostBuffer."Entry Description" := PurchLine.Description;
                InvoicePostBuffer."G/L Account" := PurchLine."No.";
            end else begin
                if PurchLine."Document Type" in [PurchLine."Document Type"::"Return Order", PurchLine."Document Type"::"Credit Memo"] then begin
                    GenPostingSetup.TestField("Purch. Credit Memo Account");
                    InvoicePostBuffer."G/L Account" := GenPostingSetup."Purch. Credit Memo Account";
                end else begin
                    GenPostingSetup.TestField("Purch. Account");
                    InvoicePostBuffer."G/L Account" := GenPostingSetup."Purch. Account";
                end;
                InvoicePostBuffer."Entry Description" := PurchHeader."Posting Description";
            end;
            InvoicePostBuffer."System-Created Entry" := true;
            InvoicePostBuffer."Gen. Bus. Posting Group" := PurchLine."Gen. Bus. Posting Group";
            InvoicePostBuffer."Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
            InvoicePostBuffer."VAT Bus. Posting Group" := PurchLine."VAT Bus. Posting Group";
            InvoicePostBuffer."VAT Prod. Posting Group" := PurchLine."VAT Prod. Posting Group";
            InvoicePostBuffer."VAT Calculation Type" := PurchLine."VAT Calculation Type";
            InvoicePostBuffer."Global Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
            InvoicePostBuffer."Global Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
            InvoicePostBuffer."Job No." := PurchLine."Job No.";
            InvoicePostBuffer.Amount := PurchLine.Amount;
            InvoicePostBuffer."VAT Base Amount" := PurchLine.Amount;
            if PurchLine."Prepayment Line" then begin
                InvoicePostBuffer.Amount := Round(PurchLine."Line Amount", Currency."Amount Rounding Precision");
                InvoicePostBuffer."VAT Base Amount" := Round(PurchLine."VAT Base Amount", Currency."Amount Rounding Precision");
            end;
            InvoicePostBuffer."Amount (ACY)" := PurchLineACY.Amount;
            InvoicePostBuffer."VAT Base Amount (ACY)" := PurchLineACY.Amount;
            InvoicePostBuffer."VAT Difference" := PurchLine."VAT Difference";
            InvoicePostBuffer."VAT %" := PurchLine."VAT %";
            InvoicePostBuffer.Adjustment := PurchHeader.Adjustment;
            InvoicePostBuffer."Deferral Code" := PurchLine."Deferral Code";
            InvoicePostBuffer."BAS Adjustment" := PurchHeader."BAS Adjustment";
            InvoicePostBuffer."Adjustment Applies-to" := PurchHeader."Adjustment Applies-to";
            InvoicePostBuffer."VAT Base (ACY)" := PurchLine."VAT Base (ACY)";
            InvoicePostBuffer."VAT Difference (ACY)" := PurchLine."VAT Difference (ACY)";
            InvoicePostBuffer."Amount Including VAT (ACY)" := PurchLine."Amount Including VAT (ACY)";

            if PurchLine.Type = PurchLine.Type::"Fixed Asset" then begin
                InvoicePostBuffer."FA Posting Date" := PurchLine."FA Posting Date";
                InvoicePostBuffer."FA Posting Type" := PurchLine."FA Posting Type";
                InvoicePostBuffer."Depreciation Book Code" := PurchLine."Depreciation Book Code";
                InvoicePostBuffer."Salvage Value" := PurchLine."Salvage Value";
                InvoicePostBuffer."Depr. until FA Posting Date" := PurchLine."Depr. until FA Posting Date";
                InvoicePostBuffer."Depr. Acquisition Cost" := PurchLine."Depr. Acquisition Cost";
                InvoicePostBuffer."Maintenance Code" := PurchLine."Maintenance Code";
                InvoicePostBuffer."Insurance No." := PurchLine."Insurance No.";
                InvoicePostBuffer."Budgeted FA No." := PurchLine."Budgeted FA No.";
                InvoicePostBuffer."Duplicate in Depreciation Book" := PurchLine."Duplicate in Depreciation Book";
                InvoicePostBuffer."Use Duplication List" := PurchLine."Use Duplication List";
            end;
            case PurchLine."VAT Calculation Type" of
                PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                    if GLSetup.CheckFullGSTonPrepayment(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group")
                       and PurchHeader."Prices Including VAT" and (PurchLine."Prepayment %" <> 0) and not PurchLine."Prepayment Line"
                    then begin
                        if PurchLine."Amount Including VAT" < PurchLine.Amount then begin
                            InvoicePostBuffer."VAT Amount" := Round(PurchLine."Amount Including VAT" -
                                InvoicePostBuffer."VAT Base Amount", Currency."Amount Rounding Precision");
                            InvoicePostBuffer."VAT Amount" := InvoicePostBuffer."VAT Amount" -
                              (InvoicePostBuffer."VAT Amount" * (PurchHeader."VAT Base Discount %" / 100));
                            InvoicePostBuffer."VAT Amount (ACY)" := -Round(InvoicePostBuffer."VAT Base Amount" * PurchLine."VAT %" / 100
                                , Currency."Amount Rounding Precision");
                            InvoicePostBuffer."VAT Amount(ACY)" := -Round(InvoicePostBuffer."VAT Base Amount" * PurchLine."VAT %" / 100
                                , Currency."Amount Rounding Precision");
                        end;
                        if PurchLine."Amount Including VAT" > PurchLine.Amount then begin
                            InvoicePostBuffer."VAT Amount" := Round(PurchLine."Amount Including VAT" -
                                InvoicePostBuffer."VAT Base Amount", Currency."Amount Rounding Precision");
                            InvoicePostBuffer."VAT Amount" := InvoicePostBuffer."VAT Amount" -
                              (InvoicePostBuffer."VAT Amount" * (PurchHeader."VAT Base Discount %" / 100));
                            InvoicePostBuffer."VAT Amount (ACY)" := Round(InvoicePostBuffer."VAT Base Amount" * PurchLine."VAT %" / 100
                                , Currency."Amount Rounding Precision");
                            InvoicePostBuffer."VAT Amount(ACY)" := Round(InvoicePostBuffer."VAT Base Amount" * PurchLine."VAT %" / 100
                                , Currency."Amount Rounding Precision");
                        end;
                    end else begin
                        InvoicePostBuffer."VAT Amount" := PurchLine."Amount Including VAT" - PurchLine.Amount;
                        InvoicePostBuffer."VAT Amount (ACY)" :=
                          PurchLineACY."Amount Including VAT (ACY)" - PurchLineACY.Amount;
                        InvoicePostBuffer."VAT Amount(ACY)" := PurchLine."Amount Including VAT (ACY)" - PurchLine."VAT Base (ACY)";
                    end;
                PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                    ;
                // Reverse Charge VAT is calculated later, based on totals
                PurchLine."VAT Calculation Type"::"Sales Tax":
                    begin
                        if not PurchLine."Use Tax" then begin
                            // Use Tax is calculated later, based on totals
                            InvoicePostBuffer."VAT Amount" := PurchLine."Amount Including VAT" - PurchLine.Amount;
                            InvoicePostBuffer."VAT Amount (ACY)" :=
                              PurchLineACY."Amount Including VAT" - PurchLineACY.Amount;
                            InvoicePostBuffer."VAT Amount(ACY)" := PurchLine."Amount Including VAT (ACY)" - PurchLine."VAT Base (ACY)";
                        end;
                        InvoicePostBuffer."Tax Area Code" := PurchLine."Tax Area Code";
                        InvoicePostBuffer."Tax Liable" := PurchLine."Tax Liable";
                        InvoicePostBuffer."Tax Group Code" := PurchLine."Tax Group Code";
                        InvoicePostBuffer."Use Tax" := PurchLine."Use Tax";
                        InvoicePostBuffer.Quantity := PurchLine."Qty. to Invoice (Base)";
                    end;
            end;
            case PurchSetup."Discount Posting" of
                PurchSetup."Discount Posting"::"Invoice Discounts":
                    begin
                        InvoicePostBuffer.Amount := InvoicePostBuffer.Amount + PurchLine."Inv. Discount Amount";
                        InvoicePostBuffer."Amount (ACY)" :=
                          InvoicePostBuffer."Amount (ACY)" + PurchLineACY."Inv. Discount Amount";
                        if (PurchLine."Inv. Discount Amount" <> 0) or
                           (PurchLineACY."Inv. Discount Amount" <> 0)
                        then
                            GenPostingSetup.TestField("Purch. Inv. Disc. Account");
                    end;
                PurchSetup."Discount Posting"::"Line Discounts":
                    begin
                        InvoicePostBuffer.Amount := InvoicePostBuffer.Amount + PurchLine."Line Discount Amount";
                        InvoicePostBuffer."Amount (ACY)" :=
                          InvoicePostBuffer."Amount (ACY)" + PurchLineACY."Line Discount Amount";
                        if (PurchLine."Line Discount Amount" <> 0) or
                           (PurchLineACY."Line Discount Amount" <> 0)
                        then
                            GenPostingSetup.TestField("Purch. Line Disc. Account");
                    end;
                PurchSetup."Discount Posting"::"All Discounts":
                    begin
                        InvoicePostBuffer.Amount :=
                          InvoicePostBuffer.Amount + PurchLine."Line Discount Amount" + PurchLine."Inv. Discount Amount";
                        InvoicePostBuffer."Amount (ACY)" :=
                          InvoicePostBuffer."Amount (ACY)" +
                          PurchLineACY."Line Discount Amount" + PurchLineACY."Inv. Discount Amount";
                        if (PurchLine."Line Discount Amount" <> 0) or
                           (PurchLineACY."Line Discount Amount" <> 0)
                        then
                            GenPostingSetup.TestField("Purch. Line Disc. Account");
                        if (PurchLine."Inv. Discount Amount" <> 0) or
                           (PurchLineACY."Inv. Discount Amount" <> 0)
                        then
                            GenPostingSetup.TestField("Purch. Inv. Disc. Account");
                    end;
            end;
            UpdateInvoicePostBufferGST(PurchLine, InvoicePostBuffer);
        end;
    end;
#endif

#if not CLEAN23
    local procedure UpdateInvoicePostBufferGST(PurchLine: Record "Purchase Line"; InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        if not GLSetup."GST Report" then
            exit;

        InvoicePostBuffer."Dimension Set ID" := PurchLine."Dimension Set ID";
        DimMgt.UpdateGlobalDimFromDimSetID(InvoicePostBuffer."Dimension Set ID",
          InvoicePostBuffer."Global Dimension 1 Code", InvoicePostBuffer."Global Dimension 2 Code");

        if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then
            InvoicePostBuffer."Fixed Asset Line No." := FALineNo;

        TempInvoicePostBufferGST.Update(InvoicePostBuffer);
    end;
#endif

    [Scope('OnPrem')]
    procedure GetDate(PurchHeader: Record "Purchase Header"): Date
    begin
        if (PurchHeader."Document Type" in [PurchHeader."Document Type"::"Blanket Order", PurchHeader."Document Type"::Quote]) and
           (PurchHeader."Posting Date" = 0D)
        then
            exit(WorkDate());
        exit(PurchHeader."Posting Date");
    end;

    local procedure FillPrepmtLineNoBuf(LineNo: Integer; PrepmtLineNo: Integer)
    begin
        TempPrepmtLineNoBuf."Old Line Number" := LineNo;
        TempPrepmtLineNoBuf."New Line Number" := PrepmtLineNo;
        TempPrepmtLineNoBuf.Insert();
    end;

    local procedure SavePrepmtVATDeducted(PurchLine: Record "Purchase Line")
    begin
        if PurchLine.Type <> PurchLine.Type::" " then
            if PurchLine."Prepayment Line" then begin
                TempPrepmtVATAmtBuf.Get(0, '', PurchLine."Line No.");
                TempPrepmtVATAmtBuf.Amount := -PurchLine."Amount Including VAT" + PurchLine.Amount;
                TempPrepmtVATAmtBuf."VAT Base Amount" := -PurchLine."VAT Base Amount";
                TempPrepmtVATAmtBuf.Modify();
            end else
                if not PurchLine."System-Created Entry" then
                    if TempPrepmtLineNoBuf.Get(PurchLine."Line No.") then
                        if not TempPrepmtVATAmtBuf.Get(0, '', TempPrepmtLineNoBuf."New Line Number") then begin
                            TempPrepmtVATAmtBuf."Line No." := TempPrepmtLineNoBuf."New Line Number";
                            TempPrepmtVATAmtBuf."Prepmt Amt to Deduct" := PurchLine."Prepmt Amt to Deduct";
                            TempPrepmtVATAmtBuf.Insert();
                        end else begin
                            TempPrepmtVATAmtBuf."Prepmt Amt to Deduct" :=
                              TempPrepmtVATAmtBuf."Prepmt Amt to Deduct" + PurchLine."Prepmt Amt to Deduct";
                            TempPrepmtVATAmtBuf.Modify();
                        end;
    end;

    local procedure DividePrepmtVATDeducted(var PurchLine: Record "Purchase Line")
    var
        PrepmtVATReminder: Decimal;
        PrepmtVATBaseReminder: Decimal;
        Ratio: Decimal;
    begin
        if TempPrepmtVATAmtBuf.FindSet() then
            repeat
                TempPrepmtLineNoBuf.SetRange("New Line Number", TempPrepmtVATAmtBuf."Line No.");
                if TempPrepmtLineNoBuf.FindSet() then
                    repeat
                        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", TempPrepmtLineNoBuf."Old Line Number");
                        Ratio := PurchLine."Prepmt Amt to Deduct" / TempPrepmtVATAmtBuf."Prepmt Amt to Deduct";
                        DistributeAmount(
                          TempPrepmtVATAmtBuf.Amount, Ratio,
                          PurchLine."Prepmt. VAT Amount Deducted", PrepmtVATReminder);
                        DistributeAmount(
                          TempPrepmtVATAmtBuf."VAT Base Amount", Ratio,
                          PurchLine."Prepmt. VAT Base Deducted", PrepmtVATBaseReminder);
                        PurchLine.Modify();
                    until TempPrepmtLineNoBuf.Next() = 0;
            until TempPrepmtVATAmtBuf.Next() = 0;
        TempPrepmtVATAmtBuf.DeleteAll();
        TempPrepmtLineNoBuf.DeleteAll();
    end;

    local procedure DistributeAmount(AmountToDistibute: Decimal; Ratio: Decimal; var Amount: Decimal; var Reminder: Decimal)
    var
        DistibutedAmount: Decimal;
        DistibutedAmountRnded: Decimal;
    begin
        DistibutedAmount := Reminder + AmountToDistibute * Ratio;
        DistibutedAmountRnded := Round(DistibutedAmount, Currency."Amount Rounding Precision");
        Reminder := DistibutedAmount - DistibutedAmountRnded;
        Amount := Amount + DistibutedAmountRnded;
    end;

    local procedure UpdateTaxForPostedDoc(var PurchHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        TaxPostBuffer: Record "Tax Posting Buffer";
        TaxManagement: Codeunit TaxInvoiceManagement;
        TaxInvoiceNo: Code[10];
    begin
        if PurchHeader.Invoice or (PurchHeader."Document Type" in [PurchHeader."Document Type"::Invoice, PurchHeader."Document Type"::"Credit Memo"]) then begin
            if GLSetup."Enable Tax Invoices" then
                if PurchHeader."Document Type" in [PurchHeader."Document Type"::"Credit Memo", PurchHeader."Document Type"::"Return Order"] then begin
                    if PurchHeader."Last Posting No." = '' then
                        PurchCrMemoHeader."No." := PurchHeader."No."
                    else
                        PurchCrMemoHeader."No." := PurchHeader."Last Posting No.";
                    PurchCrMemoHeader.SetRecFilter();
                    TaxInvoiceNo := TaxManagement.PurchTaxCrMemoPost(PurchCrMemoHeader);
                end else begin
                    if PurchHeader."Last Posting No." = '' then
                        PurchInvHeader."No." := PurchHeader."No."
                    else
                        PurchInvHeader."No." := PurchHeader."Last Posting No.";
                    PurchInvHeader.SetRecFilter();
                    TaxInvoiceNo := TaxManagement.PurchTaxInvPost(PurchInvHeader);
                end;
            if GLSetup."Enable Tax Invoices" then begin
                TaxManagement.PrintTaxInvoices(false);
                if TaxPostBuffer.FindFirst() then
                    TaxPostBuffer.DeleteAll();
            end;
        end;
    end;

    local procedure CheckTrackingAndWarehouseForReceive(PurchHeader: Record "Purchase Header") Receive: Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        ResetTempLines(TempPurchLine);
        TempPurchLine.SetFilter(Quantity, '<>0');
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
            TempPurchLine.SetFilter("Qty. to Receive", '<>0');
        TempPurchLine.SetRange("Receipt No.", '');
        OnCheckTrackingAndWarehouseForReceiveOnAfterTempPurchLineSetFilters(PurchHeader, TempPurchLine);
        Receive := TempPurchLine.FindFirst();
        WhseReceive := TempWhseRcptHeader.FindFirst();
        WhseShip := TempWhseShptHeader.FindFirst();
        if Receive then begin
            CheckTrackingSpecification(PurchHeader, TempPurchLine);
            if not (WhseReceive or WhseShip or InvtPickPutaway) then
                CheckWarehouse(TempPurchLine);
        end;
        OnAfterCheckTrackingAndWarehouseForReceive(
            PurchHeader, Receive, SuppressCommit, TempWhseShptHeader, TempWhseRcptHeader, TempPurchLine);
        exit(Receive);
    end;

    local procedure CheckTrackingAndWarehouseForShip(PurchHeader: Record "Purchase Header") Ship: Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTrackingAndWarehouseForShip(PurchHeader, TempPurchLineGlobal, Ship, IsHandled);
        if IsHandled then
            exit(Ship);

        ResetTempLines(TempPurchLine);
        TempPurchLine.SetFilter(Quantity, '<>0');
        TempPurchLine.SetFilter("Return Qty. to Ship", '<>0');
        TempPurchLine.SetRange("Return Shipment No.", '');
        OnCheckTrackingAndWarehouseForShipOnAfterTempPurchLineSetFilters(PurchHeader, TempPurchLine);
        Ship := TempPurchLine.FindFirst();
        WhseReceive := TempWhseRcptHeader.FindFirst();
        WhseShip := TempWhseShptHeader.FindFirst();
        if Ship then begin
            CheckTrackingSpecification(PurchHeader, TempPurchLine);
            if not (WhseShip or WhseReceive or InvtPickPutaway) then
                CheckWarehouse(TempPurchLine);
        end;
        OnAfterCheckTrackingAndWarehouseForShip(PurchHeader, Ship, SuppressCommit, TempPurchLine, TempWhseShptHeader, TempWhseRcptHeader);
        exit(Ship);
    end;

    local procedure CheckIfInvPutawayExists(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfInvPutawayExists(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        ResetTempLines(TempPurchLine);
        TempPurchLine.SetFilter(Quantity, '<>0');
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            TempPurchLine.SetFilter("Qty. to Receive", '<>0');
        TempPurchLine.SetRange("Receipt No.", '');
        if TempPurchLine.IsEmpty() then
            exit(false);
        TempPurchLine.FindSet();
        repeat
            if WarehouseActivityLine.ActivityExists(
                    DATABASE::"Purchase Line", TempPurchLine."Document Type".AsInteger(), TempPurchLine."Document No.", TempPurchLine."Line No.", 0,
                    WarehouseActivityLine."Activity Type"::"Invt. Put-away".AsInteger())
            then
                exit(true);
        until TempPurchLine.Next() = 0;
        exit(false);
    end;

    local procedure CheckIfInvPickExists(): Boolean
    var
        TempPurchLine: Record "Purchase Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        ResetTempLines(TempPurchLine);
        TempPurchLine.SetFilter(Quantity, '<>0');
        TempPurchLine.SetFilter("Return Qty. to Ship", '<>0');
        TempPurchLine.SetRange("Return Shipment No.", '');
        if TempPurchLine.IsEmpty() then
            exit(false);
        TempPurchLine.FindSet();
        repeat
            if WarehouseActivityLine.ActivityExists(
                    DATABASE::"Purchase Line", TempPurchLine."Document Type".AsInteger(), TempPurchLine."Document No.", TempPurchLine."Line No.", 0,
                    WarehouseActivityLine."Activity Type"::"Invt. Pick".AsInteger())
            then
                exit(true);
        until TempPurchLine.Next() = 0;
        exit(false);
    end;

    local procedure CheckHeaderPostingType(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckHeaderPostingType(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if not (PurchHeader.Receive or PurchHeader.Invoice or PurchHeader.Ship) then
            Error(ErrorInfo.Create(DocumentErrorsMgt.GetNothingToPostErrorMsg(), true, PurchHeader));
    end;

    local procedure CheckAssociatedOrderLines(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        CheckDimensions: Codeunit "Check Dimensions";
        IsHandled: Boolean;
    begin
        OnBeforeCheckAssociatedOrderLines(PurchHeader);

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter("Sales Order Line No.", '<>0');
        IsHandled := false;
        OnCheckAssociatedOrderLinesOnAfterSetFilters(PurchLine, PurchHeader, IsHandled);
        if IsHandled then
            exit;
        if PurchLine.FindSet() then
            repeat
                AddAssociatedOrderLineToBuffer(PurchHeader, PurchLine, SalesOrderLine, TempSalesLine);
                if PurchHeader.Invoice then begin
                    CheckDropShipmentReceiveInvoice(PurchLine, PurchHeader.Receive);
                    if Abs(PurchLine."Quantity Received" - PurchLine."Quantity Invoiced") < Abs(PurchLine."Qty. to Invoice")
                    then begin
                        PurchLine."Qty. to Invoice" := PurchLine."Quantity Received" - PurchLine."Quantity Invoiced";
                        PurchLine."Qty. to Invoice (Base)" := PurchLine."Qty. Received (Base)" - PurchLine."Qty. Invoiced (Base)";
                    end;
                    IsHandled := false;
                    OnCheckAssocOrderLinesOnBeforeCheckOrderLine(PurchHeader, PurchLine, IsHandled, SalesOrderLine, TempSalesLine);
                    if not IsHandled then
                        if Abs(PurchLine.Quantity - (PurchLine."Qty. to Invoice" + PurchLine."Quantity Invoiced")) <
                           Abs(SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced")
                        then
                            Error(
                                ErrorInfo.Create(
                                    StrSubstNo(CannotInvoiceBeforeAssocSalesOrderErr, PurchLine."Sales Order No."),
                                    true,
                                    PurchHeader));
                end;

                TempSalesHeader."Document Type" := TempSalesHeader."Document Type"::Order;
                TempSalesHeader."No." := PurchLine."Sales Order No.";
                if TempSalesHeader.Insert() then;
            until PurchLine.Next() = 0;

        if TempSalesHeader.FindSet() then
            repeat
                SalesHeader.Get(TempSalesHeader."Document Type"::Order, TempSalesHeader."No.");
                TempSalesLine.SetRange("Document No.", SalesHeader."No.");
                CheckDimensions.CheckSalesDim(SalesHeader, TempSalesLine);
                OnCheckAssociatedOrderLinesOnAfterCheckDimensions(PurchHeader, SalesHeader, PurchLine, TempSalesLine);
            until TempSalesHeader.Next() = 0;
    end;

    local procedure AddAssociatedOrderLineToBuffer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddAssociatedOrderLineToBuffer(PurchHeader, PurchLine, SalesOrderLine, TempSalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesOrderLine.Get(
            SalesOrderLine."Document Type"::Order, PurchLine."Sales Order No.", PurchLine."Sales Order Line No.");
        TempSalesLine := SalesOrderLine;
        TempSalesLine.Insert();
    end;

    local procedure CheckDropShipmentReceiveInvoice(PurchLine: Record "Purchase Line"; Receive: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDropShipmentReceiveInvoice(PurchLine, IsHandled);
        if IsHandled then
            exit;

        if Receive and (PurchLine."Qty. to Invoice" <> 0) and (PurchLine."Qty. to Receive" <> 0) then
            Error(DropShipmentErr);
    end;

    local procedure RunItemJnlPostLine(var ItemJnlLineToPost: Record "Item Journal Line")
    begin
        ItemJnlPostLine.RunWithCheck(ItemJnlLineToPost);
    end;

    local procedure RunItemJnlPostLineWithReservation(var ItemJnlLineToPost: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
        OnBeforeRunItemJnlPostLineWithReservation(ItemJnlLineToPost);
        ItemJnlPostLine.RunPostWithReservation(ItemJnlLineToPost, ReservationEntry);
    end;

    local procedure PostCombineSalesOrderShipment(var PurchHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCommentLine: Record "Sales Comment Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostCombineSalesOrderShipment(PurchHeader, TempDropShptPostBuffer, SalesShptHeader, ItemLedgShptEntryNo, ItemJnlPostLine, TempTrackingSpecification, TempHandlingSpecification, IsHandled);
        if not IsHandled then begin
            SalesSetup.Get();
            ArchiveSalesOrders(TempDropShptPostBuffer);
            if TempDropShptPostBuffer.FindSet() then begin
                repeat
                    SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, TempDropShptPostBuffer."Order No.");
                    OnPostCombineSalesOrderShipmentOnBeforeInsertSalesShptHeader(TempDropShptPostBuffer, SalesOrderHeader);
                    InsertSalesShptHeader(SalesOrderHeader, PurchHeader, SalesShptHeader);
                    ApprovalsMgmt.PostApprovalEntries(PurchHeader.RecordId, SalesShptHeader.RecordId, SalesShptHeader."No.");
                    IsHandled := false;
                    OnPostCombineSalesOrderShipmentOnBeforeCopyComments(PurchHeader, TempDropShptPostBuffer, SalesShptHeader, IsHandled);
                    if not IsHandled then
                        if SalesSetup."Copy Comments Order to Shpt." then begin
                            SalesCommentLine.CopyComments(
                              SalesOrderHeader."Document Type".AsInteger(), SalesCommentLine."Document Type"::Shipment.AsInteger(),
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
                        OnPostCombineSalesOrderShipmentOnAfterUpdateSalesOrderLine(SalesShptHeader, SalesOrderHeader, SalesOrderLine, SalesShptLine);
                        ServItemMgt.CreateServItemOnSalesLineShpt(SalesOrderHeader, SalesOrderLine, SalesShptLine);
                        OnPostCombineSalesOrderShipmentOnBeforeUpdateBlanketOrderLine(SalesOrderLine, SalesShptLine);
                        SalesPost.UpdateBlanketOrderLine(SalesOrderLine, true, false, false);
                        OnPostCombineSalesOrderShipmentOnAfterUpdateBlanketOrderLine(PurchHeader, TempDropShptPostBuffer, SalesOrderLine, SalesOrderHeader, SalesShptLine, SalesShptHeader);

                        SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
                        SalesOrderLine.SetRange("Document No.", TempDropShptPostBuffer."Order No.");
                        SalesOrderLine.SetRange("Attached to Line No.", TempDropShptPostBuffer."Order Line No.");
                        SalesOrderLine.SetRange(Type, SalesOrderLine.Type::" ");
                        if SalesOrderLine.FindSet() then
                            repeat
                                SalesShptLine.Init();
                                SalesShptLine.TransferFields(SalesOrderLine);
                                SalesShptLine."Document No." := SalesShptHeader."No.";
                                SalesShptLine."Order No." := SalesOrderLine."Document No.";
                                SalesShptLine."Order Line No." := SalesOrderLine."Line No.";
                                OnBeforeSalesShptLineInsert(SalesShptLine, SalesShptHeader, SalesOrderLine, SuppressCommit, TempDropShptPostBuffer);
                                SalesShptLine.Insert();
                                OnAfterSalesShptLineInsert(SalesShptLine, SalesShptHeader, SalesOrderLine, SuppressCommit, TempDropShptPostBuffer, TempPurchLineGlobal);
                            until SalesOrderLine.Next() = 0;
                        OnPostCombineSalesOrderShipmentOnAfterProcessDropShptPostBuffer(TempDropShptPostBuffer, PurchRcptHeader, SalesShptLine, TempTrackingSpecification);
                    until TempDropShptPostBuffer.Next() = 0;
                    TempDropShptPostBuffer.SetRange("Order No.");
                    OnAfterInsertCombinedSalesShipment(SalesShptHeader);
                until TempDropShptPostBuffer.Next() = 0;
            end;
        end;
        OnAfterPostCombineSalesOrderShipment(PurchHeader, TempDropShptPostBuffer);
    end;

#if not CLEAN23
    local procedure PostInvoicePostBufferLine(PurchHeader: Record "Purchase Header"; InvoicePostBuffer: Record "Invoice Post. Buffer") GLEntryNo: Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        OnBeforePostInvoicePostBufferLine(PurchHeader, InvoicePostBuffer);
        InitNewGenJnlLineFromPostInvoicePostBufferLine(GenJnlLine, PurchHeader, InvoicePostBuffer);

        GenJnlLine.CopyDocumentFields(GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, '');
        GenJnlLine.CopyFromPurchHeader(PurchHeader);
        GenJnlLine."Vendor Exchange Rate (ACY)" := PurchHeader."Vendor Exchange Rate (ACY)";
        GenJnlLine.Adjustment := PurchHeader.Adjustment;
        GenJnlLine."BAS Adjustment" := PurchHeader."BAS Adjustment";
        GenJnlLine."Adjustment Applies-to" := PurchHeader."Adjustment Applies-to";
        GenJnlLine."WHT Business Posting Group" := TempPurchLineGlobal."WHT Business Posting Group";
        GenJnlLine."WHT Product Posting Group" := TempPurchLineGlobal."WHT Product Posting Group";
        InvoicePostBuffer.CopyToGenJnlLine(GenJnlLine);
        OnPostInvoicePostBufferLineOnAfterCopyFromInvoicePostBuffer(GenJnlLine, PurchHeader, TempPurchLineGlobal);
        GenJnlLine."VAT Base (ACY)" := InvoicePostBuffer."VAT Base (ACY)";
        GenJnlLine."VAT Amount (ACY)" := InvoicePostBuffer."VAT Amount(ACY)";
        GenJnlLine."VAT Difference (ACY)" := InvoicePostBuffer."VAT Difference (ACY)";
        GenJnlLine."Amount Including VAT (ACY)" := InvoicePostBuffer."Amount Including VAT (ACY)";
        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalPurchLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            PurchHeader.GetUseDate(), PurchHeader."Currency Code", TotalPurchLine."Pmt. Discount Amount", PurchHeader."Currency Factor");

        if InvoicePostBuffer.Type <> InvoicePostBuffer.Type::"Prepmt. Exch. Rate Difference" then
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
        if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
            case InvoicePostBuffer."FA Posting Type" of
                InvoicePostBuffer."FA Posting Type"::"Acquisition Cost":
                    GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::"Acquisition Cost";
                InvoicePostBuffer."FA Posting Type"::Maintenance:
                    GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Maintenance;
                InvoicePostBuffer."FA Posting Type"::Appreciation:
                    GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Appreciation;
            end;
            InvoicePostBuffer.CopyToGenJnlLineFA(GenJnlLine);
        end;

        OnBeforePostInvPostBuffer(GenJnlLine, InvoicePostBuffer, PurchHeader, GenJnlPostLine, PreviewMode, SuppressCommit, GenJnlLineDocNo);
        GLEntryNo := RunGenJnlPostLine(GenJnlLine);
        OnAfterPostInvPostBuffer(GenJnlLine, InvoicePostBuffer, PurchHeader, GLEntryNo, SuppressCommit, GenJnlPostLine);
    end;
#endif

#if not CLEAN23
    local procedure InitNewGenJnlLineFromPostInvoicePostBufferLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitNewGenJnlLineFromPostInvoicePostBufferLine(GenJnlLine, PurchHeader, InvoicePostBuffer, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", InvoicePostBuffer."Entry Description",
            InvoicePostBuffer."Global Dimension 1 Code", InvoicePostBuffer."Global Dimension 2 Code",
            InvoicePostBuffer."Dimension Set ID", PurchHeader."Reason Code");
    end;
#endif

    local procedure FindTempItemChargeAssgntPurch(PurchLineNo: Integer): Boolean
    begin
        ClearItemChargeAssgntFilter();
        TempItemChargeAssgntPurch.SetCurrentKey("Applies-to Doc. Type");
        TempItemChargeAssgntPurch.SetRange("Document Line No.", PurchLineNo);
        exit(TempItemChargeAssgntPurch.FindSet());
    end;

#if not CLEAN23
    local procedure FillDeferralPostingBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; InvoicePostBuffer: Record "Invoice Post. Buffer"; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        if PurchLine."Deferral Code" <> '' then begin
            DeferralTemplate.Get(PurchLine."Deferral Code");

            if TempDeferralHeader.Get(
                "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
            then begin
                if TempDeferralHeader."Amount to Defer" <> 0 then begin
                    DeferralUtilities.FilterDeferralLines(
                      TempDeferralLine, "Deferral Document Type"::Purchase.AsInteger(), '', '',
                      PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
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
                    if TempDeferralLine.FindSet() then
                        repeat
                            if (TempDeferralLine."Amount (LCY)" <> 0) or (TempDeferralLine.Amount <> 0) then begin
                                DeferralPostBuffer.PreparePurch(PurchLine, GenJnlLineDocNo);
                                DeferralPostBuffer.InitFromDeferralLine(TempDeferralLine);
                                if PurchLine.IsCreditDocType() then
                                    DeferralPostBuffer.ReverseAmounts();
                                DeferralPostBuffer."G/L Account" := PurchAccount;
                                DeferralPostBuffer."Deferral Account" := DeferralAccount;
                                DeferralPostBuffer."Period Description" := DeferralTemplate."Period Description";
                                DeferralPostBuffer."Deferral Line No." := InvDefLineNo;
                                OnFillDeferralPostingBufferOnAfterInitFromDeferralLine(DeferralPostBuffer, TempDeferralLine, PurchLine, DeferralTemplate);
                                DeferralPostBuffer.Update(DeferralPostBuffer, InvoicePostBuffer);
                            end else
                                Error(ZeroDeferralAmtErr, PurchLine."No.", PurchLine."Deferral Code");

                        until TempDeferralLine.Next() = 0

                    else
                        Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code");
                end else
                    Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code")
            end else
                Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code")
        end;
    end;
#endif

#if not CLEAN23
    local procedure GetAmountsForDeferral(PurchLine: Record "Purchase Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        if PurchLine."Deferral Code" <> '' then begin
            DeferralTemplate.Get(PurchLine."Deferral Code");
            DeferralTemplate.TestField("Deferral Account");
            DeferralAccount := DeferralTemplate."Deferral Account";

            if TempDeferralHeader.Get(
                "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
            then begin
                AmtToDeferACY := TempDeferralHeader."Amount to Defer";
                AmtToDefer := TempDeferralHeader."Amount to Defer (LCY)";
            end;

            if PurchLine.IsCreditDocType() then begin
                AmtToDefer := -AmtToDefer;
                AmtToDeferACY := -AmtToDeferACY;
            end
        end else begin
            AmtToDefer := 0;
            AmtToDeferACY := 0;
            DeferralAccount := '';
        end;
    end;
#endif

    local procedure CheckMandatoryHeaderFields(var PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMandatoryFields(PurchaseHeader, IsHandled);
        if not IsHandled then begin
            PurchaseHeader.TestField("Document Type");
            PurchaseHeader.TestField("Buy-from Vendor No.");
            PurchaseHeader.TestField("Pay-to Vendor No.");
            PurchaseHeader.TestField("Posting Date");
            PurchaseHeader.TestField("Document Date");
        end;

        OnAfterCheckMandatoryFields(PurchaseHeader, SuppressCommit);
    end;

#if not CLEAN23
    local procedure InitVATAmounts(PurchLine: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalNonDedVATBase: Decimal; var TotalNonDedVATAmount: Decimal; var TotalNonDedVATBaseACY: Decimal; var TotalNonDedVATAmountACY: Decimal; var TotalNonDedVATDiff: Decimal)
    begin
        TotalVAT := PurchLine."Amount Including VAT" - PurchLine.Amount;
        TotalVATACY := PurchLineACY."Amount Including VAT" - PurchLineACY.Amount;
        TotalAmount := PurchLine.Amount;
        TotalAmountACY := PurchLineACY.Amount;
        NonDeductibleVAT.Init(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, PurchLine, PurchLineACY);
        OnAfterInitVATAmounts(PurchLine, PurchLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
    end;
#endif

#if not CLEAN23
    local procedure InitVATBase(PurchLine: Record "Purchase Line"; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        TotalVATBase := PurchLine."VAT Base Amount";
        TotalVATBaseACY := PurchLineACY."VAT Base Amount";
        OnAfterInitVATBase(PurchLine, PurchLineACY, TotalVATBase, TotalVATBaseACY);
    end;
#endif

#if not CLEAN23
    local procedure InitAmounts(PurchLine: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var TotalNonDedVATBase: Decimal; var TotalNonDedVATAmount: Decimal; var TotalNonDedVATBaseACY: Decimal; var TotalNonDedVATAmountACY: Decimal; var TotalNonDedVATDiff: Decimal)
    begin
        InitVATAmounts(PurchLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff);
        GetAmountsForDeferral(PurchLine, AmtToDefer, AmtToDeferACY, DeferralAccount);
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Replaced by local procedure CalcInvoiceDiscountPosting in codeunit Purch. Post Invoice', '20.0')]
    procedure CalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
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
        OnAfterCalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostBuffer);
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Replaced by local procedure CalcLineDiscountPosting in codeunit Purch. Post Invoice', '20.0')]
    procedure CalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostBuffer, IsHandled);
        if IsHandled then
            exit;

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
#endif

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
        PostingDate, VATDate : Date;
        ModifyHeader: Boolean;
        PostingDateExists: Boolean;
        VATDateExists: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        ReplaceVATDate: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeValidatePostingAndDocumentDate(PurchaseHeader, SuppressCommit);

        IsHandled := false;
        OnValidatePostingAndDocumentDateOnSetPostingDateExists(PurchaseHeader, SuppressCommit, PostingDateExists, ReplacePostingDate, PostingDate, IsHandled);
        if not IsHandled then
            PostingDateExists :=
                BatchProcessingMgt.GetBooleanParameter(
                    PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate) and
                BatchProcessingMgt.GetBooleanParameter(
                    PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate) and
                BatchProcessingMgt.GetDateParameter(
                    PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Posting Date", PostingDate);
        OnValidatePostingAndDocumentDateOnAfterCalcPostingDateExists(PurchaseHeader, PostingDateExists, ReplacePostingDate, PostingDate, ReplaceDocumentDate, ModifyHeader);

        VATDateExists := BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDate);
        BatchProcessingMgt.GetDateParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"VAT Date", VATDate);

        if PostingDateExists and (ReplacePostingDate or (PurchaseHeader."Posting Date" = 0D)) then begin
            PurchaseHeader."Posting Date" := PostingDate;
            PurchaseHeader.Validate("Currency Code");
            ModifyHeader := true;
        end;

        IsHandled := false;
        OnValidatePostingAndDocumentDateOnBeforeSetReplaceDocumentDate(PurchaseHeader, PostingDate, ReplaceDocumentDate, ModifyHeader, IsHandled);
        if not IsHandled then
            if PostingDateExists and ReplaceDocumentDate and (PurchaseHeader."Document Date" <> PostingDate) then begin
                PurchaseHeader.SetReplaceDocumentDate();
                PurchaseHeader.Validate("Document Date", PostingDate);
                ModifyHeader := true;
            end;

        if VATDateExists and (ReplaceVATDate) then begin
            PurchaseHeader."VAT Reporting Date" := VATDate;
            ModifyHeader := true;
        end;

        OnValidatePostingAndDocumentDateOnBeforePurchaseHeaderModify(PurchaseHeader, ModifyHeader);
        if ModifyHeader then
            PurchaseHeader.Modify();

        OnAfterValidatePostingAndDocumentDate(PurchaseHeader, SuppressCommit, PreviewMode);
    end;

    local procedure CheckExternalDocumentNumber(var VendLedgEntry: Record "Vendor Ledger Entry"; var PurchaseHeader: Record "Purchase Header")
    var
        VendorMgt: Codeunit "Vendor Mgt.";
        Handled: Boolean;
    begin
        OnBeforeCheckExternalDocumentNumber(VendLedgEntry, PurchaseHeader, Handled, GenJnlLineDocType.AsInteger(), GenJnlLineExtDocNo, SrcCode, GenJnlLineDocType, GenJnlLineDocNo, GenJnlPostLine, TotalPurchLine, TotalPurchLineLCY);
        if Handled then
            exit;

        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("External Document No.");
        VendorMgt.SetFilterForExternalDocNo(
            VendLedgEntry, GenJnlLineDocType, GenJnlLineExtDocNo, PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Document Date");
        OnCheckExternalDocumentNumberOnAfterSetFilters(VendLedgEntry, PurchaseHeader);
        if VendLedgEntry.FindFirst() then
            Error(
              PurchaseAlreadyExistsErr, VendLedgEntry."Document Type", GenJnlLineExtDocNo);
    end;

    local procedure CheckWHTApplication(PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader.IsCreditDocType() then begin
            if (PurchHeader."Applies-to Doc. Type" = PurchHeader."Applies-to Doc. Type"::Invoice) and (PurchHeader."Applies-to Doc. No." <> '') then
                WHTManagement.CheckApplicationPurchWHT(PurchHeader);

            if ((PurchHeader."Applies-to Doc. Type" = PurchHeader."Applies-to Doc. Type"::Refund) and (PurchHeader."Applies-to Doc. No." <> '')) or
               (PurchHeader."Applies-to ID" <> '')
            then
                WHTManagement.CheckApplicationPurchWHT(PurchHeader);
        end;

        if PurchHeader."Document Type" in [PurchHeader."Document Type"::Invoice] then begin
            if (PurchHeader."Applies-to Doc. Type" = PurchHeader."Applies-to Doc. Type"::"Credit Memo") and (PurchHeader."Applies-to Doc. No." <> '') then
                WHTManagement.CheckApplicationPurchWHT(PurchHeader);

            if ((PurchHeader."Applies-to Doc. Type" = PurchHeader."Applies-to Doc. Type"::Payment) and (PurchHeader."Applies-to Doc. No." <> '')) or
               (PurchHeader."Applies-to ID" <> '')
            then
                WHTManagement.CheckApplicationPurchWHT(PurchHeader);
        end;
    end;

    local procedure CalcWHTAmountOnPrepayment(DocNo: Code[20]): Decimal
    var
        PurchInvHeaderPrePmt: Record "Purch. Inv. Header";
        WHTEntryPrePmt: Record "WHT Entry";
        TotalWHTAmtToBeDeducted: Decimal;
    begin
        PurchInvHeaderPrePmt.Reset();
        PurchInvHeaderPrePmt.SetRange("Prepayment Order No.", DocNo);
        PurchInvHeaderPrePmt.SetRange("Prepayment Invoice", true);
        if PurchInvHeaderPrePmt.FindSet() then
            repeat
                WHTEntryPrePmt.SetRange("Document Type", WHTEntryPrePmt."Document Type"::Invoice);
                WHTEntryPrePmt.SetRange("Document No.", PurchInvHeaderPrePmt."No.");
                if WHTEntryPrePmt.FindSet() then
                    repeat
                        TotalWHTAmtToBeDeducted := TotalWHTAmtToBeDeducted + WHTEntryPrePmt."Unrealized Amount";
                    until WHTEntryPrePmt.Next() = 0;
            until PurchInvHeaderPrePmt.Next() = 0;
        exit(TotalWHTAmtToBeDeducted);
    end;

    local procedure PostWHT(PurchHeader: Record "Purchase Header"; TotalInvAmount: Decimal; var TotalWHTAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        WHTPostingSetup: Record "WHT Posting Setup";
        GLReg: Record "G/L Register";
        InvoiceWHTEntryExists: Boolean;
    begin
        if TempPurchLineGlobal.Type <> TempPurchLineGlobal.Type::" " then
            WHTPostingSetup.Get(TempPurchLineGlobal."WHT Business Posting Group", TempPurchLineGlobal."WHT Product Posting Group");
        if PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice] then begin
            if TotalInvAmount >= WHTPostingSetup."WHT Minimum Invoice Amount" then
                WHTManagement.InsertVendInvoiceWHT(PurchInvHeader);
            WHTEntry.Reset();
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);
            WHTEntry.SetRange("Document No.", PurchInvHeader."No.");
            if WHTEntry.Find('-') then
                repeat
                    WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                    if (WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::Payment) and
                       (WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::" ")
                    then
                        if WHTEntry.Amount <> 0 then begin
                            TotalWHTAmount := TotalWHTAmount + WHTEntry.Amount;
                            InsertGenJournalWHT(PurchHeader, GenJnlLine, WHTPostingSetup.GetPayableWHTAccount());
                            GenJnlPostLine.IncreaseWHTEntryNo();
                            GenJnlPostLine.Run(GenJnlLine);
                        end;
                until WHTEntry.Next() = 0;
            GenJnlPostLine.GetGLReg(GLReg);
            if WHTEntry.Find('+') then
                InvoiceWHTEntryExists := true;
        end else begin
            WHTManagement.InsertVendCreditWHT(PurchCrMemoHeader, PurchHeader."Applies-to ID");
            WHTEntry.Reset();
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
            WHTEntry.SetRange("Document No.", PurchCrMemoHeader."No.");
            if WHTEntry.Find('-') then
                repeat
                    WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                    if (WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::Payment) and
                       (WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::" ")
                    then
                        if WHTEntry.Amount <> 0 then begin
                            TotalWHTAmount := TotalWHTAmount + WHTEntry.Amount;
                            InsertGenJournalWHT(PurchHeader, GenJnlLine, WHTPostingSetup.GetPayableWHTAccount());
                            GenJnlPostLine.IncreaseWHTEntryNo();
                            GenJnlPostLine.RunWithCheck(GenJnlLine);
                        end;
                until WHTEntry.Next() = 0;
            GenJnlPostLine.GetGLReg(GLReg);
            if WHTEntry.Find('+') then
                InvoiceWHTEntryExists := true
        end;

        TotalWHTAmount := TotalWHTAmount - CalcWHTAmountOnPrepayment(PurchHeader."No.");
        if (TotalWHTAmount <> 0) and InvoiceWHTEntryExists then
            if PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo" then begin
                if PurchSetup."Print WHT Docs. on Credit Memo" then
                    WHTManagement.PrintWHTSlips(GLReg, false);
            end else
                WHTManagement.PrintWHTSlips(GLReg, false);
    end;

#if not CLEAN23
    local procedure PostInvoicePostingBuffer(PurchHeader: Record "Purchase Header"; var TotalAmount: Decimal)
    var
        LineCount: Integer;
        GLEntryNo: Integer;
    begin
        OnBeforePostInvoicePostBuffer(PurchHeader, TempInvoicePostBuffer, TotalPurchLine, TotalPurchLineLCY);

        LineCount := 0;

        CalculateVATAmountInBuffer(PurchHeader, TempInvoicePostBuffer);

        if TempInvoicePostBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                TempInvoicePostBuffer.ApplyRoundingForFinalPosting();

                GLEntryNo := PostInvoicePostBufferLine(PurchHeader, TempInvoicePostBuffer);

                if (TempInvoicePostBuffer."Job No." <> '') and
                   (TempInvoicePostBuffer.Type = TempInvoicePostBuffer.Type::"G/L Account")
                then
                    JobPostLine.PostPurchaseGLAccounts(TempInvoicePostBuffer, GLEntryNo);

                InsertGST(PurchHeader, TempInvoicePostBuffer, GenJnlPostLine.GetVATEntryNo());
            until TempInvoicePostBuffer.Next(-1) = 0;

        TempInvoicePostBuffer.CalcSums(Amount);
        TotalAmount := TempInvoicePostBuffer.Amount;

        TempInvoicePostBuffer.DeleteAll();
    end;
#endif

#if not CLEAN23
    local procedure CalculateVATAmountInBuffer(PurchHeader: Record "Purchase Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    var
        CurrencyDocument: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
        RemainderInvoicePostBuffer: Record "Invoice Post. Buffer";
        VATBaseAmount: Decimal;
        VATBaseAmountACY: Decimal;
        VATAmount: Decimal;
        VATAmountACY: Decimal;
        VATAmountRemainder: Decimal;
        VATAmountACYRemainder: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateVATAmountInBuffer(PurchHeader, TempInvoicePostBuffer, IsHandled);
        if IsHandled then
            exit;

        VATAmountRemainder := 0;
        VATAmountACYRemainder := 0;

        CurrencyDocument.Initialize(PurchHeader."Currency Code");

        if TempInvoicePostBuffer.FindSet() then
            repeat
                case TempInvoicePostBuffer."VAT Calculation Type" of
                    TempInvoicePostBuffer."VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            VATPostingSetup.Get(TempInvoicePostBuffer."VAT Bus. Posting Group", TempInvoicePostBuffer."VAT Prod. Posting Group");
                            IsHandled := false;
                            OnPostInvoicePostingBufferOnAfterVATPostingSetupGet(VATPostingSetup, TempInvoicePostBuffer, IsHandled);
                            if not IsHandled then begin
                                VATBaseAmount := TempInvoicePostBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100);
                                VATBaseAmountACY := TempInvoicePostBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100);

                                if PurchHeader."Currency Code" <> '' then
                                    VATBaseAmount := CurrExchRate.ExchangeAmtLCYToFCY(
                                        PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                                        VATBaseAmount, PurchHeader."Currency Factor");

                                VATAmount := VATBaseAmount * VATPostingSetup."VAT %" / 100;
                                VATAmountACY := VATBaseAmountACY * VATPostingSetup."VAT %" / 100;

                                OnCalculateVATAmountInBufferOnBeforeTempInvoicePostBufferAssign(VATAmount, VATAmountACY, TempInvoicePostBuffer);
                                TempInvoicePostBufferReverseCharge := TempInvoicePostBuffer;
                                if TempInvoicePostBufferReverseCharge.Find() then begin
                                    VATAmountRemainder += VATAmount;
                                    TempInvoicePostBuffer."VAT Amount" := Round(VATAmountRemainder, CurrencyDocument."Amount Rounding Precision");
                                    VATAmountRemainder -= TempInvoicePostBuffer."VAT Amount";

                                    if PurchHeader."Currency Code" <> '' then
                                        TempInvoicePostBuffer."VAT Amount" := Round(
                                            CurrExchRate.ExchangeAmtFCYToLCY(
                                                PurchHeader.GetUseDate(), PurchHeader."Currency Code", TempInvoicePostBuffer."VAT Amount", PurchHeader."Currency Factor"));

                                    VATAmountACYRemainder += VATAmountACY;
                                    TempInvoicePostBuffer."VAT Amount (ACY)" := Round(VATAmountACYRemainder, Currency."Amount Rounding Precision");
                                    VATAmountACYRemainder -= TempInvoicePostBuffer."VAT Amount (ACY)";

                                    TempInvoicePostBuffer."VAT Base Amount" := Round(TempInvoicePostBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100));
                                    TempInvoicePostBuffer."VAT Base Amount (ACY)" := Round(TempInvoicePostBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100));
                                end else begin
                                    if PurchHeader."Currency Code" <> '' then
                                        VATAmount := Round(
                                            CurrExchRate.ExchangeAmtFCYToLCY(PurchHeader.GetUseDate(), PurchHeader."Currency Code", VATAmount, PurchHeader."Currency Factor"))
                                    else
                                        VATAmount := Round(VATAmount);

                                    TempInvoicePostBuffer."VAT Amount" := VATAmount;
                                    TempInvoicePostBuffer."VAT Amount (ACY)" := Round(VATAmountACY, Currency."Amount Rounding Precision");

                                    TempInvoicePostBuffer."VAT Base Amount" := Round(TempInvoicePostBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100));
                                    TempInvoicePostBuffer."VAT Base Amount (ACY)" := Round(TempInvoicePostBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100));
                                end;
                                TempInvoicePostBuffer."VAT Base (ACY)" := 0;
#if not CLEAN23
                                NonDeductibleVAT.Update(
                                    TempInvoicePostBuffer, RemainderInvoicePostBuffer, CurrencyDocument."Amount Rounding Precision");
#endif                                    
                                TempInvoicePostBuffer.Modify();
                            end;
                        end;
                    TempInvoicePostBuffer."VAT Calculation Type"::"Sales Tax":
                        if TempInvoicePostBuffer."Use Tax" then begin
                            TempInvoicePostBuffer."VAT Amount" := Round(SalesTaxCalculate.CalculateTax(
                                TempInvoicePostBuffer."Tax Area Code", TempInvoicePostBuffer."Tax Group Code",
                                TempInvoicePostBuffer."Tax Liable", PurchHeader."Posting Date",
                                TempInvoicePostBuffer.Amount, TempInvoicePostBuffer.Quantity, 0));
                            if GLSetup."Additional Reporting Currency" <> '' then
                                TempInvoicePostBuffer."VAT Amount (ACY)" := CurrExchRate.ExchangeAmtLCYToFCY(
                                    PurchHeader."Posting Date", GLSetup."Additional Reporting Currency",
                                    TempInvoicePostBuffer."VAT Amount", 0);
                        end;
                end;

            until TempInvoicePostBuffer.Next() = 0;
    end;
#endif

    local procedure PostItemTracking(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingSpecificationExists: Boolean)
    var
        QtyToInvoiceBaseInTrackingSpec: Decimal;
        IsHandled: Boolean;
        ShouldProcessShipment: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemTracking(
            PurchHeader, PurchLine, TempTrackingSpecification, TrackingSpecificationExists,
            PreciseTotalChargeAmt, PreciseTotalChargeAmtACY, RoundedPrevTotalChargeAmt, RoundedPrevTotalChargeAmtACY, IsHandled);
        if IsHandled then
            exit;

        if TrackingSpecificationExists then begin
            TempTrackingSpecification.CalcSums("Qty. to Invoice (Base)");
            QtyToInvoiceBaseInTrackingSpec := TempTrackingSpecification."Qty. to Invoice (Base)";
            if not TempTrackingSpecification.FindFirst() then
                TempTrackingSpecification.Init();
        end;

        PreciseTotalChargeAmt := 0;
        PreciseTotalChargeAmtACY := 0;
        RoundedPrevTotalChargeAmt := 0;
        RoundedPrevTotalChargeAmtACY := 0;

        ShouldProcessShipment := PurchHeader.IsCreditDocType();
        OnPostItemTrackingOnAfterCalcShouldProcessShipment(PurchHeader, PurchLine, ShouldProcessShipment);
        if ShouldProcessShipment then begin
            if (Abs(RemQtyToBeInvoiced) > Abs(PurchLine."Return Qty. to Ship")) or
               (Abs(RemQtyToBeInvoiced) >= Abs(QtyToInvoiceBaseInTrackingSpec)) and (QtyToInvoiceBaseInTrackingSpec <> 0)
            then
                PostItemTrackingForShipment(PurchHeader, PurchLine, TrackingSpecificationExists, TempTrackingSpecification);

            PostItemTrackingCheckShipment(PurchLine, RemQtyToBeInvoiced);
        end else begin
            if (Abs(RemQtyToBeInvoiced) > Abs(PurchLine."Qty. to Receive")) or
               (Abs(RemQtyToBeInvoiced) >= Abs(QtyToInvoiceBaseInTrackingSpec)) and (QtyToInvoiceBaseInTrackingSpec <> 0)
            then
                PostItemTrackingForReceipt(PurchHeader, PurchLine, TrackingSpecificationExists, TempTrackingSpecification);

            PostItemTrackingCheckReceipt(PurchLine, RemQtyToBeInvoiced);
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
        EndLoop := false;
        PurchRcptLine.Reset();
        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Order:
                begin
                    PurchRcptLine.SetCurrentKey("Order No.", "Order Line No.");
                    PurchRcptLine.SetRange("Order No.", PurchLine."Document No.");
                    PurchRcptLine.SetRange("Order Line No.", PurchLine."Line No.");
                end;
            PurchHeader."Document Type"::Invoice:
                begin
                    PurchRcptLine.SetRange("Document No.", PurchLine."Receipt No.");
                    PurchRcptLine.SetRange("Line No.", PurchLine."Receipt Line No.");
                end;
        end;

        PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        OnPostItemTrackingForReceiptOnAfterPurchRcptLineSetFilters(PurchRcptLine, PurchLine, PurchHeader);
        if PurchRcptLine.FindSet(true) then begin
            ItemJnlRollRndg := true;
            repeat
                GetPurchRcptLineFromTrackingOrUpdateItemEntryRelation(PurchRcptLine, TrackingSpecificationExists, ItemEntryRelation, TempTrackingSpecification);

                UpdateRemainingQtyToBeInvoiced(RemQtyToInvoiceCurrLine, RemQtyToInvoiceCurrLineBase, PurchRcptLine);
                UpdateChargeItemPurchaseRcptLineGenProdPostingGroup(PurchRcptLine);
                CheckPurchRcptLine(PurchRcptLine, PurchLine);

                OnPostItemTrackingForReceiptOnAfterPurchRcptLineTestFields(PurchRcptLine, PurchLine);

                UpdateQtyToBeInvoicedForReceipt(
                  QtyToBeInvoiced, QtyToBeInvoicedBase,
                  TrackingSpecificationExists, PurchLine, PurchRcptLine, TempTrackingSpecification);

                if TrackingSpecificationExists then begin
                    TempTrackingSpecification."Quantity actual Handled (Base)" := QtyToBeInvoicedBase;
                    TempTrackingSpecification.Modify();
                end;

                if TrackingSpecificationExists then
                    AdjustQuantityRoundingForReceipt(PurchRcptLine, RemQtyToInvoiceCurrLine, QtyToBeInvoiced, RemQtyToInvoiceCurrLineBase, QtyToBeInvoicedBase);

                RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;

                UpdateInvoicedQtyOnPurchRcptLine(
                  PurchInvHeader, PurchRcptLine, PurchHeader, PurchLine, QtyToBeInvoiced, QtyToBeInvoicedBase, TrackingSpecificationExists, TempTrackingSpecification);

                OnPostItemTrackingForReceiptOnBeforePostItemTrackingForReceiptCondition(PurchInvHeader, PurchRcptLine, QtyToBeInvoiced, QtyToBeInvoicedBase);

                if PostItemTrackingForReceiptCondition(PurchLine, PurchRcptLine) then
                    PostItemJnlLine(
                      PurchHeader, PurchLine, 0, 0, QtyToBeInvoiced, QtyToBeInvoicedBase,
                      ItemEntryRelation."Item Entry No.", '', TempTrackingSpecification);

                EndLoop :=
                    IsEndLoopForReceivedNotInvoiced(RemQtyToBeInvoiced, TrackingSpecificationExists, PurchRcptLine, TempTrackingSpecification, PurchLine);
            until EndLoop;
        end else begin
            IsHandled := false;
            OnPostItemTrackingForReceiptOnBeforeReceiptInvoiceErr(PurchLine, IsHandled);
            if not IsHandled then
                Error(ReceiptInvoicedErr, PurchLine."Receipt Line No.", PurchLine."Receipt No.");
        end;
    end;

    local procedure IsEndLoopForReceivedNotInvoiced(RemQtyToBeInvoiced: Decimal; TrackingSpecificationExists: Boolean; var PurchRcptLine: Record "Purch. Rcpt. Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; PurchLine: Record "Purchase Line") EndLoop: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsEndLoopForReceivedNotInvoiced(RemQtyToBeInvoiced, TrackingSpecificationExists, PurchRcptLine, InvoicingTrackingSpecification, PurchLine, EndLoop, IsHandled);
        if IsHandled then
            exit;

        if TrackingSpecificationExists then
            exit((InvoicingTrackingSpecification.Next() = 0) or (RemQtyToBeInvoiced = 0));

        exit((PurchRcptLine.Next() = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(PurchLine."Qty. to Receive")));
    end;

    local procedure AdjustQuantityRoundingForReceipt(PurchRcptLine: Record "Purch. Rcpt. Line"; RemQtyToInvoiceCurrLine: Decimal; var QtyToBeInvoiced: Decimal; RemQtyToInvoiceCurrLineBase: Decimal; QtyToBeInvoicedBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAdjustQuantityRoundingForReceipt(PurchRcptLine, RemQtyToInvoiceCurrLine, QtyToBeInvoiced, RemQtyToInvoiceCurrLineBase, QtyToBeInvoicedBase, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingMgt.AdjustQuantityRounding(RemQtyToInvoiceCurrLine, QtyToBeInvoiced, RemQtyToInvoiceCurrLineBase, QtyToBeInvoicedBase);
    end;

    local procedure GetPurchRcptLineFromTrackingOrUpdateItemEntryRelation(var PurchRcptLine: Record "Purch. Rcpt. Line"; TrackingSpecificationExists: Boolean; var ItemEntryRelation: Record "Item Entry Relation"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchRcptLineFromTrackingOrUpdateItemEntryRelation(PurchRcptLine, TempTrackingSpecification, ItemEntryRelation, IsHandled);
        if IsHandled then
            exit;

        if TrackingSpecificationExists then begin
            ItemEntryRelation.Get(TempTrackingSpecification."Item Ledger Entry No.");
            PurchRcptLine.Get(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
        end else
            ItemEntryRelation."Item Entry No." := PurchRcptLine."Item Rcpt. Entry No.";
    end;

    local procedure CheckPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchRcptLine(PurchRcptLine, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchRcptLine.TestField("Buy-from Vendor No.", PurchLine."Buy-from Vendor No.");
        PurchRcptLine.TestField(Type, PurchLine.Type);
        PurchRcptLine.TestField("No.", PurchLine."No.");
        PurchRcptLine.TestField("Gen. Bus. Posting Group", PurchLine."Gen. Bus. Posting Group");
        PurchRcptLine.TestField("Gen. Prod. Posting Group", PurchLine."Gen. Prod. Posting Group");
        PurchRcptLine.TestField("Job No.", PurchLine."Job No.");
        PurchRcptLine.TestField("Unit of Measure Code", PurchLine."Unit of Measure Code");
        PurchRcptLine.TestField("Variant Code", PurchLine."Variant Code");
        PurchRcptLine.TestField("Prod. Order No.", PurchLine."Prod. Order No.");
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
        IsHandled := false;
        OnBeforePostItemTrackingForShipment(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        EndLoop := false;
        ReturnShptLine.Reset();
        OnPostItemTrackingForShipmentOnAfterReturnShptLineReset(ReturnShptLine, PurchHeader, PurchLine);
        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::"Return Order":
                begin
                    ReturnShptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                    ReturnShptLine.SetRange("Return Order No.", PurchLine."Document No.");
                    ReturnShptLine.SetRange("Return Order Line No.", PurchLine."Line No.");
                end;
            PurchHeader."Document Type"::"Credit Memo":
                begin
                    ReturnShptLine.SetRange("Document No.", PurchLine."Return Shipment No.");
                    ReturnShptLine.SetRange("Line No.", PurchLine."Return Shipment Line No.");
                end;
        end;
        ReturnShptLine.SetFilter("Return Qty. Shipped Not Invd.", '<>0');
        if ReturnShptLine.FindSet(true) then begin
            ItemJnlRollRndg := true;
            repeat
                IsHandled := false;
                OnPostItemTrackingForShipmentOnBeforeSetItemEntryRelationForShipment(ItemEntryRelation, ReturnShptLine, TempTrackingSpecification, IsHandled);
                if not IsHandled then
                    if TrackingSpecificationExists then begin // Item Tracking
                        ItemEntryRelation.Get(TempTrackingSpecification."Item Ledger Entry No.");
                        ReturnShptLine.Get(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
                    end else
                        ItemEntryRelation."Item Entry No." := ReturnShptLine."Item Shpt. Entry No.";
                UpdateChargeItemReturnShptLineGenProdPostingGroup(ReturnShptLine);
                CheckFieldsOnReturnShipmentLine(ReturnShptLine, PurchLine);
                UpdateQtyToBeInvoicedForReturnShipment(
                  QtyToBeInvoiced, QtyToBeInvoicedBase,
                  TrackingSpecificationExists, PurchLine, ReturnShptLine, TempTrackingSpecification);

                if TrackingSpecificationExists then begin
                    TempTrackingSpecification."Quantity actual Handled (Base)" := QtyToBeInvoicedBase;
                    TempTrackingSpecification.Modify();
                end;

                IsHandled := false;
                OnPostItemTrackingForShipmentOnBeforeAdjustQuantityRounding(ReturnShptLine, RemQtyToBeInvoiced, QtyToBeInvoiced, RemQtyToBeInvoicedBase, QtyToBeInvoicedBase, IsHandled);
                if not IsHandled then
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

                EndLoop :=
                    IsEndLoopForShippedNotInvoiced(RemQtyToBeInvoiced, TrackingSpecificationExists, ReturnShptLine, TempTrackingSpecification, PurchLine);
            until EndLoop;
        end else begin
            IsHandled := false;
            OnPostItemTrackingForShipmentOnBeforeReturnShipmentInvoiceErr(PurchLine, IsHandled);
            if not IsHandled then
                Error(ReturnShipmentInvoicedErr, PurchLine."Return Shipment Line No.", PurchLine."Return Shipment No.");
        end;
    end;

    local procedure IsEndLoopForShippedNotInvoiced(RemQtyToBeInvoiced: Decimal; TrackingSpecificationExists: Boolean; var ReturnShptLine: Record "Return Shipment Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; PurchLine: Record "Purchase Line") EndLoop: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsEndLoopForShippedNotInvoiced(RemQtyToBeInvoiced, TrackingSpecificationExists, ReturnShptLine, InvoicingTrackingSpecification, PurchLine, EndLoop, IsHandled);
        if IsHandled then
            exit;

        if TrackingSpecificationExists then
            exit((InvoicingTrackingSpecification.Next() = 0) or (RemQtyToBeInvoiced = 0));

        exit((ReturnShptLine.Next() = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(PurchLine."Return Qty. to Ship")));
    end;

    local procedure CheckFieldsOnReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFieldsOnReturnShipmentLine(ReturnShipmentLine, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        ReturnShipmentLine.TestField("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        ReturnShipmentLine.TestField(Type, PurchaseLine.Type);
        ReturnShipmentLine.TestField("No.", PurchaseLine."No.");
        ReturnShipmentLine.TestField("Gen. Bus. Posting Group", PurchaseLine."Gen. Bus. Posting Group");
        ReturnShipmentLine.TestField("Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        ReturnShipmentLine.TestField("Job No.", PurchaseLine."Job No.");
        ReturnShipmentLine.TestField("Unit of Measure Code", PurchaseLine."Unit of Measure Code");
        ReturnShipmentLine.TestField("Variant Code", PurchaseLine."Variant Code");
        ReturnShipmentLine.TestField("Prod. Order No.", PurchaseLine."Prod. Order No.");
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
        SetDefaultQtyBlank: Boolean;
    begin
        OnBeforePostUpdateOrderLine(PurchHeader, TempPurchLineGlobal, SuppressCommit, PurchSetup);

        ResetTempLines(TempPurchLine);
        DividePrepmtVATDeducted(TempPurchLine);
        TempPurchLine.SetRange("Prepayment Line", false);
        TempPurchLine.SetFilter(Quantity, '<>0');
        OnPostUpdateOrderLineOnBeforeFindTempPurchLine(TempPurchLine, PurchHeader);
        if TempPurchLine.FindSet() then
            repeat
                OnPostUpdateOrderLineOnBeforeLoop(PurchHeader, TempPurchLine);
                if PurchHeader.Receive then begin
                    TempPurchLine."Quantity Received" += TempPurchLine."Qty. to Receive";
                    TempPurchLine."Qty. Received (Base)" += TempPurchLine."Qty. to Receive (Base)";
                    TempPurchLine."Over-Receipt Quantity" := 0;
                    OnPostUpdateOrderLineOnPurchHeaderReceive(TempPurchLine, PurchRcptHeader);
                end;
                OnPostUpdateOrderLineOnAfterReceive(PurchHeader, TempPurchLine);
                if PurchHeader.Ship then begin
                    TempPurchLine."Return Qty. Shipped" += TempPurchLine."Return Qty. to Ship";
                    TempPurchLine."Return Qty. Shipped (Base)" += TempPurchLine."Return Qty. to Ship (Base)";
                end;
                if PurchHeader.Invoice then begin
                    if TempPurchLine."Document Type" = TempPurchLine."Document Type"::Order then
                        UpdateQtyToInvoiceForOrder(PurchHeader, TempPurchLine)
                    else
                        UpdateQtyToInvoiceForReturnOrder(PurchHeader, TempPurchLine);

                    TempPurchLine."Quantity Invoiced" := TempPurchLine."Quantity Invoiced" + TempPurchLine."Qty. to Invoice";
                    TempPurchLine."Qty. Invoiced (Base)" := TempPurchLine."Qty. Invoiced (Base)" + TempPurchLine."Qty. to Invoice (Base)";
                    if TempPurchLine."Qty. to Invoice" <> 0 then begin
                        TempPurchLine."Prepmt Amt Deducted" += TempPurchLine."Prepmt Amt to Deduct";
                        TempPurchLine."Prepmt VAT Diff. Deducted" += TempPurchLine."Prepmt VAT Diff. to Deduct";
                        DecrementPrepmtAmtInvLCY(
                          PurchHeader, TempPurchLine, TempPurchLine."Prepmt. Amount Inv. (LCY)", TempPurchLine."Prepmt. VAT Amount Inv. (LCY)");
                        TempPurchLine."Prepmt Amt to Deduct" := TempPurchLine."Prepmt. Amt. Inv." - TempPurchLine."Prepmt Amt Deducted";
                        TempPurchLine."Prepmt VAT Diff. to Deduct" := 0;
                    end;
                end;

                OnPostUpdateOrderLineOnBeforeUpdateBlanketOrderLine(PurchHeader, TempPurchLine);

                UpdateBlanketOrderLine(TempPurchLine, PurchHeader.Receive, PurchHeader.Ship, PurchHeader.Invoice);

                OnPostUpdateOrderLineOnBeforeInitOutstanding(PurchHeader, TempPurchLine);

                TempPurchLine.InitOutstanding();

                SetDefaultQtyBlank := PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank;
                OnPostUpdateOrderLineOnSetDefaultQtyBlank(PurchHeader, TempPurchLine, PurchSetup, SetDefaultQtyBlank);
                if WhseHandlingRequiredExternal(TempPurchLine) or SetDefaultQtyBlank then begin
                    if TempPurchLine."Document Type" = TempPurchLine."Document Type"::"Return Order" then begin
                        TempPurchLine."Return Qty. to Ship" := 0;
                        TempPurchLine."Return Qty. to Ship (Base)" := 0;
                    end else begin
                        TempPurchLine."Qty. to Receive" := 0;
                        TempPurchLine."Qty. to Receive (Base)" := 0;
                    end;
                    OnPostUpdateOrderLineOnBeforeInitQtyToInvoice(TempPurchLine, WhseShip, WhseReceive);
                    TempPurchLine.InitQtyToInvoice();
                end else begin
                    if TempPurchLine."Document Type" = TempPurchLine."Document Type"::"Return Order" then
                        TempPurchLine.InitQtyToShip()
                    else
                        TempPurchLine.InitQtyToReceive2();
                    OnPostUpdateOrderLineOnAfterInitQtyToReceiveOrShip(PurchHeader, TempPurchLine);
                end;
                TempPurchLine.SetDefaultQuantity();
                OnBeforePostUpdateOrderLineModifyTempLine(TempPurchLine, WhseShip, WhseReceive, SuppressCommit, PurchHeader);
                ModifyTempLine(TempPurchLine);
                OnAfterPostUpdateOrderLine(TempPurchLine, WhseShip, WhseReceive, SuppressCommit);
            until TempPurchLine.Next() = 0;
    end;

    local procedure UpdateQtyToInvoiceForOrder(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyToInvoiceForOrder(PurchHeader, TempPurchLine, IsHandled);
        if IsHandled then
            exit;

        if Abs(TempPurchLine."Quantity Invoiced" + TempPurchLine."Qty. to Invoice") > Abs(TempPurchLine."Quantity Received") then begin
            TempPurchLine.Validate("Qty. to Invoice", TempPurchLine."Quantity Received" - TempPurchLine."Quantity Invoiced");
            TempPurchLine."Qty. to Invoice (Base)" := TempPurchLine."Qty. Received (Base)" - TempPurchLine."Qty. Invoiced (Base)";
        end;
    end;

    local procedure UpdateQtyToInvoiceForReturnOrder(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyToInvoiceForReturnOrder(PurchHeader, TempPurchLine, IsHandled);
        if IsHandled then
            exit;

        if Abs(TempPurchLine."Quantity Invoiced" + TempPurchLine."Qty. to Invoice") > Abs(TempPurchLine."Return Qty. Shipped") then begin
            TempPurchLine.Validate("Qty. to Invoice", TempPurchLine."Return Qty. Shipped" - TempPurchLine."Quantity Invoiced");
            TempPurchLine."Qty. to Invoice (Base)" := TempPurchLine."Return Qty. Shipped (Base)" - TempPurchLine."Qty. Invoiced (Base)";
        end;
    end;

    procedure PostUpdateInvoiceLine(var PurchaseHeader: Record "Purchase Header")
    var
        PurchOrderLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempPurchLine: Record "Purchase Line" temporary;
        IsHandled: Boolean;
    begin
        ResetTempLines(TempPurchLine);

        IsHandled := false;
        OnBeforePostUpdateInvoiceLine(TempPurchLine, IsHandled, PurchaseHeader);
        if IsHandled then
            exit;

        TempPurchLine.SetFilter("Receipt No.", '<>%1', '');
        TempPurchLine.SetFilter(Type, '<>%1', TempPurchLine.Type::" ");
        if TempPurchLine.FindSet() then
            repeat
                PurchRcptLine.Get(TempPurchLine."Receipt No.", TempPurchLine."Receipt Line No.");
                PurchOrderLine.Get(
                  PurchOrderLine."Document Type"::Order,
                  PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
                OnPostUpdateInvoiceLineOnAfterPurchOrderLineGet(TempPurchLine, PurchRcptLine, PurchOrderLine);
                if TempPurchLine.Type = TempPurchLine.Type::"Charge (Item)" then
                    UpdatePurchOrderChargeAssgnt(TempPurchLine, PurchOrderLine);

                IsHandled := false;
                OnPostUpdateInvoiceLineOnBeforeCalcQty(TempPurchLine, PurchOrderLine, IsHandled);
                if not IsHandled then begin
                    PurchOrderLine."Quantity Invoiced" += TempPurchLine."Qty. to Invoice";
                    PurchOrderLine."Qty. Invoiced (Base)" += TempPurchLine."Qty. to Invoice (Base)";
                    if Abs(PurchOrderLine."Quantity Invoiced") > Abs(PurchOrderLine."Quantity Received") then
                        Error(InvoiceMoreThanReceivedErr, PurchOrderLine."Document No.");
                end;
                if PurchOrderLine."Sales Order Line No." <> 0 then
                    CheckAssociatedSalesOrderLine(PurchOrderLine);
                OnPostUpdateInvoiceLineOnBeforeInitQtyToInvoice(PurchOrderLine, TempPurchLine);
                PurchOrderLine.InitQtyToInvoice();
                if PurchOrderLine."Prepayment %" <> 0 then begin
                    PurchOrderLine."Prepmt Amt Deducted" += TempPurchLine."Prepmt Amt to Deduct";
                    PurchOrderLine."Prepmt VAT Diff. Deducted" += TempPurchLine."Prepmt VAT Diff. to Deduct";
                    DecrementPrepmtAmtInvLCY(
                      PurchaseHeader, TempPurchLine, PurchOrderLine."Prepmt. Amount Inv. (LCY)", PurchOrderLine."Prepmt. VAT Amount Inv. (LCY)");
                    PurchOrderLine."Prepmt Amt to Deduct" :=
                      PurchOrderLine."Prepmt. Amt. Inv." - PurchOrderLine."Prepmt Amt Deducted";
                    PurchOrderLine."Prepmt VAT Diff. to Deduct" := 0;
                end;
                PurchOrderLine.InitOutstanding();
                OnPostUpdateInvoiceLineOnBeforePurchOrderLineModify(PurchOrderLine);
                PurchOrderLine.Modify();
                OnPostUpdateInvoiceLineOnAfterPurchOrderLineModify(PurchOrderLine, TempPurchLine, PurchOrderLine, TempPurchLine);
            until TempPurchLine.Next() = 0;

        OnAfterPostUpdateInvoiceLine(TempPurchLine);
    end;

    local procedure PostUpdateOrderNo(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        if PurchInvHeader."No." = '' then
            exit;

        // Do not change 'Order No.' if already set 
        if PurchInvHeader."Order No." <> '' then
            exit;

        // Get a line where 'Order No.' is set
        PurchInvLine.SetLoadFields("Order No.");

        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetFilter(Type, '<>%1', PurchInvLine.Type::" "); // Ignore comment lines
        PurchInvLine.SetFilter("Order No.", '<>%1', '');
        if not PurchInvLine.FindFirst() then
            exit;

        // If all the lines have the same 'Order No.' then set 'Order No.' field on the header
        PurchInvLine.SetFilter("Order No.", '<>%1', PurchInvLine."Order No.");
        if PurchInvLine.IsEmpty() then begin
            PurchInvHeader.Validate("Order No.", PurchInvLine."Order No.");
            PurchInvHeader.Modify(true);
        end;
    end;

    procedure PostUpdateCreditMemoLine(var PurchaseHeader: Record "Purchase Header")
    var
        PurchOrderLine: Record "Purchase Line";
        ReturnShptLine: Record "Return Shipment Line";
        TempPurchLine: Record "Purchase Line" temporary;
        IsHandled: Boolean;
    begin
        ResetTempLines(TempPurchLine);
        IsHandled := false;
        OnPostUpdateCreditMemoLineOnAfterResetTempLines(TempPurchLine, IsHandled, PurchaseHeader);
        if not IsHandled then begin
            OnPostUpdateCreditMemoLineOnBeforeTempPurchLineSetFilters(TempPurchLine);
            TempPurchLine.SetFilter("Return Shipment No.", '<>%1', '');
            TempPurchLine.SetFilter(Type, '<>%1', TempPurchLine.Type::" ");
            if TempPurchLine.FindSet() then
                repeat
                    ReturnShptLine.Get(TempPurchLine."Return Shipment No.", TempPurchLine."Return Shipment Line No.");
                    PurchOrderLine.Get(
                      PurchOrderLine."Document Type"::"Return Order",
                      ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
                    if TempPurchLine.Type = TempPurchLine.Type::"Charge (Item)" then
                        UpdatePurchOrderChargeAssgnt(TempPurchLine, PurchOrderLine);
                    PurchOrderLine."Quantity Invoiced" :=
                      PurchOrderLine."Quantity Invoiced" + TempPurchLine."Qty. to Invoice";
                    PurchOrderLine."Qty. Invoiced (Base)" :=
                      PurchOrderLine."Qty. Invoiced (Base)" + TempPurchLine."Qty. to Invoice (Base)";
                    if Abs(PurchOrderLine."Quantity Invoiced") > Abs(PurchOrderLine."Return Qty. Shipped") then
                        Error(InvoiceMoreThanShippedErr, PurchOrderLine."Document No.");
                    OnPostUpdateCreditMemoLineOnBeforeInitQtyToInvoice(PurchOrderLine, TempPurchLine);
                    PurchOrderLine.InitQtyToInvoice();
                    PurchOrderLine.InitOutstanding();
                    PurchOrderLine.Modify();
                    OnPostUpdateCreditMemoLineOnAfterPurchOrderLineModify(PurchOrderLine, TempPurchLine, ReturnShptLine);
                until TempPurchLine.Next() = 0;
        end;

        OnAfterPostUpdateCreditMemoLine(TempPurchLine);
    end;

    local procedure PostUpdateOrderNo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        NoOfLines: Integer;
        NoOfLinesWithShipmentNo: Integer;
        NoOfLinesWithParticularShipmentNo: Integer;
    begin
        // Do not change 'Return Order No.' if already set 
        if PurchCrMemoHdr."Return Order No." <> '' then
            exit;

        PurchCrMemoLine.SetLoadFields("Order No.");

        // Get number of lines. Ignore comment lines
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.SetFilter(Type, '<>%1', PurchCrMemoLine.Type::" "); // Ignore Comment lines
        NoOfLines := PurchCrMemoLine.Count();

        if NoOfLines = 0 then
            exit;

        // Get number of lines with filled in 'Order No.'
        PurchCrMemoLine.SetFilter(PurchCrMemoLine."Order No.", '<>%1', '');
        NoOfLinesWithShipmentNo := PurchCrMemoLine.Count();
        if not PurchCrMemoLine.FindFirst() then
            exit;

        // Get number of lines with filled with a 'Order No.'
        PurchCrMemoLine.SetRange("Order No.", PurchCrMemoLine."Order No.");
        NoOfLinesWithParticularShipmentNo := PurchCrMemoLine.Count();

        PurchCrMemoLine.SetRange("Return Shipment No.");
        if (NoOfLines = NoOfLinesWithShipmentNo) and (NoOfLinesWithShipmentNo = NoOfLinesWithParticularShipmentNo) then begin
            PurchCrMemoHdr.Validate("Return Order No.", PurchCrMemoLine."Order No.");
            PurchCrMemoHdr.Modify(true);
        end;
    end;

    procedure SetPostingFlags(var PurchHeader: Record "Purchase Header")
    begin
        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Order:
                PurchHeader.Ship := false;
            PurchHeader."Document Type"::Invoice:
                begin
                    PurchHeader.Receive := true;
                    PurchHeader.Invoice := true;
                    PurchHeader.Ship := false;
                end;
            PurchHeader."Document Type"::"Return Order":
                PurchHeader.Receive := false;
            PurchHeader."Document Type"::"Credit Memo":
                begin
                    PurchHeader.Receive := false;
                    PurchHeader.Invoice := true;
                    PurchHeader.Ship := true;
                end;
        end;
        CheckReceiveInvoiceShip(PurchHeader);

        OnAfterSetPostingFlags(PurchHeader);
    end;

    local procedure CheckReceiveInvoiceShip(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReceiveInvoiceShip(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if not (PurchHeader.Receive or PurchHeader.Invoice or PurchHeader.Ship) then
            Error(ReceiveInvoiceShipErr);
    end;

    local procedure SetCheckApplToItemEntry(PurchLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemJournalLine: Record "Item Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCheckApplToItemEntry(PurchLine, Result, IsHandled, PurchaseHeader, ItemJournalLine);
        if IsHandled then
            exit(Result);

        exit(
            PurchSetup."Exact Cost Reversing Mandatory" and (PurchLine.Type = PurchLine.Type::Item) and
            (((PurchLine.Quantity < 0) and (PurchLine."Document Type" in [PurchLine."Document Type"::Order, PurchLine."Document Type"::Invoice])) or
            ((PurchLine.Quantity > 0) and PurchLine.IsCreditDocType())) and
            (PurchLine."Job No." = ''));
    end;

#if not CLEAN23
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
             "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            PostedDeferralHeader.InitFromDeferralHeader(TempDeferralHeader, '', '', NewDocumentType,
              NewDocumentNo, NewLineNo, DeferralAccount, PurchLine."Buy-from Vendor No.", PostingDate);
            DeferralUtilities.FilterDeferralLines(
              TempDeferralLine, "Deferral Document Type"::Purchase.AsInteger(), '', '',
              PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
            if TempDeferralLine.FindSet() then
                repeat
                    PostedDeferralLine.InitFromDeferralLine(
                      TempDeferralLine, '', '', NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount);
                until TempDeferralLine.Next() = 0;
        end;

        OnAfterCreatePostedDeferralScheduleFromPurchDoc(PurchLine, PostedDeferralHeader);
    end;
#endif

#if not CLEAN23
    local procedure CalcDeferralAmounts(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; OriginalDeferralAmount: Decimal)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        TotalAmountLCY: Decimal;
        TotalAmount: Decimal;
        TotalDeferralCount: Integer;
        DeferralCount: Integer;
    begin
        // Populate temp and calculate the LCY amounts for posting
        if DeferralHeader.Get(
             "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            TempDeferralHeader := DeferralHeader;
            if PurchLine.Quantity <> PurchLine."Qty. to Invoice" then
                TempDeferralHeader."Amount to Defer" :=
                  Round(TempDeferralHeader."Amount to Defer" *
                    PurchLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");
            TempDeferralHeader."Amount to Defer (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                  TempDeferralHeader."Amount to Defer", PurchHeader."Currency Factor"));
            TempDeferralHeader.Insert();
            OnCalcDeferralAmountsOnAfterTempDeferralHeaderInsert(TempDeferralHeader, DeferralHeader, PurchHeader);

            DeferralUtilities.FilterDeferralLines(
                DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
            if DeferralLine.FindSet() then begin
                TotalDeferralCount := DeferralLine.Count;
                repeat
                    TempDeferralLine.Init();
                    TempDeferralLine := DeferralLine;
                    DeferralCount := DeferralCount + 1;

                    if DeferralCount = TotalDeferralCount then begin
                        TempDeferralLine.Amount := TempDeferralHeader."Amount to Defer" - TotalAmount;
                        TempDeferralLine."Amount (LCY)" := TempDeferralHeader."Amount to Defer (LCY)" - TotalAmountLCY;
                    end else begin
                        if PurchLine.Quantity <> PurchLine."Qty. to Invoice" then
                            TempDeferralLine.Amount :=
                              Round(TempDeferralLine.Amount *
                                PurchLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");

                        TempDeferralLine."Amount (LCY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                              TempDeferralLine.Amount, PurchHeader."Currency Factor"));
                        TotalAmount := TotalAmount + TempDeferralLine.Amount;
                        TotalAmountLCY := TotalAmountLCY + TempDeferralLine."Amount (LCY)";
                    end;
                    OnBeforeTempDeferralLineInsert(TempDeferralLine, DeferralLine, PurchLine, DeferralCount, TotalDeferralCount);
                    TempDeferralLine.Insert();
                until DeferralLine.Next() = 0;
            end;
        end;
    end;
#endif

    local procedure GetAmountRoundingPrecisionInLCY(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; CurrencyCode: Code[10]) AmountRoundingPrecision: Decimal
    var
        PurchHeader: Record "Purchase Header";
    begin
        if CurrencyCode = '' then
            exit(GLSetup."Amount Rounding Precision");
        PurchHeader.Get(DocType, DocNo);
        AmountRoundingPrecision := Currency."Amount Rounding Precision" / PurchHeader."Currency Factor";
        if AmountRoundingPrecision < GLSetup."Amount Rounding Precision" then
            exit(GLSetup."Amount Rounding Precision");

        OnAfterGetAmountRoundingPrecisionInLCY(DocType, DocNo, CurrencyCode, AmountRoundingPrecision);
    end;

    local procedure CollectPurchaseLineReservEntries(var JobReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        if ItemJournalLine."Job No." <> '' then begin
            JobReservEntry.DeleteAll();
            ItemJnlLineReserve.FindReservEntry(ItemJournalLine, ReservationEntry);
            ReservationEntry.ClearTrackingFilter();
            if ReservationEntry.FindSet() then
                repeat
                    JobReservEntry := ReservationEntry;
                    JobReservEntry.Insert();
                until ReservationEntry.Next() = 0;
        end;
    end;

    procedure ArchiveSalesOrders(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveSalesOrders(TempDropShptPostBuffer, IsHandled);
        if IsHandled then
            exit;

        if TempDropShptPostBuffer.FindSet() then begin
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
                    OnArchiveSalesOrdersOnBeforeSalesOrderLineModify(SalesOrderLine, TempDropShptPostBuffer);
                    SalesOrderLine.Modify();
                until TempDropShptPostBuffer.Next() = 0;
                SalesPost.ArchiveUnpostedOrder(SalesOrderHeader);
                TempDropShptPostBuffer.SetRange("Order No.");
            until TempDropShptPostBuffer.Next() = 0;
        end;
    end;

    local procedure ClearAllVariables()
    begin
        ClearAll();
        TempPurchLineGlobal.DeleteAll();
        TempItemChargeAssgntPurch.DeleteAll();
        TempHandlingSpecification.DeleteAll();
        TempTrackingSpecification.DeleteAll();
        TempTrackingSpecificationInv.DeleteAll();
        TempWhseSplitSpecification.DeleteAll();
        TempValueEntryRelation.DeleteAll();
        TempICGenJnlLine.DeleteAll();
        TempPrepmtDeductLCYPurchLine.DeleteAll();
        TempSKU.DeleteAll();
        TempDeferralHeader.DeleteAll();
        TempDeferralLine.DeleteAll();
        OrderArchived := false;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure CheckOverReceipt(PurchaseHeader: Record "Purchase Header")
    var
        OverReceiptPurchaseLine: Record "Purchase Line";
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        if not OverReceiptMgt.IsOverReceiptAllowed() then
            exit;

        OverReceiptPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        OverReceiptPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        OverReceiptPurchaseLine.SetFilter("Over-Receipt Code", '<>%1', '');
        if not OverReceiptPurchaseLine.IsEmpty() and (InvtPickPutaway or WhseReceive) then
            PurchaseHeader.TestPurchasePrepayment();

        OverReceiptPurchaseLine.SetRange("Over-Receipt Approval Status", OverReceiptPurchaseLine."Over-Receipt Approval Status"::Pending);
        if not OverReceiptPurchaseLine.IsEmpty() then
            Error(OverReceiptApprovalErr);
    end;

    procedure GetGeneralPostingSetup(var GenPostingSetup: Record "General Posting Setup"; PurchLine: Record "Purchase Line")
    begin
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        GenPostingSetup.TestField(Blocked, false);

        OnAfterGetGeneralPostingSetup(GenPostingSetup, PurchLine);
    end;

    local procedure PostResJnlLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        ResJournalLine: Record "Res. Journal Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        if PurchaseLine."Qty. to Invoice" = 0 then
            exit;

        ResJournalLine.Init();
        ResJournalLine.CopyFrom(PurchaseHeader);
        ResJournalLine.CopyDocumentFields(GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PurchaseHeader."Posting No. Series");
        ResJournalLine.CopyFrom(PurchaseLine);

        ResJnlPostLine.RunWithCheck(ResJournalLine);
    end;

    procedure RunCopyAndCheckItemCharge(PurchaseHeader: Record "Purchase Header")
    begin
        CopyAndCheckItemCharge(PurchaseHeader);
    end;

    procedure CheckAssociatedSalesOrderLine(PurchaseLine: Record "Purchase Line")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAssociatedSalesOrderLine(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Get(SalesLine."Document Type"::Order, PurchaseLine."Sales Order No.", PurchaseLine."Sales Order Line No.");
        if Abs(PurchaseLine.Quantity - PurchaseLine."Quantity Invoiced") < Abs(SalesLine.Quantity - SalesLine."Quantity Invoiced") then
            Error(CannotPostBeforeAssosSalesOrderErr, PurchaseLine."Sales Order No.");
    end;

    local procedure PurchRcptLineInsert(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchRcptLineInsert(PurchRcptLine, PurchRcptHeader, PurchLine, SuppressCommit, PostedWhseRcptLine, IsHandled);
        if IsHandled then
            exit;

        PurchRcptLine.Insert(true);

        OnAfterPurchRcptLineInsert(PurchLine, PurchRcptLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit, PurchInvHeader, TempTrackingSpecification, PurchRcptHeader, TempWhseRcptHeader, xPurchLine, TempPurchLineGlobal);
    end;

    local procedure NeedUpdateGenProdPostingGroupOnItemChargeOnPurchaseLine(PurchaseLine: Record "Purchase Line"): Boolean
    var
        NeedUpdate: Boolean;
        IsHandled: Boolean;
    begin
        NeedUpdate := true;
        IsHandled := false;
        OnNeedUpdateGenProdPostingGroupOnItemChargeOnPurchaseLine(PurchaseLine, NeedUpdate, IsHandled);
        if IsHandled then
            exit(NeedUpdate);

        if PurchaseLine.Type <> PurchaseLine.Type::"Charge (Item)" then
            exit(false);
        if PurchaseLine."No." = '' then
            exit(false);
        if ((PurchaseLine.Type = PurchaseLine.Type::"Charge (Item)") and (PurchaseLine."Gen. Prod. Posting Group" <> '')) then
            exit(false);

        exit(true);
    end;

    local procedure NeedUpdateGenProdPostingGroupOnItemChargeOnPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        NeedUpdate: Boolean;
        IsHandled: Boolean;
    begin
        NeedUpdate := true;
        IsHandled := false;
        OnNeedUpdateGenProdPostingGroupOnItemChargeOnPurchRcptLine(PurchRcptLine, NeedUpdate, IsHandled);
        if IsHandled then
            exit(NeedUpdate);

        if PurchRcptLine.Type <> PurchRcptLine.Type::"Charge (Item)" then
            exit(false);
        if PurchRcptLine."No." = '' then
            exit(false);
        if ((PurchRcptLine.Type = PurchRcptLine.Type::"Charge (Item)") and (PurchRcptLine."Gen. Prod. Posting Group" <> '')) then
            exit(false);

        exit(true);
    end;

    local procedure NeedUpdateGenProdPostingGroupOnItemChargeOnReturnReturnShipmentLine(ReturnShipmentLine: Record "Return Shipment Line"): Boolean
    var
        NeedUpdate: Boolean;
        IsHandled: Boolean;
    begin
        NeedUpdate := true;
        IsHandled := false;
        OnNeedUpdateGenProdPostingGroupOnItemChargeOnReturnShipmentLine(ReturnShipmentLine, NeedUpdate, IsHandled);
        if IsHandled then
            exit(NeedUpdate);

        if ReturnShipmentLine.Type <> ReturnShipmentLine.Type::"Charge (Item)" then
            exit(false);
        if ReturnShipmentLine."No." = '' then
            exit(false);
        if ((ReturnShipmentLine.Type = ReturnShipmentLine.Type::"Charge (Item)") and (ReturnShipmentLine."Gen. Prod. Posting Group" <> '')) then
            exit(false);

        exit(true);
    end;

    procedure UpdateChargeItemPurchaseRcptLineGenProdPostingGroup(var PurchRcptLine: Record "Purch. Rcpt. Line");
    var
        ItemCharge: Record "Item Charge";
    begin
        if not NeedUpdateGenProdPostingGroupOnItemChargeOnPurchRcptLine(PurchRcptLine) then
            exit;

        ItemCharge.Get(PurchRcptLine."No.");
        ItemCharge.TestField("Gen. Prod. Posting Group");

        PurchRcptLine."Gen. Prod. Posting Group" := ItemCharge."Gen. Prod. Posting Group";
        PurchRcptLine.Modify(false);
    end;

    procedure UpdateChargeItemReturnShptLineGenProdPostingGroup(var ReturnShipmentLine: Record "Return Shipment Line");
    var
        ItemCharge: Record "Item Charge";
    begin
        if not NeedUpdateGenProdPostingGroupOnItemChargeOnReturnReturnShipmentLine(ReturnShipmentLine) then
            exit;

        ItemCharge.Get(ReturnShipmentLine."No.");
        ItemCharge.TestField("Gen. Prod. Posting Group");

        ReturnShipmentLine."Gen. Prod. Posting Group" := ItemCharge."Gen. Prod. Posting Group";
        ReturnShipmentLine.Modify(false);
    end;

    procedure UpdateChargeItemPurchaseLineGenProdPostingGroup(var PurchaseLine: Record "Purchase Line");
    var
        ItemCharge: Record "Item Charge";
    begin
        if not NeedUpdateGenProdPostingGroupOnItemChargeOnPurchaseLine(PurchaseLine) then
            exit;

        ItemCharge.Get(PurchaseLine."No.");
        ItemCharge.TestField("Gen. Prod. Posting Group");

        PurchaseLine."Gen. Prod. Posting Group" := ItemCharge."Gen. Prod. Posting Group";
        PurchaseLine.Modify(false);
    end;

#if not CLEAN23
    local procedure UseLegacyInvoicePosting(): Boolean
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        exit(not FeatureKeyManagement.IsExtensibleInvoicePostingEngineEnabled());
    end;
#endif

    local procedure ValidateJobLineType(PurchLine: Record "Purchase Line")
    var
        Confirmed: Boolean;
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        if PurchLine."Job Line Type" <> PurchLine."Job Line Type"::" " then
            exit;

        OnBeforeConfirmJobLineType(PurchLine, HideDialog, IsHandled);
        if not IsHandled then
            if not HideDialog then begin
                Confirmed := Confirm(ConfirmUsageWithBlankLineTypeQst, false);
                if not Confirmed then
                    Error('');
            end;
    end;

    local procedure ValidateMatchingJobPlanningLine(PurchLine: Record "Purchase Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        Confirmed: Boolean;
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        JobPlanningLine.SetCurrentKey(Type, "No.", "Job No.", "Job Task No.", "Usage Link", "System-Created Entry");
        case PurchLine.Type of
            PurchLine.Type::"G/L Account":
                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::"G/L Account");
            PurchLine.Type::Item:
                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
            PurchLine.Type::Resource:
                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
            PurchLine.Type::" ":
                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Text);
        end;
        JobPlanningLine.SetRange("No.", PurchLine."No.");
        JobPlanningLine.SetRange("Job No.", PurchLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", PurchLine."Job Task No.");
        JobPlanningLine.SetRange("Usage Link", true);
        JobPlanningLine.SetRange("System-Created Entry", false);
        if not JobPlanningLine.IsEmpty() then begin
            if PurchLine."Job Planning Line No." = 0 then begin
                OnBeforeConfirmJobPlanningLineNo(PurchLine, HideDialog, IsHandled);
                if not IsHandled then
                    if not HideDialog then begin
                        Confirmed := Confirm(ConfirmUsageWithBlankJobPlanningLineNoQst, false);
                        if not Confirmed then
                            Error('');
                    end;
            end;
            ValidateJobLineType(PurchLine);
        end;
    end;

    local procedure CheckPostingDate(var PurchaseHeader: Record "Purchase Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        SetupRecID: RecordID;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDate(PurchaseHeader, IsHandled);
        if not IsHandled then
            if GenJnlCheckLine.IsDateNotAllowed(PurchaseHeader."Posting Date", SetupRecID, PurchaseHeader."Journal Templ. Name") then
                ErrorMessageMgt.LogContextFieldError(
                    PurchaseHeader.FieldNo("Posting Date"), StrSubstNo(PostingDateNotAllowedErr, PurchaseHeader.FieldCaption("Posting Date")),
                    SetupRecID, ErrorMessageMgt.GetFieldNo(SetupRecID.TableNo, GLSetup.FieldName("Allow Posting From")),
                    ForwardLinkMgt.GetHelpCodeForAllowedPostingDate());
    end;

    local procedure CheckVATDate(var PurchaseHeader: Record "Purchase Header")
    begin
        // ensure VAT Date is filled in
        if PurchaseHeader."VAT Reporting Date" = 0D then begin
            PurchaseHeader."VAT Reporting Date" := GLSetup.GetVATDate(PurchaseHeader."Posting Date", PurchaseHeader."Document Date");
            PurchaseHeader.Modify();
        end;
    end;

    local procedure UpdateReceivingNoTelemetry(var PurchaseHeader: Record "Purchase Header")
    var
        PreviewDocNos: List of [Code[20]];
        TelemetryCustomDimensions: Dictionary of [Text, Text];
        PreviewTokenFoundLbl: Label 'Preview token %1 found on fields.', Locked = true;
        PreviewToken: Text;
    begin
        OnGetPostingPreviewDocumentNos(PreviewDocNos);
        if PreviewDocNos.Count() = 0 then
            PreviewDocNos.Add(PostingPreviewNoTok);

        if PreviewDocNos.Contains(PurchaseHeader."Receiving No.") or
           PreviewDocNos.Contains(PurchaseHeader."Return Shipment No.") or
           PreviewDocNos.Contains(PurchaseHeader."Posting No.")
        then begin
            TelemetryCustomDimensions.Add(PurchaseHeader.FieldCaption(SystemId), PurchaseHeader.SystemId);
            TelemetryCustomDimensions.Add(PurchaseHeader.FieldCaption("Document Type"), Format(PurchaseHeader."Document Type"));

            if PreviewDocNos.Contains(PurchaseHeader."Receiving No.") then begin
                PreviewToken := PurchaseHeader."Receiving No.";
                TelemetryCustomDimensions.Add(PurchaseHeader.FieldCaption("Receiving No."), PurchaseHeader."Receiving No.");
                PurchaseHeader."Receiving No." := '';
            end;
            if PreviewDocNos.Contains(PurchaseHeader."Return Shipment No.") then begin
                PreviewToken := PurchaseHeader."Return Shipment No.";
                TelemetryCustomDimensions.Add(PurchaseHeader.FieldCaption("Return Shipment No."), PurchaseHeader."Return Shipment No.");
                PurchaseHeader."Return Shipment No." := '';
            end;
            if PreviewDocNos.Contains(PurchaseHeader."Posting No.") then begin
                PreviewToken := PurchaseHeader."Posting No.";
                TelemetryCustomDimensions.Add(PurchaseHeader.FieldCaption("Posting No."), PurchaseHeader."Posting No.");
                PurchaseHeader."Posting No." := '';
            end;

            Session.LogMessage('0000CUW', StrSubstNo(PreviewTokenFoundLbl, PreviewToken), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
        end;
    end;

    local procedure CheckDefaultNoSeries(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(NoSeriesCode) then
            NoSeries.TestField("Default Nos.", true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnArchiveSalesOrdersOnBeforeSalesOrderLineModify(var SalesOrderLine: Record "Sales Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBlanketOrderPurchLineModify(var BlanketOrderPurchLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnAfterCalcInvoiceDiscountPosting in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscountPosting(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var PurchLineACY: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPurchDoc(var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean; PreviewMode: Boolean; var ErrorMessageMgt: Codeunit "Error Message Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAndUpdate(var PurchaseHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckTrackingSpecification(PurchaseHeader: Record "Purchase Header"; var TempItemPurchaseLine: Record "Purchase Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingAndWarehouseForReceive(var PurchaseHeader: Record "Purchase Header"; var Receive: Boolean; CommitIsSupressed: Boolean; var TempWarehouseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWarehouseReceiptHeader: Record "Warehouse Receipt Header" temporary; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingAndWarehouseForShip(var PurchaseHeader: Record "Purchase Header"; var Ship: Boolean; CommitIsSupressed: Boolean; var TempPurchaseLine: Record "Purchase Line" temporary; var TempWarehouseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWarehouseReceiptHeader: Record "Warehouse Receipt Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateJobPurchLine(var JobPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

#if not CLEAN23
    [IntegrationEvent(false, false)]
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnAfterCreatePostedDeferralSchedule in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    local procedure OnAfterCreatePostedDeferralScheduleFromPurchDoc(var PurchaseLine: Record "Purchase Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLine(PurchaseLine: Record "Purchase Line"; var TempWhseJnlLine: record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAfterPosting(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteApprovalEntries(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDivideAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; PurchLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAmountRoundingPrecisionInLCY(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; CurrencyCode: Code[10]; var AmountRoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineDataFromOrder(var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchSetup(var PurchSetup: Record "Purchases & Payables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyTempLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPurchaseDocDropShipment(SalesShptNo: Code[20]; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRetrieveInvoiceTrackingSpecificationIfExists(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean)
    begin
    end;

#if not CLEAN24
    [IntegrationEvent(false, false)]
    [Obsolete('Parameter NoSeriesManagement is obsolete and will be removed, update your subscriber accordingly.', '24.0')]
    local procedure OnAfterUpdatePostingNos(var PurchaseHeader: Record "Purchase Header"; var NoSeriesMgt: Codeunit NoSeriesManagement; CommitIsSupressed: Boolean; PreviewMode: Boolean; var ModifyHeader: Boolean)
    begin
    end;
#else
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostingNos(var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; PreviewMode: Boolean; var ModifyHeader: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckMandatoryFields(var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareLineOnAfterFillInvoicePostingBuffer in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvoicePostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer"; PurchLine: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; CommitIsSupressed: Boolean; var PurchHeader: Record "Purchase Header"; var GenJnlLineDocNo: Code[20]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePosting(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePostingOnBeforeCommit(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrAmount(var TotalPurchLine: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PurchaseHeader: Record "Purchase Header"; QtyToBeShipped: Decimal)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnAfterInitTotalAmounts in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVATAmounts(PurchaseLine: Record "Purchase Line"; PurchaseLineACY: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnAfterInitTotalAmounts in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVATBase(PurchaseLine: Record "Purchase Line"; PurchaseLineACY: Record "Purchase Line"; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCombinedSalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPostedHeaders(var PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var PurchSetup: Record "Purchases & Payables Setup"; var Window: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertReceiptHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertReturnShipmentHeader(var PurchHeader: Record "Purchase Header"; var ReturnShptHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvoiceRoundingAmount(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TotalPurchaseLine: Record "Purchase Line"; UseTempData: Boolean; InvoiceRoundingAmount: Decimal; CommitIsSuppressed: Boolean; RoundingLineInserted: Boolean; RoundingLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertedPrepmtVATBaseToDeduct(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PrepmtLineNo: Integer; TotalPrepmtAmtToDeduct: Decimal; var TempPrepmtDeductLCYPurchLine: Record "Purchase Line" temporary; var PrepmtVATBaseToDeduct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAssocItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCombineSalesOrderShipment(var PurchaseHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLineCopyProdOrder(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; QtyToBeReceived: Decimal; CommitIsSupressed: Boolean; QtyToBeInvoiced: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLineItemCharges(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemChargePerOrder(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemTrackingLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; WhseReceive: Boolean; WhseShip: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostUpdateCreditMemoLine(var PurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUpdateInvoiceLine(var PurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptLineInsert(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; PurchInvHeader: Record "Purch. Inv. Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchRcptHeader: Record "Purch. Rcpt. Header"; TempWhseRcptHeader: Record "Warehouse Receipt Header"; xPurchLine: Record "Purchase Line"; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchLine: Record "Purchase Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; PurchHeader: Record "Purchase Header"; PurchRcptHeader: Record "Purch. Rcpt. Header"; TempWhseRcptHeader: Record "Warehouse Receipt Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line"; CommitIsSupressed: Boolean; var PurchaseHeader: Record "Purchase Header"; GenJnlLineDocNo: Code[20]; RoundingLineInserted: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnShptHeaderInsert(var ReturnShptHeader: Record "Return Shipment Header"; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnShptLineInsert(var ReturnShptLine: Record "Return Shipment Line"; ReturnShptHeader: Record "Return Shipment Header"; PurchLine: Record "Purchase Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; xPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRevertWarehouseEntry(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesShptHeaderInsert(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesOrderHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesShptLineInsert(var SalesShptLine: Record "Sales Shipment Line"; SalesShptHeader: Record "Sales Shipment Header"; SalesOrderLine: Record "Sales Line"; CommitIsSuppressed: Boolean; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAccICLine(PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostItemLine(PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; PurchaseHeader: Record "Purchase Header"; RemQtyToBeInvoiced: Decimal; RemQtyToBeInvoicedBase: Decimal; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPostLedgerEntryOnAfterGenJnlPostLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPostBalancingEntryOnAfterGenJnlPostLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPostLinesOnAfterGenJnlLinePost in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; PurchHeader: Record "Purchase Header"; GLEntryNo: Integer; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
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
    local procedure OnAfterPostInvoice(var PurchHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; TotalPurchLine: Record "Purchase Line"; TotalPurchLineLCY: Record "Purchase Line"; CommitIsSupressed: Boolean; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPurchLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; var PurchInvLine: Record "Purch. Inv. Line"; var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLineACY: Record "Purchase Line"; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; SrcCode: Code[10]; xPurchaseLine: Record "Purchase Line")
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by OnAfterProcessPurchLines', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPurchLines(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; WhseShip: Boolean; WhseReceive: Boolean; var PurchLinesProcessed: Boolean; CommitIsSuppressed: Boolean; EverythingInvoiced: Boolean; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessPurchLines(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; WhseShip: Boolean; WhseReceive: Boolean; var PurchLinesProcessed: Boolean; CommitIsSuppressed: Boolean; EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessAssocItemJnlLine(var PurchLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleasePurchDoc(var PurchHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRefreshTempLines(var TempPurchaseLine: Record "Purchase Line" temporary)
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

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnAfterSetApplyToDocNo in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPostingFlags(var PurchHeader: Record "Purchase Header")
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
    local procedure OnAfterUpdateInvoicedQtyOnReturnShptLine(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line"; TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingSpecificationExists: Boolean; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLastPostingNos(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLineBeforePost(var PurchaseLine: Record "Purchase Line"; WhseShip: Boolean; WhseReceive: Boolean; PurchaseHeader: Record "Purchase Header"; RoundingLineInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePrepmtPurchLineWithRounding(var PrepmtPurchLine: Record "Purchase Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchaseHeader(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; GenJnlLineDocType: Integer; GenJnlLineDocNo: Code[20]; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLineDimSetIDFromAppliedEntry(var PurchLineToPost: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostingAndDocumentDate(var PurchaseHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddAssociatedOrderLineToBuffer(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; SalesOrderLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempLine(var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustQuantityRoundingForReceipt(PurchRcptLine: Record "Purch. Rcpt. Line"; RemQtyToInvoiceCurrLine: Decimal; var QtyToBeInvoiced: Decimal; RemQtyToInvoiceCurrLineBase: Decimal; QtyToBeInvoicedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveUnpostedOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var OrderArchived: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveSalesOrders(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderPurchLineModify(var BlanketOrderPurchLine: Record "Purchase Line"; PurchLine: Record "Purchase Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoice(var PurchHeader: Record "Purchase Header"; var NewInvoice: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforeCalcLineDiscountPosting in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateAmountsInclVAT(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateInvoiceEverything(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header"; var InvoiceEverything: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforeCalculateVATAmounts in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateVATAmountInBuffer(PurchHeader: Record "Purchase Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcLineAmountAndLineDiscountAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; PurchLineQty: Decimal; var IsHandled: Boolean; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDropShipmentReceiveInvoice(PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExternalDocumentNumber(VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchaseHeader: Record "Purchase Header"; var Handled: Boolean; DocType: Option; ExtDocNo: Text[35]; SrcCode: Code[10]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExtDocNo(PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Gen. Journal Document Type"; ExtDocNo: Text[35]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccDirectPosting(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICDocumentDuplicatePosting(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfInvPutawayExists(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckHeaderPostingType(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFieldsOnReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtAmtToDeduct(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTrackingSpecification(PurchHeader: Record "Purchase Header"; var TempItemPurchLine: Record "Purchase Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTrackingAndWarehouseForShip(PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary; var Ship: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var TempItemPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseRcptLineQtyToReceive(var WhseRcptLine: Record "Warehouse Receipt Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearRemAmt(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; ItemJnlRollRndg: Boolean; var RemAmt: Decimal; var RemDiscAmt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePositiveEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; JobNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
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
    local procedure OnBeforeCreatePostedWhseShptLine(PurchLine: Record "Purchase Line"; ReturnShptLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedRcptLine(PurchLine: Record "Purchase Line"; ReturnShptLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseLineFromReturnShptLine(var ReturnShptLine: Record "Return Shipment Line"; PurchLine: Record "Purchase Line"; CostBaseAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommitAndUpdateAnalysisVeiw(InvtPickPutaway: Boolean; SuppressCommit: Boolean; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyAndCheckItemChargeTempPurchLine(PurchaseHeader: Record "Purchase Header"; var TempPrepmtPurchaseLine: Record "Purchase Line" temporary; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var IsHandled: Boolean; var AssignError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePrepmtLines(PurchaseHeader: Record "Purchase Header"; var TempPrepmtPurchaseLine: Record "Purchase Line" temporary; CompleteFunctionality: Boolean; var IsHandled: Boolean; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAfterPosting(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var SkipDelete: Boolean; CommitIsSupressed: Boolean; var TempPurchLine: Record "Purchase Line" temporary; var TempPurchLineGlobal: Record "Purchase Line" temporary; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteApprovalEntries(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDivideAmount(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; var PurchLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforePrepareLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillInvoicePostBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; InvoicePostBuffer: Record "Invoice Post. Buffer"; var IsHandled: Boolean; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizePosting(var PurchaseHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary; var EverythingInvoiced: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvoicePostingSetup(var InvoicePostingInterface: Interface "Invoice Posting"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforeInitGenJnlLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitNewGenJnlLineFromPostInvoicePostBufferLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; InvoicePostBuffer: Record "Invoice Post. Buffer"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforeInitGenJnlLineAmountFieldsFromTotalLines in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLineAmountFieldsFromTotalPurchLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine2: Record "Purchase Line"; var TotalPurchLineLCY2: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoiceRoundingAmount(PurchHeader: Record "Purchase Header"; TotalAmountIncludingVAT: Decimal; UseTempData: Boolean; var InvoiceRoundingAmount: Decimal; CommitIsSupressed: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertICGenJnlLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPostedHeaders(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRcptEntryRelation(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary; TempTrackingSpecificationInv: Record "Tracking Specification" temporary; ItemLedgShptEntryNo: Integer; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReceiptHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var IsHandled: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareLineOnBeforeSetAmounts in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoicePostingBufferSetAmounts(PurchaseLine: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean; var PurchLineACY: Record "Purchase Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReceiptLine(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchLine: Record "Purchase Line"; var CostBaseAmount: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReturnShipmentLine(var ReturnShptHeader: Record "Return Shipment Header"; var PurchLine: Record "Purchase Line"; var CostBaseAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTrackingSpecification(PurchHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeItemJnlPostLine(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; var IsHandled: Boolean; WhseReceiptHeader: Record "Warehouse Receipt Header"; WhseShipmentHeader: Record "Warehouse Shipment Header"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; TempWarehouseReceiptHeader: Record "Warehouse Receipt Header" temporary; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEndLoopForShippedNotInvoiced(RemQtyToBeInvoiced: Decimal; TrackingSpecificationExists: Boolean; var ReturnShptLine: Record "Return Shipment Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; PurchLine: Record "Purchase Line"; var EndLoop: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEndLoopForReceivedNotInvoiced(RemQtyToBeInvoiced: Decimal; TrackingSpecificationExists: Boolean; var PurchRcptLine: Record "Purch. Rcpt. Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; PurchLine: Record "Purchase Line"; var EndLoop: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchRcptLineFromTrackingOrUpdateItemEntryRelation(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TrackingSpecification: Record "Tracking Specification"; var ItemEntryRelation: Record "Item Entry Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchLines(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLockTables(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSuppressed: Boolean; var IsHandled: Boolean; var TempPurchaseLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDistributeItemCharge(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var TempItemLedgerEntry: Record "Item Ledger Entry"; NonDistrQuantity: Decimal; NonDistrQtyToAssign: Decimal; NonDistrAmountToAssign: Decimal; Sign: Decimal; IndirectCostPct: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoice(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean; var Window: Dialog; HideProgressWindow: Boolean; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var InvoicePostingInterface: Interface "Invoice Posting"; var InvoicePostingParameters: Record "Invoice Posting Parameters"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; SrcCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGLAccICLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargePerSalesShpt(var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostItemJnlLineCopyProdOrder(PurchLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeReceived: Decimal; QtyToBeInvoiced: Decimal; CommitIsSupressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var HideProgressWindow: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCommitPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; ModifyHeader: Boolean; var CommitIsSupressed: Boolean; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforeInitGenJnlLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoicePostBufferLine(var PurchaseHeader: Record "Purchase Header"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessAssocItemJnlLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemLedgShptEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareCheckDocument(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineDeleteAll(var PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WhseReceive: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseShip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptLineInsert(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchLine: Record "Purchase Line"; CommitIsSupressed: Boolean; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; var xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line"; CommitIsSupressed: Boolean; var xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleasePurchDoc(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShptHeaderInsert(var ReturnShptHeader: Record "Return Shipment Header"; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WhseReceive: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseShip: Boolean)
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
    local procedure OnBeforeSalesShptHeaderInsert(var SalesShptHeader: Record "Sales Shipment Header"; SalesOrderHeader: Record "Sales Header"; CommitIsSupressed: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptLineInsert(var SalesShptLine: Record "Sales Shipment Line"; SalesShptHeader: Record "Sales Shipment Header"; SalesLine: Record "Sales Line"; CommitIsSupressed: Boolean; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCheckApplToItemEntry(var PurchaseLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean; PurchaseHeader: Record "Purchase Header"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPostLedgerEntryOnBeforeGenJnlPostLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPostBalancingEntryOnBeforeGenJnlPostLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostCombineSalesOrderShipment(var PurchaseHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var SalesShipmentHeader: Record "Sales Shipment Header"; var ItemLedgShptEntryNo: Integer; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempHandlingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPostLinesOnBeforeGenJnlLinePost in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var PurchHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlLineDocNo: code[20])
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforePostLines in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvoicePostBuffer(PurchaseHeader: Record "Purchase Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var QtyToBeReceived: Decimal; var QtyToBeReceivedBase: Decimal; var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; var ItemLedgShptEntryNo: Integer; var ItemChargeNo: Code[20]; var TrackingSpecification: Record "Tracking Specification"; CommitIsSupressed: Boolean; var IsHandled: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLineItemCharges(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAssocItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var SalesLine: Record "Sales Line"; CommitIsSupressed: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargePerOrder(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var ItemJnlLine2: Record "Item Journal Line"; var ItemChargePurchLine: Record "Purchase Line"; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary; CommitIsSupressed: Boolean; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced with OnBeforePostItemChargeLineProcedure', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargeLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargeLineProcedure(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; var RemQtyToBeInvoiced: Decimal; var TempPurchLineGlobal: Record "Purchase Line" temporary; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var RemQtyToBeInvoicedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostItemJnlLineJobConsumption(var ItemJournalLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostItemTracking(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; var PreciseTotalChargeAmt: Decimal; var PreciseTotalChargeAmtACY: Decimal; var RoundedPrevTotalChargeAmt: Decimal; var RoundedPrevTotalChargeAmtACY: Decimal; var IsHandled: Boolean)
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
    local procedure OnBeforePostItemTrackingItemChargePerOrder(var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification" temporary; var IsHandled: Boolean; var ItemJnlLine2: Record "Item Journal Line"; var TempTrackingSpecificationChargeAssmtCorrect: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostItemTrackingLineOnPostPurchLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; TempTrackingSpecification: Record "Tracking Specification" temporary; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingForShipmentCondition(PurchaseLine: Record "Purchase Line"; ReturnShipmentLine: Record "Return Shipment Line"; var Condition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResourceLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; SrcCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; JobPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateOrderLine(PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary; CommitIsSuppressed: Boolean; PurchSetup: Record "Purchases & Payables Setup")
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

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSumPurchLines2(QtyType: Option; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; InsertPurchLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSumPurchLinesTemp(var PurchHeader: Record "Purchase Header")
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforeTempDeferralLineInsert in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; PurchaseLine: Record "Purchase Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;
#endif
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
    local procedure OnBeforeTransferReservToItemJnlLine(var SalesOrderLine: Record "Sales Line"; var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line"; QtyToBeShippedBase: Decimal; var ApplySpecificItemTracking: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateAssocOrder(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var IsHandled: Boolean; SuppressCommit: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBlanketOrderLine(PurchLine: Record "Purchase Line"; Receive: Boolean; Ship: Boolean; Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN24
    [IntegrationEvent(false, false)]
    [Obsolete('Parameter NoSeriesManagement is obsolete and will be removed, update your subscriber accordingly.', '24.0')]
    local procedure OnBeforeUpdatePostingNos(var PurchHeader: Record "Purchase Header"; var NoSeriesMgt: Codeunit NoSeriesManagement; var ModifyHeader: Boolean; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;
#else
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePostingNos(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchaseHeader(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; GenJnlLineDocType: Option; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header")
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
    local procedure OnBeforeUpdateQtyToInvoiceForOrder(var PurchHeader: Record "Purchase Header"; TempPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToInvoiceForReturnOrder(var PurchHeader: Record "Purchase Header"; TempPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToBeInvoicedForReceipt(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; PurchLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; InvoicingTrackingSpecification: Record "Tracking Specification"; RemQtyToBeInvoiced: Decimal; RemQtyToBeInvoicedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToBeInvoicedForReturnShipment(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; PurchLine: Record "Purchase Line"; ReturnShipmentLine: Record "Return Shipment Line"; InvoicingTrackingSpecification: Record "Tracking Specification"; RemQtyToBeInvoiced: Decimal; RemQtyToBeInvoicedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobConsumptionReservationApplToItemEntry(var TempReservEntryJobCons: Record "Reservation Entry" temporary; var ItemJournalLine: Record "Item Journal Line"; IsNonInventoriableItem: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; var IsHandled: Boolean)
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
    local procedure OnBeforeUpdateItemChargeAssgnt(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
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
    local procedure OnValidatePostingAndDocumentDateOnSetPostingDateExists(var PurchaseHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; var PostingDateExists: Boolean; var ReplacePostingDate: Boolean; var PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseHandlingRequired(PurchaseLine: Record "Purchase Line"; var Required: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareLineOnBeforePrepareDeferralLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillDeferralPostingBuffer(var PurchLine: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; CommitIsSupressed: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforePrepareLineFADiscount in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillInvoicePostBufferFADiscount(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCountryCode(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var CountryRegionCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldPostWhseJnlLine(PurchLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; WhseReceive: Boolean; WhseShip: Boolean; InvtPickPutaway: Boolean; SrcCode: Code[10])
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert in codeunit 826 "Purch. Post Invoice Events". The publisher is raised before the insert.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCalcDeferralAmountsOnAfterTempDeferralHeaderInsert(var TempDeferralHeader: Record "Deferral Header"; DeferralHeader: Record "Deferral Header"; PurchHeader: Record "Purchase Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvDiscountSetFilter(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnAfterClearPostingFromWhseRef(var PurchHeader: Record "Purchase Header"; var InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnAfterSetPostingFlags(var PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnBeforeSetPostingFlags(var PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnAfterSetSourceCode(var PurchHeader: Record "Purchase Header"; SourceCodeSetup: Record "Source Code Setup"; var SrcCode: Code[10]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnAfterArchiveUnpostedOrder(var PurchHeader: Record "Purchase Header"; Currency: Record "Currency"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnBeforeCalcInvDiscount(var PurchaseHeader: Record "Purchase Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseReceive: Boolean; WhseShip: Boolean; var RefreshNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateAssocOrderPostingDateOnBeforeValidateDocumentDate(var SalesHeader: Record "Sales Header"; var OriginalDocumentDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAssociatedOrderLinesOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAssociatedOrderLinesOnAfterCheckDimensions(PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; var PurchaseLine: Record "Purchase Line"; TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAssocOrderLinesOnBeforeCheckOrderLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; SalesOrderLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckExternalDocumentNumberOnAfterSetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTrackingAndWarehouseForShipOnAfterTempPurchLineSetFilters(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTrackingAndWarehouseForReceiveOnAfterTempPurchLineSetFilters(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary)
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
    local procedure OnCopyAndCheckItemChargeOnBeforeCheckIfEmpty(var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToTempLinesOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePrepmtLinesOnAfterInitTempPrepmtPurchLineFromPurchHeader(var TempPrepmtPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePrepmtLinesOnAfterTempPurchLineSetFilters(var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePrepmtLinesOnAfterTempPrepmtPurchLineSetFilters(var TempPrepmtPurchLine: Record "Purchase Line" temporary; var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDivideAmountOnAfterClearAmounts(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var PurchLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDivideAmountOnAfterCalcLineAmountAndLineDiscountAmount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchaseLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDivideAmountOnBeforeTempVATAmountLineRemainderModify(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; Currency: Record Currency)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnAfterInitTotalAmounts in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostBufferOnAfterInitAmounts(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var PurchLineACY: Record "Purchase Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareLineOnAfterSetInvoiceDiscAccount in codeunit 826 "Purch. Post Invoice Events". The publisher is part of the else clause only.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostingBufferOnAfterSetLineDiscAccount(var PurchaseLine: Record "Purchase Line"; var GenPostingSetup: Record "General Posting Setup"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;
#endif

#if not CLEAN23
#pragma warning disable AS0072
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareLineOnAfterUpdateInvoicePostingBuffer in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var GenJnlLineDocNo: Code[20]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;
#pragma warning restore AS0072
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareLineOnAfterSetLineDiscountPosting in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostBufferOnAfterSetShouldCalcDiscounts(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var ShouldCalcDiscounts: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    [IntegrationEvent(false, false)]
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareLineOnBeforeSetAccount in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    local procedure OnFillInvoicePostingBufferOnBeforeSetAccount(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var PurchAccount: Code[20]; GenJnlLineDocNo: Code[20])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetItemChargeLineOnAfterGet(var ItemChargePurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchLinesOnAfterFillTempLines(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyType: Option; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICGenJnlLineOnAfterCopyDocumentFields(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var TempICGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAssocOrderChargeOnBeforeInsert(TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var NewItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(var TempICGenJournalLine: Record "Gen. Journal Line" temporary; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReceiptLineOnAfterGetWhseRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReceiptLineOnAfterInitPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchLine: Record "Purchase Line"; ItemLedgShptEntryNo: Integer; xPurchLine: Record "Purchase Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var CostBaseAmount: Decimal; PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; WhseRcptHeader: Record "Warehouse Receipt Header"; var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReceiptLineOnAfterCalcShouldGetWhseRcptLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchLine: Record "Purchase Line"; PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; WhseRcptHeader: Record "Warehouse Receipt Header"; CostBaseAmount: Decimal; WhseReceive: Boolean; WhseShip: Boolean; var ShouldGetWhseRcptLine: Boolean; xPurchLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReceiptLineOnAfterCalcShouldGetWhseShptLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchLine: Record "Purchase Line"; PostedWhseShptHeader: Record "Posted Whse. Shipment Header"; WhseShptHeader: Record "Warehouse Shipment Header"; CostBaseAmount: Decimal; WhseReceive: Boolean; WhseShip: Boolean; var ShouldGetWhseShptLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReturnShipmentLineOnAfterGetWhseShptLine(var WhseShptLine: Record "Warehouse Shipment Line"; ReturnShptLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReturnShipmentLineOnAfterReturnShptLineInit(var ReturnShptHeader: Record "Return Shipment Header"; var ReturnShptLine: Record "Return Shipment Line"; var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; var CostBaseAmount: Decimal; WhseShip: Boolean; WhseReceive: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAssocItemJnlLineOnBeforePost(var ItemJournalLine: Record "Item Journal Line"; SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Event is currently missing. Check out GitHub Issue: https://github.com/microsoft/ALAppExtensions/issues/22117', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterInitNewLine(PurchHeader: Record "Purchase Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnPostCombineSalesOrderShipmentOnAfterUpdateBlanketOrderLine(var PurchaseHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; var SalesOrderLine: Record "Sales Line"; var SalesOrderHeader: record "Sales Header"; var SalesShptLine: record "Sales Shipment Line"; SalesShptHeader: Record "Sales Shipment Header")
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
    local procedure OnPostDistributeItemChargeOnAfterCalcAmountToAssign(var PurchaseLine: Record "Purchase Line"; TempItemLedgerEntry: Record "Item Ledger Entry"; QtyToAssign: Decimal; AmountToAssign: Decimal; Sign: Decimal; Factor: Decimal)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostInvoicePostingBufferOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnPostItemChargeOnAfterPostItemJnlLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostItemChargeLineOnAfterPostItemCharge(var TempItemChargeAssgntPurch: record "Item Charge Assignment (Purch)" temporary; PurchHeader: Record "Purchase Header"; PurchaseLineBackup: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargeLineOnBeforePostItemCharge(var TempItemChargeAssgntPurch: record "Item Charge Assignment (Purch)" temporary; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var GenJnlLineDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargeOnBeforePostItemJnlLine(var PurchaseLineToPost: Record "Purchase Line"; var PurchaseLine: Record "Purchase Line"; QtyToAssign: Decimal; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerOrderOnAfterCopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line"; GeneralLedgerSetup: Record "General Ledger Setup"; QtyToInvoice: Decimal; var TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerRetRcptOnAfterCalcDistributeCharge(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var ReturnRcptLine: Record "Return Receipt Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var DistributeCharge: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerSalesRetRcptOnBeforeTestJobNo(ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerSalesShptOnAfterCalcDistributeCharge(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var SalesShptLine: Record "Sales Shipment Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var DistributeCharge: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerSalesShptOnBeforeTestJobNo(SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerRetShptOnAfterCalcDistributeCharge(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var ReturnShptLine: Record "Return Shipment Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var DistributeCharge: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerRetShptOnBeforeTestJobNo(ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerRcptOnAfterCalcDistributeCharge(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var PurchRcptLine: record "Purch. Rcpt. Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var DistributeCharge: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerRcptOnAfterPurchRcptLineGet(PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerTransferOnAfterInitPurchLine2(TransferReceiptLine: Record "Transfer Receipt Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerTransferOnBeforePostItemJnlLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemApplnEntry: Record "Item Application Entry"; TransferReceiptLine: Record "Transfer Receipt Line"; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargePerITTransferOnAfterCollectItemEntryRelation(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; TransRcptLine: Record "Transfer Receipt Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineWhseLineOnBeforeTempWhseJnlLine2Find(var TempWarehouseJournalLine2: Record "Warehouse Journal Line" temporary; PurchaseLine: Record "Purchase Line"; WhseReceive: Boolean; WhseShip: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterCopyDocumentFields(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchRcptHeader: Record "Purch. Rcpt. Header"; GenJnlLineExtDocNo: Code[35]; QtyToBeInvoiced: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterPostItemJnlLineJobConsumption(var ItemJournalLine: Record "Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; OriginalItemJnlLine: Record "Item Journal Line"; TempReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification"; QtyToBeInvoiced: Decimal; QtyToBeReceived: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostItemJnlLineOnAfterCopyItemCharge(var ItemJournalLine: Record "Item Journal Line"; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeCopyDocumentFields(var ItemJournalLine: Record "Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; WhseReceive: Boolean; WhseShip: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforePostWhseJnlLine(TempHandlingSpecification: Record "Tracking Specification"; var TempWhseJnlLine: Record "Warehouse Journal Line"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostItemJnlLineJobConsumptionOnBeforeRunItemJnlPostLineWithReservation(var ItemJournalLine: Record "Item Journal Line"; var TempReservationEntry: Record "Reservation Entry" temporary; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineJobConsumption(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemJournalLine: Record "Item Journal Line"; var TempPurchReservEntry: Record "Reservation Entry" temporary; QtyToBeInvoiced: Decimal; QtyToBeReceived: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchItemLedgEntryNo: Integer; var IsHandled: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; SrcCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterSetFactor(var PurchaseLine: Record "Purchase Line"; var Factor: Decimal; var GenJnlLineExtDocNo: Code[35]; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterPrepareItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var GenJnlLineDocNo: code[20]; TrackingSpecification: Record "Tracking Specification"; QtyToBeReceived: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineJobConsumptionOnBeforeJobPost(
        var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        var PurchRcptHeader: Record "Purch. Rcpt. Header"; var ReturnShptHeader: Record "Return Shipment Header"; PurchaseLine: Record "Purchase Line";
        SrcCode: Code[10]; QtyToBeReceived: Decimal; var IsHandled: Boolean; QtyToBeInvoiced: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineWhseLineOnAfterPostRevert(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineWhseLineOnBeforePostSingleLine(WhseShip: Boolean; WhseReceive: Boolean; InvtPickPutaway: Boolean; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterItemJnlPostLineRunWithCheck(var ItemJnlLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; QtyToBeReceived: Decimal; WhseReceive: Boolean; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; QtyToBeReceivedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck(var ItemJnlLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line"; DropShipOrder: Boolean; PurchaseHeader: Record "Purchase Header"; WhseReceive: Boolean; QtyToBeReceived: Decimal; QtyToBeReceivedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeInitAmount(var ItemJnlLine: Record "Item Journal Line"; PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineItemChargesOnAfterGetItemChargeLine(var ItemChargePurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemLineOnBeforePostShipReceive(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForReceiptOnBeforeReceiptInvoiceErr(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForReceiptOnBeforePostItemTrackingForReceiptCondition(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForReceiptOnAfterPurchRcptLineTestFields(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForReceiptOnAfterPurchRcptLineSetFilters(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForShipmentOnBeforeReturnShipmentInvoiceErr(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnAfterSetEverythingInvoiced(PurchaseLine: Record "Purchase Line"; var EverythingInvoiced: Boolean; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnAfterPostByType(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; SrcCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostPurchLineOnBeforePostByType(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; Sourcecode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeInsertCrMemoLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; xPurchaseLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeInsertInvoiceLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var PurchInvLine: Record "Purch. Inv. Line");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostPurchLineOnBeforeInsertReceiptLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; PurchRcptHeader: Record "Purch. Rcpt. Header"; RoundingLineInserted: Boolean; CostBaseAmount: Decimal; xPurchaseLine: Record "Purchase Line"; var ReturnShipmentHeader: Record "Return Shipment Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemLedgShptEntryNo: Integer; SrcCode: Code[10]; PreviewMode: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeInsertReturnShipmentLine(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; ReturnShptHeader: Record "Return Shipment Header"; TempPurchLineGlobal: Record "Purchase Line"; RoundingLineInserted: Boolean; xPurchaseLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeRoundAmount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; SrcCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnTypeCaseElse(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; SourceCode: Code[10]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnAfterCreatePostedDeferralScheduleFromPurchDoc(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchLine: Record "Purchase Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnAfterCreatePostedDeferralScheduleFromPurchDocCrMemo(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateCreditMemoLineOnAfterPurchOrderLineModify(var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary; var ReturnShptLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateCreditMemoLineOnAfterResetTempLines(var TempPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateCreditMemoLineOnBeforeInitQtyToInvoice(var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateInvoiceLineOnAfterPurchOrderLineGet(var TempPurchLine: Record "Purchase Line" temporary; PurchRcptLine: Record "Purch. Rcpt. Line"; PurchOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateInvoiceLineOnAfterPurchOrderLineModify(var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary; var PurchOrderLine: Record "Purchase Line"; var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateInvoiceLineOnBeforeInitQtyToInvoice(var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnAfterInitQtyToReceiveOrShip(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnBeforeUpdateBlanketOrderLine(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnBeforeInitOutstanding(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnBeforeInitQtyToInvoice(var TempPurchaseLine: Record "Purchase Line" temporary; WhseShip: Boolean; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnBeforeLoop(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnPurchHeaderReceive(var TempPurchLine: Record "Purchase Line"; PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostUpdateOrderLineOnSetDefaultQtyBlank(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; PurchPost: Record "Purchases & Payables Setup"; var SetDefaultQtyBlank: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Event is currently missing. Check out GitHub Issue: https://github.com/microsoft/ALAppExtensions/issues/22117', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostVendorEntryOnAfterInitNewLine(var PurchaseHeader: Record "Purchase Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforePostLedgerEntry in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostVendorEntryOnBeforeInitNewLine(var PurchHeader: Record "Purchase Header"; TotalPurchLine: Record "Purchase Line"; TotalPurchLineLCY: Record "Purchase Line"; GenJnlLineDocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Code[35]; SourceCode: Code[10]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnProcessAssocItemJnlLineOnAfterInitTempDropShptPostBuffer(var PurchLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleasePurchDocumentOnBeforeSetStatus(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountOnBeforeCalculateLCYAmounts(var xPurchLine: Record "Purchase Line"; var PurchLineACY: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountOnBeforeIncrAmount(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchLineQty: Decimal; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var CurrExchRate: Record "Currency Exchange Rate"; var NoVAT: Boolean; var IsHandled: Boolean; var NonDeductibleVAT: Codeunit "Non-Deductible VAT")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeFinalizePosting(var PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeMakeInventoryAdjustment(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; PreviewMode: Boolean; PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumPurchLines2OnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumPurchLines2OnAfterDivideAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; PurchLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumPurchLines2OnBeforeDivideAmount(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssocOrderOnAfterSalesOrderHeaderModify(var SalesOrderHeader: Record "Sales Header"; var SalesSetup: Record "Sales & Receivables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssociatedSalesOrderOnBeforeClearTempDropShptPostBuffer(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssocOrderOnAfterSalesOrderLineModify(var SalesOrderLine: Record "Sales Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; SalesOrderHeader: Record "Sales Header"; SalesShptHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssocOrderOnAfterOrderNoClearFilter(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssocOrderOnBeforeSalesOrderLineModify(var SalesOrderLine: Record "Sales Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBlanketOrderLineOnBeforeCheck(var BlanketOrderPurchLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBlanketOrderLineOnBeforeInitOutstanding(var BlanketOrderPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; Ship: Boolean; Receive: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBlanketOrderLineOnAfterCheckBlanketOrderPurchLine(var BlanketOrderPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLineBeforePostOnAfterCalcInitQtyToInvoiceNeeded(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var InitQtyToInvoiceNeeded: Boolean)
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunItemJnlPostLineWithReservation(var ItemJournalLine: Record "Item Journal Line");
    begin
    end;

#if not CLEAN23
    [IntegrationEvent(false, false)]
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforeRunGenJnlPostLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    local procedure OnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line");
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnCheckAndUpdateOnAfterCopyAndCheckItemCharge(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckAndUpdateOnAfterCalcCopyAndCheckItemChargeNeeded(var PurchHeader: Record "Purchase Header"; var CopyAndCheckItemChargeNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePostingNosOnBeforeUpdatePostingNo(PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePostingNosOnAfterCalcShouldUpdateReceivingNo(PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var ModifyHeader: Boolean; var ShouldUpdateReceivingNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePositiveOnBeforeWhseJnlPostLine(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedWhseShptLineOnBeforeCreatePostedShptLine(var ReturnShipmentLine: Record "Return Shipment Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePostedRcptLineOnBeforeCreatePostedRcptLine(var ReturnShipmentLine: Record "Return Shipment Line"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveInvoiceSpecificationOnAfterUpdateTempTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveInvoiceSpecificationOnBeforeTempTrackingSpecificationModify(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveInvoiceSpecificationOnBeforeAssignTempInvoicingSpecification(var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUpdateInvoiceLine(var TempPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssociatedSalesOrderLine(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssociatedOrderLines(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReceiveInvoiceShip(var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingItemChargePerOrderOnAfterCalcFactor(var NonDistrItemJnlLine: Record "Item Journal Line"; var ItemJnlLine2: Record "Item Journal Line"; var TempTrackingSpecificationChargeAssmt: Record "Tracking Specification"; SignFactor: Integer; Factor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingItemChargePerOrderOnAfterUpdateItemJnlLine2LocationCode(var ItemJnlLine2: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForShipmentOnAfterReturnShptLineReset(var ReturnShptLine: Record "Return Shipment Line"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForShipmentOnBeforeSetItemEntryRelationForShipment(var ItemEntryRelation: Record "Item Entry Relation"; var ReturnShptLine: Record "Return Shipment Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingForShipmentOnBeforeAdjustQuantityRounding(ReturnShptLine: Record "Return Shipment Line"; RemQtyToInvoiceCurrLine: Decimal; var QtyToBeInvoiced: Decimal; RemQtyToInvoiceCurrLineBase: Decimal; QtyToBeInvoicedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRunOnAfterFillTempLines(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRunOnAfterInvoiceRounding(var PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRunOnBeforeFillTempLines(PreviewMode: Boolean; var GenJnlLineDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRunOnAfterPostPurchLine(var TempPurchLineGlobal: Record "Purchase Line" temporary; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcInvDiscount(PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; ICGenJnlLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGLAccICLineOnAfterCreateJobPurchLine(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostItemJnlLineTrackingOnBeforeTempHandlingSpecificationFind(PurchLine: Record "Purchase Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFinalizePostingOnAfterUpdateItemChargeAssgnt(var PurchHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var EverythingInvoiced: Boolean; var TempPurchLine: Record "Purchase Line" temporary; var TempPurchLineGlobal: Record "Purchase Line" temporary; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFinalizePostingOnBeforeInsertValueEntryRelation(var PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFinalizePostingOnBeforeInsertTrackingSpecification(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; PurchHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; EverythingInvoiced: Boolean; var TempPurchLine: Record "Purchase Line"; var TempPurchLineGlobal: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizePostingOnBeforeUpdateWhseDocuments(var PurchaseHeader: Record "Purchase Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TempWarehouseReceiptHeader: Record "Warehouse Receipt Header" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TempWarehouseShipmentHeader: Record "Warehouse Shipment Header" temporary; WarehouseReceive: Boolean; WarehouseShip: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareLineOnBeforePreparePurchase in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFillInvoicePostBufferOnBeforePreparePurchase(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; PurchLineACY: Record "Purchase Line"; var GenPostingSetup: Record "General Posting Setup")
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareDeferralLineOnAfterInitFromDeferralLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFillDeferralPostingBufferOnAfterInitFromDeferralLine(var DeferralPostBuffer: Record "Deferral Posting Buffer"; DeferralLine: Record "Deferral Line"; PurchLine: Record "Purchase Line"; DeferralTemplate: Record "Deferral Template");
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new events OnPrepareLineOnAfterSetInvoiceDiscountPosting or OnPrepareLineOnBeforeCalcInvoiceDiscountPosting in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(true, false)]
    local procedure OnFillInvoicePostBufferOnBeforeProcessInvoiceDiscounts(var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnFinalizePostingOnBeforeCommit(PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReceiptLineOnBeforeCreatePostedRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReceiptLineOnBeforeCreatePostedShptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReceiptLineOnBeforeProcessWhseShptRcpt(var PurchLine: Record "Purchase Line"; var IsHandled: Boolean; var CostBaseAmount: Decimal; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPrepareGenJnlLineOnAfterCopyToGenJnlLine in codeunit 826 "Purch. Post Invoice Events".', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostInvoicePostBufferLineOnAfterCopyFromInvoicePostBuffer(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnBeforeArchiveUnpostedOrder(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnAfterInsertPostedHeaders(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssosOrderPostingNosOnBeforeReleaseSalesHeader(var PurchHeader: Record "Purchase Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssosOrderPostingNosOnAfterReleaseSalesHeader(var PurchHeader: Record "Purchase Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePostingNosOnAfterSetReturnShipmentNoFromNos(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePostingNosOnInvoiceOnBeforeSetPostingNo(var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingAndDocumentDateOnAfterCalcPostingDateExists(var PurchHeader: Record "Purchase Header"; var PostingDateExists: Boolean; var ReplacePostingDate: Boolean; var PostingDate: Date; var ReplaceDocumentDate: Boolean; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNeedUpdateGenProdPostingGroupOnItemChargeOnPurchaseLine(PurchaseLine: Record "Purchase Line"; var NeedUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNeedUpdateGenProdPostingGroupOnItemChargeOnPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line"; var NeedUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNeedUpdateGenProdPostingGroupOnItemChargeOnReturnShipmentLine(ReturnShipmentLine: Record "Return Shipment Line"; var NeedUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReturnShipmentHeader(var PurchHeader: Record "Purchase Header"; var ReturnShptHeader: Record "Return Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvoiceHeader(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean; var Window: Dialog; var HideProgressWindow: Boolean; var SrcCode: Code[10]; var PurchCommentLine: Record "Purch. Comment Line"; var RecordLinkManagement: Codeunit "Record Link Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInserCrMemoHeader(var PurchHeader: Record "Purchase Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var HideProgressWindow: Boolean; var Window: Dialog; var IsHandled: Boolean; SrcCode: Code[10]; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var PurchCommentLine: Record "Purch. Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCombineSalesOrderShipmentOnBeforeCopyComments(var PurchHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var SalesShptHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by event OnPostInvoiceOnBeforePostBalancingEntry()', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostGLAndVendorOnBeforePostBalancingEntry(var PurchHeader: Record "Purchase Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoiceOnBeforePostBalancingEntry(var PurchHeader: Record "Purchase Header"; var LineCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnAfterReceive(var PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAssosOrderPostingNos(var TempPurchLine: Record "Purchase Line" temporary; var PurchHeader: Record "Purchase Header"; var DropShipment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizePostingOnBeforeUpdateAfterPosting(var PurchHeader: Record "Purchase Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var EverythingInvoiced: Boolean; var IsHandled: Boolean; var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateInvoiceLineOnBeforePurchOrderLineModify(var PurchOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateOrderLineOnBeforeFindTempPurchLine(var TempPurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvoiceOnAfterResetTempLines(var PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary; var NewInvoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterPostInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var ReturnShipmentHeader: Record "Return Shipment Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PreviewMode: Boolean; var Window: Dialog; SrcCode: Code[10]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToTempLinesLoop(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforePostPurchLine(var PurchLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateICPartnerBusPostingGroups(var TempICGenJnlLine: Record "Gen. Journal Line" temporary; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCurrency(CurrencyCode: Code[10]; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePrepaymentLinesOnBeforeInsertedPrepmtVATBaseToDeduct(var TempPrepmtPurchLine: Record "Purchase Line" temporary; var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePrepaymentLinesOnAfterGetPurchPrepmtAccount(var GLAcc: Record "G/L Account"; var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header"; CompleteFunctionality: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePrepaymentLinesOnBeforeGetPurchPrepmtAccount(var GLAcc: Record "G/L Account"; var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header"; var GenPostingSetup: Record "General Posting Setup"; CompleteFunctionality: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReturnEntryRelation(var ReturnShptLine: Record "Return Shipment Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestPurchLineOnBeforeTestFieldQtyToReceive(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestPurchLineOnBeforeTestFieldReturnQtyToShip(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCalcVATAmountLines(var PurchaseHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAssocItemJnlLineOnBeforeInitAssocItemJnlLine(var SalesOrderLine: Record "Sales Line"; var ItemShptEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTrackingSpecificationOnBeforeGetItemTrackingSetup(var PurchaseLine: Record "Purchase Line"; var ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItemJnlLineToBeReceivedAmounts(var ItemJnlLine: Record "Item Journal Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToBeReceived: Decimal; var RemAmt: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAssocItemJnlLineOnBeforeExit(SalesOrderHeader: Record "Sales Header"; var ItemShptEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateInvoiceLineOnBeforeCalcQty(var TempPurchLine: Record "Purchase Line" temporary; var PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCombineSalesOrderShipmentOnBeforeInsertSalesShptHeader(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePrepmtLinesOnAfterShouldCalcAmounts(PurchHeader: Record "Purchase Header"; var ShouldCalcAmounts: Boolean; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeDivideAmount(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCombineSalesOrderShipmentOnAfterUpdateSalesOrderLine(SalesShptHeader: Record "Sales Shipment Header"; SalesOrderHeader: Record "Sales Header"; var SalesOrderLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted(PurchHeader: Record "Purchase Header"; var ShouldCheckPosted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted(PurchHeader: Record "Purchase Header"; var ShouldCheckUnposted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToTempLines(var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUpdateCreditMemoLineOnBeforeTempPurchLineSetFilters(var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemTrackingForShipment(var PurchHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGLAccICLineOnBeforeCreateJobPurchLine(var PurchHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsItemChargeLineWithQuantityToInvoice(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargePerRcpt(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliedOutboundItemLedgEntryNo(var ItemJnlLine: Record "Item Journal Line"; var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; PurchLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmJobLineType(PurchLine: Record "Purchase Line"; var HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmJobPlanningLineNo(PurchLine: Record "Purchase Line"; var HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemTrackingOnAfterCalcShouldProcessShipment(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var ShouldProcessShipment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemReservDisruptionOnAfterInsertTempSKU(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemChargePerRetRcpt(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemChargePerTransfer(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemChargePerRetShpt(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemChargePerSalesShpt(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvoiceHeaderOnBeforeCopyLinks(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnBeforeUpdateIncomingDocument(var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineJobConsumptionOnAfterItemLedgEntrySetFilters(var ItemLedgEntry: Record "Item Ledger Entry"; var PurchLine: Record "Purchase Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestPurchLineOnTypeCaseOnDocumentTypeCaseElse(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDecrementPrepmtAmtInvLCY(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var PrepmtAmountInvLCY: Decimal; var PrepmtVATAmountInvLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPostingPreviewDocumentNo(var PreviewDocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPostingPreviewDocumentNos(var PreviewDocumentNos: List of [Code[20]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPostedHeadersOnAfterInvoice(var PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line"; var GenJnlLineDocType: Enum "Gen. Journal Document Type"; var GenJnlLineDocNo: Code[20]; var GenJnlLineExtDocNo: Code[35]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSumPurchLines2(var PurchaseHeader: Record "Purchase Header"; var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBlanketOrderLineOnTypeCaseElse(var PurchaseLine: Record "Purchase Line"; var Sign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumPurchLines2OnAfterIsRoundingLineInserted(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; RoundingLineInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICPartnerBlocked(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvoiceOnAfterPostLines(var PurchaseHeader: Record "Purchase Header"; SrcCode: Code[10]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingAndDocumentDateOnBeforePurchaseHeaderModify(var PurchaseHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchLineDimSetIDFromAppliedEntry(var PurchaseLineToPost: Record "Purchase Line"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteItemChargeAssgnt(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargePerRetRcpt(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnBeforeRunGenJnlPostLine in codeunit 826 "Purch. Post Invoice Events".', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemQuantityPurchCredit(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargePerITTransfer(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TransRcptLine: Record "Transfer Receipt Line"; var TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemChargePerRetShpt(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePrepaymentLinesOnBeforeShouldTestGetReceiptPPmtAmtToDeduct(PurchaseHeader: Record "Purchase Header"; CompleteFunctionality: Boolean; var ShouldTestGetReceiptPPmtAmtToDeduct: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDivideAmountOnBeforeAmountIncludingVATAmountRound(var PurchaseLine: Record "Purchase Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDivideAmountOnBeforeCalcAmountsForFullVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMandatoryFields(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDate(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCrMemoHeader(var PurchaseHeader: Record "Purchase Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvoiceHeader(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndUpdateOnBeforeOnBeforeDoCommit(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleasePurchDocumentOnBeforeDoCommit(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssociatedSalesOrderBeforeInitOutstanding(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforePostInvoice(PurchaseHeader: Record "Purchase Header"; var EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchDocumentOnBeforeCheckPurchDim(var PurchaseHeader: Record "Purchase Header"; var TempPurchLineGlobal: Record "Purchase Line" temporary; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvDiscountOnBeforeDoCommit(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingAndDocumentDateOnBeforeSetReplaceDocumentDate(var PurchaseHeader: Record "Purchase Header"; var PostingDate: Date; var ReplaceDocumentDate: Boolean; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDivideAmountOnBeforeTempVATAmountLineGet(PurchaseLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAPostingPossibility(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostRestrictions(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnBeforeTestGeneralPostingGroups(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssosOrderPostingNosOnBeforeTestFieldBilltoCustomerNo(var SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDivideAmountOnAfterCalcVATBaseAmount(var PurchaseLine: Record "Purchase Line")
    begin
    end;

#if not CLEAN23
    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnPostBalancingEntryOnBeforeFindVendLedgEntry in codeunit 826 "Purch. Post Invoice Events".', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeFindVendLedgEntry(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35]; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Moved to Purchase Invoice Posting implementation. Use the new event OnCalculateVATAmountInBufferOnBeforeTempInvoicePostingBufferAssign in codeunit 826 "Purch. Post Invoice Events".', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCalculateVATAmountInBufferOnBeforeTempInvoicePostBufferAssign(var VATAmount: Decimal; var VATAmountACY: Decimal; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAfterPosting(var PurchaseHeader: Record "Purchase Header"; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemChargeOnAfterCalcTotalChargeAmt(var PurchaseLineToPost: Record "Purchase Line"; QtyToAssign: Decimal; var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPurchLineOnAfterInsertReturnShipmentLine(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; ReturnShptHeader: Record "Return Shipment Header"; TempPurchaseLineGlobal: Record "Purchase Line"; RoundingLineInserted: Boolean; xPurchaseLine: Record "Purchase Line"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.");
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeMakeInventoryAdjustment(var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemReservDisruption(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterSetCheckApplToItemEntry(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
}
