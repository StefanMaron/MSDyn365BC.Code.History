page 1431 "Forward Links"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Forward Links';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Named Forward Link";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Link; Link)
                {
                    ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
                Caption = 'Load';
                Image = Import;
                ToolTip = 'Fill the table with the links used by error handlers.';

                trigger OnAction()
                begin
                    Load();
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

