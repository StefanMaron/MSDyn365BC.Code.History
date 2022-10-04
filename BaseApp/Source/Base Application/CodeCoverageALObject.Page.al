page 9993 "Code Coverage AL Object"
{
    Caption = 'Objects';
    Editable = false;
    PageType = List;
    SourceTable = AllObj;
    SourceTableView = WHERE("Object Type" = FILTER(<> TableData));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Group';
                field(Type; "Object Type")
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type: for example, table, page, or query.';
                }
                field(ID; "Object ID")
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    ToolTip = 'Specifies the object ID.';
                }
                field(Name; "Object Name")
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the object associated with the code coverage.';
                }
                field("App Package ID"; Rec."App Package ID")
                {
                    ApplicationArea = All;
                    Caption = 'App Package ID';
                    ToolTip = 'Specifies the GUID of the app from which the object originated.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Load)
            {
                ApplicationArea = All;
                Caption = 'Load';
                Image = AddContacts;
                ToolTip = 'Force the code coverage recorder to include the filtered objects.';

                trigger OnAction()
                var
                    AllObj: Record AllObj;
                    CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
                begin
                    AllObj.CopyFilters(Rec);
                    CodeCoverageMgt.Include(AllObj);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Load_Promoted; Load)
                {
                }
            }
        }
    }
}

