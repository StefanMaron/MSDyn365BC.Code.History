codeunit 2004 "Machine Learning KeyVaultMgmt."
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        LimitTypeOption: Option Year,Month,Day,Hour;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetMachineLearningCredentials(SecretName: Text; var ApiUri: Text[250]; var ApiKey: Text[200]; var LimitType: Option; var Limit: Decimal)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SecretObject: JsonObject;
        ApiKeys: JsonArray;
        ApiUris: JsonArray;
        RandomIndex: Integer;
        SecretValue: Text;
        LimitTxt: Text;
        LimitTypeTxt: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(SecretName, SecretValue) then
            exit;

        // check if the secret is a properly formatted JSON object
        if not SecretObject.ReadFrom(SecretValue) then
            exit;

        GetAsText(SecretObject, 'Limit', LimitTxt);
        if LimitTxt <> '' then
            Evaluate(Limit, LimitTxt, 9);

        GetAsText(SecretObject, 'LimitType', LimitTxt);
        if LimitTypeTxt = '' then
            LimitTypeTxt := 'Month';

        LimitType := GetLimitTypeOptionFromText(LimitTypeTxt);

        if not GetAsArray(SecretObject, 'ApiKeys', ApiKeys) then
            exit;

        if not GetAsArray(SecretObject, 'ApiUris', ApiUris) then
            exit;

        if (ApiKeys.Count() = 0) or (ApiUris.Count() = 0) then
            exit;

        RandomIndex := Random(ApiKeys.Count()) - 1;
        GetAsText(ApiKeys, RandomIndex, ApiKey);
        GetAsText(ApiUris, RandomIndex, ApiUri);
    end;

    [NonDebuggable]
    local procedure GetAsText(JArray: JsonArray; Index: Integer; var Result: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JArray.Get(Index, JToken) then
            exit(false);

        exit(GetAsText(JToken, Result));
    end;

    [NonDebuggable]
    local procedure GetAsText(JObject: JsonObject; PropertyKey: Text; var Result: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyKey, JToken) then
            exit(false);

        exit(GetAsText(JToken, Result));
    end;

    [NonDebuggable]
    local procedure GetAsText(JToken: JsonToken; var Result: Text): Boolean
    var
        JValue: JsonValue;
    begin
        if not JToken.IsValue() then
            exit(false);

        JValue := JToken.AsValue();
        if JValue.IsUndefined() or JValue.IsNull() then
            exit(false);

        Result := JValue.AsText();
        exit(true);
    end;

    [NonDebuggable]
    local procedure GetAsArray(JObject: JsonObject; PropertyKey: Text; var Result: JsonArray): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyKey, JToken) then
            exit(false);

        if not JToken.IsArray() then
            exit(false);

        Result := JToken.AsArray();
        exit(true);
    end;

    procedure GetLimitTypeOptionFromText(LimitTypeTxt: Text): Integer
    begin
        case LimitTypeTxt of
            'Year':
                exit(LimitTypeOption::Year);
            'Month':
                exit(LimitTypeOption::Month);
            'Day':
                exit(LimitTypeOption::Day);
            'Hour':
                exit(LimitTypeOption::Hour);
        end;
    end;
}

