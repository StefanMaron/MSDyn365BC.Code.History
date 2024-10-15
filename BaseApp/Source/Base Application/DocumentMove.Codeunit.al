codeunit 7000004 "Document-Move"
{
    Permissions = TableData "Closed Cartera Doc." = imd,
                  TableData "Closed Bill Group" = imd,
                  TableData "Closed Payment Order" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text1100000: Label 'You cannot delete a bank account with bill groups in preparation.';
        Text1100001: Label 'You cannot delete a bank account with bill groups.';
        Text1100002: Label 'You cannot delete a bank account with closed bill groups in a fiscal year that has not been closed yet.';
        Text1100003: Label 'You cannot delete a bank account with payment orders in preparation.';
        Text1100004: Label 'You cannot delete a bank account with payment orders.';
        Text1100005: Label 'You cannot delete a bank account with closed payment orders in a fiscal year that has not been closed yet.';
        AccountingPeriod: Record "Accounting Period";
        BillGr: Record "Bill Group";
        BillGr2: Record "Bill Group";
        PostedBillGr: Record "Posted Bill Group";
        PostedBillGr2: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        ClosedBillGr2: Record "Closed Bill Group";
        ClosedDoc: Record "Closed Cartera Doc.";
        PmtOrd: Record "Payment Order";
        PmtOrd2: Record "Payment Order";
        PostedPmtOrd: Record "Posted Payment Order";
        PostedPmtOrd2: Record "Posted Payment Order";
        ClosedPmtOrd: Record "Closed Payment Order";
        ClosedPmtOrd2: Record "Closed Payment Order";

    [Scope('OnPrem')]
    procedure MoveBankAccDocs(BankAcc: Record "Bank Account")
    begin
        with BillGr do begin
            LockTable();
            if BillGr2.FindLast then;
            Reset;
            SetCurrentKey("Bank Account No.");
            SetRange("Bank Account No.", BankAcc."No.");
            if FindFirst then
                Error(Text1100000);
        end;

        with PostedBillGr do begin
            LockTable();
            if PostedBillGr2.FindLast then;
            Reset;
            SetCurrentKey("Bank Account No.");
            SetRange("Bank Account No.", BankAcc."No.");
            if FindFirst then
                Error(Text1100001);
        end;

        with ClosedBillGr do begin
            LockTable();
            if ClosedBillGr2.FindLast then;
            Reset;
            SetCurrentKey("Bank Account No.");
            SetRange("Bank Account No.", BankAcc."No.");
            AccountingPeriod.SetRange(Closed, false);
            if AccountingPeriod.FindFirst then
                SetFilter("Closing Date", '>=%1', AccountingPeriod."Starting Date");
            if FindFirst then
                Error(Text1100002);
            SetRange("Closing Date");
            ModifyAll("Bank Account No.", '');
        end;

        with PmtOrd do begin
            LockTable();
            if PmtOrd2.FindLast then;
            Reset;
            SetCurrentKey("Bank Account No.");
            SetRange("Bank Account No.", BankAcc."No.");
            if FindFirst then
                Error(Text1100003);
        end;

        with PostedPmtOrd do begin
            LockTable();
            if PostedPmtOrd2.FindLast then;
            Reset;
            SetCurrentKey("Bank Account No.");
            SetRange("Bank Account No.", BankAcc."No.");
            if FindFirst then
                Error(Text1100004);
        end;

        with ClosedPmtOrd do begin
            LockTable();
            if ClosedPmtOrd2.FindLast then;
            Reset;
            SetCurrentKey("Bank Account No.");
            SetRange("Bank Account No.", BankAcc."No.");
            AccountingPeriod.SetRange(Closed, false);
            if AccountingPeriod.FindFirst then
                SetFilter("Closing Date", '>=%1', AccountingPeriod."Starting Date");
            if FindFirst then
                Error(Text1100005);
            SetRange("Closing Date");
            ModifyAll("Bank Account No.", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure MoveReceivableDocs(Cust: Record Customer)
    begin
        with ClosedDoc do begin
            Reset;
            SetCurrentKey("Account No.", "Honored/Rejtd. at Date");
            SetRange("Account No.", Cust."No.");
            ModifyAll("Account No.", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure MovePayableDocs(Vend: Record Vendor)
    begin
        with ClosedDoc do begin
            Reset;
            SetCurrentKey("Account No.", "Honored/Rejtd. at Date");
            SetRange("Account No.", Vend."No.");
            ModifyAll("Account No.", '');
        end;
    end;
}

