codeunit 92 "Purch.-Post + Print"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Copy(Rec);
        Code(PurchHeader);
        Rec := PurchHeader;
    end;

    var
        ReceiveInvoiceQst: Label '&Receive,&Invoice,Receive &and Invoice';
        PostAndPrintQst: Label 'Do you want to post and print the %1?', Comment = '%1 = Document Type';
        ShipInvoiceQst: Label '&Ship,&Invoice,Ship &and Invoice';

    local procedure "Code"(var PurchHeader: Record "Purchase Header")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchasePostViaJobQueue: Codeunit "Purchase Post via Job Queue";
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmPost(PurchHeader, HideDialog, IsHandled, DefaultOption);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(PurchHeader, DefaultOption) then
                exit;

        OnAfterConfirmPost(PurchHeader);

        PurchSetup.Get();
        if PurchSetup."Post & Print with Job Queue" then
            PurchasePostViaJobQueue.EnqueuePurchDoc(PurchHeader)
        else begin
            CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchHeader);
            GetReport(PurchHeader);
        end;

        OnAfterPost(PurchHeader);
    end;

    local procedure ConfirmPost(var PurchHeader: Record "Purchase Header"; DefaultOption: Integer): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Selection: Integer;
    begin
        with PurchHeader do begin
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        Selection := StrMenu(ReceiveInvoiceQst, DefaultOption);
                        if Selection = 0 then
                            exit(false);
                        Receive := Selection in [1, 3];
                        Invoice := Selection in [2, 3];
                    end;
                "Document Type"::"Return Order":
                    begin
                        Selection := StrMenu(ShipInvoiceQst, DefaultOption);
                        if Selection = 0 then
                            exit(false);
                        Ship := Selection in [1, 3];
                        Invoice := Selection in [2, 3];
                    end
                else
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostAndPrintQst, "Document Type"), true)
                    then
                        exit(false);
            end;
            "Print Posted Documents" := true;
        end;
        exit(true);
    end;

    procedure GetReport(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        if Receive then
                            PrintReceive(PurchHeader);
                        if Invoice then
                            PrintInvoice(PurchHeader);
                    end;
                "Document Type"::Invoice:
                    PrintInvoice(PurchHeader);
                "Document Type"::"Return Order":
                    begin
                        if Ship then
                            PrintShip(PurchHeader);
                        if Invoice then
                            PrintCrMemo(PurchHeader);
                    end;
                "Document Type"::"Credit Memo":
                    PrintCrMemo(PurchHeader);
            end;
    end;

    local procedure PrintReceive(PurchHeader: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintReceive(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchRcptHeader."No." := PurchHeader."Last Receiving No.";
        PurchRcptHeader.SetRecFilter;
        PurchRcptHeader.PrintRecords(false);
    end;

    local procedure PrintInvoice(PurchHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintInvoice(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader."Last Posting No." = '' then
            PurchInvHeader."No." := PurchHeader."No."
        else
            PurchInvHeader."No." := PurchHeader."Last Posting No.";
        PurchInvHeader.SetRecFilter;
        PurchInvHeader.PrintRecords(false);
    end;

    local procedure PrintShip(PurchHeader: Record "Purchase Header")
    var
        ReturnShptHeader: Record "Return Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintShip(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        ReturnShptHeader."No." := PurchHeader."Last Return Shipment No.";
        ReturnShptHeader.SetRecFilter;
        ReturnShptHeader.PrintRecords(false);
    end;

    local procedure PrintCrMemo(PurchHeader: Record "Purchase Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintCrMemo(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader."Last Posting No." = '' then
            PurchCrMemoHdr."No." := PurchHeader."No."
        else
            PurchCrMemoHdr."No." := PurchHeader."Last Posting No.";
        PurchCrMemoHdr.SetRecFilter;
        PurchCrMemoHdr.PrintRecords(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var PurchaseHeader: Record "Purchase Header"; var HideDialog: Boolean; var IsHandled: Boolean; var DefaultOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintInvoice(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintCrMemo(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintReceive(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintShip(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}

