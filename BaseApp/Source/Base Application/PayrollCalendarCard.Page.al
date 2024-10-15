page 17428 "Payroll Calendar Card"
{
    Caption = 'Payroll Calendar Card';
    PageType = Document;
    SourceTable = "Payroll Calendar";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Shift Days"; "Shift Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Shift Start Date"; "Shift Start Date")
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
            }
            part(CalendarEntries; "Payroll Calendar Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Calendar Code" = FIELD(Code);
            }
            group(Payroll)
            {
                Caption = 'Payroll';
                field("Working Hours"; "Working Hours")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Working Days"; "Working Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Weekend Days"; "Weekend Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Holidays; Holidays)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Calendar")
            {
                Caption = '&Calendar';
                action("Setu&p")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Setu&p';
                    Image = Setup;
                    RunObject = Page "Payroll Calendar Setup";
                    RunPageLink = "Calendar Code" = FIELD(Code);
                }
                separator(Action1210010)
                {
                }
                action("Calendar by Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calendar by Periods';
                    Image = Calendar;
                    RunObject = Page "Payroll Calendar by Periods";
                    RunPageLink = Code = FIELD(Code);
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Lines';
                    Image = CreateLinesFromTimesheet;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        CreateCalendarLine: Report "Create Calendar Line";
                    begin
                        TestField(Code);

                        CreateCalendarLine.GetCalendar(Rec);
                        CreateCalendarLine.RunModal;
                        Clear(CreateCalendarLine);
                    end;
                }
                action("Copy Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Setup';
                    Image = CopyWorksheet;

                    trigger OnAction()
                    var
                        CopyCalendarSetup: Report "Copy Calendar Setup";
                    begin
                        CopyCalendarSetup.Set(Rec);
                        CopyCalendarSetup.Run;
                        Clear(CopyCalendarSetup);
                    end;
                }
            }
        }
    }
}

