page 5793 "Source Documents"
{
    Caption = 'Source Documents';
    DataCaptionFields = Type, "Location Code";
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Request";
    SourceTableView = SORTING(Type, "Location Code", "Completely Handled", "Document Status", "Expected Receipt Date", "Shipment Date", "Source Document", "Source No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code to which the request line is linked.';
                    Visible = false;
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when receipt of the items is expected.';
                    Visible = ExpectedReceiptDateVisible;
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                    Visible = ShipmentDateVisible;
                }
                field("Put-away / Pick No."; "Put-away / Pick No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the inventory put-away or pick that was created from this warehouse request.';
                }
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Destination Type"; "Destination Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether the type of destination associated with the warehouse request is a customer or a vendor.';
                }
                field("Destination No."; "Destination No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number or code of the customer or vendor related to the warehouse request.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                    Visible = false;
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Advice"; "Shipping Advice")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shipping advice, which informs whether partial deliveries are acceptable.';
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
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        ShowSourceDocumentCard();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateVisible();
    end;

    trigger OnInit()
    begin
        ShipmentDateVisible := true;
        ExpectedReceiptDateVisible := true;
    end;

    var
        [InDataSet]
        ExpectedReceiptDateVisible: Boolean;
        [InDataSet]
        ShipmentDateVisible: Boolean;

    procedure GetResult(var WhseReq: Record "Warehouse Request")
    begin
        CurrPage.SetSelectionFilter(WhseReq);
    end;

    local procedure UpdateVisible()
    begin
        ExpectedReceiptDateVisible := Type = Type::Inbound;
        ShipmentDateVisible := Type = Type::Outbound;
    end;

}

