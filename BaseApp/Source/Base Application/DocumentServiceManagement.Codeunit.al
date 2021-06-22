codeunit 9510 "Document Service Management"
{
    // Provides functions for the storage of documents to online services such as O365 (Office 365).


    trigger OnRun()
    begin
    end;

    var
        NoConfigErr: Label 'No online document configuration was found.';
        MultipleConfigsErr: Label 'More than one online document configuration was found.';
        SourceFileNotFoundErr: Label 'Cannot open the specified document from the following location: %1 due to the following error: %2.', Comment = '%1=Full path to the file on disk;%2=the detailed error describing why the document could not be accessed.';
        RequiredSourceNameErr: Label 'You must specify a source path for the document.';
        DocumentService: DotNet IDocumentService;
        DocumentServiceFactory: DotNet DocumentServiceFactory;
        ServiceType: Text;
        LastServiceType: Text;
        RequiredTargetNameErr: Label 'You must specify a name for the document.';
        RequiredTargetURIErr: Label 'You must specify the URI that you want to open.';
        ValidateConnectionErr: Label 'Cannot connect because the user name and password have not been specified, or because the connection was canceled.';

    [Scope('OnPrem')]
    procedure TestConnection()
    var
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
    begin
        // Tests connectivity to the Document Service using the current configuration in Dynamics NAV.
        // An error occurrs if unable to successfully connect.
        if not IsConfigured then
            Error(NoConfigErr);
        DocumentServiceHelper.Reset();
        SetDocumentService;
        SetProperties;
        if IsNull(DocumentService.Credentials) then
            Error(ValidateConnectionErr);
        DocumentService.ValidateConnection;
        CheckError;
    end;

    [Scope('OnPrem')]
    procedure SaveFile(SourcePath: Text; TargetName: Text; Overwrite: Boolean): Text
    var
        SourceFile: File;
        SourceStream: InStream;
    begin
        // Saves a file to the Document Service using the configured location specified in Dynamics NAV.
        // SourcePath: The path to a physical file on the Dynamics NAV server.
        // TargetName: The name which will be given to the file saved to the Document Service.
        // Overwrite: TRUE if the target file should be overwritten.
        // - An error is shown if Overwrite is FALSE and a file with that name already exists.
        // Returns: A URI to the file on the Document Service.

        if SourcePath = '' then
            Error(RequiredSourceNameErr);

        if TargetName = '' then
            Error(RequiredTargetNameErr);

        if not IsConfigured then
            Error(NoConfigErr);

        if not SourceFile.Open(SourcePath) then
            Error(SourceFileNotFoundErr, SourcePath, GetLastErrorText);

        SourceFile.CreateInStream(SourceStream);

        exit(SaveStream(SourceStream, TargetName, Overwrite));
    end;

    procedure IsConfigured(): Boolean
    var
        DocumentServiceRec: Record "Document Service";
    begin
        // Returns TRUE if Dynamics NAV has been configured with a Document Service.

        with DocumentServiceRec do begin
            if Count > 1 then
                Error(MultipleConfigsErr);

            if not FindFirst then
                exit(false);

            if (Location = '') or (Folder = '') then
                exit(false);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure IsServiceUri(TargetURI: Text): Boolean
    var
        DocumentServiceRec: Record "Document Service";
        IsValid: Boolean;
    begin
        // Returns TRUE if the TargetURI points to a location on the currently-configured Document Service.

        if TargetURI = '' then
            exit(false);

        with DocumentServiceRec do begin
            if FindLast then
                if Location <> '' then begin
                    SetDocumentService;
                    SetProperties;
                    IsValid := DocumentService.IsValidUri(TargetURI);
                    CheckError;
                    exit(IsValid);
                end
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SetServiceType(RequestedServiceType: Text)
    var
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
    begin
        // Sets the type name of the Document Service.
        // The type must match the DocumentServiceMetadata attribute value on the IDocumentServiceHandler interface
        // exposed by at least one assembly in the Server installation folder.
        // By default, Dynamics NAV uses the SharePoint Online Document Service with type named 'SHAREPOINTONLINE'.
        ServiceType := RequestedServiceType;
        DocumentServiceHelper.SetDocumentServiceType(RequestedServiceType);
    end;

    procedure GetServiceType(): Text
    begin
        // Gets the name of the current Document Service.

        exit(ServiceType);
    end;

    [Scope('OnPrem')]
    procedure OpenDocument(TargetURI: Text)
    begin
        // Navigates to the specified URI on the Document Service from the client device.

        if TargetURI = '' then
            Error(RequiredTargetURIErr);

        if not IsConfigured then
            Error(NoConfigErr);

        SetDocumentService;
        HyperLink(DocumentService.GenerateViewableDocumentAddress(TargetURI));
        CheckError;
    end;

    local procedure SetProperties()
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
    begin
        with DocumentServiceRec do begin
            if not FindFirst then
                Error(NoConfigErr);

            // The Document Service will throw an exception if the property is not known to the service type provider.
            DocumentService.Properties.SetProperty(FieldName(Description), Description);
            DocumentService.Properties.SetProperty(FieldName(Location), Location);
            DocumentService.Properties.SetProperty(FieldName("User Name"), "User Name");
            DocumentService.Properties.SetProperty(FieldName(Password), Password);
            DocumentService.Properties.SetProperty(FieldName("Document Repository"), "Document Repository");
            DocumentService.Properties.SetProperty(FieldName(Folder), Folder);

            DocumentService.Credentials := DocumentServiceHelper.ProvideCredentials;
            if not (DocumentServiceHelper.LastErrorMessage = '') then
                Error(DocumentServiceHelper.LastErrorMessage);
        end;
    end;

    local procedure SetDocumentService()
    var
        RequestedServiceType: Text;
    begin
        // Sets the Document Service for the current Service Type, reusing an existing service if possible.

        RequestedServiceType := GetServiceType;

        if RequestedServiceType = '' then
            RequestedServiceType := 'SHAREPOINTONLINE';

        if LastServiceType <> RequestedServiceType then begin
            DocumentService := DocumentServiceFactory.CreateService(RequestedServiceType);
            LastServiceType := RequestedServiceType;
        end;
    end;

    local procedure CheckError()
    begin
        // Checks whether the Document Service received an error and displays that error to the user.

        if not IsNull(DocumentService.LastError) and (DocumentService.LastError.Message <> '') then
            Error(DocumentService.LastError.Message);
    end;

    local procedure SaveStream(Stream: InStream; TargetName: Text; Overwrite: Boolean): Text
    var
        DocumentURI: Text;
    begin
        // Saves a stream to the Document Service using the configured location specified in Dynamics NAV.
        SetDocumentService;
        SetProperties;

        DocumentURI := DocumentService.Save(Stream, TargetName, Overwrite);
        CheckError;

        exit(DocumentURI);
    end;
}

