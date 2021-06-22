page 6416 "Flow User Env. Selection"
{
    Caption = 'Flow User Environment Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Flow User Environment Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Environment Display Name"; "Environment Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Environment Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the environment.';

                    trigger OnDrillDown()
                    begin
                        EnsureOnlyOneSelection;
                    end;
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';

                    trigger OnValidate()
                    begin
                        EnsureOnlyOneSelection;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if IsEmpty then
            Error(FlowServiceManagement.GetGenericError);

        SortByEnvironmentNameAscending;
        FindFirst;
    end;

    var
        FlowServiceManagement: Codeunit "Flow Service Management";

    local procedure EnsureOnlyOneSelection()
    begin
        SetRange(Enabled, true);
        if Count >= 1 then
            ModifyAll(Enabled, false);

        Reset;
        Enabled := true;

        SortByEnvironmentNameAscending;
        CurrPage.Update;
    end;

    procedure SetFlowEnvironmentBuffer(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    begin
        // clear current REC and shallow copy TempFlowUserEnvironmentBuffer to it
        // ShareTable = TRUE and so since both TempFlowUserEnvironmentBuffer and Rec are temporary, COPY function causes Rec to reference the same
        // table as TempFlowUserEnvironmentBuffer. And so any changes to REC happens to TempFlowUserEnvironmentBuffer

        DeleteAll();
        Copy(TempFlowUserEnvironmentBuffer, true);
        Reset;
    end;

    local procedure SortByEnvironmentNameAscending()
    begin
        SetCurrentKey("Environment Display Name");
        SetAscending("Environment Display Name", true);
    end;
}

