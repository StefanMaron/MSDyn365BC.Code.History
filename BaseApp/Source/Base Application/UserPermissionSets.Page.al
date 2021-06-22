page 9808 "User Permission Sets"
{
    Caption = 'User Permission Sets';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Access Control";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'User Permissions';
                field(UserSecurityID; "User Security ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Security ID';
                    Editable = false;
                    ToolTip = 'Specifies the Windows security identification (SID) of each Windows login that has been created in the current database.';
                    Visible = false;
                }
                field(PermissionSet; "Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the ID of a security role that has been assigned to this Windows login in the current database.';
                }
                field(Description; "Role Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the security role that has been given to this Windows login in the current database.';
                }
                field(Company; "Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the name of the company that this role is limited to for this Windows login.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(ShowPermissions)
            {
                Caption = 'Show Permissions';
                action(Permissions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permissions';
                    Image = Permission;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page Permissions;
                    RunPageLink = "Role ID" = FIELD("Role ID");
                    ToolTip = 'View or edit a general listing of database objects and their access representing permissions that can be organized in permission sets to be assigned to users. NOTE: To view or edit the actual permissions that this user has through assigned permission sets, choose the Effective Permissions action.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if User."User Name" <> '' then
            CurrPage.Caption := User."User Name";
    end;

    var
        User: Record User;
}

