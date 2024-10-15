namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 981 "Payment Registration Buffer"
{
    Caption = 'Payment Registration Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ledger Entry No."; Integer)
        {
            Caption = 'Ledger Entry No.';
        }
        field(2; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(3; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(7; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(8; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
        }
        field(9; "Payment Made"; Boolean)
        {
            Caption = 'Payment Made';

            trigger OnValidate()
            begin
                if not "Payment Made" then begin
                    "Amount Received" := 0;
                    "Date Received" := 0D;
                    "Remaining Amount" := "Original Remaining Amount";
                    "External Document No." := '';
                    exit;
                end;

                AutoFillDate();
                if "Amount Received" = 0 then
                    SuggestAmountReceivedBasedOnDate();
                UpdateRemainingAmount();
            end;
        }
        field(10; "Date Received"; Date)
        {
            Caption = 'Date Received';

            trigger OnValidate()
            begin
                if "Date Received" <> 0D then
                    Validate("Payment Made", true);
            end;
        }
        field(11; "Amount Received"; Decimal)
        {
            Caption = 'Amount Received';

            trigger OnValidate()
            var
                MaximumRemainingAmount: Decimal;
            begin
                if "Limit Amount Received" then begin
                    MaximumRemainingAmount := GetMaximumPaymentAmountBasedOnDate();
                    if "Amount Received" > MaximumRemainingAmount then
                        "Amount Received" := MaximumRemainingAmount;
                end;

                AutoFillDate();
                "Payment Made" := true;
                UpdateRemainingAmount();
            end;
        }
        field(12; "Original Remaining Amount"; Decimal)
        {
            Caption = 'Original Remaining Amount';
        }
        field(13; "Rem. Amt. after Discount"; Decimal)
        {
            Caption = 'Rem. Amt. after Discount';
        }
        field(14; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';

            trigger OnValidate()
            begin
                if "Pmt. Discount Date" <> 0D then
                    Validate("Payment Made", true);
            end;
        }
        field(15; "Limit Amount Received"; Boolean)
        {
            Caption = 'Limit Amount Received';
        }
        field(16; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
        }
        field(17; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(18; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(19; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
    }

    keys
    {
        key(Key1; "Ledger Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Due Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DueDateMsg: Label 'The payment is overdue. You can calculate interest for late payments from customers by choosing the Finance Charge Memo button.';
        PmtDiscMsg: Label 'Payment Discount Date is earlier than Date Received. Payment will be registered as partial payment.';

    procedure PopulateTable()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Customer: Record Customer;
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup.TestField("Bal. Account No.");

        Reset();
        DeleteAll();

        CustLedgerEntry.SetFilter("Document Type", '<>%1', CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange(Open, true);
        OnPopulateTableOnAfterCustLedgerEntrySetFilters(CustLedgerEntry, Rec);
        if CustLedgerEntry.FindSet() then
            repeat
                if Customer.Get(CustLedgerEntry."Customer No.") then begin
                    CustLedgerEntry.CalcFields("Remaining Amount");

                    Init();
                    "Ledger Entry No." := CustLedgerEntry."Entry No.";
                    "Source No." := CustLedgerEntry."Customer No.";
                    Name := Customer.Name;
                    "Document No." := CustLedgerEntry."Document No.";
                    "Document Type" := CustLedgerEntry."Document Type";
                    Description := CustLedgerEntry.Description;
                    "Due Date" := CustLedgerEntry."Due Date";
                    "Remaining Amount" := CustLedgerEntry."Remaining Amount";
                    "Original Remaining Amount" := CustLedgerEntry."Remaining Amount";
                    "Pmt. Discount Date" := CustLedgerEntry."Pmt. Discount Date";
                    "Rem. Amt. after Discount" := "Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";
                    if CustLedgerEntry."Payment Method Code" <> '' then
                        "Payment Method Code" := CustLedgerEntry."Payment Method Code";
                    "Bal. Account Type" := Enum::"Payment Balance Account Type".FromInteger(PaymentRegistrationSetup."Bal. Account Type");
                    "Bal. Account No." := PaymentRegistrationSetup."Bal. Account No.";
                    "External Document No." := CustLedgerEntry."External Document No.";
                    OnPopulateTableOnBeforeInsert(Rec, CustLedgerEntry);
                    Insert();
                end;
            until CustLedgerEntry.Next() = 0;

        if FindSet() then;
    end;

    procedure Navigate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Navigate: Page Navigate;
    begin
        CustLedgerEntry.Get("Ledger Entry No.");
        Navigate.SetDoc(CustLedgerEntry."Posting Date", CustLedgerEntry."Document No.");
        Navigate.Run();
    end;

    procedure Reload()
    var
        TempDataSavePmtRegnBuf: Record "Payment Registration Buffer" temporary;
        TempRecSavePmtRegnBuf: Record "Payment Registration Buffer" temporary;
    begin
        TempRecSavePmtRegnBuf.Copy(Rec, true);

        SaveUserValues(TempDataSavePmtRegnBuf);

        PopulateTable();

        RestoreUserValues(TempDataSavePmtRegnBuf);

        Copy(TempRecSavePmtRegnBuf);
        if Get("Ledger Entry No.") then;
    end;

    local procedure SaveUserValues(var TempSavePmtRegnBuf: Record "Payment Registration Buffer" temporary)
    var
        TempWorkPmtRegnBuf: Record "Payment Registration Buffer" temporary;
    begin
        TempWorkPmtRegnBuf.Copy(Rec, true);
        TempWorkPmtRegnBuf.Reset();
        TempWorkPmtRegnBuf.SetRange("Payment Made", true);
        if TempWorkPmtRegnBuf.FindSet() then
            repeat
                TempSavePmtRegnBuf := TempWorkPmtRegnBuf;
                TempSavePmtRegnBuf.Insert();
            until TempWorkPmtRegnBuf.Next() = 0;
    end;

    local procedure RestoreUserValues(var TempSavePmtRegnBuf: Record "Payment Registration Buffer" temporary)
    begin
        if TempSavePmtRegnBuf.FindSet() then
            repeat
                if Get(TempSavePmtRegnBuf."Ledger Entry No.") then begin
                    "Payment Made" := TempSavePmtRegnBuf."Payment Made";
                    "Date Received" := TempSavePmtRegnBuf."Date Received";
                    "Pmt. Discount Date" := TempSavePmtRegnBuf."Pmt. Discount Date";
                    SuggestAmountReceivedBasedOnDate();
                    "Remaining Amount" := TempSavePmtRegnBuf."Remaining Amount";
                    "Amount Received" := TempSavePmtRegnBuf."Amount Received";
                    "External Document No." := TempSavePmtRegnBuf."External Document No.";
                    OnRestoreUserValuesOnBeforeModify(Rec, TempSavePmtRegnBuf);
                    Modify();
                end;
            until TempSavePmtRegnBuf.Next() = 0;
    end;

    procedure GetPmtDiscStyle(): Text
    begin
        if ("Pmt. Discount Date" < "Date Received") and ("Remaining Amount" <> 0) and ("Date Received" < "Due Date") then
            exit('Unfavorable');
        exit('');
    end;

    procedure GetDueDateStyle() ReturnValue: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDueDateStyle(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if "Due Date" < "Date Received" then
            exit('Unfavorable');
        exit('');
    end;

    procedure GetWarning(): Text
    begin
        if "Date Received" <= "Pmt. Discount Date" then
            exit('');

        if "Date Received" > "Due Date" then
            exit(DueDateMsg);

        if "Remaining Amount" <> 0 then
            exit(PmtDiscMsg);

        exit('');
    end;

    local procedure AutoFillDate()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        if "Date Received" = 0D then begin
            PaymentRegistrationSetup.Get(UserId);
            if PaymentRegistrationSetup."Auto Fill Date Received" then
                "Date Received" := WorkDate();
        end;
    end;

    local procedure SuggestAmountReceivedBasedOnDate()
    begin
        "Amount Received" := GetMaximumPaymentAmountBasedOnDate();
        if "Date Received" = 0D then
            exit;
        "Remaining Amount" := 0;
    end;

    local procedure GetMaximumPaymentAmountBasedOnDate(): Decimal
    begin
        if "Date Received" = 0D then
            exit(0);

        if "Date Received" <= "Pmt. Discount Date" then
            exit("Rem. Amt. after Discount");

        exit("Original Remaining Amount");
    end;

    local procedure UpdateRemainingAmount()
    begin
        if "Date Received" = 0D then
            exit;
        if Abs("Amount Received") >= Abs("Original Remaining Amount") then
            "Remaining Amount" := 0
        else
            if "Date Received" <= "Pmt. Discount Date" then begin
                if "Amount Received" >= "Rem. Amt. after Discount" then
                    "Remaining Amount" := 0
                else
                    "Remaining Amount" := "Original Remaining Amount" - "Amount Received";
            end else
                "Remaining Amount" := "Original Remaining Amount" - "Amount Received";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateTableOnBeforeInsert(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateTableOnAfterCustLedgerEntrySetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var PaymentRegistrationBuffer: Record "Payment Registration Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreUserValuesOnBeforeModify(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"; var TempSavePmtRegnBuf: Record "Payment Registration Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDueDateStyle(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"; var ReturnValue: Text; var IsHandled: Boolean)
    begin
    end;
}

