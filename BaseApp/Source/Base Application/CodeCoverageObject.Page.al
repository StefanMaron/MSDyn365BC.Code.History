page 9992 "Code Coverage Object"
{
    Caption = 'Objects';
    Editable = false;
    PageType = List;
    SourceTable = "Object";
    SourceTableView = WHERE(Type = FILTER(<> TableData));
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with the Code Coverage AL Object page';
    ObsoleteTag = '15.2';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Group';
                field(Type; Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type: for example, table, page, or query.';
                }
                field(ID; ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    ToolTip = 'Specifies the object ID.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the object associated with the code coverage.';
                }
                field(Modified; Modified)
                {
                    ApplicationArea = All;
                    Caption = 'Modified';
                    ToolTip = 'Specifies whether the object on the line has been modified.';
                }
                field(Compiled; Compiled)
                {
                    ApplicationArea = All;
                    Caption = 'Compiled';
                    ToolTip = 'Specifies whether or not the items on the list have been compiled.';
                }
                field(Date; Date)
                {
                    ApplicationArea = All;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date relating to tracking code coverage.';
                }
                field("Version List"; "Version List")
                {
                    ApplicationArea = All;
                    Caption = 'Version List';
                    ToolTip = 'Specifies the version list.';
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View the availability of the machine or work center, including its the capacity, the allocated quantity, availability after orders, and the load in percent of its total capacity.';

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
    }
}

