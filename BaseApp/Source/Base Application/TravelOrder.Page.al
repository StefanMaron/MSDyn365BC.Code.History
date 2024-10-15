page 17456 "Travel Order"
{
    Caption = 'Travel Order';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Absence Header";
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

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("HR Order No."; "HR Order No.")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("HR Order Date"; "HR Order Date")
                {
                    ApplicationArea = Basic, Suite;
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
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
            }
            part(Lines; "Travel Order Subform")
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

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.Update();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "HR Order Comment Lines";
                    RunPageLink = "Table Name" = CONST("Absence Order"),
                                  "No." = FIELD("No."),
                                  "Line No." = CONST(0);
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Rel&ease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rel&ease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';

                    trigger OnAction()
                    begin
                        ReleaseAbsenceHeader.Run(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    begin
                        ReleaseAbsenceHeader.Reopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Absence Order-Post (Yes/No)", Rec);
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
                        if AbsenceHeader.FindFirst then begin
                            AbsenceHeader.CalcFields("Calendar Days", "Start Date", "End Date");
                            HRDocPrint.PrintFormT9(AbsenceHeader, AbsenceHeader."Calendar Days",
                              AbsenceHeader."Start Date", AbsenceHeader."End Date");
                        end;
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
                        HRDocPrint: Codeunit "HR Order - Print";
                    begin
                        AbsenceHeader.Reset();
                        AbsenceHeader.SetRange("Document Type", "Document Type");
                        AbsenceHeader.SetRange("No.", "No.");
                        if AbsenceHeader.FindFirst then begin
                            AbsenceHeader.CalcFields("Calendar Days", "Start Date", "End Date");
                            HRDocPrint.PrintFormT10(AbsenceHeader, AbsenceHeader."Calendar Days",
                              AbsenceHeader."Start Date", AbsenceHeader."End Date");
                        end;
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
                        HRDocPrint: Codeunit "HR Order - Print";
                    begin
                        AbsenceHeader.Reset();
                        AbsenceHeader.SetRange("Document Type", "Document Type");
                        AbsenceHeader.SetRange("No.", "No.");
                        if AbsenceHeader.FindFirst then begin
                            AbsenceHeader.CalcFields("Calendar Days", "Start Date", "End Date");
                            HRDocPrint.PrintFormT10a(AbsenceHeader, AbsenceHeader."Calendar Days",
                              AbsenceHeader."Start Date", AbsenceHeader."End Date");
                        end;
                    end;
                }
            }
        }
    }

    var
        ReleaseAbsenceHeader: Codeunit "Release Absence Order";
}

