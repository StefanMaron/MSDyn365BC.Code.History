page 20004 "APIV1 - Aut. Users"
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    APIVersion = 'v1.0';
    Caption = 'user', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'user';
    EntitySetName = 'users';
    InsertAllowed = false;
    PageType = API;
    SourceTable = 2000000120;
    Extensible = false;

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
                part(userGroupMember; 5442)
                {
                    ApplicationArea = All;
                    Caption = 'userGroupMember', Locked = true;
                    EntityName = 'userGroupMember';
                    EntitySetName = 'userGroupMembers';
                    SubPageLink = "User Security ID" = FIELD("User Security ID");
                }
                part(userPermission; 5446)
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
        EnvironmentInfo: Codeunit 457;
    begin
        BINDSUBSCRIPTION(AutomationAPIManagement);
        IF EnvironmentInfo.IsSaaS() THEN
            SETFILTER("License Type", '<>%1', "License Type"::"External User");
    end;

    var
        AutomationAPIManagement: Codeunit "Automation - API Management";
}

