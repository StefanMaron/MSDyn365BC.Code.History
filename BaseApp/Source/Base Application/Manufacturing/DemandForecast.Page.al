#if not CLEAN20
page 99000919 "Demand Forecast"
{
    Caption = 'Demand Forecast Overview';
    DataCaptionExpression = ProductionForecastName;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    ObsoleteReason = 'This page will be replaced by Page 2901 "Demand Forecast Card"';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ProductionForecastName; ProductionForecastName)
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand Forecast Name';
                    TableRelation = "Production Forecast Name".Name;
                    ToolTip = 'Specifies the name of the relevant demand forecast for which you are creating an entry.';

                    trigger OnValidate()
                    begin
                        SetMatrix();
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies a location code if you want to create a forecast entry for a specific location.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Loc: Record Location;
                        LocList: Page "Location List";
                    begin
                        LocList.LookupMode(true);
                        Loc.SetRange("Use As In-Transit", false);
                        LocList.SetTableView(Loc);
                        if not (LocList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := LocList.GetSelectionFilter();

                        exit(true);
                    end;

                    trigger OnValidate()
                    var
                        Location: Record Location;
                    begin
                        Location.SetFilter(Code, LocationFilter);
                        LocationFilter := Location.GetFilter(Code);
                        SetMatrix();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Planning;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                    end;
                }
                field(QtyType; QtyType)
                {
                    ApplicationArea = Planning;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        QtyTypeOnAfterValidate();
                    end;
                }
                field(ForecastType; ForecastType)
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast Type';
                    ToolTip = 'Specifies one of the following two types when you create a demand forecast entry: sales item or component item.';

                    trigger OnValidate()
                    begin
                        ForecastTypeOnAfterValidate();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        SetMatrixColumns("Matrix Page Step Type"::Initial);
                    end;
                }
            }
            part(Matrix; "Demand Forecast Matrix")
            {
                ApplicationArea = Planning;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy Demand Forecast")
                {
                    ApplicationArea = Planning;
                    Caption = 'Copy Demand Forecast';
                    Ellipsis = true;
                    Image = CopyForecast;
                    RunObject = Report "Copy Production Forecast";
                    ToolTip = 'Copy an existing demand forecast to quickly create a similar forecast.';
                }
            }
            action("Previous Set")
            {
                ApplicationArea = Planning;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Previous);
                end;
            }
            action("Previous Column")
            {
                ApplicationArea = Planning;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::PreviousColumn);
                end;
            }
            action("Next Column")
            {
                ApplicationArea = Planning;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::NextColumn);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Planning;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    SetMatrixColumns("Matrix Page Step Type"::Next);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref("Previous Column_Promoted"; "Previous Column")
                {
                }
                actionref("Next Column_Promoted"; "Next Column")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if (NewProductionForecastName <> '') and (NewProductionForecastName <> ProductionForecastName) then
            ProductionForecastName := NewProductionForecastName;
        OnOpenPageOnBeforeSetColums(PeriodType, QtyType, ForecastType, LocationFilter, DateFilter);
        SetMatrixColumns("Matrix Page Step Type"::Initial);
    end;

    var
        MatrixRecords: array[32] of Record Date;
        QtyType: Enum "Analysis Amount Type";
        NewProductionForecastName: Text[30];
        MatrixColumnCaptions: array[32] of Text[1024];
        ColumnSet: Text[1024];
        PKFirstRecInCurrSet: Text[100];
        CurrSetLength: Integer;

    protected var
        PeriodType: Enum "Analysis Period Type";
        ForecastType: Enum "Demand Forecast Type";
        ProductionForecastName: Text[30];
        LocationFilter: Text;
        DateFilter: Text[1024];

    [Obsolete('The page object will be replaced by Page 2901 "Demand Forecast Card"', '20.0')]
    procedure SetMatrixColumns(StepType: Enum "Matrix Page Step Type")
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), ArrayLen(MatrixRecords), false, PeriodType, DateFilter, PKFirstRecInCurrSet,
            MatrixColumnCaptions, ColumnSet, CurrSetLength, MatrixRecords);
        SetMatrix();
    end;

    [Obsolete('The page object will be replaced by Page 2901 "Demand Forecast Card"', '20.0')]
    procedure SetProductionForecastName(NextProductionForecastName: Text[30])
    begin
        NewProductionForecastName := NextProductionForecastName;
    end;

    [Obsolete('The page object will be replaced by Page 2901 "Demand Forecast Card"', '20.0')]
    [Scope('OnPrem')]
    procedure SetMatrix()
    begin
        CurrPage.Matrix.PAGE.LoadMatrix(
          MatrixColumnCaptions, MatrixRecords, ProductionForecastName, DateFilter, LocationFilter, ForecastType,
          QtyType, CurrSetLength);
        CurrPage.Update(false);
    end;

    local procedure ForecastTypeOnAfterValidate()
    begin
        SetMatrix();
    end;

    local procedure QtyTypeOnAfterValidate()
    begin
        SetMatrix();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetColums(var PeriodType: Enum "Analysis Period Type"; var QtyType: Option "Net Change","Balance at Date"; var ForecastType: Option "Sales Item",Component,Both; var LocationFilter: Text; var DateFilter: Text[1024])
    begin
    end;
}
#endif