report 7000084 "Partial Settl.- Receivable"
{
    Caption = 'Partial Settl.- Receivable';
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "G/L Register" = m,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Posted Bill Group" = imd,
                  TableData "Closed Bill Group" = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(PostedDoc; "Posted Cartera Doc.")
        {
            DataItemTableView = SORTING("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date") WHERE(Status = CONST(Open));

            trigger OnAfterGetRecord()
            var
                FromJnl: Boolean;
            begin
                IsRedrawn := CarteraManagement.CheckFromRedrawnDoc("No.");
                if PostedBillGr."No." = '' then begin
                    PostedBillGr.Get("Bill Gr./Pmt. Order No.");
                    BankAcc.Get(PostedBillGr."Bank Account No.");
                    BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                    Delay := BankAcc."Delay for Notices";
                end;

                RemainingAmt2 := "Remaining Amount" - AppliedAmt;

                DocCount := DocCount + 1;
                Window.Update(1, DocCount);

                with GenJnlLine do begin
                    GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                    Clear(GenJnlLine);
                    Init();
                    "Line No." := GenJnlLineNextNo;
                    "Posting Date" := PostingDate;
                    "Document Type" := "Document Type"::Payment;
                    "Document No." := PostedBillGr."No.";
                    "Reason Code" := PostedBillGr."Reason Code";
                    Validate("Account Type", "Account Type"::Customer);
                    CustLedgEntry.Get(PostedDoc."Entry No.");

                    if GLSetup."Unrealized VAT" and (PostedDoc."Document Type" = PostedDoc."Document Type"::Bill) then begin
                        FromJnl := false;
                        if PostedDoc."From Journal" then
                            FromJnl := true;
                        ExistsNoRealVAT := GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl);
                    end;

                    OnBeforeValidateAccountNo(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, FromJnl, ExistsNoRealVAT);
                    Validate("Account No.", CustLedgEntry."Customer No.");
                    if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                        Description := CopyStr(StrSubstNo(Text1100001, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(Description))
                    else
                        Description := CopyStr(StrSubstNo(Text1100002, PostedDoc."Document No."), 1, MaxStrLen(Description));
                    Validate("Currency Code", PostedDoc."Currency Code");
                    Validate(Amount, -AppliedAmt);
                    "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                    "Applies-to Doc. No." := CustLedgEntry."Document No.";
                    "Applies-to Bill No." := CustLedgEntry."Bill No.";
                    "Source Code" := SourceCode;
                    "System-Created Entry" := true;
                    "Dimension Set ID" :=
                      CarteraManagement.GetCombinedDimSetID(GenJnlLine, CustLedgEntry."Dimension Set ID");
                    OnBeforeInsertGenJournalLine(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
                    Insert();
                    SumLCYAmt := SumLCYAmt + "Amount (LCY)";
                end;

                if ("Document Type" = "Document Type"::Bill) and
                   GLSetup."Unrealized VAT" and
                   ExistsNoRealVAT and
                   (not IsRedrawn)
                then begin
                    OnBeforeCustUnrealizedVAT2(PostedDoc, GenJnlLine, CustLedgEntry, PostedBillGr, NoRealVATBuffer);
                    CarteraManagement.CustUnrealizedVAT2(
                      CustLedgEntry,
                      AppliedAmt,
                      GenJnlLine,
                      ExistVATEntry,
                      FirstVATEntryNo,
                      LastVATEntryNo,
                      NoRealVATBuffer,
                      FromJnl,
                      "Document No.");
                    OnAfterCustUnrealizedVAT2(PostedDoc, GenJnlLine, CustLedgEntry, PostedBillGr, NoRealVATBuffer);

                    if NoRealVATBuffer.Find('-') then
                        repeat
                        begin
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"G/L Account",
                              NoRealVATBuffer.Account,
                              -NoRealVATBuffer.Amount);
                            InsertGenJournalLine(
                              GenJnlLine."Account Type"::"G/L Account",
                              NoRealVATBuffer."Balance Account",
                              NoRealVATBuffer.Amount);
                        end;
                        until NoRealVATBuffer.Next() = 0;
                end;

                if AppliedAmt = RemainingAmt then begin
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Honored;
                    CustLedgEntry.Modify();
                    RemainingAmt2 := 0;
                end;

                if (PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount) and
                   (PostedBillGr.Factoring <> PostedBillGr.Factoring::" ")
                then
                    RiskDiscFactLiabs(PostedDoc);

                DimSetID := "Dimension Set ID";

                OnAfterPostedDocDataItem(PostedDoc);
            end;

            trigger OnPostDataItem()
            begin
                if DocCount = 0 then
                    Error(
                      Text1100003 +
                      Text1100004);

                if PostedBillGr.Factoring = PostedBillGr.Factoring::" " then begin
                    if "Dealing Type" = "Dealing Type"::Discount then begin
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        with GenJnlLine do begin
                            Clear(GenJnlLine);
                            Init();
                            "Line No." := GenJnlLineNextNo;
                            "Posting Date" := PostingDate;
                            "Document Type" := "Document Type"::Payment;
                            "Document No." := PostedBillGr."No.";
                            "Reason Code" := PostedBillGr."Reason Code";
                            BankAcc.TestField("Bank Acc. Posting Group");
                            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                            Validate("Account Type", "Account Type"::"G/L Account");
                            BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
                            Validate("Account No.", BankAccPostingGr."Liabs. for Disc. Bills Acc.");
                            if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                                Description := CopyStr(StrSubstNo(Text1100001, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(Description))
                            else
                                Description := CopyStr(StrSubstNo(Text1100002, PostedDoc."Document No."), 1, MaxStrLen(Description));
                            Validate("Currency Code", PostedBillGr."Currency Code");
                            Validate(Amount, AppliedAmt);
                            "Source Code" := SourceCode;
                            "System-Created Entry" := true;
                            "Dimension Set ID" :=
                              CarteraManagement.GetCombinedDimSetID(GenJnlLine, DimSetID);
                            OnBeforeInsertGenJournalLine(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
                            Insert();
                            SumLCYAmt := SumLCYAmt + "Amount (LCY)";
                        end;
                    end else
                        BankAmtBuffer := BankAmtBuffer + AppliedAmt;
                end else
                    FactBankAccounting();

                if BankAmtBuffer <> 0 then
                    BankAccounting(BankAmtBuffer);

                if PostedBillGr."Currency Code" <> '' then begin
                    if SumLCYAmt <> 0 then begin
                        Currency.SetFilter(Code, PostedBillGr."Currency Code");
                        Currency.FindFirst();
                        if SumLCYAmt > 0 then begin
                            Currency.TestField("Residual Gains Account");
                            Acct := Currency."Residual Gains Account";
                        end else begin
                            Currency.TestField("Residual Losses Account");
                            Acct := Currency."Residual Losses Account";
                        end;
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        with GenJnlLine do begin
                            Clear(GenJnlLine);
                            Init();
                            "Line No." := GenJnlLineNextNo;
                            "Posting Date" := PostingDate;
                            "Document Type" := "Document Type"::Payment;
                            "Document No." := PostedBillGr."No.";
                            "Reason Code" := PostedBillGr."Reason Code";
                            Validate("Account Type", "Account Type"::"G/L Account");
                            Validate("Account No.", Acct);
                            Description := Text1100005;
                            Validate("Currency Code", '');
                            Validate(Amount, -SumLCYAmt);
                            "Source Code" := SourceCode;
                            "System-Created Entry" := true;
                            "Dimension Set ID" :=
                              CarteraManagement.GetCombinedDimSetID(GenJnlLine, CustLedgEntry."Dimension Set ID");
                            OnBeforeInsertGenJournalLine(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
                            Insert();
                        end;
                    end;
                end;

                DocPost.PostSettlement(GenJnlLine);

                CustLedgEntry.Get("Entry No.");
                Get(Type, "Entry No.");
                "Honored/Rejtd. at Date" := PostingDate;
                "Remaining Amount" := RemainingAmt2;
                "Remaining Amt. (LCY)" := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                      CustLedgEntry."Posting Date",
                      CustLedgEntry."Currency Code",
                      RemainingAmt2,
                      CurrExchRate.ExchangeRate(CustLedgEntry."Posting Date", CustLedgEntry."Currency Code")),
                    GLSetup."Amount Rounding Precision");
                if RemainingAmt2 = 0 then begin
                    "Remaining Amt. (LCY)" := 0;
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Honored;
                    Status := Status::Honored;
                    CustLedgEntry.Open := false;
                end else begin
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Open;
                    Status := Status::Open;
                    CustLedgEntry.Open := true;
                end;
                OnBeforeModifyPostedDoc(PostedDoc, GenJnlLine, CustLedgEntry, PostedBillGr);
                CustLedgEntry.Modify();
                Modify();
                PostedBillGr.Modify();

                DocPost.CloseBillGroupIfEmpty(PostedBillGr, PostingDate);

                Window.Close();

                if ExistVATEntry then begin
                    GLReg.FindLast();
                    GLReg."From VAT Entry No." := FirstVATEntryNo;
                    GLReg."To VAT Entry No." := LastVATEntryNo;
                    GLReg.Modify();
                end;

                OnAfterPostedDocOnPostDataItem(PostedDoc, GenJnlLine, CustLedgEntry, PostedBillGr);

                Commit();
                Message(
                  Text1100006,
                  DocCount, RemainingAmt, PostedBillGr."No.", AppliedAmt);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(PostingDate);

                SourceCodeSetup.Get();
                SourceCode := SourceCodeSetup."Cartera Journal";
                DocCount := 0;
                TotalDisctdAmt := 0;
                BankAmtBuffer := 0;
                SumLCYAmt := 0;
                GenJnlLineNextNo := 0;
                ExistVATEntry := false;
                Window.Open(
                  Text1100000);
            end;
        }
    }

    requestpage
    {
        SaveValues = false;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the posting date.';

                        trigger OnValidate()
                        var
                            CustLedgEntry2: Record "Cust. Ledger Entry";
                        begin
                            CustLedgEntry2.Get(CustLedgEntryNo);
                            if CustLedgEntry2."Document Type" = CustLedgEntry2."Document Type"::Invoice then begin
                                CustLedgEntry2.CalcFields("Remaining Amount");
                                if PostingDate > CustLedgEntry2."Pmt. Discount Date" then
                                    RemainingAmt := CustLedgEntry2."Remaining Amount"
                                else
                                    RemainingAmt := CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible";
                                AppliedAmt := RemainingAmt;
                            end;
                        end;
                    }
                    field(RemainingAmount; RemainingAmt)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                        Caption = 'Remaining Amount';
                        Editable = false;
                        ToolTip = 'Specifies the pending, unpaid amount.';
                    }
                    field(CurrencyCode; CurrencyCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Currency Code';
                        Editable = false;
                        TableRelation = Currency;
                        ToolTip = 'Specifies the currency of the amounts.';
                    }
                    field(SettledAmount; AppliedAmt)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                        Caption = 'Settled Amount';
                        Editable = true;
                        MinValue = 0;
                        NotBlank = true;
                        ToolTip = 'Specifies the amount that you wish to apply to the total amount due.';

                        trigger OnValidate()
                        begin
                            if AppliedAmt > RemainingAmt then
                                Error(Text1100007, RemainingAmt);
                        end;
                    }
                }
            }
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
        PostingDate := WorkDate();
        RemainingAmt := 0;
        AppliedAmt := 0;
        CurrencyCode := '';
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    var
        Text1100000: Label ' Partially settling receivable documents      #1######';
        Text1100001: Label 'Partial Bill settlement %1/%2';
        Text1100002: Label 'Partial Document settlement %1';
        Text1100003: Label 'No receivable documents have been found that can be settled. \';
        Text1100004: Label 'Please check that the selection is not empty and at least one receivable document is open.';
        Text1100005: Label 'Residual adjust generated by rounding Amount';
        Text1100006: Label '%1 receivable documents totaling %2 have been partially settled in Bill Group %3 by an amount of %4.';
        Text1100007: Label 'The maximum permitted value is %1';
        Text1100008: Label 'Partial Document settlement %1 Customer No. %2';
        Text1100009: Label 'Partial receivable document settlement %1/%2';
        Text1100010: Label 'Partial receivable document settlement %1';
        SourceCodeSetup: Record "Source Code Setup";
        PostedBillGr: Record "Posted Bill Group";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        GLReg: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        NoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        PostingDate: Date;
        Delay: Decimal;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        GenJnlLineNextNo: Integer;
        TotalDisctdAmt: Decimal;
        RemainingAmt: Decimal;
        CurrencyCode: Code[10];
        AppliedAmt: Decimal;
        RemainingAmt2: Decimal;
        BankAmtBuffer: Decimal;
        SumLCYAmt: Decimal;
        ExistVATEntry: Boolean;
        FirstVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        IsRedrawn: Boolean;
        DimSetID: Integer;
        ExistsNoRealVAT: Boolean;
        CustLedgEntryNo: Integer;

    local procedure RiskDiscFactLiabs(PostedDoc2: Record "Posted Cartera Doc.")
    var
        Currency2: Record Currency;
        DisctedAmt: Decimal;
        RoundingPrec: Decimal;
    begin
        DisctedAmt := 0;
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        if PostedDoc2."Currency Code" <> '' then begin
            Currency2.Get(PostedDoc2."Currency Code");
            RoundingPrec := Currency2."Amount Rounding Precision";
        end else
            RoundingPrec := GLSetup."Amount Rounding Precision";

        DisctedAmt := Round(DocPost.FindDisctdAmt(
              AppliedAmt,
              PostedDoc2."Account No.",
              PostedDoc2."Bank Account No."), RoundingPrec);

        TotalDisctdAmt := TotalDisctdAmt + DisctedAmt;

        with GenJnlLine do begin
            Clear(GenJnlLine);
            Init();
            "Line No." := GenJnlLineNextNo;
            "Posting Date" := PostingDate;
            "Document Type" := "Document Type"::Payment;
            "Document No." := PostedBillGr."No.";
            "Reason Code" := PostedBillGr."Reason Code";
            BankAcc.TestField("Bank Acc. Posting Group");
            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
            Validate("Account Type", "Account Type"::"G/L Account");
            BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
            Validate("Account No.", BankAccPostingGr."Liabs. for Factoring Acc.");
            Description := CopyStr(StrSubstNo(Text1100008, PostedDoc2."Document No.", PostedDoc2."Account No."), 1, MaxStrLen(Description));
            Validate("Currency Code", PostedBillGr."Currency Code");
            Validate(Amount, DisctedAmt);
            "Source Code" := SourceCode;
            "System-Created Entry" := true;
            "Dimension Set ID" :=
              CarteraManagement.GetCombinedDimSetID(GenJnlLine, PostedDoc2."Dimension Set ID");
            OnBeforeInsertGenJournalLine(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
            Insert();
            SumLCYAmt := SumLCYAmt + "Amount (LCY)";
        end;
    end;

    local procedure FactBankAccounting()
    begin
        if PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount then
            BankAmtBuffer := BankAmtBuffer + (AppliedAmt - TotalDisctdAmt)
        else
            BankAmtBuffer := BankAmtBuffer + AppliedAmt;
    end;

    [Scope('OnPrem')]
    procedure SetInitValue(Amount: Decimal; CurrCode: Code[10]; EntryNo: Integer)
    begin
        CurrencyCode := CurrCode;
        RemainingAmt := Amount;
        AppliedAmt := RemainingAmt;
        CustLedgEntryNo := EntryNo;
    end;

    local procedure BankAccounting(BankAmt: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
        with GenJnlLine do begin
            Clear(GenJnlLine);
            Init();
            "Line No." := GenJnlLineNextNo;
            "Posting Date" := PostingDate;
            "Document Type" := "Document Type"::Payment;
            "Document No." := PostedBillGr."No.";
            "Reason Code" := PostedBillGr."Reason Code";
            BankAcc.TestField("Bank Acc. Posting Group");
            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
            Validate("Account Type", "Account Type"::"Bank Account");
            Validate("Account No.", BankAcc."No.");
            if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                Description := CopyStr(StrSubstNo(
                      Text1100001, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(Description))
            else
                Description := CopyStr(StrSubstNo(
                      Text1100002, PostedDoc."Document No."), 1, MaxStrLen(Description));
            Validate("Currency Code", PostedBillGr."Currency Code");
            Validate(Amount, BankAmt);
            "Source Code" := SourceCode;
            "System-Created Entry" := true;
            "Dimension Set ID" :=
              CarteraManagement.GetCombinedDimSetID(GenJnlLine, DimSetID);
            OnBeforeInsertGenJournalLine(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
            Insert();
            SumLCYAmt := SumLCYAmt + "Amount (LCY)";
        end;
    end;

    local procedure InsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        with GenJnlLine do begin
            Clear(GenJnlLine);
            Init();
            "Line No." := GenJnlLineNextNo;
            "Posting Date" := PostingDate;
            "Document No." := PostedBillGr."No.";
            "Reason Code" := PostedBillGr."Reason Code";
            "Account Type" := AccType;
            Validate("Account No.", AccNo);
            if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then
                Description := CopyStr(StrSubstNo(Text1100009, PostedDoc."Document No.", PostedDoc."No."), 1, MaxStrLen(Description))
            else
                Description := CopyStr(StrSubstNo(Text1100010, PostedDoc."Document No."), 1, MaxStrLen(Description));
            Validate("Currency Code", PostedDoc."Currency Code");
            Validate(Amount, Amount2);
            "Applies-to Doc. Type" := CustLedgEntry."Document Type";
            "Applies-to Doc. No." := '';
            "Applies-to Bill No." := CustLedgEntry."Bill No.";
            "Source Code" := SourceCode;
            "System-Created Entry" := true;
            "Dimension Set ID" :=
              CarteraManagement.GetCombinedDimSetID(GenJnlLine, CustLedgEntry."Dimension Set ID");
            OnBeforeInsertGenJournalLine(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, PostedBillGr);
            Insert();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedDocDataItem(var PostedCarteraDoc: Record "Posted Cartera Doc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedDocOnPostDataItem(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJournalLine(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPostedDoc(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAccountNo(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var FromJnl: Boolean; var ExistsNoRealVAT: Boolean)
    begin
    end;
}

