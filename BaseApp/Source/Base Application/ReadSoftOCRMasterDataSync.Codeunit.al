codeunit 884 "ReadSoft OCR Master Data Sync"
{

    trigger OnRun()
    begin
    end;

    var
        SyncVendorsUriTxt: Label 'masterdata/rest/%1/suppliers', Locked = true;
        SyncVendorBankAccountsUriTxt: Label 'masterdata/rest/%1/supplierbankaccounts', Locked = true;
        SyncModifiedVendorsMsg: Label 'Send updated vendors to the OCR service.';
        SyncBankAccountsMsg: Label 'Send vendor bank accounts to the OCR service.';
        SyncSuccessfulSimpleMsg: Label 'Synchronization succeeded.';
        SyncSuccessfulDetailedMsg: Label 'Synchronization succeeded. Created: %1, Updated: %2, Deleted: %3', Comment = '%1 number of created entities, %2 number of updated entities, %3 number of deleted entities';
        SyncFailedSimpleMsg: Label 'Synchronization failed.';
        SyncFailedDetailedMsg: Label 'Synchronization failed. Code: %1, Message: %2', Comment = '%1 error code, %2 error message';
        InvalidResponseMsg: Label 'Response is invalid.';
        MasterDataSyncMsg: Label 'Master data synchronization.\#1########################################', Comment = '#1 place holder for SendingPackageMsg ';
        SendingPackageMsg: Label 'Sending package %1 of %2', Comment = '%1 package number, %2 package count';
        MaxPortionSizeTxt: Label '3000', Locked = true;
        MethodPutTok: Label 'PUT', Locked = true;
        MethodPostTok: Label 'POST', Locked = true;
        OCRServiceSetup: Record "OCR Service Setup";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        XmlOptions: XmlWriteOptions;
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        OrganizationId: Text;
        PackageNo: Integer;
        PackageCount: Integer;
        MaxPortionSizeValue: Integer;
        OCRServiceMasterDataSyncSucceededTxt: Label 'Successfully synchronized %1 entities with OCR service.', Locked = true;
        OCRServiceMasterDataSyncFailedTxt: Label 'Failed to synchronize %1 entities with OCR service.', Locked = true;
        TelemetryCategoryTok: Label 'AL OCR Service', Locked = true;
        XmlNameSpace: Text;
        CRLF: Text[2];
        CR: Text[1];
        LF: Text[1];

    procedure SyncMasterData(Resync: Boolean; Silent: Boolean): Boolean
    var
        LastSyncTime: DateTime;
        SyncStartTime: DateTime;
    begin
        OCRServiceMgt.GetOcrServiceSetupExtended(OCRServiceSetup, true);
        OCRServiceSetup.TestField("Master Data Sync Enabled");

        if Resync then begin
            Clear(OCRServiceSetup."Master Data Last Sync");
            OCRServiceSetup.Modify();
            Commit();
        end;

        Initialize();
        LastSyncTime := OCRServiceSetup."Master Data Last Sync";
        SyncStartTime := CurrentDateTime();

        if not SyncVendors(LastSyncTime, SyncStartTime) then begin
            if not Silent then
                Message(SyncFailedSimpleMsg);
            exit(false);
        end;

        OCRServiceSetup."Master Data Last Sync" := SyncStartTime;
        OCRServiceSetup.Modify();
        if not Silent then
            Message(SyncSuccessfulSimpleMsg);
        exit(true);
    end;

    procedure ResetLastSyncTime()
    begin
        if not IsSyncEnabled then
            exit;
        OCRServiceSetup.Get();
        if OCRServiceSetup."Master Data Last Sync" = 0DT then
            exit;
        Clear(OCRServiceSetup."Master Data Last Sync");
        OCRServiceSetup.Modify();
        Commit();
    end;

    procedure IsSyncEnabled(): Boolean
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        if not OCRServiceSetup.Get() then
            exit(false);

        if not OCRServiceSetup."Master Data Sync Enabled" then
            exit(false);

        if not OCRServiceSetup.Enabled then
            exit(false);

        if OCRServiceSetup."Service URL" = '' then
            exit(false);

        exit(true);
    end;

    local procedure CheckSyncResponse(var ResponseBody: Text; ActivityDescription: Text): Boolean
    var
        XmlDoc: XmlDocument;
        XmlRoot: XmlElement;
        XmlNode: XmlNode;
        NoOfCreated: Integer;
        NoOfUpdated: Integer;
        NoOfDeleted: Integer;
        ErrorCode: Text;
        ErrorMessage: Text;
    begin
        if not XmlDocument.ReadFrom(ResponseBody, XmlDoc) then begin
            OCRServiceMgt.LogActivityFailed(OCRServiceSetup.RecordId, ActivityDescription, InvalidResponseMsg);
            exit(false);
        end;
        if not XmlDoc.GetRoot(XmlRoot) then begin
            OCRServiceMgt.LogActivityFailed(OCRServiceSetup.RecordId, ActivityDescription, InvalidResponseMsg);
            exit(false);
        end;
        case XmlRoot.Name() of
            'UpdateResult':
                begin
                    if XmlRoot.SelectSingleNode('Created', XmlNode) then
                        if XmlNode.IsXmlElement() then
                            if Evaluate(NoOfCreated, XmlNode.AsXmlElement().InnerText(), 9) then;
                    if XmlRoot.SelectSingleNode('Updated', XmlNode) then
                        if XmlNode.IsXmlElement() then
                            if Evaluate(NoOfUpdated, XmlNode.AsXmlElement().InnerText(), 9) then;
                    if XmlRoot.SelectSingleNode('Deleted', XmlNode) then
                        if XmlNode.IsXmlElement() then
                            if Evaluate(NoOfDeleted, XmlNode.AsXmlElement().InnerText(), 9) then;
                    OCRServiceMgt.LogActivitySucceeded(
                      OCRServiceSetup.RecordId, ActivityDescription, StrSubstNo(SyncSuccessfulDetailedMsg, NoOfCreated, NoOfUpdated, NoOfDeleted));
                    exit(true);
                end;
            'ServiceError':
                begin
                    if XmlRoot.SelectSingleNode('Code', XmlNode) then
                        if XmlNode.IsXmlElement() then
                            ErrorCode := XmlNode.AsXmlElement().InnerText();
                    if XmlRoot.SelectSingleNode('Message', XmlNode) then
                        if XmlNode.IsXmlElement() then
                            ErrorMessage := XmlNode.AsXmlElement().InnerText();
                    OCRServiceMgt.LogActivityFailed(
                      OCRServiceSetup.RecordId, ActivityDescription, StrSubstNo(SyncFailedDetailedMsg, ErrorCode, ErrorMessage));
                    exit(false);
                end;
            else begin
                    OCRServiceMgt.LogActivityFailed(OCRServiceSetup.RecordId, ActivityDescription, InvalidResponseMsg);
                    exit(false);
                end;
        end;
    end;

    local procedure SyncVendors(StartDateTime: DateTime; EndDateTime: DateTime): Boolean
    var
        TempBlobListModifiedVendor: Codeunit "Temp Blob List";
        TempBlobListBankAccount: Codeunit "Temp Blob List";
        ModifiedVendorCount: Integer;
        BankAccountCount: Integer;
        ModifyVendorPackageCount: Integer;
        BankAccountPackageCount: Integer;
        TotalPackageCount: Integer;
        Success: Boolean;
        ModifiedVendorFirstPortionAction: Code[6];
    begin
        if StartDateTime > 0DT then
            ModifiedVendorFirstPortionAction := MethodPostTok
        else
            ModifiedVendorFirstPortionAction := MethodPutTok;

        GetModifiedVendors(TempBlobListModifiedVendor, StartDateTime, EndDateTime);
        GetVendorBankAccounts(TempBlobListBankAccount, StartDateTime, EndDateTime);

        ModifiedVendorCount := TempBlobListModifiedVendor.Count();
        BankAccountCount := TempBlobListBankAccount.Count();

        if (ModifiedVendorCount > 0) or (StartDateTime = 0DT) then
            ModifyVendorPackageCount := (ModifiedVendorCount div MaxPortionSize()) + 1;
        if BankAccountCount > 0 then
            BankAccountPackageCount := (TempBlobListBankAccount.Count() div MaxPortionSize()) + 1;
        TotalPackageCount := ModifyVendorPackageCount + BankAccountPackageCount;

        if TotalPackageCount = 0 then
            exit(true);

        CheckOrganizationId();

        OpenWindow(TotalPackageCount);

        Success := SyncMasterDataEntities(
            TempBlobListModifiedVendor, VendorsUri, ModifiedVendorFirstPortionAction, MethodPostTok,
            'Suppliers', SyncModifiedVendorsMsg, MaxPortionSize);

        if Success then
            Success := SyncMasterDataEntities(
                TempBlobListBankAccount, VendorBankAccountsUri, MethodPutTok, MethodPutTok,
                'SupplierBankAccounts', SyncBankAccountsMsg, MaxPortionSize);

        CloseWindow();

        exit(Success);
    end;

    local procedure SyncMasterDataEntities(var TempBlobList: Codeunit "Temp Blob List"; RequestUri: Text; FirstPortionAction: Code[6]; NextPortionAction: Code[6]; RootNodeName: Text; ActivityDescription: Text; PortionSize: Integer): Boolean
    var
        EntityCount: Integer;
        PortionCount: Integer;
        PortionNumber: Integer;
        LastPortion: Boolean;
        RequestAction: Code[6];
        RequestBody: Text;
        ResponseBody: Text;
        ErrorMessage: Text;
        ErrorDetails: Text;
        StatusCode: Integer;
    begin
        EntityCount := TempBlobList.Count();

        if EntityCount = 0 then begin
            if FirstPortionAction <> MethodPutTok then
                exit(true);
            PortionCount := 1;
            PortionSize := 0;
        end else
            PortionCount := (EntityCount div PortionSize) + 1;

        RequestAction := FirstPortionAction;
        for PortionNumber := 1 to PortionCount do begin
            UpdateWindow();
            RequestBody := GetMasterDataEntitiesXml(TempBlobList, RootNodeName, PortionSize, LastPortion);
            OnBeforeSendRequest(RequestBody);
            if not OCRServiceMgt.RsoRequest(RequestUri, RequestAction, RequestBody, ResponseBody, ErrorMessage, ErrorDetails, StatusCode) then begin
                LogTelemetryFailedMasterDataSync(RootNodeName);
                OCRServiceMgt.LogActivityFailed(OCRServiceSetup.RecordId, ActivityDescription, SyncFailedSimpleMsg);
                exit(false);
            end;
            if not CheckSyncResponse(ResponseBody, ActivityDescription) then begin
                LogTelemetryFailedMasterDataSync(RootNodeName);
                exit(false);
            end;
            if LastPortion then
                break;
            RequestAction := NextPortionAction;
        end;
        LogTelemetrySuccessfulMasterDataSync(RootNodeName);
        exit(true);
    end;

    local procedure GetModifiedVendors(var TempBlobList: Codeunit "Temp Blob List"; StartDateTime: DateTime; EndDateTime: DateTime)
    var
        OCRVendors: Query "OCR Vendors";
        Data: Text;
    begin
        OCRVendors.SetRange(Modified_On, StartDateTime, EndDateTime);
        if OCRVendors.Open() then
            while OCRVendors.Read() do begin
                Data := GetModifiedVendorXml(OCRVendors);
                AddToBuffer(TempBlobList, Data);
            end;
    end;

    local procedure GetVendorBankAccounts(var TempBlobList: Codeunit "Temp Blob List"; StartDateTime: DateTime; EndDateTime: DateTime)
    var
        OCRVendorBankAccounts: Query "OCR Vendor Bank Accounts";
        VendorId: Guid;
        Data: Text;
    begin
        OCRVendorBankAccounts.SetRange(Modified_On, StartDateTime, EndDateTime);
        if not OCRVendorBankAccounts.Open() then
            exit;

        while OCRVendorBankAccounts.Read() do begin
            if IsNullGuid(VendorId) then
                VendorId := OCRVendorBankAccounts.Id;
            if VendorId <> OCRVendorBankAccounts.Id then begin
                AddToBuffer(TempBlobList, Data);
                VendorId := OCRVendorBankAccounts.Id;
                Data := '';
            end;
            Data += GetVendorBankAccountXml(OCRVendorBankAccounts);
        end;
        AddToBuffer(TempBlobList, Data);
    end;

    local procedure Min(A: Integer; B: Integer): Integer
    begin
        if A < B then
            exit(A);
        exit(B);
    end;

    local procedure GetMasterDataEntitiesXml(var TempBlobList: Codeunit "Temp Blob List"; RootNodeName: Text; PortionSize: Integer; var LastPortion: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Data: Text;
        Index: Integer;
    begin
        Data := '';
        LastPortion := (PortionSize > TempBlobList.Count()) or (PortionSize = 0);
        for Index := 1 to Min(PortionSize, TempBlobList.Count()) do begin
            TempBlobList.Get(Index, TempBlob);
            Data += GetFromBuffer(TempBlob);
        end;

        Data := StrSubstNo('<%1 xmlns:i="http://www.w3.org/2001/XMLSchema-instance">%2</%3>', RootNodeName, Data, RootNodeName);
        exit(Data);
    end;

    local procedure GetModifiedVendorXml(var OCRVendors: Query "OCR Vendors"): Text
    var
        XmlElem: XmlElement;
        Blocked: Boolean;
        Result: Text;
    begin
        Blocked := OCRVendors.Blocked <> OCRVendors.Blocked::" ";
        XmlElem := XmlElement.Create('Supplier');

        // when using XML as the input for API, the element order needs to match exactly
        AddElement(XmlElem, 'SupplierNumber', OCRVendors.No);
        AddElement(XmlElem, 'Name', OCRVendors.Name);
        AddElement(XmlElem, 'TaxRegistrationNumber', OCRVendors.VAT_Registration_No);
        AddElement(XmlElem, 'Street', OCRVendors.Address);
        AddElement(XmlElem, 'PostalCode', OCRVendors.Post_Code);
        AddElement(XmlElem, 'City', OCRVendors.City);
        AddElement(XmlElem, 'Blocked', Format(Blocked, 0, 9));
        AddElement(XmlElem, 'TelephoneNumber', OCRVendors.Phone_No);

        XmlElem.WriteTo(XmlOptions, Result);
        exit(Result);
    end;

    local procedure GetVendorBankAccountXml(var OCRVendorBankAccounts: Query "OCR Vendor Bank Accounts"): Text
    var
        XmlElem: XmlElement;
        Result: Text;
        AccountXml: Text;
    begin
        if (OCRVendorBankAccounts.Bank_Account_No = '') and
           (OCRVendorBankAccounts.IBAN = '')
        then
            exit('');

        // when using XML as the input for API, the element order needs to match exactly

        if OCRVendorBankAccounts.Bank_Account_No <> '' then begin
            XmlElem := XmlElement.Create('SupplierBankAccount');
            AddElement(XmlElem, 'BankName', OCRVendorBankAccounts.Name);
            AddElement(XmlElem, 'SupplierNumber', OCRVendorBankAccounts.No);
            AddElement(XmlElem, 'BankNumber', OCRVendorBankAccounts.Bank_Branch_No);
            AddElement(XmlElem, 'AccountNumber', OCRVendorBankAccounts.Bank_Account_No);
            XmlElem.WriteTo(XmlOptions, AccountXml);
            Result += AccountXml;
        end;

        if OCRVendorBankAccounts.IBAN <> '' then begin
            XmlElem := XmlElement.Create('SupplierBankAccount');
            AddElement(XmlElem, 'BankName', OCRVendorBankAccounts.Name);
            AddElement(XmlElem, 'SupplierNumber', OCRVendorBankAccounts.No);
            AddElement(XmlElem, 'BankNumberType', 'bic');
            AddElement(XmlElem, 'BankNumber', OCRVendorBankAccounts.SWIFT_Code);
            AddElement(XmlElem, 'AccountNumberType', 'iban');
            AddElement(XmlElem, 'AccountNumber', OCRVendorBankAccounts.IBAN);
            XmlElem.WriteTo(XmlOptions, AccountXml);
            Result += AccountXml;
        end;

        exit(Result);
    end;

    local procedure AddElement(var XmlElem: XmlElement; var XmlChildElem: XmlElement; Name: Text; Value: Text): Boolean
    begin
        XmlChildElem := XmlElement.Create(Name, XmlNameSpace, Value.Replace(CRLF, '').Replace(CR, '').Replace(LF, '').Trim());
        exit(XmlElem.Add(XmlChildElem));
    end;

    local procedure AddElement(var XmlElem: XmlElement; Name: Text; Value: Text): Boolean
    var
        XmlChildElem: XmlElement;
    begin
        exit(AddElement(XmlElem, XmlChildElem, Name, Value));
    end;

    local procedure Initialize()
    begin
        XmlOptions.PreserveWhitespace := true;
        XmlNameSpace := '';
        CRLF[1] := 13;
        CRLF[2] := 10;
        CR[1] := 13;
        LF[1] := 10;
    end;

    local procedure AddToBuffer(var TempBlobList: Codeunit "Temp Blob List"; Data: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(Data);
        TempBlobList.Add(TempBlob);
    end;

    local procedure GetFromBuffer(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStream: InStream;
        Data: Text;
        Line: Text;
    begin
        if not TempBlob.HasValue then
            exit;
        TempBlob.CreateInStream(InStream);
        while InStream.ReadText(Line) > 0 do
            Data += Line;
        exit(Data);
    end;

    local procedure VendorsUri(): Text
    begin
        exit(StrSubstNo(SyncVendorsUriTxt, OrganizationId));
    end;

    local procedure VendorBankAccountsUri(): Text
    begin
        exit(StrSubstNo(SyncVendorBankAccountsUriTxt, OrganizationId));
    end;

    local procedure CheckOrganizationId()
    begin
        OrganizationId := OCRServiceSetup."Organization ID";
        if OrganizationId = '' then begin
            OCRServiceMgt.UpdateOrganizationInfo(OCRServiceSetup);
            OrganizationId := OCRServiceSetup."Organization ID";
        end;
        OCRServiceSetup.TestField("Organization ID");
    end;

    local procedure MaxPortionSize(): Integer
    begin
        if MaxPortionSizeValue = 0 then
            Evaluate(MaxPortionSizeValue, MaxPortionSizeTxt);
        exit(MaxPortionSizeValue);
    end;

    local procedure OpenWindow("Count": Integer)
    begin
        PackageNo := 0;
        PackageCount := Count;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(MasterDataSyncMsg);
        Window.Update(1, '');
    end;

    local procedure UpdateWindow()
    begin
        PackageNo += 1;
        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, StrSubstNo(SendingPackageMsg, PackageNo, PackageCount));
        end;
    end;

    local procedure CloseWindow()
    begin
        Window.Close;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRequest(Body: Text)
    begin
    end;

    local procedure LogTelemetrySuccessfulMasterDataSync(RootNodeName: Text)
    begin
        SendTraceTag('00008A3', TelemetryCategoryTok, VERBOSITY::Normal,
          StrSubstNo(OCRServiceMasterDataSyncSucceededTxt, RootNodeName), DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure LogTelemetryFailedMasterDataSync(RootNodeName: Text)
    begin
        SendTraceTag('00008AJ', TelemetryCategoryTok, VERBOSITY::Normal,
          StrSubstNo(OCRServiceMasterDataSyncFailedTxt, RootNodeName), DATACLASSIFICATION::SystemMetadata);
    end;
}

