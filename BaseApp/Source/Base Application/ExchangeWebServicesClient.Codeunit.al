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
        CategoryTxt: Label 'AL EWS Client', Locked = true;
        FolderFoundOnServerTxt: Label 'Folder has been found on server.', Locked = true;
        FolderFoundOnClientTxt: Label 'Folder has been found on client.', Locked = true;
        FolderNotFoundOnServerTxt: Label 'Folder has not been found on server.', Locked = true;
        FolderNotFoundOnClientTxt: Label 'Folder has not been found on client.', Locked = true;
        InitializedOnServerWithImpersonationTxt: Label 'Service has been initialized on server with impersonation.', Locked = true;
        InitializedOnServerTxt: Label 'Service has been initialized on server.', Locked = true;
        InitializedOnClientTxt: Label 'Service has been initialized on client.', Locked = true;
        NotInitializedOnServerWithImpersonationTxt: Label 'Service has not been initialized on server with impersonation.', Locked = true;
        NotInitializedOnServerTxt: Label 'Service has not been initialized on server.', Locked = true;
        NotInitializedOnClientTxt: Label 'Service has not been initialized on client.', Locked = true;
        ServiceInvalidatedTxt: Label 'Service has been invlidated.', Locked = true;
        ConnectionFailedTxt: Label 'Connection to the Exchange server failed.', Locked = true;
        InvalidCredentialsOnClientTxt: Label 'Invalid credentials on client.', Locked = true;
        InvalidCredentialsOnServerTxt: Label 'Invalid credentials on server.', Locked = true;
        ValidCredentialsOnServerTxt: Label 'Credentials successfully validated on server.', Locked = true;
        ValidCredentialsOnClientTxt: Label 'Credentials successfully validated on server.', Locked = true;
        PublicFolderFoundOnClientTxt: Label 'Public folder has been found on client.', Locked = true;
        PublicFolderFoundOnServerTxt: Label 'Public folder has been found on server.', Locked = true;
        PublicFolderNotFoundTxt: Label 'Public folder has not been found.', Locked = true;
        PublicFolderCachedTxt: Label 'Public folder is cached.', Locked = true;
        ServiceOnServerLastErrorTxt: Label 'Service on server last error: %1.', Locked = true;
        ServiceOnClientLastErrorTxt: Label 'Service on client last error: %1.', Locked = true;

    [Scope('OnPrem')]
    procedure GetPublicFolders(var ExchangeFolder: Record "Exchange Folder"): Boolean
    begin
        if not IsServiceValid then begin
            SendTraceTag('0000D87', CategoryTxt, Verbosity::Normal, ConnectionFailedTxt, DataClassification::SystemMetadata);
            Error(Text001);
        end;

        if IsNull(ServiceOnServer) then begin
            if GetPublicFoldersOnClient(ExchangeFolder) then begin
                SendTraceTag('0000D88', CategoryTxt, Verbosity::Normal, PublicFolderFoundOnClientTxt, DataClassification::SystemMetadata);
                exit(true);
            end;
            SendTraceTag('0000DA2', CategoryTxt, Verbosity::Normal, PublicFolderNotFoundTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if GetPublicFoldersOnServer(ExchangeFolder) then begin
            SendTraceTag('0000D89', CategoryTxt, Verbosity::Normal, PublicFolderFoundOnServerTxt, DataClassification::SystemMetadata);
            exit(true);
        end;
        SendTraceTag('0000D8A', CategoryTxt, Verbosity::Normal, PublicFolderNotFoundTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    local procedure GetPublicFoldersOnClient(var ExchangeFolder: Record "Exchange Folder") FoundAny: Boolean
    var
        [RunOnClient]
        ParentInfo: DotNet FolderInfo;
        [RunOnClient]
        SubFolders: DotNet FolderInfoEnumerator;
    begin
        if ExchangeFolder.Cached then begin
            SendTraceTag('0000D8B', CategoryTxt, Verbosity::Normal, PublicFolderCachedTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

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

        if ServiceOnClient.LastError <> '' then begin
            SendTraceTag('0000D8C', CategoryTxt, Verbosity::Normal, StrSubstNo(ServiceOnClientLastErrorTxt, ServiceOnClient.LastError), DataClassification::CustomerContent);
            Message(ServiceOnClient.LastError);
        end;

        exit(FoundAny);
    end;

    local procedure GetPublicFoldersOnServer(var ExchangeFolder: Record "Exchange Folder") FoundAny: Boolean
    var
        ParentInfo: DotNet FolderInfo;
        SubFolders: DotNet FolderInfoEnumerator;
    begin
        if ExchangeFolder.Cached then begin
            SendTraceTag('0000D8D', CategoryTxt, Verbosity::Normal, PublicFolderCachedTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

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

        if ServiceOnServer.LastError <> '' then begin
            SendTraceTag('0000D8E', CategoryTxt, Verbosity::Normal, StrSubstNo(ServiceOnServerLastErrorTxt, ServiceOnServer.LastError), DataClassification::CustomerContent);
            Message(ServiceOnServer.LastError);
        end;

        exit(FoundAny);
    end;

    [Scope('OnPrem')]
    procedure InitializeOnClient(AutodiscoveryEmail: Text[250]; ServiceUri: Text): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        [RunOnClient]
        ServiceFactoryOnClient: DotNet ServiceWrapperFactory;
        Initialized: Boolean;
    begin
        if ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Windows then
            exit(false);
        if IsNull(ServiceOnClient) then begin
            InvalidateService;
            ServiceOnClient := ServiceFactoryOnClient.CreateServiceWrapper;
        end;

        if ServiceUri <> '' then
            ServiceOnClient.ExchangeServiceUrl := ServiceUri;

        Initialized := ServiceOnClient.ExchangeServiceUrl <> '';
        if not Initialized then
            Initialized := ServiceOnClient.AutodiscoverServiceUrl(AutodiscoveryEmail);

        if Initialized then
            SendTraceTag('0000D8F', CategoryTxt, Verbosity::Normal, InitializedOnClientTxt, DataClassification::SystemMetadata)
        else
            SendTraceTag('0000D8G', CategoryTxt, Verbosity::Normal, NotInitializedOnClientTxt, DataClassification::SystemMetadata);

        exit(Initialized);
    end;

    [Scope('OnPrem')]
    procedure InitializeOnServer(AutodiscoveryEmail: Text[250]; ServiceUri: Text; Credentials: DotNet NetworkCredential): Boolean
    var
        ServiceFactoryOnServer: DotNet ServiceWrapperFactory;
        Initialized: Boolean;
    begin
        if IsNull(ServiceOnServer) then begin
            InvalidateService;
            ServiceOnServer := ServiceFactoryOnServer.CreateServiceWrapperWithCredentials(Credentials);
        end;

        if ServiceUri <> '' then
            ServiceOnServer.ExchangeServiceUrl := ServiceUri;

        Initialized := ServiceOnServer.ExchangeServiceUrl <> '';
        if not Initialized then
            Initialized := ServiceOnServer.AutodiscoverServiceUrl(AutodiscoveryEmail);

        if Initialized then
            SendTraceTag('0000D8H', CategoryTxt, Verbosity::Normal, InitializedOnServerTxt, DataClassification::SystemMetadata)
        else
            SendTraceTag('0000D8I', CategoryTxt, Verbosity::Normal, NotInitializedOnServerTxt, DataClassification::SystemMetadata);

        exit(Initialized);
    end;

    [Scope('OnPrem')]
    procedure InitializeOnServerWithImpersonation(AutodiscoveryEmail: Text[250]; ServiceUri: Text; Credentials: DotNet OAuthCredentials): Boolean
    var
        ServiceFactoryOnServer: DotNet ServiceWrapperFactory;
        Initialized: Boolean;
    begin
        if IsNull(ServiceOnServer) then begin
            InvalidateService();
            ServiceOnServer := ServiceFactoryOnServer.CreateServiceWrapper();
        end;

        ServiceOnServer.SetNetworkCredential(Credentials);
        ServiceOnServer.SetImpersonatedIdentity(AutodiscoveryEmail);

        if ServiceUri <> '' then
            ServiceOnServer.ExchangeServiceUrl := ServiceUri;

        Initialized := ServiceOnServer.ExchangeServiceUrl <> '';
        if not Initialized then
            Initialized := ServiceOnServer.AutodiscoverServiceUrl(AutodiscoveryEmail);

        if Initialized then
            SendTraceTag('0000D8J', CategoryTxt, Verbosity::Normal, InitializedOnServerWithImpersonationTxt, DataClassification::SystemMetadata)
        else
            SendTraceTag('0000D8K', CategoryTxt, Verbosity::Normal, NotInitializedOnServerWithImpersonationTxt, DataClassification::SystemMetadata);

        exit(Initialized);
    end;

    [Scope('OnPrem')]
    procedure FolderExists(UniqueID: Text): Boolean
    var
        Exists: Boolean;
    begin
        if not IsServiceValid then begin
            SendTraceTag('0000D8L', CategoryTxt, Verbosity::Normal, ConnectionFailedTxt, DataClassification::SystemMetadata);
            Error(Text001);
        end;
        if IsNull(ServiceOnServer) then begin
            Exists := ServiceOnClient.FolderExists(UniqueID);
            if Exists then
                SendTraceTag('0000D8M', CategoryTxt, Verbosity::Normal, FolderFoundOnClientTxt, DataClassification::SystemMetadata)
            else
                SendTraceTag('0000D8N', CategoryTxt, Verbosity::Normal, FolderNotFoundOnClientTxt, DataClassification::SystemMetadata);
        end else begin
            Exists := ServiceOnServer.FolderExists(UniqueID);
            if Exists then
                SendTraceTag('0000D8O', CategoryTxt, Verbosity::Normal, FolderFoundOnServerTxt, DataClassification::SystemMetadata)
            else
                SendTraceTag('0000D8P', CategoryTxt, Verbosity::Normal, FolderNotFoundOnServerTxt, DataClassification::SystemMetadata);
        end;
        exit(Exists);
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
        SendTraceTag('0000D8Q', CategoryTxt, Verbosity::Normal, ServiceInvalidatedTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    procedure ValidateCredentialsOnServer(): Boolean
    begin
        if not ServiceOnServer.ValidateCredentials() then begin
            SendTraceTag('0000D8R', CategoryTxt, Verbosity::Normal, InvalidCredentialsOnServerTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        SendTraceTag('0000D8S', CategoryTxt, Verbosity::Normal, ValidCredentialsOnServerTxt, DataClassification::SystemMetadata);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ValidateCredentialsOnClient(): Boolean
    begin
        if not ServiceOnClient.ValidateCredentials() then begin
            SendTraceTag('0000D8T', CategoryTxt, Verbosity::Normal, InvalidCredentialsOnClientTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        SendTraceTag('0000D8U', CategoryTxt, Verbosity::Normal, ValidCredentialsOnClientTxt, DataClassification::SystemMetadata);
        exit(true);
    end;
}

