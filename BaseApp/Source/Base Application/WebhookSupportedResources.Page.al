page 5460 "Webhook Supported Resources"
{
    APIGroup = 'runtime';
    APIPublisher = 'microsoft';
    Caption = 'webhookSupportedResources', Locked = true;
    DelayedInsert = true;
    Editable = false;
    EntityName = 'webhookSupportedResource';
    EntitySetName = 'webhookSupportedResources';
    Extensible = false;
    ODataKeyFields = "Value Long";
    PageType = API;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(resource; "Value Long")
                {
                    ApplicationArea = All;
                    Caption = 'resource', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        View: Text;
        I: Integer;
    begin
        if Initialized then
            exit(true);

        if not GraphMgtGeneralTools.IsApiSubscriptionEnabled then begin
            Initialized := true;
            exit(false);
        end;

        View := GetView;
        Reset;

        ApiWebhookEntity.SetRange("Object Type", ApiWebhookEntity."Object Type"::Page);
        ApiWebhookEntity.SetRange("Table Temporary", false);
        if not ApiWebhookEntity.FindSet then
            exit(false);

        repeat
            if not IsSystemTable(ApiWebhookEntity) then
                if not IsCompositeKey(ApiWebhookEntity) then begin
                    I += 1;
                    ID := I;
                    "Value Long" := CopyStr(GetResourceUri(ApiWebhookEntity), 1, MaxStrLen("Value Long"));
                    Insert;
                end;
        until ApiWebhookEntity.Next = 0;

        SetView(View);
        FindFirst;
        Initialized := true;
        exit(true);
    end;

    var
        Initialized: Boolean;

    local procedure IsSystemTable(var ApiWebhookEntity: Record "Api Webhook Entity"): Boolean
    begin
        exit(ApiWebhookEntity."Table No." > 2000000000);
    end;

    local procedure IsCompositeKey(var ApiWebhookEntity: Record "Api Webhook Entity"): Boolean
    begin
        exit(StrPos(ApiWebhookEntity."Key Fields", ',') > 0);
    end;

    local procedure GetResourceUri(var ApiWebhookEntity: Record "Api Webhook Entity"): Text
    begin
        if (ApiWebhookEntity.Publisher <> '') and (ApiWebhookEntity.Group <> '') then
            exit(StrSubstNo('%1/%2/%3/%4',
                ApiWebhookEntity.Publisher, ApiWebhookEntity.Group, ApiWebhookEntity.Version, ApiWebhookEntity.Name));
        exit(StrSubstNo('%1/%2', ApiWebhookEntity.Version, ApiWebhookEntity.Name));
    end;
}

