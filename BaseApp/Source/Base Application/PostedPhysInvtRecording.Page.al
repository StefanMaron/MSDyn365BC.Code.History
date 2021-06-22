page 5887 "Posted Phys. Invt. Recording"
{
    Caption = 'Posted Phys. Invt. Recording';
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Pstd. Phys. Invt. Record Hdr";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related physical inventory order.';
                }
                field("Recording No."; "Recording No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related physical inventory recording.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies a description of the physical inventory recording.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location where the recording was performed.';
                }
                field("Person Responsible"; "Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the person who was responsible for the recording.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the recording is Open or Finished';
                }
                field("Person Recorded"; "Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the person who performed the recording.';
                }
                field("Date Recorded"; "Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the day when the recording was performed.';
                }
                field("Time Recorded"; "Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the time when the recording was performed.';
                }
                field("Allow Recording Without Order"; "Allow Recording Without Order")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies that recording lines were automatically created for items that did not exist on the physical inventory order. This can only happen if none of the values in these four fields exist for an item on the order: Item No., Variant Code, Location Code, and Bin Code.';
                }
            }
            part(Control24; "Posted Phys. Invt. Rec. Subf.")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Order No." = FIELD("Order No."),
                              "Recording No." = FIELD("Recording No.");
                SubPageView = SORTING("Order No.", "Recording No.", "Line No.");
            }
        }
        area(factboxes)
        {
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
            group("&Recording")
            {
                Caption = '&Recording';
                Image = Document;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Phys. Inventory Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Recording"),
                                  "Order No." = FIELD("Order No."),
                                  "Recording No." = FIELD("Recording No.");
                    ToolTip = 'Show comments.';
                }
            }
        }
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the posted physical inventory recording.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintPostedInvtRecording(Rec, true);
                end;
            }
        }
        area(reporting)
        {
            action("Posted Phys. Invt. Recording")
            {
                ApplicationArea = Warehouse;
                Caption = 'Posted Phys. Invt. Recording';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Posted Phys. Invt. Recording";
                ToolTip = 'Print Posted Phys. Invt. Recording.';
            }
        }
    }
}

