page 99000817 "Prod. Order Routing"
{
    Caption = 'Prod. Order Routing';
    DataCaptionExpression = Caption;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Line';
    SourceTable = "Prod. Order Routing Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Prod. Order No."; "Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order.';
                    Visible = ProdOrderNoVisible;
                }
                field("Schedule Manually"; "Schedule Manually")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies that the underlying capacity need is recalculated each time a change is made in the schedule of the routing.';
                    Visible = false;
                }
                field("Operation No."; "Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the operation number.';
                }
                field("Previous Operation No."; "Previous Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the previous operation number.';
                    Visible = false;
                }
                field("Next Operation No."; "Next Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = NextOperationNoEditable;
                    ToolTip = 'Specifies the next operation number.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of operation.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the operation.';
                }
                field("Flushing Method"; "Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                    Visible = false;
                }
                field("Starting Date-Time"; "Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date and the starting time, which are combined in a format called "starting date-time".';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Starting Time"; StartingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Time';
                    ToolTip = 'Specifies the starting time of the routing line (operation).';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Validate("Starting Time", StartingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Starting Date"; StartingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the starting date of the routing line (operation).';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Validate("Starting Date", StartingDate);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Date-Time"; "Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending date and the ending time, which are combined in a format called "ending date-time".';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Ending Time"; EndingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Time';
                    ToolTip = 'Specifies the ending time of the routing line (operation).';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Validate("Ending Time", EndingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Date"; EndingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the ending date of the routing line (operation).';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Validate("Ending Date", EndingDate);
                        CurrPage.Update(true);
                    end;
                }
                field("Setup Time"; "Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the setup time of the operation.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Run Time"; "Run Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the run time of the operation.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Wait Time"; "Wait Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the wait time after processing.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Move Time"; "Move Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the move time.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Fixed Scrap Quantity"; "Fixed Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the fixed scrap quantity.';
                    Visible = false;
                }
                field("Routing Link Code"; "Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a routing link code.';
                    Visible = false;
                }
                field("Scrap Factor %"; "Scrap Factor %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the scrap factor in percent.';
                    Visible = false;
                }
                field("Send-Ahead Quantity"; "Send-Ahead Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the send-ahead quantity of the operation.';
                    Visible = false;
                }
                field("Concurrent Capacities"; "Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the con capacity of the operation.';
                    Visible = false;
                }
                field("Unit Cost per"; "Unit Cost per")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit cost for this operation if it is different than the unit cost on the work center or machine center card.';
                    Visible = false;
                }
                field("Expected Operation Cost Amt."; "Expected Operation Cost Amt.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the total cost of operations. It is automatically calculated from the capacity need, when a production order is refreshed or replanned.';
                    Visible = false;
                }
                field("Expected Capacity Ovhd. Cost"; "Expected Capacity Ovhd. Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the capacity overhead. It is automatically calculated from the capacity need, when a production order is refreshed or replanned.';
                    Visible = false;
                }
                field("Expected Capacity Need"; "Expected Capacity Need" / ExpCapacityNeed)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Expected Capacity Need';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the expected capacity need for the production order.';
                    Visible = false;
                }
                field("Routing Status"; "Routing Status")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of the routing line, such as Planned, In Progress, or Finished.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location where the machine or work center on the production order routing line operates.';
                    Visible = false;
                }
                field("Open Shop Floor Bin Code"; "Open Shop Floor Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the corresponding bin at the machine or work center, if the location code matches the setup of that machine or work center.';
                    Visible = false;
                }
                field("To-Production Bin Code"; "To-Production Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the bin that holds components with a flushing method, that involves a warehouse activity to bring the items to the bin.';
                    Visible = false;
                }
                field("From-Production Bin Code"; "From-Production Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the corresponding bin at the machine or work center if the location code matches the setup of that machine or work center.';
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Prod. Order Rtng. Cmt. Sh.";
                    RunPageLink = Status = FIELD(Status),
                                  "Prod. Order No." = FIELD("Prod. Order No."),
                                  "Routing Reference No." = FIELD("Routing Reference No."),
                                  "Routing No." = FIELD("Routing No."),
                                  "Operation No." = FIELD("Operation No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Tools)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Tools';
                    Image = Tools;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Prod. Order Routing Tools";
                    RunPageLink = Status = FIELD(Status),
                                  "Prod. Order No." = FIELD("Prod. Order No."),
                                  "Routing Reference No." = FIELD("Routing Reference No."),
                                  "Routing No." = FIELD("Routing No."),
                                  "Operation No." = FIELD("Operation No.");
                    ToolTip = 'View or edit information about tools that apply to operations that represent the standard task.';
                }
                action(Personnel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Personnel';
                    Image = User;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Prod. Order Routing Personnel";
                    RunPageLink = Status = FIELD(Status),
                                  "Prod. Order No." = FIELD("Prod. Order No."),
                                  "Routing Reference No." = FIELD("Routing Reference No."),
                                  "Routing No." = FIELD("Routing No."),
                                  "Operation No." = FIELD("Operation No.");
                    ToolTip = 'View or edit information about personnel that applies to operations that represent the standard task.';
                }
                action("Quality Measures")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Quality Measures';
                    Image = TaskQualityMeasure;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Prod. Order Rtng Qlty Meas.";
                    RunPageLink = Status = FIELD(Status),
                                  "Prod. Order No." = FIELD("Prod. Order No."),
                                  "Routing Reference No." = FIELD("Routing Reference No."),
                                  "Routing No." = FIELD("Routing No."),
                                  "Operation No." = FIELD("Operation No.");
                    ToolTip = 'View or edit information about quality measures that apply to operations that represent the standard task.';
                }
                action("Allocated Capacity")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Allocated Capacity';
                    Image = AllocatedCapacity;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'View the capacity need, which is the sum of the setup time and the run time. The run time is equal to the run time per piece multiplied by the number of pieces in the production order.';

                    trigger OnAction()
                    var
                        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
                    begin
                        if Status = Status::Finished then
                            exit;
                        ProdOrderCapNeed.SetCurrentKey(Type, "No.", "Starting Date-Time");
                        ProdOrderCapNeed.SetRange(Type, Type);
                        ProdOrderCapNeed.SetRange("No.", "No.");
                        ProdOrderCapNeed.SetRange(Date, "Starting Date", "Ending Date");
                        ProdOrderCapNeed.SetRange("Prod. Order No.", "Prod. Order No.");
                        ProdOrderCapNeed.SetRange(Status, Status);
                        ProdOrderCapNeed.SetRange("Routing Reference No.", "Routing Reference No.");
                        ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");

                        PAGE.RunModal(0, ProdOrderCapNeed);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Order &Tracking")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        ProdOrderLine: Record "Prod. Order Line";
                        TrackingForm: Page "Order Tracking";
                    begin
                        ProdOrderLine.SetRange(Status, Status);
                        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
                        ProdOrderLine.SetRange("Routing No.", "Routing No.");
                        if ProdOrderLine.FindFirst then begin
                            TrackingForm.SetProdOrderLine(ProdOrderLine);
                            TrackingForm.RunModal;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NextOperationNoEditable := not IsSerial;
        GetStartingEndingDateAndTime(StartingTime, StartingDate, EndingTime, EndingDate);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CheckPreviousAndNext;
    end;

    trigger OnInit()
    begin
        ProdOrderNoVisible := true;
        NextOperationNoEditable := true;
    end;

    trigger OnOpenPage()
    begin
        ProdOrderNoVisible := true;
        if GetFilter("Prod. Order No.") <> '' then
            ProdOrderNoVisible := GetRangeMin("Prod. Order No.") <> GetRangeMax("Prod. Order No.");
    end;

    var
        [InDataSet]
        ProdOrderNoVisible: Boolean;
        NextOperationNoEditable: Boolean;
        StartingTime: Time;
        EndingTime: Time;
        StartingDate: Date;
        EndingDate: Date;

    local procedure ExpCapacityNeed(): Decimal
    var
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
    begin
        if "Work Center No." = '' then
            exit(1);
        WorkCenter.Get("Work Center No.");
        exit(CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"));
    end;

    procedure Initialize(NewCaption: Text)
    begin
        CurrPage.Caption(NewCaption);
    end;
}

