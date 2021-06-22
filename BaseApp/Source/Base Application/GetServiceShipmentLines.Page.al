page 5994 "Get Service Shipment Lines"
{
    Caption = 'Get Service Shipment Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Service Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Service;
                    HideValue = DocumentNoHideValue;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of this shipment.';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = true;
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the items on the service order.';
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
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of an item, resource, cost, or a standard text on the service line.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the currency code for various amounts on the shipment.';
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
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
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
                    ToolTip = 'Specifies the number of item units, resource hours, general ledger account payments, or cost that have been shipped to the customer.';
                }
                field("Qty. Shipped Not Invoiced"; "Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the quantity of the shipped item that has been posted as shipped but that has not yet been posted as invoiced.';
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
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
                action("Show Document")
                {
                    ApplicationArea = Service;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ServiceShptHeader.Get("Document No.");
                        PAGE.Run(PAGE::"Posted Service Shipment", ServiceShptHeader);
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
                    end;
                }
                action("Item &Tracking Entries")
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
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := IsFirstDocLine;
        DocumentNoHideValue := not IsFirstDocLine;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            OKOnPush;
    end;

    var
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceHeader: Record "Service Header";
        TempServiceShptLine: Record "Service Shipment Line" temporary;
        ServiceGetShpt: Codeunit "Service-Get Shipment";
        [InDataSet]
        StyleIsStrong: Boolean;
        [InDataSet]
        DocumentNoHideValue: Boolean;

    procedure SetServiceHeader(var ServiceHeader2: Record "Service Header")
    begin
        ServiceHeader.Get(ServiceHeader2."Document Type", ServiceHeader2."No.");
        ServiceHeader.TestField("Document Type", ServiceHeader."Document Type"::Invoice);
    end;

    local procedure IsFirstDocLine(): Boolean
    var
        ServiceShptLine: Record "Service Shipment Line";
    begin
        TempServiceShptLine.Reset();
        TempServiceShptLine.CopyFilters(Rec);
        TempServiceShptLine.SetRange("Document No.", "Document No.");
        if not TempServiceShptLine.FindFirst then begin
            ServiceShptLine.CopyFilters(Rec);
            ServiceShptLine.SetRange("Document No.", "Document No.");
            if not ServiceShptLine.FindFirst then
                exit(false);
            TempServiceShptLine := ServiceShptLine;
            TempServiceShptLine.Insert();
        end;
        if "Line No." = TempServiceShptLine."Line No." then
            exit(true);
    end;

    local procedure OKOnPush()
    begin
        GetShipmentLines;
        CurrPage.Close;
    end;

    procedure GetShipmentLines()
    begin
        CurrPage.SetSelectionFilter(Rec);
        ServiceGetShpt.SetServiceHeader(ServiceHeader);
        ServiceGetShpt.CreateInvLines(Rec);
    end;
}

