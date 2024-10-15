codeunit 1313 "Correct Posted Purch. Invoice"
{
    Permissions = TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        RedoApplications: Boolean;
    begin
        RedoApplications := UnapplyCostApplication(ItemJnlPostLine, "No.");
        CreateCopyDocument(Rec, PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        OnAfterCreateCorrectivePurchCrMemo(Rec, PurchaseHeader, CancellingOnly);

        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
        SetTrackInfoForCancellation(Rec);
        if RedoApplications then
            ItemJnlPostLine.RedoApplications;
        UpdatePurchaseOrderLinesFromCancelledInvoice("No.");
        Commit();
    end;

    var
        PostedInvoiceIsPaidCorrectErr: Label 'You cannot correct this posted purchase invoice because it is fully or partially paid.\\To reverse a paid purchase invoice, you must manually create a purchase credit memo.';
        PostedInvoiceIsPaidCCancelErr: Label 'You cannot cancel this posted purchase invoice because it is fully or partially paid.\\To reverse a paid purchase invoice, you must manually create a purchase credit memo.';
        AlreadyCorrectedErr: Label 'You cannot correct this posted purchase invoice because it has been canceled.';
        AlreadyCancelledErr: Label 'You cannot cancel this posted purchase invoice because it has already been canceled.';
        CorrCorrectiveDocErr: Label 'You cannot correct this posted purchase invoice because it represents a correction of a credit memo.';
        CancelCorrectiveDocErr: Label 'You cannot cancel this posted purchase invoice because it represents a correction of a credit memo.';
        VendorIsBlockedCorrectErr: Label 'You cannot correct this posted purchase invoice because vendor %1 is blocked.', Comment = '%1 = Customer name';
        VendorIsBlockedCancelErr: Label 'You cannot cancel this posted purchase invoice because vendor %1 is blocked.', Comment = '%1 = Customer name';
        ItemIsBlockedCorrectErr: Label 'You cannot correct this posted purchase invoice because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        ItemIsBlockedCancelErr: Label 'You cannot cancel this posted purchase invoice because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        AccountIsBlockedCorrectErr: Label 'You cannot correct this posted purchase invoice because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        AccountIsBlockedCancelErr: Label 'You cannot cancel this posted purchase invoice because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        NoFreeInvoiceNoSeriesCorrectErr: Label 'You cannot correct this posted purchase invoice because no unused invoice numbers are available. \\You must extend the range of the number series for purchase invoices.';
        NoFreeInvoiceNoSeriesCancelErr: Label 'You cannot cancel this posted purchase invoice because no unused invoice numbers are available. \\You must extend the range of the number series for purchase invoices.';
        NoFreeCMSeriesCorrectErr: Label 'You cannot correct this posted purchase invoice because no unused credit memo numbers are available. \\You must extend the range of the number series for credit memos.';
        NoFreeCMSeriesCancelErr: Label 'You cannot cancel this posted purchase invoice because no unused credit memo numbers are available. \\You must extend the range of the number series for credit memos.';
        NoFreePostCMSeriesCorrectErr: Label 'You cannot correct this posted purchase invoice because no unused posted credit memo numbers are available. \\You must extend the range of the number series for posted credit memos.';
        NoFreePostCMSeriesCancelErr: Label 'You cannot cancel this posted purchase invoice because no unused posted credit memo numbers are available. \\You must extend the range of the number series for posted credit memos.';
        PurchaseLineFromOrderCorrectErr: Label 'You cannot correct this posted purchase invoice because item %1 %2 is used on a purchase order.', Comment = '%1 = Item no. %2 = Item description';
        PurchaseLineFromOrderCancelErr: Label 'You cannot cancel this posted purchase invoice because item %1 %2 is used on a purchase order.', Comment = '%1 = Item no. %2 = Item description';
        ShippedQtyReturnedCorrectErr: Label 'You cannot correct this posted purchase invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        ShippedQtyReturnedCancelErr: Label 'You cannot cancel this posted purchase invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        UsedInJobCorrectErr: Label 'You cannot correct this posted purchase invoice because item %1 %2 is used in a job.', Comment = '%1 = Item no. %2 = Item description.';
        UsedInJobCancelErr: Label 'You cannot cancel this posted purchase invoice because item %1 %2 is used in a job.', Comment = '%1 = Item no. %2 = Item description.';
        PostingNotAllowedCorrectErr: Label 'You cannot correct this posted purchase invoice because it was posted in a posting period that is closed.';
        PostingNotAllowedCancelErr: Label 'You cannot cancel this posted purchase invoice because it was posted in a posting period that is closed.';
        InvoiceIsBasedOnOrderCorrectErr: Label 'You cannot correct this posted purchase invoice because the invoice is based on a purchase order.';
        InvoiceIsBasedOnOrderCancelErr: Label 'You cannot cancel this posted purchase invoice because the invoice is based on a purchase order.';
        LineTypeNotAllowedCorrectErr: Label 'You cannot correct this posted purchase invoice because the purchase invoice line for %1 %2 is of type %3, which is not allowed on a simplified purchase invoice.', Comment = '%1 = Item no. %2 = Item description %3 = Item type.';
        LineTypeNotAllowedCancelErr: Label 'You cannot cancel this posted purchase invoice because the purchase invoice line for %1 %2 is of type %3, which is not allowed on a simplified purchase invoice.', Comment = '%1 = Item no. %2 = Item description %3 = Item type.';
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        CancellingOnly: Boolean;
        InvalidDimCodeCorrectErr: Label 'You cannot correct this posted purchase invoice because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being canceled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCodeCancelErr: Label 'You cannot cancel this posted purchase invoice because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being canceled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCombinationCorrectErr: Label 'You cannot correct this posted purchase invoice because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombinationCancelErr: Label 'You cannot cancel this posted purchase invoice because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombHeaderCorrectErr: Label 'You cannot correct this posted purchase invoice because the combination of dimensions on the invoice is blocked.';
        InvalidDimCombHeaderCancelErr: Label 'You cannot cancel this posted purchase invoice because the combination of dimensions on the invoice is blocked.';
        ExternalDocCorrectErr: Label 'You cannot correct this posted purchase invoice because the external document number is required on the invoice.';
        ExternalDocCancelErr: Label 'You cannot cancel this posted purchase invoice because the external document number is required on the invoice.';
        InventoryPostClosedCorrectErr: Label 'You cannot correct this posted purchase invoice because the posting inventory period is already closed.';
        InventoryPostClosedCancelErr: Label 'You cannot cancel this posted purchase invoice because the posting inventory period is already closed.';
        PostingCreditMemoFailedOpenPostedCMQst: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is posted. Do you want to open the posted credit memo?';
        PostingCreditMemoFailedOpenCMQst: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is created but not posted. Do you want to open the credit memo?';
        CreatingCreditMemoFailedNothingCreatedErr: Label 'Canceling the invoice failed because of the following error: \\%1.';
        ErrorType: Option IsPaid,VendorBlocked,ItemBlocked,AccountBlocked,IsCorrected,IsCorrective,SerieNumInv,SerieNumCM,SerieNumPostCM,ItemIsReturned,FromOrder,PostingNotAllowed,LineFromOrder,WrongItemType,LineFromJob,DimErr,DimCombErr,DimCombHeaderErr,ExtDocErr,InventoryPostClosed;
        WrongDocumentTypeForCopyDocumentErr: Label 'You cannot correct or cancel this type of document.';
        InvoicePartiallyPaidMsg: Label 'Invoice %1 is partially paid or credited. The corrective credit memo may not be fully closed by the invoice.', Comment = '%1 - invoice no.';
        InvoiceClosedMsg: Label 'Invoice %1 is closed. The corrective credit memo will not be applied to the invoice.', Comment = '%1 - invoice no.';
        SkipLbl: Label 'Skip';
        CreateCreditMemoLbl: Label 'Create credit memo anyway';
        ShowEntriesLbl: Label 'Show applied entries';

    procedure CancelPostedInvoice(var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    begin
        CancellingOnly := true;
        exit(CreateCreditMemo(PurchInvHeader));
    end;

    local procedure CreateCreditMemo(var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        TestCorrectInvoiceIsAllowed(PurchInvHeader, CancellingOnly);
        if not CODEUNIT.Run(CODEUNIT::"Correct Posted Purch. Invoice", PurchInvHeader) then begin
            PurchCrMemoHdr.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
            if PurchCrMemoHdr.FindFirst then begin
                if Confirm(StrSubstNo(PostingCreditMemoFailedOpenPostedCMQst, GetLastErrorText)) then
                    PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
            end else begin
                PurchaseHeader.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
                if PurchaseHeader.FindFirst then begin
                    if Confirm(StrSubstNo(PostingCreditMemoFailedOpenCMQst, GetLastErrorText)) then
                        PAGE.Run(PAGE::"Purchase Credit Memo", PurchaseHeader);
                end else
                    Error(CreatingCreditMemoFailedNothingCreatedErr, GetLastErrorText);
            end;
            exit(false);
        end;
        exit(true);
    end;

    local procedure CreateCopyDocument(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; SkipCopyFromDescription: Boolean)
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        Clear(PurchaseHeader);
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := '';
        PurchaseHeader.SetAllowSelectNoSeries;
        OnBeforePurchaseHeaderInsert(PurchaseHeader, PurchInvHeader);
        PurchaseHeader.Insert(true);

        case DocumentType of
            PurchaseHeader."Document Type"::"Credit Memo":
                CopyDocMgt.SetPropertiesForCreditMemoCorrection;
            PurchaseHeader."Document Type"::Invoice:
                CopyDocMgt.SetPropertiesForInvoiceCorrection(SkipCopyFromDescription);
            else
                Error(WrongDocumentTypeForCopyDocumentErr);
        end;

        CopyDocMgt.CopyPurchaseDocForInvoiceCancelling(PurchInvHeader."No.", PurchaseHeader);

        OnAfterCreateCopyDocument(PurchaseHeader);
    end;

    procedure CreateCreditMemoCopyDocument(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if not PurchInvHeader.IsFullyOpen then begin
            ShowInvoiceAppliedNotification(PurchInvHeader);
            exit(false);
        end;
        CreateCopyDocument(PurchInvHeader, PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);
        exit(true);
    end;

    procedure CreateCorrectiveCreditMemo(var InvoiceNotification: Notification)
    var
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(InvoiceNotification.GetData(PurchInvHeader.FieldName("No.")));
        InvoiceNotification.Recall;

        CreateCopyDocument(PurchInvHeader, PurchHeader, PurchHeader."Document Type"::"Credit Memo", false);
        PAGE.Run(PAGE::"Purchase Credit Memo", PurchHeader);
    end;

    procedure ShowAppliedEntries(var InvoiceNotification: Notification)
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(InvoiceNotification.GetData(PurchInvHeader.FieldName("No.")));
        VendLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.");
        PAGE.RunModal(PAGE::"Applied Vendor Entries", VendLedgerEntry);
    end;

    procedure SkipCorrectiveCreditMemo(var InvoiceNotification: Notification)
    begin
        InvoiceNotification.Recall;
    end;

    procedure CancelPostedInvoiceStartNewInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeader: Record "Purchase Header")
    begin
        CancellingOnly := false;

        if CreateCreditMemo(PurchInvHeader) then begin
            CreateCopyDocument(PurchInvHeader, PurchaseHeader, PurchaseHeader."Document Type"::Invoice, true);
            Commit();
        end;
    end;

    procedure TestCorrectInvoiceIsAllowed(var PurchInvHeader: Record "Purch. Inv. Header"; Cancelling: Boolean)
    begin
        CancellingOnly := Cancelling;

        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount);
        TestIfPostingIsAllowed(PurchInvHeader);
        TestIfInvoiceIsCorrectedOnce(PurchInvHeader);
        TestIfInvoiceIsNotCorrectiveDoc(PurchInvHeader);
        TestIfInvoiceIsPaid(PurchInvHeader);
        TestIfVendorIsBlocked(PurchInvHeader, PurchInvHeader."Buy-from Vendor No.");
        TestIfVendorIsBlocked(PurchInvHeader, PurchInvHeader."Pay-to Vendor No.");
        TestVendorDimension(PurchInvHeader, PurchInvHeader."Pay-to Vendor No.");
        TestDimensionOnHeader(PurchInvHeader);
        TestPurchaseLines(PurchInvHeader);
        TestIfAnyFreeNumberSeries(PurchInvHeader);
        TestExternalDocument(PurchInvHeader);
        TestInventoryPostingClosed(PurchInvHeader);

        OnAfterTestCorrectInvoiceIsAllowed(PurchInvHeader, Cancelling);
    end;

    local procedure ShowInvoiceAppliedNotification(PurchInvHeader: Record "Purch. Inv. Header")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        InvoiceNotification: Notification;
        NotificationText: Text;
    begin
        InvoiceNotification.Id := CreateGuid;
        InvoiceNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        InvoiceNotification.SetData(PurchInvHeader.FieldName("No."), PurchInvHeader."No.");
        PurchInvHeader.CalcFields(Closed);
        if PurchInvHeader.Closed then
            NotificationText := StrSubstNo(InvoiceClosedMsg, PurchInvHeader."No.")
        else
            NotificationText := StrSubstNo(InvoicePartiallyPaidMsg, PurchInvHeader."No.");
        InvoiceNotification.Message(NotificationText);
        InvoiceNotification.AddAction(ShowEntriesLbl, CODEUNIT::"Correct Posted Purch. Invoice", 'ShowAppliedEntries');
        InvoiceNotification.AddAction(SkipLbl, CODEUNIT::"Correct Posted Purch. Invoice", 'SkipCorrectiveCreditMemo');
        InvoiceNotification.AddAction(CreateCreditMemoLbl, CODEUNIT::"Correct Posted Purch. Invoice", 'CreateCorrectiveCreditMemo');
        NotificationLifecycleMgt.SendNotification(InvoiceNotification, PurchInvHeader.RecordId);
    end;

    local procedure SetTrackInfoForCancellation(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelledDocument: Record "Cancelled Document";
    begin
        PurchCrMemoHdr.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        if PurchCrMemoHdr.FindLast then
            CancelledDocument.InsertPurchInvToCrMemoCancelledDocument(PurchInvHeader."No.", PurchCrMemoHdr."No.");
    end;

    local procedure TestDimensionOnHeader(PurchInvHeader: Record "Purch. Inv. Header")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if not DimensionManagement.CheckDimIDComb(PurchInvHeader."Dimension Set ID") then
            ErrorHelperHeader(ErrorType::DimCombHeaderErr, PurchInvHeader);
    end;

    local procedure TestIfVendorIsBlocked(PurchInvHeader: Record "Purch. Inv. Header"; VendNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendNo);
        if Vendor.Blocked in [Vendor.Blocked::All] then
            ErrorHelperHeader(ErrorType::VendorBlocked, PurchInvHeader);
    end;

    local procedure TestVendorDimension(PurchInvHeader: Record "Purch. Inv. Header"; VendNo: Code[20])
    var
        Vendor: Record Vendor;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        Vendor.Get(VendNo);
        TableID[1] := DATABASE::Vendor;
        No[1] := Vendor."No.";
        if not DimensionManagement.CheckDimValuePosting(TableID, No, PurchInvHeader."Dimension Set ID") then
            ErrorHelperAccount(ErrorType::DimErr, Vendor.TableCaption, Vendor."No.", Vendor."No.", Vendor.Name);
    end;

    local procedure TestPurchaseLines(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        ReceivedQtyNoReturned: Decimal;
        RevUnitCostLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if PurchInvLine.Find('-') then
            repeat
                if not IsCommentLine(PurchInvLine) then begin
                    if PurchRcptLine.Get(PurchInvLine."Receipt No.", PurchInvLine."Receipt Line No.") then begin
                        if PurchRcptLine."Order No." <> '' then
                            ErrorHelperLine(ErrorType::LineFromOrder, PurchInvLine);
                    end;

                    if (not PurchInvLine.IsCancellationSupported) and NotInvRndAccount(PurchInvHeader."Vendor Posting Group", PurchInvLine) then
                        ErrorHelperLine(ErrorType::WrongItemType, PurchInvLine);

                    if PurchInvLine.Type = PurchInvLine.Type::Item then begin
                        Item.Get(PurchInvLine."No.");

                        if Item.IsInventoriableType then
                            if (PurchInvLine.Quantity > 0) and (PurchInvLine."Job No." = '') and WasNotCancelled(PurchInvHeader."No.") then begin
                                PurchInvLine.CalcReceivedPurchNotReturned(ReceivedQtyNoReturned, RevUnitCostLCY, false);
                                if PurchInvLine.Quantity <> ReceivedQtyNoReturned then
                                    ErrorHelperLine(ErrorType::ItemIsReturned, PurchInvLine);
                            end;

                        if Item.Blocked then
                            ErrorHelperLine(ErrorType::ItemBlocked, PurchInvLine);

                        TableID[1] := DATABASE::Item;
                        No[1] := PurchInvLine."No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, PurchInvLine."Dimension Set ID") then
                            ErrorHelperAccount(ErrorType::DimErr, Item.TableCaption, No[1], Item."No.", Item.Description);

                        if Item.IsInventoriableType then
                            TestInventoryPostingSetup(PurchInvLine);
                    end;

                    TestGenPostingSetup(PurchInvLine);
                    TestVendorPostingGroup(PurchInvLine, PurchInvHeader."Vendor Posting Group");
                    TestVATPostingSetup(PurchInvLine);

                    if not DimensionManagement.CheckDimIDComb(PurchInvLine."Dimension Set ID") then
                        ErrorHelperLine(ErrorType::DimCombErr, PurchInvLine);
                end;
            until PurchInvLine.Next = 0;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; PurchInvLine: Record "Purch. Inv. Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then
            ErrorHelperAccount(ErrorType::AccountBlocked, GLAccount.TableCaption, AccountNo, '', '');
        TableID[1] := DATABASE::"G/L Account";
        No[1] := AccountNo;

        if PurchInvLine.Type = PurchInvLine.Type::Item then begin
            Item.Get(PurchInvLine."No.");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, PurchInvLine."Dimension Set ID") then
                ErrorHelperAccount(ErrorType::DimErr, GLAccount.TableCaption, AccountNo, Item."No.", Item.Description);
        end;
    end;

    local procedure TestIfInvoiceIsPaid(PurchInvHeader: Record "Purch. Inv. Header")
    begin
        PurchInvHeader.CalcFields("Amount Including VAT");
        PurchInvHeader.CalcFields("Remaining Amount");
        if PurchInvHeader."Amount Including VAT" <> PurchInvHeader."Remaining Amount" then
            ErrorHelperHeader(ErrorType::IsPaid, PurchInvHeader);
    end;

    local procedure TestIfInvoiceIsCorrectedOnce(PurchInvHeader: Record "Purch. Inv. Header")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if CancelledDocument.FindPurchCancelledInvoice(PurchInvHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrected, PurchInvHeader);
    end;

    local procedure TestIfInvoiceIsNotCorrectiveDoc(PurchInvHeader: Record "Purch. Inv. Header")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if CancelledDocument.FindPurchCorrectiveInvoice(PurchInvHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrective, PurchInvHeader);
    end;

    local procedure TestIfPostingIsAllowed(PurchInvHeader: Record "Purch. Inv. Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(PurchInvHeader."Posting Date") then
            ErrorHelperHeader(ErrorType::PostingNotAllowed, PurchInvHeader);
    end;

    local procedure TestIfAnyFreeNumberSeries(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PostingDate: Date;
    begin
        PostingDate := WorkDate;
        PurchasesPayablesSetup.Get();

        if NoSeriesManagement.TryGetNextNo(PurchasesPayablesSetup."Credit Memo Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumCM, PurchInvHeader);

        if NoSeriesManagement.TryGetNextNo(PurchasesPayablesSetup."Posted Credit Memo Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumPostCM, PurchInvHeader);

        if (not CancellingOnly) and (NoSeriesManagement.TryGetNextNo(PurchasesPayablesSetup."Invoice Nos.", PostingDate) = '') then
            ErrorHelperHeader(ErrorType::SerieNumInv, PurchInvHeader);
    end;

    local procedure TestExternalDocument(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        if (PurchInvHeader."Vendor Invoice No." = '') and PurchasesPayablesSetup."Ext. Doc. No. Mandatory" then
            ErrorHelperHeader(ErrorType::ExtDocErr, PurchInvHeader);
    end;

    local procedure TestInventoryPostingClosed(PurchInvHeader: Record "Purch. Inv. Header")
    var
        InventoryPeriod: Record "Inventory Period";
        PurchInvLine: Record "Purch. Inv. Line";
        DocumentHasLineWithRestrictedType: Boolean;
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetFilter(Quantity, '<>%1', 0);
        PurchInvLine.SetFilter(Type, '%1|%2', PurchInvLine.Type::Item, PurchInvLine.Type::"Charge (Item)");
        DocumentHasLineWithRestrictedType := not PurchInvLine.IsEmpty;

        if DocumentHasLineWithRestrictedType then begin
            InventoryPeriod.SetRange(Closed, true);
            InventoryPeriod.SetFilter("Ending Date", '>=%1', PurchInvHeader."Posting Date");
            if InventoryPeriod.FindFirst then
                ErrorHelperHeader(ErrorType::InventoryPostClosed, PurchInvHeader);
        end;
    end;

    local procedure TestGenPostingSetup(PurchInvLine: Record "Purch. Inv. Line")
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        if PurchInvLine."VAT Calculation Type" = PurchInvLine."VAT Calculation Type"::"Sales Tax" then
            exit;

        PurchasesPayablesSetup.GetRecordOnce;

        with GenPostingSetup do begin
            Get(PurchInvLine."Gen. Bus. Posting Group", PurchInvLine."Gen. Prod. Posting Group");
            if PurchInvLine.Type <> PurchInvLine.Type::"G/L Account" then begin
                TestField("Purch. Account");
                TestGLAccount("Purch. Account", PurchInvLine);
                TestField("Purch. Credit Memo Account");
                TestGLAccount("Purch. Credit Memo Account", PurchInvLine);
            end;
            if IsCheckDirectCostAppliedAccount(PurchInvLine) then begin
                TestField("Direct Cost Applied Account");
                TestGLAccount("Direct Cost Applied Account", PurchInvLine);
            end;
            if HasLineDiscountSetup() then
                if "Purch. Line Disc. Account" <> '' then
                    TestGLAccount("Purch. Line Disc. Account", PurchInvLine);
        end;
    end;

    local procedure TestVendorPostingGroup(PurchInvLine: Record "Purch. Inv. Line"; VendorPostingGr: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        with VendorPostingGroup do begin
            Get(VendorPostingGr);
            TestField("Payables Account");
            TestGLAccount("Payables Account", PurchInvLine);
        end;
    end;

    local procedure TestVATPostingSetup(PurchInvLine: Record "Purch. Inv. Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with VATPostingSetup do begin
            Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group");
            if "VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax" then begin
                TestField("Purchase VAT Account");
                TestGLAccount("Purchase VAT Account", PurchInvLine);
            end;
        end;
    end;

    local procedure TestInventoryPostingSetup(PurchInvLine: Record "Purch. Inv. Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestInventoryPostingSetup(PurchInvLine, IsHandled);
        if IsHandled then
            exit;

        with InventoryPostingSetup do begin
            Get(PurchInvLine."Location Code", PurchInvLine."Posting Group");
            TestField("Inventory Account");
            TestGLAccount("Inventory Account", PurchInvLine);
        end;
    end;

    local procedure IsCommentLine(PurchInvLine: Record "Purch. Inv. Line"): Boolean
    begin
        exit((PurchInvLine.Type = PurchInvLine.Type::" ") or (PurchInvLine."No." = ''));
    end;

    local procedure WasNotCancelled(InvNo: Code[20]): Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Applies-to Doc. Type", PurchCrMemoHdr."Applies-to Doc. Type"::Invoice);
        PurchCrMemoHdr.SetRange("Applies-to Doc. No.", InvNo);
        exit(PurchCrMemoHdr.IsEmpty);
    end;

    local procedure NotInvRndAccount(VendorPostingGroupCode: Code[20]; PurchInvLine: Record "Purch. Inv. Line"): Boolean
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if PurchInvLine.Type <> PurchInvLine.Type::"G/L Account" then
            exit(true);

        VendorPostingGroup.Get(VendorPostingGroupCode);
        exit((VendorPostingGroup."Invoice Rounding Account" <> PurchInvLine."No.") or (not PurchInvLine."System-Created Entry"));
    end;

    local procedure UnapplyCostApplication(var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; InvNo: Code[20]): Boolean
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempItemApplicationEntry: Record "Item Application Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnAppyCostApplication(InvNo, IsHandled);
        if IsHandled then
            exit(false);

        FindItemLedgEntries(TempItemLedgEntry, InvNo);
        if FindAppliedInbndEntries(TempItemApplicationEntry, TempItemLedgEntry) then begin
            repeat
                ItemJnlPostLine.UnApply(TempItemApplicationEntry);
            until TempItemApplicationEntry.Next = 0;
            exit(true);
        end;
    end;

    procedure FindItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry"; InvNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        with PurchInvLine do begin
            SetRange("Document No.", InvNo);
            SetRange(Type, Type::Item);
            if FindSet then
                repeat
                    GetItemLedgEntries(ItemLedgEntry, false);
                until Next = 0;
        end;
    end;

    local procedure FindAppliedInbndEntries(var TempItemApplicationEntry: Record "Item Application Entry" temporary; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        TempItemApplicationEntry.Reset();
        TempItemApplicationEntry.DeleteAll();
        if ItemLedgEntry.FindSet then
            repeat
                if ItemApplicationEntry.AppliedOutbndEntryExists(ItemLedgEntry."Entry No.", true, false) then
                    repeat
                        TempItemApplicationEntry := ItemApplicationEntry;
                        if not TempItemApplicationEntry.Find then
                            TempItemApplicationEntry.Insert();
                    until ItemApplicationEntry.Next = 0;
            until ItemLedgEntry.Next = 0;
        exit(TempItemApplicationEntry.FindSet);
    end;

    local procedure ErrorHelperHeader(ErrorOption: Option; PurchInvHeader: Record "Purch. Inv. Header")
    var
        Vendor: Record Vendor;
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::IsPaid:
                    Error(PostedInvoiceIsPaidCCancelErr);
                ErrorType::VendorBlocked:
                    begin
                        Vendor.Get(PurchInvHeader."Pay-to Vendor No.");
                        Error(VendorIsBlockedCancelErr, Vendor.Name);
                    end;
                ErrorType::IsCorrected:
                    Error(AlreadyCancelledErr);
                ErrorType::IsCorrective:
                    Error(CancelCorrectiveDocErr);
                ErrorType::SerieNumInv:
                    Error(NoFreeInvoiceNoSeriesCancelErr);
                ErrorType::SerieNumCM:
                    Error(NoFreeCMSeriesCancelErr);
                ErrorType::SerieNumPostCM:
                    Error(NoFreePostCMSeriesCancelErr);
                ErrorType::FromOrder:
                    Error(InvoiceIsBasedOnOrderCancelErr);
                ErrorType::PostingNotAllowed:
                    Error(PostingNotAllowedCancelErr);
                ErrorType::ExtDocErr:
                    Error(ExternalDocCancelErr);
                ErrorType::InventoryPostClosed:
                    Error(InventoryPostClosedCancelErr);
                ErrorType::DimCombHeaderErr:
                    Error(InvalidDimCombHeaderCancelErr);
            end
        else
            case ErrorOption of
                ErrorType::IsPaid:
                    Error(PostedInvoiceIsPaidCorrectErr);
                ErrorType::VendorBlocked:
                    begin
                        Vendor.Get(PurchInvHeader."Pay-to Vendor No.");
                        Error(VendorIsBlockedCorrectErr, Vendor.Name);
                    end;
                ErrorType::IsCorrected:
                    Error(AlreadyCorrectedErr);
                ErrorType::IsCorrective:
                    Error(CorrCorrectiveDocErr);
                ErrorType::SerieNumInv:
                    Error(NoFreeInvoiceNoSeriesCorrectErr);
                ErrorType::SerieNumPostCM:
                    Error(NoFreePostCMSeriesCorrectErr);
                ErrorType::SerieNumCM:
                    Error(NoFreeCMSeriesCorrectErr);
                ErrorType::FromOrder:
                    Error(InvoiceIsBasedOnOrderCorrectErr);
                ErrorType::PostingNotAllowed:
                    Error(PostingNotAllowedCorrectErr);
                ErrorType::ExtDocErr:
                    Error(ExternalDocCorrectErr);
                ErrorType::InventoryPostClosed:
                    Error(InventoryPostClosedCorrectErr);
                ErrorType::DimCombHeaderErr:
                    Error(InvalidDimCombHeaderCorrectErr);
            end;
    end;

    local procedure ErrorHelperLine(ErrorOption: Option; PurchInvLine: Record "Purch. Inv. Line")
    var
        Item: Record Item;
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::ItemBlocked:
                    begin
                        Item.Get(PurchInvLine."No.");
                        Error(ItemIsBlockedCancelErr, Item."No.", Item.Description);
                    end;
                ErrorType::ItemIsReturned:
                    begin
                        Item.Get(PurchInvLine."No.");
                        Error(ShippedQtyReturnedCancelErr, Item."No.", Item.Description);
                    end;
                ErrorType::LineFromOrder:
                    Error(PurchaseLineFromOrderCancelErr, PurchInvLine."No.", PurchInvLine.Description);
                ErrorType::WrongItemType:
                    Error(LineTypeNotAllowedCancelErr, PurchInvLine."No.", PurchInvLine.Description, PurchInvLine.Type);
                ErrorType::LineFromJob:
                    Error(UsedInJobCancelErr, PurchInvLine."No.", PurchInvLine.Description);
                ErrorType::DimCombErr:
                    Error(InvalidDimCombinationCancelErr, PurchInvLine."No.", PurchInvLine.Description);
            end
        else
            case ErrorOption of
                ErrorType::ItemBlocked:
                    begin
                        Item.Get(PurchInvLine."No.");
                        Error(ItemIsBlockedCorrectErr, Item."No.", Item.Description);
                    end;
                ErrorType::ItemIsReturned:
                    begin
                        Item.Get(PurchInvLine."No.");
                        Error(ShippedQtyReturnedCorrectErr, Item."No.", Item.Description);
                    end;
                ErrorType::LineFromOrder:
                    Error(PurchaseLineFromOrderCorrectErr, PurchInvLine."No.", PurchInvLine.Description);
                ErrorType::WrongItemType:
                    Error(LineTypeNotAllowedCorrectErr, PurchInvLine."No.", PurchInvLine.Description, PurchInvLine.Type);
                ErrorType::LineFromJob:
                    Error(UsedInJobCorrectErr, PurchInvLine."No.", PurchInvLine.Description);
                ErrorType::DimCombErr:
                    Error(InvalidDimCombinationCorrectErr, PurchInvLine."No.", PurchInvLine.Description);
            end;
    end;

    local procedure ErrorHelperAccount(ErrorOption: Option; AccountNo: Code[20]; AccountCaption: Text; No: Code[20]; Name: Text)
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::AccountBlocked:
                    Error(AccountIsBlockedCancelErr, AccountCaption, AccountNo);
                ErrorType::DimErr:
                    Error(InvalidDimCodeCancelErr, AccountCaption, AccountNo, No, Name);
            end
        else
            case ErrorOption of
                ErrorType::AccountBlocked:
                    Error(AccountIsBlockedCorrectErr, AccountCaption, AccountNo);
                ErrorType::DimErr:
                    Error(InvalidDimCodeCorrectErr, AccountCaption, AccountNo, No, Name);
            end;
    end;

    local procedure UpdatePurchaseOrderLinesFromCancelledInvoice(PurchInvHeaderNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeaderNo);
        if PurchInvLine.FindSet() then
            repeat
                if PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchInvLine."Order No.", PurchInvLine."Order Line No.") then
                    UpdatePurchaseOrderLineInvoicedQuantity(PurchaseLine, PurchInvLine.Quantity, PurchInvLine."Quantity (Base)");
            until PurchInvLine.Next() = 0;
    end;

    local procedure UpdatePurchaseOrderLineInvoicedQuantity(var PurchaseLine: Record "Purchase Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchaseOrderLineInvoicedQuantity(PurchaseLine, CancelledQuantity, CancelledQtyBase, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine."Quantity Invoiced" -= CancelledQuantity;
        PurchaseLine."Qty. Invoiced (Base)" -= CancelledQtyBase;
        PurchaseLine."Quantity Received" -= CancelledQuantity;
        PurchaseLine."Qty. Received (Base)" -= CancelledQtyBase;
        PurchaseLine.InitOutstanding();
        PurchaseLine.InitQtyToReceive();
        PurchaseLine.InitQtyToInvoice();
        PurchaseLine.Modify();
    end;

    local procedure HasLineDiscountSetup() Result: Boolean
    begin
        with PurchasesPayablesSetup do begin
            GetRecordOnce();
            Result := "Discount Posting" in ["Discount Posting"::"Line Discounts", "Discount Posting"::"All Discounts"];
        end;
        OnHasLineDiscountSetup(PurchasesPayablesSetup, Result);
    end;

    local procedure IsCheckDirectCostAppliedAccount(PurchInvLine: Record "Purch. Inv. Line") Result: Boolean
    begin
        Result := PurchInvLine.Type in [PurchInvLine.Type::"Charge (Item)", PurchInvLine.Type::"Fixed Asset", PurchInvLine.Type::Item];
        OnAfterIsCheckDirectCostAppliedAccount(PurchInvLine, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCorrectivePurchCrMemo(PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeader: Record "Purchase Header"; var CancellingOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestCorrectInvoiceIsAllowed(var PurchInvHeader: Record "Purch. Inv. Header"; Cancelling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderInsert(var PurchaseHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnAppyCostApplication(InvNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchaseOrderLineInvoicedQuantity(var PurchaseLine: Record "Purchase Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestInventoryPostingSetup(PurchInvLine: Record "Purch. Inv. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasLineDiscountSetup(PurchasesPayablesSetup: Record "Purchases & Payables Setup"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCheckDirectCostAppliedAccount(PurchInvLine: Record "Purch. Inv. Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCopyDocument(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

