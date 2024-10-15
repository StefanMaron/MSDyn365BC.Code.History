page 7343 "Pick Selection"
{
    Caption = 'Pick Selection';
    DataCaptionFields = "Document Type", "Location Code";
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Pick Request";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document from which the pick originated.';
                }
                field("Document Subtype"; "Document Subtype")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the component pick request is related to, such as Released and Assembly.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse document for which the program has received a pick request.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location in which the request is occurring.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field(AssembleToOrder; GetAsmToOrder)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assemble to Order';
                    Editable = false;
                    ToolTip = 'Specifies the assembly item that are not physically present until they have been assembled.';
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
    }

    procedure GetResult(var WhsePickRqst: Record "Whse. Pick Request")
    begin
        CurrPage.SetSelectionFilter(WhsePickRqst);
    end;

    local procedure GetAsmToOrder(): Boolean
    var
        AsmHeader: Record "Assembly Header";
    begin
        if "Document Type" = "Document Type"::Assembly then begin
            AsmHeader.Get("Document Subtype", "Document No.");
            AsmHeader.CalcFields("Assemble to Order");
            exit(AsmHeader."Assemble to Order");
        end;
    end;
}

