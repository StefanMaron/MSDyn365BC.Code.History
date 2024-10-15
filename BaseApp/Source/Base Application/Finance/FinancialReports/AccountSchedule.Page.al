namespace Microsoft.Finance.FinancialReports;

using Microsoft.CostAccounting.Account;

page 104 "Account Schedule"
{
    AutoSplitKey = true;
    Caption = 'Row Definition';
    DataCaptionFields = "Schedule Name";
    MultipleNewLines = true;
    PageType = Worksheet;
    SourceTable = "Acc. Schedule Line";
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            field(CurrentSchedName; CurrentSchedName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the row definition.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    exit(AccSchedManagement.LookupName(CurrentSchedName, Text));
                end;

                trigger OnValidate()
                begin
                    AccSchedManagement.CheckName(CurrentSchedName);
                    CurrentSchedNameOnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Description;
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = Rec.Bold;
                    ToolTip = 'Specifies text that will appear on the financial report line.';
                }
                field("Totaling Type"; Rec."Totaling Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the totaling type for the financial report line. The type determines which accounts within the totaling interval you specify in the Totaling field will be totaled. ';
                    trigger OnValidate()
                    begin
                        if Rec."Totaling Type" in [Rec."Totaling Type"::"Cost Type", Rec."Totaling Type"::"Cost Type Total"] then begin
                            CostObjectTotallingEnabled := true;
                            CostCenterTotallingEnabled := true;
                        end else begin
                            CostObjectTotallingEnabled := false;
                            CostCenterTotallingEnabled := false;
                        end;
                    end;
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

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupTotaling();
                        if Rec."Totaling Type" = Rec."Totaling Type"::"Account Category" then
                            TotalingDisplayed := GetAccountCategoryTotalingToDisplay()
                        else
                            TotalingDisplayed := Rec.Totaling;
                    end;

                }
                field("Row Type"; Rec."Row Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row type for the row definition. The type determines how the amounts in the row are calculated.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of entries that will be included in the amounts in the row definition.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of entry associated with the account schedule.';
                }
                field("Positive Only"; Rec."Positive Only")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the amounts on the line of the table must be printed only if positive.';
                }
                field("Reverse Sign"; Rec."Reverse Sign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to change the sign of the calculated amounts in the Account Schedule.';
                }
                field("Show Opposite Sign"; Rec."Show Opposite Sign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to show debits in reports as negative amounts with a minus sign and credits as positive amounts.';
                }
                field("Dimension 1 Totaling"; Rec."Dimension 1 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(1, Text));
                    end;
                }
                field("Dimension 2 Totaling"; Rec."Dimension 2 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(2, Text));
                    end;
                }
                field("Dimension 3 Totaling"; Rec."Dimension 3 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(3, Text));
                    end;
                }
                field("Dimension 4 Totaling"; Rec."Dimension 4 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled on this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(4, Text));
                    end;
                }
                field("Cost Center Totaling"; Rec."Cost Center Totaling")
                {
                    ApplicationArea = CostAccounting;
                    Enabled = CostCenterTotallingEnabled;
                    ToolTip = 'Specifies which cost center amounts will be totaled in this column.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostCenter: Record "Cost Center";
                    begin
                        exit(CostCenter.LookupCostCenterFilter(Text));
                    end;
                }
                field("Cost Object Totaling"; Rec."Cost Object Totaling")
                {
                    ApplicationArea = CostAccounting;
                    Enabled = CostObjectTotallingEnabled;
                    ToolTip = 'Specifies which cost object amounts will be totaled in this column.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostObject: Record "Cost Object";
                    begin
                        exit(CostObject.LookupCostObjectFilter(Text));
                    end;
                }
                field(Show; Rec.Show)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the account schedule line will be printed on the report.';
                }
                field(Bold; Rec.Bold)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to print the amounts in this row in bold.';
                }
                field(Italic; Rec.Italic)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to print the amounts in this row in italics.';
                }
                field(Underline; Rec.Underline)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to underline the amounts in this row.';
                }
                field("Double Underline"; Rec."Double Underline")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to double underline the amounts in this row.';
                    Visible = false;
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether there will be a page break after the current account when the account schedule is printed.';
                }
                field(HideCurrencySymbol; Rec."Hide Currency Symbol")
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
#if not CLEAN22
        area(navigation)
        {
            action(Overview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Report';
                Ellipsis = true;
                Image = ViewDetails;
                ToolTip = 'View an overview of the current account schedule.';
                Visible = false;
                ObsoleteReason = 'This page is now opened from Financial Reports Page instead (Overview action).';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';

                trigger OnAction()
                var
                    AccSchedOverview: Page "Acc. Schedule Overview";
                begin
                    AccSchedOverview.SetAccSchedName(CurrentSchedName);
                    AccSchedOverview.Run();
                end;
            }
        }
