#if not CLEAN19
page 31092 "Acc. Schedule Res. Header List"
{
    Caption = 'Acc. Schedule Res. Header List (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "Acc. Schedule Result Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '19.0';


    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                ShowCaption = false;
                field("Result Code"; "Result Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of account schedule results.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of account schedule results.';
                }
                field("Date Filter"; "Date Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date filter of account schedule results.';
                }
                field("Acc. Schedule Name"; "Acc. Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the account schedule.';
                }
                field("Column Layout Name"; "Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the column layout that you want to use in the window.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Result Date"; "Result Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the created date of account schedule results.';
                }
                field("Result Time"; "Result Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the created time of account schedule results.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Acc. Schedule Result")
            {
                Caption = 'Acc. Schedule Result';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Acc. Schedule Results Overview";
                    RunPageLink = "Result Code" = FIELD("Result Code"),
                                  "Acc. Schedule Name" = FIELD("Acc. Schedule Name");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'The funkction opens the account schedule result card.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action(Print)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Allows print the account schedule results.';

                    trigger OnAction()
                    begin
                        AccSchedResultHdr := Rec;
                        AccSchedResultHdr.SetRecFilter;
                        REPORT.RunModal(REPORT::"Account Schedule Result", true, false, AccSchedResultHdr);
                    end;
                }
                action("Export to Excel")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Excel';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    ToolTip = 'Allows the account schedule results export to excel.';

                    trigger OnAction()
                    var
                        ExpAccSchedResToExcel: Report "Exp. Acc. Sched. Res. to Excel";
                    begin
                        ExpAccSchedResToExcel.SetOptions("Result Code", false);
                        ExpAccSchedResToExcel.Run();
                    end;
                }
            }
        }
    }

    var
        AccSchedResultHdr: Record "Acc. Schedule Result Header";
}
#endif
