codeunit 393 "Reminder-Issue"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Issued Reminder Header" = rimd,
                  TableData "Issued Reminder Line" = rimd,
                  TableData "Reminder/Fin. Charge Entry" = rimd;

    trigger OnRun()
    var
        CustPostingGr: Record "Customer Posting Group";
        ReminderLine: Record "Reminder Line";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        ReminderCommentLine: Record "Reminder Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssueReminder(ReminderHeader, ReplacePostingDate, PostingDate, IsHandled);
        if IsHandled then
            exit;

        with ReminderHeader do begin
            UpdateReminderRounding(ReminderHeader);
            if (PostingDate <> 0D) and (ReplacePostingDate or ("Posting Date" = 0D)) then
                Validate("Posting Date", PostingDate);
            TestField("Customer No.");
            CheckIfBlocked("Customer No.");

            TestField("Posting Date");
            TestField("Document Date");
            TestField("Due Date");
            TestField("Customer Posting Group");
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                Error(
                  DimensionCombinationIsBlockedErr,
                  TableCaption, "No.", DimMgt.GetDimCombErr);

            TableID[1] := DATABASE::Customer;
            No[1] := "Customer No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                Error(
                  Text003,
                  TableCaption, "No.", DimMgt.GetDimValuePostingErr);

            CustPostingGr.Get("Customer Posting Group");
            CalcFields("Interest Amount", "Additional Fee", "Remaining Amount", "Add. Fee per Line");
            if ("Interest Amount" = 0) and ("Additional Fee" = 0) and ("Add. Fee per Line" = 0) and ("Remaining Amount" = 0) then
                Error(Text000);
            SourceCodeSetup.Get();
            SourceCodeSetup.TestField(Reminder);
            SrcCode := SourceCodeSetup.Reminder;

            if ("Issuing No." = '') and ("No. Series" <> "Issuing No. Series") then begin
                TestField("Issuing No. Series");
                "Issuing No." := NoSeriesMgt.GetNextNo("Issuing No. Series", "Posting Date", true);
                Modify;
                Commit();
            end;
            if "Issuing No." <> '' then
                DocNo := "Issuing No."
            else
                DocNo := "No.";

            ProcessReminderLines(ReminderHeader, ReminderLine);

            if (ReminderInterestAmount <> 0) and "Post Interest" then begin
                if ReminderInterestAmount < 0 then
                    Error(Text001);
                InitGenJnlLine(GenJnlLine."Account Type"::"G/L Account", CustPostingGr.GetInterestAccount, true);
                GenJnlLine.Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                GenJnlLine.Validate(Amount, -ReminderInterestAmount - ReminderInterestVATAmount);
                GenJnlLine.UpdateLineBalance;
                TotalAmount := TotalAmount - GenJnlLine.Amount;
                TotalAmountLCY := TotalAmountLCY - GenJnlLine."Balance (LCY)";
                GenJnlLine."Bill-to/Pay-to No." := "Customer No.";
                GenJnlLine.Insert();
            end;

            if (TotalAmount <> 0) or (TotalAmountLCY <> 0) then begin
                InitGenJnlLine(GenJnlLine."Account Type"::Customer, "Customer No.", true);
                GenJnlLine.Validate(Amount, TotalAmount);
                GenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
                GenJnlLine.Insert();
            end;

            Clear(GenJnlPostLine);
            if GenJnlLine.Find('-') then
                repeat
                    GenJnlLine2 := GenJnlLine;
                    GenJnlLine2."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                    GenJnlLine2."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                    GenJnlLine2."Dimension Set ID" := "Dimension Set ID";
                    GenJnlPostLine.Run(GenJnlLine2);
                until GenJnlLine.Next = 0;

            GenJnlLine.DeleteAll();

            if (ReminderInterestAmount <> 0) and "Post Interest" then begin
                TestField("Fin. Charge Terms Code");
                FinChrgTerms.Get("Fin. Charge Terms Code");
                if FinChrgTerms."Interest Calculation" in
                   [FinChrgTerms."Interest Calculation"::"Closed Entries",
                    FinChrgTerms."Interest Calculation"::"All Entries"]
                then begin
                    ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
                    if ReminderLine.Find('-') then
                        repeat
                            UpdateCustLedgEntriesCalculateInterest(ReminderLine."Entry No.", "Currency Code");
                        until ReminderLine.Next = 0;
                    ReminderLine.SetRange(Type);
                end;
            end;

            InsertIssuedReminderHeader(ReminderHeader, IssuedReminderHeader);

            if NextEntryNo = 0 then begin
                ReminderFinChargeEntry.LockTable();
                NextEntryNo := ReminderFinChargeEntry.GetLastEntryNo() + 1;
            end;

            ReminderCommentLine.CopyComments(
              ReminderCommentLine.Type::Reminder, ReminderCommentLine.Type::"Issued Reminder", "No.", IssuedReminderHeader."No.");
            ReminderCommentLine.DeleteComments(ReminderCommentLine.Type::Reminder, "No.");

            ReminderLine.SetRange("Detailed Interest Rates Entry");
            if ReminderLine.FindSet then
                repeat
                    if (ReminderLine.Type = ReminderLine.Type::"Customer Ledger Entry") and
                       (ReminderLine."Entry No." <> 0) and (not ReminderLine."Detailed Interest Rates Entry")
                    then begin
                        InsertReminderEntry(ReminderHeader, ReminderLine);
                        NextEntryNo := NextEntryNo + 1;
                    end;
                    InsertIssuedReminderLine(ReminderLine, IssuedReminderHeader."No.");
                until ReminderLine.Next = 0;
            ReminderLine.DeleteAll();
            Delete;
        end;

        OnAfterIssueReminder(ReminderHeader, IssuedReminderHeader."No.", GenJnlPostLine);
    end;

    var
        Text000: Label 'There is nothing to issue.';
        Text001: Label 'Interests must be positive or 0';
        DimensionCombinationIsBlockedErr: Label 'The combination of dimensions used in %1 %2 is blocked. %3.', Comment = '%1: TABLECAPTION(Reminder Header); %2: Field(No.); %3: Text GetDimCombErr';
        Text003: Label 'A dimension used in %1 %2 has caused an error. %3';
        SourceCodeSetup: Record "Source Code Setup";
        FinChrgTerms: Record "Finance Charge Terms";
        ReminderHeader: Record "Reminder Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlLine2: Record "Gen. Journal Line";
        SourceCode: Record "Source Code";
        DimMgt: Codeunit DimensionManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocNo: Code[20];
        NextEntryNo: Integer;
        ReplacePostingDate: Boolean;
        PostingDate: Date;
        SrcCode: Code[10];
        ReminderInterestAmount: Decimal;
        ReminderInterestVATAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        Text004: Label '%1 must not be %2 in %3 %4.', Comment = '%1 = Field name, %2 = field value, %3 = table caption, %4 customer number';
        LineFeeAmountErr: Label 'Line Fee amount must be positive and non-zero for Line Fee applied to %1 %2.', Comment = '%1 = Document Type, %2 = Document No.. E.g. Line Fee amount must be positive and non-zero for Line Fee applied to Invoice 102421';
        AppliesToDocErr: Label 'Line Fee has to be applied to an open overdue document.';
        EntryNotOverdueErr: Label '%1 %2 in %3 is not overdue.', Comment = '%1 = Document Type, %2 = Document No., %3 = Table name. E.g. Invoice 12313 in Cust. Ledger Entry is not overdue.';
        LineFeeAlreadyIssuedErr: Label 'The Line Fee for %1 %2 on reminder level %3 has already been issued.', Comment = '%1 = Document Type, %2 = Document No. %3 = Reminder Level. E.g. The Line Fee for Invoice 141232 on reminder level 2 has already been issued.';
        MultipleLineFeesSameDocErr: Label 'You cannot issue multiple line fees for the same level for the same document. Error with line fees for %1 %2.', Comment = '%1 = Document Type, %2 = Document No. E.g. You cannot issue multiple line fees for the same level for the same document. Error with line fees for Invoice 1312312.';

    procedure Set(var NewReminderHeader: Record "Reminder Header"; NewReplacePostingDate: Boolean; NewPostingDate: Date)
    begin
        ReminderHeader := NewReminderHeader;
        ReplacePostingDate := NewReplacePostingDate;
        PostingDate := NewPostingDate;
    end;

    procedure GetIssuedReminder(var NewIssuedReminderHeader: Record "Issued Reminder Header")
    begin
        NewIssuedReminderHeader := IssuedReminderHeader;
    end;

    local procedure InitGenJnlLine(AccType: Integer; AccNo: Code[20]; SystemCreatedEntry: Boolean)
    begin
        with ReminderHeader do begin
            GenJnlLine.Init();
            GenJnlLine."Line No." := GenJnlLine."Line No." + 1;
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Reminder;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Posting Date" := "Posting Date";
            GenJnlLine."Document Date" := "Document Date";
            GenJnlLine."Account Type" := AccType;
            GenJnlLine."Account No." := AccNo;
            GenJnlLine.Validate("Account No.");
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account" then begin
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
                GenJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
                GenJnlLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            end;
            GenJnlLine.Validate("Currency Code", "Currency Code");
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then begin
                GenJnlLine.Validate(Amount, TotalAmount);
                GenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
                GenJnlLine."Due Date" := "Due Date";
            end;
            GenJnlLine.Description := "Posting Description";
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
            GenJnlLine."Source No." := "Customer No.";
            GenJnlLine."Source Code" := SrcCode;
            GenJnlLine."Reason Code" := "Reason Code";
            GenJnlLine."System-Created Entry" := SystemCreatedEntry;
            GenJnlLine."Posting No. Series" := "Issuing No. Series";
            GenJnlLine."Salespers./Purch. Code" := '';
            GenJnlLine."Country/Region Code" := "Country/Region Code";
            GenJnlLine."VAT Registration No." := "VAT Registration No.";
        end;

        OnAfterInitGenJnlLine(GenJnlLine, ReminderHeader);
    end;

    procedure DeleteIssuedReminderLines(IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.DeleteAll();
    end;

    procedure IncrNoPrinted(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        with IssuedReminderHeader do begin
            Find;
            "No. Printed" := "No. Printed" + 1;
            Modify;
            Commit();
        end;
    end;

    procedure TestDeleteHeader(ReminderHeader: Record "Reminder Header"; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        with ReminderHeader do begin
            Clear(IssuedReminderHeader);
            SourceCodeSetup.Get();
            SourceCodeSetup.TestField("Deleted Document");
            SourceCode.Get(SourceCodeSetup."Deleted Document");

            if ("Issuing No. Series" <> '') and
               (("Issuing No." <> '') or ("No. Series" = "Issuing No. Series"))
            then begin
                IssuedReminderHeader.TransferFields(ReminderHeader);
                if "Issuing No." <> '' then
                    IssuedReminderHeader."No." := "Issuing No.";
                IssuedReminderHeader."Pre-Assigned No. Series" := "No. Series";
                IssuedReminderHeader."Pre-Assigned No." := "No.";
                IssuedReminderHeader."Posting Date" := Today;
                IssuedReminderHeader."User ID" := UserId;
                IssuedReminderHeader."Source Code" := SourceCode.Code;
                OnAfterTestDeleteHeader(IssuedReminderHeader, ReminderHeader);
            end;
        end;
    end;

    procedure DeleteHeader(ReminderHeader: Record "Reminder Header"; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        with ReminderHeader do begin
            TestDeleteHeader(ReminderHeader, IssuedReminderHeader);
            if IssuedReminderHeader."No." <> '' then begin
                IssuedReminderHeader."Shortcut Dimension 1 Code" := '';
                IssuedReminderHeader."Shortcut Dimension 2 Code" := '';
                IssuedReminderHeader.Insert();
                IssuedReminderLine.Init();
                IssuedReminderLine."Reminder No." := "No.";
                IssuedReminderLine."Line No." := 10000;
                IssuedReminderLine.Description := SourceCode.Description;
                IssuedReminderLine.Insert();
            end;
        end;
    end;

    procedure ChangeDueDate(var ReminderEntry2: Record "Reminder/Fin. Charge Entry"; NewDueDate: Date; OldDueDate: Date)
    begin
        ReminderEntry2."Due Date" := ReminderEntry2."Due Date" + (NewDueDate - OldDueDate);
        ReminderEntry2.Modify();
    end;

    local procedure InsertIssuedReminderHeader(ReminderHeader: Record "Reminder Header"; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader.TransferFields(ReminderHeader);
        IssuedReminderHeader."No." := DocNo;
        IssuedReminderHeader."Pre-Assigned No." := ReminderHeader."No.";
        IssuedReminderHeader."Source Code" := SrcCode;
        IssuedReminderHeader."User ID" := UserId;
        OnBeforeIssuedReminderHeaderInsert(IssuedReminderHeader, ReminderHeader);
        IssuedReminderHeader.Insert();
    end;

    local procedure InsertIssuedReminderLine(ReminderLine: Record "Reminder Line"; IssuedReminderNo: Code[20])
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.Init();
        IssuedReminderLine.TransferFields(ReminderLine);
        IssuedReminderLine."Reminder No." := IssuedReminderNo;
        OnBeforeIssuedReminderLineInsert(IssuedReminderLine, ReminderLine);
        IssuedReminderLine.Insert();
    end;

    local procedure InsertGenJnlLineForFee(var ReminderLine: Record "Reminder Line")
    begin
        with ReminderHeader do
            if ReminderLine.Amount <> 0 then begin
                ReminderLine.TestField("No.");
                InitGenJnlLine(GenJnlLine."Account Type"::"G/L Account",
                  ReminderLine."No.",
                  ReminderLine."Line Type" = ReminderLine."Line Type"::Rounding);
                GenJnlLine."Gen. Prod. Posting Group" := ReminderLine."Gen. Prod. Posting Group";
                GenJnlLine."VAT Prod. Posting Group" := ReminderLine."VAT Prod. Posting Group";
                GenJnlLine."VAT Calculation Type" := ReminderLine."VAT Calculation Type";
                if ReminderLine."VAT Calculation Type" =
                   ReminderLine."VAT Calculation Type"::"Sales Tax"
                then begin
                    GenJnlLine."Tax Area Code" := "Tax Area Code";
                    GenJnlLine."Tax Liable" := "Tax Liable";
                    GenJnlLine."Tax Group Code" := ReminderLine."Tax Group Code";
                end;
                GenJnlLine."VAT %" := ReminderLine."VAT %";
                GenJnlLine.Validate(Amount, -ReminderLine.Amount - ReminderLine."VAT Amount");
                GenJnlLine."VAT Amount" := -ReminderLine."VAT Amount";
                GenJnlLine.UpdateLineBalance;
                TotalAmount := TotalAmount - GenJnlLine.Amount;
                TotalAmountLCY := TotalAmountLCY - GenJnlLine."Balance (LCY)";
                GenJnlLine."Bill-to/Pay-to No." := "Customer No.";
                GenJnlLine.Insert();
            end;
    end;

    local procedure InsertReminderEntry(ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line")
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        with ReminderFinChargeEntry do begin
            Init;
            "Entry No." := NextEntryNo;
            Type := Type::Reminder;
            "No." := IssuedReminderHeader."No.";
            "Posting Date" := ReminderHeader."Posting Date";
            "Document Date" := ReminderHeader."Document Date";
            "Due Date" := IssuedReminderHeader."Due Date";
            "Customer No." := ReminderHeader."Customer No.";
            "Customer Entry No." := ReminderLine."Entry No.";
            "Document Type" := ReminderLine."Document Type";
            "Document No." := ReminderLine."Document No.";
            "Reminder Level" := ReminderLine."No. of Reminders";
            "Remaining Amount" := ReminderLine."Remaining Amount";
            "Interest Amount" := ReminderLine.Amount;
            "Interest Posted" :=
              ("Interest Amount" <> 0) and ReminderHeader."Post Interest";
            "User ID" := UserId;
            OnBeforeReminderEntryInsert(ReminderFinChargeEntry, ReminderHeader);
            Insert;
        end;
        if ReminderLine."Line Type" <> ReminderLine."Line Type"::"Not Due" then
            UpdateCustLedgEntryLastIssuedReminderLevel(ReminderFinChargeEntry);
    end;

    local procedure CheckLineFee(var ReminderLine: Record "Reminder Line"; var ReminderHeader: Record "Reminder Header")
    var
        CustLedgEntry3: Record "Cust. Ledger Entry";
        ReminderLine2: Record "Reminder Line";
    begin
        if ReminderLine.Amount <= 0 then
            Error(LineFeeAmountErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No.");
        if ReminderLine."Applies-to Document No." = '' then
            Error(AppliesToDocErr);

        with CustLedgEntry3 do begin
            SetRange("Document Type", ReminderLine."Applies-to Document Type");
            SetRange("Document No.", ReminderLine."Applies-to Document No.");
            SetRange("Customer No.", ReminderHeader."Customer No.");
            FindFirst;
            if "Due Date" >= ReminderHeader."Document Date" then
                Error(
                  EntryNotOverdueErr, FieldCaption("Document No."), ReminderLine."Applies-to Document No.", TableName);
        end;

        with IssuedReminderLine do begin
            Reset;
            SetRange("Applies-To Document Type", ReminderLine."Applies-to Document Type");
            SetRange("Applies-To Document No.", ReminderLine."Applies-to Document No.");
            SetRange(Type, Type::"Line Fee");
            SetRange("No. of Reminders", ReminderLine."No. of Reminders");
            if FindFirst then
                Error(
                  LineFeeAlreadyIssuedErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No.",
                  ReminderLine."No. of Reminders");
        end;

        with ReminderLine2 do begin
            Reset;
            SetRange("Applies-to Document Type", ReminderLine."Applies-to Document Type");
            SetRange("Applies-to Document No.", ReminderLine."Applies-to Document No.");
            SetRange(Type, IssuedReminderLine.Type::"Line Fee");
            SetRange("No. of Reminders", ReminderLine."No. of Reminders");
            if Count > 1 then
                Error(MultipleLineFeesSameDocErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No.");
        end;
    end;

    local procedure ProcessReminderLines(ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
        with ReminderHeader do begin
            ReminderLine.SetRange("Reminder No.", "No.");
            ReminderLine.SetRange("Detailed Interest Rates Entry", false);
            if ReminderLine.Find('-') then
                repeat
                    case ReminderLine.Type of
                        ReminderLine.Type::" ":
                            ReminderLine.TestField(Amount, 0);
                        ReminderLine.Type::"G/L Account":
                            if "Post Additional Fee" then
                                InsertGenJnlLineForFee(ReminderLine);
                        ReminderLine.Type::"Customer Ledger Entry":
                            begin
                                ReminderLine.TestField("Entry No.");
                                ReminderInterestAmount := ReminderInterestAmount + ReminderLine.Amount;
                                ReminderInterestVATAmount := ReminderInterestVATAmount + ReminderLine."VAT Amount";
                            end;
                        ReminderLine.Type::"Line Fee":
                            if "Post Add. Fee per Line" then begin
                                CheckLineFee(ReminderLine, ReminderHeader);
                                InsertGenJnlLineForFee(ReminderLine);
                            end;
                    end;
                until ReminderLine.Next = 0;
        end;

        OnAfterProcessReminderLines(ReminderHeader, ReminderLine, ReminderInterestAmount, ReminderInterestVATAmount);
    end;

    procedure UpdateCustLedgEntryLastIssuedReminderLevel(ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.LockTable();
        CustLedgEntry.Get(ReminderFinChargeEntry."Customer Entry No.");
        CustLedgEntry."Last Issued Reminder Level" := ReminderFinChargeEntry."Reminder Level";
        CustLedgEntry.Modify();
    end;

    local procedure UpdateCustLedgEntriesCalculateInterest(EntryNo: Integer; CurrencyCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.TestField("Currency Code", CurrencyCode);
        CustLedgerEntry.CalcFields("Remaining Amount");
        if CustLedgerEntry."Remaining Amount" = 0 then begin
            CustLedgerEntry."Calculate Interest" := false;
            CustLedgerEntry.Modify();
        end;
        CustLedgerEntry2.SetCurrentKey("Closed by Entry No.");
        CustLedgerEntry2.SetRange("Closed by Entry No.", EntryNo);
        CustLedgerEntry2.SetRange("Closing Interest Calculated", false);
        CustLedgerEntry2.ModifyAll("Closing Interest Calculated", true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssueReminder(var ReminderHeader: Record "Reminder Header"; IssuedReminderNo: Code[20]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessReminderLines(ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var InterestAmount: Decimal; var InterestVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestDeleteHeader(var IssuedReminderHeader: Record "Issued Reminder Header"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssueReminder(var ReminderHeader: Record "Reminder Header"; var ReplacePostingDate: Boolean; var PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedReminderHeaderInsert(var IssuedReminderHeader: Record "Issued Reminder Header"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedReminderLineInsert(var IssuedReminderLine: Record "Issued Reminder Line"; ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderEntryInsert(var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    local procedure CheckIfBlocked(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);

        if Customer."Privacy Blocked" then
            Error(Text004, Customer.FieldCaption("Privacy Blocked"), Customer."Privacy Blocked", Customer.TableCaption, CustomerNo);

        if Customer.Blocked = Customer.Blocked::All then
            Error(Text004, Customer.FieldCaption(Blocked), Customer.Blocked, Customer.TableCaption, CustomerNo);
    end;
}

