codeunit 1633 "Office Host Provider"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        TempExchangeObjectInternal: Record "Exchange Object" temporary;
        TempOfficeAddinContextInternal: Record "Office Add-in Context" temporary;
        [RunOnClient]
        OfficeHost: DotNet OfficeHost;
        IsHostInitialized: Boolean;

    local procedure CanHandle(): Boolean
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        if not OfficeAddinSetup.Get() then begin
            OfficeAddinSetup.Init();
            OfficeAddinSetup.Insert(true);
        end;

        exit(OfficeAddinSetup."Office Host Codeunit ID" = Codeunit::"Office Host Provider");
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnInitializeHost', '', false, false)]
    local procedure OnInitializeHost(NewOfficeHost: DotNet OfficeHost; NewHostType: Text)
    begin
        if not CanHandle() then
            exit;

        OfficeHost := NewOfficeHost;
        IsHostInitialized := not IsNull(OfficeHost);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnInitializeContext', '', false, false)]
    local procedure OnInitializeContext(TempNewOfficeAddinContext: Record "Office Add-in Context" temporary)
    begin
        if not CanHandle() then
            exit;

        TempOfficeAddinContextInternal := TempNewOfficeAddinContext;
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnInitializeExchangeObject', '', false, false)]
    local procedure OnInitializeExchangeObject()
    begin
        if not CanHandle() then
            exit;

        TempExchangeObjectInternal.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnGetHostName', '', false, false)]
    local procedure OnGetHostName(var HostName: Text)
    begin
        if not CanHandle() then
            exit;
        if not IsHostInitialized then
            exit;

        HostName := OfficeHost.HostName();
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnGetHostType', '', false, false)]
    local procedure OnGetHostType(var HostType: Text)
    begin
        if not CanHandle() then
            exit;
        if not IsHostInitialized then
            exit;

        HostType := OfficeHost.HostType();
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnCloseCurrentPage', '', false, false)]
    local procedure OnCloseCurrentPage()
    begin
        if not CanHandle() then
            exit;

        Error('');
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnInvokeExtension', '', false, false)]
    local procedure OnInvokeExtension(FunctionName: Text; Parameter1: Variant; Parameter2: Variant; Parameter3: Variant; Parameter4: Variant)
    begin
        if not CanHandle() then
            exit;

        OfficeHost := OfficeHost.Create();
        OfficeHost.InvokeExtensionAsync(FunctionName, Parameter1, Parameter2, Parameter3, Parameter4);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnIsHostInitialized', '', false, false)]
    local procedure OnIsHostInitialized(var Result: Boolean)
    begin
        if not CanHandle() then
            exit;

        Result := IsHostInitialized;
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnIsAvailable', '', false, false)]
    local procedure OnIsAvailable(var Result: Boolean)
    begin
        if not CanHandle() then
            exit;

        OnIsHostInitialized(Result);
        if Result then
            Result := OfficeHost.IsAvailable();
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnGetTempOfficeAddinContext', '', false, false)]
    local procedure OnGetTempOfficeAddinContext(var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    begin
        if not CanHandle() then
            exit;

        Clear(TempOfficeAddinContext);
        TempOfficeAddinContext.Copy(TempOfficeAddinContextInternal);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnSendToOCR', '', false, false)]
    local procedure OnSendToOCR(IncomingDocument: Record "Incoming Document")
    begin
        if not CanHandle() then
            exit;

        IncomingDocument.SendToOCR(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnEmailHasAttachments', '', false, false)]
    local procedure OnEmailHasAttachments(var Result: Boolean)
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
    begin
        if not CanHandle() then
            exit;

        if not (OfficeHost.CallbackToken in ['', ' ']) then
            with ExchangeWebServicesServer do begin
                InitializeWithOAuthToken(OfficeHost.CallbackToken, GetEndpoint);
                Result := EmailHasAttachments(TempOfficeAddinContextInternal."Item ID");
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnGetEmailAndAttachments', '', false, false)]
    local procedure OnGetEmailAndAttachments(var TempExchangeObject: Record "Exchange Object" temporary; "Action": Option InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow; VendorNumber: Code[20])
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
    begin
        if not CanHandle() then
            exit;

        if not TempExchangeObjectInternal.IsEmpty() then begin
            Clear(TempExchangeObject);
            TempExchangeObjectInternal.ModifyAll(InitiatedAction, Action);
            TempExchangeObjectInternal.ModifyAll(VendorNo, VendorNumber);
            TempExchangeObject.Copy(TempExchangeObjectInternal, true)
        end else
            if not (OfficeHost.CallbackToken() in ['', ' ']) then
                with ExchangeWebServicesServer do begin
                    InitializeWithOAuthToken(OfficeHost.CallbackToken(), GetEndpoint());
                    GetEmailAndAttachments(TempOfficeAddinContextInternal."Item ID", TempExchangeObject, Action, VendorNumber);
                    TempExchangeObjectInternal.Copy(TempExchangeObject, true);
                end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 1631, 'OnGetEmailBody', '', false, false)]
    local procedure OnGetEmailBody(ItemID: Text[250]; var EmailBody: Text)
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
    begin
        if not CanHandle() then
            exit;

        if not (OfficeHost.CallbackToken in ['', ' ']) then
            with ExchangeWebServicesServer do begin
                InitializeWithOAuthToken(OfficeHost.CallbackToken, GetEndpoint);
                EmailBody := GetEmailBody(ItemID);
            end;
    end;
}

