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
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Fill the table with the links used by error handlers.';

                trigger OnAction()
                begin
                    Load;
                end;
            }
        }
    }
}

