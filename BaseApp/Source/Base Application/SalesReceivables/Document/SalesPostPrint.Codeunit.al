codeunit 82 "Sales-Post + Print"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        OnBeforeOnRun(Rec);

        SalesHeader.Copy(Rec);
        Code(SalesHeader);
        Rec := SalesHeader;
    end;

    var
#if not CLEAN22    
        PostAndPrintQst: Label 'Do you want to post and print the %1?', Comment = '%1 = Document Type';
        PostAndEmailQst: Label 'Do you want to post and email the %1?', Comment = '%1 = Document Type';
#endif
        SendReportAsEmail: Boolean;

    procedure PostAndEmail(var ParmSalesHeader: Record "Sales Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        SendReportAsEmail := true;
        SalesHeader.Copy(ParmSalesHeader);
        Code(SalesHeader);
        ParmSalesHeader := SalesHeader;
    end;

    local procedure "Code"(var SalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmPost(SalesHeader, HideDialog, IsHandled, SendReportAsEmail, DefaultOption);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(SalesHeader, DefaultOption) then
                exit;

        OnAfterConfirmPost(SalesHeader);

        SalesSetup.Get();
        if SalesSetup."Post & Print with Job Queue" and not SendReportAsEmail then
            SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader)
        else begin
            RunSalesPost(SalesHeader);
            GetReport(SalesHeader);
        end;

        OnAfterPost(SalesHeader);
        Commit();
    end;

    local procedure RunSalesPost(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunSalesPost(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
    end;

    procedure GetReport(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(SalesHeader, IsHandled, SendReportAsEmail);
        if IsHandled then
            exit;

        with SalesHeader do
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        if Ship then
                            PrintShip(SalesHeader);
                        if Invoice then
                            PrintInvoice(SalesHeader);
                    end;
                "Document Type"::Invoice:
                    PrintInvoice(SalesHeader);
                "Document Type"::"Return Order":
                    begin
                        if Receive then
                            PrintReceive(SalesHeader);
                        if Invoice then
                            PrintCrMemo(SalesHeader);
                    end;
                "Document Type"::"Credit Memo":
                    PrintCrMemo(SalesHeader);
            end;
    end;

    local procedure ConfirmPost(var SalesHeader: Record "Sales Header"; DefaultOption: Integer) Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPostProcedure(SalesHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := PostingSelectionManagement.ConfirmPostSalesDocument(SalesHeader, DefaultOption, not SendReportAsEmail, SendReportAsEmail);
        if not Result then
            exit(false);

        SalesHeader."Print Posted Documents" := true;
        exit(true);
    end;

#if not CLEAN22
    [Obsolete('Replaced by new implementation in Posting Selection Management codeunit', '22.0')]
    procedure ConfirmationMessage(): Text
    begin
        if SendReportAsEmail then
            exit(PostAndEmailQst);
        exit(PostAndPrintQst);
    end;
#endif

    procedure PrintReceive(SalesHeader: Record "Sales Header")
    var
        ReturnRcptHeader: Record "Return Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintReceive(SalesHeader, SendReportAsEmail, IsHandled);
        if IsHandled then
            exit;

        ReturnRcptHeader."No." := SalesHeader."Last Return Receipt No.";
        if ReturnRcptHeader.Find() then;
        ReturnRcptHeader.SetRecFilter();

        if SendReportAsEmail then
            ReturnRcptHeader.EmailRecords(true)
        else
            ReturnRcptHeader.PrintRecords(false);
    end;

    procedure PrintInvoice(SalesHeader: Record "Sales Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintInvoice(SalesHeader, SendReportAsEmail, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Last Posting No." = '' then
            SalesInvHeader."No." := SalesHeader."No."
        else
            SalesInvHeader."No." := SalesHeader."Last Posting No.";
        SalesInvHeader.Find();
        SalesInvHeader.SetRecFilter();

        OnPrintInvoiceOnAfterSetSalesInvHeaderFilter(SalesHeader, SalesInvHeader, SendReportAsEmail);

        if SendReportAsEmail then
            SalesInvHeader.EmailRecords(true)
        else
            SalesInvHeader.PrintRecords(false);
    end;

    procedure PrintShip(SalesHeader: Record "Sales Header")
    var
        SalesShptHeader: Record "Sales Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintShip(SalesHeader, SendReportAsEmail, IsHandled);
        if IsHandled then
            exit;

        SalesShptHeader."No." := SalesHeader."Last Shipping No.";
        if SalesShptHeader.Find() then;
        SalesShptHeader.SetRecFilter();

        if SendReportAsEmail then
            SalesShptHeader.EmailRecords(true)
        else
            SalesShptHeader.PrintRecords(false);
    end;

    procedure PrintCrMemo(SalesHeader: Record "Sales Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintCrMemo(SalesHeader, SendReportAsEmail, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Last Posting No." = '' then
            SalesCrMemoHeader."No." := SalesHeader."No."
        else
            SalesCrMemoHeader."No." := SalesHeader."Last Posting No.";
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.SetRecFilter();

        if SendReportAsEmail then
            SalesCrMemoHeader.EmailRecords(true)
        else
            SalesCrMemoHeader.PrintRecords(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var SalesHeader: Record "Sales Header"; var HideDialog: Boolean; var IsHandled: Boolean; var SendReportAsEmail: Boolean; var DefaultOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostProcedure(var SalesHeader: Record "Sales Header"; var DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; SendReportAsEmail: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintInvoice(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintCrMemo(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintReceive(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintShip(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunSalesPost(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintInvoiceOnAfterSetSalesInvHeaderFilter(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; SendReportAsEmail: Boolean)
    begin
    end;
}

