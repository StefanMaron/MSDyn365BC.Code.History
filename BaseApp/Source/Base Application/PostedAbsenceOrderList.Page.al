page 17475 "Posted Absence Order List"
{
    Caption = 'Posted Absence Order List';
    Editable = false;
    PageType = List;
    SourceTable = "Posted Absence Header";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Calendar Days"; "Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of calendar days.';
                }
                field("Working Days"; "Working Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a comment is associated with this entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("Assigned User ID");
                    end;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field(Note; Note)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the note text or if a note exists.';
                }
                field("Travel Destination"; "Travel Destination")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Days"; "Payment Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Hours"; "Payment Hours")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("District Coefficient"; "District Coefficient")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allocation Type"; "Allocation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which VAT allocation type is used.';
                }
                field("Use Salary Indexation"; "Use Salary Indexation")
                {
                    ApplicationArea = Basic, Suite;
                }
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
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';

                    trigger OnAction()
                    begin
                        case "Document Type" of
                            "Document Type"::Vacation:
                                PAGE.Run(PAGE::"Posted Vacation Order", Rec);
                            "Document Type"::"Sick Leave":
                                PAGE.Run(PAGE::"Posted Sick Leave Order", Rec);
                            "Document Type"::Travel:
                                PAGE.Run(PAGE::"Posted Travel Order", Rec);
                            "Document Type"::"Other Absence":
                                PAGE.Run(PAGE::"Posted Other Absence Order", Rec);
                        end;
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "HR Order Comment Lines";
                    RunPageLink = "Table Name" = CONST("P.Absence Order"),
                                  "No." = FIELD("No."),
                                  "Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }
}

