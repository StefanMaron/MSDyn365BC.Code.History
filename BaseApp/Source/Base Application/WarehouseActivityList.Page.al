page 5774 "Warehouse Activity List"
{
    Caption = 'Warehouse Activity List';
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Activity Header";

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
                field(Type; Type)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of activity, such as Put-away, that the warehouse performs on the lines that are attached to the header.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
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
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        case Type of
                            Type::"Put-away":
                                PAGE.Run(PAGE::"Warehouse Put-away", Rec);
                            Type::Pick:
                                PAGE.Run(PAGE::"Warehouse Pick", Rec);
                            Type::Movement:
                                PAGE.Run(PAGE::"Warehouse Movement", Rec);
                            Type::"Invt. Put-away":
                                PAGE.Run(PAGE::"Inventory Put-away", Rec);
                            Type::"Invt. Pick":
                                PAGE.Run(PAGE::"Inventory Pick", Rec);
                            Type::"Invt. Movement":
                                PAGE.Run(PAGE::"Inventory Movement", Rec);
                        end;
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Put-away List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Put-away List';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Put-away List";
                ToolTip = 'View or print a detailed list of items that must be put away.';
            }
            action("Picking List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Picking List';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Picking List";
                ToolTip = 'View or print a detailed list of items that must be picked.';
            }
            action("Warehouse Movement List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Movement List';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Movement List";
                ToolTip = 'View or print a detailed list of items that must be moved within the warehouse.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := FormCaption;
    end;

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        ErrorIfUserIsNotWhseEmployee;
        FilterGroup(2); // set group of filters user cannot change
        SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId));
        FilterGroup(0); // set filter group back to standard
    end;

    var
        Text000: Label 'Warehouse Put-away List';
        Text001: Label 'Warehouse Pick List';
        Text002: Label 'Warehouse Movement List';
        Text003: Label 'Warehouse Activity List';
        Text004: Label 'Inventory Put-away List';
        Text005: Label 'Inventory Pick List';
        Text006: Label 'Inventory Movement List';

    local procedure FormCaption(): Text[250]
    begin
        case Type of
            Type::"Put-away":
                exit(Text000);
            Type::Pick:
                exit(Text001);
            Type::Movement:
                exit(Text002);
            Type::"Invt. Put-away":
                exit(Text004);
            Type::"Invt. Pick":
                exit(Text005);
            Type::"Invt. Movement":
                exit(Text006);
            else
                exit(Text003);
        end;
    end;
}

