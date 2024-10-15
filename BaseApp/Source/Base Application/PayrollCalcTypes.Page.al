page 17405 "Payroll Calc Types"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Calc Type List';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payroll Calc Type";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Use in Calc"; "Use in Calc")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Priority; Priority)
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
            action(Elements)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Elements';
                Image = BulletList;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Payroll Calc Type Lines";
                RunPageLink = "Calc Type Code" = FIELD(Code);
            }
        }
    }
}

