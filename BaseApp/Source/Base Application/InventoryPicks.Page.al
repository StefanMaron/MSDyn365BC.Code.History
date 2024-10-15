page 9316 "Inventory Picks"
{
    ApplicationArea = Warehouse;
    Caption = 'Inventory Picks';
    CardPageID = "Inventory Pick";
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Activity Header";
    SourceTableView = WHERE(Type = CONST("Invt. Pick"));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(SourceDocument; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of activity, such as Put-away, that the warehouse performs on the lines that are attached to the header.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the location where the warehouse activity takes place.';
                }
                field("Destination Type"; "Destination Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies information about the type of destination, such as customer or vendor, associated with the warehouse activity.';
                }
                field("Destination No."; "Destination No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number or the code of the customer or vendor that the line is linked to.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                    Visible = false;
                }
                field("No. of Lines"; "No. of Lines")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of lines in the warehouse activity document.';
                }
                field("Sorting Method"; "Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the lines are sorted on the warehouse header, such as Item or Document.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("P&ick")
            {
                Caption = 'P&ick';
                Image = CreateInventoryPickup;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Whse. Activity Header"),
                                  Type = FIELD(Type),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Posted Picks")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Picks';
                    Image = PostedInventoryPick;
                    RunObject = Page "Posted Invt. Pick List";
                    RunPageLink = "Invt Pick No." = FIELD("No.");
                    RunPageView = SORTING("Invt Pick No.");
                    ToolTip = 'View any quantities that have already been picked.';
                }
                action("Source Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source Document';
                    Image = "Order";
                    ToolTip = 'View the source document of the warehouse activity.';

                    trigger OnAction()
                    var
                        WMSMgt: Codeunit "WMS Management";
                    begin
                        WMSMgt.ShowSourceDocCard("Source Type", "Source Subtype", "Source No.");
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        ErrorIfUserIsNotWhseEmployee;
        FilterGroup(2); // set group of filters user cannot change
        SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId));
        FilterGroup(0); // set filter group back to standard
    end;
}

