page 9860 "AAD Application List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'AAD Applications', Comment = 'AAD Application should not be translated';
    CardPageId = "AAD Application Card";
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "AAD Application";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Client ID"; "Client Id")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Caption = 'Client ID';
                    ToolTip = 'Specifies a client ID.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Caption = 'Description';
                    ToolTip = 'Specifies description.';
                }
                field(State; State)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'State';
                    ToolTip = 'Specifies an application ID.';
                }

            }
        }
    }
    actions
    {
    }
}