page 17355 "Employee Category"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Employee Category';
    PageType = List;
    SourceTable = "Employee Category";
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
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("C&ategory")
            {
                Caption = 'C&ategory';
                action("Default Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Contract Terms';
                    Image = Default;
                    RunObject = Page "Default Labor Contract Terms";
                    RunPageLink = "Category Code" = FIELD(Code);
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;
}

