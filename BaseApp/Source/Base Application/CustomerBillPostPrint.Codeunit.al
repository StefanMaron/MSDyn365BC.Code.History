codeunit 12172 "Customer Bill - Post + Print"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd;
    TableNo = "Customer Bill Header";

    trigger OnRun()
    var
        HideDialog: Boolean;
    begin
        HideDialog := false;

        OnBeforeConfirmPost(Rec, HideDialog);
        if not HideDialog then
            if not Confirm(PostAndPrintQst, false, TableCaption, "No.") then
                exit;

        Code(Rec);
    end;

    var
        PostAndPrintQst: Label 'Do you want to post and print %1 %2?', Comment = '%1 = table caption, %2 = document no.';
        BillCode: Record Bill;
        InvalidListDateErr: Label 'The List Date must be greater than the Document Date of Customer Bill Line %1.';
        NoSeriesMgt: Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        Text1130012: Label 'Posting Customer Bill...\\';
        Text1130013: Label 'G/L Account       #1##################\';
        Text1130014: Label 'Customer Bill No. #2##################\';
        Text1130015: Label 'Bank Receipt No.  #3##################\';
        BRNumber: Code[20];
        InvalidRemainingAmountErr: Label 'The Remaining Amount has been modified for customer entry Document No.: %1, Document Occurrence: %2. The new amount is %3.', Comment = '%1 - document number, %2 - document occurence, 3 - amount.';
        NothingToPostErr: Label 'There is nothing to post.';
        ListNumber: Code[20];
        HidePrintDialog: Boolean;
        HTMLPath: Text[1024];
        Text12100: Label 'is not within your range of allowed posting dates';

    [Scope('OnPrem')]
    procedure "Code"(var LocalCustomerBillHeader: Record "Customer Bill Header")
    var
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerBillLine: Record "Customer Bill Line";
        IssuedCustBillHeader: Record "Issued Customer Bill Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        OldCustBillLine: Record "Customer Bill Line";
        BankAcc: Record "Bank Account";
        BillPostingGroup: Record "Bill Posting Group";
        BalanceAmount: Decimal;
    begin
        CustomerBillHeader.Copy(LocalCustomerBillHeader);

        OnBeforePost(CustomerBillHeader);

        with CustomerBillHeader do begin
            CheckCustBill(CustomerBillHeader);

            BankAcc.Get("Bank Account No.");
            BillPostingGroup.Get("Bank Account No.", "Payment Method Code");

            case Type of
                Type::"Bills For Collection":
                    BillPostingGroup.TestField("Bills For Collection Acc. No.");
                Type::"Bills For Discount":
                    BillPostingGroup.TestField("Bills For Discount Acc. No.");
                Type::"Bills Subject To Collection":
                    BillPostingGroup.TestField("Bills Subj. to Coll. Acc. No.");
            end;

            Window.Open(
              Text1130012 + Text1130013 + Text1130014 + Text1130015);

            "Test Report" := false;
            ListNumber := NoSeriesMgt.GetNextNo(BillCode."List No.", "List Date", true);
            Modify;

            CustomerBillLine.SetRange("Customer Bill No.", "No.");
            CustomerBillLine.SetCurrentKey("Customer No.", "Due Date", "Customer Bank Acc. No.", "Cumulative Bank Receipts");
            if CustomerBillLine.FindSet() then begin
                InsertIssuedBillHeader(IssuedCustBillHeader, CustomerBillHeader, BillCode, ListNumber);

                OldCustBillLine := CustomerBillLine;
                CustLedgEntry.LockTable();
                BalanceAmount := 0;
                BRNumber := NoSeriesMgt.GetNextNo(BillCode."Final Bill No.", "List Date", true);
                repeat
                    CustomerBillLine.TestField(Amount);
                    if CustomerBillLine."Document Date" > "List Date" then
                        Error(InvalidListDateErr, CustomerBillLine."Line No.");
                    CustomerBillLine.TestField("Due Date");

                    if (OldCustBillLine."Customer No." <> CustomerBillLine."Customer No.") or
                       (OldCustBillLine."Due Date" <> CustomerBillLine."Due Date") or
                       (OldCustBillLine."Customer Bank Acc. No." <> CustomerBillLine."Customer Bank Acc. No.") or
                       (OldCustBillLine."Cumulative Bank Receipts" <> CustomerBillLine."Cumulative Bank Receipts")
                    then
                        if OldCustBillLine."Cumulative Bank Receipts" then
                            BRNumber := NoSeriesMgt.GetNextNo(BillCode."Final Bill No.", "List Date", true);

                    UpdateCustLedgEntry(CustLedgEntry, CustomerBillLine);

                    BalanceAmount := BalanceAmount + CustomerBillLine.Amount;

                    PostCustBillLine(CustomerBillHeader, CustomerBillLine, CustLedgEntry);

                    InsertIssuedBillLine(CustomerBillLine, ListNumber, BRNumber);

                    if not CustomerBillLine."Cumulative Bank Receipts" then
                        BRNumber := NoSeriesMgt.GetNextNo(BillCode."Final Bill No.", "List Date", true);

                    OldCustBillLine := CustomerBillLine;
                until CustomerBillLine.Next() = 0;
                PostBalanceAccount(CustomerBillHeader, CustLedgEntry, BillPostingGroup, BalanceAmount);

                CustomerBillLine.DeleteAll(true);
                Delete(true);

                Window.Close;
                Commit();

                OnAfterPost(CustomerBillHeader, IssuedCustBillHeader);

                IssuedCustBillHeader.SetRecFilter;
                if HidePrintDialog then
                    REPORT.SaveAsPdf(REPORT::"Issued Cust Bills Report", HTMLPath, IssuedCustBillHeader)
                else
                    REPORT.RunModal(REPORT::"Issued Cust Bills Report", false, false, IssuedCustBillHeader);
            end else
                Error(NothingToPostErr);
        end;
    end;

    local procedure CheckCustBill(CustomerBillHeader: Record "Customer Bill Header")
    var
        PaymentMethod: Record "Payment Method";
    begin
        with CustomerBillHeader do begin
            TestField(Type);
            TestField("Bank Account No.");
            TestField("List Date");
            TestField("Posting Date");
            TestField("Payment Method Code");

            PaymentMethod.Get("Payment Method Code");
            BillCode.Get(PaymentMethod."Bill Code");

            BillCode.TestField("List No.");
            BillCode.TestField("Final Bill No.");
            if BillCode."Allow Issue" then
                BillCode.TestField("Bills for Coll. Temp. Acc. No.");
        end;
    end;

    local procedure InsertIssuedBillHeader(var IssuedCustBillHeader: Record "Issued Customer Bill Header"; CustomerBillHeader: Record "Customer Bill Header"; BillCode: Record Bill; ListNo: Code[20])
    begin
        IssuedCustBillHeader.Init();
        IssuedCustBillHeader.TransferFields(CustomerBillHeader);
        IssuedCustBillHeader."No. Series" := BillCode."List No.";
        IssuedCustBillHeader."No." := ListNo;
        IssuedCustBillHeader."User ID" := UserId;
        IssuedCustBillHeader.Insert();
    end;

    local procedure InsertIssuedBillLine(CustomerBillLine: Record "Customer Bill Line"; ListNo: Code[20]; FinalBillNo: Code[20])
    var
        IssuedCustBillLine: Record "Issued Customer Bill Line";
    begin
        IssuedCustBillLine.Init();
        IssuedCustBillLine.TransferFields(CustomerBillLine);
        IssuedCustBillLine."Customer Bill No." := ListNo;
        IssuedCustBillLine."Final Cust. Bill No." := FinalBillNo;
        OnInsertIssuedBillLineOnBeforeInsert(IssuedCustBillLine);
        IssuedCustBillLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure PostCustBillLine(CustomerBillHeader: Record "Customer Bill Header"; CustomerBillLine: Record "Customer Bill Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        with GenJnlLine do begin
            Init;

            Validate("Posting Date", CustomerBillHeader."Posting Date");
            "Document Date" := CustomerBillHeader."List Date";

            if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                FieldError("Posting Date", Text12100);

            if BillCode."Allow Issue" then begin
                "Account Type" := "Account Type"::"G/L Account";
                Validate("Account No.", BillCode."Bills for Coll. Temp. Acc. No.");
                Description := 'Cli ' + CustomerBillLine."Customer No." + ' Rif. ' + BRNumber;
            end else begin
                "Account Type" := "Account Type"::Customer;
                Validate("Account No.", CustomerBillLine."Customer No.");
                "Due Date" := CustomerBillLine."Due Date";
                "Document Type" := "Document Type"::Payment;
                Description := 'Cli ' + CustomerBillLine."Customer No." + ' Ft. ' + CustLedgEntry."Document No.";
                "External Document No." := CustLedgEntry."External Document No.";
                "Bank Receipt" := true;
                "Document Type to Close" := CustLedgEntry."Document Type";
                "Document No. to Close" := CustLedgEntry."Document No.";
                "Document Occurrence to Close" := CustLedgEntry."Document Occurrence";
                "Allow Issue" := CustLedgEntry."Allow Issue";
            end;

            "Document No." := ListNumber;

            Window.Update(1, "Account No.");
            Window.Update(2, "Document No.");
            Window.Update(3, BRNumber);

            Validate(Amount, -CustomerBillLine.Amount);
            "Reason Code" := CustomerBillHeader."Reason Code";
            "Source Code" := BillCode."Bill Source Code";
            "Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
            "Dimension Set ID" := CustLedgEntry."Dimension Set ID";

            OnBeforePostCustomerBillLine(GenJnlLine, CustomerBillHeader, CustomerBillLine, CustLedgEntry);
            GenJnlPostLine.RunWithoutCheck(GenJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostBalanceAccount(CustomerBillHeader: Record "Customer Bill Header"; CustLedgEntry: Record "Cust. Ledger Entry"; BillPostingGroup: Record "Bill Posting Group"; BalanceAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            Init;

            Validate("Posting Date", CustomerBillHeader."Posting Date");
            "Document Type" := "Document Type"::" ";
            "Document No." := ListNumber;
            "Document Date" := CustomerBillHeader."List Date";
            "Account Type" := "Account Type"::"G/L Account";

            case CustomerBillHeader.Type of
                CustomerBillHeader.Type::"Bills For Collection":
                    Validate("Account No.", BillPostingGroup."Bills For Collection Acc. No.");
                CustomerBillHeader.Type::"Bills For Discount":
                    Validate("Account No.", BillPostingGroup."Bills For Discount Acc. No.");
                CustomerBillHeader.Type::"Bills Subject To Collection":
                    Validate("Account No.", BillPostingGroup."Bills Subj. to Coll. Acc. No.");
            end;
            OnPostBalanceAccountOnAfterValidateAccountNo(GenJnlLine, BillPostingGroup, CustomerBillHeader);

            Description := CustomerBillHeader."Report Header";
            Validate(Amount, BalanceAmount);
            "Reason Code" := CustomerBillHeader."Reason Code";
            "Source Code" := BillCode."Bill Source Code";
            "Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
            "Dimension Set ID" := CustLedgEntry."Dimension Set ID";

            GenJnlPostLine.RunWithoutCheck(GenJnlLine);
        end;
    end;

    local procedure UpdateCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerBillLine: Record "Customer Bill Line")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        RbCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(CustomerBillLine."Customer Entry No.");
        CustLedgEntry.CalcFields("Remaining Amount");

        if CustLedgEntry."Remaining Amount" <> CustomerBillLine.Amount then
            Error(InvalidRemainingAmountErr,
              CustLedgEntry."Document No.",
              CustLedgEntry."Document Occurrence",
              CustLedgEntry."Remaining Amount");

        if CustLedgEntry."Due Date" <> CustomerBillLine."Due Date" then begin
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            CustLedgEntry."Due Date" := CustomerBillLine."Due Date";
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", CustLedgEntry."Due Date");
            RbCustLedgEntry.SetCurrentKey("Customer No.", "Document No.", "Document Type",
              "Document Type to Close", "Document No. to Close", "Document Occurrence to Close");
            RbCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
            RbCustLedgEntry.SetRange("Document No.", CustLedgEntry."Bank Receipt Temp. No.");
            RbCustLedgEntry.SetRange("Document Type", RbCustLedgEntry."Document Type"::Payment);
            RbCustLedgEntry.SetRange("Document Type to Close", CustLedgEntry."Document Type");
            RbCustLedgEntry.SetRange("Document No. to Close", CustLedgEntry."Document No.");
            RbCustLedgEntry.SetRange("Document Occurrence to Close", CustLedgEntry."Document Occurrence");
            if RbCustLedgEntry.FindFirst() then begin
                RbCustLedgEntry."Due Date" := CustomerBillLine."Due Date";
                RbCustLedgEntry.Modify();
                DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", RbCustLedgEntry."Entry No.");
                DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", RbCustLedgEntry."Due Date");
            end;
        end;
        CustLedgEntry."Cumulative Bank Receipts" := CustomerBillLine."Cumulative Bank Receipts";
        CustLedgEntry."Recipient Bank Account" := CustomerBillLine."Customer Bank Acc. No.";
        CustLedgEntry."Customer Bill No." := BRNumber;
        CustLedgEntry."Bank Receipts List No." := ListNumber;
        CustLedgEntry."Bank Receipt Issued" := true;
        CustLedgEntry.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetHidePrintDialog(NewHidePrintDialog: Boolean)
    begin
        HidePrintDialog := NewHidePrintDialog;
    end;

    [Scope('OnPrem')]
    procedure SetHTMLPath(NewHTMLPath: Text[1024])
    begin
        HTMLPath := NewHTMLPath;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var CustomerBillHeader: Record "Customer Bill Header"; var IssuedCustomerBillHeader: Record "Issued Customer Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var CustomerBillHeader: Record "Customer Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var CustomerBillHeader: Record "Customer Bill Header"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerBillLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerBillHeader: Record "Customer Bill Header"; CustomerBillLine: Record "Customer Bill Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertIssuedBillLineOnBeforeInsert(var IssuedCustomerBillLine: Record "Issued Customer Bill Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalanceAccountOnAfterValidateAccountNo(var GenJournalLine: Record "Gen. Journal Line"; BillPostingGroup: Record "Bill Posting Group"; CustomerBillHeader: Record "Customer Bill Header")
    begin
    end;
}

