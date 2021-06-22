page 9851 "Permission Set List"
{
    Caption = 'Permission Set List';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Permission Set Link" = d,
                  TableData "Aggregate Permission Set" = rimd;
    SourceTable = "Permission Set Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Permission Set';
                field(PermissionSet; "Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    Editable = false;
                    ToolTip = 'Specifies the permission set.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                }
                field("App Name"; "App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        FillRecordBuffer;
    end;
}

