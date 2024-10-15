#if not CLEAN19
page 104 "Account Schedule"
{
    AutoSplitKey = true;
    Caption = 'Account Schedule';
    DataCaptionFields = "Schedule Name";
    MultipleNewLines = true;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Insert';
    SourceTable = "Acc. Schedule Line";

    layout
    {
        area(content)
        {
            field(CurrentSchedName; CurrentSchedName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the account schedule.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    exit(AccSchedManagement.LookupName(CurrentSchedName, Text));
                end;

                trigger OnValidate()
                begin
                    AccSchedManagement.CheckName(CurrentSchedName);
                    CurrentSchedNameOnAfterValidate;
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = Indentation;
                IndentationControls = Description;
                ShowCaption = false;
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
#if not CLEAN17
                field("Row Correction"; "Row Correction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row number for the correction code.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AccSchedLine: Record "Acc. Schedule Line";
                    begin
                        // NAVCZ
                        Clear(AccSchedLine);
                        AccSchedLine.SetRange("Schedule Name", "Schedule Name");
                        AccSchedLine.SetFilter("Row No.", '<>%1', "Row No.");

                        if PAGE.RunModal(PAGE::"Acc. Schedule Line List", AccSchedLine) = ACTION::LookupOK then
                            "Row Correction" := AccSchedLine."Row No.";
                        // NAVCZ
                    end;
                }
#endif
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = Bold;
                    ToolTip = 'Specifies text that will appear on the account schedule line.';
                }
                field("Totaling Type"; "Totaling Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the totaling type for the account schedule line. The type determines which accounts within the totaling interval you specify in the Totaling field will be totaled. ';
                }
                field("Source Table"; "Source Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the selected source table (VAT entry, Value entry, Customer or vendor entry).';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field(Totaling; Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccList: Page "G/L Account List";
                        AccSchedExtensions: Page "Acc. Schedule Extensions";
                        AccSchedExtension: Record "Acc. Schedule Extension";
                    begin
                        // NAVCZ
                        if "Totaling Type" in ["Totaling Type"::"Posting Accounts", "Totaling Type"::"Total Accounts"] then begin
                            GLAccList.LookupMode(true);
                            if not (GLAccList.RunModal = ACTION::LookupOK) then
                                exit(false);

                            Text := GLAccList.GetSelectionFilter;
                            exit(true);
                        end;

                        if "Totaling Type" = "Totaling Type"::Custom then begin
                            if Totaling <> '' then begin
                                AccSchedExtension.SetFilter(Code, Totaling);
                                AccSchedExtension.FindFirst;
                                AccSchedExtensions.SetRecord(AccSchedExtension);
                            end;
                            AccSchedExtensions.SetLedgType("Source Table" - 1);
                            AccSchedExtensions.LookupMode(true);
                            if not (AccSchedExtensions.RunModal = ACTION::LookupOK) then
                                exit(false);

                            AccSchedExtensions.GetRecord(AccSchedExtension);
                            Text := AccSchedExtension.Code;
                            exit(true);
                        end;

                        exit(false);
                        // NAVCZ
                    end;
                }
                field("Row Type"; "Row Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row type for the account schedule row. The type determines how the amounts in the row are calculated.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of entries that will be included in the amounts in the account schedule row.';
                }
                field("Show Opposite Sign"; "Show Opposite Sign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to show debits in reports as negative amounts with a minus sign and credits as positive amounts.';
                }
                field("Dimension 1 Totaling"; "Dimension 1 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(1, Text));
                    end;
                }
                field("Dimension 2 Totaling"; "Dimension 2 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(2, Text));
                    end;
                }
                field("Dimension 3 Totaling"; "Dimension 3 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(3, Text));
                    end;
                }
                field("Dimension 4 Totaling"; "Dimension 4 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(4, Text));
                    end;
                }
                field(Show; Show)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the account schedule line will be printed on the report.';
                }
#if not CLEAN17
                field(Calc; Calc)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the value can be calculated in the Account Schedule - always, never, when Positive, when Negative';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
#endif
                field(Bold; Bold)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to print the amounts in this row in bold.';
                }
                field(Italic; Italic)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to print the amounts in this row in italics.';
                }
                field(Underline; Underline)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to underline the amounts in this row.';
                }
                field("Double Underline"; "Double Underline")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to double underline the amounts in this row.';
                    Visible = false;
                }
                field("New Page"; "New Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether there will be a page break after the current account when the account schedule is printed.';
                }
