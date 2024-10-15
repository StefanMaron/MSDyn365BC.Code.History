namespace Microsoft.Sales.Archive;

page 6619 "Sales Line Archive List"
{
    Caption = 'Sales Line Archive List';
    Editable = false;
    PageType = List;
    SourceTable = "Sales Line Archive";

    layout
    {
        area(content)
        {
            repeater(Control14)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of sales document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the line.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry type.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the archived sales line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                    Visible = false;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the record.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of amounts in the Line Amount field on the sales lines.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';
                    Visible = false;
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
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the related document.';

                    trigger OnAction()
                    var
                        SalesHeaderArchive: Record "Sales Header Archive";
                    begin
                        SalesHeaderArchive.Get(Rec."Document Type", Rec."Document No.", Rec."Doc. No. Occurrence", Rec."Version No.");
                        case Rec."Document Type" of
                            Rec."Document Type"::Order:
                                PAGE.Run(PAGE::"Sales Order Archive", SalesHeaderArchive);
                            Rec."Document Type"::Quote:
                                PAGE.Run(PAGE::"Sales Quote Archive", SalesHeaderArchive);
                            Rec."Document Type"::"Blanket Order":
                                PAGE.Run(PAGE::"Blanket Sales Order Archive", SalesHeaderArchive);
                            Rec."Document Type"::"Return Order":
                                PAGE.Run(PAGE::"Sales Return Order Archive", SalesHeaderArchive);
                        end;
                    end;
                }
            }
        }
    }
}

