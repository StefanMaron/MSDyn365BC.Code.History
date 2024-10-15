namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Reports;
using Microsoft.Warehouse.Ledger;

page 9325 "Firm Planned Prod. Orders"
{
    ApplicationArea = Manufacturing;
    Caption = 'Firm Planned Prod. Orders';
    CardPageID = "Firm Planned Prod. Order";
    Editable = false;
    PageType = List;
    SourceTable = "Production Order";
    SourceTableView = where(Status = const("Firm Planned"));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the production order.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing number used for this production order.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the item or the family to produce (production quantity).';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code to which you want to post the finished product from this production order.';
                    Visible = false;
                }
                field("Starting Time"; StartingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Time';
                    ToolTip = 'Specifies the starting time of the production order.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Starting Date"; StartingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the starting date of the production order.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Ending Time"; EndingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Time';
                    ToolTip = 'Specifies the ending time of the production order.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Ending Date"; EndingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the ending date of the production order.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date and starting time of the production order.';
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending date and ending time of the production order.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the due date of the production order.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Finished Date"; Rec."Finished Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the actual finishing date of a finished production order.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of the production order.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the search description.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the production order card was last modified.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a bin to which you want to post the finished items.';
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
            group("Pro&d. Order")
            {
                Caption = 'Pro&d. Order';
                Image = "Order";
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Item Ledger E&ntries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Item Ledger E&ntries';
                        Image = ItemLedger;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Order Type" = const(Production),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                    }
                    action("Capacity Ledger Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Ledger Entries';
                        Image = CapacityLedger;
                        RunObject = Page "Capacity Ledger Entries";
                        RunPageLink = "Order Type" = const(Production),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Order Type" = const(Production),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ToolTip = 'View the value entries of the item on the document or journal line.';
                    }
                    action("&Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Warehouse Entries';
                        Image = BinLedger;
                        RunObject = Page "Warehouse Entries";
                        RunPageLink = "Source Type" = filter(83 | 5407),
                                      "Source Subtype" = filter("3" | "4" | "5"),
                                      "Source No." = field("No.");
                        RunPageView = sorting("Source Type", "Source Subtype", "Source No.");
                        ToolTip = 'View the history of quantities that are registered for the item in warehouse activities. ';
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Prod. Order Comment Sheet";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Production Order Statistics";
                    RunPageLink = Status = field(Status),
                                  "No." = field("No."),
                                  "Date Filter" = field("Date Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Change &Status")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Change &Status';
                    Image = ChangeStatus;
                    RunObject = Codeunit "Prod. Order Status Management";
                    ToolTip = 'Change the production order to another status, such as Released.';
                }
                action("&Update Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Update Unit Cost';
                    Ellipsis = true;
                    Image = UpdateUnitCost;
                    ToolTip = 'Update the cost of the parent item per changes to the production BOM or routing.';

                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                    begin
                        ProdOrder.SetRange(Status, Rec.Status);
                        ProdOrder.SetRange("No.", Rec."No.");

                        REPORT.RunModal(REPORT::"Update Unit Cost", true, true, ProdOrder);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Prod. Order - Detail Calc.")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order - Detail Calc.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Prod. Order - Detailed Calc.";
                ToolTip = 'View a list of the production orders. This list contains the expected costs and the quantity per production order or per operation of a production order.';
            }
            action("Prod. Order - Precalc. Time")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order - Precalc. Time';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Prod. Order - Precalc. Time";
                ToolTip = 'View a list of information about capacity requirement, starting and ending time, etc. per operation, per production order, or per production order line.';
            }
            action("Production Order - Comp. and Routing")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order - Comp. and Routing';
                Image = "Report";
                RunObject = Report "Prod. Order Comp. and Routing";
                ToolTip = 'View information about components and operations in production orders. For released production orders, the report shows the remaining quantity if parts of the quantity have been posted as output.';
            }
            action(ProdOrderJobCard)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order Job Card';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                ToolTip = 'View a list of the work in progress of a production order. Output, Scrapped Quantity and Production Lead Time are shown or printed depending on the operation.';

                trigger OnAction()
                begin
                    ManuPrintReport.PrintProductionOrder(Rec, 0);
                end;
            }
            action(ProdOrderMaterialRequisition)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order - Material Requisition';
                Image = "Report";
                ToolTip = 'View a list of material requirements per production order. The report shows you the status of the production order, the quantity of end items and components with the corresponding required quantity. You can view the due date and location code of each component.';

                trigger OnAction()
                begin
                    ManuPrintReport.PrintProductionOrder(Rec, 1);
                end;
            }
            action("Production Order List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order List';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Prod. Order - List";
                ToolTip = 'View a list of the production orders contained in the system. Information such as order number, number of the item to be produced, starting/ending date and other data are shown or printed.';
            }
            action(ProdOrderShortageList)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order - Shortage List';
                Image = "Report";
                ToolTip = 'View a list of the missing quantity per production order. You are shown how the inventory development is planned from today until the set day - for example whether orders are still open.';

                trigger OnAction()
                begin
                    ManuPrintReport.PrintProductionOrder(Rec, 2);
                end;
            }
            action("Production Order Statistics")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order Statistics';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Production Order Statistics";
                ToolTip = 'View statistical information about the production order''s direct material and capacity costs and overhead as well as its capacity need in the time unit of measure.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Report)
                {
                    Caption = 'Reports';

                    actionref(ProdOrderShortageList_Promoted; ProdOrderShortageList)
                    {
                    }
                    actionref(ProdOrderMaterialRequisition_Promoted; ProdOrderMaterialRequisition)
                    {
                    }
                    actionref(ProdOrderJobCard_Promoted; ProdOrderJobCard)
                    {
                    }
                    actionref("Production Order - Comp. and Routing_Promoted"; "Production Order - Comp. and Routing")
                    {
                    }
                }
                actionref("&Update Unit Cost_Promoted"; "&Update Unit Cost")
                {
                }
                actionref("Change &Status_Promoted"; "Change &Status")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.GetStartingEndingDateAndTime(StartingTime, StartingDate, EndingTime, EndingDate);
    end;

    trigger OnInit()
    begin
        DateAndTimeFieldVisible := false;
    end;

    trigger OnOpenPage()
    begin
        DateAndTimeFieldVisible := false;
    end;

    var
        ManuPrintReport: Codeunit "Manu. Print Report";
        StartingTime: Time;
        EndingTime: Time;
        StartingDate: Date;
        EndingDate: Date;
        DateAndTimeFieldVisible: Boolean;
}

