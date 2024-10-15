page 17490 "Vacation Request"
{
    Caption = 'Vacation Request';
    PageType = Card;
    SourceTable = "Vacation Request";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Employee Name"; "Employee Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Time Activity Code"; "Time Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Request Date"; "Request Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Calendar Days"; "Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of calendar days.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
                field("Scheduled Year"; "Scheduled Year")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Scheduled Start Date"; "Scheduled Start Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vacation Used"; "Vacation Used")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Employee)
            {
                Caption = 'Employee';
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Org. Unit Name"; "Org. Unit Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Name"; "Job Title Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(History)
            {
                Caption = 'History';
                field("Created By User"; "Created By User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who created the record.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was created.';
                }
                field("Submit Date"; "Submit Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Approved By User"; "Approved By User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who approved the record. ';
                }
                field("Approval Date"; "Approval Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the record was approved.';
                }
                field("Closed By User"; "Closed By User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who closed the record.';
                }
                field("Closing Date"; "Closing Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was closed.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("R&equest")
            {
                Caption = 'R&equest';
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "HR Order Comment Lines";
                    RunPageLink = "Table Name" = CONST("Vacation Request"),
                                  "No." = FIELD("No.");
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        Approve;
                    end;
                }
                action(Close)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close';
                    Image = Close;

                    trigger OnAction()
                    begin
                        Close;
                    end;
                }
                separator(Action1210048)
                {
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    begin
                        Reopen;
                    end;
                }
                action("Mark as Used")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark as Used';
                    Image = Approve;

                    trigger OnAction()
                    begin
                        MarkUsed;
                    end;
                }
                action("Mark as Unused")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark as Unused';
                    Image = Close;

                    trigger OnAction()
                    begin
                        MarkUnused;
                    end;
                }
            }
        }
    }
}

