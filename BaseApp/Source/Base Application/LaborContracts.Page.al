page 17368 "Labor Contracts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Labor Contracts';
    CardPageID = "Labor Contract";
    Editable = false;
    PageType = List;
    SourceTable = "Labor Contract";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Person No."; "Person No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Person Name"; "Person Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contract Type"; "Contract Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Work Mode"; "Work Mode")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Open Contract Lines"; "Open Contract Lines")
                {
                    ApplicationArea = Basic, Suite;
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
        LaborContract: Record "Labor Contract";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(LaborContract);
        exit(SelectionFilterManagement.GetSelectionFilterForLaborContract(LaborContract));
    end;

    [Scope('OnPrem')]
    procedure SetSelection(var LaborContract: Record "Labor Contract")
    begin
        CurrPage.SetSelectionFilter(LaborContract);
    end;
}

