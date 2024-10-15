namespace Microsoft.Manufacturing.Routing;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;

page 99000765 "Routing Lines"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Routing Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the operation number for this routing line.';
                }
                field("Previous Operation No."; Rec."Previous Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the previous operation number, which is automatically assigned.';
                    Visible = false;
                }
                field("Next Operation No."; Rec."Next Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the next operation number. You use this field if you use parallel routings.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the kind of capacity type to use for the actual operation.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    begin
                        SetEditable();
                    end;
                }
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a standard task.';
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing link code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the setup time of the operation.';
                }
                field("Setup Time Unit of Meas. Code"; Rec."Setup Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the setup time of the operation.';
                    Visible = false;
                }
                field("Run Time"; Rec."Run Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the run time of the operation.';
                }
                field("Run Time Unit of Meas. Code"; Rec."Run Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the run time of the operation.';
                    Visible = false;
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the wait time according to the value in the Wait Time Unit of Measure field.';
                }
                field("Wait Time Unit of Meas. Code"; Rec."Wait Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the wait time.';
                    Visible = false;
                }
                field("Move Time"; Rec."Move Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the move time according to the value in the Move Time Unit of Measure field.';
                }
                field("Move Time Unit of Meas. Code"; Rec."Move Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the move time.';
                    Visible = false;
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the fixed scrap quantity.';
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the scrap factor in percent.';
                }
                field("Minimum Process Time"; Rec."Minimum Process Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a minimum process time.';
                    Visible = false;
                }
                field("Maximum Process Time"; Rec."Maximum Process Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a maximum process time.';
                    Visible = false;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of machines or persons that are working concurrently.';
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the send-ahead quantity.';
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                    ApplicationArea = Manufacturing;
                    Editable = UnitCostPerEditable;
                    ToolTip = 'Specifies the unit cost for this operation if it is different than the unit cost on the work center card.';
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of items that are included in the same operation at the same time. The run time on routing lines is reduced proportionally to the lot size. For example, if the lot size is two pieces, the run time will be reduced by half.';
                    Visible = false;
                }
                field("WIP Item"; Rec."WIP Item")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the item is a work in process (WIP) item.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Operation")
            {
                Caption = '&Operation';
                Image = Task;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowComment();
                    end;
                }
                action("&Tools")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Tools';
                    Image = Tools;
                    ToolTip = 'View or edit information about tools that are assigned to the operation.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowTools();
                    end;
                }
                action("&Personnel")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Personnel';
                    Image = User;
                    ToolTip = 'View or edit the personnel that are assigned to the operation.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowPersonnel();
                    end;
                }
                action("&Quality Measures")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Quality Measures';
                    ToolTip = 'View or edit the quality details that are assigned to the operation.';
                    Enabled = ShowRelatedDataEnabled;

                    trigger OnAction()
                    begin
                        ShowQualityMeasures();
                    end;
                }
                action("Subcontracting Prices")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Prices';
                    Image = Price;
                    ToolTip = 'View the related subcontracting prices.';

                    trigger OnAction()
                    begin
                        ShowSubcPrices();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowRelatedDataEnabled := Rec."Operation No." <> '';
        SetEditable();
    end;

    trigger OnInit()
    begin
        UnitCostPerEditable := true;
    end;

    var
        RtngComment: Record "Routing Comment Line";
        ShowRelatedDataEnabled: Boolean;
        UnitCostPerEditable: Boolean;

    local procedure ShowComment()
    begin
        RtngComment.SetRange("Routing No.", Rec."Routing No.");
        RtngComment.SetRange("Operation No.", Rec."Operation No.");
        RtngComment.SetRange("Version Code", Rec."Version Code");

        PAGE.Run(PAGE::"Routing Comment Sheet", RtngComment);
    end;

    local procedure ShowTools()
    var
        RtngTool: Record "Routing Tool";
    begin
        RtngTool.SetRange("Routing No.", Rec."Routing No.");
        RtngTool.SetRange("Version Code", Rec."Version Code");
        RtngTool.SetRange("Operation No.", Rec."Operation No.");

        PAGE.Run(PAGE::"Routing Tools", RtngTool);
    end;

    local procedure ShowPersonnel()
    var
        RtngPersonnel: Record "Routing Personnel";
    begin
        RtngPersonnel.SetRange("Routing No.", Rec."Routing No.");
        RtngPersonnel.SetRange("Version Code", Rec."Version Code");
        RtngPersonnel.SetRange("Operation No.", Rec."Operation No.");

        PAGE.Run(PAGE::"Routing Personnel", RtngPersonnel);
    end;

    local procedure ShowQualityMeasures()
    var
        RtngQltyMeasure: Record "Routing Quality Measure";
    begin
        RtngQltyMeasure.SetRange("Routing No.", Rec."Routing No.");
        RtngQltyMeasure.SetRange("Version Code", Rec."Version Code");
        RtngQltyMeasure.SetRange("Operation No.", Rec."Operation No.");

        PAGE.Run(PAGE::"Routing Quality Measures", RtngQltyMeasure);
    end;

    [Scope('OnPrem')]
    procedure ShowSubcPrices()
    var
        SubcPrice: Record "Subcontractor Prices";
    begin
        Rec.TestField(Type, Rec.Type::"Work Center");
        SubcPrice.SetRange("Work Center No.", Rec."No.");
        if Rec."Standard Task Code" <> '' then
            SubcPrice.SetRange("Standard Task Code", Rec."Standard Task Code")
        else
            SubcPrice.SetRange("Standard Task Code");

        PAGE.Run(PAGE::"Subcontracting Prices", SubcPrice);
    end;

    local procedure SetEditable()
    begin
        UnitCostPerEditable := Rec.Type = "Capacity Type Routing"::"Work Center";
    end;
}

