codeunit 5444 "Graph Business Setting"
{

    trigger OnRun()
    begin
    end;

    var
        BusinessSettingReadWriteRoleTxt: Label 'BusinessProfiles-Internal.ReadWrite', Locked = true;
        RegisterConnectionsTxt: Label 'Registering connections for Business Setting.', Locked = true;
        NoGraphAccessTxt: Label 'Error accessing the Graph Business Setting table. %1', Comment = '%1 - The error message.', Locked = true;

    [Scope('OnPrem')]
    procedure GetMSPayBusinessSetting() MSPayData: Text
    var
        GraphBusinessSetting: Record "Graph Business Setting";
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        ConnectionId: Text;
    begin
        SendTraceTag(
          '00001WD', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
          RegisterConnectionsTxt, DATACLASSIFICATION::SystemMetadata);

        ConnectionId := Format(CreateGuid);
        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        if GraphBusinessSetting.IsEmpty then
            SendTraceTag(
              '00001WE', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Error,
              StrSubstNo(NoGraphAccessTxt, GetLastErrorText), DATACLASSIFICATION::CustomerContent);

        MSPayData := GetMSPayData(GraphBusinessSetting);
        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    local procedure EntityEndpoint(): Text[250]
    begin
        exit('https://outlook.office365.com/SmallBusiness/api/v1/users(''{SHAREDCONTACTS}'')/BusinessSettings');
    end;

    local procedure EntityListEndpoint(): Text[250]
    begin
        exit('https://outlook.office365.com/SmallBusiness/api/v1/users(''{SHAREDCONTACTS}'')/BusinessSettings');
    end;

    local procedure ResourceUri(): Text
    begin
        exit('https://outlook.office365.com');
    end;

    local procedure GetConnectionString() ConnectionString: Text
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        ConnectionString := GraphConnectionSetup.ConstructConnectionString(EntityEndpoint, EntityListEndpoint,
            ResourceUri, BusinessSettingReadWriteRoleTxt);
    end;

    local procedure GetMSPayData(var GraphBusinessSetting: Record "Graph Business Setting") MSPayData: Text
    begin
        if GraphBusinessSetting.FindSet then
            repeat
                if (GraphBusinessSetting.Name = 'BusinessCenter_System_MicrosoftPaySettings') and
                   (GraphBusinessSetting.Scope = 'System')
                then begin
                    MSPayData := GraphBusinessSetting.GetDataString;
                    exit;
                end
            until GraphBusinessSetting.Next = 0;
    end;
}

