codeunit 10880 "Payment Reporting Mgt."
{
    Permissions = TableData "Detailed Cust. Ledg. Entry" = rm,
                  TableData "Detailed Vendor Ledg. Entry" = rm;

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure BuildVendPmtApplicationBuffer(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; StartingDate: Date; EndingDate: Date; PaymentsWithinPeriod: Boolean)
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        LastVendNo: Code[20];
        TotalPmtAmount: Decimal;
        CorrectionAmount: Decimal;
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
                if Vendor."Exclude from Payment Reporting" then begin
                    // Skip all entries associated with this Vendor
                    VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
                    VendorLedgerEntry.FindLast();
                    VendorLedgerEntry.SetRange("Vendor No.");
                end else begin
                    TotalPmtAmount := 0;
                    CorrectionAmount := 0;
                    if HasAppliedPmtVendLedgEntries(TempDtldVendLedgEntry, CorrectionAmount, VendorLedgerEntry) then begin
                        if PaymentsWithinPeriod then
                            TempDtldVendLedgEntry.SetRange("Posting Date", StartingDate, EndingDate);
                        if TempDtldVendLedgEntry.FindSet() then
                            repeat
                                TempPaymentApplicationBuffer.InsertVendorPayment(VendorLedgerEntry, TempDtldVendLedgEntry);
                                TotalPmtAmount += TempPaymentApplicationBuffer."Pmt. Amount (LCY)";
                            until TempDtldVendLedgEntry.Next() = 0;
                        TempDtldVendLedgEntry.DeleteAll();
                    end;

                    TempPaymentApplicationBuffer.InsertVendorInvoice(VendorLedgerEntry, TotalPmtAmount, CorrectionAmount);
                end;
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure HasAppliedPmtVendLedgEntries(var TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var CorrectionAmount: Decimal; InvVendorLedgerEntry: Record "Vendor Ledger Entry") Paid: Boolean
    var
        InvDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PmtDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        InvVendorLedgerEntry.TestField("Document Type", InvVendorLedgerEntry."Document Type"::Invoice);
        InvDtldVendLedgEntry.SetRange("Entry Type", InvDtldVendLedgEntry."Entry Type"::Application);
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
                                HandleAppliedVendLedgEntry(
                                  TempDtldVendLedgEntry, Paid, CorrectionAmount, PmtDtldVendLedgEntry);
                        until PmtDtldVendLedgEntry.Next() = 0;
                end else
                    HandleAppliedVendLedgEntry(
                      TempDtldVendLedgEntry, Paid, CorrectionAmount, InvDtldVendLedgEntry);
            until InvDtldVendLedgEntry.Next() = 0;
        exit(Paid);
    end;

    local procedure HandleAppliedVendLedgEntry(var TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var Paid: Boolean; var CorrectionAmount: Decimal; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        if DtldVendLedgEntry."Document Type" = DtldVendLedgEntry."Document Type"::Payment then begin
            TempDtldVendLedgEntry := DtldVendLedgEntry;
            TempDtldVendLedgEntry.Insert();
            Paid := true;
        end else
            // Calculate the amount to be deducted from the invoice by credit memos and documents with blank type but not by payments which can be treated as paid in time or delayed
            CorrectionAmount += DtldVendLedgEntry."Amount (LCY)";
    end;

    [Scope('OnPrem')]
    procedure BuildCustPmtApplicationBuffer(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; StartingDate: Date; EndingDate: Date; PaymentsWithinPeriod: Boolean)
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        LastCustNo: Code[20];
        TotalPmtAmount: Decimal;
        CorrectionAmount: Decimal;
    begin
        TempPaymentApplicationBuffer.Reset();
        TempPaymentApplicationBuffer.DeleteAll();
        CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Posting Date", StartingDate, EndingDate);
        if CustLedgerEntry.FindSet() then
            repeat
                if LastCustNo <> CustLedgerEntry."Customer No." then begin
                    Customer.Get(CustLedgerEntry."Customer No.");
                    LastCustNo := Customer."No.";
                end;
                if Customer."Exclude from Payment Reporting" then begin
                    // Skip all entries associated with this Vendor
                    CustLedgerEntry.SetRange("Customer No.", Customer."No.");
                    CustLedgerEntry.FindLast();
                    CustLedgerEntry.SetRange("Customer No.");
                end else begin
                    TotalPmtAmount := 0;
                    CorrectionAmount := 0;
                    if HasAppliedPmtCustLedgEntries(TempDtldCustLedgEntry, CorrectionAmount, CustLedgerEntry) then begin
                        if PaymentsWithinPeriod then
                            TempDtldCustLedgEntry.SetRange("Posting Date", StartingDate, EndingDate);
                        if TempDtldCustLedgEntry.FindSet() then
                            repeat
                                TempPaymentApplicationBuffer.InsertCustomerPayment(CustLedgerEntry, TempDtldCustLedgEntry);
                                TotalPmtAmount += TempPaymentApplicationBuffer."Pmt. Amount (LCY)";
                            until TempDtldCustLedgEntry.Next() = 0;
                        TempDtldCustLedgEntry.DeleteAll();
                    end;

                    TempPaymentApplicationBuffer.InsertCustomerInvoice(CustLedgerEntry, TotalPmtAmount, CorrectionAmount);
                end;
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure HasAppliedPmtCustLedgEntries(var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; var CorrectionAmount: Decimal; InvCustLedgerEntry: Record "Cust. Ledger Entry") Paid: Boolean
    var
        InvDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PmtDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        InvCustLedgerEntry.TestField("Document Type", InvCustLedgerEntry."Document Type"::Invoice);
        InvDtldCustLedgEntry.SetRange("Entry Type", InvDtldCustLedgEntry."Entry Type"::Application);
        InvDtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", InvCustLedgerEntry."Entry No.");
        InvDtldCustLedgEntry.SetRange(Unapplied, false);
        if InvDtldCustLedgEntry.FindSet() then
            repeat
                if InvDtldCustLedgEntry."Cust. Ledger Entry No." =
                   InvDtldCustLedgEntry."Applied Cust. Ledger Entry No."
                then begin
                    PmtDtldCustLedgEntry.SetRange(
                      "Applied Cust. Ledger Entry No.", InvDtldCustLedgEntry."Applied Cust. Ledger Entry No.");
                    PmtDtldCustLedgEntry.SetRange("Entry Type", PmtDtldCustLedgEntry."Entry Type"::Application);
                    PmtDtldCustLedgEntry.SetRange(Unapplied, false);
                    if PmtDtldCustLedgEntry.FindSet() then
                        repeat
                            if PmtDtldCustLedgEntry."Cust. Ledger Entry No." <>
                               PmtDtldCustLedgEntry."Applied Cust. Ledger Entry No."
                            then
                                HandleAppliedCustLedgEntry(
                                  TempDtldCustLedgEntry, Paid, CorrectionAmount, PmtDtldCustLedgEntry);
                        until PmtDtldCustLedgEntry.Next() = 0;
                end else
                    HandleAppliedCustLedgEntry(
                      TempDtldCustLedgEntry, Paid, CorrectionAmount, InvDtldCustLedgEntry);
            until InvDtldCustLedgEntry.Next() = 0;
        exit(Paid);
    end;

    local procedure HandleAppliedCustLedgEntry(var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; var Paid: Boolean; var CorrectionAmount: Decimal; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        if DtldCustLedgEntry."Document Type" = DtldCustLedgEntry."Document Type"::Payment then begin
            TempDtldCustLedgEntry := DtldCustLedgEntry;
            TempDtldCustLedgEntry.Insert();
            Paid := true;
        end else
            // Calculate the amount to be deducted from the invoice by credit memos and documents with blank type but not by payments which can be treated as paid in time or delayed
            CorrectionAmount += DtldCustLedgEntry."Amount (LCY)";
    end;

    [Scope('OnPrem')]
    procedure GetTotalAmount(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary): Decimal
    begin
        TempPaymentApplicationBuffer.CalcSums("Entry Amount Corrected (LCY)");
        exit(TempPaymentApplicationBuffer."Entry Amount Corrected (LCY)");
    end;

    [Scope('OnPrem')]
    procedure PrepareNotPaidInDaysSource(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; DaysFrom: Integer; DaysTo: Integer): Boolean
    begin
        TempPaymentApplicationBuffer.Reset();
        TempPaymentApplicationBuffer.SetRange("Pmt. Entry No.", 0);
        TempPaymentApplicationBuffer.SetRange("Document Type", TempPaymentApplicationBuffer."Document Type"::Invoice);
        TempPaymentApplicationBuffer.SetRange("Invoice Is Open", true);
        if DaysTo <> 0 then
            TempPaymentApplicationBuffer.SetRange("Days Since Due Date", DaysFrom, DaysTo)
        else
            TempPaymentApplicationBuffer.SetFilter("Days Since Due Date", '%1..', DaysFrom);
        exit(TempPaymentApplicationBuffer.FindSet);
    end;

    [Scope('OnPrem')]
    procedure PrepareDelayedPmtInDaysSource(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; DaysFrom: Integer; DaysTo: Integer): Boolean
    begin
        TempPaymentApplicationBuffer.Reset();
        TempPaymentApplicationBuffer.SetFilter("Pmt. Entry No.", '<>%1', 0);
        if DaysTo <> 0 then
            TempPaymentApplicationBuffer.SetRange("Pmt. Days Delayed", DaysFrom, DaysTo)
        else
            TempPaymentApplicationBuffer.SetFilter("Pmt. Days Delayed", '%1..', DaysFrom);
        exit(TempPaymentApplicationBuffer.FindSet);
    end;

    [Scope('OnPrem')]
    procedure GetPctOfPmtsNotPaidInDays(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; TotalAmount: Decimal): Decimal
    begin
        if TotalAmount = 0 then
            exit(0);

        exit(Round(TempPaymentApplicationBuffer."Remaining Amount (LCY)" / TotalAmount * 100));
    end;

    [Scope('OnPrem')]
    procedure GetPctOfPmtsDelayedInDays(var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary; TotalAmount: Decimal): Decimal
    begin
        if TotalAmount = 0 then
            exit(0);

        exit(Abs(Round(TempPaymentApplicationBuffer."Pmt. Amount (LCY)" / TotalAmount * 100)));
    end;

    local procedure GetCustomerReceivablesAccount(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetVendorPayablesAccount(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    [Scope('OnPrem')]
    procedure UpdateUnrealizedAdjmtGLAccDtldCustLedgerEntries()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if Customer.FindSet() then
            repeat
                DetailedCustLedgEntry.SetRange("Customer No.", Customer."No.");
                DetailedCustLedgEntry.SetFilter(
                  "Entry Type", '%1|%2',
                  DetailedCustLedgEntry."Entry Type"::"Unrealized Gain", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
                if not DetailedCustLedgEntry.IsEmpty() then
                    DetailedCustLedgEntry.ModifyAll(
                      "Curr. Adjmt. G/L Account No.", GetCustomerReceivablesAccount(Customer."No."));
            until Customer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateUnrealizedAdjmtGLAccDtldVendLedgerEntries()
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if Vendor.FindSet() then
            repeat
                DetailedVendorLedgEntry.SetRange("Vendor No.", Vendor."No.");
                DetailedVendorLedgEntry.SetFilter(
                  "Entry Type", '%1|%2',
                  DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain", DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss");
                if not DetailedVendorLedgEntry.IsEmpty() then
                    DetailedVendorLedgEntry.ModifyAll(
                      "Curr. Adjmt. G/L Account No.", GetVendorPayablesAccount(Vendor."No."));
            until Vendor.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Exchange Rates", 'OnAfterInitDtldCustLedgerEntry', '', false, false)]
    local procedure UpdateDtldCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        DetailedCustLedgEntry."Curr. Adjmt. G/L Account No." := GetCustomerReceivablesAccount(DetailedCustLedgEntry."Customer No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Exchange Rates", 'OnAfterInitDtldVendLedgerEntry', '', false, false)]
    local procedure UpdateDtldVendLedgerEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        DetailedVendorLedgEntry."Curr. Adjmt. G/L Account No." := GetVendorPayablesAccount(DetailedVendorLedgEntry."Vendor No.");
    end;
}

