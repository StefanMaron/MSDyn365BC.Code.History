codeunit 1298 "OAuth Management"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Functionality has been moved to <<OAuth>> System module';
    ObsoleteTag = '16.0';

    trigger OnRun()
    begin
    end;

    procedure GetRequestToken(ConsumerKey: Text; ConsumerSecret: Text; RequestTokenUrl: Text; CallbackUrl: Text; var RequestTokenKey: Text; var RequestTokenSecret: Text)
    var
        OAuthAuthorization: DotNet OAuthAuthorization;
        Consumer: DotNet Consumer;
        Token: DotNet Token;
        RequestToken: DotNet Token;
    begin
        Token := Token.Token('', '');
        Consumer := Consumer.Consumer(ConsumerKey, ConsumerSecret);
        OAuthAuthorization := OAuthAuthorization.OAuthAuthorization(Consumer, Token);

        RequestToken := OAuthAuthorization.GetRequestToken(RequestTokenUrl, CallbackUrl);

        RequestTokenKey := RequestToken.TokenKey;
        RequestTokenSecret := RequestToken.TokenSecret;
    end;

    procedure GetAccessToken(AccessTokenUrl: Text; Verifier: Text; ConsumerKey: Text; ConsumerSecret: Text; RequestTokenKey: Text; RequestTokenSecret: Text; var AccessTokenKey: Text; var AccessTokenSecret: Text)
    var
        OAuthAuthorization: DotNet OAuthAuthorization;
        Consumer: DotNet Consumer;
        RequestToken: DotNet Token;
        AccessToken: DotNet Token;
    begin
        RequestToken := RequestToken.Token(RequestTokenKey, RequestTokenSecret);
        Consumer := Consumer.Consumer(ConsumerKey, ConsumerSecret);
        OAuthAuthorization := OAuthAuthorization.OAuthAuthorization(Consumer, RequestToken);

        AccessToken := OAuthAuthorization.GetAccessToken(AccessTokenUrl, Verifier);

        AccessTokenKey := AccessToken.TokenKey;
        AccessTokenSecret := AccessToken.TokenSecret;
    end;

    procedure GetAuthorizationHeader(ConsumerKey: Text; ConsumerSecret: Text; AccessTokenKey: Text; AccessTokenSecret: Text; RequestUrl: Text; RequestMethod: Text) AuthorizationHeader: Text
    var
        OAuthAuthorization: DotNet OAuthAuthorization;
        Consumer: DotNet Consumer;
        AccessToken: DotNet Token;
    begin
        AccessToken := AccessToken.Token(AccessTokenKey, AccessTokenSecret);
        Consumer := Consumer.Consumer(ConsumerKey, ConsumerSecret);
        OAuthAuthorization := OAuthAuthorization.OAuthAuthorization(Consumer, AccessToken);

        AuthorizationHeader := OAuthAuthorization.GetAuthorizationHeader(RequestUrl, UpperCase(RequestMethod));
    end;

    procedure GetPropertyFromCode("Code": Text; Property: Text) Value: Text
    var
        I: Integer;
        NumberOfProperties: Integer;
    begin
        Code := ConvertStr(Code, '&', ',');
        Code := ConvertStr(Code, '=', ',');
        NumberOfProperties := Round((StrLen(Code) - StrLen(DelChr(Code, '=', ','))) / 2, 1, '>');
        for I := 1 to NumberOfProperties do begin
            if SelectStr(2 * I - 1, Code) = Property then
                Value := SelectStr(2 * I, Code);
        end;
    end;
}

