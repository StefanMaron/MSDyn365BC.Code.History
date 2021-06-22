codeunit 871 "Social Listening Management"
{

    trigger OnRun()
    begin
    end;

    var
        MslProductNameTxt: Label 'Microsoft Social Engagement', Locked = true;
        FailedToConnectTxt: Label 'Failed to connect to %1.<br><br>Verify the configuration of %1 in %3.<br><br>Afterwards %2 to try connecting to %1 again.', Comment = '%1 = Microsoft Social Engagement, %2 = refresh, %3 - product name';
        HasNotBeenAuthenticatedTxt: Label '%1 has not been authenticated.<br><br>Go to %2 to open the authentication window.<br><br>Afterwards %3 to show data.', Comment = '%1 = Microsoft Social Engagement, %2= Microsoft Social Engagement,%3 = refresh';
        ExpectedValueErr: Label 'Expected value should be an integer or url path containing %2 in %1.';
        RefreshTxt: Label 'refresh';

    procedure GetSignupURL(): Text[250]
    begin
        exit('http://go.microsoft.com/fwlink/p/?LinkId=401462');
    end;

    procedure GetTermsOfUseURL(): Text[250]
    begin
        exit('http://go.microsoft.com/fwlink/?LinkID=389042');
    end;

    procedure GetMSL_URL(): Text[250]
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        with SocialListeningSetup do begin
            if Get and ("Social Listening URL" <> '') then
                exit(CopyStr("Social Listening URL", 1, StrPos("Social Listening URL", '/app/') - 1));
            TestField("Social Listening URL");
        end;
    end;

    procedure GetMSLAppURL(): Text[250]
    begin
        exit(StrSubstNo('%1/app/%2/', GetMSL_URL, GetMSLSubscriptionID));
    end;

    procedure MSLUsersURL(): Text
    begin
        exit(StrSubstNo('%1/settings/%2/?locale=%3#page:users', GetMSL_URL, GetMSLSubscriptionID, GetLanguage));
    end;

    procedure MSLSearchItemsURL(): Text
    begin
        exit(StrSubstNo('%1/app/%2/?locale=%3#search:topics', GetMSL_URL, GetMSLSubscriptionID, GetLanguage));
    end;

    local procedure MSLAuthenticationURL(): Text
    begin
        exit(StrSubstNo('%1/widgetapi/%2/authenticate.htm?lang=%3', GetMSL_URL, GetMSLSubscriptionID, GetLanguage));
    end;

    procedure MSLAuthenticationStatusURL(): Text
    begin
        exit(StrSubstNo('%1/widgetapi/%2/auth_status.htm?lang=%3', GetMSL_URL, GetMSLSubscriptionID, GetLanguage));
    end;

    procedure GetAuthenticationWidget(SearchTopic: Text): Text
    begin
        exit(
          StrSubstNo(
            '%1/widgetapi/%2/?locale=%3#analytics:overview?date=today&nodeId=%4',
            GetMSL_URL, GetMSLSubscriptionID, GetLanguage, SearchTopic));
    end;

    local procedure GetAuthenticationLink(): Text
    begin
        exit(
          StrSubstNo(
            '<a style="text-decoration: none" href="javascript:;" onclick="openAuthenticationWindow(''%1'');">%2</a>',
            MSLAuthenticationURL, MslProductNameTxt));
    end;

    local procedure GetRefreshLink(): Text
    begin
        exit(StrSubstNo('<a style="text-decoration: none" href="javascript:;" onclick="raiseMessageLinkClick(1);">%1</a>', RefreshTxt));
    end;

    local procedure GetMSLSubscriptionID(): Text[250]
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        SocialListeningSetup.Get();
        SocialListeningSetup.TestField("Solution ID");
        exit(SocialListeningSetup."Solution ID");
    end;

    local procedure GetLanguage(): Text
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.CultureInfo(GlobalLanguage);
        exit(CultureInfo.TwoLetterISOLanguageName);
    end;

    procedure GetAuthenticationConectionErrorMsg(): Text
    begin
        exit(StrSubstNo(FailedToConnectTxt, MslProductNameTxt, GetRefreshLink, PRODUCTNAME.Full));
    end;

    procedure GetAuthenticationUserErrorMsg(): Text
    begin
        exit(StrSubstNo(HasNotBeenAuthenticatedTxt, MslProductNameTxt, GetAuthenticationLink, GetRefreshLink));
    end;

    procedure GetCustFactboxVisibility(Cust: Record Customer; var MSLSetupVisibility: Boolean; var MSLVisibility: Boolean)
    var
        SocialListeningSetup: Record "Social Listening Setup";
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
    begin
        with SocialListeningSetup do
            MSLSetupVisibility := Get and "Show on Customers" and "Accept License Agreement" and ("Solution ID" <> '');

        if MSLSetupVisibility then
            with SocialListeningSearchTopic do
                MSLVisibility := FindSearchTopic("Source Type"::Customer, Cust."No.") and ("Search Topic" <> '')
    end;

    procedure GetVendFactboxVisibility(Vend: Record Vendor; var MSLSetupVisibility: Boolean; var MSLVisibility: Boolean)
    var
        SocialListeningSetup: Record "Social Listening Setup";
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
    begin
        with SocialListeningSetup do
            MSLSetupVisibility := Get and "Show on Vendors" and "Accept License Agreement" and ("Solution ID" <> '');

        if MSLSetupVisibility then
            with SocialListeningSearchTopic do
                MSLVisibility := FindSearchTopic("Source Type"::Vendor, Vend."No.") and ("Search Topic" <> '');
    end;

    procedure GetItemFactboxVisibility(Item: Record Item; var MSLSetupVisibility: Boolean; var MSLVisibility: Boolean)
    var
        SocialListeningSetup: Record "Social Listening Setup";
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
    begin
        with SocialListeningSetup do
            MSLSetupVisibility := Get and "Show on Items" and "Accept License Agreement" and ("Solution ID" <> '');

        if MSLSetupVisibility then
            with SocialListeningSearchTopic do
                MSLVisibility := FindSearchTopic("Source Type"::Item, Item."No.") and ("Search Topic" <> '');
    end;

    procedure ConvertURLToID(URL: Text; where: Text): Text[250]
    var
        i: Integer;
        j: Integer;
        PositionOfID: Integer;
        ID: Text;
        IntegerValue: Integer;
    begin
        if URL = '' then
            exit(URL);
        if Evaluate(IntegerValue, URL) then
            exit(URL);

        PositionOfID := StrPos(LowerCase(URL), LowerCase(where));
        if PositionOfID = 0 then
            Error(ExpectedValueErr, where, URL);

        j := 1;
        for i := PositionOfID + StrLen(where) to StrLen(URL) do begin
            if not (URL[i] in ['0' .. '9']) then
                break;

            ID[j] := URL[i];
            j += 1;
        end;

        if ID = '' then
            Error(ExpectedValueErr, where, LowerCase(GetMSL_URL));
        exit(ID);
    end;

    [EventSubscriber(ObjectType::Table, 1400, 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleMSERegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        SocialListeningSetup: Record "Social Listening Setup";
        EnvironmentInfo: Codeunit "Environment Information";
        RecRef: RecordRef;
    begin
        if EnvironmentInfo.IsSaaS then
            exit;

        SocialListeningSetup.Get();
        RecRef.GetTable(SocialListeningSetup);

        with SocialListeningSetup do begin
            ServiceConnection.Status := ServiceConnection.Status::Enabled;
            if not "Show on Items" and not "Show on Customers" and not "Show on Vendors" then
                ServiceConnection.Status := ServiceConnection.Status::Disabled;
            ServiceConnection.InsertServiceConnection(
              ServiceConnection, RecRef.RecordId, TableCaption, "Social Listening URL", PAGE::"Social Listening Setup");
        end;
    end;

    procedure CheckURLPath(URL: Text; where: Text)
    var
        IntegerValue: Integer;
    begin
        if URL = '' then
            exit;
        if Evaluate(IntegerValue, URL) then
            exit;

        if StrPos(LowerCase(URL), LowerCase(GetMSL_URL)) = 0 then
            Error(ExpectedValueErr, where, LowerCase(GetMSL_URL));
    end;
}

