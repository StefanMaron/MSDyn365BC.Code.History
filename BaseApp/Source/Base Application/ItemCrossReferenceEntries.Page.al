page 5721 "Item Cross Reference Entries"
{
    Caption = 'Item Cross Reference Entries';
    DataCaptionFields = "Item No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Item Cross Reference";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Item Reference feature.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Cross-Reference Type"; "Cross-Reference Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the cross-reference entry.';
                }
                field("Cross-Reference Type No."; "Cross-Reference Type No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a customer number, a vendor number, or a bar code, depending on what you have selected in the Type field.';
                }
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cross-referenced item number. If you enter a cross reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the cross-reference number on a sales or purchase document.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item linked to this cross reference. It will override the standard description when entered on an order.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the item linked to this cross reference.';
                    Visible = false;
                }
                field("Discontinue Bar Code"; "Discontinue Bar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you want the program to discontinue a bar code cross reference.';
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
            group(DemoData)
            {
                Caption = 'Demo Data';
                Image = DataEntry;
                action(Create)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Data';
                    Image = Category;
                    ToolTip = 'Create demo data for vendors 10000..50000 and items 1100..1800.';

                    trigger OnAction()
                    begin
                        CreateDemoData();
                    end;
                }
            }
        }
    }

    local procedure CreateDemoData()
    var
        Item: Record Item;
        ItemCrossReference: Record "Item Cross Reference";
        Vendor: Record Vendor;
    begin
        ItemCrossReference.Reset();
        Vendor.SetFilter("No.", '%1..%2', '10000', '50000');
        if Item.FindSet() then
            repeat
                if Vendor.FindSet() then
                    repeat
                        ItemCrossReference.Init();
                        ItemCrossReference."Cross-Reference Type" := ItemCrossReference."Cross-Reference Type"::Vendor;
                        ItemCrossReference."Cross-Reference Type No." := Vendor."No.";
                        ItemCrossReference.Validate("Item No.", Item."No.");
                        ItemCrossReference.Validate("Cross-Reference No.", 'V' + Item."No.");
                        ItemCrossReference.Description := Item.Description;
                        if ItemCrossReference.Insert() then;
                    until Vendor.Next() = 0;
            until Item.Next() = 0;

        message('Demo data created: %1', ItemCrossReference.Count());
    end;
}

