#if not CLEAN19
page 890 "SmartList Designer Setup Part"
{
    PageType = CardPart;
    Caption = 'SmartList Designer Setup Part';
    Extensible = false;
    SourceTable = "SmartList Designer Setup";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ObsoleteTag = '19.0';

    layout
    {
        area(Content)
        {
            field(PowerAppId; PowerAppId)
            {
                ApplicationArea = All;
                Caption = 'SmartList Designer App ID';
                ToolTip = 'The ID of the SmartList Designer PowerApp';
            }

            field(PowerAppTenantId; PowerAppTenantId)
            {
                Caption = 'Azure AD Tenant ID';
                ApplicationArea = All;
                ToolTip = 'The Azure AD tenant identifier of your organization';
            }
        }
    }

    trigger OnInit()
    var
        SetupRec: Record "SmartList Designer Setup";
    begin
        Init();
        if SetupRec.Get() then
            Copy(SetupRec);

        Insert();
    end;

    trigger OnAfterGetCurrRecord()
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        TempId: Guid;
    begin
        if IsNullGuid(PowerAppTenantId) and Evaluate(TempId, AzureADTenant.GetAadTenantId()) then
            PowerAppTenantId := TempId;
    end;
}
#endif