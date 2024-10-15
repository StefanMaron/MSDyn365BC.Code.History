namespace System.Environment.Configuration;

page 9860 "AAD Application List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Microsoft Entra Applications';
    CardPageId = "AAD Application Card";
    PageType = List;
    PopulateAllFields = true;
    Editable = false;
    SourceTable = "AAD Application";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Client ID"; Rec."Client Id")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Caption = 'Client ID';
                    ToolTip = 'Specifies the client ID of the app that the entry is for.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the app that the entry is for.';
                }
                field(State; Rec.State)
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