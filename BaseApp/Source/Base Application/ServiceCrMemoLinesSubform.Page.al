page 6039 "Service Cr. Memo Lines Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Cr.Memo Line";

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
                    Lookup = false;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the credit memo.';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer to receive the service on the credit memo.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the credit memo line.';
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
                field(Nonstock; Nonstock)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the item on the credit memo line is a catalog item.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the name of an item, resource, cost, general ledger account, or some descriptive text on the service credit memo line.';
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, in which the credit memo line was registered.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
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
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of item units, resource hours, general ledger account payments, or cost specified on the credit memo line.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;
                }
                field("Inv. Discount Amount"; "Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
                    Visible = false;
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract associated with the posted service credit memo.';
                    Visible = false;
                }
                field("Shipment No."; "Shipment No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the posted shipment for this credit memo line.';
                    Visible = false;
                }
                field("Service Item No."; "Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item linked to this credit memo line.';
                    Visible = false;
                }
                field("Appl.-to Service Entry"; "Appl.-to Service Entry")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service ledger entry applied to this service credit memo.';
                    Visible = false;
                }
                field("Appl.-from Item Entry"; "Appl.-from Item Entry")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := IsFirstDocLine;
        DocumentNoHideValue := not IsFirstDocLine;
    end;

    var
        TempServCrMemoLine: Record "Service Cr.Memo Line" temporary;
        [InDataSet]
        StyleIsStrong: Boolean;
        [InDataSet]
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        ServCrMemoLine: Record "Service Cr.Memo Line";
    begin
        TempServCrMemoLine.Reset();
        TempServCrMemoLine.CopyFilters(Rec);
        TempServCrMemoLine.SetRange("Document No.", "Document No.");
        if not TempServCrMemoLine.FindFirst then begin
            ServCrMemoLine.CopyFilters(Rec);
            ServCrMemoLine.SetRange("Document No.", "Document No.");
            if not ServCrMemoLine.FindFirst then
                exit(false);
            TempServCrMemoLine := ServCrMemoLine;
            TempServCrMemoLine.Insert();
        end;
        exit("Line No." = TempServCrMemoLine."Line No.");
    end;
}

