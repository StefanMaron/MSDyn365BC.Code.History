page 6626 "Purchase Line Archive List"
{
    Caption = 'Purchase Line Archive List';
    Editable = false;
    PageType = List;
    SourceTable = "Purchase Line Archive";

    layout
    {
        area(content)
        {
            repeater(Control14)
            {
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of purchase document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the line.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry type.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the archived purchase line.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                    Visible = false;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the record.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of amounts in the Line Amount field on the purchase lines.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';
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
                action(ShowDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Document';
                    Image = View;
                    ToolTip = 'View the related document.';

                    trigger OnAction()
                    var
                        PurchaseHeaderArchive: Record "Purchase Header Archive";
                    begin
                        PurchaseHeaderArchive.Get("Document Type", "Document No.", "Doc. No. Occurrence", "Version No.");
                        case "Document Type" of
                            "Document Type"::Order:
                                PAGE.Run(PAGE::"Purchase Order Archive", PurchaseHeaderArchive);
                            "Document Type"::Quote:
                                PAGE.Run(PAGE::"Purchase Quote Archive", PurchaseHeaderArchive);
                            "Document Type"::"Blanket Order":
                                PAGE.Run(PAGE::"Blanket Purchase Order Archive", PurchaseHeaderArchive);
                            "Document Type"::"Return Order":
                                PAGE.Run(PAGE::"Purchase Return Order Archive", PurchaseHeaderArchive);
                        end;
                    end;
                }
            }
        }
    }
}

