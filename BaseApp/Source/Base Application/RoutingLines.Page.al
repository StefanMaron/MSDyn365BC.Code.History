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
                field("Operation No."; "Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the operation number for this routing line.';
                }
                field("Previous Operation No."; "Previous Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the previous operation number, which is automatically assigned.';
                    Visible = false;
                }
                field("Next Operation No."; "Next Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the next operation number. You use this field if you use parallel routings.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the kind of capacity type to use for the actual operation.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Standard Task Code"; "Standard Task Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a standard task.';
                    Visible = false;
                }
                field("Routing Link Code"; "Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing link code.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Setup Time"; "Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the setup time of the operation.';
                }
                field("Setup Time Unit of Meas. Code"; "Setup Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the setup time of the operation.';
                    Visible = false;
                }
                field("Run Time"; "Run Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the run time of the operation.';
                }
                field("Run Time Unit of Meas. Code"; "Run Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the run time of the operation.';
                    Visible = false;
                }
                field("Wait Time"; "Wait Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the wait time according to the value in the Wait Time Unit of Measure field.';
                }
                field("Wait Time Unit of Meas. Code"; "Wait Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the wait time.';
                    Visible = false;
                }
                field("Move Time"; "Move Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the move time according to the value in the Move Time Unit of Measure field.';
                }
                field("Move Time Unit of Meas. Code"; "Move Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the move time.';
                    Visible = false;
                }
                field("Fixed Scrap Quantity"; "Fixed Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the fixed scrap quantity.';
                }
                field("Scrap Factor %"; "Scrap Factor %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the scrap factor in percent.';
                }
                field("Minimum Process Time"; "Minimum Process Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a minimum process time.';
                    Visible = false;
                }
                field("Maximum Process Time"; "Maximum Process Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a maximum process time.';
                    Visible = false;
                }
                field("Concurrent Capacities"; "Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of machines or persons that are working concurrently.';
                }
                field("Send-Ahead Quantity"; "Send-Ahead Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the send-ahead quantity.';
                }
                field("Unit Cost per"; "Unit Cost per")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit cost for this operation if it is different than the unit cost on the work center or machine center card.';
                }
                field("Lot Size"; "Lot Size")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the lot size which modifies the run time that you enter on routing lines by multiplying the value in the Run Time field with the lot size to reflect that it takes, for example, twice the time to process two pieces per operation.';
                    Visible = false;
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

                    trigger OnAction()
                    begin
                        ShowComment;
                    end;
                }
                action("&Tools")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Tools';
                    Image = Tools;
                    ToolTip = 'View or edit information about tools that are assigned to the operation.';

                    trigger OnAction()
                    begin
                        ShowTools;
                    end;
                }
                action("&Personnel")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Personnel';
                    Image = User;
                    ToolTip = 'View or edit the personnel that are assigned to the operation.';

                    trigger OnAction()
                    begin
                        ShowPersonnel;
                    end;
                }
                action("&Quality Measures")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Quality Measures';
                    ToolTip = 'View or edit the quality details that are assigned to the operation.';

                    trigger OnAction()
                    begin
                        ShowQualityMeasures;
                    end;
                }
            }
        }
    }

    var
        RtngComment: Record "Routing Comment Line";

    local procedure ShowComment()
    begin
        RtngComment.SetRange("Routing No.", "Routing No.");
        RtngComment.SetRange("Operation No.", "Operation No.");
        RtngComment.SetRange("Version Code", "Version Code");

        PAGE.Run(PAGE::"Routing Comment Sheet", RtngComment);
    end;

    local procedure ShowTools()
    var
        RtngTool: Record "Routing Tool";
    begin
        RtngTool.SetRange("Routing No.", "Routing No.");
        RtngTool.SetRange("Version Code", "Version Code");
        RtngTool.SetRange("Operation No.", "Operation No.");

        PAGE.Run(PAGE::"Routing Tools", RtngTool);
    end;

    local procedure ShowPersonnel()
    var
        RtngPersonnel: Record "Routing Personnel";
    begin
        RtngPersonnel.SetRange("Routing No.", "Routing No.");
        RtngPersonnel.SetRange("Version Code", "Version Code");
        RtngPersonnel.SetRange("Operation No.", "Operation No.");

        PAGE.Run(PAGE::"Routing Personnel", RtngPersonnel);
    end;

    local procedure ShowQualityMeasures()
    var
        RtngQltyMeasure: Record "Routing Quality Measure";
    begin
        RtngQltyMeasure.SetRange("Routing No.", "Routing No.");
        RtngQltyMeasure.SetRange("Version Code", "Version Code");
        RtngQltyMeasure.SetRange("Operation No.", "Operation No.");

        PAGE.Run(PAGE::"Routing Quality Measures", RtngQltyMeasure);
    end;
}

