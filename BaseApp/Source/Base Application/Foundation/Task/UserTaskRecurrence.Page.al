namespace Microsoft.Foundation.Task;

page 1172 "User Task Recurrence"
{
    Caption = 'User Task Recurrence';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            field(RecurringStartDate; RecurringStartDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recurring Start Date';
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies the start date for the recurrence.';
            }
            field(Recurrence; Recurrence)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recurrence';
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies the recurrence pattern, such as 20D if the task must recur every 20 days.';
            }
            field(Occurrences; Occurrences)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Occurrences';
                MaxValue = 99;
                MinValue = 1;
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies the number of occurrences.';
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            UserTask.CreateRecurrence(RecurringStartDate, Recurrence, Occurrences);
    end;

    var
        UserTask: Record "User Task";
        Recurrence: DateFormula;
        RecurringStartDate: Date;
        Occurrences: Integer;

    procedure SetInitialData(UserTask2: Record "User Task")
    begin
        Clear(UserTask);
        UserTask := UserTask2;
        Occurrences := 1;
    end;
}

