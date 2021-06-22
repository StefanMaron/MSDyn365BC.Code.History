page 6415 "Flow Service Configuration"
{
    Caption = 'Flow Service Configuration';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = NavigatePage;
    Permissions = TableData "Flow Service Configuration" = rimd;
    SourceTable = "Flow Service Configuration";

    layout
    {
        area(content)
        {
            field("Flow Service"; "Flow Service")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Flow Service';
                ToolTip = 'Specifies the flow service configuration: Production Service, Testing Service (TIP 1), or Testing Service (TIP 2).';
            }
        }
    }

    actions
    {
    }

    trigger OnModifyRecord(): Boolean
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        if FlowUserEnvironmentConfig.Get(UserSecurityId) then
            FlowUserEnvironmentConfig.Delete();
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

