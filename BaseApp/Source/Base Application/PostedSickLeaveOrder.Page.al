page 17465 "Posted Sick Leave Order"
{
    Caption = 'Posted Sick Leave Order';
    Editable = false;
    PageType = Document;
    SourceTable = "Posted Absence Header";
    SourceTableView = SORTING("Document Type", "No.")
                      WHERE("Document Type" = CONST("Sick Leave"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
                field("Sick Certificate Series"; "Sick Certificate Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sick Certificate No."; "Sick Certificate No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sick Certificate Date"; "Sick Certificate Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sick Certificate Reason"; "Sick Certificate Reason")
                {
                    ApplicationArea = Basic, Suite;
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
                    DrillDown = false;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Calendar Days"; "Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the number of calendar days.';
                }
            }
            part(Lines; "Posted Sick Leave Order Subf")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
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
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Cancel Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Order';
                    Image = Cancel;

                    trigger OnAction()
                    var
                        AbsenceOrderPostYesNo: Codeunit "Absence Order-Post (Yes/No)";
                    begin
                        Clear(AbsenceOrderPostYesNo);
                        AbsenceOrderPostYesNo.CancelOrder(Rec);
                        CurrPage.Update;
                    end;
                }
            }
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

