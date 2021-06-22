page 99000761 "Machine Center List"
{
    ApplicationArea = Manufacturing;
    Caption = 'Machine Centers';
    CardPageID = "Machine Center Card";
    Editable = false;
    PageType = List;
    SourceTable = "Machine Center";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a name for the machine center.';
                }
                field("Work Center No."; "Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the work center to assign this machine center to.';
                }
                field(Capacity; Capacity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the capacity of the machine center.';
                }
                field(Efficiency; Efficiency)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the efficiency factor as a percentage of the machine center.';
                }
                field("Minimum Efficiency"; "Minimum Efficiency")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the minimum efficiency of this machine center.';
                    Visible = false;
                }
                field("Maximum Efficiency"; "Maximum Efficiency")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the maximum efficiency of this machine center.';
                    Visible = false;
                }
                field("Concurrent Capacities"; "Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how much available capacity must be concurrently planned for one operation at this machine center.';
                    Visible = false;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the percentage of the center''s cost that includes indirect costs, such as machine maintenance.';
                    Visible = false;
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Overhead Rate"; "Overhead Rate")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the overhead rate of this machine center.';
                    Visible = false;
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the machine center card was last modified.';
                    Visible = false;
                }
                field("Flushing Method"; "Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Mach. Ctr.")
            {
                Caption = '&Mach. Ctr.';
                Image = MachineCenter;
                action("Capacity Ledger E&ntries")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Ledger E&ntries';
                    Image = CapacityLedger;
                    RunObject = Page "Capacity Ledger Entries";
                    RunPageLink = Type = CONST("Machine Center"),
                                  "No." = FIELD("No."),
                                  "Posting Date" = FIELD("Date Filter");
                    RunPageView = SORTING(Type, "No.", "Work Shift Code", "Item No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Machine Center"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Lo&ad")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Lo&ad';
                    Image = WorkCenterLoad;
                    RunObject = Page "Machine Center Load";
                    RunPageLink = "No." = FIELD("No.");
                    RunPageView = SORTING("No.");
                    ToolTip = 'View the availability of the machine or work center, including its the capacity, the allocated quantity, availability after orders, and the load in percent of its total capacity.';
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Machine Center Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Work Shift Filter" = FIELD("Work Shift Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
            group("Pla&nning")
            {
                Caption = 'Pla&nning';
                Image = Planning;
                action("&Calendar")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Calendar';
                    Image = MachineCenterCalendar;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Machine Center Calendar";
                    ToolTip = 'Open the shop calendar, for example to see the load.';
                }
                action("A&bsence")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'A&bsence';
                    Image = WorkCenterAbsence;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Capacity Absence";
                    RunPageLink = "Capacity Type" = CONST("Machine Center"),
                                  "No." = FIELD("No."),
                                  Date = FIELD("Date Filter");
                    ToolTip = 'View which working days are not available. ';
                }
                action("Ta&sk List")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ta&sk List';
                    Image = TaskList;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Machine Center Task List";
                    RunPageLink = "No." = FIELD("No.");
                    RunPageView = SORTING(Type, "No.")
                                  WHERE(Type = CONST("Machine Center"),
                                        Status = FILTER(.. Released),
                                        "Routing Status" = FILTER(<> Finished));
                    ToolTip = 'View the list of operations that are scheduled for the machine center.';
                }
            }
        }
        area(reporting)
        {
            action("Machine Center List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Center List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Machine Center List";
                ToolTip = 'View the list of machine centers.';
            }
            action("Machine Center Load")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Center Load';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Machine Center Load";
                ToolTip = 'Get an overview of availability at the machine center, such as the capacity, the allocated quantity, availability after order, and the load in percent.';
            }
            action("Machine Center Load/Bar")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Center Load/Bar';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Machine Center Load/Bar";
                ToolTip = 'View a list of machine centers that are overloaded according to the plan. The efficiency or overloading is shown by efficiency bars.';
            }
        }
    }
}

