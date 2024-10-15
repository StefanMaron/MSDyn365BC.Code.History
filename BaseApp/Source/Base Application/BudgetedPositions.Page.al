page 35656 "Budgeted Positions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Budgeted Positions';
    CardPageID = "Budgeted Position Card";
    Editable = false;
    PageType = List;
    SourceTable = Position;
    SourceTableView = SORTING("Budgeted Position", "Budgeted Position No.")
                      WHERE("Budgeted Position" = CONST(true));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Parent Position No."; "Parent Position No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Opening Reason"; "Opening Reason")
                {
                    Visible = false;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Name"; "Job Title Name")
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
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
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
                field(Rate; Rate)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Filled Rate"; "Filled Rate")
                {
                    ApplicationArea = Basic, Suite;
                }
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
                field("Use Trial Period"; "Use Trial Period")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Out-of-Staff"; "Out-of-Staff")
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
                field("Kind of Work"; "Kind of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Conditions of Work"; "Conditions of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Calc Group Code"; "Calc Group Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Note; Note)
                {
                    ToolTip = 'Specifies the note text or if a note exists.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
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
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(Position2);
                        SelectedPositions := Position2.Count();
                        if SelectedPositions > 0 then
                            if Confirm(Text14700, true, SelectedPositions) then begin
                                Position2.FindSet();
                                repeat
                                    Position2.Approve(false);
                                until Position2.Next() = 0;
                            end;
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
                        SelectedPositions := Position2.Count();
                        if SelectedPositions > 0 then
                            if Confirm(Text14701, true, SelectedPositions) then begin
                                Position2.FindSet();
                                repeat
                                    Position2.Reopen(false);
                                until Position2.Next() = 0;
                            end;
                    end;
                }
                action(Close)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close';
                    Image = Close;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(Position2);
                        SelectedPositions := Position2.Count();
                        if SelectedPositions > 0 then
                            if Confirm(Text14702, true, SelectedPositions) then begin
                                Position2.FindSet();
                                repeat
                                    Position2.Close(false);
                                until Position2.Next() = 0;
                            end;
                    end;
                }
                separator(Action1210056)
                {
                }
                action("Copy Position")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Position';
                    Image = Copy;

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

    var
        Position2: Record Position;
        Text14700: Label '%1 position(s) will be approved. Continue?';
        Text14701: Label '%1 position(s) will be reopened. Continue?';
        Text14702: Label '%1 position(s) will be closed. Continue?';
        SelectedPositions: Decimal;
}

