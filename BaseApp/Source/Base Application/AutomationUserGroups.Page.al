page 5443 "Automation User Groups"
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    Caption = 'userGroups', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'userGroup';
    EntitySetName = 'userGroups';
    InsertAllowed = false;
    PageType = API;
    SourceTable = "User Group";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'code', Locked = true;
                    Editable = false;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(defaultProfileID; "Default Profile ID")
                {
                    ApplicationArea = All;
                    Caption = 'defaultProfileID', Locked = true;
                }
                field(assignToAllNewUsers; "Assign to All New Users")
                {
                    ApplicationArea = All;
                    Caption = 'assignToAllNewUsers', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        BindSubscription(AutomationAPIManagement);
    end;

    var
        AutomationAPIManagement: Codeunit "Automation - API Management";
}

