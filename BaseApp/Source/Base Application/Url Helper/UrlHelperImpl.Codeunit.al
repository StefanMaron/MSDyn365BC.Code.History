codeunit 3704 "Url Helper Impl."
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure IsPPE(): Boolean
    var
        Url: Text;
    begin
        Url := LowerCase(GetUrl(CLIENTTYPE::Web));
        exit(
          (StrPos(Url, 'projectmadeira-test') <> 0) or (StrPos(Url, 'projectmadeira-ppe') <> 0) or
          (StrPos(Url, 'financials.dynamics-tie.com') <> 0) or (StrPos(Url, 'financials.dynamics-ppe.com') <> 0) or
          (StrPos(Url, 'invoicing.officeppe.com') <> 0) or (StrPos(Url, 'businesscentral.dynamics-tie.com') <> 0) or
          (StrPos(Url, 'businesscentral.dynamics-ppe.com') <> 0));
    end;

    [Scope('OnPrem')]
    procedure IsPROD(): Boolean
    var
        Url: Text;
    begin
        Url := LowerCase(GetUrl(CLIENTTYPE::Web));
        exit(
          (StrPos(Url, 'financials.dynamics.com') <> 0) or (StrPos(Url, 'invoicing.office.net') <> 0) or
          (StrPos(Url, 'businesscentral.dynamics.com') <> 0));
    end;

    [Scope('OnPrem')]
    procedure IsTIE(): Boolean
    var
        Url: Text;
    begin
        Url := LowerCase(GetUrl(CLIENTTYPE::Web));
        exit(
          (StrPos(Url, 'financials.dynamics-servicestie.com') <> 0) or (StrPos(Url, 'invoicing.office-int.com') <> 0) or
          (StrPos(Url, 'businesscentral.dynamics-servicestie.com') <> 0));
    end;

    local procedure IsPartnerPROD(): Boolean
    var
        Url: Text;
    begin
        Url := LowerCase(GetUrl(CLIENTTYPE::Web));
        exit(StrPos(Url, 'bc.dynamics.com') <> 0);
    end;

    [Scope('OnPrem')]
    procedure GetFixedClientEndpointBaseUrl(): Text
    var
        Url: Text;
    begin
        Url := GetUrl(ClientType::Web);
        Url := Url.Remove(Url.IndexOf('.com/') + 5);  // Remove the ?tenant info.  Should return something like https://businesscentral.dynamics.com/
        exit(Url);
    end;

    [Scope('OnPrem')]
    procedure GetFixedEndpointWebServiceUrl(): Text
    begin
        if IsPPE then
            exit('https://api.businesscentral.dynamics-tie.com');
        if IsTIE then
            exit('https://api.businesscentral.dynamics-servicestie.com');
        if IsPROD then
            exit('https://api.businesscentral.dynamics.com');
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetGraphUrl(): Text
    begin
        if IsTIE or IsPPE then
            exit('https://graph.microsoft-ppe.com/');

        if IsPROD then
            exit('https://graph.microsoft.com/');
    end;

    [Scope('OnPrem')]
    procedure GetAzureADAuthEndpoint(): Text
    begin
        if IsPPE then
            exit('https://login.windows-ppe.net/common/oauth2/authorize');

        exit('https://login.microsoftonline.com/common/oauth2/authorize');
    end;

    [Scope('OnPrem')]
    procedure GetO365Resource() Resource: Text
    begin
        if IsPPE then
            Resource := 'https://edgesdf.outlook.com'
        else
            Resource := 'https://outlook.office365.com';
    end;

    [Scope('OnPrem')]
    procedure GetPowerBIResourceUrl(): Text
    begin
        if IsPPE then
            exit('https://analysis.windows-int.net/powerbi/api');

        exit('https://analysis.windows.net/powerbi/api');
    end;

    [Scope('OnPrem')]
    procedure GetPowerBIApiUrl(): Text
    begin
        if IsPPE then
            exit('https://biazure-int-edog-redirect.analysis-df.windows.net');

        exit('https://api.powerbi.com');
    end;

    [Scope('OnPrem')]
    procedure GetPowerBIReportsUrl(): Text
    begin
        if IsPPE then
            exit('https://biazure-int-edog-redirect.analysis-df.windows.net/beta/myorg/reports');

        exit('https://api.powerbi.com/beta/myorg/reports');
    end;

    [Scope('OnPrem')]
    procedure GetPowerBIEmbedReportsUrl(): Text
    begin
        if IsPPE then
            exit('https://biazure-int-edog-redirect.analysis-df.windows.net/beta/myorg/reports');

        exit('https://app.powerbi.com/reportEmbed');
    end;

    [Scope('OnPrem')]
    procedure GetExcelAddinProviderServiceUrl(): Text
    begin
        if IsPPE then
            exit('https://exceladdinprovider.smb.dynamics-tie.com');
        exit('https://exceladdinprovider.smb.dynamics.com');
    end;

    [Scope('OnPrem')]
    procedure GetTenantUrl(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        Url: Text;
    begin
        Url := GetFixedClientEndpointBaseUrl;
        if Url <> '' then
            exit(Url + AzureADTenant.GetAadTenantId);
        if IsPartnerPROD then
            exit(LowerCase(GetUrl(CLIENTTYPE::Web)));

        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetAccountantHubUrl(): Text
    begin
        if IsPPE then
            exit('https://accountants.dynamics-tie.com');

        exit('https://accountants.dynamics.com');
    end;

    [Scope('OnPrem')]
    procedure GetOfficePortalUrl(): Text
    begin
        if IsPPE then
            exit('https://go.microsoft.com/fwlink/?linkid=844935');

        exit('https://go.microsoft.com/fwlink/?linkid=844936');
    end;
}

