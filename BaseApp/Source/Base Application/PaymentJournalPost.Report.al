report 2000004 "Payment Journal Post"
{
    Caption = 'Payment Journal Post';
    Permissions = TableData "Cust. Ledger Entry" = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Gen. Journal Line" = rim;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Payment Journal Line"; "Payment Journal Line")
        {
            DataItemTableView = SORTING("Bank Account", "Beneficiary Bank Account No.", Status, "Account Type", "Account No.", "Currency Code", "Posting Date");

            trigger OnAfterGetRecord()
            var
                NewGroupLoc: Boolean;
            begin
                // Mark record for status modification after writing the data
                Mark(true);

                if "Account Type" = "Account Type"::Customer then begin
                    CustomerAmt[1] += Amount;
                    CustomerAmt[2] += "Amount (LCY)"
                end else begin
                    VendorAmt[1] += Amount;
                    VendorAmt[2] += "Amount (LCY)";
                end;

                NewGroupLoc := CheckNewGroup;
                if NewGroupLoc then begin
                    AppliesToID := CopyStr(Format("Ledger Entry No.") + '/' + "Bank Account", 1, MaxStrLen("Applies-to ID"));
                    if CustomerAmt[1] + VendorAmt[1] > 0 then
                        WriteDataRecord("Account Type");
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Status, Status::Created);

                // Check records for posting
                if Count = 0 then
                    Error(Text009);
            end;
        }
        dataitem(Docket; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

            trigger OnAfterGetRecord()
            begin
                if CustomerTotalAmount[2] > 0 then
                    WriteTrailerRecord("Payment Journal Line"."Account Type"::Customer);
                if VendorTotalAmount[2] > 0 then
                    WriteTrailerRecord("Payment Journal Line"."Account Type"::Vendor);
            end;
        }
        dataitem(Posting; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

            trigger OnPreDataItem()
            begin
                if CustomerTotalAmount[1] + VendorTotalAmount[1] > 0 then begin
                    GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");

                    GenJnlLine.Reset();
                    GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

                    LastGenJnlLine.Copy(GenJnlLine);
                    if LastGenJnlLine.FindLast then;

                    PaymJnlLine.Copy("Payment Journal Line");
                    PaymJnlLine.SetCurrentKey(
                      "Bank Account", "Beneficiary Bank Account No.", Status, "Account Type", "Account No.", "Currency Code", "Posting Date");
                    PaymJnlLine.SetRange(Status, PaymJnlLine.Status::Processed);
                    PaymJnlLine.SetRange("Account Type");
                    if PaymJnlLine.FindSet then begin
                        AppliesToID := '';
                        DocumentNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", PaymJnlLine."Posting Date", false);
                        repeat
                            SetGenJnlLine(PaymJnlLine);
                        until PaymJnlLine.Next = 0;
                        PaymJnlLine.ModifyAll(Status, PaymJnlLine.Status::Posted);
                    end;
                    if TempPaymJnlLine.FindSet then
                        repeat
                            SetGenJnlLine(TempPaymJnlLine);
                        until TempPaymJnlLine.Next = 0;

                    PaymJnlBatch.Get("Payment Journal Line"."Journal Template Name", "Payment Journal Line"."Journal Batch Name");
                    PJBatchName := IncStr(PaymJnlBatch.Name);
                    if PJBatchName <> '' then begin
                        PaymJnlBatch.Status := PaymJnlBatch.Status::Processed;

                        PaymJnlBatch.Modify(true);
                        PaymJnlBatch.Status := PaymJnlBatch.Status::" ";
                        PaymJnlBatch.Name := PJBatchName;
                        if PaymJnlBatch.Insert(true) then;
                    end;

                    if PJBatchName <> '' then begin
                        PaymJnlLine.Reset();
                        PaymJnlLine.SetRange("Journal Template Name", "Payment Journal Line"."Journal Template Name");
                        PaymJnlLine.SetRange("Journal Batch Name", PJBatchName);
                        if PaymJnlLine.FindLast then
                            LineNo := PaymJnlLine."Line No."
                        else
                            LineNo := 0;

                        // Rename
                        PaymJnlLine.Reset();
                        PaymJnlLine.SetRange("Journal Template Name", "Payment Journal Line"."Journal Template Name");
                        PaymJnlLine.SetRange("Journal Batch Name", "Payment Journal Line"."Journal Batch Name");
                        PaymJnlLine.SetFilter("Separate Line", "Payment Journal Line".GetFilter("Separate Line"));
                        PaymJnlLine.SetFilter(Status, '<%1', PaymJnlLine.Status::Processed);
                        if PaymJnlLine.FindSet then
                            repeat
                                LineNo := LineNo + 10000;
                                PaymJnlLine.Rename(PaymJnlLine."Journal Template Name", PJBatchName, LineNo);
                            until not PaymJnlLine.FindFirst;
                    end;

                    // Post
                    if AutomaticPosting then
                        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ClearAll;
        GLSetup.Get();
        EBSetup.Get();
    end;

    trigger OnPreReport()
    begin
        PostPaymentRecord := EBSetup."Summarize Gen. Jnl. Lines";

        SelectedDim.SetRange("User ID", UserId);
        SelectedDim.SetRange("Object Type", 3);
        SelectedDim.SetRange("Object ID", ReportID);
        IncludeDim := SelectedDim.FindFirst and EBSetup."Summarize Gen. Jnl. Lines";
        // check general journal
        with GenJnlBatch do begin
            Reset;
            if not Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
                Error(Text001, GenJnlLine.FieldCaption("Journal Batch Name"));

            if not ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") then
                Error(Text002, FieldCaption("Bal. Account Type"), Name);

            if "Bal. Account No." = '' then
                Error(Text003, FieldCaption("Bal. Account No."), Name);

            if not GLAcc.Get("Bal. Account No.") then
                Error(Text004, "Bal. Account No.");

            if not (GLAcc."Account Type" = GLAcc."Account Type"::Posting) then
                Error(Text005, GLAcc.FieldCaption("Account Type"), GLAcc."No.");

            TestField("No. Series");
        end;

        // currency for balancing amount
        LocalCurrency.InitRoundingPrecision
    end;

    var
        Text001: Label 'The %1 for posting is not specified.';
        Text002: Label '%1 in %2 must be G/L Account.';
        Text003: Label '%1 in %2 is not a valid G/L Account No.';
        Text004: Label '%1 in Journal Template is not a G/L Account No.';
        Text005: Label '%1 in G/L Account %2 must be %3.';
        Text009: Label 'There are no payment records in the selection.';
        Text014: Label 'Payment %1';
        Text016: Label 'The combination of invoices and credit memos for %1 %2 has caused an attempt to write a negative amount to the payment file. The format of the file does not allow this.', Comment = 'Parameter 1 - account type (,Customer,Vendor), 2 - account number.';
        GLSetup: Record "General Ledger Setup";
        EBSetup: Record "Electronic Banking Setup";
        GLAcc: Record "G/L Account";
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        LastGenJnlLine: Record "Gen. Journal Line";
        SelectedDim: Record "Selected Dimension";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymJnlLine: Record "Payment Journal Line";
        TempPaymJnlLine: Record "Payment Journal Line" temporary;
        LocalCurrency: Record Currency;
        DimensionSetEntry: Record "Dimension Set Entry";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        BalancingPostingDate: Date;
        PJBatchName: Code[10];
        DocumentNo: Code[20];
        AppliesToID: Code[50];
        RemitteeName: Text[50];
        LineNo: Integer;
        EntryNo: Integer;
        ReportID: Integer;
        CustomerAmt: array[2] of Decimal;
        CustomerTotalAmount: array[2] of Decimal;
        VendorAmt: array[2] of Decimal;
        VendorTotalAmount: array[2] of Decimal;
        AutomaticPosting: Boolean;
        PostPaymentRecord: Boolean;
        IncludeDim: Boolean;

    local procedure WriteDataRecord(AccountType: Option)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        LocalAmt: Decimal;
        LocalAmtLCY: Decimal;
    begin
        if CustomerAmt[1] + VendorAmt[1] > 0 then begin
            if AccountType = PaymJnlLine."Account Type"::Customer then begin
                LocalAmt := CustomerAmt[1];
                LocalAmtLCY := CustomerAmt[2];
            end else begin
                LocalAmt := VendorAmt[1];
                LocalAmtLCY := VendorAmt[2];
            end;
            // Totals for balancing amount in LCY
            if PostPaymentRecord then
                LocalAmtLCY := Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      "Payment Journal Line"."Posting Date", "Payment Journal Line"."Currency Code",
                      LocalAmt, "Payment Journal Line"."Currency Factor"),
                    LocalCurrency."Amount Rounding Precision");
            if AccountType = PaymJnlLine."Account Type"::Customer then begin
                CustomerTotalAmount[1] += LocalAmt;
                CustomerTotalAmount[2] += LocalAmtLCY;
            end else begin
                VendorTotalAmount[1] += LocalAmt;
                VendorTotalAmount[2] += LocalAmtLCY;
            end;

            // Modify Status
            PaymJnlLine.Copy("Payment Journal Line");
            PaymJnlLine.MarkedOnly(true);

            // Add applies to ID for each payment
            if PostPaymentRecord then begin
                PaymJnlLine.SetRange("Partial Payment", false);
                if not IncludeDim then
                    PaymJnlLine.ModifyAll("Applies-to ID", AppliesToID, true)
                else
                    if PaymJnlLine.FindSet then
                        repeat
                            TempDimBuf.Reset();
                            TempDimBuf.DeleteAll();
                            if SelectedDim.FindSet then
                                repeat
                                    if DimensionSetEntry.Get(
                                         PaymJnlLine."Dimension Set ID", SelectedDim."Dimension Code")
                                    then begin
                                        TempDimBuf."Table ID" := DATABASE::"Payment Journal Line";
                                        TempDimBuf."Dimension Code" := DimensionSetEntry."Dimension Code";
                                        TempDimBuf."Dimension Value Code" := DimensionSetEntry."Dimension Value Code";
                                        TempDimBuf.Insert();
                                    end;
                                until SelectedDim.Next = 0;
                            EntryNo := DimBufMgt.FindDimensions(TempDimBuf);
                            if EntryNo = 0 then
                                EntryNo := DimBufMgt.InsertDimensions(TempDimBuf);
                            PaymJnlLine."Applies-to ID" := CopyStr(Format(EntryNo) + '/' + AppliesToID, 1, MaxStrLen(PaymJnlLine."Applies-to ID"));
                            PaymJnlLine.Modify(true);
                        until PaymJnlLine.Next = 0;

                PaymJnlLine.SetRange("Partial Payment");
            end;
            // Order of MODIFYALL is important
            PaymJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Account Type", "Account No.");
            PaymJnlLine.ModifyAll(PaymJnlLine.Status, PaymJnlLine.Status::Processed, true);
            PaymJnlLine.ModifyAll(PaymJnlLine.Processing, true, true);
        end;

        // reset for next iteration
        "Payment Journal Line".ClearMarks;

        if LocalAmt <= 0 then
            Error(Text016, "Payment Journal Line"."Account Type", "Payment Journal Line"."Account No.");

        Clear(CustomerAmt);
        Clear(VendorAmt);
    end;

    local procedure WriteTrailerRecord(AccountType: Option)
    begin
        TempPaymJnlLine := "Payment Journal Line";
        TempPaymJnlLine."Account Type" := GenJnlBatch."Bal. Account Type";
        TempPaymJnlLine."Account No." := GenJnlBatch."Bal. Account No.";
        TempPaymJnlLine."Currency Code" := '';
        TempPaymJnlLine."Currency Factor" := 0;
        if AccountType = "Payment Journal Line"."Account Type"::Customer then begin
            TempPaymJnlLine."Line No." := GetCustBalLineNo;
            TempPaymJnlLine.Amount := -CustomerTotalAmount[2]
        end else begin
            TempPaymJnlLine."Line No." := GetVendBalLineNo;
            TempPaymJnlLine.Amount := -VendorTotalAmount[2];
        end;
        TempPaymJnlLine."Payment Message" := '';
        TempPaymJnlLine."Applies-to Doc. Type" := 0;
        TempPaymJnlLine."Applies-to Doc. No." := '';
        TempPaymJnlLine."Applies-to ID" := '';
        if BalancingPostingDate <> 0D then
            TempPaymJnlLine."Posting Date" := BalancingPostingDate;
        TempPaymJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetGenJnlLine(PaymentJnlLine: Record "Payment Journal Line")
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PaymJnlManagement.ModifyPmtDiscDueDate(PaymentJnlLine);

        if PostPaymentRecord and
           not PaymentJnlLine."Partial Payment" and
           not PaymentJnlLine."Separate Line"
        then
            PaymJnlManagement.SetApplID(PaymentJnlLine);

        with GenJnlLine do
            if PostPaymentRecord and
               not PaymentJnlLine."Partial Payment" and
               not PaymentJnlLine."Separate Line" and
               (AppliesToID = PaymentJnlLine."Applies-to ID") and
               (PaymentJnlLine."Account Type" in [PaymentJnlLine."Account Type"::Customer, PaymentJnlLine."Account Type"::Vendor])
            then begin
                GenJnlLine := LastGenJnlLine;
                Find;

                // add amounts
                Validate(Amount, Amount + PaymentJnlLine.Amount);
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';
                Validate("Applies-to ID", AppliesToID);
                Modify
            end else begin
                Clear(GenJnlLine);
                Init;
                case PaymentJnlLine."Account Type" of
                    PaymentJnlLine."Account Type"::Customer:
                        begin
                            Cust.Get(PaymentJnlLine."Account No.");
                            RemitteeName := CopyStr(Cust.Name, 1, MaxStrLen(RemitteeName));
                            "Source Type" := "Source Type"::Customer;
                            "Posting Group" := Cust."Customer Posting Group";
                            "Salespers./Purch. Code" := Cust."Salesperson Code";
                            "Payment Terms Code" := Cust."Payment Terms Code";
                            "Document Type" := "Document Type"::Refund;
                        end;
                    PaymentJnlLine."Account Type"::Vendor:
                        begin
                            Vend.Get(PaymentJnlLine."Account No.");
                            RemitteeName := CopyStr(Vend.Name, 1, MaxStrLen(RemitteeName));
                            "Source Type" := "Source Type"::Vendor;
                            "Posting Group" := Vend."Vendor Posting Group";
                            "Salespers./Purch. Code" := Vend."Purchaser Code";
                            "Payment Terms Code" := Vend."Payment Terms Code";
                            "Document Type" := "Document Type"::Payment;
                        end;
                    else begin
                            Clear(RemitteeName);
                            if PaymentJnlLine."Line No." = GetCustBalLineNo then
                                "Document Type" := "Document Type"::Refund
                            else
                                "Document Type" := "Document Type"::Payment;
                        end;
                end;
                "Journal Template Name" := GenJnlBatch."Journal Template Name";
                "Journal Batch Name" := GenJnlBatch.Name;
                if (PaymentJnlLine."Line No." = GetCustBalLineNo) and (PaymentJnlLine."Account Type" = 0) then begin
                    GenJournalLine.Copy(LastGenJnlLine);
                    GenJournalLine.SetRange("Account Type", "Account Type"::Customer);
                    GenJournalLine.FindLast;
                    "Line No." := GenJournalLine."Line No." + 1;
                end else
                    "Line No." := LastGenJnlLine."Line No." + 10000;

                // keep track of break on applies-to ID
                AppliesToID := PaymentJnlLine."Applies-to ID";

                "Document No." := DocumentNo;
                "Posting Date" := PaymentJnlLine."Posting Date";
                "Document Date" := PaymentJnlLine."Posting Date";

                "Account Type" := PaymentJnlLine."Account Type";
                if PaymentJnlLine."Account Type" = 0 then
                    Validate("Account No.", PaymentJnlLine."Account No.")
                else begin
                    "Account No." := PaymentJnlLine."Account No.";
                    "Bill-to/Pay-to No." := PaymJnlLine."Account No.";
                end;
                if PostPaymentRecord and
                   not PaymentJnlLine."Partial Payment" and
                   not PaymentJnlLine."Separate Line" and
                   (PaymentJnlLine."Applies-to Doc. Type" <> PaymentJnlLine."Applies-to Doc. Type"::"Credit Memo")
                then
                    "Applies-to ID" := AppliesToID
                else begin
                    "Applies-to Doc. Type" := PaymentJnlLine."Applies-to Doc. Type";
                    "Applies-to Doc. No." := PaymentJnlLine."Applies-to Doc. No.";
                end;

                "Currency Code" := PaymentJnlLine."Currency Code";
                "Currency Factor" := PaymentJnlLine."Currency Factor";
                Validate(Amount, PaymentJnlLine.Amount);

                if PostPaymentRecord and
                   not PaymentJnlLine."Partial Payment" and
                   not PaymentJnlLine."Separate Line"
                then
                    Description :=
                      CopyStr(StrSubstNo(Text014, RemitteeName), 1, MaxStrLen(Description))
                else
                    if PaymentJnlLine."Payment Message" <> '' then
                        Description := PaymentJnlLine."Payment Message";

                "Reason Code" := PaymentJnlLine."Reason Code";
                "Source Code" := PaymentJnlLine."Source Code";
                "Source No." := PaymentJnlLine."Account No.";
                UpdateDimSetID("Dimension Set ID", PaymentJnlLine);
                Validate("Dimension Set ID");
                "Message to Recipient" := CopyStr(PaymentJnlLine."Payment Message", 1, MaxStrLen("Message to Recipient"));
                "Exported to Payment File" := true;
                OnBeforeGenJnlLineInsert(GenJnlLine, PaymentJnlLine);
                Insert;

                if PaymentJnlLine."Line No." = GetCustBalLineNo then
                    "Line No." := LastGenJnlLine."Line No." + 10000;

                LastGenJnlLine := GenJnlLine;
            end;
    end;

    [Scope('OnPrem')]
    procedure CheckNewGroup(): Boolean
    var
        PmtJnlLineLoc: Record "Payment Journal Line";
        NewGroupLoc: Boolean;
    begin
        NewGroupLoc := false;
        PmtJnlLineLoc.Copy("Payment Journal Line");
        if PmtJnlLineLoc.Next = 1 then begin
            if (PmtJnlLineLoc."Account No." <> "Payment Journal Line"."Account No.") or
               (PmtJnlLineLoc."Account Type" <> "Payment Journal Line"."Account Type") or
               (PmtJnlLineLoc."Currency Code" <> "Payment Journal Line"."Currency Code") or
               (PmtJnlLineLoc."Posting Date" <> "Payment Journal Line"."Posting Date")
            then
                NewGroupLoc := true;
        end else
            NewGroupLoc := true;
        exit(NewGroupLoc);
    end;

    procedure SetParameters(GenJnlLineParam: Record "Gen. Journal Line"; AutomaticPostingParam: Boolean; ReportIDParam: Integer; BalancingPostingDateParam: Date)
    begin
        GenJnlLine := GenJnlLineParam;
        AutomaticPosting := AutomaticPostingParam;
        ReportID := ReportIDParam;
        BalancingPostingDate := BalancingPostingDateParam;
    end;

    local procedure UpdateDimSetID(var DimSetID: Integer; PaymentJnlLine: Record "Payment Journal Line")
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
    begin
        if PaymentJnlLine."Account Type" in [PaymentJnlLine."Account Type"::Customer, PaymentJnlLine."Account Type"::Vendor] then begin
            SelectedDim.SetRange("User ID", UserId);
            SelectedDim.SetRange("Object Type", 3);
            SelectedDim.SetRange("Object ID", ReportID);
            if SelectedDim.FindSet then
                repeat
                    if DimensionSetEntry.Get(PaymJnlLine."Dimension Set ID", SelectedDim."Dimension Code") then begin
                        TempDimBuf."Dimension Code" := DimensionSetEntry."Dimension Code";
                        TempDimBuf."Dimension Value Code" := DimensionSetEntry."Dimension Value Code";
                        TempDimBuf.Insert();
                    end;
                until SelectedDim.Next = 0;
            DimSetID := DimMgt.CreateDimSetIDFromDimBuf(TempDimBuf);
        end;
    end;

    local procedure GetCustBalLineNo(): Integer
    begin
        exit(1);
    end;

    local procedure GetVendBalLineNo(): Integer
    begin
        exit(2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; PaymentJournalLine: Record "Payment Journal Line")
    begin
    end;
}