#endif
        area(processing)
        {
            action(Indent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Indent';
                Image = Indent;
                Scope = Repeater;
                ToolTip = 'Make this row part of a group of rows. For example, indent rows that itemize a range of accounts, such as types of revenue.';

                trigger OnAction()
                var
                    AccScheduleLine: Record "Acc. Schedule Line";
                begin
                    CurrPage.SetSelectionFilter(AccScheduleLine);
                    if AccScheduleLine.FindSet() then
                        repeat
                            AccScheduleLine.Indent();
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
                Scope = Repeater;
                ToolTip = 'Move this row out one level.';

                trigger OnAction()
                var
                    AccScheduleLine: Record "Acc. Schedule Line";
                begin
                    CurrPage.SetSelectionFilter(AccScheduleLine);
                    if AccScheduleLine.FindSet() then
                        repeat
                            AccScheduleLine.Outdent();
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
                    ToolTip = 'Open the list of general ledger accounts so you can add accounts to the row definition.';

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
                    ToolTip = 'Mark the cash flow accounts from the chart of cash flow accounts and copy them to row definition lines.';

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
#if not CLEAN22
                action(EditColumnLayoutSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit Column Layout Setup';
                    Ellipsis = true;
                    Image = SetupColumns;
                    RunObject = Page "Column Layout";
                    ToolTip = 'Create or change the column layout for the current account schedule name.';
                    Visible = false;
                    ObsoleteReason = 'Relation to columns on a financial report are now stored on "Financial Report". This control is now replaced by the one on page Financial Reports, action EditColumnGroup.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';
                }
#endif
                separator(Action1100002)
                {
                }
                action("Export Schedules to ASC format")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Schedules to ASC format';
                    Image = ExportElectronicDocument;
                    RunObject = Report "Export Schedules to ASC format";
                    ToolTip = 'Export the account schedule data to a digital file format approved by the local tax authorities for the following annual reports: Balance de Situación Abreviado, Balance de Situación Normal, Cuenta de PyG Abreviado, Cuenta de PyG Normal.';
                }
            }
        }
#if not CLEAN22
        area(reporting)
        {
            action(Print)
            {
                ObsoleteReason = 'AccScheduleName is no longer printable directly as they are only row definitions, print instead related Financial Report by calling directly the Account Schedule Report with SetFinancialReportName or SetFinancialReportNameNonEditable.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';
                Visible = false;
                trigger OnAction()
                var
                    AccScheduleName: Record "Acc. Schedule Name";
                begin
                    AccScheduleName.Get(Rec."Schedule Name");
                    AccScheduleName.Print();
                end;
            }
        }
#endif
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

#if not CLEAN22
                actionref(Overview_Promoted; Overview)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This page is now opened from Financial Reports Page instead (Overview action).';
                    ObsoleteTag = '22.0';
                }
#endif
#if not CLEAN22
                actionref(Print_Promoted; Print)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'AccScheduleName is no longer printable directly as they are only row definitions, print instead related Financial Report by calling directly the Account Schedule Report with SetFinancialReportName or SetFinancialReportNameNonEditable.';
                    ObsoleteTag = '22.0';
                }
#endif
                actionref(Outdent_Promoted; Outdent)
                {
                }
                actionref(Indent_Promoted; Indent)
                {
                }
#if not CLEAN22
                actionref(EditColumnLayoutSetup_Promoted; EditColumnLayoutSetup)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Relation to columns on a financial report are now stored on "Financial Report". This control is now replaced by the one on page Financial Reports, action EditColumnGroup.';
                    ObsoleteTag = '22.0';
                }
#endif
            }
            group(Category_Category4)
            {
                Caption = 'Insert', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(InsertGLAccounts_Promoted; InsertGLAccounts)
                {
                }
                actionref(InsertCostTypes_Promoted; InsertCostTypes)
                {
                }
                actionref(InsertCFAccounts_Promoted; InsertCFAccounts)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FormatLines();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        FormatLines();
    end;

    trigger OnOpenPage()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        OriginalSchedName: Code[10];
    begin
        FinancialReportMgt.LaunchEditRowsWarningNotification();
        OriginalSchedName := CurrentSchedName;
        AccSchedManagement.OpenAndCheckSchedule(CurrentSchedName, Rec);
        if CurrentSchedName <> OriginalSchedName then
            CurrentSchedNameOnAfterValidate();
    end;

    var
        AccSchedManagement: Codeunit AccSchedManagement;
        CurrentSchedName: Code[10];
        DimCaptionsInitialized: Boolean;
        CostObjectTotallingEnabled: Boolean;
        CostCenterTotallingEnabled: Boolean;
        TotalingDisplayed: Text[250];

    procedure SetAccSchedName(NewAccSchedName: Code[10])
    begin
        CurrentSchedName := NewAccSchedName;
    end;

    local procedure CurrentSchedNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        AccSchedManagement.SetName(CurrentSchedName, Rec);
        CurrPage.Update(false);
    end;

    local procedure FormatLines()
    begin
        if not DimCaptionsInitialized then
            DimCaptionsInitialized := true;

        if Rec."Totaling Type" in [Rec."Totaling Type"::"Cost Type", Rec."Totaling Type"::"Cost Type Total"] then begin
            CostObjectTotallingEnabled := true;
            CostCenterTotallingEnabled := true;
        end;

        if Rec."Totaling Type" = Rec."Totaling Type"::"Account Category" then
            TotalingDisplayed := GetAccountCategoryTotalingToDisplay()
        else
            TotalingDisplayed := Rec.Totaling;
    end;

    procedure SetupAccSchedLine(var AccSchedLine: Record "Acc. Schedule Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetupAccSchedLine(Rec, xRec, AccSchedLine, CurrentSchedName, IsHandled);
        if IsHandled then
            exit;

        AccSchedLine := Rec;
        if Rec."Line No." = 0 then begin
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupAccSchedLine(var RecAccScheduleLine: Record "Acc. Schedule Line"; var xRecAccScheduleLine: Record "Acc. Schedule Line"; var AccScheduleLine: Record "Acc. Schedule Line"; CurrentSchedName: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

