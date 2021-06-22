codeunit 442 "Sales-Post Prepayments"
{
    Permissions = TableData "Sales Line" = imd,
                  TableData "Invoice Post. Buffer" = imd,
                  TableData "Sales Invoice Header" = imd,
                  TableData "Sales Invoice Line" = imd,
                  TableData "Sales Cr.Memo Header" = imd,
                  TableData "Sales Cr.Memo Line" = imd,
                  TableData "General Posting Setup" = imd;
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        Execute(Rec);
    end;

    var
        Text000: Label 'is not within your range of allowed posting dates';
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GenPostingSetup: Record "General Posting Setup";
        Text001: Label 'There is nothing to post.';
        Text002: Label 'Posting Prepayment Lines   #2######\';
        Text003: Label '%1 %2 -> Invoice %3';
        Text004: Label 'Posting sales and VAT      #3######\';
        Text005: Label 'Posting to customers       #4######\';
        Text006: Label 'Posting to bal. account    #5######';
        TempGlobalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Text011: Label '%1 %2 -> Credit Memo %3';
        Text012: Label 'Prepayment %1, %2 %3.';
        Text013: Label 'It is not possible to assign a prepayment amount of %1 to the sales lines.';
        Text014: Label 'VAT Amount';
        Text015: Label '%1% VAT';
        Text016: Label 'The new prepayment amount must be between %1 and %2.';
        Text017: Label 'At least one line must have %1 > 0 to distribute prepayment amount.';
        Text018: Label 'must be positive when %1 is not 0';
        Text019: Label 'Invoice,Credit Memo';
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        SuppressCommit: Boolean;
        PreviewMode: Boolean;

    procedure SetDocumentType(DocumentType: Option ,,Invoice,"Credit Memo")
    begin
        PrepmtDocumentType := DocumentType;
    end;

    local procedure Execute(var SalesHeader: Record "Sales Header")
    begin
        case PrepmtDocumentType of
            PrepmtDocumentType::Invoice:
                Invoice(SalesHeader);
            PrepmtDocumentType::"Credit Memo":
                CreditMemo(SalesHeader);
        end;
    end;

    procedure Invoice(var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeInvoice(SalesHeader, Handled);
        if not Handled then
            Code(SalesHeader, 0);
    end;

    procedure CreditMemo(var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeCreditMemo(SalesHeader, Handled);
        if not Handled then
            Code(SalesHeader, 1);
    end;

    local procedure "Code"(var SalesHeader2: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        SourceCodeSetup: Record "Source Code Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempSalesLines: Record "Sales Line" temporary;
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
        OnBeforePostPrepayments(SalesHeader2, DocumentType, SuppressCommit, PreviewMode);

        SalesHeader := SalesHeader2;
        GLSetup.Get();
        SalesSetup.Get();
        with SalesHeader do begin
            CheckPrepmtDoc(SalesHeader, DocumentType);

            UpdateDocNos(SalesHeader, DocumentType, GenJnlLineDocNo, PostingNoSeriesCode, ModifyHeader);

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
            Window.Update(1, StrSubstNo('%1 %2', SelectStr(1 + DocumentType, Text019), "No."));

            SourceCodeSetup.Get();
            SrcCode := SourceCodeSetup.Sales;
            if "Prepmt. Posting Description" <> '' then
                PostingDescription := "Prepmt. Posting Description"
            else
                PostingDescription :=
                  CopyStr(
                    StrSubstNo(Text012, SelectStr(1 + DocumentType, Text019), "Document Type", "No."),
                    1, MaxStrLen("Posting Description"));

            // Create posted header
            if SalesSetup."Ext. Doc. No. Mandatory" then
                TestField("External Document No.");
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        InsertSalesInvHeader(SalesInvHeader, SalesHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode);
                        GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                        PostedDocTabNo := DATABASE::"Sales Invoice Header";
                        Window.Update(1, StrSubstNo(Text003, "Document Type", "No.", SalesInvHeader."No."));
                    end;
                DocumentType::"Credit Memo":
                    begin
                        CalcPmtDiscOnCrMemos := GetCalcPmtDiscOnCrMemos("Prepmt. Payment Terms Code");
                        InsertSalesCrMemoHeader(
                          SalesCrMemoHeader, SalesHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode,
                          CalcPmtDiscOnCrMemos);
                        GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                        PostedDocTabNo := DATABASE::"Sales Cr.Memo Header";
                        Window.Update(1, StrSubstNo(Text011, "Document Type", "No.", SalesCrMemoHeader."No."));
                    end;
            end;
            GenJnlLineExtDocNo := "External Document No.";
            // Reverse old lines
            if DocumentType = DocumentType::Invoice then begin
                GetSalesLinesToDeduct(SalesHeader, TempSalesLines);
                if not TempSalesLines.IsEmpty then
                    CalcVATAmountLines(SalesHeader, TempSalesLines, TempVATAmountLineDeduct, DocumentType::"Credit Memo");
            end;

            // Create Lines
            TempPrepmtInvLineBuffer.DeleteAll();
            CalcVATAmountLines(SalesHeader, SalesLine, TempVATAmountLine, DocumentType);
            TempVATAmountLine.DeductVATAmountLine(TempVATAmountLineDeduct);
            UpdateVATOnLines(SalesHeader, SalesLine, TempVATAmountLine, DocumentType);
            BuildInvLineBuffer(SalesHeader, SalesLine, DocumentType, TempPrepmtInvLineBuffer, true);
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
                            InsertSalesInvLine(SalesInvHeader, LineNo, TempPrepmtInvLineBuffer, SalesHeader);
                            PostedDocTabNo := DATABASE::"Sales Invoice Line";
                        end;
                    DocumentType::"Credit Memo":
                        begin
                            InsertSalesCrMemoLine(SalesCrMemoHeader, LineNo, TempPrepmtInvLineBuffer, SalesHeader);
                            PostedDocTabNo := DATABASE::"Sales Cr.Memo Line";
                        end;
                end;
                PrevLineNo := LineNo;
                InsertExtendedText(
                  PostedDocTabNo, GenJnlLineDocNo, TempPrepmtInvLineBuffer."G/L Account No.", "Document Date", "Language Code", PrevLineNo);
            until TempPrepmtInvLineBuffer.Next = 0;

            if "Compress Prepayment" then
                case DocumentType of
                    DocumentType::Invoice:
                        CopyLineCommentLinesCompressedPrepayment("No.", DATABASE::"Sales Invoice Header", SalesInvHeader."No.");
                    DocumentType::"Credit Memo":
                        CopyLineCommentLinesCompressedPrepayment("No.", DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.");
                end;

            OnAfterCreateLinesOnBeforeGLPosting(SalesHeader, SalesInvHeader, SalesCrMemoHeader, TempPrepmtInvLineBuffer, DocumentType, LineNo);

            // G/L Posting
            LineCount := 0;
            if not "Compress Prepayment" then
                TempPrepmtInvLineBuffer.CompressBuffer;
            TempPrepmtInvLineBuffer.SetRange(Adjustment, false);
            TempPrepmtInvLineBuffer.FindSet(true);
            repeat
                if DocumentType = DocumentType::Invoice then
                    TempPrepmtInvLineBuffer.ReverseAmounts;
                RoundAmounts(SalesHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY);
                if "Currency Code" = '' then begin
                    AdjustInvLineBuffers(SalesHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, DocumentType);
                    TotalPrepmtInvLineBufferLCY := TotalPrepmtInvLineBuffer;
                end else
                    AdjustInvLineBuffers(SalesHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType);
                TempPrepmtInvLineBuffer.Modify();
            until TempPrepmtInvLineBuffer.Next = 0;

            TempPrepmtInvLineBuffer.Reset();
            TempPrepmtInvLineBuffer.SetCurrentKey(Adjustment);
            TempPrepmtInvLineBuffer.Find('+');
            repeat
                LineCount := LineCount + 1;
                Window.Update(3, LineCount);

                PostPrepmtInvLineBuffer(
                  SalesHeader, TempPrepmtInvLineBuffer, DocumentType, PostingDescription,
                  GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
            until TempPrepmtInvLineBuffer.Next(-1) = 0;

            // Post customer entry
            Window.Update(4, 1);
            PostCustomerEntry(
              SalesHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType, PostingDescription,
              GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode, CalcPmtDiscOnCrMemos);

            UpdatePostedSalesDocument(DocumentType, GenJnlLineDocNo);

            // Balancing account
            if "Bal. Account No." <> '' then begin
                Window.Update(5, 1);
                CustLedgEntry.FindLast;
                PostBalancingEntry(
                  SalesHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, CustLedgEntry, DocumentType,
                  PostingDescription, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
            end;

            // Update lines & header
            UpdateSalesDocument(SalesHeader, SalesLine, DocumentType, GenJnlLineDocNo);
            if TestStatusIsNotPendingPrepayment then
                Status := Status::"Pending Prepayment";
            Modify;
        end;

        OnAfterPostPrepaymentsOnBeforeThrowPreviewModeError(SalesHeader, SalesInvHeader, SalesCrMemoHeader, GenJnlPostLine, PreviewMode);

        if PreviewMode then begin
            Window.Close;
            OnBeforeThrowPreviewError(SalesHeader);
            GenJnlPostPreview.ThrowError;
        end;

        SalesHeader2 := SalesHeader;

        OnAfterPostPrepayments(SalesHeader2, DocumentType, SuppressCommit, SalesInvHeader, SalesCrMemoHeader);
    end;

    procedure CheckPrepmtDoc(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        Cust: Record Customer;
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        CheckDimensions: Codeunit "Check Dimensions";
    begin
        OnBeforeCheckPrepmtDoc(SalesHeader, DocumentType, SuppressCommit);
        with SalesHeader do begin
            TestField("Document Type", "Document Type"::Order);
            TestField("Sell-to Customer No.");
            TestField("Bill-to Customer No.");
            TestField("Posting Date");
            TestField("Document Date");
            if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                FieldError("Posting Date", Text000);

            if not CheckOpenPrepaymentLines(SalesHeader, DocumentType) then
                Error(Text001);

            CheckDimensions.CheckSalesPrepmtDim(SalesHeader);
            ErrorMessageMgt.Finish(RecordId);
            CheckSalesPostRestrictions();
            Cust.Get("Sell-to Customer No.");
            Cust.CheckBlockedCustOnDocs(Cust, PrepmtDocTypeToDocType(DocumentType), false, true);
            if "Bill-to Customer No." <> "Sell-to Customer No." then begin
                Cust.Get("Bill-to Customer No.");
                Cust.CheckBlockedCustOnDocs(Cust, PrepmtDocTypeToDocType(DocumentType), false, true);
            end;
            OnAfterCheckPrepmtDoc(SalesHeader, DocumentType, SuppressCommit);
        end;
    end;

    local procedure UpdateDocNos(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean)
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDocNos(SalesHeader, DocumentType, DocNo, NoSeriesCode, ModifyHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        ModifyHeader := false;
        with SalesHeader do
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

    procedure CheckOpenPrepaymentLines(SalesHeader: Record "Sales Header"; DocumentType: Option) Found: Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            ApplyFilter(SalesHeader, DocumentType, SalesLine);
            if Find('-') then
                repeat
                    if not Found then
                        Found := PrepmtAmount(SalesLine, DocumentType) <> 0;
                    if ("Prepayment VAT Identifier" = '') and ("Prepmt. Amt. Inv." = 0) then begin
                        UpdatePrepmtSetupFields;
                        Modify;
                    end;
                until Next = 0;
        end;
        exit(Found);
    end;

    local procedure RoundAmounts(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    var
        VAT: Boolean;
    begin
        TotalPrepmtInvLineBuf.IncrAmounts(PrepmtInvLineBuf);

        with PrepmtInvLineBuf do
            if SalesHeader."Currency Code" <> '' then begin
                VAT := Amount <> "Amount Incl. VAT";
                "Amount Incl. VAT" :=
                  AmountToLCY(SalesHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", TotalPrepmtInvLineBufLCY."Amount Incl. VAT");
                if VAT then
                    Amount := AmountToLCY(SalesHeader, TotalPrepmtInvLineBuf.Amount, TotalPrepmtInvLineBufLCY.Amount)
                else
                    Amount := "Amount Incl. VAT";
                "VAT Amount" := "Amount Incl. VAT" - Amount;
                if "VAT Base Amount" <> 0 then
                    "VAT Base Amount" := Amount;
            end;

        OnRoundAmountsOnBeforeIncrAmounts(SalesHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);

        TotalPrepmtInvLineBufLCY.IncrAmounts(PrepmtInvLineBuf);

        OnAfterRoundAmounts(SalesHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
    end;

    local procedure AmountToLCY(SalesHeader: Record "Sales Header"; TotalAmt: Decimal; PrevTotalAmt: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.Init();
        with SalesHeader do
            exit(
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", TotalAmt, "Currency Factor")) -
              PrevTotalAmt);
    end;

    local procedure BuildInvLineBuffer(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; var TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary; UpdateLines: Boolean)
    var
        PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferDummy: Record "Prepayment Inv. Line Buffer";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesHeader do begin
            TempGlobalPrepmtInvLineBuf.Reset();
            TempGlobalPrepmtInvLineBuf.DeleteAll();
            TempSalesLine.Reset();
            TempSalesLine.DeleteAll();
            SalesSetup.Get();
            ApplyFilter(SalesHeader, DocumentType, SalesLine);
            if SalesLine.Find('-') then
                repeat
                    if PrepmtAmount(SalesLine, DocumentType) <> 0 then begin
                        CheckSalesLineIsNegative(SalesHeader, SalesLine);

                        FillInvLineBuffer(SalesHeader, SalesLine, PrepmtInvLineBuf2);
                        if UpdateLines then
                            TempGlobalPrepmtInvLineBuf.CopyWithLineNo(PrepmtInvLineBuf2, SalesLine."Line No.");
                        TempPrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
                        if SalesSetup."Invoice Rounding" then
                            RoundAmounts(SalesHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferDummy);
                        TempSalesLine := SalesLine;
                        TempSalesLine.Insert();
                    end;
                until SalesLine.Next = 0;
            if SalesSetup."Invoice Rounding" then
                if InsertInvoiceRounding(
                     SalesHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, SalesLine."Line No.")
                then
                    TempPrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
        end;

        OnAfterBuildInvLineBuffer(TempPrepmtInvLineBuf);
    end;

    procedure BuildInvLineBuffer(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        BuildInvLineBuffer(SalesHeader, SalesLine, DocumentType, PrepmtInvLineBuf, false);
    end;

    local procedure AdjustInvLineBuffers(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo")
    var
        VATAdjustment: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        CalcPrepmtAmtInvLCYInLines(SalesHeader, PrepmtInvLineBuf, DocumentType, VATAdjustment);
        if Abs(VATAdjustment[VAT::Base]) > GLSetup."Amount Rounding Precision" then
            InsertCorrInvLineBuffer(PrepmtInvLineBuf, SalesHeader, VATAdjustment[VAT::Base])
        else
            if (VATAdjustment[VAT::Base] <> 0) or (VATAdjustment[VAT::Amount] <> 0) then begin
                PrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
                TotalPrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
            end;
    end;

    local procedure CalcPrepmtAmtInvLCYInLines(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; var VATAdjustment: array[2] of Decimal)
    var
        SalesLine: Record "Sales Line";
        PrepmtInvBufAmount: array[2] of Decimal;
        TotalAmount: array[2] of Decimal;
        LineAmount: array[2] of Decimal;
        Ratio: array[2] of Decimal;
        PrepmtAmtReminder: array[2] of Decimal;
        PrepmtAmountRnded: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        PrepmtInvLineBuf.AmountsToArray(PrepmtInvBufAmount);
        if DocumentType = DocumentType::Invoice then
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

                SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", TempGlobalPrepmtInvLineBuf."Line No.");
                if DocumentType = DocumentType::"Credit Memo" then begin
                    VATAdjustment[VAT::Base] += SalesLine."Prepmt. Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Base];
                    SalesLine."Prepmt. Amount Inv. (LCY)" := 0;
                    VATAdjustment[VAT::Amount] += SalesLine."Prepmt. VAT Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Amount];
                    SalesLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
                end else begin
                    SalesLine."Prepmt. Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Base];
                    SalesLine."Prepmt. VAT Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Amount];
                end;
                SalesLine.Modify();
            until TempGlobalPrepmtInvLineBuf.Next = 0;
        TempGlobalPrepmtInvLineBuf.DeleteAll();
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

    local procedure InsertCorrInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header"; VATBaseAdjustment: Decimal)
    var
        NewPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        SavedPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        AdjmtAmountACY: Decimal;
    begin
        SavedPrepmtInvLineBuf := PrepmtInvLineBuf;

        if SalesHeader."Currency Code" = '' then
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
          GetCorrBalAccNo(SalesHeader, VATBaseAdjustment > 0),
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
        exit(GenPostingSetup.GetSalesPrepmtAccount);
    end;

    procedure GetCorrBalAccNo(SalesHeader: Record "Sales Header"; PositiveAmount: Boolean): Code[20]
    var
        BalAccNo: Code[20];
    begin
        if SalesHeader."Currency Code" = '' then
            BalAccNo := GetInvRoundingAccNo(SalesHeader."Customer Posting Group")
        else
            BalAccNo := GetGainLossGLAcc(SalesHeader."Currency Code", PositiveAmount);
        exit(BalAccNo);
    end;

    procedure GetInvRoundingAccNo(CustomerPostingGroup: Code[20]): Code[20]
    var
        CustPostingGr: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
    begin
        CustPostingGr.Get(CustomerPostingGroup);
        GLAcc.Get(CustPostingGr.GetInvRoundingAccount);
        exit(CustPostingGr."Invoice Rounding Account");
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

    procedure FillInvLineBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        with PrepmtInvLineBuf do begin
            Init;
            OnBeforeFillInvLineBuffer(PrepmtInvLineBuf, SalesHeader, SalesLine);
            "G/L Account No." := GetPrepmtAccNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

            if not SalesHeader."Compress Prepayment" then begin
                "Line No." := SalesLine."Line No.";
                Description := SalesLine.Description;
            end;

            CopyFromSalesLine(SalesLine);
            FillFromGLAcc(SalesHeader."Compress Prepayment");

            SetAmounts(
              SalesLine."Prepayment Amount", SalesLine."Prepmt. Amt. Incl. VAT", SalesLine."Prepayment Amount",
              SalesLine."Prepayment Amount", SalesLine."Prepayment Amount", SalesLine."Prepayment VAT Difference");

            "VAT Amount" := SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount";
            "VAT Amount (ACY)" := SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount";
            "VAT Base Before Pmt. Disc." := -SalesLine."Prepayment Amount";
        end;

        OnAfterFillInvLineBuffer(PrepmtInvLineBuf, SalesLine);
    end;

    local procedure InsertInvoiceRounding(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PrevLineNo: Integer): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if InitInvoiceRoundingLine(SalesHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", SalesLine) then begin
            CreateDimensions(SalesLine);
            with PrepmtInvLineBuf do begin
                Init;
                "Line No." := PrevLineNo + 10000;
                "Invoice Rounding" := true;
                "G/L Account No." := SalesLine."No.";

                CopyFromSalesLine(SalesLine);
                "Gen. Bus. Posting Group" := SalesHeader."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := SalesHeader."VAT Bus. Posting Group";

                SetAmounts(
                  SalesLine."Line Amount", SalesLine."Amount Including VAT", SalesLine."Line Amount",
                  SalesLine."Prepayment Amount", SalesLine."Line Amount", 0);

                "VAT Amount" := SalesLine."Amount Including VAT" - SalesLine."Line Amount";
                "VAT Amount (ACY)" := SalesLine."Amount Including VAT" - SalesLine."Line Amount";
            end;
            OnAfterInsertInvoiceRounding(SalesHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, PrevLineNo);
            exit(true);
        end;
    end;

    local procedure InitInvoiceRoundingLine(SalesHeader: Record "Sales Header"; TotalAmount: Decimal; var SalesLine: Record "Sales Line"): Boolean
    var
        Currency: Record Currency;
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.Initialize(SalesHeader."Currency Code");
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

        with SalesLine do begin
            SetHideValidationDialog(true);
            "Document Type" := SalesHeader."Document Type";
            "Document No." := SalesHeader."No.";
            "System-Created Entry" := true;
            Type := Type::"G/L Account";
            Validate("No.", GetInvRoundingAccNo(SalesHeader."Customer Posting Group"));
            Validate(Quantity, 1);
            if SalesHeader."Prices Including VAT" then
                Validate("Unit Price", InvoiceRoundingAmount)
            else
                Validate(
                  "Unit Price",
                  Round(
                    InvoiceRoundingAmount /
                    (1 + (1 - SalesHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                    Currency."Amount Rounding Precision"));
            "Prepayment Amount" := "Unit Price";
            Validate("Amount Including VAT", InvoiceRoundingAmount);
        end;
        exit(true);
    end;

    local procedure CopyHeaderCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        if not SalesSetup."Copy Comments Order to Invoice" then
            exit;

        with SalesCommentLine do
            case ToDocType of
                DATABASE::"Sales Invoice Header":
                    CopyHeaderComments("Document Type"::Order, "Document Type"::"Posted Invoice", FromNumber, ToNumber);
                DATABASE::"Sales Cr.Memo Header":
                    CopyHeaderComments("Document Type"::Order, "Document Type"::"Posted Credit Memo", FromNumber, ToNumber);
            end;
    end;

    local procedure CopyLineCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20]; FromLineNo: Integer; ToLineNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        if not SalesSetup."Copy Comments Order to Invoice" then
            exit;

        with SalesCommentLine do
            case ToDocType of
                DATABASE::"Sales Invoice Header":
                    CopyLineComments("Document Type"::Order, "Document Type"::"Posted Invoice", FromNumber, ToNumber, FromLineNo, ToLineNo);
                DATABASE::"Sales Cr.Memo Header":
                    CopyLineComments("Document Type"::Order, "Document Type"::"Posted Credit Memo", FromNumber, ToNumber, FromLineNo, ToLineNo);
            end;
    end;

    local procedure CopyLineCommentLinesCompressedPrepayment(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        if not SalesSetup."Copy Comments Order to Invoice" then
            exit;

        with SalesCommentLine do
            case ToDocType of
                DATABASE::"Sales Invoice Header":
                    CopyLineCommentsFromSalesLines(
                      "Document Type"::Order, "Document Type"::"Posted Invoice", FromNumber, ToNumber, TempSalesLine);
                DATABASE::"Sales Cr.Memo Header":
                    CopyLineCommentsFromSalesLines(
                      "Document Type"::Order, "Document Type"::"Posted Credit Memo", FromNumber, ToNumber, TempSalesLine);
            end;
    end;

    local procedure InsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer)
    var
        TempExtTextLine: Record "Extended Text Line" temporary;
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TransferExtText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
    begin
        TransferExtText.PrepmtGetAnyExtText(GLAccNo, TabNo, DocDate, LanguageCode, TempExtTextLine);
        if TempExtTextLine.Find('-') then begin
            NextLineNo := PrevLineNo + 10000;
            repeat
                case TabNo of
                    DATABASE::"Sales Invoice Line":
                        begin
                            SalesInvLine.Init();
                            SalesInvLine."Document No." := DocNo;
                            SalesInvLine."Line No." := NextLineNo;
                            SalesInvLine.Description := TempExtTextLine.Text;
                            SalesInvLine.Insert();
                        end;
                    DATABASE::"Sales Cr.Memo Line":
                        begin
                            SalesCrMemoLine.Init();
                            SalesCrMemoLine."Document No." := DocNo;
                            SalesCrMemoLine."Line No." := NextLineNo;
                            SalesCrMemoLine.Description := TempExtTextLine.Text;
                            SalesCrMemoLine.Insert();
                        end;
                end;
                PrevLineNo := NextLineNo;
                NextLineNo := NextLineNo + 10000;
            until TempExtTextLine.Next = 0;
        end;
    end;

    procedure UpdateVATOnLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
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
        Currency.Initialize(SalesHeader."Currency Code");

        with SalesLine do begin
            ApplyFilter(SalesHeader, DocumentType, SalesLine);
            LockTable();
            CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Inv.");
            PrepmtAmtToInvTotal := "Prepmt. Line Amount" - "Prepmt. Amt. Inv.";
            if FindSet then
                repeat
                    PrepmtAmt := PrepmtAmount(SalesLine, DocumentType);
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

                            if SalesHeader."Prices Including VAT" then begin
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
                                    NewAmount * (1 - SalesHeader."VAT Base Discount %" / 100),
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
                                        NewAmount * (1 - SalesHeader."VAT Base Discount %" / 100),
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
                            OnUpdateVATOnLinesOnBeforeSalesLineModify(SalesHeader, SalesLine, TempVATAmountLineRemainder, NewAmount, NewAmountIncludingVAT, NewVATBaseAmount);
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

        OnAfterUpdateVATOnLines(SalesHeader, SalesLine, VATAmountLine, DocumentType);
    end;

    procedure CalcVATAmountLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    var
        Currency: Record Currency;
        NewAmount: Decimal;
        NewPrepmtVATDiffAmt: Decimal;
    begin
        Currency.Initialize(SalesHeader."Currency Code");

        VATAmountLine.DeleteAll();

        with SalesLine do begin
            ApplyFilter(SalesHeader, DocumentType, SalesLine);
            if Find('-') then
                repeat
                    NewAmount := PrepmtAmount(SalesLine, DocumentType);
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
                        NewPrepmtVATDiffAmt := PrepmtVATDiffAmount(SalesLine, DocumentType);
                        if DocumentType = DocumentType::Invoice then
                            NewPrepmtVATDiffAmt := "Prepayment VAT Difference" + "Prepmt VAT Diff. to Deduct" +
                              "Prepmt VAT Diff. Deducted";
                        VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + NewPrepmtVATDiffAmt;
                        VATAmountLine.Modify();
                    end;
                until Next = 0;
        end;

        VATAmountLine.UpdateLines(
          NewAmount, Currency, SalesHeader."Currency Factor", SalesHeader."Prices Including VAT",
          SalesHeader."VAT Base Discount %", SalesHeader."Tax Area Code", SalesHeader."Tax Liable", SalesHeader."Posting Date");

        OnAfterCalcVATAmountLines(SalesHeader, SalesLine, VATAmountLine, DocumentType);
    end;

    procedure SumPrepmt(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; var TotalAmount: Decimal; var TotalVATAmount: Decimal; var VATAmountText: Text[30])
    var
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer";
        DifVATPct: Boolean;
        PrevVATPct: Decimal;
    begin
        CalcVATAmountLines(SalesHeader, SalesLine, VATAmountLine, 2);
        UpdateVATOnLines(SalesHeader, SalesLine, VATAmountLine, 2);
        BuildInvLineBuffer(SalesHeader, SalesLine, 2, TempPrepmtInvLineBuf, false);
        if TempPrepmtInvLineBuf.Find('-') then begin
            PrevVATPct := TempPrepmtInvLineBuf."VAT %";
            repeat
                RoundAmounts(SalesHeader, TempPrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
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

    procedure GetSalesLines(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var ToSalesLine: Record "Sales Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        FromSalesLine: Record "Sales Line";
        InvRoundingSalesLine: Record "Sales Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalAmt: Decimal;
        NextLineNo: Integer;
    begin
        ApplyFilter(SalesHeader, DocumentType, FromSalesLine);
        if FromSalesLine.Find('-') then begin
            repeat
                ToSalesLine := FromSalesLine;
                ToSalesLine.Insert();
            until FromSalesLine.Next = 0;

            SalesSetup.Get();
            if SalesSetup."Invoice Rounding" then begin
                CalcVATAmountLines(SalesHeader, ToSalesLine, TempVATAmountLine, 2);
                UpdateVATOnLines(SalesHeader, ToSalesLine, TempVATAmountLine, 2);
                ToSalesLine.CalcSums("Prepmt. Amt. Incl. VAT");
                TotalAmt := ToSalesLine."Prepmt. Amt. Incl. VAT";
                ToSalesLine.FindLast;
                if InitInvoiceRoundingLine(SalesHeader, TotalAmt, InvRoundingSalesLine) then
                    with ToSalesLine do begin
                        NextLineNo := "Line No." + 1;
                        ToSalesLine := InvRoundingSalesLine;
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

    local procedure ApplyFilter(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var SalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            Reset;
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            if DocumentType in [DocumentType::Invoice, DocumentType::Statistic] then
                SetFilter("Prepmt. Line Amount", '<>0')
            else
                SetFilter("Prepmt. Amt. Inv.", '<>0');
        end;

        OnAfterApplyFilter(SalesLine, SalesHeader, DocumentType);
    end;

    procedure PrepmtAmount(SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        with SalesLine do
            case DocumentType of
                DocumentType::Statistic:
                    exit("Prepmt. Line Amount");
                DocumentType::Invoice:
                    exit("Prepmt. Line Amount" - "Prepmt. Amt. Inv.");
                else
                    exit("Prepmt. Amt. Inv." - "Prepmt Amt Deducted");
            end;
    end;

    local procedure PostPrepmtInvLineBuffer(SalesHeader: Record "Sales Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Option; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", PostingDescription,
              PrepmtInvLineBuffer."Global Dimension 1 Code", PrepmtInvLineBuffer."Global Dimension 2 Code",
              PrepmtInvLineBuffer."Dimension Set ID", SalesHeader."Reason Code");

            CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);
            CopyFromSalesHeaderPrepmt(SalesHeader);
            CopyFromPrepmtInvoiceBuffer(PrepmtInvLineBuffer);

            if not PrepmtInvLineBuffer.Adjustment then
                "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            Correction :=
              (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

            OnBeforePostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit);
            RunGenJnlPostLine(GenJnlLine);
            OnAfterPostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure PostCustomerEntry(SalesHeader: Record "Sales Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Option; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDisc: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", PostingDescription,
              SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
              SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

            CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

            CopyFromSalesHeaderPrepmtPost(SalesHeader, (DocumentType = DocumentType::Invoice) or CalcPmtDisc);

            Amount := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
            "Source Currency Amount" := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
            "Amount (LCY)" := -TotalPrepmtInvLineBufferLCY."Amount Incl. VAT";
            "Sales/Purch. (LCY)" := -TotalPrepmtInvLineBufferLCY.Amount;
            "Profit (LCY)" := -TotalPrepmtInvLineBufferLCY.Amount;

            Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

            OnBeforePostCustomerEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostCustomerEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
        end;
    end;

    local procedure PostBalancingEntry(SalesHeader: Record "Sales Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CustLedgEntry: Record "Cust. Ledger Entry"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Option; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", PostingDescription,
              SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
              SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

            if DocType = "Document Type"::"Credit Memo" then
                CopyDocumentFields("Document Type"::Refund, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode)
            else
                CopyDocumentFields("Document Type"::Payment, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

            CopyFromSalesHeaderPrepmtPost(SalesHeader, false);
            if SalesHeader."Bal. Account Type" = SalesHeader."Bal. Account Type"::"Bank Account" then
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := SalesHeader."Bal. Account No.";

            Amount := TotalPrepmtInvLineBuffer."Amount Incl. VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
            "Source Currency Amount" := Amount;
            CustLedgEntry.CalcFields(Amount);
            if CustLedgEntry.Amount = 0 then
                "Amount (LCY)" := TotalPrepmtInvLineBufferLCY."Amount Incl. VAT"
            else
                "Amount (LCY)" :=
                  TotalPrepmtInvLineBufferLCY."Amount Incl. VAT" +
                  Round(
                    CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");

            Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

            "Applies-to Doc. Type" := DocType;
            "Applies-to Doc. No." := DocNo;

            OnBeforePostBalancingEntry(GenJnlLine, CustLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostBalancingEntry(GenJnlLine, CustLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
        end;
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    procedure UpdatePrepmtAmountOnSaleslines(SalesHeader: Record "Sales Header"; NewTotalPrepmtAmount: Decimal)
    var
        Currency: Record Currency;
        SalesLine: Record "Sales Line";
        TotalLineAmount: Decimal;
        TotalPrepmtAmount: Decimal;
        TotalPrepmtAmtInv: Decimal;
        LastLineNo: Integer;
    begin
        Currency.Initialize(SalesHeader."Currency Code");

        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
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

    local procedure CreateDimensions(var SalesLine: Record "Sales Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := DATABASE::"G/L Account";
        No[1] := SalesLine."No.";
        TableID[2] := DATABASE::Job;
        No[2] := SalesLine."Job No.";
        TableID[3] := DATABASE::"Responsibility Center";
        No[3] := SalesLine."Responsibility Center";
        SalesLine."Shortcut Dimension 1 Code" := '';
        SalesLine."Shortcut Dimension 2 Code" := '';
        SalesLine."Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            SalesLine, 0, TableID, No, SourceCodeSetup.Sales,
            SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code", SalesLine."Dimension Set ID", DATABASE::Customer);
    end;

    local procedure PrepmtDocTypeToDocType(DocumentType: Option Invoice,"Credit Memo"): Integer
    begin
        case DocumentType of
            DocumentType::Invoice:
                exit(2);
            DocumentType::"Credit Memo":
                exit(3);
        end;
        exit(2);
    end;

    procedure GetSalesLinesToDeduct(SalesHeader: Record "Sales Header"; var SalesLines: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
    begin
        ApplyFilter(SalesHeader, 1, SalesLine);
        if SalesLine.FindSet then
            repeat
                if (PrepmtAmount(SalesLine, 0) <> 0) and (PrepmtAmount(SalesLine, 1) <> 0) then begin
                    SalesLines := SalesLine;
                    SalesLines.Insert();
                end;
            until SalesLine.Next = 0;
    end;

    local procedure PrepmtVATDiffAmount(SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        with SalesLine do
            case DocumentType of
                DocumentType::Statistic:
                    exit("Prepayment VAT Difference");
                DocumentType::Invoice:
                    exit("Prepayment VAT Difference");
                else
                    exit("Prepmt VAT Diff. to Deduct");
            end;
    end;

    local procedure UpdateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocNo: Code[20])
    begin
        with SalesHeader do begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            if DocumentType = DocumentType::Invoice then begin
                "Last Prepayment No." := GenJnlLineDocNo;
                "Prepayment No." := '';
                SalesLine.SetFilter("Prepmt. Line Amount", '<>0');
                if SalesLine.FindSet(true) then
                    repeat
                        if SalesLine."Prepmt. Line Amount" <> SalesLine."Prepmt. Amt. Inv." then begin
                            SalesLine."Prepmt. Amt. Inv." := SalesLine."Prepmt. Line Amount";
                            SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Incl. VAT";
                            SalesLine.CalcPrepaymentToDeduct;
                            SalesLine."Prepmt VAT Diff. to Deduct" :=
                              SalesLine."Prepmt VAT Diff. to Deduct" + SalesLine."Prepayment VAT Difference";
                            SalesLine."Prepayment VAT Difference" := 0;
                            SalesLine.Modify();
                        end;
                    until SalesLine.Next = 0;
            end else begin
                "Last Prepmt. Cr. Memo No." := GenJnlLineDocNo;
                "Prepmt. Cr. Memo No." := '';
                SalesLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
                if SalesLine.FindSet(true) then
                    repeat
                        SalesLine."Prepmt. Amt. Inv." := SalesLine."Prepmt Amt Deducted";
                        if "Prices Including VAT" then
                            SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Inv."
                        else
                            SalesLine."Prepmt. Amount Inv. Incl. VAT" :=
                              Round(
                                SalesLine."Prepmt. Amt. Inv." * (100 + SalesLine."Prepayment VAT %") / 100,
                                GetCurrencyAmountRoundingPrecision(SalesLine."Currency Code"));
                        SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Amount Inv. Incl. VAT";
                        SalesLine."Prepayment Amount" := SalesLine."Prepmt. Amt. Inv.";
                        SalesLine."Prepmt Amt to Deduct" := 0;
                        SalesLine."Prepmt VAT Diff. to Deduct" := 0;
                        SalesLine."Prepayment VAT Difference" := 0;
                        SalesLine.Modify();
                    until SalesLine.Next = 0;
            end;
        end;
    end;

    local procedure UpdatePostedSalesDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case DocumentType of
            DocumentType::Invoice:
                begin
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                    CustLedgerEntry.SetRange("Document No.", DocumentNo);
                    CustLedgerEntry.FindFirst;
                    SalesInvoiceHeader.Get(DocumentNo);
                    SalesInvoiceHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    SalesInvoiceHeader.Modify();
                end;
            DocumentType::"Credit Memo":
                begin
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                    CustLedgerEntry.SetRange("Document No.", DocumentNo);
                    CustLedgerEntry.FindFirst;
                    SalesCrMemoHeader.Get(DocumentNo);
                    SalesCrMemoHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    SalesCrMemoHeader.Modify();
                end;
        end;

        OnAfterUpdatePostedSalesDocument(DocumentType, DocumentNo, SuppressCommit);
    end;

    local procedure InsertSalesInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    begin
        with SalesHeader do begin
            SalesInvHeader.Init();
            SalesInvHeader.TransferFields(SalesHeader);
            SalesInvHeader."Posting Description" := PostingDescription;
            SalesInvHeader."Payment Terms Code" := "Prepmt. Payment Terms Code";
            SalesInvHeader."Due Date" := "Prepayment Due Date";
            SalesInvHeader."Pmt. Discount Date" := "Prepmt. Pmt. Discount Date";
            SalesInvHeader."Payment Discount %" := "Prepmt. Payment Discount %";
            SalesInvHeader."No." := GenJnlLineDocNo;
            SalesInvHeader."Pre-Assigned No. Series" := '';
            SalesInvHeader."Source Code" := SrcCode;
            SalesInvHeader."User ID" := UserId;
            SalesInvHeader."No. Printed" := 0;
            SalesInvHeader."Prepayment Invoice" := true;
            SalesInvHeader."Prepayment Order No." := "No.";
            SalesInvHeader."No. Series" := PostingNoSeriesCode;
            OnBeforeSalesInvHeaderInsert(SalesInvHeader, SalesHeader, SuppressCommit);
            SalesInvHeader.Insert();
            CopyHeaderCommentLines("No.", DATABASE::"Sales Invoice Header", GenJnlLineDocNo);
            OnAfterSalesInvHeaderInsert(SalesInvHeader, SalesHeader, SuppressCommit);
        end;
    end;

    local procedure InsertSalesInvLine(SalesInvHeader: Record "Sales Invoice Header"; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        with PrepmtInvLineBuffer do begin
            SalesInvLine.Init();
            SalesInvLine."Document No." := SalesInvHeader."No.";
            SalesInvLine."Line No." := LineNo;
            SalesInvLine."Sell-to Customer No." := SalesInvHeader."Sell-to Customer No.";
            SalesInvLine."Bill-to Customer No." := SalesInvHeader."Bill-to Customer No.";
            SalesInvLine.Type := SalesInvLine.Type::"G/L Account";
            SalesInvLine."No." := "G/L Account No.";
            SalesInvLine."Posting Date" := SalesInvHeader."Posting Date";
            SalesInvLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
            SalesInvLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
            SalesInvLine."Dimension Set ID" := "Dimension Set ID";
            SalesInvLine.Description := Description;
            SalesInvLine.Quantity := 1;
            if SalesInvHeader."Prices Including VAT" then begin
                SalesInvLine."Unit Price" := "Amount Incl. VAT";
                SalesInvLine."Line Amount" := "Amount Incl. VAT";
            end else begin
                SalesInvLine."Unit Price" := Amount;
                SalesInvLine."Line Amount" := Amount;
            end;
            SalesInvLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            SalesInvLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            SalesInvLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            SalesInvLine."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
            SalesInvLine."VAT %" := "VAT %";
            SalesInvLine.Amount := Amount;
            SalesInvLine."VAT Difference" := "VAT Difference";
            SalesInvLine."Amount Including VAT" := "Amount Incl. VAT";
            SalesInvLine."VAT Calculation Type" := "VAT Calculation Type";
            SalesInvLine."VAT Base Amount" := "VAT Base Amount";
            SalesInvLine."VAT Identifier" := "VAT Identifier";
            OnBeforeSalesInvLineInsert(SalesInvLine, SalesInvHeader, PrepmtInvLineBuffer, SuppressCommit);
            SalesInvLine.Insert();
            if not SalesHeader."Compress Prepayment" then
                CopyLineCommentLines(
                  SalesHeader."No.", DATABASE::"Sales Invoice Header", SalesInvHeader."No.", "Line No.", LineNo);
            OnAfterSalesInvLineInsert(SalesInvLine, SalesInvHeader, PrepmtInvLineBuffer, SuppressCommit);
        end;
    end;

    local procedure InsertSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    begin
        with SalesHeader do begin
            SalesCrMemoHeader.Init();
            SalesCrMemoHeader.TransferFields(SalesHeader);
            SalesCrMemoHeader."Payment Terms Code" := "Prepmt. Payment Terms Code";
            SalesCrMemoHeader."Pmt. Discount Date" := "Prepmt. Pmt. Discount Date";
            SalesCrMemoHeader."Payment Discount %" := "Prepmt. Payment Discount %";
            if ("Prepmt. Payment Terms Code" <> '') and not CalcPmtDiscOnCrMemos then begin
                SalesCrMemoHeader."Payment Discount %" := 0;
                SalesCrMemoHeader."Pmt. Discount Date" := 0D;
            end;
            SalesCrMemoHeader."Posting Description" := PostingDescription;
            SalesCrMemoHeader."Due Date" := "Prepayment Due Date";
            SalesCrMemoHeader."No." := GenJnlLineDocNo;
            SalesCrMemoHeader."Pre-Assigned No. Series" := '';
            SalesCrMemoHeader."Source Code" := SrcCode;
            SalesCrMemoHeader."User ID" := UserId;
            SalesCrMemoHeader."No. Printed" := 0;
            SalesCrMemoHeader."Prepayment Credit Memo" := true;
            SalesCrMemoHeader."Prepayment Order No." := "No.";
            SalesCrMemoHeader.Correction := GLSetup."Mark Cr. Memos as Corrections";
            SalesCrMemoHeader."No. Series" := PostingNoSeriesCode;
            OnBeforeSalesCrMemoHeaderInsert(SalesCrMemoHeader, SalesHeader, SuppressCommit);
            SalesCrMemoHeader.Insert();
            CopyHeaderCommentLines("No.", DATABASE::"Sales Cr.Memo Header", GenJnlLineDocNo);
            OnAfterSalesCrMemoHeaderInsert(SalesCrMemoHeader, SalesHeader, SuppressCommit);
        end;
    end;

    local procedure InsertSalesCrMemoLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        with PrepmtInvLineBuffer do begin
            SalesCrMemoLine.Init();
            SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
            SalesCrMemoLine."Line No." := LineNo;
            SalesCrMemoLine."Sell-to Customer No." := SalesCrMemoHeader."Sell-to Customer No.";
            SalesCrMemoLine."Bill-to Customer No." := SalesCrMemoHeader."Bill-to Customer No.";
            SalesCrMemoLine.Type := SalesCrMemoLine.Type::"G/L Account";
            SalesCrMemoLine."No." := "G/L Account No.";
            SalesCrMemoLine."Posting Date" := SalesCrMemoHeader."Posting Date";
            SalesCrMemoLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
            SalesCrMemoLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
            SalesCrMemoLine."Dimension Set ID" := "Dimension Set ID";
            SalesCrMemoLine.Description := Description;
            SalesCrMemoLine.Quantity := 1;
            if SalesCrMemoHeader."Prices Including VAT" then begin
                SalesCrMemoLine."Unit Price" := "Amount Incl. VAT";
                SalesCrMemoLine."Line Amount" := "Amount Incl. VAT";
            end else begin
                SalesCrMemoLine."Unit Price" := Amount;
                SalesCrMemoLine."Line Amount" := Amount;
            end;
            SalesCrMemoLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            SalesCrMemoLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            SalesCrMemoLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            SalesCrMemoLine."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
            SalesCrMemoLine."VAT %" := "VAT %";
            SalesCrMemoLine.Amount := Amount;
            SalesCrMemoLine."VAT Difference" := "VAT Difference";
            SalesCrMemoLine."Amount Including VAT" := "Amount Incl. VAT";
            SalesCrMemoLine."VAT Calculation Type" := "VAT Calculation Type";
            SalesCrMemoLine."VAT Base Amount" := "VAT Base Amount";
            SalesCrMemoLine."VAT Identifier" := "VAT Identifier";
            OnBeforeSalesCrMemoLineInsert(SalesCrMemoLine, SalesCrMemoHeader, PrepmtInvLineBuffer, SuppressCommit);
            SalesCrMemoLine.Insert();
            if not SalesHeader."Compress Prepayment" then
                CopyLineCommentLines(
                  SalesHeader."No.", DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", "Line No.", LineNo);
            OnAfterSalesCrMemoLineInsert(SalesCrMemoLine, SalesCrMemoHeader, PrepmtInvLineBuffer, SuppressCommit);
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

    local procedure CheckSalesLineIsNegative(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLineIsNegative(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesLine.Quantity < 0 then
            SalesLine.FieldError(Quantity, StrSubstNo(Text018, SalesHeader.FieldCaption("Prepayment %")));
        if SalesLine."Unit Price" < 0 then
            SalesLine.FieldError("Unit Price", StrSubstNo(Text018, SalesHeader.FieldCaption("Prepayment %")));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyFilter(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildInvLineBuffer(var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPrepmtDoc(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLinesOnBeforeGLPosting(var SalesHeader: Record "Sales Header"; SalesInvHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; DocumentType: Option; var LastLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvoiceRounding(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var PrevLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepayments(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepaymentsOnBeforeThrowPreviewModeError(var SalesHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmounts(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesInvHeaderInsert(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostedSalesDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtDoc(SalesHeader: Record "Sales Header"; DocumentType: Option; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoice(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreditMemo(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillInvLineBuffer(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepayments(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocNos(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean; IsPreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountsOnBeforeIncrAmounts(SalesHeader: Record "Sales Header"; VAR PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; VAR TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; VAR TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
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

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeSalesLineModify(SalesHeader: Record "Sales Header"; VAR SalesLine: Record "Sales Line"; VAR TempVATAmountLineRemainder: Record "VAT Amount Line"; NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowPreviewError(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLineIsNegative(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
}

