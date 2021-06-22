codeunit 395 "FinChrgMemo-Issue"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rimd,
                  TableData "Issued Fin. Charge Memo Header" = rimd,
                  TableData "Issued Fin. Charge Memo Line" = rimd;

    trigger OnRun()
    var
        CustPostingGr: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        FinChrgMemoLine: Record "Finance Charge Memo Line";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
    begin
        OnBeforeIssueFinChargeMemo(FinChrgMemoHeader);

        with FinChrgMemoHeader do begin
            UpdateFinanceChargeRounding(FinChrgMemoHeader);
            if (PostingDate <> 0D) and (ReplacePostingDate or ("Posting Date" = 0D)) then
                Validate("Posting Date", PostingDate);
            TestField("Customer No.");
            TestField("Posting Date");
            TestField("Document Date");
            TestField("Due Date");
            TestField("Customer Posting Group");
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                Error(
                  Text002,
                  TableCaption, "No.", DimMgt.GetDimCombErr);

            TableID[1] := DATABASE::Customer;
            No[1] := "Customer No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                Error(
                  Text003,
                  TableCaption, "No.", DimMgt.GetDimValuePostingErr);

            CustPostingGr.Get("Customer Posting Group");
            CalcFields("Interest Amount", "Additional Fee", "Remaining Amount");
            if ("Interest Amount" = 0) and ("Additional Fee" = 0) and ("Remaining Amount" = 0) then
                Error(Text000);
            SourceCodeSetup.Get();
            SourceCodeSetup.TestField("Finance Charge Memo");
            SrcCode := SourceCodeSetup."Finance Charge Memo";

            if ("Issuing No." = '') and ("No. Series" <> "Issuing No. Series") then begin
                TestField("Issuing No. Series");
                "Issuing No." := NoSeriesMgt.GetNextNo("Issuing No. Series", "Posting Date", true);
                Modify;
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
                            if (FinChrgMemoLine.Amount <> 0) and "Post Additional Fee" then begin
                                FinChrgMemoLine.TestField("No.");
                                InitGenJnlLine(GenJnlLine."Account Type"::"G/L Account",
                                  FinChrgMemoLine."No.",
                                  FinChrgMemoLine."Line Type" = FinChrgMemoLine."Line Type"::Rounding);
                                GenJnlLine."Gen. Prod. Posting Group" := FinChrgMemoLine."Gen. Prod. Posting Group";
                                GenJnlLine."VAT Prod. Posting Group" := FinChrgMemoLine."VAT Prod. Posting Group";
                                GenJnlLine."VAT Calculation Type" := FinChrgMemoLine."VAT Calculation Type";
                                if FinChrgMemoLine."VAT Calculation Type" =
                                   FinChrgMemoLine."VAT Calculation Type"::"Sales Tax"
                                then begin
                                    GenJnlLine."Tax Area Code" := "Tax Area Code";
                                    GenJnlLine."Tax Liable" := "Tax Liable";
                                    GenJnlLine."Tax Group Code" := FinChrgMemoLine."Tax Group Code";
                                end;
                                GenJnlLine."VAT %" := FinChrgMemoLine."VAT %";
                                GenJnlLine.Validate(Amount, -FinChrgMemoLine.Amount - FinChrgMemoLine."VAT Amount");
                                GenJnlLine."VAT Amount" := -FinChrgMemoLine."VAT Amount";
                                GenJnlLine.UpdateLineBalance;
                                TotalAmount := TotalAmount - GenJnlLine.Amount;
                                TotalAmountLCY := TotalAmountLCY - GenJnlLine."Balance (LCY)";
                                GenJnlLine."Bill-to/Pay-to No." := "Customer No.";
                                GenJnlLine.Insert();
                            end;
                        FinChrgMemoLine.Type::"Customer Ledger Entry":
                            begin
                                FinChrgMemoLine.TestField("Entry No.");
                                CustLedgEntry.Get(FinChrgMemoLine."Entry No.");
                                CustLedgEntry.TestField("Currency Code", "Currency Code");
                                if FinChrgMemoLine.Amount < 0 then
                                    FinChrgMemoLine.FieldError(Amount, Text001);
                                FinChrgMemoInterestAmount := FinChrgMemoInterestAmount + FinChrgMemoLine.Amount;
                                FinChrgMemoInterestVATAmount := FinChrgMemoInterestVATAmount + FinChrgMemoLine."VAT Amount";
                            end;
                    end;
                until FinChrgMemoLine.Next = 0;

            if (FinChrgMemoInterestAmount <> 0) and "Post Interest" then begin
                InitGenJnlLine(GenJnlLine."Account Type"::"G/L Account", CustPostingGr.GetInterestAccount, true);
                GenJnlLine.Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                GenJnlLine.Validate(Amount, -FinChrgMemoInterestAmount - FinChrgMemoInterestVATAmount);
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
            if GenJnlLine.Find('-') then
                repeat
                    GenJnlLine2 := GenJnlLine;
                    SetDimensions(GenJnlLine2, FinChrgMemoHeader);
                    GenJnlPostLine.RunWithCheck(GenJnlLine2);
                until GenJnlLine.Next = 0;

            GenJnlLine.DeleteAll();

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
                        until FinChrgMemoLine.Next = 0;
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
            if FinChrgMemoLine.FindSet then
                repeat
                    if (FinChrgMemoLine.Type = FinChrgMemoLine.Type::"Customer Ledger Entry") and
                       not FinChrgMemoLine."Detailed Interest Rates Entry"
                    then begin
                        InsertFinChargeEntry(IssuedFinChrgMemoHeader, FinChrgMemoLine);
                        NextEntryNo := NextEntryNo + 1;
                    end;
                    InsertIssuedFinChrgMemoLine(FinChrgMemoLine, IssuedFinChrgMemoHeader."No.");
                until FinChrgMemoLine.Next = 0;

            FinChrgMemoLine.DeleteAll();
            Delete;
        end;

        OnAfterIssueFinChargeMemo(FinChrgMemoHeader, IssuedFinChrgMemoHeader."No.");
    end;

    var
        Text000: Label 'There is nothing to issue.';
        Text001: Label 'must be positive or 0';
        Text002: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text003: Label 'A dimension in %1 %2 has caused an error. %3';
        SourceCodeSetup: Record "Source Code Setup";
        FinChrgTerms: Record "Finance Charge Terms";
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
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
        FinChrgMemoInterestAmount: Decimal;
        FinChrgMemoInterestVATAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];

    procedure Set(var NewFinChrgMemoHeader: Record "Finance Charge Memo Header"; NewReplacePostingDate: Boolean; NewPostingDate: Date)
    begin
        FinChrgMemoHeader := NewFinChrgMemoHeader;
        ReplacePostingDate := NewReplacePostingDate;
        PostingDate := NewPostingDate;
    end;

    procedure GetIssuedFinChrgMemo(var NewIssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        NewIssuedFinChrgMemoHeader := IssuedFinChrgMemoHeader;
    end;

    local procedure InitGenJnlLine(AccType: Integer; AccNo: Code[20]; SystemCreatedEntry: Boolean)
    begin
        with FinChrgMemoHeader do begin
            GenJnlLine.Init();
            GenJnlLine."Line No." := GenJnlLine."Line No." + 1;
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::"Finance Charge Memo";
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
            OnAfterInitGenJnlLine(GenJnlLine, FinChrgMemoHeader);
        end;
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
            Find;
            "No. Printed" := "No. Printed" + 1;
            Modify;
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
                IssuedFinChrgMemoHeader."User ID" := UserId;
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
        IssuedFinChrgMemoHeader."User ID" := UserId;
        OnBeforeIssuedFinChrgMemoHeaderInsert(IssuedFinChrgMemoHeader, FinChrgMemoHeader);
        IssuedFinChrgMemoHeader.Insert();
    end;

    local procedure InsertIssuedFinChrgMemoLine(FinChrgMemoLine: Record "Finance Charge Memo Line"; IssuedDocNo: Code[20])
    var
        IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChrgMemoLine.Init();
        IssuedFinChrgMemoLine.TransferFields(FinChrgMemoLine);
        IssuedFinChrgMemoLine."Finance Charge Memo No." := IssuedDocNo;
        IssuedFinChrgMemoLine.Insert();
    end;

    local procedure InsertFinChargeEntry(IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header"; FinChrgMemoLine: Record "Finance Charge Memo Line")
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        with ReminderFinChargeEntry do begin
            Init;
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
            "User ID" := UserId;
            Insert;
        end;
    end;

    local procedure SetDimensions(var GenJnlLine: Record "Gen. Journal Line"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        with GenJnlLine do begin
            "Shortcut Dimension 1 Code" := FinanceChargeMemoHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := FinanceChargeMemoHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := FinanceChargeMemoHeader."Dimension Set ID";
            if "Account Type" = "Account Type"::"G/L Account" then begin
                TableID[1] := DATABASE::"G/L Account";
                No[1] := "Account No.";
                DefaultDimension.SetRange("Table ID", TableID[1]);
                DefaultDimension.SetRange("No.", No[1]);
                if not DefaultDimension.IsEmpty then
                    "Dimension Set ID" := DimMgt.GetDefaultDimID(
                        TableID, No, SrcCode, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Dimension Set ID", 0);
            end;
        end;
    end;

    local procedure UpdateCustLedgEntriesCalculateInterest(EntryNo: Integer; DocumentDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
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
        CustLedgerEntry2.ModifyAll("Closing Interest Calculated", true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; FinChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssueFinChargeMemo(var FinChargeMemoHeader: Record "Finance Charge Memo Header"; IssuedFinChargeMemoNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestDeleteHeader(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
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
}

