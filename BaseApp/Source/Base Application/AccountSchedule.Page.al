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
                field("Extension Source Table"; "Extension Source Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the extension source table associated with account schedule line.';
                }
                field(Totaling; TotalingDisplayed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Totaling';
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';
                    Lookup = true;

                    trigger OnValidate()
                    begin
                        if Rec."Totaling Type" = Rec."Totaling Type"::"Account Category" then
                            TotalingDisplayed := GetAccountCategoryTotalingToDisplay()
                        else
                            Rec.Validate(Totaling, TotalingDisplayed);
                    end;

                    trigger OnLookup(var Text: Text): boolean
                    var
                        AccScheduleLine: Record "Acc. Schedule Line";
                        GLSetup: Record "General Ledger Setup";
                        AccScheduleExtension: Record "Acc. Schedule Extension";
                        GLAccList: Page "G/L Account List";
                        CFAccList: Page "Cash Flow Account List";
                        AccScheduleLines: Page "Acc. Schedule Lines";
                        AccScheduleExtensions: Page "Acc. Schedule Extensions";
                    begin
                        if "Totaling Type" in
                           ["Totaling Type"::"Posting Accounts", "Totaling Type"::"Total Accounts"]
                        then begin
                            GLAccList.LookupMode(true);
                            if not (GLAccList.RunModal = ACTION::LookupOK) then
                                exit(false);

                            Text := GLAccList.GetSelectionFilter;
                            TotalingDisplayed := CopyStr(Text, 1, 250);
                            Rec.Validate(Totaling, TotalingDisplayed);
                        end;

                        case "Totaling Type" of
                            "Totaling Type"::Formula:
                                begin
                                    GLSetup.Get();
                                    if GLSetup."Shared Account Schedule" <> '' then begin
                                        AccScheduleLines.LookupMode := true;
                                        AccScheduleLine.FilterGroup(2);
                                        AccScheduleLine.SetRange("Schedule Name", GLSetup."Shared Account Schedule");
                                        AccScheduleLine.FilterGroup(0);
                                        AccScheduleLines.SetTableView(AccScheduleLine);
                                        if AccScheduleLines.RunModal = ACTION::LookupOK then begin
                                            AccScheduleLines.GetRecord(AccScheduleLine);
                                            Text := AccScheduleLine."Row No.";
                                            TotalingDisplayed := CopyStr(Text, 1, 250);
                                            Rec.Validate(Totaling, TotalingDisplayed);
                                            exit(true);
                                        end else
                                            exit(false)
                                    end;
                                end;

                            "Totaling Type"::Custom:
                                begin
                                    if "Extension Source Table" <> "Extension Source Table"::" " then begin
                                        if Totaling <> '' then begin
                                            AccScheduleExtension.Get(Totaling);
                                            AccScheduleExtensions.SetRecord(AccScheduleExtension);
                                        end;
                                        AccScheduleExtension.FilterGroup(2);
                                        AccScheduleExtension.SetRange(AccScheduleExtension."Source Table", "Extension Source Table" - 1);
                                        AccScheduleExtension.FilterGroup(0);
                                        AccScheduleExtensions.SetSourceTable("Extension Source Table");
                                        AccScheduleExtensions.SetTableView(AccScheduleExtension);
                                        AccScheduleExtensions.LookupMode(true);
                                        if not (AccScheduleExtensions.RunModal = ACTION::LookupOK) then
                                            exit(false)
                                        else begin
                                            AccScheduleExtensions.GetRecord(AccScheduleExtension);
                                            Text := AccScheduleExtension.Code;
                                            TotalingDisplayed := CopyStr(Text, 1, 250);
                                            Rec.Validate(Totaling, TotalingDisplayed);
                                            exit(true);
                                        end;
                                    end;
                                end;
                        end;

                        Rec.LookupTotaling();
                        if Rec."Totaling Type" = Rec."Totaling Type"::"Account Category" then
                            TotalingDisplayed := GetAccountCategoryTotalingToDisplay()
                        else
                            TotalingDisplayed := Rec.Totaling;

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
                field("Corr. Totaling"; "Corr. Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the corresponding total of the general ledger account associated with the account schedule line.';
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
                field("Dimension 1 Corr. Totaling"; "Dimension 1 Corr. Totaling")
                {
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(12401, Text));
                    end;
                }
                field("Dimension 2 Corr. Totaling"; "Dimension 2 Corr. Totaling")
                {
                    ToolTip = 'Specifies the dimension 2 corresponding totaling account associated with the account schedule line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(12402, Text));
                    end;
                }
                field(Show; Show)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the account schedule line will be printed on the report.';
                }
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
                field(HideCurrencySymbol; "Hide Currency Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to hide currency symbols when a calculated result is not a currency.';
                    Visible = false;
                }
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
                    AccSchedOverview.Run();
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
                    if AccScheduleLine.FindSet() then
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
                    if AccScheduleLine.FindSet() then
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
                separator(Action1210006)
                {
                }
                action("Export Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Settings';
                    Ellipsis = true;
                    Image = Export;

                    trigger OnAction()
                    begin
                        AccScheduleName.Get(CurrentSchedName);
                        AccScheduleName.SetRecFilter;
                        AccScheduleName.ExportSettings(AccScheduleName);
                    end;
                }
                action("I&mport Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'I&mport Settings';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import setup information.';

                    trigger OnAction()
                    begin
                        AccScheduleName.ImportSettings('');
                    end;
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
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not DimCaptionsInitialized then
            DimCaptionsInitialized := true;
        if Rec."Totaling Type" = Rec."Totaling Type"::"Account Category" then
            TotalingDisplayed := GetAccountCategoryTotalingToDisplay()
        else
            TotalingDisplayed := Rec.Totaling;
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
        AccScheduleName: Record "Acc. Schedule Name";
        AccSchedManagement: Codeunit AccSchedManagement;
        CurrentSchedName: Code[10];
        DimCaptionsInitialized: Boolean;
        TotalingDisplayed: Text[250];

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
                if AccSchedLine.FindLast() then
                    AccSchedLine."Line No." += 10000;
                AccSchedLine.SetRange("Schedule Name");
            end;
        end;
    end;

    procedure GetAccountCategoryTotalingToDisplay(): Text[250]
    begin
        exit(AccSchedManagement.GLAccCategoryText(Rec));
    end;

    procedure GetAccSchedName(): Code[10]
    begin
        exit(CurrentSchedName);
    end;
}

