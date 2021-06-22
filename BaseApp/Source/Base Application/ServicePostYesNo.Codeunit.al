codeunit 5981 "Service-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "Service Line";

    trigger OnRun()
    begin
        Code(Rec, ServiceHeaderPreviewContext);
    end;

    var
        ShipInvoiceConsumeQst: Label '&Ship,&Invoice,Ship &and Invoice,Ship and &Consume';
        PostConfirmQst: Label 'Do you want to post the %1?', Comment = '%1 = Document Type';
        ServiceHeaderPreviewContext: Record "Service Header";
        Selection: Integer;
        PreviewMode: Boolean;
        CancelErr: Label 'The preview has been canceled.';
        NothingToPostErr: Label 'There is nothing to post.';

    local procedure "Code"(var PassedServLine: Record "Service Line"; var PassedServiceHeader: Record "Service Header")
    var
        ServicePost: Codeunit "Service-Post";
        ConfirmManagement: Codeunit "Confirm Management";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        if not PassedServiceHeader.Find then
            Error(NothingToPostErr);

        HideDialog := false;
        IsHandled := false;
        OnBeforeConfirmServPost(PassedServiceHeader, HideDialog, Ship, Consume, Invoice, IsHandled, PreviewMode, PassedServLine);
        if IsHandled then
            exit;

        with PassedServiceHeader do begin
            if not HideDialog then
                case "Document Type" of
                    "Document Type"::Order:
                        begin
                            Selection := StrMenu(ShipInvoiceConsumeQst, 3);
                            if Selection = 0 then begin
                                if PreviewMode then
                                    Error(CancelErr);
                                exit;
                            end;
                            Ship := Selection in [1, 3, 4];
                            Consume := Selection in [4];
                            Invoice := Selection in [2, 3];
                        end
                    else
                        if not PreviewMode then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(PostConfirmQst, "Document Type"), true)
                            then
                                exit;
                end;

            OnAfterConfirmPost(PassedServiceHeader, Ship, Consume, Invoice);

            ServicePost.SetPreviewMode(PreviewMode);
            ServicePost.PostWithLines(PassedServiceHeader, PassedServLine, Ship, Consume, Invoice);
        end;

        OnAfterPost(PassedServiceHeader);
    end;

    procedure PostDocument(var ServiceHeaderSource: Record "Service Header")
    var
        DummyServLine: Record "Service Line" temporary;
    begin
        OnBeforePostDocument(ServiceHeaderSource, DummyServLine);
        PostDocumentWithLines(ServiceHeaderSource, DummyServLine);
    end;

    procedure PostDocumentWithLines(var ServiceHeaderSource: Record "Service Header"; var PassedServLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        OnBeforePostDocumentWithLines(ServiceHeaderSource, PassedServLine);
        ServiceHeader.Copy(ServiceHeaderSource);
        Code(PassedServLine, ServiceHeader);
        ServiceHeaderSource := ServiceHeader;
    end;

    procedure PreviewDocument(var ServHeader: Record "Service Header")
    var
        TempServLine: Record "Service Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        BindSubscription(ServicePostYesNo);
        ServicePostYesNo.SetPreviewContext(ServHeader);
        GenJnlPostPreview.Preview(ServicePostYesNo, TempServLine);
    end;

    procedure PreviewDocumentWithLines(var ServHeader: Record "Service Header"; var PassedServLine: Record "Service Line")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        BindSubscription(ServicePostYesNo);
        ServicePostYesNo.SetPreviewContext(ServHeader);
        GenJnlPostPreview.Preview(ServicePostYesNo, PassedServLine);
    end;

    procedure SetPreviewContext(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeaderPreviewContext.Copy(ServiceHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(ServiceHeader: Record "Service Header"; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var PassedServiceHeader: Record "Service Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        ServicePostYesNo := Subscriber;
        PreviewMode := true;
        Result := ServicePostYesNo.Run(RecVar);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmServPost(var ServiceHeader: Record "Service Header"; var HideDialog: Boolean; var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean; var IsHandled: Boolean; PreviewMode: Boolean; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDocument(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDocumentWithLines(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line");
    begin
    end;
}

