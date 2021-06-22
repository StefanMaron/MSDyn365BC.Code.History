codeunit 444 "Purchase-Post Prepayments"
{
    Permissions = TableData "Purchase Line" = imd,
                  TableData "G/L Register" = rimd,
                  TableData "Invoice Post. Buffer" = imd,
                  TableData "Vendor Posting Group" = imd,
                  TableData "Inventory Posting Group" = imd,
                  TableData "Purch. Inv. Header" = imd,
                  TableData "Purch. Inv. Line" = imd,
                  TableData "Purch. Cr. Memo Hdr." = imd,
                  TableData "Purch. Cr. Memo Line" = imd;
    TableNo = "Purchase Header";

    trigger OnRun()
    begin
        Execute(Rec);
    end;

    var
        Text000: Label 'is not within your range of allowed posting dates';
        Text001: Label 'There is nothing to post.';
        Text002: Label 'Posting Prepayment Lines   #2######\';
        Text003: Label '%1 %2 -> Invoice %3';
        Text004: Label 'Posting purchases and VAT  #3######\';
        Text005: Label 'Posting to vendors         #4######\';
        Text006: Label 'Posting to bal. account    #5######';
        Text011: Label '%1 %2 -> Credit Memo %3';
        Text012: Label 'Prepayment %1, %2 %3.';
        GLSetup: Record "General Ledger Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        GenPostingSetup: Record "General Posting Setup";
        TempGlobalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Text013: Label 'It is not possible to assign a prepayment amount of %1 to the purchase lines.';
        Text014: Label 'VAT Amount';
        Text015: Label '%1% VAT';
        Text016: Label 'The new prepayment amount must be between %1 and %2.';
        Text017: Label 'At least one line must have %1 > 0 to distribute prepayment amount.';
        text019: Label 'Invoice,Credit Memo';
        SuppressCommit: Boolean;
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        PreviewMode: Boolean;

    procedure SetDocumentType(DocumentType: Option ,,Invoice,"Credit Memo")
    begin
        PrepmtDocumentType := DocumentType;
    end;

    local procedure Execute(var PurchHeader: Record "Purchase Header")
    begin
        case PrepmtDocumentType of
            PrepmtDocumentType::Invoice:
                Invoice(PurchHeader);
            PrepmtDocumentType::"Credit Memo":
                CreditMemo(PurchHeader);
        end;
    end;

    procedure Invoice(var PurchHeader: Record "Purchase Header")
    var
        Handled: Boolean;
    begin
        OnBeforeInvoice(PurchHeader, Handled);
        if not Handled then
            Code(PurchHeader, 0);
    end;

    procedure CreditMemo(var PurchHeader: Record "Purchase Header")
    var
        Handled: Boolean;
    begin
        OnBeforeCreditMemo(PurchHeader, Handled);
        if not Handled then
            Code(PurchHeader, 1);
    end;

    local procedure "Code"(var PurchHeader2: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        SourceCodeSetup: Record "Source Code Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempPurchLines: Record "Purchase Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        PostingNoSeriesCode: Code[20];
        ModifyHeader: Boolean;
        CalcPmtDiscOnCrMemos: Boolean;
        PostingDescription: Text[100];
        GenJnlLineDocType: Integer;
        PrevLineNo: Integer;
        LineCount: Integer;
        PostedDocTabNo: Integer;
        LineNo: Integer;
    begin
        OnBeforePostPrepayments(PurchHeader2, DocumentType, SuppressCommit);

        PurchHeader := PurchHeader2;
        GLSetup.Get();
        PurchSetup.Get();
        with PurchHeader do begin
            CheckPrepmtDoc(PurchHeader, DocumentType);

            UpdateDocNos(PurchHeader, DocumentType, GenJnlLineDocNo, PostingNoSeriesCode, ModifyHeader);

            if not PreviewMode and ModifyHeader then begin
                Modify;
                if not SuppressCommit then
                    Commit();
            end;

            Window.Open(
              '#1#################################\\' +
              Text002 +
              Text004 +
              Text005 +
              Text006);
            Window.Update(1, StrSubstNo('%1 %2', SelectStr(1 + DocumentType, text019), "No."));

            SourceCodeSetup.Get();
            SrcCode := SourceCodeSetup.Purchases;
            if "Prepmt. Posting Description" <> '' then
                PostingDescription := "Prepmt. Posting Description"
            else
                PostingDescription :=
                  CopyStr(
                    StrSubstNo(Text012, SelectStr(1 + DocumentType, text019), "Document Type", "No."),
                    1, MaxStrLen("Posting Description"));

            // Create posted header
            if PurchSetup."Ext. Doc. No. Mandatory" then
                TestField("Vendor Invoice No.");
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        InsertPurchInvHeader(PurchInvHeader, PurchHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode);
                        GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                        PostedDocTabNo := DATABASE::"Purch. Inv. Header";
                        GenJnlLineExtDocNo := PurchInvHeader."Vendor Invoice No.";
                        Window.Update(1, StrSubstNo(Text003, "Document Type", "No.", PurchInvHeader."No."));
                    end;
                DocumentType::"Credit Memo":
                    begin
                        if PurchSetup."Ext. Doc. No. Mandatory" then
                            TestField("Vendor Cr. Memo No.");
                        CalcPmtDiscOnCrMemos := GetCalcPmtDiscOnCrMemos("Prepmt. Payment Terms Code");
                        InsertPurchCrMemoHeader(
                          PurchCrMemoHeader, PurchHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode,
                          CalcPmtDiscOnCrMemos);
                        GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                        PostedDocTabNo := DATABASE::"Purch. Cr. Memo Hdr.";
                        GenJnlLineExtDocNo := PurchCrMemoHeader."Vendor Cr. Memo No.";
                        Window.Update(1, StrSubstNo(Text011, "Document Type", "No.", PurchCrMemoHeader."No."));
                    end;
            end;
            // Reverse old lines
            if DocumentType = DocumentType::Invoice then begin
                GetPurchLinesToDeduct(PurchHeader, TempPurchLines);
                if not TempPurchLines.IsEmpty then
                    CalcVATAmountLines(PurchHeader, TempPurchLines, TempVATAmountLineDeduct, DocumentType::"Credit Memo");
            end;

            // Create Lines
            TempPrepmtInvLineBuffer.DeleteAll();
            CalcVATAmountLines(PurchHeader, PurchLine, TempVATAmountLine, DocumentType);
            TempVATAmountLine.DeductVATAmountLine(TempVATAmountLineDeduct);
            UpdateVATOnLines(PurchHeader, PurchLine, TempVATAmountLine, DocumentType);
            BuildInvLineBuffer(PurchHeader, PurchLine, DocumentType, TempPrepmtInvLineBuffer, true);
            TempPrepmtInvLineBuffer.Find('-');
            repeat
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);
                if TempPrepmtInvLineBuffer."Line No." <> 0 then
                    LineNo := PrevLineNo + TempPrepmtInvLineBuffer."Line No."
                else
                    LineNo := PrevLineNo + 10000;
                case DocumentType of
                    DocumentType::Invoice:
                        begin
                            InsertPurchInvLine(PurchInvHeader, LineNo, TempPrepmtInvLineBuffer, PurchHeader);
                            PostedDocTabNo := DATABASE::"Purch. Inv. Line";
                        end;
                    DocumentType::"Credit Memo":
                        begin
                            InsertPurchCrMemoLine(PurchCrMemoHeader, LineNo, TempPrepmtInvLineBuffer, PurchHeader);
                            PostedDocTabNo := DATABASE::"Purch. Cr. Memo Line";
                        end;
                end;
                PrevLineNo := LineNo;
                InsertExtendedText(
                  PostedDocTabNo, GenJnlLineDocNo, TempPrepmtInvLineBuffer."G/L Account No.", "Document Date", "Language Code", PrevLineNo);
            until TempPrepmtInvLineBuffer.Next = 0;

            if "Compress Prepayment" then
                case DocumentType of
                    DocumentType::Invoice:
                        CopyLineCommentLinesCompressedPrepayment("No.", DATABASE::"Purch. Inv. Header", PurchInvHeader."No.");
                    DocumentType::"Credit Memo":
                        CopyLineCommentLinesCompressedPrepayment("No.", DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHeader."No.");
                end;

            OnAfterCreateLinesOnBeforeGLPosting(PurchHeader, PurchInvHeader, PurchCrMemoHeader, TempPrepmtInvLineBuffer, DocumentType, LineNo);

            // G/L Posting
            LineCount := 0;
            if not "Compress Prepayment" then
                TempPrepmtInvLineBuffer.CompressBuffer;
            TempPrepmtInvLineBuffer.SetRange(Adjustment, false);
            TempPrepmtInvLineBuffer.FindSet(true);
            repeat
                if DocumentType = DocumentType::"Credit Memo" then
                    TempPrepmtInvLineBuffer.ReverseAmounts;
                RoundAmounts(PurchHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY);
                if "Currency Code" = '' then begin
                    AdjustInvLineBuffers(PurchHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, DocumentType);
                    TotalPrepmtInvLineBufferLCY := TotalPrepmtInvLineBuffer;
                end else
                    AdjustInvLineBuffers(PurchHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType);
                TempPrepmtInvLineBuffer.Modify();
            until TempPrepmtInvLineBuffer.Next = 0;

            TempPrepmtInvLineBuffer.Reset();
            TempPrepmtInvLineBuffer.SetCurrentKey(Adjustment);
            TempPrepmtInvLineBuffer.Find('+');
            repeat
                LineCount := LineCount + 1;
                Window.Update(3, LineCount);

                if TempPrepmtInvLineBuffer."VAT Calculation Type" =
                   TempPrepmtInvLineBuffer."VAT Calculation Type"::"Reverse Charge VAT"
                then
                    TempPrepmtInvLineBuffer.UpdateVATAmounts;

                PostPrepmtInvLineBuffer(
                  PurchHeader, TempPrepmtInvLineBuffer, DocumentType, PostingDescription,
                  GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
            until TempPrepmtInvLineBuffer.Next(-1) = 0;

            // Post vendor entry
            Window.Update(4, 1);
            PostVendorEntry(
              PurchHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType, PostingDescription,
              GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode, CalcPmtDiscOnCrMemos);

            UpdatePostedPurchaseDocument(DocumentType, GenJnlLineDocNo);

            // Balancing account
            if "Bal. Account No." <> '' then begin
                Window.Update(5, 1);
                VendLedgEntry.FindLast;
                PostBalancingEntry(
                  PurchHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, VendLedgEntry, DocumentType,
                  GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
            end;

            // Update lines & header
            UpdatePurchaseDocument(PurchHeader, PurchLine, DocumentType, GenJnlLineDocNo);
            if TestStatusIsNotPendingPrepayment then
                Status := Status::"Pending Prepayment";
            Modify;
        end;

        PurchHeader2 := PurchHeader;

        if PreviewMode then begin
            Window.Close;
            GenJnlPostPreview.ThrowError;
        end;

        OnAfterPostPrepayments(PurchHeader2, DocumentType, SuppressCommit, PurchInvHeader, PurchCrMemoHeader);
    end;

    procedure CheckPrepmtDoc(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        Vend: Record Vendor;
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        CheckDimensions: Codeunit "Check Dimensions";
    begin
        OnBeforeCheckPrepmtDoc(PurchHeader, DocumentType);
        with PurchHeader do begin
            TestField("Document Type", "Document Type"::Order);
            TestField("Buy-from Vendor No.");
            TestField("Pay-to Vendor No.");
            TestField("Posting Date");
            TestField("Document Date");
            if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                FieldError("Posting Date", Text000);

            if not CheckOpenPrepaymentLines(PurchHeader, DocumentType) then
                Error(Text001);
            CheckDimensions.CheckPurchPrepmtDim(PurchHeader);
            ErrorMessageMgt.Finish(RecordId);
            CheckPurchasePostRestrictions();
            Vend.Get("Buy-from Vendor No.");
            Vend.CheckBlockedVendOnDocs(Vend, true);
            if "Pay-to Vendor No." <> "Buy-from Vendor No." then begin
                Vend.Get("Pay-to Vendor No.");
                Vend.CheckBlockedVendOnDocs(Vend, true);
            end;
            OnAfterCheckPrepmtDoc(PurchHeader, DocumentType);
        end;
    end;

    local procedure UpdateDocNos(var PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean)
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        with PurchHeader do
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        TestField("Prepayment Due Date");
                        TestField("Prepmt. Cr. Memo No.", '');
                        if "Prepayment No." = '' then
                            if not PreviewMode then begin
                                TestField("Prepayment No. Series");
                                "Prepayment No." := NoSeriesMgt.GetNextNo("Prepayment No. Series", "Posting Date", true);
                                ModifyHeader := true;
                            end else
                                "Prepayment No." := '***';
                        DocNo := "Prepayment No.";
                        NoSeriesCode := "Prepayment No. Series";
                    end;
                DocumentType::"Credit Memo":
                    begin
                        TestField("Prepayment No.", '');
                        if "Prepmt. Cr. Memo No." = '' then
                            if not PreviewMode then begin
                                TestField("Prepmt. Cr. Memo No. Series");
                                "Prepmt. Cr. Memo No." := NoSeriesMgt.GetNextNo("Prepmt. Cr. Memo No. Series", "Posting Date", true);
                                ModifyHeader := true;
                            end else
                                "Prepmt. Cr. Memo No." := '***';
                        DocNo := "Prepmt. Cr. Memo No.";
                        NoSeriesCode := "Prepmt. Cr. Memo No. Series";
                    end;
            end;
    end;

    procedure CheckOpenPrepaymentLines(PurchHeader: Record "Purchase Header"; DocumentType: Option) Found: Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            ApplyFilter(PurchHeader, DocumentType, PurchLine);
            if Find('-') then
                repeat
                    if not Found then
                        Found := PrepmtAmount(PurchLine, DocumentType) <> 0;
                    if ("Prepayment VAT Identifier" = '') and ("Prepmt. Amt. Inv." = 0) then begin
                        UpdatePrepmtSetupFields;
                        Modify;
                    end;
                until Next = 0;
        end;
        exit(Found);
    end;

    local procedure RoundAmounts(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    var
        VAT: Boolean;
    begin
        TotalPrepmtInvLineBuf.IncrAmounts(PrepmtInvLineBuf);

        with PrepmtInvLineBuf do
            if PurchHeader."Currency Code" <> '' then begin
                VAT := Amount <> "Amount Incl. VAT";
                "Amount Incl. VAT" :=
                  AmountToLCY(PurchHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", TotalPrepmtInvLineBufLCY."Amount Incl. VAT");
                if VAT then
                    Amount := AmountToLCY(PurchHeader, TotalPrepmtInvLineBuf.Amount, TotalPrepmtInvLineBufLCY.Amount)
                else
                    Amount := "Amount Incl. VAT";
                "VAT Amount" := "Amount Incl. VAT" - Amount;
                if "VAT Base Amount" <> 0 then
                    "VAT Base Amount" := Amount;
            end;

        TotalPrepmtInvLineBufLCY.IncrAmounts(PrepmtInvLineBuf);

        OnAfterRoundAmounts(PurchHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
    end;

    local procedure AmountToLCY(PurchHeader: Record "Purchase Header"; TotalAmt: Decimal; PrevTotalAmt: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.Init();
        with PurchHeader do
            exit(
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", TotalAmt, "Currency Factor")) -
              PrevTotalAmt);
    end;

    local procedure AdjustInvLineBuffers(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo")
    var
        VATAdjustment: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        CalcPrepmtAmtInvLCYInLines(PurchHeader, PrepmtInvLineBuf, DocumentType, VATAdjustment);
        if Abs(VATAdjustment[VAT::Base]) > GLSetup."Amount Rounding Precision" then
            InsertCorrInvLineBuffer(PrepmtInvLineBuf, PurchHeader, VATAdjustment[VAT::Base])
        else
            if (VATAdjustment[VAT::Base] <> 0) or (VATAdjustment[VAT::Amount] <> 0) then begin
                PrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
                TotalPrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
            end;
    end;

    local procedure CalcPrepmtAmtInvLCYInLines(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; var VATAdjustment: array[2] of Decimal)
    var
        PurchLine: Record "Purchase Line";
        PrepmtInvBufAmount: array[2] of Decimal;
        TotalAmount: array[2] of Decimal;
        LineAmount: array[2] of Decimal;
        Ratio: array[2] of Decimal;
        PrepmtAmtReminder: array[2] of Decimal;
        PrepmtAmountRnded: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        PrepmtInvLineBuf.AmountsToArray(PrepmtInvBufAmount);
        if DocumentType = DocumentType::"Credit Memo" then
            ReverseDecArray(PrepmtInvBufAmount);

        TempGlobalPrepmtInvLineBuf.SetFilterOnPKey(PrepmtInvLineBuf);
        TempGlobalPrepmtInvLineBuf.CalcSums(Amount, "Amount Incl. VAT");
        TempGlobalPrepmtInvLineBuf.AmountsToArray(TotalAmount);
        for VAT := VAT::Base to VAT::Amount do
            if TotalAmount[VAT] = 0 then
                Ratio[VAT] := 0
            else
                Ratio[VAT] := PrepmtInvBufAmount[VAT] / TotalAmount[VAT];
        if TempGlobalPrepmtInvLineBuf.FindSet then
            repeat
                TempGlobalPrepmtInvLineBuf.AmountsToArray(LineAmount);
                PrepmtAmountRnded[VAT::Base] :=
                  CalcRoundedAmount(LineAmount[VAT::Base], Ratio[VAT::Base], PrepmtAmtReminder[VAT::Base]);
                PrepmtAmountRnded[VAT::Amount] :=
                  CalcRoundedAmount(LineAmount[VAT::Amount], Ratio[VAT::Amount], PrepmtAmtReminder[VAT::Amount]);

                PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", TempGlobalPrepmtInvLineBuf."Line No.");
                if DocumentType = DocumentType::"Credit Memo" then begin
                    VATAdjustment[VAT::Base] += PurchLine."Prepmt. Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Base];
                    PurchLine."Prepmt. Amount Inv. (LCY)" := 0;
                    VATAdjustment[VAT::Amount] += PurchLine."Prepmt. VAT Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Amount];
                    PurchLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
                end else begin
                    PurchLine."Prepmt. Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Base];
                    PurchLine."Prepmt. VAT Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Amount];
                end;
                PurchLine.Modify();
            until TempGlobalPrepmtInvLineBuf.Next = 0;
        TempGlobalPrepmtInvLineBuf.DeleteAll();
        ReverseDecArray(VATAdjustment);
    end;

    local procedure CalcRoundedAmount(LineAmount: Decimal; Ratio: Decimal; var Reminder: Decimal) RoundedAmount: Decimal
    var
        Amount: Decimal;
    begin
        Amount := Reminder + LineAmount * Ratio;
        RoundedAmount := Round(Amount);
        Reminder := Amount - RoundedAmount;
    end;

    local procedure ReverseDecArray(var DecArray: array[2] of Decimal)
    var
        Idx: Integer;
    begin
        for Idx := 1 to ArrayLen(DecArray) do
            DecArray[Idx] := -DecArray[Idx];
    end;

    local procedure InsertCorrInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PurchHeader: Record "Purchase Header"; VATBaseAdjustment: Decimal)
    var
        NewPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        SavedPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        AdjmtAmountACY: Decimal;
    begin
        SavedPrepmtInvLineBuf := PrepmtInvLineBuf;

        if PurchHeader."Currency Code" = '' then
            AdjmtAmountACY := VATBaseAdjustment
        else
            AdjmtAmountACY := 0;

        NewPrepmtInvLineBuf.FillAdjInvLineBuffer(
          PrepmtInvLineBuf,
          GetPrepmtAccNo(PrepmtInvLineBuf."Gen. Bus. Posting Group", PrepmtInvLineBuf."Gen. Prod. Posting Group"),
          VATBaseAdjustment, AdjmtAmountACY);
        PrepmtInvLineBuf.InsertInvLineBuffer(NewPrepmtInvLineBuf);

        NewPrepmtInvLineBuf.FillAdjInvLineBuffer(
          PrepmtInvLineBuf,
          GetCorrBalAccNo(PurchHeader, VATBaseAdjustment > 0),
          -VATBaseAdjustment, -AdjmtAmountACY);
        PrepmtInvLineBuf.InsertInvLineBuffer(NewPrepmtInvLineBuf);

        PrepmtInvLineBuf := SavedPrepmtInvLineBuf;
    end;

    local procedure GetPrepmtAccNo(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]): Code[20]
    begin
        if (GenBusPostingGroup <> GenPostingSetup."Gen. Bus. Posting Group") or
           (GenProdPostingGroup <> GenPostingSetup."Gen. Prod. Posting Group")
        then
            GenPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        exit(GenPostingSetup.GetPurchPrepmtAccount);
    end;

    procedure GetCorrBalAccNo(PurchHeader: Record "Purchase Header"; PositiveAmount: Boolean): Code[20]
    var
        BalAccNo: Code[20];
    begin
        if PurchHeader."Currency Code" = '' then
            BalAccNo := GetInvRoundingAccNo(PurchHeader."Vendor Posting Group")
        else
            BalAccNo := GetGainLossGLAcc(PurchHeader."Currency Code", PositiveAmount);
        exit(BalAccNo);
    end;

    procedure GetInvRoundingAccNo(VendorPostingGroup: Code[20]): Code[20]
    var
        VendPostingGr: Record "Vendor Posting Group";
        GLAcc: Record "G/L Account";
    begin
        VendPostingGr.Get(VendorPostingGroup);
        GLAcc.Get(VendPostingGr.GetInvRoundingAccount);
        exit(VendPostingGr."Invoice Rounding Account");
    end;

    local procedure GetGainLossGLAcc(CurrencyCode: Code[10]; PositiveAmount: Boolean): Code[20]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        if PositiveAmount then
            exit(Currency.GetRealizedGainsAccount);
        exit(Currency.GetRealizedLossesAccount);
    end;

    local procedure GetCurrencyAmountRoundingPrecision(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Initialize(CurrencyCode);
        Currency.TestField("Amount Rounding Precision");
        exit(Currency."Amount Rounding Precision");
    end;

    procedure UpdateVATOnLines(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
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
        RemainderExists: Boolean;
    begin
        Currency.Initialize(PurchHeader."Currency Code");

        with PurchLine do begin
            ApplyFilter(PurchHeader, DocumentType, PurchLine);
            LockTable();
            CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Inv.");
            PrepmtAmtToInvTotal := "Prepmt. Line Amount" - "Prepmt. Amt. Inv.";
            if Find('-') then
                repeat
                    PrepmtAmt := PrepmtAmount(PurchLine, DocumentType);
                    if PrepmtAmt <> 0 then begin
                        VATAmountLine.Get(
                          "Prepayment VAT Identifier", "Prepmt. VAT Calc. Type", "Prepayment Tax Group Code", false, PrepmtAmt >= 0);
                        OnUpdateVATOnLinesOnAfterVATAmountLineGet(VATAmountLine);
                        if VATAmountLine.Modified then begin
                            RemainderExists :=
                              TempVATAmountLineRemainder.Get(
                                "Prepayment VAT Identifier", "Prepmt. VAT Calc. Type", "Prepayment Tax Group Code", false, PrepmtAmt >= 0);
                            OnUpdateVATOnLinesOnAfterGetRemainder(TempVATAmountLineRemainder, RemainderExists);
                            if not RemainderExists then begin
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
                                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then begin
                                    VATAmount := PrepmtAmt;
                                    NewAmount := 0;
                                    NewVATBaseAmount := 0;
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
                                end;
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
                until Next = 0;
        end;

        OnAfterUpdateVATOnLines(PurchHeader, PurchLine, VATAmountLine, DocumentType);
    end;

    procedure CalcVATAmountLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    var
        Currency: Record Currency;
        NewAmount: Decimal;
        NewPrepmtVATDiffAmt: Decimal;
    begin
        Currency.Initialize(PurchHeader."Currency Code");

        VATAmountLine.DeleteAll();

        with PurchLine do begin
            ApplyFilter(PurchHeader, DocumentType, PurchLine);
            if Find('-') then
                repeat
                    NewAmount := PrepmtAmount(PurchLine, DocumentType);
                    if NewAmount <> 0 then begin
                        if DocumentType = DocumentType::Invoice then
                            NewAmount := "Prepmt. Line Amount";
                        if "Prepmt. VAT Calc. Type" in
                           ["VAT Calculation Type"::"Reverse Charge VAT", "VAT Calculation Type"::"Sales Tax"]
                        then
                            "VAT %" := 0;
                        if not VATAmountLine.Get(
                             "Prepayment VAT Identifier", "Prepmt. VAT Calc. Type", "Prepayment Tax Group Code", false, NewAmount >= 0)
                        then
                            VATAmountLine.InsertNewLine(
                              "Prepayment VAT Identifier", "Prepmt. VAT Calc. Type", "Prepayment Tax Group Code", false,
                              "Prepayment VAT %", NewAmount >= 0, true);

                        VATAmountLine."Line Amount" := VATAmountLine."Line Amount" + NewAmount;
                        NewPrepmtVATDiffAmt := PrepmtVATDiffAmount(PurchLine, DocumentType);
                        if DocumentType = DocumentType::Invoice then
                            NewPrepmtVATDiffAmt := "Prepayment VAT Difference" + "Prepmt VAT Diff. to Deduct" +
                              "Prepmt VAT Diff. Deducted";
                        VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + NewPrepmtVATDiffAmt;
                        VATAmountLine.Modify();
                    end;
                until Next = 0;
        end;

        VATAmountLine.UpdateLines(
          NewAmount, Currency, PurchHeader."Currency Factor", PurchHeader."Prices Including VAT",
          PurchHeader."VAT Base Discount %", PurchHeader."Tax Area Code", PurchHeader."Tax Liable", PurchHeader."Posting Date");

        OnAfterCalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, DocumentType);
    end;

    procedure SumPrepmt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; var TotalAmount: Decimal; var TotalVATAmount: Decimal; var VATAmountText: Text[30])
    var
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer";
        DifVATPct: Boolean;
        PrevVATPct: Decimal;
    begin
        CalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, 2);
        UpdateVATOnLines(PurchHeader, PurchLine, VATAmountLine, 2);
        BuildInvLineBuffer(PurchHeader, PurchLine, 2, TempPrepmtInvLineBuf, false);
        if TempPrepmtInvLineBuf.Find('-') then begin
            PrevVATPct := TempPrepmtInvLineBuf."VAT %";
            repeat
                RoundAmounts(PurchHeader, TempPrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
                if TempPrepmtInvLineBuf."VAT %" <> PrevVATPct then
                    DifVATPct := true;
            until TempPrepmtInvLineBuf.Next = 0;
        end;
        TotalAmount := TotalPrepmtInvLineBuf.Amount;
        TotalVATAmount := TotalPrepmtInvLineBuf."VAT Amount";
        if DifVATPct or (TempPrepmtInvLineBuf."VAT %" = 0) then
            VATAmountText := Text014
        else
            VATAmountText := StrSubstNo(Text015, PrevVATPct);
    end;

    procedure GetPurchLines(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var ToPurchLine: Record "Purchase Line")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        FromPurchLine: Record "Purchase Line";
        InvRoundingPurchLine: Record "Purchase Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalAmt: Decimal;
        NextLineNo: Integer;
    begin
        ApplyFilter(PurchHeader, DocumentType, FromPurchLine);
        if FromPurchLine.Find('-') then begin
            repeat
                ToPurchLine := FromPurchLine;
                ToPurchLine.Insert();
            until FromPurchLine.Next = 0;

            PurchSetup.Get();
            if PurchSetup."Invoice Rounding" then begin
                CalcVATAmountLines(PurchHeader, ToPurchLine, TempVATAmountLine, 2);
                UpdateVATOnLines(PurchHeader, ToPurchLine, TempVATAmountLine, 2);
                ToPurchLine.CalcSums("Prepmt. Amt. Incl. VAT");
                TotalAmt := ToPurchLine."Prepmt. Amt. Incl. VAT";
                ToPurchLine.FindLast;
                if InitInvoiceRoundingLine(PurchHeader, TotalAmt, InvRoundingPurchLine) then
                    with ToPurchLine do begin
                        NextLineNo := "Line No." + 1;
                        ToPurchLine := InvRoundingPurchLine;
                        "Line No." := NextLineNo;

                        if DocumentType <> DocumentType::"Credit Memo" then
                            "Prepmt. Line Amount" := "Line Amount"
                        else
                            "Prepmt. Amt. Inv." := "Line Amount";
                        "Prepmt. VAT Calc. Type" := "VAT Calculation Type";
                        "Prepayment VAT Identifier" := "VAT Identifier";
                        "Prepayment Tax Group Code" := "Tax Group Code";
                        "Prepayment VAT Identifier" := "VAT Identifier";
                        "Prepayment Tax Group Code" := "Tax Group Code";
                        "Prepayment VAT %" := "VAT %";
                        Insert;
                    end;
            end;
        end;
    end;

    local procedure BuildInvLineBuffer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Option; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; UpdateLines: Boolean)
    var
        PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferDummy: Record "Prepayment Inv. Line Buffer";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        with PurchHeader do begin
            TempGlobalPrepmtInvLineBuf.Reset();
            TempGlobalPrepmtInvLineBuf.DeleteAll();
            TempPurchaseLine.Reset();
            TempPurchaseLine.DeleteAll();
            PurchSetup.Get();
            ApplyFilter(PurchHeader, DocumentType, PurchLine);
            if PurchLine.Find('-') then
                repeat
                    if PrepmtAmount(PurchLine, DocumentType) <> 0 then begin
                        FillInvLineBuffer(PurchHeader, PurchLine, PrepmtInvLineBuf2);
                        if UpdateLines then
                            TempGlobalPrepmtInvLineBuf.CopyWithLineNo(PrepmtInvLineBuf2, PurchLine."Line No.");
                        PrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
                        if PurchSetup."Invoice Rounding" then
                            RoundAmounts(
                              PurchHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferDummy);
                        TempPurchaseLine := PurchLine;
                        TempPurchaseLine.Insert();
                    end;
                until PurchLine.Next = 0;
            if PurchSetup."Invoice Rounding" then
                if InsertInvoiceRounding(
                     PurchHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, PurchLine."Line No.")
                then
                    PrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
        end;
    end;

    procedure BuildInvLineBuffer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        BuildInvLineBuffer(PurchHeader, PurchLine, DocumentType, PrepmtInvLineBuf, false);
    end;

    procedure FillInvLineBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        with PrepmtInvLineBuf do begin
            Init;
            "G/L Account No." := GetPrepmtAccNo(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");

            if not PurchHeader."Compress Prepayment" then begin
                "Line No." := PurchLine."Line No.";
                Description := PurchLine.Description;
            end;

            CopyFromPurchLine(PurchLine);
            FillFromGLAcc(PurchHeader."Compress Prepayment");

            SetAmounts(
              PurchLine."Prepayment Amount", PurchLine."Prepmt. Amt. Incl. VAT", PurchLine."Prepayment Amount",
              PurchLine."Prepayment Amount", PurchLine."Prepayment Amount", PurchLine."Prepayment VAT Difference");

            "VAT Amount" := PurchLine."Prepmt. Amt. Incl. VAT" - PurchLine."Prepayment Amount";
            "VAT Amount (ACY)" := PurchLine."Prepmt. Amt. Incl. VAT" - PurchLine."Prepayment Amount";
            "VAT Base Before Pmt. Disc." := PurchLine."Prepayment Amount";
        end;

        OnAfterFillInvLineBuffer(PrepmtInvLineBuf, PurchLine, SuppressCommit);
    end;

    local procedure InsertInvoiceRounding(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PrevLineNo: Integer): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        if InitInvoiceRoundingLine(PurchHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", PurchLine) then begin
            CreateDimensions(PurchLine);
            with PrepmtInvLineBuf do begin
                Init;
                "Line No." := PrevLineNo + 10000;
                "Invoice Rounding" := true;
                "G/L Account No." := PurchLine."No.";

                CopyFromPurchLine(PurchLine);

                SetAmounts(
                  PurchLine."Line Amount", PurchLine."Amount Including VAT", PurchLine."Line Amount",
                  PurchLine."Prepayment Amount", PurchLine."Line Amount", 0);

                "VAT Amount" := PurchLine."Amount Including VAT" - PurchLine."Line Amount";
                "VAT Amount (ACY)" := PurchLine."Amount Including VAT" - PurchLine."Line Amount";
            end;
            exit(true);
        end;

        OnAfterInsertInvoiceRounding(PurchHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, PrevLineNo);
    end;

    local procedure InitInvoiceRoundingLine(PurchHeader: Record "Purchase Header"; TotalAmount: Decimal; var PurchLine: Record "Purchase Line"): Boolean
    var
        Currency: Record Currency;
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.Initialize(PurchHeader."Currency Code");
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalAmount -
            Round(
              TotalAmount,
              Currency."Invoice Rounding Precision",
              Currency.InvoiceRoundingDirection),
            Currency."Amount Rounding Precision");

        if InvoiceRoundingAmount = 0 then
            exit(false);

        with PurchLine do begin
            "Document Type" := PurchHeader."Document Type";
            "Document No." := PurchHeader."No.";
            "System-Created Entry" := true;
            Type := Type::"G/L Account";
            Validate("No.", GetInvRoundingAccNo(PurchHeader."Vendor Posting Group"));
            Validate(Quantity, 1);
            if PurchHeader."Prices Including VAT" then
                Validate("Direct Unit Cost", InvoiceRoundingAmount)
            else
                Validate(
                  "Direct Unit Cost",
                  Round(
                    InvoiceRoundingAmount /
                    (1 + (1 - PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                    Currency."Amount Rounding Precision"));
            "Prepayment Amount" := "Direct Unit Cost";
            Validate("Amount Including VAT", InvoiceRoundingAmount);
        end;
        exit(true);
    end;

    local procedure ApplyFilter(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var PurchLine: Record "Purchase Line")
    begin
        with PurchLine do begin
            Reset;
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            if DocumentType in [DocumentType::Invoice, DocumentType::Statistic] then
                SetFilter("Prepmt. Line Amount", '<>0')
            else
                SetFilter("Prepmt. Amt. Inv.", '<>0');
        end;

        OnAfterApplyFilter(PurchLine, PurchHeader, DocumentType);
    end;

    procedure PrepmtAmount(PurchLine: Record "Purchase Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        with PurchLine do
            case DocumentType of
                DocumentType::Statistic:
                    exit("Prepmt. Line Amount");
                DocumentType::Invoice:
                    exit("Prepmt. Line Amount" - "Prepmt. Amt. Inv.");
                else
                    exit("Prepmt. Amt. Inv." - "Prepmt Amt Deducted");
            end;
    end;

    local procedure CopyHeaderCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchSetup."Copy Comments Order to Invoice" then
            exit;

        with PurchCommentLine do
            case ToDocType of
                DATABASE::"Purch. Inv. Header":
                    CopyHeaderComments("Document Type"::Order, "Document Type"::"Posted Invoice", FromNumber, ToNumber);
                DATABASE::"Purch. Cr. Memo Hdr.":
                    CopyHeaderComments("Document Type"::Order, "Document Type"::"Posted Credit Memo", FromNumber, ToNumber);
            end;
    end;

    local procedure CopyLineCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20]; FromLineNo: Integer; ToLineNo: Integer)
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchSetup."Copy Comments Order to Invoice" then
            exit;

        with PurchCommentLine do
            case ToDocType of
                DATABASE::"Purch. Inv. Header":
                    CopyLineComments("Document Type"::Order, "Document Type"::"Posted Invoice", FromNumber, ToNumber, FromLineNo, ToLineNo);
                DATABASE::"Purch. Cr. Memo Hdr.":
                    CopyLineComments("Document Type"::Order, "Document Type"::"Posted Credit Memo", FromNumber, ToNumber, FromLineNo, ToLineNo);
            end;
    end;

    local procedure CopyLineCommentLinesCompressedPrepayment(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchSetup."Copy Comments Order to Invoice" then
            exit;

        with PurchCommentLine do
            case ToDocType of
                DATABASE::"Purch. Inv. Header":
                    CopyLineCommentsFromPurchaseLines(
                      "Document Type"::Order, "Document Type"::"Posted Invoice", FromNumber, ToNumber, TempPurchaseLine);
                DATABASE::"Purch. Cr. Memo Hdr.":
                    CopyLineCommentsFromPurchaseLines(
                      "Document Type"::Order, "Document Type"::"Posted Credit Memo", FromNumber, ToNumber, TempPurchaseLine);
            end;
    end;

    local procedure InsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer)
    var
        TempExtTextLine: Record "Extended Text Line" temporary;
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TransferExtText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
    begin
        TransferExtText.PrepmtGetAnyExtText(GLAccNo, TabNo, DocDate, LanguageCode, TempExtTextLine);
        if TempExtTextLine.Find('-') then begin
            NextLineNo := PrevLineNo + 10000;
            repeat
                case TabNo of
                    DATABASE::"Purch. Inv. Line":
                        begin
                            PurchInvLine.Init();
                            PurchInvLine."Document No." := DocNo;
                            PurchInvLine."Line No." := NextLineNo;
                            PurchInvLine.Description := TempExtTextLine.Text;
                            PurchInvLine.Insert();
                        end;
                    DATABASE::"Purch. Cr. Memo Line":
                        begin
                            PurchCrMemoLine.Init();
                            PurchCrMemoLine."Document No." := DocNo;
                            PurchCrMemoLine."Line No." := NextLineNo;
                            PurchCrMemoLine.Description := TempExtTextLine.Text;
                            PurchCrMemoLine.Insert();
                        end;
                end;
                PrevLineNo := NextLineNo;
                NextLineNo := NextLineNo + 10000;
            until TempExtTextLine.Next = 0;
        end;
    end;

    local procedure PostPrepmtInvLineBuffer(PurchHeader: Record "Purchase Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Option; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              PurchHeader."Posting Date", PurchHeader."Document Date", PostingDescription,
              PrepmtInvLineBuffer."Global Dimension 1 Code", PrepmtInvLineBuffer."Global Dimension 2 Code",
              PrepmtInvLineBuffer."Dimension Set ID", PurchHeader."Reason Code");

            CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);
            CopyFromPurchHeaderPrepmt(PurchHeader);
            CopyFromPrepmtInvoiceBuffer(PrepmtInvLineBuffer);

            Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";
            if not PrepmtInvLineBuffer.Adjustment then
                "Gen. Posting Type" := "Gen. Posting Type"::Purchase;

            OnBeforePostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit);
            RunGenJnlPostLine(GenJnlLine);
            OnAfterPostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure PostVendorEntry(PurchHeader: Record "Purchase Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Option; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDisc: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              PurchHeader."Posting Date", PurchHeader."Document Date", PostingDescription,
              PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
              PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

            CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

            CopyFromPurchHeaderPrepmtPost(PurchHeader, (DocumentType = DocumentType::Invoice) or CalcPmtDisc);

            Amount := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
            "Source Currency Amount" := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
            "Amount (LCY)" := -TotalPrepmtInvLineBufferLCY."Amount Incl. VAT";
            "Sales/Purch. (LCY)" := -TotalPrepmtInvLineBufferLCY.Amount;
            "Profit (LCY)" := -TotalPrepmtInvLineBufferLCY.Amount;

            Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

            OnBeforePostVendorEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostVendorEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
        end;
    end;

    local procedure PostBalancingEntry(PurchHeader: Record "Purchase Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; var VendLedgEntry: Record "Vendor Ledger Entry"; DocumentType: Option Invoice,"Credit Memo"; DocType: Option; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."Posting Description",
              PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
              PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

            if DocType = "Document Type"::"Credit Memo" then
                CopyDocumentFields("Document Type"::Refund, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode)
            else
                CopyDocumentFields("Document Type"::Payment, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

            CopyFromPurchHeaderPrepmtPost(PurchHeader, false);
            if PurchHeader."Bal. Account Type" = PurchHeader."Bal. Account Type"::"Bank Account" then
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := PurchHeader."Bal. Account No.";

            Amount := TotalPrepmtInvLineBuffer."Amount Incl. VAT" + VendLedgEntry."Remaining Pmt. Disc. Possible";
            "Source Currency Amount" := Amount;
            VendLedgEntry.CalcFields(Amount);
            if VendLedgEntry.Amount = 0 then
                "Amount (LCY)" := TotalPrepmtInvLineBufferLCY."Amount Incl. VAT"
            else
                "Amount (LCY)" :=
                  TotalPrepmtInvLineBufferLCY."Amount Incl. VAT" +
                  Round(VendLedgEntry."Remaining Pmt. Disc. Possible" / VendLedgEntry."Adjusted Currency Factor");

            Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

            "Applies-to Doc. Type" := DocType;
            "Applies-to Doc. No." := DocNo;

            OnBeforePostBalancingEntry(GenJnlLine, VendLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostBalancingEntry(GenJnlLine, VendLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
        end;
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    procedure UpdatePrepmtAmountOnPurchLines(PurchHeader: Record "Purchase Header"; NewTotalPrepmtAmount: Decimal)
    var
        Currency: Record Currency;
        PurchLine: Record "Purchase Line";
        TotalLineAmount: Decimal;
        TotalPrepmtAmount: Decimal;
        TotalPrepmtAmtInv: Decimal;
        LastLineNo: Integer;
    begin
        Currency.Initialize(PurchHeader."Currency Code");

        with PurchLine do begin
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Line Amount", '<>0');
            SetFilter("Prepayment %", '<>0');
            LockTable();
            if Find('-') then
                repeat
                    TotalLineAmount := TotalLineAmount + "Line Amount";
                    TotalPrepmtAmtInv := TotalPrepmtAmtInv + "Prepmt. Amt. Inv.";
                    LastLineNo := "Line No.";
                until Next = 0
            else
                Error(Text017, FieldCaption("Prepayment %"));
            if TotalLineAmount = 0 then
                Error(Text013, NewTotalPrepmtAmount);
            if not (NewTotalPrepmtAmount in [TotalPrepmtAmtInv .. TotalLineAmount]) then
                Error(Text016, TotalPrepmtAmtInv, TotalLineAmount);
            if Find('-') then
                repeat
                    if "Line No." <> LastLineNo then
                        Validate(
                          "Prepmt. Line Amount",
                          Round(
                            NewTotalPrepmtAmount * "Line Amount" / TotalLineAmount,
                            Currency."Amount Rounding Precision"))
                    else
                        Validate("Prepmt. Line Amount", NewTotalPrepmtAmount - TotalPrepmtAmount);
                    TotalPrepmtAmount := TotalPrepmtAmount + "Prepmt. Line Amount";
                    Modify;
                until Next = 0;
        end;
    end;

    local procedure CreateDimensions(var PurchLine: Record "Purchase Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := DATABASE::"Work Center";
        No[1] := PurchLine."Work Center No.";
        TableID[2] := DATABASE::"G/L Account";
        No[2] := PurchLine."No.";
        TableID[3] := DATABASE::Job;
        No[3] := PurchLine."Job No.";
        TableID[4] := DATABASE::"Responsibility Center";
        No[4] := PurchLine."Responsibility Center";
        PurchLine."Shortcut Dimension 1 Code" := '';
        PurchLine."Shortcut Dimension 2 Code" := '';
        PurchLine."Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            PurchLine, 0, TableID, No, SourceCodeSetup.Purchases,
            PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code", PurchLine."Dimension Set ID", DATABASE::Vendor);
    end;

    procedure GetPurchLinesToDeduct(PurchHeader: Record "Purchase Header"; var PurchLines: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        ApplyFilter(PurchHeader, 1, PurchLine);
        if PurchLine.FindSet then
            repeat
                if (PrepmtAmount(PurchLine, 0) <> 0) and (PrepmtAmount(PurchLine, 1) <> 0) then begin
                    PurchLines := PurchLine;
                    PurchLines.Insert();
                end;
            until PurchLine.Next = 0;
    end;

    local procedure PrepmtVATDiffAmount(PurchLine: Record "Purchase Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        with PurchLine do
            case DocumentType of
                DocumentType::Statistic:
                    exit("Prepayment VAT Difference");
                DocumentType::Invoice:
                    exit("Prepayment VAT Difference");
                else
                    exit("Prepmt VAT Diff. to Deduct");
            end;
    end;

    local procedure UpdatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocNo: Code[20])
    begin
        with PurchaseHeader do begin
            PurchLine.Reset();
            PurchLine.SetRange("Document Type", "Document Type");
            PurchLine.SetRange("Document No.", "No.");
            if DocumentType = DocumentType::Invoice then begin
                "Last Prepayment No." := GenJnlLineDocNo;
                "Prepayment No." := '';
                PurchLine.SetFilter("Prepmt. Line Amount", '<>0');
                if PurchLine.FindSet(true) then
                    repeat
                        if PurchLine."Prepmt. Line Amount" <> PurchLine."Prepmt. Amt. Inv." then begin
                            PurchLine."Prepmt. Amt. Inv." := PurchLine."Prepmt. Line Amount";
                            PurchLine."Prepmt. Amount Inv. Incl. VAT" := PurchLine."Prepmt. Amt. Incl. VAT";
                            PurchLine.CalcPrepaymentToDeduct;
                            PurchLine."Prepmt VAT Diff. to Deduct" :=
                              PurchLine."Prepmt VAT Diff. to Deduct" + PurchLine."Prepayment VAT Difference";
                            PurchLine."Prepayment VAT Difference" := 0;
                            PurchLine.Modify();
                        end;
                    until PurchLine.Next = 0;
            end else begin
                "Last Prepmt. Cr. Memo No." := GenJnlLineDocNo;
                "Prepmt. Cr. Memo No." := '';
                PurchLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
                if PurchLine.FindSet(true) then
                    repeat
                        PurchLine."Prepmt. Amt. Inv." := PurchLine."Prepmt Amt Deducted";
                        if "Prices Including VAT" then
                            PurchLine."Prepmt. Amount Inv. Incl. VAT" := PurchLine."Prepmt. Amt. Inv."
                        else
                            PurchLine."Prepmt. Amount Inv. Incl. VAT" :=
                              Round(
                                PurchLine."Prepmt. Amt. Inv." * (100 + PurchLine."Prepayment VAT %") / 100,
                                GetCurrencyAmountRoundingPrecision(PurchLine."Currency Code"));
                        PurchLine."Prepmt. Amt. Incl. VAT" := PurchLine."Prepmt. Amount Inv. Incl. VAT";
                        PurchLine."Prepayment Amount" := PurchLine."Prepmt. Amt. Inv.";
                        PurchLine."Prepmt Amt to Deduct" := 0;
                        PurchLine."Prepmt VAT Diff. to Deduct" := 0;
                        PurchLine."Prepayment VAT Difference" := 0;
                        PurchLine.Modify();
                    until PurchLine.Next = 0;
            end;
        end;
    end;

    local procedure UpdatePostedPurchaseDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        case DocumentType of
            DocumentType::Invoice:
                begin
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
                    VendorLedgerEntry.SetRange("Document No.", DocumentNo);
                    VendorLedgerEntry.FindFirst;
                    PurchInvHeader.Get(DocumentNo);
                    PurchInvHeader."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
                    PurchInvHeader.Modify();
                end;
            DocumentType::"Credit Memo":
                begin
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
                    VendorLedgerEntry.SetRange("Document No.", DocumentNo);
                    VendorLedgerEntry.FindFirst;
                    PurchCrMemoHdr.Get(DocumentNo);
                    PurchCrMemoHdr."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
                    PurchCrMemoHdr.Modify();
                end;
        end;

        OnAfterUpdatePostedPurchDocument(DocumentType, DocumentNo, SuppressCommit);
    end;

    local procedure InsertPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    begin
        with PurchHeader do begin
            PurchInvHeader.Init();
            PurchInvHeader.TransferFields(PurchHeader);
            PurchInvHeader."Posting Description" := PostingDescription;
            PurchInvHeader."Payment Terms Code" := "Prepmt. Payment Terms Code";
            PurchInvHeader."Due Date" := "Prepayment Due Date";
            PurchInvHeader."Pmt. Discount Date" := "Prepmt. Pmt. Discount Date";
            PurchInvHeader."Payment Discount %" := "Prepmt. Payment Discount %";
            PurchInvHeader."No." := GenJnlLineDocNo;
            PurchInvHeader."Pre-Assigned No. Series" := '';
            PurchInvHeader."Source Code" := SrcCode;
            PurchInvHeader."User ID" := UserId;
            PurchInvHeader."No. Printed" := 0;
            PurchInvHeader."Prepayment Invoice" := true;
            PurchInvHeader."Prepayment Order No." := "No.";
            PurchInvHeader."No. Series" := PostingNoSeriesCode;
            OnBeforePurchInvHeaderInsert(PurchInvHeader, PurchHeader, SuppressCommit);
            PurchInvHeader.Insert();
            CopyHeaderCommentLines("No.", DATABASE::"Purch. Inv. Header", GenJnlLineDocNo);
            OnAfterPurchInvHeaderInsert(PurchInvHeader, PurchHeader, SuppressCommit);
        end;
    end;

    local procedure InsertPurchCrMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchHeader: Record "Purchase Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    begin
        with PurchHeader do begin
            PurchCrMemoHdr.Init();
            PurchCrMemoHdr.TransferFields(PurchHeader);
            PurchCrMemoHdr."Payment Terms Code" := "Prepmt. Payment Terms Code";
            PurchCrMemoHdr."Pmt. Discount Date" := "Prepmt. Pmt. Discount Date";
            PurchCrMemoHdr."Payment Discount %" := "Prepmt. Payment Discount %";
            if ("Prepmt. Payment Terms Code" <> '') and not CalcPmtDiscOnCrMemos then begin
                PurchCrMemoHdr."Payment Discount %" := 0;
                PurchCrMemoHdr."Pmt. Discount Date" := 0D;
            end;
            PurchCrMemoHdr."Posting Description" := PostingDescription;
            PurchCrMemoHdr."Due Date" := "Prepayment Due Date";
            PurchCrMemoHdr."No." := GenJnlLineDocNo;
            PurchCrMemoHdr."Pre-Assigned No. Series" := '';
            PurchCrMemoHdr."Source Code" := SrcCode;
            PurchCrMemoHdr."User ID" := UserId;
            PurchCrMemoHdr."No. Printed" := 0;
            PurchCrMemoHdr."Prepayment Credit Memo" := true;
            PurchCrMemoHdr."Prepayment Order No." := "No.";
            PurchCrMemoHdr.Correction := GLSetup."Mark Cr. Memos as Corrections";
            PurchCrMemoHdr."No. Series" := PostingNoSeriesCode;
            OnBeforePurchCrMemoHeaderInsert(PurchCrMemoHdr, PurchHeader, SuppressCommit);
            PurchCrMemoHdr.Insert();
            CopyHeaderCommentLines("No.", DATABASE::"Purch. Cr. Memo Hdr.", GenJnlLineDocNo);
            OnAfterPurchCrMemoHeaderInsert(PurchCrMemoHdr, PurchHeader, SuppressCommit);
        end;
    end;

    local procedure GetCalcPmtDiscOnCrMemos(PrepmtPmtTermsCode: Code[10]): Boolean
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PrepmtPmtTermsCode = '' then
            exit(false);
        PaymentTerms.Get(PrepmtPmtTermsCode);
        exit(PaymentTerms."Calc. Pmt. Disc. on Cr. Memos");
    end;

    local procedure InsertPurchInvLine(PurchInvHeader: Record "Purch. Inv. Header"; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchaseHeader: Record "Purchase Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        with PrepmtInvLineBuffer do begin
            PurchInvLine.Init();
            PurchInvLine."Document No." := PurchInvHeader."No.";
            PurchInvLine."Line No." := LineNo;
            PurchInvLine."Buy-from Vendor No." := PurchInvHeader."Buy-from Vendor No.";
            PurchInvLine."Pay-to Vendor No." := PurchInvHeader."Pay-to Vendor No.";
            PurchInvLine.Type := PurchInvLine.Type::"G/L Account";
            PurchInvLine."No." := "G/L Account No.";
            PurchInvLine."Posting Date" := PurchInvHeader."Posting Date";
            PurchInvLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
            PurchInvLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
            PurchInvLine."Dimension Set ID" := "Dimension Set ID";
            PurchInvLine.Description := Description;
            PurchInvLine.Quantity := 1;
            if PurchInvHeader."Prices Including VAT" then begin
                PurchInvLine."Direct Unit Cost" := "Amount Incl. VAT";
                PurchInvLine."Line Amount" := "Amount Incl. VAT";
            end else begin
                PurchInvLine."Direct Unit Cost" := Amount;
                PurchInvLine."Line Amount" := Amount;
            end;
            PurchInvLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            PurchInvLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            PurchInvLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            PurchInvLine."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
            PurchInvLine."VAT %" := "VAT %";
            PurchInvLine.Amount := Amount;
            PurchInvLine."VAT Difference" := "VAT Difference";
            PurchInvLine."Amount Including VAT" := "Amount Incl. VAT";
            PurchInvLine."VAT Calculation Type" := "VAT Calculation Type";
            PurchInvLine."VAT Base Amount" := "VAT Base Amount";
            PurchInvLine."VAT Identifier" := "VAT Identifier";
            PurchInvLine."Job No." := "Job No.";
            PurchInvLine."Job Task No." := "Job Task No.";
            OnBeforePurchInvLineInsert(PurchInvLine, PurchInvHeader, PrepmtInvLineBuffer, SuppressCommit);
            PurchInvLine.Insert();
            if not PurchaseHeader."Compress Prepayment" then
                CopyLineCommentLines(
                  PurchaseHeader."No.", DATABASE::"Purch. Inv. Header", PurchInvHeader."No.", "Line No.", LineNo);
            OnAfterPurchInvLineInsert(PurchInvLine, PurchInvHeader, PrepmtInvLineBuffer, SuppressCommit);
        end;
    end;

    local procedure InsertPurchCrMemoLine(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        with PrepmtInvLineBuffer do begin
            PurchCrMemoLine.Init();
            PurchCrMemoLine."Document No." := PurchCrMemoHdr."No.";
            PurchCrMemoLine."Line No." := LineNo;
            PurchCrMemoLine."Buy-from Vendor No." := PurchCrMemoHdr."Buy-from Vendor No.";
            PurchCrMemoLine."Pay-to Vendor No." := PurchCrMemoHdr."Pay-to Vendor No.";
            PurchCrMemoLine.Type := PurchCrMemoLine.Type::"G/L Account";
            PurchCrMemoLine."No." := "G/L Account No.";
            PurchCrMemoLine."Posting Date" := PurchCrMemoHdr."Posting Date";
            PurchCrMemoLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
            PurchCrMemoLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
            PurchCrMemoLine."Dimension Set ID" := "Dimension Set ID";
            PurchCrMemoLine.Description := Description;
            PurchCrMemoLine.Quantity := 1;
            if PurchCrMemoHdr."Prices Including VAT" then begin
                PurchCrMemoLine."Direct Unit Cost" := "Amount Incl. VAT";
                PurchCrMemoLine."Line Amount" := "Amount Incl. VAT";
            end else begin
                PurchCrMemoLine."Direct Unit Cost" := Amount;
                PurchCrMemoLine."Line Amount" := Amount;
            end;
            PurchCrMemoLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            PurchCrMemoLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            PurchCrMemoLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            PurchCrMemoLine."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
            PurchCrMemoLine."VAT %" := "VAT %";
            PurchCrMemoLine.Amount := Amount;
            PurchCrMemoLine."VAT Difference" := "VAT Difference";
            PurchCrMemoLine."Amount Including VAT" := "Amount Incl. VAT";
            PurchCrMemoLine."VAT Calculation Type" := "VAT Calculation Type";
            PurchCrMemoLine."VAT Base Amount" := "VAT Base Amount";
            PurchCrMemoLine."VAT Identifier" := "VAT Identifier";
            PurchCrMemoLine."Job No." := "Job No.";
            PurchCrMemoLine."Job Task No." := "Job Task No.";
            OnBeforePurchCrMemoLineInsert(PurchCrMemoLine, PurchCrMemoHdr, PrepmtInvLineBuffer, SuppressCommit);
            PurchCrMemoLine.Insert();
            if not PurchaseHeader."Compress Prepayment" then
                CopyLineCommentLines(
                  PurchaseHeader."No.", DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHdr."No.", "Line No.", LineNo);
            OnAfterPurchCrMemoLineInsert(PurchCrMemoLine, PurchCrMemoHdr, PrepmtInvLineBuffer, SuppressCommit);
        end;
    end;

    procedure GetPreviewMode(): Boolean
    begin
        exit(PreviewMode);
    end;

    procedure GetSuppressCommit(): Boolean
    begin
        exit(SuppressCommit);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [Scope('OnPrem')]
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyFilter(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPrepmtDoc(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLinesOnBeforeGLPosting(var PurchaseHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; DocumentType: Option; var LastLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PurchLine: Record "Purchase Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvoiceRounding(PurchaseHeader: Record "Purchase Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var PrevLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepayments(var PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepaymentsOnBeforeThrowPreviewModeError(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmounts(PurchaseHeader: Record "Purchase Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostedPurchDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtDoc(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoice(var PurchaseHeader: Record "Purchase Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreditMemo(var PurchaseHeader: Record "Purchase Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepayments(var PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterGetRemainder(var VATAmountLineRemainder: Record "VAT Amount Line"; var RemainderExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterVATAmountLineGet(var VATAmountLine: Record "VAT Amount Line")
    begin
    end;
}

