page 578 "Change Global Dim. Log Entries"
{
    Caption = 'Log Entries';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Change Global Dim. Log Entry";
    SourceTableView = SORTING(Progress)
                      WHERE("Table ID" = FILTER(> 0));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Suite;
                    StyleExpr = Style;
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Suite;
                    StyleExpr = Style;
                }
                field(Status; Status)
                {
                    ApplicationArea = Suite;
                    StyleExpr = Style;
                }
                field("Total Records"; "Total Records")
                {
                    ApplicationArea = Suite;
                }
                field(Progress; Progress)
                {
                    ApplicationArea = Suite;
                }
                field("Remaining Duration"; "Remaining Duration")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the remaining duration of the job.';
                }
                field("Earliest Start Date/Time"; "Earliest Start Date/Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the earliest date and time when the job should be run.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Rerun)
            {
                AccessByPermission = TableData "Change Global Dim. Log Entry" = M;
                ApplicationArea = Suite;
                Caption = 'Rerun';
                Enabled = IsRerunEnabled;
                Image = RefreshLines;
                ToolTip = 'Restart incomplete jobs for global dimension change. Jobs may stop with the Incomplete status because of capacity issues. Such issues can typically be resolved by choosing the Rerun action.';

                trigger OnAction()
                var
                    ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
                begin
                    ChangeGlobalDimensions.Rerun(Rec);
                end;
            }
            action(ShowError)
            {
                ApplicationArea = Suite;
                Caption = 'Show Error';
                Enabled = IsRerunEnabled;
                Image = ErrorLog;
                ToolTip = 'View a message in the Job Queue Log Entries window about the error that stopped the global dimension change job.';

                trigger OnAction()
                begin
                    ShowError;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Status in [Status::Incomplete, Status::Scheduled] then
            IsRerunEnabled := true
        else
            if Status = Status::" " then
                IsRerunEnabled := not AreAllLinesInBlankStatus
            else
                IsRerunEnabled := false;
    end;

    trigger OnAfterGetRecord()
    begin
        if "Total Records" <> "Completed Records" then
            UpdateStatus;
        SetStyle;
    end;

    var
        IsRerunEnabled: Boolean;
        [InDataSet]
        Style: Text;

    local procedure AreAllLinesInBlankStatus(): Boolean
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ChangeGlobalDimLogEntry.SetFilter(Status, '<>%1', ChangeGlobalDimLogEntry.Status::" ");
        exit(ChangeGlobalDimLogEntry.IsEmpty);
    end;

    local procedure SetStyle()
    begin
        case Status of
            Status::" ":
                Style := 'Subordinate';
            Status::Completed:
                Style := 'Favorable';
            Status::Scheduled,
          Status::"In Progress":
                Style := 'Ambiguous';
            Status::Incomplete:
                Style := 'Unfavorable'
        end;
    end;
}

