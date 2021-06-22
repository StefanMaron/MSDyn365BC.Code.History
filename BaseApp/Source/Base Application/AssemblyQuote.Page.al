page 930 "Assembly Quote"
{
    Caption = 'Assembly Quote';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Assembly Header";
    SourceTableView = SORTING("Document Type", "No.")
                      ORDER(Ascending)
                      WHERE("Document Type" = CONST(Quote));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Assembly;
                    AssistEdit = true;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    TableRelation = Item."No." WHERE("Assembly BOM" = CONST(true));
                    ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly item.';
                }
                group(Control33)
                {
                    ShowCaption = false;
                    field(Quantity; Quantity)
                    {
                        ApplicationArea = Assembly;
                        Editable = IsAsmToOrderEditable;
                        Importance = Promoted;
                        ToolTip = 'Specifies how many units of the assembly item that you expect to assemble with the assembly order.';
                    }
                    field("Unit of Measure Code"; "Unit of Measure Code")
                    {
                        ApplicationArea = Assembly;
                        Editable = IsAsmToOrderEditable;
                        ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    }
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Assembly;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date on which the assembly order is posted.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Assembly;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to start.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to finish.';
                }
                field("Assemble to Order"; "Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the assembly order is linked to a sales order, which indicates that the item is assembled to order.';

                    trigger OnDrillDown()
                    begin
                        ShowAsmToOrder;
                    end;
                }
                field(Status; Status)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the document is open, waiting to be approved, invoiced for prepayment, or released to the next stage of processing.';
                }
            }
            part(Lines; "Assembly Quote Subform")
            {
                ApplicationArea = Assembly;
                Caption = 'Lines';
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location to which you want to post output of the assembly item.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = IsAsmToOrderEditable;
                    ToolTip = 'Specifies the bin the assembly item is posted to as output and from where it is taken to storage or shipped if it is assembled to a sales order.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Assembly;
                    Editable = IsUnitCostEditable;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = Assembly;
                    Editable = IsUnitCostEditable;
                    ToolTip = 'Specifies the total unit cost of the assembly order.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control11; "Assembly Item - Details")
            {
                ApplicationArea = Assembly;
                SubPageLink = "No." = FIELD("Item No.");
            }
            part(Control44; "Component - Item Details")
            {
                ApplicationArea = Assembly;
                Provider = Lines;
                SubPageLink = "No." = FIELD("No.");
            }
            part(Control43; "Component - Resource Details")
            {
                ApplicationArea = Assembly;
                Provider = Lines;
                SubPageLink = "No." = FIELD("No.");
            }
            systempart(Control8; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control9; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Statistics)
            {
                ApplicationArea = Assembly;
                Caption = 'Statistics';
                Image = Statistics;
                RunPageOnRec = true;
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                trigger OnAction()
                begin
                    ShowStatistics;
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
            action("Assembly BOM")
            {
                ApplicationArea = Assembly;
                Caption = 'Assembly BOM';
                Image = AssemblyBOM;
                ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';

                trigger OnAction()
                begin
                    ShowAssemblyList;
                end;
            }
            action(Comments)
            {
                ApplicationArea = Comments;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Assembly Comment Sheet";
                RunPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No."),
                              "Document Line No." = CONST(0);
                ToolTip = 'View or add comments for the record.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Update Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Unit Cost';
                    Enabled = IsUnitCostEditable;
                    Image = UpdateUnitCost;
                    ToolTip = 'Update the cost of the parent item per changes to the assembly BOM.';

                    trigger OnAction()
                    begin
                        UpdateUnitCost;
                    end;
                }
                action("Refresh Lines")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Refresh Lines';
                    Image = RefreshLines;
                    ToolTip = 'Update information on the lines according to changes that you made on the header.';

                    trigger OnAction()
                    begin
                        RefreshBOM;
                        CurrPage.Update;
                    end;
                }
                action("Show Availability")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Show Availability';
                    Image = ItemAvailbyLoc;
                    ToolTip = 'View how many of the assembly order quantity can be assembled by the due date based on availability of the required components. This is shown in the Able to Assemble field. ';

                    trigger OnAction()
                    begin
                        ShowAvailability;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsUnitCostEditable := not IsStandardCostItem;
        IsAsmToOrderEditable := not IsAsmToOrder;
    end;

    trigger OnOpenPage()
    begin
        IsUnitCostEditable := true;
        IsAsmToOrderEditable := true;

        UpdateWarningOnLines;
    end;

    var
        [InDataSet]
        IsUnitCostEditable: Boolean;
        [InDataSet]
        IsAsmToOrderEditable: Boolean;
}

