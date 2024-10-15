page 17391 "Employee Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Employee Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Employee Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    EmplJnlMgt.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    EmplJnlMgt.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("HR Order No."; "HR Order No.")
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
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Post Action"; "Post Action")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Applies-to Entry"; "Applies-to Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the quantity on the journal line should be applied to an already-posted document.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Wage Period To"; "Wage Period To")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Wage Period From"; "Wage Period From")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("AE Period From"; "AE Period From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the average-earnings period. The period length is typically one year. ';
                }
                field("AE Period To"; "AE Period To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the average-earnings period. The period length is typically one year. ';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field("Payment Days"; "Payment Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Percent"; "Payment Percent")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Relative Person No."; "Relative Person No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Calendar Code"; "Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related work calendar. ';
                }
                field("Payroll Calc Group"; "Payroll Calc Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
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
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Vacation Type"; "Vacation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sick Leave Type"; "Sick Leave Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("External Document Date"; "External Document Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("External Document Issued By"; "External Document Issued By")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control22)
            {
                ShowCaption = false;
                label(Control24)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19039791;
                    ShowCaption = false;
                }
                field(EmployeeName; EmployeeName)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
                label(Control1210081)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19057987;
                    ShowCaption = false;
                }
                field(ElementDescription; ElementDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("L&ine")
            {
                Caption = 'L&ine';
                Image = Line;
                action("E&mployee Card")
                {
                    Caption = 'E&mployee Card';
                    Image = Employee;
                    RunObject = Page "Employee Card";
                    RunPageLink = "No." = FIELD("Employee No.");
                    ShortCutKey = 'Shift+F7';
                }
                action("E&lement Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&lement Card';
                    Image = EditLines;
                    RunObject = Page "Payroll Element Card";
                    RunPageLink = Code = FIELD("Element Code");
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.Update();
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
                action("Suggest Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Lines';
                    Image = SuggestLines;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        SuggestLines: Report "Suggest Salary Setup Lines";
                    begin
                        Clear(SuggestLines);
                        SuggestLines.SetJnlLine(Rec);
                        SuggestLines.Run;
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintEmplJnlLine(Rec);
                    end;
                }
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
                        CODEUNIT.Run(CODEUNIT::"Employee Journal - Post", Rec);
                        CurrentJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    PayrollElement: Record "Payroll Element";
                    TmpEmployeeJournalLine: Record "Employee Journal Line";
                    DocPrint: Codeunit "HR Order - Print";
                begin
                    if PayrollElement.Get("Element Code") then begin
                        // temporary stub, other reports should be avaliable from here later
                        PayrollElement.TestField(Type, PayrollElement.Type::Bonus);
                        case PayrollElement.Type of
                            PayrollElement.Type::Bonus:
                                begin
                                    TmpEmployeeJournalLine.Reset();
                                    TmpEmployeeJournalLine.SetRange("Journal Template Name", "Journal Template Name");
                                    TmpEmployeeJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
                                    TmpEmployeeJournalLine.SetRange("Document No.", "Document No.");
                                    if TmpEmployeeJournalLine.Count = 1 then
                                        DocPrint.PrintFormT11(Rec)
                                    else
                                        REPORT.RunModal(REPORT::"Reward Order T-11a", false, false, TmpEmployeeJournalLine)
                                end
                        end;
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EmplJnlMgt.GetAccounts(Rec, EmployeeName, ElementDescription);
    end;

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        OpenedFromBatch := ("Journal Batch Name" <> '') and ("Journal Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            EmplJnlMgt.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        EmplJnlMgt.TemplateSelection(PAGE::"Employee Journal", 0, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        EmplJnlMgt.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        EmplJnlMgt: Codeunit EmployeeJnlManagement;
        ReportPrint: Codeunit "Test Report-Print";
        CurrentJnlBatchName: Code[10];
        ElementDescription: Text[50];
        EmployeeName: Text[100];
        ShortcutDimCode: array[8] of Code[20];
        OpenedFromBatch: Boolean;
        Text19039791: Label 'Employee Name';
        Text19057987: Label 'Element Description';

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        EmplJnlMgt.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;
}

