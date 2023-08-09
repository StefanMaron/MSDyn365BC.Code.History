codeunit 395 "FinChrgMemo-Issue"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rimd,
                  TableData "Issued Fin. Charge Memo Header" = rimd,
                  TableData "Issued Fin. Charge Memo Line" = rimd;

    trigger OnRun()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        FinChrgMemoLine: Record "Finance Charge Memo Line";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        OnBeforeIssueFinChargeMemo(FinChrgMemoHeader);

        with FinChrgMemoHeader do begin
            UpdateFinanceChargeRounding(FinChrgMemoHeader);
            if (PostingDate <> 0D) and (ReplacePostingDate or ("Posting Date" = 0D)) then
                Validate("Posting Date", PostingDate);

            CheckVATDate(FinChrgMemoHeader);
            TestField("Customer No.");
            TestField("Posting Date");
            TestField("Document Date");
            TestField("Due Date");
            TestField("Customer Posting Group");
            GLSetup.Get();
            if GLSetup."Journal Templ. Name Mandatory" then
                if "Post Additional Fee" or "Post Interest" then begin
                    if GenJnlBatch."Journal Template Name" = '' then
                        Error(MissingJournalFieldErr, TempGenJnlLine.FieldCaption("Journal Template Name"));
                    if GenJnlBatch.Name = '' then
                        Error(MissingJournalFieldErr, TempGenJnlLine.FieldCaption("Journal Batch Name"));
                end;
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                Error(
                  Text002,
                  TableCaption, "No.", DimMgt.GetDimCombErr());

            TableID[1] := DATABASE::Customer;
            No[1] := "Customer No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                Error(
                  Text003,
                  TableCaption, "No.", DimMgt.GetDimValuePostingErr());

            Customer.Get("Customer No.");
            Customer.TestField("Customer Posting Group");
            if "Customer Posting Group" <> Customer."Customer Posting Group" then
                Customer.CheckAllowMultiplePostingGroups();
            CustomerPostingGroup.Get("Customer Posting Group");
            CalcFields("Interest Amount", "Additional Fee", "Remaining Amount");
            if ("Interest Amount" = 0) and ("Additional Fee" = 0) and ("Remaining Amount" = 0) then
                Error(Text000);
            SourceCodeSetup.Get();
            SourceCodeSetup.TestField("Finance Charge Memo");
            SrcCode := SourceCodeSetup."Finance Charge Memo";

            if ("Issuing No." = '') and ("No. Series" <> "Issuing No. Series") then begin
                TestField("Issuing No. Series");
                "Issuing No." := NoSeriesMgt.GetNextNo("Issuing No. Series", "Posting Date", true);
                Modify();
                Commit();
            end;
            if "Issuing No." = '' then
                DocNo := "No."
            else
                DocNo := "Issuing No.";

            FinChrgMemoLine.SetRange("Finance Charge Memo No.", "No.");
            FinChrgMemoLine.SetRange("Detailed Interest Rates Entry", false);
            if FinChrgMemoLine.Find('-') then
                repeat
                    case FinChrgMemoLine.Type of
                        FinChrgMemoLine.Type::" ":
                            FinChrgMemoLine.TestField(Amount, 0);
                        FinChrgMemoLine.Type::"G/L Account":
                            if (FinChrgMemoLine.Amount <> 0) and
                               ("Post Additional Fee" or (FinChrgMemoLine."Line Type" = FinChrgMemoLine."Line Type"::Rounding))
                            then begin
                                FinChrgMemoLine.TestField("No.");
                                InitGenJnlLine(TempGenJnlLine."Account Type"::"G/L Account",
                                  FinChrgMemoLine."No.",
                                  FinChrgMemoLine."Line Type" = FinChrgMemoLine."Line Type"::Rounding);
                                TempGenJnlLine."Gen. Prod. Posting Group" := FinChrgMemoLine."Gen. Prod. Posting Group";
                                TempGenJnlLine."VAT Prod. Posting Group" := FinChrgMemoLine."VAT Prod. Posting Group";
                                TempGenJnlLine."VAT Calculation Type" := FinChrgMemoLine."VAT Calculation Type";
                                if FinChrgMemoLine."VAT Calculation Type" =
                                   FinChrgMemoLine."VAT Calculation Type"::"Sales Tax"
                                then begin
                                    TempGenJnlLine."Tax Area Code" := "Tax Area Code";
                                    TempGenJnlLine."Tax Liable" := "Tax Liable";
                                    TempGenJnlLine."Tax Group Code" := FinChrgMemoLine."Tax Group Code";
                                end;
                                TempGenJnlLine."VAT %" := FinChrgMemoLine."VAT %";
                                TempGenJnlLine.Validate(Amount, -FinChrgMemoLine.Amount - FinChrgMemoLine."VAT Amount");
                                TempGenJnlLine."VAT Amount" := -FinChrgMemoLine."VAT Amount";
                                TempGenJnlLine.UpdateLineBalance();
                                TotalAmount := TotalAmount - TempGenJnlLine.Amount;
                                TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
                                TempGenJnlLine."Bill-to/Pay-to No." := "Customer No.";
                                OnRunOnBeforeGLAccountGenJnlLineInsert(TempGenJnlLine);
                                TempGenJnlLine.Insert();
                                OnRunOnAfterGLAccountGenJnlLineInsert(TempGenJnlLine);
                            end;
                        FinChrgMemoLine.Type::"Customer Ledger Entry":
                            begin
                                FinChrgMemoLine.TestField("Entry No.");
                                CustLedgEntry.Get(FinChrgMemoLine."Entry No.");
                                CustLedgEntry.TestField("Currency Code", "Currency Code");
                                CheckNegativeFinChrgMemoLineAmount(FinChrgMemoLine);
                                FinChrgMemoInterestAmount := FinChrgMemoInterestAmount + FinChrgMemoLine.Amount;
                                FinChrgMemoInterestVATAmount := FinChrgMemoInterestVATAmount + FinChrgMemoLine."VAT Amount";
                            end;
                    end;
                    OnAfterGetFinChrgMemoLine(FinChrgMemoLine, DocNo, CurrencyExchangeRate.ExchangeRate(FinChrgMemoHeader."Posting Date", FinChrgMemoHeader."Currency Code"));
                until FinChrgMemoLine.Next() = 0;

            if (FinChrgMemoInterestAmount <> 0) and "Post Interest" then begin
                InitGenJnlLine(TempGenJnlLine."Account Type"::"G/L Account", CustomerPostingGroup.GetInterestAccount(), true);
                TempGenJnlLine.Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                TempGenJnlLine.Validate(Amount, -FinChrgMemoInterestAmount - FinChrgMemoInterestVATAmount);
                TempGenJnlLine.UpdateLineBalance();
                TotalAmount := TotalAmount - TempGenJnlLine.Amount;
                TotalAmountLCY := TotalAmountLCY - TempGenJnlLine."Balance (LCY)";
                TempGenJnlLine."Bill-to/Pay-to No." := "Customer No.";
                OnRunOnBeforeInterestGenJnlLineInsert(TempGenJnlLine);
                TempGenJnlLine.Insert();
                OnRunOnAfterInterestGenJnlLineInsert(TempGenJnlLine);
            end;

            if (TotalAmount <> 0) or (TotalAmountLCY <> 0) then begin
                InitGenJnlLine(TempGenJnlLine."Account Type"::Customer, "Customer No.", true);
                TempGenJnlLine.Validate(Amount, TotalAmount);
                TempGenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
                OnRunOnBeforeTotalGenJnlLineInsert(TempGenJnlLine);
                TempGenJnlLine.Insert();
                OnRunOnAfterTotalGenJnlLineInsert(TempGenJnlLine);
            end;
            if TempGenJnlLine.Find('-') then
                repeat
                    GenJnlLine2 := TempGenJnlLine;
                    SetDimensions(GenJnlLine2, FinChrgMemoHeader);
                    OnBeforeGenJnlPostLineRunWithCheck(GenJnlLine2, FinChrgMemoHeader);
                    GenJnlPostLine.RunWithCheck(GenJnlLine2);
                    OnRunOnAfterGenJnlPostLineRunWithCheck(TempGenJnlLine, GenJnlPostLine);
                until TempGenJnlLine.Next() = 0;

            TempGenJnlLine.DeleteAll();

            if FinChrgMemoInterestAmount <> 0 then begin
                TestField("Fin. Charge Terms Code");
                FinChrgTerms.Get("Fin. Charge Terms Code");
                if FinChrgTerms."Interest Calculation" in
                   [FinChrgTerms."Interest Calculation"::"Closed Entries",
                    FinChrgTerms."Interest Calculation"::"All Entries"]
                then begin
                    FinChrgMemoLine.SetRange(Type, FinChrgMemoLine.Type::"Customer Ledger Entry");
                    if FinChrgMemoLine.Find('-') then
                        repeat
                            UpdateCustLedgEntriesCalculateInterest(FinChrgMemoLine."Entry No.", "Document Date");
                        until FinChrgMemoLine.Next() = 0;
                    FinChrgMemoLine.SetRange(Type);
                end;
            end;

            InsertIssuedFinChrgMemoHeader(FinChrgMemoHeader, IssuedFinChrgMemoHeader);

            if NextEntryNo = 0 then begin
                ReminderFinChargeEntry.LockTable();
                NextEntryNo := ReminderFinChargeEntry.GetLastEntryNo() + 1;
            end;

            FinChrgCommentLine.CopyComments(
              FinChrgCommentLine.Type::"Finance Charge Memo", FinChrgCommentLine.Type::"Issued Finance Charge Memo", "No.",
              IssuedFinChrgMemoHeader."No.");
            FinChrgCommentLine.DeleteComments(FinChrgCommentLine.Type::"Finance Charge Memo", "No.");

            FinChrgMemoLine.SetRange("Detailed Interest Rates Entry");
            if FinChrgMemoLine.FindSet() then
                repeat
                    if (FinChrgMemoLine.Type = FinChrgMemoLine.Type::"Customer Ledger Entry") and
                       not FinChrgMemoLine."Detailed Interest Rates Entry"
                    then begin
                        InsertFinChargeEntry(IssuedFinChrgMemoHeader, FinChrgMemoLine);
                        NextEntryNo := NextEntryNo + 1;
                    end;
                    InsertIssuedFinChrgMemoLine(FinChrgMemoLine, IssuedFinChrgMemoHeader."No.");
                until FinChrgMemoLine.Next() = 0;

            FinChrgMemoLine.DeleteAll();
            Delete();
        end;

        OnAfterIssueFinChargeMemo(FinChrgMemoHeader, IssuedFinChrgMemoHeader."No.");
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        FinChrgTerms: Record "Finance Charge Terms";
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
        GenJnlBatch: Record "Gen. Journal Batch";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlLine2: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        SourceCode: Record "Source Code";
        DimMgt: Codeunit DimensionManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ErrorMessageMgt: Codeunit "Error Message Management";
        DocNo: Code[20];
        NextEntryNo: Integer;
        ReplacePostingDate: Boolean;
        PostingDate: Date;
        SrcCode: Code[10];
        FinChrgMemoInterestAmount: Decimal;
        FinChrgMemoInterestVATAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];

        Text000: Label 'There is nothing to issue.';
        Text001: Label 'must be positive or 0';
        Text002: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text003: Label 'A dimension in %1 %2 has caused an error. %3';
        MissingJournalFieldErr: Label 'Please enter a %1 when posting Additional Fees or Interest.', Comment = '%1 - field caption';
        VATDateNotAllowedErr: Label '%1 is not within your range of allowed posting dates.', Comment = '%1 - VAT Date field caption';

    procedure Set(var NewFinChrgMemoHeader: Record "Finance Charge Memo Header"; NewReplacePostingDate: Boolean; NewPostingDate: Date)
    begin
        FinChrgMemoHeader := NewFinChrgMemoHeader;
        ReplacePostingDate := NewReplacePostingDate;
        PostingDate := NewPostingDate;
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    procedure GetIssuedFinChrgMemo(var NewIssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        NewIssuedFinChrgMemoHeader := IssuedFinChrgMemoHeader;
    end;

    local procedure InitGenJnlLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; SystemCreatedEntry: Boolean)
    begin
        with FinChrgMemoHeader do begin
            TempGenJnlLine.Init();
            TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
            TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::"Finance Charge Memo";
            TempGenJnlLine."Document No." := DocNo;
            if "Post Additional Fee" or "Post Interest" then begin
                TempGenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
                TempGenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
            end;
            TempGenJnlLine."Posting Date" := "Posting Date";
            TempGenJnlLine."VAT Reporting Date" := "VAT Reporting Date";
            TempGenJnlLine."Document Date" := "Document Date";
            TempGenJnlLine."Account Type" := AccType;
            TempGenJnlLine."Account No." := AccNo;
            TempGenJnlLine.Validate("Account No.");
            if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::"G/L Account" then begin
                TempGenJnlLine."Gen. Posting Type" := TempGenJnlLine."Gen. Posting Type"::Sale;
                TempGenJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
                TempGenJnlLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            end;
            TempGenJnlLine.Validate("Currency Code", "Currency Code");
            if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Customer then begin
                TempGenJnlLine.Validate(Amount, TotalAmount);
                TempGenJnlLine.Validate("Amount (LCY)", TotalAmountLCY);
                TempGenJnlLine."Due Date" := "Due Date";
            end;
            TempGenJnlLine.Description := "Posting Description";
            TempGenJnlLine."Source Type" := TempGenJnlLine."Source Type"::Customer;
            TempGenJnlLine."Source No." := "Customer No.";
            TempGenJnlLine."Source Code" := SrcCode;
            TempGenJnlLine."Reason Code" := "Reason Code";
            TempGenJnlLine."System-Created Entry" := SystemCreatedEntry;
            TempGenJnlLine."Posting No. Series" := "Issuing No. Series";
            TempGenJnlLine."Salespers./Purch. Code" := '';
            OnAfterInitGenJnlLine(TempGenJnlLine, FinChrgMemoHeader, SrcCode);
        end;
    end;

    local procedure CheckNegativeFinChrgMemoLineAmount(FinChrgMemoLine: Record "Finance Charge Memo Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNegativeFinChrgMemoLineAmount(FinChrgMemoHeader, FinChrgMemoLine, FinChrgTerms, IsHandled);
        if IsHandled then
            exit;
        if FinChrgMemoLine.Amount < 0 then
            FinChrgMemoLine.FieldError(Amount, Text001);
    end;

    procedure DeleteIssuedFinChrgLines(IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChrgMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChrgMemoHeader."No.");
        IssuedFinChrgMemoLine.DeleteAll();
    end;

    procedure IncrNoPrinted(var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        with IssuedFinChrgMemoHeader do begin
            Find();
            "No. Printed" := "No. Printed" + 1;
            OnIncrNoPrintedOnBeforeModify(IssuedFinChrgMemoHeader);
            Modify();
            Commit();
        end;
    end;

    procedure TestDeleteHeader(FinChrgMemoHeader: Record "Finance Charge Memo Header"; var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        with FinChrgMemoHeader do begin
            Clear(IssuedFinChrgMemoHeader);
            SourceCodeSetup.Get();
            SourceCodeSetup.TestField("Deleted Document");
            SourceCode.Get(SourceCodeSetup."Deleted Document");

            if ("Issuing No. Series" <> '') and
               (("Issuing No." <> '') or ("No. Series" = "Issuing No. Series"))
            then begin
                IssuedFinChrgMemoHeader.TransferFields(FinChrgMemoHeader);
                if "Issuing No." <> '' then
                    IssuedFinChrgMemoHeader."No." := "Issuing No.";
                IssuedFinChrgMemoHeader."Pre-Assigned No. Series" := "No. Series";
                IssuedFinChrgMemoHeader."Pre-Assigned No." := "No.";
                IssuedFinChrgMemoHeader."Posting Date" := Today;
                IssuedFinChrgMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(IssuedFinChrgMemoHeader."User ID"));
                IssuedFinChrgMemoHeader."Source Code" := SourceCode.Code;
            end;
        end;

        OnAfterTestDeleteHeader(IssuedFinChrgMemoHeader, FinChrgMemoHeader);
    end;

    procedure DeleteHeader(FinChrgMemoHeader: Record "Finance Charge Memo Header"; var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        with FinChrgMemoHeader do begin
            TestDeleteHeader(FinChrgMemoHeader, IssuedFinChrgMemoHeader);
            if IssuedFinChrgMemoHeader."No." <> '' then begin
                IssuedFinChrgMemoHeader."Shortcut Dimension 1 Code" := '';
                IssuedFinChrgMemoHeader."Shortcut Dimension 2 Code" := '';
                IssuedFinChrgMemoHeader.Insert();
                IssuedFinChrgMemoLine.Init();
                IssuedFinChrgMemoLine."Finance Charge Memo No." := "No.";
                IssuedFinChrgMemoLine."Line No." := 10000;
                IssuedFinChrgMemoLine.Description := SourceCode.Description;
                IssuedFinChrgMemoLine.Insert();
            end;
        end;
    end;

    local procedure InsertIssuedFinChrgMemoHeader(FinChrgMemoHeader: Record "Finance Charge Memo Header"; var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        IssuedFinChrgMemoHeader.Init();
        IssuedFinChrgMemoHeader.TransferFields(FinChrgMemoHeader);
        IssuedFinChrgMemoHeader."No. Series" := FinChrgMemoHeader."Issuing No. Series";
        IssuedFinChrgMemoHeader."No." := DocNo;
        IssuedFinChrgMemoHeader."Pre-Assigned No. Series" := FinChrgMemoHeader."No. Series";
        IssuedFinChrgMemoHeader."Pre-Assigned No." := FinChrgMemoHeader."No.";
        IssuedFinChrgMemoHeader."Source Code" := SrcCode;
        IssuedFinChrgMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(IssuedFinChrgMemoHeader."User ID"));
        OnBeforeIssuedFinChrgMemoHeaderInsert(IssuedFinChrgMemoHeader, FinChrgMemoHeader);
        IssuedFinChrgMemoHeader.Insert();
    end;

    local procedure InsertIssuedFinChrgMemoLine(FinChrgMemoLine: Record "Finance Charge Memo Line"; IssuedDocNo: Code[20])
    var
        IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        IssuedFinChrgMemoLine.Init();
        IssuedFinChrgMemoLine.TransferFields(FinChrgMemoLine);
        IssuedFinChrgMemoLine."Finance Charge Memo No." := IssuedDocNo;
        IssuedFinChrgMemoLine.Insert();
        OnAfterInsertIssuedFinChrgMemoLine(FinChrgMemoLine, IssuedFinChrgMemoLine, CurrencyExchangeRate.ExchangeRate(FinChrgMemoHeader."Posting Date", FinChrgMemoHeader."Currency Code"));
    end;

    local procedure InsertFinChargeEntry(IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header"; FinChrgMemoLine: Record "Finance Charge Memo Line")
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        with ReminderFinChargeEntry do begin
            Init();
            "Entry No." := NextEntryNo;
            Type := Type::"Finance Charge Memo";
            "No." := IssuedFinChrgMemoHeader."No.";
            "Posting Date" := IssuedFinChrgMemoHeader."Posting Date";
            "Due Date" := IssuedFinChrgMemoHeader."Due Date";
            "Document Date" := IssuedFinChrgMemoHeader."Document Date";
            "Customer No." := IssuedFinChrgMemoHeader."Customer No.";
            "Customer Entry No." := FinChrgMemoLine."Entry No.";
            "Document Type" := FinChrgMemoLine."Document Type";
            "Document No." := FinChrgMemoLine."Document No.";
            "Remaining Amount" := FinChrgMemoLine."Remaining Amount";
            "Interest Amount" := FinChrgMemoLine.Amount;
            "Interest Posted" := (FinChrgMemoInterestAmount <> 0) and FinChrgMemoHeader."Post Interest";
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            OnBeforeInsertFinChargeEntry(ReminderFinChargeEntry, FinChrgMemoHeader, FinChrgMemoLine);
            Insert();
        end;
    end;

    local procedure SetDimensions(var GenJnlLine: Record "Gen. Journal Line"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        DefaultDimension: Record "Default Dimension";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        with GenJnlLine do begin
            "Shortcut Dimension 1 Code" := FinanceChargeMemoHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := FinanceChargeMemoHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := FinanceChargeMemoHeader."Dimension Set ID";
            if "Account Type" = "Account Type"::"G/L Account" then begin
                DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", "Account No.");
                DefaultDimension.SetRange("Table ID", Database::"G/L Account");
                DefaultDimension.SetRange("No.", "Account No.");
                if not DefaultDimension.IsEmpty() then
                    "Dimension Set ID" := DimMgt.GetDefaultDimID(
                        DefaultDimSource, SrcCode, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Dimension Set ID", 0);
            end;
        end;

#if not CLEAN20
        RunEventOnAfterSetDimensions(GenJnlLine, FinanceChargeMemoHeader, DefaultDimSource, SrcCode);
#endif
        OnAfterSetDimensionsProcedure(GenJnlLine, FinanceChargeMemoHeader, DefaultDimSource, SrcCode);
    end;

    local procedure UpdateCustLedgEntriesCalculateInterest(EntryNo: Integer; DocumentDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustLedgEntriesCalculateInterest(EntryNo, DocumentDate, IsHandled);
        if IsHandled then
            exit;

        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.SetFilter("Date Filter", '..%1', DocumentDate);
        CustLedgerEntry.CalcFields("Remaining Amount");
        if CustLedgerEntry."Remaining Amount" = 0 then begin
            CustLedgerEntry."Calculate Interest" := false;
            CustLedgerEntry.Modify();
        end;
        CustLedgerEntry2.SetCurrentKey("Closed by Entry No.");
        CustLedgerEntry2.SetRange("Closed by Entry No.", EntryNo);
        CustLedgerEntry2.SetRange("Closing Interest Calculated", false);
        OnUpdateCustLedgEntriesCalculateInterestOnBeforeCustLedgerEntry2ModifyAll(CustLedgerEntry2, CustLedgerEntry);
        CustLedgerEntry2.ModifyAll("Closing Interest Calculated", true);
    end;

    local procedure CheckVATDate(var FinChrgMemoHeader: Record "Finance Charge Memo Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        SetupRecID: RecordID;
    begin
        // ensure VAT Date is filled in
        If FinChrgMemoHeader."VAT Reporting Date" = 0D then begin
            FinChrgMemoHeader."VAT Reporting Date" := GLSetup.GetVATDate(FinChrgMemoHeader."Posting Date", FinChrgMemoHeader."Document Date");
            FinChrgMemoHeader.Modify();
        end;

        // check whether VAT Date is within allowed VAT Periods
        GenJnlCheckLine.CheckVATDateAllowed(FinChrgMemoHeader."VAT Reporting Date");

        // check whether VAT Date is within Allowed period defined in Gen. Ledger Setup
        if GenJnlCheckLine.IsDateNotAllowed(FinChrgMemoHeader."VAT Reporting Date", SetupRecID, '') then
            ErrorMessageMgt.LogContextFieldError(
              FinChrgMemoHeader.FieldNo("VAT Reporting Date"), StrSubstNo(VATDateNotAllowedErr, FinChrgMemoHeader.FieldCaption("VAT Reporting Date")),
              SetupRecID, ErrorMessageMgt.GetFieldNo(SetupRecID.TableNo, GLSetup.FieldName("Allow Posting From")),
              ForwardLinkMgt.GetHelpCodeForAllowedPostingDate());
    end;

#if not CLEAN20
    local procedure CreateDefaultDimSourcesFromDimArray(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; TableID: array[10] of Integer; No: array[10] of Code[20])
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
    begin
        DimArrayConversionHelper.CreateDefaultDimSourcesFromDimArray(Database::"Finance Charge Memo Header", DefaultDimSource, TableID, No);
    end;

    local procedure CreateDimTableIDs(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
    begin
        DimArrayConversionHelper.CreateDimTableIDs(Database::"Finance Charge Memo Header", DefaultDimSource, TableID, No);
    end;

    local procedure RunEventOnAfterSetDimensions(var GenJnlLine: Record "Gen. Journal Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var SrcCode: Code[10])
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
        TableID2: array[10] of Integer;
        No2: array[10] of Code[20];
    begin
        if not DimArrayConversionHelper.IsSubscriberExist(Database::"Finance Charge Memo Header") then
            exit;

        CreateDimTableIDs(DefaultDimSource, TableID2, No2);
        OnAfterSetDimensions(GenJnlLine, FinanceChargeMemoHeader, TableID2, No2, SrcCode);
        CreateDefaultDimSourcesFromDimArray(DefaultDimSource, TableID2, No2);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; FinChargeMemoHeader: Record "Finance Charge Memo Header"; var SrcCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssueFinChargeMemo(var FinChargeMemoHeader: Record "Finance Charge Memo Header"; IssuedFinChargeMemoNo: Code[20])
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by OnAfterSetDimensionsProcedure()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimensions(var GenJnlLine: Record "Gen. Journal Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var TableID: array[10] of Integer; var No: array[10] of Code[20]; var SrcCode: Code[10])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimensionsProcedure(var GenJnlLine: Record "Gen. Journal Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var SrcCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestDeleteHeader(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFinChargeEntry(var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoLine: Record "Finance Charge Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssueFinChargeMemo(var FinChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedFinChrgMemoHeaderInsert(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlPostLineRunWithCheck(var GenJournalLine: Record "Gen. Journal Line"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustLedgEntriesCalculateInterestOnBeforeCustLedgerEntry2ModifyAll(var CustLedgEntry2: Record "Cust. Ledger Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertIssuedFinChrgMemoLine(FinChrgMemoLine: Record "Finance Charge Memo Line"; var IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line"; CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFinChrgMemoLine(FinChrgMemoLine: Record "Finance Charge Memo Line"; DocNo: Code[20]; CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNegativeFinChrgMemoLineAmount(FinChrgMemoHeader: Record "Finance Charge Memo Header"; FinChrgMemoLine: Record "Finance Charge Memo Line"; FinChrgTerms: Record "Finance Charge Terms"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIncrNoPrintedOnBeforeModify(var IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGLAccountGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGLAccountGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInterestGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInterestGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterTotalGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeTotalGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGenJnlPostLineRunWithCheck(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgEntriesCalculateInterest(EntryNo: Integer; DocumentDate: Date; var IsHandled: Boolean)
    begin
    end;
}

