codeunit 89 "Sales-Post + Email"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        Code();
        Rec := SalesHeader;
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        HideMailDialog: Boolean;
        PostAndSaveInvoiceQst: Label 'Do you want to post and save the %1?';
        NotSupportedDocumentTypeSavingErr: Label 'The %1 is not posted because saving document of type %1 is not supported.';

    local procedure "Code"()
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        IsHandled := false;
        OnBeforePostAndEMail(SalesHeader, HideDialog, IsHandled, HideMailDialog);
        if IsHandled then
            exit;

        if not HideDialog then
            with SalesHeader do
                case "Document Type" of
                    "Document Type"::Invoice,
                  "Document Type"::"Credit Memo":
                        if not ConfirmPostAndDistribute(SalesHeader) then
                            exit;
                    else
                        ErrorPostAndDistribute(SalesHeader);
                end;

        OnAfterConfirmPost(SalesHeader);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        OnAfterPostAndBeforeSend(SalesHeader);
        Commit();
        SendDocumentReport(SalesHeader);

        OnAfterPostAndSend(SalesHeader);
    end;

    local procedure SendDocumentReport(var SalesHeader: Record "Sales Header")
    var
    begin
        with SalesHeader do
            case "Document Type" of
                "Document Type"::Invoice:
                    begin
                        if "Last Posting No." = '' then
                            SalesInvHeader."No." := "No."
                        else
                            SalesInvHeader."No." := "Last Posting No.";
                        SalesInvHeader.Find();
                        SalesInvHeader.SetRecFilter();
                        SalesInvHeader.EmailRecords(not HideMailDialog);
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        if "Last Posting No." = '' then
                            SalesCrMemoHeader."No." := "No."
                        else
                            SalesCrMemoHeader."No." := "Last Posting No.";
                        SalesCrMemoHeader.Find();
                        SalesCrMemoHeader.SetRecFilter();
                        SalesCrMemoHeader.EmailRecords(not HideMailDialog);
                    end
            end
    end;

    procedure InitializeFrom(NewHideMailDialog: Boolean)
    begin
        HideMailDialog := NewHideMailDialog;
    end;

    local procedure ConfirmPostAndDistribute(var SalesHeader: Record "Sales Header"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        exit(
          ConfirmManagement.GetResponseOrDefault(
            StrSubstNo(PostAndSaveInvoiceQst, SalesHeader."Document Type"), true));
    end;

    local procedure ErrorPostAndDistribute(var SalesHeader: Record "Sales Header")
    var
        NotSupportedDocumentType: Text;
    begin
        NotSupportedDocumentType := NotSupportedDocumentTypeSavingErr;

        Error(NotSupportedDocumentType, SalesHeader."Document Type");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndBeforeSend(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAndEMail(var SalesHeader: Record "Sales Header"; var HideDialog: Boolean; var IsHandled: Boolean; var HideMailDialog: Boolean)
    begin
    end;
}

