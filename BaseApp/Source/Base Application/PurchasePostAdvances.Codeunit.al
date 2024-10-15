codeunit 31020 "Purchase-Post Advances"
{
    Permissions = TableData "Vendor Ledger Entry" = rm,
                  TableData "Purch. Inv. Header" = im,
                  TableData "Purch. Inv. Line" = im,
                  TableData "Purch. Cr. Memo Hdr." = im,
                  TableData "Purch. Cr. Memo Line" = im,
                  TableData "Purch. Advance Letter Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        PurchHeader: Record "Purchase Header";
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        PurchInvHeaderBuf: Record "Purch. Inv. Header";
        CurrPurchInvHeader: Record "Purch. Inv. Header";
        Currency: Record Currency;
        PurchAdvPmtTemplate: Record "Purchase Adv. Payment Template";
        TempPurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry" temporary;
        TempVendLedgEntryGre: Record "Vendor Ledger Entry" temporary;
        TempAdvanceLink: Record "Advance Link" temporary;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PrevLineNo: Integer;
        LineNo: Integer;
        NextLinkEntryNo: Integer;
        VendNoGco: Code[20];
        SystemRun: Boolean;
        LetterNoToInvoice: Code[20];
        DisablePostingCuClear: Boolean;
        PurchAdvanceLetterEntryNo: Integer;
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
        Text009Txt: Label 'Advance Letter: %1', Comment = '%1=Letter No.';
        Text010Txt: Label 'Advance Invoice: %1', Comment = '%1=Document No';
        Text012Err: Label 'Since Ext. Doc. No. is Mandatory you must post Advance Credit Memos one by one from Advance Letter form.';
        Text013Txt: Label 'Advance %1 %2.', Comment = '%1=Document type;%2=Document number';
        Text032Err: Label 'The combination of dimensions used in %1 is blocked. %2.', Comment = '%1=Document No.;%2=Dimension Error Text';
        Text4005240Err: Label 'Advance must be before Invoice.';
        Text4005242Err: Label 'Total amount VAT usage document is different.';
        Text4005245Qst: Label 'Unpost advance usage on invoice %1?', Comment = '%1=Document No.';
        Text4005246Err: Label 'You must unapply entry %1.', Comment = '%1=Entry No.';
        Text4005247Err: Label 'You can not decrease invoiced amount under %1 on AP line %2 %3.', Comment = '%1=Compared field fieldcaption;%2=Letter number;%3=Letter Line number';
        Text4005248Err: Label 'Amount To Deduct is greater then Invoiced Amount on Line %1 dokladu %2 %3.', Comment = '%1=Compared field fieldcaption;%2=Document number;%3=Document Line number';
        Text4005249Err: Label 'Amount To Deduct can not be divided to relations on Line %1 dokladu %2 %3.', Comment = '%1=Document Line number;%2=Document type;%3=Document number';
        Text4005250Err: Label 'Amount To Deduct is greater then Document Invoiced Amount .';
        Text4005251Err: Label '%1 cannot be %2.', Comment = '%1=account 1 number;%2=account 2 number';
        AppPrefTxt: Label 'XX';
        Text034Txt: Label 'Invoice';
        Text035Txt: Label 'Credit Memo';
        Text036Err: Label 'must not be larger than %1.', Comment = '%1=Amount';
        Text037Err: Label 'You must fill VAT Date.';
        Text038Err: Label 'You must fill Posting Date.';
        Text039Err: Label 'Is not possible to refund requested amount on advance letter %1 line no. %2.', Comment = '%1=Document No.;%2=Document Line No.';
        Text040Err: Label 'Amount To Refund must be greater then 0.';
        Text041Err: Label 'Sum %1 and %2 must be greater or equal then %3.', Comment = '%1=Field Caption;%2=Amount to Inv.;%3=Amount to Deduct;';
        Text042Qst: Label 'Do You Want to Post and Close Purchase Advance Letter No. %1 Refund?', Comment = '%1=Document No.';
        Text043Msg: Label 'Advance Letter No. %1 has been Closed.', Comment = '%1=Document No.';
        DescTxt: Label 'Adv. Paym.  %1.', Comment = '%1=Document No.';
        PurchaseAlreadyExistsQst: Label 'Purchase %1 %2 already exists for this vendor.\Do you want to continue?', Comment = '%1 = Document Type; %2 = External Document No.; e.g. Purchase Invoice 123 already exists...';
        PreviewMode: Boolean;

    [Scope('OnPrem')]
    procedure Invoice(var PurchHeader: Record "Purchase Header")
    begin
        Code(PurchHeader, 0);
    end;

    [Scope('OnPrem')]
    procedure CreditMemo(var PurchHeader: Record "Purchase Header"; var PurchInvHeader1: Record "Purch. Inv. Header")
    begin
        CheckInvoicesForReverse(PurchHeader, PurchInvHeader1);
        Code(PurchHeader, 1);
    end;

    local procedure CheckInvoicesForReverse(PurchHeader: Record "Purchase Header"; var PurchInvHeader1: Record "Purch. Inv. Header")
    begin
        Clear(PurchInvHeaderBuf);
        PurchInvHeaderBuf.Copy(PurchInvHeader1);
        PurchInvHeaderBuf.SetRecFilter;
        with PurchInvHeaderBuf do begin
            if IsEmpty() then begin // All Invoices will be reversed
                Reset;
                SetCurrentKey("Prepayment Order No.");
                SetRange("Prepayment Order No.", PurchHeader."No.");
                SetFilter("Reversed By Cr. Memo No.", '%1', '');
            end;
            if IsEmpty() then
                Error(Text006Err);
            PurchSetup.Get();
            if PurchSetup."Ext. Doc. No. Mandatory" then
                if FindFirst and (Next <> 0) then
                    Error(Text012Err);
            if FindFirst then
                repeat
                    TestField("Prepayment Type", "Prepayment Type"::Advance);
                    TestField("Reversed By Cr. Memo No.", '');
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure Letter(var PurchHeader: Record "Purchase Header"; var AdvanceLetterNo: Code[20]; AdvanceTemplCode: Code[10])
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchHeader2: Record "Purchase Header";
        TempAdvanceLetterLineRelation: Record "Advance Letter Line Relation" temporary;
        VendPostGr: Record "Vendor Posting Group";
    begin
        GetPurchAdvanceTempl(AdvanceTemplCode);
        PurchHeader2 := PurchHeader;
        with PurchHeader2 do begin
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                FieldError("Document Type");
            TestField("Pay-to Vendor No.");
            TestField("Buy-from Vendor No.");
            if not CheckOpenPrepaymentLines(PurchHeader) then
                Error(Text001Err);

            Validate("Prepayment Type", "Prepayment Type"::Advance);
            // Get Doc. No. and save
            if "Advance Letter No." = '' then begin
                if AdvanceTemplCode = '' then begin
                    TestField("Advance Letter No. Series");
                    "Advance Letter No." :=
                      NoSeriesMgt.GetNextNo("Advance Letter No. Series", "Posting Date", true);
                end else begin
                    PurchAdvPmtTemplate.TestField("Advance Letter Nos.");
                    "Advance Letter No." :=
                      NoSeriesMgt.GetNextNo(PurchAdvPmtTemplate."Advance Letter Nos.", "Posting Date", true);
                end;
                Modify;
                if not SystemRun and not PreviewMode then
                    Commit();
            end;
            AdvanceLetterNo := "Advance Letter No.";

            PurchSetup.Get();
            CreatePurchAdvanceLetterHeader(PurchHeader2, AdvanceTemplCode, PurchAdvanceLetterHeader);

            // Create Lines
            TempPrepmtInvLineBuf.DeleteAll();

            CreateAdvanceInvLineBuf(PurchHeader, TempPrepmtInvLineBuf, TempAdvanceLetterLineRelation);
            OnLetterOnBeforeLetterCreatePurchAdvanceLetterLines(TempPrepmtInvLineBuf, TempAdvanceLetterLineRelation);
            TempPrepmtInvLineBuf.FindSet();
            repeat
                if TempPrepmtInvLineBuf."Line No." <> 0 then
                    LineNo := TempPrepmtInvLineBuf."Line No."
                else
                    LineNo := PrevLineNo + 10000;

                PurchAdvanceLetterLine.Init();
                PurchAdvanceLetterLine."Letter No." := "Advance Letter No.";
                PurchAdvanceLetterLine."Line No." := LineNo;
                PurchAdvanceLetterLine."Pay-to Vendor No." := "Pay-to Vendor No.";
                PurchAdvanceLetterLine."No." := TempPrepmtInvLineBuf."G/L Account No.";
                PurchAdvanceLetterLine."Shortcut Dimension 1 Code" := TempPrepmtInvLineBuf."Global Dimension 1 Code";
                PurchAdvanceLetterLine."Shortcut Dimension 2 Code" := TempPrepmtInvLineBuf."Global Dimension 2 Code";
                PurchAdvanceLetterLine."Dimension Set ID" := TempPrepmtInvLineBuf."Dimension Set ID";
                PurchAdvanceLetterLine.Description := TempPrepmtInvLineBuf.Description;
                PurchAdvanceLetterLine."Gen. Bus. Posting Group" := TempPrepmtInvLineBuf."Gen. Bus. Posting Group";
                PurchAdvanceLetterLine."Gen. Prod. Posting Group" := TempPrepmtInvLineBuf."Gen. Prod. Posting Group";
                PurchAdvanceLetterLine."VAT Bus. Posting Group" := TempPrepmtInvLineBuf."VAT Bus. Posting Group";
                PurchAdvanceLetterLine."VAT Prod. Posting Group" := TempPrepmtInvLineBuf."VAT Prod. Posting Group";
                PurchAdvanceLetterLine."VAT %" := TempPrepmtInvLineBuf."VAT %";
                PurchAdvanceLetterLine."Advance Due Date" := PurchAdvanceLetterHeader."Advance Due Date";
                PurchAdvanceLetterLine.Amount := TempPrepmtInvLineBuf.Amount;
                PurchAdvanceLetterLine."Amount Including VAT" := TempPrepmtInvLineBuf."Amount Incl. VAT";
                PurchAdvanceLetterLine."Amount To Link" := 0;
                PurchAdvanceLetterLine."VAT Calculation Type" := TempPrepmtInvLineBuf."VAT Calculation Type";
                PurchAdvanceLetterLine."VAT Amount" := TempPrepmtInvLineBuf."VAT Amount";
                PurchAdvanceLetterLine."VAT Identifier" := TempPrepmtInvLineBuf."VAT Identifier";
                PurchAdvanceLetterLine."Currency Code" := "Currency Code";
                VendPostGr.Get(PurchAdvanceLetterHeader."Vendor Posting Group");
                VendPostGr.TestField("Advance Account");
                PurchAdvanceLetterLine."Advance G/L Account No." := VendPostGr."Advance Account";
                PurchAdvanceLetterLine."Job No." := TempPrepmtInvLineBuf."Job No.";
                OnLetterOnBeforeInsertPurchAdvanceLetterLine(TempPrepmtInvLineBuf, PurchAdvanceLetterHeader, PurchAdvanceLetterLine);
                PurchAdvanceLetterLine.Insert(true);

                InsertLineRelations(TempPrepmtInvLineBuf."Entry No.", PurchAdvanceLetterLine, TempAdvanceLetterLineRelation);

                PrevLineNo := LineNo;
            until TempPrepmtInvLineBuf.Next() = 0;

            // Update header
            "Advance Letter No." := '';
            Modify;
        end;
        PurchHeader := PurchHeader2;
    end;

    local procedure CreatePurchAdvanceLetterHeader(PurchHeader: Record "Purchase Header"; AdvanceTemplCode: Code[10]; var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreatePurchAdvanceLetterHeader(PurchHeader, AdvanceTemplCode, PurchAdvanceLetterHeader, IsHandled);
        if IsHandled then
            exit;
        PurchAdvanceLetterHeader.Init();
        PurchAdvanceLetterHeader.TransferFields(PurchHeader);
        PurchAdvanceLetterHeader."No." := PurchHeader."Advance Letter No.";
        PurchAdvanceLetterHeader."Order No." := PurchHeader."No.";
        PurchAdvanceLetterHeader."No. Printed" := 0;
        PurchAdvanceLetterHeader."Your Reference" := PurchHeader."Your Reference";
        PurchAdvanceLetterHeader."Language Code" := PurchHeader."Language Code";
        PurchAdvanceLetterHeader."Payment Terms Code" := PurchHeader."Prepmt. Payment Terms Code";
        PurchAdvanceLetterHeader."Payment Method Code" := PurchHeader."Payment Method Code";
        PurchAdvanceLetterHeader."Registration No." := PurchHeader."Registration No.";
        PurchAdvanceLetterHeader."Tax Registration No." := PurchHeader."Tax Registration No.";
        PurchAdvanceLetterHeader."VAT Country/Region Code" := PurchHeader."VAT Country/Region Code";
        PurchAdvanceLetterHeader."Template Code" := AdvanceTemplCode;
        if AdvanceTemplCode <> '' then begin
            GetPurchAdvanceTempl(AdvanceTemplCode);
            if PurchAdvPmtTemplate."Vendor Posting Group" <> '' then
                PurchAdvanceLetterHeader."Vendor Posting Group" := PurchAdvPmtTemplate."Vendor Posting Group";
            PurchAdvanceLetterHeader."Post Advance VAT Option" := PurchAdvPmtTemplate."Post Advance VAT Option";
        end;
        PurchAdvanceLetterHeader."Amounts Including VAT" := PurchHeader."Prices Including VAT";
        PurchAdvanceLetterHeader.Insert();
    end;

    local procedure "Code"(var PurchHeader2: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        TempPurchAdvanceLetterHeaderLoc: Record "Purch. Advance Letter Header" temporary;
    begin
        PurchHeader := PurchHeader2;
        with PurchHeader do begin
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                FieldError("Document Type");

            TestField("Pay-to Vendor No.");
            TestField("Buy-from Vendor No.");

            case DocumentType of
                DocumentType::Invoice:
                    begin
                        PurchAdvanceLetterHeader.SetRange("Order No.", "No.");
                        if LetterNoToInvoice <> '' then
                            PurchAdvanceLetterHeader.SetRange("No.", LetterNoToInvoice);
                        CheckLetter(PurchAdvanceLetterHeader, DocumentType);
                        if PurchAdvanceLetterHeader.FindSet then
                            repeat
                                PostLetter(PurchAdvanceLetterHeader, DocumentType);
                            until PurchAdvanceLetterHeader.Next() = 0;
                    end;
                DocumentType::"Credit Memo":
                    begin
                        if PurchInvHeaderBuf.FindSet then
                            repeat
                                TempPurchAdvanceLetterHeaderLoc."No." := PurchInvHeaderBuf."Letter No.";
                                if TempPurchAdvanceLetterHeaderLoc.Insert() then;
                            until PurchInvHeaderBuf.Next() = 0;
                        CheckLetter(TempPurchAdvanceLetterHeaderLoc, DocumentType);
                        TempPurchAdvanceLetterHeaderLoc.DeleteAll();
                        if PurchInvHeaderBuf.FindSet then
                            repeat
                                CurrPurchInvHeader := PurchInvHeaderBuf;
                                if (LetterNoToInvoice = '') or (LetterNoToInvoice = PurchInvHeaderBuf."Letter No.") then begin
                                    PurchAdvanceLetterHeader.Get(PurchInvHeaderBuf."Letter No.");
                                    PostLetter(PurchAdvanceLetterHeader, DocumentType);
                                end;
                            until PurchInvHeaderBuf.Next() = 0;
                    end;
            end;
        end;
        PurchHeader2 := PurchHeader;
    end;

    local procedure CheckOpenPrepaymentLines(PurchHeader: Record "Purchase Header"): Boolean
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
        IsChecked: Boolean;
    begin
        OnBeforeCheckOpenPrepaymentLines(PurchHeader, IsChecked, IsHandled);
        if IsHandled then
            exit(IsChecked);
        with PurchLine do begin
            Reset;
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Prepmt. Line Amount", '<>0');
            if FindSet then begin
                repeat
                    if "Prepmt. Line Amount" > 0 then
                        exit(true);
                until Next() = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AutoLinkPayment(VendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        TempAdvanceLink: Record "Advance Link" temporary;
        AmountToLink: Decimal;
        NextLinkEntryNo: Integer;
        TotalAmounToLink: Decimal;
    begin
        if VendLedgEntry."Document Type" <> VendLedgEntry."Document Type"::Payment then
            exit;
        SetCurrencyPrecision(VendLedgEntry."Currency Code");

        PurchAdvanceLetterLine.SetCurrentKey("Pay-to Vendor No.");
        PurchAdvanceLetterLine.SetRange("Pay-to Vendor No.", VendLedgEntry."Vendor No.");

        if GenJnlLine."Advance Letter Link Code" <> '' then
            PurchAdvanceLetterLine.SetRange("Link Code", GenJnlLine."Advance Letter Link Code")
        else
            PurchAdvanceLetterLine.SetRange("Applies-to ID", VendLedgEntry."Document No.");

        if PurchAdvanceLetterLine.FindSet(true) then begin
            repeat
                if PurchAdvanceLetterLine."Amount Linked To Journal Line" <> 0 then begin
                    AmountToLink := PurchAdvanceLetterLine."Amount Linked To Journal Line";
                    TotalAmounToLink := TotalAmounToLink + AmountToLink;
                    PurchAdvanceLetterLine."Amount Linked To Journal Line" := 0;
                    PurchAdvanceLetterLine."Applies-to ID" := '';
                    PurchAdvanceLetterLine."Link Code" := '';
                    PurchAdvanceLetterLine.Modify();

                    if not TempPurchAdvanceLetterHeader.Get(PurchAdvanceLetterLine."Letter No.") then begin
                        TempPurchAdvanceLetterHeader."No." := PurchAdvanceLetterLine."Letter No.";
                        TempPurchAdvanceLetterHeader.Insert();
                    end;

                    NextLinkEntryNo := NextLinkEntryNo + 1;
                    TempAdvanceLink.Init();
                    TempAdvanceLink."Entry No." := NextLinkEntryNo;
                    TempAdvanceLink."Entry Type" := TempAdvanceLink."Entry Type"::"Link To Letter";
                    TempAdvanceLink."CV Ledger Entry No." := VendLedgEntry."Entry No.";
                    TempAdvanceLink."Posting Date" := VendLedgEntry."Posting Date";
                    TempAdvanceLink."Currency Code" := VendLedgEntry."Currency Code";
                    TempAdvanceLink.Amount := AmountToLink;
                    if TempAdvanceLink."Currency Code" = '' then
                        TempAdvanceLink."Amount (LCY)" := AmountToLink
                    else
                        TempAdvanceLink."Amount (LCY)" :=
                          Round(AmountToLink / VendLedgEntry."Original Currency Factor");
                    TempAdvanceLink."Remaining Amount to Deduct" := TempAdvanceLink.Amount;
                    TempAdvanceLink."Document No." := PurchAdvanceLetterLine."Letter No.";
                    TempAdvanceLink."Line No." := PurchAdvanceLetterLine."Line No.";
                    TempAdvanceLink.Type := TempAdvanceLink.Type::Purchase;
                    TempAdvanceLink.Insert();
                end;
            until PurchAdvanceLetterLine.Next() = 0;
        end;
        InsertLinks(TempAdvanceLink);
    end;

    procedure AutoPostAdvanceInvoices()
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        DocumentType: Option Invoice,"Credit Memo";
        PostingDate: Date;
    begin
        SystemRun := true;
        if CheckLetter(TempPurchAdvanceLetterHeader, DocumentType::Invoice) then
            if TempPurchAdvanceLetterHeader.FindSet then
                repeat
                    PurchAdvanceLetterHeader.Get(TempPurchAdvanceLetterHeader."No.");
                    Clear(PurchHeader);

                    CalcPostingDate(PurchAdvanceLetterHeader, PostingDate);
                    if PurchAdvanceLetterHeader."Posting Date" < PostingDate then
                        PurchAdvanceLetterHeader."Posting Date" := PostingDate;
                    if PurchAdvanceLetterHeader."VAT Date" = 0D then
                        PurchAdvanceLetterHeader."VAT Date" := PurchAdvanceLetterHeader."Posting Date";
                    PurchAdvanceLetterHeader.Modify();
                    case PurchAdvanceLetterHeader."Post Advance VAT Option" of
                        PurchAdvanceLetterHeader."Post Advance VAT Option"::Always:
                            PostLetter(PurchAdvanceLetterHeader, DocumentType::Invoice);
                        PurchAdvanceLetterHeader."Post Advance VAT Option"::Never:
                            TransAmountWithoutInv(PurchAdvanceLetterHeader);
                    end;
                until TempPurchAdvanceLetterHeader.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertInitialAdvanceLink(VendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
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
            Type := Type::Purchase;
            "Currency Code" := VendLedgEntry."Currency Code";
            Amount := GenJnlLine.Amount;
            "Amount (LCY)" := GenJnlLine."Amount (LCY)";
            "CV Ledger Entry No." := VendLedgEntry."Entry No.";
            Insert;
        end;
    end;

    local procedure CheckAmountToLink(GenJnlLine: Record "Gen. Journal Line")
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        TotalAmount: Decimal;
    begin
        PurchAdvanceLetterLine.SetCurrentKey("Pay-to Vendor No.");
        PurchAdvanceLetterLine.SetRange("Pay-to Vendor No.", GenJnlLine."Account No.");

        if GenJnlLine."Advance Letter Link Code" <> '' then
            PurchAdvanceLetterLine.SetRange("Link Code", GenJnlLine."Advance Letter Link Code")
        else
            PurchAdvanceLetterLine.SetRange("Applies-to ID", GenJnlLine."Document No.");
        if PurchAdvanceLetterLine.FindSet then begin
            repeat
                if Abs(PurchAdvanceLetterLine."Amount Linked To Journal Line") > Abs(PurchAdvanceLetterLine."Amount To Link") then
                    PurchAdvanceLetterLine.FieldError(
                      "Amount Linked To Journal Line",
                      StrSubstNo(Text008Err, PurchAdvanceLetterLine.FieldCaption("Amount To Link"), PurchAdvanceLetterLine."Amount To Link"));
                TotalAmount := TotalAmount + PurchAdvanceLetterLine."Amount Linked To Journal Line";
            until PurchAdvanceLetterLine.Next() = 0;
            if Abs(TotalAmount) > Abs(GenJnlLine.Amount) then
                PurchAdvanceLetterLine.FieldError(
                  "Amount Linked To Journal Line",
                  StrSubstNo(Text008Err, GenJnlLine.FieldCaption(Amount), GenJnlLine.Amount));
        end;
    end;

    [Scope('OnPrem')]
    procedure HandleLinksBuf(var AdvanceLinkBuf2: Record "Advance Link Buffer")
    var
        TempAdvanceLinkBuf3: Record "Advance Link Buffer" temporary;
        TempAdvanceLinkBuf: Record "Advance Link Buffer" temporary;
        TempAdvanceLink: Record "Advance Link" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        AmountToLink: Decimal;
    begin
        if AdvanceLinkBuf2.FindSet then begin
            repeat
                if AdvanceLinkBuf2."Entry Type" = AdvanceLinkBuf2."Entry Type"::Payment then begin
                    TempAdvanceLinkBuf3 := AdvanceLinkBuf2;
                    TempAdvanceLinkBuf3.Insert();
                end else begin
                    TempAdvanceLinkBuf := AdvanceLinkBuf2;
                    TempAdvanceLinkBuf.Insert();
                end;
            until AdvanceLinkBuf2.Next() = 0;

            NextLinkEntryNo := 0;
            if TempAdvanceLinkBuf3.FindSet(true) then
                repeat
                    SetCurrencyPrecision(TempAdvanceLinkBuf3."Currency Code");
                    VendLedgEntry.Get(TempAdvanceLinkBuf3."Entry No.");

                    TempAdvanceLinkBuf.SetFilter("Amount To Link", '<>%1', 0);
                    if TempAdvanceLinkBuf.FindSet(true) then
                        repeat
                            if Abs(TempAdvanceLinkBuf."Amount To Link") < Abs(TempAdvanceLinkBuf3."Amount To Link") then
                                AmountToLink := TempAdvanceLinkBuf."Amount To Link"
                            else
                                AmountToLink := -TempAdvanceLinkBuf3."Amount To Link";
                            TempAdvanceLinkBuf3."Amount To Link" := TempAdvanceLinkBuf3."Amount To Link" + AmountToLink;
                            TempAdvanceLinkBuf3.Modify();
                            TempAdvanceLinkBuf."Amount To Link" := TempAdvanceLinkBuf."Amount To Link" - AmountToLink;
                            TempAdvanceLinkBuf.Modify();

                            NextLinkEntryNo := NextLinkEntryNo + 1;
                            TempAdvanceLink.Init();
                            TempAdvanceLink."Entry No." := NextLinkEntryNo;
                            TempAdvanceLink."Entry Type" := TempAdvanceLink."Entry Type"::"Link To Letter";
                            TempAdvanceLink.Type := TempAdvanceLink.Type::Purchase;
                            TempAdvanceLink."CV Ledger Entry No." := TempAdvanceLinkBuf3."Entry No.";
                            TempAdvanceLink."Posting Date" := VendLedgEntry."Posting Date";
                            TempAdvanceLink."Currency Code" := TempAdvanceLinkBuf3."Currency Code";
                            TempAdvanceLink.Amount := AmountToLink;
                            if TempAdvanceLink."Currency Code" = '' then
                                TempAdvanceLink."Amount (LCY)" := AmountToLink
                            else
                                TempAdvanceLink."Amount (LCY)" :=
                                  Round(AmountToLink / VendLedgEntry."Original Currency Factor");
                            TempAdvanceLink."Remaining Amount to Deduct" := TempAdvanceLink.Amount;
                            TempAdvanceLink."Document No." := TempAdvanceLinkBuf."Document No.";
                            TempAdvanceLink."Line No." := TempAdvanceLinkBuf."Entry No.";
                            TempAdvanceLink.Insert();

                        until TempAdvanceLinkBuf.Next() = 0;
                until TempAdvanceLinkBuf3.Next() = 0;

            InsertLinks(TempAdvanceLink);
            PostDocAfterApp(TempAdvanceLink);
        end;
    end;

    local procedure InsertLinks(var AdvanceLink: Record "Advance Link")
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        AdvanceLink2: Record "Advance Link";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        AdvanceLink2.LockTable();
        if AdvanceLink2.FindLast then
            NextLinkEntryNo := AdvanceLink2."Entry No." + 1
        else
            NextLinkEntryNo := 1;

        if AdvanceLink.FindSet then
            repeat
                AdvanceLink2.TransferFields(AdvanceLink);
                AdvanceLink2."Entry No." := NextLinkEntryNo;
                AdvanceLink2.Insert();
                if AdvanceLink2."Entry Type" = AdvanceLink2."Entry Type"::"Link To Letter" then begin
                    PurchAdvanceLetterLine.Get(AdvanceLink2."Document No.", AdvanceLink2."Line No.");
                    PurchAdvanceLetterLine."Amount To Link" := PurchAdvanceLetterLine."Amount To Link" + AdvanceLink2.Amount;
                    PurchAdvanceLetterLine."Amount Linked" := PurchAdvanceLetterLine."Amount Linked" - AdvanceLink2.Amount;
                    PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" - AdvanceLink2.Amount;
                    PurchAdvanceLetterLine.SuspendStatusCheck(true);
                    PurchAdvanceLetterLine.Modify(true);
                    PurchAdvanceLetterHeader.Get(PurchAdvanceLetterLine."Letter No.");
                    GetPurchAdvanceTempl(PurchAdvanceLetterHeader."Template Code");
                    if PurchAdvPmtTemplate."Check Posting Group on Link" then begin
                        VendLedgEntry.Get(AdvanceLink2."CV Ledger Entry No.");
                        VendLedgEntry.TestField("Vendor Posting Group", PurchAdvanceLetterHeader."Vendor Posting Group");
                    end;
                end;
                TempVendLedgEntry."Entry No." := AdvanceLink2."CV Ledger Entry No.";
                if not TempVendLedgEntry.Find then
                    TempVendLedgEntry.Insert();
                NextLinkEntryNo := NextLinkEntryNo + 1;
            until AdvanceLink.Next() = 0;
        UpdateVendLedgEntries(TempVendLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure RemoveLinks(LetterNo: Code[20]; var AdvanceLink: Record "Advance Link")
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        if AdvanceLink.IsEmpty() then begin
            AdvanceLink.Reset();
            AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
            AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
            AdvanceLink.SetRange("Document No.", LetterNo);
            AdvanceLink.SetRange("Invoice No.", '');
            AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);
        end;
        if AdvanceLink.FindSet(true) then
            repeat
                AdvanceLink.TestField(Type, AdvanceLink.Type::Purchase);
                AdvanceLink.TestField("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                AdvanceLink.TestField("Document No.", LetterNo);
                AdvanceLink.TestField("Invoice No.", '');
                PurchAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");
                PurchAdvanceLetterLine."Amount To Link" := PurchAdvanceLetterLine."Amount To Link" - AdvanceLink.Amount;
                PurchAdvanceLetterLine."Amount Linked" := PurchAdvanceLetterLine."Amount Linked" + AdvanceLink.Amount;
                if AdvanceLink."Transfer Date" = 0D then
                    PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" + AdvanceLink.Amount
                else begin
                    PurchAdvanceLetterLine."Amount Invoiced" := PurchAdvanceLetterLine."Amount Invoiced" + AdvanceLink.Amount;
                    PurchAdvanceLetterLine."Amount To Deduct" := PurchAdvanceLetterLine."Amount To Deduct" + AdvanceLink.Amount;
                end;
                PurchAdvanceLetterLine.SuspendStatusCheck(true);
                PurchAdvanceLetterLine.Modify(true);
                UpdInvAmountToLineRelations(PurchAdvanceLetterLine);
                AdvanceLink.Delete();
                TempVendLedgEntry."Entry No." := AdvanceLink."CV Ledger Entry No.";
                if not TempVendLedgEntry.Find then
                    TempVendLedgEntry.Insert();
            until AdvanceLink.Next() = 0;

        if LetterNo <> '' then begin
            PurchAdvanceLetterLine.Reset();
            PurchAdvanceLetterLine.SetRange("Letter No.", LetterNo);
            PurchAdvanceLetterLine.ModifyAll("VAT Difference Inv.", 0);
            PurchAdvanceLetterLine.ModifyAll("VAT Difference Inv. (LCY)", 0);
            PurchAdvanceLetterLine.ModifyAll("VAT Correction Inv.", false);
            PurchAdvanceLetterLine.ModifyAll("VAT Amount Inv.", 0);
        end;

        UpdateVendLedgEntries(TempVendLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure RemovePmtLinks(EntryNo: Integer)
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        AdvanceLink: Record "Advance Link";
        LinksToAdvanceLetter: Page "Links to Advance Letter";
        IsHandled: Boolean;
    begin
        OnBeforeRemovePmtLinks(EntryNo, IsHandled);
        if IsHandled then
            exit;
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
                        PurchAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");
                        FillPurchAdvanceLetterLineAmounts(PurchAdvanceLetterLine, AdvanceLink);

                        PurchAdvanceLetterLine.SuspendStatusCheck(true);
                        PurchAdvanceLetterLine.Modify(true);
                        UpdInvAmountToLineRelations(PurchAdvanceLetterLine);
                        AdvanceLink.Delete();
                    end;
                until AdvanceLink.Next() = 0;
                TempVendLedgEntry."Entry No." := EntryNo;
                TempVendLedgEntry.Insert();
                UpdateVendLedgEntries(TempVendLedgEntry);
            end;
        end;
    end;

    local procedure FillPurchAdvanceLetterLineAmounts(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; AdvanceLink: Record "Advance Link")
    var
        IsHandled: Boolean;
    begin
        OnBeforeFillPurchAdvanceLetterLineAmounts(AdvanceLink, PurchAdvanceLetterLine, IsHandled);
        if IsHandled then
            exit;

        PurchAdvanceLetterLine."Amount To Link" := PurchAdvanceLetterLine."Amount To Link" + Abs(AdvanceLink.Amount);
        PurchAdvanceLetterLine."Amount Linked" := PurchAdvanceLetterLine."Amount Linked" - Abs(AdvanceLink.Amount);
        if AdvanceLink."Transfer Date" = 0D then
            PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" - Abs(AdvanceLink.Amount)
        else begin
            PurchAdvanceLetterLine."Amount Invoiced" := PurchAdvanceLetterLine."Amount Invoiced" - Abs(AdvanceLink.Amount);
            PurchAdvanceLetterLine."Amount To Deduct" := PurchAdvanceLetterLine."Amount To Deduct" - Abs(AdvanceLink.Amount);
        end;
    end;

    local procedure UpdateVendLedgEntries(var VendLedgEntry2: Record "Vendor Ledger Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if VendLedgEntry2.FindSet then
            repeat
                VendLedgEntry.Get(VendLedgEntry2."Entry No.");
                VendLedgEntry.CalcFields("Remaining Amount to Link");
                VendLedgEntry."Open For Advance Letter" := VendLedgEntry."Remaining Amount to Link" <> 0;
                VendLedgEntry.Modify();
            until VendLedgEntry2.Next() = 0;
    end;

    local procedure CheckLetter(var PurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo"): Boolean
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        OK: Boolean;
    begin
        PurchSetup.Get();
        OK := false;
        if PurchAdvanceLetterHeader2.FindSet then
            repeat
                PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader2."No.");
                if DocumentType = DocumentType::Invoice then
                    PurchAdvanceLetterLine.SetFilter("Amount To Invoice", '<>%1', 0)
                else
                    PurchAdvanceLetterLine.SetFilter("Amount To Deduct", '<>%1', 0);
                OK := not PurchAdvanceLetterLine.IsEmpty;
            until (PurchAdvanceLetterHeader2.Next() = 0) or OK;

        if not OK then begin
            if SystemRun then
                exit(false);
            Error(Text006Err);
        end;
        exit(true)
    end;

    [Scope('OnPrem')]
    procedure TransAmountWithoutInv(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    var
        AdvanceLink: Record "Advance Link";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        if (PurchAdvanceLetterHeader."Post Advance VAT Option" <> PurchAdvanceLetterHeader."Post Advance VAT Option"::Never) and
           (PurchAdvanceLetterHeader."Post Advance VAT Option" <> PurchAdvanceLetterHeader."Post Advance VAT Option"::Optional)
        then
            Error(Text4005251Err, PurchAdvanceLetterHeader.FieldCaption("Post Advance VAT Option"),
              PurchAdvanceLetterHeader."Post Advance VAT Option");
        PurchAdvanceLetterHeader.CalcFields(Status);
        if PurchAdvanceLetterHeader.Status > PurchAdvanceLetterHeader.Status::"Pending Invoice" then
            PurchAdvanceLetterHeader.TestField(Status, PurchAdvanceLetterHeader.Status::"Pending Invoice");
        PurchAdvanceLetterHeader.CheckAmountToInvoice;

        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Document No.", PurchAdvanceLetterHeader."No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);
        AdvanceLink.SetRange("Invoice No.", '');
        OnTransAmountWithoutInvOnAfterSetAdvanceLinkFilters(AdvanceLink);
        if AdvanceLink.FindSet then
            repeat
                if AdvanceLink."Transfer Date" = 0D then begin
                    PurchAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");
                    PurchAdvanceLetterLine."Amount Invoiced" := PurchAdvanceLetterLine."Amount Invoiced" - AdvanceLink.Amount;
                    PurchAdvanceLetterLine."Amount To Deduct" := PurchAdvanceLetterLine."Amount To Deduct" - AdvanceLink.Amount;
                    PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" + AdvanceLink.Amount;
                    PurchAdvanceLetterLine.SuspendStatusCheck(true);
                    PurchAdvanceLetterLine.Modify(true);
                    UpdInvAmountToLineRelations(PurchAdvanceLetterLine);
                    AdvanceLink."Transfer Date" := WorkDate;
                    OnTransAmountWithoutInvOnBeforeModifyAdvanceLink(PurchAdvanceLetterHeader, AdvanceLink);
                    AdvanceLink.Modify();
                    OnTransAmountWithoutInvOnAfterModifyAdvanceLink(AdvanceLink, PurchAdvanceLetterHeader, PurchAdvanceLetterLine);
                end;
            until AdvanceLink.Next() = 0;

        UpdateLines(PurchAdvanceLetterHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure RestoreTransfAmountWithoutInv(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    var
        AdvanceLink: Record "Advance Link";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        if (PurchAdvanceLetterHeader."Post Advance VAT Option" <> PurchAdvanceLetterHeader."Post Advance VAT Option"::Never) and
           (PurchAdvanceLetterHeader."Post Advance VAT Option" <> PurchAdvanceLetterHeader."Post Advance VAT Option"::Optional)
        then
            Error(Text4005251Err, PurchAdvanceLetterHeader.FieldCaption("Post Advance VAT Option"),
              PurchAdvanceLetterHeader."Post Advance VAT Option");
        PurchAdvanceLetterHeader.CalcFields(Status);
        if PurchAdvanceLetterHeader.Status > PurchAdvanceLetterHeader.Status::"Pending Final Invoice" then
            PurchAdvanceLetterHeader.TestField(Status, PurchAdvanceLetterHeader.Status::"Pending Final Invoice");

        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Document No.", PurchAdvanceLetterHeader."No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);
        AdvanceLink.SetRange("Invoice No.", '');
        OnRestoreTransfAmountWithoutInvOnAfterSetAdvanceLinkFilters(AdvanceLink);
        if AdvanceLink.FindSet then
            repeat
                if (AdvanceLink."Transfer Date" <> 0D) and
                   (AdvanceLink.Amount = AdvanceLink."Remaining Amount to Deduct")
                then begin
                    PurchAdvanceLetterLine.Get(AdvanceLink."Document No.", AdvanceLink."Line No.");
                    PurchAdvanceLetterLine."Amount Invoiced" := PurchAdvanceLetterLine."Amount Invoiced" + AdvanceLink.Amount;
                    PurchAdvanceLetterLine."Amount To Deduct" := PurchAdvanceLetterLine."Amount To Deduct" + AdvanceLink.Amount;
                    PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" - AdvanceLink.Amount;
                    PurchAdvanceLetterLine.SuspendStatusCheck(true);
                    PurchAdvanceLetterLine.Modify(true);
                    UpdInvAmountToLineRelations(PurchAdvanceLetterLine);
                    AdvanceLink."Transfer Date" := 0D;
                    OnRestoreTransfAmountWithoutInvOnBeforeModifyAdvanceLink(PurchAdvanceLetterHeader, AdvanceLink);
                    AdvanceLink.Modify();
                    OnRestoreTransfAmountWithoutInvOnAfterModifyAdvanceLink(AdvanceLink, PurchAdvanceLetterHeader, PurchAdvanceLetterLine);
                end;
            until AdvanceLink.Next() = 0;

        UpdateLines(PurchAdvanceLetterHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure PostLetter(var PurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo"): Boolean
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        GenJnlLine: Record "Gen. Journal Line";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        SourceCodeSetup: Record "Source Code Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry";
        Window: Dialog;
        LineCount: Integer;
        GenJnlLineDocNo: Code[20];
        GenJnlLineDocType: Integer;
        SrcCode: Code[10];
        PostingDate: Date;
        LineAmount: Decimal;
        PostingDescription: Text[50];
        VATDate: Date;
    begin
        OnBeforePostLetter(PurchAdvanceLetterHeader2, DocumentType);

        PurchAdvanceLetterHeader := PurchAdvanceLetterHeader2;
        PurchAdvanceLetterHeader.OnCheckPurchaseAdvanceLetterPostRestrictions;
        PurchSetup.Get();
        PostLetter_PreTest(PurchAdvanceLetterHeader, DocumentType);

        with PurchHeader do begin
            Clear(PurchHeader);
            SetCurrencyPrecision("Currency Code");

            PurchAdvanceLetterHeader.CalcFields(Status);

            TransferFields(PurchAdvanceLetterHeader);
            CopyPayToSellFromAdvLetter(PurchHeader, PurchAdvanceLetterHeader);
            UpdateIncomingDocument(
              PurchAdvanceLetterHeader."Incoming Document Entry No.",
              PurchAdvanceLetterHeader."Posting Date",
              PurchAdvanceLetterHeader."No.");

            "Prepayment Type" := "Prepayment Type"::Advance;

            GLSetup.Get();

            // Get Doc. No. and save
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        TestField("Prepmt. Cr. Memo No.", '');
                        PostingDate := PurchAdvanceLetterHeader."Posting Date";
                        VATDate := PurchAdvanceLetterHeader."VAT Date";
                        if VATDate = 0D then
                            VATDate := PostingDate;
                        if "Prepayment No." = '' then
                            "Prepayment No." := GetInvoiceDocNo(PurchAdvanceLetterHeader, PostingDate);
                        GenJnlLineDocNo := "Prepayment No.";
                        GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    end;
                DocumentType::"Credit Memo":
                    begin
                        TestField("Prepayment No.", '');
                        PurchAdvanceLetterHeader.TESTFIELD("Posting Date");
                        PostingDate := PurchAdvanceLetterHeader."Posting Date";
                        VATDate := PurchAdvanceLetterHeader."VAT Date";
                        if VATDate = 0D then
                            VATDate := PostingDate;
                        if "Prepmt. Cr. Memo No." = '' then
                            "Prepmt. Cr. Memo No." := GetCrMemoDocNo(PurchAdvanceLetterHeader, PostingDate);
                        GenJnlLineDocNo := "Prepmt. Cr. Memo No.";
                        GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    end;
            end;

            Window.Open(
              '#1#################################\\' +
              Text002Msg);
            Window.Update(1, StrSubstNo('%1 %2', SelectStr(1 + DocumentType, Text003Txt), GenJnlLineDocNo));

            SourceCodeSetup.Get();
            SrcCode := SourceCodeSetup.Purchases;

            PostingDescription :=
              CopyStr(
                StrSubstNo(Text013Txt, SelectStr(1 + DocumentType, Text003Txt), "No."),
                1, MaxStrLen("Posting Description"));

            // Create posted header
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        PostLetter_SetInvHeader(PurchInvHeader, PurchAdvanceLetterHeader, PurchHeader, GenJnlLineDocNo, SrcCode, PostingDescription,
                          PostingDate, VATDate);
                        GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                        Window.Update(1, StrSubstNo(Text004Msg, "Document Type", "No.", PurchInvHeader."No."));
                    end;
                DocumentType::"Credit Memo":
                    begin
                        PostLetter_SetCrMemoHeader(
                          PurchCrMemoHdr, PurchInvHeaderBuf, PurchAdvanceLetterHeader, GenJnlLineDocNo, SrcCode, PostingDescription);

                        PurchInvHeader.Get(CurrPurchInvHeader."No.");
                        PurchInvHeader."Reversed By Cr. Memo No." := PurchCrMemoHdr."No.";
                        PurchInvHeader.Modify();

                        PurchAdvanceLetterEntry.SetCurrentKey("Document No.", "Posting Date");
                        PurchAdvanceLetterEntry.SetRange("Document No.", PurchInvHeader."No.");
                        PurchAdvanceLetterEntry.SetRange("Posting Date", PurchInvHeader."Posting Date");
                        PurchAdvanceLetterEntry.SetRange("Letter No.", PurchInvHeader."Letter No.");
                        PurchAdvanceLetterEntry.ModifyAll(Cancelled, true);
                        GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                        Window.Update(1, StrSubstNo(Text005Msg, "Document Type", "No.", PurchCrMemoHdr."No."));
                    end;
            end;

            // Create Lines
            LineCount := 0;
            TempPrepmtInvLineBuf.DeleteAll();

            case DocumentType of
                DocumentType::Invoice:
                    BuildInvoiceLineBuf(PurchAdvanceLetterHeader, TempPrepmtInvLineBuf);
                DocumentType::"Credit Memo":
                    BuilCreditMemoBuf(PurchAdvanceLetterHeader, TempPrepmtInvLineBuf);
            end;

            if TempPrepmtInvLineBuf.FindSet then
                repeat
                    LineAmount := TempPrepmtInvLineBuf."VAT Amount";

                    case DocumentType of
                        DocumentType::Invoice:
                            PostLetter_SetInvLine(PurchInvLine, PurchInvHeader, TempPrepmtInvLineBuf, LineAmount);
                        DocumentType::"Credit Memo":
                            PostLetter_SetCrMemoLine(PurchCrMemoLine, PurchCrMemoHdr, TempPrepmtInvLineBuf, PurchAdvanceLetterEntry,
                              PurchAdvanceLetterHeader."No.", CurrPurchInvHeader."No.");
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

                    PostLetter_PostToGL(GenJnlLine, TempPrepmtInvLineBuf, PurchAdvanceLetterHeader, PurchAdvanceLetterEntry,
                      DocumentType, GenJnlLineDocNo, GenJnlLineDocType, PostingDescription, SrcCode,
                      PostingDate, VATDate);

                    OnBeforePostLetterToGL(GenJnlLine, PurchAdvanceLetterHeader);
                    RunGenJnlPostLine(GenJnlLine);

                    PurchAdvanceLetterLine.Get(PurchAdvanceLetterHeader."No.", TempPrepmtInvLineBuf."Line No.");

                    PostLetter_UpdtAdvLines(
                      PurchAdvanceLetterLine, PurchAdvanceLetterHeader, DocumentType, GenJnlLineDocType, GenJnlLineDocNo, LineAmount, PostingDate);

                    FillVATFieldsOfDeductionEntry(TempPrepmtInvLineBuf."VAT %");
                    TempPurchAdvanceLetterEntry."VAT Identifier" := TempPrepmtInvLineBuf."VAT Identifier";
                    TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::VAT;
                    TempPurchAdvanceLetterEntry."Purchase Line No." := TempPrepmtInvLineBuf."Line No.";
                    TempPurchAdvanceLetterEntry."Document Type" := GenJnlLine."Document Type";
                    if DocumentType = DocumentType::Invoice then begin
                        TempPurchAdvanceLetterEntry."VAT Base Amount" := -TempPrepmtInvLineBuf."VAT Base Amount";
                        TempPurchAdvanceLetterEntry."VAT Amount" := -TempPrepmtInvLineBuf."VAT Amount";
                    end else begin
                        TempPurchAdvanceLetterEntry."VAT Base Amount" := -PurchAdvanceLetterEntry."VAT Base Amount";
                        TempPurchAdvanceLetterEntry."VAT Amount" := -PurchAdvanceLetterEntry."VAT Amount";
                    end;
                    TempPurchAdvanceLetterEntry.Cancelled := (DocumentType = DocumentType::"Credit Memo");
                    TempPurchAdvanceLetterEntry.Modify();
                until TempPrepmtInvLineBuf.Next() = 0;
            SaveDeductionEntries;
        end;

        // Update Letter Header

        LastPostedDocNo := GenJnlLineDocNo;

        if PurchAdvanceLetterHeader."Order No." <> '' then
            with PurchAdvanceLetterHeader do begin
                "Document Date" := PostingDate;
                "External Document No." := '';
                OnPostLetterOnBeforeModifyPurchAdvanceLetterHeader(PostingDate, PurchAdvanceLetterHeader);
                Modify;
            end;

        UpdateLines(PurchAdvanceLetterHeader."No.");

        PurchAdvanceLetterHeader2 := PurchAdvanceLetterHeader;

        if not DisablePostingCuClear then
            Clear(GenJnlPostLine);

        OnAfterPostLetter(PurchAdvanceLetterHeader2);

        Window.Close;
        exit(true);
    end;

    local procedure PostLetter_PreTest(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        DocumentTypeTxt: Text;
    begin
        ApprovalsMgmt.PrePostApprovalCheckPurchaseAdvanceLetter(PurchAdvanceLetterHeader);
        PurchAdvanceLetterHeader.TestField("Posting Date");
        GLSetup.Get();

        if GLSetup."Use VAT Date" then begin
            PurchAdvanceLetterHeader.TestField("VAT Date");
            PurchAdvanceLetterHeader.TestField("Original Document VAT Date");
        end;
        if (PurchAdvanceLetterHeader."Post Advance VAT Option" <> PurchAdvanceLetterHeader."Post Advance VAT Option"::Always) and
           (PurchAdvanceLetterHeader."Post Advance VAT Option" <> PurchAdvanceLetterHeader."Post Advance VAT Option"::Optional)
        then
            Error(Text4005251Err, PurchAdvanceLetterHeader.FieldCaption("Post Advance VAT Option"),
              PurchAdvanceLetterHeader."Post Advance VAT Option");

        OnPostLetter_PreTestOnBeforeCheckDimIDComb(PurchAdvanceLetterHeader);
        if not DimMgt.CheckDimIDComb(PurchAdvanceLetterHeader."Dimension Set ID") then
            Error(
              Text032Err,
              PurchAdvanceLetterHeader."No.", DimMgt.GetDimCombErr);

        PurchAdvanceLetterHeader.CalcFields(Status);
        if DocumentType = DocumentType::Invoice then begin
            if PurchAdvanceLetterHeader.Status > PurchAdvanceLetterHeader.Status::"Pending Invoice" then
                PurchAdvanceLetterHeader.TestField(Status, PurchAdvanceLetterHeader.Status::"Pending Invoice");
            PurchAdvanceLetterHeader.CheckAmountToInvoice;
        end else begin
            if PurchAdvanceLetterHeader.Status > PurchAdvanceLetterHeader.Status::"Pending Final Invoice" then
                PurchAdvanceLetterHeader.TestField(Status, PurchAdvanceLetterHeader.Status::"Pending Final Invoice");
            PurchAdvanceLetterHeader.CheckDeductedAmount;
        end;

        if PurchSetup."Ext. Doc. No. Mandatory" then begin
            PurchAdvanceLetterHeader.TestField("External Document No.");

            case DocumentType of
                DocumentType::Invoice:
                    DocumentTypeTxt := Text034Txt;
                DocumentType::"Credit Memo":
                    DocumentTypeTxt := Text035Txt;
            end;

            if not CheckExternalDocumentNumber(PurchAdvanceLetterHeader, DocumentType) then
                if not Confirm(
                     PurchaseAlreadyExistsQst, false,
                     DocumentTypeTxt, PurchAdvanceLetterHeader."External Document No.")
                then
                    Error('');
        end;
    end;

    local procedure PostLetter_SetInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PurchaseHeader: Record "Purchase Header"; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingDescription: Text[50]; PostingDate: Date; VATDate: Date)
    begin
        with PurchInvHeader do begin
            Init;
            TransferFields(PurchaseHeader);
            "Posting Description" := PostingDescription;
            "Payment Terms Code" := PurchaseHeader."Prepmt. Payment Terms Code";
            "Posting Date" := PostingDate;
            "Document Date" := PostingDate;
            "VAT Date" := VATDate;
            "Original Document VAT Date" := PurchAdvanceLetterHeader."Original Document VAT Date";
            "Currency Factor" := PurchAdvanceLetterHeader."Currency Factor";
            "Due Date" := PurchAdvanceLetterHeader."Advance Due Date";
            "No." := GenJnlLineDocNo;
            "Pre-Assigned No. Series" := '';
            "Source Code" := SrcCode;
            "User ID" := UserId;
            "No. Printed" := 0;
            "Prices Including VAT" := true;
            "Prepayment Invoice" := true;
            "Your Reference" := PurchAdvanceLetterHeader."Your Reference";
            "Language Code" := PurchAdvanceLetterHeader."Language Code";
            "Payment Terms Code" := PurchAdvanceLetterHeader."Payment Terms Code";
            "Payment Method Code" := PurchAdvanceLetterHeader."Payment Method Code";
            "Registration No." := PurchAdvanceLetterHeader."Registration No.";
            "Tax Registration No." := PurchAdvanceLetterHeader."Tax Registration No.";
            "VAT Country/Region Code" := PurchAdvanceLetterHeader."VAT Country/Region Code";
            if PurchAdvanceLetterHeader."Order No." <> '' then
                "Prepayment Order No." := PurchAdvanceLetterHeader."Order No.";
            "Letter No." := PurchAdvanceLetterHeader."No.";
            "Vendor Invoice No." := PurchAdvanceLetterHeader."External Document No.";
            OnPostLetter_SetInvHeaderOnBeforeInsertPurchInvHeader(PurchAdvanceLetterHeader, PurchInvHeader);
            Insert;
        end;
    end;

    local procedure PostLetter_SetInvLine(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; LineAmount: Decimal)
    begin
        with PurchInvLine do begin
            Init;
            "Document No." := PurchInvHeader."No.";
            "Line No." := PrepaymentInvLineBuffer."Line No.";
            "Posting Date" := PurchInvHeader."Posting Date";
            "Buy-from Vendor No." := PurchInvHeader."Buy-from Vendor No.";
            "Pay-to Vendor No." := PurchInvHeader."Pay-to Vendor No.";
            Type := Type::"G/L Account";
            "No." := PrepaymentInvLineBuffer."G/L Account No.";
            "Shortcut Dimension 1 Code" := PrepaymentInvLineBuffer."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PrepaymentInvLineBuffer."Global Dimension 2 Code";
            "Dimension Set ID" := PrepaymentInvLineBuffer."Dimension Set ID";
            Description := PrepaymentInvLineBuffer.Description;
            Quantity := 1;
            "Direct Unit Cost" := LineAmount;
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
            if PrepaymentInvLineBuffer."VAT Calculation Type" =
               PrepaymentInvLineBuffer."VAT Calculation Type"::"Reverse Charge VAT"
            then begin
                "Line No." := "Line No." + 1;
                "Direct Unit Cost" := -"Direct Unit Cost";
                "Line Amount" := -"Line Amount";
                Amount := -Amount;
                "Amount Including VAT" := -"Amount Including VAT";
                "VAT Base Amount" := -"VAT Base Amount";
                "VAT Difference (LCY)" := -"VAT Difference (LCY)";
                "Prepayment Cancelled" := true;
                Insert;
            end;
        end;
    end;

    local procedure PostLetter_SetCrMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchInvHeader: Record "Purch. Inv. Header"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingDescription: Text[50])
    begin
        with PurchCrMemoHdr do begin
            Init;
            TransferFields(PurchInvHeader);
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
            "Prices Including VAT" := true;
            "Prepayment Credit Memo" := true;
            "Vendor Cr. Memo No." := PurchAdvanceLetterHeader."External Document No.";
            "Letter No." := PurchAdvanceLetterHeader."No.";
            "Posting Date" := PurchAdvanceLetterHeader."Posting Date";
            "Document Date" := "Posting Date";
            "VAT Date" := PurchAdvanceLetterHeader."VAT Date";
            IF "VAT Date" = 0D THEN
                "VAT Date" := "Posting Date";
            "Original Document VAT Date" := PurchAdvanceLetterHeader."Original Document VAT Date";
            OnPostLetter_SetCrMemoHeaderOnBeforeInsertPurchCrMemoHeader(PurchAdvanceLetterHeader, PurchCrMemoHdr);
            Insert;
        end;
    end;

    local procedure PostLetter_SetCrMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry"; PurchAdvanceLetterHeaderNo: Code[20]; PurchInvHeaderNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchAdvanceLetterEntry.Reset();
        PurchAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type", "Posting Date");
        PurchAdvanceLetterEntry.SetRange("Letter No.", PurchAdvanceLetterHeaderNo);
        PurchAdvanceLetterEntry.SetRange("Letter Line No.", PrepaymentInvLineBuffer."Line No.");
        PurchAdvanceLetterEntry.SetRange("Entry Type", PurchAdvanceLetterEntry."Entry Type"::VAT);
        PurchAdvanceLetterEntry.SetRange("Document Type", PurchAdvanceLetterEntry."Document Type"::Invoice);
        PurchAdvanceLetterEntry.SetRange("Document No.", PurchInvHeaderNo);
        PurchAdvanceLetterEntry.FindFirst;
        PurchInvLine.Get(PurchAdvanceLetterEntry."Document No.", PurchAdvanceLetterEntry."Purchase Line No.");
        PurchCrMemoLine.Init();
        PurchCrMemoLine.TransferFields(PurchInvLine);
        PurchCrMemoLine."Document No." := PurchCrMemoHdr."No.";
        PurchCrMemoLine.Insert();
    end;

    local procedure PostLetter_PostToGL(var GenJournalLine: Record "Gen. Journal Line"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocNo: Code[20]; GenJnlLineDocType: Integer; PostingDescription: Text[50]; SrcCode: Code[10]; PostingDate: Date; VATDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with GenJournalLine do begin
            Init;
            "Advance Letter No." := PurchAdvanceLetterHeader."No.";
            "Advance Letter Line No." := PrepaymentInvLineBuffer."Line No.";
            "Posting Date" := PostingDate;
            "VAT Date" := VATDate;
            "Original Document VAT Date" := PurchAdvanceLetterHeader."Original Document VAT Date";
            "Document Date" := "Posting Date";
            Description := PostingDescription;
            Prepayment := true;
            "Prepayment Type" := "Prepayment Type"::Advance;
            "VAT Calculation Type" := "VAT Calculation Type"::"Full VAT";
            "Document Type" := GenJnlLineDocType;
            "Document No." := GenJnlLineDocNo;
            "External Document No." := PurchAdvanceLetterHeader."External Document No.";
            "Account Type" := "Account Type"::"G/L Account";
            "Account No." := PrepaymentInvLineBuffer."G/L Account No.";
            "System-Created Entry" := true;
            Validate("Currency Code", PurchAdvanceLetterHeader."Currency Code");
            if DocumentType = DocumentType::Invoice then begin
                if ("Currency Factor" <> PurchAdvanceLetterHeader."VAT Currency Factor") and
                   (PurchAdvanceLetterHeader."VAT Currency Factor" <> 0)
                then
                    "Currency Factor" := PurchAdvanceLetterHeader."VAT Currency Factor"
                else
                    "Currency Factor" := PurchAdvanceLetterHeader."Currency Factor";
            end else
                "Currency Factor" := PurchInvHeaderBuf."Currency Factor";

            if DocumentType = DocumentType::Invoice then begin
                if ((PrepaymentInvLineBuffer."VAT Difference Inv. (LCY)" <> 0) or (PrepaymentInvLineBuffer."VAT Difference" <> 0)) and
                   ("Currency Code" <> '')
                then begin
                    Validate(Amount, -PrepaymentInvLineBuffer."VAT Amount");
                    "Amount (LCY)" := -PrepaymentInvLineBuffer."VAT Amount (LCY)";
                    "VAT Amount (LCY)" := -PrepaymentInvLineBuffer."VAT Amount (LCY)";
                    if "Currency Code" = '' then
                        "Advance VAT Base Amount" := -PrepaymentInvLineBuffer."VAT Base Amount"
                    else
                        "Advance VAT Base Amount" := -PrepaymentInvLineBuffer."VAT Base Amount (LCY)";
                    "VAT Difference" := PrepaymentInvLineBuffer."VAT Difference";
                    "VAT Difference (LCY)" := PrepaymentInvLineBuffer."VAT Difference Inv. (LCY)";
                end else begin
                    Validate(Amount, -PrepaymentInvLineBuffer."VAT Amount");
                    if "Currency Code" = '' then
                        "Advance VAT Base Amount" := -PrepaymentInvLineBuffer."VAT Base Amount"
                    else
                        "Advance VAT Base Amount" :=
                          -Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              "Posting Date", "Currency Code",
                              PrepaymentInvLineBuffer."VAT Base Amount", "Currency Factor"));
                end;
                "Source Currency Code" := "Currency Code";
                "Source Currency Amount" := -PrepaymentInvLineBuffer."VAT Amount (ACY)";
            end;
            if DocumentType = DocumentType::"Credit Memo" then begin
                Validate(Amount, -PurchAdvanceLetterEntry."VAT Amount");
                "Amount (LCY)" := -PurchAdvanceLetterEntry."VAT Amount (LCY)";
                "VAT Amount (LCY)" := -PurchAdvanceLetterEntry."VAT Amount (LCY)";
                "Advance VAT Base Amount" := -PurchAdvanceLetterEntry."VAT Base Amount (LCY)";
                "Source Currency Code" := PurchAdvanceLetterEntry."Currency Code";
                "Source Currency Amount" := -PurchAdvanceLetterEntry.Amount;
            end;
            if DocumentType = DocumentType::"Credit Memo" then
                Correction := GLSetup."Mark Cr. Memos as Corrections";
            "Gen. Posting Type" := "Gen. Posting Type"::Purchase;
            "Gen. Bus. Posting Group" := PrepaymentInvLineBuffer."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := PrepaymentInvLineBuffer."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := PrepaymentInvLineBuffer."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := PrepaymentInvLineBuffer."VAT Prod. Posting Group";
            if PrepaymentInvLineBuffer."VAT Calculation Type" <>
               PrepaymentInvLineBuffer."VAT Calculation Type"::"Reverse Charge VAT"
            then begin
                VATPostingSetup.Get(PrepaymentInvLineBuffer."VAT Bus. Posting Group", PrepaymentInvLineBuffer."VAT Prod. Posting Group");
                "Bal. Account Type" := "Bal. Account Type"::"G/L Account";
                "Bal. Account No." := VATPostingSetup."Purch. Advance Offset VAT Acc.";
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
            "Bill-to/Pay-to No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
            "Country/Region Code" := PurchAdvanceLetterHeader."VAT Country/Region Code";
            "VAT Registration No." := PurchAdvanceLetterHeader."VAT Registration No.";
            "Source Type" := "Source Type"::Vendor;
            "Source No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
            "Posting No. Series" := "Posting No. Series";
        end;
        OnAfterPostLetterPostToGL(PurchAdvanceLetterHeader, PrepaymentInvLineBuffer, PurchAdvanceLetterEntry, GenJournalLine);
    end;

    local procedure PostLetter_UpdtAdvLines(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocType: Integer; GenJnlLineDocNo: Code[20]; LineAmount: Decimal; PostingDate: Date)
    var
        AdvanceLink: Record "Advance Link";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);

        if DocumentType = DocumentType::Invoice then begin
            AdvanceLink.FindLast;
            PurchAdvanceLetterLine.TestField("Amount To Invoice", -AdvanceLink.Amount);
        end else begin
            AdvanceLink.SetRange("Invoice No.", CurrPurchInvHeader."No.");
            AdvanceLink.FindFirst;
        end;
        VendorLedgerEntry.Get(AdvanceLink."CV Ledger Entry No.");
        if DocumentType = DocumentType::Invoice then begin
            LineAmount := PurchAdvanceLetterLine."Amount To Invoice";
            PurchAdvanceLetterLine."Amount Invoiced" := PurchAdvanceLetterLine."Amount Invoiced" + LineAmount;
            PurchAdvanceLetterLine."Amount To Deduct" := PurchAdvanceLetterLine."Amount To Deduct" + LineAmount;
            PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" - LineAmount;
        end else begin
            LineAmount := GetInvoiceLineAmount(CurrPurchInvHeader."No.", PurchAdvanceLetterLine."Line No.");
            PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" + LineAmount;
            PurchAdvanceLetterLine."Amount To Deduct" := PurchAdvanceLetterLine."Amount To Deduct" - LineAmount;
            PurchAdvanceLetterLine."Amount Invoiced" := PurchAdvanceLetterLine."Amount Invoiced" - LineAmount;
        end;
        PurchAdvanceLetterLine."VAT Correction Inv." := false;
        PurchAdvanceLetterLine."VAT Difference Inv." := 0;
        PurchAdvanceLetterLine."VAT Amount Inv." := 0;
        PurchAdvanceLetterLine."VAT Difference Inv. (LCY)" := 0;
        PurchAdvanceLetterLine.SuspendStatusCheck(true);
        PurchAdvanceLetterLine.Modify(true);

        if DocumentType = DocumentType::"Credit Memo" then
            UpdateInvoicedLinks(PurchAdvanceLetterLine, GenJnlLineDocType, CurrPurchInvHeader."No.")
        else
            UpdateInvoicedLinks(PurchAdvanceLetterLine, GenJnlLineDocType, GenJnlLineDocNo);

        UpdInvAmountToLineRelations(PurchAdvanceLetterLine);

        PurchInvHeader.Init();
        PurchInvHeader."No." := GenJnlLineDocNo;
        PurchInvHeader."Posting Date" := PostingDate;
        PurchInvHeader."Currency Code" := VendorLedgerEntry."Currency Code";

        CreateAdvanceEntry(PurchAdvanceLetterHeader, PurchAdvanceLetterLine, PurchInvHeader, 0, VendorLedgerEntry, 0);
    end;

    [Scope('OnPrem')]
    procedure PostInvoiceCorrection(var PurchHeader2: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; var PurchLine: Record "Purchase Line"; var GenJnlPostLine2: Codeunit "Gen. Jnl.-Post Line"; var InvoicedAmount: Decimal)
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        TempPurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header" temporary;
        FullyDeducted: Boolean;
        DocNoForVATCorr: Code[20];
        IsHandled: Boolean;
    begin
        GenJnlPostLine := GenJnlPostLine2;
        PurchHeader := PurchHeader2;
        SetCurrencyPrecision(PurchHeader."Currency Code");
        GLSetup.Get();
        PurchSetup.Get();
        TempVendLedgEntry.DeleteAll();

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter("Qty. to Invoice", '<>0');
        IsHandled := false;
        OnBeforePostPaymentCorrection(PurchInvHeader, PurchHeader, PurchLine, TempVendLedgEntry, TempPurchAdvanceLetterHeader2, DocNoForVATCorr, InvoicedAmount, IsHandled);
        if not IsHandled then
            case PurchHeader."Document Type" of
                PurchHeader."Document Type"::Order:
                    begin
                        FullyDeducted := FullyDeductedVendPrepmt(PurchLine);
                        if FullyDeducted then
                            DeductRndLetterLines(PurchHeader."No.");
                        PurchLine.SetFilter("Prepmt Amt to Deduct", '<>0');
                        if PurchLine.FindSet(true) then
                            repeat
                                PostInvLineCorrection(
                                PurchLine, PurchInvHeader, TempVendLedgEntry, DocNoForVATCorr,
                                InvoicedAmount, TempPurchAdvanceLetterHeader2);

                            until PurchLine.Next() = 0;

                        with PurchHeader do begin
                            PurchLine.Reset();
                            PurchLine.SetRange("Document Type", "Document Type");
                            PurchLine.SetRange("Document No.", "No.");
                            PurchLine.SetFilter("Prepmt. Line Amount", '<>0');
                            if PurchLine.FindSet(true) then
                                repeat
                                    UpdateOrderLine(PurchLine, "Prices Including VAT", false);
                                    PurchLine.Modify();
                                until PurchLine.Next() = 0;
                        end;
                    end;
                PurchHeader."Document Type"::Invoice:
                    begin
                        PurchLine.SetFilter("Prepmt Amt to Deduct", '<>0');

                        if PurchLine.FindSet(true) then
                            repeat
                                PostInvLineCorrection(
                                    PurchLine, PurchInvHeader, TempVendLedgEntry, DocNoForVATCorr,
                                    InvoicedAmount, TempPurchAdvanceLetterHeader2);
                            until PurchLine.Next() = 0;
                    end;
            end;

        PostPaymentCorrection(PurchInvHeader, TempVendLedgEntry);

        SaveDeductionEntries;

        if TempPurchAdvanceLetterHeader2.FindSet then
            repeat
                PurchAdvanceLetterHeader.Get(TempPurchAdvanceLetterHeader2."No.");
                PurchAdvanceLetterHeader.UpdateClosing(true);
            until TempPurchAdvanceLetterHeader2.Next() = 0;

        PurchHeader2 := PurchHeader;
        GenJnlPostLine2 := GenJnlPostLine;
    end;

    procedure PostInvLineCorrection(PurchLine: Record "Purchase Line"; PurchInvHeader: Record "Purch. Inv. Header"; var VendLedgEntry: Record "Vendor Ledger Entry"; var DocNoForVATCorr: Code[20]; var InvoicedAmount: Decimal; var TempPurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header" temporary)
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        AdvanceLink: Record "Advance Link";
        AdvanceLink2: Record "Advance Link";
        ToDeductFact: Decimal;
        AmountToDeduct: Decimal;
        VATAmount: Decimal;
        LastLetterNo: Code[20];
        i: Integer;
        EntryCount: Integer;
        EntryPos: Integer;
    begin
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Document Type", PurchLine."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", PurchLine."Document No.");
        AdvanceLetterLineRelation.SetRange("Document Line No.", PurchLine."Line No.");
        AdvanceLetterLineRelation.SetFilter("Amount To Deduct", '<>0');
        OnPostInvLineCorrectionOnAfterAdvanceLetterLineRelationSetFilters(PurchHeader, PurchLine, AdvanceLetterLineRelation);
        if AdvanceLetterLineRelation.FindSet(true) then
            repeat
                AmountToDeduct := AdvanceLetterLineRelation."Amount To Deduct";
                PurchAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                if AmountToDeduct <> 0 then begin
                    InvoicedAmount := InvoicedAmount + AmountToDeduct;

                    PurchAdvanceLetterLine."Amount To Deduct" := PurchAdvanceLetterLine."Amount To Deduct" - AmountToDeduct;
                    PurchAdvanceLetterLine."Amount Deducted" := PurchAdvanceLetterLine."Amount Deducted" + AmountToDeduct;
                    PurchAdvanceLetterLine.SuspendStatusCheck(true);
                    PurchAdvanceLetterLine.Modify(true);
                    if not TempPurchAdvanceLetterHeader2.Get(PurchAdvanceLetterLine."Letter No.") then begin
                        PurchAdvanceLetterHeader.Get(PurchAdvanceLetterLine."Letter No.");
                        TempPurchAdvanceLetterHeader2 := PurchAdvanceLetterHeader;
                        TempPurchAdvanceLetterHeader2.Insert();
                    end;

                    TempPurchAdvanceLetterHeader2.TestField("VAT Country/Region Code", PurchInvHeader."VAT Country/Region Code");

                    UpdateAdvLetterLineRelationDeductedAmountAndModify(AdvanceLetterLineRelation, AmountToDeduct);

                    TempVendLedgEntryGre.Reset();
                    TempVendLedgEntryGre.DeleteAll();
                    Clear(TempVendLedgEntryGre);
                    CalcLinkedPmtAmountToApply(PurchAdvanceLetterLine, AmountToDeduct, VendLedgEntry, TempVendLedgEntryGre);

                    if TempVendLedgEntryGre.Find('-') then begin
                        repeat
                            CreateAdvanceEntry(TempPurchAdvanceLetterHeader2, PurchAdvanceLetterLine, PurchInvHeader, PurchLine."Line No.",
                              TempVendLedgEntryGre, TempVendLedgEntryGre."Amount to Apply");
                        until TempVendLedgEntryGre.Next() = 0;
                    end;

                    TotBaseToDeduct := 0;
                    TotVATAmtToDeduct := 0;
                    TotBaseToDeductLCY := 0;
                    TotVATAmtToDeductLCY := 0;
                    EntryPos := 0;

                    EntryCount := TempVendLedgEntryGre.Count();

                    for i := 1 to 2 do begin
                        if TempVendLedgEntryGre.FindSet then
                            repeat
                                AdvanceLink.Reset();
                                AdvanceLink.SetCurrentKey("CV Ledger Entry No.", "Entry Type", "Document No.", "Line No.");
                                AdvanceLink.SetRange("CV Ledger Entry No.", TempVendLedgEntryGre."Entry No.");
                                AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                                AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
                                AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
                                AdvanceLink.CalcSums(Amount, "Remaining Amount to Deduct");
                                if AdvanceLink."Remaining Amount to Deduct" <> 0 then
                                    ToDeductFact := TempVendLedgEntryGre."Amount to Apply" /
                                      (AdvanceLink."Remaining Amount to Deduct" + TempVendLedgEntryGre."Amount to Apply")
                                else
                                    ToDeductFact := 0;

                                if (AdvanceLink."Remaining Amount to Deduct" = 0) = (i = 1) then begin
                                    EntryPos := EntryPos + 1;
                                    VATAmount := 0;

                                    AdvanceLink2.Reset();
                                    AdvanceLink2.SetCurrentKey("CV Ledger Entry No.", "Entry Type", "Document No.", "Line No.");
                                    AdvanceLink2.SetRange("CV Ledger Entry No.", TempVendLedgEntryGre."Entry No.");
                                    AdvanceLink2.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                                    AdvanceLink2.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
                                    AdvanceLink2.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
                                    AdvanceLink2.FindLast;

                                    PostVATCorrection(
                                      PurchAdvanceLetterLine, PurchInvHeader, DocNoForVATCorr, VATAmount, AdvanceLetterLineRelation,
                                      TempVendLedgEntryGre."Entry No.", i = 1, EntryPos = EntryCount, ToDeductFact);

                                    AddPrepmtPurchInvLine(PurchAdvanceLetterLine, PurchInvHeader, -TempVendLedgEntryGre."Amount to Apply",
                                      VATAmount, LastLetterNo, AdvanceLink2."Invoice No.");
                                end;
                            until TempVendLedgEntryGre.Next() = 0;
                    end;
                end;
            until AdvanceLetterLineRelation.Next() = 0;
    end;

    local procedure UpdateAdvLetterLineRelationDeductedAmountAndModify(var AdvanceLetterLineRelation: Record "Advance Letter Line Relation"; AmountToDeduct: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAdvLetterLineRelationDeductedAmountAndModify(AdvanceLetterLineRelation, AmountToDeduct, IsHandled);
        if IsHandled then
            exit;

        AdvanceLetterLineRelation."Deducted Amount" += AmountToDeduct;
        AdvanceLetterLineRelation.Modify();
    end;

    local procedure DeductRndLetterLines(OrderNo: Code[20])
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        PurchAdvanceLetterHeader.SetRange("Order No.", OrderNo);
        if PurchAdvanceLetterHeader.FindSet then
            repeat
                PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
                if PurchAdvanceLetterLine.FindSet(true) then
                    repeat
                        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
                        AdvanceLetterLineRelation.SetRange("Letter No.", PurchAdvanceLetterLine."Letter No.");
                        AdvanceLetterLineRelation.SetRange("Letter Line No.", PurchAdvanceLetterLine."Line No.");
                        if AdvanceLetterLineRelation.IsEmpty() then begin
                            PurchAdvanceLetterLine."Amount Deducted" := PurchAdvanceLetterLine."Amount Deducted" +
                              PurchAdvanceLetterLine."Amount To Deduct";
                            PurchAdvanceLetterLine."Amount To Deduct" := 0;
                            PurchAdvanceLetterLine.SuspendStatusCheck(true);
                            PurchAdvanceLetterLine.Modify(true);
                        end;
                    until PurchAdvanceLetterLine.Next() = 0;
            until PurchAdvanceLetterHeader.Next() = 0;
    end;

    local procedure PostVATCorrection(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; PurchInvHeader: Record "Purch. Inv. Header"; var DocumentNo: Code[20]; var VATAmount: Decimal; var AdvanceLetterLineRelation: Record "Advance Letter Line Relation"; LinkedEntryNo: Integer; UseAllLinkedEntry: Boolean; LastLinkedEntry: Boolean; NewDeductFactor: Decimal)
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCYDif: Decimal;
        VATAmountLCYDif: Decimal;
    begin
        PurchAdvanceLetterHeader.Get(PurchAdvanceLetterLine."Letter No.");
        if DocumentNo = '' then
            if GLSetup."Use Adv. CM Nos for Adv. Corr." then begin
                PurchAdvanceLetterHeader.Get(PurchAdvanceLetterLine."Letter No.");
                DocumentNo := GetCrMemoDocNo(PurchAdvanceLetterHeader, PurchInvHeader."Posting Date");
            end else
                DocumentNo := PurchInvHeader."No.";

        // Calc VAT Amount to Deduct
        CalcVATToDeduct(PurchAdvanceLetterLine, BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY, LinkedEntryNo);
        SetCurrencyPrecision(PurchAdvanceLetterLine."Currency Code");

        if UseAllLinkedEntry then begin
            BaseToDeduct := -BaseToDeduct;
            VATAmtToDeduct := -VATAmtToDeduct;
            if PurchInvHeader."Currency Code" = '' then begin
                BaseToDeductLCY := BaseToDeduct;
                VATAmountLCY := VATAmtToDeduct;
            end else begin
                BaseToDeductLCY := -BaseToDeductLCY;
                VATAmountLCY := -VATAmountLCY;
                BaseToDeductLCYDif := BaseToDeductLCY;
                VATAmountLCYDif := VATAmountLCY;
                if (PurchInvHeader."Currency Factor" <> PurchInvHeader."VAT Currency Factor") and
                   (PurchInvHeader."VAT Currency Factor" <> 0)
                then begin
                    BaseToDeductLCY := Round(BaseToDeduct / PurchInvHeader."VAT Currency Factor");
                    VATAmountLCY := Round(VATAmtToDeduct / PurchInvHeader."VAT Currency Factor");
                    // correct amount
                    if (BaseToDeductLCY + VATAmountLCY) <> Round((BaseToDeduct + VATAmtToDeduct) / PurchInvHeader."VAT Currency Factor") then
                        VATAmountLCY := Round((BaseToDeduct + VATAmtToDeduct) / PurchInvHeader."VAT Currency Factor") - BaseToDeductLCY;
                end else begin
                    BaseToDeductLCY := Round(BaseToDeduct / PurchInvHeader."Currency Factor");
                    VATAmountLCY := Round(VATAmtToDeduct / PurchInvHeader."Currency Factor");
                    // correct amount
                    if (BaseToDeductLCY + VATAmountLCY) <> Round((BaseToDeduct + VATAmtToDeduct) / PurchInvHeader."Currency Factor") then
                        VATAmountLCY := Round((BaseToDeduct + VATAmtToDeduct) / PurchInvHeader."Currency Factor") - BaseToDeductLCY;
                end;
                // correct Reverse Charge
                if PurchAdvanceLetterLine."VAT Calculation Type" =
                   PurchAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT"
                then begin
                    VATPostingSetup.Get(PurchAdvanceLetterLine."VAT Bus. Posting Group", PurchAdvanceLetterLine."VAT Prod. Posting Group");
                    if PurchSetup."Allow VAT Difference" then
                        VATAmountLCY :=
                          VATAmountLine.RoundVAT(BaseToDeductLCY * VATPostingSetup."VAT %" / 100)
                    else
                        VATAmountLCY :=
                          Round(
                            BaseToDeductLCY * VATPostingSetup."VAT %" / 100);
                end;

                BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
            end;
        end else
            if LastLinkedEntry and
               ((AdvanceLetterLineRelation."VAT Doc. VAT Base" <> 0) or
                (AdvanceLetterLineRelation."VAT Doc. VAT Amount" <> 0))
            then begin
                BaseToDeduct := -(AdvanceLetterLineRelation."VAT Doc. VAT Base" + TotBaseToDeduct);
                VATAmtToDeduct := -(AdvanceLetterLineRelation."VAT Doc. VAT Amount" + TotVATAmtToDeduct);
                if PurchInvHeader."Currency Code" = '' then begin
                    BaseToDeductLCY := BaseToDeduct;
                    VATAmountLCY := VATAmtToDeduct;
                end else begin
                    BaseToDeductLCY := -(AdvanceLetterLineRelation."VAT Doc. VAT Base (LCY)" + TotBaseToDeductLCY);
                    VATAmountLCY := -(AdvanceLetterLineRelation."VAT Doc. VAT Amount (LCY)" + TotVATAmtToDeductLCY);
                    VendLedgEntry.Get(LinkedEntryNo);
                    BaseToDeductLCYDif := (BaseToDeduct / VendLedgEntry."Original Currency Factor") - BaseToDeductLCY;
                    VATAmountLCYDif := (VATAmtToDeduct / VendLedgEntry."Original Currency Factor") - VATAmountLCY;
                end;
            end else begin
                BaseToDeduct := -Round(BaseToDeduct * NewDeductFactor, Currency."Amount Rounding Precision");
                VATAmtToDeduct := -Round(VATAmtToDeduct * NewDeductFactor, Currency."Amount Rounding Precision");

                if BaseToDeduct <> 0 then
                    if PurchAdvanceLetterLine."VAT %" <> 0 then
                        BaseToDeduct := BaseToDeduct +
                          TempVendLedgEntryGre."Amount to Apply" - (BaseToDeduct + VATAmtToDeduct);

                if PurchInvHeader."Currency Code" = '' then begin
                    BaseToDeductLCY := BaseToDeduct;
                    VATAmountLCY := VATAmtToDeduct;
                end else begin
                    BaseToDeductLCY := -Round(BaseToDeductLCY * NewDeductFactor);
                    VATAmountLCY := -Round(VATAmountLCY * NewDeductFactor);
                    BaseToDeductLCYDif := BaseToDeductLCY;
                    VATAmountLCYDif := VATAmountLCY;
                    if (PurchInvHeader."Currency Factor" <> PurchInvHeader."VAT Currency Factor") and
                       (PurchInvHeader."VAT Currency Factor" <> 0)
                    then begin
                        BaseToDeductLCY := Round(BaseToDeduct / PurchInvHeader."VAT Currency Factor");
                        VATAmountLCY := Round(VATAmtToDeduct / PurchInvHeader."VAT Currency Factor");
                    end else begin
                        BaseToDeductLCY := Round(BaseToDeduct / PurchInvHeader."Currency Factor");
                        VATAmountLCY := Round(VATAmtToDeduct / PurchInvHeader."Currency Factor");
                    end;
                    BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                    VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
                end;
            end;

        TotBaseToDeduct += BaseToDeduct;
        TotVATAmtToDeduct += VATAmtToDeduct;
        TotBaseToDeductLCY += BaseToDeductLCY;
        TotVATAmtToDeductLCY += VATAmountLCY;

        if PurchAdvanceLetterLine."VAT Calculation Type" =
           PurchAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT"
        then
            VATAmount := 0
        else
            VATAmount := VATAmtToDeduct;

        PostVATCorrectionToGL(PurchAdvanceLetterLine, PurchInvHeader, DocumentNo, LinkedEntryNo, BaseToDeductLCY, VATAmountLCYDif,
          BaseToDeductLCYDif, VATAmountLCY, VATAmtToDeduct, BaseToDeduct);
    end;

    local procedure PostVATCorrectionToGL(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; PurchInvHeader: Record "Purch. Inv. Header"; DocumentNo: Code[20]; LinkedEntryNo: Integer; BaseToDeductLCY: Decimal; VATAmountLCYDif: Decimal; BaseToDeductLCYDif: Decimal; VATAmountLCY: Decimal; VATAmtToDeduct: Decimal; BaseToDeduct: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        TempPurchAdvanceLetterEntry."VAT Identifier" := PurchAdvanceLetterLine."VAT Identifier";
        TempPurchAdvanceLetterEntry."Vendor Entry No." := LinkedEntryNo;
        TempPurchAdvanceLetterEntry."Letter No." := PurchAdvanceLetterLine."Letter No.";
        TempPurchAdvanceLetterEntry."Letter Line No." := PurchAdvanceLetterLine."Line No.";

        // Post VAT Correction
        PrepareInvJnlLine(GenJournalLine, PurchAdvanceLetterLine, PurchInvHeader);
        SourceCodeSetup.Get();
        GenJournalLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
        GenJournalLine."Document No." := DocumentNo;
        SetPostingGroups(GenJournalLine, PurchAdvanceLetterLine, false);
        GenJournalLine."Account No." := PurchAdvanceLetterLine."No.";
        GenJournalLine."Advance VAT Base Amount" := BaseToDeductLCY;
        GenJournalLine."Advance Exch. Rate Difference" := VATAmountLCYDif;
        GenJournalLine.Validate(Amount, VATAmountLCY);
        GenJournalLine.Validate("Source Currency Amount", CalcAmtLCYToACY(GenJournalLine."Posting Date", GenJournalLine.Amount));
        GenJournalLine."Shortcut Dimension 1 Code" := PurchInvHeader."Shortcut Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := PurchInvHeader."Shortcut Dimension 2 Code";
        GenJournalLine."Dimension Set ID" := PurchInvHeader."Dimension Set ID";

        OnBeforePostVATCorrectionToGL(GenJournalLine, PurchAdvanceLetterLine);
        if BaseToDeductLCY <> 0 then
            GenJnlPostLine.RunWithCheck(GenJournalLine);

        if BaseToDeductLCY <> 0 then begin
            PurchAdvanceLetterEntryNo += 1;
            TempPurchAdvanceLetterEntry."Entry No." := PurchAdvanceLetterEntryNo;
            TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::"VAT Deduction";
            TempPurchAdvanceLetterEntry.Amount := 0;
            TempPurchAdvanceLetterEntry.Insert();
            FillVATFieldsOfDeductionEntry(PurchAdvanceLetterLine."VAT %");
            TempPurchAdvanceLetterEntry."VAT Identifier" := PurchAdvanceLetterLine."VAT Identifier";
            TempPurchAdvanceLetterEntry."VAT Base Amount" := BaseToDeduct;
            TempPurchAdvanceLetterEntry."VAT Amount" := VATAmtToDeduct;
            OnPostVATCorrectionToGLOnBeforeModifyTempPurchAdvanceLetterEntry(PurchAdvanceLetterLine, BaseToDeductLCY, TempPurchAdvanceLetterEntry);
            TempPurchAdvanceLetterEntry.Modify();
        end;

        // VAT Offset Account
        if PurchAdvanceLetterLine."VAT Calculation Type" <>
           PurchAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT"
        then begin
            GenJournalLine."Account No." := GetPurchAdvanceOffsetVATAccount(PurchAdvanceLetterLine."VAT Bus. Posting Group", PurchAdvanceLetterLine."VAT Prod. Posting Group");
            GenJournalLine."Advance VAT Base Amount" := 0;
            SetPostingGroups(GenJournalLine, PurchAdvanceLetterLine, true);
            GenJournalLine.Validate(Amount, -VATAmountLCY);
            GenJournalLine.Validate("Source Currency Amount", CalcAmtLCYToACY(GenJournalLine."Posting Date", GenJournalLine.Amount));
            GenJournalLine."Shortcut Dimension 1 Code" := PurchInvHeader."Shortcut Dimension 1 Code";
            GenJournalLine."Shortcut Dimension 2 Code" := PurchInvHeader."Shortcut Dimension 2 Code";
            GenJournalLine."Dimension Set ID" := PurchInvHeader."Dimension Set ID";
            if BaseToDeductLCY <> 0 then
                GenJnlPostLine.RunWithCheck(GenJournalLine);
        end;

        // Gain/Loss
        if GenJournalLine."Advance Exch. Rate Difference" <> 0 then begin
            if PurchAdvanceLetterLine."VAT Calculation Type" <>
               PurchAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT"
            then begin
                if GenJournalLine."Advance Exch. Rate Difference" > 0 then begin
                    Currency.TestField("Realized Losses Acc.");
                    GenJournalLine."Account No." := Currency."Realized Losses Acc."
                end else begin
                    Currency.TestField("Realized Gains Acc.");
                    GenJournalLine."Account No." := Currency."Realized Gains Acc.";
                end;
                GenJournalLine.Validate(Amount, GenJournalLine."Advance Exch. Rate Difference");
                GenJournalLine."Shortcut Dimension 1 Code" := PurchInvHeader."Shortcut Dimension 1 Code";
                GenJournalLine."Shortcut Dimension 2 Code" := PurchInvHeader."Shortcut Dimension 2 Code";
                GenJournalLine."Dimension Set ID" := PurchInvHeader."Dimension Set ID";
                GenJnlPostLine.RunWithCheck(GenJournalLine);

                GenJournalLine."Account No." := GetPurchAdvanceOffsetVATAccount(PurchAdvanceLetterLine."VAT Bus. Posting Group", PurchAdvanceLetterLine."VAT Prod. Posting Group");
                GenJournalLine.Validate(Amount, -GenJournalLine."Advance Exch. Rate Difference");
                GenJournalLine."Shortcut Dimension 1 Code" := PurchInvHeader."Shortcut Dimension 1 Code";
                GenJournalLine."Shortcut Dimension 2 Code" := PurchInvHeader."Shortcut Dimension 2 Code";
                GenJournalLine."Dimension Set ID" := PurchInvHeader."Dimension Set ID";
                GenJnlPostLine.RunWithCheck(GenJournalLine);
            end;

            PurchAdvanceLetterEntryNo += 1;
            TempPurchAdvanceLetterEntry."Entry No." := PurchAdvanceLetterEntryNo;
            TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::"VAT Rate";
            TempPurchAdvanceLetterEntry.Amount := 0;
            TempPurchAdvanceLetterEntry."VAT Base Amount" := 0;
            TempPurchAdvanceLetterEntry."VAT Amount" := 0;
            TempPurchAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCYDif;
            TempPurchAdvanceLetterEntry."VAT Amount (LCY)" := VATAmountLCYDif;
            TempPurchAdvanceLetterEntry.Insert();
        end;
        if (PurchAdvanceLetterLine."VAT Calculation Type" =
            PurchAdvanceLetterLine."VAT Calculation Type"::"Reverse Charge VAT") and
           (BaseToDeductLCYDif <> 0) and (GenJournalLine."Advance Exch. Rate Difference" = 0)
        then begin
            PurchAdvanceLetterEntryNo += 1;
            TempPurchAdvanceLetterEntry."Entry No." := PurchAdvanceLetterEntryNo;
            TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::"VAT Rate";
            TempPurchAdvanceLetterEntry.Amount := 0;
            TempPurchAdvanceLetterEntry."VAT Base Amount" := 0;
            TempPurchAdvanceLetterEntry."VAT Amount" := 0;
            TempPurchAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCYDif;
            TempPurchAdvanceLetterEntry."VAT Amount (LCY)" := 0;
            TempPurchAdvanceLetterEntry.Insert();
        end;
    end;

    local procedure GetPurchAdvanceOffsetVATAccount(VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchAdvanceOffsetVATAccount: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetPurchAdvanceOffsetVATAccount(VATBusPostingGroupCode, VATProdPostingGroupCode, PurchAdvanceOffsetVATAccount, IsHandled);
        if IsHandled then
            exit(PurchAdvanceOffsetVATAccount);

        VATPostingSetup.Get(VATBusPostingGroupCode, VATProdPostingGroupCode);
        VATPostingSetup.TestField("Purch. Advance Offset VAT Acc.");
        exit(VATPostingSetup."Purch. Advance Offset VAT Acc.");
    end;

    local procedure AddPrepmtPurchInvLine(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; PurchInvHeader: Record "Purch. Inv. Header"; AmountInclVAT: Decimal; VATAmount: Decimal; var LastLetterNo: Code[20]; VATDocLetterNo: Code[20]): Boolean
    var
        PurchInvLine: Record "Purch. Inv. Line";
        NextLineNo: Integer;
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if not PurchInvLine.FindLast then
            exit(false);

        NextLineNo := PurchInvLine."Line No.";
        if LastLetterNo <> PurchAdvanceLetterLine."Letter No." then begin
            AddAdvanceLetterInfo(PurchAdvanceLetterLine, PurchInvHeader."No.", NextLineNo);
            LastLetterNo := PurchAdvanceLetterLine."Letter No.";
        end;

        NextLineNo := NextLineNo + 10000;
        PurchInvLine.Init();
        PurchInvLine."Line No." := NextLineNo;
        PurchInvLine."Prepayment Line" := true;
        PurchInvLine."Buy-from Vendor No." := PurchInvHeader."Buy-from Vendor No.";
        PurchInvLine."Pay-to Vendor No." := PurchInvHeader."Pay-to Vendor No.";
        PurchInvLine.Type := PurchInvLine.Type::"G/L Account";
        PurchInvLine."No." := PurchAdvanceLetterLine."Advance G/L Account No.";
        PurchInvLine.Description := PurchAdvanceLetterLine.Description;
        PurchInvLine."VAT %" := PurchAdvanceLetterLine."VAT %";
        PurchInvLine."VAT Calculation Type" := PurchAdvanceLetterLine."VAT Calculation Type"::"Full VAT";
        PurchInvLine."VAT Bus. Posting Group" := PurchAdvanceLetterLine."VAT Bus. Posting Group";
        PurchInvLine."VAT Prod. Posting Group" := PurchAdvanceLetterLine."VAT Prod. Posting Group";
        PurchInvLine."VAT Identifier" := PurchAdvanceLetterLine."VAT Identifier";
        PurchInvLine.Quantity := -1;
        PurchInvLine."VAT Base Amount" := -VATAmount - AmountInclVAT;
        PurchInvLine.Amount := PurchInvLine."VAT Base Amount";
        if PurchInvHeader."Prices Including VAT" then begin
            PurchInvLine."Direct Unit Cost" := AmountInclVAT;
            PurchInvLine."Line Amount" := -AmountInclVAT;
        end else begin
            PurchInvLine."Direct Unit Cost" := -PurchInvLine."VAT Base Amount";
            PurchInvLine."Line Amount" := PurchInvLine."VAT Base Amount";
        end;
        PurchInvLine."Amount Including VAT" := -AmountInclVAT;

        PurchInvLine."Letter No." := PurchAdvanceLetterLine."Letter No.";
        PurchInvLine."VAT Doc. Letter No." := VATDocLetterNo;

        PurchInvLine.Insert();

        FillDeductionLineNo(PurchInvLine."Line No.");
    end;

    local procedure AddAdvanceLetterInfo(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; DocumentNo: Code[20]; var NextLineNo: Integer)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        NextLineNo := NextLineNo + 10000;
        PurchInvLine.Init();
        PurchInvLine."Document No." := DocumentNo;
        PurchInvLine."Line No." := NextLineNo;
        PurchInvLine."Prepayment Line" := true;
        PurchInvLine.Description := StrSubstNo(Text009Txt, PurchAdvanceLetterLine."Letter No.");
        PurchInvLine.Insert();

        PurchInvHeader.SetRange("Letter No.", PurchAdvanceLetterLine."Letter No.");
        PurchInvHeader.SetRange("Reversed By Cr. Memo No.", '');
        PurchInvHeader.SetRange("Prepayment Invoice", true);
        if PurchInvHeader.FindSet then
            repeat
                NextLineNo := NextLineNo + 10000;

                PurchInvLine.Init();
                PurchInvLine."Line No." := NextLineNo;
                PurchInvLine."Prepayment Line" := true;
                PurchInvLine.Description :=
                  CopyStr(StrSubstNo(Text010Txt, PurchInvHeader."No."), 1, MaxStrLen(PurchInvLine.Description));
                PurchInvLine.Insert();
            until PurchInvHeader.Next() = 0;
    end;

    local procedure PreparePmtJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := PurchInvHeader."Pay-to Vendor No.";
        PrepareGenJnlLine(GenJnlLine, PurchInvHeader);
    end;

    local procedure PrepareInvJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        GenJnlLine.Init();
        GenJnlLine."Advance Letter No." := PurchAdvanceLetterLine."Letter No.";
        GenJnlLine."Advance Letter Line No." := PurchAdvanceLetterLine."Line No.";
        GenJnlLine.Prepayment := true;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine.Correction := GLSetup."Correction As Storno";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        PrepareGenJnlLine(GenJnlLine, PurchInvHeader);
    end;

    local procedure PrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        GenJnlLine."Posting Date" := PurchInvHeader."Posting Date";
        GenJnlLine."VAT Date" := PurchInvHeader."VAT Date";
        GenJnlLine."Original Document VAT Date" := PurchInvHeader."Original Document VAT Date";
        if PurchInvHeader."Original Document VAT Date" = 0D then
            GenJnlLine."Original Document VAT Date" := GenJnlLine."VAT Date";
        GenJnlLine."Document Date" := PurchInvHeader."Document Date";
        GenJnlLine."Prepayment Type" := GenJnlLine."Prepayment Type"::Advance;
        GenJnlLine."Reason Code" := PurchInvHeader."Reason Code";
        GenJnlLine."Document No." := PurchInvHeader."No.";
        GenJnlLine."External Document No." := PurchInvHeader."Vendor Invoice No.";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Source Currency Code" := PurchInvHeader."Currency Code";
        GenJnlLine."Source Code" := PurchInvHeader."Source Code";
        GenJnlLine."EU 3-Party Trade" := PurchInvHeader."EU 3-Party Trade";
        GenJnlLine."Bill-to/Pay-to No." := PurchInvHeader."Pay-to Vendor No.";
        GenJnlLine."Country/Region Code" := PurchInvHeader."VAT Country/Region Code";
        GenJnlLine."VAT Registration No." := PurchInvHeader."VAT Registration No.";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        GenJnlLine."Source No." := PurchInvHeader."Pay-to Vendor No.";
        GenJnlLine."Posting No. Series" := PurchHeader."Posting No. Series";
        GenJnlLine.Description := PurchInvHeader."Posting Description";
        OnAfterPrepareGenJnlLine(PurchInvHeader, GenJnlLine);
    end;

    local procedure SetPostingGroups(var GenJnlLine: Record "Gen. Journal Line"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; Cleanup: Boolean)
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
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
            GenJnlLine."Gen. Bus. Posting Group" := PurchAdvanceLetterLine."Gen. Bus. Posting Group";
            GenJnlLine."Gen. Prod. Posting Group" := PurchAdvanceLetterLine."Gen. Prod. Posting Group";
            GenJnlLine."VAT Bus. Posting Group" := PurchAdvanceLetterLine."VAT Bus. Posting Group";
            GenJnlLine."VAT Prod. Posting Group" := PurchAdvanceLetterLine."VAT Prod. Posting Group";
        end;
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Automatic VAT Entry";
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.SetPostFromPurchAdvLetter(true);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure PostPaymentCorrection(PurchInvHeader: Record "Purch. Inv. Header"; var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        VendLedgEntry3: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        PrepaidAmount: Decimal;
        PrepaidAmountLCY: Decimal;
        InvoiceAmount: Decimal;
    begin
        if VendLedgEntry.IsEmpty() then
            exit;

        VendLedgEntry3.SetRange("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        VendLedgEntry3.SetRange("Document No.", PurchInvHeader."No.");
        VendLedgEntry3.FindFirst;
        VendLedgEntry3.CalcFields("Remaining Amount");
        InvoiceAmount := VendLedgEntry3."Remaining Amount";

        // Post Advance Refund
        GenJnlLine.Init();
        GenJnlLine.Prepayment := true;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
        PreparePmtJnlLine(GenJnlLine, PurchInvHeader);
        SourceCodeSetup.Get();
        GenJnlLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
        if VendLedgEntry.FindSet then
            repeat
                if VendLedgEntry."Posting Date" > PurchInvHeader."Posting Date" then
                    Error(Text4005240Err);
                if InvoiceAmount > VendLedgEntry."Amount to Apply" then
                    VendLedgEntry."Amount to Apply" := InvoiceAmount;
                InvoiceAmount := InvoiceAmount - VendLedgEntry."Amount to Apply";
                VendLedgEntry2.Get(VendLedgEntry."Entry No.");
                VendLedgEntry2."Amount to Apply" := -VendLedgEntry."Amount to Apply";

                VendLedgEntry2.CalcFields("Remaining Amount");
                if Abs(VendLedgEntry2."Amount to Apply") > Abs(VendLedgEntry2."Remaining Amount") then
                    VendLedgEntry2.FieldError("Amount to Apply",
                      StrSubstNo(Text036Err, VendLedgEntry2.FieldCaption("Remaining Amount")));

                VendLedgEntry2.Modify();
                GenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
                if VendLedgEntry."Currency Code" <> '' then begin
                    VendLedgEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    if VendLedgEntry2."Remaining Amt. (LCY)" <> 0 then
                        GenJnlLine.Validate("Currency Factor", VendLedgEntry2."Remaining Amount" / VendLedgEntry2."Remaining Amt. (LCY)")
                    else
                        GenJnlLine.Validate("Currency Factor", VendLedgEntry2."Adjusted Currency Factor");
                end;
                GenJnlLine.Validate(Amount, VendLedgEntry."Amount to Apply");
                PrepaidAmount := PrepaidAmount + GenJnlLine.Amount;
                PrepaidAmountLCY := PrepaidAmountLCY + GenJnlLine."Amount (LCY)";
                GenJnlLine."Applies-to ID" := VendLedgEntry."Applies-to ID";
                GenJnlLine."Posting Group" := VendLedgEntry."Vendor Posting Group";
                GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry2."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry2."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := VendLedgEntry2."Dimension Set ID";
                OnPostPaymentCorrectionOnBeforePostAdvanceRefundRunWithCheck(VendLedgEntry2, GenJnlLine);
                GenJnlPostLine.RunWithCheck(GenJnlLine);
            until (VendLedgEntry.Next() = 0) or (InvoiceAmount = 0);

        // Post Payment
        GenJnlLine.Init();
        GenJnlLine.Prepayment := false;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        PreparePmtJnlLine(GenJnlLine, PurchInvHeader);
        if GenJnlLine."Posting Group" <> PurchInvHeader."Vendor Posting Group" then
            GenJnlLine.Validate("Posting Group", PurchInvHeader."Vendor Posting Group");
        GenJnlLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
        GenJnlLine.Validate("Currency Code", PurchInvHeader."Currency Code");
        GenJnlLine.Validate(Amount, -PrepaidAmount);
        if -PrepaidAmountLCY <> 0 then
            GenJnlLine.Validate("Amount (LCY)", -PrepaidAmountLCY);
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
        GenJnlLine."Applies-to Doc. No." := PurchInvHeader."No.";
        GenJnlLine."Shortcut Dimension 1 Code" := PurchInvHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PurchInvHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PurchInvHeader."Dimension Set ID";
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CalcLinkedAmount(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
        AdvanceLink: Record "Advance Link";
    begin
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);

        if AdvanceLink.FindSet then
            repeat
                if VendLedgEntry2.Get(AdvanceLink."CV Ledger Entry No.") then
                    if VendLedgEntry.Get(VendLedgEntry2."Entry No.") then begin
                        VendLedgEntry."Amount to Apply" := VendLedgEntry."Amount to Apply" + AdvanceLink.Amount;
                        VendLedgEntry."Currency Code" := AdvanceLink."Currency Code";
                        VendLedgEntry.Modify();
                    end else begin
                        VendLedgEntry := VendLedgEntry2;
                        VendLedgEntry."Amount to Apply" := AdvanceLink.Amount;
                        VendLedgEntry."Currency Code" := AdvanceLink."Currency Code";
                        VendLedgEntry.Insert();
                    end;
            until AdvanceLink.Next() = 0;
    end;

    local procedure CalcLinkedPmtAmountToApply(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; TotalAmountToApply: Decimal; var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry3: Record "Vendor Ledger Entry")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
        AdvanceLink: Record "Advance Link";
        AmountToApply: Decimal;
    begin
        if TotalAmountToApply = 0 then
            exit;

        SumAmountToApply := SumAmountToApply + TotalAmountToApply;

        SetCurrencyPrecision(PurchAdvanceLetterLine."Currency Code");
        AdvanceLink.SetCurrentKey("Entry Type", "Document No.", "Line No.", "Posting Date");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);

        if AdvanceLink.FindSet then
            repeat
                if VendLedgEntry2.Get(AdvanceLink."CV Ledger Entry No.") then begin
                    case true of
                        TotalAmountToApply < -AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TotalAmountToApply;
                        TotalAmountToApply = -AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TotalAmountToApply;
                        TotalAmountToApply > -AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := -AdvanceLink."Remaining Amount to Deduct";
                    end;
                    TotalAmountToApply := TotalAmountToApply - AmountToApply;
                    AdvanceLink."Remaining Amount to Deduct" := AdvanceLink."Remaining Amount to Deduct" + AmountToApply;
                    AdvanceLink.Modify();

                    if AmountToApply <> 0 then begin
                        if VendLedgEntry.Get(VendLedgEntry2."Entry No.") then begin
                            VendLedgEntry."Amount to Apply" := VendLedgEntry."Amount to Apply" - AmountToApply;
                            VendLedgEntry.Modify();
                        end else begin
                            VendLedgEntry2."Applies-to ID" := AppPrefTxt + Format(VendLedgEntry2."Entry No.");
                            VendLedgEntry2.Modify();
                            VendLedgEntry := VendLedgEntry2;
                            VendLedgEntry."Amount to Apply" := -AmountToApply;
                            VendLedgEntry."Currency Code" := AdvanceLink."Currency Code";
                            VendLedgEntry.Insert();
                        end;
                        if VendLedgEntry3.Get(VendLedgEntry2."Entry No.") then begin
                            VendLedgEntry3."Amount to Apply" := VendLedgEntry3."Amount to Apply" - AmountToApply;
                            VendLedgEntry3.Modify();
                        end else begin
                            VendLedgEntry3 := VendLedgEntry2;
                            VendLedgEntry3."Amount to Apply" := -AmountToApply;
                            VendLedgEntry3."Currency Code" := AdvanceLink."Currency Code";
                            VendLedgEntry3.Insert();
                        end;
                    end;
                end;
            until (AdvanceLink.Next() = 0) or (TotalAmountToApply = 0);
    end;

    local procedure CalcPostingDate(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PostingDate: Date)
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        AdvanceLink: Record "Advance Link";
    begin
        PostingDate := 0D;
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        PurchAdvanceLetterLine.SetFilter("Amount To Invoice", '<>0');
        if PurchAdvanceLetterLine.FindSet then
            repeat
                AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
                AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
                AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
                AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);
                AdvanceLink.SetFilter("Invoice No.", '=%1', '');
                if AdvanceLink.FindSet then
                    repeat
                        if PostingDate < AdvanceLink."Posting Date" then
                            PostingDate := AdvanceLink."Posting Date";
                    until AdvanceLink.Next() = 0;
            until PurchAdvanceLetterLine.Next() = 0;
    end;

    local procedure UpdateInvoicedLinks(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; InvoiceNo: Code[20])
    var
        AdvanceLink: Record "Advance Link";
    begin
        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);

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

    local procedure CalcVATToDeduct(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var TotalBase: Decimal; var TotalAmount: Decimal; var TotalBaseLCY: Decimal; var TotalAmountLCY: Decimal; VendEntryNo: Integer)
    var
        PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry";
    begin
        FilterPurchAdvanceLetterEntryForCalcVATToDeduct(PurchAdvanceLetterEntry, PurchAdvanceLetterLine, VendEntryNo);
        PurchAdvanceLetterEntry.CalcSums("VAT Base Amount (LCY)", "VAT Amount (LCY)", "VAT Base Amount", "VAT Amount");
        TotalAmount := PurchAdvanceLetterEntry."VAT Amount";
        TotalBase := PurchAdvanceLetterEntry."VAT Base Amount";
        TotalAmountLCY := PurchAdvanceLetterEntry."VAT Amount (LCY)";
        TotalBaseLCY := PurchAdvanceLetterEntry."VAT Base Amount (LCY)";

        FilterPurchAdvanceLetterEntryForCalcVATToDeduct(TempPurchAdvanceLetterEntry, PurchAdvanceLetterLine, VendEntryNo);
        TempPurchAdvanceLetterEntry.CalcSums("VAT Base Amount (LCY)", "VAT Amount (LCY)", "VAT Base Amount", "VAT Amount");
        TotalAmount := TotalAmount + TempPurchAdvanceLetterEntry."VAT Amount";
        TotalBase := TotalBase + TempPurchAdvanceLetterEntry."VAT Base Amount";
        TotalAmountLCY := TotalAmountLCY + TempPurchAdvanceLetterEntry."VAT Amount (LCY)";
        TotalBaseLCY := TotalBaseLCY + TempPurchAdvanceLetterEntry."VAT Base Amount (LCY)";
        TempPurchAdvanceLetterEntry.Reset();
    end;

    local procedure FilterPurchAdvanceLetterEntryForCalcVATToDeduct(var PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; VendEntryNo: Integer)
    begin
        PurchAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type", "Posting Date");
        PurchAdvanceLetterEntry.SetRange("Letter No.", PurchAdvanceLetterLine."Letter No.");
        PurchAdvanceLetterEntry.SetRange("Letter Line No.", PurchAdvanceLetterLine."Line No.");
        PurchAdvanceLetterEntry.SetFilter("Entry Type", '%1|%2|%3', PurchAdvanceLetterEntry."Entry Type"::VAT,
          PurchAdvanceLetterEntry."Entry Type"::"VAT Deduction", PurchAdvanceLetterEntry."Entry Type"::"VAT Rate");
        if VendEntryNo <> 0 then
            PurchAdvanceLetterEntry.SetRange("Vendor Entry No.", VendEntryNo);

        OnAfterFilterPurchAdvanceLetterEntryForCalcVATToDeduct(PurchAdvanceLetterEntry, PurchAdvanceLetterLine);
    end;

    [Scope('OnPrem')]
    procedure CalcNoOfDocs(VendNo: Code[20]; var QtyOfDocs: array[5] of Integer)
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        Status: Integer;
    begin
        Clear(QtyOfDocs);
        VendNoGco := VendNo;
        PurchAdvanceLetterLine.SetCurrentKey("Pay-to Vendor No.", Status);
        PurchAdvanceLetterLine.SetRange("Pay-to Vendor No.", VendNoGco);
        for Status := 0 to 4 do begin
            PurchAdvanceLetterLine.SetRange(Status, Status);
            QtyOfDocs[Status + 1] := PurchAdvanceLetterLine.Count();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPrepmtAmounts(PurchHeader: Record "Purchase Header"; var PrepmtAmtRequested: Decimal; var PrepmtAmtReceived: Decimal)
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        if not (PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice]) then
            PurchHeader.FieldError("Document Type");

        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Document Type", PurchHeader."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", PurchHeader."No.");
        if AdvanceLetterLineRelation.FindSet then begin
            repeat
                if not TempPurchAdvanceLetterLine.Get(
                     AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.")
                then begin
                    PurchAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                    TempPurchAdvanceLetterLine.Init();
                    TempPurchAdvanceLetterLine := PurchAdvanceLetterLine;
                    TempPurchAdvanceLetterLine.Insert();
                end;
            until AdvanceLetterLineRelation.Next() = 0;

            TempPurchAdvanceLetterLine.CalcSums("Amount Including VAT", "Amount Linked");
            PrepmtAmtRequested += TempPurchAdvanceLetterLine."Amount Including VAT";
            PrepmtAmtReceived += TempPurchAdvanceLetterLine."Amount Linked";
        end else begin
            PurchAdvanceLetterHeader.SetRange("Order No.", PurchHeader."No.");
            if PurchAdvanceLetterHeader.FindSet then
                repeat
                    PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
                    PurchAdvanceLetterLine.CalcSums("Amount Including VAT", "Amount Linked");
                    PrepmtAmtRequested += PurchAdvanceLetterLine."Amount Including VAT";
                    PrepmtAmtReceived += PurchAdvanceLetterLine."Amount Linked";
                until PurchAdvanceLetterHeader.Next() = 0;
        end;
    end;

    local procedure InsertInDimBuf(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"): Integer
    begin
        exit(PurchAdvanceLetterLine."Dimension Set ID");
    end;

    local procedure GetInvoiceLineAmount(DocNo: Code[20]; LineNo: Integer): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        if PurchInvLine.Get(DocNo, LineNo) then begin
            if PurchInvLine."VAT Calculation Type" = PurchInvLine."VAT Calculation Type"::"Reverse Charge VAT" then
                exit(PurchInvLine."VAT Base Amount");
            exit(PurchInvLine."Amount Including VAT" + PurchInvLine."VAT Base Amount");
        end;
        exit(0);
    end;

    local procedure InsertLineRelations(BufEntryNo: Integer; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var AdvanceLetterLineRelation2: Record "Advance Letter Line Relation")
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
                AdvanceLetterLineRelation."Letter No." := PurchAdvanceLetterLine."Letter No.";
                AdvanceLetterLineRelation."Letter Line No." := PurchAdvanceLetterLine."Line No.";
                AdvanceLetterLineRelation.Insert();
            until AdvanceLetterLineRelation2.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateOrderLine(var PurchLine: Record "Purchase Line"; PricesInclVAT: Boolean; RecalcAmtToDeduct: Boolean)
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        AdvanceLetterLineRelation.SetCurrentKey(Type, "Document Type", "Document No.", "Document Line No.", "Letter No.", "Letter Line No.");
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Document Type", PurchLine."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", PurchLine."Document No.");
        AdvanceLetterLineRelation.SetRange("Document Line No.", PurchLine."Line No.");
        AdvanceLetterLineRelation.CalcSums("Invoiced Amount", "Deducted Amount");
        AdvanceLetterLineRelation.CalcSums("VAT Doc. VAT Base", "VAT Doc. VAT Amount");

        PurchLine."Prepmt. Amount Inv. Incl. VAT" := AdvanceLetterLineRelation."Invoiced Amount";
        if PricesInclVAT then
            PurchLine."Prepmt. Amt. Inv." := AdvanceLetterLineRelation."Invoiced Amount"
        else
            PurchLine."Prepmt. Amt. Inv." :=
              Round(AdvanceLetterLineRelation."Invoiced Amount" / (1 + PurchLine."VAT %" / 100),
                Currency."Amount Rounding Precision");
        if RecalcAmtToDeduct then
            PurchLine.CalcPrepaymentToDeduct;
    end;

    [Scope('OnPrem')]
    procedure UpdInvAmountToLineRelations(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        TempPurchLine: Record "Purchase Line" temporary;
        AmtDif: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeUpdInvAmountToLineRelations(PurchAdvanceLetterLine, AmtDif, AdvanceLetterLineRelation, TempPurchLine, IsHandled);
        if IsHandled then
            exit;
        PurchAdvanceLetterLine.CalcFields("Document Linked Inv. Amount");
        AmtDif := PurchAdvanceLetterLine."Amount Invoiced" - PurchAdvanceLetterLine."Document Linked Inv. Amount";
        if AmtDif > 0 then begin
            AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
            AdvanceLetterLineRelation.SetRange("Letter No.", PurchAdvanceLetterLine."Letter No.");
            AdvanceLetterLineRelation.SetRange("Letter Line No.", PurchAdvanceLetterLine."Line No.");
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
                        if not TempPurchLine.Get(AdvanceLetterLineRelation."Document Type",
                            AdvanceLetterLineRelation."Document No.",
                            AdvanceLetterLineRelation."Document Line No.")
                        then begin
                            TempPurchLine."Document Type" := AdvanceLetterLineRelation."Document Type";
                            TempPurchLine."Document No." := AdvanceLetterLineRelation."Document No.";
                            TempPurchLine."Line No." := AdvanceLetterLineRelation."Document Line No.";
                            TempPurchLine.Insert();
                        end;
                    end;
                until (AdvanceLetterLineRelation.Next() = 0) or (AmtDif = 0);
        end else
            if AmtDif < 0 then begin
                AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
                AdvanceLetterLineRelation.SetRange("Letter No.", PurchAdvanceLetterLine."Letter No.");
                AdvanceLetterLineRelation.SetRange("Letter Line No.", PurchAdvanceLetterLine."Line No.");
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
                            if not TempPurchLine.Get(AdvanceLetterLineRelation."Document Type",
                                AdvanceLetterLineRelation."Document No.",
                                AdvanceLetterLineRelation."Document Line No.")
                            then begin
                                TempPurchLine."Document Type" := AdvanceLetterLineRelation."Document Type";
                                TempPurchLine."Document No." := AdvanceLetterLineRelation."Document No.";
                                TempPurchLine."Line No." := AdvanceLetterLineRelation."Document Line No.";
                                TempPurchLine.Insert();
                            end;
                        end;
                    until (AdvanceLetterLineRelation.Next(-1) = 0) or (AmtDif = 0);
                if AmtDif < 0 then begin
                    PurchAdvanceLetterLine.CalcFields("Document Linked Inv. Amount");
                    Error(Text4005247Err, PurchAdvanceLetterLine."Document Linked Inv. Amount",
                    PurchAdvanceLetterLine."Letter No.", PurchAdvanceLetterLine."Line No.");
                end;
            end;
        if TempPurchLine.FindSet then
            repeat
                UpdateOrderLineAmounts(TempPurchLine);
            until TempPurchLine.Next() = 0;
    end;

    local procedure UpdateOrderLineAmounts(TempPurchLine: Record "Purchase Line" temporary)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        OnBeforeUpdateOrderLineAmounts(TempPurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchHeader.Get(TempPurchLine."Document Type", TempPurchLine."Document No.");
        PurchLine.Get(TempPurchLine."Document Type", TempPurchLine."Document No.", TempPurchLine."Line No.");
        UpdateOrderLine(PurchLine, PurchHeader."Prices Including VAT", true);
        PurchLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure ClearLineRelAmountToDeduct(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20])
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
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

    local procedure FullyDeductedVendPrepmt(var PurchLine: Record "Purchase Line"): Boolean
    begin
        if PurchLine.FindSet then
            repeat
                if PurchLine."Prepmt Amt to Deduct" + PurchLine."Prepmt Amt Deducted" <> PurchLine."Prepmt. Amt. Inv." then
                    exit(false);
            until PurchLine.Next() = 0;
        exit(true);
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
                Type := Type::Purchase;
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
    procedure UpdateLines(LetterNo: Code[20])
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        TempPurchLineBuff: Record "Purchase Line" temporary;
    begin
        AdvanceLetterLineRelation.SetCurrentKey(Type, "Document Type", "Document No.", "Document Line No.", "Letter No.", "Letter Line No.");
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Letter No.", LetterNo);
        if AdvanceLetterLineRelation.FindSet(false, false) then begin
            repeat
                TempPurchLineBuff."Document Type" := AdvanceLetterLineRelation."Document Type";
                TempPurchLineBuff."Document No." := AdvanceLetterLineRelation."Document No.";
                TempPurchLineBuff."Line No." := AdvanceLetterLineRelation."Document Line No.";
                if TempPurchLineBuff.Insert() then;
            until AdvanceLetterLineRelation.Next() = 0;
        end;
        if TempPurchLineBuff.Find('-') then begin
            repeat
                PurchLine := TempPurchLineBuff;
                if PurchLine.Find then
                    if PurchLine."Prepmt. Line Amount" <> 0 then begin
                        if (PurchHeader."Document Type" <> PurchLine."Document Type") or
                           (PurchHeader."No." <> PurchLine."Document No.")
                        then
                            PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
                        UpdateOrderLine(PurchLine, PurchHeader."Prices Including VAT", true);
                        PurchLine.Modify();
                    end;
            until TempPurchLineBuff.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLetterHeader(var TempPurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header" temporary)
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
    begin
        TempPurchAdvanceLetterHeader.Reset();
        if TempPurchAdvanceLetterHeader.Find('-') then begin
            repeat
                TempPurchAdvanceLetterHeader2 := TempPurchAdvanceLetterHeader;
                PurchAdvanceLetterHeader.Get(TempPurchAdvanceLetterHeader2."No.");
                TempPurchAdvanceLetterHeader2."Template Code" := PurchAdvanceLetterHeader."Template Code";
                TempPurchAdvanceLetterHeader2."Post Advance VAT Option" := PurchAdvanceLetterHeader."Post Advance VAT Option";
                if TempPurchAdvanceLetterHeader2.Insert() then;
            until TempPurchAdvanceLetterHeader.Next() = 0;
        end;
    end;

    procedure SetLetterHeader(var TempPurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header" temporary)
    begin
        TempPurchAdvanceLetterHeader.Reset();
        TempPurchAdvanceLetterHeader.DeleteAll();
        if TempPurchAdvanceLetterHeader2.Find('-') then begin
            repeat
                TempPurchAdvanceLetterHeader := TempPurchAdvanceLetterHeader2;
                TempPurchAdvanceLetterHeader.Insert();
            until TempPurchAdvanceLetterHeader2.Next() = 0;
        end;
    end;

    procedure SetGenJnlPostLine(var GenJnlPostLineNew: Codeunit "Gen. Jnl.-Post Line")
    begin
        GenJnlPostLine := GenJnlPostLineNew;
        DisablePostingCuClear := true;
    end;

    [Scope('OnPrem')]
    procedure GetGenJnlPostLine(var GenJnlPostLineNew: Codeunit "Gen. Jnl.-Post Line")
    begin
        GenJnlPostLineNew := GenJnlPostLine;
    end;

    [Scope('OnPrem')]
    procedure GetPurchAdvanceTempl(PurchAPTemplateCode: Code[10])
    begin
        if PurchAPTemplateCode <> PurchAdvPmtTemplate.Code then
            if PurchAPTemplateCode = '' then
                Clear(PurchAdvPmtTemplate)
            else
                PurchAdvPmtTemplate.Get(PurchAPTemplateCode);
    end;

    [Scope('OnPrem')]
    procedure CheckVATCredtMemoIsNeed(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"): Boolean
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        if PurchAdvanceLetterLine.FindSet(false, false) then
            repeat
                CalcVATToDeduct(PurchAdvanceLetterLine, BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY, 0);
                if (BaseToDeduct <> 0) or (VATAmtToDeduct <> 0) or (BaseToDeductLCY <> 0) or (VATAmountLCY <> 0) then
                    exit(true);
            until PurchAdvanceLetterLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure PostVATCreditMemo(DocumentNo: Code[20]; var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date; VATDate: Date)
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        GenJnlLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
        ToDeductFactor: Decimal;
        BaseToDeductLCYDif: Decimal;
        VATAmountLCYDif: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Use VAT Date" then begin
            if VATDate = 0D then
                Error(Text037Err);
            PurchAdvanceLetterHeader.TestField("Original Document VAT Date");
        end;
        if PostingDate = 0D then
            Error(Text038Err);

        SetCurrencyPrecision(PurchAdvanceLetterHeader."Currency Code");

        PurchAdvanceLetterHeader.CalcFields(Status);
        if PurchAdvanceLetterHeader.Status > PurchAdvanceLetterHeader.Status::"Pending Final Invoice" then
            PurchAdvanceLetterHeader.TestField(Status, PurchAdvanceLetterHeader.Status::"Pending Final Invoice");

        PostVATCrMemoHeader(PurchCrMemoHdr, PurchAdvanceLetterHeader, DocumentNo, PostingDate, VATDate);

        // Create Lines
        TempPrepmtInvLineBuf.DeleteAll();
        BuildCreditMemoLineBuf(PurchAdvanceLetterHeader, TempPrepmtInvLineBuf);
        if TempPrepmtInvLineBuf.FindSet then begin
            repeat
                PostVATCrMemoLine(PurchCrMemoLine, TempPrepmtInvLineBuf, PurchCrMemoHdr);

                // Posting to G/L
                PostVATCrMemoPrepareGL(GenJnlLine, PurchAdvanceLetterHeader, TempPrepmtInvLineBuf, PurchCrMemoHdr, PostingDate, VATDate);

                PurchAdvanceLetterLine.Get(PurchAdvanceLetterHeader."No.", TempPrepmtInvLineBuf."Line No.");
                CalcVATToDeduct(PurchAdvanceLetterLine, BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY, 0);
                if VATAmtToDeduct = 0 then
                    ToDeductFactor := 0
                else
                    ToDeductFactor := -PurchAdvanceLetterLine."VAT Amount To Refund" / VATAmtToDeduct;

                if (ToDeductFactor = 0) and (BaseToDeduct <> 0) then
                    ToDeductFactor := -PurchAdvanceLetterLine."VAT Base To Refund" / BaseToDeduct;

                if (Abs(ToDeductFactor) = 1) or (ToDeductFactor = 0) then begin
                    BaseToDeduct := Round(BaseToDeduct * ToDeductFactor, Currency."Amount Rounding Precision");
                    VATAmtToDeduct := Round(VATAmtToDeduct * ToDeductFactor, Currency."Amount Rounding Precision");
                    if ((PurchAdvanceLetterLine."VAT Base To Refund" <> 0) and
                        (BaseToDeduct <> -PurchAdvanceLetterLine."VAT Base To Refund")) or
                       ((PurchAdvanceLetterLine."VAT Amount To Refund" <> 0) and
                        (VATAmtToDeduct <> -PurchAdvanceLetterLine."VAT Amount To Refund"))
                    then
                        Error(Text4005242Err);

                    PostVatCrMemo_CalcAmt(
                      BaseToDeduct, VATAmtToDeduct,
                      BaseToDeductLCY, VATAmountLCY,
                      BaseToDeductLCYDif, VATAmountLCYDif,
                      ToDeductFactor, PurchAdvanceLetterHeader."Currency Code", GenJnlLine."Currency Factor");
                end else begin
                    BaseToDeduct := -PurchAdvanceLetterLine."VAT Base To Refund";
                    VATAmtToDeduct := -PurchAdvanceLetterLine."VAT Amount To Refund";
                    PostVatCrMemo_CalcAmt(
                      BaseToDeduct, VATAmtToDeduct,
                      BaseToDeductLCY, VATAmountLCY,
                      BaseToDeductLCYDif, VATAmountLCYDif,
                      ToDeductFactor, PurchAdvanceLetterHeader."Currency Code", GenJnlLine."Currency Factor");
                end;
                GenJnlLine."Advance Exch. Rate Difference" := VATAmountLCYDif;

                RunGenJnlPostLine(GenJnlLine);

                PurchAdvanceLetterLine.Get(PurchAdvanceLetterHeader."No.", TempPrepmtInvLineBuf."Line No.");
                PostVATCrMemo_UpdtLine(PurchAdvanceLetterLine);

                UpdInvAmountToLineRelations(PurchAdvanceLetterLine);

                PurchInvHeader.TransferFields(PurchCrMemoHdr);
                VendLedgEntry.Init();
                VendLedgEntry."Vendor No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
                CreateAdvanceEntry(PurchAdvanceLetterHeader, PurchAdvanceLetterLine, PurchInvHeader, 0, VendLedgEntry, 0);
                FillVATFieldsOfDeductionEntry(TempPrepmtInvLineBuf."VAT %");
                TempPurchAdvanceLetterEntry."VAT Identifier" := TempPrepmtInvLineBuf."VAT Identifier";
                TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::VAT;
                TempPurchAdvanceLetterEntry."Purchase Line No." := TempPrepmtInvLineBuf."Line No.";
                TempPurchAdvanceLetterEntry."Document Type" := GenJnlLine."Document Type";
                TempPurchAdvanceLetterEntry."VAT Base Amount" := -TempPrepmtInvLineBuf."VAT Base Amount";
                TempPurchAdvanceLetterEntry."VAT Amount" := -TempPrepmtInvLineBuf."VAT Amount";
                TempPurchAdvanceLetterEntry.Modify();

                // Gain/Loss
                if VATAmountLCYDif <> 0 then begin
                    SetPostingGroups(GenJnlLine, PurchAdvanceLetterLine, true);
                    GenJnlLine.Validate("Currency Code", '');
                    GenJnlLine."Bal. Account No." := '';
                    if TempPrepmtInvLineBuf."VAT Calculation Type" = TempPrepmtInvLineBuf."VAT Calculation Type"::"Reverse Charge VAT" then
                        GenJnlLine."Account No." := TempPrepmtInvLineBuf."G/L Account No."
                    else
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
                    if TempPrepmtInvLineBuf."VAT Calculation Type" =
                       TempPrepmtInvLineBuf."VAT Calculation Type"::"Reverse Charge VAT"
                    then begin
                        VATPostingSetup.TestField("Reverse Chrg. VAT Acc.");
                        GenJnlLine."Account No." := VATPostingSetup."Reverse Chrg. VAT Acc.";
                    end else begin
                        VATPostingSetup.TestField("Purch. Advance Offset VAT Acc.");
                        GenJnlLine."Account No." := VATPostingSetup."Purch. Advance Offset VAT Acc.";
                    end;
                    GenJnlLine.Validate(Amount, -VATAmountLCYDif);
                    RunGenJnlPostLine(GenJnlLine);

                    PurchAdvanceLetterEntryNo += 1;
                    TempPurchAdvanceLetterEntry."Entry No." := PurchAdvanceLetterEntryNo;
                    TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::"VAT Rate";
                    TempPurchAdvanceLetterEntry.Amount := 0;
                    TempPurchAdvanceLetterEntry."Purchase Line No." := TempPrepmtInvLineBuf."Line No.";
                    TempPurchAdvanceLetterEntry."Document Type" := GenJnlLine."Document Type";
                    TempPurchAdvanceLetterEntry."VAT Base Amount" := 0;
                    TempPurchAdvanceLetterEntry."VAT Amount" := 0;
                    TempPurchAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCYDif;
                    TempPurchAdvanceLetterEntry."VAT Amount (LCY)" := VATAmountLCYDif;
                    TempPurchAdvanceLetterEntry.Insert();
                end;
            until TempPrepmtInvLineBuf.Next() = 0;
            SaveDeductionEntries;
            UpdateLines(PurchAdvanceLetterHeader."No.");
        end;
        Clear(GenJnlPostLine);
    end;

    local procedure PostVATCrMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; DocumentNo: Code[20]; PostingDate: Date; VATDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        SourceCodeSetup: Record "Source Code Setup";
        SrcCode: Code[10];
    begin
        PurchaseHeader.Init();
        PurchaseHeader.TransferFields(PurchAdvanceLetterHeader);
        CopyPayToSellFromAdvLetter(PurchaseHeader, PurchAdvanceLetterHeader);

        PurchaseHeader."VAT Date" := VATDate;

        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Purchases;

        // Create posted header
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr.TransferFields(PurchaseHeader);
        PurchCrMemoHdr."Posting Date" := PostingDate;
        PurchCrMemoHdr."VAT Date" := VATDate;
        PurchCrMemoHdr."Document Date" := PostingDate;
        PurchCrMemoHdr."Currency Factor" :=
          CurrExchRate.ExchangeRate(PostingDate, PurchaseHeader."Currency Code");
        PurchCrMemoHdr."Due Date" := PurchAdvanceLetterHeader."Advance Due Date";
        PurchCrMemoHdr.Correction := GLSetup."Mark Cr. Memos as Corrections";
        PurchCrMemoHdr."No." := DocumentNo;
        PurchCrMemoHdr."Pre-Assigned No. Series" := '';
        PurchCrMemoHdr."Source Code" := SrcCode;
        PurchCrMemoHdr."User ID" := UserId;
        PurchCrMemoHdr."No. Printed" := 0;
        PurchCrMemoHdr."Prices Including VAT" := true;
        PurchCrMemoHdr."Prepayment Credit Memo" := true;
        PurchCrMemoHdr."Vendor Cr. Memo No." := PurchAdvanceLetterHeader."External Document No.";
        PurchCrMemoHdr."Letter No." := PurchAdvanceLetterHeader."No.";
        OnPostVATCrMemoHeaderOnBeforeInsertPostVATPurchCrMemoHdr(PurchAdvanceLetterHeader, PurchCrMemoHdr);
        PurchCrMemoHdr.Insert();
    end;

    local procedure PostVATCrMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        with PurchCrMemoLine do begin
            Init;
            "Document No." := PurchCrMemoHdr."No.";
            "Line No." := PrepaymentInvLineBuffer."Line No.";
            "Posting Date" := PurchCrMemoHdr."Posting Date";
            "Buy-from Vendor No." := PurchCrMemoHdr."Buy-from Vendor No.";
            "Pay-to Vendor No." := PurchCrMemoHdr."Pay-to Vendor No.";
            Type := Type::"G/L Account";
            "No." := PrepaymentInvLineBuffer."G/L Account No.";
            "Shortcut Dimension 1 Code" := PrepaymentInvLineBuffer."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PrepaymentInvLineBuffer."Global Dimension 2 Code";
            "Dimension Set ID" := PrepaymentInvLineBuffer."Dimension Set ID";
            Description := PrepaymentInvLineBuffer.Description;
            Quantity := 1;
            "Direct Unit Cost" := PrepaymentInvLineBuffer."VAT Amount";
            "Line Amount" := PrepaymentInvLineBuffer."VAT Amount";
            Amount := PrepaymentInvLineBuffer."VAT Amount";
            "Amount Including VAT" := PrepaymentInvLineBuffer."VAT Amount";
            "VAT Base Amount" := PrepaymentInvLineBuffer."VAT Base Amount";
            "Gen. Bus. Posting Group" := PrepaymentInvLineBuffer."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := PrepaymentInvLineBuffer."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := PrepaymentInvLineBuffer."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := PrepaymentInvLineBuffer."VAT Prod. Posting Group";
            "VAT %" := PrepaymentInvLineBuffer."VAT %";
            "VAT Calculation Type" := PrepaymentInvLineBuffer."VAT Calculation Type";
            "VAT Identifier" := PrepaymentInvLineBuffer."VAT Identifier";
            Insert;
            if PrepaymentInvLineBuffer."VAT Calculation Type" =
               PrepaymentInvLineBuffer."VAT Calculation Type"::"Reverse Charge VAT"
            then begin
                "Line No." := "Line No." + 1;
                "Direct Unit Cost" := -"Direct Unit Cost";
                "Line Amount" := -"Line Amount";
                Amount := -Amount;
                "Amount Including VAT" := -"Amount Including VAT";
                "VAT Base Amount" := -"VAT Base Amount";
                "VAT Difference (LCY)" := -"VAT Difference (LCY)";
                Insert;
            end;
        end;
    end;

    local procedure PostVATCrMemoPrepareGL(var GenJnlLine: Record "Gen. Journal Line"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PostingDate: Date; VATDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with GenJnlLine do begin
            Init;
            "Advance Letter No." := PurchAdvanceLetterHeader."No.";
            "Advance Letter Line No." := PrepaymentInvLineBuffer."Line No.";
            "Posting Date" := PostingDate;
            "VAT Date" := VATDate;
            "Original Document VAT Date" := PurchAdvanceLetterHeader."Original Document VAT Date";
            "Document Date" := PostingDate;
            Description := PrepaymentInvLineBuffer.Description;
            Prepayment := true;
            "Prepayment Type" := "Prepayment Type"::Advance;
            "VAT Calculation Type" := "VAT Calculation Type"::"Full VAT";
            "Document Type" := "Document Type"::"Credit Memo";
            "Document No." := PurchCrMemoHdr."No.";
            "External Document No." := PurchAdvanceLetterHeader."External Document No.";
            "Account Type" := "Account Type"::"G/L Account";
            "Account No." := PrepaymentInvLineBuffer."G/L Account No.";
            "System-Created Entry" := true;
            Validate("Currency Code", PurchAdvanceLetterHeader."Currency Code");
            Validate(Amount, -PrepaymentInvLineBuffer."VAT Amount");
            if "Currency Code" = '' then
                "Advance VAT Base Amount" := -PrepaymentInvLineBuffer."VAT Base Amount"
            else
                "Advance VAT Base Amount" :=
                  -Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      "Posting Date", "Currency Code",
                      PrepaymentInvLineBuffer."VAT Base Amount", "Currency Factor"));
            "Source Currency Code" := PurchCrMemoHdr."Currency Code";
            "Source Currency Amount" := PrepaymentInvLineBuffer."Amount (ACY)";
            Correction := PurchCrMemoHdr.Correction;
            "Gen. Posting Type" := "Gen. Posting Type"::Purchase;
            "Gen. Bus. Posting Group" := PrepaymentInvLineBuffer."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := PrepaymentInvLineBuffer."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := PrepaymentInvLineBuffer."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := PrepaymentInvLineBuffer."VAT Prod. Posting Group";
            if PrepaymentInvLineBuffer."VAT Calculation Type" <>
               PrepaymentInvLineBuffer."VAT Calculation Type"::"Reverse Charge VAT"
            then begin
                VATPostingSetup.Get(PrepaymentInvLineBuffer."VAT Bus. Posting Group", PrepaymentInvLineBuffer."VAT Prod. Posting Group");
                "Bal. Account Type" := "Bal. Account Type"::"G/L Account";
                "Bal. Account No." := VATPostingSetup."Purch. Advance Offset VAT Acc.";
            end;
            "Tax Area Code" := PrepaymentInvLineBuffer."Tax Area Code";
            "Tax Liable" := PrepaymentInvLineBuffer."Tax Liable";
            "Tax Group Code" := PrepaymentInvLineBuffer."Tax Group Code";
            "Source Curr. VAT Amount" := -PrepaymentInvLineBuffer."VAT Amount (ACY)";
            "VAT Difference" := PrepaymentInvLineBuffer."VAT Difference";
            "VAT Posting" := "VAT Posting"::"Automatic VAT Entry";
            "Shortcut Dimension 1 Code" := PrepaymentInvLineBuffer."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PrepaymentInvLineBuffer."Global Dimension 2 Code";
            "Dimension Set ID" := PrepaymentInvLineBuffer."Dimension Set ID";
            "Job No." := PrepaymentInvLineBuffer."Job No.";
            "EU 3-Party Trade" := PurchCrMemoHdr."EU 3-Party Trade";
            "Bill-to/Pay-to No." := PurchCrMemoHdr."Pay-to Vendor No.";
            "Country/Region Code" := PurchCrMemoHdr."VAT Country/Region Code";
            "VAT Registration No." := PurchCrMemoHdr."VAT Registration No.";
            "Source Type" := "Source Type"::Vendor;
            "Source No." := PurchCrMemoHdr."Pay-to Vendor No.";
            "Source Code" := PurchCrMemoHdr."Source Code";
            "Posting No. Series" := PurchCrMemoHdr."No. Series";
            OnAfterPostVATCrMemoPrepareGL(GenJnlLine, PurchAdvanceLetterHeader, PrepaymentInvLineBuffer, PurchCrMemoHdr);
        end;
    end;

    local procedure PostVATCrMemo_UpdtLine(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
        with PurchAdvanceLetterLine do begin
            if "VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT" then begin
                "Amount To Invoice" += TempPrepmtInvLineBuf."Amount Incl. VAT";
                "Amount To Deduct" -= TempPrepmtInvLineBuf."Amount Incl. VAT";
                "Amount Invoiced" -= TempPrepmtInvLineBuf."Amount Incl. VAT";
            end;
            SuspendStatusCheck(true);
            Modify(true);
        end;
    end;

    local procedure PostVatCrMemo_CalcAmt(BaseToDeduct: Decimal; VATAmtToDeduct: Decimal; var BaseToDeductLCY: Decimal; var VATAmountLCY: Decimal; var BaseToDeductLCYDif: Decimal; var VATAmountLCYDif: Decimal; ToDeductFactor: Decimal; CurrencyCode: Code[10]; CurrencyFactor: Decimal)
    begin
        if CurrencyCode = '' then begin
            BaseToDeductLCY := BaseToDeduct;
            VATAmountLCY := VATAmtToDeduct;
        end else begin
            BaseToDeductLCY := Round(BaseToDeductLCY * ToDeductFactor);
            VATAmountLCY := Round(VATAmountLCY * ToDeductFactor);
            BaseToDeductLCYDif := BaseToDeductLCY;
            VATAmountLCYDif := VATAmountLCY;
            BaseToDeductLCY := Round(BaseToDeduct / CurrencyFactor);
            VATAmountLCY := Round(VATAmtToDeduct / CurrencyFactor);
            BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
            VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
        end;
    end;

    [Scope('OnPrem')]
    procedure BuildCreditMemoLineBuf(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer";
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        if PurchAdvanceLetterLine.FindSet then
            repeat
                FillCreditMemoLineBuf(PurchAdvanceLetterLine, PrepmtInvLineBuf2);
                if (PrepmtInvLineBuf2.Amount <> 0) or (PrepmtInvLineBuf2."VAT Amount" <> 0) then
                    xInsertInvLineBuf(PrepmtInvLineBuf, PrepmtInvLineBuf2)
            until PurchAdvanceLetterLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure FillCreditMemoLineBuf(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    var
        PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry";
    begin
        with PrepmtInvLineBuf do begin
            Clear(PrepmtInvLineBuf);

            "G/L Account No." := PurchAdvanceLetterLine."No.";
            "Dimension Set ID" := InsertInDimBuf(PurchAdvanceLetterLine);
            "Gen. Bus. Posting Group" := PurchAdvanceLetterLine."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := PurchAdvanceLetterLine."VAT Bus. Posting Group";
            "Gen. Prod. Posting Group" := PurchAdvanceLetterLine."Gen. Prod. Posting Group";
            "VAT Prod. Posting Group" := PurchAdvanceLetterLine."VAT Prod. Posting Group";
            "VAT Calculation Type" := PurchAdvanceLetterLine."VAT Calculation Type";
            "Global Dimension 1 Code" := PurchAdvanceLetterLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := PurchAdvanceLetterLine."Shortcut Dimension 2 Code";
            "Job No." := PurchAdvanceLetterLine."Job No.";

            if CloseAll then begin
                PurchAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type");
                PurchAdvanceLetterEntry.SetRange("Letter No.", PurchAdvanceLetterLine."Letter No.");
                PurchAdvanceLetterEntry.SetRange("Letter Line No.", PurchAdvanceLetterLine."Line No.");
                PurchAdvanceLetterEntry.SetRange("Entry Type",
                  PurchAdvanceLetterEntry."Entry Type"::VAT,
                  PurchAdvanceLetterEntry."Entry Type"::"VAT Deduction");
                PurchAdvanceLetterEntry.CalcSums("VAT Base Amount", "VAT Amount");
                "VAT Base Amount" := PurchAdvanceLetterEntry."VAT Base Amount";
                "VAT Amount" := PurchAdvanceLetterEntry."VAT Amount";
                "Amount Incl. VAT" := "VAT Base Amount" + "VAT Amount";
                Amount := "VAT Base Amount";
            end else begin
                if (PurchAdvanceLetterLine."VAT Base To Refund" <> 0) or (PurchAdvanceLetterLine."VAT Amount To Refund" <> 0) then begin
                    "Amount Incl. VAT" := PurchAdvanceLetterLine."VAT Base To Refund" + PurchAdvanceLetterLine."VAT Amount To Refund";
                    Amount := PurchAdvanceLetterLine."VAT Base To Refund";
                end else begin
                    "Amount Incl. VAT" := GetCreditMemoLineAmount(PurchAdvanceLetterLine);
                    Amount := Round("Amount Incl. VAT" * PurchAdvanceLetterLine.Amount / PurchAdvanceLetterLine."Amount Including VAT");
                end;

                "VAT Base Amount" := Amount;
                "VAT Amount" := "Amount Incl. VAT" - Amount;
            end;
            "Amount (ACY)" := Amount;
            "VAT Base Amount (ACY)" := Amount;
            "VAT Amount (ACY)" := "VAT Amount";
            "VAT %" := PurchAdvanceLetterLine."VAT %";
            "VAT Identifier" := PurchAdvanceLetterLine."VAT Identifier";
            "Tax Area Code" := PurchAdvanceLetterLine."Tax Area Code";
            "Tax Liable" := PurchAdvanceLetterLine."Tax Liable";
            "Tax Group Code" := PurchAdvanceLetterLine."Tax Group Code";
            "Line No." := PurchAdvanceLetterLine."Line No.";
            Description := PurchAdvanceLetterLine.Description;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCreditMemoLineAmount(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"): Decimal
    begin
        if PurchAdvanceLetterLine."Amount To Invoice" + PurchAdvanceLetterLine."Amount To Deduct" <
           PurchAdvanceLetterLine."Amount To Refund"
        then
            Error(Text039Err, PurchAdvanceLetterLine."Letter No.", PurchAdvanceLetterLine."Line No.");
        if PurchAdvanceLetterLine."Amount To Refund" > PurchAdvanceLetterLine."Amount To Invoice" then
            exit(PurchAdvanceLetterLine."Amount To Refund" - PurchAdvanceLetterLine."Amount To Invoice");

        exit(0);
    end;

    [Scope('OnPrem')]
    procedure PostRefundCorrection(DocumentNo: Code[20]; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date; VATDate: Date)
    var
        TempVendLedgEntry2: Record "Vendor Ledger Entry" temporary;
        AdvanceLink: Record "Advance Link";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        TotAmt: Decimal;
        TotAmtRnded: Decimal;
        AmtToApply: Decimal;
        TotalAmountToRefund: Decimal;
        AmtToRefund: Decimal;
    begin
        VendLedgEntry.LockTable();
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        PurchAdvanceLetterLine.SetFilter("Amount To Refund", '>0');
        OnPostRefundCorrectionOnAfterPurchAdvanceLetterLineSetFilter(PurchAdvanceLetterLine);
        if PurchAdvanceLetterLine.FindSet then begin
            repeat
                TotAmt := 0;
                TotAmtRnded := 0;
                AmtToApply := 0;
                AmtToRefund := PurchAdvanceLetterLine."Amount To Refund";
                AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
                AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
                AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);

                if AdvanceLink.FindSet then
                    repeat
                        if VendLedgEntry.Get(AdvanceLink."CV Ledger Entry No.") then begin
                            VendLedgEntry.CalcFields("Remaining Amount");
                            if VendLedgEntry."Remaining Amount" <> 0 then begin
                                if AmtToRefund > -AdvanceLink."Remaining Amount to Deduct" then
                                    TotAmt := TotAmt - AdvanceLink."Remaining Amount to Deduct"
                                else
                                    TotAmt := TotAmt + AmtToRefund;
                                AmtToApply := Round(TotAmt) - TotAmtRnded;
                                TotAmtRnded := TotAmtRnded + AmtToApply;
                                TotalAmountToRefund := TotalAmountToRefund + AmtToApply;
                                AmtToRefund := AmtToRefund - AmtToApply;
                                if TempVendLedgEntry2.Get(VendLedgEntry."Entry No.") then begin
                                    TempVendLedgEntry2."Amount to Apply" := TempVendLedgEntry2."Amount to Apply" - AmtToApply;
                                    TempVendLedgEntry2.Modify();
                                end else begin
                                    VendLedgEntry."Applies-to ID" := AppPrefTxt + Format(VendLedgEntry."Entry No.");
                                    VendLedgEntry.Modify();
                                    TempVendLedgEntry2 := VendLedgEntry;
                                    TempVendLedgEntry2."Amount to Apply" := -AmtToApply;
                                    TempVendLedgEntry2."Currency Code" := PurchAdvanceLetterHeader."Currency Code";
                                    TempVendLedgEntry2.Insert();
                                end;
                            end;
                            AdvanceLink."Remaining Amount to Deduct" := 0;
                            AdvanceLink.Modify();
                        end;
                    until AdvanceLink.Next() = 0;

                PurchAdvanceLetterLine."Amount To Link" := PurchAdvanceLetterLine."Amount To Link" + TotAmtRnded;
                PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" - TotAmtRnded;
                PurchAdvanceLetterLine."Amount Linked" := PurchAdvanceLetterLine."Amount Linked" - TotAmtRnded;
                PurchAdvanceLetterLine.SuspendStatusCheck(true);
                PurchAdvanceLetterLine.Modify(true);

            until PurchAdvanceLetterLine.Next() = 0;
        end;

        if TempVendLedgEntry2.IsEmpty() then
            exit;

        PostRefundCorrToGL(TempVendLedgEntry2, PurchAdvanceLetterHeader, DocumentNo, PostingDate, VATDate);

        UpdateLines(PurchAdvanceLetterHeader."No.");
    end;

    local procedure PostRefundCorrToGL(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; DocumentNo: Code[20]; PostingDate: Date; VATDate: Date)
    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SrcCode: Code[10];
        PrepaidAmount: Decimal;
        PrepaidAmountLCY: Decimal;
    begin
        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Purchases;

        // Post Advance Refund
        GenJnlLine.Init();
        GenJnlLine.Prepayment := true;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."VAT Date" := VATDate;
        GenJnlLine."Original Document VAT Date" := PurchAdvanceLetterHeader."Original Document VAT Date";
        GenJnlLine."Document Date" := PostingDate;
        GenJnlLine."Prepayment Type" := GenJnlLine."Prepayment Type"::Advance;
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Source Currency Code" := PurchAdvanceLetterHeader."Currency Code";
        GenJnlLine."Source Code" := SrcCode;
        GenJnlLine."Bill-to/Pay-to No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
        GenJnlLine."Country/Region Code" := PurchAdvanceLetterHeader."Pay-to Country/Region Code";
        GenJnlLine."VAT Registration No." := PurchAdvanceLetterHeader."VAT Registration No.";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        GenJnlLine."Source No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
        OnPostRefundCorrToGLOnFillAdvanceRefundGenJnlLine(PurchAdvanceLetterHeader, GenJnlLine);

        if TempVendorLedgerEntry.FindSet then
            repeat
                TempVendorLedgerEntry.TestField("Currency Code", PurchAdvanceLetterHeader."Currency Code");
                VendorLedgerEntry.Get(TempVendorLedgerEntry."Entry No.");
                VendorLedgerEntry."Amount to Apply" := -TempVendorLedgerEntry."Amount to Apply";
                VendorLedgerEntry.Modify();
                GenJnlLine.Validate("Currency Code", TempVendorLedgerEntry."Currency Code");
                if TempVendorLedgerEntry."Currency Code" <> '' then begin
                    VendorLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    if VendorLedgerEntry."Remaining Amt. (LCY)" <> 0 then
                        GenJnlLine.Validate("Currency Factor", VendorLedgerEntry."Remaining Amount" / VendorLedgerEntry."Remaining Amt. (LCY)")
                    else
                        GenJnlLine.Validate("Currency Factor", VendorLedgerEntry."Adjusted Currency Factor");
                end;
                GenJnlLine.Validate(Correction, true);
                GenJnlLine.Validate(Amount, TempVendorLedgerEntry."Amount to Apply");
                PrepaidAmount := PrepaidAmount + GenJnlLine.Amount;
                PrepaidAmountLCY := PrepaidAmountLCY + GenJnlLine."Amount (LCY)";
                GenJnlLine."Applies-to ID" := TempVendorLedgerEntry."Applies-to ID";
                GenJnlLine."Posting Group" := TempVendorLedgerEntry."Vendor Posting Group";
                GenJnlLine."Document No." := DocumentNo;
                GenJnlLine.Description := TempVendorLedgerEntry.Description;
                GenJnlLine."Shortcut Dimension 1 Code" := VendorLedgerEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := VendorLedgerEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := VendorLedgerEntry."Dimension Set ID";
                OnPostRefundCorrToGLOnBeforePostAdvanceRefundGenJnlLine(PurchAdvanceLetterHeader, GenJnlLine);

                if GenJnlLine.Amount <> 0 then
                    GenJnlPostLine.RunWithCheck(GenJnlLine);

            until TempVendorLedgerEntry.Next() = 0;

        GenJnlLine.Init();
        GenJnlLine.Prepayment := false;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."VAT Date" := VATDate;
        GenJnlLine."Original Document VAT Date" := PurchAdvanceLetterHeader."Original Document VAT Date";
        GenJnlLine."Document Date" := PostingDate;
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine.Validate("Account No.", PurchAdvanceLetterHeader."Pay-to Vendor No.");
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Source Currency Code" := PurchAdvanceLetterHeader."Currency Code";
        GenJnlLine."Source Code" := SrcCode;
        GenJnlLine."Bill-to/Pay-to No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
        GenJnlLine."Country/Region Code" := PurchAdvanceLetterHeader."Pay-to Country/Region Code";
        GenJnlLine."VAT Registration No." := PurchAdvanceLetterHeader."VAT Registration No.";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        GenJnlLine."Source No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
        GenJnlLine.Validate("Currency Code", PurchAdvanceLetterHeader."Currency Code");
        GenJnlLine.Validate(Amount, -PrepaidAmount);
        if -PrepaidAmountLCY <> 0 then
            GenJnlLine.Validate("Amount (LCY)", -PrepaidAmountLCY);
        GenJnlLine."Shortcut Dimension 1 Code" := PurchAdvanceLetterHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PurchAdvanceLetterHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PurchAdvanceLetterHeader."Dimension Set ID";
        GenJnlLine."Variable Symbol" := PurchAdvanceLetterHeader."Variable Symbol";
        GenJnlLine."Constant Symbol" := PurchAdvanceLetterHeader."Constant Symbol";
        GenJnlLine."Specific Symbol" := PurchAdvanceLetterHeader."Specific Symbol";
        OnPostRefundCorrToGLOnBeforePostAdvancePaymentGenJnlLine(PurchAdvanceLetterHeader, GenJnlLine);

        if GenJnlLine.Amount <> 0 then
            GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CheckAmountToRefund(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        PurchAdvanceLetterLine.SetFilter("Amount To Refund", '>%1', 0);
        if not PurchAdvanceLetterLine.FindFirst then
            Error(Text040Err);

        if PurchAdvanceLetterLine."Amount To Deduct" + PurchAdvanceLetterLine."Amount To Invoice" <
           PurchAdvanceLetterLine."Amount To Refund"
        then
            Error(Text041Err, PurchAdvanceLetterLine.FieldCaption("Amount To Deduct"),
              PurchAdvanceLetterLine.FieldCaption("Amount To Invoice"),
              PurchAdvanceLetterLine.FieldCaption("Amount To Refund"));
        OnAfterCheckAmountToRefund(PurchAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure ClearAmountToRefund(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        if PurchAdvanceLetterLine.FindSet then
            repeat
                PurchAdvanceLetterLine."Amount To Refund" := 0;
                PurchAdvanceLetterLine."VAT Base To Refund" := 0;
                PurchAdvanceLetterLine."VAT Amount To Refund" := 0;
                PurchAdvanceLetterLine.Modify();
            until PurchAdvanceLetterLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure PostRefund(DocumentNo: Code[20]; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date; VATDate: Date; ToPrint: Boolean)
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvPaymentTemplate: Record "Purchase Adv. Payment Template";
    begin
        // Amount To Refund Checking
        CheckAmountToRefund(PurchAdvanceLetterHeader);
        PurchSetup.Get();
        if PurchSetup."Ext. Doc. No. Mandatory" then begin
            PurchAdvanceLetterHeader.TestField("External Document No.");
            if not CheckExternalDocumentNumber(PurchAdvanceLetterHeader, 1) then
                if not Confirm(
                     PurchaseAlreadyExistsQst, false,
                     Text035Txt, PurchAdvanceLetterHeader."External Document No.")
                then
                    Error('');
        end;

        if DocumentNo = '' then
            if PurchAdvanceLetterHeader."Template Code" <> '' then begin
                PurchAdvPaymentTemplate.Get(PurchAdvanceLetterHeader."Template Code");
                PurchAdvPaymentTemplate.TestField("Advance Credit Memo Nos.");
                DocumentNo := NoSeriesMgt.GetNextNo(PurchAdvPaymentTemplate."Advance Credit Memo Nos.", PostingDate, true);
            end else begin
                PurchSetup.Get();
                PurchSetup.TestField("Advance Credit Memo Nos.");
                DocumentNo := NoSeriesMgt.GetNextNo(PurchSetup."Advance Credit Memo Nos.", PostingDate, true);
            end;

        // Create, Post and Print VAT Credit Memo
        if CheckVATCredtMemoIsNeed(PurchAdvanceLetterHeader) then begin
            PostVATCreditMemo(DocumentNo, PurchAdvanceLetterHeader, PostingDate, VATDate);
            if ToPrint then
                PrintCreditMemo(DocumentNo);
        end else
            CreateBlankCrMemo(PurchAdvanceLetterHeader, DocumentNo, PostingDate, VATDate);
        PurchAdvanceLetterLine.Reset();
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        PurchAdvanceLetterLine.SetFilter("Amount To Deduct", '<>%1', 0);
        if PurchAdvanceLetterLine.FindSet(false, false) then
            repeat
                PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" +
                  PurchAdvanceLetterLine."Amount To Deduct";
                PurchAdvanceLetterLine."Amount Invoiced" := PurchAdvanceLetterLine."Amount Invoiced" -
                  PurchAdvanceLetterLine."Amount To Deduct";
                PurchAdvanceLetterLine."Amount To Deduct" := 0;
                PurchAdvanceLetterLine.SuspendStatusCheck(true);
                PurchAdvanceLetterLine.Modify(true);
            until PurchAdvanceLetterLine.Next() = 0;

        // Release Advance Payment
        PostRefundCorrection(DocumentNo, PurchAdvanceLetterHeader, PostingDate, VATDate);

        // Clear Amount To Refund from Letter Lines
        ClearAmountToRefund(PurchAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure RefundAndCloseLetterYesNo(DocumentNo: Code[20]; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date; VATDate: Date; ToPrint: Boolean)
    begin
        if Confirm(Text042Qst, false, PurchAdvanceLetterHeader."No.") then begin
            RefundAndCloseLetter(DocumentNo, PurchAdvanceLetterHeader, PostingDate, VATDate, ToPrint);
            PurchAdvanceLetterHeader.Get(PurchAdvanceLetterHeader."No.");
            if PurchAdvanceLetterHeader.Closed then
                Message(StrSubstNo(Text043Msg, PurchAdvanceLetterHeader."No."));
        end;
    end;

    [Scope('OnPrem')]
    procedure RefundAndCloseLetter(DocumentNo: Code[20]; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date; VATDate: Date; ToPrint: Boolean)
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        TotalAmtToRefund: Decimal;
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
    begin
        CloseAll := true;

        // Calc Amount To Refund
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        if PurchAdvanceLetterLine.FindSet then
            repeat
                PurchAdvanceLetterLine."Amount To Refund" := PurchAdvanceLetterLine."Amount To Invoice" +
                  PurchAdvanceLetterLine."Amount To Deduct";
                TotalAmtToRefund := TotalAmtToRefund + PurchAdvanceLetterLine."Amount To Refund";
                CalcVATToDeduct(PurchAdvanceLetterLine, BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY, 0);
                PurchAdvanceLetterLine."VAT Base To Refund" := BaseToDeduct;
                PurchAdvanceLetterLine."VAT Amount To Refund" := VATAmtToDeduct;
                PurchAdvanceLetterLine.Modify();
            until PurchAdvanceLetterLine.Next() = 0;

        // Post and Print
        if TotalAmtToRefund <> 0 then
            PostRefund(DocumentNo, PurchAdvanceLetterHeader, PostingDate, VATDate, ToPrint);

        // Set Amount To Link = 0 and Close
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        if PurchAdvanceLetterLine.FindSet then
            repeat
                PurchAdvanceLetterLine."Amount To Link" := 0;
                PurchAdvanceLetterLine.Status := PurchAdvanceLetterLine.Status::Closed;
                PurchAdvanceLetterLine.Modify();
            until PurchAdvanceLetterLine.Next() = 0;
        PurchAdvanceLetterHeader.UpdateClosing(true);

        CloseAll := false;
    end;

    local procedure PrintCreditMemo(DocumentNo: Code[20])
    var
        ReportSelections: Record "Report Selections";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        if PurchCrMemoHdr.Get(DocumentNo) then begin
            ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Cr.Memo");
            ReportSelections.Find('-');
            repeat
                ReportSelections.TestField("Report ID");
                REPORT.Run(ReportSelections."Report ID", false, false, PurchCrMemoHdr);
            until ReportSelections.Next() = 0;
        end;
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

    local procedure CreateAdvanceEntry(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchLineNo: Integer; VendLedgEntry: Record "Vendor Ledger Entry"; AmtInclVAT: Decimal)
    begin
        PurchAdvanceLetterEntryNo += 1;
        TempPurchAdvanceLetterEntry.Init();
        TempPurchAdvanceLetterEntry."Entry No." := PurchAdvanceLetterEntryNo;
        TempPurchAdvanceLetterEntry."Template Name" := PurchAdvanceLetterHeader."Template Code";
        TempPurchAdvanceLetterEntry."Letter No." := PurchAdvanceLetterHeader."No.";
        TempPurchAdvanceLetterEntry."Letter Line No." := PurchAdvanceLetterLine."Line No.";
        TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::Deduction;
        TempPurchAdvanceLetterEntry."Document Type" := TempPurchAdvanceLetterEntry."Document Type"::Invoice;
        TempPurchAdvanceLetterEntry."Document No." := PurchInvHeader."No.";
        TempPurchAdvanceLetterEntry."Purchase Line No." := PurchLineNo;
        TempPurchAdvanceLetterEntry."Posting Date" := PurchInvHeader."Posting Date";
        TempPurchAdvanceLetterEntry."Vendor No." := VendLedgEntry."Vendor No.";
        TempPurchAdvanceLetterEntry."Vendor Entry No." := VendLedgEntry."Entry No.";
        TempPurchAdvanceLetterEntry.Amount := AmtInclVAT;
        TempPurchAdvanceLetterEntry."Currency Code" := PurchInvHeader."Currency Code";
        TempPurchAdvanceLetterEntry."User ID" := UserId;
        OnCreateAdvanceEntryOnBeforeInsertTempPurchAdvanceLetterEntry(PurchAdvanceLetterHeader, PurchAdvanceLetterLine, TempPurchAdvanceLetterEntry);
        TempPurchAdvanceLetterEntry.Insert();
    end;

    local procedure FillVATFieldsOfDeductionEntry(VATPct: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.FindLast;
        TempPurchAdvanceLetterEntry."Transaction No." := VATEntry."Transaction No.";
        TempPurchAdvanceLetterEntry."VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
        TempPurchAdvanceLetterEntry."VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
        TempPurchAdvanceLetterEntry."VAT %" := VATPct;
        TempPurchAdvanceLetterEntry."VAT Identifier" := VATEntry."VAT Identifier";
        TempPurchAdvanceLetterEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type";
        TempPurchAdvanceLetterEntry."VAT Base Amount (LCY)" := VATEntry."Advance Base";
        TempPurchAdvanceLetterEntry."VAT Amount (LCY)" := VATEntry.Amount;
        TempPurchAdvanceLetterEntry."VAT Entry No." := VATEntry."Entry No.";
        TempPurchAdvanceLetterEntry."VAT Date" := VATEntry."VAT Date";
        OnBeforeModifyTempPurchAdvanceLetterEntryOnFillVATFieldsOfDeductionEntry(TempPurchAdvanceLetterEntry, VATEntry);
        TempPurchAdvanceLetterEntry.Modify();
    end;

    local procedure FillDeductionLineNo(DeductionLineNo: Integer)
    begin
        TempPurchAdvanceLetterEntry.SetRange("Entry Type", TempPurchAdvanceLetterEntry."Entry Type"::Deduction);
        if not TempPurchAdvanceLetterEntry.FindLast then begin
            TempPurchAdvanceLetterEntry.SetRange("Entry Type");
            TempPurchAdvanceLetterEntry.FindLast;
        end;
        TempPurchAdvanceLetterEntry.SetRange("Entry Type");
        repeat
            TempPurchAdvanceLetterEntry."Deduction Line No." := DeductionLineNo;
            TempPurchAdvanceLetterEntry.Modify();
        until TempPurchAdvanceLetterEntry.Next() = 0;
    end;

    local procedure SaveDeductionEntries()
    var
        PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry";
        NextEntryNo: Integer;
    begin
        TempPurchAdvanceLetterEntry.Reset();
        if TempPurchAdvanceLetterEntry.FindSet then begin
            PurchAdvanceLetterEntry.LockTable();
            NextEntryNo := PurchAdvanceLetterEntry.GetLastEntryNo() + 1;
            repeat
                PurchAdvanceLetterEntry := TempPurchAdvanceLetterEntry;
                PurchAdvanceLetterEntry."Entry No." := NextEntryNo;
                OnSaveDeductionEntriesOnBeforeInsertPurchAdvanceLetterEntry(PurchAdvanceLetterEntry);
                PurchAdvanceLetterEntry.Insert();
                NextEntryNo += 1;
            until TempPurchAdvanceLetterEntry.Next() = 0;
            TempPurchAdvanceLetterEntry.DeleteAll();
        end;
    end;

    [Scope('OnPrem')]
    procedure xGetLastPostNo(var LastPostedDocNoNew: Code[20])
    begin
        LastPostedDocNoNew := LastPostedDocNo;
    end;

    [Scope('OnPrem')]
    procedure UnPostInvoiceCorrection(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry";
        PurchAdvanceLetterEntry2: Record "Purch. Advance Letter Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        AdvanceLink2: Record "Advance Link";
        PurchAdvanceLetterLine2: Record "Purch. Advance Letter Line";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        TempPurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry" temporary;
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        VATEntry: Record "VAT Entry";
        TempPurchAdvanceLetterEntry2: Record "Purch. Advance Letter Entry" temporary;
        DocType: Option " ","Order",Invoice;
        DocNo: Code[20];
        EntryNo: Integer;
        AdvanceLinkEntryNo: Integer;
    begin
        if not ConfirmUnPostInvoiceCorrection(PurchInvHeader) then
            exit;
        GetDocumentTypeAndNo(PurchInvHeader, DocType, DocNo);
        PurchAdvanceLetterEntry.SetCurrentKey("Document No.", "Posting Date");
        PurchAdvanceLetterEntry.SetRange("Document No.", PurchInvHeader."No.");
        PurchAdvanceLetterEntry.SetRange("Posting Date", PurchInvHeader."Posting Date");
        PurchAdvanceLetterEntry.SetRange("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        PurchAdvanceLetterEntry.SetRange(Cancelled, false);
        if PurchAdvanceLetterEntry.Find('+') then begin
            OnUnPostInvoiceCorrectionOnAfterFindPurchAdvanceLetterEntry(PurchAdvanceLetterEntry, PurchAdvanceLetterHeader);
            SourceCodeSetup.Get();
            SetCurrencyPrecision(PurchInvHeader."Currency Code");
            PurchAdvanceLetterEntry2.LockTable();
            PurchAdvanceLetterEntry2.Find('+');
            EntryNo := PurchAdvanceLetterEntry2."Entry No.";
            AdvanceLink2.LockTable();
            AdvanceLink2.FindLast;
            AdvanceLinkEntryNo := AdvanceLink2."Entry No.";
            repeat
                case PurchAdvanceLetterEntry."Entry Type" of
                    PurchAdvanceLetterEntry."Entry Type"::Deduction:
                        begin
                            PurchAdvanceLetterLine2.Get(PurchAdvanceLetterEntry."Letter No.", PurchAdvanceLetterEntry."Letter Line No.");
                            PurchAdvanceLetterLine2."Amount To Deduct" := PurchAdvanceLetterLine2."Amount To Deduct" -
                              PurchAdvanceLetterEntry.Amount;
                            PurchAdvanceLetterLine2."Amount Deducted" := PurchAdvanceLetterLine2."Amount Deducted" +
                              PurchAdvanceLetterEntry.Amount;
                            PurchAdvanceLetterLine2.SuspendStatusCheck(true);
                            PurchAdvanceLetterLine2.Modify(true);
                            if PurchAdvanceLetterHeader."No." <> PurchAdvanceLetterLine2."Letter No." then begin
                                PurchAdvanceLetterHeader.Get(PurchAdvanceLetterLine2."Letter No.");
                                if PurchAdvanceLetterHeader.Closed then begin
                                    PurchAdvanceLetterHeader.Closed := false;
                                    PurchAdvanceLetterHeader.Modify();
                                end;
                            end;
                            AdvanceLetterLineRelation.Get(AdvanceType::Purchase, DocType, DocNo,
                              PurchAdvanceLetterEntry."Purchase Line No.",
                              PurchAdvanceLetterEntry."Letter No.",
                              PurchAdvanceLetterEntry."Letter Line No.");
                            AdvanceLetterLineRelation."Deducted Amount" += PurchAdvanceLetterEntry.Amount;
                            AdvanceLetterLineRelation.Modify();
                            UnPostInvCorrPurchLine(DocType, DocNo, PurchAdvanceLetterEntry);
                            AdvanceLetterLineRelation.CancelRelation(AdvanceLetterLineRelation, true, true, true);
                            TempPurchAdvanceLetterEntry := PurchAdvanceLetterEntry;
                            TempPurchAdvanceLetterEntry.Insert();
                        end;
                    PurchAdvanceLetterEntry."Entry Type"::"VAT Deduction":
                        begin
                            PurchAdvanceLetterLine2.Get(PurchAdvanceLetterEntry."Letter No.", PurchAdvanceLetterEntry."Letter Line No.");
                            PrepareInvJnlLine(GenJnlLine, PurchAdvanceLetterLine2, PurchInvHeader);
                            GenJnlLine.Correction := true;
                            GenJnlLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
                            GenJnlLine."Document No." := PurchInvHeader."No.";
                            SetPostingGroups(GenJnlLine, PurchAdvanceLetterLine2, false);
                            GenJnlLine."Account No." := PurchAdvanceLetterLine2."No.";
                            GenJnlLine."Advance VAT Base Amount" := -PurchAdvanceLetterEntry."VAT Base Amount (LCY)";
                            PurchAdvanceLetterEntry2.Get(PurchAdvanceLetterEntry."Entry No.");
                            if (PurchAdvanceLetterEntry2.Next > 0) and
                               (PurchAdvanceLetterEntry2."Entry Type" = PurchAdvanceLetterEntry2."Entry Type"::"VAT Rate")
                            then
                                GenJnlLine."Advance Exch. Rate Difference" := -PurchAdvanceLetterEntry2."VAT Amount (LCY)";
                            GenJnlLine.Validate(Amount, -PurchAdvanceLetterEntry."VAT Amount (LCY)");
                            UnPostInvCorrGL(PurchInvHeader, GenJnlLine);
                            if PurchAdvanceLetterLine2."VAT Calculation Type" <>
                               PurchAdvanceLetterLine2."VAT Calculation Type"::"Reverse Charge VAT"
                            then begin
                                GenJnlLine."Account No." := GetPurchAdvanceOffsetVATAccount(PurchAdvanceLetterLine2."VAT Bus. Posting Group", PurchAdvanceLetterLine2."VAT Prod. Posting Group");
                                GenJnlLine."Advance VAT Base Amount" := 0;
                                SetPostingGroups(GenJnlLine, PurchAdvanceLetterLine2, true);
                                GenJnlLine.Validate(Amount, PurchAdvanceLetterEntry."VAT Amount (LCY)");
                                UnPostInvCorrGL(PurchInvHeader, GenJnlLine);
                            end;
                        end;
                    PurchAdvanceLetterEntry."Entry Type"::"VAT Rate":
                        begin
                            PurchAdvanceLetterLine2.Get(PurchAdvanceLetterEntry."Letter No.", PurchAdvanceLetterEntry."Letter Line No.");
                            if PurchAdvanceLetterLine2."VAT Calculation Type" <>
                               PurchAdvanceLetterLine2."VAT Calculation Type"::"Reverse Charge VAT"
                            then begin
                                PrepareInvJnlLine(GenJnlLine, PurchAdvanceLetterLine2, PurchInvHeader);
                                GenJnlLine.Correction := true;
                                GenJnlLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
                                GenJnlLine."Document No." := PurchInvHeader."No.";
                                SetPostingGroups(GenJnlLine, PurchAdvanceLetterLine2, true);
                                GenJnlLine."Advance Exch. Rate Difference" := -PurchAdvanceLetterEntry."VAT Amount (LCY)";
                                if GenJnlLine."Advance Exch. Rate Difference" < 0 then begin
                                    Currency.TestField("Realized Losses Acc.");
                                    GenJnlLine."Account No." := Currency."Realized Losses Acc."
                                end else begin
                                    Currency.TestField("Realized Gains Acc.");
                                    GenJnlLine."Account No." := Currency."Realized Gains Acc.";
                                end;
                                GenJnlLine.Validate(Amount, GenJnlLine."Advance Exch. Rate Difference");
                                UnPostInvCorrGL(PurchInvHeader, GenJnlLine);
                                GenJnlLine."Account No." := GetPurchAdvanceOffsetVATAccount(PurchAdvanceLetterLine2."VAT Bus. Posting Group", PurchAdvanceLetterLine2."VAT Prod. Posting Group");
                                GenJnlLine.Validate(Amount, -GenJnlLine."Advance Exch. Rate Difference");
                                UnPostInvCorrGL(PurchInvHeader, GenJnlLine);
                            end;
                        end;
                end;
                PurchAdvanceLetterEntry2 := PurchAdvanceLetterEntry;
                PurchAdvanceLetterEntry2.Cancelled := true;
                PurchAdvanceLetterEntry2.Modify();
                EntryNo := EntryNo + 1;
                PurchAdvanceLetterEntry2."Entry No." := EntryNo;
                PurchAdvanceLetterEntry2.Amount := -PurchAdvanceLetterEntry2.Amount;
                PurchAdvanceLetterEntry2."VAT Base Amount (LCY)" := -PurchAdvanceLetterEntry2."VAT Base Amount (LCY)";
                PurchAdvanceLetterEntry2."VAT Amount (LCY)" := -PurchAdvanceLetterEntry2."VAT Amount (LCY)";
                PurchAdvanceLetterEntry2."VAT Base Amount" := -PurchAdvanceLetterEntry2."VAT Base Amount";
                PurchAdvanceLetterEntry2."VAT Amount" := -PurchAdvanceLetterEntry2."VAT Amount";
                if PurchAdvanceLetterEntry2."Entry Type" in [PurchAdvanceLetterEntry2."Entry Type"::"VAT Deduction",
                                                             PurchAdvanceLetterEntry2."Entry Type"::"VAT Rate"]
                then begin
                    VATEntry.FindLast;
                    PurchAdvanceLetterEntry2."Transaction No." := VATEntry."Transaction No.";
                    PurchAdvanceLetterEntry2."VAT Entry No." := VATEntry."Entry No.";
                end;
                PurchAdvanceLetterEntry2.Insert();
                TempPurchAdvanceLetterEntry2 := PurchAdvanceLetterEntry2;
                TempPurchAdvanceLetterEntry2.Insert();
            until PurchAdvanceLetterEntry.Next(-1) = 0;
            UnPostInvCorrUpdt(PurchInvHeader, AdvanceLinkEntryNo, SourceCodeSetup, TempPurchAdvanceLetterEntry);
            UnPostInvCorrInvDoc(PurchInvHeader, TempPurchAdvanceLetterEntry2)
        end;
    end;

    local procedure ConfirmUnPostInvoiceCorrection(PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    var
        IsHandled: Boolean;
        IsConfirmed: Boolean;
    begin
        OnBeforeConfirmUnPostInvoiceCorrection(PurchInvHeader, IsConfirmed, IsHandled);
        if IsHandled then
            exit(IsConfirmed);
        exit(Confirm(Text4005245Qst, false, PurchInvHeader."No."))
    end;

    local procedure GetDocumentTypeAndNo(PurchInvHeader: Record "Purch. Inv. Header"; var DocType: Option " ","Order",Invoice; var DocNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetDocumentTypeAndNo(PurchInvHeader, DocType, DocNo, IsHandled);
        if IsHandled then
            exit;
        DocType := DocType::Invoice;
        DocNo := PurchInvHeader."Pre-Assigned No.";
        if PurchInvHeader."Order No." <> '' then begin
            DocType := DocType::Order;
            DocNo := PurchInvHeader."Order No.";
        end;
    end;

    procedure UnPostInvCorrGL(PurchInvHeader: Record "Purch. Inv. Header"; GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Shortcut Dimension 1 Code" := PurchInvHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PurchInvHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PurchInvHeader."Dimension Set ID";
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure UnPostInvCorrPurchLine(DocType: Option " ","Order",Invoice; DocNo: Code[20]; PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry")
    var
        PurchLine: Record "Purchase Line";
        Currency: Record Currency;
    begin
        if PurchLine.Get(DocType, DocNo, PurchAdvanceLetterEntry."Purchase Line No.") then begin
            PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
            if PurchLine."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                Currency.Get(PurchLine."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
            if PurchHeader."Prices Including VAT" then
                PurchLine."Prepmt Amt Deducted" := PurchLine."Prepmt Amt Deducted" +
                  PurchAdvanceLetterEntry.Amount
            else
                PurchLine."Prepmt Amt Deducted" := PurchLine."Prepmt Amt Deducted" +
                  Round(PurchAdvanceLetterEntry.Amount /
                    (1 + PurchLine."VAT %" / 100),
                    Currency."Amount Rounding Precision");
            PurchLine.Modify();
        end;
    end;

    local procedure UnapplyVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; UnapplyDocNo: Code[20])
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry3: Record "Detailed Vendor Ledg. Entry";
        GenJnlLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        Succes: Boolean;
    begin
        SourceCodeSetup.Get();
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if UnapplyDocNo <> '' then
            DtldVendLedgEntry.SetRange("Document No.", UnapplyDocNo);
        Succes := false;
        repeat
            if DtldVendLedgEntry.FindLast then begin
                DtldVendLedgEntry2.Reset();
                DtldVendLedgEntry2.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
                DtldVendLedgEntry2.SetRange("Transaction No.", DtldVendLedgEntry."Transaction No.");
                DtldVendLedgEntry2.SetRange("Vendor No.", DtldVendLedgEntry."Vendor No.");
                if DtldVendLedgEntry2.FindSet then
                    repeat
                        if (DtldVendLedgEntry2."Entry Type" <> DtldVendLedgEntry2."Entry Type"::"Initial Entry") and
                           not DtldVendLedgEntry2.Unapplied
                        then
                            DtldVendLedgEntry3.Reset();
                        DtldVendLedgEntry3.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                        DtldVendLedgEntry3.SetRange("Vendor Ledger Entry No.", DtldVendLedgEntry2."Vendor Ledger Entry No.");
                        DtldVendLedgEntry3.SetRange(Unapplied, false);
                        if DtldVendLedgEntry3.FindLast and
                           (DtldVendLedgEntry3."Transaction No." > DtldVendLedgEntry2."Transaction No.")
                        then
                            Error(Text4005246Err, DtldVendLedgEntry3."Vendor Ledger Entry No.");
                    until DtldVendLedgEntry2.Next() = 0;

                GenJnlLine.Init();
                GenJnlLine."Document No." := DtldVendLedgEntry."Document No.";
                GenJnlLine."Posting Date" := DtldVendLedgEntry."Posting Date";
                GenJnlLine."VAT Date" := GenJnlLine."Posting Date";
                GenJnlLine."Original Document VAT Date" := GenJnlLine."VAT Date";
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                GenJnlLine."Account No." := DtldVendLedgEntry."Vendor No.";
                GenJnlLine.Correction := true;
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                GenJnlLine.Description := VendLedgEntry.Description;
                GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                GenJnlLine."Posting Group" := VendLedgEntry."Vendor Posting Group";
                GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
                GenJnlLine."Source No." := DtldVendLedgEntry."Vendor No.";
                GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Purch. Entry Appln.";
                GenJnlLine."Source Currency Code" := DtldVendLedgEntry."Currency Code";
                GenJnlLine."System-Created Entry" := true;
                OnUnapplyCustLedgEntryOnBeforeUnapply(VendLedgEntry, GenJnlLine);
                GenJnlPostLine.UnapplyVendLedgEntry(GenJnlLine, DtldVendLedgEntry);
            end else
                Succes := true;
        until Succes;
    end;

    local procedure UnPostInvCorrUpdt(PurchInvHeader: Record "Purch. Inv. Header"; AdvanceLinkEntryNo: Integer; SourceCodeSetup: Record "Source Code Setup"; var TempPurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry" temporary)
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        AdvanceLink: Record "Advance Link";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        VendLedgEntry.FindFirst;
        UnapplyVendLedgEntry(VendLedgEntry, PurchInvHeader."No.");

        AdvanceLink.Reset();
        AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
        AdvanceLink.SetRange("Document No.", PurchInvHeader."No.");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::Application);
        AdvanceLink.SetFilter("Entry No.", '..%1', AdvanceLinkEntryNo);
        AdvanceLink.CalcSums(Amount);

        if FindOpenVendLedgerEntry(PurchInvHeader, VendLedgEntry) then begin
            VendLedgEntry."Amount to Apply" := -AdvanceLink.Amount;
            VendLedgEntry.Modify();
        end;

        RefundUnPostInvCorrGL(AdvanceLink, PurchInvHeader, VendLedgEntry, SourceCodeSetup);
        if AdvanceLink.FindSet(true) then
            repeat
                if TempVendLedgEntry.Get(AdvanceLink."CV Ledger Entry No.") then begin
                    TempVendLedgEntry."Amount to Apply" := TempVendLedgEntry."Amount to Apply" + AdvanceLink.Amount;
                    TempVendLedgEntry.Modify();
                end else begin
                    VendLedgEntry.Get(AdvanceLink."CV Ledger Entry No.");
                    VendLedgEntry.TestField(Reversed, false);
                    TempVendLedgEntry := VendLedgEntry;
                    TempVendLedgEntry."Amount to Apply" := AdvanceLink.Amount;
                    TempVendLedgEntry.Insert();
                end;
            until AdvanceLink.Next() = 0;

        TempVendLedgEntry.SetFilter("Amount to Apply", '<>0');
        if TempVendLedgEntry.FindSet then begin
            GenJnlLine.Init();
            GenJnlLine.Prepayment := true;
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
            PreparePmtJnlLine(GenJnlLine, PurchInvHeader);
            GenJnlLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
            repeat
                VendLedgEntry.Get(TempVendLedgEntry."Entry No.");
                UnapplyVendLedgEntry(VendLedgEntry, PurchInvHeader."No.");

                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Refund);
                VendLedgEntry.SetRange(Prepayment, true);
                VendLedgEntry.SetRange(Open, true);
                VendLedgEntry.FindFirst;
                VendLedgEntry."Amount to Apply" := TempVendLedgEntry."Amount to Apply";
                VendLedgEntry.Modify();

                GenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
                if VendLedgEntry."Currency Code" <> '' then begin
                    VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    if VendLedgEntry."Remaining Amt. (LCY)" <> 0 then
                        GenJnlLine.Validate("Currency Factor", VendLedgEntry."Remaining Amount" / VendLedgEntry."Remaining Amt. (LCY)")
                    else
                        GenJnlLine.Validate("Currency Factor", VendLedgEntry."Adjusted Currency Factor");
                end;
                GenJnlLine.Validate(Amount, -TempVendLedgEntry."Amount to Apply");
                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Refund;
                GenJnlLine."Applies-to Doc. No." := PurchInvHeader."No.";
                GenJnlLine."Posting Group" := VendLedgEntry."Vendor Posting Group";
                OnUnPostInvCorrUpdtOnBeforeTempRefundUnPostInvCorrGL(VendLedgEntry, GenJnlLine);
                UnPostInvCorrGL(PurchInvHeader, GenJnlLine);
            until TempVendLedgEntry.Next() = 0;
        end;
        // Correct Remaining Amount
        if TempPurchAdvanceLetterEntry.FindSet then
            repeat
                AdvanceLink.Reset();
                AdvanceLink.SetCurrentKey("Document No.", "Line No.", "Entry Type");
                AdvanceLink.SetRange("Document No.", TempPurchAdvanceLetterEntry."Letter No.");
                AdvanceLink.SetRange("Line No.", TempPurchAdvanceLetterEntry."Letter Line No.");
                AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                AdvanceLink.SetRange("CV Ledger Entry No.", TempPurchAdvanceLetterEntry."Vendor Entry No.");
                if AdvanceLink.FindSet then
                    repeat
                        AdvanceLink."Remaining Amount to Deduct" := AdvanceLink."Remaining Amount to Deduct" +
                          TempPurchAdvanceLetterEntry.Amount;
                        if Abs(AdvanceLink."Remaining Amount to Deduct") > Abs(AdvanceLink.Amount) then
                            AdvanceLink.FieldError("Remaining Amount to Deduct");
                        AdvanceLink.Modify();
                    until (AdvanceLink.Next() = 0) or (TempPurchAdvanceLetterEntry.Amount = 0);
            until TempPurchAdvanceLetterEntry.Next() = 0;
    end;

    local procedure FindOpenVendLedgerEntry(PurchInvHeader: Record "Purch. Inv. Header"; var VendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    var
        IsHandled: Boolean;
        IsFound: Boolean;
    begin
        OnBeforeFindOpenVendLedgerEntry(PurchInvHeader, VendLedgEntry, IsFound, IsHandled);
        if IsHandled then
            exit(IsFound);
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.SetRange(Prepayment, false);
        VendLedgEntry.SetRange(Open, true);
        exit(VendLedgEntry.FindFirst());
    end;

    local procedure RefundUnPostInvCorrGL(AdvanceLink: Record "Advance Link"; PurchInvHeader: Record "Purch. Inv. Header"; VendLedgEntry: Record "Vendor Ledger Entry"; SourceCodeSetup: Record "Source Code Setup")
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        OnBeforeRefundUnPostInvCorr(AdvanceLink, PurchInvHeader, VendLedgEntry, IsHandled);
        if IsHandled then
            exit;
        GenJnlLine.Init();
        GenJnlLine.Prepayment := false;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
        PreparePmtJnlLine(GenJnlLine, PurchInvHeader);
        GenJnlLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
        GenJnlLine.Validate("Currency Code", PurchInvHeader."Currency Code");
        if GenJnlLine."Currency Code" <> '' then
            GenJnlLine.Validate("Currency Factor", VendLedgEntry."Original Currency Factor");
        GenJnlLine.Validate(Amount, AdvanceLink.Amount);
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Payment;
        GenJnlLine."Applies-to Doc. No." := PurchInvHeader."No.";
        UnPostInvCorrGL(PurchInvHeader, GenJnlLine);
    end;

    local procedure UnPostInvCorrInvDoc(PurchInvHeader: Record "Purch. Inv. Header"; var TempPurchAdvanceLetterEntry2: Record "Purch. Advance Letter Entry" temporary)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvLine2: Record "Purch. Inv. Line";
        PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry";
    begin
        // Correct Invoice document
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange("Prepayment Line", true);
        PurchInvLine.SetRange("Prepayment Cancelled", false);
        if PurchInvLine.FindSet(true, true) then
            repeat
                PurchInvLine2 := PurchInvLine;
                PurchInvLine2."Prepayment Cancelled" := true;
                PurchInvLine2.Modify();
                if PurchInvLine.Quantity <> 0 then begin
                    PurchInvLine2."Line No." := PurchInvLine2."Line No." + 1;
                    PurchInvLine2.Quantity := -PurchInvLine2.Quantity;
                    PurchInvLine2.Amount := -PurchInvLine2.Amount;
                    PurchInvLine2."Amount Including VAT" := -PurchInvLine2."Amount Including VAT";
                    PurchInvLine2."VAT Base Amount" := -PurchInvLine2."VAT Base Amount";
                    PurchInvLine2."Line Amount" := -PurchInvLine2."Line Amount";
                    PurchInvLine2.Insert();
                    TempPurchAdvanceLetterEntry2.SetRange("Deduction Line No.", PurchInvLine."Line No.");
                    if TempPurchAdvanceLetterEntry2.FindSet then begin
                        repeat
                            PurchAdvanceLetterEntry.Get(TempPurchAdvanceLetterEntry2."Entry No.");
                            PurchAdvanceLetterEntry."Deduction Line No." := PurchInvLine2."Line No.";
                            PurchAdvanceLetterEntry.Modify();
                        until TempPurchAdvanceLetterEntry2.Next() = 0;
                    end;
                end;
            until PurchInvLine.Next() = 0;
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
    procedure BuildInvoiceLineBuf(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PrepmtInvLineBuf.Reset();
        PrepmtInvLineBuf.DeleteAll();
        Clear(PrepmtInvLineBuf);
        PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        if PurchAdvanceLetterLine.FindSet then
            repeat
                if PurchAdvanceLetterLine."Amount To Invoice" <> 0 then
                    with PrepmtInvLineBuf do begin
                        Clear(PrepmtInvLineBuf);
                        "G/L Account No." := PurchAdvanceLetterLine."No.";
                        "Dimension Set ID" := InsertInDimBuf(PurchAdvanceLetterLine);
                        "Gen. Bus. Posting Group" := PurchAdvanceLetterLine."Gen. Bus. Posting Group";
                        "VAT Bus. Posting Group" := PurchAdvanceLetterLine."VAT Bus. Posting Group";
                        "Gen. Prod. Posting Group" := PurchAdvanceLetterLine."Gen. Prod. Posting Group";
                        "VAT Prod. Posting Group" := PurchAdvanceLetterLine."VAT Prod. Posting Group";
                        "VAT Calculation Type" := PurchAdvanceLetterLine."VAT Calculation Type";
                        "Global Dimension 1 Code" := PurchAdvanceLetterLine."Shortcut Dimension 1 Code";
                        "Global Dimension 2 Code" := PurchAdvanceLetterLine."Shortcut Dimension 2 Code";
                        "Dimension Set ID" := PurchAdvanceLetterLine."Dimension Set ID";
                        "Job No." := PurchAdvanceLetterLine."Job No.";

                        "Amount Incl. VAT" := PurchAdvanceLetterLine."Amount To Invoice";
                        "Amount Incl. VAT (LCY)" := PurchAdvanceLetterLine."Amount To Invoice (LCY)";

                        SetCurrencyPrecision(PurchAdvanceLetterLine."Currency Code");
                        if PurchAdvanceLetterLine."VAT Correction Inv." then begin
                            "VAT Difference" := PurchAdvanceLetterLine."VAT Difference Inv.";
                            "VAT Difference Inv. (LCY)" := PurchAdvanceLetterLine."VAT Difference Inv. (LCY)";
                            "VAT Amount" := PurchAdvanceLetterLine."VAT Amount Inv.";
                            "VAT Amount (LCY)" := PurchAdvanceLetterLine."VAT Amount Inv. (LCY)";
                            Amount := "Amount Incl. VAT" - "VAT Amount";
                            "Amount (LCY)" := "Amount Incl. VAT (LCY)" - "VAT Amount (LCY)";
                            "VAT Base Amount" := Amount;
                            "VAT Base Amount (LCY)" := "Amount (LCY)"
                        end else begin
                            Amount :=
                              Round(
                                "Amount Incl. VAT" * PurchAdvanceLetterLine.Amount / PurchAdvanceLetterLine."Amount Including VAT",
                                Currency."Amount Rounding Precision");

                            "VAT Base Amount" := Amount;
                            "VAT Amount" := "Amount Incl. VAT" - Amount;
                        end;

                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then begin
                            VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                            "VAT Amount" :=
                              Round(
                                Amount * VATPostingSetup."VAT %" / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection)
                        end;

                        "Amount (ACY)" := Amount;
                        "VAT Base Amount (ACY)" := Amount;
                        "VAT Amount (ACY)" := "VAT Amount";
                        "VAT %" := PurchAdvanceLetterLine."VAT %";
                        "VAT Identifier" := PurchAdvanceLetterLine."VAT Identifier";
                        "Tax Area Code" := PurchAdvanceLetterLine."Tax Area Code";
                        "Tax Liable" := PurchAdvanceLetterLine."Tax Liable";
                        "Tax Group Code" := PurchAdvanceLetterLine."Tax Group Code";
                        "Line No." := PurchAdvanceLetterLine."Line No.";
                        Description := PurchAdvanceLetterLine.Description;

                        Insert;
                    end;

            until PurchAdvanceLetterLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure AdvanceUpdateVATOnLines(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
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
        if PurchHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchHeader."Currency Code");

        with PurchLine do begin
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Prepmt. Line Amount", '<>0');

            LockTable();
            if Find('-') then
                repeat
                    PrepmtAmtToInvTotal := PrepmtAmtToInvTotal + ("Prepmt. Line Amount" - "Prepmt. Amt. Inv.");
                until Next() = 0;

            if Find('-') then
                repeat
                    PrepmtAmt := "Prepmt. Line Amount";
                    if PrepmtAmt <> 0 then begin
                        VATAmountLine.Get(
                          "VAT Identifier",
                          "VAT Calculation Type",
                          "Tax Group Code",
                          false,
                          PrepmtAmt >= 0);
                        if VATAmountLine.Modified then begin
                            if not TempVATAmountLineRemainder.Get(
                                 "VAT Identifier",
                                 "VAT Calculation Type",
                                 "Tax Group Code",
                                 false,
                                 PrepmtAmt >= 0)
                            then begin
                                TempVATAmountLineRemainder := VATAmountLine;
                                TempVATAmountLineRemainder.Init();
                                TempVATAmountLineRemainder.Insert();
                            end;

                            if PurchHeader."Prices Including VAT" then begin
                                if PrepmtAmt = 0 then begin
                                    VATAmount := 0;
                                    NewAmountIncludingVAT := 0;
                                end else begin
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      VATAmountLine."VAT Amount" * PrepmtAmt / VATAmountLine."Line Amount";
                                    NewAmountIncludingVAT :=
                                      TempVATAmountLineRemainder."Amount Including VAT" +
                                      VATAmountLine."Amount Including VAT" * PrepmtAmt / VATAmountLine."Line Amount";
                                end;
                                NewAmount :=
                                  Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                                  Round(VATAmount, Currency."Amount Rounding Precision");
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - PurchHeader."VAT Base Discount %" / 100),
                                    Currency."Amount Rounding Precision");
                            end else begin
                                NewAmount := PrepmtAmt;
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - PurchHeader."VAT Base Discount %" / 100),
                                    Currency."Amount Rounding Precision");
                                if VATAmountLine."VAT Base" = 0 then
                                    VATAmount := 0
                                else
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                                NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                            end;

                            "Prepayment Amount" := NewAmount;
                            "Prepmt. Amt. Incl. VAT" :=
                              Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");

                            "Prepmt. VAT Base Amt." := NewVATBaseAmount;

                            if (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount") = 0 then
                                VATDifference := 0
                            else
                                if PrepmtAmtToInvTotal = 0 then
                                    VATDifference :=
                                      VATAmountLine."VAT Difference" * ("Prepmt. Line Amount" - "Prepmt. Amt. Inv.") /
                                      (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount")
                                else
                                    VATDifference :=
                                      VATAmountLine."VAT Difference" * ("Prepmt. Line Amount" - "Prepmt. Amt. Inv.") /
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
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure AdvanceCalcVATAmountLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        PrevVatAmountLine: Record "VAT Amount Line";
        Currency: Record Currency;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
    begin
        if PurchHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchHeader."Currency Code");

        FillTempVATAmountLine(PurchHeader, PurchLine, TempVATAmountLine);
        with TempVATAmountLine do
            if Find('-') then
                repeat
                    if (PrevVatAmountLine."VAT Identifier" <> "VAT Identifier") or
                       (PrevVatAmountLine."VAT Calculation Type" <> "VAT Calculation Type") or
                       (PrevVatAmountLine."Tax Group Code" <> "Tax Group Code") or
                       (PrevVatAmountLine."Use Tax" <> "Use Tax")
                    then
                        PrevVatAmountLine.Init();
                    if PurchHeader."Prices Including VAT" then
                        case "VAT Calculation Type" of
                            "VAT Calculation Type"::"Normal VAT",
                            "VAT Calculation Type"::"Reverse Charge VAT":
                                begin
                                    "VAT Base" :=
                                        Round(
                                            ("Line Amount" - "Invoice Discount Amount") / (1 + "VAT %" / 100),
                                            Currency."Amount Rounding Precision") - "VAT Difference";
                                    "VAT Amount" :=
                                        "VAT Difference" +
                                        Round(
                                            PrevVatAmountLine."VAT Amount" +
                                            ("Line Amount" - "VAT Base" - "VAT Difference") *
                                            (1 - PurchHeader."VAT Base Discount %" / 100),
                                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection);

                                    "Amount Including VAT" := "VAT Base" + "VAT Amount";
                                    if Positive then
                                        PrevVatAmountLine.Init
                                    else begin
                                        PrevVatAmountLine := TempVATAmountLine;
                                        PrevVatAmountLine."VAT Amount" :=
                                          ("Line Amount" - "VAT Base" - "VAT Difference") *
                                          (1 - PurchHeader."VAT Base Discount %" / 100);
                                        PrevVatAmountLine."VAT Amount" :=
                                          PrevVatAmountLine."VAT Amount" -
                                          Round(PrevVatAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    end;
                                end;
                            "VAT Calculation Type"::"Sales Tax":
                                begin
                                    "Amount Including VAT" := "Line Amount" - "Invoice Discount Amount";
                                    "VAT Base" :=
                                      Round(
                                        SalesTaxCalculate.ReverseCalculateTax(
                                          PurchHeader."Tax Area Code", "Tax Group Code", PurchHeader."Tax Liable",
                                          PurchHeader."Posting Date", "Amount Including VAT", Quantity, PurchHeader."Currency Factor"),
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
                                        PrevVatAmountLine."VAT Amount" +
                                        "VAT Base" * "VAT %" / 100 * (1 - PurchHeader."VAT Base Discount %" / 100),
                                        Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    "Amount Including VAT" := "Line Amount" - "Invoice Discount Amount" + "VAT Amount";
                                    if Positive then
                                        PrevVatAmountLine.Init
                                    else begin
                                        PrevVatAmountLine := TempVATAmountLine;
                                        PrevVatAmountLine."VAT Amount" :=
                                          "VAT Base" * "VAT %" / 100 * (1 - PurchHeader."VAT Base Discount %" / 100);
                                        PrevVatAmountLine."VAT Amount" :=
                                          PrevVatAmountLine."VAT Amount" -
                                          Round(PrevVatAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    end;
                                end;
                            "VAT Calculation Type"::"Sales Tax":
                                begin
                                    "VAT Base" := "Line Amount" - "Invoice Discount Amount";
                                    "VAT Amount" :=
                                      SalesTaxCalculate.CalculateTax(
                                        PurchHeader."Tax Area Code", "Tax Group Code", PurchHeader."Tax Liable",
                                        PurchHeader."Posting Date", "VAT Base", Quantity, PurchHeader."Currency Factor");
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
                until Next() = 0;
    end;

    local procedure FillTempVATAmountLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        NewAmount: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeFillTempVATAmountLine(PurchHeader, PurchLine, TempVATAmountLine, IsHandled);
        if IsHandled then
            exit;

        TempVATAmountLine.DeleteAll();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        PurchLine.SetFilter("Prepmt. Line Amount", '<>0');
        if PurchLine.FindSet() then
            repeat
                NewAmount := PurchLine."Prepmt. Line Amount";
                if NewAmount <> 0 then begin
                    if PurchLine."Prepmt. VAT Calc. Type" in
                        [PurchLine."VAT Calculation Type"::"Reverse Charge VAT", PurchLine."VAT Calculation Type"::"Sales Tax"]
                    then
                        PurchLine."VAT %" := 0;
                    if not TempVATAmountLine.Get(
                            PurchLine."VAT Identifier", PurchLine."VAT Calculation Type",
                            PurchLine."Tax Group Code", false, NewAmount >= 0)
                    then begin
                        TempVATAmountLine.Init();
                        TempVATAmountLine."VAT Identifier" := PurchLine."VAT Identifier";
                        TempVATAmountLine."VAT Calculation Type" := PurchLine."VAT Calculation Type";
                        TempVATAmountLine."Tax Group Code" := PurchLine."Tax Group Code";
                        TempVATAmountLine."VAT %" := PurchLine."VAT %";
                        TempVATAmountLine.Modified := true;
                        TempVATAmountLine.Positive := NewAmount >= 0;
                        TempVATAmountLine."Includes Prepayment" := true;
                        TempVATAmountLine.Insert();
                    end;
                    TempVATAmountLine."Line Amount" := TempVATAmountLine."Line Amount" + NewAmount;
                    TempVATAmountLine.Modify();
                end;
            until PurchLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateAdvanceInvLineBuf(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TempAdvanceLetterLineRelation: Record "Advance Letter Line Relation" temporary)
    var
        GLAcc: Record "G/L Account";
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        PurchLine2: Record "Purchase Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        BufEntryNo: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeCreateAdvanceInvLineBuf(PurchHeader, PrepmtInvLineBuf, TempAdvanceLetterLineRelation, IsHandled);
        if IsHandled then
            exit;
        with PurchHeader do begin
            TempAdvanceLetterLineRelation.DeleteAll();
            BufEntryNo := 0;

            PurchLine2.SetRange("Document Type", "Document Type");
            PurchLine2.SetRange("Document No.", "No.");
            PurchLine2.SetFilter(Type, '<>%1', PurchLine2.Type::" ");
            PurchLine2.SetFilter("Prepmt. Line Amount", '<>0');
            if PurchLine2.FindSet(false, false) then begin
                repeat
                    TempPurchLine := PurchLine2;
                    TempPurchLine."Prepayment Amount" := 0;
                    TempPurchLine."Prepmt. Amt. Incl. VAT" := 0;
                    TempPurchLine."Prepmt. VAT Base Amt." := 0;
                    RecalcPrepm(TempPurchLine, "Prices Including VAT");
                    TempPurchLine.Insert();
                until PurchLine2.Next() = 0;
            end;

            AdvanceCalcVATAmountLines(PurchHeader, TempPurchLine, TempVATAmountLine);
            AdvanceUpdateVATOnLines(PurchHeader, TempPurchLine, TempVATAmountLine);

            TempPurchLine.SetRange("Document Type", "Document Type");
            TempPurchLine.SetRange("Document No.", "No.");
            TempPurchLine.SetFilter(Type, '<>%1', TempPurchLine.Type::" ");
            TempPurchLine.SetFilter("Prepmt. Line Amount", '<>0');

            TempPurchLine.SetRange("System-Created Entry", false);
            if TempPurchLine.Find('-') then
                repeat
                    if TempPurchLine."Prepmt. Line Amount" <> 0 then begin
                        if (TempPurchLine."VAT Bus. Posting Group" <> VATPostingSetup."VAT Bus. Posting Group") or
                           (TempPurchLine."VAT Prod. Posting Group" <> VATPostingSetup."VAT Prod. Posting Group")
                        then begin
                            VATPostingSetup.Get(
                              TempPurchLine."VAT Bus. Posting Group", TempPurchLine."VAT Prod. Posting Group");
                            VATPostingSetup.TestField("Purch. Advance VAT Account");
                        end;
                        GLAcc.Get(VATPostingSetup."Purch. Advance VAT Account");

                        Clear(TempPrepmtInvLineBuf);
                        TempPrepmtInvLineBuf.Init();
                        TempPrepmtInvLineBuf."G/L Account No." := GLAcc."No.";
                        TempPrepmtInvLineBuf."Dimension Set ID" := TempPurchLine."Dimension Set ID";
                        TempPrepmtInvLineBuf."Gen. Bus. Posting Group" := TempPurchLine."Gen. Bus. Posting Group";
                        TempPrepmtInvLineBuf."VAT Bus. Posting Group" := TempPurchLine."VAT Bus. Posting Group";
                        TempPrepmtInvLineBuf."Gen. Prod. Posting Group" := TempPurchLine."Gen. Prod. Posting Group";
                        TempPrepmtInvLineBuf."VAT Prod. Posting Group" := TempPurchLine."VAT Prod. Posting Group";
                        TempPrepmtInvLineBuf."VAT Calculation Type" := TempPurchLine."VAT Calculation Type";
                        TempPrepmtInvLineBuf."VAT Identifier" := TempPurchLine."VAT Identifier";
                        TempPrepmtInvLineBuf."Global Dimension 1 Code" := TempPurchLine."Shortcut Dimension 1 Code";
                        TempPrepmtInvLineBuf."Global Dimension 2 Code" := TempPurchLine."Shortcut Dimension 2 Code";
                        TempPrepmtInvLineBuf."Dimension Set ID" := TempPurchLine."Dimension Set ID";
                        TempPrepmtInvLineBuf."Job No." := TempPurchLine."Job No.";
                        TempPrepmtInvLineBuf."VAT Identifier" := TempPurchLine."VAT Identifier";
                        TempPrepmtInvLineBuf."Tax Area Code" := TempPurchLine."Tax Area Code";
                        TempPrepmtInvLineBuf."Tax Liable" := TempPurchLine."Tax Liable";
                        TempPrepmtInvLineBuf."Tax Group Code" := TempPurchLine."Tax Group Code";
                        TempPrepmtInvLineBuf."VAT %" := TempPurchLine."VAT %";
                        if not "Compress Prepayment" then begin
                            TempPrepmtInvLineBuf."Line No." := TempPurchLine."Line No.";
                            TempPrepmtInvLineBuf.Description := TempPurchLine.Description;
                        end else
                            TempPrepmtInvLineBuf.Description := GLAcc.Name;

                        PrepmtInvLineBuf := TempPrepmtInvLineBuf;
                        if not PrepmtInvLineBuf.Find then begin
                            PrepmtInvLineBuf.Insert();
                            BufEntryNo := BufEntryNo + 1;
                            PrepmtInvLineBuf."Entry No." := BufEntryNo;
                        end;

                        PrepmtInvLineBuf.Amount += TempPurchLine."Prepayment Amount";
                        PrepmtInvLineBuf."Amount Incl. VAT" += TempPurchLine."Prepmt. Amt. Incl. VAT";

                        PrepmtInvLineBuf."VAT Base Amount" += TempPurchLine."Prepayment Amount";
                        PrepmtInvLineBuf."VAT Amount" += (TempPurchLine."Prepmt. Amt. Incl. VAT" - TempPurchLine."Prepayment Amount");
                        PrepmtInvLineBuf."Amount (ACY)" += TempPurchLine."Prepayment Amount";
                        PrepmtInvLineBuf."VAT Base Amount (ACY)" += TempPurchLine."Prepayment Amount";
                        PrepmtInvLineBuf."VAT Amount (ACY)" += (TempPurchLine."Prepmt. Amt. Incl. VAT" - TempPurchLine."Prepayment Amount");
                        PrepmtInvLineBuf.Modify();

                        TempAdvanceLetterLineRelation.Init();
                        TempAdvanceLetterLineRelation.Type := TempAdvanceLetterLineRelation.Type::Purchase;
                        TempAdvanceLetterLineRelation."Document Type" := TempPurchLine."Document Type";
                        TempAdvanceLetterLineRelation."Document No." := TempPurchLine."Document No.";
                        TempAdvanceLetterLineRelation."Document Line No." := TempPurchLine."Line No.";
                        TempAdvanceLetterLineRelation."Letter Line No." := PrepmtInvLineBuf."Entry No.";
                        TempAdvanceLetterLineRelation.Amount := TempPurchLine."Prepmt. Amt. Incl. VAT";
                        TempAdvanceLetterLineRelation."Primary Link" := true;
                        OnCreateAdvanceInvLineBufOnBeforeInsertTempAdvanceLetterLineRelation(TempPurchLine, TempAdvanceLetterLineRelation);
                        TempAdvanceLetterLineRelation.Insert();
                    end;
                until TempPurchLine.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure RecalcPrepm(var PurchLine: Record "Purchase Line"; PriceInclVAT: Boolean)
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        PurchHeader: Record "Purchase Header";
        TempPurchLine: Record "Purchase Line" temporary;
        LinkedAmt: Decimal;
        LinkedRemAmtLine: Decimal;
    begin
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        PurchHeader.GetPostingLineImage(TempPurchLine, 3, false);
        TempPurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");

        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Document Type", PurchLine."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", PurchLine."Document No.");
        AdvanceLetterLineRelation.SetRange("Document Line No.", PurchLine."Line No.");
        OnRecalcPrepmOnAfterSetAdvanceLetterLineRelationFilters(PurchLine, AdvanceLetterLineRelation);
        if AdvanceLetterLineRelation.FindSet(false, false) then begin
            repeat
                LinkedAmt += AdvanceLetterLineRelation.Amount;
                LinkedRemAmtLine += (AdvanceLetterLineRelation.Amount - AdvanceLetterLineRelation."Deducted Amount");
            until AdvanceLetterLineRelation.Next() = 0;
        end;

        CheckPrepmtLineAmount(TempPurchLine, LinkedRemAmtLine, PurchLine);
        PurchLine."Prepmt. Line Amount" := GetPrepmtLineAmount(TempPurchLine, PurchLine, PriceInclVAT, LinkedAmt, LinkedRemAmtLine);
        OnAfterRecalcPrepm(TempPurchLine, PriceInclVAT, LinkedAmt, LinkedRemAmtLine, PurchLine);
    end;

    local procedure CheckPrepmtLineAmount(TempPurchLine: Record "Purchase Line" temporary; LinkedRemAmtLine: Decimal; PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckPrepmtLineAmount(TempPurchLine, LinkedRemAmtLine, PurchLine, IsHandled);
        if IsHandled then
            exit;
        if TempPurchLine."Amount Including VAT" < LinkedRemAmtLine then
            PurchLine.FieldError("Prepmt. Line Amount");
    end;

    local procedure GetPrepmtLineAmount(TempPurchLine: Record "Purchase Line" temporary; PurchLine: Record "Purchase Line"; PriceInclVAT: Boolean; LinkedAmt: Decimal; LinkedRemAmtLine: Decimal): Decimal
    var
        IsHandled: Boolean;
        PrepmtLineAmount: Decimal;
    begin
        OnBeforeGetPrepmtLineAmount(TempPurchLine, PurchLine, PriceInclVAT, LinkedAmt, LinkedRemAmtLine, PrepmtLineAmount, IsHandled);
        if IsHandled then
            exit(PrepmtLineAmount);

        if PriceInclVAT then begin
            if (TempPurchLine."Amount Including VAT" - LinkedRemAmtLine) < PurchLine."Prepmt. Line Amount" - LinkedAmt then
                exit(TempPurchLine."Amount Including VAT" - LinkedRemAmtLine);
            exit(PurchLine."Prepmt. Line Amount" - LinkedAmt);
        end;

        LinkedAmt := Round(LinkedAmt / (1 + PurchLine."VAT %" / 100));
        LinkedRemAmtLine := Round(LinkedRemAmtLine / (1 + PurchLine."VAT %" / 100));

        if (TempPurchLine.Amount - LinkedRemAmtLine) < PurchLine."Prepmt. Line Amount" - LinkedAmt then
            exit(TempPurchLine.Amount - LinkedRemAmtLine)
        else
            exit(PurchLine."Prepmt. Line Amount" - LinkedAmt);
    end;

    [Scope('OnPrem')]
    procedure SetAmtToDedOnPurchDoc(PurchHeader: Record "Purchase Header"; AdjustRelations: Boolean)
    var
        TempPurchLine: Record "Purchase Line" temporary;
        PurchLine: Record "Purchase Line";
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        AmtToDeductLoc: Decimal;
        DocRemainderAmt: Decimal;
        AdvanceLetterRemainderAmt: Decimal;
        InvAmtCorrection: Decimal;
        AdjustmentToleranceAmt: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeSetAmtToDedOnPurchDoc(PurchHeader, AdjustRelations, IsHandled);
        if IsHandled then
            exit;
        if (PurchHeader."Document Type" <> PurchHeader."Document Type"::Order) and
           (PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice)
        then
            exit;
        ClearLineRelAmountToDeduct(PurchHeader."Document Type", PurchHeader."No.");
        SetCurrencyPrecision(PurchHeader."Currency Code");

        PurchHeader.GetPostingLineImage(TempPurchLine, QtyType::Invoicing, false);
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter("Prepmt Amt to Deduct", '<>0');
        PurchLine.SetFilter("Prepayment %", '<>0');
        if PurchLine.FindSet then
            repeat
                if PurchLine."Adjust Prepmt. Relation" then
                    AdjustmentToleranceAmt := Currency."Amount Rounding Precision"
                else
                    AdjustmentToleranceAmt := 0;
                TempPurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
                if PurchHeader."Prices Including VAT" then
                    AmtToDeductLoc := PurchLine."Prepmt Amt to Deduct"
                else
                    AmtToDeductLoc := Round(PurchLine."Prepmt Amt to Deduct" * (1 + PurchLine."VAT %" / 100),
                        Currency."Amount Rounding Precision");
                if TempPurchLine."Amount Including VAT" < AmtToDeductLoc then
                    if AmtToDeductLoc - TempPurchLine."Amount Including VAT" <= AdjustmentToleranceAmt then
                        AmtToDeductLoc := TempPurchLine."Amount Including VAT"
                    else
                        Error(Text4005248Err, PurchLine."Line No.", PurchLine."Document Type", PurchLine."Document No.");
                DocRemainderAmt := TempPurchLine."Amount Including VAT" - AmtToDeductLoc;

                AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
                AdvanceLetterLineRelation.SetRange("Document Type", PurchHeader."Document Type");
                AdvanceLetterLineRelation.SetRange("Document No.", PurchLine."Document No.");
                AdvanceLetterLineRelation.SetRange("Document Line No.", PurchLine."Line No.");
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
                        if not TempPurchAdvanceLetterHeader.Get(AdvanceLetterLineRelation."Letter No.") then begin
                            TempPurchAdvanceLetterHeader."No." := AdvanceLetterLineRelation."Letter No.";
                            TempPurchAdvanceLetterHeader.Insert();
                        end;
                    until AdvanceLetterLineRelation.Next() = 0;
                if AmtToDeductLoc > AdjustmentToleranceAmt then
                    Error(Text4005249Err, PurchLine."Line No.", PurchLine."Document Type", PurchLine."Document No.");
                DocRemainderAmt += AmtToDeductLoc;
                if AdvanceLetterLineRelation.FindSet then
                    repeat
                        if DocRemainderAmt > 0 then begin
                            PurchAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                            PurchAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount");
                            if (PurchAdvanceLetterLine."Document Linked Amount" < PurchAdvanceLetterLine."Amount Including VAT") and
                               (PurchAdvanceLetterLine."Document Linked Inv. Amount" < PurchAdvanceLetterLine."Amount Invoiced")
                            then begin
                                if (PurchAdvanceLetterLine."Amount Including VAT" - PurchAdvanceLetterLine."Document Linked Amount") >
                                   (PurchAdvanceLetterLine."Amount Invoiced" - PurchAdvanceLetterLine."Document Linked Inv. Amount")
                                then
                                    AdvanceLetterRemainderAmt :=
                                      PurchAdvanceLetterLine."Amount Invoiced" - PurchAdvanceLetterLine."Document Linked Inv. Amount"
                                else
                                    AdvanceLetterRemainderAmt :=
                                      PurchAdvanceLetterLine."Amount Including VAT" - PurchAdvanceLetterLine."Document Linked Amount";
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
                    until AdvanceLetterLineRelation.Next() = 0;
            until PurchLine.Next() = 0;

        SetAmtToDedOnPurchDoc_Adj(PurchHeader, PurchLine, TempPurchAdvanceLetterHeader, TempPurchLine, AdjustRelations);

        SetAmtToDedOnPurchDoc_Fin(PurchHeader, PurchLine);
    end;

    local procedure SetAmtToDedOnPurchDoc_Adj(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary; var TempPurchLine: Record "Purchase Line" temporary; AdjustRelations: Boolean)
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        AdjustmentToleranceAmt: Decimal;
        AmtToDeductLoc: Decimal;
    begin
        if not TempPurchAdvanceLetterHeader.IsEmpty and AdjustRelations then begin
            AdvanceLetterLineRelation.Reset();
            AdjustmentToleranceAmt := Currency."Amount Rounding Precision";
            PurchLine.SetRange("Prepmt Amt to Deduct");
            PurchLine.SetRange("Adjust Prepmt. Relation", true);
            PurchLine.SetFilter("Prepayment %", '<>0');
            if PurchLine.FindSet then
                repeat
                    TempPurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
                    PurchLine.CalcFields("Adv.Letter Link.Amt. to Deduct");
                    if (TempPurchLine."Amount Including VAT" > PurchLine."Adv.Letter Link.Amt. to Deduct") and
                       (TempPurchLine."Amount Including VAT" <= PurchLine."Adv.Letter Link.Amt. to Deduct" + AdjustmentToleranceAmt)
                    then begin
                        TempPurchAdvanceLetterHeader.FindSet();
                        repeat
                            PurchAdvanceLetterLine.SetRange("Letter No.", TempPurchAdvanceLetterHeader."No.");
                            PurchAdvanceLetterLine.SetFilter("Amount To Deduct", '>0');
                            if PurchAdvanceLetterLine.FindSet then
                                repeat
                                    PurchAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount");
                                    if (PurchAdvanceLetterLine."Document Linked Amount" < PurchAdvanceLetterLine."Amount Including VAT") and
                                       (PurchAdvanceLetterLine."Document Linked Inv. Amount" < PurchAdvanceLetterLine."Amount Invoiced")
                                    then begin
                                        AmtToDeductLoc := TempPurchLine."Amount Including VAT" - PurchLine."Adv.Letter Link.Amt. to Deduct";
                                        if PurchAdvanceLetterLine."Amount Including VAT" - PurchAdvanceLetterLine."Document Linked Amount" <
                                           AmtToDeductLoc
                                        then
                                            AmtToDeductLoc :=
                                              PurchAdvanceLetterLine."Amount Including VAT" - PurchAdvanceLetterLine."Document Linked Amount";
                                        if PurchAdvanceLetterLine."Amount Invoiced" - PurchAdvanceLetterLine."Document Linked Inv. Amount" <
                                           AmtToDeductLoc
                                        then
                                            AmtToDeductLoc :=
                                              PurchAdvanceLetterLine."Amount Invoiced" - PurchAdvanceLetterLine."Document Linked Inv. Amount";
                                        AdvanceLetterLineRelation.Init();
                                        AdvanceLetterLineRelation.Type := AdvanceType::Purchase;
                                        AdvanceLetterLineRelation."Document Type" := PurchLine."Document Type";
                                        AdvanceLetterLineRelation."Document No." := PurchLine."Document No.";
                                        AdvanceLetterLineRelation."Document Line No." := PurchLine."Line No.";
                                        AdvanceLetterLineRelation."Letter No." := PurchAdvanceLetterLine."Letter No.";
                                        AdvanceLetterLineRelation."Letter Line No." := PurchAdvanceLetterLine."Line No.";
                                        AdvanceLetterLineRelation.Amount := AmtToDeductLoc;
                                        AdvanceLetterLineRelation."Invoiced Amount" := AmtToDeductLoc;
                                        AdvanceLetterLineRelation."Amount To Deduct" := AmtToDeductLoc;
                                        AdvanceLetterLineRelation.Insert();
                                        UpdateOrderLine(PurchLine, PurchHeader."Prices Including VAT", true);
                                        PurchLine.Modify();
                                    end;
                                until PurchAdvanceLetterLine.Next() = 0;
                        until TempPurchAdvanceLetterHeader.Next() = 0;
                    end;
                until PurchLine.Next() = 0;

            TempPurchAdvanceLetterHeader.FindSet();
            repeat
                PurchAdvanceLetterLine.SetRange("Letter No.", TempPurchAdvanceLetterHeader."No.");
                PurchAdvanceLetterLine.SetFilter("Amount To Deduct", '>0');
                if PurchAdvanceLetterLine.FindSet then
                    repeat
                        PurchAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount");
                        if (PurchAdvanceLetterLine."Document Linked Amount" < PurchAdvanceLetterLine."Amount Including VAT") and
                           (PurchAdvanceLetterLine."Document Linked Inv. Amount" < PurchAdvanceLetterLine."Amount Invoiced") and
                           (PurchAdvanceLetterLine."Document Linked Inv. Amount" + AdjustmentToleranceAmt >=
                            PurchAdvanceLetterLine."Amount Invoiced")
                        then begin
                            if PurchAdvanceLetterLine."Amount Including VAT" - PurchAdvanceLetterLine."Document Linked Amount" >
                               PurchAdvanceLetterLine."Amount Invoiced" - PurchAdvanceLetterLine."Document Linked Inv. Amount"
                            then
                                AmtToDeductLoc := PurchAdvanceLetterLine."Amount Invoiced" - PurchAdvanceLetterLine."Document Linked Inv. Amount"
                            else
                                AmtToDeductLoc := PurchAdvanceLetterLine."Amount Including VAT" - PurchAdvanceLetterLine."Document Linked Amount";
                            if PurchLine.FindSet then
                                repeat
                                    TempPurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
                                    PurchLine.CalcFields("Adv.Letter Link.Amt. to Deduct");
                                    if TempPurchLine."Amount Including VAT" > PurchLine."Adv.Letter Link.Amt. to Deduct" then begin
                                        if TempPurchLine."Amount Including VAT" - PurchLine."Adv.Letter Link.Amt. to Deduct" < AmtToDeductLoc then
                                            AmtToDeductLoc := TempPurchLine."Amount Including VAT" - PurchLine."Adv.Letter Link.Amt. to Deduct";
                                        AdvanceLetterLineRelation.Init();
                                        AdvanceLetterLineRelation.Type := AdvanceType::Purchase;
                                        AdvanceLetterLineRelation."Document Type" := PurchLine."Document Type";
                                        AdvanceLetterLineRelation."Document No." := PurchLine."Document No.";
                                        AdvanceLetterLineRelation."Document Line No." := PurchLine."Line No.";
                                        AdvanceLetterLineRelation."Letter No." := PurchAdvanceLetterLine."Letter No.";
                                        AdvanceLetterLineRelation."Letter Line No." := PurchAdvanceLetterLine."Line No.";
                                        AdvanceLetterLineRelation.Amount := AmtToDeductLoc;
                                        AdvanceLetterLineRelation."Invoiced Amount" := AmtToDeductLoc;
                                        AdvanceLetterLineRelation."Amount To Deduct" := AmtToDeductLoc;
                                        AdvanceLetterLineRelation.Insert();
                                        UpdateOrderLine(PurchLine, PurchHeader."Prices Including VAT", true);
                                        PurchLine.Modify();
                                    end;
                                until PurchLine.Next() = 0;
                        end
                    until PurchAdvanceLetterLine.Next() = 0;
            until TempPurchAdvanceLetterHeader.Next() = 0;
        end;
    end;

    local procedure SetAmtToDedOnPurchDoc_Fin(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        TempPurchLine: Record "Purchase Line" temporary;
        TotalInvoicedAmtLoc: Decimal;
        AdvanceLetterRemainderAmt: Decimal;
        ReduceAmt: Decimal;
    begin
        AdvanceLetterLineRelation.Reset();
        TempPurchLine.Reset();
        TempPurchLine.DeleteAll();
        PurchHeader.GetPostingLineImage(TempPurchLine, QtyType::Invoicing, false);
        PurchHeader.CalcFields("Adv.Letter Link.Amt. to Deduct");
        if TempPurchLine.FindSet then
            repeat
                TotalInvoicedAmtLoc += TempPurchLine."Amount Including VAT";
            until TempPurchLine.Next() = 0;
        AdvanceLetterRemainderAmt := 0;
        if (TotalInvoicedAmtLoc < PurchHeader."Adv.Letter Link.Amt. to Deduct") and
           (PurchHeader."Adv.Letter Link.Amt. to Deduct" > 0)
        then begin
            AdvanceLetterRemainderAmt := PurchHeader."Adv.Letter Link.Amt. to Deduct" - TotalInvoicedAmtLoc;
            PurchLine.SetFilter("VAT Difference (LCY)", '>0');
            PurchLine.SetFilter("Prepmt Amt to Deduct", '<>0');
            PurchLine.SetRange("Adjust Prepmt. Relation", true);
            if PurchLine.FindSet then
                repeat
                    if AdvanceLetterRemainderAmt > PurchLine."VAT Difference (LCY)" then
                        ReduceAmt := PurchLine."VAT Difference (LCY)"
                    else
                        ReduceAmt := AdvanceLetterRemainderAmt;
                    AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
                    AdvanceLetterLineRelation.SetRange("Document Type", PurchLine."Document Type");
                    AdvanceLetterLineRelation.SetRange("Document No.", PurchLine."Document No.");
                    AdvanceLetterLineRelation.SetRange("Document Line No.", PurchLine."Line No.");
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
                                UpdateOrderLine(PurchLine, PurchHeader."Prices Including VAT", true);
                            end;
                        until (AdvanceLetterLineRelation.Next() = 0) or (ReduceAmt = 0);
                until (PurchLine.Next() = 0) or (AdvanceLetterRemainderAmt = 0);
            if AdvanceLetterRemainderAmt > 0 then begin
                PurchLine.SetRange("VAT Difference (LCY)");
                PurchLine.SetFilter("Prepmt Amt to Deduct", '<>0');
                PurchLine.SetRange("Adjust Prepmt. Relation", true);
                if PurchLine.FindSet then
                    repeat
                        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
                        AdvanceLetterLineRelation.SetRange("Document Type", PurchLine."Document Type");
                        AdvanceLetterLineRelation.SetRange("Document No.", PurchLine."Document No.");
                        AdvanceLetterLineRelation.SetRange("Document Line No.", PurchLine."Line No.");
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
                                    UpdateOrderLine(PurchLine, PurchHeader."Prices Including VAT", true);
                                end;
                            until (AdvanceLetterLineRelation.Next() = 0) or (AdvanceLetterRemainderAmt = 0);
                    until (PurchLine.Next() = 0) or (AdvanceLetterRemainderAmt = 0);
            end;
        end;
        if AdvanceLetterRemainderAmt <> 0 then
            Error(Text4005250Err);
    end;

    [Scope('OnPrem')]
    procedure CalcVATCorrection(PurchHeader: Record "Purchase Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        PurchLine: Record "Purchase Line";
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        TempAdvanceLink: Record "Advance Link" temporary;
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        AmountToDeduct: Decimal;
        EntryPos: Integer;
        EntryCount: Integer;
        i: Integer;
        ToDeductFact: Decimal;
        BaseToDeduct: Decimal;
        VATAmtToDeduct: Decimal;
        BaseToDeductLCY: Decimal;
        VATAmountLCY: Decimal;
        BaseToDeductLCYDif: Decimal;
        VATAmountLCYDif: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCalcVATCorrection(PurchHeader, TempVATAmountLine, IsHandled);
        if IsHandled then
            exit;

        TempVATAmountLine.Reset();
        TempVATAmountLine.DeleteAll();
        Clear(TempVATAmountLine);
        GLSetup.Get();

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter("Qty. to Invoice", '<>0');
        if PurchLine.FindSet then
            repeat
                AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
                AdvanceLetterLineRelation.SetRange("Document Type", PurchLine."Document Type");

                AdvanceLetterLineRelation.SetRange("Document No.", PurchLine."Document No.");
                AdvanceLetterLineRelation.SetRange("Document Line No.", PurchLine."Line No.");
                if AdvanceLetterLineRelation.FindSet then begin
                    repeat
                        PurchAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                        CreateBufLink(TempAdvanceLink, PurchAdvanceLetterLine);
                        AmountToDeduct := AdvanceLetterLineRelation."Amount To Deduct";

                        TempVendLedgEntryGre.Reset();
                        TempVendLedgEntryGre.DeleteAll();
                        Clear(TempVendLedgEntryGre);

                        CalcLinkedPmtAmountToApplyTmp(
                          PurchAdvanceLetterLine, AmountToDeduct, TempVendLedgEntry, TempVendLedgEntryGre, TempAdvanceLink);

                        TotBaseToDeduct := 0;
                        TotVATAmtToDeduct := 0;
                        TotBaseToDeductLCY := 0;
                        TotVATAmtToDeductLCY := 0;
                        EntryPos := 0;

                        EntryCount := TempVendLedgEntryGre.Count();

                        for i := 1 to 2 do begin
                            if TempVendLedgEntryGre.FindSet then
                                repeat
                                    TempAdvanceLink.Reset();
                                    TempAdvanceLink.SetCurrentKey("CV Ledger Entry No.", "Entry Type", "Document No.", "Line No.");
                                    TempAdvanceLink.SetRange("CV Ledger Entry No.", TempVendLedgEntryGre."Entry No.");
                                    TempAdvanceLink.SetRange("Entry Type", TempAdvanceLink."Entry Type"::"Link To Letter");
                                    TempAdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
                                    TempAdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
                                    TempAdvanceLink.CalcSums(Amount, "Remaining Amount to Deduct");
                                    if TempAdvanceLink."Remaining Amount to Deduct" <> 0 then
                                        ToDeductFact := TempVendLedgEntryGre."Amount to Apply" /
                                          (TempAdvanceLink."Remaining Amount to Deduct" + TempVendLedgEntryGre."Amount to Apply")
                                    else
                                        ToDeductFact := 0;

                                    if (TempAdvanceLink."Remaining Amount to Deduct" = 0) = (i = 1) then begin
                                        EntryPos := EntryPos + 1;
                                        SetCurrencyPrecision(PurchAdvanceLetterLine."Currency Code");

                                        if i = 1 then begin
                                            CalcVATToDeduct(PurchAdvanceLetterLine,
                                              BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY,
                                              TempVendLedgEntryGre."Entry No.");
                                            BaseToDeduct := -BaseToDeduct;
                                            VATAmtToDeduct := -VATAmtToDeduct;
                                            if PurchHeader."Currency Code" = '' then begin
                                                BaseToDeductLCY := -BaseToDeductLCY;
                                                VATAmountLCY := -VATAmountLCY;
                                            end else begin
                                                BaseToDeductLCY := -BaseToDeductLCY;
                                                VATAmountLCY := -VATAmountLCY;
                                                BaseToDeductLCYDif := BaseToDeductLCY;
                                                VATAmountLCYDif := VATAmountLCY;
                                                if (PurchHeader."Currency Factor" <> PurchHeader."VAT Currency Factor") and
                                                   (PurchHeader."VAT Currency Factor" <> 0)
                                                then begin
                                                    BaseToDeductLCY := Round(BaseToDeduct / PurchHeader."VAT Currency Factor");
                                                    VATAmountLCY := Round(VATAmtToDeduct / PurchHeader."VAT Currency Factor");
                                                    // correct amount
                                                    if (BaseToDeductLCY + VATAmountLCY) <>
                                                       Round((BaseToDeduct + VATAmtToDeduct) / PurchHeader."VAT Currency Factor")
                                                    then
                                                        VATAmountLCY :=
                                                          Round((BaseToDeduct + VATAmtToDeduct) / PurchHeader."VAT Currency Factor") - BaseToDeductLCY;
                                                end else begin
                                                    BaseToDeductLCY := Round(BaseToDeduct / PurchHeader."Currency Factor");
                                                    VATAmountLCY := Round(VATAmtToDeduct / PurchHeader."Currency Factor");
                                                    // correct amount
                                                    if (BaseToDeductLCY + VATAmountLCY) <>
                                                       Round((BaseToDeduct + VATAmtToDeduct) / PurchHeader."VAT Currency Factor")
                                                    then
                                                        VATAmountLCY :=
                                                          Round((BaseToDeduct + VATAmtToDeduct) / PurchHeader."VAT Currency Factor") - BaseToDeductLCY;
                                                end;
                                                BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                                                VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
                                            end;
                                        end else
                                            if (EntryPos = EntryCount) and
                                               ((AdvanceLetterLineRelation."VAT Doc. VAT Base" <> 0) or
                                                (AdvanceLetterLineRelation."VAT Doc. VAT Amount" <> 0))
                                            then begin
                                                BaseToDeduct := -(AdvanceLetterLineRelation."VAT Doc. VAT Base" + TotBaseToDeduct);
                                                VATAmtToDeduct := -(AdvanceLetterLineRelation."VAT Doc. VAT Amount" + TotVATAmtToDeduct);
                                                if PurchHeader."Currency Code" = '' then begin
                                                    BaseToDeductLCY := BaseToDeduct;
                                                    VATAmountLCY := VATAmtToDeduct;
                                                end else begin
                                                    BaseToDeductLCY := -(AdvanceLetterLineRelation."VAT Doc. VAT Base (LCY)" + TotBaseToDeductLCY);
                                                    VATAmountLCY := -(AdvanceLetterLineRelation."VAT Doc. VAT Amount (LCY)" + TotVATAmtToDeductLCY);
                                                    VendLedgEntry.Get(TempVendLedgEntryGre."Entry No.");
                                                    BaseToDeductLCYDif := (BaseToDeduct / VendLedgEntry."Original Currency Factor") - BaseToDeductLCY;
                                                    VATAmountLCYDif := (VATAmtToDeduct / VendLedgEntry."Original Currency Factor") - VATAmountLCY;
                                                end;
                                            end else begin
                                                CalcVATToDeduct(PurchAdvanceLetterLine,
                                                  BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY,
                                                  TempVendLedgEntryGre."Entry No.");
                                                BaseToDeduct := -Round(BaseToDeduct * ToDeductFact, Currency."Amount Rounding Precision");
                                                VATAmtToDeduct := -Round(VATAmtToDeduct * ToDeductFact, Currency."Amount Rounding Precision");

                                                if PurchHeader."Currency Code" = '' then begin
                                                    BaseToDeductLCY := BaseToDeduct;
                                                    VATAmountLCY := VATAmtToDeduct;
                                                end else begin
                                                    BaseToDeductLCY := -Round(BaseToDeductLCY * ToDeductFact);
                                                    VATAmountLCY := -Round(VATAmountLCY * ToDeductFact);
                                                    BaseToDeductLCYDif := BaseToDeductLCY;
                                                    VATAmountLCYDif := VATAmountLCY;
                                                    if (PurchHeader."Currency Factor" <> PurchHeader."VAT Currency Factor") and
                                                       (PurchHeader."VAT Currency Factor" <> 0)
                                                    then begin
                                                        BaseToDeductLCY := Round(BaseToDeduct / PurchHeader."VAT Currency Factor");
                                                        VATAmountLCY := Round(VATAmtToDeduct / PurchHeader."VAT Currency Factor");
                                                    end else begin
                                                        BaseToDeductLCY := Round(BaseToDeduct / PurchHeader."Currency Factor");
                                                        VATAmountLCY := Round(VATAmtToDeduct / PurchHeader."Currency Factor");
                                                    end;
                                                    BaseToDeductLCYDif := BaseToDeductLCYDif - BaseToDeductLCY;
                                                    VATAmountLCYDif := VATAmountLCYDif - VATAmountLCY;
                                                end;
                                            end;

                                        TotBaseToDeduct += BaseToDeduct;
                                        TotVATAmtToDeduct += VATAmtToDeduct;
                                        TotBaseToDeductLCY += BaseToDeductLCY;
                                        TotVATAmtToDeductLCY += VATAmountLCY;

                                        CalcVATCorrection_InsertLines(TempVATAmountLine, PurchAdvanceLetterLine,
                                          BaseToDeduct, VATAmtToDeduct, BaseToDeductLCY, VATAmountLCY,
                                          BaseToDeductLCYDif,
                                          VATAmountLCYDif);
                                    end;
                                until TempVendLedgEntryGre.Next() = 0;
                        end;
                    until AdvanceLetterLineRelation.Next() = 0;
                end;
            until PurchLine.Next() = 0;
    end;

    local procedure CalcVATCorrection_InsertLines(var TempVATAmountLine: Record "VAT Amount Line" temporary; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; BaseToDeduct: Decimal; VATAmtToDeduct: Decimal; BaseToDeductLCY: Decimal; VATAmountLCY: Decimal; BaseToDeductLCYDif: Decimal; VATAmountLCYDif: Decimal)
    var
        IsHandled: Boolean;
    begin
        if (BaseToDeduct <> 0) or (VATAmtToDeduct <> 0) then begin
            Clear(TempPurchAdvanceLetterEntry);
            TempPurchAdvanceLetterEntry."VAT Identifier" := PurchAdvanceLetterLine."VAT Identifier";
            TempPurchAdvanceLetterEntry."Vendor Entry No." := TempVendLedgEntryGre."Entry No.";

            PurchAdvanceLetterEntryNo += 1;
            TempPurchAdvanceLetterEntry."Entry No." := PurchAdvanceLetterEntryNo;
            TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::"VAT Deduction";
            TempPurchAdvanceLetterEntry."Letter No." := PurchAdvanceLetterLine."Letter No.";
            TempPurchAdvanceLetterEntry."Letter Line No." := PurchAdvanceLetterLine."Line No.";
            TempPurchAdvanceLetterEntry.Amount := 0;
            TempPurchAdvanceLetterEntry.Insert();

            TempPurchAdvanceLetterEntry."VAT Identifier" := PurchAdvanceLetterLine."VAT Identifier";
            TempPurchAdvanceLetterEntry."VAT Base Amount" := BaseToDeduct;
            TempPurchAdvanceLetterEntry."VAT Amount" := VATAmtToDeduct;
            TempPurchAdvanceLetterEntry."VAT Amount (LCY)" := VATAmountLCY;
            TempPurchAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCY;
            TempPurchAdvanceLetterEntry.Modify();

            if VATAmountLCYDif <> 0 then begin
                PurchAdvanceLetterEntryNo += 1;
                TempPurchAdvanceLetterEntry."Entry No." := PurchAdvanceLetterEntryNo;
                TempPurchAdvanceLetterEntry."Entry Type" := TempPurchAdvanceLetterEntry."Entry Type"::"VAT Rate";
                TempPurchAdvanceLetterEntry.Amount := 0;
                TempPurchAdvanceLetterEntry."VAT Base Amount" := 0;
                TempPurchAdvanceLetterEntry."VAT Amount" := 0;
                TempPurchAdvanceLetterEntry."VAT Base Amount (LCY)" := BaseToDeductLCYDif;
                TempPurchAdvanceLetterEntry."VAT Amount (LCY)" := VATAmountLCYDif;
                TempPurchAdvanceLetterEntry.Insert();
            end;

            with PurchAdvanceLetterLine do
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

            // correct Reverse Charge VAT
            if TempVATAmountLine."VAT Calculation Type" <> TempVATAmountLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
                IsHandled := false;
                OnCalcVATCorrection_InsertLinesOnBeforeCalcVATAmounts(VATAmtToDeduct, BaseToDeduct, VATAmountLCY, BaseToDeductLCY, TempVATAmountLine, IsHandled);
                if not IsHandled then begin
                    TempVATAmountLine."VAT Amount" += VATAmtToDeduct;
                    TempVATAmountLine."VAT Base" += BaseToDeduct;
                    TempVATAmountLine."Amount Including VAT" += (VATAmtToDeduct + BaseToDeduct);
                    TempVATAmountLine."VAT Amount (LCY)" += VATAmountLCY;
                    TempVATAmountLine."VAT Base (LCY)" += BaseToDeductLCY;
                    TempVATAmountLine."Amount Including VAT (LCY)" += (VATAmountLCY + BaseToDeductLCY);
                end;
            end else begin
                TempVATAmountLine."VAT Amount" += 0;
                TempVATAmountLine."VAT Base" += BaseToDeduct;
                TempVATAmountLine."Amount Including VAT" += VATAmtToDeduct;
                TempVATAmountLine."VAT Amount (LCY)" += 0;
                TempVATAmountLine."VAT Base (LCY)" += BaseToDeductLCY;
                TempVATAmountLine."Amount Including VAT (LCY)" += BaseToDeductLCY;
            end;

            TempVATAmountLine."Calculated VAT Amount" := TempVATAmountLine."VAT Amount";
            TempVATAmountLine."Calculated VAT Amount (LCY)" := TempVATAmountLine."VAT Amount (LCY)";
            TempVATAmountLine."Ext. VAT Base (LCY)" := TempVATAmountLine."VAT Base (LCY)";
            TempVATAmountLine."Ext. VAT Amount (LCY)" := TempVATAmountLine."VAT Amount (LCY)";
            TempVATAmountLine."Ext.Amount Including VAT (LCY)" := TempVATAmountLine."Amount Including VAT (LCY)";
            TempVATAmountLine."Ext. Calc. VAT Amount (LCY)" := TempVATAmountLine."Calculated VAT Amount (LCY)";
            OnCalcVATCorrection_InsertLinesOnBeforeModifyTempVATAmountLine(TempVATAmountLine);
            TempVATAmountLine.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteTempApplnAdvanceLink()
    begin
        TempAdvanceLink.Reset();
        TempAdvanceLink.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateBufLink(var TempAdvanceLink: Record "Advance Link" temporary; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    var
        AdvanceLink: Record "Advance Link";
    begin
        AdvanceLink.Reset();
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
        AdvanceLink.SetRange(Type, AdvanceLink.Type::Purchase);
        if AdvanceLink.FindSet(false, false) then begin
            repeat
                if not TempAdvanceLink.Get(AdvanceLink."Entry No.") then begin
                    TempAdvanceLink := AdvanceLink;
                    TempAdvanceLink.Insert();
                end;
            until AdvanceLink.Next() = 0;
        end;
    end;

    local procedure CalcLinkedPmtAmountToApplyTmp(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; TotalAmountToApply: Decimal; var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntryLink: Record "Vendor Ledger Entry"; var AdvanceLink: Record "Advance Link")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
        AmountToApply: Decimal;
    begin
        if TotalAmountToApply = 0 then
            exit;

        SumAmountToApply := SumAmountToApply + TotalAmountToApply;

        SetCurrencyPrecision(PurchAdvanceLetterLine."Currency Code");
        AdvanceLink.Reset();
        AdvanceLink.SetCurrentKey("Entry Type", "Document No.", "Line No.", "Posting Date");
        AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
        AdvanceLink.SetRange("Document No.", PurchAdvanceLetterLine."Letter No.");
        AdvanceLink.SetRange("Line No.", PurchAdvanceLetterLine."Line No.");
        AdvanceLink.SetFilter("Remaining Amount to Deduct", '<>0');
        if AdvanceLink.FindSet then
            repeat
                if VendLedgEntry2.Get(AdvanceLink."CV Ledger Entry No.") then begin
                    case true of
                        TotalAmountToApply < -AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TotalAmountToApply;
                        TotalAmountToApply = -AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := TotalAmountToApply;
                        TotalAmountToApply > -AdvanceLink."Remaining Amount to Deduct":
                            AmountToApply := -AdvanceLink."Remaining Amount to Deduct";
                    end;
                    TotalAmountToApply := TotalAmountToApply - AmountToApply;
                    AdvanceLink."Remaining Amount to Deduct" := AdvanceLink."Remaining Amount to Deduct" + AmountToApply;
                    AdvanceLink.Modify();

                    if AmountToApply <> 0 then begin
                        if VendLedgEntry.Get(VendLedgEntry2."Entry No.") then begin
                            VendLedgEntry."Amount to Apply" := VendLedgEntry."Amount to Apply" - AmountToApply;
                            VendLedgEntry.Modify();
                        end else begin
                            VendLedgEntry := VendLedgEntry2;
                            VendLedgEntry."Amount to Apply" := -AmountToApply;
                            VendLedgEntry."Currency Code" := AdvanceLink."Currency Code";
                            VendLedgEntry.Insert();
                        end;
                        if VendLedgEntryLink.Get(VendLedgEntry2."Entry No.") then begin
                            VendLedgEntryLink."Amount to Apply" := VendLedgEntryLink."Amount to Apply" - AmountToApply;
                            VendLedgEntryLink.Modify();
                        end else begin
                            VendLedgEntryLink := VendLedgEntry2;
                            VendLedgEntryLink."Amount to Apply" := -AmountToApply;
                            VendLedgEntryLink."Currency Code" := AdvanceLink."Currency Code";
                            VendLedgEntryLink.Insert();
                        end;
                    end;
                end;
            until (AdvanceLink.Next() = 0) or (TotalAmountToApply = 0);

        AdvanceLink.Reset();
    end;

    [Scope('OnPrem')]
    procedure CorrectVATbyDeductedVAT(PurchHeader: Record "Purchase Header")
    var
        TempAdvanceVATAmtLine: Record "VAT Amount Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempSumVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineOrigSum: Record "VAT Amount Line" temporary;
        PurchLineCorr: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        TempPurchLineOrigin: Record "Purchase Line" temporary;
        TempVATAmountLineDiff: Record "VAT Amount Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        VendPostingGroup: Record "Vendor Posting Group";
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
    begin
        PurchHeader.CalcFields("Has Letter Line Relation");
        if not PurchHeader."Has Letter Line Relation" then
            exit;

        PurchHeader.TestField("Currency Code", '');
        SetAmtToDedOnPurchDoc(PurchHeader, true);
        SetCurrencyPrecision(PurchHeader."Currency Code");
        TempVATAmountLine.Reset();
        TempVATAmountLine.DeleteAll();

        PurchHeader.GetPostingLineImage(TempPurchLineOrigin, QtyType::Invoicing, false);
        PurchHeader.GetPostingLineImage(TempPurchLine, QtyType::Invoicing, false);
        PurchLineCorr.CalcVATAmountLines(1, PurchHeader, TempPurchLine, TempVATAmountLine);
        PurchPostAdvances.CalcVATCorrection(PurchHeader, TempAdvanceVATAmtLine);

        TempVATAmountLineDiff.Reset();
        TempVATAmountLineDiff.DeleteAll();

        SumVATAmountLines(TempVATAmountLine, TempSumVATAmountLine);
        if TempSumVATAmountLine.FindSet then
            repeat
                TempVATAmountLineOrigSum := TempSumVATAmountLine;
                TempVATAmountLineOrigSum.Insert();
            until TempSumVATAmountLine.Next() = 0;
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
            until TempSumVATAmountLine.Next() = 0;

            TempVATAmountLineDiff.SetFilter("VAT Base", '<>0');
            if not PurchHeader."Prices Including VAT" then
                if TempVATAmountLineDiff.FindSet then begin
                    repeat
                        // Adjust VAT Base - Insert Purchase Line VAT Base difference
                        TempPurchLine.SetRange("VAT Identifier", TempVATAmountLineDiff."VAT Identifier");
                        TempPurchLine.FindFirst;
                        VATPostingSetup.Get(TempPurchLine."VAT Bus. Posting Group", TempPurchLine."VAT Prod. Posting Group");
                        VATPostingSetup.TestField("Purch. Ded. VAT Base Adj. Acc.");
                        if GetVPGInvRoundAcc(PurchHeader) = VATPostingSetup."Purch. Ded. VAT Base Adj. Acc." then
                            Error(Text4005251Err, VATPostingSetup.FieldCaption("Purch. Ded. VAT Base Adj. Acc."),
                              VendPostingGroup.FieldCaption("Invoice Rounding Account"));
                        PurchLineCorr.SetRange("Document Type", PurchHeader."Document Type");
                        PurchLineCorr.SetRange("Document No.", PurchHeader."No.");
                        PurchLineCorr.SetRange("VAT Bus. Posting Group", TempPurchLine."VAT Bus. Posting Group");
                        PurchLineCorr.SetRange("VAT Prod. Posting Group", TempPurchLine."VAT Prod. Posting Group");
                        PurchLineCorr.SetRange(Type, PurchLineCorr.Type::"G/L Account");
                        PurchLineCorr.SetRange("No.", VATPostingSetup."Purch. Ded. VAT Base Adj. Acc.");
                        if TempVATAmountLineDiff."VAT Base" > 0 then
                            PurchLineCorr.SetRange("Direct Unit Cost", -1)
                        else
                            PurchLineCorr.SetRange("Direct Unit Cost", 1);
                        if PurchLineCorr.FindFirst then begin
                            PurchLineCorr.SuspendStatusCheck(true);
                            PurchLineCorr.Validate(Quantity, PurchLineCorr.Quantity + Abs(TempVATAmountLineDiff."VAT Base"));
                            PurchLineCorr.Modify(true);
                        end else begin
                            PurchLineCorr.Reset();
                            PurchLineCorr.SetRange("Document Type", PurchHeader."Document Type");
                            PurchLineCorr.SetRange("Document No.", PurchHeader."No.");
                            PurchLineCorr.FindLast;
                            PurchLineCorr.Init();
                            PurchLineCorr.SuspendStatusCheck(true);
                            PurchLineCorr."Line No." += 10000;
                            PurchLineCorr.Validate(Type, PurchLineCorr.Type::"G/L Account");
                            PurchLineCorr.Validate("No.", VATPostingSetup."Purch. Ded. VAT Base Adj. Acc.");
                            PurchLineCorr.Validate("VAT Prod. Posting Group", TempPurchLine."VAT Prod. Posting Group");
                            PurchLineCorr.Validate(Quantity, Abs(TempVATAmountLineDiff."VAT Base"));
                            if TempVATAmountLineDiff."VAT Base" > 0 then begin
                                PurchLineCorr.Validate("Prepayment %", 0);
                                PurchLineCorr.Validate("Direct Unit Cost", -1)
                            end else begin
                                PurchLineCorr.Validate("Prepayment %", 100);
                                PurchLineCorr.Validate("Direct Unit Cost", 1);
                            end;
                            PurchLineCorr.Insert(true);
                        end;
                    until TempVATAmountLineDiff.Next() = 0;

                    TempPurchLine.Reset();
                    TempPurchLine.DeleteAll();

                    TempVATAmountLine.Reset();
                    TempVATAmountLine.DeleteAll();
                    TempSumVATAmountLine.Reset();
                    TempSumVATAmountLine.DeleteAll();

                    PurchHeader.GetPostingLineImage(TempPurchLine, QtyType::Invoicing, false);
                    PurchLineCorr.CalcVATAmountLines(1, PurchHeader, TempPurchLine, TempVATAmountLine);
                    SumVATAmountLines(TempVATAmountLine, TempSumVATAmountLine);
                end;

            TempVATAmountLineDiff.Reset();
            TempVATAmountLineDiff.DeleteAll();
            Clear(TempVATAmountLineDiff);

            CorrectVATbyDeductedVAT_CorrLine(
              TempSumVATAmountLine, TempVATAmountLineOrigSum, TempVATAmountLine, TempVATAmountLineDiff, TempAdvanceVATAmtLine);

            TempVATAmountLine.Reset();

            Clear(PurchLineCorr);
            PurchLineCorr.Reset();
            PurchLineCorr.UpdateVATOnLines(1, PurchHeader, PurchLineCorr, TempVATAmountLine);
            AdjustRelationOnCorrectedLines(PurchHeader, TempPurchLineOrigin);
            SetAmtToDedOnPurchDoc(PurchHeader, true);
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
            until TempSumVATAmountLine.Next() = 0;

            // Adjust VAT Amount - Correct Statistics
            TempVATAmountLineDiff.SetFilter("VAT Amount", '<>0');
            if TempVATAmountLineDiff.FindSet then begin
                repeat
                    TempVATAmountLine := TempVATAmountLineDiff;
                    TempVATAmountLine.Find;
                    TempVATAmountLine.Validate("VAT Amount",
                      TempVATAmountLine."VAT Amount" - TempVATAmountLineDiff."VAT Amount");
                    if PurchHeader."Prices Including VAT" then
                        TempVATAmountLine."VAT Base" := TempVATAmountLine."Amount Including VAT" - TempVATAmountLine."VAT Amount"
                    else
                        TempVATAmountLine."Amount Including VAT" := TempVATAmountLine."VAT Amount" + TempVATAmountLine."VAT Base";
                    if PurchHeader."Currency Code" = '' then begin
                        TempVATAmountLine.Validate("VAT Amount (LCY)", TempVATAmountLine."VAT Amount");
                        TempVATAmountLine."VAT Base (LCY)" := TempVATAmountLine."VAT Base";
                        TempVATAmountLine."Amount Including VAT (LCY)" := TempVATAmountLine."Amount Including VAT";
                    end;
                    TempVATAmountLine."Modified (LCY)" := true;
                    TempVATAmountLine.Modified := true;
                    TempVATAmountLine.Modify();
                    TempVATAmountLine.ModifyAll("Modified (LCY)", true);
                    TempVATAmountLine.ModifyAll(Modified, true);
                until TempVATAmountLineDiff.Next() = 0;
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
            until TempVATAmountLine.Next() = 0;
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
            until TempVATAmountLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure AdjustRelationOnCorrectedLines(PurchHeader: Record "Purchase Header"; var PurchLineOrigin: Record "Purchase Line")
    var
        TempPurchLine: Record "Purchase Line" temporary;
        TempPurchLine2: Record "Purchase Line" temporary;
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        PurchLine: Record "Purchase Line";
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        DecrementAmt: Decimal;
        RemainingAmtLoc: Decimal;
    begin
        PurchHeader.GetPostingLineImage(TempPurchLine, QtyType::Invoicing, false);
        PurchHeader.GetPostingLineImage(TempPurchLine2, QtyType::Invoicing, false);
        if TempPurchLine.FindSet then
            repeat
                if PurchLineOrigin.Get(TempPurchLine."Document Type", TempPurchLine."Document No.", TempPurchLine."Line No.") then
                    if TempPurchLine."Amount Including VAT" - PurchLineOrigin."Amount Including VAT" < 0 then begin
                        TempPurchLine.CalcFields("Adv.Letter Linked Inv. Amount", "Adv.Letter Linked Ded. Amount");
                        if TempPurchLine."Adv.Letter Linked Inv. Amount" - TempPurchLine."Adv.Letter Linked Ded. Amount" >
                           TempPurchLine."Amount Including VAT"
                        then begin
                            DecrementAmt := PurchLineOrigin."Amount Including VAT" -
                              TempPurchLine."Amount Including VAT";
                            RemainingAmtLoc := DecrementAmt;
                            AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
                            AdvanceLetterLineRelation.SetRange("Document Type", TempPurchLine."Document Type");
                            AdvanceLetterLineRelation.SetRange("Document No.", TempPurchLine."Document No.");
                            AdvanceLetterLineRelation.SetRange("Document Line No.", TempPurchLine."Line No.");
                            if AdvanceLetterLineRelation.Find('-') then begin
                                repeat
                                    if AdvanceLetterLineRelation."Invoiced Amount" >
                                       AdvanceLetterLineRelation."Deducted Amount"
                                    then begin
                                        if AdvanceLetterLineRelation."Invoiced Amount" -
                                           AdvanceLetterLineRelation."Deducted Amount" > RemainingAmtLoc
                                        then begin
                                            AdvanceLetterLineRelation.Amount -= RemainingAmtLoc;
                                            AdvanceLetterLineRelation."Invoiced Amount" -= RemainingAmtLoc;
                                            AdvanceLetterLineRelation.Modify();
                                            RemainingAmtLoc := 0;
                                        end else begin
                                            RemainingAmtLoc -=
                                              AdvanceLetterLineRelation."Invoiced Amount" - AdvanceLetterLineRelation."Deducted Amount";
                                            AdvanceLetterLineRelation.Amount -=
                                              AdvanceLetterLineRelation."Invoiced Amount" - AdvanceLetterLineRelation."Deducted Amount";
                                            AdvanceLetterLineRelation."Invoiced Amount" -=
                                              AdvanceLetterLineRelation."Invoiced Amount" - AdvanceLetterLineRelation."Deducted Amount";
                                            AdvanceLetterLineRelation.Modify();
                                        end;
                                        PurchLine.Get(TempPurchLine."Document Type", TempPurchLine."Document No.", TempPurchLine."Line No.");
                                        UpdateOrderLine(PurchLine, PurchHeader."Prices Including VAT", true);
                                        PurchLine.Modify();
                                        TempPurchAdvanceLetterLine."Letter No." := AdvanceLetterLineRelation."Letter No.";
                                        TempPurchAdvanceLetterLine."Line No." := AdvanceLetterLineRelation."Letter Line No.";
                                        TempPurchAdvanceLetterLine.Insert();
                                    end;
                                until (AdvanceLetterLineRelation.Next() = 0) or (RemainingAmtLoc <= 0);
                                DecrementAmt := DecrementAmt - RemainingAmtLoc;
                                if DecrementAmt > 0 then begin
                                    TempPurchLine2.SetRange("Document Type", TempPurchLine."Document Type");
                                    TempPurchLine2.SetRange("Document No.", TempPurchLine."Document No.");
                                    TempPurchLine2.SetRange("VAT Identifier", TempPurchLine."VAT Identifier");
                                    if TempPurchLine2.FindLast then begin
                                        TempPurchLine2.CalcFields("Adv.Letter Linked Ded. Amount", "Adv.Letter Linked Inv. Amount");
                                        if TempPurchLine2."Amount Including VAT" - TempPurchLine2."Adv.Letter Linked Inv. Amount" +
                                           TempPurchLine2."Adv.Letter Linked Ded. Amount" >= DecrementAmt
                                        then
                                            if TempPurchAdvanceLetterLine.FindSet then
                                                repeat
                                                    PurchAdvanceLetterLine.Get(TempPurchAdvanceLetterLine."Letter No.", TempPurchAdvanceLetterLine."Line No.");
                                                    PurchAdvanceLetterLine.CalcFields("Document Linked Inv. Amount");
                                                    if PurchAdvanceLetterLine."Amount Invoiced" -
                                                       PurchAdvanceLetterLine."Document Linked Inv. Amount" >= DecrementAmt
                                                    then begin
                                                        if AdvanceLetterLineRelation.Get(AdvanceLetterLineRelation.Type::Purchase,
                                                             TempPurchLine2."Document Type",
                                                             TempPurchLine2."Document No.",
                                                             TempPurchLine2."Line No.",
                                                             TempPurchAdvanceLetterLine."Letter No.",
                                                             TempPurchAdvanceLetterLine."Line No.")
                                                        then begin
                                                            AdvanceLetterLineRelation."Invoiced Amount" += DecrementAmt;
                                                            if AdvanceLetterLineRelation."Invoiced Amount" > AdvanceLetterLineRelation.Amount then
                                                                AdvanceLetterLineRelation.Amount := AdvanceLetterLineRelation."Invoiced Amount";
                                                            AdvanceLetterLineRelation.Modify();
                                                        end else begin
                                                            AdvanceLetterLineRelation.Init();
                                                            AdvanceLetterLineRelation.Type := AdvanceLetterLineRelation.Type::Purchase;
                                                            AdvanceLetterLineRelation."Document Type" := TempPurchLine2."Document Type";
                                                            AdvanceLetterLineRelation."Document No." := TempPurchLine2."Document No.";
                                                            AdvanceLetterLineRelation."Document Line No." := TempPurchLine2."Line No.";
                                                            AdvanceLetterLineRelation."Letter No." := TempPurchAdvanceLetterLine."Letter No.";
                                                            AdvanceLetterLineRelation."Letter Line No." := TempPurchAdvanceLetterLine."Line No.";
                                                            AdvanceLetterLineRelation.Amount := DecrementAmt;
                                                            AdvanceLetterLineRelation."Invoiced Amount" := DecrementAmt;
                                                            AdvanceLetterLineRelation.Insert();
                                                            DecrementAmt := 0;
                                                        end;
                                                        PurchLine.Get(TempPurchLine2."Document Type",
                                                          TempPurchLine2."Document No.",
                                                          TempPurchLine2."Line No.");
                                                        UpdateOrderLine(PurchLine, PurchHeader."Prices Including VAT", true);
                                                        PurchLine.Modify();
                                                    end;
                                                until (TempPurchAdvanceLetterLine.Next() = 0) or (DecrementAmt = 0);
                                    end;
                                end;
                            end;
                        end;
                    end;
                TempPurchAdvanceLetterLine.Reset();
                TempPurchAdvanceLetterLine.DeleteAll();
            until TempPurchLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure BuilCreditMemoBuf(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    var
        PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PrepmtInvLineBuf.Reset();
        PrepmtInvLineBuf.DeleteAll();
        Clear(PrepmtInvLineBuf);

        PurchInvHeader.Get(CurrPurchInvHeader."No.");

        PurchAdvanceLetterEntry.SetCurrentKey("Letter No.", "Letter Line No.", "Entry Type", "Posting Date");
        PurchAdvanceLetterEntry.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        PurchAdvanceLetterEntry.SetRange("Entry Type", PurchAdvanceLetterEntry."Entry Type"::VAT);
        PurchAdvanceLetterEntry.SetRange("Document Type", PurchAdvanceLetterEntry."Document Type"::Invoice);
        PurchAdvanceLetterEntry.SetRange("Document No.", CurrPurchInvHeader."No.");
        PurchAdvanceLetterEntry.SetRange("Posting Date", PurchInvHeader."Posting Date");

        if PurchAdvanceLetterEntry.FindSet(false, false) then begin
            repeat
                PrepmtInvLineBuf.Init();
                PurchAdvanceLetterLine.Get(PurchAdvanceLetterEntry."Letter No.", PurchAdvanceLetterEntry."Letter Line No.");

                if PurchInvLine.Get(PurchAdvanceLetterEntry."Document No.", PurchAdvanceLetterEntry."Purchase Line No.") then;

                with PrepmtInvLineBuf do begin
                    "G/L Account No." := PurchAdvanceLetterLine."No.";
                    "Dimension Set ID" := PurchInvLine."Dimension Set ID";
                    "Job No." := PurchAdvanceLetterLine."Job No.";
                    "Tax Area Code" := PurchAdvanceLetterLine."Tax Area Code";
                    "Tax Liable" := PurchAdvanceLetterLine."Tax Liable";
                    "Tax Group Code" := PurchAdvanceLetterLine."Tax Group Code";
                    "VAT Identifier" := PurchAdvanceLetterLine."VAT Identifier";
                    "Line No." := PurchAdvanceLetterLine."Line No.";

                    if not Find then begin
                        if PurchInvLine.Get(PurchAdvanceLetterEntry."Document No.", PurchAdvanceLetterEntry."Purchase Line No.") then;
                        "VAT %" := PurchAdvanceLetterLine."VAT %";
                        "Gen. Bus. Posting Group" := PurchAdvanceLetterLine."Gen. Bus. Posting Group";
                        "VAT Bus. Posting Group" := PurchAdvanceLetterLine."VAT Bus. Posting Group";
                        "Gen. Prod. Posting Group" := PurchAdvanceLetterLine."Gen. Prod. Posting Group";
                        "VAT Prod. Posting Group" := PurchAdvanceLetterLine."VAT Prod. Posting Group";
                        "VAT Calculation Type" := PurchAdvanceLetterLine."VAT Calculation Type";
                        "Global Dimension 1 Code" := PurchInvLine."Shortcut Dimension 1 Code";
                        "Global Dimension 2 Code" := PurchInvLine."Shortcut Dimension 2 Code";
                        Description := PurchAdvanceLetterLine.Description;
                        Insert;
                    end;
                end;
            until PurchAdvanceLetterEntry.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetPurchInvHeaderBuf(var PurchInvHeaderBuf2: Record "Purch. Inv. Header")
    begin
        PurchInvHeaderBuf := PurchInvHeaderBuf2;
        CurrPurchInvHeader := PurchInvHeaderBuf;
    end;

    [Scope('OnPrem')]
    procedure GetVPGInvRoundAcc(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        Vend: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        if PurchSetup."Invoice Rounding" then
            if Vend.Get(PurchHeader."Pay-to Vendor No.") then
                VendPostingGroup.Get(Vend."Vendor Posting Group");

        exit(VendPostingGroup."Invoice Rounding Account");
    end;

    local procedure PostDocAfterApp(var TempAdvanceLink: Record "Advance Link" temporary)
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        PurchaseAdvPaymentTemplate: Record "Purchase Adv. Payment Template";
        IsPostAutVAT: Boolean;
    begin
        PurchSetup.Get();
        if TempAdvanceLink.Find('-') then begin
            repeat
                if TempAdvanceLink."Entry Type" = TempAdvanceLink."Entry Type"::"Link To Letter" then begin
                    PurchAdvanceLetterHeader.Get(TempAdvanceLink."Document No.");
                    TempPurchAdvanceLetterHeader := PurchAdvanceLetterHeader;
                    if TempPurchAdvanceLetterHeader.Insert() then;
                end;
            until TempAdvanceLink.Next() = 0;
        end;
        if TempPurchAdvanceLetterHeader.Find('-') then begin
            repeat
                IsPostAutVAT := PurchSetup."Automatic Adv. Invoice Posting";
                if TempPurchAdvanceLetterHeader."Template Code" <> '' then begin
                    if TempPurchAdvanceLetterHeader."Template Code" <> PurchaseAdvPaymentTemplate.Code then
                        PurchaseAdvPaymentTemplate.Get(TempPurchAdvanceLetterHeader."Template Code");
                    IsPostAutVAT := PurchaseAdvPaymentTemplate."Automatic Adv. Invoice Posting";
                end;
                if TempPurchAdvanceLetterHeader."Post Advance VAT Option" =
                   TempPurchAdvanceLetterHeader."Post Advance VAT Option"::Never
                then
                    IsPostAutVAT := true;
                if not IsPostAutVAT then
                    TempPurchAdvanceLetterHeader.Delete();
            until TempPurchAdvanceLetterHeader.Next() = 0;
        end;
        if not TempPurchAdvanceLetterHeader.IsEmpty() then begin
            SetLetterHeader(TempPurchAdvanceLetterHeader);
            AutoPostAdvanceInvoices;
        end;
    end;

    local procedure CreateBlankCrMemo(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; DocumentNo: Code[20]; PostingDate: Date; VATDate: Date)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchaseHeader.Init();
        PurchaseHeader.TransferFields(PurchAdvanceLetterHeader);
        CopyPayToSellFromAdvLetter(PurchaseHeader, PurchAdvanceLetterHeader);
        PurchaseHeader."VAT Date" := VATDate;

        // Create posted header
        with PurchCrMemoHdr do begin
            Init;
            TransferFields(PurchaseHeader);
            "No." := DocumentNo;
            "Posting Date" := PostingDate;
            "VAT Date" := VATDate;
            "Document Date" := PostingDate;
            "Letter No." := PurchAdvanceLetterHeader."No.";
            "User ID" := UserId;
            "No. Printed" := 0;
            "Prices Including VAT" := true;
            "Prepayment Credit Memo" := true;
            "Currency Factor" :=
              CurrExchRate.ExchangeRate(PostingDate, PurchaseHeader."Currency Code");
            OnCreateBlankCrMemoOnBeforeInsertPurchCrMemoHdr(PurchAdvanceLetterHeader, PurchCrMemoHdr);
            Insert;
        end;

        with PurchCrMemoLine do begin
            Init;
            "Document No." := PurchCrMemoHdr."No.";
            "Line No." := 10000;
            Description :=
              CopyStr(StrSubstNo(DescTxt, PurchAdvanceLetterHeader."No."), 1, MaxStrLen(Description));
            Insert;
        end;
    end;

    local procedure GetCrMemoDocNo(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date) DocumentNo: Code[20]
    var
        PurchaseAdvPaymentTemplate: Record "Purchase Adv. Payment Template";
    begin
        if PurchAdvanceLetterHeader."Template Code" <> '' then begin
            PurchaseAdvPaymentTemplate.Get(PurchAdvanceLetterHeader."Template Code");
            PurchaseAdvPaymentTemplate.TestField("Advance Credit Memo Nos.");
            DocumentNo :=
              NoSeriesMgt.GetNextNo(PurchaseAdvPaymentTemplate."Advance Credit Memo Nos.", PostingDate, true);
        end else begin
            PurchSetup.Get();
            PurchSetup.TestField("Advance Credit Memo Nos.");
            DocumentNo :=
              NoSeriesMgt.GetNextNo(PurchSetup."Advance Credit Memo Nos.", PostingDate, true);
        end;
    end;

    local procedure GetInvoiceDocNo(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date) DocumentNo: Code[20]
    var
        PurchaseAdvPaymentTemplate: Record "Purchase Adv. Payment Template";
    begin
        if PurchAdvanceLetterHeader."Template Code" <> '' then begin
            PurchaseAdvPaymentTemplate.Get(PurchAdvanceLetterHeader."Template Code");
            PurchaseAdvPaymentTemplate.TestField("Advance Invoice Nos.");
            DocumentNo :=
              NoSeriesMgt.GetNextNo(PurchaseAdvPaymentTemplate."Advance Invoice Nos.", PostingDate, true);
        end else begin
            PurchSetup.Get();
            PurchSetup.TestField("Advance Invoice Nos.");
            DocumentNo :=
              NoSeriesMgt.GetNextNo(PurchSetup."Advance Invoice Nos.", PostingDate, true);
        end;
    end;

    local procedure CopyPayToSellFromAdvLetter(var PurchaseHeader: Record "Purchase Header"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        with PurchaseHeader do begin
            "Buy-from Vendor No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
            "Buy-from Vendor Name" := PurchAdvanceLetterHeader."Pay-to Name";
            "Buy-from Vendor Name 2" := PurchAdvanceLetterHeader."Pay-to Name 2";
            "Buy-from Address" := PurchAdvanceLetterHeader."Pay-to Address";
            "Buy-from Address 2" := PurchAdvanceLetterHeader."Pay-to Address 2";
            "Buy-from City" := PurchAdvanceLetterHeader."Pay-to City";
            "Buy-from Contact" := PurchAdvanceLetterHeader."Pay-to Contact";
            "Buy-from Post Code" := PurchAdvanceLetterHeader."Pay-to Post Code";
            "Buy-from County" := PurchAdvanceLetterHeader."Pay-to County";
            "Buy-from Country/Region Code" := PurchAdvanceLetterHeader."Pay-to Country/Region Code";
        end;
    end;

    local procedure ReverseAmounts(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer")
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

    local procedure CheckExternalDocumentNumber(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; DocumentType: Option Invoice,"Credit Memo"): Boolean
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("External Document No.");
        case DocumentType of
            DocumentType::Invoice:
                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
            DocumentType::"Credit Memo":
                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
        end;
        VendLedgEntry.SetRange("External Document No.", PurchAdvanceLetterHeader."External Document No.");
        VendLedgEntry.SetRange("Vendor No.", PurchAdvanceLetterHeader."Pay-to Vendor No.");
        VendLedgEntry.SetRange(Reversed, false);
        if not VendLedgEntry.IsEmpty() then
            exit(false);

        case DocumentType of
            DocumentType::Invoice:
                begin
                    PurchInvHeader.Reset();
                    PurchInvHeader.SetCurrentKey("Vendor Invoice No.");
                    PurchInvHeader.SetRange("Vendor Invoice No.", PurchAdvanceLetterHeader."External Document No.");
                    PurchInvHeader.SetRange("Pay-to Vendor No.", PurchAdvanceLetterHeader."Pay-to Vendor No.");
                    if not PurchInvHeader.IsEmpty() then
                        exit(false);
                end;
            DocumentType::"Credit Memo":
                begin
                    PurchCrMemoHdr.Reset();
                    PurchCrMemoHdr.SetCurrentKey("Vendor Cr. Memo No.");
                    PurchCrMemoHdr.SetRange("Vendor Cr. Memo No.", PurchAdvanceLetterHeader."External Document No.");
                    PurchCrMemoHdr.SetRange("Pay-to Vendor No.", PurchAdvanceLetterHeader."Pay-to Vendor No.");
                    if not PurchCrMemoHdr.IsEmpty() then
                        exit(false);
                end;
        end;

        exit(true);
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLetterToGL(var GenJournalLine: Record "Gen. Journal Line"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVATCorrectionToGL(var GenJournalLine: Record "Gen. Journal Line"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVATCrMemoHeaderOnBeforeInsertPostVATPurchCrMemoHdr(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostRefundCorrectionOnAfterPurchAdvanceLetterLineSetFilter(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckAmountToRefund(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostRefundCorrToGLOnFillAdvanceRefundGenJnlLine(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostRefundCorrToGLOnBeforePostAdvanceRefundGenJnlLine(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostRefundCorrToGLOnBeforePostAdvancePaymentGenJnlLine(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVATCorrectionToGLOnBeforeModifyTempPurchAdvanceLetterEntry(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; BaseToDeductLCY: Decimal; var TempPurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchAdvanceOffsetVATAccount(VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; var PurchAdvanceOffsetVATAccount: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareGenJnlLine(PurchInvHeader: Record "Purch. Inv. Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalcPrepmOnAfterSetAdvanceLetterLineRelationFilters(PurchLine: Record "Purchase Line"; var AdvanceLetterLineRelation: Record "Advance Letter Line Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtLineAmount(TempPurchLine: Record "Purchase Line" temporary; LinkedRemAmtLine: Decimal; PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPrepmtLineAmount(TempPurchLine: Record "Purchase Line" temporary; PurchLine: Record "Purchase Line"; PriceInclVAT: Boolean; LinkedAmt: Decimal; LinkedRemAmtLine: Decimal; var PrepmtLineAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalcPrepm(TempPurchLine: Record "Purchase Line" temporary; PriceInclVAT: Boolean; LinkedAmt: Decimal; LinkedRemAmtLine: Decimal; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUnPostInvoiceCorrection(PurchInvHeader: Record "Purch. Inv. Header"; var IsConfirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentTypeAndNo(PurchInvHeader: Record "Purch. Inv. Header"; var DocType: Option " ",Order,Invoice; var DocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnPostInvoiceCorrectionOnAfterFindPurchAdvanceLetterEntry(PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry"; var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmtToDedOnPurchDoc(PurchHeader: Record "Purchase Header"; AdjustRelations: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemovePmtLinks(EntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillPurchAdvanceLetterLineAmounts(AdvanceLink: Record "Advance Link"; var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveDeductionEntriesOnBeforeInsertPurchAdvanceLetterEntry(var PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostVATCrMemoPrepareGL(var GenJournalLine: Record "Gen. Journal Line"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforeUnapply(VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindOpenVendLedgerEntry(PurchInvHeader: Record "Purch. Inv. Header"; var VendLedgEntry: Record "Vendor Ledger Entry"; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefundUnPostInvCorr(AdvanceLink: Record "Advance Link"; PurchInvHeader: Record "Purch. Inv. Header"; VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnPostInvCorrUpdtOnBeforeTempRefundUnPostInvCorrGL(VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreTransfAmountWithoutInvOnAfterSetAdvanceLinkFilters(var AdvanceLink: Record "Advance Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreTransfAmountWithoutInvOnBeforeModifyAdvanceLink(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var AdvanceLink: Record "Advance Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreTransfAmountWithoutInvOnAfterModifyAdvanceLink(AdvanceLink: Record "Advance Link"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransAmountWithoutInvOnAfterSetAdvanceLinkFilters(var AdvanceLink: Record "Advance Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransAmountWithoutInvOnBeforeModifyAdvanceLink(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var AdvanceLink: Record "Advance Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransAmountWithoutInvOnAfterModifyAdvanceLink(AdvanceLink: Record "Advance Link"; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdInvAmountToLineRelations(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; AmtDif: Decimal; var AdvanceLetterLineRelation: Record "Advance Letter Line Relation"; var TempPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderLineAmounts(var TempPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAdvanceEntryOnBeforeInsertTempPurchAdvanceLetterEntry(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var TempPurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempPurchAdvanceLetterEntryOnFillVATFieldsOfDeductionEntry(var TempPurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAdvanceInvLineBuf(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TempAdvanceLetterLineRelation: Record "Advance Letter Line Relation" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAdvanceInvLineBufOnBeforeInsertTempAdvanceLetterLineRelation(TempPurchLine: Record "Purchase Line" temporary; var TempAdvanceLetterLineRelation: Record "Advance Letter Line Relation" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLetter_SetInvHeaderOnBeforeInsertPurchInvHeader(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLetter_SetCrMemoHeaderOnBeforeInsertPurchCrMemoHeader(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostLetterPostToGL(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillTempVATAmountLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOpenPrepaymentLines(PurchHeader: Record "Purchase Header"; var IsChecked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchAdvanceLetterHeader(PurchHeader: Record "Purchase Header"; AdvanceTemplCode: Code[10]; var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLetterOnBeforeLetterCreatePurchAdvanceLetterLines(var TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary; var TempAdvanceLetterLineRelation: Record "Advance Letter Line Relation" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLetterOnBeforeInsertPurchAdvanceLetterLine(TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary; PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateBlankCrMemoOnBeforeInsertPurchCrMemoHdr(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPaymentCorrectionOnBeforePostAdvanceRefundRunWithCheck(VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATCorrection(PurchHeader: Record "Purchase Header"; TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterPurchAdvanceLetterEntryForCalcVATToDeduct(var PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry"; PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLetterOnBeforeModifyPurchAdvanceLetterHeader(PostingDate: Date; var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPaymentCorrection(PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary; var TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary; var DocNoForVATCorr: Code[20]; var InvoicedAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATCorrection_InsertLinesOnBeforeCalcVATAmounts(VATAmtToDeduct: Decimal; BaseToDeduct: Decimal; VATAmountLCY: Decimal; BaseToDeductLCY: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATCorrection_InsertLinesOnBeforeModifyTempVATAmountLine(var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvLineCorrectionOnAfterAdvanceLetterLineRelationSetFilters(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var AdvanceLetterLineRelation: Record "Advance Letter Line Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAdvLetterLineRelationDeductedAmountAndModify(var AdvanceLetterLineRelation: Record "Advance Letter Line Relation"; var AmountToDeduct: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostLetter_PreTestOnBeforeCheckDimIDComb(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;
}

