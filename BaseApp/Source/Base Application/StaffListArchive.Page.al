page 17388 "Staff List Archive"
{
    Caption = 'Staff List Archive';
    PageType = Document;
    SourceTable = "Staff List Archive";
    SourceTableView = SORTING("Document No.");

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("HR Manager No."; "HR Manager No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Chief Accountant No."; "Chief Accountant No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Staff List Date"; "Staff List Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Staff Positions"; "Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Out-of-Staff Positions"; "Out-of-Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
            }
            part(Control1210010; "Staff List Archive Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Document No." = FIELD("Document No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "HR Order Comment Lines";
                    RunPageLink = "Table Name" = CONST("SL Archive"),
                                  "No." = FIELD("Document No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    StaffingListOrder: Record "Staff List Archive";
                begin
                    StaffingListOrder.SetRange("Document No.", "Document No.");
                    REPORT.Run(REPORT::"Staffing List T-3", true, true, StaffingListOrder);
                end;
            }
        }
    }
}

