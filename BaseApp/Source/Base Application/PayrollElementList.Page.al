page 17401 "Payroll Element List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Elements';
    CardPageID = "Payroll Element Card";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Payroll Element";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Element Group"; "Element Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payroll element group for tax registration purposes.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Directory Code"; "Directory Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Calculate; Calculate)
                {
                    Visible = false;
                }
                field("Normal Sign"; "Normal Sign")
                {
                    Visible = false;
                }
                field("Posting Type"; "Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payroll Posting Group"; "Payroll Posting Group")
                {
                    Visible = false;
                }
                field("Income Tax Base"; "Income Tax Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FSI Base"; "FSI Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FSI Injury Base"; "FSI Injury Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Federal FMI Base"; "Federal FMI Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Territorial FMI Base"; "Territorial FMI Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("PF Base"; "PF Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Print Priority"; "Print Priority")
                {
                    Visible = false;
                }
                field("Used for Spreadsheet"; "Used for Spreadsheet")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Use Indexation"; "Use Indexation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Depends on Salary Element"; "Depends on Salary Element")
                {
                    Visible = false;
                }
                field("Distribute by Periods"; "Distribute by Periods")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Calculations; Calculations)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Amounts"; "Base Amounts")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Ranges; Ranges)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("T-3 Report Column"; "T-3 Report Column")
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
            group(Element)
            {
                Caption = 'Element';
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(17400),
                                  "No." = FIELD(Code);
                    ShortCutKey = 'Shift+Ctrl+D';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment List";
                    RunPageLink = "Table Name" = CONST(Element),
                                  "No." = FIELD(Code);
                }
                separator(Action1210003)
                {
                }
                action("Ledger Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger Entry';
                    Image = LedgerEntries;
                    RunObject = Page "Payroll Ledger Entries";
                    RunPageLink = "Element Code" = FIELD(Code);
                    RunPageView = SORTING("Element Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the related transaction.';
                }
            }
            group(Calculation)
            {
                Caption = 'Calculation';
                action(Action24)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculation';
                    Image = CalculatePlan;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Payroll Calculations";
                    RunPageLink = "Element Code" = FIELD(Code);
                }
                action("Basic Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Basic Amount';
                    Image = FilterLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Payroll Base Amounts";
                    RunPageLink = "Element Code" = FIELD(Code);
                }
                action(Range)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Range';
                    Image = SetupList;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Payroll Ranges";
                    RunPageLink = "Element Code" = FIELD(Code);
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Copy)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy';
                    Ellipsis = true;
                    Image = Copy;

                    trigger OnAction()
                    begin
                        CopyPayrollElement.SetPayrollElement(Rec);
                        CopyPayrollElement.Run;
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Ellipsis = true;
                    Image = Export;

                    trigger OnAction()
                    var
                        PayrollElement: Record "Payroll Element";
                    begin
                        CurrPage.SetSelectionFilter(PayrollElement);
                        PayrollDataExchangeMgt.ExportPayrollElements(PayrollElement);
                    end;
                }
            }
        }
    }

    var
        CopyPayrollElement: Report "Copy Payroll Element";
        PayrollDataExchangeMgt: Codeunit "Payroll Data Exchange Mgt.";

    [Scope('OnPrem')]
    procedure GetSelectionFilter(): Text
    var
        PayrollElement: Record "Payroll Element";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(PayrollElement);
        exit(SelectionFilterManagement.GetSelectionFilterForPayrollElement(PayrollElement));
    end;

    [Scope('OnPrem')]
    procedure SetSelection(var PayrollElement: Record "Payroll Element")
    begin
        CurrPage.SetSelectionFilter(PayrollElement);
    end;
}

