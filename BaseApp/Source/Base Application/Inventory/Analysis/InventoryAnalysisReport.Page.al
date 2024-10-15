﻿namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;

page 7119 "Inventory Analysis Report"
{
    Caption = 'Inventory Analysis Report';
    DataCaptionExpression = GetCaption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Analysis Line";
    SourceTableView = where("Analysis Area" = const(Inventory));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentReportName; CurrentReportName)
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Analysis Report Name';
                    ToolTip = 'Specifies the name of the analysis report.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrentAreaType := Rec.GetRangeMax("Analysis Area");
                        if AnalysisReportMgt.LookupAnalysisReportName(CurrentAreaType, CurrentReportName) then begin
                            Text := CurrentReportName;
                            CurrentReportNameOnAfterValidate();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        AnalysisReportMgt.CheckReportName(CurrentReportName, Rec);
                        CurrentReportNameOnAfterValidate();
                    end;
                }
                field(CurrentLineTemplate; CurrentLineTemplate)
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Analysis Line Template';
                    ToolTip = 'Specifies the line template that is used for the analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        AnalysisReportMgt.LookupAnalysisLineTemplName(CurrentLineTemplate, Rec);
                        ValidateAnalysisTemplateName();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        AnalysisReportMgt.CheckAnalysisLineTemplName(CurrentLineTemplate, Rec);
                        CurrentLineTemplateOnAfterValidate();
                    end;
                }
                field(CurrentColumnTemplate; CurrentColumnTemplate)
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Analysis Column Template';
                    ToolTip = 'Specifies the column template that is used for the analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrentAreaType := Rec.GetRangeMax("Analysis Area");
                        if AnalysisReportMgt.LookupAnalysisColumnName(CurrentAreaType, CurrentColumnTemplate) then begin
                            Text := CurrentColumnTemplate;
                            CurrentColumnTemplateOnAfterValidate();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        CurrentAreaType := Rec.GetRangeMax("Analysis Area");
                        AnalysisReportMgt.GetColumnTemplate(CurrentAreaType.AsInteger(), CurrentColumnTemplate);
                        CurrentColumnTemplateOnAfterValidate();
                    end;
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(CurrentSourceTypeFilter; CurrentSourceTypeFilter)
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Source Type Filter';
                    ToolTip = 'Specifies filters for what is shown in the analysis view.';

                    trigger OnValidate()
                    begin
                        Rec.SetRange("Source Type Filter", CurrentSourceTypeFilter);
                        CurrentSourceTypeNoFilter := '';
                        AnalysisReportMgt.SetSourceNo(Rec, CurrentSourceTypeNoFilter);
                        CurrentSourceTypeFilterOnAfterValidate();
                    end;
                }
                field(CurrentSourceTypeNoFilter; CurrentSourceTypeNoFilter)
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Source No. Filter';
                    ToolTip = 'Specifies filters for what is shown in the analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        AnalysisReportMgt.DoLookupSourceNo(Rec, CurrentSourceTypeFilter, CurrentSourceTypeNoFilter);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        CurrentSourceTypeNoFilterOnAfterValidate();
                    end;
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
                field(ColumnsSet; GetColumnsRangeFilter())
                {
                    ApplicationArea = InventoryAnalysis;
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
                action(SetUpLines)
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Set Up &Lines';
                    Ellipsis = true;
                    Image = SetupLines;
                    ToolTip = 'Open the list of analysis lines that exist for this type of analysis report, for example to set up new lines that you can select from.';

                    trigger OnAction()
                    begin
                        AnalysisReportMgt.OpenAnalysisLinesForm(Rec, CurrentLineTemplate);
                        CurrPage.Update(false);
                    end;
                }
                action("Set Up &Columns")
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Set Up &Columns';
                    Ellipsis = true;
                    Image = SetupColumns;
                    ToolTip = 'Open the list of analysis columns that exist for this type of analysis report, for example to set up new columns that you can select from.';

                    trigger OnAction()
                    begin
                        AnalysisReportMgt.OpenAnalysisColumnsForm(Rec, CurrentColumnTemplate);
                        CurrPage.Update(false);
                    end;
                }
                separator(Action20)
                {
                }
                group("Export to Excel")
                {
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    action("Create New Document")
                    {
                        ApplicationArea = InventoryAnalysis;
                        Caption = 'Create New Document';
                        Image = ExportToExcel;
                        ToolTip = 'Open the analysis report in a new Excel workbook. This creates an Excel workbook on your device.';

                        trigger OnAction()
                        var
                            ExportAnalysisRepToExcel: Report "Export Analysis Rep. to Excel";
                        begin
                            ExportAnalysisRepToExcel.SetOptions(Rec, CurrentColumnTemplate, CurrentLineTemplate);
                            ExportAnalysisRepToExcel.Run();
                        end;
                    }
                    action("Update Existing Document")
                    {
                        ApplicationArea = InventoryAnalysis;
                        Caption = 'Update Existing Document';
                        Image = ExportToExcel;
                        ToolTip = 'Refresh the analysis report in an existing Excel workbook. You must specify the workbook that you want to update.';

                        trigger OnAction()
                        var
                            ExportAnalysisRepToExcel: Report "Export Analysis Rep. to Excel";
                        begin
                            ExportAnalysisRepToExcel.SetOptions(Rec, CurrentColumnTemplate, CurrentLineTemplate);
                            ExportAnalysisRepToExcel.SetUpdateExistingWorksheet(true);
                            ExportAnalysisRepToExcel.Run();
                        end;
                    }
                }
            }
            group("&Reports")
            {
                Caption = '&Reports';
                Image = "Report";
                action(Print)
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Print';
                    Image = Print;
                    ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        AnalysisReport: Report "Analysis Report";
                        DateFilter: Text[30];
                        ItemBudgetFilter: Text[30];
                        LocationFilter: Text[30];
                        Dim1Filter: Text[250];
                        Dim2Filter: Text[250];
                        Dim3Filter: Text[250];
                    begin
                        CurrentAreaType := Rec.GetRangeMax("Analysis Area");
                        AnalysisReport.SetParameters(CurrentAreaType, CurrentReportName, CurrentLineTemplate, CurrentColumnTemplate);
                        DateFilter := Rec.GetFilter("Date Filter");
                        ItemBudgetFilter := Rec.GetFilter("Item Budget Filter");
                        LocationFilter := Rec.GetFilter("Location Filter");
                        Dim1Filter := Rec.GetFilter("Dimension 1 Filter");
                        Dim2Filter := Rec.GetFilter("Dimension 2 Filter");
                        Dim3Filter := Rec.GetFilter("Dimension 3 Filter");
                        AnalysisReport.SetFilters(
                          DateFilter, ItemBudgetFilter, LocationFilter, Dim1Filter, Dim2Filter, Dim3Filter,
                          CurrentSourceTypeFilter.AsInteger(), CurrentSourceTypeNoFilter);
                        AnalysisReport.Run();
                    end;
                }
            }
        }
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = InventoryAnalysis;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the actual analysis report according to the selected filters and options.';

                trigger OnAction()
                begin
                    SetFilters();

                    Clear(MatrixColumnCaptions);

                    FillMatrixColumns();

                    Clear(InvtAnalysisMatrix);
                    InvtAnalysisMatrix.Load(TempAnalysisColumn, MatrixColumnCaptions, FirstLineNo, LastLineNo);
                    InvtAnalysisMatrix.SetTableView(AnalysisLine);
                    InvtAnalysisMatrix.Run();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = InventoryAnalysis;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    Direction := Direction::Backward;
                    SetPointsAnalysisColumn();
                end;
            }
            action("Next Set")
            {
                ApplicationArea = InventoryAnalysis;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    Direction := Direction::Forward;
                    SetPointsAnalysisColumn();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowMatrix_Promoted; ShowMatrix)
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        if (NewCurrentReportName <> '') and (NewCurrentReportName <> CurrentReportName) then begin
            CurrentReportName := NewCurrentReportName;
            AnalysisReportMgt.CheckReportName(CurrentReportName, Rec);
            ValidateReportName();
            AnalysisReportMgt.SetAnalysisLineTemplName(CurrentLineTemplate, Rec);
            ValidateAnalysisTemplateName();
        end;

        AnalysisReportMgt.OpenAnalysisLines(CurrentLineTemplate, Rec);
        AnalysisReportMgt.OpenColumns(CurrentColumnTemplate, Rec, TempAnalysisColumn);

        AnalysisReportMgt.CopyColumnsToTemp(Rec, CurrentColumnTemplate, TempAnalysisColumn);
        AnalysisReportMgt.SetSourceType(Rec, CurrentSourceTypeFilter.AsInteger());
        AnalysisReportMgt.SetSourceNo(Rec, CurrentSourceTypeNoFilter);

        GLSetup.Get();

        if AnalysisLineTemplate.Get(Rec.GetRangeMax("Analysis Area"), CurrentLineTemplate) then
            if AnalysisLineTemplate."Item Analysis View Code" <> '' then
                ItemAnalysisView.Get(Rec.GetRangeMax("Analysis Area"), AnalysisLineTemplate."Item Analysis View Code")
            else begin
                Clear(ItemAnalysisView);
                ItemAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                ItemAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;

        FindPeriod('');

        NoOfColumns := InvtAnalysisMatrix.GetMatrixDimension();
        Direction := Direction::Forward;

        ClearPoints();
        SetPointsAnalysisColumn();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TempAnalysisColumn: Record "Analysis Column" temporary;
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisLine: Record "Analysis Line";
        AnalysisReportMgt: Codeunit "Analysis Report Management";
        InvtAnalysisMatrix: Page "Inventory Analysis Matrix";
        NewCurrentReportName: Code[10];
        CurrentAreaType: Enum "Analysis Area Type";
        CurrentSourceTypeNoFilter: Text;
        CurrentSourceTypeFilter: Enum "Analysis Source Type";
        PeriodType: Enum "Analysis Period Type";
        Direction: Option Backward,Forward;
        NoOfColumns: Integer;
        FirstLineNo: Integer;
        LastLineNo: Integer;
        FirstColumn: Text[1024];
        LastColumn: Text[1024];
        MatrixColumnCaptions: array[32] of Text[1024];

    protected var
        CurrentReportName: Code[10];
        CurrentColumnTemplate: Code[10];
        CurrentLineTemplate: Code[10];

    local procedure FindPeriod(SearchText: Code[3])
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
        DateFilter: Text;
        InternalDateFilter: Text;
    begin
        PeriodPageMgt.FindPeriodOnMatrixPage(DateFilter, InternalDateFilter, SearchText, PeriodType, false);
        Rec.SetFilter("Date Filter", InternalDateFilter);
    end;

    local procedure ValidateAnalysisTemplateName()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        PrevItemAnalysisView: Record "Item Analysis View";
    begin
        if AnalysisLineTemplate.Get(Rec.GetRangeMax("Analysis Area"), CurrentLineTemplate) then
            if (AnalysisLineTemplate."Default Column Template Name" <> '') and
               (CurrentColumnTemplate <> AnalysisLineTemplate."Default Column Template Name")
            then begin
                CurrentColumnTemplate := AnalysisLineTemplate."Default Column Template Name";
                AnalysisReportMgt.OpenColumns(CurrentColumnTemplate, Rec, TempAnalysisColumn);
                AnalysisReportMgt.CopyColumnsToTemp(Rec, CurrentColumnTemplate, TempAnalysisColumn);
            end;

        if AnalysisLineTemplate."Item Analysis View Code" <> ItemAnalysisView.Code then begin
            PrevItemAnalysisView := ItemAnalysisView;
            if AnalysisLineTemplate."Item Analysis View Code" <> '' then
                ItemAnalysisView.Get(Rec.GetRangeMax("Analysis Area"), AnalysisLineTemplate."Item Analysis View Code")
            else begin
                Clear(ItemAnalysisView);
                ItemAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                ItemAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
            if PrevItemAnalysisView."Dimension 1 Code" <> ItemAnalysisView."Dimension 1 Code" then
                Rec.SetRange("Dimension 1 Filter");
            if PrevItemAnalysisView."Dimension 2 Code" <> ItemAnalysisView."Dimension 2 Code" then
                Rec.SetRange("Dimension 2 Filter");
            if PrevItemAnalysisView."Dimension 3 Code" <> ItemAnalysisView."Dimension 3 Code" then
                Rec.SetRange("Dimension 3 Filter");
        end;
    end;

    local procedure ValidateReportName()
    var
        AnalysisReportName: Record "Analysis Report Name";
    begin
        if AnalysisReportName.Get(Rec.GetRangeMax("Analysis Area"), CurrentReportName) then begin
            if AnalysisReportName."Analysis Line Template Name" <> '' then
                CurrentLineTemplate := AnalysisReportName."Analysis Line Template Name";
            if AnalysisReportName."Analysis Column Template Name" <> '' then
                CurrentColumnTemplate := AnalysisReportName."Analysis Column Template Name";
        end;
    end;

    local procedure GetCaption(): Text[250]
    var
        AnalysisReportName: Record "Analysis Report Name";
    begin
        if CurrentReportName <> '' then
            if AnalysisReportName.Get(Rec."Analysis Area"::Inventory, CurrentReportName) then
                exit(AnalysisReportName.Name + ' ' + AnalysisReportName.Description);
    end;

    procedure SetFilters()
    begin
        TempAnalysisColumn.Reset();
        TempAnalysisColumn.SetRange("Analysis Area", Rec."Analysis Area"::Inventory);
        TempAnalysisColumn.SetRange("Analysis Column Template", CurrentColumnTemplate);

        AnalysisLine.Copy(Rec);
        AnalysisLine.SetRange("Analysis Area", Rec."Analysis Area"::Inventory);
        AnalysisLine.SetRange("Analysis Line Template Name", CurrentLineTemplate);
    end;

    local procedure GetColumnsRangeFilter(): Text[80]
    begin
        if FirstColumn = LastColumn then
            exit(FirstColumn);

        exit(FirstColumn + '..' + LastColumn);
    end;

    local procedure SetPointsAnalysisColumn()
    var
        AnalysisColumn2: Record "Analysis Column";
        tmpFirstColumn: Text[80];
        tmpLastColumn: Text[80];
        tmpFirstLineNo: Integer;
        tmpLastLineNo: Integer;
    begin
        AnalysisColumn2.SetRange("Analysis Area", AnalysisColumn2."Analysis Area"::Inventory);
        AnalysisColumn2.SetRange("Analysis Column Template", CurrentColumnTemplate);

        if (Direction = Direction::Forward) or
           (FirstColumn = '')
        then begin
            if LastColumn = '' then begin
                AnalysisColumn2.Find('-');
                tmpFirstColumn := AnalysisColumn2."Column Header";
                tmpFirstLineNo := AnalysisColumn2."Line No.";
                AnalysisColumn2.Next(NoOfColumns - 1);
                tmpLastColumn := AnalysisColumn2."Column Header";
                tmpLastLineNo := AnalysisColumn2."Line No.";
            end else begin
                if AnalysisColumn2.Get(AnalysisColumn2."Analysis Area"::Inventory, CurrentColumnTemplate, LastLineNo) then;
                AnalysisColumn2.Next(1);
                tmpFirstColumn := AnalysisColumn2."Column Header";
                tmpFirstLineNo := AnalysisColumn2."Line No.";
                AnalysisColumn2.Next(NoOfColumns - 1);
                tmpLastColumn := AnalysisColumn2."Column Header";
                tmpLastLineNo := AnalysisColumn2."Line No.";
            end;
        end else begin
            if AnalysisColumn2.Get(AnalysisColumn2."Analysis Area"::Inventory, CurrentColumnTemplate, FirstLineNo) then;
            AnalysisColumn2.Next(-1);
            tmpLastColumn := AnalysisColumn2."Column Header";
            tmpLastLineNo := AnalysisColumn2."Line No.";
            AnalysisColumn2.Next(-NoOfColumns + 1);
            tmpFirstColumn := AnalysisColumn2."Column Header";
            tmpFirstLineNo := AnalysisColumn2."Line No.";
        end;

        if (tmpFirstColumn = tmpLastColumn) and
           ((tmpLastColumn = LastColumn) or (tmpFirstColumn = FirstColumn))
        then
            exit;

        FirstColumn := tmpFirstColumn;
        LastColumn := tmpLastColumn;
        FirstLineNo := tmpFirstLineNo;
        LastLineNo := tmpLastLineNo;
    end;

    local procedure FillMatrixColumns()
    var
        AnalysisColumn2: Record "Analysis Column";
        i: Integer;
    begin
        AnalysisColumn2.SetRange("Analysis Area", AnalysisColumn2."Analysis Area"::Inventory);
        AnalysisColumn2.SetRange("Analysis Column Template", CurrentColumnTemplate);
        AnalysisColumn2.SetRange("Line No.", FirstLineNo, LastLineNo);
        AnalysisColumn2.SetFilter(Show, '<>%1', AnalysisColumn2.Show::Never);
        i := 1;

        if AnalysisColumn2.Find('-') then
            repeat
                MatrixColumnCaptions[i] := AnalysisColumn2."Column Header";
                i := i + 1;
            until (AnalysisColumn2.Next() = 0) or (i > ArrayLen(MatrixColumnCaptions));
    end;

    local procedure ClearPoints()
    begin
        Clear(FirstColumn);
        Clear(LastColumn);
    end;

    procedure SetReportName(NewReportName: Code[10])
    begin
        NewCurrentReportName := NewReportName;
    end;

    local procedure CurrentReportNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        ValidateReportName();
        AnalysisReportMgt.SetAnalysisLineTemplName(CurrentLineTemplate, Rec);
        ValidateAnalysisTemplateName();
        AnalysisReportMgt.CopyColumnsToTemp(Rec, CurrentColumnTemplate, TempAnalysisColumn);
        CurrPage.Update(false);
        ClearPoints();
        SetPointsAnalysisColumn();
    end;

    local procedure CurrentLineTemplateOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        AnalysisReportMgt.SetAnalysisLineTemplName(CurrentLineTemplate, Rec);
        ValidateAnalysisTemplateName();
        CurrPage.Update(false);
    end;

    local procedure CurrentColumnTemplateOnAfterValidate()
    begin
        AnalysisReportMgt.CopyColumnsToTemp(Rec, CurrentColumnTemplate, TempAnalysisColumn);
        CurrPage.Update(false);
        ClearPoints();
        SetPointsAnalysisColumn();
    end;

    local procedure CurrentSourceTypeNoFilterOnAfterValidate()
    begin
        AnalysisReportMgt.SetSourceNo(Rec, CurrentSourceTypeNoFilter);
        CurrPage.Update(false);
    end;

    local procedure CurrentSourceTypeFilterOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;
}

