namespace System.AI;

using System.Environment;
using System.Integration;

page 4010 "Intelligent Cloud"
{
    Caption = 'Intelligent Cloud';
    Editable = false;
    PageType = Card;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            usercontrol(WebPageViewer; WebPageViewer)
            {
                ApplicationArea = Basic, Suite;
                Visible = ShowIntelligentCloud;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    AddInReady := true;
                    NavigateToUrl();
                end;

                trigger DocumentReady()
                begin
                end;

                trigger Callback(data: Text)
                begin
                end;

                trigger Refresh(callbackUrl: Text)
                begin
                    if AddInReady then
                        NavigateToUrl();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ShowIntelligentCloud := not EnvironmentInfo.IsSaaS();
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        AddInReady: Boolean;
        IntelligentCloudUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2009848&clcid=0x409', Locked = true;
        ShowIntelligentCloud: Boolean;

    local procedure NavigateToUrl()
    begin
        CurrPage.WebPageViewer.Navigate(IntelligentCloudUrlTxt);
    end;

    procedure GetIntelligentCloudInsightsUrl(): Text
    var
        BaseUrl: Text;
        ParameterUrl: Text;
        NoDomainUrl: Text;
    begin
        BaseUrl := GetUrl(CLIENTTYPE::Web);
        ParameterUrl := GetUrl(CLIENTTYPE::Web, '', OBJECTTYPE::Page, 4013);
        NoDomainUrl := DelChr(ParameterUrl, '<', BaseUrl);

        exit(StrSubstNo('https://businesscentral.dynamics.com/%1', NoDomainUrl));
    end;
}

