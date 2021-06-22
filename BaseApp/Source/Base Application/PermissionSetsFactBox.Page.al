page 9817 "Permission Sets FactBox"
{
    Caption = 'Permission Sets';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Access Control";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'User Permissions';
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
                    Visible = false;
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
    }

    trigger OnAfterGetRecord()
    begin
        if User."User Name" <> '' then
            CurrPage.Caption := User."User Name";
    end;

    var
        User: Record User;
}

