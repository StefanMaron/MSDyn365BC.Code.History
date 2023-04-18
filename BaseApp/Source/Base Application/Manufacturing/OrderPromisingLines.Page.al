page 99000959 "Order Promising Lines"
{
    Caption = 'Order Promising Lines';
    DataCaptionExpression = AvailabilityMgt.GetCaption();
    InsertAllowed = false;
    PageType = Worksheet;
    RefreshOnActivate = true;
    SourceTable = "Order Promising Line";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Requested Shipment Date");

    layout
    {
        area(content)
        {
            group(Control17)
            {
                ShowCaption = false;
                field(CrntSourceID; CrntSourceID)
                {
                    ApplicationArea = OrderPromising;
                    Caption = 'No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the item.';
                }
            }
            repeater(Control16)
            {
                Editable = true;
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the item number of the item that is on the promised order.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the description of the entry.';
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the requested delivery date for the entry.';
                }
                field("Requested Shipment Date"; Rec."Requested Shipment Date")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the delivery date that the customer requested, minus the shipping time.';
                }
                field("Planned Delivery Date"; Rec."Planned Delivery Date")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address. If the customer requests a delivery date, the program calculates whether the items will be available for delivery on this date. If the items are available, the planned delivery date will be the same as the requested delivery date. If not, the program calculates the date that the items are available for delivery and enters this date in the Planned Delivery Date field.';
                }
                field("Original Shipment Date"; Rec."Original Shipment Date")
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the shipment date of the entry.';
                }
                field("Earliest Shipment Date"; Rec."Earliest Shipment Date")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the Capable to Promise function as the earliest possible shipment date for the item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the number of units, calculated by subtracting the reserved quantity from the outstanding quantity in the Sales Line table.';
                }
                field("Required Quantity"; Rec."Required Quantity")
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the quantity required for order promising lines.';
                }
                field(CalcAvailability; CalcAvailability())
                {
                    ApplicationArea = OrderPromising;
                    Caption = 'Availability';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item on the order promising line are available.';
                }
                field("Unavailability Date"; Rec."Unavailability Date")
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the date when the order promising line is no longer available.';
                }
                field("Unavailable Quantity"; Rec."Unavailable Quantity")
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of items that are not available for the requested delivery date on the order.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
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
            group("&Calculate")
            {
                Caption = '&Calculate';
                Image = Calculate;
                action(AvailableToPromise)
                {
                    ApplicationArea = OrderPromising;
                    Caption = 'Available-to-Promise';
                    Image = AvailableToPromise;
                    ToolTip = 'Calculate the delivery date of the customer''s order because the items are available, either in inventory or on planned receipts, based on the reservation system. The function performs an availability check of the unreserved quantities in inventory with regard to planned production, purchases, transfers, and sales returns.';

                    trigger OnAction()
                    begin
                        CheckCalculationDone();
                        AvailabilityMgt.CalcAvailableToPromise(Rec);
                    end;
                }
                action(CapableToPromise)
                {
                    ApplicationArea = OrderPromising;
                    Caption = 'Capable-to-Promise';
                    Image = CapableToPromise;
                    ToolTip = 'Calculate the earliest date that the item can be available if it is to be produced, purchased, or transferred, assuming that the item is not in inventory and no orders are scheduled. This function is useful for "what if" scenarios.';

                    trigger OnAction()
                    begin
                        CheckCalculationDone();
                        AvailabilityMgt.CalcCapableToPromise(Rec, CrntSourceID);
                    end;
                }
            }
        }
        area(processing)
        {
            action(AcceptButton)
            {
                ApplicationArea = OrderPromising;
                Caption = '&Accept';
                Enabled = AcceptButtonEnable;
                Image = Approve;
                ToolTip = 'Accept the earliest shipment date available.';

                trigger OnAction()
                var
                    ReqLine: Record "Requisition Line";
                begin
                    Accepted := true;
                    AvailabilityMgt.UpdateSource(Rec);
                    ReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
                    ReqLine.SetRange("Order Promising ID", CrntSourceID);
                    ReqLine.ModifyAll("Accept Action Message", true);
                    OnAcceptButtonOnActionOnBeforeClosePage(Rec, CrntSourceType, CrntSourceID, OrderPromisingCalculationDone);
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AcceptButton_Promoted; AcceptButton)
                {
                }
                actionref(AvailableToPromise_Promoted; AvailableToPromise)
                {
                }
                actionref(CapableToPromise_Promoted; CapableToPromise)
                {
                }
            }
        }
    }

    trigger OnClosePage()
    var
        CapableToPromise: Codeunit "Capable to Promise";
    begin
        if not Accepted then begin
            CapableToPromise.RemoveReqLines(CrntSourceID, 0, 0, true);
            AvailabilityMgt.CancelReservations();
        end;
    end;

    trigger OnInit()
    begin
        AcceptButtonEnable := true;
    end;

    trigger OnOpenPage()
    var
        SalesHeader: Record "Sales Header";
        ServHeader: Record "Service Header";
        Job: Record Job;
    begin
        OrderPromisingCalculationDone := false;
        Accepted := false;
        if GetFilter("Source ID") <> '' then
            case CrntSourceType of
                "Source Type"::"Service Order":
                    begin
                        ServHeader."Document Type" := ServHeader."Document Type"::Order;
                        ServHeader."No." := GetRangeMin("Source ID");
                        ServHeader.Find();
                        SetServHeader(ServHeader);
                    end;
                "Source Type"::Job:
                    begin
                        Job.Status := Job.Status::Open;
                        Job."No." := GetRangeMin("Source ID");
                        Job.Find();
                        SetJob(Job);
                    end;
                else
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
                    SalesHeader."No." := GetRangeMin("Source ID");
                    SalesHeader.Find();
                    SetSalesHeader(SalesHeader);
                    AcceptButtonEnable := SalesHeader.Status = SalesHeader.Status::Open;
            end;
    end;

    var
        AvailabilityMgt: Codeunit AvailabilityManagement;
        Accepted: Boolean;
        CrntSourceID: Code[20];
        CrntSourceType: Enum "Order Promising Line Source Type";
        [InDataSet]
        AcceptButtonEnable: Boolean;
        OrderPromisingCalculationDone: Boolean;
        Text000: Label 'The order promising lines are already calculated. You must close and open the window again to perform a new calculation.';

    procedure SetSalesHeader(var CrntSalesHeader: Record "Sales Header")
    begin
        AvailabilityMgt.SetSalesHeader(Rec, CrntSalesHeader);

        CrntSourceType := CrntSourceType::Sales;
        CrntSourceID := CrntSalesHeader."No.";
    end;

    procedure SetServHeader(var CrntServHeader: Record "Service Header")
    begin
        AvailabilityMgt.SetServHeader(Rec, CrntServHeader);

        CrntSourceType := CrntSourceType::"Service Order";
        CrntSourceID := CrntServHeader."No.";
    end;

    procedure SetJob(var CrntJob: Record Job)
    begin
        AvailabilityMgt.SetJob(Rec, CrntJob);
        CrntSourceType := CrntSourceType::Job;
        CrntSourceID := CrntJob."No.";
    end;

#if not CLEAN22
    [Obsolete('Replaced by procedure SetSource()', '22.0')]
    procedure SetSourceType(SourceType: Option)
    begin
        CrntSourceType := "Order Promising Line Source Type".FromInteger(SourceType);
    end;
#endif

    procedure SetSource(SourceType: Enum "Order Promising Line Source Type")
    begin
        CrntSourceType := SourceType;
    end;

    local procedure CheckCalculationDone()
    begin
        if OrderPromisingCalculationDone then
            Error(Text000);
        OrderPromisingCalculationDone := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcceptButtonOnActionOnBeforeClosePage(var OrderPromisingLine: Record "Order Promising Line"; CrntSourceType: Enum "Order Promising Line Source Type"; CrntSourceID: Code[20]; OrderPromisingCalculationDone: Boolean)
    begin
    end;
}

