page 17414 "Payroll Document"
{
    Caption = 'Payroll Document';
    PageType = Document;
    SourceTable = "Payroll Document";

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
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Posting Type"; "Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Code"; "Period Code")
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
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
            }
            part(DocLines; "Payroll Document Subform")
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
                    RunObject = Page "Payroll Document Statistics";
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
                    RunPageLink = "Table Name" = CONST("Payroll Document"),
                                  "No." = FIELD("No."),
                                  "Line No." = CONST(0);
                }
                action("Employee Card")
                {
                    Caption = 'Employee Card';
                    Image = Employee;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Employee Card";
                    RunPageLink = "No." = FIELD("Employee No.");
                    ShortCutKey = 'Shift+F7';
                }
                action("Daily Timesheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Daily Timesheet';
                    Image = Timesheet;

                    trigger OnAction()
                    var
                        EmployeeTimesheet: Page "Employee Timesheet";
                    begin
                        EmployeeTimesheet.Set("Employee No.", "Posting Date");
                        EmployeeTimesheet.Run;
                        Clear(EmployeeTimesheet);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Documents';
                    Ellipsis = true;
                    Image = Suggest;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        SuggestDocuments: Report "Suggest Payroll Documents";
                    begin
                        Clear(SuggestDocuments);
                        SuggestDocuments.Set("Period Code", '', 0D, true);
                        SuggestDocuments.RunModal;
                        CurrPage.Update(false);
                    end;
                }
                action("Copy Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Image = CopyDocument;

                    trigger OnAction()
                    begin
                        CopyPayrollDoc.SetPayrollDoc(Rec);
                        CopyPayrollDoc.RunModal;
                        Clear(CopyPayrollDoc);
                    end;
                }
                separator(Action1210024)
                {
                }
                action("Re&lease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Codeunit "Release Payroll Document";
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    var
                        ReleasePayrollDoc: Codeunit "Release Payroll Document";
                    begin
                        ReleasePayrollDoc.Reopen(Rec);
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
                    RunObject = Codeunit "Payroll Document - Post (Y/N)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';
                }
                action("Post &Batch")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Payroll Documents", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        CopyPayrollDoc: Report "Copy Payroll Document";
}

