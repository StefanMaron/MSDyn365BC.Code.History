namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Inventory.Reports;

page 5735 "Item Reference List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Reference List';
    PageType = List;
    SourceTable = "Item Reference";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the referenced item number. If you enter a reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the reference number on a sales or purchase document.';
                }
                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the reference entry.';
                }
                field("Reference Type No."; Rec."Reference Type No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a customer number, a vendor number, or a bar code, depending on what you have selected in the Type field.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number on the item card from which you opened the Item Reference Entries window.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item that is linked to this reference.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day from when the item reference is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day from when the item reference is valid.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the item that is linked to this reference.';
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
        area(Processing)
        {
            action(PrintLabel)
            {
                ApplicationArea = Basic, Suite;
                Image = Print;
                Caption = 'Print Label';
                ToolTip = 'Print Label';

                trigger OnAction()
                var
                    ItemReference: Record "Item Reference";
                    ReferenceNoLabel: Report "Reference No Label";
                begin
                    ItemReference := Rec;
                    CurrPage.SetSelectionFilter(ItemReference);
                    ReferenceNoLabel.SetTableView(ItemReference);
                    ReferenceNoLabel.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Report';

                actionref("Print Label"; PrintLabel)
                {

                }
            }
        }
    }
}

