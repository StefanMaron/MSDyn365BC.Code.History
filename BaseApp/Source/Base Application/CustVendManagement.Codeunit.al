codeunit 11767 CustVendManagement
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure FillCVBuffer(var CurrencyBuf: Record Currency temporary; var CVLedgEntry: Record "CV Ledger Entry Buffer" temporary; CustomerNo: Code[20]; VendorNo: Code[20]; AtDate: Date; AmountsInCurrency: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        NextEntryNo: Integer;
    begin
        CurrencyBuf.Reset();
        CurrencyBuf.DeleteAll();
        CVLedgEntry.Reset();
        CVLedgEntry.DeleteAll();
        NextEntryNo := 0;

        if not AmountsInCurrency then begin
            CurrencyBuf.Code := '';
            CurrencyBuf.Insert();
        end;

        with CustLedgEntry do begin
            SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
            SetRange("Customer No.", CustomerNo);
            SetFilter("Posting Date", '..%1', AtDate);
            if FindSet then
                repeat
                    SetFilter("Date Filter", '..%1', AtDate);
                    CalcFields("Remaining Amount");
                    if "Remaining Amount" <> 0 then begin
                        NextEntryNo += 1;
                        CVLedgEntry."Entry No." := NextEntryNo;
                        CVLedgEntry."Document Date" := "Document Date";
                        CVLedgEntry."Document Type" := "Document Type";
                        CVLedgEntry."Document No." := "Document No.";
                        CVLedgEntry."External Document No." := "External Document No.";
                        CVLedgEntry."Currency Code" := "Currency Code";
                        CVLedgEntry."Due Date" := "Due Date";
                        CalcFields(Amount, "Remaining Amount", "Remaining Amt. (LCY)");
                        CVLedgEntry.Amount := Amount;
                        CVLedgEntry."Remaining Amount" := "Remaining Amount";
                        CVLedgEntry."Remaining Amt. (LCY)" := "Remaining Amt. (LCY)";
                        CVLedgEntry.Insert();
                        if AmountsInCurrency then
                            if not CurrencyBuf.Get("Currency Code") then begin
                                CurrencyBuf.Code := "Currency Code";
                                CurrencyBuf.Insert();
                            end;
                    end;
                until Next = 0;
        end;
        with VendLedgEntry do begin
            SetCurrentKey("Vendor No.", "Posting Date", "Currency Code");
            SetRange("Vendor No.", VendorNo);
            SetFilter("Posting Date", '..%1', AtDate);
            if FindSet then
                repeat
                    SetFilter("Date Filter", '..%1', AtDate);
                    CalcFields("Remaining Amount");
                    if "Remaining Amount" <> 0 then begin
                        NextEntryNo += 1;
                        CVLedgEntry."Entry No." := NextEntryNo;
                        CVLedgEntry."Document Date" := "Document Date";
                        CVLedgEntry."Document Type" := "Document Type";
                        CVLedgEntry."Document No." := "Document No.";
                        CVLedgEntry."External Document No." := "External Document No.";
                        CVLedgEntry."Currency Code" := "Currency Code";
                        CVLedgEntry."Due Date" := "Due Date";
                        CalcFields(Amount, "Remaining Amount", "Remaining Amt. (LCY)");
                        CVLedgEntry.Amount := Amount;
                        CVLedgEntry."Remaining Amount" := "Remaining Amount";
                        CVLedgEntry."Remaining Amt. (LCY)" := "Remaining Amt. (LCY)";
                        CVLedgEntry.Insert();
                        if AmountsInCurrency then
                            if not CurrencyBuf.Get("Currency Code") then begin
                                CurrencyBuf.Code := "Currency Code";
                                CurrencyBuf.Insert();
                            end;
                    end;
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcCVDebt(CustomerNo: Code[20]; VendorNo: Code[20]; CurrencyCode: Code[10]; Date: Date; InLCY: Boolean) TotalAmount: Decimal
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        if CustomerNo <> '' then begin
            Customer.Get(CustomerNo);
            Customer.SetFilter("Date Filter", '..%1', Date);
            if InLCY then
                Customer.CalcFields("Net Change (LCY)")
            else begin
                Customer.SetFilter("Currency Filter", '%1', CurrencyCode);
                Customer.CalcFields("Net Change");
            end;
        end;
        if VendorNo <> '' then begin
            Vendor.Get(VendorNo);
            Vendor.SetFilter("Date Filter", '..%1', Date);
            if InLCY then
                Vendor.CalcFields("Net Change (LCY)")
            else begin
                Vendor.SetFilter("Currency Filter", '%1', CurrencyCode);
                Vendor.CalcFields("Net Change");
            end;
        end;
        if InLCY then
            TotalAmount := Customer."Net Change (LCY)" - Vendor."Net Change (LCY)"
        else
            TotalAmount := Customer."Net Change" - Vendor."Net Change";
    end;
}

