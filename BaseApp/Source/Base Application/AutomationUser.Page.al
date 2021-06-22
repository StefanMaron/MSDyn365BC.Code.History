page 5444 "Automation User"
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    Caption = 'user', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'user';
    EntitySetName = 'users';
    InsertAllowed = false;
    PageType = API;
    SourceTable = User;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(userSecurityId; "User Security ID")
                {
                    ApplicationArea = All;
                    Caption = 'userSecurityId', Locked = true;
                    Editable = false;
                }
                field(userName; "User Name")
                {
                    ApplicationArea = All;
                    Caption = 'userName', Locked = true;
                    Editable = false;
                }
                field(displayName; "Full Name")
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    Editable = false;
                }
                field(state; State)
                {
                    ApplicationArea = All;
                    Caption = 'state', Locked = true;
                }
                field(expiryDate; "Expiry Date")
                {
                    ApplicationArea = All;
                    Caption = 'expiryDate', Locked = true;
                }
                part(userGroupMember; "Automation User Group Member")
                {
                    ApplicationArea = All;
                    Caption = 'userGroupMember', Locked = true;
                    EntityName = 'userGroupMember';
                    EntitySetName = 'userGroupMembers';
                    SubPageLink = "User Security ID" = FIELD("User Security ID");
                }
                part(userPermission; "Automation User Permission")
                {
                    ApplicationArea = All;
                    Caption = 'userPermission', Locked = true;
                    EntityName = 'userPermission';
                    EntitySetName = 'userPermissions';
                    SubPageLink = "User Security ID" = FIELD("User Security ID");
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        BindSubscription(AutomationAPIManagement);
        if EnvironmentInfo.IsSaaS then
            SetFilter("License Type", '<>%1', "License Type"::"External User");
    end;

    var
        AutomationAPIManagement: Codeunit "Automation - API Management";
}

