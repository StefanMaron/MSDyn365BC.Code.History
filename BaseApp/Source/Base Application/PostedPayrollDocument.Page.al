page 17417 "Posted Payroll Document"
{
    Caption = 'Posted Payroll Document';
    Editable = false;
    PageType = Document;
    SourceTable = "Posted Payroll Document";

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
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Posting Type"; "Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Calc Group Code"; "Calc Group Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field(Correction; Correction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry as a corrective entry. You can use the field if you need to post a corrective entry to an account.';
                }
                field("Reversing Document No."; "Reversing Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that reverses the original document.';
                }
            }
            part(DocLines; "Posted Payroll Document Subf.")
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
            group("D&ocument")
            {
                Caption = 'D&ocument';
                Image = Document;
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Posted Payroll Doc. Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

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
                    RunPageLink = "Table Name" = CONST("P.Payroll Document"),
                                  "No." = FIELD("No."),
                                  "Line No." = CONST(0);
                }
            }
        }
        area(processing)
        {
            group("P&rint")
            {
                Caption = 'P&rint';
                Image = Print;
                action("Sick Leave Absence")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sick Leave Absence';
                    Image = Absence;

                    trigger OnAction()
                    var
                        PostedPayrollDocLine: Record "Posted Payroll Document Line";
                        HROrderPrint: Codeunit "HR Order - Print";
                    begin
                        CurrPage.DocLines.PAGE.GetSelectedLine(PostedPayrollDocLine);
                        HROrderPrint.PrintSickLeaveAbsence(Rec, PostedPayrollDocLine);
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

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }
}

