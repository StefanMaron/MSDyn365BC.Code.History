codeunit 31010 "Adv.Letter-Post+Print"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        if not PreviewMode then
            exit;

        case RunOptionPreviewContext of
            RunOptionPreviewContext::Sales_Invoice:
                SalesPostAdvInvoice(SalesAdvanceLetterHeaderPreviewContext, false);
            RunOptionPreviewContext::Sales_CrMemo:
                SalesPostAdvCrMemo(SalesAdvanceLetterHeaderPreviewContext, false);
            RunOptionPreviewContext::Purch_Invoice:
                PurchPostAdvInvoice(PurchAdvanceLetterHeaderPreviewContext, false);
            RunOptionPreviewContext::Purch_CrMemo:
                PurchPostAdvCrMemo(PurchAdvanceLetterHeaderPreviewContext, false);
            RunOptionPreviewContext::Sales_CloseRefund:
                SalesRefundAndCloseLetter(SalesAdvanceLetterHeaderPreviewContext, PostingDateContext, VATDateContext);
            RunOptionPreviewContext::Purch_CloseRefund:
                PurchRefundAndCloseLetter(PurchAdvanceLetterHeaderPreviewContext, PostingDateContext, VATDateContext);
        end;
    end;

    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Text003Qst: Label 'Do you want to post Advance invoice?';
        Text000Qst: Label 'Do you want to post the prepayments for %1 %2?', Comment = '%1=tablecaption;%2=letter number';
        Text001Qst: Label 'Do you want to post a credit memo for the prepayments for %1 %2?', Comment = '%1=tablecaption;%2=letter number';
        SalesAdvanceLetterHeaderPreviewContext: Record "Sales Advance Letter Header";
        PurchAdvanceLetterHeaderPreviewContext: Record "Purch. Advance Letter Header";
        PreviewMode: Boolean;
        RunOptionPreviewContext: Option Sales_Invoice,Sales_CrMemo,Purch_Invoice,Purch_CrMemo,Sales_CloseRefund,Purch_CloseRefund;
        PostingDateContext: Date;
        VATDateContext: Date;

    [Scope('OnPrem')]
    procedure SalesPostAdvInvoice(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; Print: Boolean)
    var
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        LastPrepaymentNo: Code[20];
    begin
        if not PreviewMode then
            if not Confirm(Text003Qst, false) then
                exit;

        SalesPostAdvances.SetPreviewMode(PreviewMode);
        SalesPostAdvances.PostLetter(SalesAdvanceLetterHeader, 0);
        if PreviewMode then
            GenJnlPostPreview.ThrowError;

        Commit();

        if Print then begin
            SalesPostAdvances.xGetLastPostNo(LastPrepaymentNo);
            SalesInvHeader."No." := LastPrepaymentNo;
            SalesInvHeader.Find;
            SalesInvHeader.SetRecFilter;
            SalesInvHeader.PrintRecords(false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SalesPostAdvCrMemo(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; Print: Boolean)
    var
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PostedSalesInvoices: Page "Posted Sales Invoices";
        LastCrMemoNo: Code[20];
    begin
        if not PreviewMode then
            if not Confirm(Text001Qst, false, SalesAdvanceLetterHeader.TableCaption, SalesAdvanceLetterHeader."No.") then
                exit;

        SalesInvHeader.SetFilter("Reversed By Cr. Memo No.", '%1', '');
        SalesInvHeader.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
        PostedSalesInvoices.SetTableView(SalesInvHeader);
        PostedSalesInvoices.LookupMode(true);
        if PostedSalesInvoices.RunModal = ACTION::LookupOK then begin
            PostedSalesInvoices.GetSelection(SalesInvHeader);
            PostedSalesInvoices.GetRecord(SalesInvHeader);

            SalesPostAdvances.SetSalesInvHeaderBuf(SalesInvHeader);
            SalesPostAdvances.SetPreviewMode(PreviewMode);
            SalesPostAdvances.PostLetter(SalesAdvanceLetterHeader, 1);

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

            Commit();
            if Print then begin
                SalesPostAdvances.xGetLastPostNo(LastCrMemoNo);
                SalesCrMemoHeader."No." := LastCrMemoNo;
                SalesCrMemoHeader.Find;
                SalesCrMemoHeader.SetRecFilter;
                SalesCrMemoHeader.PrintRecords(false);
            end;
        end;
    end;

    local procedure SalesRefundAndCloseLetter(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date; VATDate: Date)
    var
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        SalesPostAdvances.SetPreviewMode(PreviewMode);
        SalesPostAdvances.RefundAndCloseLetter('', SalesAdvanceLetterHeader, PostingDate, VATDate, false);
        if PreviewMode then
            GenJnlPostPreview.ThrowError;
    end;

    [Scope('OnPrem')]
    procedure PurchPostAdvInvoice(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; Print: Boolean)
    var
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        LastPrepaymentNo: Code[20];
    begin
        if not PreviewMode then
            if not Confirm(Text000Qst, false, PurchAdvanceLetterHeader.TableCaption, PurchAdvanceLetterHeader."No.") then
                exit;

        PurchPostAdvances.SetPreviewMode(PreviewMode);
        PurchPostAdvances.PostLetter(PurchAdvanceLetterHeader, 0);
        if PreviewMode then
            GenJnlPostPreview.ThrowError;

        Commit();

        if Print then begin
            PurchPostAdvances.xGetLastPostNo(LastPrepaymentNo);
            PurchInvHeader."No." := LastPrepaymentNo;
            PurchInvHeader.Find;
            PurchInvHeader.SetRecFilter;
            PurchInvHeader.PrintRecords(false);
        end;
    end;

    [Scope('OnPrem')]
    procedure PurchPostAdvCrMemo(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; Print: Boolean)
    var
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PostedPurchInvoices: Page "Posted Purchase Invoices";
        LastCrMemoNo: Code[20];
    begin
        if not PreviewMode then
            if not Confirm(Text001Qst, false, PurchAdvanceLetterHeader.TableCaption, PurchAdvanceLetterHeader."No.") then
                exit;

        PurchInvHeader.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
        PurchInvHeader.SetFilter("Reversed By Cr. Memo No.", '%1', '');
        PostedPurchInvoices.SetTableView(PurchInvHeader);
        PostedPurchInvoices.LookupMode(true);
        if PostedPurchInvoices.RunModal = ACTION::LookupOK then begin
            PostedPurchInvoices.GetSelection(PurchInvHeader);
            PostedPurchInvoices.GetRecord(PurchInvHeader);

            PurchPostAdvances.SetPurchInvHeaderBuf(PurchInvHeader);
            PurchPostAdvances.SetPreviewMode(PreviewMode);
            PurchPostAdvances.PostLetter(PurchAdvanceLetterHeader, 1);

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

            Commit();
            if Print then begin
                PurchPostAdvances.xGetLastPostNo(LastCrMemoNo);
                PurchCrMemoHdr."No." := LastCrMemoNo;
                PurchCrMemoHdr.Find;
                PurchCrMemoHdr.SetRecFilter;
                PurchCrMemoHdr.PrintRecords(false);
            end;
        end;
    end;

    local procedure PurchRefundAndCloseLetter(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date; VATDate: Date)
    var
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        PurchPostAdvances.SetPreviewMode(PreviewMode);
        PurchPostAdvances.RefundAndCloseLetter('', PurchAdvanceLetterHeader, PostingDate, VATDate, false);
        if PreviewMode then
            GenJnlPostPreview.ThrowError;
    end;

    [Scope('OnPrem')]
    procedure PreviewSalesInv(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    var
        AdvLetterPostPrint: Codeunit "Adv.Letter-Post+Print";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RunOptionPreview: Option Invoice,CrMemo,CloseRefund;
    begin
        BindSubscription(AdvLetterPostPrint);
        AdvLetterPostPrint.SetSalesContext(SalesAdvanceLetterHeader, 0D, 0D, RunOptionPreview::Invoice);
        GenJnlPostPreview.Preview(AdvLetterPostPrint, SalesAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure PreviewSalesCrMemo(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    var
        AdvLetterPostPrint: Codeunit "Adv.Letter-Post+Print";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RunOptionPreview: Option Invoice,CrMemo,CloseRefund;
    begin
        BindSubscription(AdvLetterPostPrint);
        AdvLetterPostPrint.SetSalesContext(SalesAdvanceLetterHeader, 0D, 0D, RunOptionPreview::CrMemo);
        GenJnlPostPreview.Preview(AdvLetterPostPrint, SalesAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure PreviewSalesRefundAndCloseLetter(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date; VATDate: Date)
    var
        AdvLetterPostPrint: Codeunit "Adv.Letter-Post+Print";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RunOptionPreview: Option Invoice,CrMemo,CloseRefund;
    begin
        BindSubscription(AdvLetterPostPrint);
        AdvLetterPostPrint.SetSalesContext(SalesAdvanceLetterHeader, PostingDate, VATDate, RunOptionPreview::CloseRefund);
        GenJnlPostPreview.Preview(AdvLetterPostPrint, SalesAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure PreviewPurchInv(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    var
        AdvLetterPostPrint: Codeunit "Adv.Letter-Post+Print";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RunOptionPreview: Option Invoice,CrMemo,CloseRefund;
    begin
        BindSubscription(AdvLetterPostPrint);
        AdvLetterPostPrint.SetPurchContext(PurchAdvanceLetterHeader, 0D, 0D, RunOptionPreview::Invoice);
        GenJnlPostPreview.Preview(AdvLetterPostPrint, PurchAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure PreviewPurchCrMemo(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    var
        AdvLetterPostPrint: Codeunit "Adv.Letter-Post+Print";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RunOptionPreview: Option Invoice,CrMemo,CloseRefund;
    begin
        BindSubscription(AdvLetterPostPrint);
        AdvLetterPostPrint.SetPurchContext(PurchAdvanceLetterHeader, 0D, 0D, RunOptionPreview::CrMemo);
        GenJnlPostPreview.Preview(AdvLetterPostPrint, PurchAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure PreviewPurchRefundAndCloseLetter(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date; VATDate: Date)
    var
        AdvLetterPostPrint: Codeunit "Adv.Letter-Post+Print";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RunOptionPreview: Option Invoice,CrMemo,CloseRefund;
    begin
        BindSubscription(AdvLetterPostPrint);
        AdvLetterPostPrint.SetPurchContext(PurchAdvanceLetterHeader, PostingDate, VATDate, RunOptionPreview::CloseRefund);
        GenJnlPostPreview.Preview(AdvLetterPostPrint, PurchAdvanceLetterHeader);
    end;

    [Scope('OnPrem')]
    procedure SetSalesContext(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; PostingDate: Date; VATDate: Date; RunOptionPreview: Option Invoice,CrMemo,CloseRefund)
    begin
        SalesAdvanceLetterHeaderPreviewContext := SalesAdvanceLetterHeader;
        PostingDateContext := PostingDate;
        VATDateContext := VATDate;
        case RunOptionPreview of
            RunOptionPreview::Invoice:
                RunOptionPreviewContext := RunOptionPreviewContext::Sales_Invoice;
            RunOptionPreview::CrMemo:
                RunOptionPreviewContext := RunOptionPreviewContext::Sales_CrMemo;
            RunOptionPreview::CloseRefund:
                RunOptionPreviewContext := RunOptionPreviewContext::Sales_CloseRefund;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetPurchContext(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; PostingDate: Date; VATDate: Date; RunOptionPreview: Option Invoice,CrMemo,CloseRefund)
    begin
        PurchAdvanceLetterHeaderPreviewContext := PurchAdvanceLetterHeader;
        PostingDateContext := PostingDate;
        VATDateContext := VATDate;
        case RunOptionPreview of
            RunOptionPreview::Invoice:
                RunOptionPreviewContext := RunOptionPreviewContext::Purch_Invoice;
            RunOptionPreview::CrMemo:
                RunOptionPreviewContext := RunOptionPreviewContext::Purch_CrMemo;
            RunOptionPreview::CloseRefund:
                RunOptionPreviewContext := RunOptionPreviewContext::Purch_CloseRefund;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        AdvLetterPostPrint: Codeunit "Adv.Letter-Post+Print";
    begin
        AdvLetterPostPrint := Subscriber;
        PreviewMode := true;
        Result := AdvLetterPostPrint.Run;
    end;
}

