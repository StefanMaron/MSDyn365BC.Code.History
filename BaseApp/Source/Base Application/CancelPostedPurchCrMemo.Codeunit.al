codeunit 1402 "Cancel Posted Purch. Cr. Memo"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Purch. Cr. Memo Hdr.";

    trigger OnRun()
    var
        PurchHeader: Record "Purchase Header";
    begin
        UnapplyEntries(Rec);
        CreateCopyDocument(Rec, PurchHeader);

        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchHeader);
        SetTrackInfoForCancellation(Rec);

        Commit();
    end;

    var
        AlreadyCancelledErr: Label 'You cannot cancel this posted purchase credit memo because it has already been cancelled.';
        NotCorrectiveDocErr: Label 'You cannot cancel this posted purchase credit memo because it is not a corrective document.';
        VendorIsBlockedCancelErr: Label 'You cannot cancel this posted purchase credit memo because vendor %1 is blocked.', Comment = '%1 = Customer name';
        ItemIsBlockedCancelErr: Label 'You cannot cancel this posted purchase credit memo because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        AccountIsBlockedCancelErr: Label 'You cannot cancel this posted purchase credit memo because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        NoFreeInvoiceNoSeriesCancelErr: Label 'You cannot cancel this posted purchase credit memo because no unused invoice numbers are available. \\You must extend the range of the number series for purchase invoices.';
        NoFreePostInvSeriesCancelErr: Label 'You cannot cancel this posted purchase credit memo because no unused posted invoice numbers are available. \\You must extend the range of the number series for posted invoices.';
        PostingNotAllowedCancelErr: Label 'You cannot cancel this posted purchase credit memo because it was posted in a posting period that is closed.';
        InvalidDimCodeCancelErr: Label 'You cannot cancel this posted purchase credit memo because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being cancelled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCombinationCancelErr: Label 'You cannot cancel this posted purchase credit memo because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombHeaderCancelErr: Label 'You cannot cancel this posted purchase credit memo because the combination of dimensions on the credit memo is blocked.';
        ExternalDocCancelErr: Label 'You cannot cancel this posted purchase memo because the external document number is required on the credit memo.';
        InventoryPostClosedCancelErr: Label 'You cannot cancel this posted purchase credit memo because the inventory period is already closed.';
        PostingCreditMemoFailedOpenPostedInvQst: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is posted. Do you want to open the posted invoice?', Comment = '%1 = error text';
        PostingCreditMemoFailedOpenInvQst: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is created but not posted. Do you want to open the invoice?', Comment = '%1 = error text';
        CreatingInvFailedNothingCreatedErr: Label 'Canceling the credit memo failed because of the following error: \\%1.', Comment = '%1 = error text';
        ErrorType: Option VendorBlocked,ItemBlocked,AccountBlocked,IsAppliedIncorrectly,IsUnapplied,IsCanceled,IsCorrected,SerieNumInv,SerieNumPostInv,FromOrder,PostingNotAllowed,DimErr,DimCombErr,DimCombHeaderErr,ExtDocErr,InventoryPostClosed;
        UnappliedErr: Label 'You cannot cancel this posted purchase credit memo because it is fully or partially applied.\\To reverse an applied purchase credit memo, you must manually unapply all applied entries.';
        NotAppliedCorrectlyErr: Label 'You cannot cancel this posted purchase credit memo because it is not fully applied to an invoice.';

    procedure CancelPostedCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."): Boolean
    var
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        TestCorrectCrMemoIsAllowed(PurchCrMemoHdr);
        if not CODEUNIT.Run(CODEUNIT::"Cancel Posted Purch. Cr. Memo", PurchCrMemoHdr) then begin
            PurchInvHeader.SetRange("Applies-to Doc. No.", PurchCrMemoHdr."No.");
            if PurchInvHeader.FindFirst then begin
                if Confirm(StrSubstNo(PostingCreditMemoFailedOpenPostedInvQst, GetLastErrorText)) then
                    PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
            end else begin
                PurchHeader.SetRange("Applies-to Doc. No.", PurchCrMemoHdr."No.");
                if PurchHeader.FindFirst then begin
                    if Confirm(StrSubstNo(PostingCreditMemoFailedOpenInvQst, GetLastErrorText)) then
                        PAGE.Run(PAGE::"Purchase Invoice", PurchHeader);
                end else
                    Error(CreatingInvFailedNothingCreatedErr, GetLastErrorText);
            end;
            exit(false);
        end;
        exit(true);
    end;

    local procedure CreateCopyDocument(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header")
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        Clear(PurchHeader);
        PurchHeader."No." := '';
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader.Insert(true);
        CopyDocMgt.SetPropertiesForInvoiceCorrection(false);
        CopyDocMgt.CopyPurchDocForCrMemoCancelling(PurchCrMemoHdr."No.", PurchHeader);
        PurchHeader."Vendor Invoice No." := PurchHeader."No.";
    end;

    procedure TestCorrectCrMemoIsAllowed(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        TestIfPostingIsAllowed(PurchCrMemoHdr);
        TestIfVendorIsBlocked(PurchCrMemoHdr, PurchCrMemoHdr."Buy-from Vendor No.");
        TestIfVendorIsBlocked(PurchCrMemoHdr, PurchCrMemoHdr."Pay-to Vendor No.");
        TestIfInvoiceIsCorrectedOnce(PurchCrMemoHdr);
        TestIfCrMemoIsCorrectiveDoc(PurchCrMemoHdr);
        TestVendorDimension(PurchCrMemoHdr, PurchCrMemoHdr."Pay-to Vendor No.");
        TestDimensionOnHeader(PurchCrMemoHdr);
        TestPurchLines(PurchCrMemoHdr);
        TestIfAnyFreeNumberSeries(PurchCrMemoHdr);
        TestExternalDocument(PurchCrMemoHdr);
        TestInventoryPostingClosed(PurchCrMemoHdr);
    end;

    local procedure SetTrackInfoForCancellation(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        PurchInvHeader.SetRange("Applies-to Doc. No.", PurchCrMemoHdr."No.");
        if PurchInvHeader.FindLast then
            CancelledDocument.InsertPurchCrMemoToInvCancelledDocument(PurchCrMemoHdr."No.", PurchInvHeader."No.");
    end;

    local procedure TestDimensionOnHeader(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if not DimensionManagement.CheckDimIDComb(PurchCrMemoHdr."Dimension Set ID") then
            ErrorHelperHeader(ErrorType::DimCombHeaderErr, PurchCrMemoHdr);
    end;

    local procedure TestIfVendorIsBlocked(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; VendNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendNo);
        if Vendor.Blocked = Vendor.Blocked::All then
            ErrorHelperHeader(ErrorType::VendorBlocked, PurchCrMemoHdr);
    end;

    local procedure TestIfAppliedCorrectly(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; VendLedgEntry: Record "Vendor Ledger Entry")
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PartiallyApplied: Boolean;
    begin
        VendLedgEntry.CalcFields(Amount, "Remaining Amount");
        PartiallyApplied :=
          ((VendLedgEntry.Amount <> VendLedgEntry."Remaining Amount") and (VendLedgEntry."Remaining Amount" <> 0));
        if (CalcDtldVendLedgEntryCount(DetailedVendLedgEntry."Entry Type"::"Initial Entry", VendLedgEntry."Entry No.") <> 1) or
           (not (CalcDtldVendLedgEntryCount(DetailedVendLedgEntry."Entry Type"::Application, VendLedgEntry."Entry No.") in [0, 1])) or
           AnyDtldVendLedgEntriesExceptInitialAndApplicaltionExists(VendLedgEntry."Entry No.") or
           PartiallyApplied
        then
            ErrorHelperHeader(ErrorType::IsAppliedIncorrectly, PurchCrMemoHdr);
    end;

    local procedure TestIfUnapplied(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        PurchCrMemoHdr.CalcFields("Remaining Amount");
        if PurchCrMemoHdr."Amount Including VAT" <> -PurchCrMemoHdr."Remaining Amount" then
            ErrorHelperHeader(ErrorType::IsUnapplied, PurchCrMemoHdr);
    end;

    local procedure TestVendorDimension(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; VendNo: Code[20])
    var
        Vendor: Record Vendor;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        Vendor.Get(VendNo);
        TableID[1] := DATABASE::Vendor;
        No[1] := Vendor."No.";
        if not DimensionManagement.CheckDimValuePosting(TableID, No, PurchCrMemoHdr."Dimension Set ID") then
            ErrorHelperAccount(ErrorType::DimErr, Vendor.TableCaption, Vendor."No.", Vendor."No.", Vendor.Name);
    end;

    local procedure TestPurchLines(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        if PurchCrMemoLine.Find('-') then
            repeat
                if not IsCommentLine(PurchCrMemoLine) then begin
                    if PurchCrMemoLine.Type = PurchCrMemoLine.Type::Item then begin
                        Item.Get(PurchCrMemoLine."No.");

                        if Item.Blocked then
                            ErrorHelperLine(ErrorType::ItemBlocked, PurchCrMemoLine);

                        TableID[1] := DATABASE::Item;
                        No[1] := PurchCrMemoLine."No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, PurchCrMemoLine."Dimension Set ID") then
                            ErrorHelperAccount(ErrorType::DimErr, Item.TableCaption, No[1], Item."No.", Item.Description);

                        if Item.Type = Item.Type::Inventory then
                            TestInventoryPostingSetup(PurchCrMemoLine);
                    end;

                    TestGenPostingSetup(PurchCrMemoLine);
                    TestVendorPostingGroup(PurchCrMemoLine, PurchCrMemoHdr."Vendor Posting Group");
                    TestVATPostingSetup(PurchCrMemoLine);

                    if not DimensionManagement.CheckDimIDComb(PurchCrMemoLine."Dimension Set ID") then
                        ErrorHelperLine(ErrorType::DimCombErr, PurchCrMemoLine);
                end;
            until PurchCrMemoLine.Next = 0;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
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

        if PurchCrMemoLine.Type = PurchCrMemoLine.Type::Item then begin
            Item.Get(PurchCrMemoLine."No.");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, PurchCrMemoLine."Dimension Set ID") then
                ErrorHelperAccount(ErrorType::DimErr, GLAccount.TableCaption, AccountNo, Item."No.", Item.Description);
        end;
    end;

    local procedure TestIfInvoiceIsCorrectedOnce(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if CancelledDocument.FindPurchCancelledCrMemo(PurchCrMemoHdr."No.") then
            ErrorHelperHeader(ErrorType::IsCorrected, PurchCrMemoHdr);
    end;

    local procedure TestIfCrMemoIsCorrectiveDoc(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if not CancelledDocument.FindPurchCorrectiveCrMemo(PurchCrMemoHdr."No.") then
            ErrorHelperHeader(ErrorType::IsCanceled, PurchCrMemoHdr);
    end;

    local procedure TestIfPostingIsAllowed(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(PurchCrMemoHdr."Posting Date") then
            ErrorHelperHeader(ErrorType::PostingNotAllowed, PurchCrMemoHdr);
    end;

    local procedure TestIfAnyFreeNumberSeries(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PostingDate: Date;
    begin
        PostingDate := WorkDate;
        PurchasesPayablesSetup.Get();

        if NoSeriesManagement.TryGetNextNo(PurchasesPayablesSetup."Invoice Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumInv, PurchCrMemoHdr);

        if NoSeriesManagement.TryGetNextNo(PurchasesPayablesSetup."Posted Invoice Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumPostInv, PurchCrMemoHdr);
    end;

    local procedure TestExternalDocument(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        if (PurchCrMemoHdr."Vendor Cr. Memo No." = '') and PurchasesPayablesSetup."Ext. Doc. No. Mandatory" then
            ErrorHelperHeader(ErrorType::ExtDocErr, PurchCrMemoHdr);
    end;

    local procedure TestInventoryPostingClosed(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        InventoryPeriod: Record "Inventory Period";
    begin
        InventoryPeriod.SetRange(Closed, true);
        InventoryPeriod.SetFilter("Ending Date", '>=%1', PurchCrMemoHdr."Posting Date");
        if InventoryPeriod.FindFirst then
            ErrorHelperHeader(ErrorType::InventoryPostClosed, PurchCrMemoHdr);
    end;

    local procedure TestGenPostingSetup(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        Item: Record Item;
    begin
        with GenPostingSetup do begin
            Get(PurchCrMemoLine."Gen. Bus. Posting Group", PurchCrMemoLine."Gen. Prod. Posting Group");
            TestField("Purch. Account");
            TestGLAccount("Purch. Account", PurchCrMemoLine);
            TestField("Purch. Credit Memo Account");
            TestGLAccount("Purch. Credit Memo Account", PurchCrMemoLine);
            TestField("Purch. Line Disc. Account");
            TestGLAccount("Purch. Line Disc. Account", PurchCrMemoLine);
            if PurchCrMemoLine.Type = PurchCrMemoLine.Type::Item then begin
                Item.Get(PurchCrMemoLine."No.");
                if Item.IsInventoriableType then
                    TestGLAccount(GetCOGSAccount, PurchCrMemoLine);
            end;
        end;
    end;

    local procedure TestVendorPostingGroup(PurchCrMemoLine: Record "Purch. Cr. Memo Line"; VendorPostingGr: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        with VendorPostingGroup do begin
            Get(VendorPostingGr);
            TestField("Payables Account");
            TestGLAccount("Payables Account", PurchCrMemoLine);
        end;
    end;

    local procedure TestVATPostingSetup(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with VATPostingSetup do begin
            Get(PurchCrMemoLine."VAT Bus. Posting Group", PurchCrMemoLine."VAT Prod. Posting Group");
            if "VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax" then begin
                TestField("Purchase VAT Account");
                TestGLAccount("Purchase VAT Account", PurchCrMemoLine);
            end;
        end;
    end;

    local procedure TestInventoryPostingSetup(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        with InventoryPostingSetup do begin
            Get(PurchCrMemoLine."Location Code", PurchCrMemoLine."Posting Group");
            TestField("Inventory Account");
            TestGLAccount("Inventory Account", PurchCrMemoLine);
        end;
    end;

    local procedure UnapplyEntries(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        FindVendLedgEntry(VendorLedgerEntry, PurchCrMemoHdr."No.");
        TestIfAppliedCorrectly(PurchCrMemoHdr, VendorLedgerEntry);
        if VendorLedgerEntry.Open then
            exit;

        FindDetailedApplicationEntry(DetailedVendLedgEntry, VendorLedgerEntry);
        VendEntryApplyPostedEntries.PostUnApplyVendor(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Document No.", DetailedVendLedgEntry."Posting Date");
        TestIfUnapplied(PurchCrMemoHdr);
    end;

    local procedure FindVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.SetRange("Document No.", DocNo);
        VendorLedgerEntry.FindLast;
    end;

    local procedure FindDetailedApplicationEntry(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
        DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::Application);
        DetailedVendLedgEntry.SetRange("Vendor No.", VendLedgerEntry."Vendor No.");
        DetailedVendLedgEntry.SetRange("Document No.", VendLedgerEntry."Document No.");
        DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgerEntry."Entry No.");
        DetailedVendLedgEntry.SetRange(Unapplied, false);
        DetailedVendLedgEntry.FindFirst;
    end;

    local procedure AnyDtldVendLedgEntriesExceptInitialAndApplicaltionExists(VendLedgEntryNo: Integer): Boolean
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendLedgEntry.SetFilter(
          "Entry Type", '<>%1&<>%2', DetailedVendLedgEntry."Entry Type"::"Initial Entry", DetailedVendLedgEntry."Entry Type"::Application);
        DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        exit(not DetailedVendLedgEntry.IsEmpty);
    end;

    local procedure CalcDtldVendLedgEntryCount(EntryType: Option; VendLedgEntryNo: Integer): Integer
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DetailedVendLedgEntry.SetRange(Unapplied, false);
        exit(DetailedVendLedgEntry.Count);
    end;

    local procedure IsCommentLine(PurchCrMemoLine: Record "Purch. Cr. Memo Line"): Boolean
    begin
        exit((PurchCrMemoLine.Type = PurchCrMemoLine.Type::" ") or (PurchCrMemoLine."No." = ''));
    end;

    local procedure ErrorHelperHeader(ErrorOption: Option; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        Vendor: Record Vendor;
    begin
        case ErrorOption of
            ErrorType::VendorBlocked:
                begin
                    Vendor.Get(PurchCrMemoHdr."Pay-to Vendor No.");
                    Error(VendorIsBlockedCancelErr, Vendor.Name);
                end;
            ErrorType::IsAppliedIncorrectly:
                Error(NotAppliedCorrectlyErr);
            ErrorType::IsUnapplied:
                Error(UnappliedErr);
            ErrorType::IsCorrected:
                Error(AlreadyCancelledErr);
            ErrorType::IsCanceled:
                Error(NotCorrectiveDocErr);
            ErrorType::SerieNumInv:
                Error(NoFreeInvoiceNoSeriesCancelErr);
            ErrorType::SerieNumPostInv:
                Error(NoFreePostInvSeriesCancelErr);
            ErrorType::PostingNotAllowed:
                Error(PostingNotAllowedCancelErr);
            ErrorType::ExtDocErr:
                Error(ExternalDocCancelErr);
            ErrorType::InventoryPostClosed:
                Error(InventoryPostClosedCancelErr);
            ErrorType::DimCombHeaderErr:
                Error(InvalidDimCombHeaderCancelErr);
        end
    end;

    local procedure ErrorHelperLine(ErrorOption: Option; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        Item: Record Item;
    begin
        case ErrorOption of
            ErrorType::ItemBlocked:
                begin
                    Item.Get(PurchCrMemoLine."No.");
                    Error(ItemIsBlockedCancelErr, Item."No.", Item.Description);
                end;
            ErrorType::DimCombErr:
                Error(InvalidDimCombinationCancelErr, PurchCrMemoLine."No.", PurchCrMemoLine.Description);
        end
    end;

    local procedure ErrorHelperAccount(ErrorOption: Option; AccountNo: Code[20]; AccountCaption: Text; No: Code[20]; Name: Text)
    begin
        case ErrorOption of
            ErrorType::AccountBlocked:
                Error(AccountIsBlockedCancelErr, AccountCaption, AccountNo);
            ErrorType::DimErr:
                Error(InvalidDimCodeCancelErr, AccountCaption, AccountNo, No, Name);
        end;
    end;
}

