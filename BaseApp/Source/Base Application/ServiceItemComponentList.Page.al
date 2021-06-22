page 5986 "Service Item Component List"
{
    Caption = 'Service Item Component List';
    DataCaptionFields = "Parent Service Item No.", "Line No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Service Item Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Parent Service Item No."; "Parent Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item in which the component is included.';
                    Visible = false;
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the line.';
                    Visible = false;
                }
                field(Active; Active)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the component is in use.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the component type.';
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
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the component.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the component.';

                    trigger OnAssistEdit()
                    begin
                        AssistEditSerialNo;
                    end;
                }
                field("Date Installed"; "Date Installed")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the component was installed.';
                }
                field("From Line No."; "From Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the line number assigned to the component when it was an active component of the service item.';
                    Visible = false;
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the component was last modified.';
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
            group("Com&ponent")
            {
                Caption = 'Com&ponent';
                Image = Components;
                action("&Copy from BOM")
                {
                    ApplicationArea = Service;
                    Caption = '&Copy from BOM';
                    Image = CopyFromBOM;
                    ToolTip = 'Insert the service item components of the service item''s bill of material. ';

                    trigger OnAction()
                    begin
                        ServItem.Get("Parent Service Item No.");
                        CODEUNIT.Run(CODEUNIT::"ServComponent-Copy from BOM", ServItem);
                    end;
                }
                group("&Replaced List")
                {
                    Caption = '&Replaced List';
                    Image = ItemSubstitution;
                    action(ThisLine)
                    {
                        ApplicationArea = Service;
                        Caption = 'This Line';
                        Image = Line;
                        RunObject = Page "Replaced Component List";
                        RunPageLink = Active = CONST(false),
                                      "Parent Service Item No." = FIELD("Parent Service Item No."),
                                      "From Line No." = FIELD("Line No.");
                        RunPageView = SORTING(Active, "Parent Service Item No.", "From Line No.");
                        ToolTip = 'View or edit the list of service item components that have been replaced for the selected service item component.';
                    }
                    action(AllLines)
                    {
                        ApplicationArea = Service;
                        Caption = 'All Lines';
                        Image = AllLines;
                        RunObject = Page "Replaced Component List";
                        RunPageLink = Active = CONST(false),
                                      "Parent Service Item No." = FIELD("Parent Service Item No.");
                        RunPageView = SORTING(Active, "Parent Service Item No.", "From Line No.");
                        ToolTip = 'View or edit the list of all service item components that have been replaced.';
                    }
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Line No." := SplitLineNo(xRec, BelowxRec);
    end;

    var
        ServItem: Record "Service Item";
}

