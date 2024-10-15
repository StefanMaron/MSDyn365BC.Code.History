codeunit 11735 "Cash Document-Post"
{
    Permissions = TableData "Posted Cash Document Header" = i,
                  TableData "Posted Cash Document Line" = im;
    TableNo = "Cash Document Header";

    trigger OnRun()
    var
        BankAcc: Record "Bank Account";
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        NoCheckCashDoc: Boolean;
    begin
        OnBeforePostCashDoc(Rec);
        if not PreviewMode then
            OnCheckCashDocPostRestrictions;

        CashDocHeader := Rec;
        with CashDocHeader do begin
            TestField("Cash Desk No.");
            TestField("No.");
            TestField("Posting Date");
            TestField("VAT Date");
            if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                FieldError("Posting Date", PostingDateOutRangeErr);

            if Status <> Status::Released then begin
                CODEUNIT.Run(CODEUNIT::"Cash Document-Release", CashDocHeader);
                NoCheckCashDoc := true;
            end;

            // test cash desk
            BankAcc.Get("Cash Desk No.");
            BankAcc.TestField(Blocked, false);
            CalcFields("Amount Including VAT", "Amount Including VAT (LCY)");
            if "Amount Including VAT" <> "Released Amount" then
                Error(IsNotEqualErr, FieldCaption("Amount Including VAT"), FieldCaption("Released Amount"));

            CashDeskMgt.CheckUserRights("Cash Desk No.", 3, IsEETTransaction);

            SourceCodeSetup.Get;
            SourceCodeSetup.TestField("Cash Desk");
            if not NoCheckCashDoc then
                CashDocRelease.CheckCashDocument(Rec);

            if RecordLevelLocking then begin
                CashDocLine.LockTable;
                GLEntry.LockTable;
                if GLEntry.FindLast then;
            end;

            Window.Open(
              '#1#################################\\' +
              DialogMsg);

            // Insert posted cash order header
            GenJnlPostLine.SetPostFromCashReq(true);
            GenJnlPostLine.SetPostAdvInvAfterBatch(true);
            Window.Update(1, StrSubstNo('%1 %2 %3', "Cash Desk No.", "Cash Document Type", "No."));

            PostedCashDocHeader.Init;
            PostedCashDocHeader.TransferFields(CashDocHeader);
            PostedCashDocHeader."Posted ID" := UserId;
            PostedCashDocHeader."No. Printed" := 0;
            OnBeforePostedCashDocHeaderInsert(PostedCashDocHeader, CashDocHeader);
            PostedCashDocHeader.Insert;
            OnAfterPostedCashDocHeaderInsert(PostedCashDocHeader, CashDocHeader);

            PostHeader;
            PostLines;

            GenJnlPostLine.xGetSalesLetterHeader(TempSalesAdvanceLetterHeader);
            if not TempSalesAdvanceLetterHeader.IsEmpty then begin
                SalesPostAdvances.SetLetterHeader(TempSalesAdvanceLetterHeader);
                SalesPostAdvances.SetGenJnlPostLine(GenJnlPostLine);
                SalesPostAdvances.AutoPostAdvanceInvoices;
            end;

            GenJnlPostLine.xGetPurchLetterHeader(TempPurchAdvanceLetterHeader);
            if not TempPurchAdvanceLetterHeader.IsEmpty then begin
                PurchPostAdvances.SetLetterHeader(TempPurchAdvanceLetterHeader);
                PurchPostAdvances.SetGenJnlPostLine(GenJnlPostLine);
                PurchPostAdvances.AutoPostAdvanceInvoices;
            end;

            FinalizePosting(CashDocHeader);
        end;

        OnAfterPostCashDoc(CashDocHeader, GenJnlPostLine, PostedCashDocHeader."No.");
    end;

    var
        CashDocHeader: Record "Cash Document Header";
        CashDocLine: Record "Cash Document Line";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        PostedCashDocHeader: Record "Posted Cash Document Header";
        PostedCashDocLine: Record "Posted Cash Document Line";
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry: Record "G/L Entry";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        CashDocRelease: Codeunit "Cash Document-Release";
        CashDeskMgt: Codeunit CashDeskManagement;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        DialogMsg: Label 'Posting lines              #2######\', Comment = '%2=Line Count';
        PostingDateOutRangeErr: Label 'is not within your range of allowed posting dates';
        IsNotEqualErr: Label '%1 is not equal %2.', Comment = '%1=FIELDCAPTION("Amount Including VAT"), %2=FIELDCAPTION("Released Amount")';
        CheckDimErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error.\\%5.', Comment = '%1=TABLECAPTION, %2=Cash Desk No., %3=Cash Document No., %4=Cash Document Line No., %5=Error Text';
        PreviewMode: Boolean;

    local procedure PostHeader()
    var
        Sign: Integer;
    begin
        with TempGenJnlLine do begin
            Sign := CashDocHeader.SignAmount;

            Init;
            "Document No." := CashDocHeader."No.";
            "External Document No." := CashDocHeader."External Document No.";
            Description := CashDocHeader."Payment Purpose";
            "Posting Date" := CashDocHeader."Posting Date";
            "Document Date" := CashDocHeader."Document Date";
            "VAT Date" := CashDocHeader."VAT Date";
            "Original Document VAT Date" := CashDocHeader."VAT Date";
            "Account Type" := "Account Type"::"Bank Account";
            "Account No." := CashDocHeader."Cash Desk No.";
            "Currency Code" := CashDocHeader."Currency Code";
            CashDocHeader.CalcFields("Amount Including VAT", "Amount Including VAT (LCY)");
            Amount := CashDocHeader."Amount Including VAT" * -Sign;
            "Amount (LCY)" := CashDocHeader."Amount Including VAT (LCY)" * -Sign;
            "Salespers./Purch. Code" := CashDocHeader."Salespers./Purch. Code";
            "Source Currency Code" := "Currency Code";
            "Source Currency Amount" := Amount;
            "Source Curr. VAT Base Amount" := "VAT Base Amount";
            "Source Curr. VAT Amount" := "VAT Amount";
            "System-Created Entry" := true;
            "Shortcut Dimension 1 Code" := CashDocHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := CashDocHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := CashDocHeader."Dimension Set ID";
            "Source Code" := SourceCodeSetup."Cash Desk";
            "Reason Code" := CashDocHeader."Reason Code";
            "VAT Registration No." := CashDocHeader."VAT Registration No.";
        end;

        OnBeforePostCashDocHeader(TempGenJnlLine, CashDocHeader, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(TempGenJnlLine);
    end;

    local procedure PostLines()
    var
        LineCount: Integer;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        CashDocLine.Reset;
        CashDocLine.SetRange("Cash Desk No.", CashDocHeader."Cash Desk No.");
        CashDocLine.SetRange("Cash Document No.", CashDocHeader."No.");
        LineCount := 0;

        if CashDocLine.FindSet then
            repeat
                LineCount += 1;
                Window.Update(2, LineCount);

                // Insert posted cash order line
                PostedCashDocLine.Init;
                PostedCashDocLine.TransferFields(CashDocLine);
                OnBeforePostedCashDocLineInsert(PostedCashDocLine, PostedCashDocHeader, CashDocLine);
                PostedCashDocLine.Insert;
                OnAfterPostedCashDocLineInsert(PostedCashDocLine, PostedCashDocHeader, CashDocLine);

                // Post cash order lines
                if CashDocLine.Amount <> 0 then begin
                    CashDocLine.TestField("Account Type");
                    CashDocLine.TestField("Account No.");

                    InitGenJnlLine(CashDocHeader, CashDocLine);

                    case CashDocLine."Account Type" of
                        CashDocLine."Account Type"::"G/L Account":
                            TableID[1] := DATABASE::"G/L Account";
                        CashDocLine."Account Type"::Customer:
                            TableID[1] := DATABASE::Customer;
                        CashDocLine."Account Type"::Vendor:
                            TableID[1] := DATABASE::Vendor;
                        CashDocLine."Account Type"::"Bank Account":
                            TableID[1] := DATABASE::"Bank Account";
                        CashDocLine."Account Type"::"Fixed Asset":
                            TableID[1] := DATABASE::"Fixed Asset";
                        CashDocLine."Account Type"::Employee:
                            TableID[1] := DATABASE::Employee;
                    end;
                    No[1] := CashDocLine."Account No.";
                    TableID[2] := DATABASE::"Salesperson/Purchaser";
                    No[2] := CashDocLine."Salespers./Purch. Code";
                    TableID[3] := DATABASE::"Responsibility Center";
                    No[3] := CashDocLine."Responsibility Center";
                    TableID[4] := DATABASE::"Cash Desk Event";
                    No[4] := CashDocLine."Cash Desk Event";

                    if not DimMgt.CheckDimValuePosting(TableID, No, CashDocLine."Dimension Set ID") then begin
                        if CashDocLine."Line No." <> 0 then
                            Error(
                              CheckDimErr,
                              CashDocHeader.TableCaption, CashDocHeader."Cash Desk No.", CashDocHeader."No.", CashDocLine."Line No.",
                              DimMgt.GetDimValuePostingErr);
                        Error(DimMgt.GetDimValuePostingErr);
                    end;
                    OnBeforePostCashDocLine(TempGenJnlLine, CashDocLine, GenJnlPostLine);
                    GenJnlPostLine.RunWithCheck(TempGenJnlLine);
                end;
            until CashDocLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure InitGenJnlLine(CashDocHeader2: Record "Cash Document Header"; CashDocLine2: Record "Cash Document Line")
    var
        Sign: Integer;
    begin
        with TempGenJnlLine do begin
            Init;
            case CashDocLine2."Document Type" of
                CashDocLine2."Document Type"::Payment:
                    "Document Type" := "Document Type"::Payment;
                CashDocLine2."Document Type"::Refund:
                    "Document Type" := "Document Type"::Refund;
            end;
            "Document No." := CashDocHeader2."No.";
            "External Document No." := CashDocLine2."External Document No.";
            "Posting Date" := CashDocHeader2."Posting Date";
            "VAT Date" := CashDocHeader2."VAT Date";
            "Original Document VAT Date" := CashDocHeader2."VAT Date";
            "Posting Group" := CashDocLine2."Posting Group";
            Description := CashDocLine2.Description;
            case CashDocLine2."Account Type" of
                CashDocLine2."Account Type"::"G/L Account":
                    "Account Type" := "Account Type"::"G/L Account";
                CashDocLine2."Account Type"::Customer:
                    begin
                        "Account Type" := "Account Type"::Customer;
                        Validate("Bill-to/Pay-to No.", CashDocLine2."Account No.");
                        Validate("Sell-to/Buy-from No.", CashDocLine2."Account No.");
                    end;
                CashDocLine2."Account Type"::Vendor:
                    begin
                        "Account Type" := "Account Type"::Vendor;
                        Validate("Bill-to/Pay-to No.", CashDocLine2."Account No.");
                        Validate("Sell-to/Buy-from No.", CashDocLine2."Account No.");
                    end;
                CashDocLine2."Account Type"::"Bank Account":
                    "Account Type" := "Account Type"::"Bank Account";
                CashDocLine2."Account Type"::"Fixed Asset":
                    "Account Type" := "Account Type"::"Fixed Asset";
                CashDocLine2."Account Type"::Employee:
                    "Account Type" := "Account Type"::Employee;
            end;
            "Account No." := CashDocLine2."Account No.";

            Sign := CashDocLine2.SignAmount;

            "VAT Bus. Posting Group" := CashDocLine2."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := CashDocLine2."VAT Prod. Posting Group";
            "VAT Calculation Type" := CashDocLine2."VAT Calculation Type";
            "VAT Base Amount" := CashDocLine2."VAT Base Amount" * Sign;
            "VAT Base Amount (LCY)" := CashDocLine2."VAT Base Amount (LCY)" * Sign;
            "VAT Amount" := CashDocLine2."VAT Amount" * Sign;
            "VAT Amount (LCY)" := CashDocLine2."VAT Amount (LCY)" * Sign;
            Amount := CashDocLine2."Amount Including VAT" * Sign;
            "Amount (LCY)" := CashDocLine2."Amount Including VAT (LCY)" * Sign;
            "VAT Difference" := CashDocLine2."VAT Difference" * Sign;
            "Gen. Posting Type" := CashDocLine2."Gen. Posting Type";
            "Applies-to Doc. Type" := CashDocLine2."Applies-To Doc. Type";
            "Applies-to Doc. No." := CashDocLine2."Applies-To Doc. No.";
            "Applies-to ID" := CashDocLine2."Applies-to ID";
            "Currency Code" := CashDocHeader2."Currency Code";
            "Currency Factor" := CashDocHeader2."Currency Factor";
            "On Hold" := CashDocLine2."On Hold";
            if "Account Type" = "Account Type"::"Fixed Asset" then begin
                Validate("Depreciation Book Code", CashDocLine2."Depreciation Book Code");
                Validate("FA Posting Type", CashDocLine2."FA Posting Type");
                Validate("Maintenance Code", CashDocLine2."Maintenance Code");
                Validate("Duplicate in Depreciation Book", CashDocLine2."Duplicate in Depreciation Book");
                Validate("Use Duplication List", CashDocLine2."Use Duplication List");
            end;
            "Source Currency Code" := "Currency Code";
            "Source Currency Amount" := Amount;
            "Source Curr. VAT Base Amount" := "VAT Base Amount";
            "Source Curr. VAT Amount" := "VAT Amount";
            "System-Created Entry" := true;
            "Shortcut Dimension 1 Code" := CashDocLine2."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := CashDocLine2."Shortcut Dimension 2 Code";
            "Dimension Set ID" := CashDocLine2."Dimension Set ID";
            "Source Code" := SourceCodeSetup."Cash Desk";
            "Reason Code" := CashDocLine2."Reason Code";
            Validate(Prepayment, CashDocLine2.Prepayment);
            "Advance Letter Link Code" := CashDocLine2."Advance Letter Link Code";
            "VAT Registration No." := CashDocHeader2."VAT Registration No.";
            TransferNonDedVAT(TempGenJnlLine, CashDocLine2);

            OnAfterInitGenJnlLine(TempGenJnlLine, CashDocHeader2, CashDocLine2);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetGenJnlLine(var TempNewGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
        TempNewGenJnlLine := TempGenJnlLine;
    end;

    local procedure FinalizePosting(var CashDocHeader: Record "Cash Document Header")
    begin
        if PreviewMode then begin
            Window.Close;
            OnAfterFinalizePostingPreview(CashDocHeader, PostedCashDocHeader, GenJnlPostLine);
            GenJnlPostPreview.ThrowError;
        end;

        DeleteAfterPosting(CashDocHeader);

        Window.Close;

        OnAfterFinalizePosting(CashDocHeader, PostedCashDocHeader, GenJnlPostLine);
    end;

    local procedure DeleteAfterPosting(var CashDocHeader: Record "Cash Document Header")
    begin
        with CashDocHeader do begin
            OnBeforeDeleteAfterPosting(CashDocHeader, PostedCashDocHeader);

            if HasLinks then
                DeleteLinks;
            Delete;

            CashDocLine.Reset;
            CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
            CashDocLine.SetRange("Cash Document No.", "No.");
            if CashDocLine.FindFirst then
                repeat
                    if CashDocLine.HasLinks then
                        CashDocLine.DeleteLinks;
                until CashDocLine.Next = 0;
            CashDocLine.DeleteAll;
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteCashDocHeader(var CashDocHeader: Record "Cash Document Header")
    var
        PostedCashDocHeader: Record "Posted Cash Document Header";
        PostedCashDocLine: Record "Posted Cash Document Line";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
    begin
        // delete Header
        SourceCodeSetup.Get;
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        // create posted Document
        PostedCashDocHeader.Init;
        PostedCashDocHeader.TransferFields(CashDocHeader);
        PostedCashDocHeader."Canceled Document" := true;
        PostedCashDocHeader."Posting Date" := Today;
        PostedCashDocHeader."Created ID" := UserId;
        PostedCashDocHeader."Payment Purpose" := SourceCode.Description;
        PostedCashDocHeader.Insert;

        // create posted Document line
        PostedCashDocLine.Init;
        PostedCashDocLine."Cash Desk No." := PostedCashDocHeader."Cash Desk No.";
        PostedCashDocLine."Cash Document Type" := PostedCashDocHeader."Cash Document Type";
        PostedCashDocLine."Cash Document No." := PostedCashDocHeader."No.";
        PostedCashDocLine."Line No." := 0;
        PostedCashDocLine.Description := SourceCode.Description;
        if not PostedCashDocLine.Insert then
            PostedCashDocLine.Modify;
    end;

    local procedure TransferNonDedVAT(var GenJnlLine2: Record "Gen. Journal Line"; CashDocLine3: Record "Cash Document Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if CashDocLine3."VAT % (Non Deductible)" = 0 then
            exit;
        GenJnlLine2."VAT % (Non Deductible)" := CashDocLine3."VAT % (Non Deductible)";
        GenJnlLine2."VAT Base (Non Deductible)" := CashDocLine3."VAT Base (Non Deductible)";
        GenJnlLine2."VAT Amount (Non Deductible)" := CashDocLine3."VAT Amount (Non Deductible)";
        if CashDocHeader."Currency Code" = '' then begin
            GenJnlLine2."VAT Base LCY (Non Deduct.)" := CashDocLine3."VAT Base (Non Deductible)";
            GenJnlLine2."VAT Amount LCY (Non Deduct.)" := CashDocLine3."VAT Amount (Non Deductible)";
        end else begin
            GenJnlLine2."VAT Base LCY (Non Deduct.)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  CashDocHeader."Posting Date", CashDocHeader."Currency Code",
                  GenJnlLine2."VAT Base (Non Deductible)", CashDocHeader."Currency Factor"));
            GenJnlLine2."VAT Amount LCY (Non Deduct.)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  CashDocHeader."Posting Date", CashDocHeader."Currency Code",
                  GenJnlLine2."VAT Amount (Non Deductible)", CashDocHeader."Currency Factor"));
        end;
        if (GenJnlLine2."VAT Base (Non Deductible)" = 0) or (GenJnlLine2."VAT Amount (Non Deductible)" = 0) then
            GenJnlLine2.Validate("VAT % (Non Deductible)");
    end;

    [Scope('OnPrem')]
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePosting(var CashDocHdr: Record "Cash Document Header"; var PostedCashDocHdr: Record "Posted Cash Document Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePostingPreview(var CashDocHdr: Record "Cash Document Header"; var PostedCashDocHdr: Record "Posted Cash Document Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCashDoc(var CashDocHdr: Record "Cash Document Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PostedCashDocHdrNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedCashDocHeaderInsert(var PostedCashDocHdr: Record "Posted Cash Document Header"; var CashDocHdr: Record "Cash Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedCashDocLineInsert(var PostedCashDocLine: Record "Posted Cash Document Line"; var PostedCashDocHdr: Record "Posted Cash Document Header"; var CashDocLine: Record "Cash Document Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; CashDocHdr: Record "Cash Document Header"; CashDocLine: Record "Cash Document Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAfterPosting(var CashDocHdr: Record "Cash Document Header"; var PostedCashDocHdr: Record "Posted Cash Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCashDoc(var CashDocHdr: Record "Cash Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCashDocHeader(var GenJnlLine: Record "Gen. Journal Line"; var CashDocHdr: Record "Cash Document Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCashDocLine(var GenJnlLine: Record "Gen. Journal Line"; var CashDocLine: Record "Cash Document Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedCashDocHeaderInsert(var PostedCashDocHdr: Record "Posted Cash Document Header"; var CashDocHdr: Record "Cash Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedCashDocLineInsert(var PostedCashDocLine: Record "Posted Cash Document Line"; var PostedCashDocHdr: Record "Posted Cash Document Header"; var CashDocLine: Record "Cash Document Line")
    begin
    end;
}

