codeunit 5981 "Service-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "Service Line";

    trigger OnRun()
    begin
        Code(Rec, GlobalServiceHeader);
    end;

    var
        GlobalServiceHeader: Record "Service Header";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        Selection: Integer;
        PreviewMode: Boolean;

        ShipInvoiceConsumeQst: Label '&Ship,&Invoice,Ship &and Invoice,Ship and &Consume';
        PostConfirmQst: Label 'Do you want to post the %1?', Comment = '%1 = Document Type';

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
        if not PassedServiceHeader.Find() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

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
                                    Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
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
            GlobalServiceHeader.Copy(PassedServiceHeader);
        end;

        OnAfterPost(PassedServiceHeader);
    end;

    procedure PostDocument(var ServiceHeaderSource: Record "Service Header")
    var
        TempServiceLine: Record "Service Line" temporary;
    begin
        OnBeforePostDocument(ServiceHeaderSource, TempServiceLine);
        PostDocumentWithLines(ServiceHeaderSource, TempServiceLine);
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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePreviewDocument(ServHeader, IsHandled);
        if IsHandled then
            exit;

        BindSubscription(ServicePostYesNo);
        ServicePostYesNo.SetGlobalServiceHeader(ServHeader);
        GenJnlPostPreview.Preview(ServicePostYesNo, TempServLine);
    end;

    procedure PreviewDocumentWithLines(var ServHeader: Record "Service Header"; var PassedServLine: Record "Service Line")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        BindSubscription(ServicePostYesNo);
        ServicePostYesNo.SetGlobalServiceHeader(ServHeader);
        GenJnlPostPreview.Preview(ServicePostYesNo, PassedServLine);
    end;

    procedure SetGlobalServiceHeader(var ServiceHeader: Record "Service Header")
    begin
        GlobalServiceHeader.Copy(ServiceHeader);
    end;

    procedure GetGlobalServiceHeader(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.Copy(GlobalServiceHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var ServiceHeader: Record "Service Header"; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var PassedServiceHeader: Record "Service Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreviewDocument(var ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}

