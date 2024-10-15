page 17380 "Position Card"
{
    Caption = 'Position Card';
    PageType = Card;
    PopulateAllFields = true;
    SourceTable = Position;
    SourceTableView = WHERE("Budgeted Position" = CONST(false));

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
                field("Parent Position No."; "Parent Position No.")
                {
                    ApplicationArea = Basic, Suite;
                }
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
                field("Opening Reason"; "Opening Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Note; Note)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the note text or if a note exists.';
                }
                field("Approval Date"; "Approval Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the record was approved.';
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
                field("Out-of-Staff"; "Out-of-Staff")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Rate; Rate)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Filled Rate"; "Filled Rate")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Budgeted Position No."; "Budgeted Position No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
                field("Organization Size"; "Organization Size")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category.';
                }
                field("Statistical Group Code"; "Statistical Group Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Calendar Code"; "Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related work calendar. ';
                }
                field("Kind of Work"; "Kind of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Conditions of Work"; "Conditions of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Liability for Breakage"; "Liability for Breakage")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Hire Conditions"; "Hire Conditions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Use Trial Period"; "Use Trial Period")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Trial Period Description"; "Trial Period Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Trial Period Formula"; "Trial Period Formula")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Payroll)
            {
                Caption = 'Payroll';
                field("Calc Group Code"; "Calc Group Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Worktime Norm"; "Worktime Norm")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Future Period Vacat. Post. Gr."; "Future Period Vacat. Post. Gr.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Salary Element Code"; "Base Salary Element Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Salary"; "Base Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Additional Salary"; "Additional Salary")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a salary that is paid in addition to the base salary. ';
                }
                field("Monthly Salary"; "Monthly Salary")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Budgeted Salary"; "Budgeted Salary")
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
                field("Approved By User"; "Approved By User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who approved the record. ';
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
            group(Position)
            {
                Caption = 'Position';
                action("Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contract Terms';
                    Image = Reconcile;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        ShowContractTerms;
                    end;
                }
                action(Employees)
                {
                    Caption = 'Employees';
                    Image = TeamSales;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Employee List";
                    RunPageLink = "Position No." = FIELD("No.");
                    RunPageView = SORTING("Position No.");
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
                        Approve(false);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    begin
                        Reopen(false);
                    end;
                }
                action(Close)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close';
                    Image = Close;

                    trigger OnAction()
                    begin
                        Close(false);
                    end;
                }
                separator(Action1210097)
                {
                }
                action("Copy Position")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Position';
                    Ellipsis = true;
                    Image = Copy;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        CopyPosition: Report "Copy Position";
                    begin
                        CopyPosition.Set(Rec, 1, false);
                        CopyPosition.Run;
                        Clear(CopyPosition);
                    end;
                }
            }
        }
    }
}

