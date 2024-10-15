page 17366 "Labor Contract"
{
    Caption = 'Labor Contract';
    PageType = Document;
    SourceTable = "Labor Contract";

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
                            CurrPage.Update();
                    end;
                }
                field("Contract Type"; "Contract Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contract Type Code"; "Contract Type Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Person No."; "Person No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Person Name"; "Person Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
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
                field("Uninterrupted Service"; "Uninterrupted Service")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insured Service"; "Insured Service")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unmeasured Work Time"; "Unmeasured Work Time")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Vendor Agreement No."; "Vendor Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            part(Lines; "Labor Contract Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Contract No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Contract)
            {
                Caption = 'Contract';
                Image = Agreement;
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment List";
                    RunPageLink = "Table Name" = CONST("Labor Contract"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                separator(Action1210027)
                {
                }
            }
            group("P&rint")
            {
                Caption = 'P&rint';
                Image = Print;
                action("Dismissal Order T-61")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dismissal Order T-61';
                    Image = "Report";

                    trigger OnAction()
                    begin
                        HROrderPrint.PrintFormT61(Rec);
                        Clear(HROrderPrint);
                    end;
                }
                action("Acceptance Act T-73")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Acceptance Act T-73';
                    Image = "Report";

                    trigger OnAction()
                    begin
                        HROrderPrint.PrintFormT73(Rec);
                        Clear(HROrderPrint);
                    end;
                }
            }
        }
    }

    var
        HROrderPrint: Codeunit "HR Order - Print";
}

