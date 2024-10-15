page 10862 "View/Edit Payment Line"
{
    Caption = 'View/Edit Payment Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Payment Status";
    SourceTableView = WHERE(Look = CONST(true));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Payment Class"; "Payment Class")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the payment class.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies text to describe the payment status.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Payment Lines List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Lines List';
                Image = ListPage;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Payment Lines List";
                RunPageLink = "Payment Class" = FIELD("Payment Class"),
                              "Status No." = FIELD(Line),
                              "Copied To No." = FILTER('');
                ToolTip = 'View line information for payments and collections.';
            }
        }
    }
}

