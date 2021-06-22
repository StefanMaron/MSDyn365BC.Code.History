codeunit 5320 "Exchange Web Services Client"
{

    trigger OnRun()
    begin
    end;

    var
        TempExchangeFolder: Record "Exchange Folder" temporary;
        [RunOnClient]
        ServiceOnClient: DotNet ExchangeServiceWrapper;
        Text001: Label 'Connection to the Exchange server failed.';
        Text002: Label 'Folders with a path that exceeds 250 characters have been omitted.';
        ServiceOnServer: DotNet ExchangeServiceWrapper;
        LongPathsDetected: Boolean;

    [Scope('OnPrem')]
    procedure GetPublicFolders(var ExchangeFolder: Record "Exchange Folder"): Boolean
    begin
        if not IsServiceValid then
            Error(Text001);

        if IsNull(ServiceOnServer) then
            exit(GetPublicFoldersOnClient(ExchangeFolder));
        exit(GetPublicFoldersOnServer(ExchangeFolder));
    end;

    local procedure GetPublicFoldersOnClient(var ExchangeFolder: Record "Exchange Folder") FoundAny: Boolean
    var
        [RunOnClient]
        ParentInfo: DotNet FolderInfo;
        [RunOnClient]
        SubFolders: DotNet FolderInfoEnumerator;
    begin
        if ExchangeFolder.Cached then
            exit;

        if ExchangeFolder."Unique ID".HasValue then begin
            ParentInfo := ParentInfo.FolderInfo(ExchangeFolder.GetUniqueID, ExchangeFolder.FullPath);
            ExchangeFolder.Cached := true;
            ExchangeFolder.Modify();
        end;

        FoundAny := false;
        LongPathsDetected := false;

        SubFolders := ServiceOnClient.GetPublicFolders(ParentInfo, 1000);

        if not IsNull(SubFolders) then begin
            while SubFolders.MoveNextPage do
                while SubFolders.MoveNext do
                    if StrLen(SubFolders.Current.FullPath) > 250 then
                        LongPathsDetected := true
                    else
                        if not TempExchangeFolder.Get(SubFolders.Current.FullPath) then
                            if IsAllowedFolderType(SubFolders.Current.FolderClass) then begin
                                FoundAny := true;
                                with TempExchangeFolder do begin
                                    Init;
                                    FullPath := SubFolders.Current.FullPath;
                                    Depth := SubFolders.Current.Depth;
                                    SetUniqueID(SubFolders.Current.UniqueId);
                                    Name := SubFolders.Current.Name;
                                    Cached := false;
                                    Insert;
                                end;
                            end;
            if LongPathsDetected then
                Message(Text002);
            ReadBuffer(ExchangeFolder);
        end;

        if IsNull(ServiceOnServer) then begin
            if ServiceOnServer.LastError <> '' then
                Message(ServiceOnServer.LastError);
        end else
            if ServiceOnServer.LastError <> '' then
                Message(ServiceOnServer.LastError);

        exit(FoundAny);
    end;

    local procedure GetPublicFoldersOnServer(var ExchangeFolder: Record "Exchange Folder") FoundAny: Boolean
    var
        ParentInfo: DotNet FolderInfo;
        SubFolders: DotNet FolderInfoEnumerator;
    begin
        if ExchangeFolder.Cached then
            exit;

        if ExchangeFolder."Unique ID".HasValue then begin
            ParentInfo := ParentInfo.FolderInfo(ExchangeFolder.GetUniqueID, ExchangeFolder.FullPath);
            ExchangeFolder.Cached := true;
            ExchangeFolder.Modify();
        end;

        FoundAny := false;
        LongPathsDetected := false;

        SubFolders := ServiceOnServer.GetPublicFolders(ParentInfo, 1000);

        if not IsNull(SubFolders) then begin
            while SubFolders.MoveNextPage do
                while SubFolders.MoveNext do
                    if StrLen(SubFolders.Current.FullPath) > 250 then
                        LongPathsDetected := true
                    else
                        if not TempExchangeFolder.Get(SubFolders.Current.FullPath) then
                            if IsAllowedFolderType(SubFolders.Current.FolderClass) then begin
                                FoundAny := true;
                                with TempExchangeFolder do begin
                                    Init;
                                    FullPath := SubFolders.Current.FullPath;
                                    Depth := SubFolders.Current.Depth;
                                    SetUniqueID(SubFolders.Current.UniqueId);
                                    Name := SubFolders.Current.Name;
                                    Cached := false;
                                    Insert;
                                end;
                            end;
            if LongPathsDetected then
                Message(Text002);
            ReadBuffer(ExchangeFolder);
        end;

        if IsNull(ServiceOnServer) then begin
            if ServiceOnServer.LastError <> '' then
                Message(ServiceOnServer.LastError);
        end else
            if ServiceOnServer.LastError <> '' then
                Message(ServiceOnServer.LastError);

        exit(FoundAny);
    end;

    [Scope('OnPrem')]
    procedure InitializeOnClient(AutodiscoveryEmail: Text[250]; ServiceUri: Text): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        [RunOnClient]
        ServiceFactoryOnClient: DotNet ServiceWrapperFactory;
    begin
        if ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Windows then
            exit(false);
        if IsNull(ServiceOnClient) then begin
            InvalidateService;
            ServiceOnClient := ServiceFactoryOnClient.CreateServiceWrapper;
        end;

        if ServiceUri <> '' then
            ServiceOnClient.ExchangeServiceUrl := ServiceUri;

        if ServiceOnClient.ExchangeServiceUrl = '' then
            exit(ServiceOnClient.AutodiscoverServiceUrl(AutodiscoveryEmail));
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure InitializeOnServer(AutodiscoveryEmail: Text[250]; ServiceUri: Text; Credentials: DotNet NetworkCredential): Boolean
    var
        ServiceFactoryOnServer: DotNet ServiceWrapperFactory;
    begin
        if IsNull(ServiceOnServer) then begin
            InvalidateService;
            ServiceOnServer := ServiceFactoryOnServer.CreateServiceWrapperWithCredentials(Credentials);
        end;

        if ServiceUri <> '' then
            ServiceOnServer.ExchangeServiceUrl := ServiceUri;

        if ServiceOnServer.ExchangeServiceUrl = '' then
            exit(ServiceOnServer.AutodiscoverServiceUrl(AutodiscoveryEmail));
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure FolderExists(UniqueID: Text): Boolean
    begin
        if not IsServiceValid then
            Error(Text001);
        if IsNull(ServiceOnServer) then
            exit(ServiceOnClient.FolderExists(UniqueID));
        exit(ServiceOnServer.FolderExists(UniqueID));
    end;

    procedure ReadBuffer(var DestExchangeFolder: Record "Exchange Folder"): Boolean
    begin
        if TempExchangeFolder.FindSet then
            repeat
                if not DestExchangeFolder.Get(TempExchangeFolder.FullPath) then begin
                    TempExchangeFolder.CalcFields("Unique ID");
                    DestExchangeFolder.Init();
                    DestExchangeFolder.TransferFields(TempExchangeFolder);
                    DestExchangeFolder.Insert();
                end;
            until TempExchangeFolder.Next = 0
        else
            exit(false);
        exit(true);
    end;

    local procedure IsAllowedFolderType(FolderClass: Text): Boolean
    begin
        if FolderClass = '' then
            exit(true);

        if FolderClass = 'IPF.Note' then
            exit(true);

        exit(false);
    end;

    local procedure IsServiceValid(): Boolean
    begin
        if IsNull(ServiceOnServer) and IsNull(ServiceOnClient) then
            exit(false);

        if IsNull(ServiceOnServer) then
            exit(ServiceOnClient.ExchangeServiceUrl <> '');
        exit(ServiceOnServer.ExchangeServiceUrl <> '');
    end;

    procedure InvalidateService()
    begin
        Clear(ServiceOnClient);
        Clear(ServiceOnServer);
    end;

    [Scope('OnPrem')]
    procedure ValidateCredentialsOnServer(): Boolean
    begin
        exit(ServiceOnServer.ValidateCredentials);
    end;

    [Scope('OnPrem')]
    procedure ValidateCredentialsOnClient(): Boolean
    begin
        exit(ServiceOnClient.ValidateCredentials);
    end;
}

