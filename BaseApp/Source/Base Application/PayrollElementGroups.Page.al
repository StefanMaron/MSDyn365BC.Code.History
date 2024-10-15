page 17448 "Payroll Element Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Element Groups';
    PageType = List;
    SourceTable = "Payroll Element Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure GetSelectionFilter(): Text
    var
        PayrollElementGroup: Record "Payroll Element Group";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(PayrollElementGroup);
        exit(SelectionFilterManagement.GetSelectionFilterForPayrollElementGroup(PayrollElementGroup));
    end;

    [Scope('OnPrem')]
    procedure SetSelection(var PayrollElementGroup: Record "Payroll Element Group")
    begin
        CurrPage.SetSelectionFilter(PayrollElementGroup);
    end;
}

