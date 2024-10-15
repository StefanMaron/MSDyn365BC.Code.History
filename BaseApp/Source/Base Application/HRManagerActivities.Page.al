page 35652 "HR Manager Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    SourceTable = "HRP Cue";

    layout
    {
        area(content)
        {
            cuegroup("For Approval")
            {
                Caption = 'For Approval';
                field("Planned Budget Positions"; "Planned Budget Positions")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Budgeted Positions";
                }
                field("Planned Positions"; "Planned Positions")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Actual Positions";
                }
                field("Open Labor Contracts"; "Open Labor Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Labor Contracts";
                }
                field("Open Vacation Requests"; "Open Vacation Requests")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vacation Requests";
                }

                actions
                {
                    action("New Budget Position")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Budget Position';
                        RunObject = Page "Budgeted Position Card";
                        RunPageMode = Create;
                    }
                    action("New Position")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Position';
                        RunObject = Page "Position Card";
                        RunPageMode = Create;
                    }
                    action("New Person")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Person';
                        RunObject = Page "Person Card";
                        RunPageMode = Create;
                    }
                    action("New Labor Contract")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Labor Contract';
                        RunObject = Page "Labor Contract";
                        RunPageMode = Create;
                    }
                }
            }
            cuegroup("For Release")
            {
                Caption = 'For Release';
                field("Open Vacation Orders"; "Open Vacation Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vacation Orders";
                }
                field("Open Sick Leave Orders"; "Open Sick Leave Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sick Leave Orders";
                }
                field("Open Travel Orders"; "Open Travel Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Travel Orders";
                }
                field("Open Other Absence Orders"; "Open Other Absence Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Other Absence Orders";
                }

                actions
                {
                    action("New Vacation Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Vacation Order';
                        RunObject = Page "Vacation Order";
                        RunPageMode = Create;
                    }
                    action("New Sick Leave Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Sick Leave Order';
                        RunObject = Page "Sick Leave Order";
                        RunPageMode = Create;
                    }
                    action("New Travel Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Travel Order';
                        RunObject = Page "Travel Order";
                        RunPageMode = Create;
                    }
                    action("New Other Absence Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Other Absence Order';
                        RunObject = Page "Other Absence Order";
                        RunPageMode = Create;
                    }
                }
            }
            cuegroup("For Posting")
            {
                Caption = 'For Posting';
                field("Released Vacation Orders"; "Released Vacation Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vacation Orders";
                }
                field("Released Sick Leave Orders"; "Released Sick Leave Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sick Leave Orders";
                }
                field("Released Travel Orders"; "Released Travel Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Travel Orders";
                }
                field("Released Other Absence Orders"; "Released Other Absence Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Other Absence Orders";
                }

                actions
                {
                    action("N&avigate")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'N&avigate';
                        Image = Navigate;
                        RunObject = Page Navigate;
                        ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        PayrollPeriod.SetFilter("Ending Date", '%1..', WorkDate);
        if PayrollPeriod.FindFirst then
            SetRange("Date Filter", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date")
        else
            SetRange("Date Filter", 0D, WorkDate);
    end;

    var
        PayrollPeriod: Record "Payroll Period";
}

