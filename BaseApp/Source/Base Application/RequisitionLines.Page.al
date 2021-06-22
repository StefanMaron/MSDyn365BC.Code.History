page 517 "Requisition Lines"
{
    Caption = 'Requisition Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Requisition Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Worksheet Template Name"; "Worksheet Template Name")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the requisition worksheet template.';
                }
                field("Journal Batch Name"; "Journal Batch Name")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the requisition worksheet line.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the type of requisition worksheet line you are creating.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                    Visible = true;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of units of the item.';
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of this item have been reserved.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the vendor who will ship the items in the purchase order.';
                }
                field("Price Calculation Method"; "Price Calculation Method")
                {
                    // Visibility should be turned on by an extension for Price Calculation
                    Visible = false;
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the method that will be used for price calculation in the requisition line.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the customer.';
                    Visible = false;
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
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when the related order was created.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
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
                action("Show Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Show Worksheet';
                    Image = ViewWorksheet;
                    ToolTip = 'Open the requisition worksheet that the lines come from. ';

                    trigger OnAction()
                    begin
                        ReqWkshTmpl.Get("Worksheet Template Name");
                        ReqLine := Rec;
                        ReqLine.FilterGroup(2);
                        ReqLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
                        ReqLine.SetRange("Journal Batch Name", "Journal Batch Name");
                        ReqLine.FilterGroup(0);
                        PAGE.Run(ReqWkshTmpl."Page ID", ReqLine);
                    end;
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        ShowReservationEntries(true);
                    end;
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
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    var
        ReqLine: Record "Requisition Line";
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ShortcutDimCode: array[8] of Code[20];
}

