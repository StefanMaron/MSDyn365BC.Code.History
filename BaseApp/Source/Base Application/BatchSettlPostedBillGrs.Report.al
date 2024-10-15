report 7000086 "Batch Settl. Posted Bill Grs."
{
    Caption = 'Batch Settl. Posted Bill Grs.';
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
        dataitem(PostedBillGr; "Posted Bill Group")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);
            dataitem(PostedDoc; "Posted Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = FIELD("No.");
                DataItemTableView = SORTING("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date") WHERE(Status = CONST(Open), Type = CONST(Receivable));

                trigger OnAfterGetRecord()
                var
                    FromJnl: Boolean;
                begin
                    IsRedrawn := CarteraManagement.CheckFromRedrawnDoc("No.");
                    BankAcc.Get(PostedBillGr."Bank Account No.");
                    Delay := BankAcc."Delay for Notices";

                    if DueOnly and (PostingDate < "Due Date" + Delay) then
                        CurrReport.Skip;

                    TotalDocCount := TotalDocCount + 1;
                    DocCount := DocCount + 1;
                    Window.Update(3, Round(DocCount / TotalDoc * 10000, 1));
                    Window.Update(4, StrSubstNo('%1 %2', "Document Type", "Document No."));

                    with GenJnlLine do begin
                        GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                        Clear(GenJnlLine);
                        Init;
                        "Line No." := GenJnlLineNextNo;
                        "Posting Date" := PostingDate;
                        "Document Type" := "Document Type"::Payment;
                        "Document No." := PostedBillGr."No.";
                        Validate("Account Type", "Account Type"::Customer);
                        CustLedgEntry.Get(PostedDoc."Entry No.");
                        if PostedDoc."Document Type" = PostedDoc."Document Type"::Bill then begin
                            Description := CopyStr(
                                StrSubstNo(Text1100004, PostedDoc."Document No.", PostedDoc."No."),
                                1, MaxStrLen(Description));
                            if GLSetup."Unrealized VAT" then begin
                                FromJnl := false;
                                if PostedDoc."From Journal" then
                                    FromJnl := true;
                                ExistsNoRealVAT := GenJnlPostLine.CustFindVATSetup(VATPostingSetup, CustLedgEntry, FromJnl);
                            end;
                        end else
                            Description := CopyStr(
                                StrSubstNo(Text1100005, PostedDoc."Document No."),
                                1, MaxStrLen(Description));
                        Validate("Account No.", CustLedgEntry."Customer No.");
                        Validate("Currency Code", PostedDoc."Currency Code");
                        Validate(Amount, -PostedDoc."Remaining Amount");
                        "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                        "Applies-to Doc. No." := CustLedgEntry."Document No.";
                        "Applies-to Bill No." := CustLedgEntry."Bill No.";
                        "Source Code" := SourceCode;
                        "System-Created Entry" := true;
                        "Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                        "Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                        "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                        OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
                        Insert;
                        SumLCYAmt := SumLCYAmt + "Amount (LCY)";
                    end;

                    if ("Document Type" = "Document Type"::Bill) and
                       GLSetup."Unrealized VAT" and
                       ExistVATEntry and
                       (not IsRedrawn)
                    then begin
                        CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                        OnBeforeCustUnrealizedVAT2(PostedDoc, GenJnlLine, CustLedgEntry, PostedBillGr, NoRealVATBuffer);
                        CarteraManagement.CustUnrealizedVAT2(
                          CustLedgEntry,
                          CustLedgEntry."Remaining Amt. (LCY)",
                          GenJnlLine,
                          ExistVATEntry,
                          FirstVATEntryNo,
                          LastVATEntryNo,
                          NoRealVATBuffer,
                          FromJnl,
                          "Document No.");
                        OnAfterCustUnrealizedVAT2(PostedDoc, GenJnlLine, CustLedgEntry, PostedBillGr, NoRealVATBuffer);

                        if NoRealVATBuffer.Find('-') then begin
                            repeat
                            begin
                                InsertGenJournalLine(
                                  GenJnlLine."Account Type"::"G/L Account",
                                  NoRealVATBuffer.Account,
                                  NoRealVATBuffer.Amount);
                                InsertGenJournalLine(
                                  GenJnlLine."Account Type"::"G/L Account",
                                  NoRealVATBuffer."Balance Account",
                                  -NoRealVATBuffer.Amount);
                            end;
                            until NoRealVATBuffer.Next = 0;
                            NoRealVATBuffer.DeleteAll;
                        end;
                    end;

                    GroupAmount := GroupAmount + "Remaining Amount";
                    GroupAmountLCY := GroupAmountLCY + "Remaining Amt. (LCY)";
                    CustLedgEntry."Document Status" := CustLedgEntry."Document Status"::Honored;
                    CustLedgEntry.Modify;

                    if BGPOPostBuffer.Get('', '', CustLedgEntry."Entry No.") then begin
                        BGPOPostBuffer.Amount := BGPOPostBuffer.Amount + "Remaining Amount";
                        BGPOPostBuffer.Modify;
                    end else begin
                        BGPOPostBuffer.Init;
                        BGPOPostBuffer."Entry No." := CustLedgEntry."Entry No.";
                        BGPOPostBuffer.Amount := BGPOPostBuffer.Amount + "Remaining Amount";
                        BGPOPostBuffer.Insert;
                    end;

                    if (PostedBillGr."Dealing Type" = PostedBillGr."Dealing Type"::Discount) and
                       (PostedBillGr.Factoring <> PostedBillGr.Factoring::" ")
                    then
                        DiscFactLiabs(PostedDoc);
                end;

                trigger OnPostDataItem()
                var
                    CustLedgEntry2: Record "Cust. Ledger Entry";
                begin
                    if (DocCount = 0) or (GroupAmount = 0) then
                        CurrReport.Skip;

                    if PostedBillGr.Factoring = PostedBillGr.Factoring::" " then begin
                        with GenJnlLine do begin
                            CustLedgEntry2.Get(BGPOPostBuffer."Entry No.");
                            Clear(GenJnlLine);
                            Init;
                            GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                            "Line No." := GenJnlLineNextNo;
                            "Posting Date" := PostingDate;
                            "Document Type" := "Document Type"::Payment;
                            "Document No." := PostedBillGr."No.";
                            if "Dealing Type" = "Dealing Type"::Discount then begin
                                BankAcc.TestField("Bank Acc. Posting Group");
                                BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                                Validate("Account Type", "Account Type"::"G/L Account");
                                BankAccPostingGr.TestField("Liabs. for Disc. Bills Acc.");
                                Validate("Account No.", BankAccPostingGr."Liabs. for Disc. Bills Acc.");
                            end else begin
                                Validate("Account Type", "Account Type"::"Bank Account");
                                Validate("Account No.", BankAcc."No.");
                            end;
                            Description := CopyStr(StrSubstNo(Text1100009, PostedBillGr."No."), 1, MaxStrLen(Description));
                            Validate("Currency Code", PostedBillGr."Currency Code");
                            Validate(Amount, GroupAmount);
                            "Source Code" := SourceCode;
                            "System-Created Entry" := true;
                            "Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                            "Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                            "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                            OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                            Insert;
                            SumLCYAmt := SumLCYAmt + "Amount (LCY)";
                        end;
                    end else
                        FactBankAccounting;

                    if PostedBillGr."Currency Code" <> '' then begin
                        if SumLCYAmt <> 0 then begin
                            Currency.SetFilter(Code, PostedBillGr."Currency Code");
                            Currency.FindFirst;
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
                                Init;
                                "Line No." := GenJnlLineNextNo;
                                "Posting Date" := PostingDate;
                                "Document Type" := "Document Type"::Payment;
                                "Document No." := PostedBillGr."No.";
                                Validate("Account Type", "Account Type"::"G/L Account");
                                Validate("Account No.", Acct);
                                Description := Text1100010;
                                Validate("Currency Code", '');
                                Validate(Amount, -SumLCYAmt);
                                "Source Code" := SourceCode;
                                "System-Created Entry" := true;
                                Validate("Shortcut Dimension 1 Code", BankAcc."Global Dimension 1 Code");
                                Validate("Shortcut Dimension 2 Code", BankAcc."Global Dimension 2 Code");
                                OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                                Insert;
                            end;
                        end;
                    end;
                    DocPost.PostSettlement(GenJnlLine);
                    GenJnlLine.DeleteAll;

                    DocPost.CloseBillGroupIfEmpty(PostedBillGr, PostingDate);

                    if ExistVATEntry then begin
                        GLReg.FindLast;
                        GLReg."From VAT Entry No." := FirstVATEntryNo;
                        GLReg."To VAT Entry No." := LastVATEntryNo;
                        GLReg.Modify;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SumLCYAmt := 0;
                    GenJnlLineNextNo := 0;
                    TotalDoc := Count;
                    ExistVATEntry := false;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                BillGrCount := BillGrCount + 1;
                Window.Update(1, Round(BillGrCount / TotalBillGr * 10000, 1));
                Window.Update(2, StrSubstNo('%1', "No."));
                Window.Update(3, 0);
                GroupAmount := 0;

                TotalDisctdAmt := 0;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;

                Commit;

                Message(
                  Text1100003,
                  TotalDocCount, BillGrCount, GroupAmountLCY);
            end;

            trigger OnPreDataItem()
            begin
                DocPost.CheckPostingDate(PostingDate);

                SourceCodeSetup.Get;
                SourceCode := SourceCodeSetup."Cartera Journal";

                GroupAmountLCY := 0;
                BillGrCount := 0;
                DocCount := 0;
                TotalDocCount := 0;
                TotalBillGr := Count;
                Window.Open(
                  Text1100000 +
                  Text1100001 +
                  Text1100002);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
                    }
                    field(DueOnly; DueOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due bills only';
                        ToolTip = 'Specifies if you want to only include documents that have become overdue. If it does not matter if a document is overdue at the time of settlement, leave this field blank.';
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
        PostingDate := WorkDate;
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get;
    end;

    var
        Text1100000: Label 'Settling           @1@@@@@@@@@@@@@@@@@@@@@@@\\';
        Text1100001: Label 'Bill Groups        #2######  @3@@@@@@@@@@@@@\';
        Text1100002: Label 'Receiv. Documents  #4######';
        Text1100003: Label '%1 Documents in %2 Bill Groups totaling %3 (LCY) have been settled.';
        Text1100004: Label 'Receivable bill settlement %1/%2';
        Text1100005: Label 'Receivable document settlement %1';
        Text1100009: Label 'Bill Group settlement %1';
        Text1100010: Label 'Residual adjust generated by rounding Amount';
        Text1100011: Label 'Bill Group settlement %1 Customer No. %2';
        Text1100012: Label 'Receivable document settlement %1/%2';
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        GLReg: Record "G/L Register";
        VATPostingSetup: Record "VAT Posting Setup";
        DocPost: Codeunit "Document-Post";
        CarteraManagement: Codeunit CarteraManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        PostingDate: Date;
        DueOnly: Boolean;
        Delay: Decimal;
        SourceCode: Code[10];
        Acct: Code[20];
        DocCount: Integer;
        TotalDocCount: Integer;
        GroupAmount: Decimal;
        GroupAmountLCY: Decimal;
        GenJnlLineNextNo: Integer;
        SumLCYAmt: Decimal;
        TotalDisctdAmt: Decimal;
        BillGrCount: Integer;
        TotalBillGr: Integer;
        TotalDoc: Integer;
        ExistVATEntry: Boolean;
        LastVATEntryNo: Integer;
        FirstVATEntryNo: Integer;
        IsRedrawn: Boolean;
        BGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        NoRealVATBuffer: Record "BG/PO Post. Buffer" temporary;
        ExistsNoRealVAT: Boolean;

    [Scope('OnPrem')]
    procedure DiscFactLiabs(PostedDoc2: Record "Posted Cartera Doc.")
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
              PostedDoc2."Remaining Amount",
              PostedDoc2."Account No.",
              PostedDoc2."Bank Account No."), RoundingPrec);

        TotalDisctdAmt := TotalDisctdAmt + DisctedAmt;

        with GenJnlLine do begin
            Clear(GenJnlLine);
            Init;
            "Line No." := GenJnlLineNextNo;
            "Posting Date" := PostingDate;
            "Document Type" := "Document Type"::Payment;
            "Document No." := PostedBillGr."No.";
            BankAcc.TestField("Bank Acc. Posting Group");
            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
            Validate("Account Type", "Account Type"::"G/L Account");
            BankAccPostingGr.TestField("Liabs. for Factoring Acc.");
            Validate("Account No.", BankAccPostingGr."Liabs. for Factoring Acc.");
            Description := CopyStr(
                StrSubstNo(Text1100011,
                  PostedBillGr."No.",
                  PostedDoc2."Account No."), 1, MaxStrLen(Description));
            Validate("Currency Code", PostedBillGr."Currency Code");
            Validate(Amount, DisctedAmt);
            "Source Code" := SourceCode;
            "System-Created Entry" := true;
            "Shortcut Dimension 1 Code" := PostedDoc2."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PostedDoc2."Global Dimension 2 Code";
            "Dimension Set ID" := PostedDoc2."Dimension Set ID";
            BGPOPostBuffer."Gain - Loss Amount (LCY)" := BGPOPostBuffer."Gain - Loss Amount (LCY)" + Amount;
            BGPOPostBuffer.Modify;
            OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
            Insert;
            SumLCYAmt := SumLCYAmt + "Amount (LCY)";
        end;
    end;

    [Scope('OnPrem')]
    procedure FactBankAccounting()
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        case true of
            PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount:
                with GenJnlLine do begin
                    CustLedgEntry2.Get(BGPOPostBuffer."Entry No.");
                    GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                    Clear(GenJnlLine);
                    Init;
                    "Line No." := GenJnlLineNextNo;
                    "Posting Date" := PostingDate;
                    "Document Type" := "Document Type"::Payment;
                    "Document No." := PostedBillGr."No.";
                    BankAcc.TestField("Bank Acc. Posting Group");
                    BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                    Validate("Account Type", "Account Type"::"Bank Account");
                    Validate("Account No.", BankAcc."No.");
                    Description := CopyStr(StrSubstNo(Text1100009, PostedBillGr."No."), 1, MaxStrLen(Description));
                    Validate("Currency Code", PostedBillGr."Currency Code");
                    Validate(Amount, GroupAmount - TotalDisctdAmt);
                    "Source Code" := SourceCode;
                    "System-Created Entry" := true;
                    "Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                    "Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                    "Dimension Set ID" := CustLedgEntry2."Dimension Set ID";
                    OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                    Insert;
                    SumLCYAmt := SumLCYAmt + "Amount (LCY)";
                end;
            else
                with GenJnlLine do begin
                    CustLedgEntry2.Get(BGPOPostBuffer."Entry No.");
                    GenJnlLineNextNo := GenJnlLineNextNo + 10000;
                    Clear(GenJnlLine);
                    Init;
                    "Line No." := GenJnlLineNextNo;
                    "Posting Date" := PostingDate;
                    "Document Type" := "Document Type"::Payment;
                    "Document No." := PostedBillGr."No.";
                    BankAcc.TestField("Bank Acc. Posting Group");
                    BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                    Validate("Account Type", "Account Type"::"Bank Account");
                    Validate("Account No.", BankAcc."No.");
                    Description := CopyStr(StrSubstNo(Text1100009, PostedBillGr."No."), 1, MaxStrLen(Description));
                    Validate("Currency Code", PostedBillGr."Currency Code");
                    Validate(Amount, GroupAmount);
                    "Source Code" := SourceCode;
                    "System-Created Entry" := true;
                    "Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                    "Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                    "Dimension Set ID" := CustLedgEntry2."Dimension Set ID";
                    OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry2, PostedBillGr);
                    Insert;
                    SumLCYAmt := SumLCYAmt + "Amount (LCY)";
                end;
        end;
    end;

    local procedure InsertGenJournalLine(AccType: Integer; AccNo: Code[20]; Amount2: Decimal)
    begin
        GenJnlLineNextNo := GenJnlLineNextNo + 10000;

        with GenJnlLine do begin
            Clear(GenJnlLine);
            Init;
            "Line No." := GenJnlLineNextNo;
            "Posting Date" := PostingDate;
            "Document Type" := "Document Type"::Payment;
            "Document No." := PostedBillGr."No.";
            "Account Type" := AccType;
            "Account No." := AccNo;
            Description := CopyStr(
                StrSubstNo(Text1100012, PostedDoc."Document No.", PostedDoc."No."),
                1, MaxStrLen(Description));
            Validate("Currency Code", PostedDoc."Currency Code");
            Validate(Amount, -Amount2);
            "Applies-to Doc. Type" := CustLedgEntry."Document Type";
            "Applies-to Doc. No." := '';
            "Applies-to Bill No." := CustLedgEntry."Bill No.";
            "Source Code" := SourceCode;
            "System-Created Entry" := true;
            "Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
            "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
            OnBeforeGenJournalLineInsert(PostedDoc, GenJnlLine, VATPostingSetup, CustLedgEntry, CustLedgEntry, PostedBillGr);
            Insert;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustUnrealizedVAT2(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group"; var BgPoPostBuffer: Record "BG/PO Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineInsert(var PostedCarteraDoc: Record "Posted Cartera Doc."; var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgerEntry2: Record "Cust. Ledger Entry"; var PostedBillGroup: Record "Posted Bill Group")
    begin
    end;
}

