codeunit 1393 "Cancel Issued Reminder"
{
    Permissions = TableData "Cust. Ledger Entry" = m,
                  TableData "Issued Reminder Header" = m,
                  TableData "Issued Reminder Line" = m,
                  TableData "Reminder/Fin. Charge Entry" = m;
    TableNo = "Issued Reminder Header";

    trigger OnRun()
    begin
        if not CheckIssuedReminder(Rec) then
            exit;

        CancelIssuedReminder(Rec);
    end;

    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        TempErrorMessage: Record "Error Message" temporary;
        ReminderSourceCode: Code[10];
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        CancelNextLevelReminderTxt: Label 'You must cancel the issued reminder %1 before canceling issued reminder %2.', Comment = '%1 and %2 issued reminder numbers.';
        ShowIssuedReminderTxt: Label 'Show issued reminder %1.', Comment = '%1 - issued reminder number.';
        CancelAppliedEntryErr: Label 'You must unapply customer ledger entry %1 before canceling issued reminder %2.', Comment = '%1 - entry number, %2 - issued reminder number';
        ShowCustomerLedgerEntryTxt: Label 'Show customer ledger entry %1.', Comment = '%1 - entry number.';
        SkipShowNotification: Boolean;
        UseSameDocumentNo: Boolean;
        UseSamePostingDate: Boolean;
        NewPostingDate: Date;

    local procedure CheckIssuedReminder(IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    begin
        IssuedReminderHeader.TestField(Canceled, false);

        if not CheckAppliedReminderCustLedgerEntry(IssuedReminderHeader) then
            exit(false);
        if not CheckNextReminderLevel(IssuedReminderHeader) then
            exit(false);

        exit(true);
    end;

    local procedure CancelIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        ReminderTerms: Record "Reminder Terms";
        CustPostingGr: Record "Customer Posting Group";
        FeePosted: Boolean;
        DocumentNo: Code[20];
        PostingDate: Date;
        ReminderInterestAmount: Decimal;
        ReminderInterestVATAmount: Decimal;
    begin
        OnBeforeCancelIssuedReminder(IssuedReminderHeader);

        SourceCodeSetup.Get();
        SourceCodeSetup.TestField(Reminder);
        ReminderSourceCode := SourceCodeSetup.Reminder;
        ReminderTerms.Get(IssuedReminderHeader."Reminder Terms Code");
        FeePosted := IsFeePosted(IssuedReminderHeader);
        GetDocumentNoAndPostingDate(IssuedReminderHeader, DocumentNo, PostingDate);

        SetIssuedReminderCancelled(IssuedReminderHeader, DocumentNo);

        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        if IssuedReminderLine.FindSet() then
            repeat
                case IssuedReminderLine.Type of
                    IssuedReminderLine.Type::"Customer Ledger Entry":
                        begin
                            DecreaseCustomerLedgerEntryLastIssuedReminderLevel(IssuedReminderLine."Entry No.");
                            SetReminderEntryCancelled(IssuedReminderLine);
                            ReminderInterestAmount := ReminderInterestAmount + IssuedReminderLine.Amount;
                            ReminderInterestVATAmount := ReminderInterestVATAmount + IssuedReminderLine."VAT Amount";
                        end;
                    IssuedReminderLine.Type::"G/L Account":
                        if ReminderTerms."Post Additional Fee" then
                            InsertGenJnlLineForFee(IssuedReminderHeader, IssuedReminderLine, DocumentNo, PostingDate);
                    IssuedReminderLine.Type::"Line Fee":
                        if ReminderTerms."Post Add. Fee per Line" then
                            InsertGenJnlLineForFee(IssuedReminderHeader, IssuedReminderLine, DocumentNo, PostingDate);
                end;
            until IssuedReminderLine.Next() = 0;

        if (ReminderInterestAmount <> 0) and ReminderTerms."Post Interest" then begin
            CustPostingGr.Get(IssuedReminderHeader."Customer Posting Group");
            InitGenJnlLine(IssuedReminderHeader, TempGenJnlLine, TempGenJnlLine."Account Type"::"G/L Account",
              CustPostingGr.GetInterestAccount(), true, DocumentNo, PostingDate);
            TempGenJnlLine.Validate("VAT Bus. Posting Group", IssuedReminderHeader."VAT Bus. Posting Group");
            TempGenJnlLine.Validate(Amount, ReminderInterestAmount + ReminderInterestVATAmount);
            TempGenJnlLine.UpdateLineBalance();
            TotalAmount := TotalAmount - TempGenJnlLine.Amount;
            TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
            TempGenJnlLine."Bill-to/Pay-to No." := IssuedReminderHeader."Customer No.";
            TempGenJnlLine.Insert();
        end;

        if (TotalAmount <> 0) or (TotalAmountLCY <> 0) then begin
            InitGenJnlLine(
              IssuedReminderHeader, TempGenJnlLine, TempGenJnlLine."Account Type"::Customer,
              IssuedReminderHeader."Customer No.", true, DocumentNo, PostingDate);
            TempGenJnlLine.Validate(Amount, TotalAmount);
            TempGenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
            TempGenJnlLine.Insert();
        end;

        if FeePosted then
            PostGenJnlLines;

        OnAfterCancelIssuedReminder(IssuedReminderHeader);
    end;

    local procedure CheckNextReminderLevel(IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        IssuedReminderLine2: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.SetRange(Type, IssuedReminderLine.Type::"Customer Ledger Entry");
        if IssuedReminderLine.FindSet() then
            repeat
                IssuedReminderLine2.SetRange("Document Type", IssuedReminderLine."Document Type");
                IssuedReminderLine2.SetRange("Document No.", IssuedReminderLine."Document No.");
                IssuedReminderLine2.SetRange(Canceled, false);
                IssuedReminderLine2.SetFilter("No. of Reminders", '>%1', IssuedReminderLine."No. of Reminders");
                if IssuedReminderLine2.FindFirst then begin
                    TempErrorMessage.LogMessage(
                      IssuedReminderHeader,
                      IssuedReminderHeader.FieldNo("No."),
                      TempErrorMessage."Message Type"::Error,
                      StrSubstNo(CancelNextLevelReminderTxt, IssuedReminderLine2."Reminder No.", IssuedReminderLine."Reminder No."));
                    if not SkipShowNotification then
                        ShowNextLevelReminderNotification(IssuedReminderLine."Reminder No.", IssuedReminderLine2."Reminder No.");
                    exit(false);
                end;
            until IssuedReminderLine.Next() = 0;

        exit(true);
    end;

    local procedure CheckAppliedReminderCustLedgerEntry(IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Reminder);
        CustLedgerEntry.SetRange("Document No.", IssuedReminderHeader."No.");
        if CustLedgerEntry.FindFirst then begin
            CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
            if CustLedgerEntry.Amount <> CustLedgerEntry."Remaining Amount" then begin
                TempErrorMessage.LogMessage(
                  IssuedReminderHeader,
                  IssuedReminderHeader.FieldNo("No."),
                  TempErrorMessage."Message Type"::Error,
                  StrSubstNo(CancelAppliedEntryErr, CustLedgerEntry."Entry No.", IssuedReminderHeader."No."));
                if not SkipShowNotification then
                    ShowAppliedCustomerLedgerEntryNotification(CustLedgerEntry."Entry No.", IssuedReminderHeader);
                exit(false);
            end;
        end;

        exit(true);
    end;

    local procedure SetReminderEntryCancelled(IssuedReminderLine: Record "Issued Reminder Line")
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        ReminderFinChargeEntry.SetRange("No.", IssuedReminderLine."Reminder No.");
        ReminderFinChargeEntry.SetRange("Customer Entry No.", IssuedReminderLine."Entry No.");
        if ReminderFinChargeEntry.FindFirst then begin
            ReminderFinChargeEntry.Canceled := true;
            ReminderFinChargeEntry.Modify();
        end;
    end;

    local procedure DecreaseCustomerLedgerEntryLastIssuedReminderLevel(EntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry."Last Issued Reminder Level" := CustLedgerEntry."Last Issued Reminder Level" - 1;
        CustLedgerEntry.Modify();
    end;

    local procedure InsertGenJnlLineForFee(IssuedReminderHeader: Record "Issued Reminder Header"; var IssuedReminderLine: Record "Issued Reminder Line"; DocumentNo: Code[20]; PostingDate: Date)
    begin
        with IssuedReminderLine do
            if Amount <> 0 then begin
                TestField("No.");
                InitGenJnlLine(IssuedReminderHeader, TempGenJnlLine, TempGenJnlLine."Account Type"::"G/L Account",
                  "No.",
                  "Line Type" = "Line Type"::Rounding, DocumentNo, PostingDate);
                TempGenJnlLine.CopyFromIssuedReminderLine(IssuedReminderLine);
                if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then begin
                    TempGenJnlLine.Validate("Tax Area Code", IssuedReminderHeader."Tax Area Code");
                    TempGenJnlLine.Validate("Tax Liable", IssuedReminderHeader."Tax Liable");
                    TempGenJnlLine.Validate("Tax Group Code", "Tax Group Code");
                end;
                TempGenJnlLine.UpdateLineBalance;
                TotalAmount := TotalAmount - TempGenJnlLine.Amount;
                TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
                TempGenJnlLine."Bill-to/Pay-to No." := IssuedReminderHeader."Customer No.";
                TempGenJnlLine.Insert();
            end;
    end;

    local procedure InitGenJnlLine(IssuedReminderHeader: Record "Issued Reminder Header"; var GenJnlLine: Record "Gen. Journal Line"; AccountType: Integer; AccountNo: Code[20]; SystemCreatedEntry: Boolean; DocumentNo: Code[20]; PostingDate: Date)
    begin
        with GenJnlLine do begin
            Init;
            "Line No." := "Line No." + 1;
            "Document Type" := "Document Type"::" ";
            "Document No." := DocumentNo;
            "Posting Date" := PostingDate;

            "Account Type" := AccountType;
            Validate("Account No.", AccountNo);
            CopyFromIssuedReminderHeader(IssuedReminderHeader);
            if "Account Type" = "Account Type"::Customer then begin
                Amount := TotalAmount;
                "Amount (LCY)" := TotalAmountLCY;
                "Due Date" := IssuedReminderHeader."Due Date";
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::Reminder;
                "Applies-to Doc. No." := IssuedReminderHeader."No.";
            end;
            "Source Code" := ReminderSourceCode;
            "System-Created Entry" := SystemCreatedEntry;
            "Salespers./Purch. Code" := '';
        end;

        OnAfterInitGenJnlLine(GenJnlLine, IssuedReminderHeader);
    end;

    local procedure GetShowNextLevelReminderNotificationId(): Guid
    begin
        exit('45A066A7-A890-422A-9118-79DEB2E5DB75');
    end;

    local procedure GetAppliedCustomerLedgerEntryNotificationId(): Guid
    begin
        exit('F984E76B-CA21-46E3-B89C-146018C022B2');
    end;

    procedure GetErrorMessages(var TempErrorMessageResult: Record "Error Message" temporary): Boolean
    begin
        TempErrorMessageResult.Copy(TempErrorMessage, true);
        exit(not TempErrorMessage.IsEmpty);
    end;

    local procedure GetDocumentNoAndPostingDate(IssuedReminderHeader: Record "Issued Reminder Header"; var DocumentNo: Code[20]; var PostingDate: Date)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        if UseSamePostingDate then
            PostingDate := IssuedReminderHeader."Posting Date"
        else
            PostingDate := NewPostingDate;

        if UseSameDocumentNo then
            DocumentNo := IssuedReminderHeader."No."
        else begin
            SalesSetup.Get();
            SalesSetup.TestField("Canceled Issued Reminder Nos.");
            DocumentNo := NoSeriesManagement.GetNextNo(SalesSetup."Canceled Issued Reminder Nos.", PostingDate, true);
        end;
    end;

    local procedure PostGenJnlLines()
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        if TempGenJnlLine.FindSet() then
            repeat
                GenJnlPostLine.RunWithCheck(TempGenJnlLine);
            until TempGenJnlLine.Next() = 0;

        TempGenJnlLine.DeleteAll();
    end;

    procedure SetParameters(NewUseSameDocumentNo: Boolean; NewUseSamePostingDate: Boolean; PostingDate: Date; NewSkipShowNotification: Boolean)
    begin
        UseSameDocumentNo := NewUseSameDocumentNo;
        UseSamePostingDate := NewUseSamePostingDate;
        NewPostingDate := PostingDate;
        SkipShowNotification := NewSkipShowNotification;
    end;

    local procedure SetIssuedReminderCancelled(IssuedReminderHeader: Record "Issued Reminder Header"; DocumentNo: Code[20])
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderHeader.Validate(Canceled, true);
        IssuedReminderHeader."Canceled By" := UserId;
        IssuedReminderHeader."Canceled Date" := Today;
        IssuedReminderHeader."Canceled By Document No." := DocumentNo;
        IssuedReminderHeader.Modify();

        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.ModifyAll(Canceled, true);
    end;

    local procedure ShowNextLevelReminderNotification(ReminderNo1: Code[20]; ReminderNo2: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NextLevelReminderNotification: Notification;
    begin
        NextLevelReminderNotification.Id := GetShowNextLevelReminderNotificationId;
        NextLevelReminderNotification.Message :=
          StrSubstNo(CancelNextLevelReminderTxt, ReminderNo2, ReminderNo1);
        NextLevelReminderNotification.AddAction(
          StrSubstNo(ShowIssuedReminderTxt, ReminderNo2),
          CODEUNIT::"Cancel Issued Reminder",
          'ShowIssuedReminder');
        NextLevelReminderNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        NextLevelReminderNotification.SetData('IssuedReminderNo', ReminderNo2);
        IssuedReminderHeader.Get(ReminderNo1);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          NextLevelReminderNotification, IssuedReminderHeader.RecordId, GetShowNextLevelReminderNotificationId);
    end;

    procedure ShowIssuedReminder(Notification: Notification)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderNo: Code[20];
    begin
        Evaluate(IssuedReminderNo, Notification.GetData('IssuedReminderNo'));
        IssuedReminderHeader.Get(IssuedReminderNo);
        PAGE.Run(PAGE::"Issued Reminder", IssuedReminderHeader);
    end;

    local procedure ShowAppliedCustomerLedgerEntryNotification(EntryNo: Integer; IssuedReminderHeader: Record "Issued Reminder Header")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        AppliedCustomerLedgerNotification: Notification;
    begin
        AppliedCustomerLedgerNotification.Id := GetAppliedCustomerLedgerEntryNotificationId;
        AppliedCustomerLedgerNotification.Message :=
          StrSubstNo(CancelAppliedEntryErr, EntryNo, IssuedReminderHeader."No.");
        AppliedCustomerLedgerNotification.AddAction(
          StrSubstNo(ShowCustomerLedgerEntryTxt, EntryNo),
          CODEUNIT::"Cancel Issued Reminder",
          'ShowCustomerLedgerEntry');
        AppliedCustomerLedgerNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        AppliedCustomerLedgerNotification.SetData('EntryNo', Format(EntryNo));
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          AppliedCustomerLedgerNotification, IssuedReminderHeader.RecordId, GetAppliedCustomerLedgerEntryNotificationId);
    end;

    procedure ShowCustomerLedgerEntry(Notification: Notification)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        Evaluate(EntryNo, Notification.GetData('EntryNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);
    end;

    local procedure IsFeePosted(IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
        CustLedgerEntry.SetRange("Document No.", IssuedReminderHeader."No.");
        exit(not CustLedgerEntry.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCancelIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCancelIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;
}

