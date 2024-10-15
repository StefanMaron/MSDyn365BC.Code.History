namespace Microsoft.Sales.Customer;

page 166 "Dispute Status"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Dispute Status';
    PageType = List;
    SourceTable = "Dispute Status";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a dispture status code that you can select.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an explanation of the dispute status.';
                }
                field("Overwrite on hold"; Rec."Overwrite on hold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this dispute status should update the on hold value on the corresponding customer ledger entry.';
                }
            }

        }
    }
}