#if not CLEAN17
                field("Assets/Liabilities Type"; "Assets/Liabilities Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the asset or liabilities type for the account schedule line.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                }
#endif
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Overview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Overview';
                Ellipsis = true;
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View an overview of the current account schedule.';

                trigger OnAction()
                var
                    AccSchedOverview: Page "Acc. Schedule Overview";
                begin
                    AccSchedOverview.SetAccSchedName(CurrentSchedName);
                    AccSchedOverview.Run;
                end;
            }
        }
        area(processing)
        {
            action(Indent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Indent';
                Image = Indent;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Make this row part of a group of rows. For example, indent rows that itemize a range of accounts, such as types of revenue.';

                trigger OnAction()
                var
                    AccScheduleLine: Record "Acc. Schedule Line";
                begin
                    CurrPage.SetSelectionFilter(AccScheduleLine);
                    if AccScheduleLine.FindSet then
                        repeat
                            AccScheduleLine.Indent;
                            AccScheduleLine.Modify();
                        until AccScheduleLine.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(Outdent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Outdent';
                Image = DecreaseIndent;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Move this row out one level.';

                trigger OnAction()
                var
                    AccScheduleLine: Record "Acc. Schedule Line";
                begin
                    CurrPage.SetSelectionFilter(AccScheduleLine);
                    if AccScheduleLine.FindSet then
                        repeat
                            AccScheduleLine.Outdent;
                            AccScheduleLine.Modify();
                        until AccScheduleLine.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(InsertGLAccounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert G/L Accounts';
                    Ellipsis = true;
                    Image = InsertAccount;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Open the list of general ledger accounts so you can add accounts to the account schedule.';

                    trigger OnAction()
                    var
                        AccSchedLine: Record "Acc. Schedule Line";
                    begin
                        CurrPage.Update(true);
                        SetupAccSchedLine(AccSchedLine);
                        AccSchedManagement.InsertGLAccounts(AccSchedLine);
                    end;
                }
                action(InsertCFAccounts)
                {
                    ApplicationArea = Suite;
                    Caption = 'Insert CF Accounts';
                    Ellipsis = true;
                    Image = InsertAccount;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Mark the cash flow accounts from the chart of cash flow accounts and copy them to account schedule lines.';

                    trigger OnAction()
                    var
                        AccSchedLine: Record "Acc. Schedule Line";
                    begin
                        CurrPage.Update(true);
                        SetupAccSchedLine(AccSchedLine);
                        AccSchedManagement.InsertCFAccounts(AccSchedLine);
                    end;
                }
                action(InsertCostTypes)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Insert Cost Types';
                    Ellipsis = true;
                    Image = InsertAccount;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Insert cost types to analyze what the costs are, where the costs come from, and who should bear the costs.';

                    trigger OnAction()
                    var
                        AccSchedLine: Record "Acc. Schedule Line";
                    begin
                        CurrPage.Update(true);
                        SetupAccSchedLine(AccSchedLine);
                        AccSchedManagement.InsertCostTypes(AccSchedLine);
                    end;
                }
                action(EditColumnLayoutSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit Column Layout Setup';
                    Ellipsis = true;
                    Image = SetupColumns;
                    RunObject = Page "Column Layout";
                    ToolTip = 'Create or change the column layout for the current account schedule name.';
                }
            }
            group("O&ther")
            {
                Caption = 'O&ther';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '19.0';
                action("Set up Custom Functions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set up Custom Functions (Obsolete)';
                    Ellipsis = true;
                    Image = NewSum;
                    RunObject = Page "Acc. Schedule Extensions";
                    ToolTip = 'Specifies acc. schedule extensions page';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
#if not CLEAN17
                action("File Mapping")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'File Mapping';
                    Image = ExportToExcel;
                    ToolTip = 'File Mapping allows to set up export to Excel. You can see three dots next to the field with Amount.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;

                    trigger OnAction()
                    var
                        AccSchedFileMapping: Page "Acc. Schedule File Mapping";
                    begin
                        // NAVCZ
                        AccSchedFileMapping.SetAccSchedName("Schedule Name");
                        AccSchedFileMapping.RunModal;
                        // NAVCZ
                    end;
                }
#endif
            }
            group("&Results")
            {
                Caption = '&Results (Obsolete)';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '19.0';
                Visible = false;
                action("Save &Results")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Save &Results (Obsolete)';
                    Ellipsis = true;
                    Image = Save;
                    ToolTip = 'Opens window for saving results of acc. schedule';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;

                    trigger OnAction()
                    begin
                        AccSchedManagement.CreateResults("Schedule Name", '', '', false);
                    end;
                }
                action(Results)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Results (Obsolete)';
                    Image = ViewDetails;
                    RunObject = Page "Acc. Schedule Res. Header List";
                    RunPageLink = "Acc. Schedule Name" = FIELD("Schedule Name");
                    ToolTip = 'Opens acc. schedule res. header list';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    AccScheduleName: Record "Acc. Schedule Name";
                begin
                    AccScheduleName.Get("Schedule Name");
                    AccScheduleName.Print;
                end;
            }
#if not CLEAN17
            action("Balance Sheet")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance Sheet';
                Image = PrintReport;
                RunObject = Report "Balance Sheet";
                ToolTip = 'Open the report for balance sheet.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '17.0';
                Visible = false;
            }
            action("Income Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Income Statement';
                Image = PrintReport;
                RunObject = Report "Income Statement";
                ToolTip = 'Allows the print of account schedule.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '17.0';
                Visible = false;
            }
#endif
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not DimCaptionsInitialized then
            DimCaptionsInitialized := true;
    end;

    trigger OnOpenPage()
    var
        OriginalSchedName: Code[10];
    begin
        OriginalSchedName := CurrentSchedName;
        AccSchedManagement.OpenAndCheckSchedule(CurrentSchedName, Rec);
        if CurrentSchedName <> OriginalSchedName then
            CurrentSchedNameOnAfterValidate;
    end;

    var
        AccSchedManagement: Codeunit AccSchedManagement;
        CurrentSchedName: Code[10];
        DimCaptionsInitialized: Boolean;

    procedure SetAccSchedName(NewAccSchedName: Code[10])
    begin
        CurrentSchedName := NewAccSchedName;
    end;

    local procedure CurrentSchedNameOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        AccSchedManagement.SetName(CurrentSchedName, Rec);
        CurrPage.Update(false);
    end;

    procedure SetupAccSchedLine(var AccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine := Rec;
        if "Line No." = 0 then begin
            AccSchedLine := xRec;
            AccSchedLine.SetRange("Schedule Name", CurrentSchedName);
            if AccSchedLine.Next() = 0 then
                AccSchedLine."Line No." := xRec."Line No." + 10000
            else begin
                if AccSchedLine.FindLast then
                    AccSchedLine."Line No." += 10000;
                AccSchedLine.SetRange("Schedule Name");
            end;
        end;
    end;

    procedure GetAccSchedName(): Code[10]
    begin
        exit(CurrentSchedName);
    end;
}

#endif