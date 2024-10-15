codeunit 12173 "Vendor Bill List - Post"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    TableNo = "Vendor Bill Header";

    trigger OnRun()
    begin
        if not Confirm(Text1130000) then
            exit;

        Code(Rec);

        Message(Text1130026);
    end;

    var
        Text1130000: Label 'Do you want to post the lines?';
        MustBeErr: Label '%1 must be %2.', Comment = '%1 = List Status, %2 = Status';
        SelectionTxt: Label 'Open,Sent';
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        Window: Dialog;
        Text1130011: Label 'Posting Vendor Bill...\\';
        Text1130012: Label 'Post Line #1##########\';
        LineNo: Integer;
        BalanceAmount: Decimal;
        Text12100: Label 'Meanwhile %1 has been modified for %2 %3 %4 %5. New amount is %6. Please recreate the bill list.';
        Text1130026: Label 'The lines has been successfully posted.';
        BalanceAmountLCY: Decimal;

    [Scope('OnPrem')]
    procedure "Code"(var LocalVendorBillHeader: Record "Vendor Bill Header")
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
        TempWithholdingSocSec: Record "Tmp Withholding Contribution" temporary;
        VendBillWithhTax: Record "Vendor Bill Withholding Tax";
        BillPostingGroup: Record "Bill Posting Group";
        BillCode: Record Bill;
        WithholdingSocSec: Codeunit "Withholding - Contribution";
        TaxType: Option " ",Withhold,"Free Lance",Company;
        AmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        VendorBillHeader := LocalVendorBillHeader;

        OnBeforePost(VendorBillHeader);

        with VendorBillHeader do begin
            CheckVendorBill(VendorBillHeader, BillPostingGroup, BillCode);

            VendorBillLine.Reset();
            VendorBillLine.SetRange("Vendor Bill List No.", "No.");
            if not VendorBillLine.Find('-') then
                Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

            Window.Open(Text1130011 + Text1130012);

            InsertPostedBillHeader(PostedVendorBillHeader, VendorBillHeader, "Vendor Bill List No.", "No.");

            repeat
                LineNo := LineNo + 1;
                Window.Update(1, LineNo);
                BalanceAmount := BalanceAmount + VendorBillLine."Amount to Pay";

                if not VendorBillLine."Manual Line" then begin
                    VendLedgEntry.Get(VendorBillLine."Vendor Entry No.");
                    VendLedgEntry.CalcFields("Remaining Amount");
                    if VendLedgEntry."Remaining Amount" + VendorBillLine."Remaining Amount" <> 0 then
                        Error(Text12100,
                          VendLedgEntry.FieldCaption("Remaining Amount"),
                          VendLedgEntry.FieldCaption("Document No."),
                          VendLedgEntry."Document No.",
                          VendLedgEntry.FieldCaption("Document Occurrence"),
                          VendLedgEntry."Document Occurrence",
                          Abs(VendLedgEntry."Remaining Amount"));
                end;

                PostVendorBillLine(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry, BillCode, AmountLCY);

                BalanceAmountLCY := BalanceAmountLCY + GenJnlLine."Amount (LCY)";
                if VendBillWithhTax.Get(VendorBillLine."Vendor Bill List No.", VendorBillLine."Line No.") then begin
                    if (VendBillWithhTax."Withholding Tax Code" <> '') and (VendBillWithhTax."Withholding Tax Amount" <> 0) then
                        PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::Withhold);
                    if (VendBillWithhTax."Social Security Code" <> '') and (VendBillWithhTax."Free-Lance Amount" <> 0) then
                        PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::"Free Lance");
                    if (VendBillWithhTax."Social Security Code" <> '') and (VendBillWithhTax."Company Amount" <> 0) then
                        PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::Company);

                    OnAfterPostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType);

                    TempWithholdingSocSec.TransferFields(VendBillWithhTax);
                    WithholdingSocSec.PostPayments(TempWithholdingSocSec, GenJnlLine, true);
                end;

                IsHandled := false;
                OnBeforeInsertPostedBillLine(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType, PostedVendorBillHeader, BalanceAmountLCY, IsHandled);
                if not IsHandled then
                    InsertPostedBillLine(VendorBillLine, PostedVendorBillHeader."No.", VendorBillLine."Vendor Bill No.");
            until VendorBillLine.Next() = 0;

            PostBalanceAccount(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry, BillCode);

            if "Bank Expense" > 0 then begin
                BillPostingGroup.TestField("Expense Bill Account No.");
                PostExpense(VendorBillHeader, VendLedgEntry, BillCode, BillPostingGroup."Expense Bill Account No.");
            end;

            VendorBillLine.DeleteAll(true);
            Delete(true);

            Window.Close();
            Commit();

            OnAfterPost(VendorBillHeader);
        end;
    end;

    local procedure CheckVendorBill(VendorBillHeader: Record "Vendor Bill Header"; var BillPostingGroup: Record "Bill Posting Group"; var BillCode: Record Bill)
    var
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
    begin
        with VendorBillHeader do begin
            if "List Status" <> "List Status"::Sent then
                Error(MustBeErr, FieldCaption("List Status"), SelectStr(2, SelectionTxt));

            BankAccount.Get("Bank Account No.");
            PaymentMethod.Get("Payment Method Code");
            BillCode.Get(PaymentMethod."Bill Code");
            BillPostingGroup.Get("Bank Account No.", "Payment Method Code");
        end;
    end;

    local procedure InsertPostedBillHeader(var PostedVendorBillHeader: Record "Posted Vendor Bill Header"; VendorBillHeader: Record "Vendor Bill Header"; ListNo: Code[20]; BillNo: Code[20])
    begin
        PostedVendorBillHeader.Init();
        PostedVendorBillHeader.TransferFields(VendorBillHeader);
        PostedVendorBillHeader."No." := ListNo;
        PostedVendorBillHeader."Temporary Bill No." := BillNo;
        PostedVendorBillHeader."User ID" := UserId;
        PostedVendorBillHeader.Insert();
    end;

    local procedure InsertPostedBillLine(VendorBillLine: Record "Vendor Bill Line"; BillNo: Code[20]; ListNo: Code[20])
    var
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        PostedVendorBillLine.Init();
        PostedVendorBillLine.TransferFields(VendorBillLine);
        PostedVendorBillLine."Vendor Bill No." := BillNo;
        PostedVendorBillLine."Vendor Bill List No." := ListNo;
        PostedVendorBillLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure PostVendorBillLine(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill; var AmountLCY: Decimal)
    var
        Tax: Option " ",Withhold,"Free Lance",Company;
    begin
        with GenJnlLine do begin
            Init();
            Validate("Posting Date", VendorBillHeader."Posting Date");
            "Document Type" := "Document Type"::Payment;
            "Document No." := VendorBillHeader."Vendor Bill List No.";
            "Document Date" := VendorBillHeader."List Date";
            "Account Type" := "Account Type"::Vendor;
            Validate("Account No.", VendorBillLine."Vendor No.");
            "Due Date" := VendorBillLine."Due Date";
            "External Document No." := VendorBillLine."Vendor Bill List No.";
            Validate(Amount, VendorBillLine."Amount to Pay");
            Validate("Currency Code", VendorBillHeader."Currency Code");
            if not VendorBillLine."Manual Line" then begin
                Validate("Salespers./Purch. Code", VendLedgEntry."Purchaser Code");
                ApplyInvAndUpdateLedgEntry(GenJnlLine, VendorBillLine, Tax::" ");
            end;
            Description := Bill.Description;
            "Source Code" := Bill."Vend. Bill Source Code";
            "System-Created Entry" := true;
            "Reason Code" := VendorBillHeader."Reason Code";
            "Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
            if not VendorBillLine."Manual Line" then
                "Dimension Set ID" := VendLedgEntry."Dimension Set ID"
            else
                "Dimension Set ID" := VendorBillLine."Dimension Set ID";
            "Payment Method Code" := VendorBillHeader."Payment Method Code";
            AmountLCY := "Amount (LCY)";

            OnBeforePostVendorBillLine(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostBalanceAccount(GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill)
    begin
        with GenJnlLine do begin
            Init();
            Validate("Posting Date", VendorBillHeader."Posting Date");
            "Document Type" := "Document Type"::Payment;
            "Document No." := VendorBillHeader."Vendor Bill List No.";
            "Document Date" := VendorBillHeader."List Date";
            "Account Type" := "Account Type"::"Bank Account";
            Validate("Account No.", VendorBillHeader."Bank Account No.");
            "Currency Code" := VendorBillHeader."Currency Code";
            Validate(Amount, -BalanceAmount);
            Validate("Amount (LCY)", -BalanceAmountLCY);
            Description := Bill.Description;
            "Source Code" := Bill."Vend. Bill Source Code";
            "System-Created Entry" := true;
            "Reason Code" := VendorBillHeader."Reason Code";
            if not VendorBillLine."Manual Line" then
                Validate("Salespers./Purch. Code", VendLedgEntry."Purchaser Code");

            "Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
            if not VendorBillLine."Manual Line" then
                "Dimension Set ID" := VendLedgEntry."Dimension Set ID"
            else
                "Dimension Set ID" := VendorBillLine."Dimension Set ID";

            OnBeforePostBalanceAccount(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostExpense(VendorBillHeader: Record "Vendor Bill Header"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill; ExpenseAccNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GenJnlLine do begin
            Init();
            Validate("Posting Date", VendorBillHeader."Posting Date");
            "Document Type" := "Document Type"::Payment;
            "Document No." := VendorBillHeader."Vendor Bill List No.";
            "Document Date" := VendorBillHeader."List Date";
            "Account Type" := "Account Type"::"G/L Account";
            Validate("Account No.", ExpenseAccNo);
            Description := Bill.Description;
            "Source Code" := Bill."Vend. Bill Source Code";
            "System-Created Entry" := true;
            "Reason Code" := VendorBillHeader."Reason Code";
            "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            Validate("Bal. Account No.", VendorBillHeader."Bank Account No.");
            Validate(Amount, VendorBillHeader."Bank Expense");
            if PurchInvHeader.GET(VendLedgEntry."Document No.") then begin
                GeneralLedgerSetup.GetRecordOnce();
                if GeneralLedgerSetup."Use Activity Code" then
                    Validate("Activity Code", PurchInvHeader."Activity Code");
            end;

            OnBeforePostExpense(GenJnlLine, VendorBillHeader, VendLedgEntry);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostTax(VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill; Tax: Option " ",Withhold,"Free Lance",Company)
    var
        GenJnlLine: Record "Gen. Journal Line";
        WithholdCode: Record "Withhold Code";
        ContributionCode: Record "Contribution Code";
    begin
        with GenJnlLine do begin
            Init();
            Validate("Posting Date", VendorBillHeader."Posting Date");
            "Document Type" := "Document Type"::Payment;
            "Document No." := VendorBillHeader."Vendor Bill List No.";
            "Document Date" := VendorBillHeader."List Date";
            "External Document No." := VendorBillLine."Vendor Bill List No.";
            case Tax of
                Tax::Withhold:
                    begin
                        WithholdCode.Get(VendorBillWithholdingTax."Withholding Tax Code");
                        "Account Type" := "Account Type"::Vendor;
                        Validate("Account No.", VendorBillLine."Vendor No.");
                        Validate(Amount, VendorBillLine."Withholding Tax Amount");
                        WithholdCode.TestField("Withholding Taxes Payable Acc.");
                        "Bal. Account No." := WithholdCode."Withholding Taxes Payable Acc.";
                    end;
                Tax::"Free Lance":
                    begin
                        ContributionCode.Get(VendorBillWithholdingTax."Social Security Code");
                        "Account Type" := "Account Type"::Vendor;
                        Validate("Account No.", VendorBillLine."Vendor No.");
                        Validate(Amount, VendorBillWithholdingTax."Free-Lance Amount");
                        ContributionCode.TestField("Social Security Payable Acc.");
                        "Bal. Account No." := ContributionCode."Social Security Payable Acc.";
                    end;
                Tax::Company:
                    begin
                        ContributionCode.Get(VendorBillWithholdingTax."Social Security Code");
                        "Account Type" := "Account Type"::"G/L Account";
                        ContributionCode.TestField("Social Security Charges Acc.");
                        Validate("Account No.", ContributionCode."Social Security Charges Acc.");
                        Validate(Amount, VendorBillWithholdingTax."Company Amount");
                        ContributionCode.TestField("Social Security Payable Acc.");
                        "Bal. Account No." := ContributionCode."Social Security Payable Acc.";
                    end;
            end;
            Validate("Currency Code", VendorBillHeader."Currency Code");
            if not VendorBillLine."Manual Line" then begin
                Validate("Salespers./Purch. Code", VendLedgEntry."Purchaser Code");
                ApplyInvAndUpdateLedgEntry(GenJnlLine, VendorBillLine, Tax);
            end;
            Description := Bill.Description;
            "Source Code" := Bill."Vend. Bill Source Code";
            "System-Created Entry" := true;
            "Reason Code" := VendorBillHeader."Reason Code";
            "Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
            if not VendorBillLine."Manual Line" then
                "Dimension Set ID" := VendLedgEntry."Dimension Set ID"
            else
                "Dimension Set ID" := VendorBillLine."Dimension Set ID";

            OnBeforePostWithholdingTax(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry, VendorBillWithholdingTax);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplyInvAndUpdateLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; VendorBillLine: Record "Vendor Bill Line"; Tax: Option " ",Withhold,"Free Lance",Company)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get(VendorBillLine."Vendor Entry No.");
        if not (Tax = Tax::Company) then begin
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
            GenJnlLine."Applies-to Doc. No." := VendorBillLine."Document No.";
        end;
        GenJnlLine."Applies-to Occurrence No." := VendorBillLine."Document Occurrence";
        GenJnlLine."Allow Application" := true;
        if VendorBillLine."Amount to Pay" + VendorBillLine."Withholding Tax Amount" <> VendorBillLine."Remaining Amount" then begin
            VendLedgEntry."Vendor Bill List" := '';
            VendLedgEntry."Vendor Bill No." := '';
            VendLedgEntry.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostTax(var VendorBillHeader: Record "Vendor Bill Header"; var VendorBillLine: Record "Vendor Bill Line"; var VendBillWithhTax: Record "Vendor Bill Withholding Tax"; var VendLedgEntry: Record "Vendor Ledger Entry"; BillCode: Record Bill; TaxType: Option);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendorBillLine(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalanceAccount(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostExpense(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWithholdingTax(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry"; VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPostedBillLine(VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendBillWithhTax: Record "Vendor Bill Withholding Tax"; VendLedgEntry: Record "Vendor Ledger Entry"; BillCode: Record Bill; TaxType: Option " ",Withhold,"Free Lance",Company; PostedVendorBillHeader: Record "Posted Vendor Bill Header"; BalanceAmountLCY: Decimal; var IsHandled: Boolean)
    begin
    end;
}

