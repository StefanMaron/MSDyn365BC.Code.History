page 14965 "Payroll Analysis Report"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Analysis Reports';
    DataCaptionExpression = GetCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Payroll Analysis Line";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentReportName; CurrentReportName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis Report Name';
                    ToolTip = 'Specifies the name of the analysis report.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if PayrollAnalysisReportMgt.LookupReportName(CurrentReportName) then begin
                            Text := CurrentReportName;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        PayrollAnalysisReportMgt.CheckReportName(CurrentReportName);
                        CurrentReportNameOnAfterValida;
                    end;
                }
                field(CurrentLineTemplate; CurrentLineTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis Line Template';
                    ToolTip = 'Specifies the line template that is used for the analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord;
                        PayrollAnalysisReportMgt.LookupAnalysisLineTemplName(CurrentLineTemplate, Rec);
                        ValidateAnalysisTemplateName;
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        PayrollAnalysisReportMgt.CheckAnalysisLineTemplName(CurrentLineTemplate, Rec);
                        CurrentLineTemplateOnAfterVali;
                    end;
                }
                field(CurrentColumnTemplate; CurrentColumnTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis Column Template';
                    ToolTip = 'Specifies the column template that is used for the analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if PayrollAnalysisReportMgt.LookupColumnName(CurrentColumnTemplate) then begin
                            Text := CurrentColumnTemplate;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        PayrollAnalysisReportMgt.GetColumnTemplate(CurrentColumnTemplate);
                        CurrentColumnTemplateOnAfterVa;
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(ShowError; ShowError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Error';
                    OptionCaption = 'None,Division by Zero,Period Error,Invalid Formula,Cyclic Formula,All';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
                field(ColumnsSet; ColumnsSet)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Set';
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Actions")
            {
                Caption = '&Actions';
                Image = "Action";
                action("Set Up &Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Up &Lines';
                    Ellipsis = true;
                    Image = SetupLines;

                    trigger OnAction()
                    begin
                        PayrollAnalysisReportMgt.OpenAnalysisLinesForm(Rec, CurrentLineTemplate);
                        CurrPage.Update(false);
                    end;
                }
                action("Set Up &Columns")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Up &Columns';
                    Ellipsis = true;
                    Image = SetupColumns;

                    trigger OnAction()
                    begin
                        PayrollAnalysisReportMgt.OpenAnalysisColumnsForm(Rec, CurrentColumnTemplate);
                        CurrPage.Update(false);
                    end;
                }
                separator(Action19)
                {
                }
                action("Export to Excel")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Excel';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    ToolTip = 'Export the data to Excel.';

                    trigger OnAction()
                    var
                        ExportPayrAnRepToExcel: Report "Export Payr. An. Rep. to Excel";
                    begin
                        ExportPayrAnRepToExcel.SetOptions(Rec, CurrentColumnTemplate, CurrentLineTemplate);
                        ExportPayrAnRepToExcel.Run;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Show Matrix")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    SetFilters;
                    Clear(MatrixColumnCaptions);
                    FillMatrixColumns;
                    Clear(PayrollAnalysisMatrix);
                    PayrollAnalysisMatrix.Load(PayrollAnalysisColumn, MatrixColumnCaptions, ShowError, FirstLineNo, LastLineNo);
                    PayrollAnalysisMatrix.SetTableView(PayrollAnalysisLine);
                    PayrollAnalysisMatrix.RunModal;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Previous Set';

                trigger OnAction()
                begin
                    Direction := Direction::Backward;
                    SetPointsAnalysisColumn;
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Next Set';

                trigger OnAction()
                begin
                    Direction := Direction::Forward;
                    SetPointsAnalysisColumn;
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
    begin
        if (NewCurrentReportName <> '') and (NewCurrentReportName <> CurrentReportName) then begin
            CurrentReportName := NewCurrentReportName;
            PayrollAnalysisReportMgt.CheckReportName(CurrentReportName);
            ValidateReportName;
            PayrollAnalysisReportMgt.SetAnalysisLineTemplName(CurrentLineTemplate, Rec);
            ValidateAnalysisTemplateName;
        end;

        PayrollAnalysisReportMgt.OpenAnalysisLines(CurrentLineTemplate, Rec);
        PayrollAnalysisReportMgt.OpenColumns(CurrentColumnTemplate, Rec, PayrollAnalysisColumn);

        PayrollAnalysisReportMgt.CopyColumnsToTemp(Rec, CurrentColumnTemplate, PayrollAnalysisColumn);

        GLSetup.Get;

        if PayrollAnalysisLineTemplate.Get(CurrentLineTemplate) then
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                PayrollAnalysisView.Get(PayrollAnalysisLineTemplate."Payroll Analysis View Code")
            else begin
                Clear(PayrollAnalysisView);
                PayrollAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                PayrollAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;

        FindPeriod('');

        NoOfColumns := 7;
        Direction := Direction::Forward;

        ClearPoints;
        SetPointsAnalysisColumn;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PayrollAnalysisColumn: Record "Payroll Analysis Column" temporary;
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
        PayrollAnalysisMatrix: Page "Payroll Analysis Matrix";
        CurrentReportName: Code[10];
        CurrentLineTemplate: Code[10];
        CurrentColumnTemplate: Code[10];
        NewCurrentReportName: Code[10];
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        ShowError: Option "None","Division by Zero","Period Error","Invalid Formula","Cyclic Formula",All;
        Text003: Label '1,6,,Dimension %1 Filter';
        Direction: Option Backward,Forward;
        NoOfColumns: Integer;
        FirstLineNo: Integer;
        LastLineNo: Integer;
        FirstColumn: Text[1024];
        LastColumn: Text[1024];
        MatrixColumnCaptions: array[32] of Text[1024];

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        if GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
            if not PeriodFormMgt.FindDate('+', Calendar, PeriodType) then
                PeriodFormMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodFormMgt.FindDate(SearchText, Calendar, PeriodType);
        SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
        if GetRangeMin("Date Filter") = GetRangeMax("Date Filter") then
            SetRange("Date Filter", GetRangeMin("Date Filter"));
    end;

    local procedure ValidateAnalysisTemplateName()
    var
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
        PrevPayrollAnalysisView: Record "Payroll Analysis View";
    begin
        if PayrollAnalysisLineTemplate.Get(CurrentLineTemplate) then
            if (PayrollAnalysisLineTemplate."Default Column Template Name" <> '') and
               (CurrentColumnTemplate <> PayrollAnalysisLineTemplate."Default Column Template Name")
            then begin
                CurrentColumnTemplate := PayrollAnalysisLineTemplate."Default Column Template Name";
                PayrollAnalysisReportMgt.OpenColumns(CurrentColumnTemplate, Rec, PayrollAnalysisColumn);
                PayrollAnalysisReportMgt.CopyColumnsToTemp(Rec, CurrentColumnTemplate, PayrollAnalysisColumn);
            end;

        if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> PayrollAnalysisView.Code then begin
            PrevPayrollAnalysisView := PayrollAnalysisView;
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                PayrollAnalysisView.Get(PayrollAnalysisLineTemplate."Payroll Analysis View Code")
            else begin
                Clear(PayrollAnalysisView);
                PayrollAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                PayrollAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
            if PrevPayrollAnalysisView."Dimension 1 Code" <> PayrollAnalysisView."Dimension 1 Code" then
                SetRange("Dimension 1 Filter");
            if PrevPayrollAnalysisView."Dimension 2 Code" <> PayrollAnalysisView."Dimension 2 Code" then
                SetRange("Dimension 2 Filter");
            if PrevPayrollAnalysisView."Dimension 3 Code" <> PayrollAnalysisView."Dimension 3 Code" then
                SetRange("Dimension 3 Filter");
        end;
    end;

    local procedure ValidateReportName()
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        if PayrollAnalysisReportName.Get(CurrentReportName) then begin
            if PayrollAnalysisReportName."Analysis Line Template Name" <> '' then
                CurrentLineTemplate := PayrollAnalysisReportName."Analysis Line Template Name";
            if PayrollAnalysisReportName."Analysis Column Template Name" <> '' then
                CurrentColumnTemplate := PayrollAnalysisReportName."Analysis Column Template Name";
        end;
    end;

    local procedure GetCaption(): Text[250]
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        if CurrentReportName <> '' then
            if PayrollAnalysisReportName.Get(CurrentReportName) then
                exit(PayrollAnalysisReportName.Name + ' ' + PayrollAnalysisReportName.Description);
    end;

    [Scope('OnPrem')]
    procedure SetFilters()
    begin
        PayrollAnalysisColumn.Reset;
        PayrollAnalysisColumn.SetRange("Analysis Column Template", CurrentColumnTemplate);

        PayrollAnalysisLine.Copy(Rec);
        PayrollAnalysisLine.SetRange("Analysis Line Template Name", CurrentLineTemplate);
    end;

    local procedure ColumnsSet(): Text[80]
    begin
        if FirstColumn = LastColumn then
            exit(FirstColumn);

        exit(FirstColumn + '..' + LastColumn);
    end;

    local procedure SetPointsAnalysisColumn()
    var
        PayrollAnalysisColumn2: Record "Payroll Analysis Column";
        tmpFirstColumn: Text[80];
        tmpLastColumn: Text[80];
        tmpFirstLineNo: Integer;
        tmpLastLineNo: Integer;
    begin
        PayrollAnalysisColumn2.SetRange("Analysis Column Template", CurrentColumnTemplate);

        if (Direction = Direction::Forward) or (FirstColumn = '') then
            if LastColumn = '' then begin
                PayrollAnalysisColumn2.FindFirst;
                tmpFirstColumn := PayrollAnalysisColumn2."Column Header";
                tmpFirstLineNo := PayrollAnalysisColumn2."Line No.";
                PayrollAnalysisColumn2.Next(NoOfColumns - 1);
                tmpLastColumn := PayrollAnalysisColumn2."Column Header";
                tmpLastLineNo := PayrollAnalysisColumn2."Line No.";
            end else begin
                if PayrollAnalysisColumn2.Get(CurrentColumnTemplate, LastLineNo) then;
                PayrollAnalysisColumn2.Next;
                tmpFirstColumn := PayrollAnalysisColumn2."Column Header";
                tmpFirstLineNo := PayrollAnalysisColumn2."Line No.";
                PayrollAnalysisColumn2.Next(NoOfColumns - 1);
                tmpLastColumn := PayrollAnalysisColumn2."Column Header";
                tmpLastLineNo := PayrollAnalysisColumn2."Line No.";
            end
        else begin
            if PayrollAnalysisColumn2.Get(CurrentColumnTemplate, FirstLineNo) then;
            PayrollAnalysisColumn2.Next(-1);
            tmpLastColumn := PayrollAnalysisColumn2."Column Header";
            tmpLastLineNo := PayrollAnalysisColumn2."Line No.";
            PayrollAnalysisColumn2.Next(-NoOfColumns + 1);
            tmpFirstColumn := PayrollAnalysisColumn2."Column Header";
            tmpFirstLineNo := PayrollAnalysisColumn2."Line No.";
        end;

        if (tmpFirstColumn = tmpLastColumn) and
           ((tmpLastColumn = LastColumn) or (tmpFirstColumn = FirstColumn)) then
            exit;

        FirstColumn := tmpFirstColumn;
        LastColumn := tmpLastColumn;
        FirstLineNo := tmpFirstLineNo;
        LastLineNo := tmpLastLineNo;
    end;

    local procedure FillMatrixColumns()
    var
        PayrollAnalysisColumn2: Record "Payroll Analysis Column";
        i: Integer;
    begin
        PayrollAnalysisColumn2.SetRange("Analysis Column Template", CurrentColumnTemplate);
        PayrollAnalysisColumn2.SetRange("Line No.", FirstLineNo, LastLineNo);
        i := 1;

        if PayrollAnalysisColumn2.FindSet then
            repeat
                MatrixColumnCaptions[i] := PayrollAnalysisColumn2."Column Header";
                i := i + 1;
            until (PayrollAnalysisColumn2.Next = 0) or (i > ArrayLen(MatrixColumnCaptions));
    end;

    [Scope('OnPrem')]
    procedure ClearPoints()
    begin
        Clear(FirstColumn);
        Clear(LastColumn);
    end;

    [Scope('OnPrem')]
    procedure SetReportName(NewReportName: Code[10])
    begin
        NewCurrentReportName := NewReportName;
    end;

    local procedure CurrentReportNameOnAfterValida()
    begin
        CurrPage.SaveRecord;
        ValidateReportName;
        PayrollAnalysisReportMgt.SetAnalysisLineTemplName(CurrentLineTemplate, Rec);
        ValidateAnalysisTemplateName;
        PayrollAnalysisReportMgt.CopyColumnsToTemp(Rec, CurrentColumnTemplate, PayrollAnalysisColumn);
        CurrPage.Update(false);
        ClearPoints;
        SetPointsAnalysisColumn;
    end;

    local procedure CurrentLineTemplateOnAfterVali()
    begin
        CurrPage.SaveRecord;
        PayrollAnalysisReportMgt.SetAnalysisLineTemplName(CurrentLineTemplate, Rec);
        ValidateAnalysisTemplateName;
        CurrPage.Update(false);
    end;

    local procedure CurrentColumnTemplateOnAfterVa()
    begin
        PayrollAnalysisReportMgt.CopyColumnsToTemp(Rec, CurrentColumnTemplate, PayrollAnalysisColumn);
        CurrPage.Update(false);
        ClearPoints;
        SetPointsAnalysisColumn;
    end;
}

