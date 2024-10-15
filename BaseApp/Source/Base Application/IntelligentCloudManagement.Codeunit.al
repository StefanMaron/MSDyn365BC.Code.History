namespace System.AI;

codeunit 4009 "Intelligent Cloud Management"
{
    // // Intelligent Cloud


    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure GetIntelligentCloudInsightsUrl(): Text
    var
        BaseUrl: Text;
        ParameterUrl: Text;
        NoDomainUrl: Text;
    begin
        BaseUrl := GetUrl(CLIENTTYPE::Web);
        ParameterUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 4013);
        NoDomainUrl := DelChr(ParameterUrl, '<', BaseUrl);

        exit(StrSubstNo('https://businesscentral.dynamics.com/%1', NoDomainUrl));
    end;

    [Scope('OnPrem')]
    procedure GetIntelligentCloudLearnMoreUrl(): Text
    begin
        exit('https://go.microsoft.com/fwlink/?linkid=2009848&clcid=0x409');
    end;
}

