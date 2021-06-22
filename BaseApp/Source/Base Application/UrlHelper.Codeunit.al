codeunit 9005 "Url Helper"
{
    // // The distinction between TIE and PROD shall be felt only when making internal tools. So all functions here are Internal.

    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        UrlHelperImpl: Codeunit "Url Helper Impl.";

    [Scope('OnPrem')]
    procedure IsPPE(): Boolean
    begin
        exit(UrlHelperImpl.IsPPE);
    end;

    [Scope('OnPrem')]
    procedure IsPROD(): Boolean
    begin
        exit(UrlHelperImpl.IsPROD);
    end;

    [Scope('OnPrem')]
    procedure IsTIE(): Boolean
    begin
        exit(UrlHelperImpl.IsTIE);
    end;

    [Scope('OnPrem')]
    procedure GetFixedClientEndpointBaseUrl(): Text
    begin
        exit(UrlHelperImpl.GetFixedClientEndpointBaseUrl);
    end;

    [Scope('OnPrem')]
    procedure GetFixedEndpointWebServiceUrl(): Text
    begin
        exit(UrlHelperImpl.GetFixedEndpointWebServiceUrl());
    end;

    [Scope('OnPrem')]
    procedure GetGraphUrl(): Text
    begin
        exit(UrlHelperImpl.GetGraphUrl);
    end;

    [Scope('OnPrem')]
    procedure GetAzureADAuthEndpoint(): Text
    begin
        exit(UrlHelperImpl.GetAzureADAuthEndpoint);
    end;

    [Scope('OnPrem')]
    procedure GetO365Resource(): Text
    begin
        exit(UrlHelperImpl.GetO365Resource);
    end;

    [Scope('OnPrem')]
    procedure GetPowerBIResourceUrl(): Text
    begin
        exit(UrlHelperImpl.GetPowerBIResourceUrl);
    end;

    [Scope('OnPrem')]
    procedure GetPowerBIApiUrl(): Text
    begin
        exit(UrlHelperImpl.GetPowerBIApiUrl);
    end;

    [Scope('OnPrem')]
    procedure GetPowerBIReportsUrl(): Text
    begin
        exit(UrlHelperImpl.GetPowerBIReportsUrl);
    end;

    [Scope('OnPrem')]
    procedure GetPowerBIEmbedReportsUrl(): Text
    begin
        exit(UrlHelperImpl.GetPowerBIEmbedReportsUrl);
    end;

    [Scope('OnPrem')]
    procedure GetExcelAddinProviderServiceUrl(): Text
    begin
        exit(UrlHelperImpl.GetExcelAddinProviderServiceUrl);
    end;

    [Scope('OnPrem')]
    procedure GetTenantUrl(): Text
    begin
        exit(UrlHelperImpl.GetTenantUrl);
    end;

    [Scope('OnPrem')]
    procedure GetAccountantHubUrl(): Text
    begin
        exit(UrlHelperImpl.GetAccountantHubUrl);
    end;

    [Scope('OnPrem')]
    procedure GetOfficePortalUrl(): Text
    begin
        exit(UrlHelperImpl.GetOfficePortalUrl);
    end;
}

