codeunit 91 "Purch.-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        OnBeforeOnRun(Rec);

        if not Find then
            Error(NothingToPostErr);

        PurchaseHeader.Copy(Rec);
        Code(PurchaseHeader);
        Rec := PurchaseHeader;
    end;

    var
        ReceiveInvoiceQst: Label '&Receive,&Invoice,Receive &and Invoice';
        PostConfirmQst: Label 'Do you want to post the %1?', Comment = '%1 = Document Type';
        ShipInvoiceQst: Label '&Ship,&Invoice,Ship &and Invoice';
        NothingToPostErr: Label 'There is nothing to post.';

    local procedure "Code"(var PurchaseHeader: Record "Purchase Header")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchPostViaJobQueue: Codeunit "Purchase Post via Job Queue";
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmPost(PurchaseHeader, HideDialog, IsHandled, DefaultOption);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(PurchaseHeader, DefaultOption) then
                exit;

        OnAfterConfirmPost(PurchaseHeader);

        PurchSetup.Get();
        if PurchSetup."Post with Job Queue" then
            PurchPostViaJobQueue.EnqueuePurchDoc(PurchaseHeader)
        else begin
            OnBeforeRunPurchPost(PurchaseHeader);
            CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
        end;

        OnAfterPost(PurchaseHeader);
    end;

    local procedure ConfirmPost(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer) Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPostProcedure(PurchaseHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if DefaultOption > 3 then
            DefaultOption := 3;
        if DefaultOption <= 0 then
            DefaultOption := 1;

        with PurchaseHeader do begin
            case "Document Type" of
                "Document Type"::Order:
                    if not SelectPostOrderOption(PurchaseHeader, DefaultOption) then
                        exit(false);
                "Document Type"::"Return Order":
                    if not SelectPostReturnOrderOption(PurchaseHeader, DefaultOption) then
                        exit(false);
                else
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostConfirmQst, LowerCase(Format("Document Type"))), true)
                    then
                        exit(false);
            end;
            "Print Posted Documents" := false;
            "Posted Tax Document" := true;
        end;
        exit(true);
    end;

    local procedure SelectPostOrderOption(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer) Result: Boolean
    var
        Selection: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectPostOrderOption(PurchaseHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with PurchaseHeader do begin
            Selection := StrMenu(ReceiveInvoiceQst, DefaultOption);
            if Selection = 0 then
                exit(false);
            Receive := Selection in [1, 3];
            Invoice := Selection in [2, 3];
        end;

        exit(true);
    end;

    local procedure SelectPostReturnOrderOption(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer) Result: Boolean
    var
        Selection: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectPostReturnOrderOption(PurchaseHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with PurchaseHeader do begin
            Selection := StrMenu(ShipInvoiceQst, DefaultOption);
            if Selection = 0 then
                exit(false);
            Ship := Selection in [1, 3];
            Invoice := Selection in [2, 3];
        end;

        exit(true);
    end;

    procedure Preview(var PurchaseHeader: Record "Purchase Header")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        BindSubscription(PurchPostYesNo);
        GenJnlPostPreview.Preview(PurchPostYesNo, PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPost: Codeunit "Purch.-Post";
    begin
        with PurchaseHeader do begin
            Copy(RecVar);
            Ship := "Document Type" = "Document Type"::"Return Order";
            Receive := "Document Type" = "Document Type"::Order;
            Invoice := true;
        end;
        OnRunPreviewOnBeforePurchPostRun(PurchaseHeader);
        PurchPost.SetPreviewMode(true);
        Result := PurchPost.Run(PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var PurchaseHeader: Record "Purchase Header"; var HideDialog: Boolean; var IsHandled: Boolean; var DefaultOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostProcedure(var PurchaseHeader: Record "Purchase Header"; var DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPurchPost(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectPostOrderOption(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectPostReturnOrderOption(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunPreviewOnBeforePurchPostRun(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

