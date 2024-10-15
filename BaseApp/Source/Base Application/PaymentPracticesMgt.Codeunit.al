#if not CLEAN23
codeunit 10525 "Payment Practices Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit is obsolete. Replaced by W1 extension "Payment Practices".';
    ObsoleteTag = '23.0';

    trigger OnRun()
    begin
    end;

    var
        DaysFromLessThanDaysToErr: Label 'The value in the Days From field must be higher than the value in the Days To field.';
        DaysFromAndDaysToNotSpecifiedErr: Label 'Yoy must fill in the Days From and Days To fields.';

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeaderPayment', '', false, false)]
    local procedure FillInvoiceReceiptDateOnAfterCopyGenJnlLineFromPurchHeaderPayment(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
        GenJournalLine."Invoice Receipt Date" := PurchaseHeader."Invoice Receipt Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vend. Entry-Edit", 'OnBeforeVendLedgEntryModify', '', false, false)]
    local procedure UpdateInvoiceReceiptDateOnBeforeVendLedgEntryModify(var VendLedgEntry: Record "Vendor Ledger Entry"; FromVendLedgEntry: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry.Validate("Invoice Receipt Date", FromVendLedgEntry."Invoice Receipt Date");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInitRecord', '', false, false)]
    local procedure FillInvoiceReceiptDateOnAfterPurchHeaderInitRecord(var PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice] then
            PurchHeader."Invoice Receipt Date" := PurchHeader."Document Date";
    end;

    [Scope('OnPrem')]
    procedure BuildPmtApplicationBuffer(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; StartingDate: Date; EndingDate: Date)
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        LastVendNo: Code[20];
    begin
        TempPaymentApplicationBuffer.Reset();
        TempPaymentApplicationBuffer.DeleteAll();
        VendorLedgerEntry.SetCurrentKey("Vendor No.", "Posting Date", "Currency Code");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Posting Date", StartingDate, EndingDate);
        if VendorLedgerEntry.FindSet() then
            repeat
                if LastVendNo <> VendorLedgerEntry."Vendor No." then begin
                    Vendor.Get(VendorLedgerEntry."Vendor No.");
                    LastVendNo := Vendor."No.";
                end;
                if Vendor."Exclude from Pmt. Pract. Rep." then begin
                    // Skip all entries associated with this Vendor
                    VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
                    VendorLedgerEntry.FindLast();
                    VendorLedgerEntry.SetRange("Vendor No.");
                end else begin
                    if HasAppliedPmtVendLedgEntries(TempVendorLedgerEntry, VendorLedgerEntry) then begin
                        TempVendorLedgerEntry.FindSet();
                        repeat
                            TempPaymentApplicationBuffer.Init();
                            TempPaymentApplicationBuffer.CopyFromInvoiceVendLedgEntry(VendorLedgerEntry);
                            TempPaymentApplicationBuffer."Pmt. Entry No." := TempVendorLedgerEntry."Entry No.";
                            TempPaymentApplicationBuffer."Pmt. Posting Date" := TempVendorLedgerEntry."Posting Date";
                            TempPaymentApplicationBuffer.Insert();
                            TempVendorLedgerEntry.Delete();
                        until TempVendorLedgerEntry.Next() = 0;
                    end;
                    // If invoice not fully closed it should be considered for overdue calculation
                    if VendorLedgerEntry.Open then begin
                        TempPaymentApplicationBuffer.Init();
                        TempPaymentApplicationBuffer."Pmt. Entry No." := 0;
                        TempPaymentApplicationBuffer.CopyFromInvoiceVendLedgEntry(VendorLedgerEntry);
                        TempPaymentApplicationBuffer.Insert();
                    end;
                end;
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure HasAppliedPmtVendLedgEntries(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; InvVendorLedgerEntry: Record "Vendor Ledger Entry") Paid: Boolean
    var
        PmtVendorLedgerEntry: Record "Vendor Ledger Entry";
        InvDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PmtDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        InvVendorLedgerEntry.TestField("Document Type", InvVendorLedgerEntry."Document Type"::Invoice);
        InvDtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", InvVendorLedgerEntry."Entry No.");
        InvDtldVendLedgEntry.SetRange(Unapplied, false);
        if InvDtldVendLedgEntry.FindSet() then
            repeat
                if InvDtldVendLedgEntry."Vendor Ledger Entry No." =
                   InvDtldVendLedgEntry."Applied Vend. Ledger Entry No."
                then begin
                    PmtDtldVendLedgEntry.SetRange(
                      "Applied Vend. Ledger Entry No.", InvDtldVendLedgEntry."Applied Vend. Ledger Entry No.");
                    PmtDtldVendLedgEntry.SetRange("Entry Type", PmtDtldVendLedgEntry."Entry Type"::Application);
                    PmtDtldVendLedgEntry.SetRange(Unapplied, false);
                    if PmtDtldVendLedgEntry.FindSet() then
                        repeat
                            if PmtDtldVendLedgEntry."Vendor Ledger Entry No." <>
                               PmtDtldVendLedgEntry."Applied Vend. Ledger Entry No."
                            then
                                if PmtVendorLedgerEntry.Get(PmtDtldVendLedgEntry."Vendor Ledger Entry No.") and
                                   (PmtVendorLedgerEntry."Document Type" = PmtVendorLedgerEntry."Document Type"::Payment)
                                then begin
                                    TempVendorLedgerEntry := PmtVendorLedgerEntry;
                                    if TempVendorLedgerEntry.Insert() then;
                                    Paid := true;
                                end;
                        until PmtDtldVendLedgEntry.Next() = 0;
                end else
                    if PmtVendorLedgerEntry.Get(InvDtldVendLedgEntry."Applied Vend. Ledger Entry No.") and
                       (PmtVendorLedgerEntry."Document Type" = PmtVendorLedgerEntry."Document Type"::Payment)
                    then begin
                        TempVendorLedgerEntry := PmtVendorLedgerEntry;
                        if TempVendorLedgerEntry.Insert() then;
                        Paid := true;
                    end;
            until InvDtldVendLedgEntry.Next() = 0;
        exit(Paid);
    end;

    [Scope('OnPrem')]
    procedure GetAvgNumberOfDaysToMakePmt(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary): Integer
    var
        TotalDaysBetweenInvRcptDateAndPmtDate: Integer;
        TotalCount: Integer;
    begin
        TempPaymentApplicationBuffer.Reset();
        TempPaymentApplicationBuffer.SetFilter("Pmt. Entry No.", '<>%1', 0);
        TempPaymentApplicationBuffer.SetFilter("Pmt. Posting Date", '<>%1', 0D); // Consider only paid invoices
        if not TempPaymentApplicationBuffer.FindSet() then
            exit(0);

        repeat
            // If "Posting Date" less than "Invoice Receipt Date" than days between payment is zero
            if TempPaymentApplicationBuffer."Pmt. Posting Date" >= TempPaymentApplicationBuffer."Invoice Receipt Date" then begin
                TotalDaysBetweenInvRcptDateAndPmtDate +=
                  TempPaymentApplicationBuffer."Pmt. Posting Date" - TempPaymentApplicationBuffer."Invoice Receipt Date";
                // Mark records to show them as details in Payment Practices report
                TempPaymentApplicationBuffer.Mark(true);
                TotalCount += 1;
            end;
        until TempPaymentApplicationBuffer.Next() = 0;
        if TotalCount = 0 then
            exit(0);
        exit(Round(TotalDaysBetweenInvRcptDateAndPmtDate / TotalCount, 1));
    end;

    [Scope('OnPrem')]
    procedure GetPctOfPmtsPaidInDays(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; DaysFrom: Integer; DaysTo: Integer): Decimal
    var
        TotalPmtsPaidFromDaysFromToDaysTo: Integer;
        PaidInDays: Integer;
    begin
        if (DaysFrom <> 0) and (DaysTo <> 0) and (DaysFrom > DaysTo) then
            Error(DaysFromLessThanDaysToErr);
        if (DaysFrom = 0) and (DaysTo = 0) then
            Error(DaysFromAndDaysToNotSpecifiedErr);

        TempPaymentApplicationBuffer.Reset();
        TempPaymentApplicationBuffer.SetFilter("Pmt. Entry No.", '<>%1', 0);
        if not TempPaymentApplicationBuffer.FindSet() then
            exit(0);

        repeat
            // If "Posting Date" less than "Invoice Receipt Date" than days between payment is zero
            PaidInDays := TempPaymentApplicationBuffer."Pmt. Posting Date" - TempPaymentApplicationBuffer."Invoice Receipt Date";
            if PaidInDays < 0 then
                PaidInDays := 0;
            if ((DaysFrom = 0) and (PaidInDays <= DaysTo)) or
               ((DaysTo = 0) and (PaidInDays >= DaysFrom)) or
               ((DaysFrom <> 0) and (DaysTo <> 0) and (PaidInDays in [DaysFrom .. DaysTo]))
            then
                TotalPmtsPaidFromDaysFromToDaysTo += 1;
        until TempPaymentApplicationBuffer.Next() = 0;
        exit(Round(TotalPmtsPaidFromDaysFromToDaysTo / TempPaymentApplicationBuffer.Count * 100));
    end;

    [Scope('OnPrem')]
    procedure GetPctOfPmtsNotPaid(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary): Decimal
    var
        Total: Integer;
        OverduePmts: Integer;
    begin
        TempPaymentApplicationBuffer.Reset();
        if not TempPaymentApplicationBuffer.FindSet() then
            exit(0);

        repeat
            TempPaymentApplicationBuffer.SetRange("Invoice Entry No.", TempPaymentApplicationBuffer."Invoice Entry No."); // consider both invoice and all partial payments
            if not TempPaymentApplicationBuffer."Invoice Is Open" then begin
                // If invoice is fully paid, investigate all partial payments if some of them were paid not withing agreed terms
                TempPaymentApplicationBuffer.SetFilter("Pmt. Entry No.", '<>%1', 0);
                TempPaymentApplicationBuffer.FindSet();
                repeat
                    if TempPaymentApplicationBuffer."Pmt. Posting Date" > TempPaymentApplicationBuffer."Due Date" then begin
                        OverduePmts += 1;
                        TempPaymentApplicationBuffer.Mark(true);
                        TempPaymentApplicationBuffer.FindLast(); // if at least one partial payment are not paid within agreed terms then treat the whole invoice as not paid within agreed terms
                    end;
                until TempPaymentApplicationBuffer.Next() = 0;
                TempPaymentApplicationBuffer.SetRange("Pmt. Entry No.");
            end else
                if TempPaymentApplicationBuffer."Due Date" < WorkDate then begin
                    OverduePmts += 1;
                    // Mark records to show them as details in Payment Practices report
                    TempPaymentApplicationBuffer.Mark(true);
                    TempPaymentApplicationBuffer.FindLast(); // if invoice is not fully paid then do not consider partial payments and treat the whole invoice as not paid within agreed terms
                end;
            TempPaymentApplicationBuffer.SetRange("Invoice Entry No.");
            Total += 1;
        until TempPaymentApplicationBuffer.Next() = 0;
        exit(Round(OverduePmts / Total * 100));
    end;
}
#endif
