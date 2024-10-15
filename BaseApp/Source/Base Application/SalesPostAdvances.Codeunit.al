codeunit 31000 "Sales-Post Advances"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Sales Invoice Header" = im,
                  TableData "Sales Invoice Line" = im,
                  TableData "Sales Cr.Memo Header" = im,
                  TableData "Sales Cr.Memo Line" = im,
                  TableData "Sales Advance Letter Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        SalesHeader: Record "Sales Header";
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        SalesInvHeaderBuf: Record "Sales Invoice Header";
        CurrSalesInvHeader: Record "Sales Invoice Header";
        Currency: Record Currency;
        SalesAdvPmtTemplate1: Record "Sales Adv. Payment Template";
        TempSalesAdvanceLetterEntry: Record "Sales Advance Letter Entry" temporary;
        TempAdvanceLink: Record "Advance Link" temporary;
        TempCustLedgEntryGre: Record "Cust. Ledger Entry" temporary;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PrevLineNo: Integer;
        LineNo: Integer;
        NextLinkEntryNo: Integer;
        SystemRun: Boolean;
        LetterNoToInvoice: Code[20];
        DisablePostingCuClear: Boolean;
        SalesAdvanceLetterEntryNo: Integer;
        LastPostedDocNo: Code[20];
        SumAmountToApply: Decimal;
        TotBaseToDeductLCY: Decimal;
        TotVATAmtToDeductLCY: Decimal;
        TotBaseToDeduct: Decimal;
        TotVATAmtToDeduct: Decimal;
        CloseAll: Boolean;
        AdvanceType: Option Sale,Purchase;
        QtyType: Option General,Invoicing,Shipping,Remaining;
        Text001Err: Label 'There is nothing to create Advance Letter.';
        Text002Msg: Label 'Posting Advance Letter Lines #2######\', Comment = '%2=Lines Count';
        Text003Txt: Label 'Invoice,Credit Memo';
        Text004Msg: Label '%1 %2 -> Invoice %3', Comment = '%1=Document type;%2=Document number;%3=Posted document number';
        Text005Msg: Label '%1 %2 -> Credit Memo %3', Comment = '%1=Document type;%2=Document number;%3=Posted document number';
        Text006Err: Label 'There is nothing to post.';
        Text008Err: Label 'cannot be bigger than %1 %2.', Comment = '%1=Field caption;%2=Field value';
        Text009Msg: Label 'Advance Letter: %1', Comment = '%1=Letter No.';
        Text010Msg: Label 'Advance Invoice: %1', Comment = '%1=Document No';
        Text013Msg: Label 'Advance %1 %2.', Comment = '%1=Document type;%2=Document number';
        Text032Err: Label 'The combination of dimensions used in %1 is blocked. %2.', Comment = '%1=Document No.;%2=Dimension Error Text';
        Text4005240Err: Label 'Advance must be before Invoice.';
        Text4005245Qst: Label 'Unpost advance usage on invoice %1 ?', Comment = '%1=Document No.';
        Text4005246Err: Label 'You must unapply entry %1.', Comment = '%1=Entry No.';
        Text4005247Err: Label 'You can not decrease invoiced amount under %1 on AP line %2 %3.', Comment = '%1=Compared field fieldcaption;%2=Letter number;%3=Letter Line number';
        Text4005248Err: Label 'Amount To Deduct is greater then Invoiced Amount on Line %1 dokladu %2 %3.', Comment = '%1=Compared field fieldcaption;%2=Document number;%3=Document Line number';
        Text4005249Err: Label 'Amount To Deduct can not be divided to relations on Line %1 dokladu %2 %3.', Comment = '%1=Document Line number;%2=Document type;%3=Document number';
        Text4005250Err: Label 'Amount To Deduct is greater then Document Invoiced Amount .';
        Text4005251Err: Label '%1 cannot %2.', Comment = '%1=account 1 number;%2=account 2 number';
        AppPrefTxt: Label 'XX';
        Tex033Err: Label 'must not be larger than %1.', Comment = '%1=Amount';
        Text034Err: Label 'You must fill VAT Date.';
        Text035Err: Label 'You must fill Posting Date.';
        Text036Err: Label 'Is not possible to refund requested amount on advance letter %1 line no. %2.', Comment = '%1=Document No.;%2=Document Line No.';
        Text037Err: Label 'Amount To Refund must be greater then 0.';
        Text038Err: Label 'Sum %1 and %2 must be greater or equal then %3.', Comment = '%1=Field Caption;%2=Amount to Inv.;%3=Amount to Deduct;';
        Text040Qst: Label 'Do You Want to Post and Close Sales Advance Letter No. %1 Refund ?', Comment = '%1=Document No.';
        Text041Msg: Label 'Advance Letter No. %1 has been Closed.', Comment = '%1=Document No.';
        Text042Err: Label 'Workdate cannot precede payment on refund for advance letter %1.', Comment = '%1=Document No.';
        Text043Msg: Label '%1 %2.', Comment = '%1=Document type;%2=Document number';
        DescTxt: Label 'Adv. Paym.  %1.', Comment = '%1=Document No.';
        PreviewMode: Boolean;

    [Scope('OnPrem')]
    procedure Invoice(var SalesHeader: Record "Sales Header")
    begin
        Code(SalesHeader, 0);
    end;

    [Scope('OnPrem')]
    procedure CreditMemo(var SalesHeader: Record "Sales Header"; var SalesInvHeader1: Record "Sales Invoice Header")
    begin
        CheckInvoicesForReverse(SalesHeader, SalesInvHeader1);
        Code(SalesHeader, 1);
    end;

    local procedure CheckInvoicesForReverse(SalesHeader: Record "Sales Header"; var SalesInvHeader1: Record "Sales Invoice Header")
    begin
        Clear(SalesInvHeaderBuf);
        SalesInvHeaderBuf.Copy(SalesInvHeader1);
        SalesInvHeaderBuf.SetRecFilter;
        with SalesInvHeaderBuf do
            if IsEmpty then begin // All Invoices will be reversed
                Reset;
                SetCurrentKey("Prepayment Order No.");
                SetRange("Prepayment Order No.", SalesHeader."No.");
                SetFilter("Reversed By Cr. Memo No.", '%1', '');
                if IsEmpty then
                    Error(Text006Err);
            end else begin
                if FindFirst then
                    repeat
                        TestField("Prepayment Type", "Prepayment Type"::Advance);
                        TestField("Reversed By Cr. Memo No.", '');
                    until Next = 0;
            end;
    end;

    [Scope('OnPrem')]
    procedure Letter(var SalesHeader: Record "Sales Header"; var AdvanceLetterNo: Code[20]; AdvanceTemplCode: Code[10])
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        SalesHeader2: Record "Sales Header";
        TempAdvanceLetterLineRelation: Record "Advance Letter Line Relation" temporary;
        SalesAdvPmtTemplate: Record "Sales Adv. Payment Template";
        CustPostGr: Record "Customer Posting Group";
    begin
        SalesHeader.TestField("Prepayment Type", SalesHeader."Prepayment Type"::Advance);

        if AdvanceTemplCode <> '' then
            SalesAdvPmtTemplate.Get(AdvanceTemplCode);

        SalesHeader2 := SalesHeader;
        with SalesHeader2 do begin
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                FieldError("Document Type");
            TestField("Sell-to Customer No.");
            TestField("Bill-to Customer No.");
            if not CheckOpenPrepaymentLines(SalesHeader) then
                Error(Text001Err);

            Validate("Prepayment Type", "Prepayment Type"::Advance);
            // Get Doc. No. and save
            if "Advance Letter No." = '' then begin
                if AdvanceTemplCode = '' then begin
                    TestField("Advance Letter No. Series");
                    "Advance Letter No." :=
                      NoSeriesMgt.GetNextNo("Advance Letter No. Series", "Posting Date", true);
                end else begin
                    SalesAdvPmtTemplate.TestField("Advance Letter Nos.");
                    "Advance Letter No." :=
                      NoSeriesMgt.GetNextNo(SalesAdvPmtTemplate."Advance Letter Nos.", "Posting Date", true);
                end;
                Modify;
                if not SystemRun and not PreviewMode then
                    Commit();
            end;
            AdvanceLetterNo := "Advance Letter No.";

            SalesSetup.Get();

            // Create header
            SalesAdvanceLetterHeader.Init();
            SalesAdvanceLetterHeader.TransferFields(SalesHeader2);
            SalesAdvanceLetterHeader."No." := "Advance Letter No.";
            SalesAdvanceLetterHeader."Order No." := "No.";
            SalesAdvanceLetterHeader."No. Printed" := 0;
            SalesAdvanceLetterHeader."Your Reference" := "Your Reference";
            SalesAdvanceLetterHeader."Language Code" := "Language Code";
            SalesAdvanceLetterHeader."Payment Terms Code" := "Prepmt. Payment Terms Code";
            SalesAdvanceLetterHeader."Payment Method Code" := "Payment Method Code";
            SalesAdvanceLetterHeader."Registration No." := "Registration No.";
            SalesAdvanceLetterHeader."Tax Registration No." := "Tax Registration No.";
            SalesAdvanceLetterHeader."VAT Country/Region Code" := "VAT Country/Region Code";

            SalesAdvanceLetterHeader."Template Code" := AdvanceTemplCode;
            if AdvanceTemplCode <> '' then begin
                if SalesAdvPmtTemplate."Customer Posting Group" <> '' then
                    SalesAdvanceLetterHeader."Customer Posting Group" := SalesAdvPmtTemplate."Customer Posting Group";
                SalesAdvanceLetterHeader."Post Advance VAT Option" := SalesAdvPmtTemplate."Post Advance VAT Option";
            end;

            SalesAdvanceLetterHeader."Amounts Including VAT" := "Prices Including VAT";
            SalesAdvanceLetterHeader.Insert();

            // Create Lines
            TempPrepmtInvLineBuf.DeleteAll();
            CreateAdvanceInvLineBuf(SalesHeader, TempPrepmtInvLineBuf, TempAdvanceLetterLineRelation);

            TempPrepmtInvLineBuf.FindSet;
            repeat
                if TempPrepmtInvLineBuf."Line No." <> 0 then
                    LineNo := TempPrepmtInvLineBuf."Line No."
                else
                    LineNo := PrevLineNo + 10000;

                SalesAdvanceLetterLine.Init();
                SalesAdvanceLetterLine."Letter No." := "Advance Letter No.";
                SalesAdvanceLetterLine."Line No." := LineNo;
                SalesAdvanceLetterLine."Bill-to Customer No." := "Bill-to Customer No.";
                SalesAdvanceLetterLine."No." := TempPrepmtInvLineBuf."G/L Account No.";
                SalesAdvanceLetterLine."Shortcut Dimension 1 Code" := TempPrepmtInvLineBuf."Global Dimension 1 Code";
                SalesAdvanceLetterLine."Shortcut Dimension 2 Code" := TempPrepmtInvLineBuf."Global Dimension 2 Code";
                SalesAdvanceLetterLine."Dimension Set ID" := TempPrepmtInvLineBuf."Dimension Set ID";
                SalesAdvanceLetterLine.Description := TempPrepmtInvLineBuf.Description;
                SalesAdvanceLetterLine."Gen. Bus. Posting Group" := TempPrepmtInvLineBuf."Gen. Bus. Posting Group";
                SalesAdvanceLetterLine."Gen. Prod. Posting Group" := TempPrepmtInvLineBuf."Gen. Prod. Posting Group";
                SalesAdvanceLetterLine."VAT Bus. Posting Group" := TempPrepmtInvLineBuf."VAT Bus. Posting Group";
                SalesAdvanceLetterLine."VAT Prod. Posting Group" := TempPrepmtInvLineBuf."VAT Prod. Posting Group";
                SalesAdvanceLetterLine."VAT %" := TempPrepmtInvLineBuf."VAT %";
                SalesAdvanceLetterLine."Advance Due Date" := SalesAdvanceLetterHeader."Advance Due Date";
                SalesAdvanceLetterLine.Amount := TempPrepmtInvLineBuf.Amount;
                SalesAdvanceLetterLine."Amount Including VAT" := TempPrepmtInvLineBuf."Amount Incl. VAT";
                SalesAdvanceLetterLine."Amount To Link" := 0;
                SalesAdvanceLetterLine."VAT Calculation Type" := TempPrepmtInvLineBuf."VAT Calculation Type";
                SalesAdvanceLetterLine."VAT Amount" := TempPrepmtInvLineBuf."VAT Amount";
                SalesAdvanceLetterLine."VAT Identifier" := TempPrepmtInvLineBuf."VAT Identifier";
                SalesAdvanceLetterLine."Currency Code" := "Currency Code";
                CustPostGr.Get(SalesAdvanceLetterHeader."Customer Posting Group");
                CustPostGr.TestField("Advance Account");
                SalesAdvanceLetterLine."Advance G/L Account No." := CustPostGr."Advance Account";
                SalesAdvanceLetterLine."Job No." := TempPrepmtInvLineBuf."Job No.";
                SalesAdvanceLetterLine.Insert(true);

                InsertLineRelations(TempPrepmtInvLineBuf."Entry No.", SalesAdvanceLetterLine, TempAdvanceLetterLineRelation);

                PrevLineNo := LineNo;
            until TempPrepmtInvLineBuf.Next = 0;

            // Update header
            "Advance Letter No." := '';
            Modify;
        end;
        SalesHeader := SalesHeader2;
    end;

    local procedure "Code"(var SalesHeader2: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
    begin
        SalesHeader := SalesHeader2;
        with SalesHeader do begin
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                FieldError("Document Type");

            TestField("Sell-to Customer No.");
            TestField("Bill-to Customer No.");

            case DocumentType of
                DocumentType::Invoice:
                    begin
                        SalesAdvanceLetterHeader.SetRange("Order No.", "No.");
                        if LetterNoToInvoice <> '' then
                            SalesAdvanceLetterHeader.SetRange("No.", LetterNoToInvoice);
                        CheckLetter(SalesAdvanceLetterHeader, DocumentType);
                        if SalesAdvanceLetterHeader.FindSet then
                            repeat
                                PostLetter(SalesAdvanceLetterHeader, DocumentType);
                            until SalesAdvanceLetterHeader.Next = 0;
                    end;
                DocumentType::"Credit Memo":
                    begin
                        if SalesInvHeaderBuf.FindSet then
                            repeat
                                TempSalesAdvanceLetterHeader."No." := SalesInvHeaderBuf."Letter No.";
                                if TempSalesAdvanceLetterHeader.Insert() then;
                            until SalesInvHeaderBuf.Next = 0;
                        CheckLetter(TempSalesAdvanceLetterHeader, DocumentType);
                        TempSalesAdvanceLetterHeader.DeleteAll();
                        if SalesInvHeaderBuf.FindSet then
                            repeat
                                CurrSalesInvHeader := SalesInvHeaderBuf;
                                if (LetterNoToInvoice = '') or (LetterNoToInvoice = SalesInvHeaderBuf."Letter No.") then begin
                                    SalesAdvanceLetterHeader.Get(SalesInvHeaderBuf."Letter No.");
                                    PostLetter(SalesAdvanceLetterHeader, DocumentType);
                                end;
                            until SalesInvHeaderBuf.Next = 0;
                    end;
            end;
        end;
        SalesHeader2 := SalesHeader;
    end;

    local procedure CheckOpenPrepaymentLines(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            Reset;
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Prepmt. Line Amount", '<>0');
            if FindSet then begin
                repeat
                    if "Prepmt. Line Amount" > 0 then
                        exit(true);
                until Next = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AutoLinkPayment(CustLedgEntry: Record "Cust. Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        TempAdvanceLink: Record "Advance Link" temporary;
        AmountToLink: Decimal;
        NextLinkEntryNo: Integer;
        TotalAmounToLink: Decimal;
    begin
        if CustLedgEntry."Document Type" <> CustLedgEntry."Document Type"::Payment then
            exit;
        SetCurrencyPrecision(CustLedgEntry."Currency Code");

        SalesAdvanceLetterLine.SetCurrentKey("Bill-to Customer No.");
        SalesAdvanceLetterLine.SetRange("Bill-to Customer No.", CustLedgEntry."Customer No.");

        if GenJnlLine."Advance Letter Link Code" <> '' then
            SalesAdvanceLetterLine.SetRange("Link Code", GenJnlLine."Advance Letter Link Code")
        else
            SalesAdvanceLetterLine.SetRange("Applies-to ID", CustLedgEntry."Document No.");
        if SalesAdvanceLetterLine.FindSet(true) then begin
            repeat
                if SalesAdvanceLetterLine."Amount Linked To Journal Line" <> 0 then begin
                    AmountToLink := SalesAdvanceLetterLine."Amount Linked To Journal Line";
                    TotalAmounToLink := TotalAmounToLink + AmountToLink;
                    SalesAdvanceLetterLine."Amount Linked To Journal Line" := 0;
                    SalesAdvanceLetterLine."Applies-to ID" := '';
                    SalesAdvanceLetterLine."Link Code" := '';
                    SalesAdvanceLetterLine.Modify();

                    if not TempSalesAdvanceLetterHeader.Get(SalesAdvanceLetterLine."Letter No.") then begin
                        TempSalesAdvanceLetterHeader."No." := SalesAdvanceLetterLine."Letter No.";
                        TempSalesAdvanceLetterHeader.Insert();
                    end;

                    NextLinkEntryNo := NextLinkEntryNo + 1;
                    TempAdvanceLink.Init();
                    TempAdvanceLink."Entry No." := NextLinkEntryNo;
                    TempAdvanceLink."Entry Type" := TempAdvanceLink."Entry Type"::"Link To Letter";
                    TempAdvanceLink."CV Ledger Entry No." := CustLedgEntry."Entry No.";
                    TempAdvanceLink."Posting Date" := CustLedgEntry."Posting Date";
                    TempAdvanceLink."Currency Code" := CustLedgEntry."Currency Code";
                    TempAdvanceLink.Amount := AmountToLink;
                    if TempAdvanceLink."Currency Code" = '' then
                        TempAdvanceLink."Amount (LCY)" := AmountToLink
                    else
                        TempAdvanceLink."Amount (LCY)" :=
                          Round(AmountToLink / CustLedgEntry."Original Currency Factor");
                    TempAdvanceLink."Remaining Amount to Deduct" := TempAdvanceLink.Amount;
                    TempAdvanceLink."Document No." := SalesAdvanceLetterLine."Letter No.";
                    TempAdvanceLink."Line No." := SalesAdvanceLetterLine."Line No.";
                    TempAdvanceLink.Type := TempAdvanceLink.Type::Sale;
                    TempAdvanceLink.Insert();
                end;
            until SalesAdvanceLetterLine.Next = 0;
        end;
        InsertLinks(TempAdvanceLink);
    end;

    [Scope('OnPrem')]
    procedure AutoPostAdvanceInvoices()
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        DocumentType: Option Invoice,"Credit Memo";
        PostingDate: Date;
    begin
        SystemRun := true;
        if CheckLetter(TempSalesAdvanceLetterHeader, DocumentType::Invoice) then
            if TempSalesAdvanceLetterHeader.FindSet then
                repeat
                    SalesAdvanceLetterHeader.Get(TempSalesAdvanceLetterHeader."No.");
                    Clear(SalesHeader);

                    CalcPostingDate(SalesAdvanceLetterHeader, PostingDate);
                    if SalesAdvanceLetterHeader."Posting Date" < PostingDate then
                        SalesAdvanceLetterHeader."Posting Date" := PostingDate;
                    SalesAdvanceLetterHeader."VAT Date" := SalesAdvanceLetterHeader."Posting Date";
                    SalesAdvanceLetterHeader.Modify();

                    case SalesAdvanceLetterHeader."Post Advance VAT Option" of
                        SalesAdvanceLetterHeader."Post Advance VAT Option"::Always:
                            PostLetter(SalesAdvanceLetterHeader, DocumentType::Invoice);
                        SalesAdvanceLetterHeader."Post Advance VAT Option"::Never:
                            TransAmountWithoutInv(SalesAdvanceLetterHeader);
                    end;
                until TempSalesAdvanceLetterHeader.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertInitialAdvanceLink(CustLedgEntry: Record "Cust. Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    var
        AdvanceLink: Record "Advance Link";
        NextEntryNo: Integer;
    begin
        with AdvanceLink do begin
            CheckAmountToLink(GenJnlLine);

            LockTable();
            NextEntryNo := GetLastEntryNo() + 1;

            Init;
            "Entry No." := NextEntryNo;
            "Entry Type" := "Entry Type"::"Initial Amount";
            Type := Type::Sale;
            "Currency Code" := CustLedgEntry."Currency Code";
            Amount := GenJnlLine.Amount;
            "Amount (LCY)" := GenJnlLine."Amount (LCY)";
            "CV Ledger Entry No." := CustLedgEntry."Entry No.";
            Insert;
        end;
    end;

    local procedure CheckAmountToLink(GenJnlLine: Record "Gen. Journal Line")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        TotalAmount: Decimal;
    begin
        SalesAdvanceLetterLine.SetCurrentKey("Bill-to Customer No.");
        SalesAdvanceLetterLine.SetRange("Bill-to Customer No.", GenJnlLine."Account No.");

        if GenJnlLine."Advance Letter Link Code" <> '' then
            SalesAdvanceLetterLine.SetRange("Link Code", GenJnlLine."Advance Letter Link Code")
        else
            SalesAdvanceLetterLine.SetRange("Applies-to ID", GenJnlLine."Document No.");
        if SalesAdvanceLetterLine.FindSet then begin
            repeat
                if Abs(SalesAdvanceLetterLine."Amount Linked To Journal Line") > Abs(SalesAdvanceLetterLine."Amount To Link") then
                    SalesAdvanceLetterLine.FieldError(
                      "Amount Linked To Journal Line",
                      StrSubstNo(Text008Err, SalesAdvanceLetterLine.FieldCaption("Amount To Link"), SalesAdvanceLetterLine."Amount To Link"));
                TotalAmount := TotalAmount + SalesAdvanceLetterLine."Amount Linked To Journal Line";
            until SalesAdvanceLetterLine.Next = 0;
            if Abs(TotalAmount) > Abs(GenJnlLine.Amount) then
                SalesAdvanceLetterLine.FieldError(
                  "Amount Linked To Journal Line",
                  StrSubstNo(Text008Err, GenJnlLine.FieldCaption(Amount), GenJnlLine.Amount));
        end;
    end;

    [Scope('OnPrem')]
    procedure HandleLinksBuf(var AdvanceLinkBuf: Record "Advance Link Buffer")
    var
        TempAdvanceLinkBufPmt: Record "Advance Link Buffer" temporary;
        TempAdvanceLinkBufLetterLine: Record "Advance Link Buffer" temporary;
        TempAdvanceLink: Record "Advance Link" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        AmountToLink: Decimal;
    begin
        if AdvanceLinkBuf.FindSet then begin
            repeat
                if AdvanceLinkBuf."Entry Type" = AdvanceLinkBuf."Entry Type"::Payment then begin
                    TempAdvanceLinkBufPmt := AdvanceLinkBuf;
                    TempAdvanceLinkBufPmt.Insert();
                end else begin
                    TempAdvanceLinkBufLetterLine := AdvanceLinkBuf;
                    TempAdvanceLinkBufLetterLine.Insert();
                end;
            until AdvanceLinkBuf.Next = 0;

            NextLinkEntryNo := 0;
            if TempAdvanceLinkBufPmt.FindSet(true) then
                repeat
                    SetCurrencyPrecision(TempAdvanceLinkBufPmt."Currency Code");
                    CustLedgEntry.Get(TempAdvanceLinkBufPmt."Entry No.");

                    TempAdvanceLinkBufLetterLine.SetFilter("Amount To Link", '<>%1', 0);
                    if TempAdvanceLinkBufLetterLine.FindSet(true) then
                        repeat
                            if Abs(TempAdvanceLinkBufLetterLine."Amount To Link") < Abs(TempAdvanceLinkBufPmt."Amount To Link") then
                                AmountToLink := TempAdvanceLinkBufLetterLine."Amount To Link"
                            else
                                AmountToLink := -TempAdvanceLinkBufPmt."Amount To Link";
                            TempAdvanceLinkBufPmt."Amount To Link" := TempAdvanceLinkBufPmt."Amount To Link" + AmountToLink;
                            TempAdvanceLinkBufPmt.Modify();
                            TempAdvanceLinkBufLetterLine."Amount To Link" := TempAdvanceLinkBufLetterLine."Amount To Link" - AmountToLink;
                            TempAdvanceLinkBufLetterLine.Modify();

                            NextLinkEntryNo := NextLinkEntryNo + 1;
                            TempAdvanceLink.Init();
                            TempAdvanceLink."Entry No." := NextLinkEntryNo;
                            TempAdvanceLink."Entry Type" := TempAdvanceLink."Entry Type"::"Link To Letter";
                            TempAdvanceLink.Type := TempAdvanceLink.Type::Sale;
                            TempAdvanceLink."CV Ledger Entry No." := TempAdvanceLinkBufPmt."Entry No.";
                            TempAdvanceLink."Posting Date" := CustLedgEntry."Posting Date";
                            TempAdvanceLink."Currency Code" := TempAdvanceLinkBufPmt."Currency Code";
                            TempAdvanceLink.Amount := AmountToLink;
                            if TempAdvanceLink."Currency Code" = '' then
                                TempAdvanceLink."Amount (LCY)" := AmountToLink
                            else
                                TempAdvanceLink."Amount (LCY)" :=
                                  Round(AmountToLink / CustLedgEntry."Original Currency Factor");
                            TempAdvanceLink."Remaining Amount to Deduct" := TempAdvanceLink.Amount;
                            TempAdvanceLink."Document No." := TempAdvanceLinkBufLetterLine."Document No.";
                            TempAdvanceLink."Line No." := TempAdvanceLinkBufLetterLine."Entry No.";
                            TempAdvanceLink.Insert();

                        until TempAdvanceLinkBufLetterLine.Next = 0;
                until TempAdvanceLinkBufPmt.Next = 0;

            InsertLinks(TempAdvanceLink);
            PostDocAfterApp(TempAdvanceLink);
        end;
    end;

    local procedure InsertLinks(var AdvanceLinkTemp: Record "Advance Link")
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        AdvanceLink: Record "Advance Link";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        AdvanceLink.LockTable();
        if AdvanceLink.FindLast then
            NextLinkEntryNo := AdvanceLink."Entry No." + 1
        else
            NextLinkEntryNo := 1;

        if AdvanceLinkTemp.FindSet then
            repeat
                AdvanceLink.TransferFields(AdvanceLinkTemp);
                AdvanceLink."Entry No." := NextLinkEntryNo;
                AdvanceLink.Insert();
                if AdvanceLink."Entry Type" = AdvanceLink."Entry Type"::"Link To Letter" then begin
                    SalesAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");
                    SalesAdvanceLetterLine."Amount To Link" := SalesAdvanceLetterLine."Amount To Link" - AdvanceLink.Amount;
                    SalesAdvanceLetterLine."Amount Linked" := SalesAdvanceLetterLine."Amount Linked" + AdvanceLink.Amount;
                    SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" + AdvanceLink.Amount;
                    SalesAdvanceLetterLine.SuspendStatusCheck(true);
                    SalesAdvanceLetterLine.Modify(true);
                    SalesAdvanceLetterHeader.Get(SalesAdvanceLetterLine."Letter No.");
                    GetSaleAdvanceTempl(SalesAdvanceLetterHeader."Template Code");
                    if SalesAdvPmtTemplate1."Check Posting Group on Link" then begin
                        CustLedgEntry.Get(AdvanceLink."CV Ledger Entry No.");
                        CustLedgEntry.TestField("Customer Posting Group", SalesAdvanceLetterHeader."Customer Posting Group");
                    end;
                end;
                TempCustLedgEntry.Init();
                TempCustLedgEntry."Entry No." := AdvanceLink."CV Ledger Entry No.";
                if not TempCustLedgEntry.Find then
                    TempCustLedgEntry.Insert();
                NextLinkEntryNo := NextLinkEntryNo + 1;
            until AdvanceLinkTemp.Next = 0;
        UpdateCustLedgEntries(TempCustLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure RemoveLinks(LetterNo: Code[20]; var AdvanceLink: Record "Advance Link")
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
    begin
        if AdvanceLink.IsEmpty then begin
            AdvanceLink.Reset();
            AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
            AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
            AdvanceLink.SetRange("Document No.", LetterNo);
            AdvanceLink.SetRange("Invoice No.", '');
            AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);
        end;
        if AdvanceLink.FindSet(true) then
            repeat
                AdvanceLink.TestField(Type, AdvanceLink.Type::Sale);
                AdvanceLink.TestField("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                AdvanceLink.TestField("Document No.", LetterNo);
                AdvanceLink.TestField("Invoice No.", '');
                SalesAdvanceLetterHeader.Get(AdvanceLink."Document No.");
                SalesAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");

                SalesAdvanceLetterLine."Amount To Link" := SalesAdvanceLetterLine."Amount To Link" + AdvanceLink.Amount;
                SalesAdvanceLetterLine."Amount Linked" := SalesAdvanceLetterLine."Amount Linked" - AdvanceLink.Amount;
                if AdvanceLink."Transfer Date" = 0D then
                    SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" - AdvanceLink.Amount
                else begin
                    SalesAdvanceLetterLine."Amount Invoiced" := SalesAdvanceLetterLine."Amount Invoiced" - AdvanceLink.Amount;
                    SalesAdvanceLetterLine."Amount To Deduct" := SalesAdvanceLetterLine."Amount To Deduct" - AdvanceLink.Amount;
                end;

                SalesAdvanceLetterLine.SuspendStatusCheck(true);
                SalesAdvanceLetterLine.Modify(true);
                UpdInvAmountToLineRelations(SalesAdvanceLetterLine);
                AdvanceLink.Delete();
                TempCustLedgEntry."Entry No." := AdvanceLink."CV Ledger Entry No.";
                if not TempCustLedgEntry.Find then
                    TempCustLedgEntry.Insert();

            until AdvanceLink.Next = 0;
        UpdateCustLedgEntries(TempCustLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure RemovePmtLinks(EntryNo: Integer)
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        AdvanceLink: Record "Advance Link";
        LinksToAdvanceLetter: Page "Links to Advance Letter";
    begin
        AdvanceLink.FilterGroup(0);
        AdvanceLink.SetCurrentKey("CV Ledger Entry No.");
        AdvanceLink.SetRange("CV Ledger Entry No.", EntryNo);
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Invoice No.", '');
        AdvanceLink.FilterGroup(2);
        LinksToAdvanceLetter.SetTableView(AdvanceLink);
        LinksToAdvanceLetter.LookupMode(true);
        if LinksToAdvanceLetter.RunModal = ACTION::LookupOK then begin
            LinksToAdvanceLetter.GetSelection(AdvanceLink);
            if AdvanceLink.FindSet(true) then begin
                repeat
                    if AdvanceLink."Entry Type" = AdvanceLink."Entry Type"::"Link To Letter" then begin
                        SalesAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");
                        SalesAdvanceLetterLine."Amount To Link" := SalesAdvanceLetterLine."Amount To Link" + Abs(AdvanceLink.Amount);
                        SalesAdvanceLetterLine."Amount Linked" := SalesAdvanceLetterLine."Amount Linked" - Abs(AdvanceLink.Amount);
                        if AdvanceLink."Transfer Date" = 0D then
                            SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" - Abs(AdvanceLink.Amount)
                        else begin
                            SalesAdvanceLetterLine."Amount Invoiced" := SalesAdvanceLetterLine."Amount Invoiced" - Abs(AdvanceLink.Amount);
                            SalesAdvanceLetterLine."Amount To Deduct" := SalesAdvanceLetterLine."Amount To Deduct" - Abs(AdvanceLink.Amount);
                        end;

                        SalesAdvanceLetterLine.SuspendStatusCheck(true);
                        SalesAdvanceLetterLine.Modify(true);
                        UpdInvAmountToLineRelations(SalesAdvanceLetterLine);
                        AdvanceLink.Delete();
                    end;
                until AdvanceLink.Next = 0;
                TempCustLedgEntry."Entry No." := EntryNo;
                TempCustLedgEntry.Insert();
                UpdateCustLedgEntries(TempCustLedgEntry);
            end;
        end;
    end;

    local procedure UpdateCustLedgEntries(var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if TempCustLedgEntry.FindSet then
            repeat
                CustLedgEntry.Get(TempCustLedgEntry."Entry No.");
                CustLedgEntry.CalcFields("Remaining Amount to Link");
                CustLedgEntry."Open For Advance Letter" := CustLedgEntry."Remaining Amount to Link" <> 0;
                CustLedgEntry.Modify();
            until TempCustLedgEntry.Next = 0;
    end;

    local procedure CheckLetter(var SalesAdvanceLetterHeader2: Record "Sales Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo"): Boolean
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        OK: Boolean;
    begin
        OK := false;
        if SalesAdvanceLetterHeader2.FindSet then
            repeat
                SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader2."No.");
                if DocumentType = DocumentType::Invoice then
                    SalesAdvanceLetterLine.SetFilter("Amount To Invoice", '<>%1', 0)
                else
                    SalesAdvanceLetterLine.SetFilter("Amount To Deduct", '<>%1', 0);
                OK := not SalesAdvanceLetterLine.IsEmpty;
            until (SalesAdvanceLetterHeader2.Next = 0) or OK;

        if not OK then begin
            if SystemRun then
                exit(false);
            Error(Text006Err);
        end;
        exit(true)
    end;

    [Scope('OnPrem')]
    procedure TransAmountWithoutInv(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    var
        AdvanceLink: Record "Advance Link";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        if (SalesAdvanceLetterHeader."Post Advance VAT Option" <> SalesAdvanceLetterHeader."Post Advance VAT Option"::Never) and
           (SalesAdvanceLetterHeader."Post Advance VAT Option" <> SalesAdvanceLetterHeader."Post Advance VAT Option"::Optional)
        then
            Error(Text4005251Err, SalesAdvanceLetterHeader.FieldCaption("Post Advance VAT Option"),
              SalesAdvanceLetterHeader."Post Advance VAT Option");
        SalesAdvanceLetterHeader.CalcFields(Status);
        if SalesAdvanceLetterHeader.Status > SalesAdvanceLetterHeader.Status::"Pending Invoice" then
            SalesAdvanceLetterHeader.TestField(Status, SalesAdvanceLetterHeader.Status::"Pending Invoice");
        SalesAdvanceLetterHeader.CheckAmountToInvoice;

        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterHeader."No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);
        AdvanceLink.SetRange("Invoice No.", '');

        if AdvanceLink.FindSet then
            repeat
                if AdvanceLink."Transfer Date" = 0D then begin
                    SalesAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");
                    SalesAdvanceLetterLine."Amount Invoiced" := SalesAdvanceLetterLine."Amount Invoiced" + AdvanceLink.Amount;
                    SalesAdvanceLetterLine."Amount To Deduct" := SalesAdvanceLetterLine."Amount To Deduct" + AdvanceLink.Amount;
                    SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" - AdvanceLink.Amount;
                    SalesAdvanceLetterLine.SuspendStatusCheck(true);
                    SalesAdvanceLetterLine.Modify(true);
                    UpdInvAmountToLineRelations(SalesAdvanceLetterLine);
                    AdvanceLink."Transfer Date" := WorkDate;
                    AdvanceLink.Modify();
                end;
            until AdvanceLink.Next = 0;

        UpdateLines(SalesAdvanceLetterHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure RestoreTransfAmountWithoutInv(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    var
        AdvanceLink: Record "Advance Link";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        if (SalesAdvanceLetterHeader."Post Advance VAT Option" <> SalesAdvanceLetterHeader."Post Advance VAT Option"::Never) and
           (SalesAdvanceLetterHeader."Post Advance VAT Option" <> SalesAdvanceLetterHeader."Post Advance VAT Option"::Optional)
        then
            Error(Text4005251Err, SalesAdvanceLetterHeader.FieldCaption("Post Advance VAT Option"),
              SalesAdvanceLetterHeader."Post Advance VAT Option");
        SalesAdvanceLetterHeader.CalcFields(Status);
        if SalesAdvanceLetterHeader.Status > SalesAdvanceLetterHeader.Status::"Pending Final Invoice" then
            SalesAdvanceLetterHeader.TestField(Status, SalesAdvanceLetterHeader.Status::"Pending Final Invoice");

        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterHeader."No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);
        AdvanceLink.SetRange("Invoice No.", '');

        if AdvanceLink.FindSet then
            repeat
                if (AdvanceLink."Transfer Date" <> 0D) and
                   (AdvanceLink.Amount = AdvanceLink."Remaining Amount to Deduct")
                then begin
                    SalesAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");
                    SalesAdvanceLetterLine."Amount Invoiced" := SalesAdvanceLetterLine."Amount Invoiced" - AdvanceLink.Amount;
                    SalesAdvanceLetterLine."Amount To Deduct" := SalesAdvanceLetterLine."Amount To Deduct" - AdvanceLink.Amount;
                    SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" + AdvanceLink.Amount;
                    SalesAdvanceLetterLine.SuspendStatusCheck(true);
                    SalesAdvanceLetterLine.Modify(true);
                    UpdInvAmountToLineRelations(SalesAdvanceLetterLine);
                    AdvanceLink."Transfer Date" := 0D;
                    AdvanceLink.Modify();
                end;
            until AdvanceLink.Next = 0;

        UpdateLines(SalesAdvanceLetterHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure PostLetter(var SalesAdvanceLetterHeader2: Record "Sales Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo"): Boolean
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        GenJnlLine: Record "Gen. Journal Line";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        SourceCodeSetup: Record "Source Code Setup";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry";
        Window: Dialog;
        GenJnlLineDocNo: Code[20];
        GenJnlLineDocType: Integer;
        LineCount: Integer;
        VATDate: Date;
        PostingDate: Date;
        LineAmount: Decimal;
        PostingDescription: Text[50];
        SrcCode: Code[10];
    begin
        OnBeforePostLetter(SalesAdvanceLetterHeader2, DocumentType);

        SalesAdvanceLetterHeader := SalesAdvanceLetterHeader2;
        SalesAdvanceLetterHeader.OnCheckSalesAdvanceLetterPostRestrictions;
        SalesSetup.Get();
        PostLetter_PreTest(SalesAdvanceLetterHeader, DocumentType);

        with SalesHeader do begin
            Clear(SalesHeader);
            SetCurrencyPrecision("Currency Code");
            SalesAdvanceLetterHeader.CalcFields(Status);

            TransferFields(SalesAdvanceLetterHeader);
            CopyBillToSellFromAdvLetter(SalesHeader, SalesAdvanceLetterHeader);
            UpdateIncomingDocument(
              SalesAdvanceLetterHeader."Incoming Document Entry No.",
              SalesAdvanceLetterHeader."Posting Date",
              SalesAdvanceLetterHeader."No.");

            "Prepayment Type" := "Prepayment Type"::Advance;

            GLSetup.Get();

            // Get Doc. No. and save
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        TestField("Prepmt. Cr. Memo No.", '');
                        CalcPostingDate(SalesAdvanceLetterHeader, PostingDate);
                        if VATDate = 0D then
                            VATDate := PostingDate;
                        if "Prepayment No." = '' then
                            "Prepayment No." := GetInvoiceDocNo(SalesAdvanceLetterHeader, PostingDate);
                        GenJnlLineDocNo := "Prepayment No.";
                        GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    end;
                DocumentType::"Credit Memo":
                    begin
                        TestField("Prepayment No.", '');
                        SalesAdvanceLetterHeader.TESTFIELD("Document Date");
                        PostingDate := SalesAdvanceLetterHeader."Document Date";
                        VATDate := SalesAdvanceLetterHeader."VAT Date";
                        if VATDate = 0D then
                            VATDate := PostingDate;
                        if "Prepmt. Cr. Memo No." = '' then
                            "Prepmt. Cr. Memo No." := GetCrMemoDocNo(SalesAdvanceLetterHeader, PostingDate);
                        GenJnlLineDocNo := "Prepmt. Cr. Memo No.";
                        GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    end;
            end;

            Window.Open(
              '#1#################################\\' +
              Text002Msg);
            Window.Update(1, StrSubstNo(Text043Msg, SelectStr(1 + DocumentType, Text003Txt), GenJnlLineDocNo));

            SourceCodeSetup.Get();
            SrcCode := SourceCodeSetup.Sales;

            PostingDescription :=
              CopyStr(
                StrSubstNo(Text013Msg, SelectStr(1 + DocumentType, Text003Txt), "No."),
                1, MaxStrLen("Posting Description"));

            // Create posted header
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        PostLetter_SetInvHeader(SalesInvHeader, SalesAdvanceLetterHeader, SalesHeader, GenJnlLineDocNo, SrcCode, PostingDescription,
                          PostingDate, VATDate);
                        GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                        Window.Update(1, StrSubstNo(Text004Msg, "Document Type", "No.", SalesInvHeader."No."));
                    end;
                DocumentType::"Credit Memo":
                    begin
                        PostLetter_SetCrMemoHeader(
                          SalesCrMemoHeader, SalesInvHeaderBuf, SalesAdvanceLetterHeader, GenJnlLineDocNo, SrcCode, PostingDescription);
                        SalesInvHeader.Get(CurrSalesInvHeader."No.");
                        SalesInvHeader."Reversed By Cr. Memo No." := SalesCrMemoHeader."No.";
                        SalesInvHeader.Modify();

                        SalesAdvanceLetterEntry.SetCurrentKey("Document No.", "Posting Date");
                        SalesAdvanceLetterEntry.SetRange("Document No.", SalesInvHeader."No.");
                        SalesAdvanceLetterEntry.SetRange("Posting Date", SalesInvHeader."Posting Date");
                        SalesAdvanceLetterEntry.SetRange("Letter No.", SalesInvHeader."Letter No.");
                        SalesAdvanceLetterEntry.ModifyAll(Cancelled, true);
                        GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                        Window.Update(1, StrSubstNo(Text005Msg, "Document Type", "No.", SalesCrMemoHeader."No."));
                    end;
            end;

            // Create Lines
            LineCount := 0;
            TempPrepmtInvLineBuf.DeleteAll();

            case DocumentType of
                DocumentType::Invoice:
                    BuildInvoiceLineBuf(SalesAdvanceLetterHeader, TempPrepmtInvLineBuf);
                DocumentType::"Credit Memo":
                    BuilCreditMemoBuf(SalesAdvanceLetterHeader, TempPrepmtInvLineBuf);
            end;

            if TempPrepmtInvLineBuf.FindSet then
                repeat
                    if TempPrepmtInvLineBuf."VAT Calculation Type" =
                       TempPrepmtInvLineBuf."VAT Calculation Type"::"Reverse Charge VAT"
                    then
                        TempPrepmtInvLineBuf."VAT Amount" := 0;
                    LineAmount := TempPrepmtInvLineBuf."VAT Amount";
                    case DocumentType of
                        DocumentType::Invoice:
                            PostLetter_SetInvLine(SalesInvLine, SalesInvHeader, TempPrepmtInvLineBuf, LineAmount);
                        DocumentType::"Credit Memo":
                            PostLetter_SetCrMemoLine(SalesCrMemoLine, SalesCrMemoHeader, TempPrepmtInvLineBuf, SalesAdvanceLetterEntry,
                              SalesAdvanceLetterHeader."No.", CurrSalesInvHeader."No.");
                    end;

                    // Posting to G/L
                    LineCount := LineCount + 1;
                    Window.Update(1, LineCount);

                    if DocumentType = DocumentType::Invoice then begin
                        ReverseAmounts(TempPrepmtInvLineBuf);
                        TempPrepmtInvLineBuf."Amount (LCY)" := -TempPrepmtInvLineBuf."Amount (LCY)";
                        TempPrepmtInvLineBuf."VAT Amount (LCY)" := -TempPrepmtInvLineBuf."VAT Amount (LCY)";
                        TempPrepmtInvLineBuf."VAT Base Amount (LCY)" := -TempPrepmtInvLineBuf."VAT Base Amount (LCY)";
                        TempPrepmtInvLineBuf."Amount Incl. VAT (LCY)" := -TempPrepmtInvLineBuf."Amount Incl. VAT (LCY)";
                    end;

                    PostLetter_PostToGL(GenJnlLine, TempPrepmtInvLineBuf, SalesAdvanceLetterHeader, SalesAdvanceLetterEntry,
                      DocumentType, GenJnlLineDocNo, GenJnlLineDocType, PostingDescription, SrcCode,
                      PostingDate, VATDate);

                    OnBeforePostLetterToGL(GenJnlLine, SalesAdvanceLetterHeader);
                    RunGenJnlPostLine(GenJnlLine);

                    SalesAdvanceLetterLine.Get(SalesAdvanceLetterHeader."No.", TempPrepmtInvLineBuf."Line No.");

                    PostLetter_UpdtAdvLines(
                      SalesAdvanceLetterLine, SalesAdvanceLetterHeader, DocumentType, GenJnlLineDocType, GenJnlLineDocNo, LineAmount, PostingDate);

                    FillVATFieldsOfDeductionEntry(TempPrepmtInvLineBuf."VAT %");
                    TempSalesAdvanceLetterEntry."VAT Identifier" := TempPrepmtInvLineBuf."VAT Identifier";
                    TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::VAT;
                    TempSalesAdvanceLetterEntry."Sale Line No." := TempPrepmtInvLineBuf."Line No.";
                    TempSalesAdvanceLetterEntry."Document Type" := GenJnlLine."Document Type";
                    if DocumentType = DocumentType::Invoice then begin
                        TempSalesAdvanceLetterEntry."VAT Base Amount" := TempPrepmtInvLineBuf."VAT Base Amount";
                        TempSalesAdvanceLetterEntry."VAT Amount" := TempPrepmtInvLineBuf."VAT Amount";
                    end else begin
                        TempSalesAdvanceLetterEntry."VAT Base Amount" := -SalesAdvanceLetterEntry."VAT Base Amount";
                        TempSalesAdvanceLetterEntry."VAT Amount" := -SalesAdvanceLetterEntry."VAT Amount";
                    end;
                    TempSalesAdvanceLetterEntry.Cancelled := (DocumentType = DocumentType::"Credit Memo");
                    TempSalesAdvanceLetterEntry.Modify();
                until TempPrepmtInvLineBuf.Next = 0;
            SaveDeductionEntries;
        end;

        // Update Letter Header

        LastPostedDocNo := GenJnlLineDocNo;
        SalesAdvanceLetterHeader2 := SalesAdvanceLetterHeader;
        if DocumentType = DocumentType::"Credit Memo" then
            ClearReasonCodeOnCrMemo(SalesAdvanceLetterHeader2);
        if not DisablePostingCuClear then
            Clear(GenJnlPostLine);

        OnAfterPostLetter(SalesAdvanceLetterHeader);

        Window.Close;
        exit(true);
    end;

    local procedure PostLetter_PreTest(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        SalesAdvPaymentTemplate: Record "Sales Adv. Payment Template";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.PrePostApprovalCheckSalesAdvanceLetter(SalesAdvanceLetterHeader);
        if (SalesAdvanceLetterHeader."Post Advance VAT Option" <> SalesAdvanceLetterHeader."Post Advance VAT Option"::Always) and
           (SalesAdvanceLetterHeader."Post Advance VAT Option" <> SalesAdvanceLetterHeader."Post Advance VAT Option"::Optional)
        then
            Error(Text4005251Err, SalesAdvanceLetterHeader.FieldCaption("Post Advance VAT Option"),
              SalesAdvanceLetterHeader."Post Advance VAT Option");

        if not DimMgt.CheckDimIDComb(SalesAdvanceLetterHeader."Dimension Set ID") then
            Error(
              Text032Err,
              SalesAdvanceLetterHeader."No.", DimMgt.GetDimCombErr);

        SalesAdvanceLetterHeader.CalcFields(Status);
        if DocumentType = DocumentType::Invoice then begin
            if SalesAdvanceLetterHeader.Status > SalesAdvanceLetterHeader.Status::"Pending Invoice" then
                SalesAdvanceLetterHeader.TestField(Status, SalesAdvanceLetterHeader.Status::"Pending Invoice");
            SalesAdvanceLetterHeader.CheckAmountToInvoice;
        end else begin
            CheckReasonCodeForCrMemo(SalesAdvanceLetterHeader);
            if SalesAdvanceLetterHeader.Status > SalesAdvanceLetterHeader.Status::"Pending Final Invoice" then
                SalesAdvanceLetterHeader.TestField(Status, SalesAdvanceLetterHeader.Status::"Pending Final Invoice");
            SalesAdvanceLetterHeader.CheckDeductedAmount;
        end;

        if SalesSetup."Ext. Doc. No. Mandatory" then
            SalesAdvanceLetterHeader.TestField("External Document No.");

        if SalesAdvanceLetterHeader."Template Code" <> '' then begin
            SalesAdvPaymentTemplate.Get(SalesAdvanceLetterHeader."Template Code");
            SalesAdvPaymentTemplate.TestField("Advance Invoice Nos.");
            SalesAdvPaymentTemplate.TestField("Advance Credit Memo Nos.");
        end else begin
            SalesSetup.TestField("Advance Invoice Nos.");
            SalesSetup.TestField("Advance Credit Memo Nos.");
        end;
    end;

    local procedure PostLetter_SetInvHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; SalesHeader: Record "Sales Header"; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingDescription: Text[50]; PostingDate: Date; VATDate: Date)
    begin
        with SalesInvoiceHeader do begin
            Init;
            TransferFields(SalesHeader);
            "No." := GenJnlLineDocNo;
            "Posting Description" := PostingDescription;
            "Payment Terms Code" := SalesHeader."Prepmt. Payment Terms Code";
            "Posting Date" := PostingDate;
            "Document Date" := PostingDate;
            "VAT Date" := VATDate;
            if "Currency Code" <> '' then
                "Currency Factor" := GetInvCurrFactor(SalesAdvanceLetterHeader."No.");
            "Pre-Assigned No. Series" := '';
            "Source Code" := SrcCode;
            "User ID" := UserId;
            "No. Printed" := 0;
            "Prices Including VAT" := true;
            "Prepayment Invoice" := true;
            "External Document No." := SalesAdvanceLetterHeader."External Document No.";
            "Your Reference" := SalesAdvanceLetterHeader."Your Reference";
            "Language Code" := SalesAdvanceLetterHeader."Language Code";
            "Registration No." := SalesAdvanceLetterHeader."Registration No.";
            "Tax Registration No." := SalesAdvanceLetterHeader."Tax Registration No.";
            if SalesAdvanceLetterHeader."Order No." <> '' then
                "Prepayment Order No." := SalesHeader."No.";
            "Letter No." := SalesAdvanceLetterHeader."No.";
            Insert;
        end;
    end;

    local procedure PostLetter_SetInvLine(var SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvoiceHeader: Record "Sales Invoice Header"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; LineAmount: Decimal)
    begin
        with SalesInvoiceLine do begin
            Init;
            "Document No." := SalesInvoiceHeader."No.";
            "Line No." := PrepaymentInvLineBuffer."Line No.";
            "Posting Date" := SalesInvoiceHeader."Posting Date";
            "Sell-to Customer No." := SalesInvoiceHeader."Sell-to Customer No.";
            "Bill-to Customer No." := SalesInvoiceHeader."Bill-to Customer No.";
            Type := Type::"G/L Account";
            "No." := PrepaymentInvLineBuffer."G/L Account No.";
            "Shortcut Dimension 1 Code" := PrepaymentInvLineBuffer."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PrepaymentInvLineBuffer."Global Dimension 2 Code";
            "Dimension Set ID" := PrepaymentInvLineBuffer."Dimension Set ID";
            Description := PrepaymentInvLineBuffer.Description;
            Quantity := 1;
            "Unit Price" := LineAmount;
            "Line Amount" := LineAmount;
            Amount := LineAmount;
            "Amount Including VAT" := LineAmount;
            "VAT Base Amount" := PrepaymentInvLineBuffer."VAT Base Amount";
            "Gen. Bus. Posting Group" := PrepaymentInvLineBuffer."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := PrepaymentInvLineBuffer."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := PrepaymentInvLineBuffer."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := PrepaymentInvLineBuffer."VAT Prod. Posting Group";
            "VAT %" := PrepaymentInvLineBuffer."VAT %";
            "VAT Calculation Type" := PrepaymentInvLineBuffer."VAT Calculation Type";
            "VAT Identifier" := PrepaymentInvLineBuffer."VAT Identifier";
            Insert;
        end;
    end;

    local procedure PostLetter_SetCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingDescription: Text[50])
    begin
        with SalesCrMemoHeader do begin
            Init;
            SalesInvoiceHeader."Bank Account Code" := '';
            TransferFields(SalesInvoiceHeader);
            "No." := GenJnlLineDocNo;
            "Payment Discount %" := 0;
            "Pmt. Discount Date" := 0D;
            "Posting Description" := PostingDescription;
            Correction := GLSetup."Mark Cr. Memos as Corrections";
            "No." := GenJnlLineDocNo;
            "Pre-Assigned No. Series" := '';
            "Source Code" := SrcCode;
            "User ID" := UserId;
            "No. Printed" := 0;
            "Prepayment Credit Memo" := true;
            "Letter No." := SalesAdvanceLetterHeader."No.";
            "Reason Code" := SalesAdvanceLetterHeader."Reason Code";
            "Credit Memo Type" := "Credit Memo Type"::"Corrective Tax Document";
            "Posting Date" := SalesAdvanceLetterHeader."Document Date";
            "Document Date" := "Posting Date";
            "VAT Date" := SalesAdvanceLetterHeader."VAT Date";
            IF "VAT Date" = 0D THEN
                "VAT Date" := "Posting Date";
            Insert;
        end;
    end;

    local procedure PostLetter_SetCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry"; SalesAdvanceLetterHeaderNo: Code[20]; SalesInvHeaderNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesAdvanceLetterEntry.Reset();
        SalesAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type", "Posting Date");
        SalesAdvanceLetterEntry.SetRange("Letter No.", SalesAdvanceLetterHeaderNo);
        SalesAdvanceLetterEntry.SetRange("Letter Line No.", PrepaymentInvLineBuffer."Line No.");
        SalesAdvanceLetterEntry.SetRange("Entry Type", SalesAdvanceLetterEntry."Entry Type"::VAT);
        SalesAdvanceLetterEntry.SetRange("Document Type", SalesAdvanceLetterEntry."Document Type"::Invoice);
        SalesAdvanceLetterEntry.SetRange("Document No.", SalesInvHeaderNo);
        SalesAdvanceLetterEntry.FindFirst;
        SalesInvoiceLine.Get(SalesAdvanceLetterEntry."Document No.", SalesAdvanceLetterEntry."Sale Line No.");
        SalesCrMemoLine.Init();
        SalesCrMemoLine.TransferFields(SalesInvoiceLine);
        SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
        SalesCrMemoLine.Insert();
    end;

    local procedure PostLetter_PostToGL(var GenJournalLine: Record "Gen. Journal Line"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocNo: Code[20]; GenJnlLineDocType: Integer; PostingDescription: Text[50]; SrcCode: Code[10]; PostingDate: Date; VATDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with GenJournalLine do begin
            Init;
            "Advance Letter No." := SalesAdvanceLetterHeader."No.";
            "Advance Letter Line No." := PrepaymentInvLineBuffer."Line No.";
            "Posting Date" := PostingDate;
            "VAT Date" := VATDate;
            "Document Date" := "Posting Date";
            Description := PostingDescription;
            Prepayment := true;
            "Prepayment Type" := "Prepayment Type"::Advance;
            "VAT Calculation Type" := "VAT Calculation Type"::"Full VAT";
            "Document Type" := GenJnlLineDocType;
            "Document No." := GenJnlLineDocNo;
            "Account Type" := "Account Type"::"G/L Account";
            "Account No." := PrepaymentInvLineBuffer."G/L Account No.";
            "System-Created Entry" := true;
            Validate("Currency Code", SalesAdvanceLetterHeader."Currency Code");
            if DocumentType = DocumentType::Invoice then begin
                if "Currency Code" = '' then begin
                    Validate(Amount, PrepaymentInvLineBuffer."VAT Amount");
                    "Advance VAT Base Amount" := PrepaymentInvLineBuffer."VAT Base Amount";
                end else begin
                    Validate(Amount, PrepaymentInvLineBuffer."VAT Amount");
                    if PrepaymentInvLineBuffer."VAT Amount (LCY)" <> 0 then
                        Validate("Amount (LCY)", PrepaymentInvLineBuffer."VAT Amount (LCY)");
                    "Advance VAT Base Amount" := PrepaymentInvLineBuffer."VAT Base Amount (LCY)";
                end;
                "Source Currency Code" := "Currency Code";
                "Source Currency Amount" := PrepaymentInvLineBuffer."VAT Amount (ACY)";
            end;
            if DocumentType = DocumentType::"Credit Memo" then begin
                "Currency Factor" := SalesInvHeaderBuf."Currency Factor";
                Validate(Amount, -SalesAdvanceLetterEntry."VAT Amount");
                "Amount (LCY)" := -SalesAdvanceLetterEntry."VAT Amount (LCY)";
                "VAT Amount (LCY)" := -SalesAdvanceLetterEntry."VAT Amount (LCY)";
                "Advance VAT Base Amount" := -SalesAdvanceLetterEntry."VAT Base Amount (LCY)";
                "Source Currency Code" := SalesAdvanceLetterEntry."Currency Code";
                "Source Currency Amount" := -SalesAdvanceLetterEntry.Amount;
                "Reason Code" := SalesAdvanceLetterHeader."Reason Code";
            end;
            if DocumentType = DocumentType::"Credit Memo" then
                Correction := GLSetup."Mark Cr. Memos as Corrections";
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := PrepaymentInvLineBuffer."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := PrepaymentInvLineBuffer."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := PrepaymentInvLineBuffer."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := PrepaymentInvLineBuffer."VAT Prod. Posting Group";
            if PrepaymentInvLineBuffer."VAT Calculation Type" <>
               PrepaymentInvLineBuffer."VAT Calculation Type"::"Reverse Charge VAT"
            then begin
                VATPostingSetup.Get(PrepaymentInvLineBuffer."VAT Bus. Posting Group", PrepaymentInvLineBuffer."VAT Prod. Posting Group");
                "Bal. Account Type" := "Bal. Account Type"::"G/L Account";
                "Bal. Account No." := VATPostingSetup."Sales Advance Offset VAT Acc.";
            end;
            "Tax Area Code" := PrepaymentInvLineBuffer."Tax Area Code";
            "Tax Liable" := PrepaymentInvLineBuffer."Tax Liable";
            "Tax Group Code" := PrepaymentInvLineBuffer."Tax Group Code";
            "VAT Difference" := PrepaymentInvLineBuffer."VAT Difference";
            "VAT Posting" := "VAT Posting"::"Automatic VAT Entry";
            "Shortcut Dimension 1 Code" := PrepaymentInvLineBuffer."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PrepaymentInvLineBuffer."Global Dimension 2 Code";
            "Dimension Set ID" := PrepaymentInvLineBuffer."Dimension Set ID";
            "Job No." := PrepaymentInvLineBuffer."Job No.";
            "Source Code" := SrcCode;
            "Bill-to/Pay-to No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
            "Country/Region Code" := SalesAdvanceLetterHeader."VAT Country/Region Code";
            if SalesAdvanceLetterHeader."Perform. Country/Region Code" <> '' then begin
                "Perform. Country/Region Code" := SalesAdvanceLetterHeader."Perform. Country/Region Code";
                "Currency Code VAT" := "Currency Code";
                "Currency Factor VAT" := "Currency Factor";
            end;
            "VAT Registration No." := SalesAdvanceLetterHeader."VAT Registration No.";
            "Source Type" := "Source Type"::Customer;
            "Source No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
            "External Document No." := SalesAdvanceLetterHeader."External Document No.";
        end;
    end;

    local procedure PostLetter_UpdtAdvLines(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocType: Integer; GenJnlLineDocNo: Code[20]; LineAmount: Decimal; PostingDate: Date)
    var
        AdvanceLink: Record "Advance Link";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);

        if DocumentType = DocumentType::Invoice then begin
            AdvanceLink.FindLast;
            SalesAdvanceLetterLine.TestField("Amount To Invoice", AdvanceLink.Amount);
        end else begin
            AdvanceLink.SetRange("Invoice No.", CurrSalesInvHeader."No.");
            AdvanceLink.FindFirst;
        end;
        CustLedgerEntry.Get(AdvanceLink."CV Ledger Entry No.");
        if DocumentType = DocumentType::Invoice then begin
            LineAmount := SalesAdvanceLetterLine."Amount To Invoice";
            SalesAdvanceLetterLine."Amount Invoiced" := SalesAdvanceLetterLine."Amount Invoiced" + LineAmount;
            SalesAdvanceLetterLine."Amount To Deduct" := SalesAdvanceLetterLine."Amount To Deduct" + LineAmount;
            SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" - LineAmount;
        end else begin
            LineAmount := GetInvoiceLineAmount(CurrSalesInvHeader."No.", SalesAdvanceLetterLine."Line No.");
            SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" + LineAmount;
            SalesAdvanceLetterLine."Amount To Deduct" := SalesAdvanceLetterLine."Amount To Deduct" - LineAmount;
            SalesAdvanceLetterLine."Amount Invoiced" := SalesAdvanceLetterLine."Amount Invoiced" - LineAmount;
        end;
        SalesAdvanceLetterLine.SuspendStatusCheck(true);
        SalesAdvanceLetterLine.Modify(true);

        if DocumentType = DocumentType::"Credit Memo" then
            UpdateInvoicedLinks(SalesAdvanceLetterLine, GenJnlLineDocType, CurrSalesInvHeader."No.")
        else
            UpdateInvoicedLinks(SalesAdvanceLetterLine, GenJnlLineDocType, GenJnlLineDocNo);

        UpdInvAmountToLineRelations(SalesAdvanceLetterLine);

        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := GenJnlLineDocNo;
        SalesInvoiceHeader."Posting Date" := PostingDate;
        SalesInvoiceHeader."Currency Code" := CustLedgerEntry."Currency Code";

        CreateAdvanceEntry(SalesAdvanceLetterHeader, SalesAdvanceLetterLine, SalesInvoiceHeader, 0, CustLedgerEntry, 0);
    end;

    [Scope('OnPrem')]
    procedure PostInvoiceCorrection(var SalesHeader2: Record "Sales Header"; SalesInvHeader: Record "Sales Invoice Header"; var SalesLine: Record "Sales Line"; var GenJnlPostLine2: Codeunit "Gen. Jnl.-Post Line"; var InvoicedAmount: Decimal)
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempSalesAdvanceLetterHeader2: Record "Sales Advance Letter Header" temporary;
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        DocNoForVATCorr: Code[20];
    begin
        GenJnlPostLine := GenJnlPostLine2;
        SalesHeader := SalesHeader2;
        SetCurrencyPrecision(SalesHeader."Currency Code");
        GLSetup.Get();
        SalesSetup.Get();
        TempCustLedgEntry.DeleteAll();

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Qty. to Invoice", '<>0');
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                begin
                    SalesLine.SetFilter("Prepmt Amt to Deduct", '<>0');
                    if SalesLine.FindSet(true) then
                        repeat
                            PostInvLineCorrection(
                              SalesLine, SalesInvHeader, TempCustLedgEntry, DocNoForVATCorr,
                              InvoicedAmount, TempSalesAdvanceLetterHeader2);
                        until SalesLine.Next = 0;
                    with SalesHeader do begin
                        SalesLine.Reset();
                        SalesLine.SetRange("Document Type", "Document Type");
                        SalesLine.SetRange("Document No.", "No.");
                        SalesLine.SetFilter("Prepmt. Line Amount", '<>0');
                        if SalesLine.FindSet(true) then
                            repeat
                                UpdateOrderLine(SalesLine, "Prices Including VAT", false);
                                SalesLine.Modify();
                            until SalesLine.Next = 0;
                    end;
                end;
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesLine.SetFilter("Prepmt Amt to Deduct", '<>0');
                    if SalesLine.FindSet(true) then
                        repeat
                            PostInvLineCorrection(
                              SalesLine, SalesInvHeader, TempCustLedgEntry, DocNoForVATCorr,
                              InvoicedAmount, TempSalesAdvanceLetterHeader2);
                        until SalesLine.Next = 0;
                end;
        end;
        PostPaymentCorrection(SalesInvHeader, TempCustLedgEntry);

        if TempSalesAdvanceLetterHeader2.FindSet then
            repeat
                SalesAdvanceLetterHeader.Get(TempSalesAdvanceLetterHeader2."No.");
                SalesAdvanceLetterHeader.UpdateClosing(true);
            until TempSalesAdvanceLetterHeader2.Next = 0;
        SalesHeader2 := SalesHeader;
        GenJnlPostLine2 := GenJnlPostLine;
    end;

    local procedure PostInvLineCorrection(SalesLine: Record "Sales Line"; SalesInvHeader: Record "Sales Invoice Header"; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary; var DocNoForVATCorr: Code[20]; var InvoicedAmount: Decimal; var TempSalesAdvanceLetterHeader2: Record "Sales Advance Letter Header" temporary)
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        AdvanceLink: Record "Advance Link";
        AdvanceLink2: Record "Advance Link";
        AmountToDeduct: Decimal;
        VATAmount: Decimal;
        LastLetterNo: Code[20];
        EntryPos: Integer;
        EntryCount: Integer;
        i: Integer;
        ToDeductFact: Decimal;
    begin
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Document Type", SalesLine."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", SalesLine."Document No.");
        AdvanceLetterLineRelation.SetRange("Document Line No.", SalesLine."Line No.");
        AdvanceLetterLineRelation.SetFilter("Amount To Deduct", '<>0');
        if AdvanceLetterLineRelation.FindSet(true) then
            repeat
                AmountToDeduct := AdvanceLetterLineRelation."Amount To Deduct";
                SalesAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                if AmountToDeduct <> 0 then begin
                    InvoicedAmount := InvoicedAmount + AmountToDeduct;

                    SalesAdvanceLetterLine."Amount To Deduct" := SalesAdvanceLetterLine."Amount To Deduct" - AmountToDeduct;
                    SalesAdvanceLetterLine."Amount Deducted" := SalesAdvanceLetterLine."Amount Deducted" + AmountToDeduct;
                    SalesAdvanceLetterLine.SuspendStatusCheck(true);
                    SalesAdvanceLetterLine.Modify(true);
                    if not TempSalesAdvanceLetterHeader2.Get(SalesAdvanceLetterLine."Letter No.") then begin
                        SalesAdvanceLetterHeader.Get(SalesAdvanceLetterLine."Letter No.");
                        TempSalesAdvanceLetterHeader2 := SalesAdvanceLetterHeader;
                        TempSalesAdvanceLetterHeader2.Insert();
                    end;

                    TempSalesAdvanceLetterHeader2.TestField("Perform. Country/Region Code", SalesInvHeader."Perform. Country/Region Code");
                    TempSalesAdvanceLetterHeader2.TestField("VAT Country/Region Code", SalesInvHeader."VAT Country/Region Code");

                    AdvanceLetterLineRelation."Deducted Amount" := AdvanceLetterLineRelation."Deducted Amount" + AmountToDeduct;
                    AdvanceLetterLineRelation.Modify();

                    TempCustLedgEntryGre.Reset();
                    TempCustLedgEntryGre.DeleteAll();
                    Clear(TempCustLedgEntryGre);
                    CalcLinkedPmtAmountToApply(SalesAdvanceLetterLine, AmountToDeduct, TempCustLedgEntry, TempCustLedgEntryGre);

                    if TempCustLedgEntryGre.Find('-') then begin
                        repeat
                            CreateAdvanceEntry(TempSalesAdvanceLetterHeader2, SalesAdvanceLetterLine, SalesInvHeader, SalesLine."Line No.",
                              TempCustLedgEntryGre, TempCustLedgEntryGre."Amount to Apply");
                        until TempCustLedgEntryGre.Next = 0;
                    end;

                    TotBaseToDeduct := 0;
                    TotVATAmtToDeduct := 0;
                    TotBaseToDeductLCY := 0;
                    TotVATAmtToDeductLCY := 0;
                    EntryPos := 0;

                    EntryCount := TempCustLedgEntryGre.Count();

                    for i := 1 to 2 do begin
                        if TempCustLedgEntryGre.FindSet then
                            repeat
                                AdvanceLink.Reset();
                                AdvanceLink.SetCurrentKey("CV Ledger Entry No.", "Entry Type", "Document No.", "Line No.");
                                AdvanceLink.SetRange("CV Ledger Entry No.", TempCustLedgEntryGre."Entry No.");
                                AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                                AdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
                                AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
                                AdvanceLink.CalcSums(Amount, "Remaining Amount to Deduct");
                                if AdvanceLink."Remaining Amount to Deduct" <> 0 then
                                    ToDeductFact := TempCustLedgEntryGre."Amount to Apply" /
                                      (AdvanceLink."Remaining Amount to Deduct" + TempCustLedgEntryGre."Amount to Apply")
                                else
                                    ToDeductFact := 0;

                                if (AdvanceLink."Remaining Amount to Deduct" = 0) = (i = 1) then begin
                                    EntryPos := EntryPos + 1;
                                    VATAmount := 0;

                                    AdvanceLink2.Reset();
                                    AdvanceLink2.SetCurrentKey("CV Ledger Entry No.", "Entry Type", "Document No.", "Line No.");
                                    AdvanceLink2.SetRange("CV Ledger Entry No.", TempCustLedgEntryGre."Entry No.");
                                    AdvanceLink2.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                                    AdvanceLink2.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
                                    AdvanceLink2.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
                                    AdvanceLink2.FindLast;

                                    PostVATCorrection(
                                      SalesAdvanceLetterLine, SalesInvHeader, DocNoForVATCorr, VATAmount, AdvanceLetterLineRelation,
                                      TempCustLedgEntryGre."Entry No.", i = 1, EntryPos = EntryCount, ToDeductFact, SalesLine);

                                    AddPrepmtSalesInvLine(SalesAdvanceLetterLine, SalesInvHeader, TempCustLedgEntryGre."Amount to Apply",
                                      VATAmount, LastLetterNo, AdvanceLink2."Invoice No.");
                                end;
                            until TempCustLedgEntryGre.Next = 0;
                    end;
                end;
            until AdvanceLetterLineRelation.Next = 0;

        SaveDeductionEntries;
    end;

    local procedure PostVATCorrection(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; SalesInvHeader: Record "Sales Invoice Header"; var DocumentNo: Code[20]; var VATAmount: Decimal; var AdvanceLetterLineRelation: Record "Advance Letter Line Relation"; LinkedEntryNo: Integer; UseAllLinkedEntry: Boolean; LastLinkedEntry: Boolean; NewDeductFactor: Decimal; SalesLine: Record "Sales Line")
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCYDif: Decimal;
        VATAmountLCYDif: Decimal;
    begin
        SalesAdvanceLetterHeader.Get(SalesAdvanceLetterLine."Letter No.");
        if DocumentNo = '' then
            if GLSetup."Use Adv. CM Nos for Adv. Corr." then begin
                SalesAdvanceLetterHeader.Get(SalesAdvanceLetterLine."Letter No.");
                DocumentNo := GetCrMemoDocNo(SalesAdvanceLetterHeader, SalesInvHeader."Posting Date");
            end else
                DocumentNo := SalesInvHeader."No.";

        // Calc VAT Amount to Deduct
        CalcVATToDeduct(SalesAdvanceLetterLine, BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY, LinkedEntryNo);
        SetCurrencyPrecision(SalesAdvanceLetterLine."Currency Code");

        if UseAllLinkedEntry then begin
            BaseToDeduct := -BaseToDeduct;
            VATAmtToDeduct := -VATAmtToDeduct;

            if SalesInvHeader."Currency Code" = '' then begin
                BaseToDeductLCY := BaseToDeduct;
                VATAmountLCY := VATAmtToDeduct;
            end else begin
                BaseToDeductLCY := -BaseToDeductLCY;
                VATAmountLCY := -VATAmountLCY;
                if SalesLine."VAT %" = SalesAdvanceLetterLine."VAT %" then begin
                    BaseToDeductLCYDif := BaseToDeductLCY;
                    VATAmountLCYDif := VATAmountLCY;
                    BaseToDeductLCY := Round(BaseToDeduct / SalesInvHeader."Currency Factor");
                    VATAmountLCY := Round(VATAmtToDeduct / SalesInvHeader."Currency Factor");
                    BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                    VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
                end;
            end;
        end else
            if LastLinkedEntry and ((AdvanceLetterLineRelation."VAT Doc. VAT Base" <> 0) or
                                    (AdvanceLetterLineRelation."VAT Doc. VAT Amount" <> 0))
            then begin
                BaseToDeduct := -(AdvanceLetterLineRelation."VAT Doc. VAT Base" + TotBaseToDeduct);
                VATAmtToDeduct := -(AdvanceLetterLineRelation."VAT Doc. VAT Amount" + TotVATAmtToDeduct);
                if SalesInvHeader."Currency Code" = '' then begin
                    BaseToDeductLCY := BaseToDeduct;
                    VATAmountLCY := VATAmtToDeduct;
                end else begin
                    BaseToDeductLCY := -(AdvanceLetterLineRelation."VAT Doc. VAT Base (LCY)" + TotBaseToDeductLCY);
                    VATAmountLCY := -(AdvanceLetterLineRelation."VAT Doc. VAT Amount (LCY)" + TotVATAmtToDeductLCY);
                    if SalesLine."VAT %" = SalesAdvanceLetterLine."VAT %" then begin
                        CustLedgEntry.Get(LinkedEntryNo);
                        BaseToDeductLCYDif := (BaseToDeduct / CustLedgEntry."Original Currency Factor") - BaseToDeductLCY;
                        VATAmountLCYDif := (VATAmtToDeduct / CustLedgEntry."Original Currency Factor") - VATAmountLCY;
                    end;
                end;
            end else begin
                BaseToDeduct := -Round(BaseToDeduct * NewDeductFactor, Currency."Amount Rounding Precision");
                VATAmtToDeduct := -Round(VATAmtToDeduct * NewDeductFactor, Currency."Amount Rounding Precision");
                if SalesAdvanceLetterLine."VAT %" <> 0 then
                    BaseToDeduct := BaseToDeduct +
                      TempCustLedgEntryGre."Amount to Apply" - (BaseToDeduct + VATAmtToDeduct);
                if SalesInvHeader."Currency Code" = '' then begin
                    BaseToDeductLCY := BaseToDeduct;
                    VATAmountLCY := VATAmtToDeduct;
                end else begin
                    BaseToDeductLCY := -Round(BaseToDeductLCY * NewDeductFactor);
                    VATAmountLCY := -Round(VATAmountLCY * NewDeductFactor);
                    if SalesLine."VAT %" = SalesAdvanceLetterLine."VAT %" then begin
                        BaseToDeductLCYDif := BaseToDeductLCY;
                        VATAmountLCYDif := VATAmountLCY;
                        BaseToDeductLCY := Round(BaseToDeduct / SalesInvHeader."Currency Factor");
                        VATAmountLCY := Round(VATAmtToDeduct / SalesInvHeader."Currency Factor");
                        BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                        VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
                    end;
                end;
            end;

        TotBaseToDeduct += BaseToDeduct;
        TotVATAmtToDeduct += VATAmtToDeduct;
        TotBaseToDeductLCY += BaseToDeductLCY;
        TotVATAmtToDeductLCY += VATAmountLCY;

        if SalesAdvanceLetterLine."VAT Calculation Type" =
           SalesAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT"
        then
            VATAmount := 0
        else
            VATAmount := VATAmtToDeduct;

        if SalesAdvanceLetterHeader."Post Advance VAT Option" = SalesAdvanceLetterHeader."Post Advance VAT Option"::Never then
            exit;

        PostVATCorrectionToGL(SalesAdvanceLetterLine, SalesInvHeader, DocumentNo, LinkedEntryNo, BaseToDeductLCY, VATAmountLCYDif,
          BaseToDeductLCYDif, VATAmountLCY, VATAmtToDeduct, BaseToDeduct);
    end;

    local procedure PostVATCorrectionToGL(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; SalesInvoiceHeader: Record "Sales Invoice Header"; DocumentNo: Code[20]; LinkedEntryNo: Integer; BaseToDeductLCY: Decimal; VATAmountLCYDif: Decimal; BaseToDeductLCYDif: Decimal; VATAmountLCY: Decimal; VATAmtToDeduct: Decimal; BaseToDeduct: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        TempSalesAdvanceLetterEntry."VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
        TempSalesAdvanceLetterEntry."Customer Entry No." := LinkedEntryNo;
        TempSalesAdvanceLetterEntry."Letter No." := SalesAdvanceLetterLine."Letter No.";
        TempSalesAdvanceLetterEntry."Letter Line No." := SalesAdvanceLetterLine."Line No.";

        // Post VAT Correction
        PrepareInvJnlLine(GenJournalLine, SalesAdvanceLetterLine, SalesInvoiceHeader);
        SourceCodeSetup.Get();
        GenJournalLine."Source Code" := SourceCodeSetup."Sales Entry Application";
        GenJournalLine."Document No." := DocumentNo;
        SetPostingGroups(GenJournalLine, SalesAdvanceLetterLine, false);
        GenJournalLine."Account No." := SalesAdvanceLetterLine."No.";
        GenJournalLine."Advance VAT Base Amount" := BaseToDeductLCY;
        GenJournalLine."Advance Exch. Rate Difference" := VATAmountLCYDif;
        GenJournalLine.Validate(Amount, VATAmountLCY);
        GenJournalLine.Validate("Source Currency Amount", CalcAmtLCYToACY(GenJournalLine."Posting Date", GenJournalLine.Amount));
        GenJournalLine."Shortcut Dimension 1 Code" := SalesInvoiceHeader."Shortcut Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := SalesInvoiceHeader."Shortcut Dimension 2 Code";
        GenJournalLine."Dimension Set ID" := SalesInvoiceHeader."Dimension Set ID";

        OnBeforePostVATCorrectionToGL(GenJournalLine, SalesAdvanceLetterLine);
        if BaseToDeductLCY <> 0 then
            GenJnlPostLine.RunWithCheck(GenJournalLine);

        if BaseToDeductLCY <> 0 then begin
            SalesAdvanceLetterEntryNo += 1;
            TempSalesAdvanceLetterEntry."Entry No." := SalesAdvanceLetterEntryNo;
            TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::"VAT Deduction";
            TempSalesAdvanceLetterEntry."Deduction Line No." := 0;
            TempSalesAdvanceLetterEntry.Amount := 0;
            TempSalesAdvanceLetterEntry.Insert();
            FillVATFieldsOfDeductionEntry(SalesAdvanceLetterLine."VAT %");
            TempSalesAdvanceLetterEntry."VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
            TempSalesAdvanceLetterEntry."VAT Base Amount" := BaseToDeduct;
            TempSalesAdvanceLetterEntry."VAT Amount" := VATAmtToDeduct;
            TempSalesAdvanceLetterEntry.Modify();
        end;

        // VAT Offset Account
        if SalesAdvanceLetterLine."VAT Calculation Type" <>
           SalesAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT"
        then begin
            VATPostingSetup.Get(SalesAdvanceLetterLine."VAT Bus. Posting Group", SalesAdvanceLetterLine."VAT Prod. Posting Group");
            VATPostingSetup.TestField("Sales Advance Offset VAT Acc.");
            GenJournalLine."Account No." := VATPostingSetup."Sales Advance Offset VAT Acc.";
            GenJournalLine."Advance VAT Base Amount" := 0;
            SetPostingGroups(GenJournalLine, SalesAdvanceLetterLine, true);
            GenJournalLine.Validate(Amount, -VATAmountLCY);
            GenJournalLine.Validate("Source Currency Amount", CalcAmtLCYToACY(GenJournalLine."Posting Date", GenJournalLine.Amount));
            GenJournalLine."Shortcut Dimension 1 Code" := SalesInvoiceHeader."Shortcut Dimension 1 Code";
            GenJournalLine."Shortcut Dimension 2 Code" := SalesInvoiceHeader."Shortcut Dimension 2 Code";
            GenJournalLine."Dimension Set ID" := SalesInvoiceHeader."Dimension Set ID";
            if BaseToDeductLCY <> 0 then
                GenJnlPostLine.RunWithCheck(GenJournalLine);
        end;

        // Gain/Loss
        if GenJournalLine."Advance Exch. Rate Difference" <> 0 then begin
            if SalesAdvanceLetterLine."VAT Calculation Type" <>
               SalesAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT"
            then begin
                if GenJournalLine."Advance Exch. Rate Difference" > 0 then begin
                    Currency.TestField("Realized Losses Acc.");
                    GenJournalLine."Account No." := Currency."Realized Losses Acc."
                end else begin
                    Currency.TestField("Realized Gains Acc.");
                    GenJournalLine."Account No." := Currency."Realized Gains Acc.";
                end;
                GenJournalLine.Validate(Amount, GenJournalLine."Advance Exch. Rate Difference");
                GenJournalLine.Validate("Source Currency Amount", CalcAmtLCYToACY(GenJournalLine."Posting Date", GenJournalLine.Amount));
                GenJournalLine."Shortcut Dimension 1 Code" := SalesInvoiceHeader."Shortcut Dimension 1 Code";
                GenJournalLine."Shortcut Dimension 2 Code" := SalesInvoiceHeader."Shortcut Dimension 2 Code";
                GenJournalLine."Dimension Set ID" := SalesInvoiceHeader."Dimension Set ID";
                GenJnlPostLine.RunWithCheck(GenJournalLine);

                VATPostingSetup.Get(SalesAdvanceLetterLine."VAT Bus. Posting Group", SalesAdvanceLetterLine."VAT Prod. Posting Group");
                VATPostingSetup.TestField("Sales Advance Offset VAT Acc.");
                GenJournalLine."Account No." := VATPostingSetup."Sales Advance Offset VAT Acc.";
                GenJournalLine.Validate(Amount, -GenJournalLine."Advance Exch. Rate Difference");
                GenJournalLine."Shortcut Dimension 1 Code" := SalesInvoiceHeader."Shortcut Dimension 1 Code";
                GenJournalLine."Shortcut Dimension 2 Code" := SalesInvoiceHeader."Shortcut Dimension 2 Code";
                GenJournalLine."Dimension Set ID" := SalesInvoiceHeader."Dimension Set ID";
                GenJnlPostLine.RunWithCheck(GenJournalLine);
            end;

            SalesAdvanceLetterEntryNo += 1;
            TempSalesAdvanceLetterEntry."Entry No." := SalesAdvanceLetterEntryNo;
            TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::"VAT Rate";
            TempSalesAdvanceLetterEntry.Amount := 0;
            TempSalesAdvanceLetterEntry."VAT Base Amount" := 0;
            TempSalesAdvanceLetterEntry."VAT Amount" := 0;
            TempSalesAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCYDif;
            TempSalesAdvanceLetterEntry."VAT Amount (LCY)" := VATAmountLCYDif;
            TempSalesAdvanceLetterEntry.Insert();
        end;

        if (SalesAdvanceLetterLine."VAT Calculation Type" = SalesAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT") and
           (BaseToDeductLCYDif <> 0)
        then begin
            SalesAdvanceLetterEntryNo += 1;
            TempSalesAdvanceLetterEntry."Entry No." := SalesAdvanceLetterEntryNo;
            TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::"VAT Rate";
            TempSalesAdvanceLetterEntry.Amount := 0;
            TempSalesAdvanceLetterEntry."VAT Base Amount" := 0;
            TempSalesAdvanceLetterEntry."VAT Amount" := 0;
            TempSalesAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCYDif;
            TempSalesAdvanceLetterEntry."VAT Amount (LCY)" := 0;
            TempSalesAdvanceLetterEntry.Insert();
        end;
    end;

    local procedure AddPrepmtSalesInvLine(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; SalesInvHeader: Record "Sales Invoice Header"; AmountInclVAT: Decimal; VATAmount: Decimal; var LastLetterNo: Code[20]; VATDocLetterNo: Code[20]): Boolean
    var
        SalesInvLine: Record "Sales Invoice Line";
        NextLineNo: Integer;
    begin
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if not SalesInvLine.FindLast then
            exit(false);

        NextLineNo := SalesInvLine."Line No.";
        if LastLetterNo <> SalesAdvanceLetterLine."Letter No." then begin
            AddAdvanceLetterInfo(SalesAdvanceLetterLine, SalesInvHeader."No.", NextLineNo);
            LastLetterNo := SalesAdvanceLetterLine."Letter No.";
        end;

        NextLineNo := NextLineNo + 10000;
        SalesInvLine.Init();
        SalesInvLine."Line No." := NextLineNo;
        SalesInvLine."Prepayment Line" := true;
        SalesInvLine."Sell-to Customer No." := SalesInvHeader."Sell-to Customer No.";
        SalesInvLine."Bill-to Customer No." := SalesInvHeader."Bill-to Customer No.";
        SalesInvLine.Type := SalesInvLine.Type::"G/L Account";
        SalesInvLine."No." := SalesAdvanceLetterLine."Advance G/L Account No.";
        SalesInvLine.Description := SalesAdvanceLetterLine.Description;
        SalesInvLine."VAT %" := SalesAdvanceLetterLine."VAT %";
        SalesInvLine."VAT Calculation Type" := SalesAdvanceLetterLine."VAT Calculation Type"::"Full VAT";
        SalesInvLine."VAT Bus. Posting Group" := SalesAdvanceLetterLine."VAT Bus. Posting Group";
        SalesInvLine."VAT Prod. Posting Group" := SalesAdvanceLetterLine."VAT Prod. Posting Group";
        SalesInvLine."VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
        SalesInvLine.Quantity := -1;
        SalesInvLine."VAT Base Amount" := VATAmount - AmountInclVAT;
        SalesInvLine.Amount := SalesInvLine."VAT Base Amount";
        if SalesInvHeader."Prices Including VAT" then begin
            SalesInvLine."Unit Price" := AmountInclVAT;
            SalesInvLine."Line Amount" := -AmountInclVAT;
        end else begin
            SalesInvLine."Unit Price" := -SalesInvLine."VAT Base Amount";
            SalesInvLine."Line Amount" := SalesInvLine."VAT Base Amount";
        end;
        SalesInvLine."Amount Including VAT" := -AmountInclVAT;

        SalesInvLine."Letter No." := SalesAdvanceLetterLine."Letter No.";
        SalesInvLine."VAT Doc. Letter No." := VATDocLetterNo;

        // VAT base amount on the line must be zero if there is not exist a tax document for the Sales Advance Letter
        if SalesInvLine."Prepayment Line" and (SalesInvLine."VAT Doc. Letter No." = '') then
            SalesInvLine."VAT Base Amount" := 0;

        SalesInvLine.Insert();

        FillDeductionLineNo(SalesInvLine."Line No.");
    end;

    local procedure AddAdvanceLetterInfo(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; DocumentNo: Code[20]; var NextLineNo: Integer)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
    begin
        NextLineNo := NextLineNo + 10000;
        SalesInvLine.Init();
        SalesInvLine."Document No." := DocumentNo;
        SalesInvLine."Line No." := NextLineNo;
        SalesInvLine."Prepayment Line" := true;
        SalesInvLine.Description := StrSubstNo(Text009Msg, SalesAdvanceLetterLine."Letter No.");
        SalesInvLine.Insert();

        SalesInvHeader.SetRange("Letter No.", SalesAdvanceLetterLine."Letter No.");
        SalesInvHeader.SetRange("Reversed By Cr. Memo No.", '');
        SalesInvHeader.SetRange("Prepayment Invoice", true);
        if SalesInvHeader.FindSet then
            repeat
                NextLineNo := NextLineNo + 10000;

                SalesInvLine.Init();
                SalesInvLine."Line No." := NextLineNo;
                SalesInvLine."Prepayment Line" := true;
                SalesInvLine.Description :=
                  CopyStr(StrSubstNo(Text010Msg, SalesInvHeader."No."), 1, MaxStrLen(SalesInvLine.Description));
                SalesInvLine.Insert();
            until SalesInvHeader.Next = 0;
    end;

    local procedure PreparePmtJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesInvHeader: Record "Sales Invoice Header")
    begin
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := SalesInvHeader."Bill-to Customer No.";
        PrepareGenJnlLine(GenJnlLine, SalesInvHeader);
    end;

    local procedure PrepareInvJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; SalesInvHeader: Record "Sales Invoice Header")
    begin
        GenJnlLine.Init();
        GenJnlLine."Advance Letter No." := SalesAdvanceLetterLine."Letter No.";
        GenJnlLine."Advance Letter Line No." := SalesAdvanceLetterLine."Line No.";
        GenJnlLine.Prepayment := true;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine.Correction := GLSetup."Correction As Storno";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        PrepareGenJnlLine(GenJnlLine, SalesInvHeader);
    end;

    local procedure PrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesInvHeader: Record "Sales Invoice Header")
    begin
        GenJnlLine."Posting Date" := SalesInvHeader."Posting Date";
        GenJnlLine."VAT Date" := SalesInvHeader."VAT Date";
        GenJnlLine."Document Date" := SalesInvHeader."Document Date";
        GenJnlLine."Prepayment Type" := GenJnlLine."Prepayment Type"::Advance;
        GenJnlLine."Reason Code" := SalesInvHeader."Reason Code";
        GenJnlLine."Document No." := SalesInvHeader."No.";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Source Currency Code" := SalesInvHeader."Currency Code";
        GenJnlLine."Source Code" := SalesInvHeader."Source Code";
        GenJnlLine."EU 3-Party Trade" := SalesInvHeader."EU 3-Party Trade";
        GenJnlLine."Bill-to/Pay-to No." := SalesInvHeader."Bill-to Customer No.";
        GenJnlLine."Country/Region Code" := SalesInvHeader."VAT Country/Region Code";
        GenJnlLine."VAT Registration No." := SalesInvHeader."VAT Registration No.";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
        GenJnlLine."Source No." := SalesInvHeader."Bill-to Customer No.";
        GenJnlLine."Posting No. Series" := SalesHeader."Posting No. Series";
        GenJnlLine.Description := SalesInvHeader."Posting Description";
    end;

    local procedure SetPostingGroups(var GenJnlLine: Record "Gen. Journal Line"; SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; Cleanup: Boolean)
    begin
        if Cleanup then begin
            GenJnlLine."VAT Calculation Type" := 0;
            GenJnlLine."Gen. Posting Type" := 0;
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
        end else begin
            GenJnlLine."VAT Calculation Type" := GenJnlLine."VAT Calculation Type"::"Full VAT";
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
            GenJnlLine."Gen. Bus. Posting Group" := SalesAdvanceLetterLine."Gen. Bus. Posting Group";
            GenJnlLine."Gen. Prod. Posting Group" := SalesAdvanceLetterLine."Gen. Prod. Posting Group";
            GenJnlLine."VAT Bus. Posting Group" := SalesAdvanceLetterLine."VAT Bus. Posting Group";
            GenJnlLine."VAT Prod. Posting Group" := SalesAdvanceLetterLine."VAT Prod. Posting Group";
        end;
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Automatic VAT Entry";
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure PostPaymentCorrection(SalesInvHeader: Record "Sales Invoice Header"; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    var
        GenJnlLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        PrepaidAmount: Decimal;
        PrepaidAmountLCY: Decimal;
        InvoiceAmount: Decimal;
    begin
        if TempCustLedgEntry.IsEmpty then
            exit;

        CustLedgEntry.SetRange("Customer No.", SalesInvHeader."Bill-to Customer No.");
        CustLedgEntry.SetRange("Document No.", SalesInvHeader."No.");
        CustLedgEntry.FindFirst;
        CustLedgEntry.CalcFields("Remaining Amount");
        InvoiceAmount := CustLedgEntry."Remaining Amount";

        // Post Advance Refund
        GenJnlLine.Init();
        GenJnlLine.Prepayment := true;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
        PreparePmtJnlLine(GenJnlLine, SalesInvHeader);
        SourceCodeSetup.Get();
        GenJnlLine."Source Code" := SourceCodeSetup."Sales Entry Application";
        if TempCustLedgEntry.FindSet then
            repeat
                if TempCustLedgEntry."Posting Date" > SalesInvHeader."Posting Date" then
                    Error(Text4005240Err);
                if InvoiceAmount < TempCustLedgEntry."Amount to Apply" then
                    TempCustLedgEntry."Amount to Apply" := InvoiceAmount;
                InvoiceAmount := InvoiceAmount - TempCustLedgEntry."Amount to Apply";
                CustLedgEntry2.Get(TempCustLedgEntry."Entry No.");
                CustLedgEntry2."Amount to Apply" := -TempCustLedgEntry."Amount to Apply";

                CustLedgEntry2.CalcFields("Remaining Amount");
                if Abs(CustLedgEntry2."Amount to Apply") > Abs(CustLedgEntry2."Remaining Amount") then
                    CustLedgEntry2.FieldError("Amount to Apply", StrSubstNo(Tex033Err, CustLedgEntry2.FieldCaption("Remaining Amount")));

                CustLedgEntry2.Modify();
                GenJnlLine.Validate("Currency Code", TempCustLedgEntry."Currency Code");
                if TempCustLedgEntry."Currency Code" <> '' then begin
                    CustLedgEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    if CustLedgEntry2."Remaining Amt. (LCY)" <> 0 then
                        GenJnlLine.Validate("Currency Factor", CustLedgEntry2."Remaining Amount" / CustLedgEntry2."Remaining Amt. (LCY)")
                    else
                        GenJnlLine.Validate("Currency Factor", CustLedgEntry2."Adjusted Currency Factor");
                end;
                GenJnlLine.Validate(Amount, TempCustLedgEntry."Amount to Apply");
                PrepaidAmount := PrepaidAmount + GenJnlLine.Amount;
                PrepaidAmountLCY := PrepaidAmountLCY + GenJnlLine."Amount (LCY)";
                GenJnlLine."Applies-to ID" := TempCustLedgEntry."Applies-to ID";
                GenJnlLine."Posting Group" := TempCustLedgEntry."Customer Posting Group";
                GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry2."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry2."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := CustLedgEntry2."Dimension Set ID";
                GenJnlPostLine.RunWithCheck(GenJnlLine);
            until (TempCustLedgEntry.Next = 0) or (InvoiceAmount = 0);

        // Post Payment
        GenJnlLine.Init();
        GenJnlLine.Prepayment := false;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        PreparePmtJnlLine(GenJnlLine, SalesInvHeader);
        if GenJnlLine."Posting Group" <> SalesInvHeader."Customer Posting Group" then
            GenJnlLine.Validate("Posting Group", SalesInvHeader."Customer Posting Group");
        GenJnlLine."Source Code" := SourceCodeSetup."Sales Entry Application";
        GenJnlLine.Validate("Currency Code", SalesInvHeader."Currency Code");
        GenJnlLine.Validate(Amount, -PrepaidAmount);
        if -PrepaidAmountLCY <> 0 then
            GenJnlLine.Validate("Amount (LCY)", -PrepaidAmountLCY);
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
        GenJnlLine."Applies-to Doc. No." := SalesInvHeader."No.";
        GenJnlLine."Shortcut Dimension 1 Code" := SalesInvHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := SalesInvHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := SalesInvHeader."Dimension Set ID";
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CalcLinkedAmount(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        AdvanceLink: Record "Advance Link";
    begin
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);
        if AdvanceLink.FindSet then
            repeat
                if CustLedgEntry.Get(AdvanceLink."CV Ledger Entry No.") then
                    if TempCustLedgEntry.Get(CustLedgEntry."Entry No.") then begin
                        TempCustLedgEntry."Amount to Apply" := TempCustLedgEntry."Amount to Apply" + AdvanceLink.Amount;
                        TempCustLedgEntry."Currency Code" := AdvanceLink."Currency Code";
                        TempCustLedgEntry.Modify();
                    end else begin
                        TempCustLedgEntry := CustLedgEntry;
                        TempCustLedgEntry."Amount to Apply" := AdvanceLink.Amount;
                        TempCustLedgEntry."Currency Code" := AdvanceLink."Currency Code";
                        TempCustLedgEntry.Insert();
                    end;
            until AdvanceLink.Next = 0;
    end;

    local procedure CalcLinkedPmtAmountToApply(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; TotalAmountToApply: Decimal; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary; var CustLedgEntryLink: Record "Cust. Ledger Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        AdvanceLink: Record "Advance Link";
        AmountToApply: Decimal;
    begin
        if TotalAmountToApply = 0 then
            exit;

        SumAmountToApply := SumAmountToApply + TotalAmountToApply;

        SetCurrencyPrecision(SalesAdvanceLetterLine."Currency Code");
        AdvanceLink.SetCurrentKey("Entry Type", "Document No.", "Line No.", "Posting Date");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);

        if AdvanceLink.FindSet then
            repeat
                if CustLedgEntry.Get(AdvanceLink."CV Ledger Entry No.") then begin
                    case true of
                        TotalAmountToApply < AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TotalAmountToApply;
                        TotalAmountToApply = AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TotalAmountToApply;
                        TotalAmountToApply > AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := AdvanceLink."Remaining Amount to Deduct";
                    end;
                    TotalAmountToApply := TotalAmountToApply - AmountToApply;
                    AdvanceLink."Remaining Amount to Deduct" := AdvanceLink."Remaining Amount to Deduct" - AmountToApply;
                    AdvanceLink.Modify();

                    if AmountToApply <> 0 then begin
                        if TempCustLedgEntry.Get(CustLedgEntry."Entry No.") then begin
                            TempCustLedgEntry."Amount to Apply" := TempCustLedgEntry."Amount to Apply" + AmountToApply;
                            TempCustLedgEntry.Modify();
                        end else begin
                            CustLedgEntry."Applies-to ID" := AppPrefTxt + Format(CustLedgEntry."Entry No.");
                            CustLedgEntry.Modify();
                            TempCustLedgEntry := CustLedgEntry;
                            TempCustLedgEntry."Amount to Apply" := AmountToApply;
                            TempCustLedgEntry."Currency Code" := AdvanceLink."Currency Code";
                            TempCustLedgEntry.Insert();
                        end;
                        if CustLedgEntryLink.Get(CustLedgEntry."Entry No.") then begin
                            CustLedgEntryLink."Amount to Apply" := CustLedgEntryLink."Amount to Apply" + AmountToApply;
                            CustLedgEntryLink.Modify();
                        end else begin
                            CustLedgEntryLink := CustLedgEntry;
                            CustLedgEntryLink."Amount to Apply" := AmountToApply;
                            CustLedgEntryLink."Currency Code" := AdvanceLink."Currency Code";
                            CustLedgEntryLink.Insert();
                        end;
                    end;
                end;
            until (AdvanceLink.Next = 0) or (TotalAmountToApply = 0);
    end;

    local procedure CalcPostingDate(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; var PostingDate: Date)
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        AdvanceLink: Record "Advance Link";
    begin
        PostingDate := 0D;
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        SalesAdvanceLetterLine.SetFilter("Amount To Invoice", '<>0');
        if SalesAdvanceLetterLine.FindSet then
            repeat
                AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
                AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                AdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
                AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
                AdvanceLink.SetFilter("Invoice No.", '=%1', '');
                AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);
                if AdvanceLink.FindSet then
                    repeat
                        if PostingDate < AdvanceLink."Posting Date" then
                            PostingDate := AdvanceLink."Posting Date";
                    until AdvanceLink.Next = 0;
            until SalesAdvanceLetterLine.Next = 0;
    end;

    local procedure UpdateInvoicedLinks(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; InvoiceNo: Code[20])
    var
        AdvanceLink: Record "Advance Link";
    begin
        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);

        case DocumentType of
            DocumentType::Invoice:
                begin
                    AdvanceLink.SetRange("Invoice No.", '');
                    AdvanceLink.SetRange("Transfer Date", 0D);
                    if InvoiceNo <> '' then
                        AdvanceLink.ModifyAll("Invoice No.", InvoiceNo)
                    else
                        AdvanceLink.ModifyAll("Transfer Date", WorkDate);
                end;
            DocumentType::"Credit Memo":
                if InvoiceNo <> '' then begin
                    AdvanceLink.SetRange("Invoice No.", InvoiceNo);
                    AdvanceLink.SetRange("Transfer Date", 0D);
                    AdvanceLink.ModifyAll("Invoice No.", '');
                end else begin
                    AdvanceLink.SetRange("Invoice No.", '');
                    AdvanceLink.SetFilter("Transfer Date", '<>%1', 0D);
                    AdvanceLink.ModifyAll("Transfer Date", 0D);
                end;
        end;
    end;

    local procedure CalcVATToDeduct(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; var TotalBase: Decimal; var TotalAmount: Decimal; var TotalBaseLCY: Decimal; var TotalAmountLCY: Decimal; CustEntryNo: Integer)
    var
        SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry";
    begin
        SalesAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type", "Posting Date");
        SalesAdvanceLetterEntry.SetRange("Letter No.", SalesAdvanceLetterLine."Letter No.");
        SalesAdvanceLetterEntry.SetRange("Letter Line No.", SalesAdvanceLetterLine."Line No.");
        SalesAdvanceLetterEntry.SetFilter("Entry Type", '%1|%2|%3', SalesAdvanceLetterEntry."Entry Type"::VAT,
          SalesAdvanceLetterEntry."Entry Type"::"VAT Deduction", SalesAdvanceLetterEntry."Entry Type"::"VAT Rate");
        if CustEntryNo <> 0 then
            SalesAdvanceLetterEntry.SetRange("Customer Entry No.", CustEntryNo);
        SalesAdvanceLetterEntry.CalcSums("VAT Base Amount (LCY)", "VAT Amount (LCY)", "VAT Base Amount", "VAT Amount");
        TotalAmount := SalesAdvanceLetterEntry."VAT Amount";
        TotalBase := SalesAdvanceLetterEntry."VAT Base Amount";
        TotalAmountLCY := SalesAdvanceLetterEntry."VAT Amount (LCY)";
        TotalBaseLCY := SalesAdvanceLetterEntry."VAT Base Amount (LCY)";

        TempSalesAdvanceLetterEntry.Reset();
        TempSalesAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type", "Posting Date");
        TempSalesAdvanceLetterEntry.SetRange("Letter No.", SalesAdvanceLetterLine."Letter No.");
        TempSalesAdvanceLetterEntry.SetRange("Letter Line No.", SalesAdvanceLetterLine."Line No.");
        TempSalesAdvanceLetterEntry.SetFilter("Entry Type", '%1|%2|%3', TempSalesAdvanceLetterEntry."Entry Type"::VAT,
          TempSalesAdvanceLetterEntry."Entry Type"::"VAT Deduction", TempSalesAdvanceLetterEntry."Entry Type"::"VAT Rate");
        if CustEntryNo <> 0 then
            TempSalesAdvanceLetterEntry.SetRange("Customer Entry No.", CustEntryNo);
        TempSalesAdvanceLetterEntry.CalcSums("VAT Base Amount (LCY)", "VAT Amount (LCY)", "VAT Base Amount", "VAT Amount");
        TotalAmount := TotalAmount + TempSalesAdvanceLetterEntry."VAT Amount";
        TotalBase := TotalBase + TempSalesAdvanceLetterEntry."VAT Base Amount";
        TotalAmountLCY := TotalAmountLCY + TempSalesAdvanceLetterEntry."VAT Amount (LCY)";
        TotalBaseLCY := TotalBaseLCY + TempSalesAdvanceLetterEntry."VAT Base Amount (LCY)";
        TempSalesAdvanceLetterEntry.Reset();
    end;

    [Scope('OnPrem')]
    procedure CalcNoOfDocs(CustNo: Code[20]; var QtyOfDocs: array[5] of Integer)
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        Status: Integer;
    begin
        Clear(QtyOfDocs);
        CustNo := CustNo;
        SalesAdvanceLetterLine.SetCurrentKey("Bill-to Customer No.", Status);
        SalesAdvanceLetterLine.SetRange("Bill-to Customer No.", CustNo);
        for Status := 0 to 4 do begin
            SalesAdvanceLetterLine.SetRange(Status, Status);
            QtyOfDocs[Status + 1] := SalesAdvanceLetterLine.Count();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPrepmtAmounts(SalesHeader: Record "Sales Header"; var PrepmtAmtRequested: Decimal; var PrepmtAmtReceived: Decimal)
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        TempSalesAdvanceLetterLine: Record "Sales Advance Letter Line" temporary;
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]) then
            SalesHeader.FieldError("Document Type");

        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Document Type", SalesHeader."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", SalesHeader."No.");
        if AdvanceLetterLineRelation.FindSet then begin
            repeat
                if not TempSalesAdvanceLetterLine.Get(
                     AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.")
                then begin
                    SalesAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                    TempSalesAdvanceLetterLine.Init();
                    TempSalesAdvanceLetterLine := SalesAdvanceLetterLine;
                    TempSalesAdvanceLetterLine.Insert();
                end;
            until AdvanceLetterLineRelation.Next = 0;

            TempSalesAdvanceLetterLine.CalcSums("Amount Including VAT", "Amount Linked");
            PrepmtAmtRequested += TempSalesAdvanceLetterLine."Amount Including VAT";
            PrepmtAmtReceived += TempSalesAdvanceLetterLine."Amount Linked";
        end else begin
            SalesAdvanceLetterHeader.SetRange("Order No.", SalesHeader."No.");
            if SalesAdvanceLetterHeader.FindSet then
                repeat
                    SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
                    SalesAdvanceLetterLine.CalcSums("Amount Including VAT", "Amount Linked");
                    PrepmtAmtRequested += SalesAdvanceLetterLine."Amount Including VAT";
                    PrepmtAmtReceived += SalesAdvanceLetterLine."Amount Linked";
                until SalesAdvanceLetterHeader.Next = 0;
        end;
    end;

    local procedure InsertInDimBuf(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"): Integer
    begin
        exit(SalesAdvanceLetterLine."Dimension Set ID");
    end;

    local procedure GetInvoiceLineAmount(DocNo: Code[20]; LineNo: Integer): Decimal
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        if SalesInvLine.Get(DocNo, LineNo) then begin
            if SalesInvLine."VAT Calculation Type" = SalesInvLine."VAT Calculation Type"::"Reverse Charge VAT" then
                exit(SalesInvLine."VAT Base Amount");
            exit(SalesInvLine."Amount Including VAT" + SalesInvLine."VAT Base Amount");
        end;
        exit(0);
    end;

    local procedure InsertLineRelations(BufEntryNo: Integer; SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; var AdvanceLetterLineRelation2: Record "Advance Letter Line Relation")
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        if BufEntryNo = 0 then
            exit;
        AdvanceLetterLineRelation2.Reset();

        AdvanceLetterLineRelation2.SetRange("Letter Line No.", BufEntryNo);
        if AdvanceLetterLineRelation2.FindSet then
            repeat
                AdvanceLetterLineRelation := AdvanceLetterLineRelation2;
                AdvanceLetterLineRelation."Letter No." := SalesAdvanceLetterLine."Letter No.";
                AdvanceLetterLineRelation."Letter Line No." := SalesAdvanceLetterLine."Line No.";
                AdvanceLetterLineRelation.Insert();
            until AdvanceLetterLineRelation2.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateOrderLine(var SalesLine: Record "Sales Line"; PricesInclVAT: Boolean; RecalcAmtToDeduct: Boolean)
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        AdvanceLetterLineRelation.SetCurrentKey(Type, "Document Type", "Document No.", "Document Line No.", "Letter No.", "Letter Line No.");
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Document Type", SalesLine."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", SalesLine."Document No.");
        AdvanceLetterLineRelation.SetRange("Document Line No.", SalesLine."Line No.");
        AdvanceLetterLineRelation.CalcSums("Invoiced Amount", "Deducted Amount");

        if PricesInclVAT then
            SalesLine."Prepmt. Amt. Inv." := AdvanceLetterLineRelation."Invoiced Amount"
        else
            SalesLine."Prepmt. Amt. Inv." :=
              Round(AdvanceLetterLineRelation."Invoiced Amount" / (1 + SalesLine."VAT %" / 100),
                Currency."Amount Rounding Precision");
        if RecalcAmtToDeduct then
            SalesLine.CalcPrepaymentToDeduct;
    end;

    [Scope('OnPrem')]
    procedure UpdInvAmountToLineRelations(SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        AmtDif: Decimal;
    begin
        SalesAdvanceLetterLine.CalcFields("Document Linked Inv. Amount");
        AmtDif := SalesAdvanceLetterLine."Amount Invoiced" - SalesAdvanceLetterLine."Document Linked Inv. Amount";
        if AmtDif > 0 then begin
            AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
            AdvanceLetterLineRelation.SetRange("Letter No.", SalesAdvanceLetterLine."Letter No.");
            AdvanceLetterLineRelation.SetRange("Letter Line No.", SalesAdvanceLetterLine."Line No.");
            if AdvanceLetterLineRelation.FindSet then
                repeat
                    if AdvanceLetterLineRelation.Amount > AdvanceLetterLineRelation."Invoiced Amount" then begin
                        if AmtDif > (AdvanceLetterLineRelation.Amount - AdvanceLetterLineRelation."Invoiced Amount") then begin
                            AmtDif := AmtDif - AdvanceLetterLineRelation.Amount + AdvanceLetterLineRelation."Invoiced Amount";
                            AdvanceLetterLineRelation."Invoiced Amount" := AdvanceLetterLineRelation.Amount;
                        end else begin
                            AdvanceLetterLineRelation."Invoiced Amount" := AdvanceLetterLineRelation."Invoiced Amount" + AmtDif;
                            AmtDif := 0;
                        end;
                        AdvanceLetterLineRelation.Modify();
                        if not TempSalesLine.Get(AdvanceLetterLineRelation."Document Type",
                             AdvanceLetterLineRelation."Document No.",
                             AdvanceLetterLineRelation."Document Line No.")
                        then begin
                            TempSalesLine."Document Type" := AdvanceLetterLineRelation."Document Type";
                            TempSalesLine."Document No." := AdvanceLetterLineRelation."Document No.";
                            TempSalesLine."Line No." := AdvanceLetterLineRelation."Document Line No.";
                            TempSalesLine.Insert();
                        end;
                    end;
                until (AdvanceLetterLineRelation.Next = 0) or (AmtDif = 0);
        end else
            if AmtDif < 0 then begin
                AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
                AdvanceLetterLineRelation.SetRange("Letter No.", SalesAdvanceLetterLine."Letter No.");
                AdvanceLetterLineRelation.SetRange("Letter Line No.", SalesAdvanceLetterLine."Line No.");
                if AdvanceLetterLineRelation.Find('+') then
                    repeat
                        if AdvanceLetterLineRelation."Invoiced Amount" > AdvanceLetterLineRelation."Deducted Amount" then begin
                            if (AdvanceLetterLineRelation."Invoiced Amount" - AdvanceLetterLineRelation."Deducted Amount") < -AmtDif then begin
                                AmtDif := AmtDif + AdvanceLetterLineRelation."Invoiced Amount" - AdvanceLetterLineRelation."Deducted Amount";
                                AdvanceLetterLineRelation."Invoiced Amount" := AdvanceLetterLineRelation."Deducted Amount";
                            end else begin
                                AdvanceLetterLineRelation."Invoiced Amount" := AdvanceLetterLineRelation."Invoiced Amount" + AmtDif;
                                AmtDif := 0;
                            end;
                            AdvanceLetterLineRelation.Modify();
                            if not TempSalesLine.Get(AdvanceLetterLineRelation."Document Type",
                                 AdvanceLetterLineRelation."Document No.",
                                 AdvanceLetterLineRelation."Document Line No.")
                            then begin
                                TempSalesLine."Document Type" := AdvanceLetterLineRelation."Document Type";
                                TempSalesLine."Document No." := AdvanceLetterLineRelation."Document No.";
                                TempSalesLine."Line No." := AdvanceLetterLineRelation."Document Line No.";
                                TempSalesLine.Insert();
                            end;
                        end;
                    until (AdvanceLetterLineRelation.Next(-1) = 0) or (AmtDif = 0);
                if AmtDif < 0 then begin
                    SalesAdvanceLetterLine.CalcFields("Document Linked Inv. Amount");
                    Error(Text4005247Err, SalesAdvanceLetterLine."Document Linked Inv. Amount",
                      SalesAdvanceLetterLine."Letter No.", SalesAdvanceLetterLine."Line No.");
                end;
            end;
        if TempSalesLine.FindSet then
            repeat
                SalesHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.");
                SalesLine.Get(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.");
                UpdateOrderLine(SalesLine, SalesHeader."Prices Including VAT", true);
                SalesLine.Modify();
            until TempSalesLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure ClearLineRelAmountToDeduct(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20])
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Document Type", DocType);
        AdvanceLetterLineRelation.SetRange("Document No.", DocNo);
        AdvanceLetterLineRelation.ModifyAll("Amount To Deduct", 0);
    end;

    local procedure SetCurrencyPrecision(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    [Scope('OnPrem')]
    procedure SetLetterNo(LetterNo: Code[20])
    begin
        LetterNoToInvoice := LetterNo;
    end;

    [Scope('OnPrem')]
    procedure UpdateLines(LetterNo: Code[20])
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        TempSalesLineBuf: Record "Sales Line" temporary;
    begin
        AdvanceLetterLineRelation.SetCurrentKey(Type, "Document Type", "Document No.", "Document Line No.", "Letter No.", "Letter Line No.");
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Letter No.", LetterNo);
        if AdvanceLetterLineRelation.FindSet(false, false) then begin
            repeat
                TempSalesLineBuf."Document Type" := AdvanceLetterLineRelation."Document Type";
                TempSalesLineBuf."Document No." := AdvanceLetterLineRelation."Document No.";
                TempSalesLineBuf."Line No." := AdvanceLetterLineRelation."Document Line No.";
                if TempSalesLineBuf.Insert() then;

            until AdvanceLetterLineRelation.Next = 0;
        end;
        if TempSalesLineBuf.Find('-') then begin
            repeat
                SalesLine := TempSalesLineBuf;
                if SalesLine.Find then
                    if SalesLine."Prepmt. Line Amount" <> 0 then begin
                        if (SalesHeader."Document Type" <> SalesLine."Document Type") or
                           (SalesHeader."No." <> SalesLine."Document No.")
                        then
                            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                        UpdateOrderLine(SalesLine, SalesHeader."Prices Including VAT", true);
                        SalesLine.Modify();
                    end;
            until TempSalesLineBuf.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLetterHeader(var TempSalesAdvanceLetterHeader2: Record "Sales Advance Letter Header" temporary)
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
    begin
        TempSalesAdvanceLetterHeader.Reset();
        if TempSalesAdvanceLetterHeader.Find('-') then begin
            repeat
                TempSalesAdvanceLetterHeader2 := TempSalesAdvanceLetterHeader;
                SalesAdvanceLetterHeader.Get(TempSalesAdvanceLetterHeader2."No.");
                TempSalesAdvanceLetterHeader2."Template Code" := SalesAdvanceLetterHeader."Template Code";
                TempSalesAdvanceLetterHeader2."Post Advance VAT Option" := SalesAdvanceLetterHeader."Post Advance VAT Option";
                if TempSalesAdvanceLetterHeader2.Insert() then;
            until TempSalesAdvanceLetterHeader.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetLetterHeader(var TempSalesAdvanceLetterHeader2: Record "Sales Advance Letter Header" temporary)
    begin
        if TempSalesAdvanceLetterHeader2.Find('-') then begin
            repeat
                TempSalesAdvanceLetterHeader := TempSalesAdvanceLetterHeader2;
                TempSalesAdvanceLetterHeader.Insert();
            until TempSalesAdvanceLetterHeader2.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetGenJnlPostLine(var GenJnlPostLineNew: Codeunit "Gen. Jnl.-Post Line")
    begin
        GenJnlPostLine := GenJnlPostLineNew;
        DisablePostingCuClear := true;
    end;

    [Scope('OnPrem')]
    procedure CheckVATCredtMemoIsNeed(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"): Boolean
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        if SalesAdvanceLetterLine.FindSet then
            repeat
                CalcVATToDeduct(SalesAdvanceLetterLine, BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY, 0);
                if (BaseToDeduct <> 0) or (VATAmtToDeduct <> 0) or (BaseToDeductLCY <> 0) or (VATAmountLCY <> 0) then
                    exit(true);
            until SalesAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure PostVATCreditMemo(DocumentNo: Code[20]; var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date; VATDate: Date)
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        GenJnlLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
        ToDeductFactor: Decimal;
        BaseToDeductLCYDif: Decimal;
        VATAmountLCYDif: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Use VAT Date" then
            if VATDate = 0D then
                Error(Text034Err);
        if PostingDate = 0D then
            Error(Text035Err);

        CheckReasonCodeForCrMemo(SalesAdvanceLetterHeader);
        SetCurrencyPrecision(SalesAdvanceLetterHeader."Currency Code");

        SalesAdvanceLetterHeader.CalcFields(Status);
        if SalesAdvanceLetterHeader.Status > SalesAdvanceLetterHeader.Status::"Pending Final Invoice" then
            SalesAdvanceLetterHeader.TestField(Status, SalesAdvanceLetterHeader.Status::"Pending Final Invoice");

        PostVATCrMemoHeader(SalesCrMemoHeader, SalesAdvanceLetterHeader, DocumentNo, PostingDate, VATDate);

        // Create Lines
        TempPrepmtInvLineBuf.DeleteAll();
        BuildCreditMemoLineBuf(SalesAdvanceLetterHeader, TempPrepmtInvLineBuf);
        if TempPrepmtInvLineBuf.FindSet then begin
            repeat
                PostVATCrMemoLine(SalesCrMemoLine, TempPrepmtInvLineBuf, SalesCrMemoHeader);

                // Posting to G/L
                PostVATCrMemoPrepareGL(GenJnlLine, SalesAdvanceLetterHeader, TempPrepmtInvLineBuf, SalesCrMemoHeader, PostingDate, VATDate);
                OnAfterPostVATCrMemoPrepareGL(GenJnlLine, SalesAdvanceLetterHeader);

                SalesAdvanceLetterLine.Get(SalesAdvanceLetterHeader."No.", TempPrepmtInvLineBuf."Line No.");
                CalcVATToDeduct(SalesAdvanceLetterLine, BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY, 0);
                if TempPrepmtInvLineBuf."VAT Calculation Type" =
                   TempPrepmtInvLineBuf."VAT Calculation Type"::"Reverse Charge VAT"
                then begin
                    if BaseToDeduct = 0 then
                        ToDeductFactor := 0
                    else
                        ToDeductFactor := TempPrepmtInvLineBuf."VAT Base Amount" / BaseToDeduct;
                end else begin
                    if VATAmtToDeduct = 0 then
                        ToDeductFactor := 0
                    else
                        ToDeductFactor := TempPrepmtInvLineBuf."VAT Amount" / VATAmtToDeduct;
                    if (ToDeductFactor = 0) and (BaseToDeduct <> 0) then
                        ToDeductFactor := TempPrepmtInvLineBuf."VAT Base Amount" / BaseToDeduct;
                end;

                BaseToDeduct := Round(BaseToDeduct * ToDeductFactor, Currency."Amount Rounding Precision");
                VATAmtToDeduct := Round(VATAmtToDeduct * ToDeductFactor, Currency."Amount Rounding Precision");
                if SalesAdvanceLetterHeader."Currency Code" = '' then begin
                    BaseToDeductLCY := BaseToDeduct;
                    VATAmountLCY := VATAmtToDeduct;
                end else begin
                    BaseToDeductLCY := Round(BaseToDeductLCY * ToDeductFactor);
                    VATAmountLCY := Round(VATAmountLCY * ToDeductFactor);
                    BaseToDeductLCYDif := BaseToDeductLCY;
                    VATAmountLCYDif := VATAmountLCY;
                    BaseToDeductLCY := Round(BaseToDeduct / GenJnlLine."Currency Factor");
                    VATAmountLCY := Round(VATAmtToDeduct / GenJnlLine."Currency Factor");
                    BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                    VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
                end;
                GenJnlLine."Advance Exch. Rate Difference" := VATAmountLCYDif;

                RunGenJnlPostLine(GenJnlLine);

                SalesAdvanceLetterLine.Get(SalesAdvanceLetterHeader."No.", TempPrepmtInvLineBuf."Line No.");
                PostVATCrMemo_UpdtLine(SalesAdvanceLetterLine);

                UpdInvAmountToLineRelations(SalesAdvanceLetterLine);

                SalesInvHeader.TransferFields(SalesCrMemoHeader);
                CustLedgEntry.Init();
                CustLedgEntry."Customer No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
                CreateAdvanceEntry(SalesAdvanceLetterHeader, SalesAdvanceLetterLine, SalesInvHeader, 0, CustLedgEntry, 0);
                FillVATFieldsOfDeductionEntry(TempPrepmtInvLineBuf."VAT %");
                TempSalesAdvanceLetterEntry."VAT Identifier" := TempPrepmtInvLineBuf."VAT Identifier";
                TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::VAT;
                TempSalesAdvanceLetterEntry."Sale Line No." := TempPrepmtInvLineBuf."Line No.";
                TempSalesAdvanceLetterEntry."Document Type" := GenJnlLine."Document Type";
                TempSalesAdvanceLetterEntry."VAT Base Amount" := TempPrepmtInvLineBuf."VAT Base Amount";
                TempSalesAdvanceLetterEntry."VAT Amount" := TempPrepmtInvLineBuf."VAT Amount";
                TempSalesAdvanceLetterEntry.Modify();

                // Gain/Loss
                if (VATAmountLCYDif <> 0) or
                   ((BaseToDeductLCYDif <> 0) and
                    (TempPrepmtInvLineBuf."VAT Calculation Type" = TempPrepmtInvLineBuf."VAT Calculation Type"::"Reverse Charge VAT"))
                then begin
                    if TempPrepmtInvLineBuf."VAT Calculation Type" <>
                       TempPrepmtInvLineBuf."VAT Calculation Type"::"Reverse Charge VAT"
                    then begin
                        SetPostingGroups(GenJnlLine, SalesAdvanceLetterLine, true);
                        GenJnlLine.Validate("Currency Code", '');
                        GenJnlLine."Bal. Account No." := '';
                        if VATAmountLCYDif > 0 then begin
                            Currency.TestField("Realized Losses Acc.");
                            GenJnlLine."Account No." := Currency."Realized Losses Acc."
                        end else begin
                            Currency.TestField("Realized Gains Acc.");
                            GenJnlLine."Account No." := Currency."Realized Gains Acc.";
                        end;
                        GenJnlLine.Validate(Amount, VATAmountLCYDif);
                        RunGenJnlPostLine(GenJnlLine);

                        VATPostingSetup.Get(TempPrepmtInvLineBuf."VAT Bus. Posting Group", TempPrepmtInvLineBuf."VAT Prod. Posting Group");
                        VATPostingSetup.TestField("Sales Advance Offset VAT Acc.");
                        GenJnlLine."Account No." := VATPostingSetup."Sales Advance Offset VAT Acc.";
                        GenJnlLine.Validate(Amount, -VATAmountLCYDif);
                        RunGenJnlPostLine(GenJnlLine);
                    end;

                    SalesAdvanceLetterEntryNo += 1;
                    TempSalesAdvanceLetterEntry."Entry No." := SalesAdvanceLetterEntryNo;
                    TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::"VAT Rate";
                    TempSalesAdvanceLetterEntry.Amount := 0;
                    TempSalesAdvanceLetterEntry."Sale Line No." := TempPrepmtInvLineBuf."Line No.";
                    TempSalesAdvanceLetterEntry."Document Type" := GenJnlLine."Document Type";
                    TempSalesAdvanceLetterEntry."VAT Base Amount" := 0;
                    TempSalesAdvanceLetterEntry."VAT Amount" := 0;
                    TempSalesAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCYDif;
                    TempSalesAdvanceLetterEntry."VAT Amount (LCY)" := VATAmountLCYDif;
                    TempSalesAdvanceLetterEntry.Insert();
                end;

            until TempPrepmtInvLineBuf.Next = 0;
            SaveDeductionEntries;
            UpdateLines(SalesAdvanceLetterHeader."No.");
        end;
        Clear(GenJnlPostLine);
    end;

    local procedure PostVATCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; DocumentNo: Code[20]; PostingDate: Date; VATDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SourceCodeSetup: Record "Source Code Setup";
        SrcCode: Code[10];
    begin
        SalesHeader.Init();
        SalesHeader.TransferFields(SalesAdvanceLetterHeader);
        CopyBillToSellFromAdvLetter(SalesHeader, SalesAdvanceLetterHeader);

        SalesHeader."VAT Date" := VATDate;

        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Sales;

        // Create posted header
        with SalesCrMemoHeader do begin
            Init;
            SalesHeader."Bank Account Code" := '';
            TransferFields(SalesHeader);
            "Posting Date" := PostingDate;
            "VAT Date" := VATDate;
            "Document Date" := PostingDate;
            "Currency Factor" :=
              CurrExchRate.ExchangeRate(PostingDate, SalesHeader."Currency Code");
            "Due Date" := SalesAdvanceLetterHeader."Advance Due Date";
            Correction := GLSetup."Mark Cr. Memos as Corrections";
            "No." := DocumentNo;
            "Pre-Assigned No. Series" := '';
            "Source Code" := SrcCode;
            "User ID" := UserId;
            "No. Printed" := 0;
            "Prices Including VAT" := true;
            "Prepayment Credit Memo" := true;
            "Letter No." := SalesAdvanceLetterHeader."No.";
            "Reason Code" := SalesAdvanceLetterHeader."Reason Code";
            "Credit Memo Type" := "Credit Memo Type"::"Corrective Tax Document";
            Insert;
        end;
    end;

    local procedure PostVATCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoLine.Init();
        SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
        SalesCrMemoLine."Line No." := PrepaymentInvLineBuffer."Line No.";
        SalesCrMemoLine."Posting Date" := SalesCrMemoHeader."Posting Date";
        SalesCrMemoLine."Sell-to Customer No." := SalesCrMemoHeader."Sell-to Customer No.";
        SalesCrMemoLine."Bill-to Customer No." := SalesCrMemoHeader."Bill-to Customer No.";
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::"G/L Account";
        SalesCrMemoLine."No." := TempPrepmtInvLineBuf."G/L Account No.";
        SalesCrMemoLine."Shortcut Dimension 1 Code" := PrepaymentInvLineBuffer."Global Dimension 1 Code";
        SalesCrMemoLine."Shortcut Dimension 2 Code" := PrepaymentInvLineBuffer."Global Dimension 2 Code";
        SalesCrMemoLine."Dimension Set ID" := PrepaymentInvLineBuffer."Dimension Set ID";
        SalesCrMemoLine.Description := PrepaymentInvLineBuffer.Description;
        SalesCrMemoLine.Quantity := 1;
        SalesCrMemoLine."Unit Price" := PrepaymentInvLineBuffer."VAT Amount";
        SalesCrMemoLine."Line Amount" := PrepaymentInvLineBuffer."VAT Amount";
        SalesCrMemoLine.Amount := PrepaymentInvLineBuffer."VAT Amount";
        SalesCrMemoLine."Amount Including VAT" := PrepaymentInvLineBuffer."VAT Amount";
        SalesCrMemoLine."VAT Base Amount" := PrepaymentInvLineBuffer."VAT Base Amount";
        SalesCrMemoLine."Gen. Bus. Posting Group" := PrepaymentInvLineBuffer."Gen. Bus. Posting Group";
        SalesCrMemoLine."Gen. Prod. Posting Group" := PrepaymentInvLineBuffer."Gen. Prod. Posting Group";
        SalesCrMemoLine."VAT Bus. Posting Group" := PrepaymentInvLineBuffer."VAT Bus. Posting Group";
        SalesCrMemoLine."VAT Prod. Posting Group" := PrepaymentInvLineBuffer."VAT Prod. Posting Group";
        SalesCrMemoLine."VAT %" := PrepaymentInvLineBuffer."VAT %";
        SalesCrMemoLine."VAT Calculation Type" := PrepaymentInvLineBuffer."VAT Calculation Type";
        SalesCrMemoLine."VAT Identifier" := PrepaymentInvLineBuffer."VAT Identifier";
        SalesCrMemoLine.Insert();
    end;

    local procedure PostVATCrMemoPrepareGL(var GenJnlLine: Record "Gen. Journal Line"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PostingDate: Date; VATDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with GenJnlLine do begin
            Init;
            "Advance Letter No." := SalesAdvanceLetterHeader."No.";
            "Advance Letter Line No." := PrepaymentInvLineBuffer."Line No.";
            "Posting Date" := PostingDate;
            "VAT Date" := VATDate;
            "Document Date" := PostingDate;
            Description := PrepaymentInvLineBuffer.Description;
            Prepayment := true;
            "Prepayment Type" := "Prepayment Type"::Advance;
            "VAT Calculation Type" := "VAT Calculation Type"::"Full VAT";
            "Document Type" := "Document Type"::"Credit Memo";
            "Document No." := SalesCrMemoHeader."No.";
            "Account Type" := "Account Type"::"G/L Account";
            "Account No." := PrepaymentInvLineBuffer."G/L Account No.";
            "System-Created Entry" := true;
            Validate("Currency Code", SalesAdvanceLetterHeader."Currency Code");
            Validate(Amount, PrepaymentInvLineBuffer."VAT Amount");
            if "Currency Code" = '' then
                "Advance VAT Base Amount" := PrepaymentInvLineBuffer."VAT Base Amount"
            else
                "Advance VAT Base Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      "Posting Date", "Currency Code",
                      PrepaymentInvLineBuffer."VAT Base Amount", "Currency Factor"));
            "Source Currency Code" := SalesAdvanceLetterHeader."Currency Code";
            "Source Currency Amount" := PrepaymentInvLineBuffer."Amount (ACY)";
            Correction := SalesCrMemoHeader.Correction;
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := PrepaymentInvLineBuffer."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := PrepaymentInvLineBuffer."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := PrepaymentInvLineBuffer."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := PrepaymentInvLineBuffer."VAT Prod. Posting Group";
            if PrepaymentInvLineBuffer."VAT Calculation Type" <>
               PrepaymentInvLineBuffer."VAT Calculation Type"::"Reverse Charge VAT"
            then begin
                VATPostingSetup.Get(PrepaymentInvLineBuffer."VAT Bus. Posting Group", PrepaymentInvLineBuffer."VAT Prod. Posting Group");
                "Bal. Account Type" := "Bal. Account Type"::"G/L Account";
                "Bal. Account No." := VATPostingSetup."Sales Advance Offset VAT Acc.";
            end;
            "Tax Area Code" := PrepaymentInvLineBuffer."Tax Area Code";
            "Tax Liable" := PrepaymentInvLineBuffer."Tax Liable";
            "Tax Group Code" := PrepaymentInvLineBuffer."Tax Group Code";
            "Source Curr. VAT Amount" := PrepaymentInvLineBuffer."VAT Amount (ACY)";
            "VAT Difference" := PrepaymentInvLineBuffer."VAT Difference";
            "VAT Posting" := "VAT Posting"::"Automatic VAT Entry";
            "Shortcut Dimension 1 Code" := PrepaymentInvLineBuffer."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PrepaymentInvLineBuffer."Global Dimension 2 Code";
            "Dimension Set ID" := PrepaymentInvLineBuffer."Dimension Set ID";
            "Job No." := PrepaymentInvLineBuffer."Job No.";
            "EU 3-Party Trade" := SalesCrMemoHeader."EU 3-Party Trade";
            "Bill-to/Pay-to No." := SalesCrMemoHeader."Bill-to Customer No.";
            "Country/Region Code" := SalesCrMemoHeader."VAT Country/Region Code";
            "VAT Registration No." := SalesCrMemoHeader."VAT Registration No.";
            "Source Type" := "Source Type"::Customer;
            "Source No." := SalesCrMemoHeader."Bill-to Customer No.";
            "Source Code" := SalesCrMemoHeader."Source Code";
            "Posting No. Series" := SalesCrMemoHeader."No. Series";
            "Reason Code" := SalesCrMemoHeader."Reason Code";
        end;
    end;

    local procedure PostVATCrMemo_UpdtLine(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        with SalesAdvanceLetterLine do begin
            "Amount To Invoice" += TempPrepmtInvLineBuf."Amount Incl. VAT";
            "Amount To Deduct" -= TempPrepmtInvLineBuf."Amount Incl. VAT";
            "Amount Invoiced" -= TempPrepmtInvLineBuf."Amount Incl. VAT";
            SuspendStatusCheck(true);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure BuildCreditMemoLineBuf(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer";
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        if SalesAdvanceLetterLine.FindSet then
            repeat
                if SalesAdvanceLetterLine."Amount Including VAT" <> 0 then begin
                    FillCreditMemoLineBuf(SalesAdvanceLetterLine, PrepmtInvLineBuf2);
                    if PrepmtInvLineBuf2.Amount <> 0 then
                        xInsertInvLineBuf(PrepmtInvLineBuf, PrepmtInvLineBuf2)
                end;
            until SalesAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure FillCreditMemoLineBuf(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    var
        SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry";
    begin
        with PrepmtInvLineBuf do begin
            Clear(PrepmtInvLineBuf);

            "G/L Account No." := SalesAdvanceLetterLine."No.";
            "Dimension Set ID" := InsertInDimBuf(SalesAdvanceLetterLine);
            "Gen. Bus. Posting Group" := SalesAdvanceLetterLine."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := SalesAdvanceLetterLine."VAT Bus. Posting Group";
            "Gen. Prod. Posting Group" := SalesAdvanceLetterLine."Gen. Prod. Posting Group";
            "VAT Prod. Posting Group" := SalesAdvanceLetterLine."VAT Prod. Posting Group";
            "VAT Calculation Type" := SalesAdvanceLetterLine."VAT Calculation Type";
            "Global Dimension 1 Code" := SalesAdvanceLetterLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := SalesAdvanceLetterLine."Shortcut Dimension 2 Code";
            "Job No." := SalesAdvanceLetterLine."Job No.";

            if CloseAll then begin
                SalesAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
                SalesAdvanceLetterEntry.SetRange("Letter No.", SalesAdvanceLetterLine."Letter No.");
                SalesAdvanceLetterEntry.SetRange("Letter Line No.", SalesAdvanceLetterLine."Line No.");
                SalesAdvanceLetterEntry.SetRange("Entry Type",
                  SalesAdvanceLetterEntry."Entry Type"::VAT,
                  SalesAdvanceLetterEntry."Entry Type"::"VAT Deduction");
                SalesAdvanceLetterEntry.CalcSums("VAT Base Amount", "VAT Amount");
                "VAT Base Amount" := -SalesAdvanceLetterEntry."VAT Base Amount";
                "VAT Amount" := -SalesAdvanceLetterEntry."VAT Amount";
                "Amount Incl. VAT" := "VAT Base Amount" + "VAT Amount";
                Amount := "VAT Base Amount";
            end else begin
                "Amount Incl. VAT" := GetCreditMemoLineAmount(SalesAdvanceLetterLine);
                Amount := Round("Amount Incl. VAT" * SalesAdvanceLetterLine.Amount / SalesAdvanceLetterLine."Amount Including VAT");
                "VAT Base Amount" := Amount;
                "VAT Amount" := "Amount Incl. VAT" - Amount;
            end;

            // ACY
            "Amount (ACY)" := Amount;
            "VAT Base Amount (ACY)" := Amount;
            "VAT Amount (ACY)" := "VAT Amount";
            "VAT %" := SalesAdvanceLetterLine."VAT %";
            "VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
            "Tax Area Code" := SalesAdvanceLetterLine."Tax Area Code";
            "Tax Liable" := SalesAdvanceLetterLine."Tax Liable";
            "Tax Group Code" := SalesAdvanceLetterLine."Tax Group Code";
            "Line No." := SalesAdvanceLetterLine."Line No.";
            Description := SalesAdvanceLetterLine.Description;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCreditMemoLineAmount(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"): Decimal
    begin
        if SalesAdvanceLetterLine."Amount To Invoice" + SalesAdvanceLetterLine."Amount To Deduct" <
           SalesAdvanceLetterLine."Amount To Refund"
        then
            Error(Text036Err, SalesAdvanceLetterLine."Letter No.", SalesAdvanceLetterLine."Line No.");
        if SalesAdvanceLetterLine."Amount To Refund" > SalesAdvanceLetterLine."Amount To Invoice" then
            exit(SalesAdvanceLetterLine."Amount To Refund" - SalesAdvanceLetterLine."Amount To Invoice");

        exit(0);
    end;

    [Scope('OnPrem')]
    procedure PostRefundCorrection(DocumentNo: Code[20]; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date; VATDate: Date)
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        AdvanceLink: Record "Advance Link";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TotAmt: Decimal;
        TotAmtRnded: Decimal;
        AmtToApply: Decimal;
        TotalAmountToRefund: Decimal;
        AmtToRefund: Decimal;
    begin
        CustLedgEntry.LockTable();
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        SalesAdvanceLetterLine.SetFilter("Amount To Refund", '>0');
        if SalesAdvanceLetterLine.FindSet then
            repeat
                TotAmt := 0;
                TotAmtRnded := 0;
                AmtToApply := 0;
                AmtToRefund := SalesAdvanceLetterLine."Amount To Refund";
                AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                AdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
                AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
                AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);

                if AdvanceLink.FindSet then
                    repeat
                        if CustLedgEntry.Get(AdvanceLink."CV Ledger Entry No.") then begin
                            CustLedgEntry.CalcFields("Remaining Amount");
                            if CustLedgEntry."Remaining Amount" <> 0 then begin
                                if AmtToRefund > AdvanceLink."Remaining Amount to Deduct" then
                                    TotAmt := TotAmt + AdvanceLink."Remaining Amount to Deduct"
                                else
                                    TotAmt := TotAmt + AmtToRefund;
                                AmtToApply := Round(TotAmt) - TotAmtRnded;
                                TotAmtRnded := TotAmtRnded + AmtToApply;
                                TotalAmountToRefund := TotalAmountToRefund + AmtToApply;
                                AmtToRefund := AmtToRefund - AmtToApply;
                                if TempCustLedgEntry.Get(CustLedgEntry."Entry No.") then begin
                                    TempCustLedgEntry."Amount to Apply" := TempCustLedgEntry."Amount to Apply" + AmtToApply;
                                    TempCustLedgEntry.Modify();
                                end else begin
                                    CustLedgEntry."Applies-to ID" := AppPrefTxt + Format(CustLedgEntry."Entry No.");
                                    CustLedgEntry.Modify();
                                    TempCustLedgEntry := CustLedgEntry;
                                    TempCustLedgEntry."Amount to Apply" := AmtToApply;
                                    TempCustLedgEntry."Currency Code" := SalesAdvanceLetterHeader."Currency Code";
                                    TempCustLedgEntry.Insert();
                                end;
                            end;
                            AdvanceLink."Remaining Amount to Deduct" := 0;
                            AdvanceLink.Modify();
                        end;
                    until AdvanceLink.Next = 0;

                SalesAdvanceLetterLine."Amount To Link" := SalesAdvanceLetterLine."Amount To Link" + TotAmtRnded;
                SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" - TotAmtRnded;
                SalesAdvanceLetterLine."Amount Linked" := SalesAdvanceLetterLine."Amount Linked" - TotAmtRnded;
                SalesAdvanceLetterLine.SuspendStatusCheck(true);
                SalesAdvanceLetterLine.Modify(true);

            until SalesAdvanceLetterLine.Next = 0;

        if TempCustLedgEntry.IsEmpty then
            exit;

        PostRefundCorrToGL(TempCustLedgEntry, SalesAdvanceLetterHeader, DocumentNo, PostingDate, VATDate);

        UpdateLines(SalesAdvanceLetterHeader."No.");
    end;

    local procedure PostRefundCorrToGL(var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; DocumentNo: Code[20]; PostingDate: Date; VATDate: Date)
    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SrcCode: Code[10];
        PrepaidAmount: Decimal;
        PrepaidAmountLCY: Decimal;
    begin
        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Sales;

        // Post Advance Refund
        GenJnlLine.Init();
        GenJnlLine.Prepayment := true;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."VAT Date" := VATDate;
        GenJnlLine."Document Date" := PostingDate;
        GenJnlLine."Prepayment Type" := GenJnlLine."Prepayment Type"::Advance;
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Source Currency Code" := SalesAdvanceLetterHeader."Currency Code";
        GenJnlLine."Source Code" := SrcCode;
        GenJnlLine."Bill-to/Pay-to No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
        GenJnlLine."Country/Region Code" := SalesAdvanceLetterHeader."Bill-to Country/Region Code";
        GenJnlLine."VAT Registration No." := SalesAdvanceLetterHeader."VAT Registration No.";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
        GenJnlLine."Source No." := SalesAdvanceLetterHeader."Bill-to Customer No.";

        if TempCustLedgEntry.FindSet then
            repeat
                TempCustLedgEntry.TestField("Currency Code", SalesAdvanceLetterHeader."Currency Code");
                CustLedgEntry.Get(TempCustLedgEntry."Entry No.");
                CustLedgEntry."Amount to Apply" := -TempCustLedgEntry."Amount to Apply";
                CustLedgEntry.Modify();
                GenJnlLine.Validate("Currency Code", TempCustLedgEntry."Currency Code");
                if TempCustLedgEntry."Currency Code" <> '' then begin
                    CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    if CustLedgEntry."Remaining Amt. (LCY)" <> 0 then
                        GenJnlLine.Validate("Currency Factor", CustLedgEntry."Remaining Amount" / CustLedgEntry."Remaining Amt. (LCY)")
                    else
                        GenJnlLine.Validate("Currency Factor", CustLedgEntry."Adjusted Currency Factor");
                end;
                GenJnlLine.Validate(Correction, true);
                GenJnlLine.Validate(Amount, TempCustLedgEntry."Amount to Apply");
                PrepaidAmount := PrepaidAmount + GenJnlLine.Amount;
                PrepaidAmountLCY := PrepaidAmountLCY + GenJnlLine."Amount (LCY)";
                GenJnlLine."Applies-to ID" := TempCustLedgEntry."Applies-to ID";
                GenJnlLine."Posting Group" := TempCustLedgEntry."Customer Posting Group";
                GenJnlLine."Document No." := DocumentNo;
                GenJnlLine.Description := TempCustLedgEntry.Description;
                GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";

                if GenJnlLine.Amount <> 0 then
                    GenJnlPostLine.RunWithCheck(GenJnlLine);

            until TempCustLedgEntry.Next = 0;

        GenJnlLine.Init();
        GenJnlLine.Prepayment := false;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."VAT Date" := VATDate;
        GenJnlLine."Document Date" := PostingDate;
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine.Validate("Account No.", SalesAdvanceLetterHeader."Bill-to Customer No.");
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Source Currency Code" := SalesAdvanceLetterHeader."Currency Code";
        GenJnlLine."Source Code" := SrcCode;
        GenJnlLine."Bill-to/Pay-to No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
        GenJnlLine."Country/Region Code" := SalesAdvanceLetterHeader."Bill-to Country/Region Code";
        GenJnlLine."VAT Registration No." := SalesAdvanceLetterHeader."VAT Registration No.";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
        GenJnlLine."Source No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
        GenJnlLine.Validate("Currency Code", SalesAdvanceLetterHeader."Currency Code");
        GenJnlLine.Validate(Amount, -PrepaidAmount);
        if -PrepaidAmountLCY <> 0 then
            GenJnlLine.Validate("Amount (LCY)", -PrepaidAmountLCY);
        GenJnlLine."Shortcut Dimension 1 Code" := SalesAdvanceLetterHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := SalesAdvanceLetterHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := SalesAdvanceLetterHeader."Dimension Set ID";
        GenJnlLine."Variable Symbol" := SalesAdvanceLetterHeader."Variable Symbol";
        GenJnlLine."Constant Symbol" := SalesAdvanceLetterHeader."Constant Symbol";
        GenJnlLine."Specific Symbol" := SalesAdvanceLetterHeader."Specific Symbol";

        if GenJnlLine.Amount <> 0 then
            GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CheckAmountToRefund(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        SalesAdvanceLetterLine.SetFilter("Amount To Refund", '>%1', 0);
        if not SalesAdvanceLetterLine.FindFirst then
            Error(Text037Err);

        if SalesAdvanceLetterLine."Amount To Deduct" + SalesAdvanceLetterLine."Amount To Invoice" <
           SalesAdvanceLetterLine."Amount To Refund"
        then
            Error(Text038Err, SalesAdvanceLetterLine.FieldCaption("Amount To Deduct"),
              SalesAdvanceLetterLine.FieldCaption("Amount To Invoice"),
              SalesAdvanceLetterLine.FieldCaption("Amount To Refund"));
    end;

    [Scope('OnPrem')]
    procedure ClearAmountToRefund(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        if SalesAdvanceLetterLine.FindSet then
            repeat
                SalesAdvanceLetterLine."Amount To Refund" := 0;
                SalesAdvanceLetterLine.Modify();
            until SalesAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure PostRefund(DocumentNo: Code[20]; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date; VATDate: Date; ToPrint: Boolean)
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        // Amount To Refund Checking
        CheckAmountToRefund(SalesAdvanceLetterHeader);

        CheckPostingDateOnRefund(SalesAdvanceLetterHeader, PostingDate);
        SalesSetup.Get();

        if DocumentNo = '' then
            DocumentNo := GetCrMemoDocNo(SalesAdvanceLetterHeader, PostingDate);

        // Create, Post and Print VAT Credit Memo
        if CheckVATCredtMemoIsNeed(SalesAdvanceLetterHeader) then begin
            PostVATCreditMemo(DocumentNo, SalesAdvanceLetterHeader, PostingDate, VATDate);
            if ToPrint then
                PrintCreditMemo(DocumentNo);
        end else
            CreateBlankCrMemo(SalesAdvanceLetterHeader, DocumentNo, PostingDate, VATDate);

        SalesAdvanceLetterLine.Reset();
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        SalesAdvanceLetterLine.SetFilter("Amount To Deduct", '<>%1', 0);
        if SalesAdvanceLetterLine.FindSet(false, false) then
            repeat
                SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" +
                  SalesAdvanceLetterLine."Amount To Deduct";
                SalesAdvanceLetterLine."Amount Invoiced" := SalesAdvanceLetterLine."Amount Invoiced" -
                  SalesAdvanceLetterLine."Amount To Deduct";
                SalesAdvanceLetterLine."Amount To Deduct" := 0;
                SalesAdvanceLetterLine.SuspendStatusCheck(true);
                SalesAdvanceLetterLine.Modify(true);
            until SalesAdvanceLetterLine.Next = 0;

        // Release Advance Payment
        PostRefundCorrection(DocumentNo, SalesAdvanceLetterHeader, PostingDate, VATDate);

        // Clear Amount To Refund from Letter Lines
        ClearAmountToRefund(SalesAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure RefundAndCloseLetterYesNo(DocumentNo: Code[20]; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date; VATDate: Date; ToPrint: Boolean)
    begin
        if Confirm(Text040Qst, false, SalesAdvanceLetterHeader."No.") then begin
            RefundAndCloseLetter(DocumentNo, SalesAdvanceLetterHeader, PostingDate, VATDate, ToPrint);
            SalesAdvanceLetterHeader.Get(SalesAdvanceLetterHeader."No.");
            if SalesAdvanceLetterHeader.Closed then
                Message(StrSubstNo(Text041Msg, SalesAdvanceLetterHeader."No."));
        end;
    end;

    [Scope('OnPrem')]
    procedure RefundAndCloseLetter(DocumentNo: Code[20]; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date; VATDate: Date; ToPrint: Boolean)
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        TotalAmtToRefund: Decimal;
    begin
        CloseAll := true;

        // Calc Amount To Refund
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        if SalesAdvanceLetterLine.FindSet then
            repeat
                SalesAdvanceLetterLine."Amount To Refund" := SalesAdvanceLetterLine."Amount To Invoice" +
                  SalesAdvanceLetterLine."Amount To Deduct";
                TotalAmtToRefund := TotalAmtToRefund + SalesAdvanceLetterLine."Amount To Refund";
                SalesAdvanceLetterLine.Modify();
            until SalesAdvanceLetterLine.Next = 0;

        // Post and Print

        if TotalAmtToRefund <> 0 then
            PostRefund(DocumentNo, SalesAdvanceLetterHeader, PostingDate, VATDate, ToPrint);

        // Set Amount To Link = 0 and Close
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        if SalesAdvanceLetterLine.FindSet then
            repeat
                SalesAdvanceLetterLine."Amount To Link" := 0;
                SalesAdvanceLetterLine.Status := SalesAdvanceLetterLine.Status::Closed;
                SalesAdvanceLetterLine.Modify();
            until SalesAdvanceLetterLine.Next = 0;

        SalesAdvanceLetterHeader.UpdateClosing(true);

        CloseAll := false;
    end;

    local procedure PrintCreditMemo(DocumentNo: Code[20])
    var
        ReportSelection: Record "Report Selections";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if SalesCrMemoHeader.Get(DocumentNo) then begin
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"S.Cr.Memo");
            ReportSelection.Find('-');
            repeat
                ReportSelection.TestField("Report ID");
                REPORT.Run(ReportSelection."Report ID", false, false, SalesCrMemoHeader);
            until ReportSelection.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetSaleAdvanceTempl(SaleAPTemplateCode: Code[10])
    begin
        if SaleAPTemplateCode <> SalesAdvPmtTemplate1.Code then
            if SaleAPTemplateCode = '' then
                Clear(SalesAdvPmtTemplate1)
            else
                SalesAdvPmtTemplate1.Get(SaleAPTemplateCode);
    end;

    [Scope('OnPrem')]
    procedure xInsertInvLineBuf(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer")
    begin
        with PrepmtInvLineBuf do begin
            PrepmtInvLineBuf := PrepmtInvLineBuf2;
            if Find then begin
                with PrepmtInvLineBuf do begin
                    Amount := Amount + PrepmtInvLineBuf2.Amount;
                    "Amount Incl. VAT" := "Amount Incl. VAT" + PrepmtInvLineBuf2."Amount Incl. VAT";
                    "VAT Amount" := "VAT Amount" + PrepmtInvLineBuf2."VAT Amount";
                    "VAT Base Amount" := "VAT Base Amount" + PrepmtInvLineBuf2."VAT Base Amount";
                    "Amount (ACY)" := "Amount (ACY)" + PrepmtInvLineBuf2."Amount (ACY)";
                    "VAT Amount (ACY)" := "VAT Amount (ACY)" + PrepmtInvLineBuf2."VAT Amount (ACY)";
                    "VAT Base Amount (ACY)" := "VAT Base Amount (ACY)" + PrepmtInvLineBuf2."VAT Base Amount (ACY)";
                end;

                Modify;
            end else
                Insert;
        end;
    end;

    local procedure CreateAdvanceEntry(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesLineNo: Integer; CustLedgEntry: Record "Cust. Ledger Entry"; AmtInclVAT: Decimal)
    begin
        SalesAdvanceLetterEntryNo += 1;
        TempSalesAdvanceLetterEntry.Init();
        TempSalesAdvanceLetterEntry."Entry No." := SalesAdvanceLetterEntryNo;
        TempSalesAdvanceLetterEntry."Template Name" := SalesAdvanceLetterHeader."Template Code";
        TempSalesAdvanceLetterEntry."Letter No." := SalesAdvanceLetterHeader."No.";
        TempSalesAdvanceLetterEntry."Letter Line No." := SalesAdvanceLetterLine."Line No.";
        TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::Deduction;
        TempSalesAdvanceLetterEntry."Document Type" := TempSalesAdvanceLetterEntry."Document Type"::Invoice;
        TempSalesAdvanceLetterEntry."Document No." := SalesInvHeader."No.";
        TempSalesAdvanceLetterEntry."Sale Line No." := SalesLineNo;
        TempSalesAdvanceLetterEntry."Posting Date" := SalesInvHeader."Posting Date";
        TempSalesAdvanceLetterEntry."Customer No." := CustLedgEntry."Customer No.";
        TempSalesAdvanceLetterEntry."Customer Entry No." := CustLedgEntry."Entry No.";
        TempSalesAdvanceLetterEntry.Amount := AmtInclVAT;
        TempSalesAdvanceLetterEntry."Currency Code" := SalesInvHeader."Currency Code";
        TempSalesAdvanceLetterEntry."User ID" := UserId;
        TempSalesAdvanceLetterEntry.Insert();
    end;

    local procedure FillVATFieldsOfDeductionEntry(VATPct: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.FindLast;
        TempSalesAdvanceLetterEntry."Transaction No." := VATEntry."Transaction No.";
        TempSalesAdvanceLetterEntry."VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
        TempSalesAdvanceLetterEntry."VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
        TempSalesAdvanceLetterEntry."VAT %" := VATPct;
        TempSalesAdvanceLetterEntry."VAT Identifier" := VATEntry."VAT Identifier";
        TempSalesAdvanceLetterEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type";
        TempSalesAdvanceLetterEntry."VAT Base Amount (LCY)" := VATEntry."Advance Base";
        TempSalesAdvanceLetterEntry."VAT Amount (LCY)" := VATEntry.Amount;
        TempSalesAdvanceLetterEntry."VAT Entry No." := VATEntry."Entry No.";
        TempSalesAdvanceLetterEntry."VAT Date" := VATEntry."VAT Date";
        TempSalesAdvanceLetterEntry.Modify();
    end;

    local procedure FillDeductionLineNo(DeductionLineNo: Integer)
    begin
        TempSalesAdvanceLetterEntry.SetRange("Entry Type", TempSalesAdvanceLetterEntry."Entry Type"::Deduction);
        if not TempSalesAdvanceLetterEntry.FindLast then begin
            TempSalesAdvanceLetterEntry.SetRange("Entry Type");
            TempSalesAdvanceLetterEntry.FindLast;
        end;
        TempSalesAdvanceLetterEntry.SetRange("Entry Type");
        repeat
            if TempSalesAdvanceLetterEntry."Deduction Line No." = 0 then
                TempSalesAdvanceLetterEntry."Deduction Line No." := DeductionLineNo;
            TempSalesAdvanceLetterEntry.Modify();
        until TempSalesAdvanceLetterEntry.Next = 0;
    end;

    local procedure SaveDeductionEntries()
    var
        SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry";
        NextEntryNo: Integer;
    begin
        TempSalesAdvanceLetterEntry.Reset();
        if TempSalesAdvanceLetterEntry.FindSet then begin
            SalesAdvanceLetterEntry.LockTable();
            NextEntryNo := SalesAdvanceLetterEntry.GetLastEntryNo() + 1;
            repeat
                SalesAdvanceLetterEntry := TempSalesAdvanceLetterEntry;
                SalesAdvanceLetterEntry."Entry No." := NextEntryNo;
                SalesAdvanceLetterEntry.Insert();
                NextEntryNo += 1;
            until TempSalesAdvanceLetterEntry.Next = 0;
            TempSalesAdvanceLetterEntry.DeleteAll();
        end;
    end;

    [Scope('OnPrem')]
    procedure xGetLastPostNo(var LastPostedDocNo2: Code[20])
    begin
        LastPostedDocNo2 := LastPostedDocNo;
    end;

    [Scope('OnPrem')]
    procedure InsertTempApplnAdvanceLink(DtldEntryBufEntryNo: Integer)
    begin
        TempAdvanceLink.Init();
        TempAdvanceLink."Entry No." := DtldEntryBufEntryNo;
        TempAdvanceLink.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertApplnAdvanceLink(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    var
        AdvanceLink: Record "Advance Link";
    begin
        with AdvanceLink do
            if TempAdvanceLink.Get(DtldCVLedgEntryBuf."Entry No.") then begin
                if FindLast then
                    NextLinkEntryNo := "Entry No." + 1
                else
                    NextLinkEntryNo := 1;
                Init;
                "Entry No." := NextLinkEntryNo;
                "Entry Type" := "Entry Type"::Application;
                Type := Type::Sale;
                "Document No." := DtldCVLedgEntryBuf."Document No.";
                "CV Ledger Entry No." := DtldCVLedgEntryBuf."CV Ledger Entry No.";
                Amount := DtldCVLedgEntryBuf.Amount;
                "Amount (LCY)" := DtldCVLedgEntryBuf."Amount (LCY)";
                "Currency Code" := DtldCVLedgEntryBuf."Currency Code";
                Insert;
                TempAdvanceLink.Delete();
            end;
    end;

    [Scope('OnPrem')]
    procedure UnPostInvoiceCorrection(SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry";
        SalesAdvanceLetterEntry2: Record "Sales Advance Letter Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AdvanceLink2: Record "Advance Link";
        SalesAdvanceLetterLine2: Record "Sales Advance Letter Line";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        TempSalesAdvanceLetterEntry: Record "Sales Advance Letter Entry" temporary;
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        VATEntry: Record "VAT Entry";
        TempSalesAdvanceLetterEntry2: Record "Sales Advance Letter Entry" temporary;
        DocType: Option " ","Order",Invoice;
        DocNo: Code[20];
        EntryNo: Integer;
        AdvanceLinkEntryNo: Integer;
    begin
        if not Confirm(Text4005245Qst, false, SalesInvHeader."No.") then
            exit;
        DocType := DocType::Invoice;
        DocNo := SalesInvHeader."Pre-Assigned No.";
        if SalesInvHeader."Order No." <> '' then begin
            DocType := DocType::Order;
            DocNo := SalesInvHeader."Order No.";
        end;
        SalesAdvanceLetterEntry.SetCurrentKey("Document No.", "Posting Date");
        SalesAdvanceLetterEntry.SetRange("Document No.", SalesInvHeader."No.");
        SalesAdvanceLetterEntry.SetRange("Posting Date", SalesInvHeader."Posting Date");
        SalesAdvanceLetterEntry.SetRange("Customer No.", SalesInvHeader."Bill-to Customer No.");
        SalesAdvanceLetterEntry.SetRange(Cancelled, false);
        if SalesAdvanceLetterEntry.Find('+') then begin
            SourceCodeSetup.Get();
            SetCurrencyPrecision(SalesInvHeader."Currency Code");
            SalesAdvanceLetterEntry2.LockTable();
            SalesAdvanceLetterEntry2.Find('+');
            EntryNo := SalesAdvanceLetterEntry2."Entry No.";
            AdvanceLink2.LockTable();
            AdvanceLink2.FindLast;
            AdvanceLinkEntryNo := AdvanceLink2."Entry No.";
            repeat
                case SalesAdvanceLetterEntry."Entry Type" of
                    SalesAdvanceLetterEntry."Entry Type"::Deduction:
                        begin
                            SalesAdvanceLetterLine2.Get(SalesAdvanceLetterEntry."Letter No.", SalesAdvanceLetterEntry."Letter Line No.");
                            SalesAdvanceLetterLine2."Amount To Deduct" := SalesAdvanceLetterLine2."Amount To Deduct" +
                              SalesAdvanceLetterEntry.Amount;
                            SalesAdvanceLetterLine2."Amount Deducted" := SalesAdvanceLetterLine2."Amount Deducted" -
                              SalesAdvanceLetterEntry.Amount;
                            SalesAdvanceLetterLine2.SuspendStatusCheck(true);
                            SalesAdvanceLetterLine2.Modify(true);
                            if SalesAdvanceLetterHeader."No." <> SalesAdvanceLetterLine2."Letter No." then begin
                                SalesAdvanceLetterHeader.Get(SalesAdvanceLetterLine2."Letter No.");
                                if SalesAdvanceLetterHeader.Closed then begin
                                    SalesAdvanceLetterHeader.Closed := false;
                                    SalesAdvanceLetterHeader.Modify();
                                end;
                            end;
                            AdvanceLetterLineRelation.Get(AdvanceType::Sale, DocType, DocNo,
                              SalesAdvanceLetterEntry."Sale Line No.",
                              SalesAdvanceLetterEntry."Letter No.",
                              SalesAdvanceLetterEntry."Letter Line No.");
                            AdvanceLetterLineRelation."Deducted Amount" -= SalesAdvanceLetterEntry.Amount;
                            AdvanceLetterLineRelation.Modify();
                            UnPostInvCorrSalesLine(DocType, DocNo, SalesAdvanceLetterEntry);
                            AdvanceLetterLineRelation.CancelRelation(AdvanceLetterLineRelation, true, true, true);
                            TempSalesAdvanceLetterEntry := SalesAdvanceLetterEntry;
                            TempSalesAdvanceLetterEntry.Insert();
                        end;
                    SalesAdvanceLetterEntry."Entry Type"::"VAT Deduction":
                        begin
                            SalesAdvanceLetterLine2.Get(SalesAdvanceLetterEntry."Letter No.", SalesAdvanceLetterEntry."Letter Line No.");
                            PrepareInvJnlLine(GenJnlLine, SalesAdvanceLetterLine2, SalesInvHeader);
                            GenJnlLine.Correction := true;
                            GenJnlLine."Source Code" := SourceCodeSetup."Sales Entry Application";
                            GenJnlLine."Document No." := SalesInvHeader."No.";
                            SetPostingGroups(GenJnlLine, SalesAdvanceLetterLine2, false);
                            GenJnlLine."Account No." := SalesAdvanceLetterLine2."No.";
                            GenJnlLine."Advance VAT Base Amount" := -SalesAdvanceLetterEntry."VAT Base Amount (LCY)";
                            SalesAdvanceLetterEntry2.Get(SalesAdvanceLetterEntry."Entry No.");
                            if (SalesAdvanceLetterEntry2.Next > 0) and
                               (SalesAdvanceLetterEntry2."Entry Type" = SalesAdvanceLetterEntry2."Entry Type"::"VAT Rate")
                            then
                                GenJnlLine."Advance Exch. Rate Difference" := -SalesAdvanceLetterEntry2."VAT Amount (LCY)";
                            GenJnlLine.Validate(Amount, -SalesAdvanceLetterEntry."VAT Amount (LCY)");
                            UnPostInvCorrGL(SalesInvHeader, GenJnlLine);
                            if SalesAdvanceLetterLine2."VAT Calculation Type" <>
                               SalesAdvanceLetterLine2."VAT Calculation Type"::"Reverse Charge VAT"
                            then begin
                                VATPostingSetup.Get(SalesAdvanceLetterLine2."VAT Bus. Posting Group",
                                  SalesAdvanceLetterLine2."VAT Prod. Posting Group");
                                VATPostingSetup.TestField("Sales Advance Offset VAT Acc.");
                                GenJnlLine."Account No." := VATPostingSetup."Sales Advance Offset VAT Acc.";
                                GenJnlLine."Advance VAT Base Amount" := 0;
                                SetPostingGroups(GenJnlLine, SalesAdvanceLetterLine2, true);
                                GenJnlLine.Validate(Amount, SalesAdvanceLetterEntry."VAT Amount (LCY)");
                                UnPostInvCorrGL(SalesInvHeader, GenJnlLine);
                            end;
                        end;
                    SalesAdvanceLetterEntry."Entry Type"::"VAT Rate":
                        begin
                            SalesAdvanceLetterLine2.Get(SalesAdvanceLetterEntry."Letter No.", SalesAdvanceLetterEntry."Letter Line No.");
                            if SalesAdvanceLetterLine2."VAT Calculation Type" <>
                               SalesAdvanceLetterLine2."VAT Calculation Type"::"Reverse Charge VAT"
                            then begin
                                PrepareInvJnlLine(GenJnlLine, SalesAdvanceLetterLine2, SalesInvHeader);
                                GenJnlLine.Correction := true;
                                GenJnlLine."Source Code" := SourceCodeSetup."Sales Entry Application";
                                GenJnlLine."Document No." := SalesInvHeader."No.";
                                SetPostingGroups(GenJnlLine, SalesAdvanceLetterLine2, true);
                                GenJnlLine."Advance Exch. Rate Difference" := -SalesAdvanceLetterEntry."VAT Amount (LCY)";
                                if GenJnlLine."Advance Exch. Rate Difference" < 0 then begin
                                    Currency.TestField("Realized Losses Acc.");
                                    GenJnlLine."Account No." := Currency."Realized Losses Acc."
                                end else begin
                                    Currency.TestField("Realized Gains Acc.");
                                    GenJnlLine."Account No." := Currency."Realized Gains Acc.";
                                end;
                                GenJnlLine.Validate(Amount, GenJnlLine."Advance Exch. Rate Difference");
                                UnPostInvCorrGL(SalesInvHeader, GenJnlLine);
                                VATPostingSetup.Get(SalesAdvanceLetterLine2."VAT Bus. Posting Group",
                                  SalesAdvanceLetterLine2."VAT Prod. Posting Group");
                                VATPostingSetup.TestField("Sales Advance Offset VAT Acc.");
                                GenJnlLine."Account No." := VATPostingSetup."Sales Advance Offset VAT Acc.";
                                GenJnlLine.Validate(Amount, -GenJnlLine."Advance Exch. Rate Difference");
                                UnPostInvCorrGL(SalesInvHeader, GenJnlLine);
                            end;
                        end;
                end;
                SalesAdvanceLetterEntry2 := SalesAdvanceLetterEntry;
                SalesAdvanceLetterEntry2.Cancelled := true;
                SalesAdvanceLetterEntry2.Modify();
                EntryNo := EntryNo + 1;
                SalesAdvanceLetterEntry2."Entry No." := EntryNo;
                SalesAdvanceLetterEntry2.Amount := -SalesAdvanceLetterEntry2.Amount;
                SalesAdvanceLetterEntry2."VAT Base Amount (LCY)" := -SalesAdvanceLetterEntry2."VAT Base Amount (LCY)";
                SalesAdvanceLetterEntry2."VAT Amount (LCY)" := -SalesAdvanceLetterEntry2."VAT Amount (LCY)";
                SalesAdvanceLetterEntry2."VAT Base Amount" := -SalesAdvanceLetterEntry2."VAT Base Amount";
                SalesAdvanceLetterEntry2."VAT Amount" := -SalesAdvanceLetterEntry2."VAT Amount";
                if SalesAdvanceLetterEntry2."Entry Type" in [SalesAdvanceLetterEntry2."Entry Type"::"VAT Deduction",
                                                             SalesAdvanceLetterEntry2."Entry Type"::"VAT Rate"]
                then begin
                    VATEntry.FindLast;
                    SalesAdvanceLetterEntry2."Transaction No." := VATEntry."Transaction No.";
                    SalesAdvanceLetterEntry2."VAT Entry No." := VATEntry."Entry No.";
                end;
                SalesAdvanceLetterEntry2.Insert();
                TempSalesAdvanceLetterEntry2 := SalesAdvanceLetterEntry2;
                TempSalesAdvanceLetterEntry2.Insert();
            until SalesAdvanceLetterEntry.Next(-1) = 0;
            UnPostInvCorrUpdt(SalesInvHeader, AdvanceLinkEntryNo, SourceCodeSetup, TempSalesAdvanceLetterEntry);
            UnPostInvCorrInvDoc(SalesInvHeader, TempSalesAdvanceLetterEntry2);
        end;
    end;

    local procedure UnPostInvCorrGL(SalesInvHeader: Record "Sales Invoice Header"; GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Shortcut Dimension 1 Code" := SalesInvHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := SalesInvHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := SalesInvHeader."Dimension Set ID";
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure UnPostInvCorrSalesLine(DocType: Option " ","Order",Invoice; DocNo: Code[20]; SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry")
    var
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
    begin
        if SalesLine.Get(DocType, DocNo, SalesAdvanceLetterEntry."Sale Line No.") then begin
            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
            if SalesLine."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                Currency.Get(SalesLine."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
            if SalesHeader."Prices Including VAT" then
                SalesLine."Prepmt Amt Deducted" := SalesLine."Prepmt Amt Deducted" -
                  SalesAdvanceLetterEntry.Amount
            else
                SalesLine."Prepmt Amt Deducted" := SalesLine."Prepmt Amt Deducted" -
                  Round(SalesAdvanceLetterEntry.Amount /
                    (1 + SalesLine."VAT %" / 100),
                    Currency."Amount Rounding Precision");
            SalesLine.Modify();
        end;
    end;

    local procedure UnapplyCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; UnapplyDocNo: Code[20])
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry3: Record "Detailed Cust. Ledg. Entry";
        GenJnlLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        Succes: Boolean;
    begin
        SourceCodeSetup.Get();
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if UnapplyDocNo <> '' then
            DtldCustLedgEntry.SetRange("Document No.", UnapplyDocNo);
        Succes := false;
        repeat
            if DtldCustLedgEntry.FindLast then begin
                DtldCustLedgEntry2.Reset();
                DtldCustLedgEntry2.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
                DtldCustLedgEntry2.SetRange("Transaction No.", DtldCustLedgEntry."Transaction No.");
                DtldCustLedgEntry2.SetRange("Customer No.", DtldCustLedgEntry."Customer No.");
                if DtldCustLedgEntry2.FindSet then
                    repeat
                        if (DtldCustLedgEntry2."Entry Type" <> DtldCustLedgEntry2."Entry Type"::"Initial Entry") and
                           not DtldCustLedgEntry2.Unapplied
                        then
                            DtldCustLedgEntry3.Reset();
                        DtldCustLedgEntry3.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
                        DtldCustLedgEntry3.SetRange("Cust. Ledger Entry No.", DtldCustLedgEntry2."Cust. Ledger Entry No.");
                        DtldCustLedgEntry3.SetRange(Unapplied, false);
                        if DtldCustLedgEntry3.FindLast and
                           (DtldCustLedgEntry3."Transaction No." > DtldCustLedgEntry2."Transaction No.")
                        then
                            Error(Text4005246Err, DtldCustLedgEntry3."Cust. Ledger Entry No.");
                    until DtldCustLedgEntry2.Next = 0;

                GenJnlLine.Init();
                GenJnlLine."Document No." := DtldCustLedgEntry."Document No.";
                GenJnlLine."Posting Date" := DtldCustLedgEntry."Posting Date";
                GenJnlLine."VAT Date" := GenJnlLine."Posting Date";
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
                GenJnlLine."Account No." := DtldCustLedgEntry."Customer No.";
                GenJnlLine.Correction := true;
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                GenJnlLine.Description := CustLedgEntry.Description;
                GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                GenJnlLine."Posting Group" := CustLedgEntry."Customer Posting Group";
                GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                GenJnlLine."Source No." := DtldCustLedgEntry."Customer No.";
                GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Sales Entry Appln.";
                GenJnlLine."Source Currency Code" := DtldCustLedgEntry."Currency Code";
                GenJnlLine."System-Created Entry" := true;
                GenJnlPostLine.UnapplyCustLedgEntry(GenJnlLine, DtldCustLedgEntry);
            end else
                Succes := true;
        until Succes;
    end;

    local procedure UnPostInvCorrUpdt(SalesInvHeader: Record "Sales Invoice Header"; AdvanceLinkEntryNo: Integer; SourceCodeSetup: Record "Source Code Setup"; var TempSalesAdvanceLetterEntry: Record "Sales Advance Letter Entry" temporary)
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        AdvanceLink: Record "Advance Link";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document No.", SalesInvHeader."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Customer No.", SalesInvHeader."Bill-to Customer No.");
        CustLedgEntry.FindFirst;
        UnapplyCustLedgEntry(CustLedgEntry, SalesInvHeader."No.");

        AdvanceLink.Reset();
        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Document No.", SalesInvHeader."No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::Application);
        AdvanceLink.SetFilter("Entry No.", '..%1', AdvanceLinkEntryNo);
        AdvanceLink.CalcSums(Amount);

        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Payment);
        CustLedgEntry.SetRange(Prepayment, false);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.FindFirst;
        CustLedgEntry."Amount to Apply" := -AdvanceLink.Amount;
        CustLedgEntry.Modify();

        GenJnlLine.Init();
        GenJnlLine.Prepayment := false;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
        PreparePmtJnlLine(GenJnlLine, SalesInvHeader);
        GenJnlLine."Source Code" := SourceCodeSetup."Sales Entry Application";
        GenJnlLine.Validate("Currency Code", SalesInvHeader."Currency Code");
        if GenJnlLine."Currency Code" <> '' then
            GenJnlLine.Validate("Currency Factor", CustLedgEntry."Original Currency Factor");
        GenJnlLine.Validate(Amount, AdvanceLink.Amount);
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Payment;
        GenJnlLine."Applies-to Doc. No." := SalesInvHeader."No.";
        UnPostInvCorrGL(SalesInvHeader, GenJnlLine);

        if AdvanceLink.FindSet(true) then
            repeat
                if TempCustLedgEntry.Get(AdvanceLink."CV Ledger Entry No.") then begin
                    TempCustLedgEntry."Amount to Apply" := TempCustLedgEntry."Amount to Apply" + AdvanceLink.Amount;
                    TempCustLedgEntry.Modify();
                end else begin
                    CustLedgEntry.Get(AdvanceLink."CV Ledger Entry No.");
                    CustLedgEntry.TestField(Reversed, false);
                    TempCustLedgEntry := CustLedgEntry;
                    TempCustLedgEntry."Amount to Apply" := AdvanceLink.Amount;
                    TempCustLedgEntry.Insert();
                end;
            until AdvanceLink.Next = 0;

        TempCustLedgEntry.SetFilter("Amount to Apply", '<>0');
        if TempCustLedgEntry.FindSet then begin
            GenJnlLine.Init();
            GenJnlLine.Prepayment := true;
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
            PreparePmtJnlLine(GenJnlLine, SalesInvHeader);
            GenJnlLine."Source Code" := SourceCodeSetup."Sales Entry Application";
            repeat
                CustLedgEntry.Get(TempCustLedgEntry."Entry No.");
                UnapplyCustLedgEntry(CustLedgEntry, SalesInvHeader."No.");

                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Refund);
                CustLedgEntry.SetRange(Prepayment, true);
                CustLedgEntry.SetRange(Open, true);
                CustLedgEntry.FindFirst;
                CustLedgEntry."Amount to Apply" := TempCustLedgEntry."Amount to Apply";
                CustLedgEntry.Modify();

                GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code");
                if CustLedgEntry."Currency Code" <> '' then begin
                    CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    if CustLedgEntry."Remaining Amt. (LCY)" <> 0 then
                        GenJnlLine.Validate("Currency Factor", CustLedgEntry."Remaining Amount" / CustLedgEntry."Remaining Amt. (LCY)")
                    else
                        GenJnlLine.Validate("Currency Factor", CustLedgEntry."Adjusted Currency Factor");
                end;
                GenJnlLine.Validate(Amount, -TempCustLedgEntry."Amount to Apply");
                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Refund;
                GenJnlLine."Applies-to Doc. No." := SalesInvHeader."No.";
                GenJnlLine."Posting Group" := CustLedgEntry."Customer Posting Group";
                UnPostInvCorrGL(SalesInvHeader, GenJnlLine);
            until TempCustLedgEntry.Next = 0;
        end;

        // Correct Remaining Amount
        if TempSalesAdvanceLetterEntry.FindSet then
            repeat
                AdvanceLink.Reset();
                AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
                AdvanceLink.SetRange("Document No.", TempSalesAdvanceLetterEntry."Letter No.");
                AdvanceLink.SetRange("Line No.", TempSalesAdvanceLetterEntry."Letter Line No.");
                AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                AdvanceLink.SetRange("CV Ledger Entry No.", TempSalesAdvanceLetterEntry."Customer Entry No.");
                if AdvanceLink.FindSet then
                    repeat
                        AdvanceLink."Remaining Amount to Deduct" := AdvanceLink."Remaining Amount to Deduct" +
                          TempSalesAdvanceLetterEntry.Amount;
                        if Abs(AdvanceLink."Remaining Amount to Deduct") > Abs(AdvanceLink.Amount) then
                            AdvanceLink.FieldError("Remaining Amount to Deduct");
                        AdvanceLink.Modify();
                    until (AdvanceLink.Next = 0) or (TempSalesAdvanceLetterEntry.Amount = 0);
            until TempSalesAdvanceLetterEntry.Next = 0;
    end;

    local procedure UnPostInvCorrInvDoc(SalesInvHeader: Record "Sales Invoice Header"; var TempSalesAdvanceLetterEntry2: Record "Sales Advance Letter Entry" temporary)
    var
        SalesInvLine: Record "Sales Invoice Line";
        SalesInvLine2: Record "Sales Invoice Line";
        SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry";
    begin
        // Correct Invoice document
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetRange("Prepayment Line", true);
        SalesInvLine.SetRange("Prepayment Cancelled", false);
        if SalesInvLine.FindSet(true, true) then
            repeat
                SalesInvLine2 := SalesInvLine;
                SalesInvLine2."Prepayment Cancelled" := true;
                SalesInvLine2.Modify();
                if SalesInvLine.Quantity <> 0 then begin
                    SalesInvLine2."Line No." := SalesInvLine2."Line No." + 1;
                    SalesInvLine2.Quantity := -SalesInvLine2.Quantity;
                    SalesInvLine2.Amount := -SalesInvLine2.Amount;
                    SalesInvLine2."Amount Including VAT" := -SalesInvLine2."Amount Including VAT";
                    SalesInvLine2."VAT Base Amount" := -SalesInvLine2."VAT Base Amount";
                    SalesInvLine2."Line Amount" := -SalesInvLine2."Line Amount";
                    SalesInvLine2.Insert();
                    TempSalesAdvanceLetterEntry2.SetRange("Deduction Line No.", SalesInvLine."Line No.");
                    if TempSalesAdvanceLetterEntry2.FindSet then begin
                        repeat
                            SalesAdvanceLetterEntry.Get(TempSalesAdvanceLetterEntry2."Entry No.");
                            SalesAdvanceLetterEntry."Deduction Line No." := SalesInvLine2."Line No.";
                            SalesAdvanceLetterEntry.Modify();
                        until TempSalesAdvanceLetterEntry2.Next = 0;
                    end;
                end;
            until SalesInvLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcAmtLCYToACY(PostingDate: Date; AmountLCY: Decimal): Decimal
    var
        GLSetup: Record "General Ledger Setup";
        AddCurrency: Record Currency;
        CurrencyFactor: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" = '' then
            exit;

        AddCurrency.Get(GLSetup."Additional Reporting Currency");

        CurrencyFactor :=
          CurrExchRate.ExchangeRate(
            PostingDate, AddCurrency.Code);

        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              PostingDate, GLSetup."Additional Reporting Currency", AmountLCY, CurrencyFactor),
            AddCurrency."Amount Rounding Precision"));
    end;

    [Scope('OnPrem')]
    procedure DeleteTempApplnAdvanceLink()
    begin
        TempAdvanceLink.Reset();
        TempAdvanceLink.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CheckPostingDateOnRefund(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date)
    var
        AdvanceLink: Record "Advance Link";
    begin
        AdvanceLink.Reset();
        AdvanceLink.SetCurrentKey("Entry Type", "Document No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterHeader."No.");
        if AdvanceLink.FindSet(false, false) then
            repeat
                if PostingDate < AdvanceLink."Posting Date" then
                    Error(Text042Err, SalesAdvanceLetterHeader."No.");
            until AdvanceLink.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure BuildInvoiceLineBuf(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        AdvanceLink: Record "Advance Link";
        CustLedgEntry: Record "Cust. Ledger Entry";
        RoundingPrecision: Decimal;
        RoundingDirection: Text[1];
        ResidumAmtLCY: Decimal;
        NewVATAmountLCY: Decimal;
        ResidumAmt: Decimal;
        NewVATAmount: Decimal;
        ResidumTotalAmtLCY: Decimal;
        NewTotalAmtLCY: Decimal;
    begin
        PrepmtInvLineBuf.Reset();
        PrepmtInvLineBuf.DeleteAll();
        SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        if SalesAdvanceLetterLine.FindSet then
            repeat
                if SalesAdvanceLetterLine."Amount To Invoice" <> 0 then begin
                    if SalesAdvanceLetterLine."Currency Code" <> '' then begin
                        AdvanceLink.SetCurrentKey("Document No.", "Line No.");
                        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterHeader."No.");
                        AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
                        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                        AdvanceLink.FindLast;
                        CustLedgEntry.Get(AdvanceLink."CV Ledger Entry No.");
                    end;

                    with PrepmtInvLineBuf do begin
                        Clear(PrepmtInvLineBuf);
                        if not TempVATAmountLine.Get(
                             SalesAdvanceLetterLine."VAT Identifier", SalesAdvanceLetterLine."VAT Calculation Type",
                             SalesAdvanceLetterLine."Tax Group Code", false, SalesAdvanceLetterLine."Amount To Invoice" >= 0)
                        then begin
                            Clear(TempVATAmountLine);
                            TempVATAmountLine.Init();
                            TempVATAmountLine."VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
                            TempVATAmountLine."VAT Calculation Type" := SalesAdvanceLetterLine."VAT Calculation Type";
                            TempVATAmountLine."Tax Group Code" := SalesAdvanceLetterLine."Tax Group Code";
                            TempVATAmountLine."VAT %" := SalesAdvanceLetterLine."VAT %";
                            TempVATAmountLine.Modified := true;
                            TempVATAmountLine.Positive := SalesAdvanceLetterLine."Amount To Invoice" >= 0;
                            TempVATAmountLine."Currency Code" := SalesAdvanceLetterLine."Currency Code";
                            TempVATAmountLine.Quantity := 1;
                            TempVATAmountLine.Insert();
                        end;
                        TempVATAmountLine."Amount Including VAT" := TempVATAmountLine."Amount Including VAT" +
                          SalesAdvanceLetterLine."Amount To Invoice";
                        TempVATAmountLine.Modify();

                        CopyAdvLetterLineToBuffer(PrepmtInvLineBuf, SalesAdvanceLetterLine);
                        "Amount Incl. VAT" := SalesAdvanceLetterLine."Amount To Invoice";

                        if SalesAdvanceLetterHeader."Currency Code" = '' then
                            "Amount Incl. VAT (LCY)" := "Amount Incl. VAT";

                        SetCurrencyPrecision(SalesAdvanceLetterLine."Currency Code");

                        Amount :=
                          Round(
                            "Amount Incl. VAT" * SalesAdvanceLetterLine.Amount / SalesAdvanceLetterLine."Amount Including VAT",
                            Currency."Amount Rounding Precision");

                        "VAT Base Amount" := Amount;
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then begin
                            VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                            "VAT Amount" :=
                              Round(
                                Amount * VATPostingSetup."VAT %" / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection)
                        end else
                            "VAT Amount" := "Amount Incl. VAT" - Amount;
                        "Amount (ACY)" := Amount;
                        "VAT Base Amount (ACY)" := Amount;
                        "VAT Amount (ACY)" := "VAT Amount";
                        "VAT %" := SalesAdvanceLetterLine."VAT %";
                        "VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
                        "Tax Area Code" := SalesAdvanceLetterLine."Tax Area Code";
                        "Tax Liable" := SalesAdvanceLetterLine."Tax Liable";
                        "Tax Group Code" := SalesAdvanceLetterLine."Tax Group Code";
                        "Line No." := SalesAdvanceLetterLine."Line No.";
                        Description := SalesAdvanceLetterLine.Description;

                        Insert;
                    end;
                end;

            until SalesAdvanceLetterLine.Next = 0;

        GLSetup.Get();
        if GLSetup."Round VAT Coeff." then
            GLSetup.GetRoundingParamenters(Currency, RoundingPrecision, RoundingDirection);

        if TempVATAmountLine.Find('-') then begin
            repeat
                if SalesAdvanceLetterHeader."Currency Code" <> '' then
                    TempVATAmountLine."Amount Including VAT (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          CustLedgEntry."Posting Date", SalesAdvanceLetterHeader."Currency Code",
                          TempVATAmountLine."Amount Including VAT", CustLedgEntry."Original Currency Factor"))
                else
                    TempVATAmountLine."Amount Including VAT (LCY)" := TempVATAmountLine."Amount Including VAT";

                if GLSetup."Round VAT Coeff." then begin
                    TempVATAmountLine."VAT Amount" :=
                      Round(
                        TempVATAmountLine."Amount Including VAT" * Round(
                          TempVATAmountLine."VAT %" / (100 + TempVATAmountLine."VAT %"), GLSetup."VAT Coeff. Rounding Precision"),
                        RoundingPrecision,
                        RoundingDirection);

                    TempVATAmountLine."VAT Amount (LCY)" :=
                      Round(
                        TempVATAmountLine."Amount Including VAT (LCY)" * Round(
                          TempVATAmountLine."VAT %" / (100 + TempVATAmountLine."VAT %"), GLSetup."VAT Coeff. Rounding Precision"),
                        RoundingPrecision,
                        RoundingDirection);
                end else begin
                    TempVATAmountLine."VAT Amount" :=
                      Round(TempVATAmountLine."Amount Including VAT" * TempVATAmountLine."VAT %" / (100 + TempVATAmountLine."VAT %"),
                        Currency."Amount Rounding Precision", Currency.VATRoundingDirection);

                    TempVATAmountLine."VAT Amount (LCY)" :=
                      Round(TempVATAmountLine."Amount Including VAT (LCY)" * TempVATAmountLine."VAT %" / (100 + TempVATAmountLine."VAT %"),
                        Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                end;
                TempVATAmountLine.Modify();

                ResidumAmtLCY := 0;
                ResidumAmt := 0;
                ResidumTotalAmtLCY := 0;

                PrepmtInvLineBuf.SetRange("VAT Identifier", TempVATAmountLine."VAT Identifier");
                PrepmtInvLineBuf.SetRange("VAT Calculation Type", TempVATAmountLine."VAT Calculation Type");
                PrepmtInvLineBuf.SetRange("Tax Group Code", TempVATAmountLine."Tax Group Code");
                if PrepmtInvLineBuf.Find('-') then begin
                    repeat
                        NewVATAmountLCY := ResidumAmtLCY +
                          (TempPrepmtInvLineBuf."Amount Incl. VAT" / TempVATAmountLine."Amount Including VAT") *
                          TempVATAmountLine."VAT Amount (LCY)";
                        PrepmtInvLineBuf."VAT Amount (LCY)" := Round(NewVATAmountLCY);
                        PrepmtInvLineBuf."Amount (LCY)" := TempPrepmtInvLineBuf."Amount Incl. VAT (LCY)" -
                          PrepmtInvLineBuf."VAT Amount (LCY)";
                        PrepmtInvLineBuf."VAT Base Amount (LCY)" := TempPrepmtInvLineBuf."Amount Incl. VAT (LCY)" -
                          PrepmtInvLineBuf."VAT Amount (LCY)";
                        ResidumAmtLCY := NewVATAmountLCY - Round(NewVATAmountLCY);

                        if SalesAdvanceLetterHeader."Currency Code" <> '' then begin
                            NewVATAmount := ResidumAmt +
                              (TempPrepmtInvLineBuf."Amount Incl. VAT" / TempVATAmountLine."Amount Including VAT") *
                              TempVATAmountLine."VAT Amount";
                            PrepmtInvLineBuf."VAT Amount" := Round(NewVATAmount);

                            NewTotalAmtLCY := ResidumTotalAmtLCY +
                              (TempPrepmtInvLineBuf."Amount Incl. VAT" / TempVATAmountLine."Amount Including VAT") *
                              TempVATAmountLine."Amount Including VAT (LCY)";
                            TempPrepmtInvLineBuf."Amount Incl. VAT (LCY)" := Round(NewTotalAmtLCY);
                            PrepmtInvLineBuf."Amount (LCY)" := TempPrepmtInvLineBuf."Amount Incl. VAT (LCY)" -
                              PrepmtInvLineBuf."VAT Amount (LCY)";
                            PrepmtInvLineBuf."VAT Base Amount (LCY)" := TempPrepmtInvLineBuf."Amount Incl. VAT (LCY)" -
                              PrepmtInvLineBuf."VAT Amount (LCY)";

                            PrepmtInvLineBuf.Amount := TempPrepmtInvLineBuf."Amount Incl. VAT" - PrepmtInvLineBuf."VAT Amount";
                            PrepmtInvLineBuf."VAT Base Amount" := TempPrepmtInvLineBuf."Amount Incl. VAT" - PrepmtInvLineBuf."VAT Amount";
                            ResidumAmt := NewVATAmount - Round(NewVATAmount);
                            ResidumTotalAmtLCY := NewTotalAmtLCY - Round(NewTotalAmtLCY);
                        end else begin
                            PrepmtInvLineBuf."VAT Amount" := PrepmtInvLineBuf."VAT Amount (LCY)";
                            PrepmtInvLineBuf.Amount := PrepmtInvLineBuf."Amount (LCY)";
                            PrepmtInvLineBuf."VAT Base Amount" := PrepmtInvLineBuf."VAT Base Amount (LCY)";
                        end;
                        PrepmtInvLineBuf.Modify();
                    until PrepmtInvLineBuf.Next = 0;
                end;

            until TempVATAmountLine.Next = 0;
        end;

        PrepmtInvLineBuf.Reset();
    end;

    [Scope('OnPrem')]
    procedure BuilCreditMemoBuf(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    var
        SalesAdvanceLetterEntry: Record "Sales Advance Letter Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        SalesInvLine2: Record "Sales Invoice Line";
    begin
        PrepmtInvLineBuf.Reset();
        PrepmtInvLineBuf.DeleteAll();
        Clear(PrepmtInvLineBuf);

        SalesInvHeader.Get(CurrSalesInvHeader."No.");

        SalesAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type", "Posting Date");
        SalesAdvanceLetterEntry.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        SalesAdvanceLetterEntry.SetRange("Entry Type", SalesAdvanceLetterEntry."Entry Type"::VAT);
        SalesAdvanceLetterEntry.SetRange("Document Type", SalesAdvanceLetterEntry."Document Type"::Invoice);
        SalesAdvanceLetterEntry.SetRange("Document No.", CurrSalesInvHeader."No.");
        SalesAdvanceLetterEntry.SetRange("Posting Date", SalesInvHeader."Posting Date");

        if SalesAdvanceLetterEntry.FindSet(false, false) then begin
            repeat
                PrepmtInvLineBuf.Init();
                SalesAdvanceLetterLine.Get(SalesAdvanceLetterEntry."Letter No.", SalesAdvanceLetterEntry."Letter Line No.");

                if SalesInvLine2.Get(SalesAdvanceLetterEntry."Document No.", SalesAdvanceLetterEntry."Sale Line No.") then;

                with PrepmtInvLineBuf do begin
                    "G/L Account No." := SalesAdvanceLetterLine."No.";
                    "Dimension Set ID" := SalesInvLine2."Dimension Set ID";
                    "Job No." := SalesAdvanceLetterLine."Job No.";
                    "Tax Area Code" := SalesAdvanceLetterLine."Tax Area Code";
                    "Tax Liable" := SalesAdvanceLetterLine."Tax Liable";
                    "Tax Group Code" := SalesAdvanceLetterLine."Tax Group Code";
                    "VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
                    "Line No." := SalesAdvanceLetterLine."Line No.";

                    if not Find then begin
                        "VAT %" := SalesAdvanceLetterLine."VAT %";
                        "Gen. Bus. Posting Group" := SalesAdvanceLetterLine."Gen. Bus. Posting Group";
                        "VAT Bus. Posting Group" := SalesAdvanceLetterLine."VAT Bus. Posting Group";
                        "Gen. Prod. Posting Group" := SalesAdvanceLetterLine."Gen. Prod. Posting Group";
                        "VAT Prod. Posting Group" := SalesAdvanceLetterLine."VAT Prod. Posting Group";
                        "VAT Calculation Type" := SalesAdvanceLetterLine."VAT Calculation Type";
                        "Global Dimension 1 Code" := SalesInvLine2."Shortcut Dimension 1 Code";
                        "Global Dimension 2 Code" := SalesInvLine2."Shortcut Dimension 2 Code";
                        Description := SalesAdvanceLetterLine.Description;
                        Insert;
                    end;
                end;
            until SalesAdvanceLetterEntry.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure AdvanceUpdateVATOnLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        PrepmtAmt: Decimal;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        PrepmtAmtToInvTotal: Decimal;
    begin
        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(SalesHeader."Currency Code");

        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Prepmt. Line Amount", '<>0');
            LockTable();
            if Find('-') then
                repeat
                    PrepmtAmtToInvTotal := PrepmtAmtToInvTotal + ("Prepmt. Line Amount" - "Prepmt. Amt. Inv.");
                until Next = 0;
            if Find('-') then
                repeat
                    PrepmtAmt := "Prepmt. Line Amount";
                    if PrepmtAmt <> 0 then begin
                        TempVATAmountLine.Get(
                          "VAT Identifier",
                          "VAT Calculation Type",
                          "Tax Group Code",
                          false,
                          PrepmtAmt >= 0);
                        if TempVATAmountLine.Modified then begin
                            if not TempVATAmountLineRemainder.Get(
                                 "VAT Identifier",
                                 "VAT Calculation Type",
                                 "Tax Group Code",
                                 false,
                                 PrepmtAmt >= 0)
                            then begin
                                TempVATAmountLineRemainder := TempVATAmountLine;
                                TempVATAmountLineRemainder.Init();
                                TempVATAmountLineRemainder.Insert();
                            end;

                            if SalesHeader."Prices Including VAT" then begin
                                if PrepmtAmt = 0 then begin
                                    VATAmount := 0;
                                    NewAmountIncludingVAT := 0;
                                end else begin
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      TempVATAmountLine."VAT Amount" * PrepmtAmt / TempVATAmountLine."Line Amount";
                                    NewAmountIncludingVAT :=
                                      TempVATAmountLineRemainder."Amount Including VAT" +
                                      TempVATAmountLine."Amount Including VAT" * PrepmtAmt / TempVATAmountLine."Line Amount";
                                end;
                                NewAmount :=
                                  Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                                  Round(VATAmount, Currency."Amount Rounding Precision");
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - SalesHeader."VAT Base Discount %" / 100),
                                    Currency."Amount Rounding Precision");
                            end else begin
                                NewAmount := PrepmtAmt;
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - SalesHeader."VAT Base Discount %" / 100),
                                    Currency."Amount Rounding Precision");
                                if TempVATAmountLine."VAT Base" = 0 then
                                    VATAmount := 0
                                else
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      TempVATAmountLine."VAT Amount" * NewAmount / TempVATAmountLine."VAT Base";
                                NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                            end;

                            "Prepayment Amount" := NewAmount;
                            "Prepmt. Amt. Incl. VAT" :=
                              Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");

                            "Prepmt. VAT Base Amt." := NewVATBaseAmount;

                            if (TempVATAmountLine."Line Amount" - TempVATAmountLine."Invoice Discount Amount") = 0 then
                                VATDifference := 0
                            else
                                if PrepmtAmtToInvTotal = 0 then
                                    VATDifference :=
                                      TempVATAmountLine."VAT Difference" * ("Prepmt. Line Amount" - "Prepmt. Amt. Inv.") /
                                      (TempVATAmountLine."Line Amount" - TempVATAmountLine."Invoice Discount Amount")
                                else
                                    VATDifference :=
                                      TempVATAmountLine."VAT Difference" * ("Prepmt. Line Amount" - "Prepmt. Amt. Inv.") /
                                      PrepmtAmtToInvTotal;

                            "Prepayment VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");

                            Modify;

                            TempVATAmountLineRemainder."Amount Including VAT" :=
                              NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                            TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                            TempVATAmountLineRemainder."VAT Difference" := VATDifference - "Prepayment VAT Difference";
                            TempVATAmountLineRemainder.Modify();
                        end;
                    end;
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure AdvanceCalcVATAmountLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        TempPrevVatAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        NewAmount: Decimal;
        RoundingPrecision: Decimal;
        RoundingDirection: Text[1];
    begin
        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(SalesHeader."Currency Code");

        TempVATAmountLine.DeleteAll();

        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Prepmt. Line Amount", '<>0');

            if Find('-') then
                repeat
                    NewAmount := "Prepmt. Line Amount";
                    if NewAmount <> 0 then begin
                        if "Prepmt. VAT Calc. Type" in
                           ["VAT Calculation Type"::"Reverse Charge VAT", "VAT Calculation Type"::"Sales Tax"]
                        then
                            "VAT %" := 0;
                        if not TempVATAmountLine.Get(
                             "VAT Identifier",
                             "VAT Calculation Type", "Tax Group Code",
                             false, NewAmount >= 0)
                        then begin
                            TempVATAmountLine.Init();
                            TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                            TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                            TempVATAmountLine."VAT %" := "VAT %";
                            TempVATAmountLine.Modified := true;
                            TempVATAmountLine.Positive := NewAmount >= 0;
                            TempVATAmountLine."Includes Prepayment" := true;
                            TempVATAmountLine.Insert();
                        end;
                        TempVATAmountLine."Line Amount" := TempVATAmountLine."Line Amount" + NewAmount;
                        TempVATAmountLine.Modify();
                    end;
                until Next = 0;
        end;

        with TempVATAmountLine do
            if Find('-') then
                repeat
                    if (TempPrevVatAmountLine."VAT Identifier" <> "VAT Identifier") or
                       (TempPrevVatAmountLine."VAT Calculation Type" <> "VAT Calculation Type") or
                       (TempPrevVatAmountLine."Tax Group Code" <> "Tax Group Code") or
                       (TempPrevVatAmountLine."Use Tax" <> "Use Tax")
                    then
                        TempPrevVatAmountLine.Init();
                    if SalesHeader."Prices Including VAT" then
                        case "VAT Calculation Type" of
                            "VAT Calculation Type"::"Normal VAT",
                            "VAT Calculation Type"::"Reverse Charge VAT":
                                begin
                                    GLSetup.Get();
                                    GLSetup.GetRoundingParamenters(Currency, RoundingPrecision, RoundingDirection);

                                    if GLSetup."Round VAT Coeff." then begin
                                        "VAT Amount" :=
                                          Round(
                                            TempPrevVatAmountLine."VAT Amount" +
                                            ("Line Amount" - "Invoice Discount Amount") *
                                            Round("VAT %" / (100 + "VAT %"), GLSetup."VAT Coeff. Rounding Precision") *
                                            (1 - SalesHeader."VAT Base Discount %" / 100),
                                            RoundingPrecision,
                                            RoundingDirection);

                                        "VAT Base" := "Line Amount" - "VAT Amount";
                                    end else begin
                                        "VAT Base" :=
                                          Round(
                                            ("Line Amount" - "Invoice Discount Amount") / (1 + "VAT %" / 100),
                                            Currency."Amount Rounding Precision") - "VAT Difference";
                                        "VAT Amount" :=
                                          "VAT Difference" +
                                          Round(
                                            TempPrevVatAmountLine."VAT Amount" +
                                            ("Line Amount" - "VAT Base" - "VAT Difference") *
                                            (1 - SalesHeader."VAT Base Discount %" / 100),
                                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    end;
                                    "Amount Including VAT" := "VAT Base" + "VAT Amount";
                                    if Positive then
                                        TempPrevVatAmountLine.Init
                                    else begin
                                        TempPrevVatAmountLine := TempVATAmountLine;
                                        TempPrevVatAmountLine."VAT Amount" :=
                                          ("Line Amount" - "VAT Base" - "VAT Difference") *
                                          (1 - SalesHeader."VAT Base Discount %" / 100);
                                        TempPrevVatAmountLine."VAT Amount" :=
                                          TempPrevVatAmountLine."VAT Amount" -
                                          Round(TempPrevVatAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    end;
                                end;
                            "VAT Calculation Type"::"Sales Tax":
                                begin
                                    "Amount Including VAT" := "Line Amount" - "Invoice Discount Amount";
                                    "VAT Base" :=
                                      Round(
                                        SalesTaxCalculate.ReverseCalculateTax(
                                          SalesHeader."Tax Area Code", "Tax Group Code", SalesHeader."Tax Liable",
                                          SalesHeader."Posting Date", "Amount Including VAT", Quantity, SalesHeader."Currency Factor"),
                                        Currency."Amount Rounding Precision");
                                    "VAT Amount" := "VAT Difference" + "Amount Including VAT" - "VAT Base";
                                    if "VAT Base" = 0 then
                                        "VAT %" := 0
                                    else
                                        "VAT %" := Round(100 * "VAT Amount" / "VAT Base", 0.00001);
                                end;
                        end
                    else
                        case "VAT Calculation Type" of
                            "VAT Calculation Type"::"Normal VAT",
                            "VAT Calculation Type"::"Reverse Charge VAT":
                                begin
                                    "VAT Base" := "Line Amount" - "Invoice Discount Amount";
                                    "VAT Amount" :=
                                      "VAT Difference" +
                                      Round(
                                        TempPrevVatAmountLine."VAT Amount" +
                                        "VAT Base" * "VAT %" / 100 * (1 - SalesHeader."VAT Base Discount %" / 100),
                                        Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    "Amount Including VAT" := "Line Amount" - "Invoice Discount Amount" + "VAT Amount";
                                    if Positive then
                                        TempPrevVatAmountLine.Init
                                    else begin
                                        TempPrevVatAmountLine := TempVATAmountLine;
                                        TempPrevVatAmountLine."VAT Amount" :=
                                          "VAT Base" * "VAT %" / 100 * (1 - SalesHeader."VAT Base Discount %" / 100);
                                        TempPrevVatAmountLine."VAT Amount" :=
                                          TempPrevVatAmountLine."VAT Amount" -
                                          Round(TempPrevVatAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    end;
                                end;
                            "VAT Calculation Type"::"Sales Tax":
                                begin
                                    "VAT Base" := "Line Amount" - "Invoice Discount Amount";
                                    "VAT Amount" :=
                                      SalesTaxCalculate.CalculateTax(
                                        SalesHeader."Tax Area Code", "Tax Group Code", SalesHeader."Tax Liable",
                                        SalesHeader."Posting Date", "VAT Base", Quantity, SalesHeader."Currency Factor");
                                    if "VAT Base" = 0 then
                                        "VAT %" := 0
                                    else
                                        "VAT %" := Round(100 * "VAT Amount" / "VAT Base", 0.00001);
                                    "VAT Amount" :=
                                      "VAT Difference" +
                                      Round("VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    "Amount Including VAT" := "VAT Base" + "VAT Amount";
                                end;
                        end;
                    "Calculated VAT Amount" := "VAT Amount" - "VAT Difference";
                    Modify;
                until Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateAdvanceInvLineBuf(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TempAdvanceLetterLineRelation: Record "Advance Letter Line Relation" temporary)
    var
        GLAcc: Record "G/L Account";
        TempSalesLine: Record "Sales Line" temporary;
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempPrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        BufEntryNo: Integer;
    begin
        with SalesHeader do begin
            TempAdvanceLetterLineRelation.DeleteAll();
            BufEntryNo := 0;

            SalesLine2.SetRange("Document Type", "Document Type");
            SalesLine2.SetRange("Document No.", "No.");
            SalesLine2.SetFilter(Type, '<>%1', SalesLine2.Type::" ");
            SalesLine2.SetFilter("Prepmt. Line Amount", '<>0');
            if SalesLine2.FindSet(false, false) then begin
                repeat
                    TempSalesLine := SalesLine2;
                    TempSalesLine."Prepayment Amount" := 0;
                    TempSalesLine."Prepmt. Amt. Incl. VAT" := 0;
                    TempSalesLine."Prepmt. VAT Base Amt." := 0;
                    RecalcPrepm(TempSalesLine, "Prices Including VAT");
                    TempSalesLine.Insert();
                until SalesLine2.Next = 0;
            end;

            AdvanceCalcVATAmountLines(SalesHeader, TempSalesLine, TempVATAmountLine);
            AdvanceUpdateVATOnLines(SalesHeader, TempSalesLine, TempVATAmountLine);

            TempSalesLine.SetRange("Document Type", "Document Type");
            TempSalesLine.SetRange("Document No.", "No.");
            TempSalesLine.SetFilter(Type, '<>%1', TempSalesLine.Type::" ");
            TempSalesLine.SetFilter("Prepmt. Line Amount", '<>0');

            TempSalesLine.SetRange("System-Created Entry", false);
            if TempSalesLine.Find('-') then
                repeat
                    if TempSalesLine."Prepmt. Line Amount" <> 0 then begin
                        if (TempSalesLine."VAT Bus. Posting Group" <> VATPostingSetup."VAT Bus. Posting Group") or
                           (TempSalesLine."VAT Prod. Posting Group" <> VATPostingSetup."VAT Prod. Posting Group")
                        then begin
                            VATPostingSetup.Get(
                              TempSalesLine."VAT Bus. Posting Group", TempSalesLine."VAT Prod. Posting Group");
                            VATPostingSetup.TestField("Sales Advance VAT Account");
                        end;
                        GLAcc.Get(VATPostingSetup."Sales Advance VAT Account");

                        Clear(TempPrepmtInvLineBuf2);
                        TempPrepmtInvLineBuf2.Init();
                        TempPrepmtInvLineBuf2."G/L Account No." := GLAcc."No.";
                        TempPrepmtInvLineBuf2."Dimension Set ID" := TempSalesLine."Dimension Set ID";
                        TempPrepmtInvLineBuf2."Gen. Bus. Posting Group" := TempSalesLine."Gen. Bus. Posting Group";
                        TempPrepmtInvLineBuf2."VAT Bus. Posting Group" := TempSalesLine."VAT Bus. Posting Group";
                        TempPrepmtInvLineBuf2."Gen. Prod. Posting Group" := TempSalesLine."Gen. Prod. Posting Group";
                        TempPrepmtInvLineBuf2."VAT Prod. Posting Group" := TempSalesLine."VAT Prod. Posting Group";
                        TempPrepmtInvLineBuf2."VAT Calculation Type" := TempSalesLine."VAT Calculation Type";
                        TempPrepmtInvLineBuf2."VAT Identifier" := TempSalesLine."VAT Identifier";
                        TempPrepmtInvLineBuf2."Global Dimension 1 Code" := TempSalesLine."Shortcut Dimension 1 Code";
                        TempPrepmtInvLineBuf2."Global Dimension 2 Code" := TempSalesLine."Shortcut Dimension 2 Code";
                        TempPrepmtInvLineBuf2."Dimension Set ID" := TempSalesLine."Dimension Set ID";
                        TempPrepmtInvLineBuf2."Job No." := TempSalesLine."Job No.";
                        TempPrepmtInvLineBuf2."VAT Identifier" := TempSalesLine."VAT Identifier";
                        TempPrepmtInvLineBuf2."Tax Area Code" := TempSalesLine."Tax Area Code";
                        TempPrepmtInvLineBuf2."Tax Liable" := TempSalesLine."Tax Liable";
                        TempPrepmtInvLineBuf2."Tax Group Code" := TempSalesLine."Tax Group Code";
                        TempPrepmtInvLineBuf2."VAT %" := TempSalesLine."VAT %";
                        if not "Compress Prepayment" then begin
                            TempPrepmtInvLineBuf2."Line No." := TempSalesLine."Line No.";
                            TempPrepmtInvLineBuf2.Description := TempSalesLine.Description;
                        end else
                            TempPrepmtInvLineBuf2.Description := GLAcc.Name;

                        PrepmtInvLineBuf := TempPrepmtInvLineBuf2;
                        if not PrepmtInvLineBuf.Find then begin
                            PrepmtInvLineBuf.Insert();
                            BufEntryNo := BufEntryNo + 1;
                            PrepmtInvLineBuf."Entry No." := BufEntryNo;
                        end;

                        PrepmtInvLineBuf.Amount += TempSalesLine."Prepayment Amount";
                        PrepmtInvLineBuf."Amount Incl. VAT" += TempSalesLine."Prepmt. Amt. Incl. VAT";
                        PrepmtInvLineBuf."VAT Base Amount" += TempSalesLine."Prepayment Amount";
                        PrepmtInvLineBuf."VAT Amount" += (TempSalesLine."Prepmt. Amt. Incl. VAT" - TempSalesLine."Prepayment Amount");
                        PrepmtInvLineBuf."Amount (ACY)" += TempSalesLine."Prepayment Amount";
                        PrepmtInvLineBuf."VAT Base Amount (ACY)" += TempSalesLine."Prepayment Amount";
                        PrepmtInvLineBuf."VAT Amount (ACY)" += (TempSalesLine."Prepmt. Amt. Incl. VAT" - TempSalesLine."Prepayment Amount");
                        PrepmtInvLineBuf.Modify();

                        TempAdvanceLetterLineRelation.Init();
                        TempAdvanceLetterLineRelation.Type := TempAdvanceLetterLineRelation.Type::Sale;
                        TempAdvanceLetterLineRelation."Document Type" := TempSalesLine."Document Type";
                        TempAdvanceLetterLineRelation."Document No." := TempSalesLine."Document No.";
                        TempAdvanceLetterLineRelation."Document Line No." := TempSalesLine."Line No.";
                        TempAdvanceLetterLineRelation."Letter Line No." := PrepmtInvLineBuf."Entry No.";
                        // "Requested Amount" := ;
                        TempAdvanceLetterLineRelation.Amount := TempSalesLine."Prepmt. Amt. Incl. VAT";
                        TempAdvanceLetterLineRelation."Primary Link" := true;
                        TempAdvanceLetterLineRelation.Insert();
                    end;
                until TempSalesLine.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure RecalcPrepm(var SalesLine: Record "Sales Line"; PriceInclVAT: Boolean)
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        LinkedAmt: Decimal;
        LinkedRemAmtLine: Decimal;
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.GetPostingLineImage(TempSalesLine, 3, false);
        TempSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Document Type", SalesLine."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", SalesLine."Document No.");
        AdvanceLetterLineRelation.SetRange("Document Line No.", SalesLine."Line No.");
        if AdvanceLetterLineRelation.FindSet(false, false) then begin
            repeat
                LinkedAmt += AdvanceLetterLineRelation.Amount;
                LinkedRemAmtLine += (AdvanceLetterLineRelation.Amount - AdvanceLetterLineRelation."Deducted Amount");
            until AdvanceLetterLineRelation.Next = 0;
        end;

        if TempSalesLine."Amount Including VAT" < LinkedRemAmtLine then
            SalesLine.FieldError("Prepmt. Line Amount");

        if PriceInclVAT then begin
            if (TempSalesLine."Amount Including VAT" - LinkedRemAmtLine) < SalesLine."Prepmt. Line Amount" - LinkedAmt then
                SalesLine."Prepmt. Line Amount" := (TempSalesLine."Amount Including VAT" - LinkedRemAmtLine)
            else
                SalesLine."Prepmt. Line Amount" := SalesLine."Prepmt. Line Amount" - LinkedAmt;
        end else begin
            LinkedAmt := Round(LinkedAmt / (1 + SalesLine."VAT %" / 100));
            LinkedRemAmtLine := Round(LinkedRemAmtLine / (1 + SalesLine."VAT %" / 100));

            if (TempSalesLine.Amount - LinkedRemAmtLine) < SalesLine."Prepmt. Line Amount" - LinkedAmt then
                SalesLine."Prepmt. Line Amount" := (TempSalesLine.Amount - LinkedRemAmtLine)
            else
                SalesLine."Prepmt. Line Amount" := SalesLine."Prepmt. Line Amount" - LinkedAmt;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetAmtToDedOnSalesDoc(SalesHeader: Record "Sales Header"; AdjustRelations: Boolean)
    var
        TempSalesLine: Record "Sales Line" temporary;
        SalesLine: Record "Sales Line";
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        AmtToDeductLoc: Decimal;
        DocRemainderAmt: Decimal;
        AdvanceLetterRemainderAmt: Decimal;
        InvAmtCorrection: Decimal;
        AdjustmentToleranceAmt: Decimal;
    begin
        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Order) and
           (SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice)
        then
            exit;
        ClearLineRelAmountToDeduct(SalesHeader."Document Type", SalesHeader."No.");
        SetCurrencyPrecision(SalesHeader."Currency Code");
        SalesHeader.GetPostingLineImage(TempSalesLine, QtyType::Invoicing, false);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Prepmt Amt to Deduct", '<>0');
        SalesLine.SetFilter("Prepayment %", '<>0');
        if SalesLine.FindSet then
            repeat
                if SalesLine."Adjust Prepmt. Relation" and AdjustRelations then
                    AdjustmentToleranceAmt := Currency."Amount Rounding Precision"
                else
                    AdjustmentToleranceAmt := 0;
                TempSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
                if SalesHeader."Prices Including VAT" then
                    AmtToDeductLoc := SalesLine."Prepmt Amt to Deduct"
                else
                    AmtToDeductLoc := Round(SalesLine."Prepmt Amt to Deduct" * (1 + SalesLine."VAT %" / 100),
                        Currency."Amount Rounding Precision");
                if TempSalesLine."Amount Including VAT" < AmtToDeductLoc then
                    if AmtToDeductLoc - TempSalesLine."Amount Including VAT" <= AdjustmentToleranceAmt then
                        AmtToDeductLoc := TempSalesLine."Amount Including VAT"
                    else
                        Error(Text4005248Err, SalesLine."Line No.", SalesLine."Document Type", SalesLine."Document No.");
                DocRemainderAmt := TempSalesLine."Amount Including VAT" - AmtToDeductLoc;

                AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
                AdvanceLetterLineRelation.SetRange("Document Type", SalesHeader."Document Type");
                AdvanceLetterLineRelation.SetRange("Document No.", SalesLine."Document No.");
                AdvanceLetterLineRelation.SetRange("Document Line No.", SalesLine."Line No.");
                if AdvanceLetterLineRelation.FindSet then
                    repeat
                        if AmtToDeductLoc > 0 then
                            if AmtToDeductLoc > AdvanceLetterLineRelation."Invoiced Amount" -
                               AdvanceLetterLineRelation."Deducted Amount"
                            then begin
                                AdvanceLetterLineRelation."Amount To Deduct" := AdvanceLetterLineRelation."Invoiced Amount" -
                                  AdvanceLetterLineRelation."Deducted Amount";
                                AmtToDeductLoc -= AdvanceLetterLineRelation."Amount To Deduct";
                            end else begin
                                AdvanceLetterLineRelation."Amount To Deduct" := AmtToDeductLoc;
                                AmtToDeductLoc := 0;
                                AdvanceLetterRemainderAmt := AdvanceLetterLineRelation."Invoiced Amount" -
                                  AdvanceLetterLineRelation."Deducted Amount" -
                                  AdvanceLetterLineRelation."Amount To Deduct";
                                if (AdvanceLetterRemainderAmt > 0) and (DocRemainderAmt > 0) then begin
                                    if (AdvanceLetterRemainderAmt <= AdjustmentToleranceAmt) and
                                       (DocRemainderAmt >= AdvanceLetterRemainderAmt)
                                    then begin
                                        AdvanceLetterLineRelation."Amount To Deduct" += AdvanceLetterRemainderAmt;
                                        DocRemainderAmt -= AdvanceLetterRemainderAmt;
                                    end;
                                    if (DocRemainderAmt <= AdjustmentToleranceAmt) and
                                       (DocRemainderAmt <= AdvanceLetterRemainderAmt)
                                    then begin
                                        AdvanceLetterLineRelation."Amount To Deduct" += DocRemainderAmt;
                                        DocRemainderAmt -= AdvanceLetterRemainderAmt;
                                    end;
                                end;
                                AdvanceLetterLineRelation.Modify();
                            end
                        else
                            AdvanceLetterLineRelation."Amount To Deduct" := 0;
                        AdvanceLetterLineRelation.Modify();
                        if not TempSalesAdvanceLetterHeader.Get(AdvanceLetterLineRelation."Letter No.") then begin
                            TempSalesAdvanceLetterHeader."No." := AdvanceLetterLineRelation."Letter No.";
                            TempSalesAdvanceLetterHeader.Insert();
                        end;
                    until AdvanceLetterLineRelation.Next = 0;
                if AmtToDeductLoc > AdjustmentToleranceAmt then
                    Error(Text4005249Err, SalesLine."Line No.", SalesLine."Document Type", SalesLine."Document No.");
                DocRemainderAmt += AmtToDeductLoc;
                if AdvanceLetterLineRelation.FindSet then
                    repeat
                        if DocRemainderAmt > 0 then begin
                            SalesAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                            SalesAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount");
                            if (SalesAdvanceLetterLine."Document Linked Amount" < SalesAdvanceLetterLine."Amount Including VAT") and
                               (SalesAdvanceLetterLine."Document Linked Inv. Amount" < SalesAdvanceLetterLine."Amount Invoiced")
                            then begin
                                if (SalesAdvanceLetterLine."Amount Including VAT" - SalesAdvanceLetterLine."Document Linked Amount") >
                                   (SalesAdvanceLetterLine."Amount Invoiced" - SalesAdvanceLetterLine."Document Linked Inv. Amount")
                                then
                                    AdvanceLetterRemainderAmt :=
                                      SalesAdvanceLetterLine."Amount Invoiced" - SalesAdvanceLetterLine."Document Linked Inv. Amount"
                                else
                                    AdvanceLetterRemainderAmt :=
                                      SalesAdvanceLetterLine."Amount Including VAT" - SalesAdvanceLetterLine."Document Linked Amount";
                                if (DocRemainderAmt <= AdjustmentToleranceAmt) or
                                   (AdvanceLetterRemainderAmt <= AdjustmentToleranceAmt)
                                then begin
                                    if AdvanceLetterRemainderAmt < DocRemainderAmt then
                                        InvAmtCorrection := AdvanceLetterRemainderAmt
                                    else
                                        InvAmtCorrection := DocRemainderAmt;
                                    AdvanceLetterLineRelation.Amount += InvAmtCorrection;
                                    AdvanceLetterLineRelation."Invoiced Amount" += InvAmtCorrection;
                                    AdvanceLetterLineRelation."Amount To Deduct" += InvAmtCorrection;
                                    AdvanceLetterLineRelation.Modify();
                                    DocRemainderAmt -= InvAmtCorrection
                                end;
                            end;
                        end;
                    until AdvanceLetterLineRelation.Next = 0;
            until SalesLine.Next = 0;

        SetAmtToDedOnSalesDoc_Adj(SalesHeader, SalesLine, TempSalesAdvanceLetterHeader, TempSalesLine, AdjustRelations);

        SetAmtToDedOnSalesDoc_Fin(SalesHeader, SalesLine);
    end;

    local procedure SetAmtToDedOnSalesDoc_Adj(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary; var TempSalesLine: Record "Sales Line" temporary; AdjustRelations: Boolean)
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        AdjustmentToleranceAmt: Decimal;
        AmtToDeductLoc: Decimal;
    begin
        if not TempSalesAdvanceLetterHeader.IsEmpty and AdjustRelations then begin
            AdvanceLetterLineRelation.Reset();
            AdjustmentToleranceAmt := Currency."Amount Rounding Precision";
            SalesLine.SetRange("Prepmt Amt to Deduct");
            SalesLine.SetRange("Adjust Prepmt. Relation", true);
            SalesLine.SetFilter("Prepayment %", '<>0');
            if SalesLine.FindSet then
                repeat
                    TempSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
                    SalesLine.CalcFields("Adv.Letter Link.Amt. to Deduct");
                    if (TempSalesLine."Amount Including VAT" > SalesLine."Adv.Letter Link.Amt. to Deduct") and
                       (TempSalesLine."Amount Including VAT" <= SalesLine."Adv.Letter Link.Amt. to Deduct" + AdjustmentToleranceAmt)
                    then begin
                        TempSalesAdvanceLetterHeader.FindSet;
                        repeat
                            SalesAdvanceLetterLine.SetRange("Letter No.", TempSalesAdvanceLetterHeader."No.");
                            SalesAdvanceLetterLine.SetFilter("Amount To Deduct", '>0');
                            if SalesAdvanceLetterLine.FindSet then
                                repeat
                                    SalesAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount");
                                    if (SalesAdvanceLetterLine."Document Linked Amount" < SalesAdvanceLetterLine."Amount Including VAT") and
                                       (SalesAdvanceLetterLine."Document Linked Inv. Amount" < SalesAdvanceLetterLine."Amount Invoiced")
                                    then begin
                                        AmtToDeductLoc := TempSalesLine."Amount Including VAT" - SalesLine."Adv.Letter Link.Amt. to Deduct";
                                        if SalesAdvanceLetterLine."Amount Including VAT" - SalesAdvanceLetterLine."Document Linked Amount" <
                                           AmtToDeductLoc
                                        then
                                            AmtToDeductLoc :=
                                              SalesAdvanceLetterLine."Amount Including VAT" - SalesAdvanceLetterLine."Document Linked Amount";
                                        if SalesAdvanceLetterLine."Amount Invoiced" - SalesAdvanceLetterLine."Document Linked Inv. Amount" <
                                           AmtToDeductLoc
                                        then
                                            AmtToDeductLoc :=
                                              SalesAdvanceLetterLine."Amount Invoiced" - SalesAdvanceLetterLine."Document Linked Inv. Amount";
                                        AdvanceLetterLineRelation.Init();
                                        AdvanceLetterLineRelation.Type := AdvanceType::Sale;
                                        AdvanceLetterLineRelation."Document Type" := SalesLine."Document Type";
                                        AdvanceLetterLineRelation."Document No." := SalesLine."Document No.";
                                        AdvanceLetterLineRelation."Document Line No." := SalesLine."Line No.";
                                        AdvanceLetterLineRelation."Letter No." := SalesAdvanceLetterLine."Letter No.";
                                        AdvanceLetterLineRelation."Letter Line No." := SalesAdvanceLetterLine."Line No.";
                                        AdvanceLetterLineRelation.Amount := AmtToDeductLoc;
                                        AdvanceLetterLineRelation."Invoiced Amount" := AmtToDeductLoc;
                                        AdvanceLetterLineRelation."Amount To Deduct" := AmtToDeductLoc;
                                        AdvanceLetterLineRelation.Insert();
                                        UpdateOrderLine(SalesLine, SalesHeader."Prices Including VAT", true);
                                        SalesLine.Modify();
                                    end;
                                until SalesAdvanceLetterLine.Next = 0;
                        until TempSalesAdvanceLetterHeader.Next = 0;
                    end;
                until SalesLine.Next = 0;

            TempSalesAdvanceLetterHeader.FindSet;
            repeat
                SalesAdvanceLetterLine.SetRange("Letter No.", TempSalesAdvanceLetterHeader."No.");
                SalesAdvanceLetterLine.SetFilter("Amount To Deduct", '>0');
                if SalesAdvanceLetterLine.FindSet then
                    repeat
                        SalesAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount");
                        if (SalesAdvanceLetterLine."Document Linked Amount" < SalesAdvanceLetterLine."Amount Including VAT") and
                           (SalesAdvanceLetterLine."Document Linked Inv. Amount" < SalesAdvanceLetterLine."Amount Invoiced") and
                           (SalesAdvanceLetterLine."Document Linked Inv. Amount" + AdjustmentToleranceAmt >=
                            SalesAdvanceLetterLine."Amount Invoiced")
                        then begin
                            if SalesAdvanceLetterLine."Amount Including VAT" - SalesAdvanceLetterLine."Document Linked Amount" >
                               SalesAdvanceLetterLine."Amount Invoiced" - SalesAdvanceLetterLine."Document Linked Inv. Amount"
                            then
                                AmtToDeductLoc := SalesAdvanceLetterLine."Amount Invoiced" - SalesAdvanceLetterLine."Document Linked Inv. Amount"
                            else
                                AmtToDeductLoc := SalesAdvanceLetterLine."Amount Including VAT" - SalesAdvanceLetterLine."Document Linked Amount";
                            if SalesLine.FindSet then
                                repeat
                                    TempSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
                                    SalesLine.CalcFields("Adv.Letter Link.Amt. to Deduct");
                                    if TempSalesLine."Amount Including VAT" > SalesLine."Adv.Letter Link.Amt. to Deduct" then begin
                                        if TempSalesLine."Amount Including VAT" - SalesLine."Adv.Letter Link.Amt. to Deduct" < AmtToDeductLoc then
                                            AmtToDeductLoc := TempSalesLine."Amount Including VAT" - SalesLine."Adv.Letter Link.Amt. to Deduct";
                                        AdvanceLetterLineRelation.Init();
                                        AdvanceLetterLineRelation.Type := AdvanceType::Sale;
                                        AdvanceLetterLineRelation."Document Type" := SalesLine."Document Type";
                                        AdvanceLetterLineRelation."Document No." := SalesLine."Document No.";
                                        AdvanceLetterLineRelation."Document Line No." := SalesLine."Line No.";
                                        AdvanceLetterLineRelation."Letter No." := SalesAdvanceLetterLine."Letter No.";
                                        AdvanceLetterLineRelation."Letter Line No." := SalesAdvanceLetterLine."Line No.";
                                        AdvanceLetterLineRelation.Amount := AmtToDeductLoc;
                                        AdvanceLetterLineRelation."Invoiced Amount" := AmtToDeductLoc;
                                        AdvanceLetterLineRelation."Amount To Deduct" := AmtToDeductLoc;
                                        AdvanceLetterLineRelation.Insert();
                                        UpdateOrderLine(SalesLine, SalesHeader."Prices Including VAT", true);
                                        SalesLine.Modify();
                                    end;
                                until SalesLine.Next = 0;
                        end
                    until SalesAdvanceLetterLine.Next = 0;
            until TempSalesAdvanceLetterHeader.Next = 0;
        end;
    end;

    local procedure SetAmtToDedOnSalesDoc_Fin(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        TempSalesLine: Record "Sales Line" temporary;
        TotalInvoicedAmtLoc: Decimal;
        AdvanceLetterRemainderAmt: Decimal;
        ReduceAmt: Decimal;
    begin
        AdvanceLetterLineRelation.Reset();
        TempSalesLine.Reset();
        TempSalesLine.DeleteAll();
        SalesHeader.GetPostingLineImage(TempSalesLine, QtyType::Invoicing, false);
        SalesHeader.CalcFields("Adv.Letter Link.Amt. to Deduct");
        if TempSalesLine.FindSet then
            repeat
                TotalInvoicedAmtLoc += TempSalesLine."Amount Including VAT";
            until TempSalesLine.Next = 0;
        AdvanceLetterRemainderAmt := 0;
        if (TotalInvoicedAmtLoc < SalesHeader."Adv.Letter Link.Amt. to Deduct") and
           (SalesHeader."Adv.Letter Link.Amt. to Deduct" > 0)
        then begin
            AdvanceLetterRemainderAmt := SalesHeader."Adv.Letter Link.Amt. to Deduct" - TotalInvoicedAmtLoc;
            SalesLine.SetFilter("VAT Difference (LCY)", '>0');
            SalesLine.SetFilter("Prepmt Amt to Deduct", '<>0');
            SalesLine.SetRange("Adjust Prepmt. Relation", true);
            if SalesLine.FindSet then
                repeat
                    if AdvanceLetterRemainderAmt > SalesLine."VAT Difference (LCY)" then
                        ReduceAmt := SalesLine."VAT Difference (LCY)"
                    else
                        ReduceAmt := AdvanceLetterRemainderAmt;
                    AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
                    AdvanceLetterLineRelation.SetRange("Document Type", SalesLine."Document Type");
                    AdvanceLetterLineRelation.SetRange("Document No.", SalesLine."Document No.");
                    AdvanceLetterLineRelation.SetRange("Document Line No.", SalesLine."Line No.");
                    if AdvanceLetterLineRelation.FindSet then
                        repeat
                            if AdvanceLetterLineRelation."Amount To Deduct" > 0 then begin
                                if AdvanceLetterLineRelation."Amount To Deduct" > ReduceAmt then begin
                                    AdvanceLetterLineRelation."Amount To Deduct" := AdvanceLetterLineRelation."Amount To Deduct" - ReduceAmt;
                                    AdvanceLetterRemainderAmt := AdvanceLetterRemainderAmt - ReduceAmt;
                                    ReduceAmt := 0;
                                end else begin
                                    ReduceAmt := ReduceAmt - AdvanceLetterLineRelation."Amount To Deduct";
                                    AdvanceLetterRemainderAmt := AdvanceLetterRemainderAmt - AdvanceLetterLineRelation."Amount To Deduct";
                                    AdvanceLetterLineRelation."Amount To Deduct" := 0;
                                end;
                                AdvanceLetterLineRelation.Modify();
                                UpdateOrderLine(SalesLine, SalesHeader."Prices Including VAT", true);
                            end;
                        until (AdvanceLetterLineRelation.Next = 0) or (ReduceAmt = 0);
                until (SalesLine.Next = 0) or (AdvanceLetterRemainderAmt = 0);
            if AdvanceLetterRemainderAmt > 0 then begin
                SalesLine.SetRange("VAT Difference (LCY)");
                SalesLine.SetFilter("Prepmt Amt to Deduct", '<>0');
                SalesLine.SetRange("Adjust Prepmt. Relation", true);
                if SalesLine.FindSet then
                    repeat
                        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
                        AdvanceLetterLineRelation.SetRange("Document Type", SalesLine."Document Type");
                        AdvanceLetterLineRelation.SetRange("Document No.", SalesLine."Document No.");
                        AdvanceLetterLineRelation.SetRange("Document Line No.", SalesLine."Line No.");
                        if AdvanceLetterLineRelation.FindSet then
                            repeat
                                if AdvanceLetterLineRelation."Amount To Deduct" > 0 then begin
                                    if AdvanceLetterLineRelation."Amount To Deduct" > AdvanceLetterRemainderAmt then begin
                                        AdvanceLetterLineRelation."Amount To Deduct" :=
                                          AdvanceLetterLineRelation."Amount To Deduct" - AdvanceLetterRemainderAmt;
                                        AdvanceLetterRemainderAmt := 0;
                                    end else begin
                                        AdvanceLetterRemainderAmt := AdvanceLetterRemainderAmt - AdvanceLetterLineRelation."Amount To Deduct";
                                        AdvanceLetterLineRelation."Amount To Deduct" := 0;
                                    end;
                                    AdvanceLetterLineRelation.Modify();
                                    UpdateOrderLine(SalesLine, SalesHeader."Prices Including VAT", true);
                                end;
                            until (AdvanceLetterLineRelation.Next = 0) or (AdvanceLetterRemainderAmt = 0);
                    until (SalesLine.Next = 0) or (AdvanceLetterRemainderAmt = 0);
            end;
        end;
        if AdvanceLetterRemainderAmt <> 0 then
            Error(Text4005250Err);
    end;

    [Scope('OnPrem')]
    procedure CalcVATCorrection(SalesHeader: Record "Sales Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        SalesLine: Record "Sales Line";
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempAdvanceLink: Record "Advance Link" temporary;
        EntryPos: Integer;
        i: Integer;
        ToDeductFact: Decimal;
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
        BaseToDeductLCYDif: Decimal;
        VATAmountLCYDif: Decimal;
        AmountToDeduct: Decimal;
    begin
        TempVATAmountLine.Reset();
        TempVATAmountLine.DeleteAll();
        Clear(TempVATAmountLine);
        GLSetup.Get();

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Qty. to Invoice", '<>0');
        if SalesLine.FindSet then
            repeat
                AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
                AdvanceLetterLineRelation.SetRange("Document Type", SalesLine."Document Type");

                AdvanceLetterLineRelation.SetRange("Document No.", SalesLine."Document No.");
                AdvanceLetterLineRelation.SetRange("Document Line No.", SalesLine."Line No.");
                if AdvanceLetterLineRelation.FindSet then begin
                    repeat
                        SalesAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                        CreateBufLink(TempAdvanceLink, SalesAdvanceLetterLine);
                        AmountToDeduct := AdvanceLetterLineRelation."Amount To Deduct";

                        TempCustLedgEntryGre.Reset();
                        TempCustLedgEntryGre.DeleteAll();
                        Clear(TempCustLedgEntryGre);

                        CalcLinkedPmtAmountToApplyTmp(
                          SalesAdvanceLetterLine, AmountToDeduct, TempCustLedgEntry, TempCustLedgEntryGre, TempAdvanceLink);

                        TotBaseToDeduct := 0;
                        TotVATAmtToDeduct := 0;
                        TotBaseToDeductLCY := 0;
                        TotVATAmtToDeductLCY := 0;
                        EntryPos := 0;

                        for i := 1 to 2 do begin
                            if TempCustLedgEntryGre.FindSet then
                                repeat
                                    TempAdvanceLink.Reset();
                                    TempAdvanceLink.SetCurrentKey("CV Ledger Entry No.", "Entry Type", "Document No.", "Line No.");
                                    TempAdvanceLink.SetRange("CV Ledger Entry No.", TempCustLedgEntryGre."Entry No.");
                                    TempAdvanceLink.SetRange("Entry Type", TempAdvanceLink."Entry Type"::"Link To Letter");
                                    TempAdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
                                    TempAdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
                                    TempAdvanceLink.CalcSums(Amount, "Remaining Amount to Deduct");
                                    if TempAdvanceLink."Remaining Amount to Deduct" <> 0 then
                                        ToDeductFact := TempCustLedgEntryGre."Amount to Apply" /
                                          (TempAdvanceLink."Remaining Amount to Deduct" + TempCustLedgEntryGre."Amount to Apply")
                                    else
                                        ToDeductFact := 0;

                                    if (TempAdvanceLink."Remaining Amount to Deduct" = 0) = (i = 1) then begin
                                        EntryPos := EntryPos + 1;
                                        SetCurrencyPrecision(SalesAdvanceLetterLine."Currency Code");

                                        if i = 1 then begin
                                            CalcVATToDeduct(SalesAdvanceLetterLine,
                                              BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY,
                                              TempCustLedgEntryGre."Entry No.");
                                            BaseToDeduct := -BaseToDeduct;
                                            VATAmtToDeduct := -VATAmtToDeduct;
                                            if SalesHeader."Currency Code" = '' then begin
                                                BaseToDeductLCY := -BaseToDeductLCY;
                                                VATAmountLCY := -VATAmountLCY;
                                            end else begin
                                                BaseToDeductLCY := -BaseToDeductLCY;
                                                VATAmountLCY := -VATAmountLCY;
                                                if SalesLine."VAT %" = SalesAdvanceLetterLine."VAT %" then begin
                                                    BaseToDeductLCYDif := BaseToDeductLCY;
                                                    VATAmountLCYDif := VATAmountLCY;
                                                    BaseToDeductLCY := Round(BaseToDeduct / SalesHeader."Currency Factor");
                                                    VATAmountLCY := Round(VATAmtToDeduct / SalesHeader."Currency Factor");
                                                    BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                                                    VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
                                                end;
                                            end;
                                        end else begin
                                            CalcVATToDeduct(SalesAdvanceLetterLine,
                                              BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY,
                                              TempCustLedgEntryGre."Entry No.");
                                            BaseToDeduct := -Round(BaseToDeduct * ToDeductFact, Currency."Amount Rounding Precision");
                                            VATAmtToDeduct := -Round(VATAmtToDeduct * ToDeductFact, Currency."Amount Rounding Precision");

                                            if (SalesAdvanceLetterLine."VAT %" <> 0) and (VATAmtToDeduct <> 0) then
                                                BaseToDeduct := BaseToDeduct +
                                                  TempCustLedgEntryGre."Amount to Apply" - (BaseToDeduct + VATAmtToDeduct);

                                            if SalesHeader."Currency Code" = '' then begin
                                                BaseToDeductLCY := BaseToDeduct;
                                                VATAmountLCY := VATAmtToDeduct;
                                            end else begin
                                                BaseToDeductLCY := -Round(BaseToDeductLCY * ToDeductFact);
                                                VATAmountLCY := -Round(VATAmountLCY * ToDeductFact);
                                                if SalesLine."VAT %" = SalesAdvanceLetterLine."VAT %" then begin
                                                    BaseToDeductLCYDif := BaseToDeductLCY;
                                                    VATAmountLCYDif := VATAmountLCY;
                                                    BaseToDeductLCY := Round(BaseToDeduct / SalesHeader."Currency Factor");
                                                    VATAmountLCY := Round(VATAmtToDeduct / SalesHeader."Currency Factor");
                                                    BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                                                    VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
                                                end;
                                            end;
                                        end;

                                        CalcVATCorrection_InsertLines(TempVATAmountLine, SalesAdvanceLetterLine,
                                          BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY,
                                          BaseToDeductLCYDif,
                                          VATAmountLCYDif);
                                    end;

                                until TempCustLedgEntryGre.Next = 0;
                        end;

                    until AdvanceLetterLineRelation.Next = 0;
                end;

            until SalesLine.Next = 0;
    end;

    local procedure CalcVATCorrection_InsertLines(var TempVATAmountLine: Record "VAT Amount Line" temporary; SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; BaseToDeduct: Decimal; VATAmtToDeduct: Decimal; BaseToDeductLCY: Decimal; VATAmountLCY: Decimal; BaseToDeductLCYDif: Decimal; VATAmountLCYDif: Decimal)
    begin
        if (BaseToDeduct <> 0) or (VATAmtToDeduct <> 0) then begin
            Clear(TempSalesAdvanceLetterEntry);
            TempSalesAdvanceLetterEntry."VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
            TempSalesAdvanceLetterEntry."Customer Entry No." := TempCustLedgEntryGre."Entry No.";

            SalesAdvanceLetterEntryNo += 1;
            TempSalesAdvanceLetterEntry."Entry No." := SalesAdvanceLetterEntryNo;
            TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::"VAT Deduction";
            TempSalesAdvanceLetterEntry."Letter No." := SalesAdvanceLetterLine."Letter No.";
            TempSalesAdvanceLetterEntry."Letter Line No." := SalesAdvanceLetterLine."Line No.";
            TempSalesAdvanceLetterEntry.Amount := 0;
            TempSalesAdvanceLetterEntry.Insert();

            TempSalesAdvanceLetterEntry."VAT Identifier" := SalesAdvanceLetterLine."VAT Identifier";
            TempSalesAdvanceLetterEntry."VAT Base Amount" := BaseToDeduct;
            TempSalesAdvanceLetterEntry."VAT Amount" := VATAmtToDeduct;
            TempSalesAdvanceLetterEntry."VAT Amount (LCY)" := VATAmountLCY;
            TempSalesAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCY;
            TempSalesAdvanceLetterEntry.Modify();

            if VATAmountLCYDif <> 0 then begin
                SalesAdvanceLetterEntryNo += 1;
                TempSalesAdvanceLetterEntry."Entry No." := SalesAdvanceLetterEntryNo;
                TempSalesAdvanceLetterEntry."Entry Type" := TempSalesAdvanceLetterEntry."Entry Type"::"VAT Rate";
                TempSalesAdvanceLetterEntry.Amount := 0;
                TempSalesAdvanceLetterEntry."VAT Base Amount" := 0;
                TempSalesAdvanceLetterEntry."VAT Amount" := 0;
                TempSalesAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCYDif;
                TempSalesAdvanceLetterEntry."VAT Amount (LCY)" := VATAmountLCYDif;
                TempSalesAdvanceLetterEntry.Insert();
            end;

            with SalesAdvanceLetterLine do
                if not TempVATAmountLine.Get(
                     "VAT Identifier",
                     "VAT Calculation Type", "Tax Group Code",
                     false, false)
                then begin
                    TempVATAmountLine.Init();
                    TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                    TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                    TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                    TempVATAmountLine."VAT %" := "VAT %";
                    TempVATAmountLine.Modified := true;
                    TempVATAmountLine."Includes Prepayment" := true;
                    TempVATAmountLine.Positive := false;
                    TempVATAmountLine.Insert();
                end;
            TempVATAmountLine."VAT Amount" -= VATAmtToDeduct;
            TempVATAmountLine."VAT Base" -= BaseToDeduct;
            TempVATAmountLine."Amount Including VAT" -= (VATAmtToDeduct + BaseToDeduct);

            TempVATAmountLine."VAT Amount (LCY)" -= VATAmountLCY;
            TempVATAmountLine."VAT Base (LCY)" -= BaseToDeductLCY;
            TempVATAmountLine."Amount Including VAT (LCY)" -= (VATAmountLCY + BaseToDeductLCY);
            TempVATAmountLine."Calculated VAT Amount" := TempVATAmountLine."VAT Amount";
            TempVATAmountLine."Calculated VAT Amount (LCY)" := TempVATAmountLine."VAT Amount (LCY)";
            TempVATAmountLine.Modify();
        end;
    end;

    local procedure CalcLinkedPmtAmountToApplyTmp(SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; TotalAmountToApply: Decimal; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary; var TempCustLedgEntryLink: Record "Cust. Ledger Entry" temporary; var TempAdvanceLink: Record "Advance Link" temporary)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        AmountToApply: Decimal;
    begin
        if TotalAmountToApply = 0 then
            exit;

        SumAmountToApply := SumAmountToApply + TotalAmountToApply;

        SetCurrencyPrecision(SalesAdvanceLetterLine."Currency Code");
        TempAdvanceLink.Reset();
        TempAdvanceLink.SetCurrentKey("Entry Type", "Document No.", "Line No.", "Posting Date");
        TempAdvanceLink.SetRange("Entry Type", TempAdvanceLink."Entry Type"::"Link To Letter");
        TempAdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
        TempAdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
        TempAdvanceLink.SetFilter("Remaining Amount to Deduct", '<>0');
        if TempAdvanceLink.FindSet then
            repeat
                if CustLedgEntry.Get(TempAdvanceLink."CV Ledger Entry No.") then begin
                    case true of
                        TotalAmountToApply < TempAdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TotalAmountToApply;
                        TotalAmountToApply = TempAdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TotalAmountToApply;
                        TotalAmountToApply > TempAdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TempAdvanceLink."Remaining Amount to Deduct";
                    end;
                    TotalAmountToApply := TotalAmountToApply - AmountToApply;
                    TempAdvanceLink."Remaining Amount to Deduct" := TempAdvanceLink."Remaining Amount to Deduct" - AmountToApply;
                    TempAdvanceLink.Modify();
                    if AmountToApply <> 0 then begin
                        if TempCustLedgEntry.Get(CustLedgEntry."Entry No.") then begin
                            TempCustLedgEntry."Amount to Apply" := TempCustLedgEntry."Amount to Apply" + AmountToApply;
                            TempCustLedgEntry.Modify();
                        end else begin
                            TempCustLedgEntry := CustLedgEntry;
                            TempCustLedgEntry."Amount to Apply" := AmountToApply;
                            TempCustLedgEntry."Currency Code" := TempAdvanceLink."Currency Code";
                            TempCustLedgEntry.Insert();
                        end;
                        if TempCustLedgEntryLink.Get(CustLedgEntry."Entry No.") then begin
                            TempCustLedgEntryLink."Amount to Apply" := TempCustLedgEntryLink."Amount to Apply" + AmountToApply;
                            TempCustLedgEntryLink.Modify();
                        end else begin
                            TempCustLedgEntryLink := CustLedgEntry;
                            TempCustLedgEntryLink."Amount to Apply" := AmountToApply;
                            TempCustLedgEntryLink."Currency Code" := TempAdvanceLink."Currency Code";
                            TempCustLedgEntryLink.Insert();
                        end;
                    end;
                end;
            until (TempAdvanceLink.Next = 0) or (TotalAmountToApply = 0);
        TempAdvanceLink.Reset();
    end;

    [Scope('OnPrem')]
    procedure CreateBufLink(var TempAdvanceLink: Record "Advance Link" temporary; SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    var
        AdvanceLink: Record "Advance Link";
    begin
        AdvanceLink.Reset();
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", SalesAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", SalesAdvanceLetterLine."Line No.");
        if AdvanceLink.FindSet(false, false) then begin
            repeat
                if not TempAdvanceLink.Get(AdvanceLink."Entry No.") then begin
                    TempAdvanceLink := AdvanceLink;
                    TempAdvanceLink.Insert();
                end;
            until AdvanceLink.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CorrectVATbyDeductedVAT(SalesHeader: Record "Sales Header")
    var
        TempAdvanceVATAmtLine: Record "VAT Amount Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempSumVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineOrigSum: Record "VAT Amount Line" temporary;
        SalesLineCorr: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLineOrigin: Record "Sales Line" temporary;
        TempVATAmountLineDiff: Record "VAT Amount Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        CustPostingGroup: Record "Customer Posting Group";
    begin
        SalesHeader.CalcFields("Has Letter Line Relation");
        if not SalesHeader."Has Letter Line Relation" then
            exit;

        SalesHeader.TestField("Currency Code", '');
        SetAmtToDedOnSalesDoc(SalesHeader, true);
        SetCurrencyPrecision(SalesHeader."Currency Code");
        TempVATAmountLine.Reset();
        TempVATAmountLine.DeleteAll();

        SalesHeader.GetPostingLineImage(TempSalesLineOrigin, QtyType::Invoicing, false);
        SalesHeader.GetPostingLineImage(TempSalesLine, QtyType::Invoicing, false);
        SalesLineCorr.CalcVATAmountLines(1, SalesHeader, TempSalesLine, TempVATAmountLine);
        CalcVATCorrection(SalesHeader, TempAdvanceVATAmtLine);

        TempVATAmountLineDiff.Reset();
        TempVATAmountLineDiff.DeleteAll();

        SumVATAmountLines(TempVATAmountLine, TempSumVATAmountLine);
        if TempSumVATAmountLine.FindSet then
            repeat
                TempVATAmountLineOrigSum := TempSumVATAmountLine;
                TempVATAmountLineOrigSum.Insert();
            until TempSumVATAmountLine.Next = 0;
        TempSumVATAmountLine.SetFilter("Amount Including VAT (LCY)", '<>0');
        TempSumVATAmountLine.SetRange("VAT Difference (LCY)", 0);
        TempSumVATAmountLine.SetRange("VAT Difference", 0);
        if TempSumVATAmountLine.FindSet then begin
            repeat
                // Calc Invoice VAT & Deducted VAT difference
                TempVATAmountLineDiff := TempSumVATAmountLine;
                TempAdvanceVATAmtLine := TempSumVATAmountLine;
                TempAdvanceVATAmtLine.Positive := false;
                if TempAdvanceVATAmtLine.Find then begin
                    if TempSumVATAmountLine."Amount Including VAT" = -TempAdvanceVATAmtLine."Amount Including VAT" then
                        TempVATAmountLineDiff."VAT Base" := TempSumVATAmountLine."VAT Base" + TempAdvanceVATAmtLine."VAT Base"
                    else
                        TempVATAmountLineDiff."VAT Base" :=
                          Round(TempSumVATAmountLine."VAT Base" *
                            -TempAdvanceVATAmtLine."Amount Including VAT" / TempSumVATAmountLine."Amount Including VAT",
                            Currency."Amount Rounding Precision") + TempAdvanceVATAmtLine."VAT Base";
                    TempVATAmountLineDiff."VAT Amount" := -TempVATAmountLineDiff."VAT Base";
                    TempVATAmountLineDiff."Amount Including VAT" := 0;
                    TempVATAmountLineDiff.Insert();
                end;
            until TempSumVATAmountLine.Next = 0;

            TempVATAmountLineDiff.SetFilter("VAT Base", '<>0');
            if not SalesHeader."Prices Including VAT" then
                if TempVATAmountLineDiff.FindSet then begin
                    repeat
                        // Adjust VAT Base - Insert Sales Line VAT Base difference
                        TempSalesLine.SetRange("VAT Identifier", TempVATAmountLineDiff."VAT Identifier");
                        TempSalesLine.FindFirst;
                        VATPostingSetup.Get(TempSalesLine."VAT Bus. Posting Group", TempSalesLine."VAT Prod. Posting Group");
                        VATPostingSetup.TestField("Sales Ded. VAT Base Adj. Acc.");
                        if TempSalesLine.GetCPGInvRoundAcc(SalesHeader) = VATPostingSetup."Sales Ded. VAT Base Adj. Acc." then
                            Error(
                              Text4005251Err, VATPostingSetup.FieldCaption("Sales Ded. VAT Base Adj. Acc."),
                              CustPostingGroup.FieldCaption("Invoice Rounding Account"));
                        SalesLineCorr.SetRange("Document Type", SalesHeader."Document Type");
                        SalesLineCorr.SetRange("Document No.", SalesHeader."No.");
                        SalesLineCorr.SetRange("VAT Bus. Posting Group", TempSalesLine."VAT Bus. Posting Group");
                        SalesLineCorr.SetRange("VAT Prod. Posting Group", TempSalesLine."VAT Prod. Posting Group");
                        SalesLineCorr.SetRange(Type, SalesLineCorr.Type::"G/L Account");
                        SalesLineCorr.SetRange("No.", VATPostingSetup."Sales Ded. VAT Base Adj. Acc.");
                        if TempVATAmountLineDiff."VAT Base" > 0 then
                            SalesLineCorr.SetRange("Unit Price", -1)
                        else
                            SalesLineCorr.SetRange("Unit Price", 1);
                        if SalesLineCorr.FindFirst then begin
                            SalesLineCorr.SuspendStatusCheck(true);
                            SalesLineCorr.Validate(Quantity, SalesLineCorr.Quantity + Abs(TempVATAmountLineDiff."VAT Base"));
                            SalesLineCorr.Modify(true);
                        end else begin
                            SalesLineCorr.Reset();
                            SalesLineCorr.SetRange("Document Type", SalesHeader."Document Type");
                            SalesLineCorr.SetRange("Document No.", SalesHeader."No.");
                            SalesLineCorr.FindLast;
                            SalesLineCorr.Init();
                            SalesLineCorr.SuspendStatusCheck(true);
                            SalesLineCorr."Line No." += 10000;
                            SalesLineCorr.Validate(Type, SalesLineCorr.Type::"G/L Account");
                            SalesLineCorr.Validate("No.", VATPostingSetup."Sales Ded. VAT Base Adj. Acc.");
                            SalesLineCorr.Validate("VAT Prod. Posting Group", TempSalesLine."VAT Prod. Posting Group");
                            SalesLineCorr.Validate(Quantity, Abs(TempVATAmountLineDiff."VAT Base"));
                            if TempVATAmountLineDiff."VAT Base" > 0 then begin
                                SalesLineCorr.Validate("Prepayment %", 0);
                                SalesLineCorr.Validate("Unit Price", -1)
                            end else begin
                                SalesLineCorr.Validate("Prepayment %", 100);
                                SalesLineCorr.Validate("Unit Price", 1);
                            end;
                            SalesLineCorr.Insert(true);
                        end;
                    until TempVATAmountLineDiff.Next = 0;

                    TempSalesLine.Reset();
                    TempSalesLine.DeleteAll();

                    TempVATAmountLine.Reset();
                    TempVATAmountLine.DeleteAll();
                    TempSumVATAmountLine.Reset();
                    TempSumVATAmountLine.DeleteAll();

                    SalesHeader.GetPostingLineImage(TempSalesLine, QtyType::Invoicing, false);
                    SalesLineCorr.CalcVATAmountLines(1, SalesHeader, TempSalesLine, TempVATAmountLine);
                    SumVATAmountLines(TempVATAmountLine, TempSumVATAmountLine);
                end;

            TempVATAmountLineDiff.Reset();
            TempVATAmountLineDiff.DeleteAll();
            Clear(TempVATAmountLineDiff);

            CorrectVATbyDeductedVAT_CorrLine(
              TempSumVATAmountLine, TempVATAmountLineOrigSum, TempVATAmountLine, TempVATAmountLineDiff, TempAdvanceVATAmtLine);

            TempVATAmountLine.Reset();

            Clear(SalesLineCorr);
            SalesLineCorr.Reset();
            SalesLineCorr.UpdateVATOnLines(1, SalesHeader, SalesLineCorr, TempVATAmountLine);
            AdjustRelationOnCorrectedLines(SalesHeader, TempSalesLineOrigin);
            SetAmtToDedOnSalesDoc(SalesHeader, true);
        end;
    end;

    local procedure CorrectVATbyDeductedVAT_CorrLine(var TempSumVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineOrigSum: Record "VAT Amount Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineDiff: Record "VAT Amount Line" temporary; var TempAdvanceVATAmtLine: Record "VAT Amount Line" temporary)
    begin
        if TempSumVATAmountLine.FindSet then begin
            repeat
                // Calc Invoice VAT & Deducted VAT difference
                TempVATAmountLineOrigSum := TempSumVATAmountLine;
                TempVATAmountLineOrigSum.Find;
                TempVATAmountLineDiff := TempSumVATAmountLine;
                TempAdvanceVATAmtLine := TempSumVATAmountLine;
                TempVATAmountLine := TempSumVATAmountLine;
                TempVATAmountLine.Find;
                TempAdvanceVATAmtLine.Positive := false;
                if TempAdvanceVATAmtLine.Find then begin
                    if TempVATAmountLineOrigSum."Amount Including VAT" = -TempAdvanceVATAmtLine."Amount Including VAT" then
                        TempVATAmountLineDiff."VAT Amount" := TempSumVATAmountLine."VAT Amount" + TempAdvanceVATAmtLine."VAT Amount"
                    else
                        TempVATAmountLineDiff."VAT Amount" :=
                          Round(TempSumVATAmountLine."VAT Amount" *
                            -TempAdvanceVATAmtLine."Amount Including VAT" / TempVATAmountLineOrigSum."Amount Including VAT",
                            Currency."Amount Rounding Precision") + TempAdvanceVATAmtLine."VAT Amount";
                    TempVATAmountLineDiff."Amount Including VAT" := 0;
                    TempVATAmountLineDiff.Insert();
                end;
            until TempSumVATAmountLine.Next = 0;

            // Adjust VAT Amount - Correct Statistics
            TempVATAmountLineDiff.SetFilter("VAT Amount", '<>0');
            if TempVATAmountLineDiff.FindSet then begin
                repeat
                    TempVATAmountLine := TempVATAmountLineDiff;
                    TempVATAmountLine.Find;
                    TempVATAmountLine.Validate("VAT Amount",
                      TempVATAmountLine."VAT Amount" - TempVATAmountLineDiff."VAT Amount");
                    if SalesHeader."Prices Including VAT" then
                        TempVATAmountLine."VAT Base" := TempVATAmountLine."Amount Including VAT" - TempVATAmountLine."VAT Amount"
                    else
                        TempVATAmountLine."Amount Including VAT" := TempVATAmountLine."VAT Amount" + TempVATAmountLine."VAT Base";
                    if SalesHeader."Currency Code" = '' then begin
                        TempVATAmountLine.Validate("VAT Amount (LCY)", TempVATAmountLine."VAT Amount");
                        TempVATAmountLine."VAT Base (LCY)" := TempVATAmountLine."VAT Base";
                        TempVATAmountLine."Amount Including VAT (LCY)" := TempVATAmountLine."Amount Including VAT";
                    end;
                    TempVATAmountLine."Modified (LCY)" := true;
                    TempVATAmountLine.Modified := true;
                    TempVATAmountLine.Modify();
                    TempVATAmountLine.ModifyAll("Modified (LCY)", true);
                    TempVATAmountLine.ModifyAll(Modified, true);
                until TempVATAmountLineDiff.Next = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SumVATAmountLines(var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineSum: Record "VAT Amount Line" temporary)
    var
        TempVATAmountLineNeg: Record "VAT Amount Line" temporary;
    begin
        TempVATAmountLine.SetRange(Positive, false);
        if TempVATAmountLine.FindSet then
            repeat
                TempVATAmountLineNeg := TempVATAmountLine;
                TempVATAmountLineNeg.Insert();
            until TempVATAmountLine.Next = 0;
        TempVATAmountLine.SetRange(Positive);
        if TempVATAmountLine.FindSet then
            repeat
                TempVATAmountLineSum := TempVATAmountLine;
                if TempVATAmountLineSum.Positive then begin
                    TempVATAmountLineNeg := TempVATAmountLine;
                    TempVATAmountLineNeg.Positive := false;
                    if TempVATAmountLineNeg.Find then begin
                        TempVATAmountLineSum."VAT Base" += TempVATAmountLineNeg."VAT Base";
                        TempVATAmountLineSum."VAT Amount" += TempVATAmountLineNeg."VAT Amount";
                        TempVATAmountLineSum."Amount Including VAT" += TempVATAmountLineNeg."Amount Including VAT";
                        TempVATAmountLineSum."Line Amount" += TempVATAmountLineNeg."Line Amount";
                        TempVATAmountLineSum."Inv. Disc. Base Amount" += TempVATAmountLineNeg."Inv. Disc. Base Amount";
                        TempVATAmountLineSum."Invoice Discount Amount" += TempVATAmountLineNeg."Invoice Discount Amount";
                        TempVATAmountLineSum."VAT Difference" += TempVATAmountLineNeg."VAT Difference";
                        TempVATAmountLineSum."VAT Base (LCY)" += TempVATAmountLineNeg."VAT Base (LCY)";
                        TempVATAmountLineSum."VAT Amount (LCY)" += TempVATAmountLineNeg."VAT Amount (LCY)";
                        TempVATAmountLineSum."Amount Including VAT (LCY)" += TempVATAmountLineNeg."Amount Including VAT (LCY)";
                    end;
                end;
                if TempVATAmountLineSum."Amount Including VAT" > 0 then
                    TempVATAmountLineSum.Insert();
            until TempVATAmountLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure AdjustRelationOnCorrectedLines(SalesHeader: Record "Sales Header"; var SalesLineOrigin: Record "Sales Line")
    var
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
        AdvanceLetterLineRelationLoc: Record "Advance Letter Line Relation";
        SalesLine: Record "Sales Line";
        TempSalesAdvanceLetterLineLoc: Record "Sales Advance Letter Line" temporary;
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        DecrementAmt: Decimal;
        RemainingAmtLoc: Decimal;
    begin
        SalesHeader.GetPostingLineImage(TempSalesLine, QtyType::Invoicing, false);
        SalesHeader.GetPostingLineImage(TempSalesLine2, QtyType::Invoicing, false);
        if TempSalesLine.FindSet then
            repeat
                if SalesLineOrigin.Get(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.") then
                    if TempSalesLine."Amount Including VAT" - SalesLineOrigin."Amount Including VAT" < 0 then begin
                        TempSalesLine.CalcFields("Adv.Letter Linked Inv. Amount", "Adv.Letter Linked Ded. Amount");
                        if TempSalesLine."Adv.Letter Linked Inv. Amount" - TempSalesLine."Adv.Letter Linked Ded. Amount" >
                           TempSalesLine."Amount Including VAT"
                        then begin
                            DecrementAmt := SalesLineOrigin."Amount Including VAT" - TempSalesLine."Amount Including VAT";
                            RemainingAmtLoc := DecrementAmt;
                            AdvanceLetterLineRelationLoc.SetRange(Type, AdvanceLetterLineRelationLoc.Type::Sale);
                            AdvanceLetterLineRelationLoc.SetRange("Document Type", TempSalesLine."Document Type");
                            AdvanceLetterLineRelationLoc.SetRange("Document No.", TempSalesLine."Document No.");
                            AdvanceLetterLineRelationLoc.SetRange("Document Line No.", TempSalesLine."Line No.");
                            if AdvanceLetterLineRelationLoc.Find('-') then begin
                                repeat
                                    if AdvanceLetterLineRelationLoc."Invoiced Amount" >
                                       AdvanceLetterLineRelationLoc."Deducted Amount"
                                    then begin
                                        if AdvanceLetterLineRelationLoc."Invoiced Amount" - AdvanceLetterLineRelationLoc."Deducted Amount" >
                                           RemainingAmtLoc
                                        then begin
                                            AdvanceLetterLineRelationLoc.Amount -= RemainingAmtLoc;
                                            AdvanceLetterLineRelationLoc."Invoiced Amount" -= RemainingAmtLoc;
                                            AdvanceLetterLineRelationLoc.Modify();
                                            RemainingAmtLoc := 0;
                                        end else begin
                                            RemainingAmtLoc -=
                                              AdvanceLetterLineRelationLoc."Invoiced Amount" - AdvanceLetterLineRelationLoc."Deducted Amount";
                                            AdvanceLetterLineRelationLoc.Amount -=
                                              AdvanceLetterLineRelationLoc."Invoiced Amount" - AdvanceLetterLineRelationLoc."Deducted Amount";
                                            AdvanceLetterLineRelationLoc."Invoiced Amount" -=
                                              AdvanceLetterLineRelationLoc."Invoiced Amount" - AdvanceLetterLineRelationLoc."Deducted Amount";
                                            AdvanceLetterLineRelationLoc.Modify();
                                        end;
                                        SalesLine.Get(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.");
                                        UpdateOrderLine(SalesLine, SalesHeader."Prices Including VAT", true);
                                        SalesLine.Modify();
                                        TempSalesAdvanceLetterLineLoc."Letter No." := AdvanceLetterLineRelationLoc."Letter No.";
                                        TempSalesAdvanceLetterLineLoc."Line No." := AdvanceLetterLineRelationLoc."Letter Line No.";
                                        TempSalesAdvanceLetterLineLoc.Insert();
                                    end;
                                until (AdvanceLetterLineRelationLoc.Next = 0) or (RemainingAmtLoc <= 0);
                                DecrementAmt := DecrementAmt - RemainingAmtLoc;
                                if DecrementAmt > 0 then begin
                                    TempSalesLine2.SetRange("Document Type", TempSalesLine."Document Type");
                                    TempSalesLine2.SetRange("Document No.", TempSalesLine."Document No.");
                                    TempSalesLine2.SetRange("VAT Identifier", TempSalesLine."VAT Identifier");
                                    if TempSalesLine2.FindLast then begin
                                        TempSalesLine2.CalcFields("Adv.Letter Linked Ded. Amount", "Adv.Letter Linked Inv. Amount");
                                        if TempSalesLine2."Amount Including VAT" - TempSalesLine2."Adv.Letter Linked Inv. Amount" +
                                           TempSalesLine2."Adv.Letter Linked Ded. Amount" >= DecrementAmt
                                        then
                                            if TempSalesAdvanceLetterLineLoc.FindSet then
                                                repeat
                                                    SalesAdvanceLetterLine.Get(TempSalesAdvanceLetterLineLoc."Letter No.",
                                                      TempSalesAdvanceLetterLineLoc."Line No.");
                                                    SalesAdvanceLetterLine.CalcFields("Document Linked Inv. Amount");
                                                    if SalesAdvanceLetterLine."Amount Invoiced" -
                                                       SalesAdvanceLetterLine."Document Linked Inv. Amount" >= DecrementAmt
                                                    then begin
                                                        if AdvanceLetterLineRelationLoc.Get(AdvanceLetterLineRelationLoc.Type::Sale,
                                                             TempSalesLine2."Document Type",
                                                             TempSalesLine2."Document No.",
                                                             TempSalesLine2."Line No.",
                                                             TempSalesAdvanceLetterLineLoc."Letter No.",
                                                             TempSalesAdvanceLetterLineLoc."Line No.")
                                                        then begin
                                                            AdvanceLetterLineRelationLoc."Invoiced Amount" += DecrementAmt;
                                                            if AdvanceLetterLineRelationLoc."Invoiced Amount" > AdvanceLetterLineRelationLoc.Amount then
                                                                AdvanceLetterLineRelationLoc.Amount := AdvanceLetterLineRelationLoc."Invoiced Amount";
                                                            AdvanceLetterLineRelationLoc.Modify();
                                                        end else begin
                                                            AdvanceLetterLineRelationLoc.Init();
                                                            AdvanceLetterLineRelationLoc.Type := AdvanceLetterLineRelationLoc.Type::Sale;
                                                            AdvanceLetterLineRelationLoc."Document Type" := TempSalesLine2."Document Type";
                                                            AdvanceLetterLineRelationLoc."Document No." := TempSalesLine2."Document No.";
                                                            AdvanceLetterLineRelationLoc."Document Line No." := TempSalesLine2."Line No.";
                                                            AdvanceLetterLineRelationLoc."Letter No." := TempSalesAdvanceLetterLineLoc."Letter No.";
                                                            AdvanceLetterLineRelationLoc."Letter Line No." := TempSalesAdvanceLetterLineLoc."Line No.";
                                                            AdvanceLetterLineRelationLoc.Amount := DecrementAmt;
                                                            AdvanceLetterLineRelationLoc."Invoiced Amount" := DecrementAmt;
                                                            AdvanceLetterLineRelationLoc.Insert();
                                                            DecrementAmt := 0;
                                                        end;
                                                        SalesLine.Get(TempSalesLine2."Document Type",
                                                          TempSalesLine2."Document No.",
                                                          TempSalesLine2."Line No.");
                                                        UpdateOrderLine(SalesLine, SalesHeader."Prices Including VAT", true);
                                                        SalesLine.Modify();
                                                    end;
                                                until (TempSalesAdvanceLetterLineLoc.Next = 0) or (DecrementAmt = 0);
                                    end;
                                end;
                            end;
                        end;
                    end;
                TempSalesAdvanceLetterLineLoc.Reset();
                TempSalesAdvanceLetterLineLoc.DeleteAll();
            until TempSalesLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure SetSalesInvHeaderBuf(var SalesInvHeaderBuf2: Record "Sales Invoice Header")
    begin
        SalesInvHeaderBuf := SalesInvHeaderBuf2;
        CurrSalesInvHeader := SalesInvHeaderBuf;
    end;

    local procedure PostDocAfterApp(var TempAdvanceLink: Record "Advance Link" temporary)
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        IsPostAutVAT: Boolean;
    begin
        SalesSetup.Get();
        if TempAdvanceLink.Find('-') then
            repeat
                if TempAdvanceLink."Entry Type" = TempAdvanceLink."Entry Type"::"Link To Letter" then begin
                    SalesAdvanceLetterHeader.Get(TempAdvanceLink."Document No.");
                    TempSalesAdvanceLetterHeader := SalesAdvanceLetterHeader;
                    if TempSalesAdvanceLetterHeader.Insert() then;
                end;
            until TempAdvanceLink.Next = 0;

        if TempSalesAdvanceLetterHeader.Find('-') then
            repeat
                IsPostAutVAT := SalesSetup."Automatic Adv. Invoice Posting";
                if TempSalesAdvanceLetterHeader."Post Advance VAT Option" =
                   TempSalesAdvanceLetterHeader."Post Advance VAT Option"::Never
                then
                    IsPostAutVAT := true;
                if not IsPostAutVAT then
                    TempSalesAdvanceLetterHeader.Delete();
            until TempSalesAdvanceLetterHeader.Next = 0;

        if not TempSalesAdvanceLetterHeader.IsEmpty then begin
            SetLetterHeader(TempSalesAdvanceLetterHeader);
            AutoPostAdvanceInvoices;
        end;
    end;

    local procedure CreateBlankCrMemo(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; DocumentNo: Code[20]; PostingDate: Date; VATDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesHeader.Init();
        SalesHeader.TransferFields(SalesAdvanceLetterHeader);
        CopyBillToSellFromAdvLetter(SalesHeader, SalesAdvanceLetterHeader);
        SalesHeader."VAT Date" := VATDate;

        // Create posted header
        with SalesCrMemoHeader do begin
            Init;
            SalesHeader."Bank Account Code" := '';
            TransferFields(SalesHeader);
            "No." := DocumentNo;
            "Posting Date" := PostingDate;
            "VAT Date" := VATDate;
            "Document Date" := PostingDate;
            "Letter No." := SalesAdvanceLetterHeader."No.";
            "User ID" := UserId;
            "No. Printed" := 0;
            "Prices Including VAT" := true;
            "Prepayment Credit Memo" := true;
            "Currency Factor" :=
              CurrExchRate.ExchangeRate(PostingDate, SalesHeader."Currency Code");
            "Credit Memo Type" := "Credit Memo Type"::"Corrective Tax Document";
            Insert;
        end;

        with SalesCrMemoLine do begin
            Init;
            "Document No." := SalesCrMemoHeader."No.";
            "Line No." := 10000;
            Description :=
              CopyStr(StrSubstNo(DescTxt, SalesAdvanceLetterHeader."No."), 1, MaxStrLen(Description));
            Insert;
        end;
    end;

    local procedure GetCrMemoDocNo(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date) DocumentNo: Code[20]
    var
        SalesAdvPaymentTemplate: Record "Sales Adv. Payment Template";
    begin
        if SalesAdvanceLetterHeader."Template Code" <> '' then begin
            SalesAdvPaymentTemplate.Get(SalesAdvanceLetterHeader."Template Code");
            SalesAdvPaymentTemplate.TestField("Advance Credit Memo Nos.");
            DocumentNo :=
              NoSeriesMgt.GetNextNo(SalesAdvPaymentTemplate."Advance Credit Memo Nos.", PostingDate, true);
        end else begin
            SalesSetup.Get();
            SalesSetup.TestField("Advance Credit Memo Nos.");
            DocumentNo :=
              NoSeriesMgt.GetNextNo(SalesSetup."Advance Credit Memo Nos.", PostingDate, true);
        end;
    end;

    local procedure GetInvoiceDocNo(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date) DocumentNo: Code[20]
    var
        SalesAdvPaymentTemplate: Record "Sales Adv. Payment Template";
    begin
        if SalesAdvanceLetterHeader."Template Code" <> '' then begin
            SalesAdvPaymentTemplate.Get(SalesAdvanceLetterHeader."Template Code");
            SalesAdvPaymentTemplate.TestField("Advance Invoice Nos.");
            DocumentNo :=
              NoSeriesMgt.GetNextNo(SalesAdvPaymentTemplate."Advance Invoice Nos.", PostingDate, true);
        end else begin
            SalesSetup.Get();
            SalesSetup.TestField("Advance Invoice Nos.");
            DocumentNo :=
              NoSeriesMgt.GetNextNo(SalesSetup."Advance Invoice Nos.", PostingDate, true);
        end;
    end;

    local procedure CopyBillToSellFromAdvLetter(var SalesHeader: Record "Sales Header"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        with SalesHeader do begin
            "Sell-to Customer No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
            "Sell-to Customer Name" := SalesAdvanceLetterHeader."Bill-to Name";
            "Sell-to Customer Name 2" := SalesAdvanceLetterHeader."Bill-to Name 2";
            "Sell-to Address" := SalesAdvanceLetterHeader."Bill-to Address";
            "Sell-to Address 2" := SalesAdvanceLetterHeader."Bill-to Address 2";
            "Sell-to City" := SalesAdvanceLetterHeader."Bill-to City";
            "Sell-to Contact" := SalesAdvanceLetterHeader."Bill-to Contact";
            "Sell-to Post Code" := SalesAdvanceLetterHeader."Bill-to Post Code";
            "Sell-to County" := SalesAdvanceLetterHeader."Bill-to County";
            "Sell-to Country/Region Code" := SalesAdvanceLetterHeader."Bill-to Country/Region Code";
        end;
    end;

    local procedure CopyAdvLetterLineToBuffer(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        with PrepaymentInvLineBuffer do begin
            "G/L Account No." := SalesAdvanceLetterLine."No.";
            "Gen. Bus. Posting Group" := SalesAdvanceLetterLine."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := SalesAdvanceLetterLine."VAT Bus. Posting Group";
            "Gen. Prod. Posting Group" := SalesAdvanceLetterLine."Gen. Prod. Posting Group";
            "VAT Prod. Posting Group" := SalesAdvanceLetterLine."VAT Prod. Posting Group";
            "VAT Calculation Type" := SalesAdvanceLetterLine."VAT Calculation Type";
            "Global Dimension 1 Code" := SalesAdvanceLetterLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := SalesAdvanceLetterLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := SalesAdvanceLetterLine."Dimension Set ID";
            "Job No." := SalesAdvanceLetterLine."Job No.";
        end;
    end;

    [Scope('OnPrem')]
    procedure ReverseAmounts(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    begin
        with PrepaymentInvLineBuffer do begin
            Amount := -Amount;
            "Amount Incl. VAT" := -"Amount Incl. VAT";
            "VAT Amount" := -"VAT Amount";
            "VAT Base Amount" := -"VAT Base Amount";
            "Amount (ACY)" := -"Amount (ACY)";
            "VAT Amount (ACY)" := -"VAT Amount (ACY)";
            "VAT Base Amount (ACY)" := -"VAT Base Amount (ACY)";
            "VAT Difference" := -"VAT Difference";
        end;
    end;

    local procedure GetInvCurrFactor(LetterNo: Code[20]): Decimal
    var
        AdvanceLink: Record "Advance Link";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", LetterNo);
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Sale);
        AdvanceLink.SetRange("Invoice No.", '');
        AdvanceLink.SetRange("Transfer Date", 0D);
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.FindLast;
        CustLedgerEntry.Get(AdvanceLink."CV Ledger Entry No.");
        exit(CustLedgerEntry."Original Currency Factor");
    end;

    local procedure UpdateIncomingDocument(IncomingDocNo: Integer; PostingDate: Date; DocNo: Code[20])
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocNo, PostingDate, DocNo);
    end;

    [Scope('OnPrem')]
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure CheckReasonCodeForCrMemo(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        SalesSetup.Get();
        if not SalesSetup."Reas.Cd. on Tax Corr.Doc.Mand." then
            exit;

        SalesAdvanceLetterHeader.TestField("Reason Code");
    end;

    local procedure ClearReasonCodeOnCrMemo(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        with SalesAdvanceLetterHeader do begin
            if "Reason Code" = '' then
                exit;

            if Find then begin
                "Reason Code" := '';
                Modify;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLetterToGL(var GenJournalLine: Record "Gen. Journal Line"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVATCorrectionToGL(var GenJournalLine: Record "Gen. Journal Line"; SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostVATCrMemoPrepareGL(var GenJournalLine: Record "Gen. Journal Line"; SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;
}

