page 17468 "Posted Travel Order"
{
    Caption = 'Posted Travel Order';
    Editable = false;
    PageType = Document;
    SourceTable = "Posted Absence Header";
    SourceTableView = WHERE("Document Type" = CONST(Travel));

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
                field("Travel Destination"; "Travel Destination")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Travel Purpose"; "Travel Purpose")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Travel Reason Document"; "Travel Reason Document")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Travel Paid By Type"; "Travel Paid By Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Travel Paid by No."; "Travel Paid by No.")
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
            part(Lines; "Posted Travel Order Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
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
            group(Print)
            {
                Caption = 'Print';
                Image = Print;
                action("Travel Order T-9")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Travel Order T-9';
                    Image = PrintReport;

                    trigger OnAction()
                    var
                        AbsenceHeader: Record "Absence Header";
                        HRDocPrint: Codeunit "HR Order - Print";
                    begin
                        AbsenceHeader.Reset();
                        AbsenceHeader.SetRange("Document Type", "Document Type");
                        AbsenceHeader.SetRange("No.", "No.");
                        AbsenceHeader.TransferFields(Rec);
                        CalcFields("Calendar Days", "Start Date", "End Date");
                        HRDocPrint.PrintFormT9(AbsenceHeader, "Calendar Days", "Start Date", "End Date");
                    end;
                }
                action("Travel Warrant T-10")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Travel Warrant T-10';
                    Image = PrintReport;

                    trigger OnAction()
                    var
                        AbsenceHeader: Record "Absence Header";
                    begin
                        AbsenceHeader.Reset();
                        AbsenceHeader.SetRange("Document Type", "Document Type");
                        AbsenceHeader.SetRange("No.", "No.");
                        AbsenceHeader.TransferFields(Rec);
                        CalcFields("Calendar Days", "Start Date", "End Date");
                        HROrderPrint.PrintFormT10(AbsenceHeader, "Calendar Days", "Start Date", "End Date");
                    end;
                }
                action("Work Assignment T-10a")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Work Assignment T-10a';
                    Image = PrintReport;

                    trigger OnAction()
                    var
                        AbsenceHeader: Record "Absence Header";
                    begin
                        AbsenceHeader.Reset();
                        AbsenceHeader.SetRange("Document Type", "Document Type");
                        AbsenceHeader.SetRange("No.", "No.");
                        AbsenceHeader.TransferFields(Rec);
                        CalcFields("Calendar Days", "Start Date", "End Date");
                        HROrderPrint.PrintFormT10a(AbsenceHeader, "Calendar Days", "Start Date", "End Date");
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

    var
        HROrderPrint: Codeunit "HR Order - Print";
}

