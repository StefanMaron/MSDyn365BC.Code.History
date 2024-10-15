page 17400 "Payroll Element Card"
{
    Caption = 'Payroll Element Card';
    PageType = Card;
    SourceTable = "Payroll Element";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
                field("Pay Type"; "Pay Type")
                {
                    ApplicationArea = All;
                    Visible = PayTypeVisible;
                }
                field("Bonus Type"; "Bonus Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Depends on Salary Element"; "Depends on Salary Element")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Normal Sign"; "Normal Sign")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Posting Type"; "Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payroll Posting Group"; "Payroll Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Print Priority"; "Print Priority")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("T-3 Report Column"; "T-3 Report Column")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control1906752401)
            {
                Caption = 'Calculation';
                field(Calculate; Calculate)
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
                field("Use Indexation"; "Use Indexation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Used for Spreadsheet"; "Used for Spreadsheet")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Distribute by Periods"; "Distribute by Periods")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Include into Calculation by"; "Include into Calculation by")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fixed Amount Bonus"; "Fixed Amount Bonus")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Base"; "Income Tax Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("PF Base"; "PF Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FSI Base"; "FSI Base")
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
                field("FSI Injury Base"; "FSI Injury Base")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                }
                field("Amount Mandatory"; "Amount Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Quantity Mandatory"; "Quantity Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Advance Payment"; "Advance Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if advance payments made by the employee are included.';
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
                separator(Action1210000)
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
                action(Action21)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculation';
                    Image = CalculatePlan;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Payroll Calculations";
                    RunPageLink = "Element Code" = FIELD(Code);
                }
                action("Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Amount';
                    Image = FilterLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Payroll Base Amounts";
                    RunPageLink = "Element Code" = FIELD(Code);
                    RunPageView = SORTING("Element Code", Code);
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
            action(Copy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy';
                Ellipsis = true;
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CopyPayrollElement.SetPayrollElement(Rec);
                    CopyPayrollElement.Run;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PayTypeVisible := (Type = 2) or (Type = 3);
    end;

    var
        CopyPayrollElement: Report "Copy Payroll Element";
        [InDataSet]
        PayTypeVisible: Boolean;
}

