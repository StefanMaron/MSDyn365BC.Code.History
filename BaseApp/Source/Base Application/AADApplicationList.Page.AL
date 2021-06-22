page 9860 "AAD Application List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Azure Active Directory Applications', Comment = 'Azure Active Directory Application should not be translated';
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
                    ToolTip = 'Specifies the client ID of the app that the entry is for.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the app that the entry is for.';
                }
                field(State; State)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'State';
                    ToolTip = 'Specifies if the app is enabled or disabled.';
                }
            }
        }
    }
    actions
    {
    }
}