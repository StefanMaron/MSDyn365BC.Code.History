codeunit 2004 "Machine Learning KeyVaultMgmt."
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        LimitTypeOption: Option Year,Month,Day,Hour;

    [Scope('OnPrem')]
    procedure GetMachineLearningCredentials(SecretName: Text; var ApiUri: Text[250]; var ApiKey: Text[200]; var LimitType: Option; var Limit: Decimal)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        ApiKeyJArray: DotNet JArray;
        ApiUriJArray: DotNet JArray;
        JObject: DotNet JObject;
        SecretValue: Text;
        LimitTxt: Text;
        LimitTypeTxt: Text;
        Index: Integer;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(SecretName, SecretValue) then
            exit;

        JSONManagement.InitializeObject(SecretValue);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'Limit', LimitTxt);
        if LimitTxt <> '' then
            Evaluate(Limit, LimitTxt, 9);
        if not JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'LimitType', LimitTypeTxt) then
            LimitTypeTxt := 'Month';
        LimitType := GetLimitTypeOptionFromText(LimitTypeTxt);
        if not JSONManagement.GetArrayPropertyValueFromJObjectByName(JsonObject, 'ApiKeys', ApiKeyJArray) then
            exit;
        if not JSONManagement.GetArrayPropertyValueFromJObjectByName(JsonObject, 'ApiUris', ApiUriJArray) then
            exit;

        JSONManagement.InitializeCollectionFromJArray(ApiKeyJArray);
        if JSONManagement.GetCollectionCount > 0 then begin
            Index := Random(JSONManagement.GetCollectionCount) - 1;
            if JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index) then
                ApiKey := Format(JObject);
            JSONManagement.InitializeCollectionFromJArray(ApiUriJArray);
            if JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index) then
                ApiUri := Format(JObject);
        end;
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

