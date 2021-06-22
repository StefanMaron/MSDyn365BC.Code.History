page 875 "Social Listening FactBox"
{
    Caption = 'Social Media Insights';
    PageType = CardPart;
    SourceTable = "Social Listening Search Topic";

    layout
    {
        area(content)
        {
            usercontrol(SocialListening; "Microsoft.Dynamics.Nav.Client.SocialListening")
            {
                ApplicationArea = Suite;

                trigger AddInReady()
                begin
                    IsAddInReady := true;
                    UpdateAddIn;
                end;

                trigger DetermineUserAuthenticationResult(result: Integer)
                begin
                    case result of
                        -1: // Error
                            CurrPage.SocialListening.ShowMessage(SocialListeningMgt.GetAuthenticationConectionErrorMsg);
                        0: // User is not authenticated
                            CurrPage.SocialListening.ShowMessage(SocialListeningMgt.GetAuthenticationUserErrorMsg);
                        1: // User is authenticated
                            CurrPage.SocialListening.ShowWidget(SocialListeningMgt.GetAuthenticationWidget("Search Topic"));
                    end;
                end;

                trigger MessageLinkClick(identifier: Integer)
                begin
                    case identifier of
                        1: // Refresh
                            UpdateAddIn;
                    end;
                end;
            }
        }
    }


    trigger OnAfterGetCurrRecord()
    begin
        IsDataReady := true;
        UpdateAddIn;
    end;

    var
        SocialListeningMgt: Codeunit "Social Listening Management";
        IsDataReady: Boolean;
        IsAddInReady: Boolean;

    local procedure UpdateAddIn()
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        if "Search Topic" = '' then
            exit;
        if not IsAddInReady then
            exit;

        if not IsDataReady then
            exit;

        if not SocialListeningSetup.Get or
           (SocialListeningSetup."Solution ID" = '')
        then
            exit;

        CurrPage.SocialListening.DetermineUserAuthentication(SocialListeningMgt.MSLAuthenticationStatusURL);
    end;
}

