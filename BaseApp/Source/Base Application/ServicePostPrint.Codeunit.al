codeunit 5982 "Service-Post+Print"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label '&Ship,&Invoice,Ship &and Invoice,Ship and &Consume';
        Text001: Label 'Do you want to post and print the %1?';
        ServiceHeader: Record "Service Header";
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        ServicePost: Codeunit "Service-Post";
        Selection: Integer;
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;

    procedure PostDocument(var Rec: Record "Service Header")
    var
        DummyServLine: Record "Service Line" temporary;
    begin
        ServiceHeader.Copy(Rec);
        Code(DummyServLine);
        Rec := ServiceHeader;
    end;

    local procedure "Code"(var PassedServLine: Record "Service Line")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        IsHandled := false;
        OnBeforeConfirmPost(ServiceHeader, HideDialog, Ship, Consume, Invoice, IsHandled);
        if IsHandled then
            exit;

        with ServiceHeader do begin
            if not HideDialog then
                case "Document Type" of
                    "Document Type"::Order:
                        begin
                            Selection := StrMenu(Text000, 3);
                            if Selection = 0 then
                                exit;
                            Ship := Selection in [1, 3, 4];
                            Consume := Selection in [4];
                            Invoice := Selection in [2, 3];
                        end
                    else
                        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text001, "Document Type"), true) then
                            exit;
                end;

            OnAfterConfirmPost(ServiceHeader, Ship, Consume, Invoice);

            ServicePost.PostWithLines(ServiceHeader, PassedServLine, Ship, Consume, Invoice);
            OnAfterPost(ServiceHeader);

            GetReport(ServiceHeader);
            Commit();
        end;
    end;

    local procedure GetReport(var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        with ServiceHeader do
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        if Ship then begin
                            ServShptHeader."No." := "Last Shipping No.";
                            ServShptHeader.SetRecFilter;
                            IsHandled := false;
                            OnBeforeServiceShipmentHeaderPrintRecords(ServShptHeader, IsHandled);
                            if not IsHandled then
                                ServShptHeader.PrintRecords(false);
                        end;
                        if Invoice then begin
                            ServInvHeader."No." := "Last Posting No.";
                            ServInvHeader.SetRecFilter;
                            IsHandled := false;
                            OnBeforeServiceInvoiceHeaderPrintRecords(ServInvHeader, IsHandled);
                            if not IsHandled then
                                ServInvHeader.PrintRecords(false);
                        end;
                    end;
                "Document Type"::Invoice:
                    begin
                        if "Last Posting No." = '' then
                            ServInvHeader."No." := "No."
                        else
                            ServInvHeader."No." := "Last Posting No.";
                        ServInvHeader.SetRecFilter;
                        IsHandled := false;
                        OnBeforeServiceInvoiceHeaderPrintRecords(ServInvHeader, IsHandled);
                        if not IsHandled then
                            ServInvHeader.PrintRecords(false);
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        if "Last Posting No." = '' then
                            ServCrMemoHeader."No." := "No."
                        else
                            ServCrMemoHeader."No." := "Last Posting No.";
                        ServCrMemoHeader.SetRecFilter;
                        IsHandled := false;
                        OnBeforeServiceCrMemoHeaderPrintRecords(ServCrMemoHeader, IsHandled);
                        if not IsHandled then
                            ServCrMemoHeader.PrintRecords(false);
                    end;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(ServiceHeader: Record "Service Header"; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var ServiceHeader: Record "Service Header"; var HideDialog: Boolean; var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceCrMemoHeaderPrintRecords(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvoiceHeaderPrintRecords(var ServiceInvoiceHeader: Record "Service Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShipmentHeaderPrintRecords(var ServiceShipmentHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;
}

