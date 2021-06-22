page 5970 "Posted Service Shipment Lines"
{
    AutoSplitKey = true;
    Caption = 'Posted Service Shipment Lines';
    DataCaptionFields = "Document No.";
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Service Shipment Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SelectionFilter; SelectionFilter)
                {
                    ApplicationArea = Service;
                    Caption = 'Selection Filter';
                    OptionCaption = 'All Service Shipment Lines,Lines per Selected Service Item,Lines Not Item Related';
                    ToolTip = 'Specifies a selection filter.';

                    trigger OnValidate()
                    begin
                        SelectionFilterOnAfterValidate;
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Service Item Line No."; "Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item line to which this service line is linked.';
                    Visible = false;
                }
                field("Service Item No."; "Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item to which this service line is linked.';
                    Visible = false;
                }
                field("Service Item Serial No."; "Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the service item to which this shipment line is linked.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of this shipment line.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of an item, resource, cost, or a standard text on the service line.';
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the type of work performed under the posted service order.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of item units, resource hours, general ledger account payments, or cost that have been shipped to the customer.';
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Quantity Consumed"; "Quantity Consumed")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of units of items, resource hours, general ledger account payments, or costs that have been posted as consumed.';
                }
                field("Qty. Shipped Not Invoiced"; "Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the shipped item that has been posted as shipped but that has not yet been posted as invoiced.';
                }
                field("Fault Area Code"; "Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault area associated with this service line.';
                }
                field("Symptom Code"; "Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the symptom associated with this service shipment line.';
                }
                field("Fault Code"; "Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault code associated with this service shipment line.';
                }
                field("Fault Reason Code"; "Fault Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault reason for the service shipment line.';
                    Visible = false;
                }
                field("Resolution Code"; "Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the resolution associated with this service shipment line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, from which the items should be taken and where they should be registered.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Spare Part Action"; "Spare Part Action")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the item has been used to replace the whole service item, one of the service item components, installed as a new component, or as a supplementary tool in the service process.';
                }
                field("Replaced Item Type"; "Replaced Item Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service item component replaced by the item on the service line.';
                }
                field("Replaced Item No."; "Replaced Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item component replaced by the item on the service line.';
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract associated with the posted service order.';
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the posting group used when the service line was posted.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service line was posted.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
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
                action(Dimenions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action(ItemTrackingEntries)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ToolTip = 'View serial or lot numbers that are assigned to items.';

                    trigger OnAction()
                    begin
                        ShowItemTrackingLines;
                    end;
                }
                separator(Action27)
                {
                }
                action(ItemInvoiceLines)
                {
                    ApplicationArea = Service;
                    Caption = 'Item Invoice &Lines';
                    Image = ItemInvoice;
                    ToolTip = 'View posted sales invoice lines for the item. ';

                    trigger OnAction()
                    begin
                        TestField(Type, Type::Item);
                        ShowItemServInvLines;
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
                action("&Order Tracking")
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Order Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Track the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    begin
                        ShowTracking;
                    end;
                }
                separator(Action86)
                {
                }
                action(UndoShipment)
                {
                    ApplicationArea = Service;
                    Caption = '&Undo Shipment';
                    Image = UndoShipment;
                    ToolTip = 'Withdraw the line from the shipment. This is useful for making corrections, because the line is not deleted. You can make changes and post it again.';

                    trigger OnAction()
                    begin
                        UndoServShptPosting;
                    end;
                }
                action(UndoConsumption)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'U&ndo Consumption';
                    Image = Undo;
                    ToolTip = 'Cancel the consumption on the service order, for example because it was posted by mistake.';

                    trigger OnAction()
                    begin
                        UndoServConsumption;
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Clear(SelectionFilter);
        SetSelectionFilter;
    end;

    var
        SelectionFilter: Option "All Shipment Lines","Lines per Selected Service Item","Lines Not Item Related";
        ServItemLineNo: Integer;

    procedure Initialize(ServItemLineNo2: Integer)
    begin
        ServItemLineNo := ServItemLineNo2;
    end;

    procedure SetSelectionFilter()
    begin
        case SelectionFilter of
            SelectionFilter::"All Shipment Lines":
                SetRange("Service Item Line No.");
            SelectionFilter::"Lines per Selected Service Item":
                SetRange("Service Item Line No.", ServItemLineNo);
            SelectionFilter::"Lines Not Item Related":
                SetFilter("Service Item Line No.", '=%1', 0);
        end;
        CurrPage.Update(false);
    end;

    local procedure ShowTracking()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TrackingForm: Page "Order Tracking";
    begin
        TestField(Type, Type::Item);
        if "Item Shpt. Entry No." <> 0 then begin
            ItemLedgEntry.Get("Item Shpt. Entry No.");
            TrackingForm.SetItemLedgEntry(ItemLedgEntry);
        end else
            TrackingForm.SetMultipleItemLedgEntries(TempItemLedgEntry,
              DATABASE::"Service Shipment Line", 0, "Document No.", '', 0, "Line No.");
        TrackingForm.RunModal;
    end;

    local procedure UndoServShptPosting()
    var
        ServShptLine: Record "Service Shipment Line";
    begin
        ServShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(ServShptLine);
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServShptLine);
    end;

    local procedure UndoServConsumption()
    var
        ServShptLine: Record "Service Shipment Line";
    begin
        ServShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(ServShptLine);
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServShptLine);
    end;

    local procedure SelectionFilterOnAfterValidate()
    begin
        CurrPage.Update;
        SetSelectionFilter;
    end;
}

